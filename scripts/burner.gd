extends RigidBody2D

@export var speed:float = 480
@export var distance:float = 400
@export var direction:Vector2 = Vector2.RIGHT
var start_pos:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = direction * speed
	start_pos = position

func _physics_process(delta: float) -> void:
	if position.distance_to(start_pos) > distance:
		queue_free()

# TODO: collision
