local cache <const> = require("server.modules.cache")
local logger <const> = require("shared.logger")
local config <const> = require("config")

local store = {}

---@param kind "component"|"prop"
---@param id number
---@param drawable number
---@param texture? number
---@return number price, string key
local function priceFor(kind, id, drawable, texture)
  local prices <const> = config.itemPrices.items or {}
  local specific <const> = ("%s_%d_%d_%d"):format(kind, id, drawable, texture or -1)
  local general  <const> = ("%s_%d_%d"):format(kind, id, drawable)

  if prices[specific] then return prices[specific], specific end
  if prices[general] then return prices[general], general end

  return 0, general
end

---@param src number
---@param identifier string
---@param appearance table
---@return boolean ok, number totalCost, string[] missing
function store.checkAndCharge(src, identifier, appearance)
  if not config.itemPrices.enabled then return true, 0, {} end
  if type(appearance) ~= "table" then return true, 0, {} end

  local owed = 0
  local toGrant = {}

  if type(appearance.clothing) == "table" then
    for _, c in ipairs(appearance.clothing) do
      if type(c.component) == "number" and type(c.drawable) == "number" then
        local p, key = priceFor("component", c.component, c.drawable, c.texture)
        if p > 0 and not cache.ownsItem(src, "component", key) then
          owed = owed + p
          toGrant[#toGrant + 1] = { kind = "component", key = key, price = p }
        end
      end
    end
  end

  if type(appearance.props) == "table" then
    for _, p in ipairs(appearance.props) do
      if type(p.prop) == "number" and type(p.drawable) == "number" then
        local price, key = priceFor("prop", p.prop, p.drawable, p.texture)
        if price > 0 and not cache.ownsItem(src, "prop", key) then
          owed = owed + price
          toGrant[#toGrant + 1] = { kind = "prop", key = key, price = price }
        end
      end
    end
  end

  if owed == 0 then return true, 0, {} end

  local bridge <const> = require("bridge").get("framework")
  local moneyType <const> = config.itemPrices.moneyType or "cash"

  if not bridge.hasMoney(src, moneyType, owed) then
    local missing = {}
    for _, item in ipairs(toGrant) do missing[#missing + 1] = item.key end
    
    return false, owed, missing
  end

  bridge.removeMoney(src, moneyType, owed)
  for _, item in ipairs(toGrant) do
    cache.grantItem(src, item.kind, item.key)
  end

  logger.info("Per-item charge:", identifier, "owed:", owed, "items:", #toGrant)
  return true, owed, {}
end

---@param src number
---@return table<string,boolean>
function store.getOwnedKeys(src)
  return cache.getOwned(src)
end

---@return table
function store.getCatalog()
  return config.itemPrices.items or {}
end

return store
