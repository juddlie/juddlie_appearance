if GetResourceState("es_extended") ~= "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_appearance.")
end

local ped <const> = require("client.modules.ped")
local menu <const> = require("client.modules.menu")
local nui <const> = require("client.modules.nui")
local logger <const> = require("shared.logger")

local ESX <const> = exports["es_extended"]:getSharedObject()

local bridge <const> = {}

---@param skin table
---@param cb function?
local function loadSkin(skin, cb)
	if skin and skin.model then
		logger.debug("ESX compat: Loading skin with model:", skin.model)
		ped.applyAppearance(cache.ped, skin)
	end

	if cb then cb() end
end

---@param oldSkin table
---@param existing? table
---@return table
local function convertComponents(oldSkin, existing)
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
local function convertProps(oldSkin, existing)
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
	if not skin.model then skin.model = "mp_m_freemode_01" end

	logger.debug("ESX compat: skinchanger:loadSkin2")
	ped.applyAppearance(pedHandle, skin)
end)

RegisterNetEvent("skinchanger:getSkin", function(cb)
	logger.debug("ESX compat: skinchanger:getSkin")

	local appearance <const> = lib.callback.await("juddlie_appearance:server:getAppearance", false)
	if cb then cb(appearance) end
end)

RegisterNetEvent("skinchanger:loadSkin", function(skin, cb)
	loadSkin(skin, cb)
end)

RegisterNetEvent("skinchanger:loadClothes", function(_, clothes)
	if not clothes then return end

	logger.debug("ESX compat: skinchanger:loadClothes")
	applyClothesFromOldSkin(clothes)
end)

AddEventHandler("esx_skin:openSaveableMenu", function(onSubmit, onCancel)
	logger.info("ESX: openSaveableMenu triggered")
	menu.open()
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
