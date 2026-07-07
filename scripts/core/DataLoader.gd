class_name DataLoader
extends RefCounted

static func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open JSON file: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON root must be an object: %s" % path)
		return {}

	return parsed

static func index_by_id(items: Array) -> Dictionary:
	var result := {}
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			result[item["id"]] = item
	return result
