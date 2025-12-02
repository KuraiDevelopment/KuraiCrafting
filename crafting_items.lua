-- ============================================================================
-- KURAI.DEV CRAFTING RECIPES v3.0
-- ============================================================================

CraftingRecipes = {}

-- ====================== BASIC (No Blueprint Required) ======================
CraftingRecipes['bandage'] = {
    label = 'Bandage',
    category = 'basic',
    description = 'Basic medical supply',
    ingredients = {{item = 'cloth', count = 2}},
    result = {item = 'bandage', count = 1},
    time = 3000,
    requiredLevel = 0,
    xp = 5,
    skillCheck = {'easy'},
    failureChance = 0.02,
    canProduceQuality = false,
    requiresBlueprint = false
}

CraftingRecipes['wood_plank'] = {
    label = 'Wood Plank',
    category = 'basic',
    ingredients = {{item = 'wood', count = 3}},
    result = {item = 'wood_plank', count = 2},
    time = 2500,
    requiredLevel = 0,
    xp = 3,
    requiredTool = 'saw',
    toolDurability = 3,
    skillCheck = {'easy'},
    failureChance = 0.05,
    canProduceQuality = false,
    requiresBlueprint = false
}

CraftingRecipes['rope'] = {
    label = 'Rope',
    category = 'basic',
    ingredients = {{item = 'cloth', count = 5}},
    result = {item = 'rope', count = 1},
    time = 4000,
    requiredLevel = 2,
    xp = 6,
    skillCheck = {'easy', 'easy'},
    failureChance = 0.03,
    canProduceQuality = false,
    requiresBlueprint = false
}

CraftingRecipes['duct_tape'] = {
    label = 'Duct Tape',
    category = 'basic',
    ingredients = {{item = 'cloth', count = 2}, {item = 'plastic_raw', count = 2}},
    result = {item = 'duct_tape', count = 1},
    time = 3000,
    requiredLevel = 3,
    xp = 7,
    skillCheck = {'easy'},
    failureChance = 0.03,
    canProduceQuality = false,
    requiresBlueprint = false
}

-- ====================== TOOLS ======================
CraftingRecipes['lockpick'] = {
    label = 'Lockpick',
    category = 'tools',
    description = 'Used for picking locks',
    ingredients = {{item = 'metalscrap', count = 2}, {item = 'plastic', count = 1}},
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
    ingredients = {{item = 'steel', count = 1}, {item = 'plastic', count = 2}, {item = 'rubber', count = 1}},
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
    blueprintRarity = 'common'
}

CraftingRecipes['hammer_craft'] = {
    label = 'Hammer',
    category = 'tools',
    ingredients = {{item = 'steel', count = 2}, {item = 'wood_plank', count = 1}},
    result = {item = 'hammer', count = 1, metadata = {durability = 100}},
    time = 10000,
    requiredLevel = 10,
    xp = 22,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'uncommon'
}

CraftingRecipes['advanced_lockpick'] = {
    label = 'Advanced Lockpick',
    category = 'tools',
    ingredients = {{item = 'steel', count = 3}, {item = 'rubber', count = 2}, {item = 'lockpick', count = 2}},
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
    blueprintRarity = 'rare'
}

-- ====================== COMPONENTS ======================
CraftingRecipes['metalscrap'] = {
    label = 'Metal Scrap',
    category = 'components',
    ingredients = {{item = 'iron', count = 2}, {item = 'aluminum', count = 1}},
    result = {item = 'metalscrap', count = 3},
    time = 2500,
    requiredLevel = 3,
    xp = 4,
    requiredTool = 'hammer',
    toolDurability = 2,
    skillCheck = {'easy'},
    failureChance = 0.04,
    canProduceQuality = false,
    requiresBlueprint = false
}

CraftingRecipes['steel'] = {
    label = 'Steel',
    category = 'components',
    ingredients = {{item = 'iron', count = 5}, {item = 'coal', count = 2}},
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
    blueprintRarity = 'common'
}

CraftingRecipes['plastic'] = {
    label = 'Plastic',
    category = 'components',
    ingredients = {{item = 'plastic_raw', count = 3}},
    result = {item = 'plastic', count = 2},
    time = 3000,
    requiredLevel = 5,
    xp = 8,
    skillCheck = {'easy'},
    failureChance = 0.03,
    canProduceQuality = false,
    requiresBlueprint = false
}

CraftingRecipes['rubber'] = {
    label = 'Rubber',
    category = 'components',
    ingredients = {{item = 'rubber_raw', count = 3}},
    result = {item = 'rubber', count = 2},
    time = 4000,
    requiredLevel = 6,
    xp = 10,
    skillCheck = {'easy'},
    failureChance = 0.04,
    canProduceQuality = false,
    requiresBlueprint = false
}

CraftingRecipes['gunpowder'] = {
    label = 'Gunpowder',
    category = 'components',
    ingredients = {{item = 'sulfur', count = 2}, {item = 'charcoal', count = 3}, {item = 'potassium_nitrate', count = 1}},
    result = {item = 'gunpowder', count = 2},
    time = 10000,
    requiredLevel = 18,
    xp = 30,
    skillCheck = {'medium', 'hard'},
    failureChance = 0.15,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'rare'
}

-- ====================== ELECTRONICS ======================
CraftingRecipes['electronic_kit'] = {
    label = 'Electronic Kit',
    category = 'electronics',
    ingredients = {{item = 'copper', count = 4}, {item = 'plastic', count = 2}, {item = 'metalscrap', count = 3}},
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
    blueprintRarity = 'uncommon'
}

