import numpy as np
import json
import math
import sys
import time
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures

# --- CHECK FOR REQUESTS LIBRARY ---
try:
    import requests
except ImportError:
    print("ERROR: The 'requests' library is required for this script.")
    print("Please install it by running: py -m pip install requests")
    sys.exit()
# ----------------------------------


# --- USER SETTINGS ---

# CRITICAL: Your GeoNames username.
GEONAMES_USERNAME = ""

# How many times to split the bounding box.
GRID_DIVISIONS = 2

# Set the maximum number of cities for the final file.
MAX_CITIES_LIMIT = 500

# Define the geographic area to search for cities
BOUNDING_BOX = {
    "north": 58.0,
    "south": 54.0,
    "east": 15.5,
    "west": 8.0
}

# --- CITY DENYLIST ---
DENYLIST_CITIES = {
    #"Malmo",
    #"Copenhagen" # Block English name if main city is "København"
}
# -----------------------------

# --- FILTERS ---
MIN_PIXEL_DISTANCE = 15
MIN_POPULATION_FILTER = 1000

# --- CITY FLAG SETTINGS ---
FORCE_ALL_CITIES_TRUE = False
CITY_POPULATION_THRESHOLD = 10000

# --- OTHER SETTINGS ---
POPULATION_DIVISOR = 15
MAP_WIDTH = 8192.0
MAP_HEIGHT = 8192.0
OUTPUT_FILENAME = "city_coordinates.json"
# ---------------------

# --- CITY OVERRIDES (PRIORITY 1) ---
CITY_OVERRIDES = [
    # {"name": "København", "pop_raw": 1396508, "city": True, "x_pixel": 4704, "y_pixel": 5850},
]
# ----------------------------------------

# --- NEW: METROPOLITAN AREAS (PRIORITY 2) ---
# Define your metro areas. The script will find and place the main city,
# then find and place all suburbs, ignoring proximity for this group.
METROPOLITAN_AREAS = [
    {
        "main_city": "København",
        "country_code": "DK",
        "suburbs": [
            "Frederiksberg", 
            "Valby", 
            "Herlev",
            "Glostrup",
            "Taastrup"
        ]
    },
    {
        "main_city": "Aarhus",
        "country_code": "DK",
        "suburbs": [
            "Brabrand",
            "Viby",
            "Højbjerg"
        ]
    },
]
# ----------------------------------------


