# Advanced Progression Crafting System

A detailed and progression-based crafting script for FiveM QBCore/QBox framework with multiple station types, skill checks, quality system, and persistent progression.

## 🌟 Features

### Core Systems
- **Multi-Station Crafting**: Different station types (Workbench, Electronics, Weapons, Medical, Cooking)
- **Progressive Leveling**: 100+ levels with dynamic XP scaling
- **Category System**: Recipes organized by categories with station-specific access
- **Quality Crafting**: Items can be crafted in Normal, Fine, or Excellent quality
- **Skill Checks**: Optional ox_lib skill checks for immersive crafting
- **Tool Requirements**: Certain recipes require specific tools in inventory
- **Failure System**: Configurable chance to fail and lose materials

### Progression
- **Dynamic XP System**: XP formula: `(level^1.5) * 100 + 200`
- **8 Progression Tiers**: Novice → Legendary
- **Streak Bonuses**: Craft same items consecutively for bonus XP
- **Achievement Ready**: Database structure for future achievement system
- **Persistent Stats**: All progress saved to MySQL database

### UI/UX
- **Modern Context Menu**: Category-based navigation with ox_lib
- **Progress Bars**: Visual feedback during crafting
- **Detailed Tooltips**: Shows ingredients, requirements, and XP
- **Level Indicators**: Clear visual indicators for locked recipes
- **Blip System**: Optional map markers for crafting stations

### Admin Features
- **Level Management**: Set player crafting levels
- **XP Commands**: Give XP to players
- **Recipe Management**: Dynamic recipe addition/removal
- **Statistics**: Database views for analytics
- **Debug Mode**: Detailed logging for troubleshooting

## 📋 Requirements

