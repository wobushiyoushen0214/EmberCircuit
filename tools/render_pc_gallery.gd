extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

const SNAPSHOT_SIZE := Vector2i(1600, 900)
const WIDE_SNAPSHOT_SIZE := Vector2i(2048, 1066)
const DEFAULT_PC_SNAPSHOT_SIZE := Vector2i(1280, 720)
const OUT_DIR := "/tmp/embercircuit_pc_gallery"

var capture_failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_warning("PC gallery snapshots need a real display backend. Run without --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	SaveManagerScript.set_storage_namespace("pc_gallery")
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	_set_audio_stream_loading_suppressed(true)
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	await _capture(scene, "00_welcome", Callable())
	await _capture(scene, "00_welcome_720p", Callable(), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "01_character_select", func(main): main._on_new_run_pressed())
	await _capture(scene, "01_character_select_720p", func(main): main._on_new_run_pressed(), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "01_character_select_wide", func(main): main._on_new_run_pressed(), WIDE_SNAPSHOT_SIZE)
	await _capture(scene, "02_combat", func(main): main._on_character_selected("ember_exile"))
	await _capture(scene, "03_reward", func(main):
		main._on_character_selected("ember_exile")
		main.combat.phase = "won"
		main._refresh_combat()
	)
	await _capture(scene, "03_reward_720p", func(main):
		main._on_character_selected("ember_exile")
		main.combat.phase = "won"
		main._refresh_combat()
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "04_map", func(main):
		main._on_character_selected("ember_exile")
		main.combat.phase = "won"
		main._advance_to_next_node()
	)
	await _capture(scene, "04_map_720p", func(main):
		main._on_character_selected("ember_exile")
		main.combat.phase = "won"
		main._advance_to_next_node()
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "05_event", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "broken_reactor")
	)
	await _capture(scene, "05_event_720p", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "broken_reactor")
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "05_event_wide", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "broken_reactor")
	, WIDE_SNAPSHOT_SIZE)
	await _capture(scene, "05_event_ash_archive_720p", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "ash_archive")
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "05_event_coolant_cache_720p", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "coolant_cache")
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "05_event_soot_market_720p", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_event_id(main, "soot_market")
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "06_shop", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "shop")
	)
	await _capture(scene, "07_campfire", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "campfire")
	)
	await _capture(scene, "07_campfire_720p", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "campfire")
	, DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "07_campfire_forge_720p", func(main):
		main._on_character_selected("ember_exile")
		_jump_to_node_type(main, "campfire")
		main._on_campfire_forge_pressed()
	, DEFAULT_PC_SNAPSHOT_SIZE)
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
	await _capture(scene, "29_defeat_720p", Callable(self, "_setup_defeat_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE)
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
	await _capture(scene, "30_forge_bishop_phase_720p", Callable(self, "_setup_boss_phase_snapshot").bind("chapter_one", "chapter_one_boss"), DEFAULT_PC_SNAPSHOT_SIZE, 0.55)
	await _capture(scene, "31_storm_archon_phase_720p", Callable(self, "_setup_boss_phase_snapshot").bind("chapter_two", "chapter_two_boss"), DEFAULT_PC_SNAPSHOT_SIZE, 0.55)
	await _capture(scene, "32_nexus_heart_phase_720p", Callable(self, "_setup_boss_phase_snapshot").bind("chapter_three", "chapter_three_boss"), DEFAULT_PC_SNAPSHOT_SIZE, 0.55)
	await _capture(scene, "33_enemy_windup_720p", Callable(self, "_setup_enemy_windup_snapshot"), DEFAULT_PC_SNAPSHOT_SIZE, 0.08)
	await _capture(scene, "34_ember_relic_hud_720p", func(main): main._on_character_selected("ember_exile"), DEFAULT_PC_SNAPSHOT_SIZE)
	await _capture(scene, "35_pyre_relic_hud_720p", func(main): main._on_character_selected("pyre_ascetic"), DEFAULT_PC_SNAPSHOT_SIZE)
	_release_audio_streams()
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
	if not capture_failures.is_empty():
		push_error("PC gallery failed captures: %s" % ", ".join(capture_failures))
		quit(1)
		return
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
	var setup_succeeded := true
	if setup.is_valid():
		var setup_result: Variant = setup.call(main)
		if setup_result is bool:
			setup_succeeded = setup_result
		await process_frame
		await process_frame
	if not setup_succeeded:
		capture_failures.append(name)
		await _dispose_capture(viewport, main)
		return
	await create_timer(settle_seconds).timeout
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	await RenderingServer.frame_post_draw

	var image: Image = viewport.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Failed to save PC gallery snapshot: %s" % path)
		capture_failures.append(name)
	await _dispose_capture(viewport, main)

func _dispose_capture(viewport: SubViewport, main: Node) -> void:
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

func _setup_enemy_windup_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	main._on_end_turn_pressed()

func _setup_run_complete_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	_complete_run_by_boss_jumps(main)

func _setup_defeat_snapshot(main) -> void:
	main._on_character_selected("ember_exile")
	main.completed_chapter_ids = ["chapter_one"]
	main.player_profile["forge_marks"] = int(main.progression_data.get("currency", {}).get("boss_reward", 2))
	main.combat.phase = "lost"
	main.combat.player["hp"] = 0
	main._refresh_combat()

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

func _setup_boss_phase_snapshot(main, chapter_id: String, encounter_id: String) -> bool:
	main._on_character_selected("arc_tinker")
	main.current_chapter_id = chapter_id
	main.route_nodes = [{
		"id": "gallery_%s_phase" % encounter_id,
		"type": "boss",
		"encounter_id": encounter_id
	}]
	main.current_node_id = "gallery_%s_phase" % encounter_id
	main.current_node_index = 0
	main.available_node_ids.clear()
	main.available_node_ids.append(main.current_node_id)
	main._start_current_node()
	if main.combat == null or main.combat.enemies.is_empty():
		push_error("Boss phase gallery setup has no combat enemy: %s" % encounter_id)
		return false
	var boss: Dictionary = main.combat.enemies[0]
	var boss_data: Dictionary = boss.get("data", {})
	var phases: Array = boss_data.get("phases", [])
	if str(boss_data.get("tier", "")) != "boss" or phases.is_empty() or not phases[0] is Dictionary:
		push_error("Boss phase gallery encounter lacks configured Boss phases: %s" % encounter_id)
		return false
	var first_phase: Dictionary = phases[0]
	var threshold_ratio: float = main._boss_phase_threshold_ratio(boss, first_phase)
	if threshold_ratio < 0.0:
		push_error("Boss phase gallery phase has no supported threshold: %s" % encounter_id)
		return false
	var target_hp: int = max(1, int(floor(float(int(boss.get("max_hp", 1))) * threshold_ratio)))
	var transition_damage: int = max(1, int(boss.get("hp", 1)) + int(boss.get("block", 0)) - target_hp)
	main.combat._damage_enemy(boss, transition_damage, {"name": "阶段图库", "ignore_player_modifiers": true})
	main._refresh_combat()
	if int(boss.get("phase_index", -1)) < 0 or main.enemy_stage_stack.get_node_or_null("BossPhaseBanner") == null:
		push_error("Boss phase gallery failed to enter and present the first phase: %s" % encounter_id)
		return false
	return true

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
