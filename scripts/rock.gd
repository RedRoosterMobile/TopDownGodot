extends Node2D

@onready var rigid_body_2d: RigidBody2D = $RigidBody2D
@onready var grenade: Sprite2D = $Rock

var initial_direction: Vector2 = Vector2.RIGHT  # Default direction
var initial_force:float = 1100

func set_direction(direction: Vector2) -> void:
	initial_direction = direction.normalized()

func _ready() -> void:
	print("rocky")
	apply_initial_force()
	adjust_physics_properties()
	# $AnimationPlayer.play("scale")

func _physics_process(delta: float) -> void:
	grenade.position = rigid_body_2d.position
	grenade.rotation = rigid_body_2d.rotation
	bounce_checker()
		
var previous_velocity:Vector2 = Vector2.ZERO
func bounce_checker():
	var current_velocity:Vector2 = rigid_body_2d.linear_velocity.normalized()
	Helpers.bounce_checker(current_velocity,previous_velocity,func():
		Messenger.raise_attention.emit(grenade.global_position)
	)
	previous_velocity = current_velocity

func apply_initial_force() -> void:
	# same same
	#rigid_body_2d.linear_velocity = initial_direction * initial_force
	rigid_body_2d.apply_impulse(initial_direction*initial_force)

func adjust_physics_properties() -> void:
	# Create and assign PhysicsMaterial
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 0.3  # Increase bounce
	physics_material.friction = 1  # Decrease friction
	rigid_body_2d.physics_material_override = physics_material

	# Optional: Adjust mass and damping
	rigid_body_2d.mass = 1.5  # Lighter mass for more bounce
	rigid_body_2d.linear_damp = 0.25  # No linear damping
	rigid_body_2d.angular_damp = 0.15  # No angular damping
	
