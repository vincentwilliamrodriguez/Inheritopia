extends Node

var audio_player: Node
	
func play(sound_name: String):
	audio_player.get_node(sound_name).playing = true

func stop_instantly(sound_name: String):
	audio_player.get_node(sound_name).playing = false

func stop(sound_name: String):
	var effect = audio_player.get_node(sound_name)
	var effect_volume = effect.volume_db
	var tween = create_tween()
	tween.tween_property(effect, "volume_db", -40, 2).from_current()
	tween.tween_callback(effect.set.bind("playing", false))
	tween.tween_callback(effect.set.bind("volume_db", effect_volume))

func stop_all_events():
	for audio in audio_player.get_children():
		if audio.bus == "GameSFX":
			stop(audio.name)

func is_playing(sound_name: String):
	return audio_player.get_node(sound_name).playing
