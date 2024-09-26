extends CharacterBody2D

# original tutorial https://www.youtube.com/watch?v=HycyFNQfqI0
@export var subviewport:SubViewport
var movespeed:float = 700
@export var bullet_speed:float = 3000
@export var bullet_accuracy:float = 0.05
var bullet = preload("res://scenes/bullet.tscn")
var dialogue_active:bool = false
var time: float = 0.0
@onready var sfx_shot := $SfxShot
@onready var spr_player = $Sprite2D
@onready var anim_legs = $AnimLegs
@onready var bullet_particles_scene = preload("res://scenes/bullet_particles_2d.tscn")
#@onready var balloon_scene = preload("res://dialogue/balloon.tscn")
@onready var example_balloon: CanvasLayer = $ExampleBalloon
@onready var camera_2d: Camera2D = $Camera2D
@onready var cursor: Sprite2D = $Cursor

#region Screenshake
@export var shake_duration:float = 0.2
@export var shake_intensity:float = 50.0
@export var shake_cooldown_intensity:float = 0.5

var shake_timer = 0.0
var current_intensity = 0.0
var original_position = Vector2.ZERO

#region Knockback

var knockback_velocity: Vector2 = Vector2.ZERO  # Track knockback velocity
var knockback_force = 300
var knockback_decreaser = 20

#region functions
#var example_balloon:CanvasLayer

var rt_node:Node2D
func _ready():
	#example_balloon = balloon_scene.instantiate()
	print(example_balloon)
	
	Messenger.connect("screenshake", screenshake)
	original_position = camera_2d.position
	rt_node = subviewport.get_node("Node2D")

func screenshake(strength:int = 1):
	# Stackable intensity
	current_intensity += shake_intensity
	shake_timer = shake_duration

	# Start the shake (or continue if already shaking)
	_start_shaking(strength)

