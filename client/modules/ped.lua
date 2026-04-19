local config <const> = require("config")

local ped = {}
ped.currentModelName = "mp_m_freemode_01"

local faceFeatureIndex = {}
for i, name in ipairs(config.faceFeatures) do
  faceFeatureIndex[name] = i - 1
end

---@param n number
---@return number
function ped.tofloat(n)
  return n + 0.0
end

---@param p number
---@return boolean
function ped.isFreemode(p)
  local model <const> = GetEntityModel(p)

  return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

---@param p number
---@return table
function ped.getAppearance(p)
  local shapeFirst, shapeSecond, _, skinFirst, skinSecond, _, shapeMix, skinMix = Citizen.InvokeNative(
    0x2746BD9D88C5C5D0, p,
    Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
    Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
    Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0),
    Citizen.PointerValueFloatInitialized(0)
  )
  shapeMix = math.min(tonumber(tostring(shapeMix):sub(1, 4)) or 0, 1.0)
  skinMix = math.min(tonumber(tostring(skinMix):sub(1, 4)) or 0, 1.0)

  local headBlend = {
    shapeFirst = shapeFirst,
    shapeSecond = shapeSecond,
    skinFirst = skinFirst,
    skinSecond = skinSecond,
    shapeMix = shapeMix,
    skinMix = skinMix,
  }

  local faceFeatures = {}
  for name, idx in pairs(faceFeatureIndex) do
    faceFeatures[name] = tonumber(string.format("%.2f", GetPedFaceFeature(p, idx)))
  end

  local headOverlays = {}
  for i = 0, 12 do
    local _, val, _, col1, col2, opa = GetPedHeadOverlayData(p, i)
    if val == 255 then
      val = -1; opa = 1.0
    end
    
    headOverlays[#headOverlays + 1] = {
      value = val,
      opacity = tonumber(string.format("%.2f", opa)),
      firstColor = col1,
      secondColor = col2,
    }
  end

  local hair = {
    style = GetPedDrawableVariation(p, 2),
    color = GetPedHairColor(p),
    highlight = GetPedHairHighlightColor(p),
    collection = GetPedDrawableVariationCollectionName(p, 2),
    localIndex = GetPedDrawableVariationCollectionLocalIndex(p, 2),
  }

  local clothing = {}
  for _, cid in ipairs(config.componentIds) do
    clothing[#clothing + 1] = {
      component = cid,
      drawable = GetPedDrawableVariation(p, cid),
      texture = GetPedTextureVariation(p, cid),
      collection = GetPedDrawableVariationCollectionName(p, cid),
      localIndex = GetPedDrawableVariationCollectionLocalIndex(p, cid),
    }
  end

  local props = {}
  for _, pid in ipairs(config.propIds) do
    local drawable <const> = GetPedPropIndex(p, pid)
    local entry = {
      prop = pid,
      drawable = drawable,
      texture = GetPedPropTextureIndex(p, pid),
    }
    if drawable ~= -1 then
      entry.collection = GetPedPropCollectionName(p, pid)
      entry.localIndex = GetPedPropCollectionLocalIndex(p, pid)
    end
    props[#props + 1] = entry
  end

  local eyeColor = GetPedEyeColor(p)

  local modelHash = GetEntityModel(p)
  local model
  if modelHash == `mp_m_freemode_01` then
    model = "mp_m_freemode_01"
  elseif modelHash == `mp_f_freemode_01` then
    model = "mp_f_freemode_01"
  else
    model = ped.currentModelName or "mp_m_freemode_01"
  end

  return {
    model = model,
    headBlend = headBlend,
    faceFeatures = faceFeatures,
    headOverlays = headOverlays,
    hair = hair,
    eyeColor = eyeColor,
    clothing = clothing,
    props = props,
    tattoos = {},
  }
end

---@param model string
---@return boolean
function ped.applyModel(model)
  if type(model) ~= "string" then return false end

  local modelHash <const> = joaat(model)
  if GetEntityModel(cache.ped) == modelHash then return false end
  if not IsModelInCdimage(modelHash) then return false end

  RequestModel(modelHash)

  local timeout <const> = GetGameTimer() + 5000
  while not HasModelLoaded(modelHash) do
    if GetGameTimer() > timeout then return false end
    Wait(0)
  end

  SetPlayerModel(PlayerId(), modelHash)
  SetModelAsNoLongerNeeded(modelHash)
  cache.ped = PlayerPedId()

  if ped.isFreemode(cache.ped) then
    SetPedDefaultComponentVariation(cache.ped)
    SetPedHeadBlendData(cache.ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0, false)
  end

  ped.currentModelName = model
  return true
end

---@param p number
---@param data table
function ped.applyAppearance(p, data)
  if not data then return end

  if data.headBlend and ped.isFreemode(p) then
    local hb = data.headBlend
    SetPedHeadBlendData(p,
      hb.shapeFirst, hb.shapeSecond, 0,
      hb.skinFirst, hb.skinSecond, 0,
      ped.tofloat(hb.shapeMix or config.defaultShapeMix or 0.5), ped.tofloat(hb.skinMix or config.defaultSkinMix or 0.5), 0.0, false
    )
  end

  if data.faceFeatures then
    for name, val in pairs(data.faceFeatures) do
      local idx = faceFeatureIndex[name]
      if idx then
        SetPedFaceFeature(p, idx, ped.tofloat(val))
      end
    end
  end

  if data.headOverlays then
    for i, overlay in ipairs(data.headOverlays) do
      local idx = i - 1
      local val = overlay.value
      if val == -1 then val = 255 end

      SetPedHeadOverlay(p, idx, val, ped.tofloat(overlay.opacity or 1.0))

      if overlay.firstColor then
        local colorType = 1
        if idx == 4 or idx == 5 or idx == 8 then colorType = 2 end

        SetPedHeadOverlayColor(p, idx, colorType, overlay.firstColor, overlay.secondColor or 0)
      end
    end
  end

  if data.hair then
    if data.hair.collection then
      SetPedCollectionComponentVariation(p, 2, data.hair.collection, data.hair.localIndex, 0, 0)
    else
      SetPedComponentVariation(p, 2, data.hair.style, 0, 0)
    end

    SetPedHairColor(p, data.hair.color, data.hair.highlight)
  end

  if data.eyeColor then
    SetPedEyeColor(p, data.eyeColor)
  end

  if data.clothing then
    for _, c in ipairs(data.clothing) do
      if not (ped.isFreemode(p) and (c.component == 0 or c.component == 2)) then
        if c.collection then
          local maxTex <const> = GetNumberOfPedCollectionTextureVariations(p, c.component, c.collection, c.localIndex) - 1
          local tex <const> = math.min(c.texture, math.max(maxTex, 0))

          SetPedCollectionComponentVariation(p, c.component, c.collection, c.localIndex, tex, 0)
        else
          local maxTex <const> = GetNumberOfPedTextureVariations(p, c.component, c.drawable) - 1
          local tex <const> = math.min(c.texture, math.max(maxTex, 0))

          SetPedComponentVariation(p, c.component, c.drawable, tex, 0)
        end
      end
    end
  end

  if data.props then
    for _, pr in ipairs(data.props) do
      if pr.drawable == -1 then
        ClearPedProp(p, pr.prop)
      else
        if pr.collection then
          local maxTex <const> = GetNumberOfPedCollectionPropTextureVariations(p, pr.prop, pr.collection, pr.localIndex) - 1
          local tex <const> = math.min(pr.texture, math.max(maxTex, 0))

          SetPedCollectionPropIndex(p, pr.prop, pr.collection, pr.localIndex, tex, false)
        else
          local maxTex <const> = GetNumberOfPedPropTextureVariations(p, pr.prop, pr.drawable) - 1
          local tex <const> = math.min(pr.texture, math.max(maxTex, 0))

          SetPedPropIndex(p, pr.prop, pr.drawable, tex, false)
        end
      end
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
end

---@param key string
---@param value number
function ped.setFaceFeature(key, value)
  local idx <const> = faceFeatureIndex[key]
  if idx then
    SetPedFaceFeature(cache.ped, idx, ped.tofloat(value))
  end
end

---@param data table
function ped.setHeadBlend(data)
  if not ped.isFreemode(cache.ped) then return end

  local shapeFirst, shapeSecond, _, skinFirst, skinSecond, _, shapeMix, skinMix = Citizen.InvokeNative(
    0x2746BD9D88C5C5D0, cache.ped,
    Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
    Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
    Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0),
    Citizen.PointerValueFloatInitialized(0)
  )

  SetPedHeadBlendData(cache.ped,
    data.shapeFirst or shapeFirst,
    data.shapeSecond or shapeSecond,
    0,
    data.skinFirst or skinFirst,
    data.skinSecond or skinSecond,
    0,
    ped.tofloat(data.shapeMix or shapeMix or config.defaultShapeMix or 0.5),
    ped.tofloat(data.skinMix or skinMix or config.defaultSkinMix or 0.5),
    0.0, false
  )
