extends RigidBody2D

func _ready() -> void:
	gravity_scale = 0  # No gravity effect
	# Set a lifetime for the shrapnel
	var lifetime:float = 0.5
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	# hit a wall or other stuff
	# todo: player..
	queue_free()
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	#print(body)
	queue_free()
	
