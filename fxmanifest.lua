fx_version 'cerulean'
game 'gta5'

author 'BLDR Team'
description 'Progression Crafting System (QBCore + ox_lib/ox_target/ox_inventory)'
version '1.0.0'

shared_script 'config.lua'
shared_script 'crafting_items.lua'

client_script 'client.lua'
server_script 'server.lua'

ui_page 'web/public/index.html'

files {
  'web/public/index.html',
  'web/build/bundle.js'
}

dependencies {
  'qb-core',
  'ox_lib',
  'ox_target',
  'ox_inventory',
  'oxmysql'
}

lua54 'yes'