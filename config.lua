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
Config.EnableDebug = true  -- Temporarily enabled to diagnose prop loading issues

-- ====================== PROP SETTINGS ======================
Config.SpawnStationProps = true        -- Enable/disable prop spawning globally
Config.PropDrawDistance = 100.0        -- Distance at which props are visible
Config.UseTargetOnProp = true          -- Target the prop model vs invisible zone

-- ====================== STATION TYPES ======================
Config.StationTypes = {
    workbench = {
        label = 'Workbench',
        icon = 'fa-solid fa-hammer',
        categories = {'basic', 'tools', 'components'},
        defaultProp = 'prop_tool_bench02',
        propOffset = vector3(0.0, 0.0, -1.0),
        targetSize = vector3(2.0, 1.5, 1.5),
        props = {
            {model = 'prop_tool_bench02', label = 'Tool Bench'},
            {model = 'prop_toolchest_05', label = 'Tool Chest'},
            {model = 'gr_prop_gr_bench_04a', label = 'Garage Bench'},
            {model = 'prop_tool_bench02_ld', label = 'Light Duty Bench'},
            {model = 'prop_toolchest_04', label = 'Rolling Tool Chest'},
            {model = 'prop_toolchest_02', label = 'Red Tool Chest'}
        }
    },
    electronics_bench = {
        label = 'Electronics Bench',
        icon = 'fa-solid fa-microchip',
        categories = {'electronics', 'components'},
        defaultProp = 'hei_prop_hei_fib_desk',
        propOffset = vector3(0.0, 0.0, -1.0),
        targetSize = vector3(2.0, 1.5, 1.5),
        props = {
            {model = 'hei_prop_hei_fib_desk', label = 'Tech Desk'},
            {model = 'prop_tool_bench02_ld', label = 'Light Bench'},
            {model = 'prop_laptop_01a', label = 'Laptop Setup'},
            {model = 'hei_heist_kit_bin_01', label = 'Equipment Bin'}
        }
    },
    weapon_bench = {
        label = 'Weapon Bench',
        icon = 'fa-solid fa-gun',
        categories = {'weapons', 'attachments', 'ammo'},
        defaultProp = 'gr_prop_bunker_bench_01a',
        propOffset = vector3(0.0, 0.0, -1.0),
        targetSize = vector3(2.5, 1.5, 1.5),
        props = {
            {model = 'gr_prop_bunker_bench_01a', label = 'Weapon Bench'},
            {model = 'gr_prop_bunker_bench_02a', label = 'Weapon Bench Alt'},
            {model = 'gr_prop_gr_bench_04a', label = 'Heavy Bench'},
            {model = 'prop_toolchest_04', label = 'Ammo Chest'},
            {model = 'gr_prop_bunker_crate_01a', label = 'Weapon Crate'}
        }
    },
    medical_station = {
        label = 'Medical Station',
        icon = 'fa-solid fa-briefcase-medical',
        categories = {'medical', 'chemistry'},
        defaultProp = 'v_med_medtrolley2',
        propOffset = vector3(0.0, 0.0, -1.0),
        targetSize = vector3(1.5, 1.5, 1.5),
        props = {
            {model = 'v_med_medtrolley2', label = 'Medical Trolley'},
            {model = 'prop_med_bag_01', label = 'Medical Bag'},
            {model = 'v_med_crtntable', label = 'Medical Table'},
            {model = 'prop_defilied_ragdoll_01', label = 'First Aid Station'}
        }
    },
    cooking_station = {
        label = 'Cooking Station',
        icon = 'fa-solid fa-fire-burner',
        categories = {'food', 'drinks'},
        defaultProp = 'prop_cooker_03',
        propOffset = vector3(0.0, 0.0, -1.0),
        targetSize = vector3(1.5, 1.5, 1.5),
        props = {
            {model = 'prop_cooker_03', label = 'Cooker/Stove'},
            {model = 'prop_gas_cooker01', label = 'Gas Cooker'},
            {model = 'prop_bbq_3', label = 'BBQ Grill'},
            {model = 'v_res_tre_fridge', label = 'Fridge'}
        }
    }
}

