local config <const> = require("config")
local logger <const> = require("shared.logger")
local context <const> = IsDuplicityVersion() and "server" or "client"

local bridge = {}
local loaded = {}

---@param type "framework" | "interaction"
---@return table
function bridge.get(type)
  if loaded[type] then return loaded[type] end

  if type == "framework" then
    local path <const> = ("bridge/framework/%s/%s"):format(config.framework, context)
    logger.debug("Loading framework bridge:", path)
    local ok, mod = pcall(require, path)
    if not ok then
      logger.error("Failed to load framework bridge:", config.framework, mod)
      error(("Failed to load framework bridge '%s': %s. Check config.lua"):format(config.framework, mod))
    end

    loaded[type] = mod
    logger.info("Framework bridge loaded:", config.framework)
    return mod
  end

  if type == "interaction" then
    if not config.interaction then
      logger.debug("Interaction bridge disabled")
      return {}
    end
    if context ~= "client" then return {} end

    local path <const> = ("bridge/interaction/%s/client"):format(config.interaction)
    logger.debug("Loading interaction bridge:", path)
    local ok, mod = pcall(require, path)
    if not ok then
      logger.error("Failed to load interaction bridge:", config.interaction, mod)
      error(("Failed to load interaction bridge '%s': %s. Check config.lua"):format(config.interaction, mod))
    end

    loaded[type] = mod
    logger.info("Interaction bridge loaded:", config.interaction)
    return mod
  end

  error(("Unknown bridge type '%s'. Use 'framework' or 'interaction'"):format(type))
end

return bridge