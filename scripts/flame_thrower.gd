extends Node2D
@onready var burner_scene = preload("res://scenes/burner.tscn")
@onready var flame_thrower: CPUParticles2D = $FlameThrower

@export var is_active: bool = true
@export var spawn_interval: float = 0.1  # Spawn every 2 seconds

var time_passed: float = 0.0

func _ready() -> void:
	create_burner()

func _physics_process(delta: float) -> void:
	# Increment time_passed by delta (the time between frames)
	time_passed += delta
	
	# Check if enough time has passed to spawn another burner
	if is_active and time_passed >= spawn_interval:
		create_burner()
		time_passed = 0.0  # Reset the timer
	
	if is_active and not flame_thrower.emitting:
		print("play ft sound")
	elif is_active:
		print("loop ft sound?")
	else:
		print("stop ft sound")
		
	flame_thrower.emitting = is_active
	
func create_burner():
	var burner_instance: RigidBody2D = burner_scene.instantiate()
	burner_instance.position = global_position
	
	burner_instance.direction = Vector2.RIGHT.rotated(global_rotation)
	get_tree().root.add_child( burner_instance)
