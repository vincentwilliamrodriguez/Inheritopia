extends Control

@onready var sunflowers_panel = %SunflowersPanel
@onready var sunflower_template = %Sunflower
@onready var sky = %Sky
@onready var sign = %Sign
@onready var counters = %Counters
@onready var tiles = %Tiles
@onready var overlay = %Overlay
@onready var sky_images = [preload("res://images/sky/day.png"),
						   preload("res://images/sky/night.png")]

var sunflowers: Array[Sunflower]
var breeding_orders = []
var preview_map = 0
var generation_num = 1
var phase_num = 1
var score = 0
var selected_parents = [null, null]
var soil_values = []
var events = {
	"Storm": 			g.Storm.new(1, [0.90, 0.70], 0.20, 4),
	"Waterlogging": 	g.Waterlogging.new(2, [0.70, 0.50], 0.00, 2),
	"Drought": 			g.Event.new(2, [0.80, 0.95], 0.25),
	"Pest Invasion": 	g.Pest.new(0, [0.40, 0.40], 0.15, 2),
	"Night": 			g.Event.new(1, [0.85, 0.95], 0.00),
	"Fertility": 		g.Event.new(0, [1.00, 1.00], 0.05)
}

func _ready():
	sign.pivot_offset.x = sign.size.x / 2
	
	# Initialization of tiles
	for i in 16:
		var coords = Vector2i(g.to_2d_x(i), g.to_2d_y(i))
		var value = g.rng.randi_range(0, 1)
		tiles.set_cell(0, coords, value, Vector2i(0, 0))
		soil_values.append(value)
	
	# Initialization of sunflowers
	for i in g.START_POS:
		var sunflower = new_sunflower(i, g.START_GENES)
		sunflowers.append(sunflower)
		sunflowers_panel.add_child.call_deferred(sunflower)

func _process(delta):
	# Updates counters
	var phase_name = g.PHASES[phase_num]
	counters.text = "Generation %s\n%s\nScore: %s" % [generation_num, phase_name, score]
	
	overlay.queue_redraw()

func _input(event):
	# Breeding Phase control
	if phase_num == 1:
		# Next generation
		if Input.is_action_just_released("next"):
			transition_phase()
		
		# Selecting breeding parents
		if event is InputEventMouseButton and event.is_pressed():
			var global_pos = get_viewport().get_mouse_position()
			var local_pos = tiles.to_local(global_pos)
			var map_pos = tiles.local_to_map(local_pos)
			
			if not g.is_inbound(map_pos.x, map_pos.y):
				return
			
			var selected_parent = find_by_pos(g.to_1d_vector(map_pos))
			
			if selected_parent and not selected_parent.is_parent:
				when_parent_selected(selected_parent)
			else:
				reset_selected_parents()
		
func _on_overlay_draw():
	# For breeding phase overlay
	if (phase_num == 1):
		for order in breeding_orders:
			var center_1 = order[0].position + Vector2(g.SQUARE_SIZE / 2, g.SQUARE_SIZE / 2)
			var center_2 = order[1].position + Vector2(g.SQUARE_SIZE / 2, g.SQUARE_SIZE / 2)
			
			overlay.draw_line(center_1, center_2, Color.GREEN, 2.0)
			overlay.draw_circle(center_2, 10, Color.GREEN)
	
	# For event overlay
	for event_name in events:
		if not g.events_overlay[event_name]:
			continue
		
		var event_color = g.events_preview_color[event_name]
		
		if event_name in ["Storm", "Waterlogging", "Pest Invasion"]:
			var event_map = events[event_name].affected_map
			
			for i in 16:
				if g.is_true_in_map(event_map, i):
					overlay.draw_rect(Rect2(g.to_2d_x(i) * g.SQUARE_SIZE, g.to_2d_y(i) * g.SQUARE_SIZE, g.SQUARE_SIZE, g.SQUARE_SIZE), event_color)
		
		elif is_event_active(event_name):
			if event_name == "Night":
				overlay.draw_rect(Rect2(-50, -50, g.SQUARE_SIZE * 4 + 100, g.SQUARE_SIZE * 4 + 100), event_color)
			else:
				overlay.draw_rect(Rect2(0, 0, g.SQUARE_SIZE * 4, g.SQUARE_SIZE * 4), event_color)
	
	# For custom overlay
	for i in 16:
		if g.is_true_in_map(preview_map, i):
			overlay.draw_rect(Rect2(g.to_2d_x(i) * g.SQUARE_SIZE, g.to_2d_y(i) * g.SQUARE_SIZE, g.SQUARE_SIZE, g.SQUARE_SIZE), Color("Red", 0.3))

