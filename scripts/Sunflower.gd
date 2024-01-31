class_name Sunflower extends Node2D

@export var genes: Array = g.START_GENES
@export var pos: int
@export var is_parent: bool = false

func _ready():
	position.x = g.SQUARE_SIZE * g.to_2d_x(pos)
	position.y = g.SQUARE_SIZE * g.to_2d_y(pos)
	
	$Label.text = g.get_genome_text(genes)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
