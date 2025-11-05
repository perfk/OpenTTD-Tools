// MIT License
//
// Copyright (c) 2025 Perfk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Industry Placer GameScript - v3.0 Enhanced Strategy System
// Separated terrain strategies from distance modifiers for maximum flexibility
 

// ============================================================================
// CONFIGURATION SECTION
// Copy your GetTownIndustries() function from config.nut here
// ============================================================================

function GetTownIndustries() {
    return [
        {
            Town = "Copenhagen",
            Industries = [
                { 
                    Name = "Farm", 
                    Strategies = [
                        { Type = "NextToRoad", Distance = "Near, Mid" },
                        { Type = "FlatNearWater", Distance = "Any" }
                    ],
                    Amount = 2,
                    KeepCloseTo = true
                },
                { 
                    Name = "Coal Mine", 
                    Strategies = [
                        { Type = "NextToRoad", Distance = "Far, Mid" },
                        { Type = "Mountain", Distance = "Far" },
                        { Type = "Hills", Distance = "Any" },
                        { Type = "Flat", Distance = "Any" },
                        { Type = "LevelGround", Distance = "Any" },
                        { Type = "Any", Distance = "Any" }
                    ],
                    Amount = 1
                },
                { 
                    Name = "Bank", 
                    Strategies = [
                        { Type = "OnHouse", Distance = "Town" }
                    ],
                    Amount = 1
                },
                { 
                    Name = "Steel Mill", 
                    Strategies = [
                        { Type = "NextToRoad", Distance = "Mid" },
                        { Type = "Flat", Distance = "Any" }
                    ],
                    Amount = 1
                },
                { 
                    Name = "Factory", 
                    Strategies = [
                        { Type = "NextToRoad", Distance = "Mid" },
                        { Type = "Flat", Distance = "Any" }
                    ],
                    Amount = 1
                }
            ]
        },
        {
            Town = "Aarhus",
            Industries = [
                { 
                    Name = "Bank", 
                    Strategies = [
                        { Type = "OnHouse", Distance = "Town" }
                    ],
                    Amount = 1
                },
                { 
                    Name = "Farm", 
                    Strategies = [
                        { Type = "FlatNearWater", Distance = "Any" }
                    ],
                    Amount = 1,
                    KeepCloseTo = true
                },
                { 
                    Name = "Forest", 
                    Strategies = [
                        { Type = "Any", Distance = "Mid" }
                    ],
                    Amount = 2
                },
                { 
                    Name = "Factory", 
                    Strategies = [
                        { Type = "NextToRoad", Distance = "Mid" },
                        { Type = "Any", Distance = "Mid" }
                    ],
                    Amount = 1
                },
                { 
                    Name = "Power Plant", 
                    Strategies = [
                        { Type = "NextToRoad", Distance = "Mid" },
                        { Type = "Any", Distance = "Mid" }
                    ],
                    Amount = 1
                }
            ],
            IgnoreHeightRequirement = true
        }
        
        // ADD YOUR 500+ TOWNS HERE
    ];
}

// ============================================================================
// MAIN SCRIPT - DO NOT EDIT BELOW THIS LINE
// ============================================================================

class IndustryPlacer extends GSController {
    town_industries = null;
    failed_industries = null;
    placed_industries = null;
    
    constructor() {
        this.town_industries = GetTownIndustries();
        this.failed_industries = [];
        this.placed_industries = {};
        GSLog.Info("Configuration loaded: " + this.town_industries.len() + " towns configured");
    }
}