# --- Step 1: The 27-Point Reference Data ---
# This list is now ONLY used for training the model.
reference_data = [
    {"name": "Skagen", "lat": 57.7167, "lon": 10.5833, "x": 147, "y": 3374, "pop": 7394},
    {"name": "Aalborg", "lat": 57.0480, "lon": 9.9187, "x": 1681, "y": 2573, "pop": 120700},
    {"name": "Ringkøbing", "lat": 56.0901, "lon": 8.2440, "x": 3806, "y": 540, "pop": 9773},
    {"name": "Esbjerg", "lat": 55.4703, "lon": 8.4543, "x": 5136, "y": 788, "pop": 71554},
    {"name": "Westerland (Sylt)", "lat": 54.9142, "lon": 8.3378, "x": 6337, "y": 618, "pop": 9072},
    {"name": "Sønderborg", "lat": 54.9138, "lon": 9.7923, "x": 6340, "y": 2411, "pop": 28333},
    {"name": "Odense", "lat": 55.3990, "lon": 10.3920, "x": 5298, "y": 3157, "pop": 185480},
    {"name": "Nyborg", "lat": 55.3353, "lon": 10.7425, "x": 5469, "y": 3622, "pop": 17900},
    {"name": "Maribo", "lat": 54.7759, "lon": 11.5017, "x": 6637, "y": 4507, "pop": 5786},
    {"name": "Køge", "lat": 55.4600, "lon": 12.1834, "x": 5177, "y": 5328, "pop": 38657},
    {"name": "København", "lat": 55.6800, "lon": 12.5900, "x": 4704, "y": 5803, "pop": 1396508},
    {"name": "Malmø", "lat": 55.6000, "lon": 13.0000, "x": 4894, "y": 6366, "pop": 325069},
    {"name": "Kalundborg", "lat": 55.6814, "lon": 11.0833, "x": 4683, "y": 4006, "pop": 16659},
    {"name": "Helsingborg", "lat": 56.0500, "lon": 12.7167, "x": 3893, "y": 5972, "pop": 113816},
    {"name": "Åhus", "lat": 55.9242, "lon": 14.2917, "x": 4160, "y": 7911, "pop": 9848},
    {"name": "Halmstad", "lat": 56.6739, "lon": 12.8572, "x": 2515, "y": 6164, "pop": 71422},
    {"name": "Gothenburg", "lat": 57.7000, "lon": 12.0000, "x": 183, "y": 5081, "pop": 579281},
    {"name": "Aarhus", "lat": 56.1500, "lon": 10.2167, "x": 3645, "y": 2912, "pop": 293744},
    {"name": "Grenaa", "lat": 56.4069, "lon": 10.8871, "x": 3094, "y": 3760, "pop": 14107},
    {"name": "Silkeborg", "lat": 56.1833, "lon": 9.5517, "x": 3613, "y": 2120, "pop": 51353},
    {"name": "Herning", "lat": 56.1333, "lon": 8.9833, "x": 3700, "y": 1405, "pop": 51560},
    {"name": "Ebeltoft", "lat": 56.1947, "lon": 10.6781, "x": 3572, "y": 3496, "pop": 7287},
    {"name": "Nakskov", "lat": 54.8541, "lon": 11.0333, "x": 6512, "y": 4061, "pop": 12456},
    {"name": "Varberg", "lat": 57.1056, "lon": 12.2503, "x": 1549, "y": 5418, "pop": 36323},
    {"name": "Løkken", "lat": 57.3707, "lon": 9.7175, "x": 955, "y": 2324, "pop": 1669},
    {"name": "Anderstorp", "lat": 57.2833, "lon": 13.6333, "x": 1159, "y": 7096, "pop": 4965},
    {"name": "Husum", "lat": 54.4858, "lon": 9.0524, "x": 7245, "y": 1519, "pop": 23814},
]

# --- Failsafe check for Username ---
if GEONAMES_USERNAME == "YOUR_USERNAME_HERE" or not GEONAMES_USERNAME:
    print("ERROR: Please edit the script and set your 'GEONAMES_USERNAME' at the top.")
    sys.exit()

# --- API Endpoints ---
api_search_url = "http://api.geonames.org/searchJSON"
api_tiled_url = "http://api.geonames.org/citiesJSON"


# --- Helper function for Geo Calculations ---
def calculate_pixel_coords(lat, lon, model_x, model_y, poly):
    new_geo = np.array([[lat, lon]])
    new_poly = poly.transform(new_geo)
    pred_x = model_x.predict(new_poly)[0]
    pred_y = model_y.predict(new_poly)[0]
    return pred_x, pred_y

# --- Helper function for finding city data ---
def get_city_geodata(city_name, country_code, reference_map):
    # 1. Check if it's in the reference_data (our ground truth)
    if city_name in reference_map:
        print(f"    > Found '{city_name}' in reference data.")
        city_ref = reference_map[city_name]
        return {
            "name": city_ref['name'], "pop": city_ref['pop'],
            "lat": city_ref['lat'], "lon": city_ref['lon'],
            "x_pixel": city_ref['x'], "y_pixel": city_ref['y']
        }
        
    # 2. If not, find it via the API
    print(f"    > Searching for '{city_name}' via API...")
    params = {"q": city_name, "country": country_code, "maxRows": 1, "username": GEONAMES_USERNAME}
    try:
        response = requests.get(api_search_url, params=params)
        response.raise_for_status()
        data = response.json()
        if "geonames" in data and len(data["geonames"]) > 0:
            city_api = data["geonames"][0]
            print(f"    > Found '{city_name}' via API.")
            return {
                "name": city_api['name'], "pop": city_api.get('population', 0),
                "lat": float(city_api['lat']), "lon": float(city_api['lng'])
            }
        else:
            print(f"    > ERROR: Could not find city '{city_name}' via API.")
            return None
    except Exception as e:
        print(f"    > ERROR: API call for '{city_name}' failed: {e}.")
        return None

