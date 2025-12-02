# 🔨 Kurai.Dev Advanced Crafting System v3.0

**The definitive crafting solution for QBCore/QBox servers.**

![Version](https://img.shields.io/badge/version-3.0.0-blue)
![Framework](https://img.shields.io/badge/framework-QBCore%20%7C%20QBox-green)
![License](https://img.shields.io/badge/license-MIT-yellow)

---

## ✨ Features

### 🎯 Core Systems
- **100+ Level Progression** - From Novice to Legendary with meaningful milestones
- **5 Station Types** - Workbench, Electronics, Weapons, Medical, Cooking
- **50+ Recipes** - Comprehensive recipe library across 10 categories
- **Quality Crafting** - Normal, Fine, and Excellent quality tiers
- **Skill Checks** - ox_lib skill checks for engaging gameplay

### 🆕 NEW in v3.0

#### 📜 Blueprint Discovery System
- Recipes are locked behind discoverable blueprints
- 5 rarity tiers: Common, Uncommon, Rare, Epic, Legendary
- Starter recipes available without blueprints
- Blueprints can be found as loot, purchased from NPCs, or earned
- Creates real progression goals beyond just leveling

#### ⭐ Specialization System
- Choose your crafting focus at level 10
- **5 Specializations:**
  - 🔨 **Blacksmith** - Tools & components expert
  - ⚡ **Engineer** - Electronics specialist  
  - 🔫 **Weaponsmith** - Weapons & attachments master
  - 🧪 **Chemist** - Medical & chemistry focus
  - 🍳 **Chef** - Food & drinks expertise
- Bonus XP, success rate, and quality in your specialty
- Reduced XP in opposing categories (tradeoffs matter)
- Reset available for a fee

#### 🔧 Tool Durability System
- Tools degrade with use
- Different degradation rates per tool
- Repair system with materials
- Quality crafted tools last longer
- Creates ongoing economy demand

#### 🔍 Recipe Search
- Search recipes by name or description
- Filter through 50+ recipes instantly
- Find what you need without menu diving

#### 🛡️ Security Hardened
- Server-side station proximity validation
- Anti-exploit rate limiting
- Fixed async race conditions
- Proper MySQL.await patterns throughout

---

## 📋 Requirements

| Dependency | Required |
|------------|----------|
| [qb-core](https://github.com/qbcore-framework/qb-core) | ✅ |
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ |
| [ox_target](https://github.com/overextended/ox_target) | ✅ |
| [oxmysql](https://github.com/overextended/oxmysql) | ✅ |

---

## 🚀 Installation

### 1. Download & Extract
```bash
# Place in your resources folder
resources/[qb]/kurai-crafting/
```

### 2. Import Database
```sql
-- Run install.sql in your MySQL database
source install.sql;
```

### 3. Add to server.cfg
```cfg
ensure ox_lib
ensure ox_target
ensure oxmysql
ensure qb-core
ensure kurai-crafting
```

### 4. Configure
Edit `config.lua` to customize:
- Station locations
- XP multipliers
- Specialization bonuses
- Tool durability rates
- And more!

---

## 📖 Usage

### Player Commands
| Command | Description |
|---------|-------------|
| `/craftinglevel` | Check your crafting level, XP, and specialization |

### Admin Commands
| Command | Permission | Description |
|---------|------------|-------------|
| `/setcraftinglevel [id] [level]` | admin | Set player's crafting level |
| `/givecraftxp [id] [amount]` | admin | Give crafting XP to player |
| `/giveblueprint [id] [recipe]` | admin | Unlock a blueprint for player |
| `/listrecipes` | admin | Print all recipe IDs to console |
| `/addcraftstation [type]` | admin | Create a dynamic station at your location |
| `/managecraftstations` | admin | Open station management menu |
| `/deletecraftstation` | admin | Delete nearest dynamic station |

---

## 🔧 Exports

### Server-Side
```lua
-- Get player's crafting level
exports['kurai-crafting']:GetPlayerCraftingLevel(source)

-- Get player's current XP
exports['kurai-crafting']:GetPlayerCraftingXP(source)

-- Get full crafting data
exports['kurai-crafting']:GetPlayerCraftingData(source)

-- Get player's specialization
exports['kurai-crafting']:GetPlayerSpecialization(source)

-- Check if player has a blueprint
exports['kurai-crafting']:HasBlueprint(source, recipeId)

-- Unlock a blueprint for player
exports['kurai-crafting']:UnlockBlueprint(source, recipeId)

-- Add a custom recipe at runtime
exports['kurai-crafting']:AddRecipe(recipeId, recipeData)

-- Remove a recipe
exports['kurai-crafting']:RemoveRecipe(recipeId)

-- Get tool durability
exports['kurai-crafting']:GetToolDurability(source, toolName)
```

---

## 📜 Adding Custom Recipes

### Basic Recipe Structure
```lua
CraftingRecipes['my_custom_item'] = {
    label = 'Custom Item',
    category = 'basic',                    -- Category for menu grouping
    description = 'A custom crafted item',
    ingredients = {
        {item = 'metalscrap', count = 2},
        {item = 'plastic', count = 1}
    },
    result = {item = 'custom_item', count = 1},
    time = 5000,                           -- Craft time in ms
    requiredLevel = 10,                    -- Minimum level
    xp = 25,                               -- XP awarded
    requiredTool = 'screwdriver',          -- nil if no tool needed
    toolDurability = 5,                    -- How much tool degrades
    skillCheck = {'easy', 'medium'},       -- Skill check difficulty
    failureChance = 0.10,                  -- Base failure rate (10%)
    canProduceQuality = true,              -- Can craft fine/excellent
    requiresBlueprint = true,              -- Needs blueprint to unlock
    blueprintRarity = 'uncommon',          -- Blueprint rarity tier
    blueprintItem = 'blueprint_custom'     -- Item that unlocks this
}
```

### Adding via Export (Runtime)
```lua
-- In another resource
exports['kurai-crafting']:AddRecipe('gang_lockpick', {
    label = 'Gang Lockpick',
    category = 'tools',
    description = 'Special lockpick for gang activities',
    ingredients = {
        {item = 'lockpick', count = 2},
        {item = 'gold', count = 1}
    },
    result = {item = 'gang_lockpick', count = 1},
    time = 10000,
    requiredLevel = 30,
    xp = 50,
    requiresBlueprint = false  -- Available immediately
})
```

---

## 🏪 Blueprint Integration

### Creating Blueprint Items
Add to your `qb-core/shared/items.lua`:
```lua
['blueprint_lockpick'] = {
    name = 'blueprint_lockpick',
    label = 'Lockpick Blueprint',
    weight = 100,
    type = 'item',
    image = 'blueprint_lockpick.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A blueprint for crafting lockpicks'
},
```

### Blueprint Usage Handler
The script automatically handles blueprint items. When used, they unlock the corresponding recipe.

### Adding Blueprints to Loot Tables
```lua
-- Example for qb-lootables or similar
{item = 'blueprint_lockpick', chance = 15},  -- 15% drop chance
{item = 'blueprint_suppressor', chance = 2}, -- 2% for rare blueprints
```

---

## ⚙️ Configuration Examples

### Adjusting XP Rates
```lua
Config.XPMultipliers = {
    base = 1.0,
    groupBonus = 0.1,        -- +10% per nearby player
    qualityBonus = 0.25,     -- +25% for quality crafts
    firstTimeBonus = 2.0,    -- 2x XP first time crafting recipe
    streakBonus = 0.05,      -- +5% per consecutive craft (max 10)
    specializationBonus = 0.25
}
```

### Custom Specialization
```lua
Config.Specializations['mechanic'] = {
    label = 'Mechanic',
    icon = 'fa-solid fa-car',
    description = 'Vehicle parts and repair specialist',
    color = '#4169E1',
    bonusCategories = {'vehicles', 'components'},
    xpBonus = 0.30,
    successBonus = 0.15,
    qualityBonus = 0.20,
    penaltyCategories = {'food', 'medical'},
    xpPenalty = 0.15
}
```

### Tool Configuration
```lua
Config.Tools['wrench'] = {
    label = 'Wrench',
    maxDurability = 75,
    degradePerUse = 3,
    repairItem = 'steel',
    repairAmount = 2,
    repairRestores = 30
}
```

---

## 📊 Database Views

The installation creates useful analytics views:

| View | Description |
|------|-------------|
| `crafting_leaderboard` | Top 100 crafters by level |
| `popular_recipes` | Most crafted recipes with success rates |
| `blueprint_stats` | Blueprint distribution across players |
| `specialization_distribution` | Player specialization breakdown |
| `recent_crafting_activity` | Last 100 crafts with details |
| `player_crafting_summary` | Full summary per player |

---

## 🔒 Security Features

- ✅ Server-side ingredient validation
- ✅ Station proximity verification (prevents remote crafting exploits)
- ✅ Anti-exploit rate limiting (configurable max crafts per minute)
- ✅ Synchronous database operations (no race conditions)
- ✅ Blueprint ownership validation
- ✅ Tool durability server-side tracking

---

## 🐛 Troubleshooting

### Recipes not showing?
1. Check station type matches recipe category
2. Verify player level meets requirement
3. Confirm blueprint is unlocked (if required)

### Tool not degrading?
1. Enable `Config.EnableToolDurability = true`
2. Ensure tool has `durability` metadata
3. Check recipe has `toolDurability > 0`

### Station zones not working?
1. Restart ox_target
2. Check coordinates in config
3. Enable debug mode to see zones

---

## 📝 Changelog

### v3.0.0
- ✨ Added Blueprint Discovery System
- ✨ Added Specialization System (5 paths)
- ✨ Added Tool Durability System
- ✨ Added Recipe Search
- 🔒 Fixed station type exploit (server-side validation)
- 🔒 Fixed race condition in data loading
- 🔒 Fixed DeleteStation async return bug
- 🔒 Added anti-exploit rate limiting
- ⚡ Implemented first-time craft bonus
- ⚡ Level-based failure reduction
- 📊 Added comprehensive analytics views

### v2.0.0
- Initial public release
- Basic progression system
- Quality crafting
- Dynamic stations

---

## 📄 License

MIT License - Free to use and modify.

---

## 💬 Support

- **Discord:** [Kurai.Dev Community](https://discord.gg/kurai)
- **Issues:** GitHub Issues
- **Documentation:** This README + inline code comments

---

**Made with ❤️ by Kurai.Dev**

*The definitive crafting solution for QBCore/QBox*
