-- ============================================================================
-- KURAI.DEV ADVANCED PROGRESSION CRAFTING SYSTEM v3.0
-- Client-side with full prop spawning, search, blueprints, specializations
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ====================== LOCAL VARIABLES ======================
local currentStation = nil
local isCrafting = false
local lastCraftTime = 0
local craftingBlips = {}
local craftingProps = {}
local dynamicStations = {}
local cachedPlayerData = nil

-- ====================== MODEL LOADING ======================
local function LoadModel(model)
    if type(model) ~= 'string' and type(model) ~= 'number' then 
        if Config.EnableDebug then
            print('[Crafting] Invalid model type: ' .. type(model))
        end
        return nil 
    end
    
    local hash = type(model) == 'number' and model or GetHashKey(model)
    
    -- Check if model is valid in game files
    if not IsModelInCdimage(hash) then
        print('[Crafting] ERROR: Model not found in game files: ' .. tostring(model))
        print('[Crafting] Hash tried: ' .. tostring(hash))
        return nil
    end
    
    -- Check if it's already loaded
    if HasModelLoaded(hash) then
        if Config.EnableDebug then
            print('[Crafting] Model already loaded: ' .. tostring(model))
        end
        return hash
    end
    
    -- Request the model
    if Config.EnableDebug then
        print('[Crafting] Requesting model: ' .. tostring(model))\n    end
    
    RequestModel(hash)
    
    -- Wait for model to load with timeout
    local attempts = 0
    local maxAttempts = 200  -- Increased from 100
    
    while not HasModelLoaded(hash) and attempts < maxAttempts do
        Wait(50)  -- Increased from 10ms to 50ms
        attempts = attempts + 1
        
        -- Re-request every 10 attempts
        if attempts % 10 == 0 then
            if Config.EnableDebug then
                print('[Crafting] Still waiting for model... Attempt ' .. attempts .. '/' .. maxAttempts)
            end
            RequestModel(hash)
        end
    end
    
    if not HasModelLoaded(hash) then
        print('[Crafting] ERROR: Failed to load model after ' .. maxAttempts .. ' attempts: ' .. tostring(model))
        print('[Crafting] Hash: ' .. tostring(hash))
        return nil
    end
    
    if Config.EnableDebug then
        print('[Crafting] Successfully loaded model: ' .. tostring(model) .. ' (took ' .. attempts .. ' attempts)')
    end
    
    return hash
end

-- ====================== PROP MANAGEMENT ======================
local fallbackProps = {
    'prop_tool_bench02',
    'prop_toolchest_05',
    'prop_table_03',
    'prop_table_04',
    'prop_chair_01a'
}

local function SpawnPropWithFallback(model, coords, heading, offset, stationType)
    -- Try primary model first
    local prop = SpawnProp(model, coords, heading, offset)
    if prop then return prop end
    
    -- If primary failed and we have a station type, try station-specific fallbacks
    if stationType and Config.StationTypes[stationType] then
        local stationConfig = Config.StationTypes[stationType]
        if stationConfig.props then
            print('[Crafting] Primary prop failed, trying station alternatives...')
            for _, propData in ipairs(stationConfig.props) do
                if propData.model ~= model then
                    print('[Crafting] Trying alternative: ' .. propData.model)
                    prop = SpawnProp(propData.model, coords, heading, offset)
                    if prop then
                        print('[Crafting] Successfully spawned alternative prop: ' .. propData.model)
                        return prop
                    end
                end
            end
        end
    end
    
    -- Try universal fallbacks
    print('[Crafting] All station props failed, trying universal fallbacks...')
    for _, fallbackModel in ipairs(fallbackProps) do
        if fallbackModel ~= model then
            print('[Crafting] Trying fallback: ' .. fallbackModel)
            prop = SpawnProp(fallbackModel, coords, heading, offset)
            if prop then
                print('[Crafting] Successfully spawned fallback prop: ' .. fallbackModel)
                return prop
            end
        end
    end
    
    print('[Crafting] ERROR: All prop spawn attempts failed for this station!')
    return nil
end

