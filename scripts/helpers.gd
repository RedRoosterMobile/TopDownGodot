extends Node

func free_recursively(node:Node):
	for child in node.get_children():
		free_recursively(child)
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.free()  # Immediate deletion

func bounce_checker(
	current_velocity: Vector2,
	previous_normalized_velocity: Vector2,
	callback: Callable
) -> Vector2:
	var current_velocity_normalized = current_velocity.normalized()
	var diff = current_velocity_normalized - previous_normalized_velocity
	if diff.length_squared() > 0.7:
		print("bounce")
		callback.call()
	return current_velocity_normalized
