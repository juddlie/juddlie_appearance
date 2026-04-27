local config <const> = require("config")

local blacklist = {}

---@param playerData table { job: string?, gang: string?, identifier: string? }
---@param rule table { jobs: table?, gangs: table?, identifiers: table?, aces: table?, invert: boolean? }
---@return boolean
local function matchesRule(playerData, rule)
  local matched = false

  if rule.jobs then
    for _, job in ipairs(rule.jobs) do
      if playerData.job == job then
        matched = true
        break
      end
    end
  end

  if not matched and rule.gangs then
    for _, gang in ipairs(rule.gangs) do
      if playerData.gang == gang then
        matched = true
        break
      end
    end
  end

  if not matched and rule.identifiers then
    for _, id in ipairs(rule.identifiers) do
      if playerData.identifier == id then
        matched = true
        break
      end
    end
  end

  if not matched and rule.aces then
    for _, ace in ipairs(rule.aces) do
      if playerData.aces and playerData.aces[ace] then
        matched = true
        break
      end
    end
  end

  if rule.invert then
    return not matched
  end

  return matched
end

---@param component number
---@param drawable number
---@param playerData table
---@return boolean
function blacklist.isClothingBlocked(component, drawable, playerData)
  if not config.blacklist or not config.blacklist.enabled then return false end

  local isWhitelist <const> = config.blacklist.mode == "whitelist"
  local foundRule = false

  for _, rule in ipairs(config.blacklist.clothing or {}) do
    if rule.component == component then
      for _, d in ipairs(rule.drawables or {}) do
        if d == drawable then
          foundRule = true
          local matched <const> = matchesRule(playerData, rule)
          if isWhitelist then
            return not matched
          else
            return matched
          end
        end
      end
    end
  end

  return isWhitelist and not foundRule
end

---@param prop number
---@param drawable number
---@param playerData table
---@return boolean
function blacklist.isPropBlocked(prop, drawable, playerData)
  if not config.blacklist or not config.blacklist.enabled then return false end

  local isWhitelist <const> = config.blacklist.mode == "whitelist"
  local foundRule = false

  for _, rule in ipairs(config.blacklist.props or {}) do
    if rule.prop == prop then
      for _, d in ipairs(rule.drawables or {}) do
        if d == drawable then
          foundRule = true
          local matched <const> = matchesRule(playerData, rule)
          if isWhitelist then
            return not matched
          else
            return matched
          end
        end
      end
    end
  end

  return isWhitelist and not foundRule
end

---@param appearance table
---@param playerData table
---@return boolean, string?
function blacklist.validateAppearance(appearance, playerData)
  if not config.blacklist or not config.blacklist.enabled then return true end

  if appearance.clothing then
    for _, c in ipairs(appearance.clothing) do
      if blacklist.isClothingBlocked(c.component, c.drawable, playerData) then
        return false, ("Clothing component %d drawable %d is restricted"):format(c.component, c.drawable)
      end
    end
  end

  if appearance.props then
    for _, p in ipairs(appearance.props) do
      if blacklist.isPropBlocked(p.prop, p.drawable, playerData) then
        return false, ("Prop %d drawable %d is restricted"):format(p.prop, p.drawable)
      end
    end
  end

  return true
end

return blacklist
