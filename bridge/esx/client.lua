if not GetResourceState("es_extended") == "started" then
	error("es_extended is not started. Please start es_extended before starting juddlie_appearance.")
end

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("esx:onPlayerSpawn", handler)
end

return bridge
