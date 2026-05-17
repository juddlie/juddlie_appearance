if GetResourceState("es_extended") ~= "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_appearance.")
end

local ped <const> = require("client.modules.ped")
local menu <const> = require("client.modules.menu")
local logger <const> = require("shared.logger")

local ESX <const> = exports["es_extended"]:getSharedObject()

local bridge <const> = {}
local pendingSaveableSubmit = nil
local pendingSaveableCancel = nil
local convertComponents
local convertProps

local legacyFeatureMap <const> = {
	noseWidth = "nose_1",
	nosePeakHeight = "nose_2",
	nosePeakLength = "nose_3",
	noseBoneHeight = "nose_4",
	nosePeakLowering = "nose_5",
	noseBoneTwist = "nose_6",
	eyebrowHeight = "eyebrows_5",
	eyebrowDepth = "eyebrows_6",
	cheekboneHeight = "cheeks_1",
	cheekboneWidth = "cheeks_2",
	cheekWidth = "cheeks_3",
	eyeOpening = "eye_squint",
	lipThickness = "lip_thickness",
	jawBoneWidth = "jaw_1",
	jawBoneLength = "jaw_2",
	chinBoneHeight = "chin_1",
	chinBoneLength = "chin_2",
	chinBoneWidth = "chin_3",
	chinHole = "chin_4",
	neckThickness = "neck_thickness",
}

local legacyOverlayMap <const> = {
	{ value = "blemishes_1", opacity = "blemishes_2" },
	{ value = "beard_1", opacity = "beard_2", color = "beard_3", secondColor = "beard_4" },
	{ value = "eyebrows_1", opacity = "eyebrows_2", color = "eyebrows_3", secondColor = "eyebrows_4" },
	{ value = "age_1", opacity = "age_2" },
	{ value = "makeup_1", opacity = "makeup_2", color = "makeup_3", secondColor = "makeup_4" },
	{ value = "blush_1", opacity = "blush_2", color = "blush_3" },
	{ value = "complexion_1", opacity = "complexion_2" },
	{ value = "sun_1", opacity = "sun_2" },
	{ value = "lipstick_1", opacity = "lipstick_2", color = "lipstick_3", secondColor = "lipstick_4" },
	{ value = "moles_1", opacity = "moles_2" },
	{ value = "chest_1", opacity = "chest_2", color = "chest_3" },
	{ value = "bodyb_1", opacity = "bodyb_2" },
	{ value = "bodyb_3", opacity = "bodyb_4" },
}

---@param skin table
---@return string
local function getModelFromLegacySkin(skin)
	if type(skin.model) == "string" then return skin.model end

	local sex <const> = tonumber(skin.sex) or 0
	return sex == 1 and "mp_f_freemode_01" or "mp_m_freemode_01"
end

---@param value any
---@param fallback number
---@return number
local function numberOr(value, fallback)
	local number <const> = tonumber(value)
	if number == nil then return fallback end

	return number
end

---@param oldSkin table
---@return table
local function convertLegacySkin(oldSkin)
	local converted = {
		model = getModelFromLegacySkin(oldSkin),
		headBlend = {
			shapeFirst = numberOr(oldSkin.mom or oldSkin.face or oldSkin.shapeFirst, 0),
			shapeSecond = numberOr(oldSkin.dad or oldSkin.skin or oldSkin.shapeSecond, 0),
			skinFirst = numberOr(oldSkin.mom or oldSkin.face or oldSkin.skinFirst, 0),
			skinSecond = numberOr(oldSkin.dad or oldSkin.skin or oldSkin.skinSecond, 0),
			shapeMix = numberOr(oldSkin.shape_mix or oldSkin.mix or oldSkin.shapeMix, 0.5),
			skinMix = numberOr(oldSkin.skin_mix or oldSkin.skinMix, 0.5),
		},
		faceFeatures = {},
		headOverlays = {},
		hair = {
			style = numberOr(oldSkin.hair_1, 0),
			color = numberOr(oldSkin.hair_color_1, 0),
			highlight = numberOr(oldSkin.hair_color_2, 0),
		},
		eyeColor = numberOr(oldSkin.eye_color, 0),
		clothing = convertComponents(oldSkin),
		props = convertProps(oldSkin),
		tattoos = oldSkin.tattoos or {},
	}

	for juddlieKey, legacyKey in pairs(legacyFeatureMap) do
		converted.faceFeatures[juddlieKey] = numberOr(oldSkin[legacyKey], 0.0)
	end

	for _, map in ipairs(legacyOverlayMap) do
		local value = numberOr(oldSkin[map.value], -1)
		converted.headOverlays[#converted.headOverlays + 1] = {
			value = value,
			opacity = numberOr(oldSkin[map.opacity], value == -1 and 0.0 or 1.0),
			firstColor = map.color and numberOr(oldSkin[map.color], 0) or 0,
			secondColor = map.secondColor and numberOr(oldSkin[map.secondColor], 0) or 0,
		}
	end

	return converted
