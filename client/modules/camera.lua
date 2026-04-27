local config <const> = require("config")

local camera = {}

camera.handle = nil
camera.preset = "full_body"
camera.rotation = 0.0
camera.fov = config.defaultFov
camera.zoom = 1.0
camera.heightOffset = 0.0
camera._updateThread = false
camera.keysHeld = {}

local ROTATE_SPEED = 5.0
local HEIGHT_SPEED = 0.05
local HEIGHT_MIN = -0.5
local HEIGHT_MAX = 0.8

function camera.setKeyState(key, pressed)
  camera.keysHeld[key] = pressed and true or false
end

function camera.destroy()
  camera._updateThread = false
  camera.heightOffset = 0.0
  camera.keysHeld = {}

  if not camera.handle then return end

  RenderScriptCams(false, true, config.cameraTransitionTime or 500, true, false)
  DestroyCam(camera.handle, false)

  camera.handle = nil
end

function camera._getLookAtCoord()
  local pedCoords <const> = GetEntityCoords(cache.ped)
  local presetData <const> = config.cameraOffsets[camera.preset] or config.cameraOffsets.full_body

  local lookZ = pedCoords.z
  if camera.preset == "face" then
    lookZ = pedCoords.z + 0.65
  elseif presetData and presetData.offset then
    lookZ = pedCoords.z + (presetData.offset.z or 0.2)
  end

  return vector3(pedCoords.x, pedCoords.y, lookZ + camera.heightOffset)
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
    pedCoords.z + offset.z + camera.heightOffset
  )

  local lookAt <const> = camera._getLookAtCoord()

  local transitionTime <const> = config.cameraTransitionTime or 500
  local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)

  SetCamCoord(newCam, camPos.x, camPos.y, camPos.z)
  PointCamAtCoord(newCam, lookAt.x, lookAt.y, lookAt.z)
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

  if not camera._updateThread then
    camera._updateThread = true
    CreateThread(function()
      while camera._updateThread and camera.handle do
        if camera.keysHeld["a"] then
          local h = GetEntityHeading(cache.ped)
          SetEntityHeading(cache.ped, h - ROTATE_SPEED)
          camera.rotation = camera.rotation + ROTATE_SPEED
        end

        if camera.keysHeld["d"] then
          local h = GetEntityHeading(cache.ped)
          SetEntityHeading(cache.ped, h + ROTATE_SPEED)
          camera.rotation = camera.rotation - ROTATE_SPEED
        end

        if camera.keysHeld["w"] then
          camera.heightOffset = math.min(camera.heightOffset + HEIGHT_SPEED, HEIGHT_MAX)
        end

        if camera.keysHeld["s"] then
          camera.heightOffset = math.max(camera.heightOffset - HEIGHT_SPEED, HEIGHT_MIN)
        end

        local coords <const> = GetEntityCoords(cache.ped)
        local heading <const> = GetEntityHeading(cache.ped)
        local rad <const> = math.rad(heading + camera.rotation)

        local pd <const> = config.cameraOffsets[camera.preset] or config.cameraOffsets.full_body
        local off <const> = pd.offset
        local zy <const> = off.y * camera.zoom

        local cx = coords.x + off.x * math.cos(rad) - zy * math.sin(rad)
        local cy = coords.y + off.x * math.sin(rad) + zy * math.cos(rad)
        local cz = coords.z + off.z + camera.heightOffset

        SetCamCoord(camera.handle, cx, cy, cz)

        local lz = coords.z
        if camera.preset == "face" then
          lz = coords.z + 0.65
        else
          lz = coords.z + (off.z or 0.2)
        end

        PointCamAtCoord(camera.handle, coords.x, coords.y, lz + camera.heightOffset)
        Wait(0)
      end
    end)
  end
end

---@param preset string
function camera.setPreset(preset)
  camera.preset = preset
  camera.heightOffset = 0.0
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