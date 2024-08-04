extends CharacterBody2D

var motion = Vector2()

func _physics_process(delta):
	var player = get_parent().get_node("Player")

	position += (player.position - position)/50
	look_at(player.position)
	
	#  velocity = motion
	move_and_collide(motion)

func _on_area_2d_body_entered(body):
	if "BulletRigidBody2D" in body.name:
		queue_free()
		body.get_parent().queue_free()
	
