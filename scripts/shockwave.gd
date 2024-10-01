extends ColorRect

var param_force:float = 0.1
var param_size:float = 0.5

var current_param_force:float = 0.0
var current_param_size:float = 0.0
var is_expanding:bool = false
var mat: ShaderMaterial = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Messenger.shockwave.connect(spawn_wave)
	mat = material
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if is_expanding:
		if current_param_force<=param_force and current_param_size<=param_size:
			#print("expanding ", current_param_size)
			current_param_force += delta/5
			current_param_size += delta
		else:
			is_expanding = false
			current_param_force = 0.0
			current_param_size = 0.0
		mat.set_shader_parameter("force",current_param_force)
		mat.set_shader_parameter("size",current_param_size)

func spawn_wave(uv_x:float,uv_y:float):
	print("spawn wave")
	current_param_force = 0.0
	current_param_size = 0.0
	mat.set_shader_parameter("force",0.0)
	mat.set_shader_parameter("size",0.0)
	mat.set_shader_parameter("center", Vector2(uv_x, uv_y))
	is_expanding = true