function IndustryPlacer::Start() {
    GSLog.Info("===========================================");
    GSLog.Info("Industry Placer - v3.0 Strategy System");
    GSLog.Info("===========================================");
    
    this.Sleep(1);
    
    // List all towns
    GSLog.Info("Listing all towns on the map:");
    local all_towns = GSTownList();
    foreach (town_id, _ in all_towns) {
        GSLog.Info("  - Town: '" + GSTown.GetName(town_id) + "' (ID: " + town_id + ")");
    }
    GSLog.Info("-------------------------------------------");
    
    // List all available industry types
    GSLog.Info("Available industry types:");
    local all_industries = GSIndustryTypeList();
    foreach (industry_type, _ in all_industries) {
        local can_build = GSIndustryType.CanBuildIndustry(industry_type);
        GSLog.Info("  - '" + GSIndustryType.GetName(industry_type) + "' (Can build: " + can_build + ")");
    }
    GSLog.Info("===========================================");
    
    // Process each town configuration
    foreach (idx, town_config in this.town_industries) {
        GSLog.Info("-------------------------------------------");
        GSLog.Info("Processing town: '" + town_config.Town + "'");
        
        local town_id = this.FindTownByName(town_config.Town);
        
        if (town_id == null) {
            GSLog.Warning("*** TOWN NOT FOUND: '" + town_config.Town + "' ***");
            continue;
        }
        
        GSLog.Info("Found town ID: " + town_id);
        
        // Calculate and display nearest towns info
        local safe_radius = this.GetSafePlacementRadius(town_id);
        this.DisplayNearestTownsInfo(town_id);
        GSLog.Info("Safe placement radius: " + safe_radius + " tiles");
        GSLog.Info("");
        
        // Place each industry
        foreach (idx2, industry_config in town_config.Industries) {
            this.ProcessIndustry(industry_config, town_id, town_config);
        }
    }
    
    GSLog.Info("===========================================");
    GSLog.Info("Industry placement complete!");
    GSLog.Info("===========================================");
    GSLog.Info("");
    
    // TREE PLANTING DISABLED
    // GameScripts cannot plant trees (AITile.PlantTree is AI-only)
    // Trees must be placed manually in Scenario Editor or by AI companies
    GSLog.Info("===========================================");
    GSLog.Info("Note: Tree planting disabled (GameScript limitation)");
    GSLog.Info("Use Scenario Editor to plant trees manually");
    GSLog.Info("===========================================");
    GSLog.Info("");
    
    // Place signs for failed industries
    if (this.failed_industries.len() > 0) {
        GSLog.Info("===========================================");
        GSLog.Info("Placing signs for failed industries...");
        GSLog.Info("===========================================");
        
        foreach (fail_info in this.failed_industries) {
            this.PlaceFailureSign(fail_info.town_id, fail_info.town_name, fail_info.industry_name);
        }
        
        GSLog.Info("Placed " + this.failed_industries.len() + " signs for manual placement");
    }
    
    while (true) {
        this.Sleep(74);
    }
}

/**
 * Process a single industry with new strategy system
 */
function IndustryPlacer::ProcessIndustry(industry_config, town_id, town_config) {
    local industry_name = industry_config.Name;
    local amount = ("Amount" in industry_config) ? industry_config.Amount : 1;
    local keep_close_to = ("KeepCloseTo" in industry_config) ? industry_config.KeepCloseTo : false;
    
    // Default strategy if none specified
    local strategies = ("Strategies" in industry_config) ? 
        industry_config.Strategies : 
        [{ Type = "Any", Distance = "Mid" }];
    
    // Count total combinations
    local total_combinations = this.CountStrategyCombinations(strategies);
    
    GSLog.Info("  Industry: '" + industry_name + "' (amount: " + amount + ", " + total_combinations + " combinations to try)");
    
    local successes = 0;
    for (local i = 0; i < amount; i++) {
        if (amount > 1) {
            GSLog.Info("    Placing instance " + (i + 1) + " of " + amount);
        }
        
        // For clustering: after first placement, use KeepCloseTo
        local use_clustering = keep_close_to && (i > 0);
        
        local success = this.PlaceIndustryWithStrategies(
            industry_name, 
            town_id, 
            town_config.Town, 
            strategies,
            use_clustering,
            town_config
        );
        
        if (success) {
            successes++;
        }
    }
    
    // Track failures
    if (successes < amount) {
        local failures = amount - successes;
        for (local f = 0; f < failures; f++) {
            this.failed_industries.append({
                town_id = town_id,
                town_name = town_config.Town,
                industry_name = industry_name
            });
        }
    }
}

/**
 * Count total strategy combinations
 */
function IndustryPlacer::CountStrategyCombinations(strategies) {
    local count = 0;
    
    foreach (strategy in strategies) {
        local distances = this.ParseDistances(strategy.Distance);
        count += distances.len();
    }
    
    return count;
}

/**
 * Parse distance string into array
 * "Far, Mid" → ["Far", "Mid"]
 * "Any" → ["Mid", "Far", "Near", "Town"]
 */
function IndustryPlacer::ParseDistances(distance_str) {
    if (distance_str == "Any") {
        return ["Mid", "Far", "Near", "Town"];
    }
    
    // Manual parsing - Squirrel doesn't have split()
    local distances = [];
    local current = "";
    
    for (local i = 0; i < distance_str.len(); i++) {
        local char = distance_str[i];
        
        if (char == ',') {
            // Found separator, add current word if not empty
            current = this.trim(current);
            if (current.len() > 0) {
                distances.append(current);
            }
            current = "";
        } else {
            // Add character to current word
            current += char.tochar();
        }
    }
    
    // Add last word
    current = this.trim(current);
    if (current.len() > 0) {
        distances.append(current);
    }
    
    return distances;
}

