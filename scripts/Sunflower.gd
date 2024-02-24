class_name Sunflower extends Node2D

@export var genes: Array = g.START_GENES
@export var pos: int
@export var is_receiver := false
@export var is_glowing := false
@export var flower_center : Vector2

func _ready():
	position = g.SQUARE_SIZE * g.to_2d_vector(pos)
	
	$Label.text = g.get_genome_text(genes)
	get_node("Animation").play("Idle")
	
	# Sunflower parts visuals
	for trait_num in 3:
		var is_dominant : bool = genes[trait_num] > 0
		get_node("Visuals/Sunflower%s0" % trait_num).visible = not is_dominant
		get_node("Visuals/Sunflower%s1" % trait_num).visible = is_dominant
		
		# Adjusting flower center based on stem height
		if trait_num == 1:
			flower_center = Vector2(100, 35) if is_dominant else Vector2(100, 60)
			
			for i in 2:
				get_node("Visuals/Sunflower0%s" % i).position = flower_center

func set_glow(val: bool):
	is_glowing = val
	#$Glow.visible = val
	
	for i in 2:
		var texture = (g.glow_images if val else g.flower_images)[i]
		get_node("Visuals/Sunflower0%s" % i).texture = texture

func get_flower_offset() -> Vector2:
	if $Visuals/Sunflower00.visible:
		return $Visuals/Sunflower00.offset * $Visuals/Sunflower00.scale
	else:
		return $Visuals/Sunflower01.offset * $Visuals/Sunflower01.scale
