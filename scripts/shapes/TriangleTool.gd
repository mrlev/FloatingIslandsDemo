class_name TriangleTool
extends RefCounted


static func get_centroid(points: Array[Vector3]) -> Vector3:
	return Vector3(	(points[0].x + points[1].x + points[2].x) / 3.0,
					(points[0].y + points[1].y + points[2].y) / 3.0,
					(points[0].z + points[1].z + points[2].z) / 3.0 )


static func get_random_point(rng: RandomNumberGenerator, points: Array[Vector3]) -> Vector3:
	return points[0] + sqrt(rng.randf()) * (-points[0] + points[1] + rng.randf() * (points[2] - points[1]))


static func get_area(points: Array[Vector3]) -> float:
	var BA = points[0] - points[1]
	var BC = points[2] - points[1]
	var P = BA.cross(BC)
	return P.length()/2