/**
 * Trim whitespace from string
 */
function IndustryPlacer::trim(str) {
    local start = 0;
    local end = str.len();
    
    // Trim from start
    while (start < end && (str[start] == ' ' || str[start] == '\t' || str[start] == '\n' || str[start] == '\r')) {
        start++;
    }
    
    // Trim from end
    while (end > start && (str[end-1] == ' ' || str[end-1] == '\t' || str[end-1] == '\n' || str[end-1] == '\r')) {
        end--;
    }
    
    if (start >= end) return "";
    
    // Extract substring
    local result = "";
    for (local i = start; i < end; i++) {
        result += str[i].tochar();
    }
    
    return result;
}

/**
 * Place industry using new strategy system
 */
function IndustryPlacer::PlaceIndustryWithStrategies(industry_name, town_id, town_name, strategies, use_clustering, town_config) {
    local industry_type = this.FindIndustryTypeByName(industry_name);
    
    if (industry_type == null) {
        GSLog.Warning("      ERROR: Industry '" + industry_name + "' not found");
        return false;
    }
    
    if (!GSIndustryType.CanBuildIndustry(industry_type)) {
        GSLog.Warning("      ERROR: Cannot build '" + industry_name + "'");
        return false;
    }
    
    // Try clustering first if requested
    if (use_clustering) {
        if (this.PlaceCloseToSimilar(industry_type, industry_name, town_id, town_name)) {
            return true;
        }
        GSLog.Info("      No existing industries to cluster with, using strategies...");
    }
    
    // Try each strategy in order
    local combo_num = 0;
    foreach (strategy in strategies) {
        local strategy_type = strategy.Type;
        local distances = this.ParseDistances(strategy.Distance);
        
        foreach (distance in distances) {
            combo_num++;
            
            GSLog.Info("      [" + combo_num + "/" + this.CountStrategyCombinations(strategies) + "] " + 
                      strategy_type + " + " + distance + ": Trying...");
            
            local placed = this.ExecuteStrategy(
                industry_type,
                industry_name,
                town_id,
                town_name,
                strategy_type,
                distance,
                town_config
            );
            
            if (placed) {
                // Track for clustering
                this.TrackPlacedIndustry(industry_type, industry_name, town_id);
                return true;
            }
        }
    }
    
    GSLog.Warning("      FAILED: All " + combo_num + " strategy combinations exhausted");
    return false;
}

/**
 * Execute a single strategy + distance combination
 */
function IndustryPlacer::ExecuteStrategy(industry_type, industry_name, town_id, town_name, strategy_type, distance, town_config) {
    local safe_radius = this.GetSafePlacementRadius(town_id);
    local distance_range = this.CalculateDistanceRange(town_id, distance, safe_radius);
    local max_attempts = this.CalculateAttempts(distance_range);
    
    GSLog.Info("        Range: " + distance_range.min + "-" + distance_range.max + " tiles (" + max_attempts + " attempts)");
    
    switch (strategy_type) {
        case "NextToRoad":
            return this.Strategy_NextToRoad(industry_type, town_id, distance_range, max_attempts);
        case "Mountain":
            return this.Strategy_Mountain(industry_type, town_id, distance_range, max_attempts);
        case "Hills":
            return this.Strategy_Hills(industry_type, town_id, distance_range, max_attempts);
        case "FlatNearWater":
            return this.Strategy_FlatNearWater(industry_type, industry_name, town_id, town_name, distance_range, max_attempts, town_config);
        case "Flat":
            return this.Strategy_Flat(industry_type, town_id, distance_range, max_attempts);
        case "Lowland":
            return this.Strategy_Lowland(industry_type, town_id, distance_range, max_attempts);
        case "OnWater":
            return this.Strategy_OnWater(industry_type, town_id, distance_range, max_attempts);
        case "Coastal":
            return this.Strategy_Coastal(industry_type, town_id, distance_range, max_attempts);
        case "OnHouse":
            return this.Strategy_OnHouse(industry_type, town_id, distance_range, max_attempts);
        case "LevelGround":
            return this.Strategy_LevelGround(industry_type, town_id, distance_range, max_attempts);
        case "Any":
            return this.Strategy_Any(industry_type, town_id, distance_range, max_attempts);
        default:
            GSLog.Warning("        Unknown strategy: " + strategy_type);
            return false;
    }
}

