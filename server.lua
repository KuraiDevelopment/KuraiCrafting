-- ============================================================================
-- KURAI.DEV ADVANCED PROGRESSION CRAFTING SYSTEM v3.0
-- Server-side logic with blueprints, specializations, tool durability
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ====================== DATA CACHES ======================
local PlayerData = {}
local PlayerBlueprints = {}
local PlayerSpecializations = {}
local DynamicStations = {}
local CraftingCooldowns = {}
local AntiExploitTracker = {}

-- ====================== INITIALIZATION ======================
local function InitializePlayerData(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    
    if Config.UseMySQL then
        -- Use synchronous queries to prevent race conditions
        local result = MySQL.query.await('SELECT * FROM crafting_progression WHERE citizenid = ?', {citizenid})
        
        if result and result[1] then
            PlayerData[source] = {
                level = result[1].level or 0,
                xp = result[1].xp or 0,
                totalCrafted = result[1].total_crafted or 0,
                lastCraft = {},
                craftStreak = {},
                craftedRecipes = {}  -- Track what they've crafted before
            }
        else
            MySQL.insert.await('INSERT INTO crafting_progression (citizenid, level, xp, total_crafted) VALUES (?, ?, ?, ?)',
                {citizenid, 0, 0, 0})
            
            PlayerData[source] = {
                level = 0,
                xp = 0,
                totalCrafted = 0,
                lastCraft = {},
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
        else
            PlayerSpecializations[source] = nil
        end
        
        -- Load crafted recipes for first-time bonus tracking
        local craftedBefore = MySQL.query.await(
            'SELECT DISTINCT recipe_id FROM crafting_stats WHERE citizenid = ? AND success = 1', 
            {citizenid}
        )
        if craftedBefore then
            for _, craft in ipairs(craftedBefore) do
                PlayerData[source].craftedRecipes[craft.recipe_id] = true
            end
        end
        
        return true
    else
        local metadata = Player.PlayerData.metadata or {}
        PlayerData[source] = {
            level = metadata[Config.ProgressionDataKey] or 0,
            xp = metadata[Config.CraftingXPKey] or 0,
            totalCrafted = metadata.total_crafted or 0,
            lastCraft = {},
            craftStreak = {},
            craftedRecipes = {}
        }
        PlayerBlueprints[source] = metadata.crafting_blueprints or {}
        PlayerSpecializations[source] = metadata.crafting_specialization or nil
        return true
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
        Player.Functions.SetMetaData('crafting_blueprints', PlayerBlueprints[source] or {})
        Player.Functions.SetMetaData('crafting_specialization', PlayerSpecializations[source])
    end
end

-- ====================== UTILITY FUNCTIONS ======================
local function GetPlayerCraftingData(source)
    if not PlayerData[source] then
        InitializePlayerData(source)
    end
    return PlayerData[source] or {level = 0, xp = 0, totalCrafted = 0, lastCraft = {}, craftStreak = {}, craftedRecipes = {}}
end

local function CalculateXPForNextLevel(currentLevel)
    return math.floor((currentLevel ^ 1.5) * 100 + 200)
end

local function GetProgressionTitle(level)
    local title = 'Novice'
    local color = '#AAAAAA'
    for _, tier in ipairs(Config.Progression) do
        if level >= tier.level then
            title = tier.label
            color = tier.color
        else
            break
        end
    end
    return title, color
end

-- ====================== BLUEPRINT SYSTEM ======================
local function HasBlueprint(source, recipeId)
    if not Config.EnableBlueprints then return true end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return false end
    
    -- Starter recipes don't need blueprints
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
    
    if PlayerBlueprints[source][recipeId] then
        return false -- Already unlocked
    end
    
    PlayerBlueprints[source][recipeId] = true
    
    if Config.UseMySQL then
        local citizenid = Player.PlayerData.citizenid
        MySQL.insert('INSERT INTO crafting_blueprints (citizenid, recipe_id) VALUES (?, ?)', {citizenid, recipeId})
    end
    
    if Config.EnableDebug then
        print(('[Crafting] %s unlocked blueprint: %s'):format(Player.PlayerData.citizenid, recipeId))
    end
    
    return true
end

local function GetPlayerBlueprints(source)
    return PlayerBlueprints[source] or {}
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
    
    PlayerSpecializations[source] = {
        type = specType,
        level = 1,
        xp = 0
    }
    
    if Config.UseMySQL then
        local citizenid = Player.PlayerData.citizenid
        MySQL.query('DELETE FROM crafting_specializations WHERE citizenid = ?', {citizenid})
        MySQL.insert('INSERT INTO crafting_specializations (citizenid, specialization, spec_level, spec_xp) VALUES (?, ?, ?, ?)',
            {citizenid, specType, 1, 0})
    end
    
    return true
end

local function ResetPlayerSpecialization(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    if not Config.AllowSpecializationReset then return false end
    
    -- Check if player can afford reset
    if Config.SpecializationResetCost > 0 then
        if Player.PlayerData.money.cash < Config.SpecializationResetCost then
            return false, 'Not enough money'
        end
        Player.Functions.RemoveMoney('cash', Config.SpecializationResetCost, 'specialization-reset')
    end
    
    PlayerSpecializations[source] = nil
    
    if Config.UseMySQL then
        local citizenid = Player.PlayerData.citizenid
        MySQL.query('DELETE FROM crafting_specializations WHERE citizenid = ?', {citizenid})
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
    
    local isBonus = false
    local isPenalty = false
    
    for _, cat in ipairs(specConfig.bonusCategories) do
        if cat == category then
            isBonus = true
            break
        end
    end
    
    for _, cat in ipairs(specConfig.penaltyCategories) do
        if cat == category then
            isPenalty = true
            break
        end
    end
    
    if isBonus then
        return {
            xpMult = 1.0 + specConfig.xpBonus,
            successMult = 1.0 + specConfig.successBonus,
            qualityMult = 1.0 + specConfig.qualityBonus
        }
    elseif isPenalty then
        return {
            xpMult = 1.0 - specConfig.xpPenalty,
            successMult = 1.0,  -- No success penalty
            qualityMult = 1.0   -- No quality penalty
        }
    else
        return {xpMult = 1.0, successMult = 1.0, qualityMult = 1.0}
    end
end

-- ====================== TOOL DURABILITY SYSTEM ======================
local function GetToolDurability(Player, toolName)
    if not Config.EnableToolDurability then return 100 end
    
    local items = Player.Functions.GetItemsByName(toolName)
    if not items or #items == 0 then return 0 end
    
    -- Find tool with highest durability
    local bestDurability = 0
    local bestSlot = nil
    
    for _, item in ipairs(items) do
        local durability = 100
        if item.info and item.info.durability then
            durability = item.info.durability
        end
        if durability > bestDurability then
            bestDurability = durability
            bestSlot = item.slot
        end
    end
    
    return bestDurability, bestSlot
end

local function DegradeTool(Player, toolName, amount)
    if not Config.EnableToolDurability then return true end
    if not toolName or amount <= 0 then return true end
    
    local items = Player.Functions.GetItemsByName(toolName)
    if not items or #items == 0 then return false end
    
    -- Find tool with highest durability
    local bestDurability = 0
    local bestSlot = nil
    local bestItem = nil
    
    for _, item in ipairs(items) do
        local durability = 100
        if item.info and item.info.durability then
            durability = item.info.durability
        end
        if durability > bestDurability then
            bestDurability = durability
            bestSlot = item.slot
            bestItem = item
        end
    end
    
    if not bestItem then return false end
    
    local newDurability = bestDurability - amount
    
    if newDurability <= 0 then
        -- Tool breaks
        Player.Functions.RemoveItem(toolName, 1, bestSlot)
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[toolName], 'remove', 1)
        
        if Config.ToolBreakNotification then
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 
                'Your ' .. (Config.Tools[toolName] and Config.Tools[toolName].label or toolName) .. ' broke!', 
                'error')
        end
        
        return true, true -- Success, but tool broke
    else
        -- Update durability
        local newInfo = bestItem.info or {}
        newInfo.durability = newDurability
        
        Player.Functions.RemoveItem(toolName, 1, bestSlot)
        Player.Functions.AddItem(toolName, 1, nil, newInfo)
        
        return true, false -- Success, tool intact
    end
end

local function HasRequiredTool(Player, toolName)
    if not toolName then return true, nil end
    if not Config.RequireTools then return true, nil end
    
    local item = Player.Functions.GetItemByName(toolName)
    if not item or item.amount <= 0 then
        return false, toolName
    end
    
    if Config.EnableToolDurability then
        local durability = GetToolDurability(Player, toolName)
        if durability <= 0 then
            return false, toolName .. ' (broken)'
        end
    end
    
    return true, nil
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
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[ing.item], 'remove', ing.count * amount)
    end
