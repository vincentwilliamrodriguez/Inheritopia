extends Node

@onready var sunflower_class = $Sunflower

var sunflowers: Array[Sunflower]
var breeding_orders = [[0, 0], [1, 1], [2, 2], [3, 3]]

func _ready():
	# Initialization
	for i in g.START_POS:
		var sunflower = new_sunflower(i, g.START_GENES, len(sunflowers))
		sunflowers.append(sunflower)
		add_child.call_deferred(sunflower)
	
	for i in 5:
		breed(sunflowers[0], sunflowers[1])
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event):
	if Input.is_action_just_released("next"):
		next_generation()

func new_sunflower(pos, genes, index):
	var sunflower = sunflower_class.duplicate()
	sunflower.visible = true
	sunflower.genes = genes
	sunflower.pos = pos
	return sunflower

func breed(parent_1: Sunflower, parent_2: Sunflower):
	var genes_1 = parent_1.genes
	var genes_2 = parent_2.genes
	var genes_seed = []
	
	for t in len(g.traits):
		var possible_genes = g.breed_lookup[genes_1[t]][genes_2[t]]
		var rand = g.rng.randi_range(0, 3)
		genes_seed.append(possible_genes[rand])
	
	return genes_seed

func next_generation():
	var seeds: Array[Sunflower]
	
	for order in breeding_orders:
		var parent_1 = sunflowers[order[0]]
		var parent_2 = sunflowers[order[1]]
		var genes_seed = breed(parent_1, parent_2)
		var seed = new_sunflower(parent_2.pos, genes_seed, len(seeds))
		seeds.append(seed)
	
	for sunflower in sunflowers:
		sunflower.queue_free()
	
	sunflowers.clear()
	sunflowers.append_array(seeds)
	
	for seed in seeds:
		sunflowers.append(seed)
		add_child.call_deferred(seed)

