local target <const> = exports.ox_target
local config <const> = require("config")
local logger <const> = require("shared.logger")

local bridge = {}

---@param coords vector3
---@param radius number
---@param key number
---@param label string
---@param onNearby function
---@return CPoint
function bridge.addPoint(coords, radius, key, label, onNearby)
  logger.debug("Adding ox point at:", coords)
  
  local point = lib.points.new({
    coords = coords,
    distance = radius,
  })

  function point:onEnter()
    lib.showTextUI(label)
  end

  function point:onExit()
    lib.hideTextUI()
  end

  function point:nearby()
    if IsControlJustReleased(0, key) then
      onNearby()
    end
  end

  return point
end

---@param id string
---@param coords vector3
---@param radius number
---@param label string
---@param icon string
---@param onSelect function
function bridge.addZone(id, coords, radius, label, icon, onSelect)
  if GetResourceState("ox_target") ~= "started" then
    logger.error("ox_target is not started")
    error("ox_target is not started. set config.interactionType = 'point' or start ox_target.")
  end

  logger.debug("Adding ox_target zone:", id, "at", coords)

  target:addSphereZone({
    coords = coords,
    radius = radius,
    debug = config.debug,
    name = id,
    options = {
      {
        label = label,
        icon = icon or "fas fa-tshirt",
        onSelect = onSelect,
      },
    },
  })
end

---@param id string
function bridge.removeZone(id)
  if GetResourceState("ox_target") ~= "started" then
    logger.error("ox_target is not started")
    error("ox_target is not started. set config.interactionType = 'point' or start ox_target.")
  end

  logger.debug("Removing ox_target zone:", id)
  target:removeZone(id)
end

return bridge
