fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'b3j0'
description 'Billing and Society invoice system'
version '1.0.0'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'web/dist/images/*'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/locales.lua',
    'locales/en.lua',
    'locales/id.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'ox_target',
    'ox_inventory',
    'Renewed-Banking'
}
