class_name SaveManager
extends RefCounted

const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

const SAVE_PATH := "user://ember_circuit_run_save.json"
const SETTINGS_PATH := "user://ember_circuit_settings.json"
const PROFILE_PATH := "user://ember_circuit_profile.json"
const PLAYTEST_STORE_PATH := "user://ember_circuit_playtest_telemetry.json"
const PLAYTEST_EXPORT_PATH := "user://ember_circuit_playtest_report.json"
const DISCOVERY_CATEGORIES := ["cards", "relics", "potions", "enemies", "events", "challenges"]
const RUN_SAVE_VERSION := 5
const ATOMIC_TEMP_SUFFIX := ".tmp"
const ATOMIC_BACKUP_SUFFIX := ".bak"

static var _storage_namespace: String = ""

static func set_storage_namespace(namespace_id: String) -> void:
	_storage_namespace = namespace_id.strip_edges().replace("/", "_").replace("\\", "_").replace("..", "_")

static func clear_storage_namespace() -> void:
	_storage_namespace = ""

static func cleanup_storage_namespace() -> void:
	if _storage_namespace.is_empty():
		return
	for path in [run_save_path(), settings_path(), profile_path(), playtest_store_path(), playtest_export_path()]:
		_remove_atomic_files(path)

static func run_save_path() -> String:
	return _storage_path(SAVE_PATH)

static func settings_path() -> String:
	return _storage_path(SETTINGS_PATH)

static func profile_path() -> String:
	return _storage_path(PROFILE_PATH)

static func playtest_store_path() -> String:
	return _storage_path(PLAYTEST_STORE_PATH)

static func playtest_export_path() -> String:
	return _storage_path(PLAYTEST_EXPORT_PATH)

static func save_run(state: Dictionary) -> bool:
	var path := run_save_path()
	return _atomic_write_json(path, state, "run save")

static func load_run() -> Dictionary:
	var path := run_save_path()
	_recover_atomic_file(path)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open save file for reading: %s" % path)
		return {}

	var raw_text: String = file.get_as_text()
	file = null
	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is not a dictionary.")
		return {}
	var state: Dictionary = parsed
	var run_id: String = _run_id_from_state(state)
	if run_id.is_empty():
		run_id = "legacy_%s" % raw_text.sha256_text().substr(0, 20)
	var migration_needed: bool = int(state.get("version", 0)) < RUN_SAVE_VERSION or str(state.get("run_id", "")) != run_id
	state["version"] = max(RUN_SAVE_VERSION, int(state.get("version", 0)))
	state["run_id"] = run_id
	if migration_needed:
		_atomic_write_json(path, state, "migrated run save")
	return state

static func delete_run() -> bool:
	var path := run_save_path()
	_recover_atomic_file(path)
	if not FileAccess.file_exists(path):
		_remove_atomic_sidecars(path)
		return true
	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Cannot delete run save: %s" % path)
		return false
	_remove_atomic_sidecars(path)
	return true

static func delete_run_for_run_id(expected_run_id: String) -> bool:
	if expected_run_id.is_empty():
		return false
	var path := run_save_path()
	_recover_atomic_file(path)
	if not FileAccess.file_exists(path):
		return not FileAccess.file_exists(path + ATOMIC_TEMP_SUFFIX) and not FileAccess.file_exists(path + ATOMIC_BACKUP_SUFFIX)
	var saved_state: Dictionary = load_run()
	if saved_state.is_empty():
		return false
	var saved_run_id: String = _run_id_from_state(saved_state)
	if saved_run_id.is_empty():
		return false
	if saved_run_id != expected_run_id:
		return true
	return delete_run()

