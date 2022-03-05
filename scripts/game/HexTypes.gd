class_name HexTypes
extends RefCounted

# List all game/terrain hex type enums and helper functions
enum water { none, river_start, river_path, river_end, lake }


static func is_water(type) -> bool:
	return type != water.none


static func is_river(type) -> bool:
	return type == water.river_start or type == water.river_path or type == water.river_start


static func is_water_path(type) -> bool:
	return is_river(type)


static func is_water_body(type) -> bool:
	return type == water.lake
