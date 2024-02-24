extends Control

var progress := []
var scene_load_status := 0
var has_loaded := false
var is_button_pressed := false
var main_game_path := "res://scenes/game.tscn"

@onready var animation: AnimationPlayer = $Animation
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var audio_player_scene := preload("res://scenes/sound.tscn")


func _ready() -> void:
	animation.play("RESET")
	
	var audio_player = audio_player_scene.instantiate()
	get_tree().root.add_child.call_deferred(audio_player)
	
	await audio_player.ready
	sound.audio_player = audio_player
	sound.play("music_day")
	
	ResourceLoader.load_threaded_request(main_game_path)

func _process(_delta: float) -> void:
	scene_load_status = ResourceLoader.load_threaded_get_status(main_game_path, progress)
	progress_bar.value = progress[0]
	
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED and not has_loaded:
		has_loaded = true
		animation.play("Complete")

func _on_button_pressed() -> void:
	if is_button_pressed:
		return
	
	is_button_pressed = true
	
	animation.play("Fade")
	await animation.animation_finished
	
	var main_game = ResourceLoader.load_threaded_get(main_game_path)
	get_tree().change_scene_to_packed(main_game)
