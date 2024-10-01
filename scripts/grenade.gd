extends Node2D

@onready var rigid_body_2d: RigidBody2D = $RigidBody2D
@onready var timer: Timer = $TriggerTimer
@onready var shrapnel_scene = preload("res://scenes/shrapnel.tscn")
@onready var explosion_anim: AnimatedSprite2D = $RigidBody2D/ExplosionAnim
@onready var snd_explosion: AudioStreamPlayer2D = $sndExplosion
var initial_direction: Vector2 = Vector2.RIGHT  # Default direction
# @onready var grenade: Sprite2D = $RigidBody2D/Grenade

var trigger_time:float = 3
var initial_force:float = 1000

func set_direction(direction: Vector2) -> void:
	initial_direction = direction.normalized()

func _ready() -> void:
	apply_initial_force()
	adjust_physics_properties()
	start_explosion_timer()
	$AnimationPlayer.play("scale")

func _physics_process(delta: float) -> void:
	# works
	# $RigidBody2D/Grenade.scale = Vector2(4,4)
	# does not work
	#$AnimationPlayer.advance(delta)
	pass
	

func apply_initial_force() -> void:
	rigid_body_2d.linear_velocity = initial_direction * initial_force

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
	#region shochwave
	# magic sauce: screen coorinates (aka on my screen in pixels)
	var player_pos = $RigidBody2D/Grenade.get_global_transform_with_canvas()
	var spawn_pos = player_pos.get_origin()
	# from the window config
	var size:Vector2i = get_window().size
	# to uv
	var uv_position = Vector2(
		spawn_pos.x / size.x,
		spawn_pos.y / size.y
	)	
	Messenger.shockwave.emit(uv_position.x,uv_position.y)
	
	#region shrapnel
	var explosion_position = $RigidBody2D/Grenade.global_position
	var shrapnel_count = 20
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
	
	explosion_anim.scale *= randf_range(1, 2)
	explosion_anim.modulate.a = randf_range(0.5, 1)
	explosion_anim.stop()
	explosion_anim.play()
	explosion_anim.visible = true

func _on_explosion_anim_animation_looped() -> void:
	# Remove the grenade
	queue_free()
