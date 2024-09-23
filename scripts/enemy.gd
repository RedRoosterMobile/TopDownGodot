extends CharacterBody2D

var motion := Vector2()
var is_dead := false
@onready var sfx_zombie_growl := $AnimZombie/SfxZombieGrowl
@onready var timer:Timer = $Timer
@onready var animated_sprite_2d = $AnimZombie
var speed:float = 1.0
# will be set in the editor, like in Unity
@export var player: Node2D;
@onready var sprite_2d: Sprite2D = $Sprite2D
# pathfinding
# https://www.youtube.com/watch?v=yT22SXYpoYM
@onready var ray_cast_2d: RayCast2D = $RayCast2D

@onready var blood_path_scene = preload("res://scenes/blood_path.tscn")

var sound_files: Array[String] = [
	"res://assets/sounds/sfx/zombie/1.wav",
	"res://assets/sounds/sfx/zombie/2.wav",
	"res://assets/sounds/sfx/zombie/3.wav",
	"res://assets/sounds/sfx/zombie/4.wav",
	"res://assets/sounds/sfx/zombie/5.wav",
	"res://assets/sounds/sfx/zombie/6.wav",
	"res://assets/sounds/sfx/zombie/7.wav",
	"res://assets/sounds/sfx/zombie/8.wav",
	"res://assets/sounds/sfx/zombie/9.wav",
	"res://assets/sounds/sfx/zombie/10.wav",
	"res://assets/sounds/sfx/zombie/11.wav",
	"res://assets/sounds/sfx/zombie/12.wav"
]

func play_random_sound():
	var random_index:int = randi() % sound_files.size()
	var random_sound_path:String = sound_files[random_index]
	var sound := load(random_sound_path) as AudioStream
	sfx_zombie_growl.stream = sound
	sfx_zombie_growl.play()

func start_random_timer():
	var random_interval := randf_range(1.0, 5.0) # Random interval between 1 and 5 seconds
	timer.wait_time = random_interval
	timer.start()

func _ready():
	randomize() # Ensure randomness each time the game runs
	play_random_sound()
	start_random_timer()
	animated_sprite_2d.play("walk")
	
	
	#queue_redraw()
	print("drawe line ready")
#func _draw():
	#blood_line()

const blood_spawn_interval = 0.001  # Interval in seconds
var blood_spawn_timer = blood_spawn_interval
var blood_timer_enabled = true
var blood_path_start_pos=Vector2.ZERO
func _physics_process(delta):
	if is_dead:
		if(blood_spawn_timer<=0 and blood_timer_enabled):
			var blood_path:Node2D = blood_path_scene.instantiate()
			blood_path.position = global_position
			if(blood_path_start_pos==Vector2.ZERO):
				blood_path_start_pos=global_position
			#player.draw_blood_line()
			blood_path.rotation_degrees = randi_range(1,4)*90
			blood_path.scale = Vector2(4,4)*randi_range(1,2)
			blood_path.modulate.a = randf_range(0.5,1)
			blood_path.modulate.h = randf_range(0.5,0.9)
			
			player.draw_me_add(blood_path)
			blood_spawn_timer = blood_spawn_interval + 0.1
			
		else:
			blood_spawn_timer -= delta
		move_and_slide()
		return
	
	if player and player.position.distance_to(self.position) < 400:
		# todo: only walk if the path is clear (raycast the motion vector)
		motion = (player.position - position) / randf_range(55, 85) * speed
		
		look_at(player.position)
		if ray_cast_2d.is_colliding():
			# player in plain sight?
			if ray_cast_2d.get_collider() == player:
				move_and_collide(motion)
			else:
				motion = Vector2.ZERO
		# todo: path-finding
		# todo: think of some following logic:
		# sound attraction? noise level?
		# distract enemies? decoys?
		
	else:
		motion = Vector2.ZERO

func _on_area_2d_body_entered(body):
	if "BulletRigidBody2D" in body.name:
		# kill bullet
		body.get_parent().queue_free()
		
		is_dead = true
		var bb:RigidBody2D = body as RigidBody2D
		
		# Calculate the impact direction
		var impact_direction = (global_position - body.global_position).normalized()

		# Apply impact force
		var impact_force = randf_range(150,200)  # Adjust this value as needed
		velocity = impact_direction * impact_force


		#$CollisionShape2D.queue_free()
		timer.stop()
		animated_sprite_2d.play("die")
		
func _on_timer_timeout():
	play_random_sound()
	start_random_timer()

#region animation

func _on_anim_zombie_frame_changed() -> void:
	blood_line()
func _on_anim_zombie_animation_finished():
	print("draw me")	
	
	blood_timer_enabled=false
	velocity = Vector2.ZERO
	animated_sprite_2d.pause()
	sprite_2d.queue_free()
	
	$Area2D.queue_free()
	player.draw_me(self)
	# draw to renderr texture?, yes!!
	#queue_free()
	
func blood_line():
	# path
	if(blood_path_start_pos):
		var sprite_pos = global_position
		var random_x_offset = 0#randf_range(-30, 30)
		var random_y_offset = 0#randf_range(-30, 30)
		var random_pos = sprite_pos + Vector2(random_x_offset, random_y_offset)
		var line_color = Color(1, 0, 0, randf_range(0.01,0.05))  # Equivalent to 0xaa0000 with alpha 0.1
		var line_width = randf_range(50,70)
		
		# Draw the line
		player.draw_blood_line(blood_path_start_pos, random_pos, line_color, line_width)
		blood_path_start_pos = sprite_pos
