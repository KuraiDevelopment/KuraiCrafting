local QBCore = exports['qb-core']:GetCoreObject()

-- ====================== PLAYER DATA CACHE ======================
local PlayerData = {}

local function InitializePlayerData(source)
    if PlayerData[source] then return end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if Config.UseMySQL then
        MySQL.query('SELECT * FROM crafting_progression WHERE citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                PlayerData[source] = {
                    level = result[1].level or 0,
                    xp = result[1].xp or 0,
                    totalCrafted = result[1].total_crafted or 0,
                    lastCraft = {},
                    craftStreak = {}
                }
            else
                -- Create new entry
                MySQL.insert('INSERT INTO crafting_progression (citizenid, level, xp, total_crafted) VALUES (?, ?, ?, ?)',
                    {citizenid, 0, 0, 0})
                
                PlayerData[source] = {
                    level = 0,
                    xp = 0,
                    totalCrafted = 0,
                    lastCraft = {},
                    craftStreak = {}
                }
            end
        end)
    else
        -- Fallback to metadata
        local metadata = Player.PlayerData.metadata or {}
        PlayerData[source] = {
            level = metadata[Config.ProgressionDataKey] or 0,
            xp = metadata[Config.CraftingXPKey] or 0,
            totalCrafted = metadata.total_crafted or 0,
            lastCraft = {},
            craftStreak = {}
        }
    end
end

local function SavePlayerData(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not PlayerData[source] then return end
    
    local citizenid = Player.PlayerData.citizenid
    local data = PlayerData[source]
    
    if Config.UseMySQL then
        MySQL.update('UPDATE crafting_progression SET level = ?, xp = ?, total_crafted = ? WHERE citizenid = ?',
            {data.level, data.xp, data.totalCrafted, citizenid})
    else
        Player.Functions.SetMetaData(Config.ProgressionDataKey, data.level)
        Player.Functions.SetMetaData(Config.CraftingXPKey, data.xp)
        Player.Functions.SetMetaData('total_crafted', data.totalCrafted)
    end
end

-- ====================== UTILITY FUNCTIONS ======================
local function GetPlayerCraftingData(source)
    if not PlayerData[source] then
        InitializePlayerData(source)
        Wait(100) -- Give time for DB query
    end
    return PlayerData[source] or {level = 0, xp = 0, totalCrafted = 0, lastCraft = {}, craftStreak = {}}
end

local function CalculateXPForNextLevel(currentLevel)
    -- Formula: (level^1.5) * 100 + 200
    return math.floor((currentLevel ^ 1.5) * 100 + 200)
end

local function GetProgressionTitle(level)
    local title = 'Novice'
    for _, tier in ipairs(Config.Progression) do
        if level >= tier.level then
            title = tier.label
        else
            break
        end
    end
    return title
end

local function HasRequiredTool(Player, toolName)
    if not toolName then return true end
    local item = Player.Functions.GetItemByName(toolName)
    return item and item.amount > 0
end

local function CheckIngredients(Player, ingredients, amount)
    for _, ing in ipairs(ingredients) do
        local item = Player.Functions.GetItemByName(ing.item)
        if not item or item.amount < (ing.count * amount) then
            return false, ing.item
        end
    end
    return true
end

local function RemoveIngredients(Player, ingredients, amount)
    for _, ing in ipairs(ingredients) do
        Player.Functions.RemoveItem(ing.item, ing.count * amount)
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[ing.item], 'remove', ing.count * amount)
    end
end

local function GiveResult(Player, result, amount, quality)
    local itemName = result.item
    local itemCount = result.count * amount
    
    -- Apply quality suffix if applicable
    if quality and quality ~= 'normal' then
        -- Check if item has quality variants (you may need to adjust item names)
        -- For now, we'll just increase count slightly for higher quality
        if quality == 'fine' then
            itemCount = math.ceil(itemCount * 1.1)
        elseif quality == 'excellent' then
            itemCount = math.ceil(itemCount * 1.25)
        end
    end
    
    Player.Functions.AddItem(itemName, itemCount)
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[itemName], 'add', itemCount)
    
    return itemCount
end

local function CalculateXPGain(recipe, amount, Player, recipeId)
    local data = GetPlayerCraftingData(Player.PlayerData.source)
    local baseXP = recipe.xp * amount
    local multiplier = Config.XPMultipliers.base
    
    -- Streak bonus (same recipe crafted consecutively)
    if data.craftStreak[recipeId] then
        local streakCount = math.min(data.craftStreak[recipeId], 10)
        multiplier = multiplier + (streakCount * Config.XPMultipliers.streakBonus)
    end
    
    -- First time bonus (check if crafted before in stats)
    -- For simplicity, we'll skip this check for now
    
    return math.floor(baseXP * multiplier)
