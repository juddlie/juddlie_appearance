local tattooData <const> = require("shared.tattoos")
local sharedData <const> = require("shared.data")

local config = {}

-- enables debug logging and the /appearance command for testing
-- set to false in production
config.debug = false

-- which framework to use for player data (jobs, gangs, identifiers)
-- "esx" = es_extended
-- "qbx" = qbx_core / qb-core
-- "ox" = ox_core (overextended framework, uses stateId + groups)
-- "custom" = standalone (no framework, uses license identifier only)
---@type "esx" | "qbx" | "ox" | "custom"
config.framework = "esx"

-- which target resource handles interaction at locations
-- "ox" = ox_target
-- "qb" = qb-target
---@type "ox" | "qb"
config.interaction = "ox"

-- how players interact at locations
-- "point"  = proximity-based, shows a textui prompt and the player presses e (ox only)
-- "target" = target-based, player aims with the target eye and clicks an option
-- note: "point" mode only works with config.interaction = "ox"
---@type "target" | "point"
config.interactionType = "point"

-- which fivem identifier type to use for saving player data
-- only used when config.framework = "custom" (esx/qbx use their own identifier)
-- "license"  = rockstar license
-- "license2" = rockstar license (alt)
-- "fivem"    = fivem account id
-- "discord"  = discord id
---@type "license" | "license2" | "fivem" | "discord"
config.licenseType = "license"

-- language locale
config.locale = "en"

-- accent color used throughout the ui
-- supports:
--   mantine color names: "blue", "teal", "cyan", "green", "violet", "grape", "pink", "red", "orange", "yellow", "lime", "indigo"
--   hex codes: "#3B82F6", "#ff5733"
--   rgb values: "rgb(59, 130, 246)"
config.accentColor = "blue"

-- default camera field of view when the menu opens
config.defaultFov = 50

-- make the player invincible while the appearance menu is open
-- prevents them from being killed during customization
config.invincibleDuringCustomization = true

-- freeze the player in place while the appearance menu is open
config.freezeDuringCustomization = true

-- hide the minimap/radar while the appearance menu is open
config.hideRadar = false

-- default head blend shape/skin mix when creating a new freemode ped
-- or when no mix value is provided (range: 0.0 to 1.0)
config.defaultShapeMix = 0.5
config.defaultSkinMix = 0.5

-- timeout in milliseconds for loading ped models and animation dicts
-- if loading takes longer than this, the request is cancelled
config.modelLoadTimeout = 5000
config.animationLoadTimeout = 5000

-- animation blend in/out speeds for the animation preview
config.animationBlendIn = 8.0
config.animationBlendOut = -8.0

-- camera transition duration in milliseconds (used when creating/destroying the camera)
config.cameraTransitionTime = 500

-- lighting clock times for each lighting preset (hour, minute, second)
config.lightingTimes = {
	studio = { 18, 0, 0 },
	day    = { 12, 0, 0 },
	night  = { 0, 0, 0 },
}

