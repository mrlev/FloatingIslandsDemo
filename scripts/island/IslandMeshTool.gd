class_name IslandMeshTool
extends RefCounted

# This tool takes height and water data to build the land and water meshes for the island

# We also create a list of triangles where certain game objects like trees or grass
# can be placed

const UV_GRASS = Vector2(0.516, 0.3)
const UV_DIRT = Vector2(0.391, 0.3)
const UV_RIVER = Vector2(0.172, 0.61)

const HEX_TOP_MESH_RADIUS := 0.9
const LAKE_RADIUS := 1.0
const LAKE_WATER_OFFSET := 0.01
const RIVER_SEAM_WATER_VERTICES := [Vector3(-0.066667, -0.01, 0.433013), Vector3(0.066667, -0.01, 0.433013)]


const DEBUG_DRAW_FLOW_DIRS = false
const DEBUG_DRAW_RIVER_PATHS = false


# We have created land and water meshes in Blender for the river tiles
# as these would be difficult to procedurally generate in code.
# Especially if you would want an artist to be able to tweak their appearances later!
static func create_meshes_from_data(height_data: Dictionary, water_data: Dictionary) -> Dictionary:
	var tile_data = {}
	tile_data["land"] = RiverTileTool.load_land_mesh_data()
	tile_data["water"] = RiverTileTool.load_water_mesh_data()
	
	var mesh_data = {}
	var land_mesh_data = create_island_mesh(height_data, water_data, tile_data)
	mesh_data["land_mesh"] = land_mesh_data["mesh"]
	mesh_data["mm_area_data"] = land_mesh_data["mm_area_data"]
	mesh_data["lake_mesh"] = create_lake_mesh(height_data, water_data)
	mesh_data["river_mesh"] = create_river_mesh(height_data, water_data, tile_data)
	return mesh_data

# Helpers to add triangles and quads to the surface tool arrays
static func add_triangle_to_surface_arrays(vertices, uvs, points, uv):
	uvs.append(uv)
	vertices.append(points[0])
	uvs.append(uv)
	vertices.append(points[1])
	uvs.append(uv)
	vertices.append(points[2])


static func add_quad_to_surface_arrays(vertices, uvs, points, uv):
	uvs.append(uv)
	vertices.append(points[0])
	uvs.append(uv)
	vertices.append(points[1])
	uvs.append(uv)
	vertices.append(points[2])
	
	uvs.append(uv)
	vertices.append(points[0])
	uvs.append(uv)
	vertices.append(points[2])
	uvs.append(uv)
	vertices.append(points[3])


static func add_quad_to_multimesh_area(mm_area, points):
	mm_area.append(points[0])
	mm_area.append(points[1])
	mm_area.append(points[2])
	mm_area.append(points[0])
	mm_area.append(points[2])
	mm_area.append(points[3])


static func add_river_tile_land_vertices(vertices, uvs, tile_data: MeshDataTool, pos, flow_dir, multimesh_area: PackedVector3Array):
	var face_count = tile_data.get_face_count()
	var t = Transform3D(Basis().rotated(Vector3.DOWN, deg2rad(60.0 * flow_dir)).scaled(Vector3(0.9, 0.9, 0.9)))
	for fi in face_count:
		var fn = tile_data.get_face_normal(fi)
		var indices := [tile_data.get_face_vertex(fi, 0), tile_data.get_face_vertex(fi, 1), tile_data.get_face_vertex(fi, 2)]
		var triangle_uvs := [tile_data.get_vertex_uv(indices[0]), tile_data.get_vertex_uv(indices[1]), tile_data.get_vertex_uv(indices[2])]
		var triangle_vertices := [	pos + (t * tile_data.get_vertex(indices[0])),
									pos + (t * tile_data.get_vertex(indices[1])),
									pos + (t * tile_data.get_vertex(indices[2]))]
									
		uvs.append_array(triangle_uvs)
		vertices.append_array(triangle_vertices)
		
		if Vector3.UP.is_equal_approx(fn):
			multimesh_area.append_array(triangle_vertices)