end

local function CalculateFailureChance(source, recipe)
    local baseChance = recipe.failureChance or Config.BaseFailureChance
    local data = GetPlayerCraftingData(source)
    local specBonus = GetSpecializationBonus(source, recipe.category)
    
    -- Apply level-based reduction
    if Config.LevelFailureReduction.enabled then
        local reduction = data.level * Config.LevelFailureReduction.reductionPerLevel
        reduction = math.min(reduction, Config.LevelFailureReduction.maxReduction)
        baseChance = baseChance * (1 - reduction)
    end
    
    -- Apply specialization success bonus (reduces failure)
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
    
    -- Calculate excellent chance
    local excellentChance = Config.QualityChances.excellent.baseChance
    excellentChance = excellentChance + (data.level * Config.QualityChances.excellent.levelBonus)
    excellentChance = excellentChance * specBonus.qualityMult
    
    -- Calculate fine chance
    local fineChance = Config.QualityChances.fine.baseChance
    fineChance = fineChance + (data.level * Config.QualityChances.fine.levelBonus)
    fineChance = fineChance * specBonus.qualityMult
    
    if roll <= excellentChance then
        return 'excellent'
    elseif roll <= (excellentChance + fineChance) then
        return 'fine'
    else
        return 'normal'
    end
end

local function GiveResult(Player, result, amount, quality)
    local itemName = result.item
    local itemCount = result.count * amount
    local metadata = result.metadata or {}
    
    -- Apply quality bonus
    if quality and quality ~= 'normal' then
        if quality == 'fine' then
            itemCount = math.ceil(itemCount * 1.15)
            metadata.quality = 'fine'
        elseif quality == 'excellent' then
            itemCount = math.ceil(itemCount * 1.30)
            metadata.quality = 'excellent'
        end
    end
    
    -- Handle tool durability for crafted tools
    if Config.EnableToolDurability and Config.Tools[itemName] then
        metadata.durability = Config.Tools[itemName].maxDurability
        if quality == 'fine' then
            metadata.durability = math.floor(metadata.durability * 1.1)
        elseif quality == 'excellent' then
            metadata.durability = math.floor(metadata.durability * 1.25)
        end
    end
    
    if next(metadata) then
        Player.Functions.AddItem(itemName, itemCount, nil, metadata)
    else
        Player.Functions.AddItem(itemName, itemCount)
    end
    
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[itemName], 'add', itemCount)
    
    return itemCount
