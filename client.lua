local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']
local currentStation = nil
local isCrafting = false
local lastCraftTime = 0
local craftingBlips = {}
local dynamicStations = {}

-- ====================== UTILITY FUNCTIONS ======================
local function GetPlayerLevel()
    return lib.callback.await('crafting:getPlayerLevel', false)
end

local function ShowNotification(title, description, type)
    lib.notify({
        title = title,
        description = description,
        type = type or 'info',
        position = 'top'
    })
end

local function CanCraft()
    if isCrafting then
        ShowNotification('Crafting', 'You are already crafting!', 'error')
        return false
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastCraftTime < (Config.GlobalCooldown * 1000) then
        ShowNotification('Crafting', 'Please wait before crafting again', 'error')
        return false
    end
    
    return true
end

local function PlayCraftingAnimation(stationType)
    local ped = PlayerPedId()
    local animData = Config.Animations[stationType] or Config.Animations.workbench
    
    RequestAnimDict(animData.dict)
    while not HasAnimDictLoaded(animData.dict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, -8.0, -1, animData.flag, 0, false, false, false)
end

local function StopCraftingAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- ====================== CRAFTING UI ======================
local function FormatIngredients(ingredients)
    local text = ''
    for i, ing in ipairs(ingredients) do
        text = text .. ing.count .. 'x ' .. ing.item
        if i < #ingredients then
            text = text .. ', '
        end
    end
    return text
end

local function GetCategoryIcon(category)
    local icons = {
        basic = 'fa-solid fa-box',
        tools = 'fa-solid fa-wrench',
        components = 'fa-solid fa-gears',
        electronics = 'fa-solid fa-microchip',
        weapons = 'fa-solid fa-gun',
        attachments = 'fa-solid fa-crosshairs',
        medical = 'fa-solid fa-briefcase-medical',
        chemistry = 'fa-solid fa-flask',
        food = 'fa-solid fa-burger',
        drinks = 'fa-solid fa-mug-hot'
    }
    return icons[category] or 'fa-solid fa-box'
end

local function OpenCraftingMenu(station)
    if not CanCraft() then return end
    
    currentStation = station
    
    -- Get available recipes from server
    lib.callback('crafting:getAvailableRecipes', false, function(data)
        if not data or not data.recipes then
            ShowNotification('Crafting', 'Failed to load recipes', 'error')
            return
        end
        
        local recipes = data.recipes
        local playerLevel = data.level
        local playerXP = data.xp
        
        -- Group recipes by category
        local categories = {}
        for id, recipe in pairs(recipes) do
            if not categories[recipe.category] then
                categories[recipe.category] = {}
            end
            table.insert(categories[recipe.category], {id = id, recipe = recipe})
        end
        
        -- Build menu options
        local contextMenu = {}
        
        -- Add player info header
        table.insert(contextMenu, {
            title = '📊 Crafting Level: ' .. playerLevel,
            description = 'XP: ' .. playerXP,
            disabled = true,
            icon = 'fa-solid fa-chart-line'
        })
        
        table.insert(contextMenu, {
            title = '━━━━━━━━━━━━━━━━',
            disabled = true
        })
        
        -- Add categories
        for category, categoryRecipes in pairs(categories) do
            table.insert(contextMenu, {
                title = string.upper(category:sub(1,1)) .. category:sub(2),
                description = #categoryRecipes .. ' recipes available',
                icon = GetCategoryIcon(category),
                arrow = true,
                onSelect = function()
                    OpenCategoryMenu(station, category, categoryRecipes, playerLevel)
                end
            })
        end
        
        lib.registerContext({
            id = 'crafting_main_menu',
            title = station.label or 'Crafting Station',
            options = contextMenu
        })
        
        lib.showContext('crafting_main_menu')
    end, station.type)
end