end

---@param skin table
---@return table
local function normalizeSkin(skin)
	if skin.model and (skin.headBlend or skin.clothing or skin.headOverlays or skin.faceFeatures) then
		return skin
	end

	return convertLegacySkin(skin)
end

---@param skin table
---@param cb function?
local function loadSkin(skin, cb)
	if skin then
		local normalized <const> = normalizeSkin(skin)

		logger.debug("ESX compat: Loading skin with model:", normalized.model)
		if normalized.model then
			ped.applyModel(normalized.model)
		end

		ped.applyAppearance(cache.ped, normalized)
		TriggerEvent("skinchanger:modelLoaded")
	end

	if cb then cb() end
end

---@param oldSkin table
---@param existing? table
---@return table
function convertComponents(oldSkin, existing)
	return {
		{ component = 0, drawable = (existing and existing[1] and existing[1].drawable) or 0, texture = (existing and existing[1] and existing[1].texture) or 0 },
		{ component = 1, drawable = oldSkin.mask_1 or (existing and existing[2] and existing[2].drawable) or 0, texture = oldSkin.mask_2 or (existing and existing[2] and existing[2].texture) or 0 },
		{ component = 2, drawable = (existing and existing[3] and existing[3].drawable) or 0, texture = (existing and existing[3] and existing[3].texture) or 0 },
		{ component = 3, drawable = oldSkin.arms or (existing and existing[4] and existing[4].drawable) or 0, texture = oldSkin.arms_2 or (existing and existing[4] and existing[4].texture) or 0 },
		{ component = 4, drawable = oldSkin.pants_1 or (existing and existing[5] and existing[5].drawable) or 0, texture = oldSkin.pants_2 or (existing and existing[5] and existing[5].texture) or 0 },
		{ component = 5, drawable = oldSkin.bags_1 or (existing and existing[6] and existing[6].drawable) or 0, texture = oldSkin.bags_2 or (existing and existing[6] and existing[6].texture) or 0 },
		{ component = 6, drawable = oldSkin.shoes_1 or (existing and existing[7] and existing[7].drawable) or 0, texture = oldSkin.shoes_2 or (existing and existing[7] and existing[7].texture) or 0 },
		{ component = 7, drawable = oldSkin.chain_1 or (existing and existing[8] and existing[8].drawable) or 0, texture = oldSkin.chain_2 or (existing and existing[8] and existing[8].texture) or 0 },
		{ component = 8, drawable = oldSkin.tshirt_1 or (existing and existing[9] and existing[9].drawable) or 0, texture = oldSkin.tshirt_2 or (existing and existing[9] and existing[9].texture) or 0 },
		{ component = 9, drawable = oldSkin.bproof_1 or (existing and existing[10] and existing[10].drawable) or 0, texture = oldSkin.bproof_2 or (existing and existing[10] and existing[10].texture) or 0 },
		{ component = 10, drawable = oldSkin.decals_1 or (existing and existing[11] and existing[11].drawable) or 0, texture = oldSkin.decals_2 or (existing and existing[11] and existing[11].texture) or 0 },
		{ component = 11, drawable = oldSkin.torso_1 or (existing and existing[12] and existing[12].drawable) or 0, texture = oldSkin.torso_2 or (existing and existing[12] and existing[12].texture) or 0 },
	}
end

---@param oldSkin table
---@param existing? table
---@return table
function convertProps(oldSkin, existing)
	return {
		{ prop = 0, drawable = oldSkin.helmet_1 or (existing and existing[1] and existing[1].drawable) or -1, texture = oldSkin.helmet_2 or (existing and existing[1] and existing[1].texture) or -1 },
		{ prop = 1, drawable = oldSkin.glasses_1 or (existing and existing[2] and existing[2].drawable) or -1, texture = oldSkin.glasses_2 or (existing and existing[2] and existing[2].texture) or -1 },
		{ prop = 2, drawable = oldSkin.ears_1 or (existing and existing[3] and existing[3].drawable) or -1, texture = oldSkin.ears_2 or (existing and existing[3] and existing[3].texture) or -1 },
		{ prop = 6, drawable = oldSkin.watches_1 or (existing and existing[4] and existing[4].drawable) or -1, texture = oldSkin.watches_2 or (existing and existing[4] and existing[4].texture) or -1 },
		{ prop = 7, drawable = oldSkin.bracelets_1 or (existing and existing[5] and existing[5].drawable) or -1, texture = oldSkin.bracelets_2 or (existing and existing[5] and existing[5].texture) or -1 },
	}
end

