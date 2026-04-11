local config <const> = require("config")

local context <const> = IsDuplicityVersion() and "server" or "client"
local modulePath <const> = ("bridge/%s/%s"):format(config.framework, context)

local ok, bridge = pcall(require, modulePath)
if not ok then
  error(("Failed to load framework '%s': %s. Please check config.lua"):format(config.framework, bridge))
end

return bridge