local config <const> = require("config")

local camera = {}

camera.handle = nil
camera.preset = "fullBody"
camera.rotation = 0.0
camera.fov = config.defaultFov
camera.zoom = 1.0

function camera.destroy()
  if not camera.handle then return end

  RenderScriptCams(false, true, config.cameraTransitionTime or 500, true, false)
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

  local zoomedY <const> = offset.y * camera.zoom

  local camPos <const> = vector3(
    pedCoords.x + offset.x * math.cos(headingRad) - zoomedY * math.sin(headingRad),
    pedCoords.y + offset.x * math.sin(headingRad) + zoomedY * math.cos(headingRad),
    pedCoords.z + offset.z
  )

  camera.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

  SetCamCoord(camera.handle, camPos.x, camPos.y, camPos.z)
  PointCamAtPedBone(camera.handle, cache.ped, camera.preset == "face" and 31086 or 0, 0.0, 0.0, 0.0, true)
  SetCamFov(camera.handle, camera.fov + 0.0)
  RenderScriptCams(true, true, config.cameraTransitionTime or 500, true, false)
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
  camera.zoom = zoom
  camera.create()
end

---@param rotation number
function camera.setRotation(rotation)
  camera.rotation = rotation
  
  camera.create()
end

---@param lighting string
function camera.setLighting(lighting)
  local times <const> = config.lightingTimes or {}
  local preset <const> = times[lighting] or times.studio or { 18, 0, 0 }
  NetworkOverrideClockTime(preset[1], preset[2], preset[3])
end

return camera
