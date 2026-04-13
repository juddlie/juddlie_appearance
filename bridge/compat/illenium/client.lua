local ped <const> = require("client.modules.ped")
local menu <const> = require("client.modules.menu")
local nui <const> = require("client.modules.nui")
local logger <const> = require("shared.logger")
local config <const> = require("config")

local illeniumHeadOverlays <const> = {
  "blemishes", "beard", "eyebrows", "ageing", "makeUp",
  "blush", "complexion", "sunDamage", "lipstick",
  "moleAndFreckles", "chestHair", "bodyBlemishes", "addBodyBlemishes",
}

local featureToJuddlie <const> = {
  noseWidth = "noseWidth",
  nosePeakHigh = "nosePeakHeight",
  nosePeakSize = "nosePeakLength",
  noseBoneHigh = "noseBoneHeight",
  nosePeakLowering = "nosePeakLowering",
  noseBoneTwist = "noseBoneTwist",
  eyeBrownHigh = "eyebrowHeight",
  eyeBrownForward = "eyebrowDepth",
  cheeksBoneHigh = "cheekboneHeight",
  cheeksBoneWidth = "cheekboneWidth",
  cheeksWidth = "cheekWidth",
  eyesOpening = "eyeOpening",
  lipsThickness = "lipThickness",
  jawBoneWidth = "jawBoneWidth",
  jawBoneBackSize = "jawBoneLength",
  chinBoneLowering = "chinBoneHeight",
  chinBoneLenght = "chinBoneLength",
  chinBoneSize = "chinBoneWidth",
  chinHole = "chinHole",
  neckThickness = "neckThickness",
}

local featureFromJuddlie <const> = {}
for illeniumKey, juddlieKey in pairs(featureToJuddlie) do
  featureFromJuddlie[juddlieKey] = illeniumKey
end

local pedTattoos = {}

---@param exportName string
---@param func function
local function exportHandler(exportName, func)
  AddEventHandler(("__cfx_export_illenium-appearance_%s"):format(exportName), function(setCB)
    setCB(func)
  end)
end

---@param juddlieApp table
---@return table? appearance
local function toIlleniumAppearance(juddlieApp)
  if not juddlieApp then return nil end

  local result = { model = juddlieApp.model, eyeColor = juddlieApp.eyeColor, tattoos = {} }

  if juddlieApp.headBlend then
    result.headBlend = {
      shapeFirst = juddlieApp.headBlend.shapeFirst,
      shapeSecond = juddlieApp.headBlend.shapeSecond,
      shapeThird = 0,
      skinFirst = juddlieApp.headBlend.skinFirst,
      skinSecond = juddlieApp.headBlend.skinSecond,
      skinThird = 0,
      shapeMix = juddlieApp.headBlend.shapeMix,
      skinMix = juddlieApp.headBlend.skinMix,
      thirdMix = 0,
    }
  end

  if juddlieApp.faceFeatures then
    result.faceFeatures = {}
    for juddlieKey, value in pairs(juddlieApp.faceFeatures) do
      local illeniumKey = featureFromJuddlie[juddlieKey]
      if illeniumKey then result.faceFeatures[illeniumKey] = value end
    end
  end

  if juddlieApp.headOverlays then
    result.headOverlays = {}
    for i, overlay in ipairs(juddlieApp.headOverlays) do
      local name = illeniumHeadOverlays[i]
      if name then
        local value, opacity = overlay.value, overlay.opacity
        if value == -1 then
          value = 0; opacity = 0
        end

        result.headOverlays[name] = { style = value, opacity = opacity, color = overlay.firstColor, secondColor = overlay
        .secondColor }
      end
    end
  end

  if juddlieApp.clothing then
    result.components = {}
    for index, clothingData in ipairs(juddlieApp.clothing) do
      result.components[index] = { component_id = clothingData.component, drawable = clothingData.drawable, texture =
      clothingData.texture }
    end
  end

  if juddlieApp.props then
    result.props = {}
    for index, propData in ipairs(juddlieApp.props) do
      result.props[index] = { prop_id = propData.prop, drawable = propData.drawable, texture = propData.texture }
    end
  end

  if juddlieApp.hair then
    result.hair = { style = juddlieApp.hair.style, color = juddlieApp.hair.color, highlight = juddlieApp.hair.highlight, texture = 0 }
  end

  if juddlieApp.tattoos then
    for _, tattoo in ipairs(juddlieApp.tattoos) do
      local zone = tattoo.zone or "ZONE_TORSO"
      if not result.tattoos[zone] then result.tattoos[zone] = {} end
      result.tattoos[zone][#result.tattoos[zone] + 1] = {
        collection = tattoo.collection,
        hashMale = tattoo.overlay,
        hashFemale = tattoo.overlay,
        name = tattoo.label or "",
        zone = zone,
        opacity = 1.0,
      }
    end
  end

  return result
