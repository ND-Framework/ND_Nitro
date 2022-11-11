-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666"
description "Nitro for vehicles"
version "1.0.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

files {
	"ui/index.html",
	"ui/script.js",
	"ui/style.css"
}
ui_page "ui/index.html"

server_script "source/server.lua"
client_scripts {
    "source/client.lua"
}