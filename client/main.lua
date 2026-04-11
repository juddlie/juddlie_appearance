local bridge <const> = require("bridge")
local config <const> = require("config")

local nui <const> = require("client.modules.nui")
local ped <const> = require("client.modules.ped")
local camera <const> = require("client.modules.camera")
local menu <const> = require("client.modules.menu")
local randomizer <const> = require("client.modules.randomizer")
local animation <const> = require("client.modules.animation")

local initialSpawn = true

local function initAppearance()
  local appearance <const> = lib.callback.await("juddlie_appearance:server:getAppearance", false)
  if not appearance then return end

  ped.applyAppearance(cache.ped, appearance)
end

nui.handleMessage("appearance:exit", function()
  menu.close(false)
end)

nui.handleMessage("appearance:apply", function(data)
  if type(data) ~= "table" then return end

  ped.applyAppearance(cache.ped, data)
  menu.originalAppearance = ped.getAppearance(cache.ped)

  TriggerServerEvent("juddlie_appearance:server:saveAppearance", menu.originalAppearance)
end)

nui.handleMessage("appearance:revert", function()
  if not menu.originalAppearance then return end

  ped.applyAppearance(cache.ped, menu.originalAppearance)
end)

nui.handleMessage("appearance:quickEdit", function(data)
  if type(data) ~= "table" or not data.type or not data.id then return end

  ped.quickEdit(data)
end)

nui.handleMessage("appearance:setFaceFeature", function(data)
  if type(data) ~= "table" or type(data.key) ~= "string" or type(data.value) ~= "number" then return end

  ped.setFaceFeature(data.key, data.value)
end)

nui.handleMessage("appearance:setHeadBlend", function(data)
  if type(data) ~= "table" then return end

  ped.setHeadBlend(data)
end)

nui.handleMessage("appearance:setHair", function(data)
  if type(data) ~= "table" or data.style == nil or data.color == nil or data.highlight == nil then return end

  ped.setHair(data)
end)

nui.handleMessage("appearance:setOverlay", function(data)
  if type(data) ~= "table" or type(data.index) ~= "number" then return end

  ped.setOverlay(data)
end)

nui.handleMessage("appearance:setEyeColor", function(data)
  if type(data) ~= "table" or type(data.color) ~= "number" then return end

  ped.setEyeColor(data.color)
end)

nui.handleMessage("appearance:setClothing", function(data)
  if type(data) ~= "table" or type(data.component) ~= "number" or type(data.drawable) ~= "number" or type(data.texture) ~= "number" then return end

  ped.setClothing(data)
end)

nui.handleMessage("appearance:setProp", function(data)
  if type(data) ~= "table" or type(data.prop) ~= "number" or type(data.drawable) ~= "number" or type(data.texture) ~= "number" then return end

  ped.setProp(data)
end)

nui.handleMessage("appearance:browseTattoos", function(data)
  if type(data) ~= "table" or type(data.zone) ~= "string" then return end

  local available = {}
  for _, t in ipairs(config.tattoos) do
    if t.zone == data.zone then
      available[#available + 1] = {
        collection = t.collection,
        overlay = t.overlay,
        zone = t.zone,
        label = t.label,
      }
    end
  end

  nui.sendMessage("tattooList", { zone = data.zone, tattoos = available })
end)

nui.handleMessage("appearance:addTattoo", function(data)
  if type(data) ~= "table" or type(data.collection) ~= "string" or type(data.overlay) ~= "string" then return end

  AddPedDecorationFromHashes(cache.ped, joaat(data.collection), joaat(data.overlay))
end)

nui.handleMessage("appearance:removeTattoo", function(data) end)

nui.handleMessage("appearance:reapplyTattoos", function(data)
  if type(data) ~= "table" then return end

  ClearPedDecorations(cache.ped)
  for _, t in ipairs(data) do
    if t.collection and t.overlay then
      AddPedDecorationFromHashes(cache.ped, joaat(t.collection), joaat(t.overlay))
    end
  end
end)

nui.handleMessage("appearance:clearTattoos", function()
  ClearPedDecorations(cache.ped)
end)

nui.handleMessage("appearance:savePreset", function(data)
  if type(data) ~= "table" or type(data.id) ~= "string" or type(data.name) ~= "string" then return end

  TriggerServerEvent("juddlie_appearance:server:savePreset", data)
end)

nui.handleMessage("appearance:deletePreset", function(presetId)
  if type(presetId) ~= "string" then return end

  TriggerServerEvent("juddlie_appearance:server:deletePreset", presetId)
end)

nui.handleMessage("appearance:applyPreset", function(data)
  if type(data) ~= "table" then return end

  ped.applyAppearance(cache.ped, data)
end)

nui.handleMessage("appearance:previewPreset", function(data)
  if type(data) ~= "table" then return end

  ped.applyAppearance(cache.ped, data)
end)

nui.handleMessage("appearance:setCameraPreset", function(data)
  if type(data) ~= "table" or type(data.preset) ~= "string" then return end

  camera.setPreset(data.preset)
end)

nui.handleMessage("appearance:setLighting", function(data)
  if type(data) ~= "table" or type(data.lighting) ~= "string" then return end

  camera.setLighting(data.lighting)
end)

nui.handleMessage("appearance:setFov", function(data)
  if type(data) ~= "table" or type(data.fov) ~= "number" then return end

  camera.setFov(data.fov)
end)

nui.handleMessage("appearance:setZoom", function(data)
  if type(data) ~= "table" or type(data.zoom) ~= "number" then return end

  camera.setZoom(data.zoom)
end)

nui.handleMessage("appearance:setRotation", function(data)
  if type(data) ~= "table" or type(data.rotation) ~= "number" then return end

  camera.setRotation(data.rotation)
end)

nui.handleMessage("appearance:toggleCompare", function(data)
  if type(data) ~= "table" then return end

  if data.enabled and menu.originalAppearance then
    ped.applyAppearance(cache.ped, menu.originalAppearance)
  end
end)

nui.handleMessage("appearance:randomize", function(data)
  if type(data) ~= "table" or type(data.categories) ~= "table" then return end

  randomizer.randomize(data.categories)
end)

nui.handleMessage("appearance:autoRandomize", function(data)
  if type(data) ~= "table" then return end

  if data.enabled then
    randomizer.startAuto(data)
    return
  end

  randomizer.stopAuto()
end)

nui.handleMessage("appearance:playAnimation", function(data)
  if type(data) ~= "table" or type(data.animation) ~= "string" then return end

  animation.play(data.animation)
end)

bridge.onPlayerLoaded(function()
  if not initialSpawn then return end

  initialSpawn = false
  initAppearance()
end)

if config.debug then
  RegisterCommand("appearance", function()
    menu.open()
  end, false)
end

AddEventHandler("onResourceStart", function(resource)
  if resource ~= cache.resource then return end

  initAppearance()
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= cache.resource then return end

  menu.close(false)
end)

exports("open", function() menu.open() end)
exports("close", function() menu.close(false) end)