function OpenCategoryMenu(station, category, recipes, playerLevel)
    local contextMenu = {}
    
    -- Sort by required level
    table.sort(recipes, function(a, b)
        return a.recipe.requiredLevel < b.recipe.requiredLevel
    end)
    
    for _, recipeData in ipairs(recipes) do
        local id = recipeData.id
        local recipe = recipeData.recipe
        
        local canCraft = playerLevel >= recipe.requiredLevel
        local levelText = canCraft and '✓ Level ' .. recipe.requiredLevel or '🔒 Level ' .. recipe.requiredLevel
        
        table.insert(contextMenu, {
            title = recipe.label,
            description = 'Ingredients: ' .. FormatIngredients(recipe.ingredients) .. '\n' .. levelText .. ' • ' .. recipe.xp .. ' XP',
            icon = GetCategoryIcon(recipe.category),
            disabled = not canCraft,
            arrow = true,
            onSelect = function()
                OpenRecipeMenu(station, id, recipe)
            end
        })
    end
    
    lib.registerContext({
        id = 'crafting_category_menu',
        title = string.upper(category:sub(1,1)) .. category:sub(2) .. ' Recipes',
        menu = 'crafting_main_menu',
        options = contextMenu
    })
    
    lib.showContext('crafting_category_menu')
end

function OpenRecipeMenu(station, recipeId, recipe)
    local input = lib.inputDialog(recipe.label, {
        {
            type = 'number',
            label = 'Amount to Craft',
            description = 'Maximum: ' .. Config.MaxCraftAmount,
            default = 1,
            min = 1,
            max = Config.MaxCraftAmount,
            required = true
        }
    })
    
    if not input or not input[1] then return end
    
    local amount = tonumber(input[1])
    if not amount or amount < 1 or amount > Config.MaxCraftAmount then
        ShowNotification('Crafting', 'Invalid amount', 'error')
        return
    end
    
    StartCrafting(station, recipeId, recipe, amount)
end

-- ====================== CRAFTING PROCESS ======================
function StartCrafting(station, recipeId, recipe, amount)
    if not CanCraft() then return end
    
    isCrafting = true
    local totalTime = recipe.time * amount
    
    -- Play animation
    PlayCraftingAnimation(station.type)
    
    -- Disable controls if configured
    if Config.DisableControlsWhileCrafting then
        CreateThread(function()
            while isCrafting do
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true) -- Look Left/Right
                EnableControlAction(0, 2, true) -- Look Up/Down
                Wait(0)
            end
        end)
    end
    
    -- Show progress bar with skill check
    local success = true
    
    if Config.UseSkillCheck and recipe.skillCheck then
        ShowNotification('Crafting', 'Starting craft...', 'info')
        
        -- Progress bar
        if lib.progressCircle({
            duration = totalTime,
            label = 'Crafting ' .. recipe.label .. ' (' .. amount .. 'x)',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true
            }
        }) then
            -- Skill check
            success = lib.skillCheck(recipe.skillCheck, {'w', 'a', 's', 'd'})
            
            if not success then
                ShowNotification('Crafting Failed', 'You failed the skill check!', 'error')
            end
        else
            success = false
            ShowNotification('Crafting Cancelled', 'You cancelled the crafting process', 'error')
        end
    else
        -- Simple progress without skill check
        if not lib.progressCircle({
            duration = totalTime,
            label = 'Crafting ' .. recipe.label .. ' (' .. amount .. 'x)',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true
            }
        }) then
            success = false
            ShowNotification('Crafting Cancelled', 'You cancelled the crafting process', 'error')
        end
    end
    
    -- Stop animation
    StopCraftingAnimation()
    isCrafting = false
    lastCraftTime = GetGameTimer()
    
    -- Send to server for validation and completion
    if success then
        TriggerServerEvent('crafting:attemptCraft', recipeId, amount, station.type)
    end
end

-- ====================== STATION INTERACTIONS ======================
local function SetupStations()
    -- Clear existing zones
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
    craftingBlips = {}
    
    -- Combine config and dynamic stations
    local allStations = {}
    
    for i, station in ipairs(Config.CraftingStations) do
        table.insert(allStations, {index = 'config_' .. i, station = station})
    end
    
    for i, station in ipairs(dynamicStations) do
        table.insert(allStations, {index = 'dynamic_' .. i, station = station})
    end
    
    for _, data in ipairs(allStations) do
        local i = data.index
        local station = data.station
        
        -- Create ox_target zone
        local stationName = 'crafting_station_' .. i
        
        exports.ox_target:addBoxZone({
            coords = station.coords,
            size = vec3(2.0, 2.0, 2.0),
            rotation = station.heading or 0.0,
            debug = false,
            options = {
                {
                    name = stationName,
                    label = Config.StationTypes[station.type].label,
                    icon = Config.StationTypes[station.type].icon,
                    distance = Config.CraftingDistance,
                    onSelect = function()
                        OpenCraftingMenu(station)
                    end
                }
            }
        })
        
        -- Create blip if configured
        if Config.ShowBlips and station.blip then
            local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipColour(blip, Config.BlipColour)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(station.label or Config.StationTypes[station.type].label)
            EndTextCommandSetBlipName(blip)
            table.insert(craftingBlips, blip)
        end
    end
