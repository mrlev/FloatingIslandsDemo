extends GPUParticles3D

# Manually emit waterfall and spray particles based on the array of transforms provided
var rng: RandomNumberGenerator = null
var current_index := 0
var emission_timer := 0.0
var emission_threshold := 0.0
var emission_transforms = []


func initialise(pr: Dictionary):
	rng = pr["rng"]
	emission_transforms = pr["emission_transforms"]
	var count = emission_transforms.size()
	amount *= count * lifetime
	$SprayParticles.amount *= count * $SprayParticles.lifetime
	emission_threshold = lifetime / amount


func _physics_process(delta):
	emission_timer += delta
	while emission_timer >= emission_threshold:
		var t: Transform3D = emission_transforms[current_index]
		t.origin += CircleTool.get_random_point(rng, 0.075)
		var v = rng.randf_range(process_material.initial_velocity_min, process_material.initial_velocity_max)
		var ev = process_material.direction * v * t.basis
		emit_particle(t, ev, Color.WHITE, Color.WHITE, EMIT_FLAG_POSITION | EMIT_FLAG_VELOCITY )
		$SprayParticles.emit_particle(t, ev, Color.WHITE, Color.WHITE, EMIT_FLAG_POSITION )
		emission_timer -= emission_threshold
		current_index = (current_index+1) % emission_transforms.size()
