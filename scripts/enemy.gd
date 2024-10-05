extends CharacterBody2D
class_name Enemy

var motion := Vector2()
var is_dead := false
var was_hit := false
var is_burning := false
var burnout_time: float = 3.0
var time_till_burnout: float = burnout_time
var speed: float = 5.0
var rt_node: Node2D

var fov_angle: float = 90.0 # Field of view angle in degrees

var enemy_state: Enums.EnemyState = Enums.EnemyState.IDLE

@export var player: Player
@export var debug_cirlces: bool = false
@export var health: float = 3.0
@export var noise_awareness_circle: int = 700
@export var visual_awareness_circle: int = 450
@export var jump_circle: int = 250
@export var target: Node2D = null
# additional stuff
# https://godotshaders.com/shader/qi-aura-outline/
# https://godotshaders.com/shader/fire-distortion/
@onready var fire: GPUParticles2D = $Fire

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

@onready var sfx_zombie_growl := $AnimZombie/SfxZombieGrowl
@onready var sfx_gore_splash: AudioStreamPlayer2D = $AnimZombie/SndGoreSplash
@onready var timer: Timer = $Timer
@onready var anim_zombie: AnimatedSprite2D = $AnimZombie
@onready var anim_impact: AnimatedSprite2D = $AnimImpact
@onready var sprite_2d: Sprite2D = $Sprite2D
# pathfinding
# https://www.youtube.com/watch?v=yT22SXYpoYM
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var blood_path_scene = preload("res://scenes/blood_path.tscn")
@onready var footstep_trigger_scene = preload("res://scenes/footstep_trigger.tscn")
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

