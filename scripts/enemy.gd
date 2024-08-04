extends CharacterBody2D

var motion := Vector2()
@onready var sfx_zombie_growl := $Sprite2D/SfxZombieGrowl
@onready var timer := $Timer

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

func _physics_process(delta):
	var player: CharacterBody2D = get_parent().get_node("Player")
	position += (player.position - position) / randf_range(55, 85)
	look_at(player.position)
	move_and_collide(motion)

func _on_area_2d_body_entered(body):
	if "BulletRigidBody2D" in body.name:
		queue_free()
		body.get_parent().queue_free()

func _on_timer_timeout():
	play_random_sound()
	start_random_timer()
