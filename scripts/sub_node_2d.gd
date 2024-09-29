extends Node2D

var should_draw_blood_line = false
var blood_line_start = Vector2.ZERO
var blood_line_end = Vector2.ZERO
var blood_line_color = Color(1, 0, 0, 1)  # Red color
var blood_line_width = 50.0  # Adjust as needed
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
# func _frame_post_draw():
	
func _process(delta: float) -> void:
	# whatever gets here, free it
	if(get_child_count()):
		get_child(0).queue_free()
