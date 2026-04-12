local bridge <const> = require("bridge").get("framework")
local logger <const> = require("shared.logger")

local players = {}
local cache = {}

---@param src number
---@return table?
function cache.load(src)
  if players[src] then return players[src] end

  local identifier <const> = bridge.getIdentifier(src)
  if not identifier then
    logger.warn("Failed to get identifier for player:", src)
    return
  end

  logger.debug("Loading player data:", src, identifier)

  local skin <const> = MySQL.scalar.await(
    "SELECT skin FROM juddlie_appearance WHERE identifier = ?",
    { identifier }
  )

  local presetRows <const> = MySQL.query.await(
    "SELECT * FROM juddlie_appearance_presets WHERE identifier = ? ORDER BY created_at DESC",
    { identifier }
  )

  local outfitRows <const> = MySQL.query.await(
    "SELECT * FROM juddlie_appearance_outfits WHERE identifier = ? ORDER BY created_at DESC",
    { identifier }
  )

  local presets = {}
  for _, row in ipairs(presetRows or {}) do
    presets[row.preset_id] = {
      id = row.preset_id,
      name = row.name,
      tags = json.decode(row.tags) or {},
      data = json.decode(row.data),
      createdAt = row.created_at,
      shareCode = row.share_code,
    }
  end

  local outfits = {}
  for _, row in ipairs(outfitRows or {}) do
    outfits[row.outfit_id] = {
      id = row.outfit_id,
      name = row.name,
      category = row.category or "custom",
      data = json.decode(row.data),
      shareCode = row.share_code,
      favorite = row.favorite == 1,
      createdAt = row.created_at,
    }
  end

  players[src] = {
    identifier = identifier,
    appearance = skin and json.decode(skin) or nil,
    presets = presets,
    outfits = outfits,
  }

  logger.info("Player data loaded:", src, identifier)
  return players[src]
end

---@param src number
function cache.unload(src)
  local player <const> = players[src]
  if not player then return end

  logger.debug("Unloading player data:", src, player.identifier)

  if player.appearance then
    MySQL.insert(
      "INSERT INTO juddlie_appearance (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = VALUES(skin)",
      { player.identifier, json.encode(player.appearance) }
    )
  end

  players[src] = nil
end

---@param src number
---@return table?
function cache.getAppearance(src)
  local player <const> = cache.load(src)
  if not player then return end

  return player.appearance
end

---@param src number
---@param appearance table
function cache.setAppearance(src, appearance)
  local player <const> = cache.load(src)
  if not player then return end

  player.appearance = appearance
end

---@param src number
---@return table
function cache.getPresets(src)
  local player <const> = cache.load(src)
  if not player then return {} end

  local list = {}
  for _, preset in pairs(player.presets) do
    list[#list + 1] = preset
  end

  table.sort(list, function(a, b) return (a.createdAt or 0) > (b.createdAt or 0) end)
  return list
end

---@param src number
---@param preset table
function cache.addPreset(src, preset)
  local player <const> = cache.load(src)
  if not player then return end

  player.presets[preset.id] = {
    id = preset.id,
    name = preset.name,
    tags = preset.tags or {},
    data = preset.data,
    createdAt = preset.createdAt or os.time() * 1000,
    shareCode = preset.shareCode,
  }

  MySQL.insert(
    "INSERT INTO juddlie_appearance_presets (identifier, preset_id, name, tags, data, share_code, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
    {
      player.identifier,
      preset.id,
      preset.name,
      json.encode(preset.tags or {}),
      json.encode(preset.data),
      preset.shareCode,
      preset.createdAt or os.time() * 1000,
    }
  )
end

---@param src number
---@param presetId string
function cache.removePreset(src, presetId)
  local player <const> = cache.load(src)
  if not player then return end

  player.presets[presetId] = nil

  MySQL.query(
    "DELETE FROM juddlie_appearance_presets WHERE identifier = ? AND preset_id = ?",
    { player.identifier, presetId }
  )
end

---@param src number
---@return table
function cache.getOutfits(src)
  local player <const> = cache.load(src)
  if not player then return {} end

  local list = {}
  for _, outfit in pairs(player.outfits) do
    list[#list + 1] = outfit
  end

  table.sort(list, function(a, b) return (a.createdAt or 0) > (b.createdAt or 0) end)
  return list
end

---@param src number
---@param outfit table
function cache.addOutfit(src, outfit)
  local player <const> = cache.load(src)
  if not player then return end

  player.outfits[outfit.id] = {
    id = outfit.id,
    name = outfit.name,
    category = outfit.category or "custom",
    data = outfit.data,
    shareCode = outfit.shareCode,
    favorite = outfit.favorite or false,
    createdAt = outfit.createdAt or os.time() * 1000,
  }

  MySQL.insert(
    "INSERT INTO juddlie_appearance_outfits (identifier, outfit_id, name, category, data, share_code, favorite, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    {
      player.identifier,
      outfit.id,
      outfit.name,
      outfit.category or "custom",
      json.encode(outfit.data),
      outfit.shareCode,
      outfit.favorite and 1 or 0,
      outfit.createdAt or os.time() * 1000,
    }
  )
end

---@param src number
---@param outfitId string
function cache.removeOutfit(src, outfitId)
  local player <const> = cache.load(src)
  if not player then return end

  player.outfits[outfitId] = nil

  MySQL.query(
    "DELETE FROM juddlie_appearance_outfits WHERE identifier = ? AND outfit_id = ?",
    { player.identifier, outfitId }
  )
end

---@param src number
---@param outfitId string
---@param updates table
function cache.updateOutfit(src, outfitId, updates)
  local player <const> = cache.load(src)
  if not player or not player.outfits[outfitId] then return end

  local outfit <const> = player.outfits[outfitId]

  if updates.name then outfit.name = updates.name end
  if updates.category then outfit.category = updates.category end
  if updates.favorite ~= nil then outfit.favorite = updates.favorite end

  MySQL.query(
    "UPDATE juddlie_appearance_outfits SET name = ?, category = ?, favorite = ? WHERE identifier = ? AND outfit_id = ?",
    { outfit.name, outfit.category, outfit.favorite and 1 or 0, player.identifier, outfitId }
  )
end

function cache.saveAll()
  local count = 0
  for src in pairs(players) do
    cache.unload(src)
    count = count + 1
  end
  logger.info("Saved all player data:", count, "players")
end

return cache
