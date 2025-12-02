-- Config for progression crafting
Config = {}

-- General settings
Config.CraftingDistance = 2.5 -- ox_target distance
Config.CraftingStations = {
    -- example station
    {name = 'workbench_1', coords = vector3(-268.0, -956.0, 31.2), heading = 0.0}
}

-- Progression tiers define what recipes unlock at which level
Config.Progression = {
    { level = 0,   label = 'Novice',    unlocks = {'bandage', 'wood_plank'} },
    { level = 5,   label = 'Apprentice',unlocks = {'lockpick', 'metal_scrap'} },
    { level = 15,  label = 'Adept',     unlocks = {'silencer', 'advanced_medkit'} },
    { level = 30,  label = 'Master',     unlocks = {'weapon_upgrade', 'vehicle_part'} }
}

-- XP gained from crafting items (also used server-side validation)
Config.CraftingXP = {
    bandage = 5,
    wood_plank = 2,
    lockpick = 10,
    metal_scrap = 6,
    silencer = 25,
    advanced_medkit = 30,
    weapon_upgrade = 60,
    vehicle_part = 40
}

-- QBCore item names that may be given (server uses these strings)
Config.ProgressionDataKey = 'crafting_level' -- stored in player metadata

-- Server-side limits
Config.MaxCraftAmount = 10

-- Notifications
Config.NotifyType = 'success' -- QBCore notify type when appropriate

-- MySQL settings
Config.UseMySQL = true -- requires oxmysql
Config.DatabaseTable = 'bldr_crafting_players' -- table to persist xp/level

-- Admin settings
Config.AdminGroup = 'admin' -- qb group or ace; adjust as needed for your server

-- Client animations/settings
Config.CraftingAnim = { dict = 'mini@repair', name = 'fixing_a_ped' }
Config.DisableControlsWhileCrafting = true

-- Progress visuals
Config.UseSkillCheck = false -- if true, will use lib.skillCheck; else simple progress wait
