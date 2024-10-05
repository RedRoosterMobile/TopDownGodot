extends Node

signal screenshake(strength: float)
signal shockwave(x: float,y: float)

# the player's  stuff
signal bloody_footsteps()
signal draw_node(node: Node2D)
signal pickup(item: Enums.PickupItems)

# unused
signal explosion
