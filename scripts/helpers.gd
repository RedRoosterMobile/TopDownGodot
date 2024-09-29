extends Node

func free_recursively(node:Node):
	for child in node.get_children():
		free_recursively(child)
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.free()  # Immediate deletion