end

local function CalculateXPGain(source, recipe, amount, recipeId)
    local data = GetPlayerCraftingData(source)
    local baseXP = recipe.xp * amount
    local multiplier = Config.XPMultipliers.base
    local bonuses = {}
    
    -- Streak bonus
    if data.craftStreak[recipeId] then
        local streakCount = math.min(data.craftStreak[recipeId], 10)
        local streakMult = streakCount * Config.XPMultipliers.streakBonus
        multiplier = multiplier + streakMult
        if streakMult > 0 then
            table.insert(bonuses, {name = 'Streak x' .. streakCount, value = streakMult})
        end
    end
    
    -- First time bonus
    if not data.craftedRecipes[recipeId] then
        multiplier = multiplier + Config.XPMultipliers.firstTimeBonus
        table.insert(bonuses, {name = 'First Craft!', value = Config.XPMultipliers.firstTimeBonus})
        data.craftedRecipes[recipeId] = true
    end
    
    -- Specialization bonus
    local specBonus = GetSpecializationBonus(source, recipe.category)
    if specBonus.xpMult ~= 1.0 then
        multiplier = multiplier * specBonus.xpMult
        if specBonus.xpMult > 1.0 then
            table.insert(bonuses, {name = 'Specialization', value = specBonus.xpMult - 1.0})
        end
    end
    
    return math.floor(baseXP * multiplier), bonuses
