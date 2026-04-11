local bridge <const> = require("bridge")

local players = {}
local cache = {}

---@param src number
---@return table?
function cache.load(src)
  if players[src] then return players[src] end

  local identifier <const> = bridge.getIdentifier(src)
  if not identifier then return end

  local skin <const> = MySQL.scalar.await(
    "SELECT skin FROM juddlie_appearance WHERE identifier = ?",
    { identifier }
  )

  local rows <const> = MySQL.query.await(
    "SELECT * FROM juddlie_appearance_presets WHERE identifier = ? ORDER BY created_at DESC",
    { identifier }
  )

  local presets = {}
  for _, row in ipairs(rows or {}) do
    presets[row.preset_id] = {
      id = row.preset_id,
      name = row.name,
      tags = json.decode(row.tags) or {},
      data = json.decode(row.data),
      createdAt = row.created_at,
      shareCode = row.share_code,
    }
  end

  players[src] = {
    identifier = identifier,
    appearance = skin and json.decode(skin) or nil,
    presets = presets,
  }

  return players[src]
end

---@param src number
function cache.unload(src)
  local player <const> = players[src]
  if not player then return end

  if player.appearance then
    MySQL.insert.await(
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

function cache.saveAll()
  for src in pairs(players) do
    cache.unload(src)
  end
end

return cache
