fx_version 'cerulean'
game 'gta5'

author 'kurai.dev'
description 'Advanced Progression-Based Crafting System for QBCore/QBox'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'crafting_items.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'oxmysql'
}

lua54 'yes'
