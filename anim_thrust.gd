extends GPUParticles2D

# Relative relationship between thrust and the "size" of the particle ejection
@export var thrust_animation_scale: float = 30.0

func setAudio(on: bool) -> void:
	var thrust_audio = find_child("AudioStreamPlayer2D")
	if thrust_audio is AudioStreamPlayer2D:
		if on and thrust_audio.playing == false:
			thrust_audio.play()
		if !on and thrust_audio.playing == true:
			thrust_audio.stop()
		#thrust_audio.playing = on

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if process_material is ParticleProcessMaterial:
		var parent_thrust = (get_parent() as Body).f_own
		var planar_thrust = Vector2(parent_thrust[0], parent_thrust[1])
		var thrust_scalar = planar_thrust.length()
		if (thrust_scalar < 0.1):
			emitting = false
			setAudio(false)
			return
		else:
			emitting = true
			setAudio(true)
		# This is simply left because the node is relatively positioned to
		# its parent, and right is the 0deg rotation. If/when a ship can thrust
		# in non-forward directions, this will need updating.
		var angle = Vector2.LEFT 
		var base_veloc =  (thrust_animation_scale * thrust_scalar * delta * 60)
		process_material.initial_velocity_min = base_veloc - 5
		process_material.initial_velocity_max = base_veloc + 5
		process_material.spread = 15
		process_material.direction = Vector3(angle[0], angle[1], 0)
