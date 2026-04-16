lib.versionCheck("juddlie/juddlie_appearance")

local cache <const> = require("server.modules.cache")
local blacklist <const> = require("shared.blacklist")
local bridge <const> = require("bridge").get("framework")
local logger <const> = require("shared.logger")
local config <const> = require("config")

local locale <const> = require("shared.locale")
locale.init()

local limits <const> = config.limits or {}
local maxPresets <const> = limits.maxPresets or 50
local maxOutfits <const> = limits.maxOutfits or 50
local maxJsonSize <const> = limits.maxPayloadSize or 100000

---@param value any
---@param expectedType string
---@return boolean
local function validateType(value, expectedType)
  return type(value) == expectedType
end

---@param data table
---@return boolean
local function validatePayloadSize(data)
  local encoded = json.encode(data)
  return encoded and #encoded <= maxJsonSize
end

---@param appearance table
RegisterNetEvent("juddlie_appearance:server:saveAppearance", function(appearance)
  local source <const> = source
  if not source or not validateType(appearance, "table") then return end
  if not validatePayloadSize(appearance) then
    logger.warn("Oversized appearance payload rejected from player:", source)
    return
  end

  logger.debug("Saving appearance for player:", source)

  if blacklist and blacklist.validateAppearance then
    local playerData <const> = bridge.getPlayerData(source) or {}
    local valid, reason = blacklist.validateAppearance(appearance, playerData)
    if not valid then
      logger.warn("Blacklist blocked appearance save for player:", source, reason)
      lib.notify(source, { title = locale.t("ui.sidebar.appearance"), description = reason or locale.t("notify.restricted"), type = "error" })
      return
    end
  end

  cache.setAppearance(source, appearance)
  logger.debug("Appearance saved for player:", source)
end)

---@param preset table
RegisterNetEvent("juddlie_appearance:server:savePreset", function(preset)
  local source <const> = source
  if not source or not validateType(preset, "table") then return end
  if not validateType(preset.id, "string") or not validateType(preset.name, "string") then return end
  if not validatePayloadSize(preset) then return end

  local existing <const> = cache.getPresets(source)
  if #existing >= maxPresets then
    lib.notify(source, { title = locale.t("ui.sidebar.appearance"), description = locale.t("notify.max_presets"), type = "error" })
    return
  end

  logger.debug("Saving preset for player:", source, preset.name or preset.id)
  cache.addPreset(source, preset)
end)

---@param presetId string
RegisterNetEvent("juddlie_appearance:server:deletePreset", function(presetId)
  local source <const> = source
  if not source or not validateType(presetId, "string") then return end

  logger.debug("Deleting preset for player:", source, presetId)
  cache.removePreset(source, presetId)
end)

---@param outfit table
RegisterNetEvent("juddlie_appearance:server:saveOutfit", function(outfit)
  local source <const> = source
  if not source or not validateType(outfit, "table") then return end
  if not validateType(outfit.id, "string") or not validateType(outfit.name, "string") then return end
  if not validatePayloadSize(outfit) then return end

  local existing <const> = cache.getOutfits(source)
  if #existing >= maxOutfits then
    lib.notify(source, { title = locale.t("ui.sidebar.appearance"), description = locale.t("notify.max_outfits"), type = "error" })
    return
  end

  logger.debug("Saving outfit for player:", source, outfit.name or outfit.id)
  cache.addOutfit(source, outfit)
end)

---@param outfitId string
RegisterNetEvent("juddlie_appearance:server:deleteOutfit", function(outfitId)
  local source <const> = source
  if not source or not validateType(outfitId, "string") then return end

  logger.debug("Deleting outfit for player:", source, outfitId)
  cache.removeOutfit(source, outfitId)
end)

---@param data table
RegisterNetEvent("juddlie_appearance:server:updateOutfit", function(data)
  local source <const> = source
  if not source or type(data) ~= "table" or type(data.id) ~= "string" then return end

  logger.debug("Updating outfit for player:", source, data.id)
  cache.updateOutfit(source, data.id, data)
end)

---@param jobName string
---@param data table
RegisterNetEvent("juddlie_appearance:server:saveJobOutfit", function(jobName, data)
  local source <const> = source
  if not source or not validateType(jobName, "string") or not validateType(data, "table") then return end
  if not validatePayloadSize(data) then return end

  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return end

  logger.debug("Saving job outfit for player:", source, "job:", jobName)

  MySQL.insert(
    "INSERT INTO juddlie_appearance_job_outfits (identifier, job, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)",
    { identifier, jobName, json.encode(data) }
  )
end)

---@param targetSrc number
RegisterNetEvent("juddlie_appearance:server:adminRequestAppearance", function(targetSrc)
  local source <const> = source
  if not source then return end

  if config.admin and config.admin.acePermission then
    if not IsPlayerAceAllowed(tostring(source), config.admin.acePermission) then
      logger.warn("Unauthorized admin command attempt from player:", source)
      lib.notify(source, { title = locale.t("ui.admin.title"), description = locale.t("notify.admin_no_permission"), type = "error" })
      return
    end
  end

  local targetId <const> = tonumber(targetSrc)
  if not targetId or not GetPlayerName(targetId) then
    lib.notify(source, { title = locale.t("ui.admin.title"), description = locale.t("notify.admin_player_not_found"), type = "error" })
    return
  end

  local targetAppearance <const> = cache.getAppearance(targetId)
  if not targetAppearance then
    lib.notify(source, { title = locale.t("ui.admin.title"), description = locale.t("notify.admin_load_failed"), type = "error" })
    return
  end

  logger.info("Admin", source, "requested appearance for player:", targetId)
  TriggerClientEvent("juddlie_appearance:client:adminOpenEditor", source, targetId, targetAppearance)
end)

