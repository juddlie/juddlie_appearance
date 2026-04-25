local ped <const> = require("client.modules.ped")

local marketplace = {}

local previewSnapshot = nil

---@param data table
local function applyOutfitFragment(data)
  if type(data) ~= "table" then return end

  if data.clothing then
    for _, c in ipairs(data.clothing) do ped.setClothing(c) end
  end

  if data.props then
    for _, p in ipairs(data.props) do ped.setProp(p) end
  end
end

---@param listingId string
function marketplace.beginPreview(listingId)
  local data <const> = lib.callback.await("juddlie_appearance:server:previewMarketplace", false, listingId)
  if not data then return end

  if not previewSnapshot then
    previewSnapshot = ped.getAppearance(cache.ped)
  end

  applyOutfitFragment(data)
end

function marketplace.endPreview()
  if not previewSnapshot then return end

  ped.applyAppearance(cache.ped, previewSnapshot)
  previewSnapshot = nil
end

---@param payload table
function marketplace.list(payload)
  TriggerServerEvent("juddlie_appearance:server:listMarketplace", payload or {})
end

---@param listingId string
function marketplace.unlist(listingId)
  TriggerServerEvent("juddlie_appearance:server:unlistMarketplace", listingId)
end

---@param query? table
---@param cb fun(rows:table[])
function marketplace.browse(query, cb)
  CreateThread(function()
    local rows <const> = lib.callback.await("juddlie_appearance:server:browseMarketplace", false, query or {})
    cb(rows or {})
  end)
end

---@param listingId string
---@param cb fun(ok:boolean, err:string?, outfit:table?)
function marketplace.buy(listingId, cb)
  CreateThread(function()
    local ok, err, outfit = lib.callback.await("juddlie_appearance:server:buyMarketplace", false, listingId)
    marketplace.endPreview()
    cb(ok, err, outfit)
  end)
end

return marketplace
