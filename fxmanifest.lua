fx_version 'cerulean'
game 'gta5'

author 'Reluctant'
description 'In-game vehicle handling editor with real-time apply and handling.meta export'
version '0.2'

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