/**
 * Calculate distance range based on distance modifier
 */
function IndustryPlacer::CalculateDistanceRange(town_id, distance, safe_radius) {
    local town_location = GSTown.GetLocation(town_id);
    
    switch (distance) {
        case "Far":
            return { 
                min = (safe_radius * 0.70).tointeger(), 
                max = (safe_radius * 0.98).tointeger(),
                center = town_location
            };
        case "Mid":
            return { 
                min = (safe_radius * 0.40).tointeger(), 
                max = (safe_radius * 0.70).tointeger(),
                center = town_location
            };
        case "Near":
            // From 40% down to edge of houses (estimate 10% or min 5 tiles)
            local house_edge = (safe_radius * 0.10).tointeger();
            if (house_edge < 5) house_edge = 5;
            return { 
                min = house_edge, 
                max = (safe_radius * 0.40).tointeger(),
                center = town_location
            };
        case "Town":
            // On houses (0-10% or specific house tiles)
            return { 
                min = 0, 
                max = (safe_radius * 0.10).tointeger(),
                center = town_location
            };
        default:
            return { 
                min = 0, 
                max = safe_radius,
                center = town_location
            };
    }
}

/**
 * Calculate attempts based on range size
 * Formula: (range_size * 2)²
 */
function IndustryPlacer::CalculateAttempts(distance_range) {
    local range_size = distance_range.max - distance_range.min;
    if (range_size < 5) range_size = 5;
    
    local attempts = (range_size * 2);
    attempts = attempts * attempts;
    
    // Cap at reasonable maximum
    if (attempts > 10000) attempts = 10000;
    if (attempts < 100) attempts = 100;
    
    return attempts;
}

/**
 * Generate random tile within distance range
 */
function IndustryPlacer::GetRandomTileInRange(center, distance_range) {
    local min_dist = distance_range.min;
    local max_dist = distance_range.max;
    
    // Generate random point in ring
    local angle = GSBase.RandRange(360) * 3.14159 / 180.0;
    local distance = min_dist + GSBase.RandRange(max_dist - min_dist);
    
    local offset_x = (distance * cos(angle)).tointeger();
    local offset_y = (distance * sin(angle)).tointeger();
    
    return GSMap.GetTileIndex(
        GSMap.GetTileX(center) + offset_x,
        GSMap.GetTileY(center) + offset_y
    );
}

// ============================================================================
// STRATEGY IMPLEMENTATIONS
// ============================================================================

/**
 * Strategy: NextToRoad
 */
function IndustryPlacer::Strategy_NextToRoad(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    local road_tiles = [];
    
    // Phase 1: Find roads in range
    GSLog.Info("        Scanning for roads...");
    for (local scan = 0; scan < max_attempts / 2; scan++) {
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        if (GSTile.HasTransportType(tile, GSTile.TRANSPORT_ROAD)) {
            road_tiles.append(tile);
        }
    }
    
    GSLog.Info("        Found " + road_tiles.len() + " road tiles, checking adjacent...");
    
    if (road_tiles.len() == 0) {
        GSLog.Info("        FAILED: No roads in range");
        return false;
    }
    
    // Phase 2: Try adjacent tiles
    local adjacent_checked = 0;
    foreach (road_tile in road_tiles) {
        for (local dx = -1; dx <= 1; dx++) {
            for (local dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) continue;
                
                adjacent_checked++;
                
                local adjacent_tile = GSMap.GetTileIndex(
                    GSMap.GetTileX(road_tile) + dx,
                    GSMap.GetTileY(road_tile) + dy
                );
                
                if (!GSMap.IsValidTile(adjacent_tile)) continue;
                if (GSTile.IsWaterTile(adjacent_tile)) continue;
                
                local closest_town = GSTile.GetClosestTown(adjacent_tile);
                if (closest_town != town_id) continue;
                
                if (GSIndustryType.BuildIndustry(industry_type, adjacent_tile)) {
                    local final_distance = GSMap.DistanceManhattan(adjacent_tile, town_location);
                    GSLog.Info("        SUCCESS! Placed " + final_distance + " tiles from center (checked " + adjacent_checked + " tiles)");
                    return true;
                }
            }
        }
    }
    
    GSLog.Info("        FAILED: Checked " + adjacent_checked + " adjacent tiles");
    return false;
}

/**
 * Strategy: Mountain (highest ground)
 */