---@param targetSrc number
---@param appearance table
RegisterNetEvent("juddlie_appearance:server:adminSaveAppearance", function(targetSrc, appearance)
  local source <const> = source
  if not source or not validateType(appearance, "table") then return end
  if not validatePayloadSize(appearance) then return end

  if config.admin and config.admin.acePermission then
    if not IsPlayerAceAllowed(tostring(source), config.admin.acePermission) then
      logger.warn("Unauthorized admin save attempt from player:", source)
      return
    end
  end

  local targetId <const> = tonumber(targetSrc)
  if not targetId or not GetPlayerName(targetId) then return end

  logger.info("Admin", source, "saving appearance for player:", targetId)
  cache.setAppearance(targetId, appearance)

  TriggerClientEvent("juddlie_appearance:client:applyAppearance", targetId, appearance)
end)

AddEventHandler("playerDropped", function()
  local source <const> = source
  if not source then return end

  logger.debug("Player dropped, unloading cache:", source)
  cache.unload(source)
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
  logger.info("Server shutting down — saving all player data")
  cache.saveAll()
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= GetCurrentResourceName() then return end

  logger.info("Resource stopping — saving all player data")
  cache.saveAll()
end)

---@param source number
---@return table?
lib.callback.register("juddlie_appearance:server:getAppearance", function(source)
  local source <const> = source
  if not source then return end

  logger.debug("Callback: getAppearance for player:", source)
  return cache.getAppearance(source)
end)

---@param source number
---@param shopType string
---@return boolean hasEnough
---@return number price
lib.callback.register("juddlie_appearance:server:hasMoney", function(source, shopType)
  local source <const> = source
  if not source or not shopType then return true, 0 end

  local price <const> = config.prices and config.prices[shopType] or 0
  if price <= 0 then return true, 0 end

  return bridge.hasMoney(source, "cash", price), price
end)

RegisterNetEvent("juddlie_appearance:server:chargeCustomer", function(shopType)
  local source <const> = source
  if not source or not shopType then return end

  local price <const> = config.prices and config.prices[shopType] or 0
  if price <= 0 then return end

  if not bridge.hasMoney(source, "cash", price) then
    logger.warn("Player", source, "tried to save without enough money for:", shopType)
    return
  end

  bridge.removeMoney(source, "cash", price)
  logger.info("Charged player", source, "$" .. price, "for:", shopType)
end)

---@param source number
---@return table?
lib.callback.register("juddlie_appearance:server:getPresets", function(source)
  local source <const> = source
  if not source then return end

  return cache.getPresets(source)
end)

---@param source number
---@return table
lib.callback.register("juddlie_appearance:server:getOutfits", function(source)
  local source <const> = source
  if not source then return {} end

  return cache.getOutfits(source)
end)

---@param source number
---@param jobName string
---@return table?
lib.callback.register("juddlie_appearance:server:getJobOutfit", function(source, jobName)
  if not source or not jobName then return end

  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return end

  local data <const> = MySQL.scalar.await(
    "SELECT data FROM juddlie_appearance_job_outfits WHERE identifier = ? AND job = ?",
    { identifier, jobName }
  )

  if data then
    return json.decode(data)
  end

  return nil
end)

---@param src number
---@return table?
exports("getPlayerAppearance", function(src)
  return cache.getAppearance(src)
end)

---@param src number
---@param data table
exports("setPlayerAppearance", function(src, data)
  if type(data) ~= "table" then return end

  cache.setAppearance(src, data)
  TriggerClientEvent("juddlie_appearance:client:applyAppearance", src, data)
end)

---@param src number
---@return table
exports("getPlayerOutfits", function(src)
  return cache.getOutfits(src)
end)

---@param src number
---@param outfitId string
---@return table?
exports("getPlayerOutfit", function(src, outfitId)
  local outfits <const> = cache.getOutfits(src)
  for _, outfit in ipairs(outfits) do
    if outfit.id == outfitId then return outfit end
  end

  return nil
end)


if config.migration and config.migration.enabled then
  local migrate <const> = require("server.modules.migrate")

  RegisterCommand(config.migration.command or "migrateappearance", function(source)
    if source ~= 0 then
      if config.migration.acePermission then
        if not IsPlayerAceAllowed(tostring(source), config.migration.acePermission) then
          lib.notify(source, { title = locale.t("ui.migrate.title"), description = locale.t("notify.admin_no_permission"), type = "error" })
          return
        end
      else
        lib.notify(source, { title = locale.t("ui.migrate.title"), description = locale.t("ui.migrate.console_only"), type = "error" })
        return
      end
    end

    logger.info("Starting illenium-appearance migration...")
    print("^3[juddlie_appearance] Starting migration from illenium-appearance...^0")

    local success, skins, outfits = migrate.fromIllenium()
    if success then
      local msg = ("Migration complete: %d skins, %d outfits migrated."):format(skins, outfits)
      logger.info(msg)
      print(("^2[juddlie_appearance] %s^0"):format(msg))
      if source ~= 0 then
        lib.notify(source, { title = "Migration", description = msg, type = "success" })
      end
    else
      local msg = ("Migration failed: %s"):format(tostring(skins))
      logger.error(msg)
      print(("^1[juddlie_appearance] %s^0"):format(msg))
      if source ~= 0 then
        lib.notify(source, { title = "Migration", description = msg, type = "error" })
      end
    end
  end, true)

  logger.info("Migration command registered:", config.migration.command or "migrateappearance")
end
