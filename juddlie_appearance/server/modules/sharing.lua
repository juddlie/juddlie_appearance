local logger <const> = require("shared.logger")
local security <const> = require("shared.security")
local config <const> = require("config")

local sharing = {}

---@param identifier string
---@param payload table 
---@param opts? { kind?:string, maxUses?:number, ttlSeconds?:number }
---@return string? code, string? error
function sharing.generate(identifier, payload, opts)
  if type(identifier) ~= "string" or type(payload) ~= "table" then
    return nil, "invalid_args"
  end

  opts = opts or {}

  if not security.fitsBudget(
    payload,
    (config.share.maxPayloadBytes) or 100000)
  then
    return nil, "payload_too_large"
  end

  if not security.allow(
    "share-gen:" .. identifier,
    config.share.rateLimitGen or 5,
    (config.share.rateLimitWindowMs) or 60000)
  then
    return nil, "rate_limited"
  end

  local code
  for _ = 1, 5 do
    local candidate <const> = security.randomCode(config.share.codeLength or 6)
    local exists <const> = MySQL.scalar.await(
      "SELECT 1 FROM juddlie_appearance_share_codes WHERE code = ?",
      { candidate }
    )
    if not exists then code = candidate; break end
  end
  if not code then return nil, "code_collision" end

  local now <const> = os.time() * 1000
  local expiresAt = nil
  if opts.ttlSeconds and opts.ttlSeconds > 0 then
    expiresAt = now + (opts.ttlSeconds * 1000)
  end

  MySQL.insert(
    [[
      INSERT INTO juddlie_appearance_share_codes
        (code, identifier, kind, payload, max_uses, uses, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, 0, ?, ?)
    ]],
    {
      code,
      identifier,
      opts.kind or "outfit",
      json.encode(payload),
      math.max(0, math.floor(tonumber(opts.maxUses) or 0)),
      expiresAt,
      now,
    }
  )

  logger.info("Share code generated:", code, "by:", identifier)
  return code, nil
end

---@param identifier string
---@param code string
---@return table? data, nil, string? error
function sharing.import(identifier, code)
  if type(code) ~= "string" or #code < 4 or #code > 32 then
    return nil, nil, "invalid_code"
  end

  if not security.allow(
    "share-import:" .. identifier,
    (config.share.rateLimitImport) or 20,
    (config.share.rateLimitWindowMs) or 60000)
  then
    return nil, nil, "rate_limited"
  end

  local row <const> = MySQL.single.await(
    "SELECT * FROM juddlie_appearance_share_codes WHERE code = ?",
    { code:upper() }
  )
  if not row then return nil, nil, "not_found" end

  local now <const> = os.time() * 1000
  if row.expires_at and now > row.expires_at then
    return nil, nil, "expired"
  end
  
  if row.max_uses and row.max_uses > 0 and row.uses >= row.max_uses then
    return nil, nil, "exhausted"
  end

  MySQL.query(
    "UPDATE juddlie_appearance_share_codes SET uses = uses + 1 WHERE code = ?",
    { row.code }
  )

  local ok, decoded = pcall(json.decode, row.payload)
  if not ok then return nil, nil, "corrupt" end

  return decoded, nil, nil
end

---@param identifier string
---@param code string
---@return boolean
function sharing.revoke(identifier, code)
  if type(code) ~= "string" then return false end
  
  local affected <const> = MySQL.update.await(
    "DELETE FROM juddlie_appearance_share_codes WHERE code = ? AND identifier = ?",
    { code:upper(), identifier }
  ) or 0
  
  return affected > 0
end

---@param identifier string
---@return table[]
function sharing.list(identifier)
  return MySQL.query.await(
    "SELECT code, kind, max_uses, uses, expires_at, created_at FROM juddlie_appearance_share_codes WHERE identifier = ? ORDER BY created_at DESC",
    { identifier }
  ) or {}
end

return sharing
