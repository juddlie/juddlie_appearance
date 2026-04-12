local target <const> = exports["qb-target"]
local config <const> = require("config")
local logger <const> = require("shared.logger")

local bridge = {}

---@param id string
---@param coords vector3
---@param radius number
---@param label string
---@param icon string
---@param onSelect function
function bridge.addZone(id, coords, radius, label, icon, onSelect)
  if GetResourceState("qb-target") ~= "started" then
    logger.error("qb-target is not started")
    error("qb-target is not started. set config.interactionType = 'point' or start qb-target.")
  end

  logger.debug("Adding qb-target zone:", id, "at", coords)

  target:AddCircleZone(id, coords, radius, {
    name = id,
    debugPoly = config.debug,
  }, {
    options = {
      {
        type = "client",
        label = label,
        icon = icon or "fas fa-tshirt",
        action = onSelect,
      },
    },
    distance = radius,
  })
end

---@param id string
function bridge.removeZone(id)
  if GetResourceState("qb-target") ~= "started" then
    logger.error("qb-target is not started")
    error("qb-target is not started. set config.interactionType = 'point' or start qb-target.")
  end

  logger.debug("Removing qb-target zone:", id)
  target:RemoveZone(id)
end

return bridge
