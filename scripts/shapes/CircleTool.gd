class_name CircleTool
extends RefCounted


static func get_random_point(rng: RandomNumberGenerator, radius: float) -> Vector3:
	var a = rng.randf() * 2.0 * PI
	var r = radius * sqrt(rng.randf())
	return Vector3(r * cos(a), 0.0, r * sin(a))
