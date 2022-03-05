class_name IslandMultiMeshDataTool
extends RefCounted

# This tool takes a list of valid triangles and their area weights to create an array
# of transforms to give to the MultiMeshInstanceTool

const HEX_TOP_RADIUS := 0.35

const TREE_DENSITY := [0, 1]
const TREE_MESH_COUNT := 3
const TREE_MESH_SCALE_RANGE = [0.16, 0.24]

const STONE_DENSITY := [0, 1]
const STONE_MESH_COUNT := 2
const STONE_MESH_SCALE_RANGE = [0.1, 0.2]

const GRASS_DENSITY := [1, 5]
const GRASS_MESH_COUNT := 5
const GRASS_MESH_SCALE_RANGE = [0.2, 0.5]


static func generate_multimesh_data(rng: RandomNumberGenerator, hex_count: int, spawn_triangles: Dictionary) -> Array:
	var spawn_params = {}
	spawn_params["rng"] = rng
	spawn_params["hex_count"] = hex_count
	spawn_params["triangles"] = spawn_triangles["triangles"]
	spawn_params["weights"] = spawn_triangles["weights"]
	
	var tree_mesh_params = {}
	tree_mesh_params["type_name"] = "trees"
	tree_mesh_params["density_range"] = TREE_DENSITY
	tree_mesh_params["type_count"] = TREE_MESH_COUNT
	tree_mesh_params["scale_range"] = TREE_MESH_SCALE_RANGE
	
	var stone_mesh_params = {}
	stone_mesh_params["type_name"] = "stones"
	stone_mesh_params["density_range"] = STONE_DENSITY
	stone_mesh_params["type_count"] = STONE_MESH_COUNT
	stone_mesh_params["scale_range"] = STONE_MESH_SCALE_RANGE
	
	var grass_mesh_params = {}
	grass_mesh_params["type_name"] = "grass"
	grass_mesh_params["density_range"] = GRASS_DENSITY
	grass_mesh_params["type_count"] = GRASS_MESH_COUNT
	grass_mesh_params["scale_range"] = GRASS_MESH_SCALE_RANGE
	
	var tree_data = generate_transforms(spawn_params, tree_mesh_params)
	var stone_data = generate_transforms(spawn_params, stone_mesh_params)
	var grass_data = generate_transforms(spawn_params, grass_mesh_params)
	
	return [tree_data, stone_data, grass_data]


static func generate_transforms(pr: Dictionary, mesh_params: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = pr["rng"]
	var hex_count = pr["hex_count"]
	var triangles: PackedVector3Array = pr["triangles"]
	var weights: PackedFloat32Array = pr["weights"]
	
	var density_range = mesh_params["density_range"]
	var type_count = mesh_params["type_count"]
	var scale_range = mesh_params["scale_range"]
	
	var transform_data = PackedFloat32Array()
	var type_data = []
	for i in type_count:
		type_data.append([])
	
	var index = 0
	for hc in hex_count:
		var instance_count = rng.randi_range(density_range[0], density_range[1])
		for i in instance_count:
			
			var weight_index = weights.bsearch(rng.randf())
			var tri_index = weight_index * 3
			var points := [triangles[tri_index + 0], triangles[tri_index + 1], triangles[tri_index + 2]]
			var pos = TriangleTool.get_random_point(rng, points)
			
			var type = rng.randi_range(0, type_count - 1)
			var rot_angle = rng.randf_range(0.0, 2 * PI)
			var scale = rng.randf_range(scale_range[0], scale_range[1])
			transform_data.append_array([pos.x, pos.y, pos.z, rot_angle, scale])
			type_data[type].append(index)
			index += 1
	
	return {"transform_data": transform_data, "type_name": mesh_params["type_name"], "type_data": type_data}


static func get_stepped_height(cube_coords: Vector3i, stepped_heights, height_map) -> float:
	return stepped_heights[height_map[cube_coords]]
