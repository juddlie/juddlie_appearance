local logger <const> = require("shared.logger")

local migrate = {}

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
      local dataCol = nil
      local allColNames = {}
      for _, col in ipairs(outfitColumns or {}) do
        local name = col.COLUMN_NAME or col.column_name
        allColNames[#allColNames + 1] = name
        if not dataCol and (name == "outfitData" or name == "outfit_data" or name == "outfit" or name == "skin" or name == "data") then
          dataCol = name
        end
      end

      if not dataCol then
        logger.warn("player_outfits: no known data column found. Columns:", table.concat(allColNames, ", "))
        logger.warn("Skipping outfit migration.")
      else
        logger.debug("player_outfits data column:", dataCol)

        local colSet = {}
        for _, n in ipairs(allColNames) do colSet[n] = true end

        local hasModel = colSet["model"] ~= nil
        local nameCol = colSet["outfitname"] and "outfitname"
            or colSet["outfit_name"] and "outfit_name"
            or colSet["name"] and "name"
            or nil

        if not nameCol then
          logger.warn("player_outfits: no name column found. Columns:", table.concat(allColNames, ", "))
          logger.warn("Skipping outfit migration.")
        else
          local selectParts = {
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
                  MySQL.insert(
                    "INSERT INTO juddlie_appearance_outfits (identifier, outfit_id, name, category, data, favorite, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    {
                      row.ident,
                      outfitId,
                      row.oname,
                      "custom",
                      json.encode(outfitData),
                      0,
                      os.time() * 1000,
                    }
                  )
                  outfitCount = outfitCount + 1
                end
              end
            end
          end
        end
      end
    end
  end

  logger.info(("Migration complete: %d skins, %d outfits migrated."):format(skinCount, outfitCount))
  return true, skinCount, outfitCount
end

---@param skin table
---@param model string?
---@return table? converted
function migrate.convertSkin(skin, model)
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

  local featureMap = {
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

  for juddlieKey, illeniumKey in pairs(featureMap) do
    result.faceFeatures[juddlieKey] = tonumber(skin[illeniumKey]) or 0.0
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

  local componentMap = {
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

  local propMap = {
    [0] = { drawable = "hat_1", texture = "hat_2" },
    [1] = { drawable = "glasses_1", texture = "glasses_2" },
    [2] = { drawable = "ear_1", texture = "ear_2" },
    [6] = { drawable = "watch_1", texture = "watch_2" },
    [7] = { drawable = "brace_1", texture = "brace_2" },
  }

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
---@return table? outfit
function migrate.convertToOutfit(skin)
  if not skin then return nil end

  local clothing = {}
  local props = {}

  local componentMap = {
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

  for cid = 0, 11 do
    local map = componentMap[cid]
    clothing[#clothing + 1] = {
      component = cid,
      drawable = tonumber(skin[map.drawable]) or tonumber(skin[("drawable_%d"):format(cid)]) or 0,
      texture = tonumber(skin[map.texture]) or tonumber(skin[("texture_%d"):format(cid)]) or 0,
    }
  end

  local propMap = {
    [0] = { drawable = "hat_1", texture = "hat_2" },
    [1] = { drawable = "glasses_1", texture = "glasses_2" },
    [2] = { drawable = "ear_1", texture = "ear_2" },
    [6] = { drawable = "watch_1", texture = "watch_2" },
    [7] = { drawable = "brace_1", texture = "brace_2" },
  }

  for _, pid in ipairs({ 0, 1, 2, 6, 7 }) do
    local map = propMap[pid]
    props[#props + 1] = {
      prop = pid,
      drawable = tonumber(skin[map.drawable]) or tonumber(skin[("prop_%d"):format(pid)]) or -1,
      texture = tonumber(skin[map.texture]) or tonumber(skin[("propTexture_%d"):format(pid)]) or 0,
    }
  end

  return {
    clothing = clothing,
    props = props,
    tattoos = skin.tattoos or {},
  }
end

return migrate
