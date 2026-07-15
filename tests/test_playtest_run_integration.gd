extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

var failed: bool = false
var original_user_files: Dictionary = {}

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for path in [SaveManagerScript.SAVE_PATH, SaveManagerScript.PROFILE_PATH, SaveManagerScript.PLAYTEST_STORE_PATH, SaveManagerScript.PLAYTEST_EXPORT_PATH]:
		_capture_user_file(str(path))
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	SaveManagerScript.save_playtest_store(PlaytestTelemetryScript.default_store())

	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(main)
	await process_frame
	await process_frame

	main._on_character_selected("ember_exile")
	var active: Dictionary = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(str(active.get("character_id", "")) == "ember_exile", "starting a character run creates active human telemetry")
	_check(str(active.get("config_fingerprint", "")).length() == 64, "active run snapshots gameplay configuration fingerprint")
	_check(int(active.get("summary", {}).get("nodes_visited", 0)) == 1, "initial combat node is recorded")
	_check(int(active.get("summary", {}).get("combats_started", 0)) == 1, "initial encounter start is recorded")

	var playable_index := _first_playable_card_index(main)
	_check(playable_index >= 0, "integration fixture has a playable card")
	var played_id := ""
	if playable_index >= 0:
		played_id = PlaytestTelemetryScript.base_card_id(str(main.combat.hand[playable_index].get("id", "")))
		main._on_card_pressed(playable_index)
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(int(active.get("card_telemetry", {}).get(played_id, {}).get("plays", 0)) == 1, "real Main card path records the played card")

	main.combat.phase = "won"
	main._refresh_combat()
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(int(active.get("summary", {}).get("combats_won", 0)) == 1, "combat reward refresh records encounter victory once")
	_check(int(active.get("summary", {}).get("cards_offered", 0)) == main.reward_options.size(), "visible combat reward options are recorded once")
	if not main.reward_options.is_empty():
		var reward_id := str((main.reward_options[0] as Dictionary).get("id", ""))
		main._on_reward_card_pressed(reward_id)
		active = PlaytestTelemetryScript.active_run(main.playtest_store)
		_check(int(active.get("card_telemetry", {}).get(reward_id, {}).get("acquisitions", 0)) == 1, "selected combat reward records acquisition")
		_check(int(active.get("card_telemetry", {}).get(reward_id, {}).get("acquisition_sources", {}).get("combat_reward", 0)) == 1, "selected combat reward records its source")
	main.card_reward_done = true
	main.relic_reward_done = true
	main.potion_reward_done = true
	main._advance_to_next_node()

	var saved: Dictionary = main._create_save_state()
	_check(saved.get("playtest_active_run", {}) is Dictionary and not saved.get("playtest_active_run", {}).is_empty(), "run save snapshots active playtest telemetry")
	_check(SaveManagerScript.save_run(saved), "integration fixture writes a resumable run save")

	main._on_character_selected("arc_tinker")
	_check(main.playtest_store.get("runs", []).size() == 1 and str((main.playtest_store.get("runs", [])[0] as Dictionary).get("outcome", "")) == "abandoned", "starting over archives the previous in-progress run as abandoned")
	_check(str(PlaytestTelemetryScript.active_run(main.playtest_store).get("character_id", "")) == "arc_tinker", "new character run replaces the active telemetry row")
	var replaced_hp: int = main.run_hp
	var replaced_node_id: String = main.current_node_id
	var replaced_deck_ids: Array = main.run_deck_ids.duplicate(true)
	main._on_load_pressed()
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(str(active.get("character_id", "")) == "ember_exile", "loading a different save restores its active telemetry row")
	_check(int(active.get("summary", {}).get("loads", 0)) == 1, "restored telemetry records one save-load restart")
	_check(main.playtest_store.get("runs", []).size() == 1, "loading a previously abandoned save removes its stale abandoned row")
	var replaced: Dictionary = main.playtest_store.get("runs", [])[0]
	_check(str(replaced.get("character_id", "")) == "arc_tinker", "loading a different save archives the replaced active run")
	_check(str(replaced.get("outcome", "")) == "abandoned", "replaced active run is archived as abandoned")
	_check(int(replaced.get("final", {}).get("hp", -1)) == replaced_hp, "replaced run archives its own HP before loading new state")
	_check(str(replaced.get("final", {}).get("node_id", "")) == replaced_node_id, "replaced run archives its own node before loading new state")
	_check(replaced.get("final", {}).get("deck_ids", []) == replaced_deck_ids, "replaced run archives its own deck before loading new state")

	var resumed_battle_node_id := _first_available_battle_node_id(main)
	_check(not resumed_battle_node_id.is_empty(), "restored route exposes a battle node for terminal-flow verification")
	if not resumed_battle_node_id.is_empty():
		main._on_map_node_pressed(resumed_battle_node_id)
		main.combat.phase = "lost"
		main._on_combat_changed()
	_check(PlaytestTelemetryScript.active_run(main.playtest_store).is_empty(), "defeat finalizes active telemetry exactly once")
	_check(main.playtest_store.get("runs", []).size() == 2, "defeat is appended to bounded run history")
	var defeated: Dictionary = main.playtest_store.get("runs", [])[-1]
	_check(str(defeated.get("outcome", "")) == "defeat", "defeated run records terminal outcome")
	_check(not str(defeated.get("failure", {}).get("encounter_id", "")).is_empty(), "defeated run records failure encounter")

	main._on_export_playtest_report_pressed()
	_check(main.last_playtest_export_ok, "in-game export action writes the report")
	_check(main.last_playtest_export_run_count == 2, "in-game export reports archived run count")
	_check(main.last_playtest_export_path == SaveManagerScript.playtest_export_absolute_path(), "in-game export exposes the report path")
	_check(not str(main.status_label.text).contains(main.last_playtest_export_path), "export feedback keeps the absolute path out of visible PC layout text")
	_check(str(main.status_label.tooltip_text) == main.last_playtest_export_path, "export feedback keeps the full report path in its tooltip")
	_check(FileAccess.file_exists(SaveManagerScript.PLAYTEST_EXPORT_PATH), "in-game export creates shareable JSON")
	var exported = JSON.parse_string(FileAccess.get_file_as_string(SaveManagerScript.PLAYTEST_EXPORT_PATH))
	_check(exported is Dictionary and int(exported.get("summary", {}).get("defeats", 0)) == 1, "exported report includes the real defeat")

	main._on_profile_pressed()
	_check(main.last_profile_export_button_visible, "profile page exposes the playtest report action")
	_check(main.last_combat_layout_overflow <= 0.0, "profile export action keeps the PC page inside 720p")

	main.queue_free()
	await process_frame
	_restore_user_files()
	if failed:
		quit(1)
		return
	print("Playtest run integration test passed.")
	quit(0)

func _first_playable_card_index(main) -> int:
	if main.combat == null:
		return -1
	for index in range(main.combat.hand.size()):
		if main.combat.can_play_card(index):
			return index
	return -1

func _first_available_battle_node_id(main) -> String:
	for node_id_value in main.available_node_ids:
		var node_id := str(node_id_value)
		var node: Dictionary = main._node_by_id(node_id)
		if main._is_battle_node(str(node.get("type", ""))):
			return node_id
	return ""

func _capture_user_file(path: String) -> void:
	var entry := {"exists": FileAccess.file_exists(path), "text": ""}
	if bool(entry.get("exists", false)):
		entry["text"] = FileAccess.get_file_as_string(path)
	original_user_files[path] = entry

func _restore_user_files() -> void:
	for path_value in original_user_files.keys():
		var path := str(path_value)
		var entry: Dictionary = original_user_files.get(path_value, {})
		if bool(entry.get("exists", false)):
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(str(entry.get("text", "")))
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
