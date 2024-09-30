extends Node2D

func _ready() -> void:
	var n:Node2D = get_child(randi_range(0, 4))
	n.visible = true
