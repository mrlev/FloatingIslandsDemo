class_name HexGrid
extends RefCounted

# HexGrid using Godot 4.0 GDScript
# Using flat topped hexes and with a negative y-axis

# As always, we stand on the shoulders of giants:
# https://www.redblobgames.com/grids/hexagons/
# https://github.com/romlok/godot-gdhexgrid

# cube coords in each direction
const DIR_N = Vector3i(0, 1, -1)
const DIR_NE = Vector3i(1, 0, -1)
const DIR_SE = Vector3i(1, -1, 0)
const DIR_S = Vector3i(0, -1, 1)
const DIR_SW = Vector3i(-1, 0, 1)
const DIR_NW = Vector3i(-1, 1, 0)
const DIR_ALL := [DIR_N, DIR_NE, DIR_SE, DIR_S, DIR_SW, DIR_NW]

# const transforms for this hex size, allowing the grid to be used without being instantiated
# e.g. cube_coords = HexGrid.world_pos_to_cube_coords(Vector3(1.0, 2.0, 3.0))
const HEX_SIZE = Vector2(1, sqrt(3)/2)
const HEX_TRANSFORM = Transform2D(Vector2(0.75, -0.433013), Vector2(0, -0.866025), Vector2(0.0, 0.0) )
const HEX_TRANSFORM_INV = Transform2D(Vector2(1.333333, -0.666667), Vector2(0, -1.154701), Vector2(0.0, 0.0) )
# if you want to change the hex size, use the following to recalculate and output the transform values:
# 	HEX_TRANSFORM = Transform2D(
#		Vector2(HEX_SIZE.x * 3/4, -HEX_SIZE.y / 2),
#		Vector2(0, -HEX_SIZE.y),
#		Vector2(0, 0)
#	)
#	HEX_TRANSFORM_INV = HEX_TRANSFORM.affine_inverse()


# grid to world pos functions
# cartesian world coords are in Vector3 format
# cube coords are in Vector3i format
# axial coords are in Vector2i format
static func world_pos_to_cube_coords(world_pos: Vector3) -> Vector3i:
	return axial_to_cube(world_pos_to_axial(world_pos))


static func get_hex_centre_v2(cube_coords: Vector3i) -> Vector2:
	return HEX_TRANSFORM * Vector2(cube_to_axial(cube_coords))


static func get_hex_centre_v3(cube_coords: Vector3i, y: float) -> Vector3:
	var v2 = get_hex_centre_v2(cube_coords)
	return Vector3(v2.x, y, v2.y)


# converting between coordinate systems
static func axial_to_cube(axial_coords: Vector2i) -> Vector3i:
	return Vector3i(axial_coords.x, axial_coords.y, -axial_coords.x - axial_coords.y)


static func cube_to_axial(cube_coords: Vector3i) -> Vector2i:
	return Vector2i(cube_coords.x, cube_coords.y)


static func world_pos_to_axial(world_pos: Vector3) -> Vector2i:
	return Vector2i( (HEX_TRANSFORM_INV * Vector2(world_pos.x, world_pos.z)).round() )


# retrieving nearby cube coords
static func get_cube_coords_in_dir(cube_coords: Vector3i, dir: int) -> Vector3i:
	return cube_coords + DIR_ALL[dir]


static func get_all_cube_coords_adjacent(cube_coords: Vector3i) -> Array[Vector3i]:
	return [	cube_coords + DIR_N, cube_coords + DIR_NE, cube_coords + DIR_SE,
			cube_coords + DIR_S, cube_coords + DIR_SW, cube_coords + DIR_NW	 ]


static func get_all_cube_coords_within(cube_coords: Vector3i, radius: int) -> Array[Vector3i]:
	var coords: Array[Vector3i] = []
	for dx in range(-radius, radius+1):
		for dy in range(max(-radius, -radius - dx), min(radius, radius - dx) + 1):
			coords.append( cube_coords + axial_to_cube(Vector2i(dx, dy)) )
	return coords


static func get_all_cube_coords_in_ring(cube_coords: Vector3i, radius: int) -> Array[Vector3i]:
	var coords: Array[Vector3i] = []
	if radius < 1:
		return [cube_coords]
	var current = cube_coords + (DIR_N * radius)
	for dir in [DIR_SE, DIR_S, DIR_SW, DIR_NW, DIR_N, DIR_NE]:
		for i in radius:
			coords.append(current)
			current = current + dir
	return coords
