local config <const> = require("config")
local context <const> = IsDuplicityVersion() and "SERVER" or "CLIENT"

local logger = {}

---@param level string
---@param ... any
local function log(level, ...)
  local args <const> = { ... }

  local parts = {}
  for i = 1, #args do
    parts[i] = tostring(args[i])
  end

  print(("^3[%s] ^7[%s] [%s] %s^0"):format(cache.resource, context, level, table.concat(parts, " ")))
end

---@param ... any
function logger.debug(...)
  if not config.debug then return end

  log("DEBUG", ...)
end

---@param ... any
function logger.info(...)
  log("INFO", ...)
end

---@param ... any
function logger.warn(...)
  log("^1WARN^7", ...)
end

---@param ... any
function logger.error(...)
  log("^1ERROR^7", ...)
end

return logger