static func add_river_tile_water_vertices(vertices, uvs, uv2s, tile_data: MeshDataTool, pos, flow_dir):
	var face_count = tile_data.get_face_count()
	var t = Transform3D(Basis().rotated(Vector3.DOWN, deg2rad(60.0 * flow_dir)).scaled(Vector3(0.9, 0.9, 0.9)))
	for fi in face_count:
		var indices := [0,0,0]
		for fvi in 3:
			indices[fvi] = tile_data.get_face_vertex(fi, fvi)
		var face_vertices := [	pos + (t * tile_data.get_vertex(indices[0])),
								pos + (t * tile_data.get_vertex(indices[1])),
								pos + (t * tile_data.get_vertex(indices[2])),]
		var face_uv2s := [tile_data.get_vertex_uv2(indices[0]), tile_data.get_vertex_uv2(indices[1]), tile_data.get_vertex_uv2(indices[2])]
		var face_uvs := [tile_data.get_vertex_uv2(indices[0]), tile_data.get_vertex_uv2(indices[1]), tile_data.get_vertex_uv2(indices[2])]
		vertices.append_array(face_vertices)
		uvs.append_array(face_uvs)
		uv2s.append_array(face_uv2s)


static func add_hex_tile(mesh_data: Dictionary, hex_data: Dictionary):
	var vertices = mesh_data["vertices"]
	var uvs = mesh_data["uvs"]
	var river_tile_data = mesh_data["river_tile_data"]
	var multimesh_area = mesh_data["multimesh_area"]
	
	var inlet_patterns = hex_data["inlet_patterns"]
	var cube_coords = hex_data["cube_coords"]
	var height = hex_data["height"]
	var water_type = hex_data["water_type"]
	var flow_dir = hex_data["flow_dir"]
	
	var pos = HexGrid.get_hex_centre_v3(cube_coords, height)
	if water_type == HexTypes.water.river_start:
		add_river_tile_land_vertices(vertices, uvs, river_tile_data[0], pos, flow_dir, multimesh_area)
	elif water_type == HexTypes.water.river_path or water_type == HexTypes.water.river_end:
		if inlet_patterns.has(cube_coords):
			var pattern = inlet_patterns[cube_coords]
			if river_tile_data.has(pattern):
				add_river_tile_land_vertices(vertices, uvs, river_tile_data[pattern], pos, flow_dir, multimesh_area)
	elif water_type == HexTypes.water.lake:
		var corner_vertices = HexTool.get_hex_corner_vertices(pos, HEX_TOP_MESH_RADIUS)
		for i in 6:
			var points := [pos - Vector3(0.0, 0.05, 0.0), corner_vertices[i], corner_vertices[(i+1)%6]]
			add_triangle_to_surface_arrays(vertices, uvs, points, UV_DIRT)
	else:
		var corner_vertices = HexTool.get_hex_corner_vertices(pos, HEX_TOP_MESH_RADIUS)
		for i in 6:
			var points := [pos, corner_vertices[i], corner_vertices[(i+1)%6]]
			add_triangle_to_surface_arrays(vertices, uvs, points, UV_GRASS)
			multimesh_area.append_array(points)
			


