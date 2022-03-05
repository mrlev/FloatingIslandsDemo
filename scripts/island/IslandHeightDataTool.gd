class_name IslandHeightDataTool
extends RefCounted

# This tool creates a map of which hexes constitute the island area
# Samples noise and creates a height map for top and bottom of the island
# Marks hexes as troughs if applicable

# As we are generating a lot of vertices and height data we use PackedArrays
# as we can now pass these as references in 4.0
# and for speed/memory usage. 

# We use a dictionary to map hex coords to array indices for the different
# sample/data areas


static func generate_island_height_data(params: Dictionary) -> Dictionary:
	var data = {}
	set_hex_map(params, data)
	set_noise_samples(params, data)
	set_top_heights(params, data)
	set_bottom_heights(params, data)
	set_troughs(params, data)
	clear_temp_data(data)
	return data


# Create the initial map by "splatting" areas of coordinates in the island radius
# The height map is created one hex larger than the island for sampling adjacent heights later
# The noise map is created two hexes larger in order to have adjacent samples for the height map
static func set_hex_map(pr: Dictionary, height_data: Dictionary):
	var island_radius = pr["island_radius"]
	var splat_count = pr["splat_count"]
	var splat_radius_min = pr["splat_radius_min"]
	var splat_radius_max = pr["splat_radius_max"]
	var rng = pr["rng"]
	
	var splat_map = {}
	var noise_coords = {}
	var height_coords = {}
	
	for i in splat_count:
		var rand_pos = CircleTool.get_random_point(rng, island_radius)
		var splat_coords = HexGrid.world_pos_to_cube_coords(rand_pos)
		var splat_radius = rng.randi_range(splat_radius_min, splat_radius_max)
		
		var island_cc_array = HexGrid.get_all_cube_coords_within(splat_coords, splat_radius)
		for cube_coords in island_cc_array:
			if not splat_map.has(cube_coords):
				splat_map[cube_coords] = 1
			else:
				splat_map[cube_coords] += 1
		
		var height_cc_array = HexGrid.get_all_cube_coords_within(splat_coords, splat_radius + 1)
		for cube_coords in height_cc_array:
			if not height_coords.has(cube_coords):
				height_coords[cube_coords] = 0
		
		var noise_cc_array = HexGrid.get_all_cube_coords_within(splat_coords, splat_radius + 2)
		for cube_coords in noise_cc_array:
			if not noise_coords.has(cube_coords):
				noise_coords[cube_coords] = Vector3()
				
	height_data["splat_map"] = splat_map
	height_data["noise_coords"] = noise_coords
	height_data["height_coords"] = height_coords
	
	height_data["hex_map"] = {}
	for cube_coords in splat_map:
		height_data["hex_map"][cube_coords] = {}


static func set_noise_samples(pr: Dictionary, height_data: Dictionary):
	var noise: OpenSimplexNoise = pr["noise"]
	var noise_scale = pr["noise_scale"]
	
	var noise_coords = height_data["noise_coords"]
	var noise_sample_map = {}
	var noise_samples = PackedFloat32Array()
	
	var world_pos = pr["island_world_position"]
	
	var visited = {}
	for cube_coords in noise_coords:
		# remember to add the world position to the noise samples
		var pos = HexGrid.get_hex_centre_v3(cube_coords, 0.0)
		noise_samples.append( noise.get_noise_3dv(pos + world_pos) * noise_scale )
		noise_sample_map[ HexTool.get_vertex_key(cube_coords, -1) ] = noise_samples.size() - 1
		for dir in 6:
			var key = HexTool.get_vertex_key(cube_coords, dir)
			if not visited.has(key):
				var vertex =  HexTool.get_hex_corner_vertex(pos + world_pos, 1.0, dir)
				noise_samples.append( abs(noise.get_noise_3dv(vertex) * noise_scale) )
				noise_sample_map[key] = noise_samples.size() - 1
				visited[key] = true
	
	height_data["noise_sample_map"] = noise_sample_map
	height_data["noise_samples"] = noise_samples


static func get_noise_sample(noise_samples: PackedFloat32Array, noise_sample_map: Dictionary, cube_coords: Vector3i, dir: int) -> float:
	return noise_samples[noise_sample_map[HexTool.get_vertex_key(cube_coords, dir)]]


# Top height is determined by the number of visits in the splat map
# and noise samples from central and corner vertices
static func set_top_heights(pr: Dictionary, height_data: Dictionary):
	var splat_height_step = pr["splat_height_step"]
	
	var splat_map = height_data["splat_map"]
	var noise_sample_map = height_data["noise_sample_map"]
	var noise_samples = height_data["noise_samples"]
	var height_coords = height_data["height_coords"]
	
	var height_map = {}
	var heights = PackedFloat32Array()
	var stepped_heights = PackedFloat32Array()
	
	#noise
	for cube_coords in height_coords:
		# add noise sample heights
		var h = get_noise_sample(noise_samples, noise_sample_map, cube_coords, -1)
		for dir in 6:
			h += get_noise_sample(noise_samples, noise_sample_map, cube_coords, dir)
		h /= 7.0
		
		heights.append(h)
		height_map[cube_coords] = heights.size() - 1
	
	# splats
	for cube_coords in splat_map:
		var splat_count = splat_map[cube_coords]
		var index = height_map[cube_coords]
		heights[index] += splat_count * splat_height_step
	
	# stepped heights
	var step = 1.0 / splat_height_step
	for cube_coords in height_map:
		var h = heights[height_map[cube_coords]]
		var rh = round(h * step) / step
		stepped_heights.append(rh)
		
	height_data["height_map"] = height_map
	height_data["heights"] = heights
	height_data["stepped_heights"] = stepped_heights