end

---@param illeniumApp table
---@return table appearance
local function toJuddlieAppearance(illeniumApp)
  if not illeniumApp then return {} end

  local result = { model = illeniumApp.model, eyeColor = illeniumApp.eyeColor }

  if illeniumApp.headBlend then
    result.headBlend = {
      shapeFirst = illeniumApp.headBlend.shapeFirst,
      shapeSecond = illeniumApp.headBlend.shapeSecond,
      skinFirst = illeniumApp.headBlend.skinFirst,
      skinSecond = illeniumApp.headBlend.skinSecond,
      shapeMix = illeniumApp.headBlend.shapeMix,
      skinMix = illeniumApp.headBlend.skinMix,
    }
  end

  if illeniumApp.faceFeatures then
    result.faceFeatures = {}
    for illeniumKey, value in pairs(illeniumApp.faceFeatures) do
      local juddlieKey = featureToJuddlie[illeniumKey]
      if juddlieKey then result.faceFeatures[juddlieKey] = value end
    end
  end

  if illeniumApp.headOverlays then
    result.headOverlays = {}
    for i, name in ipairs(illeniumHeadOverlays) do
      local overlay = illeniumApp.headOverlays[name]
      if overlay then
        result.headOverlays[i] = {
          value = (overlay.style == 0 and overlay.opacity == 0) and -1 or overlay.style,
          opacity = overlay.opacity,
          firstColor = overlay.color,
          secondColor = overlay.secondColor,
        }
      else
        result.headOverlays[i] = { value = -1, opacity = 1.0, firstColor = 0, secondColor = 0 }
      end
    end
  end

  if illeniumApp.components then
    result.clothing = {}
    for index, componentData in ipairs(illeniumApp.components) do
      result.clothing[index] = { component = componentData.component_id, drawable = componentData.drawable, texture =
      componentData.texture }
    end
  end

  if illeniumApp.props then
    result.props = {}
    for index, propData in ipairs(illeniumApp.props) do
      result.props[index] = { prop = propData.prop_id, drawable = propData.drawable, texture = propData.texture }
    end
  end

  if illeniumApp.hair then
    result.hair = { style = illeniumApp.hair.style, color = illeniumApp.hair.color, highlight = illeniumApp.hair
    .highlight }
  end

  if illeniumApp.tattoos then
    result.tattoos = {}
    local isMale = GetEntityModel(cache.ped) == `mp_m_freemode_01`
    for zone, zoneTattoos in pairs(illeniumApp.tattoos) do
      for _, tattoo in ipairs(zoneTattoos) do
        result.tattoos[#result.tattoos + 1] = {
          collection = tattoo.collection,
          overlay = isMale and tattoo.hashMale or tattoo.hashFemale,
          zone = zone,
          label = tattoo.name or "",
        }
      end
    end
  end

  return result
end

---@param pedHandle number 
---@param tattoos table? 
local function setPedTattoos(pedHandle, tattoos)
  pedTattoos = tattoos or {}

  local isMale = GetEntityModel(pedHandle) == `mp_m_freemode_01`
  ClearPedDecorations(pedHandle)

  for _, zoneTattoos in pairs(pedTattoos) do
    for _, tattoo in ipairs(zoneTattoos) do
      local hash = isMale and tattoo.hashMale or tattoo.hashFemale
      if hash then
        for _ = 1, (tattoo.opacity or 0.1) * 10 do
          AddPedDecorationFromHashes(pedHandle, joaat(tattoo.collection), joaat(hash))
        end
      end
    end
  end
end

---@param model string|number
---@return number pedHandle 
local function setPlayerModel(model)
  if type(model) == "string" then model = joaat(model) end
  if not IsModelInCdimage(model) then return PlayerId() end

  RequestModel(model)
  local timeout <const> = GetGameTimer() + (config.modelLoadTimeout or 5000)
  while not HasModelLoaded(model) do
    if GetGameTimer() > timeout then return PlayerId() end
    Wait(0)
  end

  SetPlayerModel(PlayerId(), model)
  Wait(150)
  SetModelAsNoLongerNeeded(model)
  cache.ped = PlayerPedId()

  if ped.isFreemode(cache.ped) then
    SetPedDefaultComponentVariation(cache.ped)
    if model == `mp_m_freemode_01` then
      SetPedHeadBlendData(cache.ped, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)
    elseif model == `mp_f_freemode_01` then
      SetPedHeadBlendData(cache.ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0, false)
    end
  end

  pedTattoos = {}
  return cache.ped
