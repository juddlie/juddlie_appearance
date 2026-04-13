local cache <const> = require("server.modules.cache")
local logger <const> = require("shared.logger")

local illeniumHeadOverlays <const> = {
	"blemishes", "beard", "eyebrows", "ageing", "makeUp",
	"blush", "complexion", "sunDamage", "lipstick",
	"moleAndFreckles", "chestHair", "bodyBlemishes",
}

local featureToJuddlie <const> = {
	noseWidth = "noseWidth",
	nosePeakHigh = "nosePeakHeight",
	nosePeakSize = "nosePeakLength",
	noseBoneHigh = "noseBoneHeight",
	nosePeakLowering = "nosePeakLowering",
	noseBoneTwist = "noseBoneTwist",
	eyeBrownHigh = "eyebrowHeight",
	eyeBrownForward = "eyebrowDepth",
	cheeksBoneHigh = "cheekboneHeight",
	cheeksBoneWidth = "cheekboneWidth",
	cheeksWidth = "cheekWidth",
	eyesOpening = "eyeOpening",
	lipsThickness = "lipThickness",
	jawBoneWidth = "jawBoneWidth",
	jawBoneBackSize = "jawBoneLength",
	chinBoneLowering = "chinBoneHeight",
	chinBoneLength = "chinBoneLength",
	chinBoneSize = "chinBoneWidth",
	chinHole = "chinHole",
	neckThickness = "neckThickness",
}

local featureFromJuddlie <const> = {}
for illeniumKey, juddlieKey in pairs(featureToJuddlie) do
	featureFromJuddlie[juddlieKey] = illeniumKey
end

---@param juddlieApp table
---@return table? appearance
local function toIlleniumAppearance(juddlieApp)
	if not juddlieApp then return nil end

	local result = { model = juddlieApp.model }

	if juddlieApp.headBlend then
		result.headBlend = {
			shapeFirst = juddlieApp.headBlend.shapeFirst,
			shapeSecond = juddlieApp.headBlend.shapeSecond,
			shapeThird = 0,
			skinFirst = juddlieApp.headBlend.skinFirst,
			skinSecond = juddlieApp.headBlend.skinSecond,
			skinThird = 0,
			shapeMix = juddlieApp.headBlend.shapeMix,
			skinMix = juddlieApp.headBlend.skinMix,
			thirdMix = 0,
		}
	end

	if juddlieApp.faceFeatures then
		result.faceFeatures = {}
		for juddlieKey, value in pairs(juddlieApp.faceFeatures) do
			local illeniumKey = featureFromJuddlie[juddlieKey]
			if illeniumKey then result.faceFeatures[illeniumKey] = value end
		end
	end

	if juddlieApp.headOverlays then
		result.headOverlays = {}
		for i, overlay in ipairs(juddlieApp.headOverlays) do
			local name = illeniumHeadOverlays[i]
			if name then
				local value = overlay.value
				local opacity = overlay.opacity
				if value == -1 then value = 0; opacity = 0 end
				result.headOverlays[name] = {
					style = value,
					opacity = opacity,
					color = overlay.firstColor,
					secondColor = overlay.secondColor,
				}
			end
		end
	end

	if juddlieApp.clothing then
		result.components = {}
		for index, clothingData in ipairs(juddlieApp.clothing) do
			result.components[index] = {
				component_id = clothingData.component,
				drawable = clothingData.drawable,
				texture = clothingData.texture,
			}
		end
	end

	if juddlieApp.props then
		result.props = {}
		for index, propData in ipairs(juddlieApp.props) do
			result.props[index] = {
				prop_id = propData.prop,
				drawable = propData.drawable,
				texture = propData.texture,
			}
		end
	end

	if juddlieApp.hair then
		result.hair = {
			style = juddlieApp.hair.style,
			color = juddlieApp.hair.color,
			highlight = juddlieApp.hair.highlight,
			texture = 0,
		}
	end

	result.eyeColor = juddlieApp.eyeColor
	result.tattoos = {}

	if juddlieApp.tattoos then
		for _, tattoo in ipairs(juddlieApp.tattoos) do
			local zone = tattoo.zone or "ZONE_TORSO"
			if not result.tattoos[zone] then result.tattoos[zone] = {} end
			result.tattoos[zone][#result.tattoos[zone] + 1] = {
				collection = tattoo.collection,
				hashMale = tattoo.overlay,
				hashFemale = tattoo.overlay,
				name = tattoo.label or "",
				zone = zone,
				opacity = 1.0,
			}
		end
	end

	return result
end

