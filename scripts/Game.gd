extends Node2D

@onready var sunflower_class = $Sunflower

var sunflowers: Array[Sunflower]
var breeding_orders = []
var preview_map = 0b0
var generation_num = 1

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
		transition_phase()
		event_phase()
		
func _draw():	
	for order in breeding_orders:
		var center_1 = sunflowers[order[0]].position + Vector2(64, 64)
		var center_2 = sunflowers[order[1]].position + Vector2(64, 64)
		
		draw_line(center_1, center_2, Color.GREEN, 1.0)
		draw_circle(center_2, 5, Color.GREEN)
	
	for event_name in g.events:
		var event_color = g.events_preview_color[event_name]
		
		if event_name in ["Storm", "Waterlogging", "Pest Invasion"]:
			var event_map = g.events[event_name].affected_map
			
			for i in 16:
				if g.is_true_in_map(event_map, i):
					draw_rect(Rect2(g.to_2d_x(i) * 128, g.to_2d_y(i) * 128, 128, 128), event_color)
		elif g.is_event_active(event_name):
			draw_rect(Rect2(0, 0, 128 * 4, 128 * 4), event_color)

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

func transition_phase():
	var seeds: Array[Sunflower]
	var seed_map = 0x0
	
	for order in breeding_orders:
		var parent_1 = sunflowers[order[0]]
		var parent_2 = sunflowers[order[1]]
		
		var bonus = 1.0 if g.is_event_active("Fertility") else \
					0.2 if (parent_1.genes[0] > 0) else \
					0.0
					
		var rand_num = g.rng.randfn(1.2 + bonus, 0.3) if (order[0] == order[1]) else \
					   g.rng.randfn(2.2 + bonus, 0.3)
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
	generation_num += 1

func find_free_tile(pos, map):
	if not g.is_true_in_map(map, pos):
		return pos
	
	var neighbors = g.neighbors_lookup[pos].duplicate()
	neighbors.shuffle()
	
	for neighbor in neighbors:
		if not g.is_true_in_map(map, neighbor):
			return neighbor
	
	return find_free_tile(neighbors[0], map)

func event_phase():
	preview_map = 0
	
	for event_name in g.events:
		var event = g.events[event_name]
		var is_position_based = (event_name in ["Storm", "Waterlogging", "Pest Invasion"])
		
		if event.active_num > 0:
			# Applying events
			var perished_sunflowers = []
			
			for sunflower in sunflowers:
				var is_plant_affected = g.is_true_in_map(event.affected_map, sunflower.pos)
				
				if is_position_based and not is_plant_affected:
					continue
				
				var is_dominant = sunflower.genes[event.affected_trait] > 0
				var survival_chance = event.survival_chances[int(is_dominant)]
				
				if g.rng.randf() > survival_chance:
					perished_sunflowers.append(sunflower)
			
			#await get_tree().create_timer(0.5).timeout
			
			for sunflower in perished_sunflowers:
				sunflowers.pop_at(find_index(sunflower))
				sunflower.queue_free()
		
			# Updating existing events
			
			match event_name:
				"Storm":
					g.events["Waterlogging"].spawn_waterlogged()
					event.move_storm()
					event.update_map()
						
				"Pest Invasion":
					var white_sunflowers = 0b0
					for sunflower in sunflowers:
						if (sunflower.genes[0] == 0):	# if flower color is white
							white_sunflowers |= (1 << sunflower.pos)
							
					event.update_map(white_sunflowers)
				
			event.active_num += 1
			
			# Removing events
			var remove_event = false
			match event_name:
				"Storm":
					remove_event = not g.is_inbound(event.eye_pos.x, event.eye_pos.y)
				"Drought":
					remove_event = (event.active_num > 6)
				"Fertility":
					remove_event = (event.active_num > 1)
				"Waterlogging", "Pest Invasion":
					remove_event = (event.affected_map == 0)
				"Night":
					remove_event = (((generation_num - 1) / 5) % 2) == 0
			
			if remove_event:
				event.active_num = 0
		
		# Spawning new events
		else:
			var add_event = false
			
			match event_name:
				"Waterlogging":
					add_event = g.is_event_active("Storm")
				"Night":
					add_event = (((generation_num - 1) / 5) % 2) == 1
				_:
					var exclusive = (event_name == "Storm" and g.is_event_active("Drought")) or \
									(event_name == "Drought" and g.is_event_active("Storm"))
					var rand = g.rng.randf()
					add_event = (rand < event.spawn_chance) and not exclusive
			
			if add_event:
				event.active_num = 1
				
				match event_name:
					"Storm":
						event.spawn_storm()
					"Pest Invasion":
						event.spawn_pest()
		
		# Reverting tiles affected too long to normal
		if is_position_based:
			event.remove_longest_affected()
	
	for i in len(sunflowers) / 2:
		breeding_orders.append([i, i + (len(sunflowers) / 2)])
	
	var current_events = []
	for event_name in g.events:
		if g.is_event_active(event_name):
			current_events.append(event_name)
	
	print("Awaw %s %s" % [generation_num, current_events])

func find_index(inp: Sunflower):
	for i in len(sunflowers):
		if sunflowers[i].pos == inp.pos:
			return i
	
	return -1