static func add_river_tile_land_seam(mesh_data: Dictionary, edge_data: Dictionary):
	var vertices = mesh_data["vertices"]
	var uvs = mesh_data["uvs"]
	var multimesh_area = mesh_data["multimesh_area"]
	
	var dir = edge_data["dir"]
	var pos1 = edge_data["pos1"]
	var pos2 = edge_data["pos2"]
	
	var points1 = HexTool.get_hex_triangle_vertices(pos1, HEX_TOP_MESH_RADIUS, dir)
	var points2 = HexTool.get_hex_triangle_vertices(pos2, HEX_TOP_MESH_RADIUS, (dir + 3)%6)
	
	var edge_points1 := [points1[1], points1[1].lerp(points1[2], 1.0/3.0), points1[1].lerp(points1[2], 0.5) - Vector3(0.0, 0.045, 0.0), points1[1].lerp(points1[2], 2.0/3.0), points1[2]]
	var edge_points2 := [points2[2], points2[2].lerp(points2[1], 1.0/3.0), points2[2].lerp(points2[1], 0.5) - Vector3(0.0, 0.045, 0.0), points2[2].lerp(points2[1], 2.0/3.0), points2[1]]
	
	var q1 := [edge_points1[0], edge_points2[0], edge_points2[1], edge_points1[1]]
	var q2 := [edge_points1[1], edge_points2[1], edge_points2[2], edge_points1[2]]
	var q3 := [edge_points1[2], edge_points2[2], edge_points2[3], edge_points1[3]]
	var q4 := [edge_points1[3], edge_points2[3], edge_points2[4], edge_points1[4]]
	
	add_quad_to_surface_arrays(vertices, uvs, q1, UV_GRASS)
	add_quad_to_surface_arrays(vertices, uvs, q2, UV_DIRT)
	add_quad_to_surface_arrays(vertices, uvs, q3, UV_DIRT)
	add_quad_to_surface_arrays(vertices, uvs, q4, UV_GRASS)
	
	var pos3 = null
	var point3 = null
	if edge_data.has("pos3"):
		pos3 = edge_data["pos3"]
		point3 = HexTool.get_hex_corner_vertex(pos3, HEX_TOP_MESH_RADIUS, (dir+5)%6)
		add_triangle_to_surface_arrays(vertices, uvs, [points1[2], points2[1], point3], UV_GRASS)
	
	if is_equal_approx(pos1.y, pos2.y):
		add_quad_to_multimesh_area(multimesh_area, q1)
		add_quad_to_multimesh_area(multimesh_area, q4)
		
		if pos3 != null:
			if is_equal_approx(pos1.y, pos3.y):
				multimesh_area.append_array([points1[2], points2[1], point3])


static func add_river_tile_water_seam(mesh_data: Dictionary, edge_data: Dictionary):
	var vertices = mesh_data["vertices"]
	var uvs = mesh_data["uvs"]
	var uv2s = mesh_data["uv2s"]
	
	var dir = edge_data["dir"]
	var pos1 = edge_data["pos1"]
	var pos2 = edge_data["pos2"]
	var pos1_inlet = edge_data["pos1_inlet"]

	var t2 = Transform3D( Basis().rotated(Vector3.UP, dir * deg2rad(60.0)).scaled(Vector3(0.9, 0.9, 0.9)) )
	var t1 = Transform3D( Basis().rotated(Vector3.UP, float((dir+3)%6) * deg2rad(60.0)).scaled(Vector3(0.9, 0.9, 0.9)) )
	var points1 = [pos1 + (RIVER_SEAM_WATER_VERTICES[0] * t1), pos1 + (RIVER_SEAM_WATER_VERTICES[1] * t1)]
	var points2 = [pos2 + (RIVER_SEAM_WATER_VERTICES[0] * t2), pos2 + (RIVER_SEAM_WATER_VERTICES[1] * t2)]

	add_triangle_to_surface_arrays(vertices, uvs, [points1[0], points1[1], points2[0]], UV_RIVER)
	add_triangle_to_surface_arrays(vertices, uvs, [points1[0], points2[0], points2[1]], UV_RIVER)
	
	var uv2_01 = [Vector2(0.33, 0.1), Vector2(0.66, 0.1), Vector2(0.66, 0.0)]
	var uv2_02 = [Vector2(0.33, 0.1), Vector2(0.66, 0.0), Vector2(0.33, 0.0)]
	if pos1_inlet:
		for i in 3:
			uv2_01[i] = uv2_01[i].rotated(PI)
			uv2_02[i] = uv2_02[i].rotated(PI)
	
	uv2s.append_array(uv2_01)
	uv2s.append_array(uv2_02)


