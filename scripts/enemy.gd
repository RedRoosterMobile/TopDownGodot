extends CharacterBody2D
class_name Enemy

var motion := Vector2()
var is_dead := false
var was_hit := false
var speed:float = 5
var rt_node:Node2D

var fov_angle: float = 90.0  # Field of view angle in degrees

var enemy_state:Enums.EnemyState = Enums.EnemyState.IDLE

@export var player: Player
@export var debug_cirlces: bool = false
@export var health: int = 3
@export var noise_awareness_circle:int = 700
@export var visual_awareness_circle:int = 450
@export var jump_circle:int = 250

@export var target: Node2D = null
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

@onready var sfx_zombie_growl := $AnimZombie/SfxZombieGrowl
@onready var sfx_gore_splash: AudioStreamPlayer2D = $AnimZombie/SndGoreSplash
@onready var timer:Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimZombie
@onready var anim_impact: AnimatedSprite2D = $AnimImpact
@onready var sprite_2d: Sprite2D = $Sprite2D
# pathfinding
# https://www.youtube.com/watch?v=yT22SXYpoYM
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var blood_path_scene = preload("res://scenes/blood_path.tscn")
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var enemy_collider: CollisionShape2D = $EnemyCollider

 # 1-5  normal
 # 6-7  attack
 # 8-11 die
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
]

func _draw():
	if not is_dead and debug_cirlces:
		# Draw Noise Awareness Circle (Red)
		draw_circle(Vector2.ZERO, noise_awareness_circle/scale.x, Color(1, 0, 0, 0.3))
		# Draw Visual Awareness Circle (Green)
		draw_circle(Vector2.ZERO, visual_awareness_circle/scale.x, Color(0, 1, 0, 0.3))
		# Draw Jump Circle (Blue)
		draw_circle(Vector2.ZERO, jump_circle/scale.x, Color(0, 0, 1, 0.3))

func play_random_growl_sound() -> void:
	if not is_dead and enemy_state != Enums.EnemyState.JUMP:
		var random_index:int = randi_range(1,5)-1
		play_growl(random_index)

func play_growl(index:int) -> void:
	var sound_path:String = sound_files[index]
	var sound := load(sound_path) as AudioStream
	sfx_zombie_growl.stream = sound
	sfx_zombie_growl.play()

func start_random_timer() -> void:
	var random_interval := randf_range(2.0, 5.0) # Random interval between 1 and 5 seconds
	timer.wait_time = random_interval
	timer.start()

func _ready():
	anim_impact.visible = false
	randomize() # Ensure randomness each time the game runs
	play_random_growl_sound()
	start_random_timer()
	animated_sprite_2d.play("walk")
	ray_cast_2d.target_position.x = visual_awareness_circle
	call_deferred("nav_setup")
	
func nav_setup():
	await get_tree().physics_frame
	if target:
		print("set up")
		navigation_agent_2d.target_position = player.global_position

