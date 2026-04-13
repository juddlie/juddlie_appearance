local bridge <const> = {}

---@param handler function
function bridge.onPlayerLoaded(handler)
  CreateThread(function()
    repeat Wait(500) until NetworkIsSessionActive()

    handler()
  end)
end

---@return string?, number?
function bridge.getPlayerJob() return nil, nil end

---@return string?
function bridge.getPlayerGang() return nil end

return bridge