end

---@param data table
function ped.setHair(data)
  if data.collection then
    SetPedCollectionComponentVariation(cache.ped, 2, data.collection, data.localIndex, 0, 0)
  else
    SetPedComponentVariation(cache.ped, 2, data.style, 0, 0)
  end

  SetPedHairColor(cache.ped, data.color, data.highlight)
end

---@param data table
function ped.setOverlay(data)
  local val = data.value
  if val == -1 then val = 255 end

  SetPedHeadOverlay(cache.ped, data.index, val, ped.tofloat(data.opacity or 1.0))

  if data.firstColor then
    local colorType = 1
    if data.index == 4 or data.index == 5 or data.index == 8 then colorType = 2 end

    SetPedHeadOverlayColor(cache.ped, data.index, colorType, data.firstColor, data.secondColor or 0)
  end
end

---@param color number
function ped.setEyeColor(color)
  SetPedEyeColor(cache.ped, color)
end

---@param data table
function ped.setClothing(data)
  if ped.isFreemode(cache.ped) and (data.component == 0 or data.component == 2) then return end
  if data.collection then
    local maxTex <const> = GetNumberOfPedCollectionTextureVariations(cache.ped, data.component, data.collection, data.localIndex) - 1
    local tex <const> = math.min(data.texture, math.max(maxTex, 0))

    SetPedCollectionComponentVariation(cache.ped, data.component, data.collection, data.localIndex, tex, 0)
  else
    local maxTex <const> = GetNumberOfPedTextureVariations(cache.ped, data.component, data.drawable) - 1
    local tex <const> = math.min(data.texture, math.max(maxTex, 0))

    SetPedComponentVariation(cache.ped, data.component, data.drawable, tex, 0)
  end
