local bridge <const> = require("bridge").get("framework")
local config <const> = require("config")
local logger <const> = require("shared.logger")

local nui <const> = require("client.modules.nui")
local ped <const> = require("client.modules.ped")
local camera <const> = require("client.modules.camera")
local menu <const> = require("client.modules.menu")
local randomizer <const> = require("client.modules.randomizer")
local animation <const> = require("client.modules.animation")
local zones <const> = require("client.modules.zones")

local initialSpawn = true

local function initAppearance()
  logger.debug("Fetching appearance from server")

  local appearance <const> = lib.callback.await("juddlie_appearance:server:getAppearance", false)
  if not appearance then
    logger.warn("No appearance data returned from server")
    return
  end

  logger.debug("Applying initial appearance")
  ped.applyAppearance(cache.ped, appearance)
end

nui.handleMessage("appearance:exit", function()
  logger.debug("NUI exit requested")
  menu.close(false)
end)

nui.handleMessage("appearance:apply", function(data)
  if type(data) ~= "table" then return end

  logger.debug("Applying and saving appearance")
  ped.applyAppearance(cache.ped, data)
  menu.originalAppearance = ped.getAppearance(cache.ped)

  TriggerServerEvent("juddlie_appearance:server:saveAppearance", menu.originalAppearance)
end)

nui.handleMessage("appearance:revert", function()
  if not menu.originalAppearance then return end

  logger.debug("Reverting appearance")
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

nui.handleMessage("appearance:removeTattoo", function(data)
  
end)

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

  logger.debug("Saving preset:", data.name)
  TriggerServerEvent("juddlie_appearance:server:savePreset", data)
end)

nui.handleMessage("appearance:deletePreset", function(presetId)
  if type(presetId) ~= "string" then return end

  logger.debug("Deleting preset:", presetId)
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

nui.handleMessage("appearance:saveOutfit", function(data)
  if type(data) ~= "table" or type(data.id) ~= "string" or type(data.name) ~= "string" then return end

  logger.debug("Saving outfit:", data.name)
  TriggerServerEvent("juddlie_appearance:server:saveOutfit", data)
end)

nui.handleMessage("appearance:deleteOutfit", function(outfitId)
  if type(outfitId) ~= "string" then return end

  logger.debug("Deleting outfit:", outfitId)
  TriggerServerEvent("juddlie_appearance:server:deleteOutfit", outfitId)
end)

nui.handleMessage("appearance:updateOutfit", function(data)
  if type(data) ~= "table" or type(data.id) ~= "string" then return end

  TriggerServerEvent("juddlie_appearance:server:updateOutfit", data)
end)

nui.handleMessage("appearance:applyOutfit", function(data)
  if type(data) ~= "table" then return end

  if data.clothing then
    for _, c in ipairs(data.clothing) do
      ped.setClothing(c)
    end
  end

  if data.props then
    for _, p in ipairs(data.props) do
      ped.setProp(p)
    end
  end

  if data.tattoos then
    ClearPedDecorations(cache.ped)
    for _, t in ipairs(data.tattoos) do
      if t.collection and t.overlay then
        AddPedDecorationFromHashes(cache.ped, joaat(t.collection), joaat(t.overlay))
      end
    end
  end
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
  logger.info("Player loaded — initializing appearance")
  initAppearance()
  zones.init()
end)

if config.debug then
  RegisterCommand("appearance", function()
    menu.open()
  end, false)
end

-- ═══════════════════════════════════════════════
-- Reload Skin Command
-- ═══════════════════════════════════════════════

RegisterCommand(config.commands and config.commands.reloadSkin or "reloadskin", function()
  logger.info("Reloading skin from database")
  initAppearance()
  lib.notify({ title = "Appearance", description = "Skin reloaded from database.", type = "success" })
end, false)

AddEventHandler("onResourceStart", function(resource)
  if resource ~= cache.resource then return end

  logger.info("Resource started — initializing")
  initAppearance()
  zones.init()
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= cache.resource then return end

  logger.info("Resource stopping — cleaning up")
  zones.destroy()
  menu.close(false)
end)

-- ═══════════════════════════════════════════════
-- Server-side apply event (for export API)
-- ═══════════════════════════════════════════════

RegisterNetEvent("juddlie_appearance:client:applyAppearance", function(data)
  if type(data) ~= "table" then return end

  ped.applyAppearance(cache.ped, data)
end)

-- ═══════════════════════════════════════════════
-- Enhanced Client Exports
-- ═══════════════════════════════════════════════

exports("open", function(options)
  if type(options) == "table" and options.tabs then
    menu.allowedTabs = options.tabs
    menu.open()
    nui.sendMessage("setAllowedTabs", { tabs = options.tabs })
  else
    menu.allowedTabs = nil
    menu.open()
  end
end)

exports("close", function() menu.close(false) end)

exports("getAppearance", function()
  return ped.getAppearance(cache.ped)
end)

exports("setAppearance", function(data)
  if type(data) ~= "table" then return end
  ped.applyAppearance(cache.ped, data)
end)