end


RegisterNetEvent("illenium-appearance:client:openClothingShop", function(isPedMenu)
  logger.debug("illenium compat: openClothingShop, isPedMenu:", isPedMenu)
  if isPedMenu then
    menu.allowedTabs = nil
    menu.open()
  else
    menu.allowedTabs = { "clothing", "props", "outfits" }
    menu.open()
    nui.sendMessage("setAllowedTabs", { tabs = { "clothing", "props", "outfits" } })
  end
end)

RegisterNetEvent("illenium-appearance:client:openClothingShopMenu", function(isPedMenu)
  logger.debug("illenium compat: openClothingShopMenu, isPedMenu:", isPedMenu)
  if isPedMenu then
    menu.allowedTabs = nil
    menu.open()
  else
    menu.allowedTabs = { "clothing", "props", "outfits" }
    menu.open()
    nui.sendMessage("setAllowedTabs", { tabs = { "clothing", "props", "outfits" } })
  end
end)

RegisterNetEvent("illenium-appearance:client:OpenBarberShop", function()
  logger.debug("illenium compat: OpenBarberShop")
  menu.allowedTabs = { "hair", "face", "colors" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "hair", "face", "colors" } })
end)

RegisterNetEvent("illenium-appearance:client:OpenTattooShop", function()
  logger.debug("illenium compat: OpenTattooShop")
  menu.allowedTabs = { "tattoos" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "tattoos" } })
end)

RegisterNetEvent("illenium-appearance:client:OpenSurgeonShop", function()
  logger.debug("illenium compat: OpenSurgeonShop")
  menu.allowedTabs = { "face", "headblend" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "face", "headblend" } })
end)

RegisterNetEvent("illenium-appearance:client:reloadSkin", function()
  logger.debug("illenium compat: reloadSkin")
  local appearance <const> = lib.callback.await("juddlie_appearance:server:getAppearance", false)
  if appearance then
    ped.applyAppearance(cache.ped, appearance)
  end
end)

RegisterNetEvent("illenium-appearance:client:ClearStuckProps", function()
  logger.debug("illenium compat: ClearStuckProps")
  ClearAllPedProps(cache.ped)
end)

RegisterNetEvent("illenium-appearance:client:changeOutfit", function(outfitData)
  if type(outfitData) ~= "table" then return end
  logger.debug("illenium compat: changeOutfit")

  if outfitData.model then setPlayerModel(outfitData.model) end

  local converted <const> = toJuddlieAppearance(outfitData)
  if converted then ped.applyAppearance(cache.ped, converted) end
end)

RegisterNetEvent("illenium-appearance:client:loadJobOutfit", function(outfitData)
  if type(outfitData) ~= "table" then return end
  logger.debug("illenium compat: loadJobOutfit")

  local converted <const> = toJuddlieAppearance(outfitData)
  if converted then
    ped.applyAppearance(cache.ped, { clothing = converted.clothing, props = converted.props })
  end
end)

RegisterNetEvent("illenium-appearance:client:OpenClothingRoom", function()
  logger.debug("illenium compat: OpenClothingRoom")
  menu.allowedTabs = { "clothing", "props", "outfits" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "clothing", "props", "outfits" } })
end)

RegisterNetEvent("illenium-appearance:client:OpenPlayerOutfitRoom", function()
  logger.debug("illenium compat: OpenPlayerOutfitRoom")
  menu.allowedTabs = { "outfits" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "outfits" } })
end)

RegisterNetEvent("illenium-appearance:client:saveOutfit", function()
  logger.debug("illenium compat: saveOutfit")
  local appearance <const> = ped.getAppearance(cache.ped)
  if not appearance then return end

  local illeniumApp <const> = toIlleniumAppearance(appearance)
  if not illeniumApp then return end

  TriggerServerEvent("illenium-appearance:server:saveOutfit",
    "Outfit " .. os.date("%H:%M"),
    illeniumApp.model,
    illeniumApp.components,
    illeniumApp.props
  )
end)

RegisterNetEvent("illenium-appearance:client:generateOutfitCode", function(outfitID)
  logger.debug("illenium compat: generateOutfitCode — not fully supported")
end)

RegisterNetEvent("illenium-appearance:client:importOutfitCode", function()
  logger.debug("illenium compat: importOutfitCode — not fully supported")
end)

