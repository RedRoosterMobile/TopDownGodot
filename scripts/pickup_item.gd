extends Area2D
# to use this, set a type and add an image (e.g. of a sandwich)

@export var item_type: Enums.PickupItems = Enums.PickupItems.SANDWICH

@onready var pickup_zone: CollisionShape2D = $PickupZone

func _on_body_entered(body: Node2D) -> void:
	print("picked up ", Enums.PickupItems.find_key(item_type))
	const data = {
		Food = "Food",
		Food2 = "Food2"
	}
	Messenger.pickup.emit(item_type,data)
	queue_free()
