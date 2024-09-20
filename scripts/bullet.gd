extends Node2D

func _on_area_2d_body_entered(body):
	# hit the wall
	if "CosmicLilacLayer" in body.name:
		queue_free()
	elif "InteractableLayer" in body.name:
		queue_free()
