lib.versionCheck("juddlie/juddlie_appearance")

local bridge <const> = require("bridge").get("framework")
local logger <const> = require("shared.logger")
local config <const> = require("config")

local sharing <const> = require("server.modules.sharing")
local marketplace <const> = require("server.modules.marketplace")
local store <const> = require("server.modules.store")
local drops <const> = require("server.modules.drops")
local wardrobe <const> = require("server.modules.wardrobe")
local cache <const> = require("server.modules.cache")
local blacklist <const> = require("shared.blacklist")

local locale <const> = require("shared.locale")
locale.init()

local limits <const> = config.limits or {}
local uniformsCfg <const> = config.factionUniforms or {}

local maxPresets <const> = limits.maxPresets or 50
local maxOutfits <const> = limits.maxOutfits or 50
local maxJsonSize <const> = limits.maxPayloadSize or 100000
local maxUniforms <const> = uniformsCfg.maxPerFaction or 25

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

---@param src number
---@return string? faction, string kind, number grade
local function getPlayerFaction(src)
  local data <const> = bridge.getPlayerData(src) or {}

  if data.gang and data.gang ~= "" and data.gang ~= "none" then
    return data.gang, "gang", tonumber(data.jobGrade) or 0
  end

  if data.job and data.job ~= "" and data.job ~= "none" then
    return data.job, "job", tonumber(data.jobGrade) or 0
  end

  return nil, "job", 0
end

---@param src number
---@param faction string
---@return boolean
local function isFactionBoss(src, faction)
  if not faction then return false end

  if uniformsCfg.acePermission and IsPlayerAceAllowed(tostring(src), uniformsCfg.acePermission) then
    return true
  end

  local _, _, grade = getPlayerFaction(src)
  local minGrade <const> = (uniformsCfg.bossGrades and uniformsCfg.bossGrades[faction])
    or uniformsCfg.defaultBossGrade or 4

  return grade >= minGrade
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

