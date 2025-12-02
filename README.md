# 🔨 Kurai.Dev Advanced Crafting v3.0

**The definitive crafting solution for QBCore/QBox.**

## ✨ Features

- **100+ Level Progression** with titles (Novice → Legendary)
- **Blueprint Discovery System** - Find/buy blueprints to unlock recipes
- **5 Specializations** - Blacksmith, Engineer, Weaponsmith, Chemist, Chef
- **Tool Durability** - Tools degrade and can be repaired
- **Quality Crafting** - Normal, Fine, Excellent tiers
- **Dynamic Station Props** - Full prop spawning system
- **Recipe Search** - Find recipes instantly
- **Admin Tools** - In-game station management

## 📋 Requirements

- qb-core
- ox_lib
- ox_target
- oxmysql

## 🚀 Installation

1. Place in `resources/[qb]/kurai-crafting/`
2. Import `install.sql` into your database
3. Add to server.cfg:
```cfg
ensure kurai-crafting
```

## 🛠️ Admin Commands

| Command | Description |
|---------|-------------|
| `/addcraftstation [type]` | Create station at your location with prop selection |
| `/managecraftstations` | Open station management UI |
| `/deletecraftstation` | Delete nearest dynamic station |
| `/setcraftinglevel [id] [level]` | Set player level |
| `/givecraftxp [id] [xp]` | Give XP to player |
| `/giveblueprint [id] [recipe]` | Unlock blueprint |

### Station Types
- `workbench`
- `electronics_bench`
- `weapon_bench`
- `medical_station`
- `cooking_station`

## 📦 Prop System

When creating stations with `/addcraftstation`:
- Select from multiple prop models per station type
- Adjust heading (rotation)
- Adjust height offset
- Preview before confirming
- Props persist in database

Set `spawnProp = false` in config for MLO locations with existing furniture.

## 🔧 Config

```lua
Config.SpawnStationProps = true  -- Enable/disable prop spawning
Config.EnableBlueprints = true   -- Require blueprints for recipes
Config.EnableSpecializations = true
Config.EnableToolDurability = true
```

## 📄 License

MIT - Free to use and modify.

---

**Made by Kurai.Dev**
