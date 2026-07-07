class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://ember_circuit_run_save.json"

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
