extends Node

var SQUARE_SIZE = 128
var START_POS = [5, 6, 9, 10]
var START_GENES = [2, 2, 2]

var rng = RandomNumberGenerator.new()
var breed_lookup = []

var traits = ['y', 't', 'r']
var genotypes = [["yy", "yY", "Yy", "YY"],
				 ["tt", "tT", "Tt", "TT"],
				 ["rr", "rR", "Rr", "RR"]]

func _ready():
	# Initializing breed_lookup
	for i in 4:
		breed_lookup.append([])
		for j in 4:
			breed_lookup[i].append(monohybrid_cross(i, j))
	
	#print(range(10).map(func(_n): return roundi(rng.randfn(2, 1))))


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
