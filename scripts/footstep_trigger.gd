extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("send signal body")
	Messenger.bloody_footsteps.emit()
	queue_free()