- [qb-core](https://github.com/qbcore-framework/qb-core) or [qbox](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

## 🚀 Installation

1. **Download/Clone** this resource into your `resources` folder

2. **Database Setup**
   ```bash
   # Run the install.sql file in your database
   # This creates: crafting_progression, crafting_stats, crafting_achievements tables
   ```

3. **Configure** your `config.lua` file
   - Set up crafting station locations
   - Adjust XP multipliers
   - Configure station types and categories
   - Enable/disable features as needed

4. **Add to server.cfg**
   ```cfg
   ensure CraftingScript
   ```

5. **Add Items** to your `qb-core/shared/items.lua` (or your item system)
   - Ensure all recipe items and results exist in your items database
   - Example items: `cloth`, `wood`, `metalscrap`, `steel`, `lockpick`, etc.

## ⚙️ Configuration

### Crafting Stations
```lua
Config.CraftingStations = {
    {
        type = 'workbench',
        coords = vector3(-268.0, -956.0, 31.2),
        heading = 0.0,
        blip = true,
        label = 'Public Workbench'
    }
}
```

### Station Types
Each station type has access to specific recipe categories:
- **Workbench**: basic, tools, components
- **Electronics Bench**: electronics, components
- **Weapon Bench**: weapons, attachments
- **Medical Station**: medical, chemistry
- **Cooking Station**: food, drinks

### Progression Tiers
```lua
Config.Progression = {
    {level = 0,   label = 'Novice',      color = '#AAAAAA'},
    {level = 5,   label = 'Apprentice',  color = '#4CAF50'},
    {level = 10,  label = 'Journeyman',  color = '#2196F3'},
    {level = 20,  label = 'Adept',       color = '#9C27B0'},
    {level = 35,  label = 'Expert',      color = '#FF9800'},
    {level = 50,  label = 'Master',      color = '#F44336'},
    {level = 75,  label = 'Grandmaster', color = '#FFD700'},
    {level = 100, label = 'Legendary',   color = '#00FFFF'}
}
```

## 📝 Adding Custom Recipes

Edit `crafting_items.lua`:

```lua
CraftingRecipes['your_item_id'] = {
    label = 'Item Name',
    category = 'basic', -- basic, tools, components, electronics, weapons, attachments, medical, chemistry, food, drinks
    description = 'Item description',
    ingredients = {
        {item = 'ingredient1', count = 2},
        {item = 'ingredient2', count = 1}
    },
    result = {item = 'result_item', count = 1},
    time = 5000, -- milliseconds
    requiredLevel = 10,
    xp = 20,
    requiredTool = 'hammer', -- or nil
    skillCheck = {'easy', 'medium'}, -- difficulty array
    failureChance = 0.05, -- 5%
    canProduceQuality = true -- can craft fine/excellent versions
}
```

## 🎮 Commands

### Player Commands
- `/craftinglevel` - Check your crafting level and progress

### Admin Commands
- `/setcraftinglevel [id] [level]` - Set a player's crafting level
- `/givecraftxp [id] [xp]` - Give crafting XP to a player
- `/addcraftstation [type]` - Add a crafting station at your current location
  - Types: `workbench`, `electronics_bench`, `weapon_bench`, `medical_station`, `cooking_station`
- `/managecraftstations` - Open the station management menu
- `/deletecraftstation` - Delete the nearest dynamic crafting station

## 🛠️ Admin Station Management

The script includes a powerful in-game station management system:

### Adding Stations
1. Stand where you want the station
2. Run `/addcraftstation [type]` (e.g., `/addcraftstation workbench`)
3. Configure the label, blip visibility, and heading
4. Station is instantly created and saved to database

### Managing Stations
1. Run `/managecraftstations` to open the management UI
2. View all stations grouped by type
3. See distance from your location
4. Click on dynamic stations to:
   - Teleport to the station
   - Set GPS waypoint
   - Delete the station

### Station Types
- **Config Stations**: Defined in `config.lua` (cannot be deleted in-game)
- **Dynamic Stations**: Created by admins in-game (stored in database, can be deleted)

### Features
- Stations persist across server restarts
- Real-time updates for all players
- Distance indicators
- Quick teleport/waypoint system
- Confirmation dialogs for deletions

## 🔧 Exports

### Client Exports
```lua
-- None currently implemented
```

### Server Exports
```lua
-- Get player crafting level
local level = exports['CraftingScript']:GetPlayerCraftingLevel(source)

-- Get player crafting XP
local xp = exports['CraftingScript']:GetPlayerCraftingXP(source)

-- Get full player crafting data
local data = exports['CraftingScript']:GetPlayerCraftingData(source)
-- Returns: {level, xp, totalCrafted, lastCraft, craftStreak}

-- Add a custom recipe dynamically
exports['CraftingScript']:AddRecipe('custom_item', recipeData)

-- Remove a recipe
exports['CraftingScript']:RemoveRecipe('item_id')
```

## 📊 Database Structure

### crafting_progression
Stores player progression data
- `citizenid` - Player identifier
- `level` - Current crafting level
- `xp` - Current experience points
- `total_crafted` - Total items crafted

### crafting_stats
Detailed crafting history
- `citizenid` - Player identifier
- `recipe_id` - Recipe identifier
- `amount` - Quantity crafted
- `success` - Success/failure flag
- `timestamp` - When crafted

### crafting_achievements
Achievement tracking (ready for implementation)
- `citizenid` - Player identifier
- `achievement_id` - Achievement identifier
- `unlocked_at` - Unlock timestamp

## 🎨 Customization Tips

1. **Adjust XP Scaling**: Modify `CalculateXPForNextLevel()` in `server.lua`
2. **Change Quality Rates**: Edit `DetermineQuality()` percentages
3. **Add New Station Types**: Add to `Config.StationTypes` and create corresponding categories
4. **Custom Animations**: Modify `Config.Animations` for each station type
5. **Failure Mechanics**: Adjust `Config.FailureChance` and per-recipe chances

## 🐛 Troubleshooting

### Recipes Not Showing
- Ensure player level meets `requiredLevel`
- Check station type has the recipe's category
- Verify recipe exists in `crafting_items.lua`

### Stations Not Loading
- Run `install.sql` to create `crafting_stations` table
- Check that oxmysql is running
- Verify `Config.UseMySQL = true` in config
- Check server console for database errors

### Admin Commands Not Working
- Verify player has the admin role set in `Config.AdminGroup`
- Default is `'admin'` - adjust in config if using different permissions
- For QBox, ensure proper ace permissions are set

### Items Not Being Given
- Check item names match your QBCore items exactly
- Ensure items are registered in `qb-core/shared/items.lua`
- Check server console for errors

### Database Issues
- Verify oxmysql is running: `ensure oxmysql`
- Check MySQL credentials in your server config
- Run `install.sql` if tables don't exist

### Skill Checks Not Working
- Ensure `Config.UseSkillCheck = true`
- Verify ox_lib is installed and running
- Check recipe has `skillCheck` array defined

## 📈 Performance

- Optimized database queries with indexes
- Cached player data in memory
- Efficient recipe filtering
- Background saving to prevent blocking

## 🔄 Updates & Support

This is a custom script built for QBCore/QBox compatibility. 

### Planned Features
- Achievement system implementation
- Recipe unlocking through quests
- Crafting stations as purchasable items
- Group crafting with shared XP
- Recipe discovery system
- Mobile crafting for certain categories

## 📄 License

Free to use and modify for your FiveM server. Credit appreciated but not required.

## 🤝 Credits

Developed for QBCore/QBox Framework
- Uses ox_lib for UI components
- Uses ox_target for interaction zones
- Uses oxmysql for database operations

---

**Version:** 2.0.0  
**Author:** kurai.dev  
**Framework:** QBCore/QBox  
**Last Updated:** 2025
