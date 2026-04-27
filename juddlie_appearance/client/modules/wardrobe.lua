local ped <const> = require("client.modules.ped")

local wardrobe = {}

---@param cb function
function wardrobe.refresh(cb)
  CreateThread(function()
    local list, max = lib.callback.await("juddlie_appearance:server:getWardrobe", false)
    
    cb(list or {}, max or 4)
  end)
end

---@param slot number
---@param name string
---@param data table
function wardrobe.save(slot, name, data)
  TriggerServerEvent("juddlie_appearance:server:saveWardrobeSlot", {
    slot = slot, name = name, data = data,
  })
end

---@param slot number
function wardrobe.delete(slot)
  TriggerServerEvent("juddlie_appearance:server:deleteWardrobeSlot", slot)
end

---@param slot number
---@param cb? function
function wardrobe.apply(slot, cb)
  CreateThread(function()
    local data <const> = lib.callback.await("juddlie_appearance:server:applyWardrobeSlot", false, slot)
    if type(data) == "table" then
      ped.applyAppearance(cache.ped, data)
    end

    if cb then cb(data) end
  end)
end

return wardrobe
