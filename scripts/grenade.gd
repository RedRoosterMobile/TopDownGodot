extends Node2D

@onready var rigid_body_2d: RigidBody2D = $RigidBody2D
@onready var timer: Timer = $TriggerTimer
@onready var shrapnel_scene = preload("res://scenes/shrapnel.tscn")
@onready var snd_explosion: AudioStreamPlayer2D = $sndExplosion
@onready var explosion: AnimatedSprite2D = $Explosion
#@onready var grenade: Sprite2D = $RigidBody2D/Grenade
@onready var grenade: Sprite2D = $Grenade

var initial_direction: Vector2 = Vector2.RIGHT  # Default direction
# @onready var grenade: Sprite2D = $RigidBody2D/Grenade
var has_exploded:bool= false

var trigger_time:float = 3
var initial_force:float = 1000

func set_direction(direction: Vector2) -> void:
	initial_direction = direction.normalized()

func _ready() -> void:
	apply_initial_force()
	adjust_physics_properties()
	start_explosion_timer()
	$AnimationPlayer.play("scale")
var previous_rotation = 0
var previous_position = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if not has_exploded:
		grenade.position = rigid_body_2d.position
		grenade.rotation = rigid_body_2d.rotation
		bounce_checker()
		
func bounce_checker():
	var current_velocity:Vector2 = rigid_body_2d.linear_velocity.normalized()
	var diff:Vector2 = current_velocity-previous_position
	if diff.length_squared() > 0.7:
		print("bounce")
		Messenger.raise_attention.emit(grenade.global_position)
	# print(current_velocity-previous_position)
	previous_position = current_velocity

func apply_initial_force() -> void:
	# same same
	#rigid_body_2d.linear_velocity = initial_direction * initial_force
	rigid_body_2d.apply_impulse(initial_direction*initial_force)

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
	timer.wait_time = trigger_time
	timer.start()

func _on_timer_timeout() -> void:
	
	explode()
	# trigger a bunch of (invisible) rigidbodies in a circle and accellerate them outwards
	# make them disappear on first collision
	# queue_free()
func explode() -> void:
	print("boom")
	Messenger.raise_attention.emit(grenade.global_position)
	#region shockwave
	# magic sauce: screen coorinates (aka on my screen in pixels)
	var player_pos = grenade.get_global_transform_with_canvas()
	has_exploded = true
	grenade.queue_free()
	var spawn_pos = player_pos.get_origin()
	# from the window config
	var size:Vector2i = get_window().size
	# to uv
	var uv_position = Vector2(
		spawn_pos.x / size.x,
		spawn_pos.y / size.y
	)	
	Messenger.shockwave.emit(uv_position.x,uv_position.y)
	
	
	#region explosion
	var explosion_position = grenade.global_position
	explosion.global_position=explosion_position
	explosion.rotation = -rotation
	explosion.scale *= randf_range(1, 2)
	explosion.visible = true
	explosion.play()
	
	#region shrapnel
	
	var shrapnel_count = 40
	var shrapnel_speed = 1000  # Adjust as needed

	for i in range(shrapnel_count):
		var angle = i * (TAU / shrapnel_count)  # Distribute evenly around a circle
		var direction = Vector2(cos(angle), sin(angle))

		var shrapnel = shrapnel_scene.instantiate()
		shrapnel.position = explosion_position  # Position at the grenade's location
		# Set the shrapnel's velocity
		shrapnel.linear_velocity = direction * shrapnel_speed
		# Add the shrapnel to the scene
		#get_tree().current_scene.add_child(shrapnel)
		get_tree().get_root().call_deferred("add_child", shrapnel)

	# Optionally, play explosion effects here (particles, sound, etc.)
	#region FX
	Messenger.screenshake.emit(1)
	snd_explosion.pitch_scale=randf_range(0.5, 1)
	snd_explosion.play()

func _on_explosion_animation_finished() -> void:
	queue_free()

# instead check if direction has changed and then fire it
# this catches ALL cases where it bounces somewhere!
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("wall"):
		print("##################### ",body)
		Messenger.raise_attention.emit(grenade.global_position)
