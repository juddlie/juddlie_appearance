local config <const> = require("config")

local camera = {}

camera.handle = nil
camera.preset = "full_body"
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
  local pedCoords <const> = GetEntityCoords(cache.ped)
  local pedHeading <const> = GetEntityHeading(cache.ped)
  local headingRad <const> = math.rad(pedHeading + camera.rotation)

  local presetData <const> = config.cameraOffsets[camera.preset] or config.cameraOffsets.full_body
  local offset <const> = presetData.offset
  local zoomedY <const> = offset.y * camera.zoom

  local camPos <const> = vector3(
    pedCoords.x + offset.x * math.cos(headingRad) - zoomedY * math.sin(headingRad),
    pedCoords.y + offset.x * math.sin(headingRad) + zoomedY * math.cos(headingRad),
    pedCoords.z + offset.z
  )

  local lookZ = pedCoords.z
  if camera.preset == "face" then
    lookZ = pedCoords.z + 0.65
  else
    lookZ = pedCoords.z + (offset.z or 0.2)
  end

  local transitionTime <const> = config.cameraTransitionTime or 500
  local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)

  SetCamCoord(newCam, camPos.x, camPos.y, camPos.z)
  PointCamAtCoord(newCam, pedCoords.x, pedCoords.y, lookZ)
  SetCamFov(newCam, camera.fov + 0.0)

  if camera.handle then
    local oldCam = camera.handle
    camera.handle = newCam
    RenderScriptCams(true, false, 0, true, false)
    SetCamActiveWithInterp(newCam, oldCam, transitionTime, 1, 1)
    CreateThread(function()
      Wait(transitionTime)
      DestroyCam(oldCam, false)
    end)
  else
    SetCamActive(newCam, true)
    RenderScriptCams(true, true, transitionTime, true, false)
    camera.handle = newCam
  end
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