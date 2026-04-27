if GetResourceState("ox_core") ~= "started" then
	error("ox_core is not started. Please start ox_core before starting juddlie_appearance.")
end

local menu <const> = require("client.modules.menu")

local Ox <const> = require '@ox_core.lib.init'
local player <const> = Ox.GetPlayer()

local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
	RegisterNetEvent("ox:setActiveCharacter", function(character)
		if character.isNew then
			menu.open()
			return
		end

		handler()
	end)
end

---@return string?, number?
function bridge.getPlayerJob()
	local name, grade = player.getGroupByType("job")
	if not name then return nil, nil end

	return name, grade or 0
end

---@return string?
function bridge.getPlayerGang()
	local name <const> = player.getGroupByType("gang")
	return name
end

return bridge
