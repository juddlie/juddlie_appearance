local useQBX = GetResourceState("qbx_core") == "started"
local useQB = not useQBX and GetResourceState("qb-core") == "started"

if not useQBX and not useQB then
	error("qbx_core or qb-core is not started. Please start one of them before starting juddlie_appearance.")
end

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("QBCore:Client:OnPlayerLoaded", handler)
end

---@return string?, number?
function bridge.getPlayerJob()
	local player
	if useQBX then
		player = exports["qbx_core"]:GetPlayerData()
	else
		local QBCore <const> = exports["qb-core"]:GetCoreObject()
		player = QBCore.Functions.GetPlayerData()
	end

	if not player or not player.job then return nil, nil end
	return player.job.name, player.job.grade and player.job.grade.level or 0
end

---@return string?
function bridge.getPlayerGang()
	local player
	if useQBX then
		player = exports["qbx_core"]:GetPlayerData()
	else
		local QBCore <const> = exports["qb-core"]:GetCoreObject()
		player = QBCore.Functions.GetPlayerData()
	end

	if not player or not player.gang then return nil end
	return player.gang.name
end

return bridge
