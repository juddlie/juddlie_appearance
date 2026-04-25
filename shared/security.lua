local security = {}
local buckets = {}
local lastSweep = 0

---@return number
local function now()
  return GetGameTimer and GetGameTimer() or (os.clock() * 1000)
end

---@param t number
local function sweep(t)
  if t - lastSweep < 300000 then return end

  lastSweep = t
  for k, b in pairs(buckets) do
    if t - b.touched > 300000 then buckets[k] = nil end
  end
end

---@param key string
---@param capacity number
---@param refillMs number 
---@return boolean allowed
function security.allow(key, capacity, refillMs)
  local t <const> = now()
  sweep(t)

  local b = buckets[key]
  if not b then
    b = { tokens = capacity, last = t, touched = t }
    buckets[key] = b
  end

  local elapsed <const> = t - b.last
  if elapsed > 0 and refillMs > 0 then
    local refill <const> = (elapsed / refillMs) * capacity

    b.tokens = math.min(capacity, b.tokens + refill)
    b.last = t
  end

  b.touched = t

  if b.tokens >= 1 then
    b.tokens = b.tokens - 1
    return true
  end

  return false
end

---@param key string
function security.reset(key)
  buckets[key] = nil
end

---@param data any
---@param maxBytes number
---@return boolean
function security.fitsBudget(data, maxBytes)
  local ok, encoded = pcall(json.encode, data)
  if not ok or not encoded then return false end

  return #encoded <= maxBytes
end

---@param length? number
---@return string
function security.randomCode(length)
  length = length or 10

  local alphabet <const> = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

  local out = {}
  for i = 1, length do
    local n <const> = math.random(1, #alphabet)
    out[i] = alphabet:sub(n, n)
  end

  return table.concat(out)
end

return security