RegisterNetEvent("illenium-appearance:client:updateOutfit", function(outfitID)
  logger.debug("illenium compat: updateOutfit")
  local appearance <const> = ped.getAppearance(cache.ped)
  if not appearance then return end

  local illeniumApp <const> = toIlleniumAppearance(appearance)
  if not illeniumApp then return end

  TriggerServerEvent("illenium-appearance:server:updateOutfit",
    outfitID,
    illeniumApp.model,
    illeniumApp.components,
    illeniumApp.props
  )
end)

RegisterNetEvent("illenium-appearance:client:deleteOutfit", function(outfitID)
  logger.debug("illenium compat: deleteOutfit")
  TriggerServerEvent("illenium-appearance:server:deleteOutfit", outfitID)
end)

RegisterNetEvent("illenium-appearance:client:OutfitManagementMenu", function(data)
  logger.debug("illenium compat: OutfitManagementMenu — not supported, opening outfits tab instead")
  menu.allowedTabs = { "outfits" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "outfits" } })
end)

RegisterNetEvent("illenium-appearance:client:SaveManagementOutfit", function(mType)
  logger.debug("illenium compat: SaveManagementOutfit — not supported")
end)

RegisterNetEvent("illenium-appearance:client:DeleteManagementOutfit", function(outfitID)
  logger.debug("illenium compat: DeleteManagementOutfit — not supported")
end)

RegisterNetEvent("illenium-appearance:client:openOutfitMenu", function()
  logger.debug("illenium compat: openOutfitMenu")
  menu.allowedTabs = { "outfits" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "outfits" } })
end)

RegisterNetEvent("illenium-apearance:client:outfitsCommand", function(isJob)
  logger.debug("illenium compat: outfitsCommand", isJob and "job" or "gang")
  menu.allowedTabs = { "outfits" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "outfits" } })
end)

RegisterNetEvent("illenium-appearance:client:openJobOutfitsMenu", function(outfitsToShow)
  logger.debug("illenium compat: openJobOutfitsMenu")
  menu.allowedTabs = { "outfits" }
  menu.open()
  nui.sendMessage("setAllowedTabs", { tabs = { "outfits" } })
end)

logger.info("Registering illenium-appearance compatibility exports")

exportHandler("getPedAppearance", function(pedHandle)
  local appearance <const> = toIlleniumAppearance(ped.getAppearance(pedHandle))
  appearance.tattoos = pedTattoos

  return appearance
end)

exportHandler("getPedModel", function(pedHandle)
  return ped.getAppearance(pedHandle).model
end)

exportHandler("getPedComponents", function(pedHandle)
  return toIlleniumAppearance(ped.getAppearance(pedHandle)).components
end)

exportHandler("getPedProps", function(pedHandle)
  return toIlleniumAppearance(ped.getAppearance(pedHandle)).props
end)

exportHandler("getPedHeadBlend", function(pedHandle)
  return toIlleniumAppearance(ped.getAppearance(pedHandle)).headBlend
end)

exportHandler("getPedFaceFeatures", function(pedHandle)
  return toIlleniumAppearance(ped.getAppearance(pedHandle)).faceFeatures
end)

exportHandler("getPedHeadOverlays", function(pedHandle)
  return toIlleniumAppearance(ped.getAppearance(pedHandle)).headOverlays
end)

exportHandler("getPedHair", function(pedHandle)
  return toIlleniumAppearance(ped.getAppearance(pedHandle)).hair
end)

exportHandler("setPlayerModel", setPlayerModel)

exportHandler("setPedHeadBlend", function(pedHandle, headBlend)
  if not headBlend then return end
  ped.applyAppearance(pedHandle, {
    headBlend = {
      shapeFirst = headBlend.shapeFirst,
      shapeSecond = headBlend.shapeSecond,
      skinFirst = headBlend.skinFirst,
      skinSecond = headBlend.skinSecond,
      shapeMix = headBlend.shapeMix,
      skinMix = headBlend.skinMix,
    }
  })
end)

exportHandler("setPedFaceFeatures", function(pedHandle, faceFeatures)
  if not faceFeatures then return end

  local converted = {}
  for illeniumKey, value in pairs(faceFeatures) do
    local juddlieKey = featureToJuddlie[illeniumKey]
    if juddlieKey then converted[juddlieKey] = value end
  end

  ped.applyAppearance(pedHandle, { faceFeatures = converted })
end)

