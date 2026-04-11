if not GetResourceState("qbx_core") == "started" then
	error("qbx_core is not started. Please start qbx_core before starting juddlie_appearance.")
end

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("QBCore:Client:OnPlayerLoaded", handler)
end

return bridge
