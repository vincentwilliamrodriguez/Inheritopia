extends CanvasLayer

var tutorial_num = 0
var tutorial_tween: Tween
var is_tween_running = false

@onready var line = $DialoguePanel/Line

func _process(_delta):
	if tutorial_tween:
		is_tween_running = tutorial_tween.is_running()

func begin_tutorial():
	tutorial_num = 0
	visible = true
	next_tutorial_line()

func next_tutorial_line():
	tutorial_num += 1
	tutorial_tween = create_tween()
	
	if tutorial_num < len(g.tutorial_lines):
		line.text = g.tutorial_lines[tutorial_num]
		
		sound.play("typing")
		
		var line_time = line.text.length() / 25.0
		tutorial_tween.tween_property(line, "visible_ratio", 1.0, line_time) \
					  .from(0.0)
		tutorial_tween.tween_callback(sound.stop_instantly.bind("typing"))
		
	else:
		visible = false

func _on_dialogue_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if tutorial_tween:
			tutorial_tween.stop()
			
			if is_tween_running:
				line.visible_ratio = 1
				sound.stop_instantly("typing")
			else:
				next_tutorial_line()
