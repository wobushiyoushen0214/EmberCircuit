class_name BalanceCandidateOverlay
extends RefCounted

const CandidateSelector = preload("res://scripts/tools/BalanceCandidateSelector.gd")
const SCHEMA_VERSION := 1
const DATASET_NAMES := ["map_generation", "level_tree", "economy", "player", "relics"]
const ERROR_ORDER := [
	"overlay_file_missing",
	"overlay_json_invalid",
	"schema_version_unsupported",
	"candidate_id_invalid",
	"changes_empty",
	"dataset_forbidden",
	"path_forbidden",
	"path_duplicate",
	"value_invalid"
]
const ALLOWED_PATHS := {
	"map_generation.chapter_one.encounter_layer_bands": "encounter_layer_bands",
	"level_tree.route_constraints.max_pressure_nodes_between_campfires": "pressure",
	"level_tree.chapters.chapter_one.node_budget.campfire": "campfire_budget",
	"level_tree.chapters.chapter_two.node_budget.campfire": "campfire_budget",
	"level_tree.chapters.chapter_three.node_budget.campfire": "campfire_budget",
	"economy.campfire.heal_percent_of_max_hp": "heal_percent",
	"economy.reward_generation.card_rarity_weights": "card_rarity_weights",
	"player.characters.arc_tinker.starting_momentum": "starting_momentum",
	"player.characters.arc_tinker.starter_deck_ids": "starter_deck_ids",
	"player.characters.ember_exile.starter_deck_ids": "starter_deck_ids",
	"player.characters.pyre_ascetic.starter_deck_ids": "starter_deck_ids",
	"relics.relics.ember_bottle.effects.0.amount": "starter_relic_amount",
	"relics.relics.ash_rosary.effects.0.amount": "starter_relic_amount"
}

