-- Alves Racing App
-- Sistema de corridas simplificado para Qbox
-- Autor: Alves

fx_version 'cerulean'
game 'gta5'

author 'Alves'
description 'Sistema de corridas ranked/unranked com ELO'
version '1.0.0'

ui_page 'ui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'ui/index.html',
    'ui/style.css',
    'ui/tablet-new.css',
    'ui/script.js'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql'
}

lua54 'yes'
