local cache <const> = require("server.modules.cache")

---@param appearance table
RegisterNetEvent("juddlie_appearance:server:saveAppearance", function(appearance)
  local source <const> = source
  if not source then return end

  cache.setAppearance(source, appearance)
end)

---@param preset table
RegisterNetEvent("juddlie_appearance:server:savePreset", function(preset)
  local source <const> = source
  if not source then return end

  cache.addPreset(source, preset)
end)

---@param presetId string
RegisterNetEvent("juddlie_appearance:server:deletePreset", function(presetId)
  local source <const> = source
  if not source then return end

  cache.removePreset(source, presetId)
end)

AddEventHandler("playerDropped", function()
  local source <const> = source
  if not source then return end

  cache.unload(source)
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
  cache.saveAll()
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= GetCurrentResourceName() then return end

  cache.saveAll()
end)

---@param source number
---@return table?
lib.callback.register("juddlie_appearance:server:getAppearance", function(source)
  local source <const> = source
  if not source then return end

  return cache.getAppearance(source)
end)

---@param source number
---@return table?
lib.callback.register("juddlie_appearance:server:getPresets", function(source)
  local source <const> = source
  if not source then return end

  return cache.getPresets(source)
end)
