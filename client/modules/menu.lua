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
menu.shopType = nil
menu.pedMenuActive = false

local defaultTabs <const> = {
  "ped", "face", "hair", "clothing", "props", "tattoos", "colors", "walkstyle", "accessories",
  "presets", "outfits", "wardrobe", "marketplace", "drops", "camera", "history", "randomizer", "animations",
}

---@param tabs string[]?
---@return string[]?
function menu.filterAllowedTabs(tabs)
  if not config.rcoreTattoosCompatibility then return tabs end

  local source <const> = tabs or defaultTabs
  local filtered = {}

  for _, tab in ipairs(source) do
    if tab ~= "tattoos" then
      filtered[#filtered + 1] = tab
    end
  end

  return filtered
end

---@param tabs string[]?
---@return string[]?
function menu.setAllowedTabs(tabs)
  menu.allowedTabs = menu.filterAllowedTabs(tabs)

  if menu.allowedTabs then
    nui.sendMessage("setAllowedTabs", { tabs = menu.allowedTabs })
  end

  return menu.allowedTabs
end

---@param active boolean
function menu.setPedMenuActive(active)
  menu.pedMenuActive = active == true
  nui.sendMessage("setPedMenuActive", { active = menu.pedMenuActive })
end

function menu.open()
  if menu.active then return end

  local allowedTabs <const> = menu.filterAllowedTabs(menu.allowedTabs)
  if allowedTabs and #allowedTabs == 0 then
    logger.warn("No available appearance tabs after compatibility filtering")
    menu.allowedTabs = nil
    menu.setPedMenuActive(false)
    return
  end

  menu.allowedTabs = allowedTabs

  logger.debug("Opening appearance menu")
  menu.active = true
  menu.originalAppearance = ped.getAppearance(cache.ped)

  if config.freezeDuringCustomization ~= false then FreezeEntityPosition(cache.ped, true) end

  if config.invincibleDuringCustomization then SetEntityInvincible(cache.ped, true) end
  if config.hideRadar then DisplayRadar(false) end

  camera.create()
  
  nui.sendMessage("setAppearance", menu.originalAppearance)
  nui.sendMessage("setMaxValues", ped.getMaxValues(cache.ped))
  nui.sendMessage("setShopType", { shopType = menu.shopType })
  nui.sendMessage("setPedMenuActive", { active = menu.pedMenuActive == true })
  if menu.allowedTabs then
    nui.sendMessage("setAllowedTabs", { tabs = menu.allowedTabs })
  end

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
  menu.shopType = nil
  menu.setPedMenuActive(false)
  camera.destroy()

  if config.freezeDuringCustomization ~= false then FreezeEntityPosition(cache.ped, false) end

  if config.invincibleDuringCustomization then SetEntityInvincible(cache.ped, false) end
  if config.hideRadar then DisplayRadar(true) end

  ClearPedTasks(cache.ped)

  SetNuiFocus(false, false)
  nui.sendMessage("setVisible", { visible = false })

  if not save then
    if menu.originalAppearance.model then
      ped.applyModel(menu.originalAppearance.model)
    end
    
    ped.applyAppearance(cache.ped, menu.originalAppearance)
  end

  randomizer.stopAuto()
end

return menu
