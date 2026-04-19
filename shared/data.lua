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

data.walkStyles = {
	{ value = "default", label = "Default", clipset = nil, category = "normal" },
	{ value = "brave", label = "Brave", clipset = "move_m@brave", category = "normal" },
	{ value = "confident", label = "Confident", clipset = "move_m@confident", category = "normal" },
	{ value = "hurry", label = "Hurry", clipset = "move_m@hurry@a", category = "normal" },
	{ value = "business", label = "Business", clipset = "move_m@business@a", category = "normal" },
	{ value = "tough_guy", label = "Tough Guy", clipset = "move_m@tough_guy@", category = "tough" },
	{ value = "gangster", label = "Gangster", clipset = "move_m@gangster@generic", category = "tough" },
	{ value = "posh", label = "Posh", clipset = "move_m@posh@", category = "normal" },
	{ value = "sexy", label = "Sexy", clipset = "move_f@sexy@a", category = "feminine" },
	{ value = "heels", label = "Heels", clipset = "move_f@heels@c", category = "feminine" },
	{ value = "arrogant", label = "Arrogant", clipset = "move_m@arrogant@a", category = "normal" },
	{ value = "sad", label = "Sad", clipset = "move_m@sad@a", category = "mood" },
	{ value = "intimidation", label = "Intimidation", clipset = "move_m@intimidation@1h", category = "tough" },
	{ value = "drunk", label = "Drunk", clipset = "move_m@drunk@moderatedrunk", category = "impaired" },
	{ value = "injured", label = "Injured", clipset = "move_m@injured", category = "impaired" },
	{ value = "hipster", label = "Hipster", clipset = "move_m@hipster@a", category = "normal" },
	{ value = "hobo", label = "Hobo", clipset = "move_m@hobo@a", category = "normal" },
	{ value = "money", label = "Money", clipset = "move_m@money", category = "normal" },
	{ value = "quick", label = "Quick", clipset = "move_m@quick", category = "normal" },
	{ value = "fat", label = "Heavy", clipset = "move_m@fat@a", category = "normal" },
	{ value = "swagger", label = "Swagger", clipset = "move_m@swagger", category = "tough" },
	{ value = "muscle", label = "Muscle", clipset = "move_m@muscle@a", category = "tough" },
	{ value = "femme", label = "Femme", clipset = "move_f@femme@", category = "feminine" },
	{ value = "cop", label = "Cop", clipset = "move_m@cop@stroll", category = "professional" },
	{ value = "alien", label = "Alien", clipset = "move_m@alien", category = "special" },
	{ value = "maneater", label = "Maneater", clipset = "move_f@maneater", category = "feminine" },
	{ value = "chichi", label = "Chichi", clipset = "move_f@chichi", category = "feminine" },
	{ value = "sassy", label = "Sassy", clipset = "move_m@sassy", category = "feminine" },
	{ value = "depressed", label = "Depressed", clipset = "move_m@depressed@a", category = "mood" },
}

data.walkStyleCategories = {
	{ value = "all", label = "All" },
	{ value = "normal", label = "Normal" },
	{ value = "tough", label = "Tough" },
	{ value = "feminine", label = "Feminine" },
	{ value = "mood", label = "Mood" },
	{ value = "impaired", label = "Impaired" },
	{ value = "professional", label = "Professional" },
	{ value = "special", label = "Special" },
}

return data
