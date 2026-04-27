local config <const> = require("config")
local logger <const> = require("shared.logger")
local locale <const> = require("shared.locale")
local ped <const> = require("client.modules.ped")

local outfitwheel = {}

local cachedOutfits = {}

function outfitwheel.refreshOutfits()
  local outfits <const> = lib.callback.await("juddlie_appearance:server:getOutfits", false)
  
  cachedOutfits = outfits or {}

  logger.debug("Outfit wheel refreshed:", #cachedOutfits, "outfits")
end

function outfitwheel.open()
  if not config.outfitWheel or not config.outfitWheel.enabled then return end

  outfitwheel.refreshOutfits()

  if #cachedOutfits == 0 then
    lib.notify({ title = locale.t("ui.outfits.title"), description = locale.t("ui.outfit_wheel.no_outfits"), type = "info" })
    return
  end

  local options = {}

  local favorites = {}
  local regular = {}

  for _, outfit in ipairs(cachedOutfits) do
    if outfit.favorite then
      favorites[#favorites + 1] = outfit
    else
      regular[#regular + 1] = outfit
    end
  end

  if #favorites > 0 then
    for _, outfit in ipairs(favorites) do
      options[#options + 1] = {
        title = ("⭐ %s"):format(outfit.name),
        description = outfit.category and outfit.category:sub(1, 1):upper() .. outfit.category:sub(2) or "Custom",
        icon = config.outfitWheel.favoriteIcon or "star",
        onSelect = function()
          outfitwheel.applyOutfit(outfit)
        end,
      }
    end
  end

  for _, outfit in ipairs(regular) do
    local categoryColors <const> = config.outfitWheel.categoryColors or {
      casual = "blue",
      work = "orange",
      formal = "purple",
      custom = "gray",
    }

    options[#options + 1] = {
      title = outfit.name,
      description = outfit.category and outfit.category:sub(1, 1):upper() .. outfit.category:sub(2) or "Custom",
      icon = config.outfitWheel.defaultIcon or "shirt",
      iconColor = categoryColors[outfit.category] or "gray",
      onSelect = function()
        outfitwheel.applyOutfit(outfit)
      end,
    }
  end

  lib.registerContext({
    id = "juddlie_outfit_wheel",
    title = locale.t("ui.outfit_wheel.title"),
    options = options,
  })

  lib.showContext("juddlie_outfit_wheel")
end

---@param outfit table
function outfitwheel.applyOutfit(outfit)
  if not outfit or not outfit.data then return end

  local data <const> = outfit.data
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

  if data.tattoos then
    ClearPedDecorations(p)
    for _, t in ipairs(data.tattoos) do
      if t.collection and t.overlay then
        AddPedDecorationFromHashes(p, joaat(t.collection), joaat(t.overlay))
      end
    end
  end

  logger.debug("Outfit applied via wheel:", outfit.name)
  lib.notify({ title = locale.t("ui.outfits.title"), description = locale.t("ui.outfit_wheel.applied", outfit.name), type = "success" })

  local fullAppearance <const> = ped.getAppearance(p)
  TriggerServerEvent("juddlie_appearance:server:saveAppearance", fullAppearance)
end

---@param jobName string
function outfitwheel.saveJobOutfit(jobName)
  if not jobName or jobName == "" then return end

  local appearance <const> = ped.getAppearance(cache.ped)
  local outfitData = {
    clothing = appearance.clothing,
    props = appearance.props,
    tattoos = appearance.tattoos,
  }

  TriggerServerEvent("juddlie_appearance:server:saveJobOutfit", jobName, outfitData)
  logger.debug("Job outfit saved for:", jobName)
end

---@param jobName string
function outfitwheel.loadJobOutfit(jobName)
  if not jobName or jobName == "" then return end

  local outfitData <const> = lib.callback.await("juddlie_appearance:server:getJobOutfit", false, jobName)
  if not outfitData then
    logger.debug("No job outfit found for:", jobName)
    return
  end

  if outfitData.clothing then
    for _, c in ipairs(outfitData.clothing) do
      ped.setClothing(c)
    end
  end

  if outfitData.props then
    for _, pr in ipairs(outfitData.props) do
      ped.setProp(pr)
    end
  end

  if outfitData.tattoos then
    ClearPedDecorations(cache.ped)
    for _, t in ipairs(outfitData.tattoos) do
      if t.collection and t.overlay then
        AddPedDecorationFromHashes(cache.ped, joaat(t.collection), joaat(t.overlay))
      end
    end
  end

  logger.debug("Job outfit loaded for:", jobName)
  lib.notify({ title = locale.t("ui.outfits.title"), description = locale.t("notify.job_outfit_loaded"), type = "success" })
end

function outfitwheel.init()
  if not config.outfitWheel or not config.outfitWheel.enabled then return end

  RegisterKeyMapping(
    config.outfitWheel.command or "+outfitwheel",
    "Open Outfit Wheel",
    "keyboard",
    config.outfitWheel.key or "F7"
  )

  RegisterCommand(config.outfitWheel.command or "+outfitwheel", function()
    outfitwheel.open()
  end, false)

  logger.info("Outfit wheel initialized with key:", config.outfitWheel.key or "F7")
end

return outfitwheel
