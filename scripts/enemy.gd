extends CharacterBody2D

var motion := Vector2()
var dead := false
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

func _physics_process(delta):
	if dead:
		return
	
	if player.position.distance_to(self.position) < 400:
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
		body.get_parent().queue_free()
		dead = true
		timer.stop()
		animated_sprite_2d.play("die")
		
func _on_timer_timeout():
	play_random_sound()
	start_random_timer()

func _on_anim_zombie_animation_finished():
	print("done")
	# draw to renderr texture?
	queue_free()
