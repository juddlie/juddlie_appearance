local cache <const> = require("server.modules.cache")
local logger <const> = require("shared.logger")
local config <const> = require("config")

local drops = {}

---@param drop table
---@param src number
---@param playerData table
---@return boolean
local function passesRestrictions(drop, src, playerData)
  local r <const> = drop.restrictions
  if not r or type(r) ~= "table" then return true end

  if r.aces and #r.aces > 0 then
    local has = false
    for _, ace in ipairs(r.aces) do
      if IsPlayerAceAllowed(tostring(src), ace) then has = true break end
    end

    if not has then return false end
  end

  if r.jobs and #r.jobs > 0 then
    local match = false
    for _, j in ipairs(r.jobs) do
      if playerData.job == j then match = true break end
    end

    if not match then return false end
  end

  if r.gangs and #r.gangs > 0 then
    local match = false
    for _, g in ipairs(r.gangs) do
      if playerData.gang == g then match = true break end
    end

    if not match then return false end
  end

  if r.minJobGrade and (playerData.jobGrade or 0) < r.minJobGrade then
    return false
  end

  return true
end

---@param drop table
---@param now number
---@return boolean
local function inWindow(drop, now)
  if drop.startsAt and now < drop.startsAt then return false end
  if drop.endsAt and now > drop.endsAt then return false end

  return true
end

---@param row table from db
---@return table normalized
local function normalizeDbRow(row)
  return {
    id = row.id,
    name = row.name,
    description = row.description,
    tier = row.tier,
    data = json.decode(row.data),
    restrictions = row.restrictions and json.decode(row.restrictions) or nil,
    startsAt = row.starts_at,
    endsAt = row.ends_at,
    claimable = row.claimable == 1,
    source = "db",
  }
end

---@param src number
---@param playerData table
---@return table[]
function drops.listForPlayer(src, playerData)
  local now <const> = os.time() * 1000
  local out = {}

  for _, d in ipairs((config.drops and config.drops.static) or {}) do
    if inWindow(d, now) and passesRestrictions(d, src, playerData) then
      local normalized <const> = {
        id = d.id, name = d.name, description = d.description,
        tier = d.tier or "seasonal",
        data = d.data,
        restrictions = d.restrictions,
        startsAt = d.startsAt, endsAt = d.endsAt,
        claimable = d.claimable == true,
        source = "config",
      }

      out[#out + 1] = normalized
    end
  end

  local rows <const> = MySQL.query.await(
    "SELECT * FROM juddlie_appearance_drops WHERE (starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?)",
    { now, now }
  ) or {}

  for _, row in ipairs(rows) do
    local normalized <const> = normalizeDbRow(row)
    if passesRestrictions(normalized, src, playerData) then
      out[#out + 1] = normalized
    end
  end

  return out
end

---@param src number
---@param identifier string
---@param dropId string
---@param playerData table
---@return boolean ok, string? error, table? data
function drops.claim(src, identifier, dropId, playerData)
  if type(dropId) ~= "string" then return false, "invalid_args" end

  local list <const> = drops.listForPlayer(src, playerData)

  for _, d in ipairs(list) do
    if d.id == dropId then
      if not d.claimable then return false, "not_claimable" end
      cache.addOutfit(src, {
        id = "drop_" .. dropId .. "_" .. tostring(os.time()),
        name = d.name,
        category = "custom",
        data = d.data,
        favorite = false,
        createdAt = os.time() * 1000,
        tags = { "drop", d.tier or "seasonal" },
      })
      logger.info("Drop claimed:", dropId, "by:", identifier)
      return true, nil, d.data
    end
  end

  return false, "not_found"
end

---@param identifier string
---@param drop table  
---@return boolean
function drops.upsert(identifier, drop)
  if type(drop) ~= "table"
    or type(drop.id) ~= "string"
    or type(drop.name) ~= "string"
    or type(drop.data) ~= "table"
  then
    return false
  end

  MySQL.insert(
    [[
      INSERT INTO juddlie_appearance_drops
        (id, name, description, tier, data, restrictions, starts_at, ends_at, claimable, created_by, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        description = VALUES(description),
        tier = VALUES(tier),
        data = VALUES(data),
        restrictions = VALUES(restrictions),
        starts_at = VALUES(starts_at),
        ends_at = VALUES(ends_at),
        claimable = VALUES(claimable)
    ]],
    {
      drop.id,
      drop.name:sub(1, 100),
      (drop.description or ""):sub(1, 500),
      drop.tier or "seasonal",
      json.encode(drop.data),
      drop.restrictions and json.encode(drop.restrictions) or nil,
      drop.startsAt,
      drop.endsAt,
      drop.claimable and 1 or 0,
      identifier,
      os.time() * 1000,
    }
  )
  return true
end

---@param dropId string
function drops.remove(dropId)
  if type(dropId) ~= "string" then return end
  
  MySQL.query("DELETE FROM juddlie_appearance_drops WHERE id = ?", { dropId })
end

return drops