local function SpawnProp(model, coords, heading, offset)
    if not Config.SpawnStationProps then return nil end
    if not model then 
        if Config.EnableDebug then
            print('[Crafting] No model provided to SpawnProp')
        end
        return nil 
    end
    
    if Config.EnableDebug then
        print('[Crafting] Attempting to spawn prop: ' .. tostring(model))
        print('[Crafting] Coords: ' .. tostring(coords))
    end
    
    local modelHash = LoadModel(model)
    if not modelHash then 
        print('[Crafting] ERROR: Could not load model hash for: ' .. tostring(model))
        return nil 
    end
    
    offset = offset or vector3(0.0, 0.0, -1.0)
    
    local propCoords = vector3(
        coords.x + offset.x,
        coords.y + offset.y,
        coords.z + offset.z
    )
    
    -- Create the object with network control
    local prop = CreateObject(modelHash, propCoords.x, propCoords.y, propCoords.z, false, true, false)
    
    if not DoesEntityExist(prop) then
        print('[Crafting] ERROR: Failed to create prop entity for: ' .. tostring(model))
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end
    
    -- Wait a frame for the entity to fully initialize
    Wait(0)
    
    -- Set prop properties
    SetEntityHeading(prop, heading or 0.0)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityInvincible(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    
    -- Make sure it's visible
    SetEntityVisible(prop, true, false)
    SetEntityAlpha(prop, 255, false)
    
    SetModelAsNoLongerNeeded(modelHash)
    
    if Config.EnableDebug then
        print('[Crafting] Successfully spawned prop: ' .. tostring(model) .. ' (Entity ID: ' .. prop .. ')')
        print('[Crafting] Prop coords: ' .. tostring(propCoords))
    end
    
    return prop
end

local function DeleteProp(prop)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
        return true
    end
    return false
end

local function ClearAllProps()
    for index, prop in pairs(craftingProps) do
        DeleteProp(prop)
    end
    craftingProps = {}
end

-- ====================== UTILITY FUNCTIONS ======================
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
    ClearPedTasks(PlayerPedId())
end

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
        ammo = 'fa-solid fa-box',
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
local nuiOpen = false

local function OpenCraftingMenu(station)
    if not CanCraft() then return end
    if nuiOpen then return end
    
    currentStation = station
    
    lib.callback('crafting:getAvailableRecipes', false, function(data)
        if not data or not data.recipes then
            ShowNotification('Crafting', 'Failed to load recipes', 'error')
            return
        end
        
        cachedPlayerData = data
        nuiOpen = true
        
        -- Get specialization data
        lib.callback('crafting:getSpecializations', false, function(specData)
            data.specializationData = specData
            
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openCrafting',
                station = station,
                data = data
            })
        end)
    end, station.type)
end

local function CloseCraftingMenu()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeCrafting'})
end

-- NUI Callbacks
RegisterNUICallback('uiReady', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    CloseCraftingMenu()
    cb('ok')
end)

RegisterNUICallback('craftItem', function(data, cb)
    local recipeId = data.recipeId
    local amount = data.amount
    
    if not cachedPlayerData or not cachedPlayerData.recipes[recipeId] then
        cb('error')
        return
    end
    
    local recipe = cachedPlayerData.recipes[recipeId]
    StartCrafting(currentStation, recipeId, recipe, amount)
    cb('ok')
end)

RegisterNUICallback('openSpecialization', function(data, cb)
    lib.callback('crafting:getSpecializations', false, function(specData)
        SendNUIMessage({
            action = 'openSpecialization',
            data = specData
        })
    end)
    cb('ok')
end)

RegisterNUICallback('selectSpecialization', function(data, cb)
    lib.callback('crafting:selectSpecialization', false, function(success)
        if success then
            ShowNotification('Specialization', 'Specialization selected!', 'success')
            -- Refresh UI data
            lib.callback('crafting:getAvailableRecipes', false, function(newData)
                lib.callback('crafting:getSpecializations', false, function(specData)
                    newData.specializationData = specData
                    SendNUIMessage({
                        action = 'updateData',
                        data = newData
                    })
                end)
            end, currentStation.type)
        else
            ShowNotification('Specialization', 'Failed to select specialization', 'error')
        end
    end, data.specialization)
    cb('ok')
end)

RegisterNUICallback('resetSpecialization', function(data, cb)
    lib.callback('crafting:resetSpecialization', false, function(success)
        if success then
            ShowNotification('Specialization', 'Specialization reset!', 'success')
            -- Refresh UI data
            lib.callback('crafting:getAvailableRecipes', false, function(newData)
                lib.callback('crafting:getSpecializations', false, function(specData)
                    newData.specializationData = specData
                    SendNUIMessage({
                        action = 'updateData',
                        data = newData
                    })
                end)
            end, currentStation.type)
        else
            ShowNotification('Specialization', 'Failed to reset', 'error')
        end
    end)
    cb('ok')
end)

