# Strategic Industry Placer GameScript

An OpenTTD GameScript (v3.0) that automatically places industries near specified towns using an advanced strategy-based placement system.

## Overview

Strategic Industry Placer allows you to precisely control where industries spawn on your OpenTTD map by configuring towns, industry types, terrain preferences, and distance modifiers. Perfect for scenario creators who want specific industry layouts.

## Features

- **Strategy-Based Placement**: Choose from 11 different terrain strategies
- **Distance Control**: Place industries at specific distances from town centers (Town/Near/Mid/Far)
- **Multiple Attempts**: Automatically tries multiple strategy/distance combinations
- **Industry Clustering**: Group similar industries together (e.g., multiple farms)
- **Safe Radius Calculation**: Automatically avoids placing industries too close to neighboring towns
- **Failure Tracking**: Places signs on map for industries that failed to place
- **Detailed Logging**: Comprehensive console output for debugging

## Installation

1. Copy the `industry_placer` folder to your OpenTTD GameScripts directory:
   - **Windows**: `Documents\OpenTTD\game\`
   - **Linux**: `~/.openttd/game/`
   - **macOS**: `~/Documents/OpenTTD/game/`

2. The folder structure should look like:
   ```
   game/
   └── industry_placer/
       ├── main.nut
       ├── info.nut
       └── README.md
   ```

## Usage

### Step 1: Configure Your Towns and Industries

Edit the `GetTownIndustries()` function in [main.nut](main.nut) (lines 11-109). This is where you define which industries to place near which towns.

### Step 2: Basic Configuration Example

```squirrel
function GetTownIndustries() {
    return [
        {
            Town = "Copenhagen",
            Industries = [
                {
                    Name = "Farm",
                    Strategies = [
                        { Type = "FlatNearWater", Distance = "Any" }
                    ],
                    Amount = 2
                }
            ]
        }
    ];
}
```

### Step 3: Run in OpenTTD

1. Open OpenTTD in **Scenario Editor** mode
2. Load or create a map with the towns you've configured
3. Go to **Game Script Settings**
4. Select **Strategic Industry Placer** from the list
5. Click **Start**
6. Check the console (` key) for detailed placement logs

## Configuration Reference

### Town Configuration Object

```squirrel
{
    Town = "TownName",                    // Exact town name (case-sensitive)
    Industries = [ /* industry configs */ ],
    IgnoreHeightRequirement = false       // Optional: bypass Farm height limits
}
```

### Industry Configuration Object

```squirrel
{
    Name = "IndustryName",                // Exact industry name
    Strategies = [                        // List of placement strategies (tried in order)
        { Type = "StrategyType", Distance = "DistanceModifier" }
    ],
    Amount = 1,                           // Number of instances to place
    KeepCloseTo = false                   // Optional: cluster instances together
}
```

## Available Strategies

### Terrain-Based Strategies

| Strategy | Description | Best For |
|----------|-------------|----------|
| `NextToRoad` | Places adjacent to existing roads | Factories, Steel Mills |
| `Mountain` | Finds highest elevation areas | Coal Mines, Quarries |
| `Hills` | Locates areas with elevation changes | Iron Ore Mines, Forests |
| `Flat` | Searches for level ground | Factories, Power Plants |
| `FlatNearWater` | Flat areas within 10 tiles of water | Farms (with height limit) |
| `Lowland` | Finds lowest elevation areas | Oil Wells |
| `OnWater` | Places on water tiles | Oil Rigs |
| `Coastal` | Land within 50 tiles of water | Docks, Oil Refineries |
| `OnHouse` | Places on town house tiles | Banks, Town Buildings |
| `LevelGround` | Attempts to level terrain (3x3 area) | Last resort placement |
| `Any` | No terrain preference | Fallback option |

## Distance Modifiers

Distance is calculated from the town center with a "safe radius" that avoids neighboring towns.

| Distance | Range | Description |
|----------|-------|-------------|
| `Town` | 0-10% of safe radius | On or very near houses |
| `Near` | 10-40% of safe radius | Close to town edge |
| `Mid` | 40-70% of safe radius | Medium distance |
| `Far` | 70-98% of safe radius | Near safe radius limit |
| `Any` | All distances | Tries: Mid → Far → Near → Town |

### Multiple Distance Example

```squirrel
{
    Type = "NextToRoad",
    Distance = "Far, Mid"  // First tries Far, then Mid
}
```

## Advanced Examples

### Example 1: Multiple Strategies with Fallback

