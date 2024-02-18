extends CanvasLayer

var tutorial_num := 0
var tutorial_timer: SceneTreeTimer
var tutorial_tween: Tween
var continue_tween: Tween
var is_tween_running := false
var can_continue := true
var debounce := true
var needed_stack := []
var cur_stack := []

signal tutorial_started
signal proceed

@onready var line = $DialoguePanel/Line
@onready var continue_label = $DialoguePanel/Continue
@onready var animation = $TutorialAnimation
@onready var arrow = $Arrow

func _process(_delta):
	if len(needed_stack) > 0 and len(cur_stack) < len(needed_stack):
		arrow.visible = true
		move_arrow(needed_stack[len(cur_stack)])
	else:
		arrow.visible = false
		
	if tutorial_tween:
		is_tween_running = tutorial_tween.is_running()
		debounce = true

func begin_tutorial():
	if visible:
		return
	
	tutorial_num = 0
	visible = true
	tutorial_started.emit()
	next_tutorial_line()

func next_tutorial_line():
	continue_label.modulate.a = 0
	
	if animation.has_animation(str(tutorial_num)):
		animation.play(str(tutorial_num)) # starting num
		tutorial_tween = create_tween()
		tutorial_tween.tween_property(line, "modulate:a", 0, 0.3)
		await animation.animation_finished
	
	tutorial_num += 1 # ending num
	
	can_continue = (tutorial_num not in [4, 6, 8, 9, 10, 11, 13, 14])
	if continue_tween:
		continue_tween.kill()
	
	match tutorial_num:
		6:
			needed_stack = [5, 6]
		9:
			needed_stack = [5, 10, 9, 5, 9, 9]
		13:
			needed_stack = [10, 6]
		_:
			cur_stack = []
			needed_stack = []
	
	if tutorial_num < len(g.tutorial_lines):
		line.modulate.a = 1
		line.text = g.tutorial_lines[tutorial_num]
		
		sound.play("typing")
		
		var line_time = line.text.length() / 25.0
		tutorial_tween = create_tween()
		tutorial_tween.tween_property(line, "visible_ratio", 1.0, line_time) \
					  .from(0.0)
		tutorial_tween.tween_callback(sound.stop_instantly.bind("typing"))
		
		await tutorial_tween.finished
		
		check_if_can_continue()
	else:
		visible = false
		tutorial_num = 0

func check_if_can_continue():
	if can_continue:
		show_continue()
	else:
		pass
		#tutorial_timer = get_tree().create_timer(30)
		#tutorial_timer.timeout.connect(show_continue)

func show_continue():
	if continue_label.modulate.a == 0.0:
		continue_tween = create_tween()
		continue_tween.tween_property(continue_label, "modulate:a", 1.0, 0.1).from(0.0)
	can_continue = true

func _on_dialogue_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if debounce and tutorial_tween and not animation.is_playing():
			if is_tween_running:
				tutorial_tween.stop()
				line.visible_ratio = 1
				sound.stop_instantly("typing")
				check_if_can_continue()
					
			elif can_continue:
				proceed.emit()
				next_tutorial_line()
	
	debounce = false

func move_arrow(aim):
	if typeof(aim) == TYPE_INT:
		arrow.position = g.to_2d_vector(aim) * g.SQUARE_SIZE + Vector2(560, 230) + Vector2(100, 50)

func check_stack(attempt):
	if len(cur_stack) < len(needed_stack) and \
	   needed_stack[len(cur_stack)] == attempt:
		
		cur_stack.append(attempt)
