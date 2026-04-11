local config <const> = require("config")

local camera = {}

camera.handle = nil
camera.preset = "fullBody"
camera.rotation = 0.0
camera.fov = config.defaultFov

function camera.destroy()
  if not camera.handle then return end

  RenderScriptCams(false, true, 500, true, false)
  DestroyCam(camera.handle, false)

  camera.handle = nil
end

function camera.create()
  camera.destroy()

  local pedCoords <const> = GetEntityCoords(cache.ped)
  local pedHeading <const> = GetEntityHeading(cache.ped)
  local headingRad <const> = math.rad(pedHeading + camera.rotation)

  local presetData <const> = config.cameraOffsets[camera.preset] or config.cameraOffsets.fullBody
  local offset <const> = presetData.offset

  local camPos <const> = vector3(
    pedCoords.x + offset.x * math.cos(headingRad) - offset.y * math.sin(headingRad),
    pedCoords.y + offset.x * math.sin(headingRad) + offset.y * math.cos(headingRad),
    pedCoords.z + offset.z
  )

  camera.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

  SetCamCoord(camera.handle, camPos.x, camPos.y, camPos.z)
  PointCamAtPedBone(camera.handle, cache.ped, camera.preset == "face" and 31086 or 0, 0.0, 0.0, 0.0, true)
  SetCamFov(camera.handle, camera.fov + 0.0)
  RenderScriptCams(true, true, 500, true, false)
end

---@param preset string
function camera.setPreset(preset)
  camera.preset = preset
  camera.create()
end

---@param fov number
function camera.setFov(fov)
  camera.fov = fov

  if camera.handle then
    SetCamFov(camera.handle, camera.fov + 0.0)
  end
end

---@param zoom number
function camera.setZoom(zoom)
  local presetData <const> = config.cameraOffsets[camera.preset] or
    config.cameraOffsets.fullBody

  local baseY <const> = presetData.offset.y

  config.cameraOffsets[camera.preset] = {
    offset = vector3(presetData.offset.x, baseY * zoom, presetData.offset.z),
    rotation = presetData.rotation,
  }

  camera.create()
end

---@param rotation number
function camera.setRotation(rotation)
  camera.rotation = rotation
  
  camera.create()
end

---@param lighting string
function camera.setLighting(lighting)
  if lighting == "night" then
    NetworkOverrideClockTime(0, 0, 0)
  elseif lighting == "day" then
    NetworkOverrideClockTime(12, 0, 0)
  else
    NetworkOverrideClockTime(18, 0, 0)
  end
end

return camera
