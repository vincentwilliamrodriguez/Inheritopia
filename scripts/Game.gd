extends Control

@onready var popup_layer = %PopupLayer
@onready var sunflowers_panel = %SunflowersPanel
@onready var sunflower_template = %Sunflower
@onready var garden = %Garden
@onready var sky = %Sky
@onready var sign = %Sign
@onready var counters = %Counters
@onready var tiles = %Tiles
@onready var overlay = %Overlay
@onready var traits_panel = %TraitsPanel

@onready var SKY_IMAGES = [preload("res://images/sky/day.png"),
						   preload("res://images/sky/night.png")]
@onready var SW_RESOURCES = [preload("res://themes/weakness.tres"),
  							 preload("res://themes/strength.tres")]
@onready var SW_SIGNS = [preload("res://images/icons/sw_minus.png"),
  						 preload("res://images/icons/sw_plus.png")]
@onready var GARDEN_BG = [preload("res://images/background/grass.png"),
						  preload("res://images/background/dry_grass.jpg")]
						
var sunflowers: Array[Sunflower]
var breeding_orders: Array
var preview_map: int
var generation_num: int
var phase_num: int
var score: int
var correct_puzzles: int
var hovered_sunflower: Sunflower
var selected_parents: Array
var soil_values: Array
var events: Dictionary

func _init_variables():
	sunflowers = []
	breeding_orders = []
	preview_map = 0
	generation_num = 1
	phase_num = 1
	score = 0
	correct_puzzles = 0
	hovered_sunflower = null
	selected_parents = [null, null]
	soil_values = []
	events = {
		"Storm": 			g.Storm.new(1, [0.90, 0.70], 0.20, 4),
		"Waterlogging": 	g.Waterlogging.new(2, [0.70, 0.50], 0.00, 2),
		"Drought": 			g.Event.new(2, [0.80, 0.95], 0.25),
		"Pest Invasion": 	g.Pest.new(0, [0.40, 0.40], 0.15, 2),
		"Night": 			g.Event.new(1, [0.85, 0.95], 0.00),
		"Fertility": 		g.Event.new(0, [1.00, 1.00], 0.05)
	}

func _ready():
	_init_variables()
	
	sign.pivot_offset.x = sign.size.x / 2
	
	# Initialization of UI
	update_traits_panel()
	update_breeding_panel()
	
	# Initialization of tiles
	for i in 16:
		var coords = Vector2i(g.to_2d_x(i), g.to_2d_y(i))
		var value = g.rng.randi_range(0, 1)
		tiles.set_cell(0, coords, value, Vector2i(0, 0))
		soil_values.append(value)
		
	update_event_textures()
	
	# Initialization of sunflowers
	for i in g.START_POS:
		var sunflower = new_sunflower(i, g.START_GENES)
		sunflowers.append(sunflower)
		sunflowers_panel.add_child.call_deferred(sunflower)

func _process(delta):
	# Updates counters
	var phase_name = g.PHASES[phase_num]
	counters.text = g.counters_text % [generation_num, score, phase_name]
	
	overlay.queue_redraw()

func _input(event):	
	# Breeding Phase control
	if phase_num == 1:		
		# Selecting breeding parents
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				var selected_parent = get_sunflower_by_mouse()
				
				if selected_parent and not selected_parent.is_receiver:
					when_parent_selected(selected_parent)
					
			if event.button_index == MOUSE_BUTTON_RIGHT:
				reset_selected_parents()
	
	# Trait info
	if event is InputEventMouseMotion:
		var sunflower = get_sunflower_by_mouse()
		# only change when a sunflower is hovered at, and when no hovered sunflower or when different sunflower is hovered
		if sunflower and \
			(not hovered_sunflower or \
			 not hovered_sunflower.pos == sunflower.pos):
				hovered_sunflower = sunflower
				update_traits_panel()

func next_generation():
	transition_phase()

func when_parent_selected(parent: Sunflower):
	if not selected_parents[0]:
		selected_parents[0] = parent
		
	elif not selected_parents[1]:
		selected_parents[1] = parent
		parent.modulate = Color("Yellow")
	
	update_breeding_panel()

