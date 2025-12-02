local QBCore = exports['qb-core']:GetCoreObject()
local oxmysql = exports.oxmysql

-- DB table: bldr_crafting_players (citizenid PK, xp INT, level INT)
-- Load player crafting data on join
AddEventHandler('QBCore:Server:PlayerLoaded', function(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    oxmysql:execute('SELECT xp, level FROM bldr_crafting_players WHERE citizenid = ?', {citizenid}, function(result)
        if result and result[1] then
            Player.Functions.SetMetaData(Config.ProgressionDataKey, tonumber(result[1].level) or 0)
            Player.Functions.SetMetaData('_crafting_xp', tonumber(result[1].xp) or 0)
        else
            -- create row
            oxmysql:insert('INSERT INTO bldr_crafting_players (citizenid, xp, level) VALUES (?, ?, ?)', {citizenid, 0, 0})
            Player.Functions.SetMetaData(Config.ProgressionDataKey, 0)
            Player.Functions.SetMetaData('_crafting_xp', 0)
        end
    end)
end)

-- Save on resource stop and player logout
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for _, player in pairs(QBCore.Functions.GetPlayers()) do
        local Ply = QBCore.Functions.GetPlayer(player)
        if Ply then
            local citizenid = Ply.PlayerData.citizenid
            local meta = Ply.PlayerData.metadata or {}
            local xp = meta._crafting_xp or 0
            local lvl = meta[Config.ProgressionDataKey] or 0
            oxmysql:execute('UPDATE bldr_crafting_players SET xp = ?, level = ? WHERE citizenid = ?', {xp, lvl, citizenid})
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    if not Ply then return end
    local citizenid = Ply.PlayerData.citizenid
    local meta = Ply.PlayerData.metadata or {}
    local xp = meta._crafting_xp or 0
    local lvl = meta[Config.ProgressionDataKey] or 0
    oxmysql:execute('UPDATE bldr_crafting_players SET xp = ?, level = ? WHERE citizenid = ?', {xp, lvl, citizenid})
end)

-- Utility: get player's crafting level from metadata
local function GetPlayerCraftLevel(player)
    local metadata = player.PlayerData.metadata or {}
    return metadata[Config.ProgressionDataKey] or 0
end

-- Ensure recipe exists and player can craft amount
local function ValidateCraft(player, recipeId, amount)
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return false, 'invalid_recipe' end
    if type(amount) ~= 'number' or amount < 1 or amount > Config.MaxCraftAmount then return false, 'invalid_amount' end

    local level = GetPlayerCraftLevel(player)
    if level < recipe.requiredLevel then return false, 'insufficient_level' end

    -- Check player items via server inventory
    for _, req in pairs(recipe.ingredients) do
        local invItem = player.Functions.GetItemByName(req.item)
        if not invItem or invItem.amount < (req.count * amount) then
            return false, 'missing_ingredients'
        end
    end

    return true
end

-- Remove ingredients and give item(s), award XP
local function PerformCraft(player, recipeId, amount)
    local recipe = CraftingRecipes[recipeId]

    -- Double-check inventory before removing
    for _, req in pairs(recipe.ingredients) do
        if not player.Functions.GetItemByName(req.item) or player.Functions.GetItemByName(req.item).amount < (req.count * amount) then
            player.Functions.Notify('Craft failed: missing ingredients', 'error')
            return false
        end
    end

    -- remove ingredients atomically
    for _, req in pairs(recipe.ingredients) do
        player.Functions.RemoveItem(req.item, req.count * amount)
    end

    -- give resulting item
    player.Functions.AddItem(recipeId, amount)

    -- Award XP and bump progression when thresholds met
    local xpGain = (Config.CraftingXP[recipeId] or 1) * amount
    local metadata = player.PlayerData.metadata or {}
    metadata._crafting_xp = (metadata._crafting_xp or 0) + xpGain

    -- Level up logic: next level at (level +1)*Config.XPPerLevel
    local currentLevel = metadata[Config.ProgressionDataKey] or 0
    local xpNeeded = (currentLevel + 1) * (Config.XPPerLevel or 100)
    while metadata._crafting_xp >= xpNeeded do
        metadata._crafting_xp = metadata._crafting_xp - xpNeeded
        currentLevel = currentLevel + 1
        xpNeeded = (currentLevel + 1) * (Config.XPPerLevel or 100)
    end
    metadata[Config.ProgressionDataKey] = currentLevel

    -- persist to DB
    local citizenid = player.PlayerData.citizenid
    local xp = metadata._crafting_xp or 0
    local lvl = metadata[Config.ProgressionDataKey] or 0
    oxmysql:execute('UPDATE bldr_crafting_players SET xp = ?, level = ? WHERE citizenid = ?', {xp, lvl, citizenid})

    -- update player metadata
    player.Functions.SetMetaData(Config.ProgressionDataKey, metadata[Config.ProgressionDataKey])
    player.Functions.SetMetaData('_crafting_xp', metadata._crafting_xp)

    -- notify
    player.Functions.Notify(('Crafted %s x%d'):format(recipe.label, amount), Config.NotifyType)
    return true
