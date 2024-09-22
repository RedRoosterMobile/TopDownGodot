extends PointLight2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var time:float = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var modifier:float = sin(time*2)*0.5+0.5
	energy = 1 - modifier/2
	time += delta