func reset_selected_parents():
	for sunflower in selected_parents:
		if sunflower and not sunflower.is_receiver:
			sunflower.modulate = Color("White")
		
	selected_parents = [null, null]
	update_breeding_panel()

func confirm_breeding():
	if selected_parents[0] and selected_parents[1]:
		selected_parents[1].is_receiver = true
		selected_parents[1].modulate = Color("Green")
		
		breeding_orders.append(selected_parents)
		reset_selected_parents()

func update_traits_panel():
	var preview_panel = traits_panel.get_node("%SunflowerPreview")
	var traits_info = traits_panel.get_node("%TraitsInfo")
	
	if hovered_sunflower:
		preview_panel.get_node("Name").modulate.a = 1
		traits_info.get_node("MarginContainer").modulate.a = 1
		var genes = hovered_sunflower.genes
		
		# Preview Panel
		update_preview(preview_panel.get_node("Card"), hovered_sunflower)
		preview_panel.get_node("Name").text = g.get_genome_text(genes)
		
		# Traits info
		for trait_num in 3:
			var base = traits_info.get_node("MarginContainer/VBoxContainer/%s" % trait_num)
			var pheno_num = int(genes[trait_num] > 0)
			
			var genotype_label = base.get_node("Info/Genotype")
			var genotype = g.genotypes[trait_num][genes[trait_num]]
			var phenotype_color = g.phenotype_colors[trait_num][pheno_num]
			genotype_label.text = "[color=%s]%s[/color]" % [phenotype_color, genotype]
			
			var phenotype_label = base.get_node("Info/Phenotype")
			var phenotype = g.phenotypes[trait_num][pheno_num]
			var font_size = 36 if (phenotype != "Shallow-rooted") else 32
			phenotype_label.text = "[font_size=%s][outline_size=8] %s[/outline_size][/font_size]" % [font_size, phenotype]
			
			for sw_num in 2:
				var sw: Control = base.get_node("sw/%s" % sw_num)
				
				var sw_sign: TextureRect = sw.get_node("Sign")
				var strength_num = int(sw_num == (1 - pheno_num))
				var more_or_less = "More" if strength_num == 1 else "Less"
				sw.add_theme_stylebox_override("panel", SW_RESOURCES[strength_num])
				sw_sign.texture = SW_SIGNS[strength_num]
				sw.tooltip_text = g.sw_tooltips[trait_num][sw_num] % more_or_less
			
	else:
		preview_panel.get_node("Name").modulate.a = 0
		traits_info.get_node("MarginContainer").modulate.a = 0

