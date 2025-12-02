-- ============================================================================
-- KURAI.DEV ADVANCED PROGRESSION CRAFTING SYSTEM v3.0
-- The definitive crafting solution for QBCore/QBox
-- ============================================================================

Config = {}

-- ====================== GENERAL SETTINGS ======================
Config.CraftingDistance = 3.0          -- Interaction distance for stations
Config.MaxCraftAmount = 25             -- Maximum items per craft session
Config.ProgressionDataKey = 'crafting_level'
Config.CraftingXPKey = 'crafting_xp'
Config.NotifyType = 'inform'

-- ====================== DATABASE ======================
Config.UseMySQL = true
Config.DatabaseTable = 'crafting_progression'
Config.StatsTable = 'crafting_stats'
Config.BlueprintsTable = 'crafting_blueprints'
Config.SpecializationsTable = 'crafting_specializations'

-- ====================== ADMIN ======================
Config.AdminGroup = 'admin'
Config.EnableDebug = false

-- ====================== STATION CATEGORIES ======================
Config.StationTypes = {
    workbench = {
        label = 'Workbench',
        icon = 'fa-solid fa-hammer',
        categories = {'basic', 'tools', 'components'}
    },
    electronics_bench = {
        label = 'Electronics Bench',
        icon = 'fa-solid fa-microchip',
        categories = {'electronics', 'components'}
    },
    weapon_bench = {
        label = 'Weapon Bench',
        icon = 'fa-solid fa-gun',
        categories = {'weapons', 'attachments', 'ammo'}
    },
    medical_station = {
        label = 'Medical Station',
        icon = 'fa-solid fa-briefcase-medical',
        categories = {'medical', 'chemistry'}
    },
    cooking_station = {
        label = 'Cooking Station',
        icon = 'fa-solid fa-fire-burner',
        categories = {'food', 'drinks'}
    }
}

-- ====================== CRAFTING STATIONS ======================
Config.CraftingStations = {
    -- Workbenches (Public)
    {type = 'workbench', coords = vector3(-268.0, -956.0, 31.2), heading = 0.0, blip = true, label = 'Public Workbench'},
    {type = 'workbench', coords = vector3(1275.0, -1710.0, 54.8), heading = 180.0, blip = true, label = 'Workshop'},
    
    -- Electronics (Specialized)
    {type = 'electronics_bench', coords = vector3(2747.0, 3472.0, 55.7), heading = 90.0, blip = false, label = 'Electronics Lab'},
    
    -- Weapon Benches (Hidden/Gang)
    {type = 'weapon_bench', coords = vector3(1087.0, -3099.0, -39.0), heading = 270.0, blip = false, label = 'Underground Workshop'},
    
    -- Medical Stations
    {type = 'medical_station', coords = vector3(304.0, -595.0, 43.3), heading = 0.0, blip = true, label = 'Hospital Lab'},
    
    -- Cooking Stations
    {type = 'cooking_station', coords = vector3(216.0, -1398.0, 30.6), heading = 140.0, blip = false, label = 'Restaurant Kitchen'}
}

-- ====================== PROGRESSION SYSTEM ======================
-- XP formula: (level^1.5) * 100 + 200
Config.Progression = {
    {level = 0,   label = 'Novice',        color = '#AAAAAA'},
    {level = 5,   label = 'Apprentice',    color = '#4CAF50'},
    {level = 10,  label = 'Journeyman',    color = '#2196F3'},
    {level = 20,  label = 'Adept',         color = '#9C27B0'},
    {level = 35,  label = 'Expert',        color = '#FF9800'},
    {level = 50,  label = 'Master',        color = '#F44336'},
    {level = 75,  label = 'Grandmaster',   color = '#FFD700'},
    {level = 100, label = 'Legendary',     color = '#00FFFF'}
}

-- XP Multipliers
Config.XPMultipliers = {
    base = 1.0,
    groupBonus = 0.1,        -- Per nearby player (max 3)
    qualityBonus = 0.25,     -- For quality crafts
    firstTimeBonus = 2.0,    -- First time crafting a recipe
    streakBonus = 0.05,      -- Per consecutive craft (max 10)
    specializationBonus = 0.25  -- When crafting in your specialization
}

-- ====================== SPECIALIZATION SYSTEM ======================
Config.EnableSpecializations = true
Config.SpecializationUnlockLevel = 10  -- Level required to pick a specialization
Config.AllowSpecializationReset = true
Config.SpecializationResetCost = 5000  -- In-game currency cost to reset

