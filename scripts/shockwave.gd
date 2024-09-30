extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Messenger.shockwave.connect(spawn_wave)
	pass # Replace with function body.

func spawn_wave(uv_x:float,uv_y:float):
	var mat: ShaderMaterial = material
	mat.set_shader_parameter("center", Vector2(uv_x, uv_y))
	pass