# --- Helper function for adding to JSON ---
def add_to_final_list(city_name, pop_raw, pred_x, pred_y):
    norm_x = round(pred_x / MAP_WIDTH, 6)
    norm_y = round(pred_y / MAP_HEIGHT, 6)
    
    if not (0 <= norm_x <= 1 and 0 <= norm_y <= 1):
        print(f"  > Info: City '{city_name}' is outside map bounds (X: {norm_x}, Y: {norm_y}). Skipping.")
        return False

    is_city_flag = (FORCE_ALL_CITIES_TRUE or 
                    pop_raw > CITY_POPULATION_THRESHOLD)
    
    output_json.append({
        "name": city_name,
        "population": math.ceil(pop_raw / POPULATION_DIVISOR),
        "city": is_city_flag,
        "x": norm_x,
        "y": norm_y
    })
    kept_pixel_coords.append((pred_x, pred_y))
    processed_names.add(city_name)
    return True

# --- Step 2: Prepare Data for Training ---
print(f"Gathering training data from {len(reference_data)} reference cities...")
X_geo_list = []
Y_pixel_x = []
Y_pixel_y = []

# Build a quick lookup map for reference data
reference_map = {city['name']: city for city in reference_data}

for city in reference_data:
    X_geo_list.append([city["lat"], city["lon"]])
    Y_pixel_x.append(city["x"])
    Y_pixel_y.append(city["y"])

# --- Step 3: Create and Train the Models ---
print("Training polynomial models...")
X_geo = np.array(X_geo_list)
poly = PolynomialFeatures(degree=2, include_bias=True)
X_poly = poly.fit_transform(X_geo)

model_x = LinearRegression()
model_x.fit(X_poly, Y_pixel_x)

model_y = LinearRegression()
model_y.fit(X_poly, Y_pixel_y)
print("Models trained successfully.\n")

# --- Step 4: Process City Overrides (Priority 1) ---
print(f"Processing {len(CITY_OVERRIDES)} user override cities...")
output_json = []
kept_pixel_coords = []
processed_names = set() # This list tracks all processed cities

for city in CITY_OVERRIDES:
    try:
        if not all(k in city for k in ("name", "pop_raw", "city", "x_pixel", "y_pixel")):
            print(f"  > ERROR: Override for '{city.get('name')}' is missing required data. Skipping.")
            continue
        
        px_x = city["x_pixel"]
        px_y = city["y_pixel"]
        norm_x = round(px_x / MAP_WIDTH, 6)
        norm_y = round(px_y / MAP_HEIGHT, 6)

        if not (0 <= norm_x <= 1 and 0 <= norm_y <= 1):
             print(f"  > ERROR: Override city '{city['name']}' is outside map bounds (X: {norm_x}, Y: {norm_y}). Skipping.")
             continue

        output_json.append({
            "name": city["name"],
            "population": math.ceil(city["pop_raw"] / POPULATION_DIVISOR),
            "city": city["city"],
            "x": norm_x,
            "y": norm_y
        })
        kept_pixel_coords.append((px_x, px_y))
        processed_names.add(city["name"])
        print(f"  > Added override for '{city['name']}'.")

    except Exception as e:
        print(f"  > ERROR: Could not process override '{city.get('name', 'Unnamed City')}'. Reason: {e}")

print(f"Added {len(output_json)} override cities to the final list.\n")


# --- Step 5: Process Metropolitan Areas (Priority 2) ---
print(f"Processing {len(METROPOLITAN_AREAS)} metropolitan areas...")