end

---@param data table
function ped.setProp(data)
  if data.drawable == -1 then
    ClearPedProp(cache.ped, data.prop)
  else
    if data.collection then
      local maxTex <const> = GetNumberOfPedCollectionPropTextureVariations(cache.ped, data.prop, data.collection, data.localIndex) - 1
      local tex <const> = math.min(data.texture, math.max(maxTex, 0))

      SetPedCollectionPropIndex(cache.ped, data.prop, data.collection, data.localIndex, tex, false)
    else
      local maxTex <const> = GetNumberOfPedPropTextureVariations(cache.ped, data.prop, data.drawable) - 1
      local tex <const> = math.min(data.texture, math.max(maxTex, 0))

      SetPedPropIndex(cache.ped, data.prop, data.drawable, tex, false)
    end
  end
end

---@param data table
function ped.quickEdit(data)
  if data.type == "prop" then
    if GetPedPropIndex(cache.ped, data.id) == -1 then
      SetPedPropIndex(cache.ped, data.id, 0, 0, false)
    else
      ClearPedProp(cache.ped, data.id)
    end
  else
    if GetPedDrawableVariation(cache.ped, data.id) == 0 then
      SetPedComponentVariation(cache.ped, data.id, 1, 0, 0)
    else
      SetPedComponentVariation(cache.ped, data.id, 0, 0, 0)
    end
  end
end

function ped.clearTattoos()
  ClearPedDecorations(cache.ped)
end

---@param p number
---@return table
function ped.getMaxValues(p)
  local components = {}
  for _, cid in ipairs(config.componentIds) do
    local maxDraw <const> = GetNumberOfPedDrawableVariations(p, cid) - 1
    local currentDraw <const> = GetPedDrawableVariation(p, cid)
    local maxTex <const> = GetNumberOfPedTextureVariations(p, cid, currentDraw) - 1

    components[tostring(cid)] = { maxDrawable = math.max(0, maxDraw), maxTexture = math.max(0, maxTex) }
  end

  local maxHairDraw <const> = GetNumberOfPedDrawableVariations(p, 2) - 1
  local hair = { maxStyle = math.max(0, maxHairDraw), maxColor = 63 }

  local props = {}
  for _, pid in ipairs(config.propIds) do
    local maxDraw <const> = GetNumberOfPedPropDrawableVariations(p, pid) - 1
    local currentDraw <const> = GetPedPropIndex(p, pid)
    local maxTex = 0

    if currentDraw >= 0 then
      maxTex = GetNumberOfPedPropTextureVariations(p, pid, currentDraw) - 1
    end
    
    props[tostring(pid)] = { maxDrawable = math.max(0, maxDraw), maxTexture = math.max(0, maxTex) }
  end

  local overlays = {}
  for i = 0, 12 do
    overlays[tostring(i)] = math.max(0, GetNumHeadOverlayValues(i) - 1)
  end

  return { components = components, props = props, hair = hair, overlays = overlays }
end

---@param p number
---@param componentId number
---@param drawable number
---@return number
function ped.getComponentTextureMax(p, componentId, drawable)
  return math.max(0, GetNumberOfPedTextureVariations(p, componentId, drawable) - 1)
end

---@param p number
---@param propId number
---@param drawable number
---@return number
function ped.getPropTextureMax(p, propId, drawable)
  if drawable < 0 then return 0 end

  return math.max(0, GetNumberOfPedPropTextureVariations(p, propId, drawable) - 1)
end

return ped
