extends RigidBody2D

func _ready():
	apply_random_force()
	
func apply_random_force():
	angular_velocity = g.rng.randf_range(-1, 1)

func _on_counters_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_pos = to_local(get_viewport().get_mouse_position())
		angular_velocity = remap(mouse_pos.x, -150, 150, -1.5, 1.5)
