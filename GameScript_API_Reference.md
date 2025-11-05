# OpenTTD GameScript API Reference

This document provides a tested reference for what works and what doesn't in the OpenTTD GameScript API, based on systematic testing in both scenario editor and live gameplay modes.

**Last Updated:** 2025-11-05
**OpenTTD Version:** Tested with GameScript API v15
**Testing Context:** Scenario Editor + Live Gameplay

---

## Quick Reference

### ✅ What Works
- **Trees** - `GSTree.PlantTree()`
- **Roads** - `GSRoad.BuildRoad()`, road types, depots
- **Bridges** - `GSBridge.BuildBridge()` (road/rail)
- **Tunnels** - `GSTunnel.BuildTunnel()` (road/rail)
- **Towns** - `GSTown.FoundTown()`, `GSTown.ExpandTown()` (houses + roads)
- **Signs** - `GSSign.BuildSign()`

### ⚠️ Partially Works
- **Industries** - `GSIndustryType.BuildIndustry()` - Needs more testing, some newGRF packs are hard to place due to all kinds of restrictions.

### ❌ Does NOT Work
- **Houses** - No `BuildHouse()` API exists (use town expansion instead)
- **Rivers** - No `BuildRiver()` API exists (canals are different)
- **Objects** - `GSObjectType.BuildObject()` fails for GameScripts
- **Town Action: Fund Buildings** - Only works in live game, NOT scenario editor

### ⏳ Not Yet Tested
- **Rails** - Track building
- **Depots** - Rail depots (road depots work)
- **Stations** - Train/bus/truck stations

---

