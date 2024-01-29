extends Node

var SQUARE_SIZE = 128
var START_POS = [5, 6, 9, 10]
var START_GENES = [2, 2, 2]

var rng = RandomNumberGenerator.new()
var breed_lookup = []
var neighbors_lookup = []

var traits = ['y', 't', 'r']
var genotypes = [["yy", "yY", "Yy", "YY"],
				 ["tt", "tT", "Tt", "TT"],
				 ["rr", "rR", "Rr", "RR"]]

class Event:
	var affected_map: int
	var affected_trait: int

func _ready():
	# Initialize breed_lookup
	for i in 4:
		breed_lookup.append([])
		for j in 4:
			breed_lookup[i].append(monohybrid_cross(i, j))
	
	# Initialize neighbors_lookup
	for i in 16:
		neighbors_lookup.append([])
		var cur_x = i % 4
		var cur_y = i / 4
		
		for dir_x in [-1, 0, 1]:
			for dir_y in [-1, 0, 1]:
				var new_x = cur_x + dir_x
				var new_y = cur_y + dir_y
				
				if not (dir_x == 0 and dir_y == 0) and \
					   (new_x >= 0 and new_x < 4) and \
					   (new_y >= 0 and new_y < 4):
					neighbors_lookup[i].append(new_x + 4 * new_y)
				


func _process(delta):
	pass


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


