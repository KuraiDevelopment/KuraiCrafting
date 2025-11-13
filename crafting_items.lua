-- Advanced Recipe System with Categories, Tools, and Quality
CraftingRecipes = {}

-- ====================== BASIC CRAFTING ======================
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
    skillCheck = {'easy', 'easy'},
    failureChance = 0.02,
    canProduceQuality = false
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
    skillCheck = {'easy'},
    failureChance = 0.05,
    canProduceQuality = false
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
    skillCheck = {'easy', 'easy'},
    failureChance = 0.03,
    canProduceQuality = false
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
    skillCheck = {'easy', 'medium'},
    failureChance = 0.08,
    canProduceQuality = true
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
    result = {item = 'drill', count = 1},
    time = 15000,
    requiredLevel = 15,
    xp = 35,
    requiredTool = 'screwdriver',
    skillCheck = {'medium', 'medium', 'hard'},
    failureChance = 0.12,
    canProduceQuality = true
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
    skillCheck = {'medium', 'hard'},
    failureChance = 0.10,
    canProduceQuality = true
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
    skillCheck = {'easy'},
    failureChance = 0.04,
    canProduceQuality = false
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
    skillCheck = {'medium', 'medium'},
    failureChance = 0.06,
    canProduceQuality = true
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
    skillCheck = {'easy'},
    failureChance = 0.03,
    canProduceQuality = false
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
    requiredTool = 'screwdriver',
    skillCheck = {'medium', 'medium', 'hard'},
    failureChance = 0.15,
    canProduceQuality = true
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
    requiredTool = 'screwdriver',
    skillCheck = {'medium', 'hard', 'hard'},
    failureChance = 0.18,
    canProduceQuality = true
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
    requiredTool = 'screwdriver',
    skillCheck = {'hard', 'hard', 'hard'},
    failureChance = 0.20,
    canProduceQuality = true
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
    skillCheck = {'medium', 'medium'},
    failureChance = 0.10,
    canProduceQuality = true
}

CraftingRecipes['pistol_ammo'] = {
    label = 'Pistol Ammo',
    category = 'weapons',
    description = '9mm ammunition',
    ingredients = {
        {item = 'copper', count = 3},
        {item = 'metalscrap', count = 2},
        {item = 'gunpowder', count = 1}
    },
    result = {item = 'pistol_ammo', count = 50},
    time = 8000,
    requiredLevel = 20,
    xp = 30,
    requiredTool = nil,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = false
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
    skillCheck = {'hard', 'hard', 'hard'},
    failureChance = 0.25,
    canProduceQuality = true
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
    skillCheck = {'hard', 'hard'},
    failureChance = 0.20,
    canProduceQuality = true
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
    skillCheck = {'medium', 'hard'},
    failureChance = 0.15,
    canProduceQuality = true
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
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true
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
    skillCheck = {'medium', 'hard', 'hard'},
    failureChance = 0.10,
    canProduceQuality = true
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
    skillCheck = {'medium', 'medium'},
    failureChance = 0.15,
    canProduceQuality = false
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
    skillCheck = {'easy'},
    failureChance = 0.02,
    canProduceQuality = true
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
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true
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
    skillCheck = {'easy'},
    failureChance = 0.01,
    canProduceQuality = false
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
