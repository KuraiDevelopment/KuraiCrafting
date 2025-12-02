local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']

local function OpenCraftMenuAtStation(station)
    -- fetch available recipes from server
    lib.callback('bldr_crafting:getAvailableRecipes', false, function(recipes)
        local items = {}
        for id, recipe in pairs(recipes) do
            items[#items+1] = {id = id, title = recipe.label, description = ('Requires lvl %d'):format(recipe.requiredLevel), recipe = recipe}
        end
        if #items == 0 then
            lib.notify({title='Crafting', description='No recipes available', type='info'})
            return
        end

        -- Simple inputDialog to choose and amount
        local choices = {}
        for _, it in ipairs(items) do
            choices[#choices+1] = {value = it.id, text = it.title .. ' - ' .. it.description}
        end

        lib.inputDialog('Select Recipe', {
            {type='select', label='Recipe', name='recipe', options = choices},
            {type='input', label='Amount', name='amount', default='1'}
        }, function(values)
            if not values then return end
            local recipeId = values.recipe
            local amount = tonumber(values.amount) or 1
            -- start progress and tell server to validate+perform
            local recipe = CraftingRecipes[recipeId]
            if not recipe then lib.notify({title='Crafting', description='Invalid recipe', type='error'}) return end

            -- show progress bar using ox_lib skill check or simple wait
            lib.notify({title='Crafting', description=('Crafting %s x%d'):format(recipe.label, amount), type='info'})
            -- perform client-side delay for immersion (server will validate and actually remove/give)
            local totalTime = recipe.time * amount
            local start = GetGameTimer()
            while GetGameTimer() - start < totalTime do
                Citizen.Wait(500)
            end

            TriggerServerEvent('bldr_crafting:requestCraft', recipeId, amount)
        end)
    end)
end

-- add ox_target options for each station
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
    while true do
        Citizen.Wait(1500)
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        for _, station in pairs(Config.CraftingStations) do
            if #(pcoords - station.coords) < Config.CraftingDistance then
                lib.showTextUI('[E] - Open Crafting')
                if IsControlJustReleased(0, 38) then -- E
                    lib.hideTextUI()
                    OpenCraftMenuAtStation(station)
                end
                break
            else
                lib.hideTextUI()
            end
        end
    end
end)

-- Clean up UI when resource stops
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    lib.hideTextUI()
end)
