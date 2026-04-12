local config <const> = require("config")
local logger <const> = require("shared.logger")
local locale <const> = require("shared.locale")

local menu <const> = require("client.modules.menu")
local nui <const> = require("client.modules.nui")

local framework <const> = require("bridge").get("framework")
local interaction = require("bridge").get("interaction")

local zones = {}

local blips = {}

---@param location table
---@return string
local function getInteractLabel(location)
  return ("[E] %s"):format(location.label or "Open Appearance")
end

---@param location table
local function openAtLocation(location)
  if menu.active then return end

  if location.job then
    local playerJob, playerGrade = framework.getPlayerJob()
    if playerJob ~= location.job then
      logger.debug("Access denied to location:", location.label, "- job mismatch:", playerJob, "!=", location.job)
      lib.notify({ title = locale.t("ui.sidebar.appearance"), description = locale.t("notify.no_access"), type = "error" })
      return
    end

    if location.minRank and playerGrade and playerGrade < location.minRank then
      logger.debug("Access denied to location:", location.label, "- rank too low:", playerGrade, "<", location.minRank)
      lib.notify({ title = locale.t("ui.sidebar.appearance"), description = locale.t("notify.rank_too_low"), type = "error" })
      return
    end
  end

  if location.gang then
    local playerGang = framework.getPlayerGang()
    if playerGang ~= location.gang then
      logger.debug("Access denied to location:", location.label, "- gang mismatch:", playerGang, "!=", location.gang)
      lib.notify({ title = locale.t("ui.sidebar.appearance"), description = locale.t("notify.no_access"), type = "error" })
      return
    end
  end

  if location.tabs then
    nui.sendMessage("setAllowedTabs", { tabs = location.tabs })
  end

  menu.allowedTabs = location.tabs or nil
  logger.debug("Opening menu at location:", location.label)
  menu.open()
end

function zones.setupBlips()
  for i = 1, #config.locations do
    local loc <const> = config.locations[i]
    if not loc.blip then goto continue end

    local blip <const> = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
    SetBlipSprite(blip, loc.blip.sprite or config.defaultBlip.sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, loc.blip.scale or config.defaultBlip.scale or 0.7)
    SetBlipColour(blip, loc.blip.color or config.defaultBlip.color or 0)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(loc.blip.label or loc.label or "Appearance")
    EndTextCommandSetBlipName(blip)

    blips[#blips + 1] = blip

    ::continue::
  end

  for i = 1, #config.clothingRooms do
    local room <const> = config.clothingRooms[i]
    if not room.blip then goto continue end

    local blip <const> = AddBlipForCoord(room.coords.x, room.coords.y, room.coords.z)
    SetBlipSprite(blip, room.blip.sprite or config.defaultBlip.sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, room.blip.scale or config.defaultBlip.scale or 0.7)
    SetBlipColour(blip, room.blip.color or config.defaultBlip.color or 0)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(room.blip.label or room.label or "Locker Room")
    EndTextCommandSetBlipName(blip)

    blips[#blips + 1] = blip

    ::continue::
  end
end

function zones.setupPoints()
  if not interaction then return end

  for i = 1, #config.locations do
    if not interaction.addPoint then goto continue end

    local loc <const> = config.locations[i]

    interaction.addPoint(
      loc.coords,
      loc.radius or config.defaultLocationRadius or 2.0,
      38,
      getInteractLabel(loc),
      function()
        openAtLocation(loc)
      end
    )

    ::continue::
  end

  for i = 1, #config.clothingRooms do
    if not interaction.addPoint then goto continue end

    local room <const> = config.clothingRooms[i]

    interaction.addPoint(
      room.coords,
      room.radius or config.defaultClothingRoomRadius or 1.5,
      38,
      getInteractLabel(room),
      function()
        openAtLocation(room)
      end
    )

    ::continue::
  end
end

function zones.setupTarget()
  if not interaction then return end

  for i = 1, #config.locations do
    if not interaction.addZone then goto continue end

    local loc <const> = config.locations[i]
    local id <const> = ("appearance_loc_%d"):format(i)

    interaction.addZone(
      id,
      loc.coords,
      loc.radius or config.defaultLocationRadius or 2.0,
      getInteractLabel(loc),
      config.targetIcons.location or "fas fa-tshirt",
      function() openAtLocation(loc) end
    )

    ::continue::
  end

  for i = 1, #config.clothingRooms do
    if not interaction.addZone then goto continue end

    local room <const> = config.clothingRooms[i]
    local id <const> = ("appearance_room_%d"):format(i)

    interaction.addZone(
      id,
      room.coords,
      room.radius or config.defaultClothingRoomRadius or 1.5,
      getInteractLabel(room),
      config.targetIcons.clothingRoom or "fas fa-door-open",
      function() openAtLocation(room) end
    )

    ::continue::
  end
end

function zones.init()
  logger.info("Initializing zones:", #config.locations, "locations,", #config.clothingRooms, "clothing rooms")
  zones.setupBlips()

  if config.interactionType == "target" then
    zones.setupTarget()
    return
  end

  zones.setupPoints()
end

function zones.destroy()
  logger.debug("Destroying zones and blips")
  for _, blip in ipairs(blips) do
    RemoveBlip(blip)
  end

  blips = {}
end

return zones