func highlight():
	var tween = get_tree().create_tween()
	var tt: ShaderMaterial = anim_zombie.material as ShaderMaterial
	
	tween.tween_method(
	  func(value): tt.set_shader_parameter("current_intensity", value),
	  0.0, # Start value
	  1.0, # End value
	  0.1 # Duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);
	tween.tween_method(
	  func(value): tt.set_shader_parameter("current_intensity", value),
	  1.0, # Start value
	  0.0, # End value
	  0.1 # Duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);

func _draw():
	if not is_dead and debug_cirlces:
		# Draw Noise Awareness Circle (Red)
		draw_circle(Vector2.ZERO, noise_awareness_circle / scale.x, Color(1, 0, 0, 0.3))
		# Draw Visual Awareness Circle (Green)
		draw_circle(Vector2.ZERO, visual_awareness_circle / scale.x, Color(0, 1, 0, 0.3))
		# Draw Jump Circle (Blue)
		draw_circle(Vector2.ZERO, jump_circle / scale.x, Color(0, 0, 1, 0.3))

func play_random_growl_sound() -> void:
	if not is_dead and enemy_state != Enums.EnemyState.JUMP:
		var random_index: int = randi_range(1, 5) - 1
		play_growl(random_index)

func play_growl(index: int) -> void:
	var sound_path: String = sound_files[index]
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
	anim_zombie.material = anim_zombie.material.duplicate()
	anim_zombie.play("walk")
	ray_cast_2d.target_position.x = visual_awareness_circle
	call_deferred("nav_setup")
	# line2dexample()
	
func nav_setup():
	await get_tree().physics_frame
	if target:
		print("set up nav")
		navigation_agent_2d.target_position = player.global_position

const blood_spawn_interval = 0.01 # Interval in seconds
var blood_spawn_timer = blood_spawn_interval
var blood_timer_enabled = true
# used in path and line
var blood_path_start_pos = Vector2.ZERO
func _physics_process(delta) -> void:
	if is_dead:
		handle_death(delta)
	elif was_hit:
		handle_hit(delta)
	elif enemy_state == Enums.EnemyState.ATTACHED:
		handle_attached_state(delta)
	else:
		handle_awareness(delta)
		handle_burning(delta)

func handle_death(delta: float) -> void:
	if blood_spawn_timer <= 0 and blood_timer_enabled:
		spawn_blood_path()
	else:
		blood_spawn_timer -= delta
	move_and_slide()
	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func spawn_blood_path() -> void:
	var blood_path: Node2D = blood_path_scene.instantiate()
	blood_path.position = global_position
	if blood_path_start_pos == Vector2.ZERO:
		blood_path_start_pos = global_position
	blood_path.rotation += get_angle_to(player.global_position)
	blood_path.scale = Vector2(4, 4)
	blood_path.modulate.a = randf_range(0.8, 1)
	blood_path.modulate.h = randf_range(0.5, 0.9)
	player.draw_me_add(blood_path)
	blood_spawn_timer = blood_spawn_interval + 0.1

func handle_hit(delta: float) -> void:
	move_and_slide()
	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func handle_attached_state(delta: float) -> void:
	var distance = player.position.distance_to(position)
	velocity = velocity.move_toward(position.direction_to(player.position) * distance, 10000 * delta)
	move_and_slide()

func handle_awareness(delta: float) -> void:
	aquire_target()
	if target:
		handle_target_awareness(delta)
	else:
		enemy_state = Enums.EnemyState.IDLE
		anim_zombie.pause()

func handle_target_awareness(delta: float) -> void:
	var distance_to_player: float = player.position.distance_to(self.position)
	var is_in_jump_zone: bool = distance_to_player <= jump_circle
	var is_in_visual_awareness_zone: bool = (distance_to_player > jump_circle) and (distance_to_player <= visual_awareness_circle)
	var is_in_noise_awareness_zone: bool = (distance_to_player > visual_awareness_circle) and (distance_to_player <= noise_awareness_circle)
	
	if is_in_visual_awareness_zone:
		handle_visual_awareness()
	elif is_in_jump_zone:
		handle_jump_awareness()
	elif is_in_noise_awareness_zone:
		handle_noise_awareness()
	else:
		enemy_state = Enums.EnemyState.IDLE
		anim_zombie.play("walk")
		anim_zombie.pause()

func handle_visual_awareness() -> void:
	enemy_state = Enums.EnemyState.VISUAL
	navigation_agent_2d.target_position = player.global_position
	anim_zombie.play("fly")
	look_at(player.position)
	motion = position.direction_to(navigation_agent_2d.get_next_path_position()) * speed
	move_and_collide(motion)

func handle_jump_awareness() -> void:
	if enemy_state != Enums.EnemyState.JUMP:
		play_growl(11 - 1)
	enemy_state = Enums.EnemyState.JUMP
	navigation_agent_2d.target_position = player.global_position
	anim_zombie.play("fly")
	look_at(player.position)
	motion = position.direction_to(navigation_agent_2d.get_next_path_position()) * speed * 2
	move_and_collide(motion)

func handle_noise_awareness() -> void:
	enemy_state = Enums.EnemyState.NOISE
	var angle: float = get_angle_to(player.position)
	anim_zombie.play("walk")
	if abs(angle) >= 0.1:
		slowly_turn_towards(angle)
		target = null
	else:
		navigation_agent_2d.target_position = player.global_position
		look_at(player.position)
		motion = position.direction_to(navigation_agent_2d.get_next_path_position()) * speed / 2
		move_and_collide(motion)

func handle_burning(delta: float) -> void:
	if is_burning:
		if time_till_burnout <= 0:
			handle_burnout()
		else:
			time_till_burnout -= delta
			
			var vv = time_till_burnout/burnout_time
			# shitty randomness
			var tt = clamp(vv+randf_range(0.1,0.5),0.0,1.0)
			
			anim_zombie.material.set_shader_parameter("tint", tt)
			# for shader we need to to it ourselves

func handle_burnout() -> void:
	print("all burnt out")
	is_dead = true
	health = 0.0
	enemy_state = Enums.EnemyState.DEAD
	timer.stop()
	anim_zombie.pause()
	anim_zombie.play("die")
	fire.visible = false
	fire.emitting = false

func slowly_turn_towards(target_angle, turn_speed = 0.02) -> void:
	rotation = lerp_angle(rotation, rotation + target_angle, turn_speed)

func aquire_target():
	var distance_to_player: float = player.position.distance_to(self.position)
	var is_in_jump_zone: bool = distance_to_player <= jump_circle
	var is_in_visual_awareness_zone: bool = (distance_to_player > jump_circle) and (distance_to_player <= visual_awareness_circle)
	var is_in_noise_awareness_zone: bool = (distance_to_player > visual_awareness_circle) and (distance_to_player <= noise_awareness_circle)
	
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
	var was_dead = is_dead
	if body.is_in_group("bullet"):
		# kill bullet
		# body.get_parent().queue_free()
		var bullet_global_position: Vector2 = body.global_position
		body.queue_free()


		health -= 1.0
		if health <= 0.0:
			is_dead = true
			
			timer.stop()
			fire.visible = false
			fire.emitting = false
			if not was_dead:
				highlight()
				anim_zombie.play("die")
		else:
			was_hit = true
			highlight()
			get_tree().create_timer(0.2).timeout.connect(func():
				was_hit = false
				# turn around towards player..
				# same as look_at()
				var target_angle = get_angle_to(player.position)
				rotation = rotation + target_angle
			)
			
		# todo: spawn some blood particle
		sfx_gore_splash.pitch_scale = randf_range(0.7, 1)
		sfx_gore_splash.play()
		
		# 8-11 die
		play_growl(randi_range(8, 11) - 1)
		
		# no effect when hurt only
		# Calculate the impact direction
		
		# the next three lines are the same
		#var impact_direction:Vector2 = (global_position - bullet_global_position).normalized()
		#var impact_direction:Vector2 = global_position.direction_to(bullet_global_position)*-1
		var impact_direction: Vector2 = bullet_global_position.direction_to(global_position)
		anim_impact.rotation += position.angle_to(player.position)
		anim_impact.visible = true
		anim_impact.speed_scale = sfx_gore_splash.pitch_scale
		anim_impact.play()
		# Apply impact force
		var impact_force = randf_range(150, 190)
		velocity += impact_direction * impact_force
	elif body.is_in_group("fire"):
		body.queue_free()
		is_burning = true
		speed = 2.5
		fire.visible = true
		fire.emitting = true
		# start the fire!
	elif body.is_in_group("shrapnel"):
		Messenger.screenshake.emit(1)
		var shrapnel_force: float = randf_range(0.8, 1)
		health -= shrapnel_force
		if health <= 0.0:
			is_dead = true
			fire.visible = false
			fire.emitting = false
			timer.stop()
			if not was_dead:
				highlight()
				anim_zombie.pause()
				anim_zombie.call_deferred("play", "die")
				# anim_zombie.play("die")
		else:
			was_hit = true
			highlight()
			get_tree().create_timer(0.2).timeout.connect(func():
				was_hit = false
				slowly_turn_towards(randf_range(0, TAU), 0.2)
			)
		var bullet_global_position: Vector2 = body.global_position
		var impact_direction: Vector2 = bullet_global_position.direction_to(global_position)
		#anim_impact.rotation += position.angle_to(player.postition)
		anim_impact.visible = true
		anim_impact.speed_scale = sfx_gore_splash.pitch_scale
		anim_impact.play()
		# Apply impact force
		var impact_force = randf_range(150 * 2, 190 * 2)
		velocity += impact_direction * impact_force * shrapnel_force
		print("enemy hit by a shrapnel")

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
	anim_zombie.pause()
	
	# transfer tint from shader to enemy for painting
	var tint = anim_zombie.material.get_shader_parameter("tint")
	anim_zombie.modulate.r = tint
	anim_zombie.modulate.g = tint
	anim_zombie.modulate.b = tint
	anim_zombie.material = null
	if is_burning:
		# don't draw fire
		fire.visible = false
	else:
		# spawn footstep trigger at global_position
		spawn_footstep_trigger()
	player.draw_me(self)

func spawn_footstep_trigger():
	print("spawing")
	# instantiate new trigger
	var trigger: Node2D = footstep_trigger_scene.instantiate()
	trigger.global_position = global_position
	get_tree().get_root().add_child(trigger)

func blood_line() -> void:
	# path
	if (blood_path_start_pos):
		var sprite_pos = global_position
		var line_color = Color(1, 0, 0, randf_range(0.01, 0.05)) # Equivalent to 0xaa0000 with alpha 0.1
		var line_width = randf_range(50, 70)
		# Draw the line
		player.draw_blood_line(blood_path_start_pos, sprite_pos, line_color, line_width)
		blood_path_start_pos = sprite_pos

# try this inside the the subviewport
func line2dexample() -> void:
	# Get the Line2D node
	var line: Line2D = $Line2D # Line2D.new
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
	line.default_color = Color(1, 0, 0) # Red color
