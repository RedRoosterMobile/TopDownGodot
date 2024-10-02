extends CharacterBody2D
class_name Player
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

@onready var footprint: Sprite2D = $AnimLegs/Footstep
var footprint_alpha = 0
var footprint_step: bool = false
const FOOTPRINT_COOLDOWN:float = 1
var time_to_footprint: float = FOOTPRINT_COOLDOWN

@onready var bullet_particles_scene = preload("res://scenes/bullet_particles_2d.tscn")
@onready var grenade_scene = preload("res://scenes/grenade.tscn")
@onready var shell_scene = preload("res://scenes/shell.tscn")
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

var attached_enemies:Array = []

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
	Messenger.connect("bloody_footsteps", soak_shoes_in_blood)
	Messenger.connect("draw_node", draw_me)
	original_position = camera_2d.position
	rt_node = subviewport.get_node("Node2D")

func screenshake(strength:int = 1):
	# Stackable intensity
	current_intensity += shake_intensity
	shake_timer = shake_duration
	# Start the shake (or continue if already shaking)
	_start_shaking(strength)

func soak_shoes_in_blood():
	print("shoes fully soaking with blood")
	footprint_alpha = 1
	
func draw_footprints(delta):
	var step:Sprite2D = footprint.duplicate()
	
	var offset:Vector2 = step.global_position
	
	# Define the array of colors
	var color_array = [
		Color8(255, 0, 0),   # 0xff0000
		Color8(153, 0, 0),   # 0x990000
		Color8(170, 0, 0),   # 0xaa0000
		Color8(255, 16, 16)  # 0xff1010
	]
	
	footprint_step = not footprint_step
	var y_offset:float = 30.0
	if footprint_step:
		y_offset *= -1
		step.flip_h = true
		
	var o = Vector2(
		 sin(rotation + anim_legs.rotation) * y_offset,
		-cos(rotation + anim_legs.rotation) * y_offset
	)

	# Select a random tint color
	var random_tint = color_array.pick_random()
	# Apply the tint color
	step.modulate = random_tint
	# Set the alpha transparency
	# FNORD: division by 10 makes NO sense, but works
	step.modulate.a = footprint_alpha/10
	step.position = global_position + offset + o
	step.rotation = rotation + anim_legs.rotation + rad_to_deg(-90)
	step.scale *= 6
	step.visible = true
	draw_me_add(step)
	
	pass

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
	#
	
	
	#

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
		print("grenade")
		var grenade = grenade_scene.instantiate()
		var direction := Vector2(1, 0).rotated(rotation)
		grenade.position = global_position
		grenade.set_direction(direction)
		get_tree().get_root().call_deferred("add_child", grenade)
		
		# particle effect
		# somehow make it physics active
		return
		pass
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
	# ERTHQUAKE, or drunk effect!
	#camera_2d.transform=camera_2d.transform.rotated(0.05)
	
	# IDLE effect?
	#var rotation_trans = Transform2D(0.001, global_position.normalized())
	#camera_2d.transform *= rotation_trans
	
	#Vector2.from_angle(PI/4)
	#Vector2.from_angle(PI / 2)

	#var rotation_trans = Transform2D(PI / 2, Vector2.from_angle(PI/4))
	#camera_2d.transform *= rotation_trans

	
	#camera_2d.rotation+=sin(time*300)*PI
	# TODO rotate world instead?????
	# get_parent().rotation=PI/4
	# Define frequency and amplitude
	#const FREQUENCY = 2.0  # Adjust as needed
	#const AMPLITUDE = 0.5  # Adjust as needed (in radians)
	# camera_2d.rotation= PI/4
	# $PointLight2D.position.y = sin(time/30)*20
	if time_to_footprint <= 0:
		draw_footprints(delta)
		time_to_footprint = FOOTPRINT_COOLDOWN
		footprint_alpha -= 0.1
	else:
		time_to_footprint -= 0.1
	
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
	
	# shell
	var shell:RigidBody2D = shell_scene.instantiate()
	
	shell.position = get_global_position() + Vector2(60, 0).rotated(rotation)
	shell.rotation = rotation
	var shell_accuracy: float = randf_range(-bullet_accuracy * 10, bullet_accuracy * 10)
	var direction_shell := Vector2(1, 0).rotated(rotation + shell_accuracy + deg_to_rad(90))
	shell.linear_velocity = direction_shell * bullet_speed/2
	get_tree().get_root().call_deferred("add_child", shell)
	
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
	if body.is_in_group("shrapnel"):
		print("ouch. fire in the hole!")
		kill()
	if body.is_in_group("enemy"):
		var enemy = body as Enemy
		if not enemy.is_dead and enemy.enemy_state == Enums.EnemyState.JUMP:
			#enemy.enemy_state = Enums.EnemyState.ATTACHED
			#attached_enemies.push_back(enemy)
			#print(attached_enemies.size())
			kill()
		elif not enemy.is_dead and enemy.enemy_state == Enums.EnemyState.ATTACHED:
			#enemy.enemy_state = Enums.EnemyState.ATTACHED
			#attached_enemies.push_back(enemy)
			#print(attached_enemies.size())
			print("bite?")
			pass
		elif not body.is_dead:
			#kill()
			return
	
# when dialogue done
func _on_example_balloon_tree_exited() -> void:
	print("done with dialogue")
	toggle_pause()

# only works for non transparent stuff
func draw_me(arg:Node2D):
	arg.reparent(rt_node)
	# Connect to rt_node's after_draw signal with a one-shot connection
	get_tree().create_timer(1).timeout.connect(func():
		if(arg):
			arg.queue_free()
	)

# works for transparent stuff
func draw_me_add(arg:Node2D):
	rt_node.add_child(arg)
	
	get_tree().create_timer(0.1).timeout.connect(func():
		if(arg):
			arg.queue_free()
	)

func draw_blood_line(sprite_pos, random_pos, line_color, line_width):
	rt_node.draw_blood_line(sprite_pos, random_pos, line_color, line_width)
