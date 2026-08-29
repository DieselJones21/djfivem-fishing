fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem-fishing'
author 'DieselJones21'
description 'Ocean, lake, and river fishing with ox_lib skill checks, progress bars, ox_inventory, and a custom tackle shop UI'
version '1.3.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/fishing.lua',
    'client/boats.lua',
}

server_scripts {
    'server/bridge.lua',
    'server/stats.lua',
    'server/boats.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/brand/*.png',
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