func update_breeding_panel():
	var breeding_panel = get_node("%BreedingPanel")
	var punnett_square_tabs = get_node("%PunnettSquareTabs")
	
	# Breeding Parents Preview
	for parent_num in 2:
		var base = breeding_panel.get_node("ParentsPreview/%s" % parent_num)
		update_preview(base, selected_parents[parent_num])
	
	# Punnett square
	for trait_num in 3:
		var punnett_square = punnett_square_tabs.get_node("%s/PunnettSquare" % trait_num)
		var offspring_grid = punnett_square.get_node("%Grid")
		
		# Shows alleles of each trait of each parent
		for parent_num in 2:
			for allele_num in 2:
				var allele_label = punnett_square.get_node("%s/%s" % [parent_num, allele_num])
				allele_label.text = " "
				
				if selected_parents[parent_num]:
					var gene = selected_parents[parent_num].genes[trait_num]
					var is_allele_dominant = int(g.is_true_in_map(gene, 1 - allele_num))
					
					var allele_color = g.phenotype_colors[trait_num][is_allele_dominant]
					var allele_letter = g.alleles[trait_num][is_allele_dominant]
					allele_label.text = "[color=%s]%s[/color]" % [allele_color, allele_letter]
		
		# Shows offspring's possible genotypes
		if selected_parents[0] and selected_parents[1]:
			var gene_1 = selected_parents[0].genes[trait_num]
			var gene_2 = selected_parents[1].genes[trait_num]
			var child_genotypes = g.breed_lookup[gene_1][gene_2]
			var is_one_parent_glowing = selected_parents[0].is_glowing or \
										selected_parents[1].is_glowing
			
			for square_num in 4:
				var square_label = offspring_grid.get_node("%s/Label" % square_num)
				var puzzle_btn = square_label.get_node("Puzzle")
				var child_gene = child_genotypes[square_num]
				
				var child_genotype = g.genotypes[trait_num][child_gene]
				var child_color = g.phenotype_colors[trait_num][int(child_gene > 0)]
				square_label.text = "[center][color=%s]%s[/color][/center]" % [child_color, child_genotype]
				
				if is_one_parent_glowing:
					puzzle_btn.visible = true
					
					for i in range(1, 4):
						var puzzle_num = [-1, 3, 2, 0][i]
						var puzzle_option = g.genotypes[trait_num][puzzle_num]
						puzzle_btn.set_item_text(i, puzzle_option)
					
					if puzzle_btn.item_selected.is_connected(_on_puzzle_selected):
						puzzle_btn.item_selected.disconnect(_on_puzzle_selected)
					puzzle_btn.item_selected.connect(_on_puzzle_selected.bind(child_gene, puzzle_btn))
				
				else:
					puzzle_btn.visible = false
		else:
			for square_num in 4:
				var square_label = offspring_grid.get_node("%s/Label" % square_num)
				var puzzle_btn = square_label.get_node("Puzzle")
				square_label.text = " "
				puzzle_btn.visible = false
				puzzle_btn.select(0)

func update_preview(node: Node, sunflower: Sunflower):
	for previewous in node.get_children():
		if previewous.name != "Shadow":
			previewous.queue_free()
	
	if not sunflower:
		return
	
	var preview = sunflower.duplicate(true)
	preview.scale = (200.0 / 250.0) * node.size / 200.0
	
	var cur_size = Vector2(200, 200) * preview.scale
	preview.position = (node.size - cur_size) / 2
	preview.modulate = Color("White")
	node.add_child.call_deferred(preview)

func _on_puzzle_selected(id: int, correct: int, puzzle_btn: OptionButton):
	var attempt = [-1, 3, 2, 0][id]
	
	if attempt == correct:
		puzzle_btn.visible = false
		correct_puzzles += 1
		# TODO: Add sound effect
	else:
		puzzle_btn.select(0) # Sets it back to question mark
		# TODO: Add sound effect
	
	# Player gets enough puzzles correct
	if correct_puzzles >= 8:
		score += 50
		
		var sunflower_map = 0b0
		
		for sunflower in sunflowers:
			sunflower_map |= (1 << sunflower.pos)
			
		var new_sunflower_pos = find_free_tile(g.rng.randi_range(0, 15), sunflower_map)
		var new_sunflower = new_sunflower(new_sunflower_pos, g.START_GENES)
		sunflowers.append(new_sunflower)
		sunflowers_panel.add_child.call_deferred(new_sunflower)
		
		for sunflower in sunflowers:
			if sunflower.is_glowing:
				sunflower.set_glow(false)
		
		update_breeding_panel()
		

func _on_overlay_draw():
	# For breeding phase overlay
	if (phase_num == 1):
		# Selected parents
		if selected_parents[0]:
			var center_1 = selected_parents[0].position + Vector2(g.SQUARE_SIZE / 2, g.SQUARE_SIZE / 2)
			var center_2 = overlay.to_local(get_viewport().get_mouse_position())
			
			if selected_parents[1]:
				center_2 = selected_parents[1].position + Vector2(g.SQUARE_SIZE / 2, g.SQUARE_SIZE / 2)
			
			overlay.draw_line(center_1, center_2, g.SELECTED_PARENT_COLOR, 5.0)
			overlay.draw_circle(center_2, 10, g.SELECTED_PARENT_COLOR)
		
		# Already parents
		for order in breeding_orders:
			var center_1 = order[0].position + Vector2(g.SQUARE_SIZE / 2, g.SQUARE_SIZE / 2)
			var center_2 = order[1].position + Vector2(g.SQUARE_SIZE / 2, g.SQUARE_SIZE / 2)
			
			overlay.draw_line(center_1, center_2, g.PARENT_COLOR, 5.0)
			overlay.draw_circle(center_2, 10, g.PARENT_COLOR)
	
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
	
	if g.rng.randf() < g.GLOWING_CHANCE:
		sunflower.set_glow(true)
		
	return sunflower