-- ====================== CONFIG STATIONS (Permanent) ======================
-- Set spawnProp = false for stations inside MLOs that already have furniture
Config.CraftingStations = {
    {
        type = 'workbench',
        coords = vector3(-268.0, -956.0, 31.2),
        heading = 0.0,
        blip = true,
        label = 'Public Workbench',
        spawnProp = true,
        prop = 'prop_tool_bench02',
        propOffset = vector3(0.0, 0.0, -1.0)
    },
    {
        type = 'workbench',
        coords = vector3(1275.0, -1710.0, 54.8),
        heading = 180.0,
        blip = true,
        label = 'Workshop',
        spawnProp = true,
        prop = 'prop_tool_bench02',
        propOffset = vector3(0.0, 0.0, -1.0)
    },
    {
        type = 'electronics_bench',
        coords = vector3(2747.0, 3472.0, 55.7),
        heading = 90.0,
        blip = false,
        label = 'Electronics Lab',
        spawnProp = true,
        prop = 'hei_prop_hei_fib_desk',
        propOffset = vector3(0.0, 0.0, -1.0)
    },
    {
        type = 'weapon_bench',
        coords = vector3(1087.0, -3099.0, -39.0),
        heading = 270.0,
        blip = false,
        label = 'Underground Workshop',
        spawnProp = true,
        prop = 'gr_prop_bunker_bench_01a',
        propOffset = vector3(0.0, 0.0, -1.0)
    },
    {
        type = 'medical_station',
        coords = vector3(304.0, -595.0, 43.3),
        heading = 0.0,
        blip = true,
        label = 'Hospital Lab',
        spawnProp = false,  -- Inside hospital MLO
        prop = nil,
        propOffset = vector3(0.0, 0.0, 0.0)
    },
    {
        type = 'cooking_station',
        coords = vector3(216.0, -1398.0, 30.6),
        heading = 140.0,
        blip = false,
        label = 'Restaurant Kitchen',
        spawnProp = true,
        prop = 'prop_cooker_03',
        propOffset = vector3(0.0, 0.0, -1.0)
    }
}

-- ====================== PROGRESSION SYSTEM ======================
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

Config.XPMultipliers = {
    base = 1.0,
    groupBonus = 0.1,
    qualityBonus = 0.25,
    firstTimeBonus = 2.0,
    streakBonus = 0.05,
    specializationBonus = 0.25
}

-- ====================== SPECIALIZATION SYSTEM ======================
Config.EnableSpecializations = true
Config.SpecializationUnlockLevel = 10
Config.AllowSpecializationReset = true
Config.SpecializationResetCost = 5000

Config.Specializations = {
    blacksmith = {
        label = 'Blacksmith',
        icon = 'fa-solid fa-hammer',
        description = 'Master of metalworking and tool creation',
        color = '#8B4513',
        bonusCategories = {'tools', 'components', 'basic'},
        xpBonus = 0.25,
        successBonus = 0.10,
        qualityBonus = 0.15,
        penaltyCategories = {'electronics', 'chemistry'},
        xpPenalty = 0.15
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
Config.ShowLockedRecipes = true

Config.BlueprintRarity = {
    common = {color = '#AAAAAA', dropRate = 0.15, basePrice = 500},
    uncommon = {color = '#4CAF50', dropRate = 0.08, basePrice = 1500},
    rare = {color = '#2196F3', dropRate = 0.04, basePrice = 5000},
    epic = {color = '#9C27B0', dropRate = 0.02, basePrice = 15000},
    legendary = {color = '#FF9800', dropRate = 0.005, basePrice = 50000}
}

-- ====================== TOOL DURABILITY ======================
Config.EnableToolDurability = true
Config.ShowToolDurability = true
Config.ToolBreakNotification = true

Config.Tools = {
    hammer = {
        label = 'Hammer',
        maxDurability = 100,
        degradePerUse = 2,
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

Config.LevelFailureReduction = {
    enabled = true,
    reductionPerLevel = 0.003,
    maxReduction = 0.80
}

Config.QualityChances = {
    excellent = {baseChance = 0.05, levelBonus = 0.002},
    fine = {baseChance = 0.20, levelBonus = 0.003}
}

Config.GlobalCooldown = 1
Config.RecipeCooldown = 5

-- ====================== ANIMATIONS ======================
Config.Animations = {
    workbench = {dict = 'mini@repair', anim = 'fixing_a_ped', flag = 1},
    electronics_bench = {dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer', flag = 1},
    weapon_bench = {dict = 'mini@repair', anim = 'fixing_a_ped', flag = 1},
    medical_station = {dict = 'mini@sprunk', anim = 'plyr_buy_drink_pt1', flag = 1},
    cooking_station = {dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer', flag = 1}
}

-- ====================== UI SETTINGS ======================
Config.DisableControlsWhileCrafting = true
Config.EnableRecipeSearch = true

-- ====================== BLIP SETTINGS ======================
Config.ShowBlips = true
Config.BlipSprite = 478
Config.BlipColour = 5
Config.BlipScale = 0.7

-- ====================== SECURITY ======================
Config.ServerSideValidation = true
Config.StationProximityCheck = 10.0
Config.AntiExploit = {
    enabled = true,
    maxCraftsPerMinute = 30,
    logSuspiciousActivity = true
}
