extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

func _init() -> void:
	SaveManagerScript.set_storage_namespace("test_save_manager")
	SaveManagerScript.cleanup_storage_namespace()

	var state := {
		"version": 1,
		"selected_character_id": "arc_tinker",
		"run_deck_ids": ["ember_strike", "ash_guard+"],
		"run_relic_ids": ["ember_bottle"],
		"run_potion_ids": ["volatile_vial"],
		"run_hp": 42,
		"run_max_hp": 72,
		"run_gold": 123,
		"run_shop_remove_count": 2,
		"current_challenge_level": 1,
		"current_node_index": 3,
		"run_completed": false
	}

	_check(SaveManagerScript.save_run(state), "save_run returns true")
	var loaded: Dictionary = SaveManagerScript.load_run()
	_check(int(loaded.get("run_hp", 0)) == 42, "load_run restores HP")
	_check(int(loaded.get("run_gold", 0)) == 123, "load_run restores gold")
	_check(int(loaded.get("run_shop_remove_count", 0)) == 2, "load_run restores shop removal count")
	_check(int(loaded.get("current_challenge_level", 0)) == 1, "load_run restores challenge level")
	_check(loaded.get("run_deck_ids", []).size() == 2, "load_run restores deck")
	_check(str(loaded.get("run_deck_ids", [])[1]) == "ash_guard+", "load_run keeps upgraded card marker")
	_check(str(loaded.get("run_potion_ids", [])[0]) == "volatile_vial", "load_run restores potions")
	_check(str(loaded.get("selected_character_id", "")) == "arc_tinker", "load_run restores selected character")
	var recovery_path := SaveManagerScript.run_save_path()
	var recovery_temp_path := recovery_path + SaveManagerScript.ATOMIC_TEMP_SUFFIX
	var recovery_backup_path := recovery_path + SaveManagerScript.ATOMIC_BACKUP_SUFFIX
	_check(DirAccess.rename_absolute(ProjectSettings.globalize_path(recovery_path), ProjectSettings.globalize_path(recovery_backup_path)) == OK, "atomic recovery fixture stages the previous run save")
	var pending_state: Dictionary = state.duplicate(true)
	pending_state["run_hp"] = 37
	var pending_file := FileAccess.open(recovery_temp_path, FileAccess.WRITE)
	_check(pending_file != null, "atomic recovery fixture opens a complete temp file")
	if pending_file != null:
		pending_file.store_string(JSON.stringify(pending_state, "\t"))
		pending_file = null
	_check(int(SaveManagerScript.load_run().get("run_hp", 0)) == 37 and not FileAccess.file_exists(recovery_backup_path), "load_run promotes a verified temp file after an interrupted replacement")
	_check(SaveManagerScript.save_run(state), "corrupt-primary recovery fixture restores a verified run save")
	_check(DirAccess.rename_absolute(ProjectSettings.globalize_path(recovery_path), ProjectSettings.globalize_path(recovery_backup_path)) == OK, "corrupt-primary recovery fixture stages a valid backup")
	var corrupt_file := FileAccess.open(recovery_path, FileAccess.WRITE)
	_check(corrupt_file != null, "corrupt-primary recovery fixture opens the primary path")
	if corrupt_file != null:
		corrupt_file.store_string("[]")
		corrupt_file = null
	_check(int(SaveManagerScript.load_run().get("run_hp", 0)) == 42 and not FileAccess.file_exists(recovery_backup_path), "load_run restores a verified backup instead of keeping a corrupt primary")
	var owned_state: Dictionary = state.duplicate(true)
	owned_state["playtest_active_run"] = {"run_id": "owned-run-a"}
	_check(SaveManagerScript.save_run(owned_state), "ownership fixture writes run A")
	_check(SaveManagerScript.delete_run_for_run_id("current-run-b"), "deleting current run B treats an unrelated save as preserved")
	_check(str(SaveManagerScript.load_run().get("playtest_active_run", {}).get("run_id", "")) == "owned-run-a", "run B terminal cleanup does not delete saved run A")
	_check(not SaveManagerScript.delete_run_for_run_id(""), "empty run ownership cannot authorize deletion")
	_check(str(SaveManagerScript.load_run().get("playtest_active_run", {}).get("run_id", "")) == "owned-run-a", "empty ownership leaves the save untouched")
	_check(SaveManagerScript.delete_run_for_run_id("owned-run-a"), "matching run ownership deletes its save")
	_check(SaveManagerScript.load_run().is_empty(), "owned run save is removed after matching cleanup")
	_check(SaveManagerScript.save_run(owned_state), "sidecar cleanup fixture restores an owned run save")
	_check(DirAccess.rename_absolute(ProjectSettings.globalize_path(recovery_path), ProjectSettings.globalize_path(recovery_backup_path)) == OK, "sidecar cleanup fixture leaves the owned save only in a verified backup")
	_check(SaveManagerScript.delete_run_for_run_id("owned-run-a"), "owned cleanup recovers and deletes a verified atomic sidecar")
	_check(not FileAccess.file_exists(recovery_path) and not FileAccess.file_exists(recovery_temp_path) and not FileAccess.file_exists(recovery_backup_path), "owned cleanup cannot report success while a recoverable sidecar remains")
	_check(SaveManagerScript.save_run(state), "delete_run fixture restores a generic run save")
	_check(SaveManagerScript.delete_run(), "delete_run removes an existing run save")
	_check(SaveManagerScript.load_run().is_empty(), "deleted run save cannot be resumed")
	_check(SaveManagerScript.delete_run(), "delete_run is idempotent when no run save exists")

	var settings := {
		"audio_enabled": false,
		"master_volume": 1.4,
		"music_enabled": false,
		"music_volume": -0.25,
		"screen_shake_enabled": false,
		"hit_stop_enabled": true,
		"floating_text_enabled": false,
		"tutorial_enabled": false,
		"tutorial_completed_steps": ["character_select", "combat_player", "character_select"]
	}
	_check(SaveManagerScript.save_settings(settings), "save_settings returns true")
	var loaded_settings: Dictionary = SaveManagerScript.load_settings()
	_check(not bool(loaded_settings.get("audio_enabled", true)), "load_settings restores audio toggle")
	_check(is_equal_approx(float(loaded_settings.get("master_volume", 0.0)), 1.0), "load_settings clamps master volume")
	_check(not bool(loaded_settings.get("music_enabled", true)), "load_settings restores music toggle")
	_check(is_equal_approx(float(loaded_settings.get("music_volume", 1.0)), 0.0), "load_settings clamps music volume")
	_check(not bool(loaded_settings.get("screen_shake_enabled", true)), "load_settings restores screen shake toggle")
	_check(bool(loaded_settings.get("hit_stop_enabled", false)), "load_settings restores hit stop toggle")
	_check(not bool(loaded_settings.get("floating_text_enabled", true)), "load_settings restores floating text toggle")
	_check(not bool(loaded_settings.get("tutorial_enabled", true)), "load_settings restores tutorial toggle")
	_check(loaded_settings.get("tutorial_completed_steps", []).size() == 2, "load_settings normalizes tutorial completed steps")
	_check(SaveManagerScript.save_settings(SaveManagerScript.default_settings()), "save_settings can restore defaults")

	var profile := {
		"version": 1,
		"stats": {
			"runs_started": 3,
			"runs_completed": 1,
			"bosses_defeated": 4,
			"cards_removed": 2,
			"best_gold": 180,
			"highest_deck_size": 28,
			"best_challenge_level_completed": 2,
			"max_challenge_level_unlocked": 3
		},
		"completed_chapters": ["chapter_one", "chapter_two", "chapter_one"],
		"character_completions": ["ember_exile", "ember_exile"],
		"unlocked_achievement_ids": ["first_ignition", "boss_breaker", "first_ignition"],
		"last_unlock_ids": ["boss_breaker", "boss_breaker"],
		"reward_receipt_ids": ["boss:fixture:chapter_one", "boss:fixture:chapter_one", "completion:fixture"],
		"discovered": {
			"cards": ["ember_strike", "ash_guard", "ember_strike"],
			"relics": ["ember_bottle", "ember_bottle"],
			"potions": ["volatile_vial"],
			"enemies": ["soot_raider"],
			"events": ["broken_reactor"],
			"challenges": ["0", "1", "1"]
		}
	}
	_check(SaveManagerScript.save_profile(profile), "save_profile returns true")
	var loaded_profile: Dictionary = SaveManagerScript.load_profile()
	var loaded_stats: Dictionary = loaded_profile.get("stats", {})
	_check(int(loaded_stats.get("runs_started", 0)) == 3, "load_profile restores run count")
	_check(int(loaded_stats.get("bosses_defeated", 0)) == 4, "load_profile restores boss count")
	_check(int(loaded_stats.get("cards_removed", 0)) == 2, "load_profile restores card removal count")
	_check(int(loaded_stats.get("best_challenge_level_completed", 0)) == 2, "load_profile restores best challenge level")
	_check(int(loaded_stats.get("max_challenge_level_unlocked", 0)) == 3, "load_profile restores unlocked challenge level")
	_check(loaded_profile.get("completed_chapters", []).size() == 2, "load_profile de-duplicates completed chapters")
	_check(loaded_profile.get("character_completions", []).size() == 1, "load_profile de-duplicates character completions")
	_check(loaded_profile.get("unlocked_achievement_ids", []).size() == 2, "load_profile de-duplicates achievements")
	_check(loaded_profile.get("last_unlock_ids", []).size() == 1, "load_profile de-duplicates latest unlocks")
	_check(int(loaded_profile.get("version", 0)) == 3 and loaded_profile.get("reward_receipt_ids", []).size() == 2, "profile v3 migrates and de-duplicates terminal reward receipts")
	var loaded_discovered: Dictionary = loaded_profile.get("discovered", {})
	_check(loaded_discovered.get("cards", []).size() == 2, "load_profile de-duplicates discovered cards")
	_check(loaded_discovered.get("challenges", []).size() == 2, "load_profile de-duplicates discovered challenge levels")
	_check(loaded_discovered.has("events") and loaded_discovered.has("potions"), "load_profile preserves discovery categories")
	_check(SaveManagerScript.save_profile(SaveManagerScript.default_profile()), "save_profile can restore defaults")
	var default_discovered: Dictionary = SaveManagerScript.default_profile().get("discovered", {})
	_check(default_discovered.has("cards") and default_discovered.get("cards", []).is_empty(), "default_profile includes empty discovery state")

	var playtest_store: Dictionary = PlaytestTelemetryScript.start_run(
		PlaytestTelemetryScript.default_store(),
		{
			"run_id": "save-manager-fixture",
			"timestamp_utc": "2026-07-15T12:00:00Z",
			"character_id": "arc_tinker",
			"challenge_level": 1,
			"username": "must-not-survive-normalization",
			"home_path": "/private/fixture"
		}
	)
	_check(SaveManagerScript.save_playtest_store(playtest_store), "save_playtest_store returns true")
	var loaded_playtest_store: Dictionary = SaveManagerScript.load_playtest_store()
	var loaded_active: Dictionary = PlaytestTelemetryScript.active_run(loaded_playtest_store)
	_check(str(loaded_active.get("run_id", "")) == "save-manager-fixture", "load_playtest_store restores active run")
	_check(not loaded_active.has("username") and not loaded_active.has("home_path"), "playtest store strips fields outside the privacy schema")

	var report: Dictionary = PlaytestTelemetryScript.build_report(loaded_playtest_store, {"generated_at_utc": "2026-07-15T12:30:00Z"})
	_check(SaveManagerScript.export_playtest_report(report), "export_playtest_report returns true")
	_check(FileAccess.file_exists(SaveManagerScript.playtest_export_path()), "playtest export is written to isolated user data")
	var exported = JSON.parse_string(FileAccess.get_file_as_string(SaveManagerScript.playtest_export_path()))
	_check(exported is Dictionary and int(exported.get("schema_version", 0)) == PlaytestTelemetryScript.SCHEMA_VERSION, "exported playtest report is valid versioned JSON")
	_check(SaveManagerScript.playtest_export_absolute_path() == ProjectSettings.globalize_path(SaveManagerScript.playtest_export_path()), "playtest export exposes a shareable absolute path")

	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
	print("Save manager smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