# The bottom height is based on the distance of the hex to the edge of the island
static func set_bottom_heights(params: Dictionary, height_data: Dictionary):
	var rng: RandomNumberGenerator = params["rng"]
	
	var hex_map = height_data["hex_map"]
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	
	var perimeter_distances = {}
	for cube_coords in hex_map:
		var found = false
		var radius = 1
		while not found:
			var coords = HexGrid.get_all_cube_coords_in_ring(cube_coords, radius)
			for cc in coords:
				if not hex_map.has(cc):
					found = true
					perimeter_distances[cube_coords] = radius-1
			radius +=1	
	
	# create the centre vertices first
	var centres = {}
	var vertices = PackedVector3Array()
	var vertex_map = {}
	for cube_coords in hex_map:
		var centre_height = stepped_heights[ height_map[cube_coords] ]
		var pd = perimeter_distances[cube_coords]
		if pd == 0:
			centre_height -= rng.randf_range(0.5, 1.0)
		else:
			centre_height -= sqrt(pd + 0.5) * rng.randf_range(0.66, 3.0)
		centres[cube_coords] = centre_height
	
	# then the corners
	for cube_coords in hex_map:
		var pos = HexGrid.get_hex_centre_v3(cube_coords, 0.0)
		for dir in 6:
			var keys = HexTool.get_vertex_key_variations(cube_coords, dir)
			var add = true
			for key in keys:
				if vertex_map.has(key):
					add = false
			if add:
				var avg_bh = 0.0
				var divisor = 0
				for key in keys:
					var cc = Vector3i(key[0], key[1], key[2])
					if centres.has(cc):
						avg_bh += centres[cc]
					else:
						avg_bh += stepped_heights[ height_map[cube_coords] ]
					divisor += 1
				avg_bh /= divisor
					
				var bottom_height = avg_bh			
				var vertex = HexTool.get_hex_corner_vertex(Vector3(pos.x, bottom_height, pos.z), 1.0, dir)
				vertices.append(vertex)
				vertex_map[keys[0]] = vertices.size() - 1
		
		vertices.append(Vector3(pos.x, centres[cube_coords], pos.z))
		vertex_map[HexTool.get_vertex_key(cube_coords, -1)] = vertices.size() - 1
	
	height_data["bottom_vertices"] = vertices
	height_data["bottom_vertices_map"] = vertex_map


# A trough is a hex or group of hexes where no adjacent hexes are higher
static func set_troughs(_params: Dictionary, height_data: Dictionary):
	var hex_map = height_data["hex_map"]
	var height_map = height_data["height_map"] 
	var stepped_heights = height_data["stepped_heights"]
	
	var potential_troughs = {}
	var troughs = []
	
	for cube_coords in hex_map:
		var height = stepped_heights[height_map[cube_coords]]
		var adj_heights = get_adjacent_heights(cube_coords, stepped_heights, height_map)
		var is_potential_trough = true
		for dir in 6:
			if not is_equal_approx(height, adj_heights[dir]):
				if adj_heights[dir] < height:
					is_potential_trough = false
					break
				
		if is_potential_trough:
			potential_troughs[cube_coords] = true
	
	# flood fill from potential troughs to see if they are actually the lowest
	var added_coords = {}
	for cube_coords in potential_troughs:
		if not added_coords.has(cube_coords):
			var frontier = [cube_coords]
			var is_trough = true
			var visited = {}
			var coords = []
			while frontier.size():
				var current_coords = frontier.pop_back()
				if not visited.has(current_coords):
					visited[current_coords] = true
					var height = stepped_heights[height_map[current_coords]]
					var adj_heights = get_adjacent_heights(current_coords, stepped_heights, height_map)
					for dir in 6:
						if not is_equal_approx(height, adj_heights[dir]):
							if adj_heights[dir] < height:
								frontier.clear()
								is_trough = false
								break
					if is_trough:
						coords.append(current_coords)
						for dir in 6:
							if is_equal_approx(height, adj_heights[dir]):
								var adj_coords = HexGrid.get_cube_coords_in_dir(current_coords, dir)
								if hex_map.has(adj_coords):
									frontier.append(adj_coords)
								else:
									is_trough = false
									frontier.clear()
									break
			if is_trough:
				var id = troughs.size()
				for cc in coords:
					added_coords[cc] = id
				troughs.append(coords)
	
	height_data["troughs"] = troughs


static func clear_temp_data(height_data: Dictionary):
	height_data.erase("splat_map")
	height_data.erase("noise_coords")
	height_data.erase("height_coords")


static func get_adjacent_heights(cube_coords, heights_array, height_map) -> Array[float]:
	var heights: Array[float] = []
	var adj_coords = HexGrid.get_all_cube_coords_adjacent(cube_coords)
	for dir in 6:
		heights.append( heights_array[height_map[adj_coords[dir]]] )
	return heights
