local logger <const> = require("shared.logger")

local migrate = {}

local componentMap <const> = {
  [0] = { drawable = "drawable_0", texture = "texture_0" },
  [1] = { drawable = "drawable_1", texture = "texture_1" },
  [2] = { drawable = "drawable_2", texture = "texture_2" },
  [3] = { drawable = "arms", texture = "arms_2" },
  [4] = { drawable = "pants_1", texture = "pants_2" },
  [5] = { drawable = "bags_1", texture = "bags_2" },
  [6] = { drawable = "shoes_1", texture = "shoes_2" },
  [7] = { drawable = "chain_1", texture = "chain_2" },
  [8] = { drawable = "tshirt_1", texture = "tshirt_2" },
  [9] = { drawable = "bproof_1", texture = "bproof_2" },
  [10] = { drawable = "decals_1", texture = "decals_2" },
  [11] = { drawable = "torso_1", texture = "torso_2" },
}

local propMap <const> = {
  [0] = { drawable = "hat_1", texture = "hat_2" },
  [1] = { drawable = "glasses_1", texture = "glasses_2" },
  [2] = { drawable = "ear_1", texture = "ear_2" },
  [6] = { drawable = "watch_1", texture = "watch_2" },
  [7] = { drawable = "brace_1", texture = "brace_2" },
}

local legacyFeatureMap <const> = {
  noseWidth = "nose_1",
  nosePeakHeight = "nose_2",
  nosePeakLength = "nose_3",
  noseBoneHeight = "nose_4",
  nosePeakLowering = "nose_5",
  noseBoneTwist = "nose_6",
  eyebrowHeight = "eyebrows_5",
  eyebrowDepth = "eyebrows_6",
  cheekboneHeight = "cheeks_1",
  cheekboneWidth = "cheeks_2",
  cheekWidth = "cheeks_3",
  eyeOpening = "eye_squint",
  lipThickness = "lip_thickness",
  jawBoneWidth = "jaw_1",
  jawBoneLength = "jaw_2",
  chinBoneHeight = "chin_1",
  chinBoneLength = "chin_2",
  chinBoneWidth = "chin_3",
  chinHole = "chin_4",
  neckThickness = "neck_thickness",
}

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

