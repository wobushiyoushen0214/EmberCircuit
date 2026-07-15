extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

var original_user_files: Dictionary = {}

func _init() -> void:
	_capture_user_file(SaveManagerScript.SAVE_PATH)
	_capture_user_file(SaveManagerScript.SETTINGS_PATH)
	_capture_user_file(SaveManagerScript.PROFILE_PATH)
	_capture_user_file(SaveManagerScript.PLAYTEST_STORE_PATH)
	_capture_user_file(SaveManagerScript.PLAYTEST_EXPORT_PATH)

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
	_check(FileAccess.file_exists(SaveManagerScript.PLAYTEST_EXPORT_PATH), "playtest export is written to user data")
	var exported = JSON.parse_string(FileAccess.get_file_as_string(SaveManagerScript.PLAYTEST_EXPORT_PATH))
	_check(exported is Dictionary and int(exported.get("schema_version", 0)) == PlaytestTelemetryScript.SCHEMA_VERSION, "exported playtest report is valid versioned JSON")
	_check(SaveManagerScript.playtest_export_absolute_path() == ProjectSettings.globalize_path(SaveManagerScript.PLAYTEST_EXPORT_PATH), "playtest export exposes a shareable absolute path")

	_restore_user_files()
	print("Save manager smoke test passed.")
	quit(0)

func _capture_user_file(path: String) -> void:
	var entry := {
		"exists": FileAccess.file_exists(path),
		"text": ""
	}
	if bool(entry.get("exists", false)):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			entry["text"] = file.get_as_text()
	original_user_files[path] = entry

func _restore_user_files() -> void:
	for path in original_user_files.keys():
		var entry: Dictionary = original_user_files.get(path, {})
		if bool(entry.get("exists", false)):
			var file := FileAccess.open(str(path), FileAccess.WRITE)
			if file != null:
				file.store_string(str(entry.get("text", "")))
		elif FileAccess.file_exists(str(path)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(str(path)))

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		_restore_user_files()
		quit(1)