func new_sunflower(pos, genes):
	var sunflower = sunflower_template.duplicate()
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

func when_parent_selected(parent: Sunflower):
	if not selected_parents[0]:
		selected_parents[0] = parent
		parent.modulate = Color("Yellow")
		
	else:
		selected_parents[1] = parent
		
		for sunflower in selected_parents:
			sunflower.is_parent = true
			sunflower.modulate = Color("Green")
		
		breeding_orders.append(selected_parents)
		reset_selected_parents()

func reset_selected_parents():
	for sunflower in selected_parents:
		if sunflower and not sunflower.is_parent:
			sunflower.modulate = Color("White")
		
	selected_parents = [null, null]

func transition_phase():
	phase_num = 2
	
	var seeds: Array[Sunflower]
	var seed_map = 0x0
	
	for order in breeding_orders:
		var parent_1 = order[0]
		var parent_2 = order[1]
		
		var bonus = 2.0 if is_event_active("Fertility") else \
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
		
	await get_tree().create_timer(0.5).timeout
	
	sunflowers.clear()
	sunflowers.append_array(seeds)
	
	for seed in seeds:
		sunflowers_panel.add_child.call_deferred(seed)
	
	await get_tree().create_timer(0.5).timeout
	
	breeding_orders.clear()
	generation_num += 1
	
	event_phase()

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
	phase_num = 0
	
	for event_name in events:
		var event = events[event_name]
		var is_position_based = (event_name in ["Storm", "Waterlogging", "Pest Invasion"])
		preview_map = 0
		
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
					preview_map = (1 << sunflower.pos)
			
			await get_tree().create_timer(0.5).timeout
			
			for sunflower in perished_sunflowers:
				sunflowers.pop_at(find_index(sunflower))
				sunflower.queue_free()
		
			# Updating existing events
			
			match event_name:
				"Storm":
					events["Waterlogging"].spawn_waterlogged(event)
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
					add_event = is_event_active("Storm")
				"Night":
					add_event = (((generation_num - 1) / 5) % 2) == 1
				_:
					var exclusive = (event_name == "Storm" and is_event_active("Drought")) or \
									(event_name == "Drought" and is_event_active("Storm"))
					var rand = g.rng.randf()
					add_event = (rand < event.spawn_chance) and not exclusive
			
			if add_event:
				event.active_num = 1
				
				match event_name:
					"Storm":
						event.spawn_storm()
					"Pest Invasion":
						event.spawn_pest()
					"Drought":
						events["Waterlogging"].affected_map = 0b0  # drought removes waterlogging
						events["Waterlogging"].active_num = 0
		
		# Reverting tiles affected too long to normal
		if is_position_based:
			event.remove_longest_affected()
	
	
	var current_events = []
	for event_name in events:
		if is_event_active(event_name):
			current_events.append(event_name)
	
	print("Awaw %s %s" % [generation_num, current_events])
	update_event_textures()
	compute_trait_scores()
	check_game_over()
	breeding_phase()

func breeding_phase():
	phase_num = 1

func compute_trait_scores():
	for sunflower in sunflowers:
		for gene in sunflower.genes:
			if (gene > 0):
				score += 5	# For dominant traits
			else:
				score += 8	# For recessive traits

func check_game_over():
	if len(sunflowers) == 0:
		print("Awaw over!")
		
		# To-do: game over pop-up
		get_tree().reload_current_scene()

func update_event_textures():
	# For tiles
	for i in 16:
		var coords = Vector2i(g.to_2d_x(i), g.to_2d_y(i))
		
		if is_event_active("Drought"):
			tiles.set_cell(0, coords, 2, Vector2i(0, 0))
		
		elif g.is_true_in_map(events["Waterlogging"].affected_map, i):
			tiles.set_cell(0, coords, soil_values[i] + 4, Vector2i(0, 0))
		
		else:
			tiles.set_cell(0, coords, soil_values[i], Vector2i(0, 0))
	
	# For the sky
	sky.texture = sky_images[int(is_event_active("Night"))]

func find_index(inp: Sunflower):
	for i in len(sunflowers):
		if sunflowers[i].pos == inp.pos:
			return i
	
	return -1

func find_by_pos(pos: int):
	for sunflower in sunflowers:
		if sunflower.pos == pos:
			return sunflower
	
	return null

func is_event_active(event_name: String):
	return events[event_name].active_num > 0


