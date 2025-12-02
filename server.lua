-- ============================================================================
-- KURAI.DEV ADVANCED PROGRESSION CRAFTING SYSTEM v3.0
-- Server-side with prop storage, blueprints, specializations
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ====================== DATA CACHES ======================
local PlayerData = {}
local PlayerBlueprints = {}
local PlayerSpecializations = {}
local DynamicStations = {}
local AntiExploitTracker = {}

-- ====================== INITIALIZATION ======================
local function InitializePlayerData(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    
    if Config.UseMySQL then
        local result = MySQL.query.await('SELECT * FROM crafting_progression WHERE citizenid = ?', {citizenid})
        
        if result and result[1] then
            PlayerData[source] = {
                level = result[1].level or 0,
                xp = result[1].xp or 0,
                totalCrafted = result[1].total_crafted or 0,
                craftStreak = {},
                craftedRecipes = {}
            }
        else
            MySQL.insert.await('INSERT INTO crafting_progression (citizenid, level, xp, total_crafted) VALUES (?, ?, ?, ?)',
                {citizenid, 0, 0, 0})
            
            PlayerData[source] = {
                level = 0,
                xp = 0,
                totalCrafted = 0,
                craftStreak = {},
                craftedRecipes = {}
            }
        end
        
        -- Load blueprints
        local blueprints = MySQL.query.await('SELECT recipe_id FROM crafting_blueprints WHERE citizenid = ?', {citizenid})
        PlayerBlueprints[source] = {}
        if blueprints then
            for _, bp in ipairs(blueprints) do
                PlayerBlueprints[source][bp.recipe_id] = true
            end
        end
        
        -- Load specialization
        local spec = MySQL.query.await('SELECT * FROM crafting_specializations WHERE citizenid = ?', {citizenid})
        if spec and spec[1] then
            PlayerSpecializations[source] = {
                type = spec[1].specialization,
                level = spec[1].spec_level or 1,
                xp = spec[1].spec_xp or 0
            }
        end
        
        -- Load crafted recipes
        local craftedBefore = MySQL.query.await('SELECT DISTINCT recipe_id FROM crafting_stats WHERE citizenid = ? AND success = 1', {citizenid})
        if craftedBefore then
            for _, craft in ipairs(craftedBefore) do
                PlayerData[source].craftedRecipes[craft.recipe_id] = true
            end
        end
        
        return true
    end
    
    return false
end

local function SavePlayerData(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not PlayerData[source] then return end
    
    local citizenid = Player.PlayerData.citizenid
    local data = PlayerData[source]
    
    if Config.UseMySQL then
        MySQL.update('UPDATE crafting_progression SET level = ?, xp = ?, total_crafted = ? WHERE citizenid = ?',
            {data.level, data.xp, data.totalCrafted, citizenid})
    end
end

-- ====================== UTILITY FUNCTIONS ======================
local function GetPlayerCraftingData(source)
    if not PlayerData[source] then
        InitializePlayerData(source)
    end
    return PlayerData[source] or {level = 0, xp = 0, totalCrafted = 0, craftStreak = {}, craftedRecipes = {}}
end

local function CalculateXPForNextLevel(currentLevel)
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

-- ====================== BLUEPRINT SYSTEM ======================
local function HasBlueprint(source, recipeId)
    if not Config.EnableBlueprints then return true end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return false end
    if not recipe.requiresBlueprint then return true end
    
    return PlayerBlueprints[source] and PlayerBlueprints[source][recipeId] == true
end

local function UnlockBlueprint(source, recipeId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe or not recipe.requiresBlueprint then return false end
    
    if not PlayerBlueprints[source] then
        PlayerBlueprints[source] = {}
    end
    
    if PlayerBlueprints[source][recipeId] then return false end
    
    PlayerBlueprints[source][recipeId] = true
    
    if Config.UseMySQL then
        MySQL.insert('INSERT INTO crafting_blueprints (citizenid, recipe_id) VALUES (?, ?)',
            {Player.PlayerData.citizenid, recipeId})
    end
    
    return true
end

-- ====================== SPECIALIZATION SYSTEM ======================
local function GetPlayerSpecialization(source)
    return PlayerSpecializations[source]
end

local function SetPlayerSpecialization(source, specType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    if not Config.Specializations[specType] then return false end
    
    local data = GetPlayerCraftingData(source)
    if data.level < Config.SpecializationUnlockLevel then
        return false, 'Level too low'
    end
    
    PlayerSpecializations[source] = {type = specType, level = 1, xp = 0}
    
    if Config.UseMySQL then
        MySQL.query('DELETE FROM crafting_specializations WHERE citizenid = ?', {Player.PlayerData.citizenid})
        MySQL.insert('INSERT INTO crafting_specializations (citizenid, specialization, spec_level, spec_xp) VALUES (?, ?, ?, ?)',
            {Player.PlayerData.citizenid, specType, 1, 0})
    end
    
    return true
end

local function ResetPlayerSpecialization(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    if not Config.AllowSpecializationReset then return false end
    
    if Config.SpecializationResetCost > 0 then
        if Player.PlayerData.money.cash < Config.SpecializationResetCost then
            return false, 'Not enough money'
        end
        Player.Functions.RemoveMoney('cash', Config.SpecializationResetCost, 'specialization-reset')
    end
    
    PlayerSpecializations[source] = nil
    
    if Config.UseMySQL then
        MySQL.query('DELETE FROM crafting_specializations WHERE citizenid = ?', {Player.PlayerData.citizenid})
    end
    
    return true
end

local function GetSpecializationBonus(source, category)
    local spec = PlayerSpecializations[source]
    if not spec or not Config.EnableSpecializations then
        return {xpMult = 1.0, successMult = 1.0, qualityMult = 1.0}
    end
    
    local specConfig = Config.Specializations[spec.type]
    if not specConfig then
        return {xpMult = 1.0, successMult = 1.0, qualityMult = 1.0}
    end
    
    for _, cat in ipairs(specConfig.bonusCategories) do
        if cat == category then
            return {
                xpMult = 1.0 + specConfig.xpBonus,
                successMult = 1.0 + specConfig.successBonus,
                qualityMult = 1.0 + specConfig.qualityBonus
            }
        end
    end
    
    for _, cat in ipairs(specConfig.penaltyCategories) do
        if cat == category then
            return {xpMult = 1.0 - specConfig.xpPenalty, successMult = 1.0, qualityMult = 1.0}
        end
    end
    
    return {xpMult = 1.0, successMult = 1.0, qualityMult = 1.0}
end

-- ====================== TOOL DURABILITY ======================
local function GetToolDurability(Player, toolName)
    if not Config.EnableToolDurability then return 100 end
    
    local items = Player.Functions.GetItemsByName(toolName)
    if not items or #items == 0 then return 0 end
    
    local bestDurability = 0
    for _, item in ipairs(items) do
        local durability = (item.info and item.info.durability) or 100
        if durability > bestDurability then
            bestDurability = durability
        end
    end
    
    return bestDurability
end

local function DegradeTool(Player, toolName, amount)
    if not Config.EnableToolDurability or not toolName then return true end
    
    local items = Player.Functions.GetItemsByName(toolName)
    if not items or #items == 0 then return false end
    
    local bestItem = nil
    local bestDurability = 0
    
    for _, item in ipairs(items) do
        local durability = (item.info and item.info.durability) or 100
        if durability > bestDurability then
            bestDurability = durability
            bestItem = item
        end
    end
    
    if not bestItem then return false end
    
    local newDurability = bestDurability - amount
    
    if newDurability <= 0 then
        Player.Functions.RemoveItem(toolName, 1, bestItem.slot)
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[toolName], 'remove', 1)
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Your ' .. toolName .. ' broke!', 'error')
        return true, true
    else
        local newInfo = bestItem.info or {}
        newInfo.durability = newDurability
        Player.Functions.RemoveItem(toolName, 1, bestItem.slot)
        Player.Functions.AddItem(toolName, 1, nil, newInfo)
        return true, false
    end
end

-- ====================== CRAFTING MECHANICS ======================
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
    end
end

local function CalculateFailureChance(source, recipe)
    local baseChance = recipe.failureChance or Config.BaseFailureChance
    local data = GetPlayerCraftingData(source)
    local specBonus = GetSpecializationBonus(source, recipe.category)
    
    if Config.LevelFailureReduction.enabled then
        local reduction = data.level * Config.LevelFailureReduction.reductionPerLevel
        reduction = math.min(reduction, Config.LevelFailureReduction.maxReduction)
        baseChance = baseChance * (1 - reduction)
    end
    
    baseChance = baseChance / specBonus.successMult
    return math.max(0, baseChance)
end

local function DetermineQuality(source, recipe)
    if not Config.QualitySystem or not recipe.canProduceQuality then
        return 'normal'
    end
    
    local data = GetPlayerCraftingData(source)
    local specBonus = GetSpecializationBonus(source, recipe.category)
    local roll = math.random(100) / 100
    
    local excellentChance = Config.QualityChances.excellent.baseChance + (data.level * Config.QualityChances.excellent.levelBonus)
    excellentChance = excellentChance * specBonus.qualityMult
    
    local fineChance = Config.QualityChances.fine.baseChance + (data.level * Config.QualityChances.fine.levelBonus)
    fineChance = fineChance * specBonus.qualityMult
    
    if roll <= excellentChance then
        return 'excellent'
    elseif roll <= (excellentChance + fineChance) then
        return 'fine'
    end
    return 'normal'
end

local function GiveResult(Player, result, amount, quality)
    local itemCount = result.count * amount
    local metadata = result.metadata or {}
    
    if quality == 'fine' then
        itemCount = math.ceil(itemCount * 1.15)
        metadata.quality = 'fine'
    elseif quality == 'excellent' then
        itemCount = math.ceil(itemCount * 1.30)
        metadata.quality = 'excellent'
    end
    
    if Config.EnableToolDurability and Config.Tools[result.item] then
        metadata.durability = Config.Tools[result.item].maxDurability
    end
    
    if next(metadata) then
        Player.Functions.AddItem(result.item, itemCount, nil, metadata)
    else
        Player.Functions.AddItem(result.item, itemCount)
    end
    
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[result.item], 'add', itemCount)
    return itemCount
end

local function CalculateXPGain(source, recipe, amount, recipeId)
    local data = GetPlayerCraftingData(source)
    local baseXP = recipe.xp * amount
    local multiplier = Config.XPMultipliers.base
    local bonuses = {}
    
    if data.craftStreak[recipeId] then
        local streakCount = math.min(data.craftStreak[recipeId], 10)
        local streakMult = streakCount * Config.XPMultipliers.streakBonus
        multiplier = multiplier + streakMult
    end
    
    if not data.craftedRecipes[recipeId] then
        multiplier = multiplier + Config.XPMultipliers.firstTimeBonus
        table.insert(bonuses, {name = 'First Craft!', value = Config.XPMultipliers.firstTimeBonus})
        data.craftedRecipes[recipeId] = true
    end
    
    local specBonus = GetSpecializationBonus(source, recipe.category)
    multiplier = multiplier * specBonus.xpMult
    
    return math.floor(baseXP * multiplier), bonuses
end

local function AwardXP(source, xpAmount)
    local data = GetPlayerCraftingData(source)
    local oldLevel = data.level
    
    data.xp = data.xp + xpAmount
    
    local leveledUp = false
    while data.xp >= CalculateXPForNextLevel(data.level) do
        data.xp = data.xp - CalculateXPForNextLevel(data.level)
        data.level = data.level + 1
        leveledUp = true
    end
    
    SavePlayerData(source)
    return leveledUp, data.level, oldLevel
end

-- ====================== ANTI-EXPLOIT ======================
local function CheckAntiExploit(source)
    if not Config.AntiExploit.enabled then return true end
    
    local now = os.time()
    if not AntiExploitTracker[source] then
        AntiExploitTracker[source] = {count = 0, windowStart = now}
    end
    
    local tracker = AntiExploitTracker[source]
    if now - tracker.windowStart > 60 then
        tracker.count = 0
        tracker.windowStart = now
    end
    
    tracker.count = tracker.count + 1
    return tracker.count <= Config.AntiExploit.maxCraftsPerMinute
end

-- ====================== STATION VALIDATION ======================
local function ValidateStationProximity(source, stationCoords, stationType)
    if not Config.ServerSideValidation then return true end
    
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - stationCoords)
    
    return distance <= Config.StationProximityCheck
end

-- ====================== CALLBACKS ======================
lib.callback.register('crafting:getPlayerLevel', function(source)
    return GetPlayerCraftingData(source).level
end)

lib.callback.register('crafting:getAvailableRecipes', function(source, stationType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local data = GetPlayerCraftingData(source)
    local stationConfig = Config.StationTypes[stationType]
    if not stationConfig then return nil end
    
    local availableRecipes = {}
    local lockedRecipes = {}
    
    for id, recipe in pairs(CraftingRecipes) do
        local categoryAvailable = false
        for _, cat in ipairs(stationConfig.categories) do
            if cat == recipe.category then
                categoryAvailable = true
                break
            end
        end
        
        if categoryAvailable then
            local hasBlueprint = HasBlueprint(source, id)
            local meetsLevel = data.level >= recipe.requiredLevel
            
            if hasBlueprint and meetsLevel then
                availableRecipes[id] = recipe
            elseif Config.ShowLockedRecipes then
                lockedRecipes[id] = {
                    recipe = recipe,
                    reason = not hasBlueprint and 'blueprint' or 'level'
                }
            end
        end
    end
    
    return {
        recipes = availableRecipes,
        lockedRecipes = lockedRecipes,
        level = data.level,
        xp = data.xp,
        nextLevelXP = CalculateXPForNextLevel(data.level),
        title = GetProgressionTitle(data.level),
        specialization = GetPlayerSpecialization(source),
        totalCrafted = data.totalCrafted
    }
end)

lib.callback.register('crafting:getSpecializations', function(source)
    local data = GetPlayerCraftingData(source)
    return {
        available = Config.Specializations,
        current = GetPlayerSpecialization(source),
        canSelect = data.level >= Config.SpecializationUnlockLevel,
        requiredLevel = Config.SpecializationUnlockLevel,
        canReset = Config.AllowSpecializationReset,
        resetCost = Config.SpecializationResetCost
    }
end)

lib.callback.register('crafting:selectSpecialization', function(source, specType)
    return SetPlayerSpecialization(source, specType)
end)

lib.callback.register('crafting:resetSpecialization', function(source)
    return ResetPlayerSpecialization(source)
end)

lib.callback.register('crafting:getToolDurability', function(source, toolName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    return GetToolDurability(Player, toolName)
end)

-- ====================== CRAFTING EVENT ======================
RegisterNetEvent('crafting:attemptCraft', function(recipeId, amount, stationType, stationCoords)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not CheckAntiExploit(source) then
        TriggerClientEvent('crafting:craftResult', source, false, 'Too many attempts!')
        return
    end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        TriggerClientEvent('crafting:craftResult', source, false, 'Invalid recipe!')
        return
    end
    
    if amount < 1 or amount > Config.MaxCraftAmount then
        TriggerClientEvent('crafting:craftResult', source, false, 'Invalid amount!')
        return
    end
    
    if stationCoords and not ValidateStationProximity(source, stationCoords, stationType) then
        TriggerClientEvent('crafting:craftResult', source, false, 'Not at a valid station!')
        return
    end
    
    local data = GetPlayerCraftingData(source)
    
    if data.level < recipe.requiredLevel then
        TriggerClientEvent('crafting:craftResult', source, false, 'Level too low!')
        return
    end
    
    if not HasBlueprint(source, recipeId) then
        TriggerClientEvent('crafting:craftResult', source, false, 'Blueprint required!')
        return
    end
    
    local stationConfig = Config.StationTypes[stationType]
    if stationConfig then
        local categoryAllowed = false
        for _, cat in ipairs(stationConfig.categories) do
            if cat == recipe.category then
                categoryAllowed = true
                break
            end
        end
        if not categoryAllowed then
            TriggerClientEvent('crafting:craftResult', source, false, 'Wrong station type!')
            return
        end
    end
    
    if recipe.requiredTool then
        local item = Player.Functions.GetItemByName(recipe.requiredTool)
        if not item then
            TriggerClientEvent('crafting:craftResult', source, false, 'Missing tool: ' .. recipe.requiredTool)
            return
        end
    end
    
    local hasIngredients, missingItem = CheckIngredients(Player, recipe.ingredients, amount)
    if not hasIngredients then
        TriggerClientEvent('crafting:craftResult', source, false, 'Missing: ' .. missingItem)
        return
    end
    
    local failureChance = CalculateFailureChance(source, recipe)
    local failed = math.random() < failureChance
    
    RemoveIngredients(Player, recipe.ingredients, amount)
    
    if recipe.requiredTool and recipe.toolDurability then
        DegradeTool(Player, recipe.requiredTool, recipe.toolDurability * amount)
    end
    
    if failed then
        TriggerClientEvent('crafting:craftResult', source, false, 'Crafting failed! Materials lost.')
        return
    end
    
    local quality = DetermineQuality(source, recipe)
    local actualCount = GiveResult(Player, recipe.result, amount, quality)
    local xpGained, xpBonuses = CalculateXPGain(source, recipe, amount, recipeId)
    local leveledUp, newLevel = AwardXP(source, xpGained)
    
    data.totalCrafted = data.totalCrafted + actualCount
    SavePlayerData(source)
    
    local message = 'Crafted ' .. actualCount .. 'x ' .. recipe.label
    if quality ~= 'normal' then
        message = message .. ' (' .. quality:upper() .. '!)'
    end
    
    TriggerClientEvent('crafting:craftResult', source, true, message, xpGained, leveledUp, newLevel, xpBonuses, quality)
    
    if leveledUp then
        TriggerClientEvent('QBCore:Notify', source, 'Level up! Now level ' .. newLevel, 'success')
    end
end)

-- ====================== DYNAMIC STATIONS ======================
local function LoadDynamicStations()
    if not Config.UseMySQL then return end
    
    local result = MySQL.query.await('SELECT * FROM crafting_stations', {})
    
    if result then
        DynamicStations = {}
        for _, station in ipairs(result) do
            table.insert(DynamicStations, {
                id = station.id,
                type = station.station_type,
                coords = vector3(station.x, station.y, station.z),
                heading = station.heading,
                blip = station.show_blip == 1,
                label = station.label,
                prop = station.prop,
                propOffset = vector3(
                    station.prop_offset_x or 0.0,
                    station.prop_offset_y or 0.0,
                    station.prop_offset_z or -1.0
                ),
                dynamic = true
            })
        end
        
        TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
    end
end

lib.callback.register('crafting:admin:saveStation', function(source, stationData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local propOffset = stationData.propOffset or vector3(0.0, 0.0, -1.0)
    
    local result = MySQL.insert.await(
        'INSERT INTO crafting_stations (station_type, x, y, z, heading, show_blip, label, prop, prop_offset_x, prop_offset_y, prop_offset_z, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            stationData.type,
            stationData.coords.x,
            stationData.coords.y,
            stationData.coords.z,
            stationData.heading,
            stationData.blip and 1 or 0,
            stationData.label,
            stationData.prop,
            propOffset.x,
            propOffset.y,
            propOffset.z,
            Player.PlayerData.citizenid
        }
    )
    
    if result then
        stationData.id = result
        stationData.propOffset = propOffset
        stationData.dynamic = true
        table.insert(DynamicStations, stationData)
        TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
        return true
    end
    return false
end)

lib.callback.register('crafting:admin:deleteStation', function(source, stationId)
    local result = MySQL.query.await('DELETE FROM crafting_stations WHERE id = ?', {stationId})
    
    if result and result.affectedRows > 0 then
        for i, station in ipairs(DynamicStations) do
            if station.id == stationId then
                table.remove(DynamicStations, i)
                break
            end
        end
        TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
        return true
    end
    return false
end)

lib.callback.register('crafting:admin:getAllStations', function(source)
    local allStations = {}
    
    for i, station in ipairs(Config.CraftingStations) do
        table.insert(allStations, {
            id = 'config_' .. i,
            type = station.type,
            coords = station.coords,
            heading = station.heading,
            blip = station.blip,
            label = station.label,
            prop = station.prop,
            dynamic = false
        })
    end
    
    for _, station in ipairs(DynamicStations) do
        table.insert(allStations, station)
    end
    
    return allStations
end)

-- ====================== PLAYER EVENTS ======================
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    InitializePlayerData(source)
end)

AddEventHandler('playerDropped', function()
    local source = source
    if PlayerData[source] then
        SavePlayerData(source)
        PlayerData[source] = nil
        PlayerBlueprints[source] = nil
        PlayerSpecializations[source] = nil
        AntiExploitTracker[source] = nil
    end
end)

-- ====================== COMMANDS ======================
QBCore.Commands.Add('craftinglevel', 'Check crafting level', {}, false, function(source)
    local data = GetPlayerCraftingData(source)
    local title = GetProgressionTitle(data.level)
    TriggerClientEvent('QBCore:Notify', source, 'Level ' .. data.level .. ' ' .. title .. ' | XP: ' .. data.xp .. '/' .. CalculateXPForNextLevel(data.level), 'inform')
end)

QBCore.Commands.Add('setcraftinglevel', 'Set crafting level (Admin)', {{name = 'id', help = 'Player ID'}, {name = 'level', help = 'Level'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local level = tonumber(args[2])
    if not targetId or not level then return end
    
    local data = GetPlayerCraftingData(targetId)
    data.level = level
    data.xp = 0
    SavePlayerData(targetId)
    
    TriggerClientEvent('QBCore:Notify', targetId, 'Level set to ' .. level, 'success')
    TriggerClientEvent('QBCore:Notify', source, 'Set level to ' .. level, 'success')
end, Config.AdminGroup)

QBCore.Commands.Add('givecraftxp', 'Give crafting XP (Admin)', {{name = 'id', help = 'Player ID'}, {name = 'xp', help = 'XP'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local xp = tonumber(args[2])
    if not targetId or not xp then return end
    
    AwardXP(targetId, xp)
    TriggerClientEvent('QBCore:Notify', targetId, 'Received ' .. xp .. ' XP', 'success')
end, Config.AdminGroup)

QBCore.Commands.Add('giveblueprint', 'Give blueprint (Admin)', {{name = 'id', help = 'Player ID'}, {name = 'recipe', help = 'Recipe ID'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local recipeId = args[2]
    if not targetId or not recipeId then return end
    
    if UnlockBlueprint(targetId, recipeId) then
        local recipe = CraftingRecipes[recipeId]
        TriggerClientEvent('QBCore:Notify', targetId, 'Blueprint unlocked: ' .. (recipe and recipe.label or recipeId), 'success')
    end
end, Config.AdminGroup)

QBCore.Commands.Add('addcraftstation', 'Add crafting station (Admin)', {{name = 'type', help = 'Station type'}}, true, function(source, args)
    local stationType = args[1]
    if not stationType or not Config.StationTypes[stationType] then
        local types = {}
        for k in pairs(Config.StationTypes) do table.insert(types, k) end
        TriggerClientEvent('QBCore:Notify', source, 'Types: ' .. table.concat(types, ', '), 'error')
        return
    end
    TriggerClientEvent('crafting:admin:createStation', source, stationType)
end, Config.AdminGroup)

QBCore.Commands.Add('managecraftstations', 'Manage stations (Admin)', {}, true, function(source)
    TriggerClientEvent('crafting:admin:openManagement', source)
end, Config.AdminGroup)

QBCore.Commands.Add('deletecraftstation', 'Delete nearest station (Admin)', {}, true, function(source)
    TriggerClientEvent('crafting:admin:deleteNearest', source)
end, Config.AdminGroup)

-- ====================== EXPORTS ======================
exports('GetPlayerCraftingLevel', function(source) return GetPlayerCraftingData(source).level end)
exports('GetPlayerCraftingData', function(source) return GetPlayerCraftingData(source) end)
exports('HasBlueprint', function(source, recipeId) return HasBlueprint(source, recipeId) end)
exports('UnlockBlueprint', function(source, recipeId) return UnlockBlueprint(source, recipeId) end)

-- ====================== INIT ======================
CreateThread(function()
    Wait(1000)
    LoadDynamicStations()
end)
