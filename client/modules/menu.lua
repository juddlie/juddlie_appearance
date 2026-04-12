local config <const> = require("config")
local logger <const> = require("shared.logger")

local nui <const> = require("client.modules.nui")
local ped <const> = require("client.modules.ped")
local camera <const> = require("client.modules.camera")
local randomizer <const> = require("client.modules.randomizer")

local menu = {}

menu.active = false
menu.originalAppearance = nil
menu.allowedTabs = nil

function menu.open()
  if menu.active then return end

  logger.debug("Opening appearance menu")
  menu.active = true
  menu.originalAppearance = ped.getAppearance(cache.ped)

  FreezeEntityPosition(cache.ped, true)

  if config.invincibleDuringCustomization then SetEntityInvincible(cache.ped, true) end
  if config.hideRadar then DisplayRadar(false) end

  camera.create()
  
  nui.sendMessage("setAppearance", menu.originalAppearance)

  local userPresets <const> = lib.callback.await("juddlie_appearance:server:getPresets", false)
  if userPresets then
    nui.sendMessage("setPresets", userPresets)
  end

  local userOutfits <const> = lib.callback.await("juddlie_appearance:server:getOutfits", false)
  if userOutfits then
    nui.sendMessage("setOutfits", userOutfits)
  end

  nui.setVisible(true, true)
end

---@param save boolean
function menu.close(save)
  if not menu.active then return end

  logger.debug("Closing appearance menu, save:", save)
  menu.active = false
  menu.allowedTabs = nil
  camera.destroy()

  FreezeEntityPosition(cache.ped, false)

  if config.invincibleDuringCustomization then SetEntityInvincible(cache.ped, false) end
  if config.hideRadar then DisplayRadar(true) end

  ClearPedTasks(cache.ped)

  SetNuiFocus(false, false)
  nui.sendMessage("setVisible", { visible = false })

  if not save then
    ped.applyAppearance(cache.ped, menu.originalAppearance)
  end

  randomizer.stopAuto()
end

return menu
