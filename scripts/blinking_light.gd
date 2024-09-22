extends PointLight2D

var time: float = 0
# todo: sync with sound?? ask philipp
func _process(delta: float) -> void:
	# Simulate a sawtooth wave that resets to 0 when it hits 1.
	var sawtooth = fmod(time / 2.0, 1.0)
	var extra_flicker = sin(time * 1) * 0.5 + 0.5
	energy = sawtooth
	time += delta * 2.0 + extra_flicker  # Adjust speed by changing this multiplier
