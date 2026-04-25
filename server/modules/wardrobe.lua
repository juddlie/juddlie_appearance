local cache <const> = require("server.modules.cache")
local config <const> = require("config")

local wardrobe = {}

---@return number
function wardrobe.maxSlots()
  return config.wardrobe.maxSlots or 4
end

---@param src number
---@return table[]
function wardrobe.list(src)
  return cache.getWardrobe(src)
end

---@param src number
---@param slot number
---@param entry { name:string, data:table, thumbnailId?:string }
---@return boolean
function wardrobe.save(src, slot, entry)
  slot = math.floor(tonumber(slot) or -1)
  if slot < 1 or slot > wardrobe.maxSlots() then return false end

  if type(entry) ~= "table" or type(entry.name) ~= "string" or type(entry.data) ~= "table" then
    return false
  end

  cache.setWardrobeSlot(src, slot, entry)
  return true
end

---@param src number
---@param slot number
---@return boolean
function wardrobe.delete(src, slot)
  slot = math.floor(tonumber(slot) or -1)
  if slot < 1 or slot > wardrobe.maxSlots() then return false end

  cache.deleteWardrobeSlot(src, slot)

  return true
end

---@param src number
---@param slot number
---@return table?
function wardrobe.get(src, slot)
  slot = math.floor(tonumber(slot) or -1)

  for _, entry in ipairs(cache.getWardrobe(src)) do
    if entry.slot == slot then return entry end
  end

  return nil
end

return wardrobe