## Table of Contents
1. [Verified Working Features](#verified-working-features)
2. [Partially Working Features](#partially-working-features)
3. [Non-Working Features](#non-working-features)
4. [Not Yet Tested](#not-yet-tested)
5. [Critical Discoveries](#critical-discoveries)
6. [API Gotchas](#api-gotchas)

---

## Verified Working Features

### 1. Trees ✅
**Status:** Verified working in scenario editor

**API:**
```squirrel
GSTree.PlantTree(tile)
```

**Notes:**
- Single tree planting works
- Multiple plantings on same tile creates thick forest
- No company mode required

---

### 2. Roads ✅
**Status:** Verified working in scenario editor

**API:**
```squirrel
// List available road types
GSRoadTypeList(GSRoad.ROADTRAMTYPES_ROAD)

// Set current road type
GSRoad.SetCurrentRoadType(road_type)

// Build road between two tiles
GSRoad.BuildRoad(tile1, tile2)

// Build road depot
GSRoad.BuildRoadDepot(tile, front_tile)
```

**Notes:**
- All road types detected correctly (including "city" type)
- T-intersection building works
- Can search for specific road types by name (e.g., "city", "highway")
- Falls back to first available road type if specific type not found

**Example - Finding City Roads:**
```squirrel
local town_road_type = null;
local road_types = GSRoadTypeList(GSRoad.ROADTRAMTYPES_ROAD);

foreach (road_type, _ in road_types) {
    local road_name = GSRoad.GetName(road_type);
    if (road_name.find("city") != null || road_name.find("City") != null) {
        town_road_type = road_type;
        break;
    }
}

// Fallback to first available if not found
if (town_road_type == null && road_types.Count() > 0) {
    town_road_type = road_types.Begin();
}

GSRoad.SetCurrentRoadType(town_road_type);
```

---

### 3. Bridges ✅
**Status:** Verified working in scenario editor

**API:**
```squirrel
GSBridge.BuildBridge(vehicle_type, bridge_id, start_tile, end_tile)
```

**Parameters:**
- `vehicle_type`: GSVehicle.VT_ROAD or GSVehicle.VT_RAIL
- `bridge_id`: Bridge type ID (get from GSBridgeList)
- `start_tile`: Starting tile coordinate
- `end_tile`: Ending tile coordinate

**Notes:**
- Only needs start and end coordinates
- Game automatically determines bridge height and validates path
- Works for both road and rail bridges

**Example:**
```squirrel
local bridges = GSBridgeList();
local bridge_id = bridges.Begin();
local start = GSMap.GetTileIndex(x1, y1);
local end = GSMap.GetTileIndex(x2, y2);

GSBridge.BuildBridge(GSVehicle.VT_ROAD, bridge_id, start, end);
```

---

### 4. Tunnels ✅
**Status:** Verified working in scenario editor

**API:**
```squirrel
GSTunnel.BuildTunnel(vehicle_type, start_tile)
```

**Parameters:**
- `vehicle_type`: GSVehicle.VT_ROAD or GSVehicle.VT_RAIL
- `start_tile`: Starting tile (must be a slope facing the tunnel direction)

**Notes:**
- Only needs start coordinate
- Game automatically calculates tunnel end point
- Start tile must have proper slope orientation
- Works for both road and rail tunnels

---

### 5. Towns ✅
**Status:** Verified working in both scenario editor and live game

**APIs:**

#### Found Town
```squirrel
GSTown.FoundTown(tile, size, is_city, layout, town_name)
```

**Parameters:**
- `tile`: Center tile for town
- `size`: GSTown.TOWN_SIZE_SMALL / MEDIUM / LARGE
- `is_city`: true/false (cities grow faster)
- `layout`: GSTown.ROAD_LAYOUT_ORIGINAL / BETTER_ROADS / 2x2_GRID / 3x3_GRID
- `town_name`: String name for the town

**Notes:**
- Works without company mode in scenario editor
- Returns town ID via `GSTile.GetTownAuthority(tile)` after founding

#### Expand Town (Immediate)
```squirrel
GSTown.ExpandTown(town_id, houses)
```

**Parameters:**
- `town_id`: ID of the town
- `houses`: Number of houses to build

**Notes:**
- **CRITICAL:** Must be called WITHOUT GSCompanyMode wrapper!
- Builds houses AND roads immediately
- Works in both scenario editor and live game

**WRONG:**
```squirrel
{
    local mode = GSCompanyMode(company_id);
    GSTown.ExpandTown(town_id, houses); // FAILS!
}
```

**RIGHT:**
```squirrel
GSTown.ExpandTown(town_id, houses); // Works!
```

#### Fund Buildings (Live Game Only)
```squirrel
GSTown.PerformTownAction(town_id, 5)
```

**Parameters:**
- `town_id`: ID of the town
- `5`: Action constant for TOWN_ACTION_FUND_BUILDINGS

**Notes:**
- **CRITICAL:** Must be called WITH GSCompanyMode wrapper!
- Only works in LIVE GAME (not scenario editor)
- Funds building construction over 3 economy-months (time-based, not immediate)
- Requires town population > 0
- The parameter is the numeric index `5`, not an enum constant

**Example:**
```squirrel
{
    local mode = GSCompanyMode(company_id);
    local success = GSTown.PerformTownAction(town_id, 5);
    if (success) {
        local duration = GSTown.GetFundBuildingsDuration(town_id);
        GSLog.Info("Funding for " + duration + " months");
    }
}
```

#### Other Town Functions
```squirrel
GSTown.IsValidTown(town_id)
GSTown.GetName(town_id)
GSTown.GetPopulation(town_id)
GSTown.GetRating(town_id, company_id)
GSTown.GetFundBuildingsDuration(town_id)
GSTown.IsActionAvailable(town_id, action)
```

---

### 6. Signs ✅
**Status:** Verified working in scenario editor

**API:**
```squirrel
GSSign.BuildSign(tile, text)
```

**Parameters:**
- `tile`: Tile coordinate for sign placement
- `text`: String text to display

**Returns:**
- Sign ID (integer >= 0) on success
- null or negative value on failure

**Notes:**
- Signs may be hidden by transparency settings in game UI
- Check View > Transparency Settings > Signs if not visible
- No company mode required

**Example:**
```squirrel
local tile = GSMap.GetTileIndex(x, y);
local sign_id = GSSign.BuildSign(tile, "My Sign Text");

if (sign_id != null && sign_id >= 0) {
    GSLog.Info("Sign placed successfully");
}
```

---

## Partially Working Features

### 7. Industries ⚠️
**Status:** Partially working - some industries succeed, others fail

**API:**
```squirrel
GSIndustryType.BuildIndustry(industry_type, tile)
```

**Test Results:**
- ✅ Oil Rig: Works (in water tiles)
- ❌ Forest: Fails (no clear error message)

**Known Issues:**
- No reliable way to verify if industry was actually built
- Some industry types have hidden placement requirements
- Error messages are often unclear or missing

**TODO:**
- Improve verification logic:
  1. Try to build industry
  2. Check if industry exists at location after building
  3. Report detailed success/failure information
  4. Automatically try different locations if placement fails

**Example - Current Approach:**
```squirrel
local industry_types = GSIndustryTypeList();
foreach (ind_type, _ in industry_types) {
    local name = GSIndustryType.GetName(ind_type);
    if (name == "Oil Rig") {
        local tile = /* water tile */;
        local built = GSIndustryType.BuildIndustry(ind_type, tile);
        // built may return true even if placement failed!
    }
}
```

---

## Non-Working Features

### 8. Houses ❌
**Status:** API does not exist

**Attempted API:**
```squirrel
GSTown.BuildHouse() // DOES NOT EXIST
```

**Notes:**
- GameScript CANNOT build houses directly
- Only towns can build houses (via ExpandTown or natural growth)
- GameScript can detect existing houses:
  - `GSTile.IsHouseTile(tile)`
  - Can get house information but not create them

**Alternative:**
- Use `GSTown.ExpandTown()` to let the town build houses

---

### 9. Rivers ❌
**Status:** API does not exist (canals are different)

**Attempted API:**
```squirrel
GSRiver.BuildRiver() // DOES NOT EXIST
```

**Notes:**
- GameScript can detect rivers: `GSTile.IsRiverTile(tile)`
- GameScript CAN build canals: `GSMarine.BuildCanal(tile)`
- Canals create water tiles but NOT "river" tiles
- Rivers and canals are fundamentally different features
- No known way to build actual rivers via GameScript

---

### 10. Objects ❌
**Status:** BuildObject fails for GameScripts

**API:**
```squirrel
GSObjectType.BuildObject(object_type, tile)
```

**Test Results:**
- Object types can be enumerated correctly
- Tile validation passes
- BuildObject fails with errors:
  - View 0: ERR_UNKNOWN
  - Other views: ERR_PRECONDITION_FAILED
- Tested both with and without GSCompanyMode wrapper - both fail

**Tested Objects:**
- Lighthouse (ID: 1) - Failed in both scenario editor and live game

**Conclusion:**
- `GSObjectType.BuildObject()` may not be available to GameScripts
- Objects can be placed manually in editor but not via API
- This may be a limitation by design

---

## Not Yet Tested

### 11. Rails ⏳
**Status:** Not yet tested

**Expected API:**
```squirrel
GSRail.BuildRail(tile1, tile2)
GSRail.BuildRailTrack(tile, track)
```

---

### 12. Depots ⏳
**Status:** Not yet tested

**Expected API:**
```squirrel
GSRoad.BuildRoadDepot(tile, front_tile)
GSRail.BuildRailDepot(tile, direction)
```

---

### 13. Stations ⏳
**Status:** Not yet tested

**Expected API:**
```squirrel
GSStation.BuildRoadStation()
GSStation.BuildRailStation()
```

---

## Critical Discoveries

### Company Mode Behavior
Different APIs have **opposite requirements** for GSCompanyMode:

| API | Requires Company Mode? | Notes |
|-----|----------------------|-------|
| `GSTown.ExpandTown()` | ❌ NO | Must call WITHOUT wrapper |
| `GSTown.PerformTownAction()` | ✅ YES | Must call WITH wrapper |
| `GSTile.DemolishTile()` | ✅ YES | Requires company context |
| `GSTree.PlantTree()` | ❌ NO | Works without wrapper |
| `GSRoad.BuildRoad()` | Varies | Context-dependent |

**Key Insight:** Always check if an API fails - try both with and without GSCompanyMode!

---

### Scenario Editor vs Live Game

Some features only work in specific contexts:

| Feature | Scenario Editor | Live Game |
|---------|----------------|-----------|
| `GSTown.ExpandTown()` | ✅ | ✅ |
| `GSTown.PerformTownAction()` | ❌ | ✅ |
| Most building APIs | ✅ | ✅ |

**Time-based actions** (like FUND_BUILDINGS) require a running game with advancing time.

---

## API Gotchas

### 1. Enum Constants
Some enum constants are **NOT prefixed** with the class name:

**WRONG:**
```squirrel
GSTown.PerformTownAction(town_id, GSTown.TOWN_ACTION_FUND_BUILDINGS)
```

**RIGHT:**
```squirrel
GSTown.PerformTownAction(town_id, 5)
```

### 2. Tile Clearing
Multi-tile buildings (2x2, 3x3 houses) can usually be cleared in one pass:

```squirrel
GSTile.DemolishTile(any_tile_of_building)
```

For unknow reason, buildings are not always removed.


### 3. Road Type Detection
When searching for road types by name, search for lowercase and capitalized variants:

```squirrel
if (road_name.find("city") != null || road_name.find("City") != null)
```

### 4. Error Messages
Some APIs return success but actually failed:
- Always verify results when possible
- Check if expected object exists at location
- Some APIs provide poor error messages

### 5. Sign Visibility
Signs created via API may be hidden by transparency settings:
- UI: View > Transparency Settings > Signs
- Players need to enable sign visibility manually

### 6. API Version
Always specify your API version in `info.nut`:

```squirrel
function GetAPIVersion() {
    return "15";
}
```

This ensures compatibility and reduces warning messages.

---

## Testing Methodology

### Basic Test Structure
```squirrel
function TestFeature() {
    GSLog.Info("TEST: Feature Name");

    local tile = GSMap.GetTileIndex(x, y);
    local built = false;

    // Attempt to build
    local result = GSFeature.Build(tile);

    if (result) {
        built = true;
        GSLog.Info("  SUCCESS: Feature built");
    } else {
        local error = GSError.GetLastErrorString();
        GSLog.Info("  FAILED: " + error);
    }

    GSLog.Info("  Status: " + (built ? "SUCCESS" : "FAILED"));
    GSLog.Info("");
}
```

### Company Mode Testing Pattern
If an API fails, try both modes:

```squirrel
// Attempt 1: Without company mode
local success = GSFeature.Build(tile);

if (!success) {
    // Attempt 2: With company mode
    {
        local mode = GSCompanyMode(company_id);
        success = GSFeature.Build(tile);
    }
}

if (!success) {
    // Attempt 3: With deity mode
    {
        local deity_mode = GSCompanyMode(GSCompany.COMPANY_INVALID);
        success = GSFeature.Build(tile);
    }
}
```

---

## Useful Helper Functions

### Get Test Tile
```squirrel
function GetTestTile(x_offset, y_offset) {
    local map_x = GSMap.GetMapSizeX();
    local map_y = GSMap.GetMapSizeY();
    local center_x = map_x / 2;
    local center_y = map_y / 2;
    return GSMap.GetTileIndex(center_x + x_offset, center_y + y_offset);
}
```

### Sleep Helper
```squirrel
function Sleep(ticks) {
    if (!GSController.GetSetting("debug_signs")) return;
    local current_tick = GSController.GetTick();
    while (GSController.GetTick() < current_tick + ticks) {
        GSController.Sleep(1);
    }
}
```

---

## Resources

- **Official API Documentation:** https://docs.openttd.org/gs-api/
- **OpenTTD Wiki:** https://wiki.openttd.org/
- **Development Forum:** https://www.tt-forums.net/
- **Discord:** OpenTTD Development Community

---

## Contributing

This document is based on systematic testing. If you discover:
- New working features
- Corrections to existing information
- Additional gotchas or edge cases

Please update this document and note the date and API version tested.

**Document Version:** 1.0
**Contributors:** Testing conducted via TreePlacer GameScript test suite