func _start_shaking(strength:int):
	if shake_timer > 0:
		# Create the tween on the fly
		var tween = get_tree().create_tween()
		var offset = Vector2(randf_range(-current_intensity*strength, current_intensity*strength), randf_range(-current_intensity, current_intensity))
		# Tween the camera position to a random offset and back
		tween.tween_property(camera_2d, "position", original_position + offset, shake_duration / 10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# After moving to offset, shake back to original position
		tween.tween_property(camera_2d, "position", original_position, shake_duration / 10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# When the tween completes, reduce the intensity and check if more shaking is needed
		tween.tween_callback(_on_shake_complete)

func _on_shake_complete():
	shake_timer -= shake_duration / 10
	#current_intensity *= 0.9  # Reduce intensity gradually
	current_intensity = lerpf(current_intensity*1, 0, shake_cooldown_intensity)

	if shake_timer > 0:
		_start_shaking(1)  # Continue shaking
	else:
		camera_2d.position = original_position  # Reset to the original position
		current_intensity = 0

func _physics_process(delta):
	var motion = Vector2()

	# Movement input
	if Input.is_action_pressed("up"):
		motion.y -= 1
	if Input.is_action_pressed("down"):
		motion.y += 1
	if Input.is_action_pressed("right"):
		motion.x += 1
	if Input.is_action_pressed("left"):
		motion.x -= 1
	
	# Interact with dialogue
	if Input.is_action_just_pressed("interact"):
		if not dialogue_active:
			var resource = load("res://dialogue/main.dialogue")
			example_balloon.start(resource, "start")
			dialogue_active = true
			toggle_pause()

	# Shoot action
	if Input.is_action_just_pressed("shoot"):
		fire()

	# Normalize motion to prevpent faster diagonal movement
	if motion.length() > 0:
		motion = motion.normalized()

	# Apply the movement with movespeed
	velocity = motion * movespeed
	
	# Apply knockback force to velocity
	velocity += knockback_velocity
	
	# Gradually reduce the knockback effect
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_force * delta * knockback_decreaser)
	
	# Leg animation handling
	if velocity.length() > 0:
		anim_legs.play()
		anim_legs.rotation = velocity.angle() - rotation
	else:
		anim_legs.stop()
	
	# Use move_and_slide without arguments
	move_and_slide()
	
	# Character looks towards the mouse position
	look_at(get_global_mouse_position())
	
	# cursor
	cursor.position = get_local_mouse_position()
	cursor.rotation = -rotation
	var scale_factor = 3.0 + sin(time * 10.0) * 0.5  # Adjust the speed and amplitude of the sine wave
	cursor.scale = Vector2(scale_factor, scale_factor)  # Set the cursor scale
	
	# camera
	var viewport_size = get_viewport().get_visible_rect().size
	# var half_width = viewport_size.x * 0.381
	var half_height = viewport_size.x * 0.381
	var clamped_cursor_position = Vector2(
		clamp(cursor.position.x,-half_height,half_height),
		clamp(cursor.position.y,-half_height,half_height)
	)
	# Calculate the midpoint between the player and the clamped cursor position
	# var midpoint = (position+clamped_cursor_position)/2
	# Lerp the camera position for smooth movement
	camera_2d.position = camera_2d.position.slerp(clamped_cursor_position, 0.005)
	
	time += delta
	

# check https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
func toggle_pause():
	if get_tree():
		get_tree().paused = not get_tree().paused
		dialogue_active = get_tree().paused

func fire():
	var bullet_instance = bullet.instantiate()
	var bullet_rigid_body:RigidBody2D = bullet_instance.get_node("BulletRigidBody2D")
	
	bullet_rigid_body.position = get_global_position() + Vector2(120, 0).rotated(rotation)
	# bullet_rigid_body.position = global_position
	bullet_rigid_body.rotation = rotation

	var accuracy:float = randf_range(-bullet_accuracy, bullet_accuracy)
	# Apply the impulse to the bullet
	var direction := Vector2(1, 0).rotated(rotation+accuracy)
	bullet_rigid_body.linear_velocity = direction * bullet_speed
	
	 # Knockback effect: apply knockback to the player in the opposite direction of the bullet
	knockback_velocity += direction * -knockback_force

	# Set the bullet's collision layer and mask
	# bullet_rigid_body.collision_layer = 2
	# bullet_rigid_body.collision_mask = 1 | 4  # Ignore layer 1 (player), interact with other layers (e.g., enemies on layer 4)
	
	# Add the bullet instance to the scene tree
	get_tree().get_root().call_deferred("add_child", bullet_instance)
	# bullet_particles.restart()
	# bullet_particles.emitting = true
	
	# Instance and add the particles
	var bullet_particles_instance := bullet_particles_scene.instantiate()
	bullet_particles_instance.position = bullet_rigid_body.position # Adjust the position if needed
	get_tree().get_root().call_deferred("add_child", bullet_particles_instance)
	sfx_shot.play()

# https://youtu.be/HycyFNQfqI0?si=NJQaapwXdqKIyq7M&t=410
func kill():
	print("player died!")
	get_tree().reload_current_scene()

func _on_area_2d_body_entered(body):
	if "Enemy" in body.name:
		if not body.is_dead:
			kill()
		
# when dialogue done
func _on_example_balloon_tree_exited() -> void:
	print("done with dialogue")
	toggle_pause()
	
func draw_me(arg:Node2D):
	# the order is killing me here!! lol
	arg.reparent(rt_node)
	get_tree().create_timer(1).timeout.connect(func():
		arg.queue_free()
	)

func draw_me_add(arg:Node2D):
	rt_node.add_child(arg)
	get_tree().create_timer(1).timeout.connect(func():
		arg.queue_free()
	)

func draw_blood_line(sprite_pos, random_pos, line_color, line_width):
	rt_node.draw_blood_line(sprite_pos, random_pos, line_color, line_width)
	
	
	
	
	