-- Legacy compatibility - remove old context menu functions
function OpenRecipeSearch(station, playerData)
    -- Removed - now handled by NUI search
end

function OpenCategoryMenu(station, category, recipes, playerLevel, playerData)
    -- Removed - now handled by NUI
end

function OpenRecipeMenu(station, recipeId, recipe)
    -- Removed - now handled by NUI
end

function OpenSpecializationMenu()
    -- Removed - now handled by NUI
end

-- Keep compatibility with old notification calls but also send to NUI
local originalShowNotification = ShowNotification
ShowNotification = function(title, description, type)
    originalShowNotification(title, description, type)
    if nuiOpen then
        SendNUIMessage({
            action = 'notify',
            title = title,
            message = description,
            type = type
        })
    end
end

-- Deprecated context menu section
--[[ OLD CONTEXT MENU CODE - KEEPING FOR REFERENCE
local function OpenCraftingMenu_OLD(station)
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
        local spec = data.specialization
        
]]--

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
        if lib.progressCircle({
            duration = totalTime,
            label = 'Crafting ' .. recipe.label .. ' (' .. amount .. 'x)',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {move = true, car = true, combat = true}
        }) then
            success = lib.skillCheck(recipe.skillCheck, {'w', 'a', 's', 'd'})
        else
            success = false
        end
    else
        if not lib.progressCircle({
            duration = totalTime,
            label = 'Crafting ' .. recipe.label .. ' (' .. amount .. 'x)',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {move = true, car = true, combat = true}
        }) then
            success = false
        end
    end
    
    StopCraftingAnimation()
    isCrafting = false
    lastCraftTime = GetGameTimer()
    
    if success then
        TriggerServerEvent('crafting:attemptCraft', recipeId, amount, station.type, station.coords)
    else
        ShowNotification('Crafting', 'Cancelled', 'error')
    end
end

