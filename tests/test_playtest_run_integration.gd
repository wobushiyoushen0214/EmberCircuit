extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

var failed: bool = false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManagerScript.set_storage_namespace("test_playtest_integration")
	SaveManagerScript.cleanup_storage_namespace()
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
	_check(not main.save_button.disabled, "combat victory reward state allows transactional saving")
	var reward_card_ids_before_save: Array[String] = []
	for reward_card_value in main.reward_options:
		reward_card_ids_before_save.append(str((reward_card_value as Dictionary).get("id", "")))
	var reward_relic_ids_before_save: Array[String] = []
	for reward_relic_value in main.relic_reward_options:
		reward_relic_ids_before_save.append(str((reward_relic_value as Dictionary).get("id", "")))
	var reward_potion_ids_before_save: Array[String] = []
	for reward_potion_value in main.potion_reward_options:
		reward_potion_ids_before_save.append(str((reward_potion_value as Dictionary).get("id", "")))
	var reward_flags_before_save: Array[bool] = [main.card_reward_done, main.relic_reward_done, main.potion_reward_done]
	var reward_gold_before_save: int = main.run_gold
	main._on_save_pressed()
	var reward_save: Dictionary = SaveManagerScript.load_run()
	_check(bool(reward_save.get("combat_reward_state", {}).get("active", false)), "combat reward save persists an active reward transaction")
	_check(str(reward_save.get("combat_reward_state", {}).get("run_id", "")) == main._active_playtest_run_id() and str(reward_save.get("combat_reward_state", {}).get("chapter_id", "")) == main.current_chapter_id, "combat reward save binds the transaction to its run and chapter")
	_check(reward_save.get("combat_reward_state", {}).get("card_ids", []) == reward_card_ids_before_save, "combat reward save preserves the exact card offers")
	_check(reward_save.get("combat_reward_state", {}).get("relic_ids", []) == reward_relic_ids_before_save, "combat reward save preserves the exact relic offers")
	_check(reward_save.get("combat_reward_state", {}).get("potion_ids", []) == reward_potion_ids_before_save, "combat reward save preserves the exact potion offers")
	main._on_load_pressed()
	var reward_card_ids_after_load: Array[String] = []
	for reward_card_value in main.reward_options:
		reward_card_ids_after_load.append(str((reward_card_value as Dictionary).get("id", "")))
	var reward_relic_ids_after_load: Array[String] = []
	for reward_relic_value in main.relic_reward_options:
		reward_relic_ids_after_load.append(str((reward_relic_value as Dictionary).get("id", "")))
	var reward_potion_ids_after_load: Array[String] = []
	for reward_potion_value in main.potion_reward_options:
		reward_potion_ids_after_load.append(str((reward_potion_value as Dictionary).get("id", "")))
	_check(main.combat.phase == "won" and reward_card_ids_after_load == reward_card_ids_before_save, "loading from the reward page restores the same unresolved card offers")
	_check(reward_relic_ids_after_load == reward_relic_ids_before_save and reward_potion_ids_after_load == reward_potion_ids_before_save, "loading from the reward page restores the same item offers")
	_check([main.card_reward_done, main.relic_reward_done, main.potion_reward_done] == reward_flags_before_save, "loading from the reward page restores all reward completion flags")
	_check(main.run_gold == reward_gold_before_save, "loading a reward transaction does not grant combat gold twice")
	_check(bool(SaveManagerScript.load_run().get("combat_reward_state", {}).get("active", false)), "load migration writeback keeps the active reward transaction resumable")
	var malformed_reward_save: Dictionary = reward_save.duplicate(true)
	malformed_reward_save["combat_reward_state"]["card_ids"] = ["missing_card_fixture"]
	_check(SaveManagerScript.save_run(malformed_reward_save), "same-node malformed reward transaction fixture is written")
	main._on_load_pressed()
	_check(main.combat.phase == "player" and main.reward_generated_for.is_empty(), "a same-node transaction with an unknown reward ID is rejected")
	_check(main.run_gold == reward_gold_before_save - int(reward_save.get("combat_reward_state", {}).get("combat_reward_gold", 0)), "rejecting a malformed reward transaction rolls back its already granted combat gold")
	_check(SaveManagerScript.load_run().get("combat_reward_state", {}).is_empty(), "loading clears a malformed same-node reward transaction")
	_check(SaveManagerScript.save_run(reward_save), "valid reward transaction fixture is restored after malformed-state verification")
	main._on_load_pressed()
	_check(main.combat.phase == "won" and main.run_gold == reward_gold_before_save, "valid reward state remains resumable after malformed-state rejection")
	var stale_reward_save: Dictionary = reward_save.duplicate(true)
	stale_reward_save["combat_reward_state"]["reward_generated_for"] = "stale_node:stale_encounter"
	_check(SaveManagerScript.save_run(stale_reward_save), "stale reward transaction fixture is written")
	main._on_load_pressed()
	_check(main.combat.phase == "player" and main.reward_generated_for.is_empty(), "a reward transaction from another node is rejected instead of being restored")
	_check(main.run_gold == reward_gold_before_save - int(reward_save.get("combat_reward_state", {}).get("combat_reward_gold", 0)), "rejecting a stale reward transaction rolls back its already granted combat gold")
	_check(SaveManagerScript.load_run().get("combat_reward_state", {}).is_empty(), "loading strips a stale reward transaction from the migrated save")
	_check(SaveManagerScript.save_run(reward_save), "valid reward transaction fixture is restored after stale-state verification")
	main._on_load_pressed()
	_check(main.combat.phase == "won" and main.run_gold == reward_gold_before_save, "the valid reward transaction remains repeatably resumable without duplicate gold")
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(int(active.get("summary", {}).get("combats_won", 0)) == 1, "combat reward refresh records encounter victory once")
	_check(int(active.get("summary", {}).get("cards_offered", 0)) == main.reward_options.size(), "visible combat reward options are recorded once")
	_check(int(active.get("summary", {}).get("nodes_visited", 0)) == 1 and int(active.get("summary", {}).get("combats_started", 0)) == 1, "valid reward-page reloads do not record duplicate node or combat starts")
	if not main.reward_options.is_empty():
		var reward_id := str((main.reward_options[0] as Dictionary).get("id", ""))
		var reward_id_count_before: int = main.run_deck_ids.count(reward_id)
		main._on_reward_card_pressed(reward_id)
		active = PlaytestTelemetryScript.active_run(main.playtest_store)
		_check(int(active.get("card_telemetry", {}).get(reward_id, {}).get("acquisitions", 0)) == 1, "selected combat reward records acquisition")
		_check(int(active.get("card_telemetry", {}).get(reward_id, {}).get("acquisition_sources", {}).get("combat_reward", 0)) == 1, "selected combat reward records its source")
		main._on_save_pressed()
		_check(bool(SaveManagerScript.load_run().get("combat_reward_state", {}).get("card_reward_done", false)), "a partially processed reward transaction persists the completed card choice")
		main._on_load_pressed()
		_check(main.card_reward_done and main.run_deck_ids.count(reward_id) == reward_id_count_before + 1, "loading a partially processed reward does not duplicate the acquired card")
	var fixture_relic_id := "cinder_lens"
	var fixture_potion_id := "guard_tonic"
	var fixture_relic: Dictionary = main._relic_by_id(fixture_relic_id)
	var fixture_potion: Dictionary = main._potion_by_id(fixture_potion_id)
	_check(not fixture_relic.is_empty() and not fixture_potion.is_empty(), "item reward persistence fixtures resolve from authoritative data")
	main.relic_reward_options = [fixture_relic.duplicate(true)]
	main.potion_reward_options = [fixture_potion.duplicate(true)]
	main.relic_reward_done = false
	main.potion_reward_done = false
	var relic_count_before: int = main.run_relic_ids.count(fixture_relic_id)
	main._on_reward_relic_pressed(fixture_relic_id)
	main._on_save_pressed()
	main._on_load_pressed()
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(main.relic_reward_done and not main.potion_reward_done and main.run_relic_ids.count(fixture_relic_id) == relic_count_before + 1, "loading a partially processed item reward preserves one relic and the unresolved potion")
	_check(int(active.get("item_acquisitions", {}).get("relics", {}).get(fixture_relic_id, {}).get("count", 0)) == 1, "reward-page reload does not duplicate relic acquisition telemetry")
	main._on_skip_potion_reward_pressed()
	main._on_save_pressed()
	main._on_load_pressed()
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(int(active.get("reward_skips", {}).get("potion", 0)) == 1, "reward-page reload does not duplicate potion-skip telemetry")
	main.potion_reward_options = [fixture_potion.duplicate(true)]
	main.potion_reward_done = false
	var potion_count_before: int = main.run_potion_ids.count(fixture_potion_id)
	main._on_reward_potion_pressed(fixture_potion_id)
	main._on_save_pressed()
	main._on_load_pressed()
	active = PlaytestTelemetryScript.active_run(main.playtest_store)
	_check(main.potion_reward_done and main.run_potion_ids.count(fixture_potion_id) == potion_count_before + 1, "loading a processed potion reward preserves exactly one acquired potion")
	_check(int(active.get("item_acquisitions", {}).get("potions", {}).get(fixture_potion_id, {}).get("count", 0)) == 1 and int(active.get("reward_skips", {}).get("potion", 0)) == 1, "reward-page reload keeps potion acquisition and prior skip telemetry idempotent")
	_check(int(active.get("summary", {}).get("nodes_visited", 0)) == 1 and int(active.get("summary", {}).get("combats_started", 0)) == 1, "partial reward reloads keep node-start telemetry idempotent")
	main.card_reward_done = true
	main.relic_reward_done = true
	main.potion_reward_done = true
	main._advance_to_next_node()

	var saved: Dictionary = main._create_save_state()
	var saved_load_count: int = int(saved.get("playtest_active_run", {}).get("summary", {}).get("loads", 0))
	var saved_run_hp: int = int(saved.get("run_hp", 0))
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
	_check(int(active.get("summary", {}).get("loads", 0)) == saved_load_count + 1, "restored telemetry records exactly one additional save-load restart")
	_check(int(SaveManagerScript.load_run().get("run_hp", -1)) == saved_run_hp, "load migration writeback cannot leak HP from the replaced combat")
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
	_check(main.save_button.disabled, "combat defeat state disables run saving")
	_check(SaveManagerScript.load_run().is_empty(), "combat defeat invalidates the stale resumable save")
	main._on_save_pressed()
	_check(SaveManagerScript.load_run().is_empty(), "combat defeat rejects an explicit save attempt")
	_check(PlaytestTelemetryScript.active_run(main.playtest_store).is_empty(), "defeat finalizes active telemetry exactly once")
	_check(main.playtest_store.get("runs", []).size() == 2, "defeat is appended to bounded run history")
	var defeated: Dictionary = main.playtest_store.get("runs", [])[-1]
	_check(str(defeated.get("outcome", "")) == "defeat", "defeated run records terminal outcome")
	_check(not str(defeated.get("failure", {}).get("encounter_id", "")).is_empty(), "defeated run records failure encounter")

	main._on_export_playtest_report_pressed()
	_check(main.last_playtest_export_ok, "in-game export action writes the report")
	_check(main.last_playtest_export_run_count == 2, "in-game export reports archived run count")
	_check(main.last_playtest_export_summary.contains("方向") and main.last_playtest_export_summary.contains("硬门") and main.last_playtest_export_summary.contains("尚缺"), "in-game export summary exposes evidence-gate progress")
	_check(main.last_playtest_export_path == SaveManagerScript.playtest_export_absolute_path(), "in-game export exposes the report path")
	_check(not str(main.status_label.text).contains(main.last_playtest_export_path), "export feedback keeps the absolute path out of visible PC layout text")
	_check(str(main.status_label.tooltip_text) == main.last_playtest_export_path, "export feedback keeps the full report path in its tooltip")
	_check(FileAccess.file_exists(SaveManagerScript.playtest_export_path()), "in-game export creates shareable JSON")
	var exported = JSON.parse_string(FileAccess.get_file_as_string(SaveManagerScript.playtest_export_path()))
	_check(exported is Dictionary and int(exported.get("summary", {}).get("defeats", 0)) == 1, "exported report includes the real defeat")
	_check(int(exported.get("coverage", {}).get("total_cells", 0)) == 12, "exported primary cohort contains the full three-by-four coverage matrix")
	_check(not str(exported.get("primary_cohort_id", "")).is_empty(), "exported report identifies its primary cohort")

	main._on_character_selected("pyre_ascetic")
	var completion_run_id: String = str(PlaytestTelemetryScript.active_run(main.playtest_store).get("run_id", ""))
	_check(not completion_run_id.is_empty(), "completion fixture has stable run ownership")
	var completion_boss_chapter: String = main.current_chapter_id
	_check(main._record_boss_defeated(completion_boss_chapter), "completion fixture persists its boss reward receipt before terminal telemetry")
	var boss_count_before_terminal: int = main._profile_stat("bosses_defeated")
	var boss_marks_before_terminal: int = main._progression_currency_amount()
	var stale_completion_state: Dictionary = main._create_save_state()
	_check(SaveManagerScript.save_run(stale_completion_state), "integration fixture writes an owned pre-completion save")
	var runs_completed_before: int = main._profile_stat("runs_completed")
	var completion_marks_before: int = main._progression_currency_amount()
	var profile_before_failed_completion: Dictionary = main.player_profile.duplicate(true)
	main.run_completed = true
	var blocked_profile_path: String = SaveManagerScript.profile_path()
	if FileAccess.file_exists(blocked_profile_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_profile_path))
	_check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_profile_path)) == OK, "failure fixture blocks the profile target with a real directory")
	_check(not main._record_run_completed(), "completion remains open when profile persistence fails")
	_check(main.player_profile == profile_before_failed_completion and str(SaveManagerScript.load_run().get("playtest_active_run", {}).get("run_id", "")) == completion_run_id, "failed profile persistence rolls back rewards and preserves the owned run save")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_profile_path)) == OK, "failure fixture releases the profile target")
	_check(main._record_run_completed(), "completion succeeds after profile storage recovers")
	_check(str(SaveManagerScript.load_run().get("run_id", "")) == completion_run_id, "profile persistence alone keeps the owned run save until terminal telemetry is durable")
	_check(not main._finalize_terminal_run_storage("victory", "wrong_identity", "different-run-id") and main._active_playtest_run_id() == completion_run_id, "terminal finalization rejects a telemetry identity mismatch and keeps the active run retryable")
	_check(main._finalize_terminal_run_storage("victory", "integration_completion", completion_run_id), "victory telemetry persists before terminal save cleanup")
	_check(SaveManagerScript.load_run().is_empty(), "durable full run completion invalidates the stale resumable save")
	_check(main._record_boss_defeated(completion_boss_chapter) and main._profile_stat("bosses_defeated") == boss_count_before_terminal and main._progression_currency_amount() == boss_marks_before_terminal + int(main.progression_data.get("currency", {}).get("full_run_bonus", 3)), "victory cleanup retry accepts the existing boss receipt without requiring an active telemetry row")
	_check(not main._record_boss_defeated("unreceipted_terminal_chapter"), "an archived run cannot mint a new boss receipt after terminal telemetry")
	_check(SaveManagerScript.save_run(stale_completion_state), "restart guard fixture restores the stale pre-terminal save after victory telemetry is durable")
	var stale_guard = scene.instantiate()
	stale_guard.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(stale_guard)
	await process_frame
	await process_frame
	stale_guard._on_load_pressed()
	_check(stale_guard._playtest_active_run().is_empty() and stale_guard._archived_playtest_run_outcome(completion_run_id) == "victory" and SaveManagerScript.load_run().is_empty(), "a restarted app rejects and cleans a stale save whose victory is already archived")
	stale_guard.queue_free()
	await process_frame
	_check(SaveManagerScript.save_run(main._create_save_state()), "cleanup retry fixture recreates the same terminal run save after telemetry was archived")
	_check(main._finalize_terminal_run_storage("victory", "cleanup_retry", completion_run_id) and SaveManagerScript.load_run().is_empty(), "terminal cleanup retry requires and accepts the matching archived telemetry record")
	var runs_completed_after: int = main._profile_stat("runs_completed")
	var completion_marks_after: int = main._progression_currency_amount()
	var completion_receipt_id := "completion:%s" % completion_run_id
	_check(runs_completed_after == runs_completed_before + 1 and completion_marks_after == completion_marks_before + int(main.progression_data.get("currency", {}).get("full_run_bonus", 3)), "first completion receipt grants permanent rewards exactly once")
	_check(main.player_profile.get("reward_receipt_ids", []).has(completion_receipt_id), "completed run persists its reward receipt")
	main._record_run_completed()
	_check(main._profile_stat("runs_completed") == runs_completed_after and main._progression_currency_amount() == completion_marks_after, "repeating the same completion receipt cannot duplicate permanent rewards")
	main.combat.phase = "player"
	main._on_save_pressed()
	_check(SaveManagerScript.load_run().is_empty(), "full run completion rejects an explicit save attempt")

	main._on_character_selected("arc_tinker")
	var current_run_id: String = str(PlaytestTelemetryScript.active_run(main.playtest_store).get("run_id", ""))
	var protected_state: Dictionary = main._create_save_state()
	protected_state["playtest_active_run"] = (protected_state.get("playtest_active_run", {}) as Dictionary).duplicate(true)
	protected_state["playtest_active_run"]["run_id"] = "protected-other-run"
	_check(SaveManagerScript.save_run(protected_state), "integration fixture writes a save owned by another run")
	main.combat.phase = "lost"
	main.combat.player["hp"] = 0
	main._refresh_combat()
	_check(not current_run_id.is_empty() and str(SaveManagerScript.load_run().get("playtest_active_run", {}).get("run_id", "")) == "protected-other-run", "terminal cleanup preserves a save owned by another run")
	SaveManagerScript.delete_run()

	main._on_character_selected("ember_exile")
	var retryable_run_id: String = main._active_playtest_run_id()
	_check(not retryable_run_id.is_empty() and SaveManagerScript.save_run(main._create_save_state()), "terminal telemetry failure fixture writes an owned resumable save")
	var blocked_telemetry_path := SaveManagerScript.playtest_store_path()
	if FileAccess.file_exists(blocked_telemetry_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_telemetry_path))
	_check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_telemetry_path)) == OK, "terminal telemetry failure fixture blocks the telemetry target")
	main.combat.phase = "lost"
	main.combat.player["hp"] = 0
	main._refresh_combat()
	var failure_stage: Node = main.reward_row.find_child("PcDefeatExperience", true, false)
	var persistence_retry_button := failure_stage.find_child("DefeatCleanupRetryButton", true, false) as Button if failure_stage != null else null
	var new_run_retry_button := failure_stage.find_child("DefeatRetryButton", true, false) as Button if failure_stage != null else null
	_check(str(SaveManagerScript.load_run().get("run_id", "")) == retryable_run_id and not main._playtest_active_run().is_empty(), "failed defeat telemetry persistence preserves both the owned run save and retryable active telemetry")
	_check(not main.last_terminal_persistence_error.is_empty() and persistence_retry_button != null and new_run_retry_button != null and new_run_retry_button.disabled, "defeat page exposes a visible persistence retry and blocks abandoning the recoverable save")
	_check(main.last_combat_layout_overflow <= 0.0 and int(main.reward_scroll.get("vertical_scroll_mode")) == 0 and not main.reward_scroll.get_v_scroll_bar().visible, "retryable defeat storage error still fits the fixed 720p page without a system scrollbar")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_telemetry_path)) == OK, "terminal telemetry failure fixture releases the telemetry target")
	persistence_retry_button.pressed.emit()
	_check(main.last_terminal_persistence_error.is_empty() and SaveManagerScript.load_run().is_empty() and main._playtest_active_run().is_empty(), "defeat persistence retry durably archives telemetry before deleting its owned save")

	main._on_profile_pressed()
	_check(main.last_profile_export_button_visible, "profile page exposes the playtest report action")
	_check(main.last_combat_layout_overflow <= 0.0, "profile export action keeps the PC page inside 720p")

	main.queue_free()
	await process_frame
	SaveManagerScript.save_playtest_store(PlaytestTelemetryScript.default_store())
	var legacy_source = scene.instantiate()
	legacy_source.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(legacy_source)
	await process_frame
	await process_frame
	legacy_source._on_character_selected("ember_exile")
	var legacy_state: Dictionary = legacy_source._create_save_state()
	legacy_state["version"] = 2
	legacy_state.erase("run_id")
	legacy_state.erase("playtest_active_run")
	_check(SaveManagerScript.save_run(legacy_state), "legacy fixture writes an alpha.1-style v2 run save without telemetry identity")
	legacy_source.queue_free()
	await process_frame

	var legacy_first_load = scene.instantiate()
	legacy_first_load.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(legacy_first_load)
	await process_frame
	await process_frame
	legacy_first_load._on_load_pressed()
	await process_frame
	var migrated_run_id: String = legacy_first_load._active_playtest_run_id()
	var migrated_state: Dictionary = SaveManagerScript.load_run()
	_check(migrated_run_id.begins_with("legacy_") and int(migrated_state.get("version", 0)) == 5 and str(migrated_state.get("run_id", "")) == migrated_run_id and str(migrated_state.get("playtest_active_run", {}).get("run_id", "")) == migrated_run_id, "first legacy load persists one stable identity into the v5 run save")
	legacy_first_load.queue_free()
	await process_frame

	var legacy_second_load = scene.instantiate()
	legacy_second_load.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(legacy_second_load)
	await process_frame
	await process_frame
	legacy_second_load._on_load_pressed()
	await process_frame
	_check(legacy_second_load._active_playtest_run_id() == migrated_run_id, "restarting and loading the migrated legacy save keeps the same run identity")
	legacy_second_load.combat.phase = "lost"
	legacy_second_load.combat.player["hp"] = 0
	legacy_second_load._refresh_combat()
	_check(SaveManagerScript.load_run().is_empty(), "migrated legacy ownership allows terminal cleanup to delete its own save")
	legacy_second_load.queue_free()
	await process_frame
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
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

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
