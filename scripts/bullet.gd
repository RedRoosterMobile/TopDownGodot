extends Node2D
@onready var impact_anim: AnimatedSprite2D = $ImpactAnim
@onready var bullet_rigid_body_2d: RigidBody2D = $BulletRigidBody2D

func _on_area_2d_body_entered(body):
	# hit the wall
	if "CosmicLilacLayer" in body.name:
		handle_impact()
	elif "InteractableLayer" in body.name:
		handle_impact()

func handle_impact():
	bullet_rigid_body_2d.queue_free()
	impact_anim.position = bullet_rigid_body_2d.position
	impact_anim.rotation = bullet_rigid_body_2d.rotation
	impact_anim.scale *= randf_range(1, 2)
	impact_anim.stop()
	impact_anim.play()
	impact_anim.visible = true
	get_tree().create_timer(0.2).timeout.connect(func():
		impact_anim.queue_free()
	)
