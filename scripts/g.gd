extends Node

const SQUARE_SIZE = 200
const START_POS = [5, 6, 9, 10]
const START_GENES = [2, 2, 2]
const GLOWING_CHANCE = 0.10
const START_SPAWN_FACTOR = 0.5
const SELECTED_PARENT_COLOR = Color("Yellow", 0.5)
const PARENT_COLOR = Color("Green", 0.5)
const PHASES = ["Event Phase", "Breeding Phase", "Transition Phase"]
const SAVE_LOCATION = "user://savegame.save"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var breed_lookup = []
var neighbors_lookup = []

var traits = ['y', 't', 'r']
var alleles = [
	['y', 'Y'],
	['t', 'T'],
	['r', 'R']
]
var genotypes = [
	["yy", "yY", "Yy", "YY"],
	["tt", "tT", "Tt", "TT"],
	["rr", "rR", "Rr", "RR"]
]
var phenotypes = [
	["White", "Yellow"],
	["Short", "Tall"],
	["Shallow-rooted", "Deep-rooted"]
]
var phenotype_colors = [
	["#ffffff", "#f8e400"],
	["#006100", "#04e104"],
	["#734c00", "#c38100"]
]
var events_preview_color = {
	"Storm": 			Color("White", 0.2),
	"Waterlogging": 	Color("Blue", 0.2),
	"Drought": 			Color("Orange", 0.05),
	"Pest Invasion": 	Color("Red", 0.2),
	"Night": 			Color("Black", 0.3),
	"Fertility": 		Color("Yellow", 0.1)
}
var events_overlay = {
	"Storm": 			false,
	"Waterlogging": 	false,
	"Drought": 			false,
	"Pest Invasion": 	false,
	"Night": 			true,
	"Fertility": 		false
}

var sw_tooltips = [
	["%s seed production", "%s resistant to pests"],
	["%s likely to survive nights", "%s resistant to storms"],
	["%s likely to survive droughts", "%s resistant to waterlogging"]
]

var gameover_text = "Good job! You survived %s generations and got a score of %s.\n\nYour highscores are now %s generations and a score of %s."
var counters_text = "[center][color=\"#ddd\"][font_size=24]Generation[/font_size][/color] %s\n[color=\"#ddd\"][font_size=24]Score[/font_size][/color] %s\n%s[/center]"

var tutorial_lines = [
	"Awaw",
	"Welcome to the magical garden of Inheritopia, young apprentice! I'm Mellifera, the garden's Bee Guardian.",
	"We have been keeping its harmony for ages, but the mysterious force known as \"The Mogusa\" seeks to disrupt the peace through calamities and events.",
	"We'll need your help to save Inheritopia, and for that I am giving you the power of the bees to breed the last remaining sunflowers.",
	"Hover over a sunflower to reveal its traits, including its flower color, stem height, and root depth.",
	"This panel shows its phenotype and genotype for the three traits. This also shows its strengths and weaknesses against The Mogusa's disasters.",
	"Now, click on these two sunflowers to select them for breeding. You can see them in the breeding panel on the right side. Right click to deselect, if needed.",
	"This is the Punnett square. It shows you how the parents' traits combine during breeding. This will be useful to predict what the children will look like.",
	"Click \"Breed\" or press space to confirm your breeding order. If you think you made a mistake, you may click the adjacent undo button.",
	"Now, my apprentice, breed the remaining sunflowers. Let the magic of genetics happen in our garden.",
	"Ready to progress? Click \"Next Generation\" or press Enter and see the majestic bees pollinate the sunflowers according to your commands.",
	"Oh no, a storm approaches! Let's see how our sunflowers fare against it.",
	"Notice how the shorter plants coped better against the storm? This is why it's important to adapt your plants' traits based on the events.",
	"One last thing - keep an eye out for glowing sunflowers. Select this and another sunflower to proceed.",
	"As you can see, a glowing sunflower unlocks puzzles in the Punnett Squares. Solve 8 of them to reveal its secret bonus.",
	"Ta-da! Eight correct answers give you a new sunflower: a special one that you can breed when you're stuck with homozygous traits.",
	"Good luck, dear apprentice! There are more events looming, but I'll let you discover those by yourself. Goodbye!"
]


@onready var flower_images = [
	preload("res://images/sunflower/sunflower_00.png"),
	preload("res://images/sunflower/sunflower_01.png")
]
@onready var glow_images = [
	preload("res://images/sunflower/sunflower_00_glow.png"),
	preload("res://images/sunflower/sunflower_01_glow.png")
]

class Event:
	var affected_map: int
	var affected_trait: int
	var base_spawn_chance: float
	var spawn_chance: float
	var survival_chances: Array
	var active_num: int
	var past_affected_map: Array
	var tile_lasts_for: int
	var animation: AnimationMixer
	
	func _init(inp_trait, inp_survival, inp_spawn, inp_tile = 0):
		affected_trait = inp_trait
		survival_chances = inp_survival
		base_spawn_chance = inp_spawn
		spawn_chance = inp_spawn
		tile_lasts_for = inp_tile
		
		for i in tile_lasts_for:
			past_affected_map.append(0b0)
	
	
	func remove_longest_affected():
		var longest_affected = affected_map
		
		for map in past_affected_map:
			longest_affected &= map
		
		affected_map ^= longest_affected	# removing longest affected tiles from the map
		past_affected_map.pop_front()
		past_affected_map.push_back(affected_map)

