local config <const> = require("config")
local logger <const> = require("shared.logger")

local locale = {}
local strings = {}
local fallback = {}

---@param lang string
---@return table? translations
local function loadLocaleFile(lang)
  local path <const> = ("locales/%s.json"):format(lang)
  local raw <const> = LoadResourceFile(cache.resource, path)

  if not raw then
    logger.warn("Locale file not found:", path)
    return nil
  end

  local ok, data = pcall(json.decode, raw)
  if not ok or type(data) ~= "table" then
    logger.error("Failed to parse locale file:", path)
    return nil
  end

  return data
end

function locale.init()
  fallback = loadLocaleFile("en") or {}

  local lang <const> = config.locale or "en"
  if lang ~= "en" then
    strings = loadLocaleFile(lang) or {}
    logger.info("Locale loaded:", lang, "(" .. tostring(#strings) .. " keys)")
  else
    strings = fallback
  end
end

---@param key string
---@param ... any
---@return string translated
function locale.t(key, ...)
  local value = locale.resolve(strings, key) or locale.resolve(fallback, key) or key

  if select("#", ...) > 0 then
    local ok, result = pcall(string.format, value, ...)
    if ok then return result end
  end

  return value
end

---@param tbl table
---@param key string
---@return string?
function locale.resolve(tbl, key)
  local current = tbl
  for part in key:gmatch("[^%.]+") do
    if type(current) ~= "table" then return nil end
    current = current[part]
  end

  if type(current) == "string" then return current end
  return nil
end

---@return table all 
function locale.getAll()
  local merged = {}

  locale.flatten(fallback, "", merged)
  locale.flatten(strings, "", merged)

  return merged
end

---@param tbl table
---@param prefix string
---@param result table
function locale.flatten(tbl, prefix, result)
  for k, v in pairs(tbl) do
    local fullKey = prefix == "" and k or (prefix .. "." .. k)
    if type(v) == "table" then
      locale.flatten(v, fullKey, result)
    else
      result[fullKey] = v
    end
  end
end

return locale