Config.Specializations = {
    blacksmith = {
        label = 'Blacksmith',
        icon = 'fa-solid fa-hammer',
        description = 'Master of metalworking and tool creation',
        color = '#8B4513',
        bonusCategories = {'tools', 'components', 'basic'},
        xpBonus = 0.25,           -- 25% more XP in bonus categories
        successBonus = 0.10,      -- 10% better success rate
        qualityBonus = 0.15,      -- 15% better quality chance
        penaltyCategories = {'electronics', 'chemistry'},
        xpPenalty = 0.15          -- 15% less XP in penalty categories
    },
    engineer = {
        label = 'Engineer',
        icon = 'fa-solid fa-microchip',
        description = 'Expert in electronics and advanced technology',
        color = '#00CED1',
        bonusCategories = {'electronics', 'components'},
        xpBonus = 0.25,
        successBonus = 0.12,
        qualityBonus = 0.10,
        penaltyCategories = {'food', 'drinks'},
        xpPenalty = 0.10
    },
    weaponsmith = {
        label = 'Weaponsmith',
        icon = 'fa-solid fa-gun',
        description = 'Specialist in weapons and modifications',
        color = '#DC143C',
        bonusCategories = {'weapons', 'attachments', 'ammo'},
        xpBonus = 0.30,
        successBonus = 0.15,
        qualityBonus = 0.20,
        penaltyCategories = {'medical', 'food'},
        xpPenalty = 0.20
    },
    chemist = {
        label = 'Chemist',
        icon = 'fa-solid fa-flask',
        description = 'Master of chemistry and medical crafting',
        color = '#9932CC',
        bonusCategories = {'medical', 'chemistry'},
        xpBonus = 0.25,
        successBonus = 0.12,
        qualityBonus = 0.15,
        penaltyCategories = {'weapons', 'tools'},
        xpPenalty = 0.15
    },
    chef = {
        label = 'Chef',
        icon = 'fa-solid fa-utensils',
        description = 'Culinary expert with enhanced food crafting',
        color = '#FF6347',
        bonusCategories = {'food', 'drinks'},
        xpBonus = 0.20,
        successBonus = 0.15,
        qualityBonus = 0.25,
        penaltyCategories = {'weapons', 'electronics'},
        xpPenalty = 0.10
    }
}

-- ====================== BLUEPRINT SYSTEM ======================
Config.EnableBlueprints = true
Config.ShowLockedRecipes = true  -- Show recipes player doesn't have blueprints for

-- Blueprint rarity affects drop rates and purchase prices
Config.BlueprintRarity = {
    common = {color = '#AAAAAA', dropRate = 0.15, basePrice = 500},
    uncommon = {color = '#4CAF50', dropRate = 0.08, basePrice = 1500},
    rare = {color = '#2196F3', dropRate = 0.04, basePrice = 5000},
    epic = {color = '#9C27B0', dropRate = 0.02, basePrice = 15000},
    legendary = {color = '#FF9800', dropRate = 0.005, basePrice = 50000}
}

-- ====================== TOOL DURABILITY SYSTEM ======================
Config.EnableToolDurability = true
Config.ShowToolDurability = true
Config.ToolBreakNotification = true

-- Tool definitions with max durability
Config.Tools = {
    hammer = {
        label = 'Hammer',
        maxDurability = 100,
        degradePerUse = 2,      -- Base degradation per craft
        repairItem = 'metalscrap',
        repairAmount = 2,
        repairRestores = 25
    },
    screwdriver = {
        label = 'Screwdriver',
        maxDurability = 80,
        degradePerUse = 3,
        repairItem = 'metalscrap',
        repairAmount = 1,
        repairRestores = 20
    },
    saw = {
        label = 'Saw',
        maxDurability = 60,
        degradePerUse = 4,
        repairItem = 'steel',
        repairAmount = 1,
        repairRestores = 30
    },
    drill = {
        label = 'Drill',
        maxDurability = 50,
        degradePerUse = 5,
        repairItem = 'electronic_kit',
        repairAmount = 1,
        repairRestores = 25
    },
    soldering_iron = {
        label = 'Soldering Iron',
        maxDurability = 40,
        degradePerUse = 4,
        repairItem = 'copper',
        repairAmount = 2,
        repairRestores = 20
    }
}

-- ====================== CRAFTING MECHANICS ======================
Config.UseSkillCheck = true
Config.SkillCheckDifficulty = {'easy', 'easy', 'medium'}
Config.BaseFailureChance = 0.05
Config.QualitySystem = true
Config.RequireTools = true

-- Level-based failure reduction (masters fail less)
Config.LevelFailureReduction = {
    enabled = true,
    reductionPerLevel = 0.003,  -- 0.3% reduction per level
    maxReduction = 0.80         -- Maximum 80% reduction at high levels
}

-- Quality chances (base, modified by level and specialization)
Config.QualityChances = {
    excellent = {baseChance = 0.05, levelBonus = 0.002},  -- +0.2% per level
    fine = {baseChance = 0.20, levelBonus = 0.003}        -- +0.3% per level
}

-- Cooldowns (seconds)
Config.GlobalCooldown = 1
Config.RecipeCooldown = 5

-- ====================== CRAFTING QUEUE ======================
Config.EnableCraftingQueue = true
Config.MaxQueueSize = 10
Config.QueueProcessInterval = 100  -- ms between queue checks

-- ====================== ANIMATIONS ======================
Config.Animations = {
    workbench = {
        dict = 'mini@repair',
        anim = 'fixing_a_ped',
        flag = 1
    },
    electronics_bench = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flag = 1
    },
    weapon_bench = {
        dict = 'mini@repair',
        anim = 'fixing_a_ped',
        flag = 1
    },
    medical_station = {
        dict = 'mini@sprunk',
        anim = 'plyr_buy_drink_pt1',
        flag = 1
    },
    cooking_station = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flag = 1
    }
}

-- ====================== UI SETTINGS ======================
Config.DisableControlsWhileCrafting = true
Config.ShowProgressBar = true
Config.ShowIngredients = true
Config.ShowRequiredLevel = true
Config.PlaySoundEffects = true
Config.EnableRecipeSearch = true
Config.RecipesPerPage = 10

-- ====================== BLIP SETTINGS ======================
Config.ShowBlips = true
Config.BlipSprite = 478
Config.BlipColour = 5
Config.BlipScale = 0.7

-- ====================== SECURITY ======================
Config.ServerSideValidation = true
Config.StationProximityCheck = 10.0  -- Max distance for station validation
Config.AntiExploit = {
    enabled = true,
    maxCraftsPerMinute = 30,
    logSuspiciousActivity = true
}
