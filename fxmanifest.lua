fx_version "cerulean"
game "gta5"
lua54 "yes"

ui_page "web/build/index.html"

author "juddlie"
version "1.0.0"

shared_scripts {
	"@ox_lib/init.lua",
	"shared/*.lua",
	"config.lua",
	"bridge/init.lua",
}

client_scripts {
	"client/modules/*.lua",
	"client/main.lua",
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server/modules/*.lua",
	"server/main.lua",
}

files {
	"web/build/index.html",
	"web/build/assets/*.js",
	"web/build/assets/*.css",
	"bridge/framework/**/client.lua",
	"bridge/interaction/**/client.lua",
}
