local bridge <const> = require("bridge").get("framework")
local cache <const> = require("server.modules.cache")
local logger <const> = require("shared.logger")
local security <const> = require("shared.security")
local config <const> = require("config")

local marketplace = {}

---@param identifier string
---@return number
local function activeListingCount(identifier)
  return MySQL.scalar.await(
    "SELECT COUNT(*) FROM juddlie_appearance_marketplace WHERE seller = ? AND status = 'active'",
    { identifier }
  ) or 0
end

---@param identifier string
---@param sellerName string?
---@param listing { id:string, name:string, description?:string, category?:string, tags?:table, price:number, data:table, ttlSeconds?:number }
---@return boolean ok, string? error
function marketplace.list(identifier, sellerName, listing)
  if not config.marketplace.enabled then return false, "disabled" end

  if type(listing) ~= "table" 
    or type(listing.id) ~= "string" 
    or type(listing.name) ~= "string"
    or type(listing.data) ~= "table"
  then
    return false, "invalid_args"
  end

  if not security.fitsBudget(listing.data, (config.marketplace.maxPayloadBytes) or 100000) then
    return false, "payload_too_large"
  end

  if not security.allow(
    "market-list:" .. identifier, 
    (config.marketplace.rateLimitList) or 5, 
    (config.marketplace.rateLimitWindowMs) or 60000) 
  then
    return false, "rate_limited"
  end

  local maxListings <const> = config.marketplace.maxListingsPerSeller or 5
  if activeListingCount(identifier) >= maxListings then
    return false, "max_listings"
  end

  local price <const> = math.max(
    config.marketplace.minPrice or 1, 
    math.min(config.marketplace.maxPrice or 1000000,
    math.floor(tonumber(listing.price) or 0))
  )

  local now <const> = os.time() * 1000
  local expiresAt = nil
  if listing.ttlSeconds and listing.ttlSeconds > 0 then
    expiresAt = now + (listing.ttlSeconds * 1000)
  elseif (config.marketplace.defaultTtlHours or 0) > 0 then
    expiresAt = now + (config.marketplace.defaultTtlHours * 3600 * 1000)
  end

  MySQL.insert(
    [[
      INSERT INTO juddlie_appearance_marketplace
        (id, seller, seller_name, name, description, category, tags, price, data, created_at, expires_at, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
    ]],
    {
      listing.id,
      identifier,
      sellerName,
      listing.name:sub(1, 100),
      (listing.description or ""):sub(1, 500),
      listing.category or "custom",
      json.encode(listing.tags or {}),
      price,
      json.encode(listing.data),
      now,
      expiresAt,
    }
  )

  logger.info("Marketplace listing created:", listing.id, "by:", identifier, "price:", price)
  return true, nil
end

---@param identifier string
---@param listingId string
---@return boolean
function marketplace.unlist(identifier, listingId)
  if not config.marketplace.enabled then return false end
  if type(listingId) ~= "string" then return false end

  local affected <const> = MySQL.update.await(
    "UPDATE juddlie_appearance_marketplace SET status = 'cancelled' WHERE id = ? AND seller = ? AND status = 'active'",
    { listingId, identifier }
  ) or 0

  return affected > 0
end

---@param query? { search?:string, category?:string, sort?:string, limit?:number, offset?:number }
---@param viewerIdentifier? string
---@return table[]
function marketplace.browse(query, viewerIdentifier)
  if not config.marketplace.enabled then return {} end
  query = query or {}

  local where = { "status = 'active'", "(expires_at IS NULL OR expires_at > ?)" }

  ---@type any[]
  local params = { os.time() * 1000 }

  if query.search and #query.search > 0 then
    where[#where + 1] = "(name LIKE ? OR description LIKE ?)"
    
    local like <const> = "%" .. query.search:gsub("[%%_]", "") .. "%"

    params[#params + 1] = like
    params[#params + 1] = like
  end

  if query.category and #query.category > 0 then
    where[#where + 1] = "category = ?"
    params[#params + 1] = query.category
  end

  local order = "created_at DESC"
  if query.sort == "price_asc" then order = "price ASC"
  elseif query.sort == "price_desc" then order = "price DESC"
  elseif query.sort == "popular" then order = "purchases DESC"
  end

  local limit <const> = math.min(50, math.max(1, math.floor(tonumber(query.limit) or 25)))
  local offset <const> = math.max(0, math.floor(tonumber(query.offset) or 0))

  params[#params + 1] = limit
  params[#params + 1] = offset

  local rows <const> = MySQL.query.await(
    ("SELECT id, seller, seller_name, name, description, category, tags, price, purchases, created_at, expires_at FROM juddlie_appearance_marketplace WHERE %s ORDER BY %s LIMIT ? OFFSET ?"):format(table.concat(where, " AND "), order),
    params
  ) or {}

  for _, r in ipairs(rows) do
    r.tags = r.tags and json.decode(r.tags) or {}
    r.isMine = viewerIdentifier ~= nil and r.seller == viewerIdentifier
    r.sellerName = r.seller_name; r.seller_name = nil
  end
  
  return rows
end

---@param listingId string
---@return table?
function marketplace.preview(listingId)
  if not config.marketplace.enabled or type(listingId) ~= "string" then return nil end

  local row <const> = MySQL.single.await(
    "SELECT data FROM juddlie_appearance_marketplace WHERE id = ? AND status = 'active'",
    { listingId }
  )
  if not row then return nil end

  return json.decode(row.data)
end

---@param src number
---@param identifier string
---@param listingId string
---@return boolean ok, string? error, table? outfit
function marketplace.buy(src, identifier, listingId)
  if not config.marketplace.enabled then return false, "disabled" end
  if type(listingId) ~= "string" then return false, "invalid_args" end

  if not security.allow("market-buy:" .. identifier, config.marketplace.rateLimitBuy or 10, config.marketplace.rateLimitWindowMs or 60000) then
    return false, "rate_limited"
  end

  local listing <const> = MySQL.single.await(
    "SELECT * FROM juddlie_appearance_marketplace WHERE id = ? AND status = 'active' FOR UPDATE",
    { listingId }
  )
  if not listing then return false, "not_found" end
  if listing.seller == identifier then return false, "own_listing" end
  
  if listing.expires_at and os.time() * 1000 > listing.expires_at then
    return false, "expired"
  end

  local price <const> = listing.price
  local moneyType <const> = config.marketplace.moneyType or "cash"

  if not bridge.hasMoney(src, moneyType, price) then
    return false, "no_money"
  end
  if not bridge.removeMoney(src, moneyType, price) then
    return false, "charge_failed"
  end

  local taxRate <const> = math.max(0, math.min(1, tonumber(config.marketplace.tax) or 0))
  local payout <const> = math.floor(price * (1 - taxRate))
  if payout > 0 then
    local players <const> = GetPlayers()
    for _, pid in ipairs(players) do
      local pidNum <const> = tonumber(pid)
      if pidNum and bridge.getIdentifier(pidNum) == listing.seller then
        if bridge.addMoney then bridge.addMoney(pidNum, moneyType, payout) end
        break
      end
    end
  end

  MySQL.query(
    "UPDATE juddlie_appearance_marketplace SET purchases = purchases + 1 WHERE id = ?",
    { listingId }
  )

  if config.marketplace.singleUse then
    MySQL.query(
      "UPDATE juddlie_appearance_marketplace SET status = 'sold' WHERE id = ?",
      { listingId }
    )
  end

  local outfitData <const> = json.decode(listing.data)
  local outfitId <const> = ("mp_%s_%d"):format(listingId:sub(1, 8), os.time())
  cache.addOutfit(src, {
    id = outfitId,
    name = listing.name .. " (Marketplace)",
    category = listing.category or "custom",
    data = outfitData,
    favorite = false,
    createdAt = os.time() * 1000,
    tags = { "marketplace" },
  })

  logger.info("Marketplace sale:", listingId, "buyer:", identifier, "seller:", listing.seller, "price:", price, "payout:", payout)
  return true, nil, { id = outfitId, data = outfitData, name = listing.name }
end

return marketplace
