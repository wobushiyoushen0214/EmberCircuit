extends SceneTree

const AudioManagerScript = preload("res://scripts/core/AudioManager.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio = AudioManagerScript.new()
	root.add_child(audio)
	await process_frame
	audio.play_event("ui_click")
	audio.play_event("card_play")
	audio.play_event("missing_event")
	root.remove_child(audio)
	audio.queue_free()
	await process_frame
	print("Audio manager smoke test passed.")
	quit(0)
