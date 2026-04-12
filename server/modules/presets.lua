local bridge <const> = require("bridge").get("framework")

local presets = {}

---@param src number
---@return table
function presets.getAll(src)
  local identifier <const> = bridge.getIdentifier(src)
  if not identifier then return {} end

  local rows <const> = MySQL.query.await(
    "SELECT * FROM juddlie_appearance_presets WHERE identifier = ? ORDER BY created_at DESC",
    { identifier }
  )

  local result = {}
  for _, row in ipairs(rows or {}) do
    result[#result + 1] = {
      id = row.preset_id,
      name = row.name,
      tags = json.decode(row.tags) or {},
      data = json.decode(row.data),
      createdAt = row.created_at,
      shareCode = row.share_code,
    }
  end

  return result
end

---@param src number
---@param preset table
function presets.save(src, preset)
  local identifier <const> = bridge.getIdentifier(src)
  if not (identifier and preset) then return end

  MySQL.insert.await(
    "INSERT INTO juddlie_appearance_presets (identifier, preset_id, name, tags, data, share_code, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
    {
      identifier,
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
function presets.delete(src, presetId)
  local identifier <const> = bridge.getIdentifier(src)
  if not identifier then return end

  MySQL.query.await(
    "DELETE FROM juddlie_appearance_presets WHERE identifier = ? AND preset_id = ?",
    { identifier, presetId }
  )
end

return presets