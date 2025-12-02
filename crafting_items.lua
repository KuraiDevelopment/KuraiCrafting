-- ============================================================================
-- KURAI.DEV ADVANCED CRAFTING RECIPES v3.0
-- Complete recipe system with blueprints, tool durability, and quality tiers
-- ============================================================================

CraftingRecipes = {}

-- ====================== BASIC CRAFTING ======================
-- These recipes are available without blueprints (starter recipes)

CraftingRecipes['bandage'] = {
    label = 'Bandage',
    category = 'basic',
    description = 'Basic medical supply for minor wounds',
    ingredients = {
        {item = 'cloth', count = 2},
        {item = 'water', count = 1}
    },
    result = {item = 'bandage', count = 1},
    time = 3000,
    requiredLevel = 0,
    xp = 5,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy', 'easy'},
    failureChance = 0.02,
    canProduceQuality = false,
    requiresBlueprint = false,  -- Starter recipe
    blueprintRarity = nil
}

CraftingRecipes['wood_plank'] = {
    label = 'Wood Plank',
    category = 'basic',
    description = 'Processed wooden plank for construction',
    ingredients = {
        {item = 'wood', count = 3}
    },
    result = {item = 'wood_plank', count = 2},
    time = 2500,
    requiredLevel = 0,
    xp = 3,
    requiredTool = 'saw',
    toolDurability = 3,
    skillCheck = {'easy'},
    failureChance = 0.05,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['rope'] = {
    label = 'Rope',
    category = 'basic',
    description = 'Strong rope for various uses',
    ingredients = {
        {item = 'cloth', count = 5}
    },
    result = {item = 'rope', count = 1},
    time = 4000,
    requiredLevel = 2,
    xp = 6,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy', 'easy'},
    failureChance = 0.03,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['duct_tape'] = {
    label = 'Duct Tape',
    category = 'basic',
    description = 'Universal repair material',
    ingredients = {
        {item = 'cloth', count = 2},
        {item = 'plastic_raw', count = 2}
    },
    result = {item = 'duct_tape', count = 1},
    time = 3000,
    requiredLevel = 3,
    xp = 7,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy'},
    failureChance = 0.03,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

-- ====================== TOOLS ======================

CraftingRecipes['lockpick'] = {
    label = 'Lockpick',
    category = 'tools',
    description = 'Used for picking locks',
    ingredients = {
        {item = 'metalscrap', count = 2},
        {item = 'plastic', count = 1}
    },
    result = {item = 'lockpick', count = 1},
    time = 6000,
    requiredLevel = 5,
    xp = 12,
    requiredTool = 'screwdriver',
    toolDurability = 5,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.08,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'common',
    blueprintItem = 'blueprint_lockpick'
}

CraftingRecipes['screwdriver_craft'] = {
    label = 'Screwdriver',
    category = 'tools',
    description = 'Essential tool for electronics and crafting',
    ingredients = {
        {item = 'steel', count = 1},
        {item = 'plastic', count = 2},
        {item = 'rubber', count = 1}
    },
    result = {item = 'screwdriver', count = 1, metadata = {durability = 80}},
    time = 8000,
    requiredLevel = 8,
    xp = 18,
    requiredTool = 'hammer',
    toolDurability = 4,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.06,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'common',
    blueprintItem = 'blueprint_screwdriver'
}

CraftingRecipes['hammer_craft'] = {
    label = 'Hammer',
    category = 'tools',
    description = 'Heavy tool for metalworking',
    ingredients = {
        {item = 'steel', count = 2},
        {item = 'wood_plank', count = 1}
    },
    result = {item = 'hammer', count = 1, metadata = {durability = 100}},
    time = 10000,
    requiredLevel = 10,
    xp = 22,
    requiredTool = nil,  -- Can make without tools
    toolDurability = 0,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_hammer'
}

CraftingRecipes['drill'] = {
    label = 'Drill',
    category = 'tools',
    description = 'Power tool for drilling',
    ingredients = {
        {item = 'steel', count = 4},
        {item = 'plastic', count = 3},
        {item = 'electronic_kit', count = 1}
    },
    result = {item = 'drill', count = 1, metadata = {durability = 50}},
    time = 15000,
    requiredLevel = 15,
    xp = 35,
    requiredTool = 'screwdriver',
    toolDurability = 8,
    skillCheck = {'medium', 'medium', 'hard'},
    failureChance = 0.12,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_drill'
}

CraftingRecipes['advanced_lockpick'] = {
    label = 'Advanced Lockpick',
    category = 'tools',
    description = 'Professional lockpick with higher success rate',
    ingredients = {
        {item = 'steel', count = 3},
        {item = 'rubber', count = 2},
        {item = 'lockpick', count = 2}
    },
    result = {item = 'advancedlockpick', count = 1},
    time = 10000,
    requiredLevel = 25,
    xp = 45,
    requiredTool = 'screwdriver',
    toolDurability = 6,
    skillCheck = {'medium', 'hard'},
    failureChance = 0.10,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_advancedlockpick'
}

CraftingRecipes['thermite'] = {
    label = 'Thermite',
    category = 'tools',
    description = 'High-temperature cutting compound',
    ingredients = {
        {item = 'aluminum', count = 5},
        {item = 'iron_oxide', count = 3},
        {item = 'magnesium', count = 2}
    },
    result = {item = 'thermite', count = 1},
    time = 20000,
    requiredLevel = 40,
    xp = 80,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'hard', 'hard', 'hard'},
    failureChance = 0.20,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'epic',
    blueprintItem = 'blueprint_thermite'
}

-- ====================== COMPONENTS ======================

CraftingRecipes['metalscrap'] = {
    label = 'Metal Scrap',
    category = 'components',
    description = 'Processed metal scrap',
    ingredients = {
        {item = 'iron', count = 2},
        {item = 'aluminum', count = 1}
    },
    result = {item = 'metalscrap', count = 3},
    time = 2500,
    requiredLevel = 3,
    xp = 4,
    requiredTool = 'hammer',
    toolDurability = 2,
    skillCheck = {'easy'},
    failureChance = 0.04,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['steel'] = {
    label = 'Steel',
    category = 'components',
    description = 'High-quality steel material',
    ingredients = {
        {item = 'iron', count = 5},
        {item = 'coal', count = 2}
    },
    result = {item = 'steel', count = 2},
    time = 8000,
    requiredLevel = 10,
    xp = 20,
    requiredTool = 'hammer',
    toolDurability = 4,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.06,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'common',
    blueprintItem = 'blueprint_steel'
}

CraftingRecipes['plastic'] = {
    label = 'Plastic',
    category = 'components',
    description = 'Molded plastic material',
    ingredients = {
        {item = 'plastic_raw', count = 3}
    },
    result = {item = 'plastic', count = 2},
    time = 3000,
    requiredLevel = 5,
    xp = 8,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy'},
    failureChance = 0.03,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['glass'] = {
    label = 'Glass',
    category = 'components',
    description = 'Refined glass for precision work',
    ingredients = {
        {item = 'sand', count = 4},
        {item = 'coal', count = 1}
    },
    result = {item = 'glass', count = 2},
    time = 6000,
    requiredLevel = 12,
    xp = 15,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium'},
    failureChance = 0.10,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_glass'
}

CraftingRecipes['rubber'] = {
    label = 'Rubber',
    category = 'components',
    description = 'Processed rubber material',
    ingredients = {
        {item = 'rubber_raw', count = 3}
    },
    result = {item = 'rubber', count = 2},
    time = 4000,
    requiredLevel = 6,
    xp = 10,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy'},
    failureChance = 0.04,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['gunpowder'] = {
    label = 'Gunpowder',
    category = 'components',
    description = 'Explosive propellant for ammunition',
    ingredients = {
        {item = 'sulfur', count = 2},
        {item = 'charcoal', count = 3},
        {item = 'potassium_nitrate', count = 1}
    },
    result = {item = 'gunpowder', count = 2},
    time = 10000,
    requiredLevel = 18,
    xp = 30,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'hard'},
    failureChance = 0.15,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_gunpowder'
}

-- ====================== ELECTRONICS ======================

CraftingRecipes['electronic_kit'] = {
    label = 'Electronic Kit',
    category = 'electronics',
    description = 'Basic electronics assembly kit',
    ingredients = {
        {item = 'copper', count = 4},
        {item = 'plastic', count = 2},
        {item = 'metalscrap', count = 3}
    },
    result = {item = 'electronic_kit', count = 1},
    time = 12000,
    requiredLevel = 15,
    xp = 30,
    requiredTool = 'soldering_iron',
    toolDurability = 6,
    skillCheck = {'medium', 'medium', 'hard'},
    failureChance = 0.15,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_electronic_kit'
}

CraftingRecipes['radio'] = {
    label = 'Radio',
    category = 'electronics',
    description = 'Two-way communication radio',
    ingredients = {
        {item = 'electronic_kit', count = 1},
        {item = 'steel', count = 2},
        {item = 'plastic', count = 3}
    },
    result = {item = 'radio', count = 1},
    time = 18000,
    requiredLevel = 20,
    xp = 50,
    requiredTool = 'soldering_iron',
    toolDurability = 8,
    skillCheck = {'medium', 'hard', 'hard'},
    failureChance = 0.18,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_radio'
}

CraftingRecipes['phone'] = {
    label = 'Phone',
    category = 'electronics',
    description = 'Mobile communication device',
    ingredients = {
        {item = 'electronic_kit', count = 2},
        {item = 'plastic', count = 3},
        {item = 'glass', count = 1}
    },
    result = {item = 'phone', count = 1},
    time = 25000,
    requiredLevel = 35,
    xp = 80,
    requiredTool = 'soldering_iron',
    toolDurability = 10,
    skillCheck = {'hard', 'hard', 'hard'},
    failureChance = 0.20,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'epic',
    blueprintItem = 'blueprint_phone'
}

CraftingRecipes['hacking_device'] = {
    label = 'Hacking Device',
    category = 'electronics',
    description = 'Advanced electronic intrusion tool',
    ingredients = {
        {item = 'electronic_kit', count = 3},
        {item = 'phone', count = 1},
        {item = 'laptop_parts', count = 2}
    },
    result = {item = 'hacking_device', count = 1},
    time = 35000,
    requiredLevel = 50,
    xp = 150,
    requiredTool = 'soldering_iron',
    toolDurability = 15,
    skillCheck = {'hard', 'hard', 'hard', 'hard'},
    failureChance = 0.25,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'legendary',
    blueprintItem = 'blueprint_hacking_device'
}

-- ====================== WEAPONS ======================

CraftingRecipes['weapon_knife'] = {
    label = 'Knife',
    category = 'weapons',
    description = 'Sharp melee weapon',
    ingredients = {
        {item = 'steel', count = 2},
        {item = 'wood_plank', count = 1},
        {item = 'cloth', count = 1}
    },
    result = {item = 'weapon_knife', count = 1},
    time = 10000,
    requiredLevel = 10,
    xp = 25,
    requiredTool = 'hammer',
    toolDurability = 6,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.10,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_knife'
}

CraftingRecipes['weapon_bat'] = {
    label = 'Baseball Bat',
    category = 'weapons',
    description = 'Wooden blunt weapon',
    ingredients = {
        {item = 'wood_plank', count = 4},
        {item = 'duct_tape', count = 1}
    },
    result = {item = 'weapon_bat', count = 1},
    time = 6000,
    requiredLevel = 5,
    xp = 15,
    requiredTool = 'saw',
    toolDurability = 4,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['weapon_machete'] = {
    label = 'Machete',
    category = 'weapons',
    description = 'Large cutting blade',
    ingredients = {
        {item = 'steel', count = 4},
        {item = 'wood_plank', count = 1},
        {item = 'rubber', count = 1}
    },
    result = {item = 'weapon_machete', count = 1},
    time = 15000,
    requiredLevel = 20,
    xp = 40,
    requiredTool = 'hammer',
    toolDurability = 8,
    skillCheck = {'medium', 'hard'},
    failureChance = 0.12,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_machete'
}

-- ====================== AMMO ======================

CraftingRecipes['pistol_ammo'] = {
    label = 'Pistol Ammo',
    category = 'ammo',
    description = '9mm ammunition box',
    ingredients = {
        {item = 'copper', count = 3},
        {item = 'metalscrap', count = 2},
        {item = 'gunpowder', count = 1}
    },
    result = {item = 'pistol_ammo', count = 24},
    time = 8000,
    requiredLevel = 20,
    xp = 30,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_pistol_ammo'
}

CraftingRecipes['rifle_ammo'] = {
    label = 'Rifle Ammo',
    category = 'ammo',
    description = '5.56mm ammunition box',
    ingredients = {
        {item = 'copper', count = 5},
        {item = 'steel', count = 2},
        {item = 'gunpowder', count = 2}
    },
    result = {item = 'rifle_ammo', count = 30},
    time = 12000,
    requiredLevel = 30,
    xp = 50,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'hard'},
    failureChance = 0.10,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'epic',
    blueprintItem = 'blueprint_rifle_ammo'
}

CraftingRecipes['shotgun_ammo'] = {
    label = 'Shotgun Shells',
    category = 'ammo',
    description = '12 gauge ammunition',
    ingredients = {
        {item = 'copper', count = 4},
        {item = 'plastic', count = 2},
        {item = 'gunpowder', count = 1},
        {item = 'metalscrap', count = 3}
    },
    result = {item = 'shotgun_ammo', count = 12},
    time = 10000,
    requiredLevel = 25,
    xp = 40,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_shotgun_ammo'
}

-- ====================== ATTACHMENTS ======================

CraftingRecipes['weapon_suppressor'] = {
    label = 'Weapon Suppressor',
    category = 'attachments',
    description = 'Reduces weapon sound',
    ingredients = {
        {item = 'steel', count = 5},
        {item = 'rubber', count = 3},
        {item = 'metalscrap', count = 4}
    },
    result = {item = 'weapon_suppressor', count = 1},
    time = 20000,
    requiredLevel = 40,
    xp = 100,
    requiredTool = 'drill',
    toolDurability = 12,
    skillCheck = {'hard', 'hard', 'hard'},
    failureChance = 0.20,  -- Reduced from 0.25, further reduced by level
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'epic',
    blueprintItem = 'blueprint_suppressor'
}

CraftingRecipes['weapon_scope'] = {
    label = 'Weapon Scope',
    category = 'attachments',
    description = 'Increases weapon accuracy',
    ingredients = {
        {item = 'steel', count = 3},
        {item = 'glass', count = 2},
        {item = 'plastic', count = 2}
    },
    result = {item = 'weapon_scope', count = 1},
    time = 15000,
    requiredLevel = 35,
    xp = 75,
    requiredTool = 'screwdriver',
    toolDurability = 8,
    skillCheck = {'hard', 'hard'},
    failureChance = 0.18,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_scope'
}

CraftingRecipes['weapon_grip'] = {
    label = 'Weapon Grip',
    category = 'attachments',
    description = 'Improves weapon handling',
    ingredients = {
        {item = 'plastic', count = 4},
        {item = 'rubber', count = 2},
        {item = 'metalscrap', count = 1}
    },
    result = {item = 'weapon_grip', count = 1},
    time = 10000,
    requiredLevel = 25,
    xp = 40,
    requiredTool = 'screwdriver',
    toolDurability = 5,
    skillCheck = {'medium', 'hard'},
    failureChance = 0.12,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_grip'
}

CraftingRecipes['weapon_flashlight'] = {
    label = 'Weapon Flashlight',
    category = 'attachments',
    description = 'Tactical flashlight attachment',
    ingredients = {
        {item = 'electronic_kit', count = 1},
        {item = 'glass', count = 1},
        {item = 'plastic', count = 2}
    },
    result = {item = 'weapon_flashlight', count = 1},
    time = 8000,
    requiredLevel = 18,
    xp = 30,
    requiredTool = 'screwdriver',
    toolDurability = 4,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.10,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_flashlight'
}

-- ====================== MEDICAL ======================

CraftingRecipes['medkit'] = {
    label = 'Medical Kit',
    category = 'medical',
    description = 'Advanced medical supplies',
    ingredients = {
        {item = 'bandage', count = 3},
        {item = 'painkillers', count = 2},
        {item = 'plastic', count = 1}
    },
    result = {item = 'medkit', count = 1},
    time = 8000,
    requiredLevel = 12,
    xp = 25,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'common',
    blueprintItem = 'blueprint_medkit'
}

CraftingRecipes['ifaks'] = {
    label = 'IFAK',
    category = 'medical',
    description = 'Individual First Aid Kit',
    ingredients = {
        {item = 'medkit', count = 1},
        {item = 'bandage', count = 4},
        {item = 'painkillers', count = 3},
        {item = 'plastic', count = 2}
    },
    result = {item = 'ifaks', count = 1},
    time = 15000,
    requiredLevel = 30,
    xp = 70,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'hard', 'hard'},
    failureChance = 0.10,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare',
    blueprintItem = 'blueprint_ifak'
}

CraftingRecipes['adrenaline'] = {
    label = 'Adrenaline Shot',
    category = 'medical',
    description = 'Emergency revival medication',
    ingredients = {
        {item = 'chemical_base', count = 2},
        {item = 'epinephrine', count = 1},
        {item = 'syringe', count = 1}
    },
    result = {item = 'adrenaline', count = 1},
    time = 12000,
    requiredLevel = 40,
    xp = 60,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'hard', 'hard'},
    failureChance = 0.15,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'epic',
    blueprintItem = 'blueprint_adrenaline'
}

-- ====================== CHEMISTRY ======================

CraftingRecipes['chemical_base'] = {
    label = 'Chemical Base',
    category = 'chemistry',
    description = 'Basic chemical compound',
    ingredients = {
        {item = 'water', count = 3},
        {item = 'chemical_powder', count = 2}
    },
    result = {item = 'chemical_base', count = 2},
    time = 10000,
    requiredLevel = 18,
    xp = 35,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.15,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_chemical_base'
}

CraftingRecipes['painkillers'] = {
    label = 'Painkillers',
    category = 'chemistry',
    description = 'Pain relief medication',
    ingredients = {
        {item = 'chemical_base', count = 1},
        {item = 'herbs', count = 2}
    },
    result = {item = 'painkillers', count = 3},
    time = 6000,
    requiredLevel = 8,
    xp = 15,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.08,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

-- ====================== FOOD & DRINKS ======================

CraftingRecipes['sandwich'] = {
    label = 'Sandwich',
    category = 'food',
    description = 'Freshly made sandwich',
    ingredients = {
        {item = 'bread', count = 2},
        {item = 'meat', count = 1},
        {item = 'lettuce', count = 1}
    },
    result = {item = 'sandwich', count = 1},
    time = 4000,
    requiredLevel = 0,
    xp = 5,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy'},
    failureChance = 0.02,
    canProduceQuality = true,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['burger'] = {
    label = 'Burger',
    category = 'food',
    description = 'Delicious burger',
    ingredients = {
        {item = 'bread', count = 2},
        {item = 'meat', count = 2},
        {item = 'cheese', count = 1},
        {item = 'lettuce', count = 1}
    },
    result = {item = 'burger', count = 1},
    time = 6000,
    requiredLevel = 5,
    xp = 10,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['steak_dinner'] = {
    label = 'Steak Dinner',
    category = 'food',
    description = 'Premium cooked steak with sides',
    ingredients = {
        {item = 'raw_steak', count = 1},
        {item = 'potato', count = 2},
        {item = 'butter', count = 1},
        {item = 'seasoning', count = 1}
    },
    result = {item = 'steak_dinner', count = 1},
    time = 12000,
    requiredLevel = 15,
    xp = 25,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon',
    blueprintItem = 'blueprint_steak_dinner'
}

CraftingRecipes['coffee'] = {
    label = 'Coffee',
    category = 'drinks',
    description = 'Hot coffee',
    ingredients = {
        {item = 'coffee_beans', count = 2},
        {item = 'water', count = 1}
    },
    result = {item = 'coffee', count = 1},
    time = 3000,
    requiredLevel = 0,
    xp = 3,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy'},
    failureChance = 0.01,
    canProduceQuality = false,
    requiresBlueprint = false,
    blueprintRarity = nil
}

CraftingRecipes['energy_drink'] = {
    label = 'Energy Drink',
    category = 'drinks',
    description = 'Homemade energy booster',
    ingredients = {
        {item = 'water', count = 2},
        {item = 'sugar', count = 2},
        {item = 'caffeine', count = 1}
    },
    result = {item = 'energy_drink', count = 2},
    time = 5000,
    requiredLevel = 8,
    xp = 12,
    requiredTool = nil,
    toolDurability = 0,
    skillCheck = {'easy', 'easy'},
    failureChance = 0.04,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'common',
    blueprintItem = 'blueprint_energy_drink'
}

-- ====================== UTILITY FUNCTIONS ======================

function GetRecipesByCategory(category)
    local recipes = {}
    for id, recipe in pairs(CraftingRecipes) do
        if recipe.category == category then
            recipes[id] = recipe
        end
    end
    return recipes
end

function GetRecipesByLevel(level)
    local recipes = {}
    for id, recipe in pairs(CraftingRecipes) do
        if recipe.requiredLevel <= level then
            recipes[id] = recipe
        end
    end
    return recipes
end

function GetRecipeById(id)
    return CraftingRecipes[id]
end

function GetRecipesRequiringBlueprint()
    local recipes = {}
    for id, recipe in pairs(CraftingRecipes) do
        if recipe.requiresBlueprint then
            recipes[id] = recipe
        end
    end
    return recipes
end

function GetStarterRecipes()
    local recipes = {}
    for id, recipe in pairs(CraftingRecipes) do
        if not recipe.requiresBlueprint then
            recipes[id] = recipe
        end
    end
    return recipes
end

function GetRecipesByRarity(rarity)
    local recipes = {}
    for id, recipe in pairs(CraftingRecipes) do
        if recipe.blueprintRarity == rarity then
            recipes[id] = recipe
        end
    end
    return recipes
end

function SearchRecipes(searchTerm)
    local results = {}
    local term = string.lower(searchTerm)
    
    for id, recipe in pairs(CraftingRecipes) do
        if string.find(string.lower(recipe.label), term) or
           string.find(string.lower(recipe.description or ''), term) or
           string.find(string.lower(recipe.category), term) then
            results[id] = recipe
        end
    end
    
    return results
end
