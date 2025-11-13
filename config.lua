-- Advanced Progression Crafting Config
Config = {}

-- ====================== GENERAL SETTINGS ======================
Config.CraftingDistance = 3.0 -- Interaction distance for stations
Config.MaxCraftAmount = 25 -- Maximum items per craft session
Config.ProgressionDataKey = 'crafting_level' -- Metadata key for player level
Config.CraftingXPKey = 'crafting_xp' -- Metadata key for player XP
Config.NotifyType = 'inform' -- Default notification type

-- ====================== STATION CATEGORIES ======================
-- Each station type has its own category of recipes
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
        categories = {'weapons', 'attachments'}
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
-- XP formula: XP needed for next level = (level^1.5) * 100 + 200
Config.Progression = {
    -- Level thresholds and titles
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
    base = 1.0,              -- Base XP multiplier
    groupBonus = 0.1,        -- Bonus per nearby player crafting (stacks up to 3)
    qualityBonus = 0.25,     -- Bonus for successful quality crafts
    firstTimeBonus = 2.0,    -- First time crafting a recipe
    streakBonus = 0.05       -- Per consecutive craft of same type (max 10)
}

-- ====================== CRAFTING MECHANICS ======================
Config.UseSkillCheck = true -- Enable ox_lib skill checks
Config.SkillCheckDifficulty = {'easy', 'easy', 'medium'} -- Default difficulty
Config.FailureChance = 0.05 -- 5% base chance to fail and lose materials
Config.QualitySystem = true -- Enable quality tiers (normal, fine, excellent)
Config.RequireTools = true -- Require tools in inventory for crafting

-- Cooldowns (seconds)
Config.GlobalCooldown = 1 -- Between any crafts
Config.RecipeCooldown = 5 -- Between same recipe crafts

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

-- ====================== DATABASE ======================
Config.UseMySQL = true
Config.DatabaseTable = 'crafting_progression'
Config.StatsTable = 'crafting_stats'

-- ====================== ADMIN ======================
Config.AdminGroup = 'admin'
Config.EnableDebug = false

-- ====================== UI SETTINGS ======================
Config.DisableControlsWhileCrafting = true
Config.ShowProgressBar = true
Config.ShowIngredients = true
Config.ShowRequiredLevel = true
Config.PlaySoundEffects = true

-- ====================== BLIP SETTINGS ======================
Config.ShowBlips = true
Config.BlipSprite = 478
Config.BlipColour = 5
Config.BlipScale = 0.7