```squirrel
{
    Name = "Coal Mine",
    Strategies = [
        { Type = "Mountain", Distance = "Far" },        // Try mountains far away first
        { Type = "Hills", Distance = "Any" },           // Then any hills
        { Type = "NextToRoad", Distance = "Mid, Far" }, // Then near roads
        { Type = "Any", Distance = "Any" }              // Last resort
    ],
    Amount = 1
}
```

### Example 2: Clustered Industries

```squirrel
{
    Name = "Farm",
    Strategies = [
        { Type = "FlatNearWater", Distance = "Any" }
    ],
    Amount = 3,
    KeepCloseTo = true  // Places 2nd and 3rd farms within 15 tiles of 1st
}
```

### Example 3: Bank in Town Center

```squirrel
{
    Name = "Bank",
    Strategies = [
        { Type = "OnHouse", Distance = "Town" }
    ],
    Amount = 1
}
```

### Example 4: Farms with Height Override

```squirrel
{
    Town = "Aarhus",
    Industries = [
        {
            Name = "Farm",
            Strategies = [
                { Type = "FlatNearWater", Distance = "Any" }
            ],
            Amount = 1
        }
    ],
    IgnoreHeightRequirement = true  // Allows farms above 4 tiles elevation
}
```

## Industry Names

Use exact names as they appear in your NewGRF. Common base game industries:

- `Coal Mine`
- `Iron Ore Mine`
- `Oil Wells`
- `Oil Rig`
- `Forest`
- `Farm`
- `Factory`
- `Steel Mill`
- `Oil Refinery`
- `Power Plant`
- `Bank`
- `Water Tower`

**Tip**: Check the console output when the script starts - it lists all available industry types.

## Safe Radius Calculation

The script automatically calculates a "safe radius" for each town:
- Takes the average distance to the 4 nearest towns
- Divides by 2
- Clamped between 20-100 tiles

This prevents industries from spawning too close to neighboring towns.

## Strategy Attempt Calculation

Each strategy+distance combination calculates attempts based on range size:
```
attempts = (range_size × 2)²
```
Capped between 100-10,000 attempts per combination.

## Troubleshooting

### Industry Won't Place

1. **Check town name**: Must match exactly (case-sensitive)
2. **Check industry name**: View console for available industries
3. **Try more strategies**: Add fallback options like `{ Type = "Any", Distance = "Any" }`
4. **Check terrain**: Some industries have strict terrain requirements
5. **Review signs**: Failed industries place signs at town centers

### Console Shows "TOWN NOT FOUND"

- Verify exact town name spelling and capitalization
- Check that the town exists on your map
- View the "Listing all towns" section in console output

### "Cannot build industry" Error

- Industry type might be disabled in game settings
- NewGRF might not allow scripted placement
- Check OpenTTD's industry construction settings

## Limitations

1. **Tree Planting Disabled**: GameScripts cannot plant trees (AI-only feature)
2. **Scenario Editor Only**: Best used in Scenario Editor before gameplay
3. **One-Time Execution**: Industries are placed once at startup
4. **NewGRF Compatibility**: Some NewGRFs may restrict scripted industry placement

## Output and Logging

The script provides detailed console output:
- Lists all towns found on map
- Shows all available industry types
- Displays nearest towns and safe radius for each configured town
- Shows real-time progress for each placement attempt
- Reports success/failure for each industry
- Places signs for failed placements

## Technical Details

- **Version**: 3.0 Enhanced Strategy System
- **API Version**: 15
- **Language**: Squirrel (NUT)
- **File Structure**:
  - `main.nut`: Core logic and configuration (1,348 lines)
  - `info.nut`: Script metadata (22 lines)

## Key Functions Reference

| Function | Line | Purpose |
|----------|------|---------|
| `GetTownIndustries()` | 11 | Main configuration function |
| `Start()` | 128 | Script entry point |
| `ProcessIndustry()` | 213 | Handles single industry placement |
| `ExecuteStrategy()` | 406 | Executes specific strategy+distance |
| `GetSafePlacementRadius()` | 1293 | Calculates safe placement area |

## Tips for Best Results

1. **Order matters**: List strategies from most to least specific
2. **Always add fallback**: End with `{ Type = "Any", Distance = "Any" }`
3. **Test incrementally**: Start with one town, then expand
4. **Use console**: Monitor placement in real-time
5. **Save before running**: GameScript placement is permanent
6. **Multiple distances**: Use `"Far, Mid, Near"` to try multiple ranges

## License

MIT License

Copyright (c) 2025 Perfk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Credits

- Claude.ai
- Designed for [OpenTTD](https://www.openttd.org/)