end

local function AwardXP(source, xpAmount)
    local data = GetPlayerCraftingData(source)
    local oldLevel = data.level
    
    data.xp = data.xp + xpAmount
    
    -- Check for level up
    local leveledUp = false
    local newLevel = data.level
    
    while true do
        local xpNeeded = CalculateXPForNextLevel(data.level)
        if data.xp >= xpNeeded then
            data.xp = data.xp - xpNeeded
            data.level = data.level + 1
            leveledUp = true
            newLevel = data.level
        else
            break
        end
    end
    
    SavePlayerData(source)
    
    return leveledUp, newLevel, oldLevel
end

local function DetermineQuality(recipe)
    if not Config.QualitySystem or not recipe.canProduceQuality then
        return 'normal'
    end
    
    local roll = math.random(100)
    
    if roll >= 95 then
        return 'excellent'
    elseif roll >= 75 then
        return 'fine'
    else
        return 'normal'
    end
end

local function UpdateCraftStreak(source, recipeId)
    local data = GetPlayerCraftingData(source)
    
    -- Reset other streaks
    for id, _ in pairs(data.craftStreak) do
        if id ~= recipeId then
            data.craftStreak[id] = 0
        end
    end
    
    -- Increment current streak
    data.craftStreak[recipeId] = (data.craftStreak[recipeId] or 0) + 1
end

local function RecordCraftStat(source, recipeId, amount, success)
    if not Config.UseMySQL then return end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.insert('INSERT INTO crafting_stats (citizenid, recipe_id, amount, success, timestamp) VALUES (?, ?, ?, ?, NOW())',
        {citizenid, recipeId, amount, success and 1 or 0})
end

-- ====================== CALLBACKS ======================
lib.callback.register('crafting:getPlayerLevel', function(source)
    local data = GetPlayerCraftingData(source)
    return data.level
end)

