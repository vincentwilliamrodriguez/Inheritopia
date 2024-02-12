class_name Sunflower extends Node2D

@export var genes: Array = g.START_GENES
@export var pos: int
@export var is_receiver := false
@export var is_glowing := false
@export var flower_center := Vector2(100, 100)

func _ready():
	position = g.SQUARE_SIZE * g.to_2d_vector(pos)
	
	$Label.text = g.get_genome_text(genes)

func set_glow(val: bool):
	is_glowing = val
	$Glow.visible = val
