# Development Guide

## Project Structure

```
KuraiCrafting/
├── client.lua              # Client-side FiveM logic
├── server.lua              # Server-side FiveM logic
├── config.lua              # Configuration settings
├── crafting_items.lua      # Recipe definitions
├── fxmanifest.lua          # Resource manifest
├── database.sql            # Database schema
├── package.json            # Node.js dependencies
├── webpack.config.js       # Build configuration
├── tsconfig.json           # TypeScript configuration
├── tailwind.config.js      # Tailwind CSS configuration
├── postcss.config.js       # PostCSS configuration
├── styles.css              # Global styles
├── App.tsx                 # Main React component wrapper
├── index.tsx               # React entry point
├── components/             # React components
│   ├── CraftingApp.tsx     # Main crafting UI logic
│   └── CraftingPanel.tsx   # Recipe detail panel
├── utils/                  # Utility functions
│   └── fetchNui.ts         # NUI communication helper
└── web/                    # Web assets
    ├── public/
    │   └── index.html      # HTML template
    └── build/
        └── bundle.js       # Compiled JS bundle
```

## Development Workflow

### 1. UI Development

When working on the React UI:

```bash
# Watch for changes and auto-rebuild
npm run watch

# Or manually build
npm run build
```

### 2. Testing in FiveM

1. Ensure the resource is started: `ensure KuraiCrafting`
2. Restart after Lua changes: `restart KuraiCrafting`
3. After UI changes, just rebuild - no restart needed (refresh with F5 in NUI DevTools)

### 3. Debugging

#### Client-side Debugging
- Use F8 console in-game
- Check client.lua prints

#### NUI Debugging
- Press F8 and type: `nui_devtools 1`
- Open Chrome DevTools to debug React app
- Check console for NUI messages

#### Server-side Debugging
- Check server console
- Use `print()` statements

## Adding New Recipes

1. Edit `crafting_items.lua`:
```lua
CraftingRecipes = {
    your_item = {
        label = 'Your Item Name',
        ingredients = {
            {item = 'material1', count = 2},
            {item = 'material2', count = 1}
        },
        time = 5000,  -- milliseconds
        requiredLevel = 5
    }
}
```

2. Add XP reward in `config.lua`:
```lua
Config.CraftingXP = {
    your_item = 15
}
```

## Customizing the UI

### Colors & Styling
Edit `components/CraftingApp.tsx` and `components/CraftingPanel.tsx`
- Uses Tailwind CSS utility classes
- Main colors: zinc (grays), amber (highlights), red (close button)

### Layout
- Main layout is 80vw x 80vh centered
- Left sidebar: 72 width units (18rem)
- Uses CSS Grid for responsive layout

### Adding Features
1. Add state in `CraftingApp.tsx`
2. Create NUI callback in `client.lua`
3. Use `fetchNui()` to communicate

## Common Issues

### UI Not Showing
- Check `ensure KuraiCrafting` in server.cfg
- Verify `npm run build` completed successfully
- Check F8 console for errors

### Recipes Not Loading
- Verify `crafting_items.lua` syntax
- Check server console for Lua errors
- Ensure player has required level

### Inventory Not Updating
- Check ox_inventory compatibility
- Verify QBCore player data structure
- Check server-side item names match

## Performance Tips

1. **Build for Production**: Always use `npm run build` (not watch) for production
2. **Optimize Images**: If adding images, use compressed formats
3. **Minimize NUI Messages**: Batch updates when possible
4. **Database**: Index frequently queried columns

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Created by BLDR Team & Kurai Development