function IndustryPlacer::Strategy_Mountain(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    local best_height = 0;
    local best_tile = null;
    
    // Phase 1: Find highest ground
    GSLog.Info("        Scanning for high ground...");
    local tiles_checked = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        local height = GSTile.GetMaxHeight(tile);
        if (height > best_height) {
            best_height = height;
            best_tile = tile;
        }
    }
    
    GSLog.Info("        Highest: " + best_height + " (checked " + tiles_checked + " tiles)");
    
    if (best_height == 0) {
        GSLog.Info("        FAILED: No elevated ground found");
        return false;
    }
    
    // Phase 2: Try to place on high ground (within 3 levels)
    GSLog.Info("        Attempting placement on height " + (best_height - 3) + "+...");
    local min_height = best_height - 3;
    local placement_attempts = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        local height = GSTile.GetMaxHeight(tile);
        if (height >= min_height) {
            placement_attempts++;
            
            if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                local final_distance = GSMap.DistanceManhattan(tile, town_location);
                GSLog.Info("        SUCCESS! Height " + height + ", " + final_distance + " tiles from center");
                return true;
            }
        }
    }
    
    GSLog.Info("        FAILED: Tried " + placement_attempts + " high tiles");
    return false;
}

/**
 * Strategy: Hills (near elevation changes)
 */
function IndustryPlacer::Strategy_Hills(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Scanning for hills...");
    local hill_tiles = 0;
    local tiles_checked = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        // Check for elevation change in adjacent tiles
        local tile_height = GSTile.GetMaxHeight(tile);
        local is_near_hill = false;
        
        for (local dx = -1; dx <= 1 && !is_near_hill; dx++) {
            for (local dy = -1; dy <= 1 && !is_near_hill; dy++) {
                if (dx == 0 && dy == 0) continue;
                
                local adj_tile = GSMap.GetTileIndex(
                    GSMap.GetTileX(tile) + dx,
                    GSMap.GetTileY(tile) + dy
                );
                
                if (GSMap.IsValidTile(adj_tile)) {
                    local adj_height = GSTile.GetMaxHeight(adj_tile);
                    if (this.abs(adj_height - tile_height) >= 2) {
                        is_near_hill = true;
                    }
                }
            }
        }
        
        if (is_near_hill) {
            hill_tiles++;
            
            if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                local final_distance = GSMap.DistanceManhattan(tile, town_location);
                GSLog.Info("        SUCCESS! Near hill, " + final_distance + " tiles from center");
                return true;
            }
        }
    }
    
    GSLog.Info("        FAILED: Found " + hill_tiles + " hill edges, checked " + tiles_checked + " tiles");
    return false;
}

/**
 * Strategy: FlatNearWater
 */
function IndustryPlacer::Strategy_FlatNearWater(industry_type, industry_name, town_id, town_name, distance_range, max_attempts, town_config) {
    local town_location = GSTown.GetLocation(town_id);
    local ignore_height = ("IgnoreHeightRequirement" in town_config) ? town_config.IgnoreHeightRequirement : false;
    
    GSLog.Info("        Scanning for flat land near water...");
    if (industry_name == "Farm" && !ignore_height) {
        GSLog.Info("        Height limit: 4 tiles above sea level");
    }
    
    local best_score = -1;
    local best_tile = null;
    local tiles_checked = 0;
    local water_tiles = 0;
    
    // Phase 1: Try near water
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        // Check height for farms
        if (industry_name == "Farm" && !ignore_height) {
            local height = GSTile.GetMinHeight(tile);
            if (height > 4) continue;
        }
        
        local flat_score = this.CalculateFlatness(tile);
        local water_distance = this.GetDistanceToWater(tile);
        
        if (water_distance < 10) {
            water_tiles++;
            local score = flat_score - (water_distance / 5.0);
            
            if (score > best_score) {
                if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                    local final_distance = GSMap.DistanceManhattan(tile, town_location);
                    GSLog.Info("        SUCCESS! Near water (dist: " + water_distance + "), " + final_distance + " from center");
                    return true;
                }
                best_score = score;
                best_tile = tile;
            }
        }
    }
    
    GSLog.Info("        FAILED: Checked " + tiles_checked + " tiles, " + water_tiles + " near water");
    return false;
}

/**
 * Strategy: Flat
 */