static func create_island_mesh(height_data: Dictionary, water_data: Dictionary, tile_data: Dictionary) -> Dictionary:
	var hex_map = height_data["hex_map"]
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	
	var water_types = water_data["water_types"]
	var flow_map = water_data["flow_map"]
	var flow_directions = water_data["flow_directions"]
	var inlet_patterns = water_data["inlet_patterns"]
	var inlet_flags = water_data["inlet_flags"]
	var lakes = water_data["lakes"]
	
	var river_tile_land = tile_data["land"]
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var multimesh_area = PackedVector3Array()
	
	var all_lake_coords = {}
	for lake in lakes:
		for cube_coords in lake:
			all_lake_coords[cube_coords] = true
	
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# add hex tops
	var mesh_data = {"vertices": vertices, "uvs": uvs, "river_tile_data": river_tile_land,
					"multimesh_area": multimesh_area}
	for cube_coords in hex_map:
		var hex_data = {	"cube_coords": cube_coords, "height": stepped_heights[height_map[cube_coords]],
						"water_type": water_types[cube_coords], "flow_dir": flow_directions[flow_map[cube_coords]],
						"inlet_patterns": inlet_patterns}
		add_hex_tile(mesh_data, hex_data)
	
	# add hex seams and corners
	var edges_visited = {}
	for cube_coords in hex_map:
		for dir in 6:
			var edge_key = HexTool.get_edge_key(cube_coords, dir)
			if not edges_visited.has(edge_key):
				edges_visited[edge_key] = true
				var adj_coords = HexGrid.get_cube_coords_in_dir(cube_coords, dir)
				var adj_coords2 = HexGrid.get_cube_coords_in_dir(cube_coords, (dir+1)%6)
				
				# add the seam along this edge
				var river_edge = false
				if inlet_flags.has(cube_coords):
					if inlet_flags[cube_coords][dir]:
						river_edge = true
						
				if inlet_flags.has(adj_coords):
					if inlet_flags[adj_coords][(dir+3)%6]:
						river_edge = true
				
				if river_edge:
					var edge_data = {"edge_key": edge_key,
									"dir": dir,
									"pos1": HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]]),
									"pos2": HexGrid.get_hex_centre_v3(adj_coords, stepped_heights[height_map[adj_coords]])}
					if hex_map.has(adj_coords2):
						edge_data["pos3"] = HexGrid.get_hex_centre_v3(adj_coords2, stepped_heights[height_map[adj_coords2]])
					add_river_tile_land_seam(mesh_data, edge_data)
				
				var lake_edge = false
				if all_lake_coords.has(cube_coords) and all_lake_coords.has(adj_coords):
					lake_edge = true
				
				if not river_edge and hex_map.has(adj_coords):
					var pos1 = HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]])
					var pos2 = HexGrid.get_hex_centre_v3(adj_coords, stepped_heights[height_map[adj_coords]])
					var points1 = HexTool.get_hex_triangle_vertices(pos1, HEX_TOP_MESH_RADIUS, dir)
					var points2 = HexTool.get_hex_triangle_vertices(pos2, HEX_TOP_MESH_RADIUS, (dir + 3)%6)
					var quad_points := [points1[1], points2[2], points2[1], points1[2]]
					add_quad_to_surface_arrays(vertices, uvs, quad_points, UV_GRASS)
					
					if not lake_edge and is_equal_approx(pos1.y, pos2.y):
						add_quad_to_multimesh_area(multimesh_area, quad_points)
					
					# check the corner at the end of this edge and add
					if hex_map.has(adj_coords2):
						var pos3 = HexGrid.get_hex_centre_v3(adj_coords2, stepped_heights[height_map[adj_coords2]])
						var point3 = HexTool.get_hex_corner_vertex(pos3, HEX_TOP_MESH_RADIUS, (dir+5)%6)
						var tri_points := [points1[2], points2[1], point3]
						add_triangle_to_surface_arrays(vertices, uvs, tri_points, UV_GRASS)
						
						if not lake_edge and is_equal_approx(pos1.y, pos3.y):
							multimesh_area.append_array(tri_points)
	
	# add bottom vertices
	var bv = height_data["bottom_vertices"]
	var bvm = height_data["bottom_vertices_map"]
	for cube_coords in hex_map:
		var centre_key = HexTool.get_vertex_key(cube_coords, -1)
		var centre_vertex = bv[bvm[centre_key]]
		var edge_vertices = []
		for dir in 6:
			var keys = HexTool.get_vertex_key_variations(cube_coords, dir)
			for key in keys:
				if bvm.has(key):
					edge_vertices.append(bv[bvm[key]])
		for dir in 6:
			var tri_points := [ centre_vertex, edge_vertices[(dir+1)%6], edge_vertices[dir] ]
			add_triangle_to_surface_arrays(vertices, uvs, tri_points, UV_DIRT)
	
	# join the top and bottom edges
	for cube_coords in hex_map:
		for dir in 6:
			var adj_coords = HexGrid.get_cube_coords_in_dir(cube_coords, dir)
			if not hex_map.has(adj_coords):
				var pos = HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]])
				var points_top = HexTool.get_hex_corner_vertices(pos, HEX_TOP_MESH_RADIUS)
				var points_bot = []
				for dir in 6:
					var keys = HexTool.get_vertex_key_variations(cube_coords, dir)
					for key in keys:
						if bvm.has(key):
							points_bot.append(bv[bvm[key]])
				
				var quad_points := [ points_top[dir], points_bot[dir], points_bot[(dir+1)%6], points_top[(dir+1)%6] ]
				add_quad_to_surface_arrays(vertices, uvs, quad_points, UV_DIRT)
				
				var next_coords = HexGrid.get_cube_coords_in_dir(cube_coords, (dir+1)%6)
				if hex_map.has(next_coords):
					var pos2 = HexGrid.get_hex_centre_v3(next_coords, stepped_heights[height_map[next_coords]])
					var next_points = HexTool.get_hex_corner_vertices(pos2, HEX_TOP_MESH_RADIUS)
					var tri_points := [points_top[(dir+1)%6], points_bot[(dir+1)%6], next_points[(dir+5)%6]]
					add_triangle_to_surface_arrays(vertices, uvs, tri_points, UV_DIRT)
					
	var tri_count = vertices.size() / 3
	if tri_count > 0:
		var index = 0
		for i in tri_count:
			st.set_uv(uvs[index])
			st.add_vertex(vertices[index])
			st.set_uv(uvs[index+1])
			st.add_vertex(vertices[index+1])
			st.set_uv(uvs[index+2])
			st.add_vertex(vertices[index+2])
			index += 3
			
		st.index()
		st.optimize_indices_for_cache()
		st.generate_normals()
		st.commit(mesh)
		
		mesh.surface_set_material(0, preload("res://materials/low_poly.material"))
		
		# get the data for the flat triangles for the multimesh areas
		var mm_area_data = get_multimesh_area_data(multimesh_area)
		
		return {"mesh": mesh, "mm_area_data": mm_area_data}
	assert(0)
	return {}


