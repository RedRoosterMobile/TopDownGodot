extends Node2D

var should_draw_blood_line = false
var blood_line_start = Vector2.ZERO
var blood_line_end = Vector2.ZERO
var blood_line_color = Color(1, 0, 0, 1)  # Red color
var blood_line_width = 50.0  # Adjust as needed

var free_interval:float = 2
var free_timer:float=free_interval
# @onready var sv:SubViewport = $".."
# try Line2D with a texture or gradient here?

func _draw():
	if should_draw_blood_line:
		# print("from-to", blood_line_start, blood_line_end)
		draw_line(blood_line_start, blood_line_end, blood_line_color, blood_line_width)
		should_draw_blood_line = false  # Set to false if you want to draw the line only once

func draw_blood_line(sprite_pos, random_pos, line_color, line_width):
	blood_line_start = sprite_pos
	blood_line_end = random_pos
	blood_line_color = line_color
	blood_line_width = line_width
	should_draw_blood_line = true
	queue_redraw()

func _process(delta: float) -> void:
	return
	# whatever gets here, free it
	if(free_timer <= 0 and get_child_count()):
		var fc:Node = get_child(0)
		# hack..
		if (fc.name != "BloodPath"):
			fc.queue_free()
			print("interval hit")
			free_timer = free_interval
	free_timer -= delta
	pass
