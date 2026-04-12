if GetResourceState("es_extended") ~= "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_appearance.")
end

local ESX <const> = exports["es_extended"]:getSharedObject()

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("esx:onPlayerSpawn", handler)
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

return bridge
