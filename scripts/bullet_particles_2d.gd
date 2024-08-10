extends CPUParticles2D

func _ready():
	color.a = randf_range(0.3, 0.5)
	emitting = true
	pass

func _on_finished():
	queue_free()

