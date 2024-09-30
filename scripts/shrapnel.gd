extends RigidBody2D

func _ready() -> void:
	gravity_scale = 0  # No gravity effect
	name = "Shrapnel"
	# Enable contact monitoring
	#body_contact_monitoring = true
	#body_contacts_reported = 1  # Set to the number of contacts you want to monitor

	# Set a lifetime for the shrapnel
	var lifetime = 2.0
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	#print("on area entered")
	#print(area)
	queue_free()
	pass # Replace with function body.

func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("on area body entered")
	#print(body)
	#if(body.name == "Enemy"):
	#	var enemy:Enemy = body
		#enemy
		#body.queue_free()
	queue_free()
	
