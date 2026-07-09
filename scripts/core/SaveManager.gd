class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://ember_circuit_run_save.json"
const SETTINGS_PATH := "user://ember_circuit_settings.json"
const PROFILE_PATH := "user://ember_circuit_profile.json"
const DISCOVERY_CATEGORIES := ["cards", "relics", "potions", "enemies", "events", "challenges"]

static func save_run(state: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for writing: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(state, "\t"))
	return true

static func load_run() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open save file for reading: %s" % SAVE_PATH)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is not a dictionary.")
		return {}
	return parsed

static func default_settings() -> Dictionary:
	return {
		"version": 1,
		"audio_enabled": true,
		"master_volume": 1.0,
		"music_enabled": true,
		"music_volume": 0.65,
		"screen_shake_enabled": true,
		"hit_stop_enabled": true,
		"floating_text_enabled": true,
		"tutorial_enabled": true,
		"tutorial_completed_steps": []
	}

static func normalized_settings(raw_settings: Dictionary) -> Dictionary:
	var settings: Dictionary = default_settings()
	settings["audio_enabled"] = bool(raw_settings.get("audio_enabled", settings.get("audio_enabled", true)))
	settings["master_volume"] = clamp(float(raw_settings.get("master_volume", settings.get("master_volume", 1.0))), 0.0, 1.0)
	settings["music_enabled"] = bool(raw_settings.get("music_enabled", settings.get("music_enabled", true)))
	settings["music_volume"] = clamp(float(raw_settings.get("music_volume", settings.get("music_volume", 0.65))), 0.0, 1.0)
	settings["screen_shake_enabled"] = bool(raw_settings.get("screen_shake_enabled", settings.get("screen_shake_enabled", true)))
	settings["hit_stop_enabled"] = bool(raw_settings.get("hit_stop_enabled", settings.get("hit_stop_enabled", true)))
	settings["floating_text_enabled"] = bool(raw_settings.get("floating_text_enabled", settings.get("floating_text_enabled", true)))
	settings["tutorial_enabled"] = bool(raw_settings.get("tutorial_enabled", settings.get("tutorial_enabled", true)))
	var completed_steps: Array = []
	for step_id in raw_settings.get("tutorial_completed_steps", []):
		var normalized_id: String = str(step_id)
		if not normalized_id.is_empty() and not completed_steps.has(normalized_id):
			completed_steps.append(normalized_id)
	settings["tutorial_completed_steps"] = completed_steps
	return settings

static func save_settings(settings: Dictionary) -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open settings file for writing: %s" % SETTINGS_PATH)
		return false
	file.store_string(JSON.stringify(normalized_settings(settings), "\t"))
	return true

static func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return default_settings()

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open settings file for reading: %s" % SETTINGS_PATH)
		return default_settings()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Settings file is not a dictionary.")
		return default_settings()
	return normalized_settings(parsed)

static func default_profile() -> Dictionary:
	return {
		"version": 1,
		"stats": {
			"runs_started": 0,
			"runs_completed": 0,
			"bosses_defeated": 0,
			"cards_removed": 0,
			"best_gold": 0,
			"highest_deck_size": 0,
			"best_challenge_level_completed": 0,
			"max_challenge_level_unlocked": 0
		},
		"completed_chapters": [],
		"character_completions": [],
		"unlocked_achievement_ids": [],
		"last_unlock_ids": [],
		"discovered": _empty_discovered()
	}

static func normalized_profile(raw_profile: Dictionary) -> Dictionary:
	var profile: Dictionary = default_profile()
	var raw_stats: Dictionary = raw_profile.get("stats", {})
	var stats: Dictionary = profile.get("stats", {})
	for stat_id in stats.keys():
		stats[stat_id] = max(0, int(raw_stats.get(stat_id, stats.get(stat_id, 0))))
	profile["stats"] = stats
	profile["completed_chapters"] = _unique_string_array(raw_profile.get("completed_chapters", []))
	profile["character_completions"] = _unique_string_array(raw_profile.get("character_completions", []))
	profile["unlocked_achievement_ids"] = _unique_string_array(raw_profile.get("unlocked_achievement_ids", []))
	profile["last_unlock_ids"] = _unique_string_array(raw_profile.get("last_unlock_ids", []))
	profile["discovered"] = _normalized_discovered(raw_profile.get("discovered", {}))
	return profile

static func save_profile(profile: Dictionary) -> bool:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open profile file for writing: %s" % PROFILE_PATH)
		return false
	file.store_string(JSON.stringify(normalized_profile(profile), "\t"))
	return true

static func load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return default_profile()

	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open profile file for reading: %s" % PROFILE_PATH)
		return default_profile()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Profile file is not a dictionary.")
		return default_profile()
	return normalized_profile(parsed)

static func _unique_string_array(raw_array: Array) -> Array:
	var normalized: Array = []
	for value in raw_array:
		var value_id: String = str(value)
		if not value_id.is_empty() and not normalized.has(value_id):
			normalized.append(value_id)
	return normalized

static func _empty_discovered() -> Dictionary:
	var discovered: Dictionary = {}
	for category in DISCOVERY_CATEGORIES:
		discovered[str(category)] = []
	return discovered

static func _normalized_discovered(raw_discovered: Dictionary) -> Dictionary:
	var discovered: Dictionary = _empty_discovered()
	for category in DISCOVERY_CATEGORIES:
		var category_id: String = str(category)
		discovered[category_id] = _unique_string_array(raw_discovered.get(category_id, []))
	return discovered
