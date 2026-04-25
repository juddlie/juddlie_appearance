local sharing = {}

---@param outfitId string
---@param opts? table
---@param cb fun(code:string?, err:string?)
function sharing.generate(outfitId, opts, cb)
  CreateThread(function()
    local payload <const> = opts or {}
    payload.outfitId = outfitId

    local code, err = lib.callback.await("juddlie_appearance:server:generateShareCode", false, payload)
    cb(code, err)
  end)
end

---@param code string
---@param cb fun(ok:boolean, err:string?, outfitId:string?)
function sharing.import(code, cb)
  CreateThread(function()
    local ok, err, outfitId = lib.callback.await("juddlie_appearance:server:importShareCode", false, code)
    
    cb(ok, err, outfitId)
  end)
end

---@param code string
function sharing.revoke(code)
  TriggerServerEvent("juddlie_appearance:server:revokeShareCode", code)
end

return sharing
