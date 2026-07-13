extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

const SNAPSHOT_SIZE := Vector2i(1600, 900)
const WIDE_SNAPSHOT_SIZE := Vector2i(2048, 1066)
const DEFAULT_PC_SNAPSHOT_SIZE := Vector2i(1280, 720)
const OUT_DIR := "/tmp/embercircuit_pc_gallery"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_warning("PC gallery snapshots need a real display backend. Run without --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	_set_audio_stream_loading_suppressed(true)
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	await _capture(scene, "01_character_select", Callable())
	await _capture(scene, "02_combat", func(main): main._on_character_selected("ember_exile"))
	await _capture(scene, "03_reward", func(main):
		main._on_character_selected("ember_exile")
		main.combat.phase = "won"
		main._refresh_combat()
	)
	await _capture(scene, "04_map", func(main):
		main._on_character_selected("ember_exile")
		main.combat.phase = "won"
		main._advance_to_next_node()
	)
	await _capture(scene, "05_event", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "broken_reactor")
	)
	await _capture(scene, "06_shop", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "shop")
	)
	await _capture(scene, "07_campfire", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "campfire")
	)
	await _capture(scene, "08_deck", func(main):
		main._on_character_selected("ember_exile")
		main._on_deck_view_pressed()
	)
	await _capture(scene, "09_compendium", func(main):
		main._on_compendium_pressed()
	)
	await _capture(scene, "10_settings", func(main):
		main._on_settings_pressed()
	)
	await _capture(scene, "11_combat_wide", func(main): main._on_character_selected("arc_tinker"), WIDE_SNAPSHOT_SIZE)
	await _capture(scene, "12_combat_pyre", func(main): main._on_character_selected("pyre_ascetic"))
	await _capture(scene, "13_combat_default_720p", func(main): main._on_character_selected("arc_tinker"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "14_combat_action_720p", Callable(self, "_setup_combat_action_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE, 0.16)
	await _capture(scene, "15_treasure", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "treasure")
	)
	await _capture(scene, "16_shop_remove", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "shop")
		main.run_gold = max(main.run_gold, main._remove_card_price())
		main._on_shop_remove_card_pressed()
	)
	await _capture(scene, "17_run_complete", Callable(self, "_setup_run_complete_snapshot"))
	await _capture(scene, "18_run_complete_720p", Callable(self, "_setup_run_complete_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "19_chain_event_start", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "mute_calibrator")
	)
	await _capture(scene, "20_chain_event_follow_up", func(main):
		main._on_character_selected("ember_exile")
		main.completed_event_ids["mute_calibrator"] = true
		main.current_chapter_id = "chapter_two"
		main._build_route()
		_jump_to_event_id(main, "calibrator_return")
	)
	await _capture(scene, "21_draw_pile_720p", Callable(self, "_setup_draw_pile_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "22_profile_progression_720p", Callable(self, "_setup_profile_progression_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "23_deck_mastery_720p", Callable(self, "_setup_deck_mastery_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "24_intro_patrol_art_720p", _encounter_snapshot_setup("intro_patrol", "ember_exile"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "25_executor_elite_art_720p", _encounter_snapshot_setup("executor_elite", "arc_tinker"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "26_forge_bishop_art_720p", _encounter_snapshot_setup("chapter_one_boss", "pyre_ascetic"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "27_power_card_frame_720p", Callable(self, "_setup_power_card_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "28_deck_grid_720p", Callable(self, "_setup_deck_grid_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
	_release_audio_streams()
	print("Saved PC gallery snapshots to %s" % OUT_DIR)
	quit(0)

func _capture(scene: PackedScene, name: String, setup: Callable, snapshot_size: Vector2i = SNAPSHOT_SIZE, settle_seconds: float = 0.55) -> void:
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
	if setup.is_valid():
		setup.call(main)
		await process_frame
		await process_frame
	await create_timer(settle_seconds).timeout
	await process_frame

	var image: Image = viewport.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Failed to save PC gallery snapshot: %s" % path)
	viewport.remove_child(main)
	main.queue_free()
	root.remove_child(viewport)
	viewport.queue_free()
	await process_frame
	await process_frame

func _jump_to_node_type(main, node_type: String) -> void:
	for node in main.route_nodes:
		var node_dict: Dictionary = node
		if str(node_dict.get("type", "")) == node_type:
			main.current_node_id = str(node_dict.get("id", ""))
			main.current_node_index = main._node_index_by_id(main.current_node_id)
			main.available_node_ids.clear()
			main._start_current_node()
			return

func _complete_run_by_boss_jumps(main) -> void:
	for _i in range(3):
		_jump_to_node_type(main, "boss")
		if main.combat != null:
			main.combat.phase = "won"
		main._advance_to_next_node()

func _jump_to_event_id(main, event_id: String) -> void:
	for i in range(main.route_nodes.size()):
		var node_dict: Dictionary = main.route_nodes[i]
		if str(node_dict.get("type", "")) == "event":
			node_dict["event_id"] = event_id
			main.route_nodes[i] = node_dict
			main.current_node_id = str(node_dict.get("id", ""))
			main.current_node_index = main._node_index_by_id(main.current_node_id)
			main.available_node_ids.clear()
			main._start_current_node()
			return

func _setup_combat_action_snapshot(main) -> void:
	main._on_character_selected("arc_tinker")
	var card_index: int = _first_playable_attack_card_index(main)
	if card_index >= 0:
		main._on_card_pressed(card_index)

func _setup_run_complete_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	_complete_run_by_boss_jumps(main)

func _setup_draw_pile_snapshot(main) -> void:
	main._on_character_selected("arc_tinker")
	main._open_pile_view("draw")

func _setup_power_card_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	var power_card: Dictionary = main.combat.cards_by_id.get("counter_pressure", {}).duplicate(true)
	var attack_card: Dictionary = main.combat.cards_by_id.get("ember_strike", {}).duplicate(true)
	var skill_card: Dictionary = main.combat.cards_by_id.get("ash_guard", {}).duplicate(true)
	main.combat.hand = [attack_card, skill_card, power_card, power_card.duplicate(true), skill_card.duplicate(true)]
	main._refresh_combat()

func _setup_deck_grid_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	main.run_deck_ids = [
		"ember_strike+", "ember_strike", "spark_throw", "pressure_probe",
		"ash_guard+", "ash_guard", "cooling_breath", "soot_step",
		"counter_pressure", "smelt_plating", "furnace_prayer", "searing_wound"
	]
	main._on_deck_view_pressed()

func _setup_profile_progression_snapshot(main) -> void:
	main.player_profile["forge_marks"] = 9
	main.player_profile["completed_chapters"] = ["chapter_one", "chapter_two"]
	main.player_profile["purchased_upgrade_node_ids"] = ["exile_tempered_body", "exile_old_wound_charm"]
	main.selected_character_id = "ember_exile"
	main._on_profile_pressed()

func _setup_deck_mastery_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	main.run_deck_ids = ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "spark_throw", "pressure_probe", "ash_guard", "ash_guard", "shield_pulse", "shield_pulse"]
	main.route_nodes = [{"id": "elite_mastery", "type": "elite", "encounter_id": "executor_elite"}]
	main.current_node_id = "elite_mastery"
	main.current_node_index = 0
	main.combat.phase = "won"
	main.reward_generated_for = "elite_mastery:executor_elite"
	main.combat_reward_gold = 42
	main.card_reward_done = true
	main.relic_reward_done = true
	main.potion_reward_done = true
	main._refresh_combat()

func _encounter_snapshot_setup(encounter_id: String, character_id: String) -> Callable:
	return func(main):
		main._on_character_selected(character_id)
		var node_type := "combat"
		if encounter_id.ends_with("_elite"):
			node_type = "elite"
		elif encounter_id.ends_with("_boss"):
			node_type = "boss"
		main.route_nodes = [{
			"id": "gallery_%s" % encounter_id,
			"type": node_type,
			"encounter_id": encounter_id
		}]
		main.current_node_id = "gallery_%s" % encounter_id
		main.current_node_index = 0
		main.available_node_ids.clear()
		main.available_node_ids.append(main.current_node_id)
		main._start_current_node()

func _first_playable_attack_card_index(main) -> int:
	if main == null or main.combat == null:
		return -1
	for i in range(main.combat.hand.size()):
		var card: Dictionary = main.combat.hand[i]
		if str(card.get("type", "")) == "attack" and main.combat.can_play_card(i):
			return i
	for i in range(main.combat.hand.size()):
		if main.combat.can_play_card(i):
			return i
	return -1

func _release_audio_streams() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("release_streams_for_shutdown"):
		audio_manager.release_streams_for_shutdown()

func _set_audio_stream_loading_suppressed(suppressed: bool) -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("set_stream_loading_suppressed"):
		audio_manager.set_stream_loading_suppressed(suppressed)
