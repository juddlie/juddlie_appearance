local config <const> = require("config")
local localeModule = nil

pcall(function()
  localeModule = require("shared.locale")
end)

local nui = {}

nui.ready = false
nui.visible = false

---@return boolean
function nui.isVisible()
  return nui.visible
end

---@param visible boolean
---@param focus boolean?
function nui.setVisible(visible, focus)
  if type(focus) == "boolean" then
    SetNuiFocus(visible, visible)
  end

  nui.visible = visible
  nui.sendMessage("setVisible", { visible = visible })
end

---@param action string
---@param data table?
function nui.sendMessage(action, data)
  data = data or {}

  SendNUIMessage({ action = action, data = data })
end

---@param message string
---@param handler function
function nui.handleMessage(message, handler)
  RegisterNUICallback(message, function(body, cb)
    handler(body)
    cb("ok")
  end)
end

nui.handleMessage("ready", function()
  if nui.ready then return end

  nui.ready = true
  nui.sendMessage("setConfig", {
    cameraPresets = config.cameraPresets,
    lightingPresets = config.lightingPresets,
    cameraDefaults = config.cameraDefaults,
    cameraRanges = config.cameraRanges,
    animations = config.animations,
    overlayLabels = config.overlayLabels,
    componentLabels = config.componentLabels,
    propLabels = config.propLabels,
    propIds = config.propIds,
    tattooZones = config.tattooZones,
    faceRegions = config.faceRegions,
    quickSlots = config.quickSlots,
    randomizerCategories = config.randomizerCategories,
    outfitCategories = config.outfitCategories,
    locale = config.locale or "en",
    localeStrings = localeModule and localeModule.getAll() or {},
    disabledComponents = config.disabledComponents or {},
    disabledProps = config.disabledProps or {},
  })
end)

return nui