const blood_spawn_interval = 0.01  # Interval in seconds
var blood_spawn_timer = blood_spawn_interval
var blood_timer_enabled = true
# used in path and line
var blood_path_start_pos = Vector2.ZERO
func _physics_process(delta) -> void:
	if is_dead:
		if(blood_spawn_timer<=0 and blood_timer_enabled):
			var blood_path:Node2D = blood_path_scene.instantiate()
			blood_path.position = global_position
			if (blood_path_start_pos == Vector2.ZERO):
				blood_path_start_pos = global_position
			#blood_path.rotation_degrees = randi_range(1,4)*90
			blood_path.rotation = blood_path.rotation + get_angle_to(player.global_position)
			blood_path.scale = Vector2(4,4)
			blood_path.modulate.a = randf_range(0.5, 1)
			blood_path.modulate.h = randf_range(0.5, 0.9)
			
			player.draw_me_add(blood_path)
			blood_spawn_timer = blood_spawn_interval + 0.1
		else:
			blood_spawn_timer -= delta
		move_and_slide()
		# reduce velocity over time
		velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)
		return
	
	if enemy_state == Enums.EnemyState.ATTACHED:
		var distance = player.position.distance_to(position)
		velocity = velocity.move_toward(position.direction_to(player.position)*distance, 10000 * delta)
		# remove collision layers?
		move_and_slide()
		return
	
	var is_pathfinding = false
	#region pathfinding
	# set target if not set
	
	# find target
	aquire_target()
	
	if target:
		# TODO: add all circles, done
		var distance_to_player:float = player.position.distance_to(self.position)
		
		var is_in_jump_zone:bool = distance_to_player <= jump_circle
		var is_in_visual_awareness_zone:bool = (distance_to_player > jump_circle) and (distance_to_player <= visual_awareness_circle)
		var is_in_noise_awareness_zone:bool = (distance_to_player > visual_awareness_circle) and (distance_to_player <= noise_awareness_circle)
		
		if is_in_visual_awareness_zone:
			enemy_state = Enums.EnemyState.VISUAL
			navigation_agent_2d.target_position = player.global_position
			animated_sprite_2d.play("fly")
			look_at(player.position)
			# next two lines are the same
			#motion = (navigation_agent_2d.get_next_path_position()- position).normalized() * speed
			motion = position.direction_to(navigation_agent_2d.get_next_path_position()) * speed
			move_and_collide(motion)
		elif is_in_jump_zone:
			if enemy_state != Enums.EnemyState.JUMP:
				play_growl(11-1)
			enemy_state = Enums.EnemyState.JUMP
			navigation_agent_2d.target_position = player.global_position
			animated_sprite_2d.play("fly")
			look_at(player.position)
			# next two lines are the same
			motion = position.direction_to(navigation_agent_2d.get_next_path_position()) * speed*2
			move_and_collide(motion)
		elif is_in_noise_awareness_zone:
			enemy_state = Enums.EnemyState.NOISE
			
			var angle:float = get_angle_to(player.position)
			animated_sprite_2d.play("walk")
			# print(player.get_real_velocity().length_squared() > 400)
			# turn around first, before walking
			if abs(angle) >= 0.1:
				slowly_turn_towards(angle)
				target = null
			else:
				navigation_agent_2d.target_position = player.global_position
				look_at(player.position)
				motion = position.direction_to(navigation_agent_2d.get_next_path_position()) * speed/2
				move_and_collide(motion)
			
		else:
			# never happens?
			enemy_state = Enums.EnemyState.IDLE
			animated_sprite_2d.play("walk")
			animated_sprite_2d.pause()
	else:
		enemy_state = Enums.EnemyState.IDLE
		animated_sprite_2d.pause() # aka IDLE
	if navigation_agent_2d.is_navigation_finished():
		target = null
		#return
	
	
	#region awareness
	return
	# legacy code?
	if player and player.position.distance_to(self.position) < visual_awareness_circle:
		# todo: only walk if the path is clear (raycast the motion vector)
		motion = (player.position - position) / randf_range(55, 85) * speed

		slowly_turn_towards(get_angle_to(player.position))
		if ray_cast_2d.is_colliding():
			# player in plain sight?
			if ray_cast_2d.get_collider() == player:
				move_and_collide(motion)

func slowly_turn_towards(target_angle, turn_speed = 0.02) -> void:
	rotation = lerp_angle(rotation, rotation + target_angle, turn_speed)

