extends Area3D

# EXPORTS ----------------------------------------------------------------------
@export var speed: float = 50.0


# CODE -------------------------------------------------------------------------
func _process(delta: float) -> void:
	position += transform.basis * Vector3(0, 0, -speed) * delta
