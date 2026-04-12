local config <const> = require("config")

local ped <const> = require("client.modules.ped")
local nui <const> = require("client.modules.nui")

local randomizer = {}

randomizer.autoTimer = nil

---@param categories table
function randomizer.randomize(categories)
  for _, cat in ipairs(categories) do
    if cat == "face" and ped.isFreemode(cache.ped) then
      SetPedHeadBlendData(cache.ped,
        math.random(0, 45), math.random(0, 45), 0,
        math.random(0, 45), math.random(0, 45), 0,
        math.random() * 1.0, math.random() * 1.0, 0.0, false
      )
      
      for i = 0, 19 do
        SetPedFaceFeature(cache.ped, i, ped.tofloat(math.random() * 2.0 - 1.0))
      end
    elseif cat == "hair" then
      local maxHair <const> = GetNumberOfPedDrawableVariations(cache.ped, 2) - 1
      local style <const> = math.random(0, maxHair)

      SetPedComponentVariation(cache.ped, 2, style, 0, 0)
      SetPedHairColor(cache.ped, math.random(0, 63), math.random(0, 63))
    elseif cat == "clothing" then
      for _, cid in ipairs(config.componentIds) do
        if cid ~= 0 and cid ~= 2 then
          local maxDraw <const> = GetNumberOfPedDrawableVariations(cache.ped, cid) - 1
          if maxDraw >= 0 then
            local draw <const> = math.random(0, maxDraw)
            local maxTex <const> = GetNumberOfPedTextureVariations(cache.ped, cid, draw) - 1
            SetPedComponentVariation(cache.ped, cid, draw, math.random(0, math.max(0, maxTex)), 0)
          end
        end
      end
    elseif cat == "props" then
      for _, pid in ipairs(config.propIds) do
        local maxDraw <const> = GetNumberOfPedPropDrawableVariations(cache.ped, pid) - 1
        if maxDraw >= 0 then
          local draw <const> = math.random(-1, maxDraw)
          if draw == -1 then
            ClearPedProp(cache.ped, pid)
          else
            local maxTex <const> = GetNumberOfPedPropTextureVariations(cache.ped, pid, draw) - 1
            SetPedPropIndex(cache.ped, pid, draw, math.random(0, math.max(0, maxTex)), false)
          end
        end
      end
    elseif cat == "tattoos" then
      ClearPedDecorations(cache.ped)
    end
  end

  nui.sendMessage("setAppearance", ped.getAppearance(cache.ped))
end

---@param data table
function randomizer.startAuto(data)
  local timerToken = {}
  randomizer.autoTimer = timerToken

  CreateThread(function()
    while randomizer.autoTimer == timerToken do
      local unlocked = {}
      for cat, locked in pairs(data.locks or {}) do
        if not locked then unlocked[#unlocked + 1] = cat end
      end
      
      if #unlocked > 0 then
        randomizer.randomize(unlocked)
      end

      Wait(math.floor((data.speed or 2) * 1000))
    end
  end)
end

function randomizer.stopAuto()
  randomizer.autoTimer = nil
end

return randomizer
