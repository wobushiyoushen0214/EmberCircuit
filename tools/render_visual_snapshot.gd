extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

const COMPACT_SNAPSHOT_SIZE := Vector2i(390, 640)
const DESKTOP_SNAPSHOT_SIZE := Vector2i(1600, 900)
const CHARACTER_SELECT_PATH := "/tmp/embercircuit_character_select.png"
const COMBAT_PATH := "/tmp/embercircuit_combat.png"
const CHARACTER_SELECT_DESKTOP_PATH := "/tmp/embercircuit_character_select_desktop.png"
const COMBAT_DESKTOP_PATH := "/tmp/embercircuit_combat_desktop.png"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_warning("Visual snapshots need a real display backend. Run this script without --headless.")
		quit(2)
		return
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	_set_audio_stream_loading_suppressed(true)
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	await _capture_scene(scene, COMPACT_SNAPSHOT_SIZE, "", CHARACTER_SELECT_PATH)
	await _capture_scene(scene, COMPACT_SNAPSHOT_SIZE, "ember_exile", COMBAT_PATH)
	await _capture_scene(scene, DESKTOP_SNAPSHOT_SIZE, "", CHARACTER_SELECT_DESKTOP_PATH)
	await _capture_scene(scene, DESKTOP_SNAPSHOT_SIZE, "ember_exile", COMBAT_DESKTOP_PATH)
	_release_audio_streams()
	await process_frame
	print("Saved visual snapshots:")
	print(CHARACTER_SELECT_PATH)
	print(COMBAT_PATH)
	print(CHARACTER_SELECT_DESKTOP_PATH)
	print(COMBAT_DESKTOP_PATH)
	quit(0)

func _capture_scene(scene: PackedScene, snapshot_size: Vector2i, character_id: String, output_path: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = snapshot_size
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var main = scene.instantiate()
	main.debug_viewport_size_override = Vector2(snapshot_size)
	viewport.add_child(main)
	await process_frame
	await process_frame
	if not character_id.is_empty():
		main._on_character_selected(character_id)
		await process_frame
		await process_frame
	await create_timer(0.70).timeout
	await process_frame

	var image: Image = viewport.get_texture().get_image()
	var error: Error = image.save_png(output_path)
	if error != OK:
		push_error("Failed to save visual snapshot: %s" % output_path)
	viewport.remove_child(main)
	main.queue_free()
	root.remove_child(viewport)
	viewport.queue_free()
	await process_frame
	await process_frame

func _release_audio_streams() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("release_streams_for_shutdown"):
		audio_manager.release_streams_for_shutdown()

func _set_audio_stream_loading_suppressed(suppressed: bool) -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("set_stream_loading_suppressed"):
		audio_manager.set_stream_loading_suppressed(suppressed)