class Storm:
	extends Event
	var eye_pos: Vector2i
	var dir: Vector2i
	var storm_visuals: Node2D
	var storm_player: AnimationPlayer
	
	func spawn_storm(is_tutorial := false):
		dir = Vector2i(g.rng.randi_range(-1, 1), g.rng.randi_range(-1, 1))
		if dir == Vector2i(0, 0):
			dir = Vector2i(1, 0)
		
		if is_tutorial:
			dir = Vector2(-1, 1)
		
		match dir:
			Vector2i(-1, -1):	eye_pos = Vector2i(3, 3)
			Vector2i(-1, 0):	eye_pos = Vector2i(3, 1)
			Vector2i(-1, 1):	eye_pos = Vector2i(3, 0)
			Vector2i(0, -1):	eye_pos = Vector2i(2, 3)
			Vector2i(0, 1):		eye_pos = Vector2i(1, 0)
			Vector2i(1, -1):	eye_pos = Vector2i(0, 3)
			Vector2i(1, 0):		eye_pos = Vector2i(0, 1)
			Vector2i(1, 1):		eye_pos = Vector2i(0, 0)
			
		update_map()
		
	func move_storm():
		var move_storm_anim: Animation = storm_player.get_animation("MoveStorm")
		move_storm_anim.track_set_key_value(0, 0, to_storm_visuals_pos(eye_pos))
		
		eye_pos += dir
		
		move_storm_anim.track_set_key_value(0, 1, to_storm_visuals_pos(eye_pos))
		storm_player.play("MoveStorm")
	
	func update_map():
		affected_map = 0
		
		if g.is_inbound(eye_pos.x, eye_pos.y):
			var eye_pos_1d = g.to_1d_vector(eye_pos)
			affected_map |= (1 << eye_pos_1d)
			
			for neighbpr in g.neighbors_lookup[eye_pos_1d]:
				affected_map |= (1 << neighbpr)
		
		storm_visuals.position = to_storm_visuals_pos(eye_pos)
	
	func to_storm_visuals_pos(inp_eye_pos: Vector2):
		return (Vector2(inp_eye_pos) + Vector2(0.6, 0.5)) * g.SQUARE_SIZE
	
	func show():
		storm_player.play("ShowStorm")
	
	func hide():
		storm_player.play("HideStorm")
	
class Waterlogging:
	extends Event
	const FLOOD_CHANCE = 0.20
	
	func spawn_waterlogged(storm: Storm):
		var storm_map = storm.affected_map
		
		for i in 16:
			if g.is_true_in_map(storm_map, i) and (g.rng.randf() < FLOOD_CHANCE):
				affected_map |= (1 << i)

class Pest:
	extends Event
	const PEST_CHANCE = 0.10
	const PEST_CHANCE_WHITE = 0.02
	
	func spawn_pest():
		var pest_pos = g.random_item([0, 3, 12, 15])
		affected_map |= (1 << pest_pos)
	
	func update_map(white_sunflowers):
		var new_affected_map = affected_map
		
		for i in 16:
			if g.is_true_in_map(affected_map, i):
				for neighbor in g.neighbors_lookup[i]:
					var spread_chance = PEST_CHANCE_WHITE if g.is_true_in_map(white_sunflowers, i) else \
										PEST_CHANCE
										
					if (g.rng.randf() < spread_chance):
						new_affected_map |= (1 << neighbor)
		
		affected_map = new_affected_map

func _ready():
	# Initialize breed_lookup
	for i in 4:
		breed_lookup.append([])
		for j in 4:
			breed_lookup[i].append(monohybrid_cross(i, j))
	
	# Initialize neighbors_lookup
	for i in 16:
		neighbors_lookup.append([])
		var cur_x = to_2d_x(i)
		var cur_y = to_2d_y(i)
		
		for dir_x in [-1, 0, 1]:
			for dir_y in [-1, 0, 1]:
				var new_x = cur_x + dir_x
				var new_y = cur_y + dir_y
				
				if not (dir_x == 0 and dir_y == 0) and \
					   is_inbound(new_x, new_y):
					neighbors_lookup[i].append(to_1d(new_x, new_y))
	


func to_1d(x: int, y: int):
	return x + 4 * y

func to_1d_vector(vector: Vector2i):
	return int(vector.x + 4 * vector.y)

func to_2d_x(n: int):
	return n % 4
	
func to_2d_y(n: int):
	return n / 4

func to_2d_vector(n: int):
	return Vector2(n % 4, n / 4)

func is_inbound(x: int, y: int):
	return (x >= 0 and x < 4) and \
		   (y >= 0 and y < 4)

func is_true_in_map(map: int, i: int):
	return (((map >> i) & 1) == 1)

func monohybrid_cross(gene_1: int, gene_2: int):
	var res = []
	
	for i in 2:
		for j in 2:
			var allele_1 = (gene_1 >> (1-i)) & 1
			var allele_2 = (gene_2 >> (1-j)) & 1
			var child_gene = (allele_1 << 1) + allele_2
			
			res.append(child_gene if (child_gene != 1) else 2)
			
	return res

func get_genome_text(genes: Array):
	var res = ""
	
	for i in len(traits):
		res += genotypes[i][genes[i]]
	
	return res

func random_item(array: Array):
	return array[rng.randi_range(0, len(array) - 1)]



