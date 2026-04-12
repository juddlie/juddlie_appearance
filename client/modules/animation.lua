local config <const> = require("config")

local animation = {}

local animsByValue = {}
for _, a in ipairs(config.animations) do
  animsByValue[a.value] = a
end

---@param value string
function animation.play(value)
  ClearPedTasks(cache.ped)

  local anim <const> = animsByValue[value]
  if not (anim and anim.dict) then return end

  RequestAnimDict(anim.dict)
  local timeout = 0
  local maxTimeout <const> = config.animationLoadTimeout or 5000
  while not HasAnimDictLoaded(anim.dict) and timeout < maxTimeout do
    Wait(10)
    timeout = timeout + 10
  end

  if HasAnimDictLoaded(anim.dict) then
    TaskPlayAnim(cache.ped, anim.dict, anim.name, config.animationBlendIn or 8.0, config.animationBlendOut or -8.0, -1, 1, 0.0, false, false, false)
  end
end

return animation
