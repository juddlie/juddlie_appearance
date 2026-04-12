local cache <const> = require("server.modules.cache")
local blacklist <const> = require("shared.blacklist")
local bridge <const> = require("bridge").get("framework")
local logger <const> = require("shared.logger")

---@param appearance table
RegisterNetEvent("juddlie_appearance:server:saveAppearance", function(appearance)
  local source <const> = source
  if not source then return end

  logger.debug("Saving appearance for player:", source)

  if blacklist and blacklist.validateAppearance then
    local playerData <const> = bridge.getPlayerData(source) or {}
    local valid, reason = blacklist.validateAppearance(appearance, playerData)
    if not valid then
      logger.warn("Blacklist blocked appearance save for player:", source, reason)
      lib.notify(source, { title = "Appearance", description = reason or "Restricted item detected.", type = "error" })
      return
    end
  end

  cache.setAppearance(source, appearance)
  logger.debug("Appearance saved for player:", source)
end)

---@param preset table
RegisterNetEvent("juddlie_appearance:server:savePreset", function(preset)
  local source <const> = source
  if not source then return end

  logger.debug("Saving preset for player:", source, preset.name or preset.id)
  cache.addPreset(source, preset)
end)

---@param presetId string
RegisterNetEvent("juddlie_appearance:server:deletePreset", function(presetId)
  local source <const> = source
  if not source then return end

  logger.debug("Deleting preset for player:", source, presetId)
  cache.removePreset(source, presetId)
end)

---@param outfit table
RegisterNetEvent("juddlie_appearance:server:saveOutfit", function(outfit)
  local source <const> = source
  if not source then return end

  logger.debug("Saving outfit for player:", source, outfit.name or outfit.id)
  cache.addOutfit(source, outfit)
end)

---@param outfitId string
RegisterNetEvent("juddlie_appearance:server:deleteOutfit", function(outfitId)
  local source <const> = source
  if not source then return end

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
