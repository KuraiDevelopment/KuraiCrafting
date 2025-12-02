# Kurai Crafting System

A modern progression-based crafting system for FiveM (QBCore) with a beautiful React UI.

## Features

- 🎨 Modern React UI with Tailwind CSS
- 📊 Progression system with XP and levels
- 🔧 Crafting stations with ox_target integration
- 💾 MySQL database for persistent player data
- 🎯 Real-time inventory updates
- ⚡ Optimized NUI communication

## Dependencies

- qb-core
- ox_lib
- ox_target
- ox_inventory
- oxmysql

## Installation

1. Clone this repository to your FiveM resources folder
2. Install Node.js dependencies:
   ```bash
   npm install
   ```

3. Build the UI:
   ```bash
   npm run build
   ```

4. Create the database table:
   ```sql
   CREATE TABLE IF NOT EXISTS `bldr_crafting_players` (
     `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
     `xp` INT NOT NULL DEFAULT 0,
     `level` INT NOT NULL DEFAULT 0
   );
   ```

5. Add to your `server.cfg`:
   ```
   ensure KuraiCrafting
   ```

6. Configure crafting stations in `config.lua`

## Development

To watch for changes and auto-rebuild:
```bash
npm run watch
```

## Configuration

Edit `config.lua` to customize:
- Crafting stations locations
- XP requirements
- Progression tiers
- Recipe unlocks

Edit `crafting_items.lua` to add/modify recipes.

## Usage

Players can interact with crafting stations using:
- ox_target interaction
- Press `E` when near a station
- ESC to close the UI

## Credits

Created by BLDR Team & Kurai Development
