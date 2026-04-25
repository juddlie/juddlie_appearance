local config <const> = require("config")
local logger <const> = require("shared.logger")
local locale <const> = require("shared.locale")
local ped <const> = require("client.modules.ped")

local uniforms = {}

local cached = {}
local cachedCanManage = false
local cachedFaction = nil

---@return string
local function newId()
  return ("uni_%d_%d"):format(GetGameTimer(), math.random(1000, 9999))
end

local function refresh()
  local list, canManage, faction = lib.callback.await(
    "juddlie_appearance:server:getFactionUniforms", false
  )

  cached = list or {}
  cachedCanManage = canManage == true
  cachedFaction = faction

  logger.debug(("Uniforms refreshed: %d items (faction=%s, manage=%s)"):format(
    #cached, tostring(cachedFaction), tostring(cachedCanManage)
  ))
end

---@param existing? table
local function promptSave(existing)
  local input <const> = lib.inputDialog(locale.t("ui.uniforms.save_title"), {
    {
      type = "input",
      label = locale.t("ui.uniforms.name"),
      required = true,
      max = 100,
      default = existing and existing.name or "",
    },
    {
      type = "number",
      label = locale.t("ui.uniforms.min_grade"),
      min = 0,
      max = 20,
      default = existing and existing.minGrade or 0,
    },
  })

  if not input then return end

  local appearance <const> = ped.getAppearance(cache.ped)
  local payload = {
    clothing = appearance.clothing,
  }

  if config.factionUniforms.includeAccessories ~= false then
    payload.props = appearance.props
  end

  local uniform = {
    id = existing and existing.id or newId(),
    name = input[1],
    minGrade = tonumber(input[2]) or 0,
    data = payload,
  }

  TriggerServerEvent("juddlie_appearance:server:saveFactionUniform", uniform)
  logger.debug("Uniform save requested:", uniform.name)

  SetTimeout(400, function()
    refresh()
  end)
end

---@param uniform table
local function confirmDelete(uniform)
  local ok <const> = lib.alertDialog({
    header = locale.t("ui.uniforms.delete_title"),
    content = locale.t("ui.uniforms.delete_confirm", uniform.name),
    centered = true,
    cancel = true,
  })

  if ok ~= "confirm" then return end

  TriggerServerEvent("juddlie_appearance:server:deleteFactionUniform", uniform.id)
  SetTimeout(400, function()
    refresh()
    uniforms.open()
  end)
end

---@param uniform table
local function buildManageMenu(uniform)
  lib.registerContext({
    id = "juddlie_uniform_manage_" .. uniform.id,
    title = uniform.name,
    menu = "juddlie_uniforms",
    options = {
      {
        title = locale.t("ui.uniforms.equip"),
        icon = "shirt",
        onSelect = function() uniforms.apply(uniform) end,
      },
      {
        title = locale.t("ui.uniforms.overwrite"),
        description = locale.t("ui.uniforms.overwrite_desc"),
        icon = "rotate",
        onSelect = function() promptSave(uniform) end,
      },
      {
        title = locale.t("ui.uniforms.delete"),
        icon = "trash",
        iconColor = "red",
        onSelect = function() confirmDelete(uniform) end,
      },
    },
  })
end

---@param uniform table
function uniforms.apply(uniform)
  if not uniform or not uniform.data then return end

  local data <const> = uniform.data
  local p <const> = cache.ped

  if data.clothing then
    for _, c in ipairs(data.clothing) do
      ped.setClothing(c)
    end
  end

  if data.props then
    for _, pr in ipairs(data.props) do
      ped.setProp(pr)
    end
  end

  logger.debug("Uniform applied:", uniform.name)
  lib.notify({
    title = locale.t("ui.uniforms.title"),
    description = locale.t("notify.uniform_applied", uniform.name),
    type = "success",
  })

  local fullAppearance <const> = ped.getAppearance(p)
  TriggerServerEvent("juddlie_appearance:server:saveAppearance", fullAppearance)
end

function uniforms.open()
  if not config.factionUniforms.enabled then return end

  refresh()

  local options = {}

  if cachedCanManage then
    options[#options + 1] = {
      title = locale.t("ui.uniforms.save_current"),
      description = locale.t("ui.uniforms.save_current_desc"),
      icon = "plus",
      iconColor = "green",
      onSelect = function() promptSave() end,
    }
  end

  if not cachedFaction then
    options[#options + 1] = {
      title = locale.t("ui.uniforms.no_faction"),
      description = locale.t("ui.uniforms.no_faction_desc"),
      icon = "ban",
      disabled = true,
    }
  elseif #cached == 0 then
    options[#options + 1] = {
      title = locale.t("ui.uniforms.empty"),
      description = locale.t("ui.uniforms.empty_desc"),
      icon = "shirt",
      disabled = true,
    }
  end

  for _, uniform in ipairs(cached) do
    local entry = {
      title = uniform.name,
      description = locale.t("ui.uniforms.min_grade_label", uniform.minGrade or 0),
      icon = "user-tie",
      iconColor = "blue",
      onSelect = function() uniforms.apply(uniform) end,
    }

    if cachedCanManage then
      entry.menu = "juddlie_uniform_manage_" .. uniform.id
    end

    options[#options + 1] = entry
  end

  if cachedCanManage then
    for _, uniform in ipairs(cached) do
      buildManageMenu(uniform)
    end
  end

  lib.registerContext({
    id = "juddlie_uniforms",
    title = cachedFaction
      and locale.t("ui.uniforms.title_with_faction", cachedFaction)
      or locale.t("ui.uniforms.title"),
    options = options,
  })

  lib.showContext("juddlie_uniforms")
end

function uniforms.init()
  if not config.factionUniforms.enabled then return end

  RegisterCommand(config.factionUniforms.command or "uniforms", function()
    uniforms.open()
  end, false)

  if config.factionUniforms.saveCurrentAsCommand then
    RegisterCommand(config.factionUniforms.saveCurrentAsCommand, function()
      refresh()

      if not cachedCanManage then
        lib.notify({
          title = locale.t("ui.uniforms.title"),
          description = locale.t("notify.uniform_not_boss"),
          type = "error",
        })
        return
      end

      promptSave()
    end, false)
  end

  logger.info("Faction uniforms initialized — command:", config.factionUniforms.command or "uniforms")
end

return uniforms
