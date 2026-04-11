if not GetResourceState("qbx_core") == "started" then
	error("qbx_core is not started. Please start qbx_core before starting juddlie_appearance.")
end

local Qbx <const> = exports["qbx_core"]

local bridge = {}

---@param src number
---@return string?
function bridge.getIdentifier(src)
	local player <const> = Qbx:GetPlayer(src)
	if not player then return end

	return player.PlayerData.citizenid
end

return bridge