# ⚡ Quick Start Guide

## Installation (5 Minutes)

### Step 1: Install Dependencies
```bash
npm install
```

### Step 2: Build the UI
```bash
npm run build
```

### Step 3: Setup Database
Run this SQL in your database:
```sql
CREATE TABLE IF NOT EXISTS `bldr_crafting_players` (
  `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
  `xp` INT NOT NULL DEFAULT 0,
  `level` INT NOT NULL DEFAULT 0
);
```

### Step 4: Add to Server Config
Add to `server.cfg`:
```
ensure KuraiCrafting
```

### Step 5: Start Server & Test
1. Start/restart your FiveM server
2. Join the server
3. Go to coordinates: `-268.0, -956.0, 31.2`
4. Press `E` to open crafting UI

## Done! 🎉

Your crafting system is now live with a modern UI!

## Customize Stations

Edit `config.lua` and add your crafting station locations:
```lua
Config.CraftingStations = {
    {name = 'downtown_bench', coords = vector3(-268.0, -956.0, 31.2), heading = 0.0},
    {name = 'your_station', coords = vector3(x, y, z), heading = 0.0}
}
```

## Need Help?

- 📖 See **README.md** for full documentation
- 🛠️ See **DEVELOPMENT.md** for development guide
- ✅ See **INTEGRATION_COMPLETE.md** for what was integrated

---

Made with ❤️ by Kurai Development
