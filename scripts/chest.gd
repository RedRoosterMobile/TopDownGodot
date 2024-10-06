extends Node2D

@export var item:Enums.PickupItems= Enums.PickupItems.SANDWICH

@onready var closed: Sprite2D = $closed
@onready var opened: Sprite2D = $opened
@onready var trigger: Area2D = $trigger

var time = 0.0
var speed = 30.0
var is_empty = false

func _process(delta: float) -> void:
	if not is_empty:
		var zto = sin(time*speed)*0.5+0.5
		closed.material.set_shader_parameter("width", zto)
		time += delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	opened.visible = true
	closed.visible = false
	Messenger.pickup.emit(item)

func _on_area_2d_body_exited(body: Node2D) -> void:
	#if not is_empty:
	is_empty = true
	closed.queue_free()
	trigger.queue_free()
	
