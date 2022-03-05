class_name IslandGenerator
extends Node3D

# The IslandGenerator acts as the editor interface for terrain generation
# Eventually this class could become a static tool and run with
# parameters generated in code or from JSON

# Currently we are generating one island at a time
# from parameters set in the editor for demo/debugging purposes

# Note that the Godot debugger does not like large datasets so stepping through
# the code for large islands can be problematic at the moment

# generator parameters
@export var enabled = true
@export var create_on_ready := true
@export var enable_particle_effects := true

# rng parameters
@onready var rng = RandomNumberGenerator.new()
@export var rng_seed = 12345

# noise parameters
@onready var noise = OpenSimplexNoise.new()
@export var noise_seed = 12345
@export var noise_period = 8
@export var noise_octaves = 3
@export var noise_lacunarity = 2
@export var noise_persistence = 0.8
@export var noise_scale = 2.0

# height map parameters
@export var island_world_position := Vector3()
@export var island_radius = 6.0
@export var splat_count := 16
@export var splat_radius_min := 2
@export var splat_radius_max := 4
@export var splat_height_step := 0.1

# water map parameters
@export var river_threshold := 4
@export var lake_threshold := 4
@export var min_river_length := 4
@export var lake_spread_radius := 1
@export var lake_external_edge_max := 5

# currently active island instance
var island_id = 0
var island_instance: Island = null

# screenshots
var ss_index = 0


func _ready():
	initialise_rng()
	initialise_noise()
	
	if create_on_ready:
		create_island()


func initialise_rng():
	rng.seed = rng_seed


func initialise_noise():
	noise.seed = noise_seed
	noise.period = noise_period
	noise.octaves = noise_octaves
	noise.lacunarity = noise_lacunarity
	noise.persistence = noise_persistence


# Run all of the tools to create the data and meshes for the island
# Initialise and add the island to the scene tree
func create_island():
	if island_instance != null:
		remove_child(island_instance)
		island_instance.queue_free() 
		island_instance = null
	
	var height_params = get_height_params()	
	var height_data = IslandHeightDataTool.generate_island_height_data(height_params)
	
	var water_params = get_water_params()	
	var water_data = {}
	IslandWaterDataTool.set_water_data(water_params, height_data, water_data)	
	
	var mesh_data = IslandMeshTool.create_meshes_from_data(height_data, water_data)
	var multimesh_data = IslandMultiMeshDataTool.generate_multimesh_data(rng, height_data["hex_map"].size(), mesh_data["mm_area_data"])
	
	# create and add instance
	var new_island = Island.new()
	add_child(new_island)
	var island_data = 	{ "id": island_id, "enable_particle_effects": enable_particle_effects,
						"parameters": {"height_params": height_params, "water_params": water_params, "rng": rng},
						"data": {"height_data": height_data, "water_data": water_data, 
						"mesh_data": mesh_data, "multimesh_data": multimesh_data },}
	new_island.initialise(island_data)
	
	island_id += 1
	island_instance = new_island


func get_height_params() -> Dictionary:
	var height_params = {}
	height_params["noise"] = noise
	height_params["noise_scale"] = noise_scale
	height_params["island_world_position"] = island_world_position
	height_params["island_radius"] = island_radius
	height_params["splat_count"] = splat_count
	height_params["splat_radius_min"] = splat_radius_min
	height_params["splat_radius_max"] = splat_radius_max
	height_params["splat_height_step"] = splat_height_step
	height_params["rng"] = rng
	return height_params


func get_water_params() -> Dictionary:
	var water_params = {}
	water_params["rng"] = rng
	water_params["river_threshold"] = river_threshold
	water_params["lake_threshold"] = lake_threshold
	water_params["min_river_length"] = min_river_length
	water_params["lake_spread_radius"] = lake_spread_radius
	water_params["lake_external_edge_max"] = lake_external_edge_max
	water_params["height_step"] = splat_height_step
	return water_params


# Input for generating a new island or taking screenshots
func _unhandled_input(_event):
	# generate new island on Spacebar
	if Input.is_action_just_pressed("ui_select"):
		generate_new_island()
	
	#take screenshot on Q
	if Input.is_action_just_pressed("ui_q"):
		var viewport_texture: ViewportTexture = get_viewport().get_texture()
		var image: Image = viewport_texture.get_image()
		var filename = "screenshot_" + str(ss_index) + ".png"
		image.save_png(filename)
		ss_index += 1


# Update seeds and generate a new island
func generate_new_island():
	noise_seed += 1
	noise.seed = noise_seed
	rng_seed += 1
	rng.seed = rng_seed
	create_island()
