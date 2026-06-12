fx_version 'cerulean'
game 'gta5'

author 'Reluctant'
description 'In-game vehicle handling editor'
version '0.6.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
}