exportHandler("setPedHeadOverlays", function(pedHandle, headOverlays)
  if not headOverlays then return end

  local converted = {}
  for i, name in ipairs(illeniumHeadOverlays) do
    local overlayData = headOverlays[name]
    if overlayData then
      converted[i] = { value = overlayData.style, opacity = overlayData.opacity, firstColor = overlayData.color, secondColor =
      overlayData.secondColor }
    end
  end

  ped.applyAppearance(pedHandle, { headOverlays = converted })
end)

exportHandler("setPedHair", function(pedHandle, hair, tattoos)
  if not hair then return end

  ped.applyAppearance(pedHandle, {
    hair = { style = hair.style, color = hair.color, highlight = hair.highlight }
  })

  if ped.isFreemode(pedHandle) and tattoos then
    setPedTattoos(pedHandle, tattoos)
  end
end)

exportHandler("setPedEyeColor", function(pedHandle, eyeColor)
  if not eyeColor then return end

  ped.applyAppearance(pedHandle, { eyeColor = eyeColor })
end)

exportHandler("setPedComponent", function(pedHandle, component)
  if not component then return end

  ped.applyAppearance(pedHandle, {
    clothing = { { component = component.component_id, drawable = component.drawable, texture = component.texture } }
  })
end)

exportHandler("setPedComponents", function(pedHandle, components)
  if not components then return end

  local clothing = {}
  for index, componentData in ipairs(components) do
    clothing[index] = { component = componentData.component_id, drawable = componentData.drawable, texture =
    componentData.texture }
  end

  ped.applyAppearance(pedHandle, { clothing = clothing })
end)

exportHandler("setPedProp", function(pedHandle, prop)
  if not prop then return end

  ped.applyAppearance(pedHandle, {
    props = { { prop = prop.prop_id, drawable = prop.drawable, texture = prop.texture } }
  })
end)

exportHandler("setPedProps", function(pedHandle, props)
  if not props then return end

  local converted = {}
  for index, propData in ipairs(props) do
    converted[index] = { prop = propData.prop_id, drawable = propData.drawable, texture = propData.texture }
  end

  ped.applyAppearance(pedHandle, { props = converted })
end)

exportHandler("setPlayerAppearance", function(appearance)
  if not appearance then return end

  setPlayerModel(appearance.model)
  ped.applyAppearance(cache.ped, toJuddlieAppearance(appearance))
end)

exportHandler("setPedAppearance", function(pedHandle, appearance)
  if not appearance then return end

  ped.applyAppearance(pedHandle, toJuddlieAppearance(appearance))
end)

exportHandler("setPedTattoos", setPedTattoos)

exportHandler("startPlayerCustomization", function(cb, conf)
  repeat Wait(0) until IsScreenFadedIn() and not IsPlayerSwitchInProgress()

  menu.open()

  if cb then
    CreateThread(function()
      while menu.active do Wait(100) end
      cb(toIlleniumAppearance(ped.getAppearance(cache.ped)))
    end)
  end
end)

if config.framework == "qbx" then
  logger.info("Registering qb-clothing/qb-multicharacter compatibility events")

  RegisterNetEvent("qb-clothes:client:CreateFirstCharacter", function()
    logger.debug("illenium compat: qb-clothes:client:CreateFirstCharacter")

    repeat Wait(0) until IsScreenFadedIn() and not IsPlayerSwitchInProgress()

    menu.allowedTabs = nil
    menu.open()
  end)

  RegisterNetEvent("qb-clothing:client:openMenu", function()
    logger.debug("illenium compat: qb-clothing:client:openMenu")
    menu.allowedTabs = nil
    menu.open()
  end)

  RegisterNetEvent("qb-clothing:client:openOutfitMenu", function()
    logger.debug("illenium compat: qb-clothing:client:openOutfitMenu")
    menu.allowedTabs = { "outfits" }
    menu.open()
    nui.sendMessage("setAllowedTabs", { tabs = { "outfits" } })
  end)

  RegisterNetEvent("qb-clothing:client:loadOutfit", function(outfitData)
    if type(outfitData) ~= "table" then return end
    logger.debug("illenium compat: qb-clothing:client:loadOutfit")

    local converted <const> = toJuddlieAppearance(outfitData)
    if converted then
      ped.applyAppearance(cache.ped, { clothing = converted.clothing, props = converted.props })
    end
  end)

  RegisterNetEvent("qb-multicharacter:client:chooseChar", function()
    logger.debug("illenium compat: qb-multicharacter:client:chooseChar — clearing decorations")
    ClearPedDecorations(cache.ped)
    pedTattoos = {}
  end)
end
