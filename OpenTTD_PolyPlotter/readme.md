# OpenTTD PolyPlotter

A Python tool that generates realistic city placement data for OpenTTD maps by using polynomial regression models trained on real-world geographic coordinates. This script fetches city data from the GeoNames API and converts latitude/longitude coordinates to pixel positions on an OpenTTD map.

## Features

- **Polynomial Regression Mapping**: Uses scikit-learn to train a 2nd-degree polynomial model that maps real-world coordinates to game map pixels
- **GeoNames API Integration**: Automatically fetches city data including population and coordinates
- **Intelligent City Filtering**:
  - Proximity-based filtering to prevent cities from spawning too close together
  - Population-based filtering to focus on significant settlements
  - Customizable denylist for excluding specific cities
- **Priority System**:
  1. **City Overrides**: Manually define specific cities with exact pixel coordinates
  2. **Metropolitan Areas**: Define main cities with suburbs that bypass proximity filters
  3. **API-fetched Cities**: Automatically discover cities in the bounding box
- **Tiled API Queries**: Divides large geographic areas into smaller tiles to work within API limits
- **Automatic City/Town Classification**: Flags larger cities based on population thresholds

## Requirements

### Python Version
- Python 3.6 or higher

### Dependencies
```bash
pip install numpy scikit-learn requests
```

Or install all at once:
```bash
py -m pip install numpy scikit-learn requests
```

## Setup

### 1. Get a GeoNames Account
1. Register for a free account at [geonames.org](http://www.geonames.org/login)
2. Enable the free web services on your account page
3. Note your username

### 2. Configure the Script

Open [OpenTTD_PolyPlotter.py](OpenTTD_PolyPlotter.py) and set your GeoNames username:

```python
GEONAMES_USERNAME = "your_username_here"
```

### 3. Set Your Geographic Area

Define the bounding box for the region you want to map:
https://www.latlong.net/ can be a great help with this

```python
BOUNDING_BOX = {
    "north": 58.0,
    "south": 54.0,
    "east": 15.5,
    "west": 8.0
}
```

The default values cover Denmark and southern Sweden.

## Configuration Options

### Map Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `MAP_WIDTH` | 8192.0 | Width of your OpenTTD map in pixels |
| `MAP_HEIGHT` | 8192.0 | Height of your OpenTTD map in pixels |
| `OUTPUT_FILENAME` | "city_coordinates.json" | Name of the output file |

### City Filtering

| Setting | Default | Description |
|---------|---------|-------------|
| `MAX_CITIES_LIMIT` | 500 | Maximum number of cities in the output |
| `MIN_POPULATION_FILTER` | 1000 | Minimum population for a city to be included |
| `MIN_PIXEL_DISTANCE` | 15 | Minimum distance between cities in pixels |

### City Classification

| Setting | Default | Description |
|---------|---------|-------------|
| `FORCE_ALL_CITIES_TRUE` | False | Mark all settlements as cities (vs towns) |
| `CITY_POPULATION_THRESHOLD` | 10000 | Population threshold for city classification |
| `POPULATION_DIVISOR` | 15 | Divides real population for game balance |

### API Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `GRID_DIVISIONS` | 2 | How many times to split the bounding box (2 = 2x2 = 4 tiles) |

## Advanced Features

### City Overrides (Priority 1)

Manually define specific cities with exact coordinates:

```python
CITY_OVERRIDES = [
    {
        "name": "København",
        "pop_raw": 1396508,
        "city": True,
        "x_pixel": 4704,
        "y_pixel": 5850
    },
]
```

### Metropolitan Areas (Priority 2)

Define major cities with their suburbs to ensure they all appear on the map:

```python
METROPOLITAN_AREAS = [
    {
        "main_city": "København",
        "country_code": "DK",
        "suburbs": [
            "Frederiksberg",
            "Valby",
            "Herlev"
        ]
    },
]
```

Suburbs in metropolitan areas bypass the proximity filter.

### City Denylist

Exclude specific cities from appearing:

```python
DENYLIST_CITIES = {
    "Malmo",
    "Copenhagen"  # Block English name if using Danish "København"
}
```

## Usage

### Basic Usage

1. Configure your settings (see Setup section)
2. Run the script:

```bash
python OpenTTD_PolyPlotter.py
```

Or:

```bash
py OpenTTD_PolyPlotter.py
```

3. The script will generate `city_coordinates.json` in the same directory

### Understanding the Output

The script generates a JSON file with the following structure:

```json
[
  {
    "name": "København",
    "population": 93100,
    "city": true,
    "x": 0.574219,
    "y": 0.708496
  }
]
```

- `name`: City name
- `population`: Population divided by `POPULATION_DIVISOR`
- `city`: Boolean flag (true = city, false = town)
- `x`, `y`: Normalized coordinates (0.0 to 1.0)

## How It Works

### 1. Training Phase
The script uses 27 reference cities with known lat/lon and pixel coordinates to train two polynomial regression models (one for X, one for Y).

### 2. City Processing Priority
1. **Overrides**: User-defined cities with exact coordinates
2. **Metropolitan Areas**: Main cities and their suburbs
3. **API Cities**: All other cities found in the bounding box

### 3. Filtering
- Cities are sorted by population (highest first)
- Each city is checked against the proximity filter
- Cities outside map bounds are skipped
- Processing stops when `MAX_CITIES_LIMIT` is reached

### 4. Output
The final list preserves override/metro grouping and is saved to JSON.

## Reference Data

The script includes 27 pre-calibrated reference cities covering Denmark, southern Sweden, and northern Germany. These are used exclusively for training the polynomial model and are NOT automatically added to your output unless they:
- Appear in your overrides
- Are part of a metropolitan area
- Are found by the API search

## Troubleshooting

### "ERROR: The 'requests' library is required"
Install the requests library:
```bash
py -m pip install requests
```

### "ERROR: Please edit the script and set your 'GEONAMES_USERNAME'"
You forgot to set your GeoNames username. See Setup section.

### "API ERROR: ... daily limit of credits exceeded"
You've hit the GeoNames API rate limit. Free accounts have:
- 20,000 credits per day
- 1,000 credits per hour

Try reducing `GRID_DIVISIONS` or wait for your quota to reset.

### Cities appearing in wrong locations
The polynomial model is trained on Scandinavia reference data. For other regions:
1. Update the `reference_data` list with cities from your target region
2. Ensure you have at least 20-30 well-distributed reference points
3. Adjust `BOUNDING_BOX` to match your region

### Too few/many cities
Adjust these settings:
- `MAX_CITIES_LIMIT`: Increase/decrease total cities
- `MIN_POPULATION_FILTER`: Lower to include smaller towns
- `MIN_PIXEL_DISTANCE`: Decrease to pack cities closer together

## Tips

1. **Start Small**: Test with a small bounding box first
2. **Balance the Grid**: Larger `GRID_DIVISIONS` values make more API calls but find more cities
3. **API Delays**: The script includes a 1.1-second delay between API calls to respect rate limits
4. **Population Balance**: Adjust `POPULATION_DIVISOR` to make cities grow faster/slower in-game
5. **Metro Areas**: Use metropolitan areas to ensure important city clusters appear realistically

## License

This script uses the GeoNames geographical database, which is available under a Creative Commons Attribution 4.0 License.

## Credits

- Geographic data from [GeoNames](http://www.geonames.org/)
- Designed for [OpenTTD](https://www.openttd.org/)