---@param clothes table
local function applyClothesFromOldSkin(clothes)
	local currentAppearance <const> = ped.getAppearance(cache.ped)
	local components <const> = convertComponents(clothes, currentAppearance.clothing)
	local props <const> = convertProps(clothes, currentAppearance.props)

	for _, c in ipairs(components) do ped.setClothing(c) end
	for _, p in ipairs(props) do ped.setProp(p) end
end

---@param exportName string
---@param func function
local function exportHandler(exportName, func)
	AddEventHandler(("__cfx_export_skinchanger_%s"):format(exportName), function(setCB)
		setCB(func)
	end)
end

RegisterNetEvent("skinchanger:loadSkin2", function(pedHandle, skin)
	if not skin then return end
	local normalized <const> = normalizeSkin(skin)

	logger.debug("ESX compat: skinchanger:loadSkin2")
	ped.applyAppearance(pedHandle, normalized)
end)

RegisterNetEvent("skinchanger:getSkin", function(cb)
	logger.debug("ESX compat: skinchanger:getSkin")

	local appearance <const> = ped.getAppearance(cache.ped)
	if cb then cb(appearance) end
end)

RegisterNetEvent("skinchanger:loadSkin", function(skin, cb)
	loadSkin(skin, cb)
end)

RegisterNetEvent("skinchanger:loadDefaultModel", function(loadMale, cb)
	local model <const> = loadMale and "mp_m_freemode_01" or "mp_f_freemode_01"
	logger.debug("ESX compat: skinchanger:loadDefaultModel", model)
	ped.applyModel(model)
	TriggerEvent("skinchanger:modelLoaded")
	if cb then cb() end
end)

RegisterNetEvent("skinchanger:loadClothes", function(_, clothes)
	if not clothes then return end

	logger.debug("ESX compat: skinchanger:loadClothes")
	applyClothesFromOldSkin(clothes)
end)

AddEventHandler("esx_skin:openSaveableMenu", function(onSubmit, onCancel)
	logger.info("ESX: openSaveableMenu triggered")
	pendingSaveableSubmit = onSubmit
	pendingSaveableCancel = onCancel
	menu.allowedTabs = nil
	menu.open()
end)

AddEventHandler("esx_skin:openMenu", function(onSubmit, onCancel)
	logger.info("ESX: openMenu triggered")
	pendingSaveableSubmit = onSubmit
	pendingSaveableCancel = onCancel
	menu.allowedTabs = nil
	menu.open()
end)

AddEventHandler("esx_skin:openRestrictedMenu", function(onSubmit, onCancel)
	logger.info("ESX: openRestrictedMenu triggered")
	pendingSaveableSubmit = onSubmit
	pendingSaveableCancel = onCancel
	menu.allowedTabs = nil
	menu.open()
end)

AddEventHandler("esx_skin:openSaveableRestrictedMenu", function(onSubmit, onCancel)
	logger.info("ESX: openSaveableRestrictedMenu triggered")
	pendingSaveableSubmit = onSubmit
	pendingSaveableCancel = onCancel
	menu.allowedTabs = nil
	menu.open()
end)

AddEventHandler("juddlie_appearance:client:appearanceApplied", function(appearance)
	if pendingSaveableSubmit then
		pendingSaveableSubmit(appearance)
		pendingSaveableSubmit = nil
		pendingSaveableCancel = nil
	end
end)

AddEventHandler("juddlie_appearance:client:appearanceCancelled", function()
	if pendingSaveableCancel then
		pendingSaveableCancel()
		pendingSaveableSubmit = nil
		pendingSaveableCancel = nil
	end
end)

AddEventHandler("esx_skin:playerRegistered", function()
	logger.info("ESX: playerRegistered triggered")

	local playerData <const> = ESX.GetPlayerData()
	if playerData and playerData.skin then
		loadSkin(playerData.skin)
		return
	end

	ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
		if skin then
			loadSkin(skin)
			return
		end

		logger.debug("ESX compat: No player skin found on registration")
		loadSkin({ sex = 0 }, function()
			TriggerEvent("esx_skin:openSaveableMenu")
		end)
	end)
end)

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("esx:playerLoaded", handler)
end

---@return string?, number?
function bridge.getPlayerJob()
	local player <const> = ESX.GetPlayerData()
	if player and player.job then
		return player.job.name, player.job.grade
	end

	return nil, nil
end

---@return string?
function bridge.getPlayerGang() return nil end

exportHandler("GetSkin", function()
	local appearance <const> = lib.callback.await("juddlie_appearance:server:getAppearance", false)
	return appearance
end)

exportHandler("LoadSkin", function(skin)
	return loadSkin(skin)
end)

exportHandler("LoadClothes", function(_, clothesSkin)
	if not clothesSkin then return end
	applyClothesFromOldSkin(clothesSkin)
end)

return bridge
