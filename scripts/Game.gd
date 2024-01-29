extends Node2D

@onready var sunflower_class = $Sunflower

var sunflowers: Array[Sunflower]
var breeding_orders = []

func _ready():
	# Initialization
	for i in g.START_POS:
		var sunflower = new_sunflower(i, g.START_GENES)
		sunflowers.append(sunflower)
		add_child.call_deferred(sunflower)
	
	
	for i in len(sunflowers) / 2:
		breeding_orders.append([i, i + (len(sunflowers) / 2)])
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	pass

func _unhandled_input(event):
	if Input.is_action_just_released("next"):
		next_generation()
		
		for i in len(sunflowers) / 2:
			breeding_orders.append([i, i + (len(sunflowers) / 2)])

func _draw():
	for order in breeding_orders:
		var center_1 = sunflowers[order[0]].position + Vector2(64, 64)
		var center_2 = sunflowers[order[1]].position + Vector2(64, 64)
		
		draw_line(center_1, center_2, Color.GREEN, 1.0)
		draw_circle(center_2, 5, Color.GREEN)

func new_sunflower(pos, genes):
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
		genes_seed.append(g.random_item(possible_genes))
	
	return genes_seed

func next_generation():
	var seeds: Array[Sunflower]
	var seed_map = 0x0
	
	for order in breeding_orders:
		var parent_1 = sunflowers[order[0]]
		var parent_2 = sunflowers[order[1]]
		
		var rand_num = g.rng.randfn(1.2, 0.3) if (order[0] == order[1]) else \
					   g.rng.randfn(2.2, 0.3)
					
		var num_of_seed = clampi(roundi(rand_num), 1, 3)
		
		for n in num_of_seed:
			if len(seeds) >= 16:
				break
			
			var seed_genes = breed(parent_1, parent_2)
			var seed_pos = find_free_tile(parent_2.pos, seed_map)
			var seed = new_sunflower(seed_pos, seed_genes)
			
			seeds.append(seed)
			seed_map |= 1 << seed_pos
	
	for sunflower in sunflowers:
		sunflower.queue_free()
	
	sunflowers.clear()
	sunflowers.append_array(seeds)
	
	for seed in seeds:
		add_child.call_deferred(seed)
	
	breeding_orders.clear()

func find_free_tile(pos, map):
	if (map >> pos) & 1 == 0:
		return pos
	
	var neighbors = g.neighbors_lookup[pos].duplicate()
	neighbors.shuffle()
	
	for neighbor in neighbors:
		if (map >> neighbor) & 1 == 0:
			return neighbor
	
	return find_free_tile(neighbors[0], map)