function IndustryPlacer::Strategy_Flat(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Scanning for flat ground...");
    local tiles_checked = 0;
    local flat_tiles = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        if (this.CalculateFlatness(tile) > 6) {
            flat_tiles++;
            
            if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                local final_distance = GSMap.DistanceManhattan(tile, town_location);
                GSLog.Info("        SUCCESS! Flat ground, " + final_distance + " tiles from center");
                return true;
            }
        }
    }
    
    GSLog.Info("        FAILED: Checked " + tiles_checked + " tiles, " + flat_tiles + " were flat");
    return false;
}

/**
 * Strategy: Lowland (lowest elevation)
 */
function IndustryPlacer::Strategy_Lowland(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    local best_height = 255;
    local best_tile = null;
    
    GSLog.Info("        Scanning for low ground...");
    local tiles_checked = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        local height = GSTile.GetMinHeight(tile);
        if (height < best_height) {
            best_height = height;
            best_tile = tile;
        }
    }
    
    GSLog.Info("        Lowest: " + best_height + " (checked " + tiles_checked + " tiles)");
    
    if (best_tile != null) {
        if (GSIndustryType.BuildIndustry(industry_type, best_tile)) {
            local final_distance = GSMap.DistanceManhattan(best_tile, town_location);
            GSLog.Info("        SUCCESS! Low ground, " + final_distance + " tiles from center");
            return true;
        }
    }
    
    GSLog.Info("        FAILED");
    return false;
}

/**
 * Strategy: OnWater (offshore)
 */
function IndustryPlacer::Strategy_OnWater(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Scanning for water tiles...");
    local tiles_checked = 0;
    local water_tiles = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (!GSTile.IsWaterTile(tile)) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        water_tiles++;
        
        if (GSIndustryType.BuildIndustry(industry_type, tile)) {
            GSLog.Info("        SUCCESS! On water, " + distance + " tiles from center");
            return true;
        }
    }
    
    GSLog.Info("        FAILED: Checked " + tiles_checked + " tiles, " + water_tiles + " were water");
    return false;
}

/**
 * Strategy: Coastal (near shore)
 */
function IndustryPlacer::Strategy_Coastal(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Scanning for coastal areas...");
    local tiles_checked = 0;
    local coastal_tiles = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        // Check if near water (<50 tiles)
        local water_dist = this.GetDistanceToWater(tile);
        if (water_dist < 50) {
            coastal_tiles++;
            
            if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                GSLog.Info("        SUCCESS! Coastal (water: " + water_dist + " tiles), " + distance + " from center");
                return true;
            }
        }
    }
    
    GSLog.Info("        FAILED: Checked " + tiles_checked + " tiles, " + coastal_tiles + " coastal");
    return false;
}

/**
 * Strategy: OnHouse (on house tiles)
 */
function IndustryPlacer::Strategy_OnHouse(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Scanning for house tiles...");
    local tiles_checked = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        // Must not be water
        if (GSTile.IsWaterTile(tile)) continue;
        
        tiles_checked++;
        
        if (GSIndustryType.BuildIndustry(industry_type, tile)) {
            GSLog.Info("        SUCCESS! Placed in town, " + distance + " tiles from center");
            return true;
        }
    }
    
    GSLog.Info("        FAILED: Checked " + tiles_checked + " tiles (town may need more houses)");
    return false;
}

/**
 * Strategy: LevelGround (level terrain if needed)
 */
function IndustryPlacer::Strategy_LevelGround(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Attempting to level ground...");
    local leveling_attempts = 0;
    
    for (local attempt = 0; attempt < max_attempts && attempt < 200; attempt++) {
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        if (GSTile.IsWaterTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        // Check if 3x3 area can be leveled
        local can_level = true;
        for (local dx = -1; dx <= 1 && can_level; dx++) {
            for (local dy = -1; dy <= 1 && can_level; dy++) {
                local check_tile = GSMap.GetTileIndex(
                    GSMap.GetTileX(tile) + dx,
                    GSMap.GetTileY(tile) + dy
                );
                
                if (!GSMap.IsValidTile(check_tile)) {
                    can_level = false;
                    continue;
                }
                
                if (GSTile.IsWaterTile(check_tile)) can_level = false;
                if (GSTile.HasTransportType(check_tile, GSTile.TRANSPORT_ROAD)) can_level = false;
                if (GSTile.HasTransportType(check_tile, GSTile.TRANSPORT_RAIL)) can_level = false;
            }
        }
        
        if (can_level) {
            leveling_attempts++;
            
            local leveled = GSTile.LevelTiles(
                GSMap.GetTileIndex(GSMap.GetTileX(tile) - 1, GSMap.GetTileY(tile) - 1),
                GSMap.GetTileIndex(GSMap.GetTileX(tile) + 1, GSMap.GetTileY(tile) + 1)
            );
            
            if (leveled) {
                if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                    local final_distance = GSMap.DistanceManhattan(tile, town_location);
                    GSLog.Info("        SUCCESS! Leveled ground, " + final_distance + " tiles from center");
                    return true;
                }
            }
        }
    }
    
    GSLog.Info("        FAILED: Attempted " + leveling_attempts + " leveling sites");
    return false;
}

