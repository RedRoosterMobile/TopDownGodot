extends CharacterBody2D

# original tutorial https://www.youtube.com/watch?v=HycyFNQfqI0

var movespeed:float = 500
var bullet_speed:float = 2000
var bullet = preload("res://scenes/bullet.tscn")
var is_awake:bool = false
@onready var sfx_shot := $SfxShot
@onready var spr_player = $Sprite2D
@onready var anim_legs = $AnimLegs
# @onready var bullet_particles = $BulletParticles2D
@onready var bullet_particles_scene = preload("res://scenes/bullet_particles_2d.tscn")

func _ready():
	pass
	# Set the player's collision layer and mask
	# collision_layer = 1
	# collision_mask = 1 | 4  # Ignore layer 2 (bullet), interact with other layers (e.g., enemies on layer 4)

func _process(delta):
	pass

func _physics_process(delta):
	var motion = Vector2()
	if Input.is_action_pressed("up"):
		motion.y -= 1
	if Input.is_action_pressed("down"):
		motion.y += 1
	if Input.is_action_pressed("right"):
		motion.x += 1
	if Input.is_action_pressed("left"):
		motion.x -= 1
		
	if Input.is_action_just_pressed("shoot"):
		if not is_awake:
			# https://youtu.be/UhPFk8FSbd8?si=-AI9E1rRgZJXa5di&t=162
			DialogueManager.show_example_dialogue_balloon(load("res://dialogue/main.dialogue"), "start")
			is_awake = true
		else:
			fire()
	# Normalize the motion vector to prevent faster diagonal movement
	if motion.length() > 0:
		motion = motion.normalized()
	
	# Apply the movement
	velocity = motion * movespeed
	
	# leg animation
	if(velocity.length() > 0):
		anim_legs.play()
		anim_legs.rotation = velocity.angle() - rotation
	else:
		anim_legs.stop()

	move_and_slide()
	look_at(get_global_mouse_position())
	
func fire():
	var bullet_instance = bullet.instantiate()
	var bullet_rigid_body:RigidBody2D = bullet_instance.get_node("BulletRigidBody2D")
	bullet_rigid_body.position = get_global_position() + Vector2(50, 0).rotated(rotation)
	# bullet_rigid_body.position = global_position
	bullet_rigid_body.rotation = rotation

	# Apply the impulse to the bullet
	var direction := Vector2(1, 0).rotated(rotation)
	bullet_rigid_body.linear_velocity = direction * bullet_speed
	
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
		kill()
		
