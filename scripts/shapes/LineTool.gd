class_name LineTool
extends Node

# Helper for drawing debug lines. Use as an autoload

# Unit size cylinder pointing in the -z direction
# means we can use look_at_from_position and scale to easily place the lines
var line_z_mesh = preload("res://obj/lines/cylinder_line_z.obj")
var lines = []


func draw_3d_line(start: Vector3, end: Vector3, width: float):
	var mi = MeshInstance3D.new()
	add_child(mi)
	mi.mesh = line_z_mesh
	mi.look_at_from_position(start.lerp(end, 0.5), end, Vector3.UP)
	mi.scale = Vector3(width, width, start.distance_to(end))
	lines.append(mi)


func clear_3d_lines():
	for line in lines:
		remove_child(line)
		line.queue_free()
	lines.clear()