-- default auto-randomizer speed in seconds (used when player doesn't specify)
config.randomizerDefaultSpeed = 2

-- server-side limits to prevent abuse
-- max number of presets and outfits a player can save
-- max json payload size in bytes accepted from clients
config.limits = {
	maxPresets = 50,
	maxOutfits = 50,
	maxPayloadSize = 100000,
}

-- default blip settings used when a location doesn't specify its own
config.defaultBlip = {
	sprite = 1,
	color = 0,
	scale = 0.7,
}

-- default interaction radius for locations and clothing rooms (in meters)
config.defaultLocationRadius = 2.0
config.defaultClothingRoomRadius = 1.5

-- icons used for ox_target / qb-target interaction zones
config.targetIcons = {
	location = "fas fa-tshirt",
	clothingRoom = "fas fa-door-open",
}

-- disabled components / props
-- use these if you have a clothing-as-items system and want to prevent
-- players from changing certain slots through the appearance menu
--
-- component ids:
--   0 = head, 1 = mask, 2 = hair, 3 = upper body/torso,
--   4 = legs/pants, 5 = bags/parachute, 6 = shoes, 7 = accessories,
--   8 = undershirt, 9 = body armor, 10 = decals/badges, 11 = jacket/outer
--
-- prop ids:
--   0 = hats, 1 = glasses, 2 = ears, 6 = watches, 7 = bracelets
config.disabledComponents = {} -- e.g. { 9 } to disable body armor
config.disabledProps = {}      -- e.g. { 6, 7 } to disable watch and bracelet

-- ped models available in the ped model selector page
-- value = the model name (hash), label = display name
config.pedModels = {
	{ value = "mp_m_freemode_01", label = "Freemode Male" },
	{ value = "mp_f_freemode_01", label = "Freemode Female" },
}

-- camera position offsets for each preset
-- offset = vector3(x, y, z) relative to the ped
-- rotation = vector3(pitch, roll, yaw)
config.cameraOffsets = {
	face = {
		offset = vector3(0.0, 0.7, 0.65),
		rotation = vector3(-5.0, 0.0, 0.0)
	},
	threeQuarter = {
		offset = vector3(0.5, 1.2, 0.3),
		rotation = vector3(-5.0, 0.0, 0.0)
	},
	fullBody = {
		offset = vector3(0.0, 2.5, 0.2),
		rotation = vector3(-5.0, 0.0, 0.0)
	},
}

-- camera angle presets shown in the ui dropdown
-- value = internal key, label = display name
config.cameraPresets = {
	{ value = "face", label = "Face" },
	{ value = "three_quarter", label = "3/4" },
	{ value = "full_body", label = "Full Body" },
}

-- lighting presets shown in the ui dropdown
config.lightingPresets = {
	{ value = "studio", label = "Studio" },
	{ value = "day", label = "Day" },
	{ value = "night", label = "Night" },
}

-- default camera settings when the menu first opens
config.cameraDefaults = {
	preset = "full_body",
	lighting = "studio",
	fov = 50,
	zoom = 1,
	rotation = 0,
}

-- min/max/step ranges for camera sliders in the ui
config.cameraRanges = {
	fov = { min = 20, max = 90, step = 1 },
	zoom = { min = 0.5, max = 3, step = 0.1 },
	rotation = { min = -180, max = 180, step = 1 },
}

-- categories players can assign their saved outfits to
-- value = stored in database, label = shown to the player
-- add or remove as needed
config.outfitCategories = {
	{ value = "casual", label = "Casual" },
	{ value = "work", label = "Work" },
	{ value = "formal", label = "Formal" },
	{ value = "custom", label = "Custom" },
}

-- these are the zones where the appearance menu can be opened
-- each location creates a map blip and an interaction point/target
--
-- fields:
--   type = label for your reference only (not used in code)
--   label = name shown to the player on interaction
--   coords = world position (vector3)
--   radius = interaction radius in meters
--   tabs = which menu tabs are available at this location
--     valid tabs: "clothing", "props", "outfits", "hair", "face",
--      "colors", "tattoos", "presets", "animations", "randomizer", "camera"
--   blip = map blip config (optional)
--     sprite = blip icon id (see https://docs.fivem.net/docs/game-references/blips/)
--     color  = blip color id
--     scale  = blip size on the map
--     label  = text shown on the map
config.locations = {
	{
		type = "clothing_store",
		label = "Clothing Store",
		coords = vector3(72.3, -1399.1, 29.4),
		radius = 2.0,
		tabs = { "clothing", "props", "outfits" },
		blip = {
			sprite = 73, 
			color = 47, 
			scale = 0.7, 
			label = "Clothing Store"
		},
	},
	{
		type = "clothing_store",
		label = "Clothing Store",
		coords = vector3(-703.8, -152.3, 37.4),
		radius = 2.0,
		tabs = { "clothing", "props", "outfits" },
		blip = { 
			sprite = 73,
			color = 47,
			scale = 0.7,
			label = "Clothing Store"
		},
	},
	{
		type = "clothing_store",
		label = "Clothing Store",
		coords = vector3(-167.9, -299.0, 39.7),
		radius = 2.0,
		tabs = { "clothing", "props", "outfits" },
		blip = { 
			sprite = 73,
			color = 47,
			scale = 0.7,
			label = "Clothing Store"
		},
	},
	{
		type = "barber",
		label = "Barber Shop",
		coords = vector3(-814.3, -183.8, 37.6),
		radius = 1.5,
		tabs = { "hair", "face", "colors" },
		blip = {
			sprite = 71,
			color = 0,
			scale = 0.7,
			label = "Barber Shop"
		},
	},
	{
		type = "barber",
		label = "Barber Shop",
		coords = vector3(136.8, -1708.4, 29.3),
		radius = 1.5,
		tabs = { "hair", "face", "colors" },
		blip = {
			sprite = 71,
			color = 0,
			scale = 0.7,
			label = "Barber Shop"
		},
	},
	{
		type = "barber",
		label = "Barber Shop",
		coords = vector3(-1282.6, -1116.8, 6.99),
		radius = 1.5,
		tabs = { "hair", "face", "colors" },
		blip = { 
			sprite = 71,
			color = 0,
			scale = 0.7,
			label = "Barber Shop"
		},
	},
	{
		type = "tattoo",
		label = "Tattoo Parlor",
		coords = vector3(1322.6, -1651.9, 52.3),
		radius = 1.5,
		tabs = { "tattoos" },
		blip = { 
			sprite = 75,
			color = 1,
			scale = 0.7,
			label = "Tattoo Parlor"
		},
	},
	{
		type = "tattoo",
		label = "Tattoo Parlor",
		coords = vector3(-1153.7, -1425.7, 4.95),
		radius = 1.5,
		tabs = { "tattoos" },
		blip = { 
			sprite = 75,
			color = 1,
			scale = 0.7,
			label = "Tattoo Parlor"
		},
	},
	{
		type = "surgeon",
		label = "Plastic Surgeon",
		coords = vector3(316.8, -584.2, 43.3),
		radius = 1.5,
		tabs = { "face", "colors" },
		blip = { 
			sprite = 102, 
			color = 2, 
			scale = 0.7, 
			label = "Plastic Surgeon" 
		},
	},
}

-- how much to charge players when they save changes at each shop type
-- set a price to 0 to make that shop free
-- these match the "type" field on each location in config.locations
config.prices = {
	clothing_store = 100,
	barber = 100,
	tattoo = 100,
	surgeon = 500,
}

-- if true, players are charged per tattoo applied (uses the tattoo shop price above)
-- if false, players pay once when they save, regardless of how many tattoos they add
config.chargePerTattoo = false

-- block (or exclusively allow) specific clothing drawables and props
-- based on job, gang, identifier, or ace permissions
--
-- enabled = set to true to activate the blacklist system
-- mode = "blacklist" blocks listed items, "whitelist" only allows listed items
--
-- each rule in clothing/props can have:
--   component / prop = which component or prop id this rule applies to
--   drawables = list of drawable ids to restrict
--   jobs = job names that match this rule
--   gangs = gang names that match this rule
--   identifiers = specific player identifiers
--   aces = ace permission strings (e.g. "appearance.vip")
--   invert = flip the logic:
--                      false (default) = blocked for matching players
--                      true = blocked for everyone except matching players
--
-- to grant ace permissions, add to your server.cfg:
--   add_ace identifier.license:abc123 appearance.vip allow
--   add_ace group.admin appearance.vip allow
config.blacklist = {
	enabled = false,

	---@type "blacklist" | "whitelist"
	mode = "blacklist",

	clothing = {
		-- example: only police can wear component 11 drawable 55
		-- { component = 11, drawables = { 55 }, jobs = { "police" }, invert = true },
	},

	props = {
		-- example: only players with the "appearance.vip" ace can wear prop 0 drawable 120
		-- { prop = 0, drawables = { 120 }, aces = { "appearance.vip" }, invert = true },
	},
}

-- restricted locations that only specific jobs or gangs can access
-- works the same as regular locations but with access control
--
-- fields:
--   label   = name shown to the player
--   coords  = world position (vector3)
--   radius  = interaction radius in meters
--   job     = required job name (must match your framework exactly, case-sensitive)
--   gang    = required gang name (use job or gang, not both)
--   minRank = minimum job/gang grade required (0 = all ranks)
--   tabs    = which menu tabs are available in this room
--   blip    = map blip config (optional, same as locations)
config.clothingRooms = {
	-- {
	-- 	label = "LSPD Locker Room",
	-- 	coords = vector3(461.8, -1000.4, 30.7),
	-- 	radius = 1.5,
	-- 	job = "police",
	-- 	minRank = 0,
	-- 	tabs = { "clothing", "props", "outfits" },
	-- 	blip = { sprite = 366, color = 29, scale = 0.6, label = "LSPD Locker Room" },
	-- },
	-- {
	-- 	label = "EMS Locker Room",
	-- 	coords = vector3(311.8, -592.4, 43.3),
	-- 	radius = 1.5,
	-- 	job = "ambulance",
	-- 	minRank = 0,
	-- 	tabs = { "clothing", "props", "outfits" },
	-- 	blip = { sprite = 61, color = 1, scale = 0.6, label = "EMS Locker Room" },
	-- },
}

-- separate command to change your ped model
-- enabled = whether the ped menu command is registered
-- command = the chat command to open it (e.g. /pedmenu)
-- acePermission = false means everyone can use it
--                 set to an ace string like "admin.pedmenu" to restrict access
--                 then grant it in server.cfg: add_ace group.admin admin.pedmenu allow
config.pedMenu = {
	enabled = true,
	command = "pedmenu",
	acePermission = false,
}

-- reloadskin = reloads the player's saved appearance from the database
-- note: when config.debug = true, an /appearance command is also registered
--       which opens the full menu without needing to be at a location
config.commands = {
	reloadSkin = "reloadskin",
}

-- allows players to quickly swap outfits via a keybind
-- opens an ox_lib context menu with saved outfits
config.outfitWheel = {
	enabled = true,
	-- the keybind to open the outfit wheel (can be rebound by the player in their keybind settings)
	key = "F7",
	-- the command name (used internally for RegisterKeyMapping)
	command = "+outfitwheel",
	-- icon shown for favorite outfits in the context menu
	favoriteIcon = "star",
	-- icon shown for regular outfits in the context menu
	defaultIcon = "shirt",
	-- color mapping for outfit categories in the context menu
	categoryColors = {
		casual = "blue",
		work = "orange",
		formal = "purple",
		custom = "gray",
	},
}

-- allows admins/staff to edit another player's appearance
-- usage: /setappearance [player server id]
config.admin = {
	enabled = true,
	-- the command name to open the editor for a target player
	command = "setappearance",
	-- ace permission required to use the command
	-- set to false to disable permission checks (not recommended)
	-- grant in server.cfg: add_ace group.admin admin.appearance allow
	acePermission = "admin.appearance",
}

-- one-time migration tool to import data from illenium-appearance
-- usage: run the command from server console or with the appropriate ace permission
config.migration = {
	enabled = true,
	-- the command to trigger migration
	command = "migrateappearance",
	-- ace permission required (set to false to allow console-only)
	acePermission = false,
}

-- shared data (don't change unless you know what you're doing)
-- these are loaded from shared/tattoos.lua and shared/data.lua
config.tattoos = tattooData.list
config.tattooZones = tattooData.zones

config.componentIds = sharedData.componentIds
config.propIds = sharedData.propIds
config.componentLabels = sharedData.componentLabels
config.propLabels = sharedData.propLabels
config.overlayLabels = sharedData.overlayLabels
config.faceFeatures = sharedData.faceFeatures
config.faceRegions = sharedData.faceRegions
config.animations = sharedData.animations
config.quickSlots = sharedData.quickSlots
config.randomizerCategories = sharedData.randomizerCategories

return config