func load_and_apply(path: String, datasets: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _rejected(["overlay_file_missing"])
	var source_text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	if parser.parse(source_text) != OK or parser.data is not Dictionary:
		return _rejected(["overlay_json_invalid"])
	var payload: Dictionary = parser.data
	var validation_errors := _validate_payload(payload, datasets)
	if not validation_errors.is_empty():
		return _rejected(validation_errors)
	var candidate_id: String = payload["candidate_id"]
	var changes: Array = payload["changes"]

	var copied_datasets: Dictionary = {}
	for dataset_name in DATASET_NAMES:
		if not datasets.has(dataset_name):
			continue
		var source_dataset = datasets.get(dataset_name, {})
		copied_datasets[dataset_name] = (source_dataset as Dictionary).duplicate(true) if source_dataset is Dictionary else {}

	var applied_fields: Array = []
	var selector = CandidateSelector.new()
	for change_value in changes:
		var change: Dictionary = change_value
		var dataset_name := str(change.get("dataset", ""))
		var path_parts: Array = change["path"]
		if dataset_name in ["player", "relics"]:
			var selector_result: Dictionary = selector.apply(dataset_name, copied_datasets[dataset_name], path_parts, change.get("value"))
			if not bool(selector_result.get("ok", false)):
				return _rejected(selector_result.get("errors", ["path_forbidden"]))
		else:
			_apply_path(copied_datasets[dataset_name], path_parts, change.get("value"))
		applied_fields.append(_qualified_path(dataset_name, path_parts))
	applied_fields.sort()

	return {
		"ok": true,
		"metadata": {
			"schema_version": SCHEMA_VERSION,
			"candidate_id": candidate_id,
			"sha256": _sha256_file(path),
			"applied_fields": applied_fields
		},
		"datasets": copied_datasets,
		"errors": []
	}

func _validate_payload(payload: Dictionary, available_datasets = null) -> Array:
	if not _is_integer_number(payload.get("schema_version")) or int(payload.get("schema_version", 0)) != SCHEMA_VERSION:
		return ["schema_version_unsupported"]
	var candidate_id_value = payload.get("candidate_id")
	if typeof(candidate_id_value) != TYPE_STRING or not _valid_candidate_id(candidate_id_value):
		return ["candidate_id_invalid"]
	var changes_value = payload.get("changes")
	if changes_value is not Array or (changes_value as Array).is_empty():
		return ["changes_empty"]
	if _has_unknown_fields(payload, ["schema_version", "candidate_id", "changes"]):
		return ["value_invalid"]

	var errors: Array = []
	var seen_paths: Dictionary = {}
	for change_value in changes_value:
		if change_value is not Dictionary:
			_append_error(errors, "value_invalid")
			continue
		var change: Dictionary = change_value
		if _has_unknown_fields(change, ["dataset", "path", "value"]):
			_append_error(errors, "value_invalid")
			continue
		var dataset_value = change.get("dataset")
		if typeof(dataset_value) != TYPE_STRING or not DATASET_NAMES.has(dataset_value) or (available_datasets is Dictionary and not (available_datasets as Dictionary).has(dataset_value)):
			_append_error(errors, "dataset_forbidden")
			continue
		var path_value = change.get("path")
		if not _valid_path_parts(path_value):
			_append_error(errors, "path_forbidden")
			continue
		var qualified_path := _qualified_path(dataset_value, path_value)
		if seen_paths.has(qualified_path):
			_append_error(errors, "path_duplicate")
		else:
			seen_paths[qualified_path] = true
		if not ALLOWED_PATHS.has(qualified_path):
			_append_error(errors, "path_forbidden")
			continue
		if not change.has("value") or not _valid_value(str(ALLOWED_PATHS[qualified_path]), change.get("value")):
			_append_error(errors, "value_invalid")
	errors.sort_custom(func(a, b) -> bool: return ERROR_ORDER.find(a) < ERROR_ORDER.find(b))
	return errors

func _has_unknown_fields(value: Dictionary, allowed_fields: Array) -> bool:
	for field_value in value.keys():
		if not allowed_fields.has(str(field_value)):
			return true
	return false

func _valid_candidate_id(candidate_id: String) -> bool:
	if candidate_id.is_empty():
		return false
	for index in range(candidate_id.length()):
		var code := candidate_id.unicode_at(index)
		var allowed := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code in [45, 46, 95]
		if not allowed:
			return false
	return true

func _valid_path_parts(path_value) -> bool:
	if path_value is not Array or (path_value as Array).is_empty():
		return false
	for part in path_value:
		if typeof(part) != TYPE_STRING or str(part).is_empty():
			return false
	return true

func _valid_value(validator: String, value) -> bool:
	match validator:
		"encounter_layer_bands":
			return _valid_encounter_layer_bands(value)
		"pressure":
			return _is_integer_number(value) and int(value) >= 1 and int(value) <= 4
		"campfire_budget":
			return _valid_campfire_budget(value)
		"heal_percent":
			return _is_integer_number(value) and int(value) >= 1 and int(value) <= 100
		"card_rarity_weights":
			return _valid_card_rarity_weights(value)
		"starting_momentum":
			return _is_integer_number(value) and int(value) >= 0 and int(value) <= 5
		"starter_deck_ids":
			return _valid_starter_deck_ids(value)
		"starter_relic_amount":
			return _is_integer_number(value) and int(value) >= 1 and int(value) <= 10
	return false

func _valid_starter_deck_ids(value) -> bool:
	if value is not Array or (value as Array).size() != 10:
		return false
	for card_id_value in value:
		if typeof(card_id_value) != TYPE_STRING or str(card_id_value).strip_edges().is_empty():
			return false
	return true

func _valid_encounter_layer_bands(value) -> bool:
	if value is not Dictionary:
		return false
	var config: Dictionary = value
	var config_keys: Array = config.keys()
	config_keys.sort()
	if config_keys != ["combat"]:
		return false
	var bands_value = config.get("combat")
	if bands_value is not Array or (bands_value as Array).is_empty():
		return false
	var ranges: Array = []
	for band_value in bands_value:
		if band_value is not Dictionary:
			return false
		var band: Dictionary = band_value
		var band_keys: Array = band.keys()
		band_keys.sort()
		if band_keys != ["encounter_ids", "layers"]:
			return false
		var layers_value = band.get("layers")
		if layers_value is not Array or (layers_value as Array).size() != 2:
			return false
		var layers: Array = layers_value
		if not _is_integer_number(layers[0]) or not _is_integer_number(layers[1]):
			return false
		var start_layer := int(layers[0])
		var end_layer := int(layers[1])
		if start_layer < 0 or end_layer < start_layer:
			return false
		var encounter_ids_value = band.get("encounter_ids")
		if encounter_ids_value is not Array or (encounter_ids_value as Array).is_empty():
			return false
		for encounter_id in encounter_ids_value:
			if typeof(encounter_id) != TYPE_STRING or str(encounter_id).strip_edges().is_empty():
				return false
		for existing_range_value in ranges:
			var existing_range: Array = existing_range_value
			if start_layer <= int(existing_range[1]) and end_layer >= int(existing_range[0]):
				return false
		ranges.append([start_layer, end_layer])
	return true

func _valid_campfire_budget(value) -> bool:
	if value is not Array or (value as Array).size() != 2:
		return false
	var budget: Array = value
	return _is_integer_number(budget[0]) and _is_integer_number(budget[1]) and int(budget[0]) >= 0 and int(budget[1]) >= int(budget[0])

func _valid_card_rarity_weights(value) -> bool:
	if value is not Dictionary:
		return false
	var weights: Dictionary = value
	var keys: Array = weights.keys()
	keys.sort()
	if keys != ["common", "rare", "uncommon"]:
		return false
	var total := 0
	for key in keys:
		if not _is_integer_number(weights[key]) or int(weights[key]) < 0:
			return false
		total += int(weights[key])
	return total == 100

func _is_integer_number(value) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	return float(value) == round(float(value))

func _append_error(errors: Array, error_code: String) -> void:
	if not errors.has(error_code):
		errors.append(error_code)

func _apply_path(dataset: Dictionary, path_parts: Array, value) -> void:
	var target := dataset
	for index in range(path_parts.size() - 1):
		var part := str(path_parts[index])
		if not target.has(part) or target[part] is not Dictionary:
			target[part] = {}
		target = target[part]
	var final_part := str(path_parts[path_parts.size() - 1])
	target[final_part] = value.duplicate(true) if value is Dictionary or value is Array else value

func _qualified_path(dataset_name: String, path_parts: Array) -> String:
	var parts := PackedStringArray([dataset_name])
	for path_part in path_parts:
		parts.append(str(path_part))
	return ".".join(parts)

func _sha256_file(path: String) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()

func _rejected(errors: Array) -> Dictionary:
	return {"ok": false, "metadata": {}, "datasets": {}, "errors": errors}
