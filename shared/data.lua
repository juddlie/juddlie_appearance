local data = {}

data.componentIds = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
data.propIds = { 0, 1, 2, 6, 7 }

data.componentLabels = {
	["0"] = "Head", ["1"] = "Mask", ["2"] = "Hair", ["3"] = "Upper Body", ["4"] = "Lower Body",
	["5"] = "Bags", ["6"] = "Shoes", ["7"] = "Accessories", ["8"] = "Undershirt",
	["9"] = "Armor", ["10"] = "Decals", ["11"] = "Tops",
}

data.propLabels = {
	["0"] = "Hat", ["1"] = "Glasses", ["2"] = "Ears", ["6"] = "Watch", ["7"] = "Bracelet",
}

data.overlayLabels = {
	"Blemishes", "Facial Hair", "Eyebrows", "Ageing", "Makeup",
	"Blush", "Complexion", "Sun Damage", "Lipstick", "Moles/Freckles",
	"Chest Hair", "Body Blemishes", "Add Body Blemishes",
}

data.faceFeatures = {
	"noseWidth", "nosePeakHeight", "nosePeakLength", "noseBoneHeight",
	"nosePeakLowering", "noseBoneTwist", "eyebrowHeight", "eyebrowDepth",
	"cheekboneHeight", "cheekboneWidth", "cheekWidth", "eyeOpening",
	"lipThickness", "jawBoneWidth", "jawBoneLength", "chinBoneHeight",
	"chinBoneLength", "chinBoneWidth", "chinHole", "neckThickness",
}

data.faceRegions = {
	{ name = "Eyes", features = { "eyeOpening", "eyebrowHeight", "eyebrowDepth" } },
	{ name = "Nose", features = { "noseWidth", "nosePeakHeight", "nosePeakLength", "noseBoneHeight", "nosePeakLowering", "noseBoneTwist" } },
	{ name = "Cheeks", features = { "cheekboneHeight", "cheekboneWidth", "cheekWidth" } },
	{ name = "Jaw", features = { "jawBoneWidth", "jawBoneLength" } },
	{ name = "Chin", features = { "chinBoneHeight", "chinBoneLength", "chinBoneWidth", "chinHole" } },
	{ name = "Lips", features = { "lipThickness" } },
	{ name = "Neck", features = { "neckThickness" } },
}

data.animations = {
	{ value = "idle", label = "Idle", desc = "Standing still", dict = nil, name = nil },
	{ value = "walk", label = "Walk", desc = "Walking forward", dict = "move_m@casual@d", name = "walk" },
	{ value = "run", label = "Run", desc = "Running forward", dict = "move_m@jog@", name = "run" },
	{ value = "crouch", label = "Crouch", desc = "Crouching position", dict = "move_crouch_proto", name = "idle" },
	{ value = "sit", label = "Sit", desc = "Sitting on ground", dict = "anim@amb@business@bgen@bgen_no_work@", name = "sit_phone_phoneputdown_idle_nowork" },
}

data.quickSlots = {
	{ label = "Hat", component = 0, prop = 0, type = "prop" },
	{ label = "Glasses", component = 1, prop = 1, type = "prop" },
	{ label = "Top", component = 11, prop = -1, type = "clothing" },
	{ label = "Shoes", component = 6, prop = -1, type = "clothing" },
}

data.randomizerCategories = {
	{ key = "face", label = "Face" },
	{ key = "hair", label = "Hair" },
	{ key = "clothing", label = "Clothing" },
	{ key = "props", label = "Props" },
	{ key = "tattoos", label = "Tattoos" },
}

return data
