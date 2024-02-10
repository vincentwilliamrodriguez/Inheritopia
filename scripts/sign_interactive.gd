extends RigidBody2D

func _ready():
	apply_random_force()
	
func apply_random_force():
	angular_velocity = g.rng.randf_range(-1, 1)

