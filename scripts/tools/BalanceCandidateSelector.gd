class_name BalanceCandidateSelector
extends RefCounted

func apply(dataset_name: String, dataset: Dictionary, path_parts: Array, value) -> Dictionary:
	match dataset_name:
		"player":
			return _apply_player(dataset, path_parts, value)
		"relics":
			return _apply_relic(dataset, path_parts, value)
	return _rejected("path_forbidden")

func _apply_player(dataset: Dictionary, path_parts: Array, value) -> Dictionary:
	if path_parts.size() != 3 or str(path_parts[0]) != "characters" or not ["starting_momentum", "starter_deck_ids"].has(str(path_parts[2])):
		return _rejected("path_forbidden")
	var match_result := _unique_entity(dataset.get("characters", []), str(path_parts[1]))
	if not bool(match_result.get("ok", false)):
		return match_result
	var entity: Dictionary = match_result["entity"]
	entity[str(path_parts[2])] = _copy_value(value)
	return _accepted()

func _apply_relic(dataset: Dictionary, path_parts: Array, value) -> Dictionary:
	if path_parts.size() != 5 or str(path_parts[0]) != "relics" or str(path_parts[2]) != "effects" or str(path_parts[3]) != "0" or str(path_parts[4]) != "amount":
		return _rejected("path_forbidden")
	var match_result := _unique_entity(dataset.get("relics", []), str(path_parts[1]))
	if not bool(match_result.get("ok", false)):
		return match_result
	var entity: Dictionary = match_result["entity"]
	var effects_value = entity.get("effects")
	if effects_value is not Array or (effects_value as Array).is_empty() or (effects_value as Array)[0] is not Dictionary:
		return _rejected("path_forbidden")
	var effect: Dictionary = (effects_value as Array)[0]
	effect["amount"] = _copy_value(value)
	return _accepted()

func _unique_entity(collection_value, entity_id: String) -> Dictionary:
	if collection_value is not Array:
		return _rejected("selector_not_found")
	var matches: Array = []
	for entity_value in collection_value:
		if entity_value is Dictionary and str((entity_value as Dictionary).get("id", "")) == entity_id:
			matches.append(entity_value)
	if matches.is_empty():
		return _rejected("selector_not_found")
	if matches.size() > 1:
		return _rejected("selector_ambiguous")
	return {"ok": true, "entity": matches[0], "errors": []}

func _copy_value(value):
	return value.duplicate(true) if value is Dictionary or value is Array else value

func _accepted() -> Dictionary:
	return {"ok": true, "errors": []}

func _rejected(error_code: String) -> Dictionary:
	return {"ok": false, "errors": [error_code]}
