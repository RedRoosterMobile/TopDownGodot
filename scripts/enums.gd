# Enums.gd
extends Node

enum EnemyState { IDLE, JUMP, VISUAL, NOISE, DEAD, HIT, ATTACHED }
enum PickupItems {
	# food
	SANDWICH,
	SHAKE,
	# guns
	GRENADE,
	FLAMETHROWER,
	# ammo
	FUEL,
	AMMO,
	# items
	NIGHTVISION,
	FLASHLIGHT,
	BATTERY,
	KEYCARD,
	VHS,
	AUDIO_LOG
}

# nyi
enum PlayerThrowableWeapon { GRENADE}
enum Food { SANDWICH, SHAKE }
enum Weapon { DEFAULT, FLAMETHROWER, SHOTGUN }

#const PickupItems = {
#	Food = Food,
#	Weapon = Weapon
#}
