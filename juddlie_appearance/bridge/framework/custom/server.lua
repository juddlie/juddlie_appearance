local config <const> = require("config")

local bridge = {}

---@param src string
---@return string?
function bridge.getIdentifier(src)
  local identifier <const> = GetPlayerIdentifierByType(src, config.licenseType)
  if not identifier then return end
  
  local cleaned <const> = identifier:gsub("^.-:", "")

  return cleaned
end

---@param src number|string
---@return table
function bridge.getPlayerData(src)
  local identifier <const> = bridge.getIdentifier(tostring(src))

  return {
    identifier = identifier,
    job = nil,
    jobGrade = 0,
    gang = nil,
  }
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.hasMoney(src, moneyType, amount)
  return true
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.removeMoney(src, moneyType, amount)
  return true
end

---@param src number
---@param moneyType string
---@param amount number
---@return boolean
function bridge.addMoney(src, moneyType, amount)
  return true
end

return bridge