end

-- ====================== ADMIN STATION MANAGEMENT ======================
local function GetClosestStation()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0
    
    -- Check dynamic stations only (can't delete config stations)
    for i, station in ipairs(dynamicStations) do
        local dist = #(pCoords - station.coords)
        if dist < closestDist then
            closestDist = dist
            closest = {index = i, station = station, distance = dist}
        end
    end
    
    return closest
end

RegisterNetEvent('crafting:admin:createStation', function(stationType)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Input dialog for station details
    local input = lib.inputDialog('Create Crafting Station', {
        {
            type = 'input',
            label = 'Station Label',
            description = 'Name for this station',
            default = Config.StationTypes[stationType].label,
            required = true
        },
        {
            type = 'checkbox',
            label = 'Show on Map',
            description = 'Display blip on map',
            checked = false
        },
        {
            type = 'number',
            label = 'Heading',
            description = 'Station rotation',
            default = math.floor(heading),
            min = 0,
            max = 360
        }
    })
    
    if not input then return end
    
    local stationData = {
        type = stationType,
        coords = pCoords,
        heading = input[3],
        blip = input[2],
        label = input[1]
    }
    
    -- Show preview
    ShowNotification('Crafting Station', 'Saving station...', 'info')
    
    -- Save to server
    lib.callback('crafting:admin:saveStation', false, function(success)
        if success then
            ShowNotification('Success', 'Crafting station created!', 'success')
        else
            ShowNotification('Error', 'Failed to create station', 'error')
        end
    end, stationData)
end)

RegisterNetEvent('crafting:admin:openManagement', function()
    lib.callback('crafting:admin:getAllStations', false, function(allStations)
        if not allStations then
            ShowNotification('Error', 'Failed to load stations', 'error')
            return
        end
        
        local contextMenu = {}
        
        table.insert(contextMenu, {
            title = '📊 Station Management',
            description = 'Total Stations: ' .. #allStations,
            disabled = true,
            icon = 'fa-solid fa-chart-bar'
        })
        
        table.insert(contextMenu, {
            title = '➕ Create New Station',
            description = 'Use /addcraftstation [type]',
            disabled = true,
            icon = 'fa-solid fa-plus'
        })
        
        table.insert(contextMenu, {
            title = '━━━━━━━━━━━━━━━━',
            disabled = true
        })
        
        -- Group by type
        local grouped = {}
        for _, station in ipairs(allStations) do
            if not grouped[station.type] then
                grouped[station.type] = {}
            end
            table.insert(grouped[station.type], station)
        end
        
        for stationType, stations in pairs(grouped) do
            table.insert(contextMenu, {
                title = Config.StationTypes[stationType].label .. ' (' .. #stations .. ')',
                description = 'View all ' .. stationType .. ' stations',
                icon = Config.StationTypes[stationType].icon,
                arrow = true,
                onSelect = function()
                    OpenStationTypeMenu(stationType, stations)
                end
            })
        end
        
        lib.registerContext({
            id = 'crafting_admin_menu',
            title = 'Station Management',
            options = contextMenu
        })
        
        lib.showContext('crafting_admin_menu')
    end)
end)

function OpenStationTypeMenu(stationType, stations)
    local contextMenu = {}
    
    for _, station in ipairs(stations) do
        local isDynamic = station.dynamic
        local distText = ''
        
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local dist = #(pCoords - station.coords)
        distText = string.format('%.1fm away', dist)
        
        table.insert(contextMenu, {
            title = station.label,
            description = distText .. (isDynamic and ' • Dynamic' or ' • Config') .. '\nCoords: ' .. math.floor(station.coords.x) .. ', ' .. math.floor(station.coords.y),
            icon = isDynamic and 'fa-solid fa-database' or 'fa-solid fa-file',
            metadata = {
                {label = 'Type', value = stationType},
                {label = 'Heading', value = station.heading},
                {label = 'Blip', value = station.blip and 'Yes' or 'No'}
            },
            arrow = isDynamic,
            onSelect = isDynamic and function()
                OpenStationActions(station)
            end or nil
        })
    end
    
    lib.registerContext({
        id = 'crafting_station_type_menu',
        title = Config.StationTypes[stationType].label .. ' Stations',
        menu = 'crafting_admin_menu',
        options = contextMenu
    })
    
    lib.showContext('crafting_station_type_menu')
end

function OpenStationActions(station)
    local contextMenu = {
        {
            title = '🗺️ Teleport to Station',
            description = 'TP to this station location',
            icon = 'fa-solid fa-location-dot',
            onSelect = function()
                SetEntityCoords(PlayerPedId(), station.coords.x, station.coords.y, station.coords.z)
                SetEntityHeading(PlayerPedId(), station.heading)
                ShowNotification('Teleport', 'Teleported to station', 'success')
            end
        },
        {
            title = '📍 Set Waypoint',
            description = 'Mark station on GPS',
            icon = 'fa-solid fa-map-pin',
            onSelect = function()
                SetNewWaypoint(station.coords.x, station.coords.y)
                ShowNotification('Waypoint', 'Waypoint set', 'success')
            end
        },
        {
            title = '🗑️ Delete Station',
            description = 'Permanently remove this station',
            icon = 'fa-solid fa-trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Delete Station',
                    content = 'Are you sure you want to delete this station? This cannot be undone.',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    lib.callback('crafting:admin:deleteStation', false, function(success)
                        if success then
                            ShowNotification('Success', 'Station deleted', 'success')
                        else
                            ShowNotification('Error', 'Failed to delete station', 'error')
                        end
                    end, station.id)
                end
            end
        }
    }
    
    lib.registerContext({
        id = 'crafting_station_actions',
        title = station.label,
        menu = 'crafting_station_type_menu',
        options = contextMenu
    })
    
    lib.showContext('crafting_station_actions')
end

RegisterNetEvent('crafting:admin:deleteNearest', function()
    local closest = GetClosestStation()
    
    if not closest then
        ShowNotification('Error', 'No dynamic stations nearby', 'error')
        return
    end
    
    if closest.distance > 10.0 then
        ShowNotification('Error', 'Nearest station is too far (' .. math.floor(closest.distance) .. 'm)', 'error')
        return
    end
    
    local confirm = lib.alertDialog({
        header = 'Delete Station',
        content = 'Delete "' .. closest.station.label .. '"?\n\nThis cannot be undone.',
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        lib.callback('crafting:admin:deleteStation', false, function(success)
            if success then
                ShowNotification('Success', 'Station deleted', 'success')
            else
                ShowNotification('Error', 'Failed to delete station', 'error')
            end
        end, closest.station.id)
    end
end)

RegisterNetEvent('crafting:updateStations', function(newDynamicStations)
    dynamicStations = newDynamicStations
    SetupStations()
end)

-- ====================== EVENTS ======================
RegisterNetEvent('crafting:craftResult', function(success, message, xpGained, levelUp, newLevel)
    if success then
        local description = message
        if xpGained then
            description = description .. ' (+' .. xpGained .. ' XP)'
        end
        if levelUp then
            description = description .. '\n🎉 Level Up! Now level ' .. newLevel
        end
        ShowNotification('Crafting Success', description, 'success')
    else
        ShowNotification('Crafting Failed', message, 'error')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetupStations()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    -- Clean up blips
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
    craftingBlips = {}
end)

-- ====================== INITIALIZATION ======================
CreateThread(function()
    if QBCore.Functions.GetPlayerData() and QBCore.Functions.GetPlayerData().citizenid then
        SetupStations()
    end
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    lib.hideTextUI()
    StopCraftingAnimation()
    
    -- Clean up blips
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
end)
