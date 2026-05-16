fx_version 'cerulean'
game 'gta5'

name 'alves-racing-core'
description 'Server-side racing core for Alves Racing: rules, thermal systems, nitro and HUD telemetry.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

ui_page 'ui/index.html'

client_scripts {
    'client/*.lua'
}

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

dependencies {
    'ox_lib'
}

lua54 'yes'
