if GetResourceState("qbx_core") ~= "started" then
	error("qbx_core is not started. Please start qbx_core before starting juddlie_appearance.")
end

local QBX <const> = exports["qbx_core"]:GetPlayerData()

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("QBCore:Client:OnPlayerLoaded", handler)
end

---@return string?, number?
function bridge.getPlayerJob()
	local player <const> = QBX:GetPlayerData()
	if player and player.job then
		return player.job.name, player.job.grade and player.job.grade.level or 0
	end

	return nil, nil
end

---@return string?
function bridge.getPlayerGang()
	local player <const> = QBX:GetPlayerData()
	if player and player.gang then
		return player.gang.name
	end

	return nil
end

return bridge