-- ====================== STATION SETUP ======================
local function SetupStations()
    -- Clear existing
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
    craftingBlips = {}
    ClearAllProps()
    
    -- Remove old zones
    for i = 1, 100 do
        exports.ox_target:removeZone('crafting_station_config_' .. i)
        exports.ox_target:removeZone('crafting_station_dynamic_' .. i)
    end
    
    local allStations = {}
    
    -- Add config stations
    for i, station in ipairs(Config.CraftingStations) do
        table.insert(allStations, {index = 'config_' .. i, station = station, isConfig = true})
    end
    
    -- Add dynamic stations
    for i, station in ipairs(dynamicStations) do
        table.insert(allStations, {index = 'dynamic_' .. i, station = station, isConfig = false})
    end
    
    for _, data in ipairs(allStations) do
        local i = data.index
        local station = data.station
        local stationConfig = Config.StationTypes[station.type]
        
        if not stationConfig then
            print('[Crafting] Unknown station type: ' .. tostring(station.type))
            goto continue
        end
        
        -- Spawn prop
        local shouldSpawnProp = Config.SpawnStationProps
        if data.isConfig and station.spawnProp == false then
            shouldSpawnProp = false
        end
        
        if shouldSpawnProp and station.prop then
            if Config.EnableDebug then
                print('[Crafting] Setting up station: ' .. (station.label or 'Unknown'))
                print('[Crafting] Type: ' .. station.type)
                print('[Crafting] Prop: ' .. tostring(station.prop))
                print('[Crafting] Coords: ' .. tostring(station.coords))
            end
            
            local offset = station.propOffset or stationConfig.propOffset or vector3(0.0, 0.0, -1.0)
            local prop = SpawnPropWithFallback(station.prop, station.coords, station.heading, offset, station.type)
            if prop then
                craftingProps[i] = prop
                if Config.EnableDebug then
                    print('[Crafting] Prop spawned successfully for: ' .. (station.label or 'Unknown'))
                end
            else
                print('[Crafting] WARNING: Failed to spawn prop for station: ' .. (station.label or 'Unknown'))
            end
        elseif shouldSpawnProp and not station.prop then
            print('[Crafting] WARNING: Station ' .. (station.label or 'Unknown') .. ' is set to spawn prop but no prop model defined')
        end
        
        -- Create target zone
        local targetSize = stationConfig.targetSize or vector3(2.0, 1.5, 1.5)
        
        exports.ox_target:addBoxZone({
            coords = station.coords,
            size = targetSize,
            rotation = station.heading or 0.0,
            debug = Config.EnableDebug,
            options = {
                {
                    name = 'crafting_station_' .. i,
                    label = station.label or stationConfig.label,
                    icon = stationConfig.icon,
                    distance = Config.CraftingDistance,
                    onSelect = function()
                        OpenCraftingMenu(station)
                    end
                }
            }
        })
        
        -- Create blip
        if Config.ShowBlips and station.blip then
            local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipColour(blip, Config.BlipColour)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(station.label or stationConfig.label)
            EndTextCommandSetBlipName(blip)
            table.insert(craftingBlips, blip)
        end
        
        ::continue::
    end
    
    if Config.EnableDebug then
        print('[Crafting] Setup ' .. #allStations .. ' stations')
    end
end

-- ====================== ADMIN: CREATE STATION ======================
local isPlacingStation = false
local previewProp = nil
local previewHeading = 0.0
local previewHeight = 0.0

local function CleanupPreviewProp()
    if previewProp and DoesEntityExist(previewProp) then
        DeleteProp(previewProp)
        previewProp = nil
    end
end

local function UpdatePreviewProp(model, coords, heading, heightOffset)
    CleanupPreviewProp()
    
    if Config.EnableDebug then
        print('[Crafting] Creating preview prop: ' .. tostring(model))
    end
    
    local offset = vector3(0.0, 0.0, heightOffset / 10.0 - 1.0)
    previewProp = SpawnProp(model, coords, heading, offset)
    
    if previewProp and DoesEntityExist(previewProp) then
        SetEntityAlpha(previewProp, 200, false)
        SetEntityCollision(previewProp, false, false)
        
        if Config.EnableDebug then
            print('[Crafting] Preview prop created successfully')
        end
        return true
    end
    
    print('[Crafting] ERROR: Failed to create preview prop for model: ' .. tostring(model))
    return false
end

RegisterNetEvent('crafting:admin:createStation', function(stationType)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local stationConfig = Config.StationTypes[stationType]
    if not stationConfig then
        ShowNotification('Error', 'Invalid station type', 'error')
        return
    end
    
    -- Build prop options from config
    local propOptions = {}
    for _, propData in ipairs(stationConfig.props) do
        table.insert(propOptions, {value = propData.model, label = propData.label})
    end
    
    local input = lib.inputDialog('Create ' .. stationConfig.label, {
        {
            type = 'input',
            label = 'Station Label',
            description = 'Name for this station',
            default = stationConfig.label,
            required = true
        },
        {
            type = 'select',
            label = 'Prop Model',
            description = 'Physical object to spawn',
            options = propOptions,
            default = stationConfig.defaultProp
        },
        {
            type = 'checkbox',
            label = 'Show on Map',
            description = 'Display blip on map',
            checked = false
        }
    })
    
    if not input then return end
    
    local stationLabel = input[1]
    local selectedProp = input[2]
    local showBlip = input[3]
    
    -- Initialize preview
    previewHeading = heading
    previewHeight = 0.0
    isPlacingStation = true
    
    -- Create initial preview
    if not UpdatePreviewProp(selectedProp, pCoords, previewHeading, previewHeight) then
        ShowNotification('Error', 'Failed to load prop model', 'error')
        isPlacingStation = false
        return
    end
    
    ShowNotification('Prop Preview', 'Use Arrow Keys to rotate\nPage Up/Down for height\nEnter to confirm, Backspace to cancel', 'info')
    
    -- Preview loop
    CreateThread(function()
        while isPlacingStation do
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            -- Disable controls
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)  -- Look Left/Right
            EnableControlAction(0, 2, true)  -- Look Up/Down
            EnableControlAction(0, 200, true) -- Pause menu
            
            -- Rotation controls
            if IsControlPressed(0, 174) then -- Left Arrow
                previewHeading = previewHeading + 2.0
                if previewHeading >= 360.0 then previewHeading = previewHeading - 360.0 end
            elseif IsControlPressed(0, 175) then -- Right Arrow
                previewHeading = previewHeading - 2.0
                if previewHeading < 0.0 then previewHeading = previewHeading + 360.0 end
            end
            
            -- Height controls
            if IsControlPressed(0, 10) then -- Page Up
                previewHeight = previewHeight + 1
                if previewHeight > 20 then previewHeight = 20 end
            elseif IsControlPressed(0, 11) then -- Page Down
                previewHeight = previewHeight - 1
                if previewHeight < -20 then previewHeight = -20 end
            end
            
            -- Update preview prop position and rotation
            if previewProp and DoesEntityExist(previewProp) then
                local offset = vector3(0.0, 0.0, previewHeight / 10.0 - 1.0)
                local propCoords = vector3(
                    coords.x + offset.x,
                    coords.y + offset.y,
                    coords.z + offset.z
                )
                SetEntityCoords(previewProp, propCoords.x, propCoords.y, propCoords.z, false, false, false, false)
                SetEntityHeading(previewProp, previewHeading)
            end
            
            -- Display help text
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(
                string.format(
                    'Rotation: %.1f° | Height: %.1f~n~'
                    ..'~INPUT_MOVE_LR~ Rotate | ~INPUT_REPLAY_PAGEUP~ ~INPUT_REPLAY_PAGEDOWN~ Height~n~'
                    ..'~INPUT_FRONTEND_ACCEPT~ Confirm | ~INPUT_FRONTEND_CANCEL~ Cancel',
                    previewHeading,
                    previewHeight / 10.0
                )
            )
            EndTextCommandDisplayHelp(0, false, true, -1)
            
            -- Confirm placement
            if IsControlJustPressed(0, 191) then -- Enter
                break
            end
            
            -- Cancel placement
            if IsControlJustPressed(0, 194) then -- Backspace
                CleanupPreviewProp()
                isPlacingStation = false
                ShowNotification('Cancelled', 'Station placement cancelled', 'info')
                return
            end
            
            Wait(0)
        end
        
        -- Confirmed placement
        isPlacingStation = false
        local finalCoords = GetEntityCoords(PlayerPedId())
        
        local stationData = {
            type = stationType,
            coords = vector3(finalCoords.x, finalCoords.y, finalCoords.z),
            heading = previewHeading,
            blip = showBlip,
            label = stationLabel,
            prop = selectedProp,
            propOffset = vector3(0.0, 0.0, previewHeight / 10.0 - 1.0)
        }
        
        CleanupPreviewProp()
        
        local confirmInput = lib.alertDialog({
            header = 'Confirm Station Placement',
            content = string.format(
                'Station: %s\nProp: %s\nRotation: %.1f°\nHeight: %.1f\n\nSave this station?',
                stationData.label,
                stationData.prop,
                stationData.heading,
                previewHeight / 10.0
            ),
            centered = true,
            cancel = true
        })
        
        if confirmInput ~= 'confirm' then
            ShowNotification('Cancelled', 'Station creation cancelled', 'info')
            return
        end
        
        ShowNotification('Crafting Station', 'Saving station...', 'info')
        
        lib.callback('crafting:admin:saveStation', false, function(success)
            if success then
                ShowNotification('Success', 'Crafting station created!', 'success')
            else
                ShowNotification('Error', 'Failed to create station', 'error')
            end
        end, stationData)
    end)
end)