func aquire_target():
	var distance_to_player:float = player.position.distance_to(self.position)
		
	var is_in_jump_zone:bool = distance_to_player <= jump_circle
	var is_in_visual_awareness_zone:bool = (distance_to_player > jump_circle) and (distance_to_player <= visual_awareness_circle)
	var is_in_noise_awareness_zone:bool = (distance_to_player > visual_awareness_circle) and (distance_to_player <= noise_awareness_circle)
	
	if false:
		print("---")
		# always works
		print("jump   ", is_in_jump_zone)
		# only works if in fov (needs to turn)
		print("visual ", is_in_visual_awareness_zone)
		# always works (on any target), needs to turn first if not in fov
		print("noise  ", is_in_noise_awareness_zone)
		
		print("fov    ", is_player_in_fov())
		print("---")
	
	# check if target empty
	if (not target):
		if is_in_visual_awareness_zone:
			#enemy_state = EnemyState.VISUAL
			target = player
		elif is_in_noise_awareness_zone:
			#enemy_state = EnemyState.NOISE
			target = player
		elif is_in_jump_zone:
			#enemy_state = EnemyState.JUMP
			target = player
		else:
			#enemy_state = EnemyState.IDLE
			target = null
	

func is_player_in_fov() -> bool:
	var to_player = (player.global_position - global_position).normalized()
	var facing_direction = Vector2.RIGHT.rotated(global_rotation)
	var dot_product = facing_direction.dot(to_player)
	var angle_to_player = acos(dot_product)
	var half_fov_rad = deg_to_rad(fov_angle) / 2.0
	return angle_to_player < half_fov_rad

func _on_area_2d_body_entered(body) -> void:
	if "BulletRigidBody2D" in body.name:
		# kill bullet
		# body.get_parent().queue_free()
		var bullet_global_position:Vector2 = body.global_position
		body.queue_free()
		
		health -= 1
		if health <= 0:
			is_dead = true
			timer.stop()
			animated_sprite_2d.play("die")
		else:
			was_hit = true
			get_tree().create_timer(0.2).timeout.connect(func():
				was_hit = false
				# turn around towards player..
				# same as look_at()
				var target_angle = get_angle_to(player.position)
				rotation = rotation + target_angle
			)
			
		# todo: spawn some blood particle
		sfx_gore_splash.pitch_scale = randf_range(0.7,1)
		sfx_gore_splash.play()
		
		# 8-11 die
		play_growl(randi_range(8,11)-1)
		
		# no effect when hurt only
		# Calculate the impact direction
		
		# the next three lines are the same
		#var impact_direction:Vector2 = (global_position - bullet_global_position).normalized()
		#var impact_direction:Vector2 = global_position.direction_to(bullet_global_position)*-1
		var impact_direction:Vector2 = bullet_global_position.direction_to(global_position)
		anim_impact.rotation += position.angle_to(player.position)
		anim_impact.visible = true
		anim_impact.speed_scale = sfx_gore_splash.pitch_scale
		anim_impact.play()
		# Apply impact force
		var impact_force = randf_range(150,190)
		velocity += impact_direction * impact_force

func _on_timer_timeout() -> void:
	play_random_growl_sound()
	start_random_timer()

#region animation

func _on_anim_zombie_frame_changed() -> void:
	blood_line()
func _on_anim_zombie_animation_finished() -> void:
	print("draw me")
	anim_impact.pause()
	blood_timer_enabled = false
	velocity = Vector2.ZERO
	animated_sprite_2d.pause()
	player.draw_me(self)

func blood_line() -> void:
	# path
	if(blood_path_start_pos):
		var sprite_pos = global_position
		var line_color = Color(1, 0, 0, randf_range(0.01,0.05))  # Equivalent to 0xaa0000 with alpha 0.1
		var line_width = randf_range(50,70)
		
		# Draw the line
		player.draw_blood_line(blood_path_start_pos, sprite_pos, line_color, line_width)
		blood_path_start_pos = sprite_pos

# try this inside the the subviewport
func line2dexample() -> void:
	# Get the Line2D node
	var line:Line2D = $Line2D # Line2D.new
	
	# Define the points for the line
	var points = [
		Vector2(100, 100),
		Vector2(200, 200),
		Vector2(300, 100),
		Vector2(400, 200)
	]
	# line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	# Set the points to the Line2D
	line.points = points
	# line.add_point(Vector2(0,0))
	
	# Optional: Adjust other properties
	line.width = 4
	line.default_color = Color(1, 0, 0)  # Red color
	
	# add_child(line)
