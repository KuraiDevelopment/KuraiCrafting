-- ============================================================================
-- KURAI.DEV ADVANCED PROGRESSION CRAFTING SYSTEM v3.0
-- Client-side with search, blueprints, specializations, tool durability
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()
local currentStation = nil
local isCrafting = false
local lastCraftTime = 0
local craftingBlips = {}
local dynamicStations = {}
local cachedPlayerData = nil

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

-- ====================== FORMATTING HELPERS ======================
local function FormatIngredients(ingredients)
    local text = ''
    for i, ing in ipairs(ingredients) do
        local itemLabel = QBCore.Shared.Items[ing.item] and QBCore.Shared.Items[ing.item].label or ing.item
        text = text .. ing.count .. 'x ' .. itemLabel
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
        ammo = 'fa-solid fa-bullets',
        medical = 'fa-solid fa-briefcase-medical',
        chemistry = 'fa-solid fa-flask',
        food = 'fa-solid fa-burger',
        drinks = 'fa-solid fa-mug-hot'
    }
    return icons[category] or 'fa-solid fa-box'
end

local function GetRarityColor(rarity)
    if not rarity then return '#AAAAAA' end
    return Config.BlueprintRarity[rarity] and Config.BlueprintRarity[rarity].color or '#AAAAAA'
end

local function FormatToolDurability(toolName)
    if not Config.EnableToolDurability or not toolName then return '' end
    
    local durability = lib.callback.await('crafting:getToolDurability', false, toolName)
    local maxDurability = Config.Tools[toolName] and Config.Tools[toolName].maxDurability or 100
    
    local percent = math.floor((durability / maxDurability) * 100)
    local color = percent > 50 and '~g~' or (percent > 25 and '~o~' or '~r~')
    
    return color .. percent .. '%~s~'
end

