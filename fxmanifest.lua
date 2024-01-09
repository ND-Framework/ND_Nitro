-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666"
description "Nitro for vehicles"
version "2.0.1"

fx_version "cerulean"
game "gta5"
lua54 "yes"

files {
	"ui/index.html",
	"ui/style.css",
	"ui/script.js"
}
ui_page "ui/index.html"

client_scripts {
    "@ox_lib/init.lua",
    "source/client.lua"
}
