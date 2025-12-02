fx_version 'cerulean'
game 'gta5'

author 'BLDR Team'
description 'Progression Crafting System (QBCore + ox_lib/ox_target/ox_inventory)'
version '1.0.0'

shared_script 'config.lua'
shared_script 'crafting_items.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
  'qb-core',
  'ox_lib',
  'ox_target',
  'ox_inventory',
  'oxmysql'
}

lua54 'yes'