end

local function AwardXP(source, xpAmount)
    local data = GetPlayerCraftingData(source)
    local oldLevel = data.level
    
    data.xp = data.xp + xpAmount
    
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

local function UpdateCraftStreak(source, recipeId)
    local data = GetPlayerCraftingData(source)
    
    for id, _ in pairs(data.craftStreak) do
        if id ~= recipeId then
            data.craftStreak[id] = 0
        end
    end
    
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

-- ====================== ANTI-EXPLOIT ======================
local function CheckAntiExploit(source)
    if not Config.AntiExploit.enabled then return true end
    
    local now = os.time()
    
    if not AntiExploitTracker[source] then
        AntiExploitTracker[source] = {count = 0, windowStart = now}
    end
    
    local tracker = AntiExploitTracker[source]
    
    -- Reset window every minute
    if now - tracker.windowStart > 60 then
        tracker.count = 0
        tracker.windowStart = now
    end
    
    tracker.count = tracker.count + 1
    
    if tracker.count > Config.AntiExploit.maxCraftsPerMinute then
        if Config.AntiExploit.logSuspiciousActivity then
            local Player = QBCore.Functions.GetPlayer(source)
            print(('[Crafting Anti-Exploit] Suspicious activity from %s (%s): %d crafts in 1 minute'):format(
                Player and Player.PlayerData.citizenid or 'Unknown',
                source,
                tracker.count
            ))
        end
        return false
    end
    
    return true
end

-- ====================== STATION VALIDATION ======================
local function ValidateStationProximity(source, stationCoords, stationType)
    if not Config.ServerSideValidation then return true end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    
    local distance = #(playerCoords - stationCoords)
    
    if distance > Config.StationProximityCheck then
        if Config.EnableDebug then
            print(('[Crafting] Station validation failed for %s: Distance %.2f > %.2f'):format(
                Player.PlayerData.citizenid, distance, Config.StationProximityCheck
            ))
        end
        return false
    end
    
    -- Verify station exists
    local stationExists = false
    
    for _, station in ipairs(Config.CraftingStations) do
        if station.type == stationType and #(station.coords - stationCoords) < 1.0 then
            stationExists = true
            break
        end
    end
    
    if not stationExists then
        for _, station in ipairs(DynamicStations) do
            if station.type == stationType and #(station.coords - stationCoords) < 1.0 then
                stationExists = true
                break
            end
        end
    end
    
    return stationExists
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
    local playerBlueprints = GetPlayerBlueprints(source)
    
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
            local meetsLevel = playerLevel >= recipe.requiredLevel
            
            if hasBlueprint and meetsLevel then
                availableRecipes[id] = recipe
            elseif Config.ShowLockedRecipes then
                lockedRecipes[id] = {
                    recipe = recipe,
                    reason = not hasBlueprint and 'blueprint' or 'level',
                    requiredLevel = recipe.requiredLevel
                }
            end
        end
    end
    
    local spec = GetPlayerSpecialization(source)
    
    return {
        recipes = availableRecipes,
        lockedRecipes = lockedRecipes,
        level = playerLevel,
        xp = data.xp,
        nextLevelXP = CalculateXPForNextLevel(playerLevel),
        title = GetProgressionTitle(playerLevel),
        specialization = spec,
        totalCrafted = data.totalCrafted
    }
