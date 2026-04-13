if GetResourceState("qbx_core") ~= "started" then
	error("qbx_core is not started. Please start qbx_core before starting juddlie_appearance.")
end

local QBXCore <const> = exports["qbx_core"]

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("QBCore:Client:OnPlayerLoaded", handler)
end

---@return string?, number?
function bridge.getPlayerJob()
	local player <const> = QBXCore:GetPlayerData()
	if not player or not player.job then return nil, nil end

	return player.job.name, player.job.grade and player.job.grade.level or 0
end

---@return string?
function bridge.getPlayerGang()
	local player <const> = QBXCore:GetPlayerData()
	if not player or not player.gang then return nil end
	
	return player.gang.name
end

return bridge
