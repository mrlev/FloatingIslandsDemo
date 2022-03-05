class_name IslandMultiMeshInstanceTool
extends RefCounted


const TREE_MESHES = [preload("res://meshes/trees/low_poly_tree_001.mesh"), 
					preload("res://meshes/trees/low_poly_tree_002.mesh"),
					preload("res://meshes/trees/low_poly_tree_003.mesh")]


const STONE_MESHES = [	preload("res://meshes/stones/stone_small_001.mesh"),
						preload("res://meshes/stones/stone_mid_001.mesh")]


const GRASS_MESHES = [ 	preload("res://meshes/grass/grass_001.tres"),
						preload("res://meshes/grass/grass_002.tres"),
						preload("res://meshes/grass/grass_003.tres"),
						preload("res://meshes/grass/grass_004.tres"),
						preload("res://meshes/grass/grass_005.tres") ]


static func create_multimesh(pr: Dictionary) -> MultiMesh:
	var type_name = pr["type_name"]
	var type_index = pr["type_index"]
	var transform_array = pr["transform_array"]
	var index_array = pr["index_array"]
	var instance_count = index_array.size()
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = instance_count
	mm.mesh = get_array_mesh(type_name, type_index)
	
	for i in instance_count:
		var tdi = index_array[i] * 5
		var pos = Vector3(transform_array[tdi+0], transform_array[tdi+1], transform_array[tdi+2])
		var rot = transform_array[tdi+3]
		var scale = Vector3(transform_array[tdi+4], transform_array[tdi+4], transform_array[tdi+4])
		mm.set_instance_transform( i, Transform3D(Basis().rotated(Vector3.DOWN, rot).scaled(scale), pos) )
	return mm


static func get_array_mesh(type_name, type_index) -> ArrayMesh:
	match type_name:
		"trees":
			return TREE_MESHES[type_index]
		"stones":
			return STONE_MESHES[type_index]
		"grass":
			return GRASS_MESHES[type_index]
	assert(0)
	return null
