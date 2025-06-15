fx_version 'cerulean'
games { 'gta5' }

author 'The_Hs5'

description 'Simple fivem vehicles parking sensor script:)'
version '1.0.0'

dependency {'oxmysql', 'ox_lib'}

shared_scripts {
	'@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/**.lua'
}

ui_page 'html/index.html'

files {
    'html/car_top.svg',
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'