if GetResourceState("qbx_core") ~= "started" then
	error("qbx_core is not started. Please start qbx_core before starting juddlie_appearance.")
end

local QBXCore <const> = exports["qbx_core"]:GetCoreObject()

local bridge = {}

---@param src number
---@return string?
function bridge.getIdentifier(src)
	local player <const> = QBXCore.Functions.GetPlayer(src)
	if not player then return end

	return player.PlayerData.citizenid
end

---@param src number
---@return table
function bridge.getPlayerData(src)
	local player <const> = QBXCore.Functions.GetPlayer(src)
	if not player then return {} end

	local playerData <const> = player.PlayerData

	return {
		identifier = playerData.citizenid,
		job = playerData.job and playerData.job.name or nil,
		jobGrade = playerData.job and playerData.job.grade and playerData.job.grade.level or 0,
		gang = playerData.gang and playerData.gang.name or nil,
	}
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.hasMoney(src, moneyType, amount)
	local player <const> = QBXCore.Functions.GetPlayer(src)
	if not player then return false end

	return (player.PlayerData.money[moneyType] or 0) >= amount
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.removeMoney(src, moneyType, amount)
	local player <const> = QBXCore.Functions.GetPlayer(src)
	if not player then return false end

	return player.Functions.RemoveMoney(moneyType, amount)
end

return bridge