extends Sprite2D

@onready var animation_tree := $AnimationTree
var previous_pos: Vector2


func _ready():
	previous_pos = position

func _physics_process(_delta):
	var direction := (position - previous_pos).normalized()
	direction = direction if direction != Vector2.ZERO else Vector2(0.1, 0) # keep facing right when idle
	
	animation_tree.set("parameters/blend_position", direction)
	
	
	previous_pos = position
	
