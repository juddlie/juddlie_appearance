local config <const> = require("config")
local logger <const> = require("shared.logger")
local locale <const> = require("shared.locale")

local nui <const> = require("client.modules.nui")
local ped <const> = require("client.modules.ped")
local menu <const> = require("client.modules.menu")

local admin = {}

admin.targetSource = nil
admin.isAdminEdit = false

---@param targetSrc number
---@param targetAppearance table
function admin.openForPlayer(targetSrc, targetAppearance)
  if not targetAppearance then
    lib.notify({ title = locale.t("ui.admin.title"), description = locale.t("notify.admin_load_failed"), type = "error" })
    return
  end

  admin.targetSource = targetSrc
  admin.isAdminEdit = true

  logger.info("Admin editing appearance for player:", targetSrc)
  lib.notify({ title = locale.t("ui.admin.title"), description = locale.t("ui.admin.editing", targetSrc), type = "info" })

  ped.applyAppearance(cache.ped, targetAppearance)

  menu.open()
  menu.originalAppearance = targetAppearance
  nui.sendMessage("setAppearance", targetAppearance)
  nui.sendMessage("setMaxValues", ped.getMaxValues(cache.ped))
  nui.sendMessage("setAdminMode", { enabled = true, targetId = targetSrc })
end

---@param appearance table
function admin.saveForPlayer(appearance)
  if not admin.isAdminEdit or not admin.targetSource then return end

  logger.info("Admin saving appearance for player:", admin.targetSource)
  TriggerServerEvent("juddlie_appearance:server:adminSaveAppearance", admin.targetSource, appearance)

  lib.notify({ title = locale.t("ui.admin.title"), description = locale.t("ui.admin.saved", admin.targetSource), type = "success" })
end

function admin.close()
  if not admin.isAdminEdit then return end

  logger.debug("Closing admin edit mode")

  local ourAppearance <const> = lib.callback.await("juddlie_appearance:server:getAppearance", false)
  if ourAppearance then
    ped.applyAppearance(cache.ped, ourAppearance)
  end

  admin.targetSource = nil
  admin.isAdminEdit = false
  nui.sendMessage("setAdminMode", { enabled = false, targetId = nil })
end


function admin.init()
  if not config.admin or not config.admin.enabled then return end

  RegisterCommand(config.admin.command or "setappearance", function(_, args)
    local targetId = tonumber(args[1])
    if not targetId then
      lib.notify({ title = locale.t("ui.admin.title"), description = locale.t("notify.admin_usage"), type = "error" })
      return
    end

    logger.debug("Admin command: editing player", targetId)
    TriggerServerEvent("juddlie_appearance:server:adminRequestAppearance", targetId)
  end, false)

  logger.info("Admin commands initialized")
end

return admin
