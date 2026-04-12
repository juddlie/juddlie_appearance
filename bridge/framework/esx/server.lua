if GetResourceState("es_extended") ~= "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_appearance.")
end

local logger <const> = require("shared.logger")

local ESX <const> = exports["es_extended"]:getSharedObject()

local bridge = {}

---@param src number
---@return string?
function bridge.getIdentifier(src)
	local xPlayer <const> = ESX.GetPlayerFromId(src)
	if not xPlayer then return end

	return xPlayer.identifier
end

---@param src number
---@return table
function bridge.getPlayerData(src)
	local xPlayer <const> = ESX.GetPlayerFromId(src)
	if not xPlayer then return {} end

	return {
		identifier = xPlayer.identifier,
		job = xPlayer.job and xPlayer.job.name or nil,
		jobGrade = xPlayer.job and xPlayer.job.grade or 0,
		gang = nil,
	}
end

ESX.RegisterServerCallback("esx_skin:getPlayerSkin", function(source, cb)
	local xPlayer <const> = ESX.GetPlayerFromId(source)
	if not xPlayer then
		cb(nil, {})
		return
	end

	logger.debug("ESX compat: esx_skin:getPlayerSkin for", source)

	local playerCache <const> = require("server.modules.cache")
	local appearance <const> = playerCache.getAppearance(source)
	cb(appearance, {
		skin_male = xPlayer.job and xPlayer.job.skin_male or nil,
		skin_female = xPlayer.job and xPlayer.job.skin_female or nil,
	})
end)

return bridge