---@param illeniumApp table
---@return table? appearance
local function toJuddlieAppearance(illeniumApp)
	if not illeniumApp then return nil end

	local result = { model = illeniumApp.model }

	if illeniumApp.headBlend then
		result.headBlend = {
			shapeFirst = illeniumApp.headBlend.shapeFirst,
			shapeSecond = illeniumApp.headBlend.shapeSecond,
			skinFirst = illeniumApp.headBlend.skinFirst,
			skinSecond = illeniumApp.headBlend.skinSecond,
			shapeMix = illeniumApp.headBlend.shapeMix,
			skinMix = illeniumApp.headBlend.skinMix,
		}
	end

	if illeniumApp.faceFeatures then
		result.faceFeatures = {}
		for illeniumKey, value in pairs(illeniumApp.faceFeatures) do
			local juddlieKey = featureToJuddlie[illeniumKey]
			if juddlieKey then result.faceFeatures[juddlieKey] = value end
		end
	end

	if illeniumApp.headOverlays then
		result.headOverlays = {}
		for i, name in ipairs(illeniumHeadOverlays) do
			local overlay = illeniumApp.headOverlays[name]
			if overlay then
				result.headOverlays[i] = {
					value = (overlay.style == 0 and overlay.opacity == 0) and -1 or overlay.style,
					opacity = overlay.opacity,
					firstColor = overlay.color,
					secondColor = overlay.secondColor,
				}
			else
				result.headOverlays[i] = { value = -1, opacity = 1.0, firstColor = 0, secondColor = 0 }
			end
		end
	end

	if illeniumApp.components then
		result.clothing = {}
		for index, comp in ipairs(illeniumApp.components) do
			result.clothing[index] = {
				component = comp.component_id,
				drawable = comp.drawable,
				texture = comp.texture,
			}
		end
	end

	if illeniumApp.props then
		result.props = {}
		for index, propData in ipairs(illeniumApp.props) do
			result.props[index] = {
				prop = propData.prop_id,
				drawable = propData.drawable,
				texture = propData.texture,
			}
		end
	end

	if illeniumApp.hair then
		result.hair = {
			style = illeniumApp.hair.style,
			color = illeniumApp.hair.color,
			highlight = illeniumApp.hair.highlight,
		}
	end

	result.eyeColor = illeniumApp.eyeColor

	if illeniumApp.tattoos then
		result.tattoos = {}
		for zone, zoneTattoos in pairs(illeniumApp.tattoos) do
			for _, tattoo in ipairs(zoneTattoos) do
				result.tattoos[#result.tattoos + 1] = {
					collection = tattoo.collection,
					overlay = tattoo.hashMale or tattoo.hashFemale,
					zone = zone,
					label = tattoo.name or "",
				}
			end
		end
	end

	return result
end

RegisterNetEvent("illenium-appearance:server:saveAppearance", function(appearance)
	local source <const> = source
	if not source or type(appearance) ~= "table" then return end

	logger.debug("illenium compat: saving appearance for player:", source)
	local juddlieApp <const> = toJuddlieAppearance(appearance)
	if juddlieApp then
		cache.setAppearance(source, juddlieApp)
	end
end)

RegisterNetEvent("illenium-appearance:server:saveOutfit", function(name, model, components, props)
	local source <const> = source
	if not source or type(name) ~= "string" then return end

	logger.debug("illenium compat: saving outfit for player:", source, name)

	local clothing = {}
	if components then
		for index, comp in ipairs(components) do
			clothing[index] = { component = comp.component_id, drawable = comp.drawable, texture = comp.texture }
		end
	end

	local outfitProps = {}
	if props then
		for index, propData in ipairs(props) do
			outfitProps[index] = { prop = propData.prop_id, drawable = propData.drawable, texture = propData.texture }
		end
	end

	local outfit <const> = {
		id = lib.uuid(),
		name = name,
		category = "custom",
		data = {
			model = model or "mp_m_freemode_01",
			clothing = clothing,
			props = outfitProps,
		},
	}

	cache.addOutfit(source, outfit)
end)

RegisterNetEvent("illenium-appearance:server:deleteOutfit", function(id)
	local source <const> = source
	if not source then return end

	logger.debug("illenium compat: deleting outfit for player:", source, id)

	local outfits <const> = cache.getOutfits(source)
	for _, outfit in ipairs(outfits) do
		if outfit.id == tostring(id) or outfit.id == id then
			cache.removeOutfit(source, outfit.id)
			return
		end
	end
end)

RegisterNetEvent("illenium-appearance:server:ChangeRoutingBucket", function()
	local source <const> = source
	if not source then return end
	SetPlayerRoutingBucket(tostring(source), source + 1000)
end)

RegisterNetEvent("illenium-appearance:server:ResetRoutingBucket", function()
	local source <const> = source
	if not source then return end
	SetPlayerRoutingBucket(tostring(source), 0)
end)

logger.info("Registering illenium-appearance server compatibility")

---@param source number
---@return table? appearance
lib.callback.register("illenium-appearance:server:getAppearance", function(source)
	local appearance <const> = cache.getAppearance(source)
  if not appearance then return nil end

	return toIlleniumAppearance(appearance)
end)

---@param source number
---@return table[] outfits
lib.callback.register("illenium-appearance:server:getOutfits", function(source)
	local outfits <const> = cache.getOutfits(source)
	local result = {}

	for _, outfit in ipairs(outfits) do
		result[#result + 1] = {
			id = outfit.id,
			name = outfit.name,
			model = outfit.data and outfit.data.model or "mp_m_freemode_01",
			components = outfit.data and outfit.data.clothing and (function()
				local convertedClothing = {}
				for index, clothingData in ipairs(outfit.data.clothing) do
					convertedClothing[index] = { component_id = clothingData.component, drawable = clothingData.drawable, texture = clothingData.texture }
				end
				return convertedClothing
			end)() or {},
			props = outfit.data and outfit.data.props and (function()
				local convertedProps = {}
				for index, propData in ipairs(outfit.data.props) do
					convertedProps[index] = { prop_id = propData.prop, drawable = propData.drawable, texture = propData.texture }
				end
				return convertedProps
			end)() or {},
		}
	end

	return result
end)

lib.callback.register("illenium-appearance:server:getUniform", function(source)
	return nil
end)

lib.callback.register("illenium-appearance:server:hasMoney", function(source, shopType)
	return true, 0
end)

logger.info("Illenium-appearance server compatibility loaded")
