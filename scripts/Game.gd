extends Node

@onready var sunflower_class = $Sunflower

var sunflowers: Array[Sunflower]

func _ready():
	# Initialization
	for i in g.START_POS:
		new_sunflower(i, g.START_GENES)
	
	for i in 5:
		breed(sunflowers[0], sunflowers[1])
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func new_sunflower(pos, genes):
	var sunflower = sunflower_class.duplicate()
	sunflower.name = "Sunflower" + str(len(sunflowers))
	sunflower.visible = true
	sunflower.genes = genes
	sunflower.pos = pos
	sunflowers.append(sunflower)
	add_child.call_deferred(sunflower)

func breed(parent_1: Sunflower, parent_2: Sunflower):
	var genes_1 = parent_1.genes
	var genes_2 = parent_2.genes
	var genes_child = []
	
	for t in len(g.traits):
		var possible_genes = g.breed_lookup[genes_1[t]][genes_2[t]]
		var rand = g.rng.randi_range(0, 3)
		genes_child.append(possible_genes[rand])
	
	print(genes_child)