lib.callback.register('crafting:getAvailableRecipes', function(source, stationType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local data = GetPlayerCraftingData(source)
    local playerLevel = data.level
    
    -- Get station configuration
    local stationConfig = Config.StationTypes[stationType]
    if not stationConfig then return nil end
    
    -- Filter recipes by station categories and player level
    local availableRecipes = {}
    
    for id, recipe in pairs(CraftingRecipes) do
        -- Check if recipe category is available at this station
        local categoryAvailable = false
        for _, cat in ipairs(stationConfig.categories) do
            if cat == recipe.category then
                categoryAvailable = true
                break
            end
        end
        
        if categoryAvailable and playerLevel >= recipe.requiredLevel then
            availableRecipes[id] = recipe
        end
    end
    
    return {
        recipes = availableRecipes,
        level = playerLevel,
        xp = data.xp,
        nextLevelXP = CalculateXPForNextLevel(playerLevel),
        title = GetProgressionTitle(playerLevel)
    }
end)

-- ====================== EVENTS ======================
RegisterNetEvent('crafting:attemptCraft', function(recipeId, amount, stationType)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Validate recipe
    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        TriggerClientEvent('crafting:craftResult', source, false, 'Invalid recipe!')
        return
    end
    
    -- Validate amount
    if amount < 1 or amount > Config.MaxCraftAmount then
        TriggerClientEvent('crafting:craftResult', source, false, 'Invalid amount!')
        return
    end
    
    -- Get player data
    local data = GetPlayerCraftingData(source)
    
    -- Check level requirement
    if data.level < recipe.requiredLevel then
        TriggerClientEvent('crafting:craftResult', source, false, 'Your crafting level is too low!')
        return
    end
    
    -- Check station type allows this recipe
    local stationConfig = Config.StationTypes[stationType]
    if not stationConfig then
        TriggerClientEvent('crafting:craftResult', source, false, 'Invalid crafting station!')
        return
    end
    
    local categoryAllowed = false
    for _, cat in ipairs(stationConfig.categories) do
        if cat == recipe.category then
            categoryAllowed = true
            break
        end
    end
    
    if not categoryAllowed then
        TriggerClientEvent('crafting:craftResult', source, false, 'This station cannot craft that item!')
        return
    end
    
    -- Check for required tool
    if Config.RequireTools and not HasRequiredTool(Player, recipe.requiredTool) then
        TriggerClientEvent('crafting:craftResult', source, false, 'You need a ' .. recipe.requiredTool .. ' to craft this!')
        return
    end
    
    -- Check ingredients
    local hasIngredients, missingItem = CheckIngredients(Player, recipe.ingredients, amount)
    if not hasIngredients then
        TriggerClientEvent('crafting:craftResult', source, false, 'Missing ingredient: ' .. missingItem)
        return
    end
    
    -- Check for failure (random chance)
    local failed = false
    if Config.FailureChance > 0 then
        local failRoll = math.random()
        if failRoll < (recipe.failureChance or Config.FailureChance) then
            failed = true
        end
    end
    
    -- Remove ingredients
    RemoveIngredients(Player, recipe.ingredients, amount)
    
    if failed then
        -- Craft failed, items consumed
        TriggerClientEvent('crafting:craftResult', source, false, 'Crafting failed! Materials were lost.')
        RecordCraftStat(source, recipeId, amount, false)
        return
    end
    
    -- Determine quality
    local quality = DetermineQuality(recipe)
    
    -- Give result
    local actualCount = GiveResult(Player, recipe.result, amount, quality)
    
    -- Calculate and award XP
    local xpGained = CalculateXPGain(recipe, amount, Player, recipeId)
    local leveledUp, newLevel, oldLevel = AwardXP(source, xpGained)
    
    -- Update statistics
    data.totalCrafted = data.totalCrafted + actualCount
    UpdateCraftStreak(source, recipeId)
    SavePlayerData(source)
    RecordCraftStat(source, recipeId, amount, true)
    
    -- Build success message
    local message = 'Crafted ' .. actualCount .. 'x ' .. recipe.label
    if quality ~= 'normal' then
        message = message .. ' (' .. quality .. ' quality!)'
    end
    
    -- Notify client
    TriggerClientEvent('crafting:craftResult', source, true, message, xpGained, leveledUp, newLevel)
    
    if leveledUp then
        local title = GetProgressionTitle(newLevel)
        TriggerClientEvent('QBCore:Notify', source, 'Congratulations! You are now a ' .. title .. ' (Level ' .. newLevel .. ')', 'success', 5000)
    end
    
    -- Log
    if Config.EnableDebug then
        print(('[Crafting] %s crafted %dx %s (Level: %d, XP: +%d)'):format(
            Player.PlayerData.citizenid, amount, recipeId, data.level, xpGained))
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    InitializePlayerData(source)
end)

AddEventHandler('playerDropped', function()
    local source = source
    if PlayerData[source] then
        SavePlayerData(source)
        PlayerData[source] = nil
    end
end)

-- ====================== DYNAMIC STATION MANAGEMENT ======================
local DynamicStations = {}

local function LoadDynamicStations()
    if not Config.UseMySQL then return end
    
    MySQL.query('SELECT * FROM crafting_stations', {}, function(result)
        if result then
            for _, station in ipairs(result) do
                table.insert(DynamicStations, {
                    id = station.id,
                    type = station.station_type,
                    coords = vector3(station.x, station.y, station.z),
                    heading = station.heading,
                    blip = station.show_blip == 1,
                    label = station.label,
                    dynamic = true
                })
            end
            TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
            if Config.EnableDebug then
                print('[Crafting] Loaded ' .. #DynamicStations .. ' dynamic stations from database')
            end
        end
    end)
end

local function SaveStation(stationData)
    if not Config.UseMySQL then return false end
    
    local result = MySQL.insert.await('INSERT INTO crafting_stations (station_type, x, y, z, heading, show_blip, label, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {stationData.type, stationData.coords.x, stationData.coords.y, stationData.coords.z, stationData.heading, stationData.blip and 1 or 0, stationData.label, stationData.createdBy})
    
    if result then
        stationData.id = result
        stationData.dynamic = true
        table.insert(DynamicStations, stationData)
        TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
        return true
    end
    return false
end

local function DeleteStation(stationId)
    if not Config.UseMySQL then return false end
    
    MySQL.query('DELETE FROM crafting_stations WHERE id = ?', {stationId}, function(result)
        if result then
            for i, station in ipairs(DynamicStations) do
                if station.id == stationId then
                    table.remove(DynamicStations, i)
                    break
                end
            end
            TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
            return true
        end
    end)
    return false
end

-- Initialize dynamic stations on resource start
CreateThread(function()
    Wait(1000) -- Wait for database
    LoadDynamicStations()
end)

-- ====================== COMMANDS ======================
QBCore.Commands.Add('craftinglevel', 'Check your crafting level', {}, false, function(source)
    local data = GetPlayerCraftingData(source)
    local title = GetProgressionTitle(data.level)
    local nextXP = CalculateXPForNextLevel(data.level)
    
    TriggerClientEvent('QBCore:Notify', source, 
        ('Crafting Level: %d (%s)\nXP: %d / %d\nTotal Crafted: %d'):format(
            data.level, title, data.xp, nextXP, data.totalCrafted
        ), 'inform', 7000)
end)

QBCore.Commands.Add('setcraftinglevel', 'Set player crafting level (Admin)', {
    {name = 'id', help = 'Player ID'},
    {name = 'level', help = 'Level to set'}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local level = tonumber(args[2])
    
    if not targetId or not level then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid arguments', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local data = GetPlayerCraftingData(targetId)
    data.level = level
    data.xp = 0
    SavePlayerData(targetId)
    
    TriggerClientEvent('QBCore:Notify', targetId, 'Your crafting level was set to ' .. level, 'success')
    TriggerClientEvent('QBCore:Notify', source, 'Set crafting level to ' .. level, 'success')
end, Config.AdminGroup)

QBCore.Commands.Add('givecraftxp', 'Give player crafting XP (Admin)', {
    {name = 'id', help = 'Player ID'},
    {name = 'xp', help = 'Amount of XP'}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local xp = tonumber(args[2])
    
    if not targetId or not xp then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid arguments', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local leveledUp, newLevel = AwardXP(targetId, xp)
    
    TriggerClientEvent('QBCore:Notify', targetId, 'You received ' .. xp .. ' crafting XP!', 'success')
    TriggerClientEvent('QBCore:Notify', source, 'Gave ' .. xp .. ' XP', 'success')
    
    if leveledUp then
        TriggerClientEvent('QBCore:Notify', targetId, 'Level up! Now level ' .. newLevel, 'success')
    end
end, Config.AdminGroup)

-- ====================== STATION MANAGEMENT COMMANDS ======================
QBCore.Commands.Add('addcraftstation', 'Add a crafting station at your location (Admin)', {
    {name = 'type', help = 'Station type: workbench, electronics_bench, weapon_bench, medical_station, cooking_station'}
}, true, function(source, args)
    local stationType = args[1]
    
    if not stationType or not Config.StationTypes[stationType] then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid station type! Use: workbench, electronics_bench, weapon_bench, medical_station, or cooking_station', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Trigger client to get player position and open config menu
    TriggerClientEvent('crafting:admin:createStation', source, stationType)
end, Config.AdminGroup)

QBCore.Commands.Add('managecraftstations', 'Manage crafting stations (Admin)', {}, true, function(source)
    TriggerClientEvent('crafting:admin:openManagement', source)
end, Config.AdminGroup)

QBCore.Commands.Add('deletecraftstation', 'Delete nearest crafting station (Admin)', {}, true, function(source)
    TriggerClientEvent('crafting:admin:deleteNearest', source)
end, Config.AdminGroup)

-- ====================== ADMIN CALLBACKS ======================
lib.callback.register('crafting:admin:saveStation', function(source, stationData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    stationData.createdBy = Player.PlayerData.citizenid
    local success = SaveStation(stationData)
    
    if success then
        if Config.EnableDebug then
            print(('[Crafting] %s created station: %s at %s'):format(
                Player.PlayerData.citizenid, stationData.type, stationData.coords))
        end
    end
    
    return success
end)

lib.callback.register('crafting:admin:deleteStation', function(source, stationId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local success = DeleteStation(stationId)
    
    if success and Config.EnableDebug then
        print(('[Crafting] %s deleted station ID: %d'):format(Player.PlayerData.citizenid, stationId))
    end
    
    return success
end)

lib.callback.register('crafting:admin:getAllStations', function(source)
    local allStations = {}
    
    -- Add config stations
    for i, station in ipairs(Config.CraftingStations) do
        table.insert(allStations, {
            id = 'config_' .. i,
            type = station.type,
            coords = station.coords,
            heading = station.heading,
            blip = station.blip,
            label = station.label,
            dynamic = false
        })
    end
    
    -- Add dynamic stations
    for _, station in ipairs(DynamicStations) do
        table.insert(allStations, station)
    end
    
    return allStations
end)

-- ====================== EXPORTS ======================
exports('GetPlayerCraftingLevel', function(source)
    local data = GetPlayerCraftingData(source)
    return data.level
end)

exports('GetPlayerCraftingXP', function(source)
    local data = GetPlayerCraftingData(source)
    return data.xp
end)

exports('GetPlayerCraftingData', function(source)
    return GetPlayerCraftingData(source)
end)

exports('AddRecipe', function(recipeId, recipeData)
    CraftingRecipes[recipeId] = recipeData
    if Config.EnableDebug then
        print('[Crafting] Added recipe: ' .. recipeId)
    end
end)

exports('RemoveRecipe', function(recipeId)
    CraftingRecipes[recipeId] = nil
    if Config.EnableDebug then
        print('[Crafting] Removed recipe: ' .. recipeId)
    end
end)
