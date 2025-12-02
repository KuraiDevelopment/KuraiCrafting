-- Shared recipe definitions
-- Each recipe: id, label, ingredients ({item, count}), time (ms), requiredLevel
CraftingRecipes = {
    bandage = {
        label = 'Bandage',
        ingredients = { {item = 'cloth', count = 2} },
        time = 3000,
        requiredLevel = 0
    },
    wood_plank = {
        label = 'Wood Plank',
        ingredients = { {item = 'wood', count = 3} },
        time = 2500,
        requiredLevel = 0
    },
    lockpick = {
        label = 'Lockpick',
        ingredients = { {item = 'metal', count = 2}, {item='tinderbox', count=1} },
        time = 6000,
        requiredLevel = 5
    },
    metal_scrap = {
        label = 'Metal Scrap',
        ingredients = { {item = 'metal', count = 1} },
        time = 2000,
        requiredLevel = 5
    },
    silencer = {
        label = 'Silencer',
        ingredients = { {item = 'metal_scrap', count = 5}, {item='rubber', count=2} },
        time = 12000,
        requiredLevel = 15
    },
    advanced_medkit = {
        label = 'Advanced Medkit',
        ingredients = { {item = 'bandage', count = 2}, {item='painkillers', count=1} },
        time = 10000,
        requiredLevel = 15
    },
    weapon_upgrade = {
        label = 'Weapon Upgrade',
        ingredients = { {item = 'silencer', count = 1}, {item='advanced_parts', count=2} },
        time = 25000,
        requiredLevel = 30
    },
    vehicle_part = {
        label = 'Vehicle Part',
        ingredients = { {item = 'metal_scrap', count = 8}, {item='circuit', count=1} },
        time = 20000,
        requiredLevel = 30
    }
}

-- Admin-editable cache (in-memory); server-side commands will save to DB
AdminRecipeCache = AdminRecipeCache or {}
for k,v in pairs(CraftingRecipes) do AdminRecipeCache[k] = v end