# Work out the areas and weights for the triangles in the multimesh spawning area
static func get_multimesh_area_data(triangles: PackedVector3Array) -> Dictionary:
	var data = {}
	var tri_count = triangles.size() / 3
	var index = 0
	var total_area = 0.0
	var areas = PackedFloat32Array()
	var weights = PackedFloat32Array()
	for i in tri_count:
		var points := [triangles[index+0], triangles[index+1], triangles[index+2]]
		var area = TriangleTool.get_area(points)
		areas.append(area)
		total_area += area
		index += 3
	
	var cumulative_weight = 0.0
	for i in areas.size():
		var weight = areas[i] / total_area
		cumulative_weight += weight
		weights.append(cumulative_weight)
	
	weights[weights.size()-1] = 1.0
	
	data["triangles"] = triangles
	data["weights"] = weights
	
	return data


static func create_lake_mesh(height_data: Dictionary, water_data: Dictionary) -> ArrayMesh:
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	var lakes = water_data["lakes"]
	
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var uv2s = PackedVector2Array()
	
	# add lakes
	for lake in lakes:
		for cube_coords in lake:
			var pos = HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]] + LAKE_WATER_OFFSET)
			var points = HexTool.get_hex_corner_vertices(pos, LAKE_RADIUS)
			for i in 6:
				uv2s.append(Vector2(pos.x, pos.z))
				uvs.append(UV_RIVER)
				vertices.append(pos)
				
				uv2s.append(Vector2(points[i].x, points[i].z))
				uvs.append(UV_RIVER)
				vertices.append(points[i])
				
				uv2s.append(Vector2(points[(i+1)%6].x, points[(i+1)%6].z))
				uvs.append(UV_RIVER)
				vertices.append(points[(i+1)%6]) 
	
	var tri_count = vertices.size() / 3
	if tri_count > 0:
		var index = 0
		for i in tri_count:
			st.set_uv2(uv2s[index])
			st.set_uv(uvs[index])
			st.add_vertex(vertices[index])
			
			st.set_uv2(uv2s[index+1])
			st.set_uv(uvs[index+1])
			st.add_vertex(vertices[index+1])
			
			st.set_uv2(uv2s[index+2])
			st.set_uv(uvs[index+2])
			st.add_vertex(vertices[index+2])
			index += 3
			
		st.index()
		st.optimize_indices_for_cache()
		st.generate_normals()
		st.commit(mesh)
		
		mesh.surface_set_material(0, preload("res://materials/lake/lake_water.material"))
		return mesh
		
	return null


