class_name Sunflower extends Node2D

@export var genes: Array = g.START_GENES
@export var pos: int

func _ready():
	position.x = g.SQUARE_SIZE * (pos % 4)
	position.y = g.SQUARE_SIZE * (pos / 4)
	
	$Label.text = g.get_genome_text(genes)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
