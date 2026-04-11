local tattooData <const> = require("shared.tattoos")
local sharedData <const> = require("shared.data")

local config = {}

config.debug = true

---@type "esx" | "qbx" | "standalone"
config.framework = "esx"
config.licenseType = "license"

config.defaultFov = 50
config.invincibleDuringCustomization = true
config.hideRadar = false

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

config.cameraPresets = {
	{ value = "face", label = "Face" },
	{ value = "three_quarter", label = "3/4" },
	{ value = "full_body", label = "Full Body" },
}

config.lightingPresets = {
	{ value = "studio", label = "Studio" },
	{ value = "day", label = "Day" },
	{ value = "night", label = "Night" },
}

config.cameraDefaults = {
	preset = "full_body",
	lighting = "studio",
	fov = 50,
	zoom = 1,
	rotation = 0,
}

config.cameraRanges = {
	fov = { min = 20, max = 90, step = 1 },
	zoom = { min = 0.5, max = 3, step = 0.1 },
	rotation = { min = -180, max = 180, step = 1 },
}

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
