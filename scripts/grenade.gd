extends Node2D

@onready var rigid_body_2d: RigidBody2D = $RigidBody2D
@onready var timer: Timer = $TriggerTimer
@onready var shrapnel_scene = preload("res://scenes/shrapnel.tscn")
var initial_direction: Vector2 = Vector2.RIGHT  # Default direction

func set_direction(direction: Vector2) -> void:
	initial_direction = direction.normalized()

func _ready() -> void:
	apply_initial_force()
	adjust_physics_properties()
	start_explosion_timer()

func apply_initial_force() -> void:
	var force_magnitude: float = 1000  # Adjust this value as needed
	rigid_body_2d.linear_velocity = initial_direction * force_magnitude

func adjust_physics_properties() -> void:
	# Create and assign PhysicsMaterial
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 0.8  # Increase bounce
	physics_material.friction = 1.0  # Decrease friction
	rigid_body_2d.physics_material_override = physics_material

	# Optional: Adjust mass and damping
	rigid_body_2d.mass = 15.5  # Lighter mass for more bounce
	rigid_body_2d.linear_damp = 0.25  # No linear damping
	rigid_body_2d.angular_damp = 0.15  # No angular damping
	
func start_explosion_timer():
	timer.wait_time = 3
	timer.start()

func _on_timer_timeout() -> void:
	explode()
	# trigger a bunch of (invisible) rigidbodies in a circle and accellerate them outwards
	# make them disappear on first collision
	# queue_free()
func explode() -> void:
	print("boom")
	var shrapnel_count = 20
	var shrapnel_speed = 1000  # Adjust as needed

	for i in range(shrapnel_count):
		var angle = i * (TAU / shrapnel_count)  # Distribute evenly around a circle
		var direction = Vector2(cos(angle), sin(angle))

		var shrapnel = shrapnel_scene.instantiate()
		shrapnel.position = $RigidBody2D/Sprite2D.global_position  # Position at the grenade's location
		# Set the shrapnel's velocity
		shrapnel.linear_velocity = direction * shrapnel_speed
		# Add the shrapnel to the scene
		#get_tree().current_scene.add_child(shrapnel)
		get_tree().get_root().call_deferred("add_child", shrapnel)

	# Optionally, play explosion effects here (particles, sound, etc.)

	# Remove the grenade
	queue_free()
# TODO:
# shockwave shader
# hurt enemies that are in range
# push them in the opposite direction
# physics?
# accellerate a bunch of invisible particles outwards
# remove kill them on first collision
