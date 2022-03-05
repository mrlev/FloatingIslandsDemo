class_name RiverTileTool
extends RefCounted

# This tool loads in exported mesh data and returns a dictionary of MeshDataTools


const RIVER_TILE_LAND =\
[
	preload("res://gltf/export/river_hex_uv2_00_land.res"),
	preload("res://gltf/export/river_hex_uv2_01_land.res"),
	preload("res://gltf/export/river_hex_uv2_02_land.res"),
	preload("res://gltf/export/river_hex_uv2_03_land.res"),
	preload("res://gltf/export/river_hex_uv2_04_land.res"),
	preload("res://gltf/export/river_hex_uv2_05_land.res"),
	preload("res://gltf/export/river_hex_uv2_06_land.res"),
	preload("res://gltf/export/river_hex_uv2_07_land.res"),
	preload("res://gltf/export/river_hex_uv2_08_land.res"),
	preload("res://gltf/export/river_hex_uv2_09_land.res"),
	preload("res://gltf/export/river_hex_uv2_10_land.res"),
	preload("res://gltf/export/river_hex_uv2_11_land.res"),
	preload("res://gltf/export/river_hex_uv2_12_land.res"),
	preload("res://gltf/export/river_hex_uv2_13_land.res"),
	preload("res://gltf/export/river_hex_uv2_14_land.res"),
	preload("res://gltf/export/river_hex_uv2_15_land.res"),
	preload("res://gltf/export/river_hex_uv2_16_land.res"),
	preload("res://gltf/export/river_hex_uv2_17_land.res"),
	preload("res://gltf/export/river_hex_uv2_18_land.res"),
	preload("res://gltf/export/river_hex_uv2_19_land.res"),
	preload("res://gltf/export/river_hex_uv2_20_land.res"),
	preload("res://gltf/export/river_hex_uv2_21_land.res"),
	preload("res://gltf/export/river_hex_uv2_22_land.res"),
	preload("res://gltf/export/river_hex_uv2_23_land.res"),
	preload("res://gltf/export/river_hex_uv2_24_land.res"),
	preload("res://gltf/export/river_hex_uv2_25_land.res"),
	preload("res://gltf/export/river_hex_uv2_26_land.res"),
	preload("res://gltf/export/river_hex_uv2_27_land.res"),
	preload("res://gltf/export/river_hex_uv2_28_land.res"),
	preload("res://gltf/export/river_hex_uv2_29_land.res"),
	preload("res://gltf/export/river_hex_uv2_30_land.res"),
	preload("res://gltf/export/river_hex_uv2_31_land.res")
]

const RIVER_TILE_WATER =\
[
	preload("res://gltf/export/river_hex_uv2_00_water.res"),
	preload("res://gltf/export/river_hex_uv2_01_water.res"),
	preload("res://gltf/export/river_hex_uv2_02_water.res"),
	preload("res://gltf/export/river_hex_uv2_03_water.res"),
	preload("res://gltf/export/river_hex_uv2_04_water.res"),
	preload("res://gltf/export/river_hex_uv2_05_water.res"),
	preload("res://gltf/export/river_hex_uv2_06_water.res"),
	preload("res://gltf/export/river_hex_uv2_07_water.res"),
	preload("res://gltf/export/river_hex_uv2_08_water.res"),
	preload("res://gltf/export/river_hex_uv2_09_water.res"),
	preload("res://gltf/export/river_hex_uv2_10_water.res"),
	preload("res://gltf/export/river_hex_uv2_11_water.res"),
	preload("res://gltf/export/river_hex_uv2_12_water.res"),
	preload("res://gltf/export/river_hex_uv2_13_water.res"),
	preload("res://gltf/export/river_hex_uv2_14_water.res"),
	preload("res://gltf/export/river_hex_uv2_15_water.res"),
	preload("res://gltf/export/river_hex_uv2_16_water.res"),
	preload("res://gltf/export/river_hex_uv2_17_water.res"),
	preload("res://gltf/export/river_hex_uv2_18_water.res"),
	preload("res://gltf/export/river_hex_uv2_19_water.res"),
	preload("res://gltf/export/river_hex_uv2_20_water.res"),
	preload("res://gltf/export/river_hex_uv2_21_water.res"),
	preload("res://gltf/export/river_hex_uv2_22_water.res"),
	preload("res://gltf/export/river_hex_uv2_23_water.res"),
	preload("res://gltf/export/river_hex_uv2_24_water.res"),
	preload("res://gltf/export/river_hex_uv2_25_water.res"),
	preload("res://gltf/export/river_hex_uv2_26_water.res"),
	preload("res://gltf/export/river_hex_uv2_27_water.res"),
	preload("res://gltf/export/river_hex_uv2_28_water.res"),
	preload("res://gltf/export/river_hex_uv2_29_water.res"),
	preload("res://gltf/export/river_hex_uv2_30_water.res"),
	preload("res://gltf/export/river_hex_uv2_31_water.res")
]


static func load_land_mesh_data() -> Dictionary:
	var data = {}
	for i in RIVER_TILE_LAND.size():
		data[i] = MeshDataTool.new()
		data[i].create_from_surface(RIVER_TILE_LAND[i], 0)
	return data


static func load_water_mesh_data() -> Dictionary:
	var data = {}
	for i in RIVER_TILE_WATER.size():
		data[i] = MeshDataTool.new()
		data[i].create_from_surface(RIVER_TILE_WATER[i], 0)
	return data
