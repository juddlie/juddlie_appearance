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

return bridge