func breed(parent_1: Sunflower, parent_2: Sunflower):
	var genes_1 = parent_1.genes
	var genes_2 = parent_2.genes
	var genes_seed = []
	
	for t in len(g.traits):
		var possible_genes = g.breed_lookup[genes_1[t]][genes_2[t]]
		genes_seed.append(g.random_item(possible_genes))
	
	return genes_seed

func undo_breeding():
	reset_selected_parents()
	
	if len(breeding_orders) > 0:
		var last_order = breeding_orders.pop_back()[1]
		last_order.is_receiver = false
		last_order.modulate = Color("White")

func restart_game(is_gameover = false):	
	if is_gameover or phase_num == 1:
		for sunflower in sunflowers:
			sunflower.queue_free()
		
		_ready()

func show_popup(name: String):
	popup_layer.get_node(name).show()
	popup_layer.get_node("Shade").visible = true

func hide_popup():
	for popup in popup_layer.get_children():
		if popup is Window:
			popup.hide()
	
	popup_layer.get_node("Shade").visible = false

func transition_phase():
	phase_num = 2
	selected_parents = [null, null]
	correct_puzzles = 0
	update_breeding_panel()
	
	var seeds: Array[Sunflower]
	var seed_map = 0x0
	
	for order in breeding_orders:
		var parent_1 = order[0]
		var parent_2 = order[1]
		
		var bonus = 2.0 if is_event_active("Fertility") else \
					0.2 if (parent_1.genes[0] > 0) else \
					0.0
					
		var rand_num = g.rng.randfn(1.2 + bonus, 0.3)
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
		
	for sunflower in sunflowers:
			if sunflower.is_glowing:
				print("Awaw")
				
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
	
	%SignBody.apply_random_force()
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
		show_popup("GameoverScreen")
		save_scores()
		
		var awaw = load_scores()
		%GameoverScreen.get_label().text = g.gameover_text % [generation_num, score, awaw["HS_generation"], awaw["HS_score"]]
		
func save_scores():	
	var hs_generation = 0
	var hs_score = 0
	var past_data = load_scores()
	
	if past_data:
		hs_generation = past_data["HS_generation"]
		hs_score = past_data["HS_score"]
	
	var save_game = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var data = {
		"HS_generation": max(hs_generation, generation_num),
		"HS_score": max(hs_score, score)
	}
	
	var json_string = JSON.stringify(data)
	save_game.store_line(json_string)


func load_scores():
	if not FileAccess.file_exists("user://savegame.save"):
		return null

	var save_game = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json_string = save_game.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return null

	return json.get_data()
	
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
	sky.texture = SKY_IMAGES[int(is_event_active("Night"))]
	
	# For the garden's background
	garden.texture = GARDEN_BG[int(is_event_active("Drought"))]
	

func find_index(inp: Sunflower):
	for i in len(sunflowers):
		if sunflowers[i].pos == inp.pos:
			return i
	
	return -1

func find_by_pos(pos: int):
	for sunflower in sunflowers:
		if is_instance_valid(sunflower) and sunflower.pos == pos:
			return sunflower
	
	return null

func is_event_active(event_name: String):
	return events[event_name].active_num > 0

func get_sunflower_by_mouse():
	var global_pos = get_viewport().get_mouse_position()
	var local_pos = tiles.to_local(global_pos)
	var map_pos = tiles.local_to_map(local_pos)
	
	if not g.is_inbound(map_pos.x, map_pos.y):
		return null
	
	return find_by_pos(g.to_1d_vector(map_pos))

