extends Node2D
@onready var impact_anim: AnimatedSprite2D = $ImpactAnim
@onready var bullet_rigid_body_2d: RigidBody2D = $BulletRigidBody2D
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim

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
	
	get_tree().create_timer(0.25).timeout.connect(func():
		impact_anim.queue_free()
	)
	handle_explosion()
	
	# final cleanup, needs to happen last
	get_tree().create_timer(0.31).timeout.connect(func():
		queue_free()
	)
	
func handle_explosion():
	if randi_range(1,5) == 1:
		Messenger.screenshake.emit(3)
		explosion_anim.position = bullet_rigid_body_2d.position
		explosion_anim.rotation = bullet_rigid_body_2d.rotation
		explosion_anim.scale *= randf_range(1, 2)
		explosion_anim.modulate.a = randf_range(0.5, 1)
		explosion_anim.stop()
		explosion_anim.play()
		explosion_anim.visible = true
	else:
		Messenger.screenshake.emit(1)
	
