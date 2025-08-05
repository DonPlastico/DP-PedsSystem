fx_version 'cerulean'
game 'gta5'

author 'DP-Scripts'
description 'Sistema de Peds para jugadores - DP-PedSystem'
version '1.0.0'

shared_script 'shared/config.lua'

client_scripts {
    'client/cl_main.lua',
    'client/cl_commands.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua',
    'server/sv_commands.lua'
}

dependencies {
    'qb-core',
    'qb-menu',
    'qb-input',
    'oxmysql'
}