for metro in METROPOLITAN_AREAS:
    main_city_name = metro["main_city"]
    print(f"  > Processing Metro: {main_city_name}")

    if main_city_name in processed_names:
        print(f"    > Info: Main city '{main_city_name}' was already added as an override. Skipping.")
        continue

    # 1. Find and Add the Main City
    main_city_data = get_city_geodata(main_city_name, metro["country_code"], reference_map)
    if not main_city_data:
        print(f"    > ERROR: Could not find main city '{main_city_name}'. Skipping metro.")
        continue

    # Get pixel data (either pre-calculated or newly calculated)
    if 'x_pixel' in main_city_data:
        pred_x, pred_y = main_city_data['x_pixel'], main_city_data['y_pixel']
    else:
        pred_x, pred_y = calculate_pixel_coords(main_city_data['lat'], main_city_data['lon'], model_x, model_y, poly)
    
    # Add the main city to the list
    if not add_to_final_list(main_city_data['name'], main_city_data['pop'], pred_x, pred_y):
        print(f"    > ERROR: Main city '{main_city_name}' is out of bounds. Skipping metro.")
        continue
    
    # 2. Find and Add Suburbs
    print(f"    > Finding {len(metro['suburbs'])} defined suburbs...")
    suburbs_added = 0
    for suburb_name in metro["suburbs"]:
        if suburb_name in processed_names:
            print(f"      > Info: Suburb '{suburb_name}' was already processed. Skipping.")
            continue
        if suburb_name in DENYLIST_CITIES:
            print(f"      > Info: Suburb '{suburb_name}' is on denylist. Skipping.")
            continue
            
        suburb_data = get_city_geodata(suburb_name, metro["country_code"], reference_map)
        if not suburb_data:
            print(f"      > ERROR: Could not find suburb '{suburb_name}'. Skipping.")
            continue
            
        # Get pixel data for suburb
        if 'x_pixel' in suburb_data:
            sub_x, sub_y = suburb_data['x_pixel'], suburb_data['y_pixel']
        else:
            sub_x, sub_y = calculate_pixel_coords(suburb_data['lat'], suburb_data['lon'], model_x, model_y, poly)

        # Force-add the suburb (no proximity check)
        if add_to_final_list(suburb_data['name'], suburb_data['pop'], sub_x, sub_y):
            print(f"      > Added suburb: {suburb_data['name']} (Pop: {suburb_data['pop']})")
            suburbs_added += 1
            
    print(f"    > Successfully added {suburbs_added} suburbs for {main_city_name}.")

print("\n")

# --- Step 6: Find All Other Cities via API (Tiled) ---
print(f"Searching for all other cities with tiled API calls (Grid: {GRID_DIVISIONS}x{GRID_DIVISIONS})...")
found_cities_api = []
denylist_skipped_count = 0

lat_step = (BOUNDING_BOX["north"] - BOUNDING_BOX["south"]) / GRID_DIVISIONS
lon_step = (BOUNDING_BOX["east"] - BOUNDING_BOX["west"]) / GRID_DIVISIONS

for i in range(GRID_DIVISIONS): # Rows (Lat)
    for j in range(GRID_DIVISIONS): # Columns (Lon)
        
        tile_north = BOUNDING_BOX["north"] - (i * lat_step)
        tile_south = BOUNDING_BOX["north"] - ((i + 1) * lat_step)
        tile_west = BOUNDING_BOX["west"] + (j * lon_step)
        tile_east = BOUNDING_BOX["west"] + ((j + 1) * lon_step)
        
        print(f"  > Fetching tile {i+1},{j+1}...")
        
        params = {
            "north": tile_north, "south": tile_south,
            "east": tile_east, "west": tile_west,
            "lang": "en", "maxRows": 1000, "username": GEONAMES_USERNAME
        }

        try:
            response = requests.get(api_tiled_url, params=params)
            response.raise_for_status() 
            data = response.json()

            if "geonames" in data:
                tile_city_count = 0
                for city in data["geonames"]:
                    population = city.get('population', 0)
                    city_name = city.get('name')

                    if not city_name:
                        continue
                    if population < MIN_POPULATION_FILTER:
                        continue
                    if city_name in DENYLIST_CITIES:
                        denylist_skipped_count += 1
                        continue
                    if city_name in processed_names:
                        continue
                    
                    found_cities_api.append({
                        "name": city_name,
                        "pop": population,
                        "lat": float(city['lat']),
                        "lon": float(city['lng'])
                    })
                    processed_names.add(city_name)
                    tile_city_count += 1
                
                print(f"    > Found {tile_city_count} new cities in this tile.")

            elif "status" in data:
                print(f"    > API ERROR for tile: {data['status']['message']} (Value: {data['status']['value']})")

            time.sleep(1.1)

        except requests.exceptions.HTTPError as http_err:
            print(f"  > HTTP ERROR: {http_err}")
        except requests.exceptions.ConnectionError as conn_err:
            print(f"  > Connection ERROR: {conn_err}")
        except Exception as e:
            print(f"  > An unexpected API error occurred in tile {i+1},{j+1}: {e}")

