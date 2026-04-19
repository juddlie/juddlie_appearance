if GetResourceState("ox_core") ~= "started" then
	error("ox_core is not started. Please start ox_core before starting juddlie_appearance.")
end

local Ox <const> = require '@ox_core.lib.init'

local bridge = {}

---@param src number
---@return string?
function bridge.getIdentifier(src)
	local oxPlayer <const> = Ox.GetPlayer(src)
	if not oxPlayer then return end

	return tostring(oxPlayer.stateId)
end

---@param src number
---@return table
function bridge.getPlayerData(src)
	local oxPlayer <const> = Ox.GetPlayer(src)
	if not oxPlayer then return {} end

	local jobName, jobGrade = oxPlayer.getGroupByType("job")
	local gangName <const> = oxPlayer.getGroupByType("gang")

	return {
		identifier = tostring(oxPlayer.stateId),
		job = jobName or nil,
		jobGrade = jobGrade or 0,
		gang = gangName or nil,
	}
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.hasMoney(src, moneyType, amount)
	return exports.ox_inventory:GetItemCount(src, moneyType) >= amount
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.removeMoney(src, moneyType, amount)
	return exports.ox_inventory:RemoveItem(src, moneyType, amount)
end

return bridge
