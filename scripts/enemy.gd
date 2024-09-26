extends CharacterBody2D

var motion := Vector2()
var is_dead := false
var was_hit := false
var speed:float = 5

@export var player: Node2D;
@export var health: int = 3
@export var awareness_circle:int = 800

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

func play_random_growl_sound() -> void:
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
	ray_cast_2d.target_position.x = awareness_circle
	call_deferred("nav_setup")
	
	
func nav_setup():
	await get_tree().physics_frame
	if target:
		print("set up")
		navigation_agent_2d.target_position=player.global_position
	pass

const blood_spawn_interval = 0.01  # Interval in seconds
var blood_spawn_timer = blood_spawn_interval
var blood_timer_enabled = true
# used in path and line
var blood_path_start_pos=Vector2.ZERO
func _physics_process(delta) -> void:
	if is_dead:
		if(blood_spawn_timer<=0 and blood_timer_enabled):
			var blood_path:Node2D = blood_path_scene.instantiate()
			blood_path.position = global_position
			if (blood_path_start_pos==Vector2.ZERO):
				blood_path_start_pos=global_position
			#blood_path.rotation_degrees = randi_range(1,4)*90
			blood_path.rotation = blood_path.rotation + get_angle_to(player.global_position)
			blood_path.scale = Vector2(4,4)*randi_range(1,1)
			blood_path.modulate.a = randf_range(0.5,1)
			blood_path.modulate.h = randf_range(0.5,0.9)
			
			player.draw_me_add(blood_path)
			blood_spawn_timer = blood_spawn_interval + 0.1
		else:
			blood_spawn_timer -= delta
		move_and_slide()
		# reduce velocity over time
		velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)
		return
	
	var is_pathfinding = false
	#region pathfinding
	if target:
		# TODO: add all circles, done
		if player.position.distance_to(self.position) < awareness_circle:
			navigation_agent_2d.target_position = player.global_position
			animated_sprite_2d.play("fly")
			look_at(player.position)
			# next two lines are the same
			#motion = (navigation_agent_2d.get_next_path_position()- position).normalized() * speed
			motion = position.direction_to(navigation_agent_2d.get_next_path_position())*speed
			move_and_collide(motion)
		else:
			animated_sprite_2d.play("walk")
	if navigation_agent_2d.is_navigation_finished():
		target = null
		#return
	
	#region awareness
	return
	# legacy code?
	if player and player.position.distance_to(self.position) < awareness_circle:
		# todo: only walk if the path is clear (raycast the motion vector)
		motion = (player.position - position) / randf_range(55, 85) * speed
		
		#look_at(player.position)
		if is_pathfinding:
			look_at(player.position)
		else:
			slowly_turn_towards(get_angle_to(player.position))
		if ray_cast_2d.is_colliding():
			# player in plain sight?
			if ray_cast_2d.get_collider() == player:
				move_and_collide(motion)

func slowly_turn_towards(target_angle, turn_speed = 0.02) -> void:
	rotation = lerp_angle(rotation, rotation + target_angle, turn_speed)

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
	blood_timer_enabled=false
	velocity = Vector2.ZERO
	animated_sprite_2d.pause()
	sprite_2d.queue_free()
	
	$Area2D.queue_free()
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