CraftingRecipes['radio'] = {
    label = 'Radio',
    category = 'electronics',
    ingredients = {{item = 'electronic_kit', count = 1}, {item = 'steel', count = 2}, {item = 'plastic', count = 3}},
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
    blueprintRarity = 'rare'
}

-- ====================== WEAPONS ======================
CraftingRecipes['weapon_knife'] = {
    label = 'Knife',
    category = 'weapons',
    ingredients = {{item = 'steel', count = 2}, {item = 'wood_plank', count = 1}, {item = 'cloth', count = 1}},
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
    blueprintRarity = 'uncommon'
}

CraftingRecipes['weapon_bat'] = {
    label = 'Baseball Bat',
    category = 'weapons',
    ingredients = {{item = 'wood_plank', count = 4}, {item = 'duct_tape', count = 1}},
    result = {item = 'weapon_bat', count = 1},
    time = 6000,
    requiredLevel = 5,
    xp = 15,
    requiredTool = 'saw',
    toolDurability = 4,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true,
    requiresBlueprint = false
}

-- ====================== AMMO ======================
CraftingRecipes['pistol_ammo'] = {
    label = 'Pistol Ammo',
    category = 'ammo',
    ingredients = {{item = 'copper', count = 3}, {item = 'metalscrap', count = 2}, {item = 'gunpowder', count = 1}},
    result = {item = 'pistol_ammo', count = 24},
    time = 8000,
    requiredLevel = 20,
    xp = 30,
    skillCheck = {'medium', 'medium'},
    failureChance = 0.08,
    canProduceQuality = false,
    requiresBlueprint = true,
    blueprintRarity = 'rare'
}

-- ====================== ATTACHMENTS ======================
CraftingRecipes['weapon_suppressor'] = {
    label = 'Weapon Suppressor',
    category = 'attachments',
    ingredients = {{item = 'steel', count = 5}, {item = 'rubber', count = 3}, {item = 'metalscrap', count = 4}},
    result = {item = 'weapon_suppressor', count = 1},
    time = 20000,
    requiredLevel = 40,
    xp = 100,
    requiredTool = 'drill',
    toolDurability = 12,
    skillCheck = {'hard', 'hard', 'hard'},
    failureChance = 0.20,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'epic'
}

CraftingRecipes['weapon_flashlight'] = {
    label = 'Weapon Flashlight',
    category = 'attachments',
    ingredients = {{item = 'electronic_kit', count = 1}, {item = 'glass', count = 1}, {item = 'plastic', count = 2}},
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
    blueprintRarity = 'uncommon'
}

-- ====================== MEDICAL ======================
CraftingRecipes['medkit'] = {
    label = 'Medical Kit',
    category = 'medical',
    ingredients = {{item = 'bandage', count = 3}, {item = 'painkillers', count = 2}, {item = 'plastic', count = 1}},
    result = {item = 'medkit', count = 1},
    time = 8000,
    requiredLevel = 12,
    xp = 25,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'common'
}

CraftingRecipes['ifaks'] = {
    label = 'IFAK',
    category = 'medical',
    ingredients = {{item = 'medkit', count = 1}, {item = 'bandage', count = 4}, {item = 'painkillers', count = 3}},
    result = {item = 'ifaks', count = 1},
    time = 15000,
    requiredLevel = 30,
    xp = 70,
    skillCheck = {'medium', 'hard', 'hard'},
    failureChance = 0.10,
    canProduceQuality = true,
    requiresBlueprint = true,
    blueprintRarity = 'rare'
}

-- ====================== CHEMISTRY ======================
CraftingRecipes['painkillers'] = {
    label = 'Painkillers',
    category = 'chemistry',
    ingredients = {{item = 'chemical_base', count = 1}, {item = 'herbs', count = 2}},
    result = {item = 'painkillers', count = 3},
    time = 6000,
    requiredLevel = 8,
    xp = 15,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.08,
    canProduceQuality = false,
    requiresBlueprint = false
}

-- ====================== FOOD ======================
CraftingRecipes['sandwich'] = {
    label = 'Sandwich',
    category = 'food',
    ingredients = {{item = 'bread', count = 2}, {item = 'meat', count = 1}, {item = 'lettuce', count = 1}},
    result = {item = 'sandwich', count = 1},
    time = 4000,
    requiredLevel = 0,
    xp = 5,
    skillCheck = {'easy'},
    failureChance = 0.02,
    canProduceQuality = true,
    requiresBlueprint = false
}

CraftingRecipes['burger'] = {
    label = 'Burger',
    category = 'food',
    ingredients = {{item = 'bread', count = 2}, {item = 'meat', count = 2}, {item = 'cheese', count = 1}},
    result = {item = 'burger', count = 1},
    time = 6000,
    requiredLevel = 5,
    xp = 10,
    skillCheck = {'easy', 'medium'},
    failureChance = 0.05,
    canProduceQuality = true,
    requiresBlueprint = false
}

-- ====================== DRINKS ======================
CraftingRecipes['coffee'] = {
    label = 'Coffee',
    category = 'drinks',
    ingredients = {{item = 'coffee_beans', count = 2}, {item = 'water', count = 1}},
    result = {item = 'coffee', count = 1},
    time = 3000,
    requiredLevel = 0,
    xp = 3,
    skillCheck = {'easy'},
    failureChance = 0.01,
    canProduceQuality = false,
    requiresBlueprint = false
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

function GetRecipeById(id)
    return CraftingRecipes[id]
end

function SearchRecipes(searchTerm)
    local results = {}
    local term = string.lower(searchTerm)
    for id, recipe in pairs(CraftingRecipes) do
        if string.find(string.lower(recipe.label), term) then
            results[id] = recipe
        end
    end
    return results
end
