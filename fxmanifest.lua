fx_version 'cerulean'
game 'gta5'

name 'kurai-crafting'
author 'Kurai.Dev'
description 'Advanced Progression Crafting System v3.0 - The Definitive Solution'
version '3.0.0'

lua54 'yes'

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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'oxmysql'
}
