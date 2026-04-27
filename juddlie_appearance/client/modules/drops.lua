local ped <const> = require("client.modules.ped")

local drops = {}

local previewSnapshot = nil

---@param cb fun(list:table[])
function drops.refresh(cb)
  CreateThread(function()
    local list <const> = lib.callback.await("juddlie_appearance:server:getDrops", false) or {}
    cb(list)
  end)
end

---@param data table
function drops.preview(data)
  if type(data) ~= "table" then return end

  if not previewSnapshot then
    previewSnapshot = ped.getAppearance(cache.ped)
  end

  if data.clothing then
    for _, c in ipairs(data.clothing) do ped.setClothing(c) end
  end

  if data.props then
    for _, p in ipairs(data.props) do ped.setProp(p) end
  end
end

function drops.endPreview()
  if not previewSnapshot then return end
  
  ped.applyAppearance(cache.ped, previewSnapshot)
  previewSnapshot = nil
end

---@param dropId string
---@param cb fun(ok:boolean, err:string?)
function drops.claim(dropId, cb)
  CreateThread(function()
    local ok, err = lib.callback.await("juddlie_appearance:server:claimDrop", false, dropId)
    cb(ok, err)
  end)
end

return drops