---@param uniform table
RegisterNetEvent("juddlie_appearance:server:saveFactionUniform", function(uniform)
  local source <const> = source
  if not uniformsCfg.enabled then return end
  if not source or not validateType(uniform, "table") then return end
  if not validateType(uniform.id, "string") or not validateType(uniform.name, "string") then return end
  if not validateType(uniform.data, "table") then return end
  if not validatePayloadSize(uniform.data) then
    logger.warn("Oversized uniform payload rejected from player:", source)
    return
  end

  local faction, kind = getPlayerFaction(source)
  if not faction then
    lib.notify(source, { title = locale.t("ui.uniforms.title"), description = locale.t("notify.uniform_no_faction"), type = "error" })
    return
  end

  if not isFactionBoss(source, faction) then
    logger.warn("Non-boss tried to save uniform:", source, faction)
    lib.notify(source, { title = locale.t("ui.uniforms.title"), description = locale.t("notify.uniform_not_boss"), type = "error" })
    return
  end

  local existing <const> = MySQL.scalar.await(
    "SELECT id FROM juddlie_appearance_faction_uniforms WHERE faction = ? AND kind = ? AND uniform_id = ?",
    { faction, kind, uniform.id }
  )

  if not existing then
    local count <const> = MySQL.scalar.await(
      "SELECT COUNT(*) FROM juddlie_appearance_faction_uniforms WHERE faction = ? AND kind = ?",
      { faction, kind }
    ) or 0

    if count >= maxUniforms then
      lib.notify(source, { title = locale.t("ui.uniforms.title"), description = locale.t("notify.uniform_max_reached"), type = "error" })
      return
    end
  end

  local minGrade <const> = math.max(0, math.floor(tonumber(uniform.minGrade) or 0))
  local createdBy <const> = bridge.getIdentifier(source)

  MySQL.insert(
    [[
      INSERT INTO juddlie_appearance_faction_uniforms
        (faction, kind, uniform_id, name, min_grade, data, created_by, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        min_grade = VALUES(min_grade),
        data = VALUES(data)
    ]],
    { faction, kind, uniform.id, uniform.name:sub(1, 100), minGrade, json.encode(uniform.data), createdBy, os.time() }
  )

  logger.info("Uniform saved:", source, faction, kind, uniform.name)
  lib.notify(source, { title = locale.t("ui.uniforms.title"), description = locale.t("notify.uniform_saved"), type = "success" })
end)

---@param uniformId string
RegisterNetEvent("juddlie_appearance:server:deleteFactionUniform", function(uniformId)
  local source <const> = source
  if not uniformsCfg.enabled then return end
  if not source or not validateType(uniformId, "string") then return end

  local faction, kind = getPlayerFaction(source)
  if not faction then return end

  if not isFactionBoss(source, faction) then
    logger.warn("Non-boss tried to delete uniform:", source, faction)
    lib.notify(source, { title = locale.t("ui.uniforms.title"), description = locale.t("notify.uniform_not_boss"), type = "error" })
    return
  end

  MySQL.query(
    "DELETE FROM juddlie_appearance_faction_uniforms WHERE faction = ? AND kind = ? AND uniform_id = ?",
    { faction, kind, uniformId }
  )

  logger.info("Uniform deleted:", source, faction, kind, uniformId)
  lib.notify(source, { title = locale.t("ui.uniforms.title"), description = locale.t("notify.uniform_deleted"), type = "success" })
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
  logger.info("Charged player", source, locale.t("ui.common.currency_symbol") .. price, "for:", shopType)
end)

---@param code string
RegisterNetEvent("juddlie_appearance:server:revokeShareCode", function(code)
  local source <const> = source
  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return end

  sharing.revoke(identifier, code)
end)

---@param payload table
RegisterNetEvent("juddlie_appearance:server:listMarketplace", function(payload)
  local source <const> = source
  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return end

  local sellerName <const> = GetPlayerName(source)
  local ok, err = marketplace.list(identifier, sellerName, payload or {})
  if not ok then
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_" .. (err or "failed")), type = "error" })
  else
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_listed"), type = "success" })
  end
end)

---@param listingId string
RegisterNetEvent("juddlie_appearance:server:unlistMarketplace", function(listingId)
  local source <const> = source
  if not source then return end

  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return end

  local ok <const> = marketplace.unlist(identifier, listingId)
  if ok then
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_unlisted"), type = "success" })
  else
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_not_found"), type = "error" })
  end
end)

---@param payload table
RegisterNetEvent("juddlie_appearance:server:adminUpsertDrop", function(payload)
  local source <const> = source
  if config.admin and config.admin.acePermission and not IsPlayerAceAllowed(tostring(source), config.admin.acePermission) then
    return
  end

  local identifier <const> = identifierOf(source); if not identifier then return end
  drops.upsert(identifier, payload or {})
end)

---@param dropId string
RegisterNetEvent("juddlie_appearance:server:adminRemoveDrop", function(dropId)
  local source <const> = source
  if config.admin and config.admin.acePermission and not IsPlayerAceAllowed(tostring(source), config.admin.acePermission) then
    return
  end
  
  drops.remove(dropId)
end)

---@param payload { slot:number, name?:string, data:table }
RegisterNetEvent("juddlie_appearance:server:saveWardrobeSlot", function(payload)
  local source <const> = source
  if type(payload) ~= "table" or type(payload.slot) ~= "number" then return end
  if not validatePayloadSize(payload.data or {}) then return end

  wardrobe.save(source, payload.slot, {
    name = payload.name or ("Slot " .. payload.slot),
    data = payload.data,
  })
end)

---@param slot number
RegisterNetEvent("juddlie_appearance:server:deleteWardrobeSlot", function(slot)
  local source <const> = source
  if type(slot) ~= "number" then return end

  wardrobe.delete(source, slot)
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
---@return table list, boolean canManage, string? faction
lib.callback.register("juddlie_appearance:server:getFactionUniforms", function(src)
  if not uniformsCfg.enabled then return {}, false, nil end

  local faction, kind = getPlayerFaction(src)
  if not faction then return {}, false, nil end

  local rows <const> = MySQL.query.await(
    "SELECT uniform_id AS id, name, min_grade AS minGrade, data, created_at AS createdAt FROM juddlie_appearance_faction_uniforms WHERE faction = ? AND kind = ? ORDER BY name ASC",
    { faction, kind }
  ) or {}

  local _, _, grade = getPlayerFaction(src)
  local list = {}
  for i = 1, #rows do
    local r <const> = rows[i]
    if (tonumber(r.minGrade) or 0) <= grade then
      list[#list + 1] = {
        id = r.id,
        name = r.name,
        minGrade = tonumber(r.minGrade) or 0,
        data = json.decode(r.data),
        createdAt = r.createdAt,
      }
    end
  end

  return list, isFactionBoss(src, faction), faction
end)

---@param source number
---@param opts { outfitId:string, maxUses?:number, ttlSeconds?:number }
---@return string?, string?
lib.callback.register("juddlie_appearance:server:generateShareCode", function(source, opts)
  if type(opts) ~= "table" or type(opts.outfitId) ~= "string" then return nil, "invalid_args" end

  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return nil, "no_identifier" end

  local list <const> = cache.getOutfits(source)
  local outfit
  for _, o in ipairs(list) do 
    if o.id == opts.outfitId then outfit = o break end 
  end

  if not outfit then return nil, "not_found" end

  local code, err = sharing.generate(identifier, outfit.data, {
    kind = "outfit",
    maxUses = opts.maxUses,
    ttlSeconds = opts.ttlSeconds,
  })

  return code, err
end)

---@param source number
---@param code string
---@return boolean ok, string? error, string? outfitId
lib.callback.register("juddlie_appearance:server:importShareCode", function(source, code)
  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return false, "no_identifier" end

  local data, _, err = sharing.import(identifier, code)
  if not data then return false, err end

  local outfitId <const> = ("share_%s_%d"):format(tostring(code):sub(1, 8), os.time())
  cache.addOutfit(source, {
    id = outfitId,
    name = ("Imported %s"):format(os.date("%Y-%m-%d")),
    category = "custom",
    data = data,
    favorite = false,
    createdAt = os.time() * 1000,
    tags = { "imported" },
  })

  return true, nil, outfitId
end)

---@param source number
---@param query? table
---@return table[]
lib.callback.register("juddlie_appearance:server:browseMarketplace", function(source, query)
  local identifier <const> = bridge.getIdentifier(source)
  return marketplace.browse(query or {}, identifier)
end)

---@param source number
---@param listingId string
---@return boolean
lib.callback.register("juddlie_appearance:server:unlistMarketplaceListing", function(source, listingId)
  local source <const> = source
  if not source then return false end

  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return false end

  local ok <const> = marketplace.unlist(identifier, listingId)
  if ok then
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_unlisted"), type = "success" })
  else
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_not_found"), type = "error" })
  end

  return ok
end)

---@param _ number
---@param listingId string
---@return table?
lib.callback.register("juddlie_appearance:server:previewMarketplace", function(_, listingId)
  return marketplace.preview(listingId)
end)

---@param source number
---@param listingId string
---@return boolean, string?, table?
lib.callback.register("juddlie_appearance:server:buyMarketplace", function(source, listingId)
  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return false, "no_identifier" end

  local ok, err, outfit = marketplace.buy(source, identifier, listingId)
  if ok then
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_purchased"), type = "success" })
  else
    lib.notify(source, { title = locale.t("ui.marketplace.title"), description = locale.t("notify.market_" .. (err or "failed")), type = "error" })
  end

  return ok, err, outfit
end)

---@param source number
---@return table<string,boolean>
lib.callback.register("juddlie_appearance:server:getOwnedItems", function(source)
  return store.getOwnedKeys(source)
end)

---@param source number
---@param appearance table
---@return boolean ok, number owed
lib.callback.register("juddlie_appearance:server:checkAndChargeItems", function(source, appearance)
  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return false, 0 end

  local ok, owed = store.checkAndCharge(source, identifier, appearance)
  if ok and owed > 0 then
    lib.notify(source, { title = locale.t("ui.store.title"), description = locale.t("notify.items_charged", locale.t("ui.common.currency_symbol"), owed), type = "info" })
  elseif not ok then
    lib.notify(source, { title = locale.t("ui.store.title"), description = locale.t("notify.items_no_money"), type = "error" })
  end

  return ok, owed
end)

---@param source number
---@return table[]
lib.callback.register("juddlie_appearance:server:getDrops", function(source)
  local data <const> = bridge.getPlayerData(source) or {}

  return drops.listForPlayer(source, data)
end)

---@param source number
---@param dropId string
---@return boolean ok, string? error, table? data
lib.callback.register("juddlie_appearance:server:claimDrop", function(source, dropId)
  local identifier <const> = bridge.getIdentifier(source)
  if not identifier then return false, "no_identifier" end

  local data <const> = bridge.getPlayerData(source) or {}
  local ok, err, dropData = drops.claim(source, identifier, dropId, data)
  if ok then
    lib.notify(source, { title = locale.t("ui.drops.title"), description = locale.t("notify.drop_claimed"), type = "success" })
  end

  return ok, err, dropData
end)

---@param source number
---@return table[] slots, number maxSlots
lib.callback.register("juddlie_appearance:server:getWardrobe", function(source)
  return wardrobe.list(source), wardrobe.maxSlots()
end)

---@param source number
---@param slot number
---@return table?
lib.callback.register("juddlie_appearance:server:applyWardrobeSlot", function(source, slot)
  local entry <const> = wardrobe.get(source, slot)
  if not entry then return nil end

  return entry.data
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

---@param src number
---@return boolean
exports("isFactionBoss", function(src)
  local faction <const> = getPlayerFaction(src)
  if not faction then return false end

  return isFactionBoss(src, faction)
end)

---@param src number
---@param listing table
---@return boolean
exports("listOutfitOnMarketplace", function(src, listing)
  local identifier <const> = identifierOf(src); if not identifier then return false end
  local ok = marketplace.list(identifier, GetPlayerName(src), listing or {})

  return ok
end)

---@param src number
---@param kind string
---@param key string
exports("grantOwnedItem", function(src, kind, key)
  cache.grantItem(src, kind, key)
end)

---@param drop table
---@return boolean
exports("upsertDrop", function(drop)
  return drops.upsert("system", drop or {})
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