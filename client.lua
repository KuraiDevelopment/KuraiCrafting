local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']
local isUIOpen = false

-- Helper to get player inventory for UI
local function GetPlayerInventory()
    local Player = QBCore.Functions.GetPlayerData()
    local inventory = {}
    
    if Player and Player.items then
        for _, item in pairs(Player.items) do
            if item and item.name and item.amount then
                -- Convert item names to display format
                local displayName = item.label or item.name
                inventory[displayName] = (inventory[displayName] or 0) + item.amount
            end
        end
    end
    
    return inventory
end

-- Helper to transform recipes for UI
local function TransformRecipesForUI(recipes)
    local transformed = {}
    
    for id, recipe in pairs(recipes) do
        local ingredients = {}
        for _, ing in ipairs(recipe.ingredients) do
            table.insert(ingredients, {
                name = ing.item,
                count = ing.count
            })
        end
        
        table.insert(transformed, {
            id = id,
            name = recipe.label,
            description = ('Requires level %d'):format(recipe.requiredLevel),
            ingredients = ingredients,
            craftTime = math.floor((recipe.time or 3000) / 1000), -- Convert ms to seconds
            resultCount = 1,
            requiredLevel = recipe.requiredLevel
        })
    end
    
    return transformed
end

local function OpenCraftMenuAtStation(station)
    if isUIOpen then return end
    
    -- Fetch available recipes from server
    lib.callback('bldr_crafting:getAvailableRecipes', false, function(recipes)
        if not recipes or next(recipes) == nil then
            lib.notify({title='Crafting', description='No recipes available', type='info'})
            return
        end

        local Player = QBCore.Functions.GetPlayerData()
        local playerLevel = Player.metadata and Player.metadata[Config.ProgressionDataKey] or 0
        
        -- Transform data for React UI
        local uiRecipes = TransformRecipesForUI(recipes)
        local inventory = GetPlayerInventory()
        
        -- Open NUI
        SetNuiFocus(true, true)
        isUIOpen = true
        
        SendNUIMessage({
            action = 'openCrafting',
            data = {
                recipes = uiRecipes,
                inventory = inventory,
                playerLevel = playerLevel
            }
        })
    end)
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb('ok')
end)

RegisterNUICallback('craftItem', function(data, cb)
    local recipeId = data.recipeId
    local amount = data.amount or 1
    
    if not recipeId then
        cb('error')
        return
    end
    
    -- Trigger server event to handle crafting
    TriggerServerEvent('bldr_crafting:requestCraft', recipeId, amount)
    
    -- Update inventory in UI after a delay
    Citizen.SetTimeout(1000, function()
        if isUIOpen then
            local inventory = GetPlayerInventory()
            SendNUIMessage({
                action = 'updateInventory',
                data = {
                    inventory = inventory
                }
            })
        end
    end)
    
    cb('ok')
end)

-- Add ox_target options for each station
Citizen.CreateThread(function()
    for _, station in pairs(Config.CraftingStations) do
        exports.ox_target:addBoxZone({
            coords = station.coords,
            size = vector3(1.2,1.2,1.2),
            rotation = station.heading or 0,
            debug = false,
            options = {
                {
                    name = station.name,
                    label = 'Use Workbench',
                    icon = 'fa-solid fa-tools',
                    distance = Config.CraftingDistance,
                    onSelect = function(data)
                        OpenCraftMenuAtStation(station)
                    end
                }
            }
        })
    end
end)

-- Lightweight keybind fallback at nearest station
Citizen.CreateThread(function()
    local textUIShown = false
    while true do
        Citizen.Wait(1500)
        
        if isUIOpen then
            if textUIShown then
                lib.hideTextUI()
                textUIShown = false
            end
            goto continue
        end
        
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local nearStation = false
        
        for _, station in pairs(Config.CraftingStations) do
            if #(pcoords - station.coords) < Config.CraftingDistance then
                nearStation = true
                if not textUIShown then
                    lib.showTextUI('[E] - Open Crafting')
                    textUIShown = true
                end
                
                if IsControlJustReleased(0, 38) then -- E
                    OpenCraftMenuAtStation(station)
                end
                break
            end
        end
        
        if not nearStation and textUIShown then
            lib.hideTextUI()
            textUIShown = false
        end
        
        ::continue::
    end
end)

-- Clean up UI when resource stops
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    if isUIOpen then
        SetNuiFocus(false, false)
        isUIOpen = false
    end
    lib.hideTextUI()
end)

-- Listen for inventory updates from server
RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    if isUIOpen then
        local inventory = GetPlayerInventory()
        SendNUIMessage({
            action = 'updateInventory',
            data = {
                inventory = inventory
            }
        })
    end
end)
