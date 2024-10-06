extends Area2D

func _on_body_entered(body: Node2D) -> void:
	Messenger.bloody_footsteps.emit()
	queue_free()
