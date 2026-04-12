if not GetResourceState("es_extended") == "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_appearance.")
end

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

return bridge