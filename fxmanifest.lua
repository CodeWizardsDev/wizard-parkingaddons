fx_version 'cerulean'
games { 'gta5' }

author 'The_Hs5'

description 'Simple fivem vehicles parking sensor script:)'
version '1.0.0'

shared_scripts {
    'config.lua'
}

ui_page 'html/index.html'

files {
    'html/car_top.svg',
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'client/**.lua'
}

lua54 'yes'