class_name Island
extends Node3D

# Island node to be initialised and added to the scene tree
# Stores a copy of all parameters, data, meshes and particle data
# in case we need to update the mesh etc. later during gameplay

var id = -1
var parameters = {}
var data = {}
var mesh_instances = {}
var multimesh_instances = {}
var particle_instances = {"waterfalls": []}


func _ready():
	add_mesh_instances()


func initialise(island_data: Dictionary):
	id = island_data["id"]
	parameters = island_data["parameters"]
	data = island_data["data"]
	
	update_mesh_instance("mi_land", data["mesh_data"]["land_mesh"])
	update_mesh_instance("mi_lakes", data["mesh_data"]["lake_mesh"])
	update_mesh_instance("mi_rivers", data["mesh_data"]["river_mesh"])
	add_multimesh_instances(data["multimesh_data"])
	add_waterfall(parameters["rng"], data["water_data"]["waterfall_transforms"])


func add_mesh_instances():
	add_mesh_instance("mi_land")
	add_mesh_instance("mi_lakes")
	add_mesh_instance("mi_rivers")


func add_mesh_instance(mi_name: String):
	var mi = MeshInstance3D.new()
	mesh_instances[mi_name] = mi
	add_child(mi)


func update_mesh_instance(mi_name: String, mesh: ArrayMesh):
	mesh_instances[mi_name].mesh = mesh


func add_multimesh_instances(mm_data: Array):
	for index in mm_data.size():
		var element = mm_data[index]
		var type_name = element["type_name"]
		var type_data = element["type_data"]
		var transform_array = element["transform_data"]
		multimesh_instances[type_name] = []
		for i in type_data.size():
			var params = {"type_name": type_name, "type_index": i, "transform_array": transform_array, "index_array": type_data[i]}
			var mm: MultiMesh = IslandMultiMeshInstanceTool.create_multimesh(params)
			var mmi = MultiMeshInstance3D.new()
			mmi.multimesh = mm
			add_child(mmi)
			multimesh_instances["trees"].append(mmi)


func add_waterfall(rng, transform_data):
	if transform_data.size() > 0:
		var wf_params = {"rng": rng, "emission_transforms": transform_data}
		var scene = preload("res://scenes/particles/waterfall_particles.tscn").instantiate()
		add_child(scene)
		particle_instances["waterfalls"].append(scene)
		scene.initialise(wf_params)