-- ====================== CRAFTING UI ======================
local function OpenCraftingMenu(station)
    if not CanCraft() then return end
    
    currentStation = station
    
    lib.callback('crafting:getAvailableRecipes', false, function(data)
        if not data or not data.recipes then
            ShowNotification('Crafting', 'Failed to load recipes', 'error')
            return
        end
        
        cachedPlayerData = data
        local recipes = data.recipes
        local lockedRecipes = data.lockedRecipes or {}
        local playerLevel = data.level
        local playerXP = data.xp
        local nextLevelXP = data.nextLevelXP
        local spec = data.specialization
        
        -- Group recipes by category
        local categories = {}
        local lockedCategories = {}
        
        for id, recipe in pairs(recipes) do
            if not categories[recipe.category] then
                categories[recipe.category] = {}
            end
            table.insert(categories[recipe.category], {id = id, recipe = recipe, locked = false})
        end
        
        -- Add locked recipes if configured
        if Config.ShowLockedRecipes then
            for id, lockedData in pairs(lockedRecipes) do
                local recipe = lockedData.recipe
                if not categories[recipe.category] then
                    categories[recipe.category] = {}
                end
                table.insert(categories[recipe.category], {
                    id = id, 
                    recipe = recipe, 
                    locked = true, 
                    lockReason = lockedData.reason
                })
            end
        end
        
        local contextMenu = {}
        
        -- Player info header
        local specText = spec and (' | ' .. Config.Specializations[spec.type].label) or ''
        local progressPercent = math.floor((playerXP / nextLevelXP) * 100)
        
        table.insert(contextMenu, {
            title = '📊 Level ' .. playerLevel .. ' ' .. data.title .. specText,
            description = 'XP: ' .. playerXP .. '/' .. nextLevelXP .. ' (' .. progressPercent .. '%) | Crafted: ' .. data.totalCrafted,
            icon = 'fa-solid fa-chart-line',
            disabled = true
        })
        
        -- Search option
        if Config.EnableRecipeSearch then
            table.insert(contextMenu, {
                title = '🔍 Search Recipes',
                description = 'Find recipes by name',
                icon = 'fa-solid fa-magnifying-glass',
                onSelect = function()
                    OpenRecipeSearch(station, data)
                end
            })
        end
        
        -- Specialization option (if available)
        if Config.EnableSpecializations then
            local specIcon = spec and Config.Specializations[spec.type].icon or 'fa-solid fa-star'
            local specLabel = spec and ('Specialization: ' .. Config.Specializations[spec.type].label) or 'Choose Specialization'
            
            table.insert(contextMenu, {
                title = '⭐ ' .. specLabel,
                description = spec and 'View or change your specialization' or (playerLevel >= Config.SpecializationUnlockLevel and 'Select your crafting focus!' or 'Unlocks at level ' .. Config.SpecializationUnlockLevel),
                icon = specIcon,
                disabled = playerLevel < Config.SpecializationUnlockLevel and not spec,
                onSelect = function()
                    OpenSpecializationMenu()
                end
            })
        end
        
        table.insert(contextMenu, {
            title = '━━━━━━━━━━━━━━━━',
            disabled = true
        })
        
        -- Sort categories
        local sortedCategories = {}
        for category, _ in pairs(categories) do
            table.insert(sortedCategories, category)
        end
        table.sort(sortedCategories)
        
        -- Add categories
        for _, category in ipairs(sortedCategories) do
            local categoryRecipes = categories[category]
            local availableCount = 0
            local lockedCount = 0
            
            for _, r in ipairs(categoryRecipes) do
                if r.locked then
                    lockedCount = lockedCount + 1
                else
                    availableCount = availableCount + 1
                end
            end
            
            local description = availableCount .. ' available'
            if lockedCount > 0 then
                description = description .. ', ' .. lockedCount .. ' locked'
            end
            
            table.insert(contextMenu, {
                title = string.upper(category:sub(1,1)) .. category:sub(2),
                description = description,
                icon = GetCategoryIcon(category),
                arrow = true,
                onSelect = function()
                    OpenCategoryMenu(station, category, categoryRecipes, playerLevel, data)
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

function OpenRecipeSearch(station, playerData)
    local input = lib.inputDialog('Search Recipes', {
        {type = 'input', label = 'Recipe Name', placeholder = 'Enter search term...', required = true}
    })
    
    if not input or not input[1] or input[1] == '' then return end
    
    local searchTerm = string.lower(input[1])
    local results = {}
    
    -- Search available recipes
    for id, recipe in pairs(playerData.recipes) do
        if string.find(string.lower(recipe.label), searchTerm) or
           string.find(string.lower(recipe.description or ''), searchTerm) then
            table.insert(results, {id = id, recipe = recipe, locked = false})
        end
    end
    
    -- Search locked recipes
    if Config.ShowLockedRecipes and playerData.lockedRecipes then
        for id, lockedData in pairs(playerData.lockedRecipes) do
            local recipe = lockedData.recipe
            if string.find(string.lower(recipe.label), searchTerm) or
               string.find(string.lower(recipe.description or ''), searchTerm) then
                table.insert(results, {
                    id = id, 
                    recipe = recipe, 
                    locked = true, 
                    lockReason = lockedData.reason
                })
            end
        end
    end
    
    if #results == 0 then
        ShowNotification('Search', 'No recipes found for "' .. input[1] .. '"', 'error')
        return
    end
    
    -- Sort by level
    table.sort(results, function(a, b)
        return a.recipe.requiredLevel < b.recipe.requiredLevel
    end)
    
    local contextMenu = {}
    
    table.insert(contextMenu, {
        title = '🔍 Search: "' .. input[1] .. '"',
        description = #results .. ' results found',
        icon = 'fa-solid fa-magnifying-glass',
        disabled = true
    })
    
    for _, recipeData in ipairs(results) do
        local id = recipeData.id
        local recipe = recipeData.recipe
        local isLocked = recipeData.locked
        
        local icon = GetCategoryIcon(recipe.category)
        local title = recipe.label
        local description = recipe.category:sub(1,1):upper() .. recipe.category:sub(2) .. ' • Level ' .. recipe.requiredLevel .. ' • ' .. recipe.xp .. ' XP'
        
        if isLocked then
            if recipeData.lockReason == 'blueprint' then
                title = '🔒 ' .. title .. ' [Blueprint Required]'
                description = description .. '\n📜 Rarity: ' .. (recipe.blueprintRarity or 'unknown')
            else
                title = '🔒 ' .. title .. ' [Level ' .. recipe.requiredLevel .. ']'
            end
        end
        
        table.insert(contextMenu, {
            title = title,
            description = description,
            icon = icon,
            disabled = isLocked,
            arrow = not isLocked,
            onSelect = not isLocked and function()
                OpenRecipeMenu(station, id, recipe)
            end or nil
        })
    end
    
    lib.registerContext({
        id = 'crafting_search_results',
        title = 'Search Results',
        menu = 'crafting_main_menu',
        options = contextMenu
    })
    
    lib.showContext('crafting_search_results')
end

function OpenCategoryMenu(station, category, recipes, playerLevel, playerData)
    local contextMenu = {}
    
    -- Sort by required level
    table.sort(recipes, function(a, b)
        if a.locked ~= b.locked then
            return not a.locked  -- Unlocked first
        end
        return a.recipe.requiredLevel < b.recipe.requiredLevel
    end)
    
    -- Check for specialization bonus
    local spec = playerData.specialization
    local hasSpecBonus = false
    if spec and Config.EnableSpecializations then
        local specConfig = Config.Specializations[spec.type]
        for _, cat in ipairs(specConfig.bonusCategories) do
            if cat == category then
                hasSpecBonus = true
                break
            end
        end
    end
    
    if hasSpecBonus then
        table.insert(contextMenu, {
            title = '⭐ Specialization Bonus Active!',
            description = '+' .. math.floor(Config.Specializations[spec.type].xpBonus * 100) .. '% XP, +' .. 
                          math.floor(Config.Specializations[spec.type].successBonus * 100) .. '% Success',
            icon = Config.Specializations[spec.type].icon,
            disabled = true
        })
    end
    
    for _, recipeData in ipairs(recipes) do
        local id = recipeData.id
        local recipe = recipeData.recipe
        local isLocked = recipeData.locked
        local lockReason = recipeData.lockReason
        
        local canCraft = not isLocked
        local title = recipe.label
        local description = 'Ingredients: ' .. FormatIngredients(recipe.ingredients)
        
        -- Tool requirement
        if recipe.requiredTool then
            local toolLabel = Config.Tools[recipe.requiredTool] and Config.Tools[recipe.requiredTool].label or recipe.requiredTool
            local durabilityText = FormatToolDurability(recipe.requiredTool)
            description = description .. '\n🔧 Requires: ' .. toolLabel
            if durabilityText ~= '' then
                description = description .. ' ' .. durabilityText
            end
        end
        
        -- Level and XP info
        local levelText = '✓ Level ' .. recipe.requiredLevel
        if isLocked and lockReason == 'level' then
            levelText = '🔒 Level ' .. recipe.requiredLevel
        end
        description = description .. '\n' .. levelText .. ' • ' .. recipe.xp .. ' XP'
        
        -- Quality info
        if recipe.canProduceQuality then
            description = description .. ' • ✨ Quality'
        end
        
        -- Blueprint lock info
        if isLocked and lockReason == 'blueprint' then
            title = '🔒 ' .. title
            local rarityColor = GetRarityColor(recipe.blueprintRarity)
            description = description .. '\n📜 Blueprint Required (' .. (recipe.blueprintRarity or 'unknown') .. ')'
        end
        
        table.insert(contextMenu, {
            title = title,
            description = description,
            icon = GetCategoryIcon(recipe.category),
            disabled = isLocked,
            arrow = not isLocked,
            onSelect = not isLocked and function()
                OpenRecipeMenu(station, id, recipe)
            end or nil
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
    local resultLabel = QBCore.Shared.Items[recipe.result.item] and QBCore.Shared.Items[recipe.result.item].label or recipe.result.item
    
    local input = lib.inputDialog(recipe.label, {
        {
            type = 'number',
            label = 'Amount to Craft',
            description = 'Creates ' .. recipe.result.count .. 'x ' .. resultLabel .. ' each. Max: ' .. Config.MaxCraftAmount,
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

-- ====================== SPECIALIZATION UI ======================
function OpenSpecializationMenu()
    lib.callback('crafting:getSpecializations', false, function(data)
        if not data then return end
        
        local contextMenu = {}
        
        if data.current then
            local currentSpec = Config.Specializations[data.current.type]
            
            table.insert(contextMenu, {
                title = '⭐ Current: ' .. currentSpec.label,
                description = currentSpec.description,
                icon = currentSpec.icon,
                disabled = true
            })
            
            -- Bonus categories
            local bonusText = table.concat(data.current.type and currentSpec.bonusCategories or {}, ', ')
            table.insert(contextMenu, {
                title = '✅ Bonus Categories',
                description = bonusText .. '\n+' .. math.floor(currentSpec.xpBonus * 100) .. '% XP, +' .. 
                              math.floor(currentSpec.successBonus * 100) .. '% Success, +' .. 
                              math.floor(currentSpec.qualityBonus * 100) .. '% Quality',
                icon = 'fa-solid fa-arrow-up',
                disabled = true
            })
            
            -- Penalty categories
            if currentSpec.penaltyCategories and #currentSpec.penaltyCategories > 0 then
                local penaltyText = table.concat(currentSpec.penaltyCategories, ', ')
                table.insert(contextMenu, {
                    title = '⚠️ Reduced Categories',
                    description = penaltyText .. '\n-' .. math.floor(currentSpec.xpPenalty * 100) .. '% XP',
                    icon = 'fa-solid fa-arrow-down',
                    disabled = true
                })
            end
            
            if data.canReset then
                table.insert(contextMenu, {
                    title = '🔄 Reset Specialization',
                    description = data.resetCost > 0 and ('Cost: $' .. data.resetCost) or 'Free',
                    icon = 'fa-solid fa-rotate-left',
                    onSelect = function()
                        local confirm = lib.alertDialog({
                            header = 'Reset Specialization',
                            content = 'Are you sure you want to reset your specialization?' .. 
                                      (data.resetCost > 0 and ('\n\nCost: $' .. data.resetCost) or ''),
                            centered = true,
                            cancel = true
                        })
                        
                        if confirm == 'confirm' then
                            lib.callback('crafting:resetSpecialization', false, function(success, error)
                                if success then
                                    ShowNotification('Specialization', 'Specialization reset!', 'success')
                                else
                                    ShowNotification('Specialization', error or 'Failed to reset', 'error')
                                end
                            end)
                        end
                    end
                })
            end
        else
            table.insert(contextMenu, {
                title = '⭐ Choose Your Specialization',
                description = 'Each specialization provides bonuses to specific categories',
                icon = 'fa-solid fa-star',
                disabled = true
            })
            
            table.insert(contextMenu, {
                title = '━━━━━━━━━━━━━━━━',
                disabled = true
            })
            
            for specId, specConfig in pairs(Config.Specializations) do
                local bonusText = '+' .. math.floor(specConfig.xpBonus * 100) .. '% XP in: ' .. 
                                  table.concat(specConfig.bonusCategories, ', ')
                
                table.insert(contextMenu, {
                    title = specConfig.label,
                    description = specConfig.description .. '\n' .. bonusText,
                    icon = specConfig.icon,
                    onSelect = function()
                        local confirm = lib.alertDialog({
                            header = 'Choose ' .. specConfig.label .. '?',
                            content = specConfig.description .. '\n\n' ..
                                      '✅ Bonus: ' .. table.concat(specConfig.bonusCategories, ', ') .. '\n' ..
                                      '⚠️ Reduced: ' .. table.concat(specConfig.penaltyCategories, ', '),
                            centered = true,
                            cancel = true
                        })
                        
                        if confirm == 'confirm' then
                            lib.callback('crafting:selectSpecialization', false, function(success, error)
                                if success then
                                    ShowNotification('Specialization', 'You are now a ' .. specConfig.label .. '!', 'success')
                                else
                                    ShowNotification('Specialization', error or 'Failed to select', 'error')
                                end
                            end, specId)
                        end
                    end
                })
            end
        end
        
        lib.registerContext({
            id = 'crafting_specialization_menu',
            title = 'Crafting Specialization',
            menu = 'crafting_main_menu',
            options = contextMenu
        })
        
        lib.showContext('crafting_specialization_menu')
    end)
end

-- ====================== CRAFTING PROCESS ======================
function StartCrafting(station, recipeId, recipe, amount)
    if not CanCraft() then return end
    
    isCrafting = true
    local totalTime = recipe.time * amount
    
    PlayCraftingAnimation(station.type)
    
    if Config.DisableControlsWhileCrafting then
        CreateThread(function()
            while isCrafting do
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true)
                EnableControlAction(0, 2, true)
                Wait(0)
            end
        end)
    end
    
    local success = true
    
    if Config.UseSkillCheck and recipe.skillCheck then
        ShowNotification('Crafting', 'Starting craft...', 'info')
        
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
            success = lib.skillCheck(recipe.skillCheck, {'w', 'a', 's', 'd'})
            
            if not success then
                ShowNotification('Crafting Failed', 'You failed the skill check!', 'error')
            end
        else
            success = false
            ShowNotification('Crafting Cancelled', 'You cancelled the crafting process', 'error')
        end
    else
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
    
    StopCraftingAnimation()
    isCrafting = false
    lastCraftTime = GetGameTimer()
    
    if success then
        -- Pass station coords for server-side validation
        TriggerServerEvent('crafting:attemptCraft', recipeId, amount, station.type, station.coords)
    end
end

-- ====================== STATION INTERACTIONS ======================
local function SetupStations()
    -- Clear existing
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
    craftingBlips = {}
    
    -- Remove old zones
    exports.ox_target:removeZone('crafting_station_')
    
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
        
        local stationName = 'crafting_station_' .. i
        
        exports.ox_target:addBoxZone({
            coords = station.coords,
            size = vec3(2.0, 2.0, 2.0),
            rotation = station.heading or 0.0,
            debug = Config.EnableDebug,
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
    
    ShowNotification('Crafting Station', 'Saving station...', 'info')
    
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
RegisterNetEvent('crafting:craftResult', function(success, message, xpGained, levelUp, newLevel, xpBonuses, quality)
    if success then
        local description = message
        if xpGained then
            description = description .. '\n+' .. xpGained .. ' XP'
            
            if xpBonuses and #xpBonuses > 0 then
                for _, bonus in ipairs(xpBonuses) do
                    description = description .. ' (' .. bonus.name .. ')'
                end
            end
        end
        if levelUp then
            description = description .. '\n🎉 LEVEL UP! Now level ' .. newLevel
        end
        ShowNotification('Crafting Success', description, 'success')
    else
        ShowNotification('Crafting Failed', message, 'error')
    end
end)

RegisterNetEvent('crafting:blueprintUnlocked', function(recipeId, recipeLabel)
    lib.notify({
        title = '📜 Blueprint Learned!',
        description = 'You can now craft: ' .. recipeLabel,
        type = 'success',
        duration = 5000,
        position = 'top'
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetupStations()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
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

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    lib.hideTextUI()
    StopCraftingAnimation()
    
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
end)