end)

lib.callback.register('crafting:getSpecializations', function(source)
    local data = GetPlayerCraftingData(source)
    local currentSpec = GetPlayerSpecialization(source)
    
    return {
        available = Config.Specializations,
        current = currentSpec,
        canSelect = data.level >= Config.SpecializationUnlockLevel,
        requiredLevel = Config.SpecializationUnlockLevel,
        canReset = Config.AllowSpecializationReset,
        resetCost = Config.SpecializationResetCost
    }
end)

lib.callback.register('crafting:selectSpecialization', function(source, specType)
    local success, error = SetPlayerSpecialization(source, specType)
    return success, error
end)

lib.callback.register('crafting:resetSpecialization', function(source)
    local success, error = ResetPlayerSpecialization(source)
    return success, error
end)

lib.callback.register('crafting:getToolDurability', function(source, toolName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    return GetToolDurability(Player, toolName)
end)

-- ====================== EVENTS ======================
RegisterNetEvent('crafting:attemptCraft', function(recipeId, amount, stationType, stationCoords)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Anti-exploit check
    if not CheckAntiExploit(source) then
        TriggerClientEvent('crafting:craftResult', source, false, 'Too many craft attempts! Slow down.')
        return
    end
    
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
    
    -- Validate station proximity (SECURITY FIX)
    if stationCoords and not ValidateStationProximity(source, stationCoords, stationType) then
        TriggerClientEvent('crafting:craftResult', source, false, 'You are not at a valid crafting station!')
        if Config.EnableDebug then
            print(('[Crafting] EXPLOIT ATTEMPT: %s tried to craft from invalid location'):format(Player.PlayerData.citizenid))
        end
        return
    end
    
    local data = GetPlayerCraftingData(source)
    
    -- Check level requirement
    if data.level < recipe.requiredLevel then
        TriggerClientEvent('crafting:craftResult', source, false, 'Your crafting level is too low!')
        return
    end
    
    -- Check blueprint
    if not HasBlueprint(source, recipeId) then
        TriggerClientEvent('crafting:craftResult', source, false, 'You don\'t have the blueprint for this recipe!')
        return
    end
    
    -- Check station type
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
    local hasTool, missingTool = HasRequiredTool(Player, recipe.requiredTool)
    if not hasTool then
        TriggerClientEvent('crafting:craftResult', source, false, 'You need a ' .. missingTool .. ' to craft this!')
        return
    end
    
    -- Check ingredients
    local hasIngredients, missingItem = CheckIngredients(Player, recipe.ingredients, amount)
    if not hasIngredients then
        TriggerClientEvent('crafting:craftResult', source, false, 'Missing ingredient: ' .. missingItem)
        return
    end
    
    -- Calculate failure chance
    local failureChance = CalculateFailureChance(source, recipe)
    local failed = math.random() < failureChance
    
    -- Remove ingredients
    RemoveIngredients(Player, recipe.ingredients, amount)
    
    -- Degrade tool
    local toolBroke = false
    if recipe.requiredTool and recipe.toolDurability and recipe.toolDurability > 0 then
        local _, broke = DegradeTool(Player, recipe.requiredTool, recipe.toolDurability * amount)
        toolBroke = broke
    end
    
    if failed then
        TriggerClientEvent('crafting:craftResult', source, false, 'Crafting failed! Materials were lost.')
        RecordCraftStat(source, recipeId, amount, false)
        return
    end
    
    -- Determine quality
    local quality = DetermineQuality(source, recipe)
    
    -- Give result
    local actualCount = GiveResult(Player, recipe.result, amount, quality)
    
    -- Calculate and award XP
    local xpGained, xpBonuses = CalculateXPGain(source, recipe, amount, recipeId)
    local leveledUp, newLevel, oldLevel = AwardXP(source, xpGained)
    
    -- Update statistics
    data.totalCrafted = data.totalCrafted + actualCount
    UpdateCraftStreak(source, recipeId)
    SavePlayerData(source)
    RecordCraftStat(source, recipeId, amount, true)
    
    -- Build success message
    local message = 'Crafted ' .. actualCount .. 'x ' .. recipe.label
    if quality ~= 'normal' then
        message = message .. ' (' .. string.upper(quality) .. '!)'
    end
    if toolBroke then
        message = message .. ' (Tool broke!)'
    end
    
    -- Notify client
    TriggerClientEvent('crafting:craftResult', source, true, message, xpGained, leveledUp, newLevel, xpBonuses, quality)
    
    if leveledUp then
        local title = GetProgressionTitle(newLevel)
        TriggerClientEvent('QBCore:Notify', source, 'Congratulations! You are now a ' .. title .. ' (Level ' .. newLevel .. ')', 'success', 5000)
        
        -- Check if they can now select a specialization
        if oldLevel < Config.SpecializationUnlockLevel and newLevel >= Config.SpecializationUnlockLevel then
            TriggerClientEvent('QBCore:Notify', source, 'You can now choose a crafting specialization!', 'inform', 5000)
        end
    end
    
    if Config.EnableDebug then
        print(('[Crafting] %s crafted %dx %s (Level: %d, XP: +%d, Quality: %s)'):format(
            Player.PlayerData.citizenid, amount, recipeId, data.level, xpGained, quality))
    end
end)

-- Blueprint usage event
RegisterNetEvent('crafting:useBlueprint', function(blueprintItem, recipeId)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local item = Player.Functions.GetItemByName(blueprintItem)
    if not item then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have this blueprint!', 'error')
        return
    end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid blueprint!', 'error')
        return
    end
    
    if HasBlueprint(source, recipeId) then
        TriggerClientEvent('QBCore:Notify', source, 'You already know this recipe!', 'error')
        return
    end
    
    -- Remove the blueprint item and unlock the recipe
    Player.Functions.RemoveItem(blueprintItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[blueprintItem], 'remove', 1)
    
    if UnlockBlueprint(source, recipeId) then
        TriggerClientEvent('QBCore:Notify', source, 'Learned: ' .. recipe.label .. '!', 'success')
        TriggerClientEvent('crafting:blueprintUnlocked', source, recipeId, recipe.label)
    end
end)

-- Tool repair event
RegisterNetEvent('crafting:repairTool', function(toolName)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local toolConfig = Config.Tools[toolName]
    if not toolConfig then
        TriggerClientEvent('QBCore:Notify', source, 'This tool cannot be repaired!', 'error')
        return
    end
    
    local item = Player.Functions.GetItemByName(toolName)
    if not item then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have this tool!', 'error')
        return
    end
    
    local currentDurability = (item.info and item.info.durability) or toolConfig.maxDurability
    if currentDurability >= toolConfig.maxDurability then
        TriggerClientEvent('QBCore:Notify', source, 'This tool doesn\'t need repairs!', 'info')
        return
    end
    
    local repairItem = Player.Functions.GetItemByName(toolConfig.repairItem)
    if not repairItem or repairItem.amount < toolConfig.repairAmount then
        TriggerClientEvent('QBCore:Notify', source, 'You need ' .. toolConfig.repairAmount .. 'x ' .. toolConfig.repairItem .. ' to repair this!', 'error')
        return
    end
    
    -- Remove repair materials
    Player.Functions.RemoveItem(toolConfig.repairItem, toolConfig.repairAmount)
    
    -- Update tool durability
    local newDurability = math.min(currentDurability + toolConfig.repairRestores, toolConfig.maxDurability)
    local newInfo = item.info or {}
    newInfo.durability = newDurability
    
    Player.Functions.RemoveItem(toolName, 1, item.slot)
    Player.Functions.AddItem(toolName, 1, nil, newInfo)
    
    TriggerClientEvent('QBCore:Notify', source, 'Repaired ' .. toolConfig.label .. ' (' .. newDurability .. '/' .. toolConfig.maxDurability .. ')', 'success')
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
        PlayerBlueprints[source] = nil
        PlayerSpecializations[source] = nil
        AntiExploitTracker[source] = nil
    end
end)

-- ====================== DYNAMIC STATION MANAGEMENT ======================
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
                dynamic = true
            })
        end
        TriggerClientEvent('crafting:updateStations', -1, DynamicStations)
        
        if Config.EnableDebug then
            print('[Crafting] Loaded ' .. #DynamicStations .. ' dynamic stations')
        end
    end
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

-- FIXED: Async delete function
local function DeleteStation(stationId)
    if not Config.UseMySQL then return false end
    
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
end

CreateThread(function()
    Wait(1000)
    LoadDynamicStations()
end)

-- ====================== COMMANDS ======================
QBCore.Commands.Add('craftinglevel', 'Check your crafting level', {}, false, function(source)
    local data = GetPlayerCraftingData(source)
    local title, color = GetProgressionTitle(data.level)
    local nextXP = CalculateXPForNextLevel(data.level)
    local spec = GetPlayerSpecialization(source)
    
    local specText = spec and (' | Spec: ' .. Config.Specializations[spec.type].label) or ''
    
    TriggerClientEvent('QBCore:Notify', source, 
        ('Level %d %s%s\nXP: %d/%d | Total Crafted: %d'):format(
            data.level, title, specText, data.xp, nextXP, data.totalCrafted
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

QBCore.Commands.Add('giveblueprint', 'Give player a blueprint (Admin)', {
    {name = 'id', help = 'Player ID'},
    {name = 'recipe', help = 'Recipe ID'}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local recipeId = args[2]
    
    if not targetId or not recipeId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid arguments', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid recipe ID', 'error')
        return
    end
    
    if UnlockBlueprint(targetId, recipeId) then
        TriggerClientEvent('QBCore:Notify', targetId, 'Blueprint unlocked: ' .. recipe.label, 'success')
        TriggerClientEvent('QBCore:Notify', source, 'Gave blueprint: ' .. recipe.label, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Player already has this blueprint', 'error')
    end
end, Config.AdminGroup)

QBCore.Commands.Add('listrecipes', 'List all recipe IDs (Admin)', {}, true, function(source)
    print('=== AVAILABLE RECIPES ===')
    for id, recipe in pairs(CraftingRecipes) do
        print(('[%s] %s - Category: %s, Level: %d, Blueprint: %s'):format(
            id, recipe.label, recipe.category, recipe.requiredLevel,
            recipe.requiresBlueprint and recipe.blueprintRarity or 'N/A'
        ))
    end
    TriggerClientEvent('QBCore:Notify', source, 'Recipe list printed to server console', 'success')
end, Config.AdminGroup)

QBCore.Commands.Add('addcraftstation', 'Add a crafting station (Admin)', {
    {name = 'type', help = 'Station type'}
}, true, function(source, args)
    local stationType = args[1]
    
    if not stationType or not Config.StationTypes[stationType] then
        local types = {}
        for k, _ in pairs(Config.StationTypes) do
            table.insert(types, k)
        end
        TriggerClientEvent('QBCore:Notify', source, 'Valid types: ' .. table.concat(types, ', '), 'error')
        return
    end
    
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
    return SaveStation(stationData)
end)

lib.callback.register('crafting:admin:deleteStation', function(source, stationId)
    return DeleteStation(stationId)
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
            dynamic = false
        })
    end
    
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

exports('GetPlayerSpecialization', function(source)
    return GetPlayerSpecialization(source)
end)

exports('HasBlueprint', function(source, recipeId)
    return HasBlueprint(source, recipeId)
end)

exports('UnlockBlueprint', function(source, recipeId)
    return UnlockBlueprint(source, recipeId)
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

exports('GetToolDurability', function(source, toolName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    return GetToolDurability(Player, toolName)
end)