static func create_river_mesh(height_data: Dictionary, water_data: Dictionary, tile_data) -> ArrayMesh:
	var height_map = height_data["height_map"]
	var stepped_heights = height_data["stepped_heights"]
	var water_types = water_data["water_types"]
	var flow_map = water_data["flow_map"]
	var flow_directions = water_data["flow_directions"]
	var inlet_patterns = water_data["inlet_patterns"]
	var inlet_flags = water_data["inlet_flags"]
	var river_tile_water_data = tile_data["water"]
	
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var uv2s = PackedVector2Array()
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for cube_coords in flow_map:
		var pos = HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]])
		var flow_dir = flow_directions[flow_map[cube_coords]]
		if water_types[cube_coords] == HexTypes.water.river_start:
			add_river_tile_water_vertices(vertices, uvs, uv2s, river_tile_water_data[0], pos, flow_dir)
		elif water_types[cube_coords] == HexTypes.water.river_path or water_types[cube_coords] == HexTypes.water.river_end:
			if inlet_patterns.has(cube_coords):
				var inlet_pattern = inlet_patterns[cube_coords]
				add_river_tile_water_vertices(vertices, uvs, uv2s, river_tile_water_data[inlet_pattern], pos, flow_dir)
	
	var mesh_data = {"vertices": vertices, "uvs": uvs, "uv2s": uv2s}
	var edges_visited = {}
	for cube_coords in flow_map:
		for dir in 6:
			var edge_key = HexTool.get_edge_key(cube_coords, dir)
			if not edges_visited.has(edge_key):
				edges_visited[edge_key] = true
				var adj_coords = HexGrid.get_cube_coords_in_dir(cube_coords, dir)
				# add the seam along this edge
				var river_edge = false
				var p1_inlet = false
				if inlet_flags.has(cube_coords):
					if inlet_flags[cube_coords][dir]:
						river_edge = true
						p1_inlet = true
				if inlet_flags.has(adj_coords):
					if inlet_flags[adj_coords][(dir+3)%6]:
						river_edge = true
				if river_edge:
					var edge_data = {"edge_key": edge_key,
									"dir": dir,
									"pos1": HexGrid.get_hex_centre_v3(cube_coords, stepped_heights[height_map[cube_coords]]),
									"pos2": HexGrid.get_hex_centre_v3(adj_coords, stepped_heights[height_map[adj_coords]]),
									"pos1_inlet": p1_inlet}
					add_river_tile_water_seam(mesh_data, edge_data)
	
	var tri_count = vertices.size() / 3
	if tri_count > 0:
		var index = 0
		for i in tri_count:
			st.set_uv2(uv2s[index])
			st.set_uv(uvs[index])
			st.add_vertex(vertices[index])
			
			st.set_uv2(uv2s[index+1])
			st.set_uv(uvs[index+1])
			st.add_vertex(vertices[index+1])
			
			st.set_uv2(uv2s[index+2])
			st.set_uv(uvs[index+2])
			st.add_vertex(vertices[index+2])
			index += 3
			
		st.index()
		st.optimize_indices_for_cache()
		st.generate_normals()
		st.commit(mesh)
		
		mesh.surface_set_material(0, preload("res://materials/river/river_water.material"))
		return mesh
		
	return null
