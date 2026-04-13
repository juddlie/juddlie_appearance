local useQBX = GetResourceState("qbx_core") == "started"
local useQB = not useQBX and GetResourceState("qb-core") == "started"

if not useQBX and not useQB then
	error("qbx_core or qb-core is not started. Please start one of them before starting juddlie_appearance.")
end

local bridge = {}

---@param src number
---@return string?
function bridge.getIdentifier(src)
	if useQBX then
		local player <const> = exports["qbx_core"]:GetPlayer(src)
		if not player then return end
		return player.PlayerData.citizenid
	else
		local QBCore <const> = exports["qb-core"]:GetCoreObject()
		local player <const> = QBCore.Functions.GetPlayer(src)
		if not player then return end
		return player.PlayerData.citizenid
	end
end

---@param src number
---@return table
function bridge.getPlayerData(src)
	local pd
	if useQBX then
		local player <const> = exports["qbx_core"]:GetPlayer(src)
		if not player then return {} end
		pd = player.PlayerData
	else
		local QBCore <const> = exports["qb-core"]:GetCoreObject()
		local player <const> = QBCore.Functions.GetPlayer(src)
		if not player then return {} end
		pd = player.PlayerData
	end

	return {
		identifier = pd.citizenid,
		job = pd.job and pd.job.name or nil,
		jobGrade = pd.job and pd.job.grade and pd.job.grade.level or 0,
		gang = pd.gang and pd.gang.name or nil,
	}
end

return bridge