end

-- Server callback to request available recipes filtered by player level
QBCore.Functions.CreateCallback('bldr_crafting:getAvailableRecipes', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb({}) return end
    local lvl = GetPlayerCraftLevel(Player)
    local available = {}
    for id, recipe in pairs(CraftingRecipes) do
        if lvl >= recipe.requiredLevel then
            available[id] = recipe
        end
    end
    cb(available)
end)

-- Server event to start craft (client-side does progress/UI)
RegisterNetEvent('bldr_crafting:requestCraft', function(recipeId, amount, stationId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local ok, err = ValidateCraft(Player, recipeId, amount)
    if not ok then
        local map = {
            invalid_recipe = 'Invalid recipe',
            invalid_amount = 'Invalid amount',
            insufficient_level = 'Your crafting level is too low for this recipe',
            missing_ingredients = 'You do not have required ingredients'
        }
        Player.Functions.Notify(map[err] or 'Cannot craft', 'error')
        return
    end

    -- perform craft
    local success = PerformCraft(Player, recipeId, amount)
    if success then
        print(('[bldr_crafting] %s crafted %s x%d at station %s'):format(Player.PlayerData.citizenid, recipeId, amount, tostring(stationId)))
    end
end)

-- Admin command to set player crafting level
QBCore.Commands.Add('setcraft', 'Set crafting level (admin)', {{name='id', help='player id'},{name='level', help='level'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local level = tonumber(args[2])
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player or not level then return end
    Player.Functions.SetMetaData(Config.ProgressionDataKey, level)
    Player.Functions.Notify(('Your crafting level was set to %d'):format(level), 'success')
    -- persist
    local citizenid = Player.PlayerData.citizenid
    local meta = Player.PlayerData.metadata or {}
    local xp = meta._crafting_xp or 0
    oxmysql:execute('UPDATE bldr_crafting_players SET xp = ?, level = ? WHERE citizenid = ?', {xp, level, citizenid})
end, 'admin')

-- Admin exports for placing/removing stations and managing recipes
RegisterNetEvent('bldr_crafting:admin:saveStation', function(station)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Player.PlayerData.job.isboss and not IsPlayerAceAllowed(src, 'admin') then
        return
    end
    -- persist station to DB (simple JSON store in a table 'bldr_crafting_stations')
    oxmysql:execute('INSERT INTO bldr_crafting_stations (name, coords, heading, data) VALUES (?, ?, ?, ?)',{station.name, json.encode(station.coords), station.heading or 0, json.encode(station)})
    TriggerClientEvent('bldr_crafting:admin:stationSaved', src)
end)

RegisterNetEvent('bldr_crafting:admin:deleteStation', function(stationId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Player.PlayerData.job.isboss and not IsPlayerAceAllowed(src, 'admin') then
        return
    end
    oxmysql:execute('DELETE FROM bldr_crafting_stations WHERE id = ?', {stationId})
    TriggerClientEvent('bldr_crafting:admin:stationDeleted', src)
end)

-- Export: get player craft level (server)
exports('GetCraftLevel', function(playerSource)
    local Player = QBCore.Functions.GetPlayer(playerSource)
    if not Player then return 0 end
    return GetPlayerCraftLevel(Player)
end)