static func default_settings() -> Dictionary:
	return {
		"version": 2,
		"audio_enabled": true,
		"master_volume": 1.0,
		"music_enabled": true,
		"music_volume": 0.65,
		"screen_shake_enabled": true,
		"hit_stop_enabled": true,
		"floating_text_enabled": true,
		"tutorial_enabled": true,
		"tutorial_completed_steps": [],
		"reduced_motion": false,
		"flash_intensity": 1.0,
		"particle_density": 1.0
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
	settings["reduced_motion"] = bool(raw_settings.get("reduced_motion", false))
	settings["flash_intensity"] = snappedf(clampf(float(raw_settings.get("flash_intensity", 1.0)), 0.0, 1.0), 0.25)
	settings["particle_density"] = snappedf(clampf(float(raw_settings.get("particle_density", 1.0)), 0.0, 1.0), 0.25)
	var completed_steps: Array = []
	for step_id in raw_settings.get("tutorial_completed_steps", []):
		var normalized_id: String = str(step_id)
		if not normalized_id.is_empty() and not completed_steps.has(normalized_id):
			completed_steps.append(normalized_id)
	settings["tutorial_completed_steps"] = completed_steps
	return settings

static func save_settings(settings: Dictionary) -> bool:
	var path := settings_path()
	return _atomic_write_json(path, normalized_settings(settings), "settings")

static func load_settings() -> Dictionary:
	var path := settings_path()
	_recover_atomic_file(path)
	if not FileAccess.file_exists(path):
		return default_settings()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open settings file for reading: %s" % path)
		return default_settings()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Settings file is not a dictionary.")
		return default_settings()
	return normalized_settings(parsed)

static func default_profile() -> Dictionary:
	return {
		"version": 3,
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
		"reward_receipt_ids": [],
		"forge_marks": 0,
		"purchased_upgrade_node_ids": [],
		"equipped_skill_book_by_character": {},
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
	profile["reward_receipt_ids"] = _unique_string_array(raw_profile.get("reward_receipt_ids", []))
	profile["forge_marks"] = max(0, int(raw_profile.get("forge_marks", 0)))
	profile["purchased_upgrade_node_ids"] = _unique_string_array(raw_profile.get("purchased_upgrade_node_ids", []))
	profile["equipped_skill_book_by_character"] = _normalized_string_dictionary(raw_profile.get("equipped_skill_book_by_character", {}))
	profile["discovered"] = _normalized_discovered(raw_profile.get("discovered", {}))
	return profile

static func save_profile(profile: Dictionary) -> bool:
	var path := profile_path()
	return _atomic_write_json(path, normalized_profile(profile), "profile")

static func load_profile() -> Dictionary:
	var path := profile_path()
	_recover_atomic_file(path)
	if not FileAccess.file_exists(path):
		return default_profile()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open profile file for reading: %s" % path)
		return default_profile()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Profile file is not a dictionary.")
		return default_profile()
	return normalized_profile(parsed)

static func save_playtest_store(store: Dictionary) -> bool:
	var path := playtest_store_path()
	return _atomic_write_json(path, PlaytestTelemetryScript.normalize_store(store), "playtest telemetry")

static func load_playtest_store() -> Dictionary:
	var path := playtest_store_path()
	_recover_atomic_file(path)
	if not FileAccess.file_exists(path):
		return PlaytestTelemetryScript.default_store()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open playtest telemetry file for reading: %s" % path)
		return PlaytestTelemetryScript.default_store()
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Playtest telemetry file is not a dictionary.")
		return PlaytestTelemetryScript.default_store()
	return PlaytestTelemetryScript.normalize_store(parsed)

static func export_playtest_report(report: Dictionary) -> bool:
	if int(report.get("schema_version", 0)) != PlaytestTelemetryScript.SCHEMA_VERSION:
		push_error("Playtest report has an unsupported schema version.")
		return false
	var path := playtest_export_path()
	return _atomic_write_json(path, report, "playtest report")

static func playtest_export_absolute_path() -> String:
	return ProjectSettings.globalize_path(playtest_export_path())

static func _storage_path(default_path: String) -> String:
	if _storage_namespace.is_empty():
		return default_path
	return "user://%s_%s" % [_storage_namespace, default_path.get_file()]

static func _run_id_from_state(state: Dictionary) -> String:
	var active_run_value = state.get("playtest_active_run", {})
	if active_run_value is Dictionary:
		var active_run_id: String = str((active_run_value as Dictionary).get("run_id", ""))
		if not active_run_id.is_empty():
			return active_run_id
	return str(state.get("run_id", ""))

static func _atomic_write_json(path: String, value: Dictionary, label: String) -> bool:
	var serialized: String = JSON.stringify(value, "\t")
	var temp_path := path + ATOMIC_TEMP_SUFFIX
	var backup_path := path + ATOMIC_BACKUP_SUFFIX
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot open %s temp file for writing: %s" % [label, temp_path])
		return false
	file.store_string(serialized)
	file.flush()
	var write_error: Error = file.get_error()
	file = null
	if write_error != OK or not FileAccess.file_exists(temp_path) or FileAccess.get_file_as_string(temp_path) != serialized:
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_warning("Cannot verify %s temp file: %s" % [label, temp_path])
		return false
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	var had_previous: bool = FileAccess.file_exists(path)
	if had_previous:
		var backup_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path))
		if backup_error != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			push_warning("Cannot stage previous %s for replacement: %s" % [label, path])
			return false
	var replace_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))
	if replace_error != OK:
		if had_previous and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_warning("Cannot replace %s atomically: %s" % [label, path])
		return false
	if not FileAccess.file_exists(path) or FileAccess.get_file_as_string(path) != serialized:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if had_previous and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))
		push_warning("Cannot verify replaced %s: %s" % [label, path])
		return false
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	return true

static func _recover_atomic_file(path: String) -> void:
	var temp_path := path + ATOMIC_TEMP_SUFFIX
	var backup_path := path + ATOMIC_BACKUP_SUFFIX
	if FileAccess.file_exists(path):
		if _valid_json_file(path):
			_remove_atomic_sidecars(path)
			return
		if _valid_json_file(temp_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK:
				_remove_atomic_sidecars(path)
				return
		if _valid_json_file(backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path)) == OK:
				_remove_atomic_sidecars(path)
				return
		return
	if _valid_json_file(temp_path):
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK:
			if FileAccess.file_exists(backup_path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
			return
	if _valid_json_file(backup_path):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))
	if FileAccess.file_exists(path):
		_remove_atomic_sidecars(path)

static func _valid_json_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(path)) == OK and parser.data is Dictionary

static func _remove_atomic_sidecars(path: String) -> void:
	for sidecar_path in [path + ATOMIC_TEMP_SUFFIX, path + ATOMIC_BACKUP_SUFFIX]:
		if FileAccess.file_exists(sidecar_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(sidecar_path))

static func _remove_atomic_files(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_remove_atomic_sidecars(path)

static func _unique_string_array(raw_array: Array) -> Array:
	var normalized: Array = []
	for value in raw_array:
		var value_id: String = str(value)
		if not value_id.is_empty() and not normalized.has(value_id):
			normalized.append(value_id)
	return normalized

static func _normalized_string_dictionary(raw_dictionary: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key_value in raw_dictionary.keys():
		var key: String = str(key_value).strip_edges()
		var value: String = str(raw_dictionary.get(key_value, "")).strip_edges()
		if not key.is_empty() and not value.is_empty():
			normalized[key] = value
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