/**
 * Strategy: Any (no terrain checks)
 */
function IndustryPlacer::Strategy_Any(industry_type, town_id, distance_range, max_attempts) {
    local town_location = GSTown.GetLocation(town_id);
    
    GSLog.Info("        Trying any valid tile...");
    local tiles_checked = 0;
    
    for (local attempt = 0; attempt < max_attempts; attempt++) {
        if (attempt % 1000 == 0 && attempt > 0) {
            GSLog.Info("          Progress: " + attempt + "/" + max_attempts);
        }
        
        local tile = this.GetRandomTileInRange(town_location, distance_range);
        
        if (!GSMap.IsValidTile(tile)) continue;
        
        local closest_town = GSTile.GetClosestTown(tile);
        if (closest_town != town_id) continue;
        
        local distance = GSMap.DistanceManhattan(tile, town_location);
        if (distance < distance_range.min || distance > distance_range.max) continue;
        
        tiles_checked++;
        
        if (GSIndustryType.BuildIndustry(industry_type, tile)) {
            GSLog.Info("        SUCCESS! Placed " + distance + " tiles from center");
            return true;
        }
    }
    
    GSLog.Info("        FAILED: Checked " + tiles_checked + " tiles");
    return false;
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function IndustryPlacer::FindTownByName(name) {
    local town_list = GSTownList();
    foreach (town_id, _ in town_list) {
        if (GSTown.GetName(town_id) == name) {
            return town_id;
        }
    }
    return null;
}

function IndustryPlacer::FindIndustryTypeByName(name) {
    local industry_list = GSIndustryTypeList();
    foreach (industry_type, _ in industry_list) {
        if (GSIndustryType.GetName(industry_type) == name) {
            return industry_type;
        }
    }
    return null;
}

function IndustryPlacer::PlaceCloseToSimilar(industry_type, industry_name, town_id, town_name) {
    if (!(town_id in this.placed_industries)) return false;
    if (!(industry_name in this.placed_industries[town_id])) return false;
    
    local existing_tiles = this.placed_industries[town_id][industry_name];
    if (existing_tiles.len() == 0) return false;
    
    GSLog.Info("      Clustering near " + existing_tiles.len() + " existing " + industry_name + "(s)...");
    
    local search_radius = 15;
    local max_attempts = 300;
    
    foreach (existing_tile in existing_tiles) {
        for (local attempt = 0; attempt < max_attempts; attempt++) {
            local offset_x = GSBase.RandRange(search_radius * 2) - search_radius;
            local offset_y = GSBase.RandRange(search_radius * 2) - search_radius;
            
            local tile = GSMap.GetTileIndex(
                GSMap.GetTileX(existing_tile) + offset_x,
                GSMap.GetTileY(existing_tile) + offset_y
            );
            
            if (!GSMap.IsValidTile(tile)) continue;
            if (GSTile.IsWaterTile(tile)) continue;
            
            local closest_town = GSTile.GetClosestTown(tile);
            if (closest_town != town_id) continue;
            
            if (GSIndustryType.BuildIndustry(industry_type, tile)) {
                local distance = GSMap.DistanceManhattan(tile, existing_tile);
                GSLog.Info("      SUCCESS: Clustered (distance: " + distance + " tiles)");
                return true;
            }
        }
    }
    
    return false;
}

function IndustryPlacer::TrackPlacedIndustry(industry_type, industry_name, town_id) {
    local industry_list = GSIndustryList();
    
    foreach (industry_id, _ in industry_list) {
        if (GSIndustry.GetIndustryType(industry_id) == industry_type) {
            local tile = GSIndustry.GetLocation(industry_id);
            
            if (!(town_id in this.placed_industries)) {
                this.placed_industries[town_id] <- {};
            }
            if (!(industry_name in this.placed_industries[town_id])) {
                this.placed_industries[town_id][industry_name] <- [];
            }
            
            this.placed_industries[town_id][industry_name].append(tile);
            break;
        }
    }
}

function IndustryPlacer::PlaceFailureSign(town_id, town_name, industry_name) {
    local town_location = GSTown.GetLocation(town_id);
    local sign_text = "Missing: " + industry_name;
    
    if (GSSign.BuildSign(town_location, sign_text)) {
        GSLog.Info("  Sign placed near " + town_name + ": " + sign_text);
    }
}

function IndustryPlacer::CalculateFlatness(center_tile) {
    if (!GSMap.IsValidTile(center_tile)) return 0;
    
    local center_height = GSTile.GetMaxHeight(center_tile);
    local flatness_score = 10;
    local check_radius = 2;
    
    for (local dx = -check_radius; dx <= check_radius; dx++) {
        for (local dy = -check_radius; dy <= check_radius; dy++) {
            local tile = GSMap.GetTileIndex(
                GSMap.GetTileX(center_tile) + dx,
                GSMap.GetTileY(center_tile) + dy
            );
            
            if (GSMap.IsValidTile(tile)) {
                local height_diff = this.abs(GSTile.GetMaxHeight(tile) - center_height);
                flatness_score -= height_diff;
            }
        }
    }
    
    return flatness_score;
}

function IndustryPlacer::GetDistanceToWater(center_tile) {
    if (!GSMap.IsValidTile(center_tile)) return 999;
    
    local min_distance = 999;
    local search_radius = 20;
    
    for (local dx = -search_radius; dx <= search_radius; dx++) {
        for (local dy = -search_radius; dy <= search_radius; dy++) {
            local tile = GSMap.GetTileIndex(
                GSMap.GetTileX(center_tile) + dx,
                GSMap.GetTileY(center_tile) + dy
            );
            
            if (GSMap.IsValidTile(tile) && GSTile.IsWaterTile(tile)) {
                local distance = this.abs(dx) + this.abs(dy);
                if (distance < min_distance) {
                    min_distance = distance;
                }
            }
        }
    }
    
    return min_distance;
}

function IndustryPlacer::abs(value) {
    return value < 0 ? -value : value;
}

function IndustryPlacer::DisplayNearestTownsInfo(town_id) {
    local town_location = GSTown.GetLocation(town_id);
    local town_list = GSTownList();
    local distances = [];
    
    foreach (other_town_id, _ in town_list) {
        if (other_town_id == town_id) continue;
        
        local other_location = GSTown.GetLocation(other_town_id);
        local distance = GSMap.DistanceManhattan(town_location, other_location);
        local other_name = GSTown.GetName(other_town_id);
        
        distances.append({ name = other_name, distance = distance });
    }
    
    distances.sort(function(a, b) {
        if (a.distance < b.distance) return -1;
        if (a.distance > b.distance) return 1;
        return 0;
    });
    
    local display_count = distances.len() < 4 ? distances.len() : 4;
    
    if (display_count > 0) {
        GSLog.Info("Nearest towns:");
        for (local i = 0; i < display_count; i++) {
            GSLog.Info("  " + (i + 1) + ". " + distances[i].name + " (" + distances[i].distance + " tiles)");
        }
    } else {
        GSLog.Info("No other towns on map");
    }
}

function IndustryPlacer::GetSafePlacementRadius(town_id) {
    local town_location = GSTown.GetLocation(town_id);
    local town_list = GSTownList();
    local distances = [];
    
    foreach (other_town_id, _ in town_list) {
        if (other_town_id == town_id) continue;
        
        local other_location = GSTown.GetLocation(other_town_id);
        local distance = GSMap.DistanceManhattan(town_location, other_location);
        distances.append(distance);
    }
    
    distances.sort();
    
    local towns_to_check = 4;
    if (distances.len() < towns_to_check) {
        towns_to_check = distances.len();
    }
    
    local total_distance = 0;
    for (local i = 0; i < towns_to_check; i++) {
        total_distance += distances[i];
    }
    
    if (towns_to_check == 0) {
        return 100;
    }
    
    local avg_distance = total_distance / towns_to_check;
    local safe_radius = (avg_distance / 2).tointeger();
    
    if (safe_radius < 20) safe_radius = 20;
    if (safe_radius > 100) safe_radius = 100;
    
    return safe_radius;
}

// Trigonometry helpers
function cos(angle) {
    // Simple cosine approximation
    local pi = 3.14159;
    angle = angle % (2 * pi);
    if (angle < 0) angle += 2 * pi;
    
    // Taylor series approximation
    local x2 = angle * angle;
    return 1.0 - x2/2.0 + x2*x2/24.0;
}

function sin(angle) {
    // Simple sine approximation
    local pi = 3.14159;
    return cos(angle - pi/2.0);
}