-- ====================== ADMIN: MANAGE STATIONS ======================
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
        
        -- Quick create buttons
        table.insert(contextMenu, {
            title = '➕ Create Station Here',
            description = 'Select a station type',
            icon = 'fa-solid fa-plus',
            arrow = true,
            onSelect = function()
                local typeOptions = {}
                for typeId, typeConfig in pairs(Config.StationTypes) do
                    table.insert(typeOptions, {value = typeId, label = typeConfig.label})
                end
                
                local input = lib.inputDialog('Select Station Type', {
                    {type = 'select', label = 'Station Type', options = typeOptions, required = true}
                })
                
                if input and input[1] then
                    TriggerEvent('crafting:admin:createStation', input[1])
                end
            end
        })
        
        table.insert(contextMenu, {title = '━━━━━━━━━━━━━━━━', disabled = true})
        
        -- Group by type
        local grouped = {}
        for _, station in ipairs(allStations) do
            if not grouped[station.type] then
                grouped[station.type] = {}
            end
            table.insert(grouped[station.type], station)
        end
        
        for stationType, stations in pairs(grouped) do
            local stationConfig = Config.StationTypes[stationType]
            if stationConfig then
                table.insert(contextMenu, {
                    title = stationConfig.label .. ' (' .. #stations .. ')',
                    icon = stationConfig.icon,
                    arrow = true,
                    onSelect = function()
                        OpenStationTypeMenu(stationType, stations)
                    end
                })
            end
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
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    
    for _, station in ipairs(stations) do
        local dist = #(pCoords - station.coords)
        local distText = string.format('%.1fm away', dist)
        
        table.insert(contextMenu, {
            title = station.label,
            description = distText .. (station.dynamic and ' • Dynamic' or ' • Config'),
            icon = station.dynamic and 'fa-solid fa-database' or 'fa-solid fa-file',
            arrow = station.dynamic,
            onSelect = station.dynamic and function()
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
            icon = 'fa-solid fa-location-dot',
            onSelect = function()
                SetEntityCoords(PlayerPedId(), station.coords.x, station.coords.y, station.coords.z)
                ShowNotification('Teleport', 'Teleported!', 'success')
            end
        },
        {
            title = '📍 Set Waypoint',
            icon = 'fa-solid fa-map-pin',
            onSelect = function()
                SetNewWaypoint(station.coords.x, station.coords.y)
                ShowNotification('Waypoint', 'Waypoint set', 'success')
            end
        },
        {
            title = '🗑️ Delete Station',
            icon = 'fa-solid fa-trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Delete Station',
                    content = 'Are you sure? This cannot be undone.',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    lib.callback('crafting:admin:deleteStation', false, function(success)
                        if success then
                            ShowNotification('Success', 'Station deleted', 'success')
                        else
                            ShowNotification('Error', 'Failed to delete', 'error')
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
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0
    
    for i, station in ipairs(dynamicStations) do
        local dist = #(pCoords - station.coords)
        if dist < closestDist then
            closestDist = dist
            closest = station
        end
    end
    
    if not closest or closestDist > 10.0 then
        ShowNotification('Error', 'No dynamic station within 10m', 'error')
        return
    end
    
    local confirm = lib.alertDialog({
        header = 'Delete Station',
        content = 'Delete "' .. closest.label .. '"?',
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        lib.callback('crafting:admin:deleteStation', false, function(success)
            if success then
                ShowNotification('Success', 'Station deleted', 'success')
            else
                ShowNotification('Error', 'Failed to delete', 'error')
            end
        end, closest.id)
    end
end)

-- ====================== EVENTS ======================
RegisterNetEvent('crafting:updateStations', function(newDynamicStations)
    dynamicStations = newDynamicStations
    SetupStations()
end)

RegisterNetEvent('crafting:craftResult', function(success, message, xpGained, levelUp, newLevel, xpBonuses, quality)
    if success then
        local description = message
        if xpGained then
            description = description .. '\n+' .. xpGained .. ' XP'
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
        duration = 5000
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetupStations()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ClearAllProps()
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
    craftingBlips = {}
end)

-- ====================== INITIALIZATION ======================
CreateThread(function()
    while not QBCore do Wait(100) end
    while not QBCore.Functions.GetPlayerData().citizenid do Wait(100) end
    SetupStations()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CleanupPreviewProp()
    ClearAllProps()
    for _, blip in ipairs(craftingBlips) do
        RemoveBlip(blip)
    end
end)

-- ====================== TEST COMMANDS ======================
RegisterCommand('testprop', function(source, args)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local propModel = args[1] or 'prop_tool_bench02'
    
    print('=========================================')
    print('[Test] Attempting to spawn test prop: ' .. propModel)
    print('[Test] Player coords: ' .. tostring(coords))
    print('=========================================')
    
    local testProp = SpawnProp(propModel, coords + vector3(0.0, 2.0, 0.0), heading, vector3(0.0, 0.0, 0.0))
    
    if testProp then
        print('[Test] SUCCESS - Prop spawned with entity ID: ' .. testProp)
        print('[Test] Prop exists: ' .. tostring(DoesEntityExist(testProp)))
        print('[Test] Prop coords: ' .. tostring(GetEntityCoords(testProp)))
        print('=========================================')
        
        -- Delete after 10 seconds
        SetTimeout(10000, function()
            if DoesEntityExist(testProp) then
                DeleteEntity(testProp)
                print('[Test] Test prop deleted after 10 seconds')
            end
        end)
    else
        print('[Test] FAILED - Could not spawn prop')
        print('=========================================')
    end
end)

RegisterCommand('listprops', function()
    print('=========================================')
    print('[Crafting] Current spawned props:')
    local count = 0
    for index, prop in pairs(craftingProps) do
        count = count + 1
        print(string.format('[%s] Entity ID: %s | Exists: %s', 
            tostring(index), 
            tostring(prop), 
            tostring(DoesEntityExist(prop))
        ))
    end
    print('[Crafting] Total props: ' .. count)
    print('=========================================')
end)

RegisterCommand('reloadstations', function()
    print('[Crafting] Reloading all stations...')
    SetupStations()
    print('[Crafting] Stations reloaded!')
end)
