fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem-fishing'
author 'DieselJones21'
description 'Ocean, lake, and river fishing with ox_lib skill checks, progress bars, ox_inventory, and a custom tackle shop UI'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/fishing.lua',
}

server_scripts {
    'server/bridge.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'locales/*.json',
    'images/*.png',
}

ox_libs {
    'locale',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'interact',
}
