extends AcceptDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	get_label().label_settings = load("res://themes/dialog_text.tres")
	get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

