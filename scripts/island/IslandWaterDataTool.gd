class_name IslandWaterDataTool
extends RefCounted

# This tool uses height data to calculate the flow direction from each hex
# Then we use this to create a flow count per hex
# which in turn is used to create river paths and lakes

const INLET_FLAG_VALUES = [16, 8, 4, 2, 1]
const DO_RIVER_AND_LAKE_CHECKS = true


static func set_water_data(params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	set_flow_counts(params, height_data, water_data)
	set_hex_types(params, height_data, water_data)
	set_lakes(params, height_data, water_data)
	set_river_paths(params, height_data, water_data)
	set_waterfalls(params, height_data, water_data)
	if DO_RIVER_AND_LAKE_CHECKS: check_river_and_lakes(params, height_data, water_data)
	set_inlets(params, height_data, water_data)


static func get_adjacent_heights(cube_coords: Vector3i, heights_array, height_map) -> Array[float]:
	var heights: Array[float] = []
	var adj_coords = HexGrid.get_all_cube_coords_adjacent(cube_coords)
	for dir in 6:
		heights.append( heights_array[height_map[adj_coords[dir]]] )
	return heights


# If we go off the edge of the island the flow map won't contain adj_coords
# A flow value of -1 means the hex has no outgoing direction
static func get_adjacent_flow_directions(cube_coords: Vector3i, flow_directions, flow_map) -> Array[int]:
	var flow_dirs: Array[int] = [-1, -1, -1, -1, -1, -1]
	var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
	for dir in 6:
		var adj_coords = adj_coords_array[dir]
		if flow_map.has(adj_coords):
			flow_dirs[dir] = flow_directions[flow_map[adj_coords]]
	return flow_dirs


# Starting from each hex on the island, follow the flow map
# Add a count per hex for each visit
static func set_flow_counts(_params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var hex_map = height_data["hex_map"]
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	var troughs = height_data["troughs"]
	
	var flow_map = {}
	var flow_directions = PackedInt32Array()
	var flow_counts = PackedInt32Array()
	
	# unpack trough coordinates and groups
	var all_trough_coords = {}
	for i in troughs.size():
		for cube_coords in troughs[i]:
			all_trough_coords[cube_coords] = i
	
	# set the flow direction for each hex based on the heights of adjacent hexes
	# can be set to 0-5 if an adjacent hex is lower, or -1 if no valid dir is found
	for cube_coords in hex_map:
		var sh = stepped_heights[height_map[cube_coords]]
		var adjacent_stepped_heights = get_adjacent_heights(cube_coords, stepped_heights, height_map)
		
		# find the lowest adjacent neighbour
		var lowest = sh
		var lowest_index = -1
		for dir in 6:
			var ash = adjacent_stepped_heights[dir]
			if not is_equal_approx(ash, lowest):
				if ash < lowest:
					lowest = adjacent_stepped_heights[dir]
					lowest_index = dir
			# check for edge of island
			if lowest_index == -1:
				var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
				for dir in 6:
					var adj_coords = adj_coords_array[dir]
					if not hex_map.has(adj_coords):
						lowest_index = dir
						break
		
		flow_directions.append(lowest_index)
		flow_counts.append(0)
		flow_map[cube_coords] = flow_directions.size() - 1
	
	# set flow counts
	# starting from each hex add a count of 1 to each hex we visit
	# following the flow directions across the map
	for cube_coords in flow_map:
		var fd = flow_directions[flow_map[cube_coords]]
		var current_coords = cube_coords
		while fd != -1:
			flow_counts[flow_map[current_coords]] += 1
			current_coords = HexGrid.get_cube_coords_in_dir(current_coords, fd)
			if not flow_map.has(current_coords):
				fd = -1
				
	water_data["flow_map"] = flow_map
	water_data["flow_directions"] = flow_directions
	water_data["flow_counts"] = flow_counts


# Set the water type of each hex based on the river and lake thresholds we have set
static func set_hex_types(params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var rt = params["river_threshold"]
	var lt = params["lake_threshold"]
	
	var troughs = height_data["troughs"]
	
	var flow_map = water_data["flow_map"]
	var flow_counts = water_data["flow_counts"]
	var flow_directions = water_data["flow_directions"]
	
	# set initial river and lake hexes
	# unpack trough coordinates and groups
	var all_trough_coords = {}
	for i in troughs.size():
		for cube_coords in troughs[i]:
			all_trough_coords[cube_coords] = i
	
	var water_types = {}
	for cube_coords in flow_map:
		var fc = flow_counts[flow_map[cube_coords]]
		var fd = flow_directions[flow_map[cube_coords]]
		if fd == -1:
			var has_been_set = false
			if fc >= lt:
				if all_trough_coords.has(cube_coords):
					water_types[cube_coords] = HexTypes.water.lake
					has_been_set = true
			if not has_been_set:
				water_types[cube_coords] = HexTypes.water.none
		else:
			if fc < rt:
				water_types[cube_coords] = HexTypes.water.none
			else:
				water_types[cube_coords] = HexTypes.water.river_path
	
	water_data["water_types"] = water_types


static func set_lakes(params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var lake_spread_radius = params["lake_spread_radius"]
	var lake_external_edge_max = params["lake_external_edge_max"]
	var river_threshold = params["river_threshold"]
	
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	
	var water_types = water_data["water_types"]
	var flow_map = water_data["flow_map"]
	var flow_counts = water_data["flow_counts"]
	
	# find lake hexes and work out how far they can spread
	var lake_hexes = {}
	for cube_coords in water_types:
		if water_types[cube_coords] == HexTypes.water.lake:
			lake_hexes[cube_coords] = lake_spread_radius
	
	# check for spreading to adjacent hexes and set these to lake type
	var visited = {}
	for cube_coords in lake_hexes:
		visited[cube_coords] = true
		var radius = lake_hexes[cube_coords]
		var spread_coords = HexGrid.get_all_cube_coords_within(cube_coords, radius)
		
		var h = stepped_heights[height_map[cube_coords]]
		for sc in spread_coords:
			if height_map.has(sc):
				if not visited.has(sc):
					visited[sc] = true
					var sh = stepped_heights[height_map[sc]]
					if is_equal_approx(h, sh):
						if flow_map.has(sc):
							water_types[sc] = HexTypes.water.lake
					elif sh < h:
						if flow_map.has(sc):
							water_types[sc] = HexTypes.water.lake
	
	# create lake groups
	var lakes = []
	visited.clear()
	for cube_coords in lake_hexes:
		var lake = []
		if not visited.has(cube_coords):
			var current_coords = cube_coords
			var frontier = [current_coords]
			while frontier.size():
				current_coords = frontier.pop_back()
				if not visited.has(current_coords):
					visited[current_coords] = true
					if water_types[current_coords] == HexTypes.water.lake:
						if not lake.has(current_coords):
							lake.append(current_coords)
							var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(current_coords)
							for dir in 6:
								var adj_coords = adj_coords_array[dir]
								if water_types.has(adj_coords):
									var adj_type = water_types[adj_coords]
									if adj_type == HexTypes.water.lake:
										if not frontier.has(adj_coords):
											frontier.append(adj_coords)
		if lake.size() > 0:
			lakes.append(lake)
	
	# check for a valid size/shape/location:
	# if we have too many external edges exposed then void the lake
	var to_erase = []
	for i in lakes.size():
		var lake = lakes[i]
		var lake_size = lake.size()
		var external_edge_count = 0
		for cube_coords in lake:
			var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
			for adj_coords in adj_coords_array:
				if not flow_map.has(adj_coords):
					external_edge_count += 1
		
		# get rid of lakes which have too many external edges
		if external_edge_count > 0:
			if external_edge_count >= lake_size or external_edge_count >= lake_external_edge_max:
				for cube_coords in lake:
					var fc = flow_counts[flow_map[cube_coords]]
					if fc < river_threshold:
						water_types[cube_coords] = HexTypes.water.none
					else:
						water_types[cube_coords] = HexTypes.water.river_path
				to_erase.append(lake)
			
	for i in to_erase.size():
		lakes.erase(to_erase[i])
		
	# set the height of the lake to be 1 step lower than the lowest adjacent land
	# set flow directions of lake hexes to -1
	for i in lakes.size():
		update_lake(lakes[i], params, height_data, water_data)
	
	water_data["lakes"] = lakes


# We may alter the hexes of a lake in the future or modify the heights of adjacent hexes
# This function will go through all lakes and set their properties accordingly
static func update_lake(lake: Array, params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var height_step = params["height_step"]
	
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	
	var flow_map = water_data["flow_map"]
	var flow_directions = water_data["flow_directions"]
	var water_types = water_data["water_types"]
	
	var perimeter = {}
	var lowest = 9999999999.99
	for cube_coords in lake:
		var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
		for adj_coords in adj_coords_array:
			if not perimeter.has(adj_coords) and not lake.has(adj_coords):
				if flow_map.has(adj_coords):
					perimeter[adj_coords] = true
	
	for pc in perimeter:
		var h = stepped_heights[height_map[pc]]
		if not is_equal_approx(h, lowest):
			if h < lowest:
				lowest = h
		
	lowest -= height_step
	for cube_coords in lake:
		stepped_heights[height_map[cube_coords]] = lowest
		flow_directions[flow_map[cube_coords]] = -1
		water_types[cube_coords] = HexTypes.water.lake


# Determine which of the hexes set as the river type are valid rivers or not
# Update river and lake data
static func set_river_paths(params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var min_river_length = params["min_river_length"]
	
	var water_types = water_data["water_types"]
	var flow_map = water_data["flow_map"]
	var flow_directions = water_data["flow_directions"]
	var lakes = water_data["lakes"]
	
	# get all river coords
	var river_coords = {}
	for cube_coords in flow_map:
		var type = water_types[cube_coords]
		if HexTypes.is_river(type):
			river_coords[cube_coords] = true
	
	# find river coords where no other river hexes flow into them
	var start_points = {}
	for cube_coords in river_coords:
		var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
		var start_point = true
		for dir in 6:
			var adj_coords = adj_coords_array[dir]
			if flow_map.has(adj_coords):
				if HexTypes.is_river(water_types[adj_coords]):
					if HexGrid.get_cube_coords_in_dir(adj_coords, flow_directions[flow_map[adj_coords]]) == cube_coords:
						start_point = false
						break
		if start_point:
			start_points[cube_coords] = true
	
	# map the paths
	var river_paths = []
	for cube_coords in start_points:
		var path = [cube_coords]
		var current_coords = cube_coords
		var visited = {}
		while current_coords != null:
			if not visited.has(current_coords):
				visited[current_coords] = true
				var flow_dir = flow_directions[flow_map[current_coords]]
				if not flow_dir == -1:
					var next_coords = HexGrid.get_cube_coords_in_dir(current_coords, flow_dir)
					if flow_map.has(next_coords):
						current_coords = next_coords
						path.append(current_coords)
					else:
						current_coords = null
				else:
					current_coords = null
			else:
				current_coords = null
		
		if path.size() > min_river_length:
			river_paths.append(path)
	
	# update end of river to become a lake if applicable
	var ends_visited = {}
	for path in river_paths:
		var cube_coords = path.back()
		if water_types.has(cube_coords):
			if not water_types[cube_coords] == HexTypes.water.lake:
				if not ends_visited.has(cube_coords):
					ends_visited[cube_coords] = true

					if not is_on_perimeter(cube_coords, flow_map):
						#check if we are next to an exisiting lake or not
						var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
						var added_index = -1
						for i in lakes.size():
							var lake = lakes[i]
							if added_index != -1:
								break
							for adj_coords in adj_coords_array:
								if lake.has(adj_coords):
									lake.append(cube_coords)
									added_index = i
									break
						if added_index == -1:
							lakes.append([cube_coords])
							added_index = lakes.size() - 1

						# update the heights of the lake
						var lake = lakes[added_index]
						update_lake(lake, params, height_data, water_data)

						# remove these coords from the path
						path.pop_back()

			else:
				path.pop_back()
		else:
			path.pop_back()
	
	# update types for remaining path coords
	for path in river_paths:
		for i in path.size():
			var cube_coords = path[i]
			if i == 0:
				water_types[cube_coords] = HexTypes.water.river_start
			elif i == path.size() - 1:
				water_types[cube_coords] = HexTypes.water.river_end
			else:
				water_types[cube_coords] = HexTypes.water.river_path
	
	# clear types from non river or lakes
	var all_river_coords = {}
	for path in river_paths:
		for cube_coords in path:
			all_river_coords[cube_coords] = true
	
	for cube_coords in water_types:
		if not all_river_coords.has(cube_coords):
			if water_types[cube_coords] != HexTypes.water.lake:
				water_types[cube_coords] = HexTypes.water.none
	
	water_data["river_paths"] = river_paths


# Waterfalls occur at the edge of the island where a river flows off the map
# In Godot 4.0 we can have one particle system per island
# manually calling emit from each transform 
static func set_waterfalls(_params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	
	var river_paths = water_data["river_paths"]
	var flow_map = water_data["flow_map"]
	var flow_directions = water_data["flow_directions"]
	
	var waterfall_transforms: Array[Transform3D] = []
	for path in river_paths:
		var cube_coords = path.back()
		var flow_dir = flow_directions[flow_map[cube_coords]]
		var next_coords = HexGrid.get_cube_coords_in_dir(cube_coords, flow_dir)
		if not flow_map.has(next_coords):
			# off the edge of the map is a waterfall
			var pos = HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]])
			var points = HexTool.get_hex_triangle_vertices(pos, 0.9, flow_dir)
			var centre = points[1].lerp(points[2], 0.5)
			var t = Transform3D(Basis(Vector3.DOWN, deg2rad(-60.0 * flow_dir)), centre)
			if not waterfall_transforms.has(t):
				waterfall_transforms.append(t)
	
	water_data["waterfall_transforms"] = waterfall_transforms


# Each hex can only have one water outlet, but multiple inlets
# This gives a finite number of combinations (32) for differing inlet configurations
static func set_inlets(_params: Dictionary, _height_data: Dictionary, water_data: Dictionary):
	var river_paths = water_data["river_paths"]
	var flow_map = water_data["flow_map"]
	var flow_directions = water_data["flow_directions"]
	
	# set outlets and prepare inlet arrays
	var outlets = {}
	var inlet_flags = {}
	
	# rivers
	for path in river_paths:
		for cube_coords in path:
			if flow_map.has(cube_coords):
				var outlet_dir = flow_directions[flow_map[cube_coords]]
				if outlet_dir != -1:
					outlets[cube_coords] = outlet_dir
					var outlet_coords = HexGrid.get_cube_coords_in_dir(cube_coords, outlet_dir)
					if flow_map.has(outlet_coords):
						if not inlet_flags.has(outlet_coords):
							inlet_flags[outlet_coords] = [0, 0, 0, 0, 0, 0]
						inlet_flags[outlet_coords][(outlet_dir+3)%6] = 1
	
	# set pattern based on 5 bit product i.e. 0 - 31 possible combinations
	# this is based around which flags are present
	# going clockwise from the outlet dir
	var inlet_patterns = {}
	var visited = {}
	for cube_coords in inlet_flags:
		var pattern = 0
		var outlet_dir = flow_directions[flow_map[cube_coords]]
		if outlet_dir != -1:
			if not visited.has(cube_coords):
				visited[cube_coords] = true
				var flags = inlet_flags[cube_coords]
				for i in 5:
					var test_dir = (outlet_dir + 1 + i)%6
					if flags[test_dir]:
						pattern += INLET_FLAG_VALUES[i]
				inlet_patterns[cube_coords] = pattern
	
	water_data["outlets"] = outlets
	water_data["inlet_flags"] = inlet_flags
	water_data["inlet_patterns"] = inlet_patterns


static func is_on_perimeter(cube_coords, map) -> bool:
	var adj_coords_array = HexGrid.get_all_cube_coords_adjacent(cube_coords)
	for adj_coords in adj_coords_array:
		if not map.has(adj_coords):
			return true
	return false


# Sanity check when debugging to ensure rivers paths do not overshoot into lakes or off the edge of the hex map
static func check_river_and_lakes(_params: Dictionary, height_data: Dictionary, water_data: Dictionary):
	var hex_map = height_data["hex_map"]
	var height_map = height_data["height_map"]
	
	var lakes = water_data["lakes"]
	var river_paths = water_data["river_paths"]
	
	var all_lake_coords = {}
	var all_river_coords = {}
	var all_perimeter_coords = {}
	
	for cube_coords in height_map:
		if not hex_map.has(cube_coords):
			all_perimeter_coords[cube_coords] = true
	
	for lake in lakes:
		for cube_coords in lake:
			all_lake_coords[cube_coords] = true
	
	for path in river_paths:
		for cube_coords in path:
			all_river_coords[cube_coords] = true
	
	for cube_coords in all_river_coords:
		assert(not all_lake_coords.has(cube_coords))
		assert(not all_perimeter_coords.has(cube_coords))
