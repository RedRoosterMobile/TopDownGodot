extends Sprite2D

var total_frames = 0
var current_frame = 0
var animation_speed = 0.05  # Time in seconds between frames
var timer = 0

func _ready():
	total_frames = hframes * vframes  # Total number of frames

func _process(delta):
	timer += delta
	if timer >= animation_speed:
		timer = 0
		current_frame = (current_frame + 1) % total_frames  # Loop the frames
		frame = current_frame  # Set the current frame
