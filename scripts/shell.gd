extends RigidBody2D

var timer_ran_out = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	adjust_physics_properties()
	get_tree().create_timer(1).timeout.connect(draw_on_next_frame)
	print(z_index)
	# z_index=-1
	
func _physics_process(delta: float) -> void:
	if timer_ran_out and abs(linear_velocity.length()) < 1:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		Messenger.draw_node.emit(self)

func adjust_physics_properties() -> void:
	# Create and assign PhysicsMaterial
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 0.8  # Increase bounce
	physics_material.friction = 0.1  # Decrease friction
	physics_material_override = physics_material
	
	# Optional: Adjust mass and damping
	# mass = 0.5  # Lighter mass for more bounce
	linear_damp = 2.25  # No linear damping
	angular_damp = 0.0  # No angular damping

func draw_on_next_frame():
	timer_ran_out = true
