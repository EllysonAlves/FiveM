fx_version 'cerulean'
games { 'gta5' }

author 'cw-vehicledash'
description 'Vehicle Dashboard — lista e spawna veículos de corrida Alves Racing'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/assets/**',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'alves-racingapp',
    'qbx_vehiclekeys',
}

lua54 'yes'