print(f"\nFound {len(found_cities_api)} total potential new cities from all tiles.")
if denylist_skipped_count > 0:
    print(f"Skipped {denylist_skipped_count} cities found on the denylist.")


# --- Step 7: Calculate, Filter, and Add New API Cities ---
print("\nCalculating and filtering new cities...")
calculated_cities = []
calc_skipped_bounds = 0

for city in found_cities_api:
    pred_x, pred_y = calculate_pixel_coords(city['lat'], city['lon'], model_x, model_y, poly)
    norm_x = round(pred_x / MAP_WIDTH, 6)
    norm_y = round(pred_y / MAP_HEIGHT, 6)
    
    if 0 <= norm_x <= 1 and 0 <= norm_y <= 1:
        calculated_cities.append({
            "name": city['name'],
            "pop": city['pop'],
            "pred_x": pred_x,
            "pred_y": pred_y
        })
    else:
        calc_skipped_bounds += 1

calculated_cities.sort(key=lambda c: c['pop'], reverse=True)
print(f"Sorted {len(calculated_cities)} valid new cities by population.")

# --- Step 8: Proximity Filter ---
print(f"Running proximity filter (Min Distance: {MIN_PIXEL_DISTANCE} pixels)...")
new_cities_added = 0
prox_skipped = 0

for city in calculated_cities:
    if len(output_json) >= MAX_CITIES_LIMIT:
        print(f"  > Info: Reached MAX_CITIES_LIMIT of {MAX_CITIES_LIMIT}. Stopping search.")
        break
    
    is_too_close = False
    px_a = (city['pred_x'], city['pred_y'])
    
    # Check distance against ALL cities already in our final list
    # (Overrides, Metros, and Suburbs)
    for px_b in kept_pixel_coords:
        dist = np.sqrt((px_a[0] - px_b[0])**2 + (px_a[1] - px_b[1])**2)
        if dist < MIN_PIXEL_DISTANCE:
            is_too_close = True
            prox_skipped += 1
            break
            
    if not is_too_close:
        # We can use the helper function, as it also checks bounds
        if add_to_final_list(city["name"], city["pop"], city["pred_x"], city["pred_y"]):
            new_cities_added += 1

print(f"Added {new_cities_added} new cities after proximity filter.")
print(f"Skipped {prox_skipped} new cities (too close to another city).")

# --- Step 9: Write final JSON to file ---
try:
    with open(OUTPUT_FILENAME, 'w', encoding='utf-8') as f:
        # No alphabetical sort, to preserve override/metro grouping
        json.dump(output_json, f, indent=2, ensure_ascii=False)
    
    print("\n--- Processing Complete ---")
    print(f"Successfully saved {len(output_json)} total cities to {OUTPUT_FILENAME}")
    print(f"Skipped {calc_skipped_bounds} potential new cities (out of bounds).")

except PermissionError:
    print(f"\nERROR: Permission denied. Could not write to {OUTPUT_FILENAME}.")
except Exception as e:
    print(f"\nAn unexpected error occurred: {e}")
