# juddlie_appearance

A fully-featured character appearance menu for FiveM. Supports ESX, QBX, and standalone frameworks with ox_target or qb-target interaction.

---

## Dependencies

These resources **must** be installed and started before `juddlie_appearance`:

| Resource | Required | Purpose |
|----------|----------|---------|
| [ox_lib](https://github.com/overextended/ox_lib) | Yes | UI notifications, points, utilities |
| [oxmysql](https://github.com/overextended/oxmysql) | Yes | Database queries |
| [es_extended](https://github.com/esx-framework/esx_core) | If using ESX | ESX framework bridge |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | If using QBX | QBX framework bridge |
| [ox_target](https://github.com/overextended/ox_target) | If using ox interaction | Target zones |
| [qb-target](https://github.com/qbcore-framework/qb-target) | If using qb interaction | Target zones |

---

## Installation

1. Place the `juddlie_appearance` folder into your server's `resources` directory.
2. Add `ensure juddlie_appearance` to your `server.cfg` (**after** your framework and the dependencies above).
3. Open `config.lua` and set your framework + interaction method (see below).
4. Restart your server — the database tables are created automatically on first start.

> **Database tables created automatically:**
> - `juddlie_appearance` — player skins
> - `juddlie_appearance_presets` — saved presets
> - `juddlie_appearance_outfits` — saved outfits
> - `juddlie_appearance_job_outfits` — job outfits

---

## Configuration

Everything is configured in **`config.lua`**. Below is a walkthrough of every section.

### Framework

```lua
config.framework = "esx"
```

| Value | Framework |
|-------|-----------|
| `"esx"` | ESX / es_extended |
| `"qbx"` | QBX / qbx_core |
| `"custom"` | Standalone — no framework, uses license identifier only |

### Interaction Method

```lua
config.interaction = "ox"
config.interactionType = "point"
```

**`config.interaction`** — which target resource to use:

| Value | Description |
|-------|-------------|
| `"ox"` | Use ox_target |
| `"qb"` | Use qb-target |

**`config.interactionType`** — how players interact at locations:

| Value | Description |
|-------|-------------|
| `"point"` | Proximity-based — shows a TextUI prompt and the player presses **E** when nearby (ox only) |
| `"target"` | Target-based — player aims with the target eye and clicks the option |

> **Note:** `"point"` mode is only available with `config.interaction = "ox"`. If you use `"qb"`, set `interactionType` to `"target"`.

### Identifier Type

```lua
config.licenseType = "license"
```

Only used when `config.framework = "custom"`. Determines which FiveM identifier is used to save player data.

| Value | Identifier |
|-------|------------|
| `"license"` | Rockstar license |
| `"license2"` | Rockstar license (alt) |
| `"fivem"` | FiveM account ID |
| `"discord"` | Discord ID |

When using ESX or QBX, the identifier comes from the framework automatically — this setting is ignored.

### General Settings

```lua
config.debug = true                          -- enables /appearance command for testing
config.locale = "en"                         -- language (see Localization section)
config.defaultFov = 50                       -- camera field of view
config.invincibleDuringCustomization = true   -- god mode while menu is open
config.freezeDuringCustomization = true       -- freeze the player in place while menu is open
config.hideRadar = false                     -- hide minimap while menu is open
```

### Head Blend Defaults

```lua
-- default head blend mix values when creating a new freemode ped (range: 0.0 to 1.0)
config.defaultShapeMix = 0.5
config.defaultSkinMix = 0.5
```

### Timeouts & Animation

```lua
config.modelLoadTimeout = 5000      -- timeout (ms) for loading ped models
config.animationLoadTimeout = 5000  -- timeout (ms) for loading animation dicts
config.animationBlendIn = 8.0       -- animation blend in speed
config.animationBlendOut = -8.0     -- animation blend out speed
config.cameraTransitionTime = 500   -- camera create/destroy transition (ms)
config.randomizerDefaultSpeed = 2   -- auto-randomizer speed in seconds
```

### Server Limits

Prevent abuse with payload size limits and max saved items:

```lua
config.limits = {
    maxPresets = 50,       -- max presets per player
    maxOutfits = 50,       -- max outfits per player
    maxPayloadSize = 100000, -- max JSON payload size in bytes
}
```

### Default Blip & Radius

```lua
-- default blip settings used when a location doesn't specify its own
config.defaultBlip = {
    sprite = 1,
    color = 0,
    scale = 0.7,
}

-- default interaction radius for locations and clothing rooms (in meters)
config.defaultLocationRadius = 2.0
config.defaultClothingRoomRadius = 1.5
```

### Target Icons

```lua
-- icons used for ox_target / qb-target interaction zones
config.targetIcons = {
    location = "fas fa-tshirt",
    clothingRoom = "fas fa-door-open",
}
```

### Lighting Times

```lua
-- clock times set for each lighting preset (hour, minute, second)
config.lightingTimes = {
    studio = { 18, 0, 0 },
    day    = { 12, 0, 0 },
    night  = { 0, 0, 0 },
}
```

### Ped Models

Models available in the ped model selector page:

```lua
config.pedModels = {
    { value = "mp_m_freemode_01", label = "Freemode Male" },
    { value = "mp_f_freemode_01", label = "Freemode Female" },
}
```

### Disabled Components / Props

Use this if you have a clothing-as-items system and want to prevent players from changing certain components through the appearance menu.

```lua
config.disabledComponents = {}   -- e.g., { 9 } to disable body armor
config.disabledProps = {}        -- e.g., { 6, 7 } to disable watch and bracelet
```

**Component IDs reference:**

| ID | Component |
|----|-----------|
| 0 | Head |
| 1 | Beard / Mask |
| 2 | Hair |
| 3 | Upper Body / Torso |
| 4 | Legs / Pants |
| 5 | Bags / Parachute |
| 6 | Shoes |
| 7 | Accessories |
| 8 | Undershirt |
| 9 | Body Armor |
| 10 | Decals / Badges |
| 11 | Jacket / Outer |

**Prop IDs reference:**

| ID | Prop |
|----|------|
| 0 | Hats |
| 1 | Glasses |
| 2 | Ears |
| 6 | Watches |
| 7 | Bracelets |

---

## Locations

Locations are the zones where the appearance menu can be opened. Each location gets a map blip and an interaction point/target.

```lua
config.locations = {
    {
        type = "clothing_store",     -- type label (for your reference only)
        label = "Clothing Store",    -- name shown to the player
        coords = vector3(72.3, -1399.1, 29.4),  -- world position
        radius = 2.0,               -- interaction radius (in meters)
        tabs = { "clothing", "props", "outfits" },  -- which menu tabs are available here
        blip = {
            sprite = 73,            -- blip icon (see https://docs.fivem.net/docs/game-references/blips/)
            color = 47,             -- blip color
            scale = 0.7,            -- blip size
            label = "Clothing Store" -- text on the map
        },
    },
}
```

### Available Tab Names

| Tab Name | What It Opens |
|----------|---------------|
| `"clothing"` | Shirts, pants, shoes, etc. |
| `"props"` | Hats, glasses, watches, etc. |
| `"outfits"` | Saved outfits |
| `"hair"` | Hair style and color |
| `"face"` | Face shape / features |
| `"colors"` | Eye color, makeup, overlays |
| `"tattoos"` | Tattoo parlor |
| `"presets"` | Saved presets (full appearance) |
| `"animations"` | Pose / animation browser |
| `"randomizer"` | Randomize appearance |
| `"camera"` | Camera controls |

### Location Types (Examples)

You can use any combination of tabs to create different shop types:

| Store Type | Suggested Tabs |
|------------|----------------|
| Clothing Store | `{ "clothing", "props", "outfits" }` |
| Barber Shop | `{ "hair", "face", "colors" }` |
| Tattoo Parlor | `{ "tattoos" }` |
| Plastic Surgeon | `{ "face", "colors" }` |
| Full Customization | All tabs |

---

## Job / Gang Clothing Rooms

Clothing rooms are restricted locations that only specific jobs or gangs can access. They work the same as regular locations but with access control.

```lua
config.clothingRooms = {
    {
        label = "LSPD Locker Room",
        coords = vector3(461.8, -1000.4, 30.7),
        radius = 1.5,
        job = "police",          -- required job name (must match your framework)
        -- gang = "ballas",      -- OR use gang instead of job (not both)
        minRank = 0,             -- minimum job/gang grade (0 = all ranks)
        tabs = { "clothing", "props", "outfits" },
        blip = { sprite = 366, color = 29, scale = 0.6, label = "LSPD Locker Room" },
    },
}
```

| Field | Type | Description |
|-------|------|-------------|
| `label` | string | Name shown to the player |
| `coords` | vector3 | World position |
| `radius` | number | Interaction radius in meters |
| `job` | string | Required job name — player must have this job |
| `gang` | string | Required gang name (use one or the other, not both) |
| `minRank` | number | Minimum grade/rank required. `0` means any rank |
| `tabs` | table | Which menu tabs are available |
| `blip` | table | Optional — map blip config (same fields as locations) |

> **Tip:** If `minRank` is set to `2`, only players with grade 2 or higher can access the room.

---

## Blacklist / Whitelist

Block (or exclusively allow) specific clothing drawables and props based on job, gang, identifier, or ACE permissions.

```lua
config.blacklist = {
    enabled = false,              -- set to true to activate
    mode = "blacklist",           -- "blacklist" or "whitelist"

    clothing = {
        {
            component = 11,           -- component ID (see table above)
            drawables = { 55, 56 },   -- drawable IDs to restrict
            jobs = { "police" },      -- only police are affected
            invert = true,            -- invert = block everyone EXCEPT police
        },
    },

    props = {
        {
            prop = 0,                 -- prop ID
            drawables = { 120 },      -- drawable IDs to restrict
            aces = { "appearance.vip" }, -- only players with this ACE
            invert = true,            -- block everyone EXCEPT those with the ACE
        },
    },
}
```

### How Rules Work

Each rule in `clothing` or `props` can use any combination of these filters:

| Field | Type | Description |
|-------|------|-------------|
| `component` / `prop` | number | Which component or prop this rule applies to |
| `drawables` | table | List of drawable IDs to restrict |
| `jobs` | table | Job names that match this rule |
| `gangs` | table | Gang names that match this rule |
| `identifiers` | table | Specific player identifiers |
| `aces` | table | ACE permission strings (e.g., `"appearance.vip"`) |
| `invert` | boolean | Flip the logic (see below) |

### Understanding `invert`

| `invert` | Behavior |
|----------|----------|
| `false` (default) | The drawable is blocked **for matching players** (e.g., police can't wear it) |
| `true` | The drawable is blocked **for everyone EXCEPT matching players** (e.g., only police can wear it) |

### Granting ACE Permissions

Add ACE permissions in your `server.cfg`:

```cfg
add_ace identifier.license:abc123 appearance.vip allow
add_ace group.admin appearance.vip allow
```

---

## Outfit Categories

Customize the categories players can organize their outfits into:

```lua
config.outfitCategories = {
    { value = "casual", label = "Casual" },
    { value = "work", label = "Work" },
    { value = "formal", label = "Formal" },
    { value = "custom", label = "Custom" },
}
```

Add or remove categories as needed. The `value` is stored in the database, the `label` is what players see.

---

## Camera Settings

### Presets

```lua
config.cameraPresets = {
    { value = "face", label = "Face" },
    { value = "three_quarter", label = "3/4" },
    { value = "full_body", label = "Full Body" },
}
```

### Camera Offsets

Control where each camera preset is positioned relative to the player:

```lua
config.cameraOffsets = {
    face = {
        offset = vector3(0.0, 0.7, 0.65),      -- x, y, z offset from ped
        rotation = vector3(-5.0, 0.0, 0.0)      -- pitch, roll, yaw
    },
    threeQuarter = {
        offset = vector3(0.5, 1.2, 0.3),
        rotation = vector3(-5.0, 0.0, 0.0)
    },
    fullBody = {
        offset = vector3(0.0, 2.5, 0.2),
        rotation = vector3(-5.0, 0.0, 0.0)
    },
}
```

### Defaults and Ranges

```lua
config.cameraDefaults = {
    preset = "full_body",   -- starting camera angle
    lighting = "studio",    -- starting lighting
    fov = 50,
    zoom = 1,
    rotation = 0,
}

config.cameraRanges = {
    fov = { min = 20, max = 90, step = 1 },
    zoom = { min = 0.5, max = 3, step = 0.1 },
    rotation = { min = -180, max = 180, step = 1 },
}
```

### Lighting Presets

```lua
config.lightingPresets = {
    { value = "studio", label = "Studio" },
    { value = "day", label = "Day" },
    { value = "night", label = "Night" },
}
```

---

## Ped Menu

A separate command to change your ped model (useful for admin/testing):

```lua
config.pedMenu = {
    enabled = true,
    command = "pedmenu",           -- chat command to open it
    acePermission = false,         -- false = everyone can use it
                                   -- "admin.pedmenu" = only players with this ACE
}
```

To restrict it, set `acePermission` to an ACE string and grant it in your `server.cfg`:

```cfg
add_ace group.admin admin.pedmenu allow
```

---

## Commands

```lua
config.commands = {
    reloadSkin = "reloadskin",   -- reloads your saved skin from the database
}
```

| Command | Description |
|---------|-------------|
| `/reloadskin` | Re-applies your saved appearance from the database |
| `/appearance` | Opens the full menu (only available when `config.debug = true`) |
| `/pedmenu` | Opens the ped model selector (when `config.pedMenu.enabled = true`) |

---

## Exports

### Client Exports

Use these from other client-side resources:

```lua
-- Open the appearance menu
exports.juddlie_appearance:open()

-- Open with restricted tabs only
exports.juddlie_appearance:open({ tabs = { "clothing", "props" } })

-- Close the menu
exports.juddlie_appearance:close()

-- Get the player's current appearance data
local appearance = exports.juddlie_appearance:getAppearance()

-- Apply appearance data to the player's ped
exports.juddlie_appearance:setAppearance(appearanceData)
```

### Server Exports

Use these from other server-side resources:

```lua
-- Get a player's saved appearance
local appearance = exports.juddlie_appearance:getPlayerAppearance(source)

-- Set a player's appearance (saves to DB + applies on client)
exports.juddlie_appearance:setPlayerAppearance(source, appearanceData)

-- Get all outfits for a player
local outfits = exports.juddlie_appearance:getPlayerOutfits(source)

-- Get a specific outfit by ID
local outfit = exports.juddlie_appearance:getPlayerOutfit(source, "outfit_id_here")
```

---

## Custom Framework Bridge

If you set `config.framework = "custom"`, the resource runs without ESX or QBX. The custom bridge uses FiveM native identifiers.

To add your own framework support, edit the files in:
- `bridge/framework/custom/client.lua`
- `bridge/framework/custom/server.lua`

Each bridge must return a table with these functions:

**Client:**
```lua
bridge.onPlayerLoaded(handler)   -- call handler() when the player is ready
bridge.getPlayerJob()            -- return jobName, jobGrade
bridge.getPlayerGang()           -- return gangName
```

**Server:**
```lua
bridge.getIdentifier(src)        -- return the player's unique identifier string
bridge.getPlayerData(src)        -- return { identifier, job, jobGrade, gang }
```

---

## Troubleshooting

### Menu won't open
- Make sure you're standing inside a location's radius
- Check that the `tabs` array on the location isn't empty
- With `config.debug = true`, try `/appearance` to test without a location

### "Failed to load framework bridge" error
- Make sure `config.framework` matches your installed framework (`"esx"`, `"qbx"`, or `"custom"`)
- Ensure your framework resource is started **before** `juddlie_appearance`

### "Failed to load interaction bridge" error
- Make sure `config.interaction` matches your installed target resource (`"ox"` or `"qb"`)
- Ensure `ox_target` or `qb-target` is started before this resource

### Blips show but interaction doesn't work
- Check `config.interactionType` — if set to `"point"`, you need `config.interaction = "ox"`
- If using qb-target, set `config.interactionType = "target"`

### Clothing rooms say "You don't have access"
- The `job` or `gang` value must match your framework exactly (case-sensitive)
- Check `minRank` — the player's grade must be >= this value

### Blacklist not working
- Set `config.blacklist.enabled = true`
- Make sure `component` / `prop` and `drawables` IDs are correct
- Test with a simple rule first, then add complexity

### Database tables not created
- Make sure `oxmysql` is started and connected before this resource
- Check your server console for SQL errors

---

## Outfit Wheel (Quick Swap)

Quickly swap between saved outfits using a keybind — no need to open the full appearance menu.

```lua
config.outfitWheel = {
    enabled = true,
    key = "F7",               -- default keybind (players can rebind it in their FiveM keybind settings)
    command = "+outfitwheel",  -- internal command name
    favoriteIcon = "star",     -- icon for favorite outfits in the context menu
    defaultIcon = "shirt",     -- icon for regular outfits in the context menu
    categoryColors = {         -- color mapping for outfit categories
        casual = "blue",
        work = "orange",
        formal = "purple",
        custom = "gray",
    },
}
```

When pressed, opens an ox_lib context menu listing all saved outfits. Favorites (⭐) appear at the top. The applied outfit is automatically saved to the database.

---

## Admin Appearance Panel

Staff members can edit another player's appearance remotely using a command.

```lua
config.admin = {
    enabled = true,
    command = "setappearance",        -- /setappearance [player id]
    acePermission = "admin.appearance", -- ACE permission required
}
```

**Usage:** `/setappearance 5` — opens the appearance menu with player 5's current skin. Changes are saved to that player's database entry and applied to their ped in real-time.

**Grant permission in server.cfg:**
```cfg
add_ace group.admin admin.appearance allow
```

---

## Migration from illenium-appearance

One-command migration tool to import all player skins and outfits from illenium-appearance.

```lua
config.migration = {
    enabled = true,
    command = "migrateappearance",
    acePermission = false,  -- console-only by default
}
```

**Usage:** Run `migrateappearance` from the server console. The tool will:

1. Auto-detect whether you're migrating from QB (`citizenid` column) or ESX (`identifier` column)
2. Convert all skin data from illenium's flat format to juddlie's structured format
3. Migrate outfits from the `player_outfits` table
4. **Skip** any players who already have data in juddlie_appearance (safe to re-run)
5. Print a summary of how many skins and outfits were migrated

> **Important:** Back up your database before running the migration. The tool only inserts new data — it never overwrites existing juddlie_appearance records.

---

## Localization (i18n)

The resource supports multiple languages. Locale files are stored as JSON in the `locales/` folder.

```lua
config.locale = "en"  -- change to "es", "fr", "de", "pt", etc.
```

### Included Languages

| Code | Language |
|------|----------|
| `en` | English |
| `es` | Spanish |
| `fr` | French |
| `de` | German |
| `pt` | Portuguese |

### Adding a New Language

1. Copy `locales/en.json` to `locales/xx.json` (where `xx` is your language code)
2. Translate all strings in the JSON file
3. Set `config.locale = "xx"` in `config.lua`

---

## Clothing Search

The clothing tab includes a built-in search bar that filters components by name, component ID, or drawable number. This makes it much faster to find specific clothing items when working with hundreds of drawables.

---

## Job Outfit Persistence

When players use job clothing rooms, their outfit is automatically saved per job. On reconnect, the job outfit is restored — players no longer lose their work clothes after disconnecting.