---@return boolean success
---@return number|string skinCount_or_error
---@return number? outfitCount
function migrate.fromIllenium()
  logger.info("Starting migration from illenium-appearance...")

  local hasSkins = MySQL.scalar.await(
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'playerskins'"
  )

  if not hasSkins or hasSkins == 0 then
    return false, "Table 'playerskins' not found. Is illenium-appearance installed?"
  end

  local columns = MySQL.query.await(
    "SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'playerskins'"
  )

  local idColumn = nil
  local columnNames = {}
  for _, col in ipairs(columns or {}) do
    local name = col.COLUMN_NAME or col.column_name
    columnNames[name] = true
    if name == "citizenid" then
      idColumn = "citizenid"
    elseif name == "identifier" and not idColumn then
      idColumn = "identifier"
    end
  end

  if not idColumn then
    return false, "Could not detect identifier column in playerskins table."
  end

  logger.info("Detected illenium column layout:", idColumn)

  local skinCol = columnNames["skin"] and "skin" or (columnNames["data"] and "data" or nil)
  if not skinCol then
    local allCols = {}
    for n in pairs(columnNames) do allCols[#allCols + 1] = n end
    return false, "No known skin data column in playerskins. Columns: " .. table.concat(allCols, ", ")
  end

  local hasModel = columnNames["model"] ~= nil
  local hasActive = columnNames["active"] ~= nil

  local selectParts = { ("`%s` AS ident"):format(idColumn), ("`%s` AS skin"):format(skinCol) }
  if hasModel then selectParts[#selectParts + 1] = "`model`" end

  local skinQuery = ("SELECT %s FROM `playerskins`%s"):format(
    table.concat(selectParts, ", "),
    hasActive and " WHERE `active` = 1" or ""
  )

  logger.debug("playerskins query:", skinQuery)
  local skinRows = MySQL.query.await(skinQuery)

  local skinCount = 0
  for _, row in ipairs(skinRows or {}) do
    if row.ident and row.skin then
      local exists = MySQL.scalar.await(
        "SELECT COUNT(*) FROM juddlie_appearance WHERE identifier = ?",
        { row.ident }
      )

      if exists == 0 then
        local ok, skinData = pcall(json.decode, row.skin)
        if ok and skinData then
          local converted = migrate.convertSkin(skinData, row.model)
          if converted then
            MySQL.insert.await(
              "INSERT INTO juddlie_appearance (identifier, skin) VALUES (?, ?)",
              { row.ident, json.encode(converted) }
            )
            skinCount = skinCount + 1
          end
        else
          logger.warn("Failed to parse skin data for:", row.ident)
        end
      end
    end
  end

  local outfitCount = 0
  local hasOutfits = MySQL.scalar.await(
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'player_outfits'"
  )

  if hasOutfits and hasOutfits > 0 then
    local outfitColumns = MySQL.query.await(
      "SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'player_outfits'"
    )

    local outfitIdCol = nil
    for _, col in ipairs(outfitColumns or {}) do
      local name = col.COLUMN_NAME or col.column_name
      if name == "citizenid" then
        outfitIdCol = "citizenid"
      elseif name == "identifier" and not outfitIdCol then
        outfitIdCol = "identifier"
      end
    end

    if outfitIdCol then
      local colSet = {}
      local allColNames = {}
      for _, col in ipairs(outfitColumns or {}) do
        local name = col.COLUMN_NAME or col.column_name
        allColNames[#allColNames + 1] = name
        colSet[name] = true
      end

      local codeMap = {}
      local hasOutfitCodes = MySQL.scalar.await(
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'player_outfit_codes'"
      )
      if hasOutfitCodes and hasOutfitCodes > 0 then
        local codeRows = MySQL.query.await("SELECT `outfitid`, `code` FROM `player_outfit_codes`")
        for _, codeRow in ipairs(codeRows or {}) do
          if codeRow.outfitid and codeRow.code and codeRow.code ~= "" then
            codeMap[codeRow.outfitid] = codeRow.code
          end
        end
        logger.info(("Loaded %d outfit share codes from player_outfit_codes"):format(#codeRows or 0))
      end

      local hasModel = colSet["model"] ~= nil
      local hasComponents = colSet["components"] ~= nil
      local hasProps = colSet["props"] ~= nil
      local nameCol = colSet["outfitname"] and "outfitname"
          or colSet["outfit_name"] and "outfit_name"
          or colSet["name"] and "name"
          or nil

      local dataCol = nil
      if not hasComponents then
        for _, name in ipairs(allColNames) do
          if name == "outfitData" or name == "outfit_data" or name == "outfit" or name == "skin" or name == "data" then
            dataCol = name
            break
          end
        end
      end

      if not nameCol then
        logger.warn("player_outfits: no name column found. Columns:", table.concat(allColNames, ", "))
        logger.warn("Skipping outfit migration.")
      elseif hasComponents and hasProps then
        logger.debug("player_outfits: detected illenium format (components + props columns)")

        local selectParts = {
          "`id`",
          ("`%s` AS ident"):format(outfitIdCol),
          ("`%s` AS oname"):format(nameCol),
          "`components`",
          "`props`",
        }
        if hasModel then selectParts[#selectParts + 1] = "`model`" end

        local selectQuery = ("SELECT %s FROM `player_outfits`"):format(table.concat(selectParts, ", "))
        local outfitRows = MySQL.query.await(selectQuery)

        for _, row in ipairs(outfitRows or {}) do
          if row.ident and row.oname then
            local components = row.components and json.decode(row.components) or {}
            local props = row.props and json.decode(row.props) or {}

            local clothing = {}
            for _, comp in ipairs(components) do
              clothing[#clothing + 1] = {
                component = comp.component_id,
                drawable = comp.drawable or 0,
                texture = comp.texture or 0,
              }
            end

            local outfitProps = {}
            for _, propData in ipairs(props) do
              outfitProps[#outfitProps + 1] = {
                prop = propData.prop_id,
                drawable = propData.drawable or -1,
                texture = propData.texture or 0,
              }
            end

            local outfitData = { clothing = clothing, props = outfitProps, tattoos = {} }
            local outfitId = ("migrated_%s_%d"):format(row.oname:gsub("%s+", "_"):lower(), os.time())
            local shareCode = row.id and codeMap[row.id] or nil

            MySQL.insert(
              "INSERT INTO juddlie_appearance_outfits (identifier, outfit_id, name, category, data, share_code, favorite, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
              {
                row.ident,
                outfitId,
                row.oname,
                "custom",
                json.encode(outfitData),
                shareCode,
                0,
                os.time() * 1000,
              }
            )
            outfitCount = outfitCount + 1
          end
        end
      elseif dataCol then
        logger.debug("player_outfits data column:", dataCol)

        local selectParts = {
          "`id`",
          ("`%s` AS ident"):format(outfitIdCol),
          ("`%s` AS oname"):format(nameCol),
          ("`%s` AS skin"):format(dataCol),
        }
        if hasModel then selectParts[#selectParts + 1] = "`model`" end

        local selectQuery = ("SELECT %s FROM `player_outfits`"):format(table.concat(selectParts, ", "))
        local outfitRows = MySQL.query.await(selectQuery)

        for _, row in ipairs(outfitRows or {}) do
          if row.ident and row.skin and row.oname then
            local ok, skinData = pcall(json.decode, row.skin)
            if ok and skinData then
              local outfitData = migrate.convertToOutfit(skinData)
              if outfitData then
                local outfitId = ("migrated_%s_%d"):format(row.oname:gsub("%s+", "_"):lower(), os.time())
                local shareCode = row.id and codeMap[row.id] or nil
                MySQL.insert(
                  "INSERT INTO juddlie_appearance_outfits (identifier, outfit_id, name, category, data, share_code, favorite, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                  {
                    row.ident,
                    outfitId,
                    row.oname,
                    "custom",
                    json.encode(outfitData),
                    shareCode,
                    0,
                    os.time() * 1000,
                  }
                )
                outfitCount = outfitCount + 1
              end
            end
          end
        end
      else
        logger.warn("player_outfits: no known data column found. Columns:", table.concat(allColNames, ", "))
        logger.warn("Skipping outfit migration.")
      end
    end
  end

  logger.info(("Migration complete: %d skins, %d outfits migrated."):format(skinCount, outfitCount))
  return true, skinCount, outfitCount
end

---@param skin table
---@param model string?
---@return table?
function migrate.convertSkin(skin, model)
  if not skin then return nil end

  if skin.headBlend or skin.headOverlays or skin.components then
    return migrate.convertModernSkin(skin, model)
  end

  return migrate.convertLegacySkin(skin, model)
end

---@param skin table
---@param model string?
---@return table?
function migrate.convertModernSkin(skin, model)
  local result = {
    model = model or skin.model or "mp_m_freemode_01",
    headBlend = {},
    faceFeatures = {},
    headOverlays = {},
    hair = {},
    eyeColor = skin.eyeColor or 0,
    clothing = {},
    props = {},
    tattoos = {},
  }

  if skin.headBlend then
    result.headBlend = {
      shapeFirst = skin.headBlend.shapeFirst or 0,
      shapeSecond = skin.headBlend.shapeSecond or 0,
      skinFirst = skin.headBlend.skinFirst or 0,
      skinSecond = skin.headBlend.skinSecond or 0,
      shapeMix = skin.headBlend.shapeMix or 0.5,
      skinMix = skin.headBlend.skinMix or 0.5,
    }
  end

  if skin.faceFeatures then
    for illeniumKey, juddlieKey in pairs(featureToJuddlie) do
      result.faceFeatures[juddlieKey] = tonumber(skin.faceFeatures[illeniumKey]) or 0.0
    end
  end

  if skin.headOverlays then
    for i, name in ipairs(illeniumHeadOverlays) do
      local overlay = skin.headOverlays[name]
      if overlay then
        local value = overlay.style or overlay.value or -1
        local opacity = overlay.opacity or 1.0
        if value == 0 and opacity == 0 then value = -1 end

        result.headOverlays[i] = {
          value = value,
          opacity = opacity,
          firstColor = overlay.color or overlay.firstColor or 0,
          secondColor = overlay.secondColor or 0,
        }
      else
        result.headOverlays[i] = { value = -1, opacity = 1.0, firstColor = 0, secondColor = 0 }
      end
    end
  end

  if skin.hair then
    result.hair = {
      style = skin.hair.style or 0,
      color = skin.hair.color or 0,
      highlight = skin.hair.highlight or 0,
    }
  end

  if skin.components then
    for _, comp in ipairs(skin.components) do
      result.clothing[#result.clothing + 1] = {
        component = comp.component_id,
        drawable = comp.drawable or 0,
        texture = comp.texture or 0,
      }
    end
  else
    for cid = 0, 11 do
      result.clothing[#result.clothing + 1] = { component = cid, drawable = 0, texture = 0 }
    end
  end

  if skin.props then
    for _, propData in ipairs(skin.props) do
      result.props[#result.props + 1] = {
        prop = propData.prop_id,
        drawable = propData.drawable or -1,
        texture = propData.texture or 0,
      }
    end
  else
    for _, pid in ipairs({ 0, 1, 2, 6, 7 }) do
      result.props[#result.props + 1] = { prop = pid, drawable = -1, texture = 0 }
    end
  end

  if skin.tattoos and type(skin.tattoos) == "table" then
    local isZoned = false
    for key in pairs(skin.tattoos) do
      if type(key) == "string" and key:find("^ZONE_") then
        isZoned = true
        break
      end
    end

    if isZoned then
      for zone, zoneTattoos in pairs(skin.tattoos) do
        for _, tattoo in ipairs(zoneTattoos) do
          result.tattoos[#result.tattoos + 1] = {
            collection = tattoo.collection,
            overlay = tattoo.hashMale or tattoo.hashFemale or tattoo.overlay,
            zone = zone,
            label = tattoo.name or tattoo.label or "",
          }
        end
      end
    else
      result.tattoos = skin.tattoos
    end
  end

  return result
end

---@param skin table
---@param model string?
---@return table?
function migrate.convertLegacySkin(skin, model)
  if not skin then return nil end

  local result = {
    model = model or skin.model or "mp_m_freemode_01",
    headBlend = {
      shapeFirst = skin.face or skin.Mom or skin.shapeFirst or 0,
      shapeSecond = skin.skin or skin.Dad or skin.shapeSecond or 0,
      skinFirst = skin.face or skin.Mom or skin.skinFirst or 0,
      skinSecond = skin.skin or skin.Dad or skin.skinSecond or 0,
      shapeMix = skin.mix or skin.ShapeMix or skin.shapeMix or 0.5,
      skinMix = skin.skinMix or skin.SkinMix or skin.skinMix or 0.5,
    },
    faceFeatures = {},
    headOverlays = {},
    hair = {
      style = skin.hair_1 or skin["hair_1"] or 0,
      color = skin.hair_color_1 or skin["hair_color_1"] or 0,
      highlight = skin.hair_color_2 or skin["hair_color_2"] or 0,
    },
    eyeColor = skin.eye_color or skin["eye_color"] or 0,
    clothing = {},
    props = {},
    tattoos = skin.tattoos or {},
  }

  for juddlieKey, legacyKey in pairs(legacyFeatureMap) do
    result.faceFeatures[juddlieKey] = tonumber(skin[legacyKey]) or 0.0
  end

  for i = 0, 12 do
    local overlayVal = skin[("overlay_%d"):format(i + 1)] or skin[("headOverlay_%d"):format(i)]
    local overlayOpacity = skin[("opacity_%d"):format(i + 1)] or skin[("headOverlayOpacity_%d"):format(i)]
    local overlayColor1 = skin[("overlayColor_%d"):format(i + 1)] or skin[("headOverlayColor1_%d"):format(i)]
    local overlayColor2 = skin[("overlayColorSecond_%d"):format(i + 1)] or skin[("headOverlayColor2_%d"):format(i)]

    if type(overlayVal) == "table" then
      result.headOverlays[#result.headOverlays + 1] = {
        value = overlayVal.value or overlayVal.index or -1,
        opacity = overlayVal.opacity or 1.0,
        firstColor = overlayVal.firstColor or overlayVal.color or 0,
        secondColor = overlayVal.secondColor or overlayVal.colorSecond or 0,
      }
    else
      result.headOverlays[#result.headOverlays + 1] = {
        value = tonumber(overlayVal) or -1,
        opacity = tonumber(overlayOpacity) or 1.0,
        firstColor = tonumber(overlayColor1) or 0,
        secondColor = tonumber(overlayColor2) or 0,
      }
    end
  end

  for cid = 0, 11 do
    local map = componentMap[cid]
    local drawable = 0
    local texture = 0

    if map then
      drawable = tonumber(skin[map.drawable]) or tonumber(skin[("drawable_%d"):format(cid)]) or 0
      texture = tonumber(skin[map.texture]) or tonumber(skin[("texture_%d"):format(cid)]) or 0
    end

    result.clothing[#result.clothing + 1] = {
      component = cid,
      drawable = drawable,
      texture = texture,
    }
  end

  for _, pid in ipairs({ 0, 1, 2, 6, 7 }) do
    local map = propMap[pid]
    local drawable = -1
    local texture = 0

    if map then
      drawable = tonumber(skin[map.drawable]) or tonumber(skin[("prop_%d"):format(pid)]) or -1
      texture = tonumber(skin[map.texture]) or tonumber(skin[("propTexture_%d"):format(pid)]) or 0
    end

    result.props[#result.props + 1] = {
      prop = pid,
      drawable = drawable,
      texture = texture,
    }
  end

  return result
end

---@param skin table
---@return table?
function migrate.convertToOutfit(skin)
  if not skin then return nil end

  local clothing = {}
  local props = {}

  if skin.components then
    for _, comp in ipairs(skin.components) do
      clothing[#clothing + 1] = {
        component = comp.component_id,
        drawable = comp.drawable or 0,
        texture = comp.texture or 0,
      }
    end
  else
    for cid = 0, 11 do
      local map = componentMap[cid]
      clothing[#clothing + 1] = {
        component = cid,
        drawable = tonumber(skin[map.drawable]) or tonumber(skin[("drawable_%d"):format(cid)]) or 0,
        texture = tonumber(skin[map.texture]) or tonumber(skin[("texture_%d"):format(cid)]) or 0,
      }
    end
  end

  if skin.props and type(skin.props) == "table" and #skin.props > 0 and skin.props[1] and skin.props[1].prop_id ~= nil then
    for _, propData in ipairs(skin.props) do
      props[#props + 1] = {
        prop = propData.prop_id,
        drawable = propData.drawable or -1,
        texture = propData.texture or 0,
      }
    end
  else
    for _, pid in ipairs({ 0, 1, 2, 6, 7 }) do
      local map = propMap[pid]
      props[#props + 1] = {
        prop = pid,
        drawable = tonumber(skin[map.drawable]) or tonumber(skin[("prop_%d"):format(pid)]) or -1,
        texture = tonumber(skin[map.texture]) or tonumber(skin[("propTexture_%d"):format(pid)]) or 0,
      }
    end
  end

  return {
    clothing = clothing,
    props = props,
    tattoos = skin.tattoos or {},
  }
end

return migrate
