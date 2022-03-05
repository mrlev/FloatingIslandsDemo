class_name HexTool
extends RefCounted

# corners
#       0   1
#       /   \
#     5      2
#       \   /
#       4   3

# edges
#         0
#    5  /   \ 1
#    4  \   / 2
#         3

# Unit hex of 0.5 radius dimensions
const HEX_CORNERS := [	Vector3(-0.25, 0.0, -0.433), Vector3( 0.25, 0.0, -0.433), Vector3( 0.5, 0.0, 0.0),
						Vector3( 0.25, 0.0,  0.433), Vector3(-0.25, 0.0,  0.433), Vector3(-0.5, 0.0, 0.0) ]


static func get_hex_corner_vertex(pos: Vector3, radius: float, dir: int) -> Vector3:
	return pos + (HEX_CORNERS[dir] * radius)


static func get_hex_corner_vertices(pos: Vector3, radius: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for i in 6:
		points.append(pos + (HEX_CORNERS[i]) * radius)
	return points


static func get_hex_triangle_vertices(pos: Vector3, radius: float, dir: int) -> Array[Vector3]:
	return [pos, pos + (HEX_CORNERS[dir] * radius),  pos + (HEX_CORNERS[(dir+1)%6] * radius)]


# Corner vertices on the hex grid can be shared by up to 3 hexagons
# This key gives each shared corner a unique id
static func get_vertex_key(cube_coords: Vector3i, dir: int) -> Array[int]:
	match dir:
		-1:
			return [cube_coords.x, cube_coords.y, cube_coords.z, -1]
		0: 
			return [cube_coords.x, cube_coords.y, cube_coords.z, 0]
		1: 
			return [cube_coords.x, cube_coords.y, cube_coords.z, 1]
		2: 
			var coords = cube_coords + HexGrid.DIR_SE
			return [coords.x, coords.y, coords.z, 0]
		3:
			var coords = cube_coords + HexGrid.DIR_S
			return [coords.x, coords.y, coords.z, 1]
		4:
			var coords = cube_coords + HexGrid.DIR_S
			return [coords.x, coords.y, coords.z, 0]
		5:
			var coords = cube_coords + HexGrid.DIR_SW
			return [coords.x, coords.y, coords.z, 1]
			
	assert(0)
	return []


# Get the possible keys for a particular vertex, as we can't always be sure
# of how or which hex we are trying to get the key from
static func get_vertex_key_variations(cube_coords: Vector3i, dir: int) -> Array:
	if dir == -1:
		return [ [cube_coords.x, cube_coords.y, cube_coords.z, -1] ]
	else:
		var coords1 = cube_coords
		var coords2 = HexGrid.get_cube_coords_in_dir(cube_coords, dir)
		var coords3 = HexGrid.get_cube_coords_in_dir(cube_coords, (dir+5)%6)
		var k1 = [coords1.x, coords1.y, coords1.z, dir]
		var k2 = [coords2.x, coords2.y, coords2.z, (dir+4)%6]
		var k3 = [coords3.x, coords3.y, coords3.z, (dir+2)%6]
		return [k1, k2, k3]


# Edges can also be given a unique id based on the adjacency and edge direction
static func get_edge_key(cube_coords: Vector3i, dir: int) -> Array[int]:
	match dir:
		0:
			return [cube_coords.x, cube_coords.y, cube_coords.z, 0]
		1:
			return [cube_coords.x, cube_coords.y, cube_coords.z, 1]
		2:
			return [cube_coords.x, cube_coords.y, cube_coords.z, 2]
		3:
			var coords = cube_coords + HexGrid.DIR_S
			return [coords.x, coords.y, coords.z, 0]
		4:
			var coords = cube_coords + HexGrid.DIR_SW
			return [coords.x, coords.y, coords.z, 1]
		5:			
			var coords = cube_coords + HexGrid.DIR_NW
			return [coords.x, coords.y, coords.z, 2]
			
	assert(0)
	return []
