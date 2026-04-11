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

return bridge