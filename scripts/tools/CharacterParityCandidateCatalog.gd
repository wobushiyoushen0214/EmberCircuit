class_name CharacterParityCandidateCatalog
extends RefCounted

const STEPS := ["B0", "A1", "A2", "A3", "E1", "E2", "E3", "Y1", "Y2", "Y3"]
const ROLE_KEYS := ["arc", "ember", "pyre"]
const ROLE_STEPS := {
	"arc": ["A1", "A2", "A3"],
	"ember": ["E1", "E2", "E3"],
	"pyre": ["Y1", "Y2", "Y3"]
}
const ALLOWED_CARD_IDS := [
	"ash_guard", "brand_strike", "cooling_breath", "ember_strike", "induction_coil",
	"kindle_pain", "penitent_cut", "pressure_probe", "relay_strike", "scar_guard",
	"soot_step", "spark_throw", "static_primer", "wound_offering"
]
const ALLOWED_RELIC_IDS := ["ash_rosary", "ember_bottle"]

func validate(payloads: Dictionary) -> Dictionary:
	var errors: Array = []
	var keys: Array = payloads.keys()
	keys.sort()
	var expected_keys: Array = STEPS.duplicate()
	expected_keys.sort()
	if keys != expected_keys:
		errors.append("candidate_order_mismatch")
	for step_value in STEPS:
		var step := str(step_value)
		var payload_value = payloads.get(step)
		if payload_value is not Dictionary:
			_append_error(errors, "%s:input_missing" % step)
			continue
		var payload: Dictionary = payload_value
		if not _has_exact_keys(payload, ["schema_version", "candidate_id", "changes"]):
			_append_error(errors, "%s:identity_mismatch" % step)
			continue
		if not _is_integer_number(payload.get("schema_version")) or int(payload.get("schema_version", 0)) != 1 or payload.get("candidate_id") != "024-%s" % step:
			_append_error(errors, "%s:identity_mismatch" % step)
			continue
		var changes_value = payload.get("changes")
		if changes_value is not Array:
			_append_error(errors, "%s:exact_changes_mismatch" % step)
			continue
		var changes: Array = changes_value
		if not _changes_are_sorted(changes):
			_append_error(errors, "%s:change_order_mismatch" % step)
		if not _candidate_ids_allowed(changes):
			_append_error(errors, "%s:candidate_id_forbidden" % step)
		if _canonical(changes) != _canonical(_expected_changes(step)):
			_append_error(errors, "%s:exact_changes_mismatch" % step)
	return {"ok": errors.is_empty(), "errors": errors}

func compose_selected(payloads: Dictionary, selected_steps: Dictionary) -> Dictionary:
	var validation := validate(payloads)
	if not bool(validation.get("ok", false)):
		return {"ok": false, "payload": {}, "errors": validation.get("errors", [])}
	if not _has_exact_keys(selected_steps, ROLE_KEYS):
		return {"ok": false, "payload": {}, "errors": ["selected_steps_mismatch"]}
	for role_value in ROLE_KEYS:
		var role := str(role_value)
		var selected = selected_steps.get(role)
		if typeof(selected) != TYPE_STRING or not (ROLE_STEPS[role] as Array).has(selected):
			return {"ok": false, "payload": {}, "errors": ["selected_steps_mismatch"]}

	var merged_by_path: Dictionary = {}
	var errors: Array = []
	for step_value in ["B0", selected_steps["arc"], selected_steps["ember"], selected_steps["pyre"]]:
		var payload: Dictionary = payloads[str(step_value)]
		for change_value in payload.get("changes", []):
			var change: Dictionary = change_value
			var key := _qualified_path(change)
			if merged_by_path.has(key) and _canonical(merged_by_path[key]) != _canonical(change):
				_append_error(errors, "compose_conflict")
			else:
				merged_by_path[key] = change.duplicate(true)
	if not errors.is_empty():
		return {"ok": false, "payload": {}, "errors": errors}
	var paths: Array = merged_by_path.keys()
	paths.sort()
	var changes: Array = []
	for path_value in paths:
		changes.append(merged_by_path[path_value])
	var candidate_id := "024-C1-%s-%s-%s" % [selected_steps["arc"], selected_steps["ember"], selected_steps["pyre"]]
	return {"ok": true, "payload": {"schema_version": 1, "candidate_id": candidate_id, "changes": changes}, "errors": []}

func _expected_changes(step: String) -> Array:
	var changes := _base_changes()
	match step:
		"A1":
			changes.append(_change("player", ["characters", "arc_tinker", "starting_momentum"], 0))
		"A2":
			changes.append(_change("player", ["characters", "arc_tinker", "starter_deck_ids"], _arc_a2_deck()))
			changes.append(_change("player", ["characters", "arc_tinker", "starting_momentum"], 0))
		"A3":
			changes.append(_change("player", ["characters", "arc_tinker", "starter_deck_ids"], _arc_a3_deck()))
			changes.append(_change("player", ["characters", "arc_tinker", "starting_momentum"], 0))
		"E1":
			changes.append(_change("player", ["characters", "ember_exile", "starter_deck_ids"], _ember_e1_deck()))
		"E2":
			changes.append(_change("player", ["characters", "ember_exile", "starter_deck_ids"], _ember_e2_deck()))
		"E3":
			changes.append(_change("player", ["characters", "ember_exile", "starter_deck_ids"], _ember_e2_deck()))
			changes.append(_change("relics", ["relics", "ember_bottle", "effects", "0", "amount"], 5))
		"Y1":
			changes.append(_change("player", ["characters", "pyre_ascetic", "starter_deck_ids"], _pyre_y1_deck()))
		"Y2":
			changes.append(_change("player", ["characters", "pyre_ascetic", "starter_deck_ids"], _pyre_y2_deck()))
		"Y3":
			changes.append(_change("player", ["characters", "pyre_ascetic", "starter_deck_ids"], _pyre_y2_deck()))
			changes.append(_change("relics", ["relics", "ash_rosary", "effects", "0", "amount"], 3))
	changes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _qualified_path(a) < _qualified_path(b))
	return changes

func _base_changes() -> Array:
	return [
		_change("economy", ["campfire", "heal_percent_of_max_hp"], 30),
		_change("level_tree", ["chapters", "chapter_one", "node_budget", "campfire"], [2, 2]),
		_change("level_tree", ["chapters", "chapter_three", "node_budget", "campfire"], [2, 2]),
		_change("level_tree", ["chapters", "chapter_two", "node_budget", "campfire"], [2, 2]),
		_change("level_tree", ["route_constraints", "max_pressure_nodes_between_campfires"], 3),
		_change("map_generation", ["chapter_one", "encounter_layer_bands"], {"combat": [
			{"layers": [0, 0], "encounter_ids": ["intro_patrol"]},
			{"layers": [1, 2], "encounter_ids": ["intro_patrol", "polluted_lab", "cinder_kennels"]},
			{"layers": [3, 6], "encounter_ids": ["polluted_lab", "iron_checkpoint", "cinder_kennels"]}
		]})
	]

func _arc_a2_deck() -> Array:
	return ["spark_throw", "spark_throw", "relay_strike", "pressure_probe", "pressure_probe", "soot_step", "soot_step", "ash_guard", "ash_guard", "static_primer"]

func _arc_a3_deck() -> Array:
	return ["spark_throw", "spark_throw", "relay_strike", "pressure_probe", "induction_coil", "soot_step", "soot_step", "ash_guard", "ash_guard", "static_primer"]

func _ember_e1_deck() -> Array:
	return ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "pressure_probe", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"]

func _ember_e2_deck() -> Array:
	return ["ember_strike", "ember_strike", "ember_strike", "pressure_probe", "pressure_probe", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"]

func _pyre_y1_deck() -> Array:
	return ["brand_strike", "brand_strike", "penitent_cut", "penitent_cut", "scar_guard", "scar_guard", "scar_guard", "scar_guard", "kindle_pain", "cooling_breath"]

func _pyre_y2_deck() -> Array:
	return ["brand_strike", "brand_strike", "penitent_cut", "penitent_cut", "scar_guard", "scar_guard", "scar_guard", "scar_guard", "kindle_pain", "wound_offering"]

func _candidate_ids_allowed(changes: Array) -> bool:
	for change_value in changes:
		if change_value is not Dictionary:
			return false
		var change: Dictionary = change_value
		var path: Array = change.get("path", []) if change.get("path") is Array else []
		if str(change.get("dataset", "")) == "player" and not path.is_empty() and str(path.back()) == "starter_deck_ids":
			var deck = change.get("value")
			if deck is not Array or (deck as Array).size() != 10:
				return false
			for card_id in deck:
				if typeof(card_id) != TYPE_STRING or not ALLOWED_CARD_IDS.has(card_id):
					return false
		if str(change.get("dataset", "")) == "relics":
			if path.size() != 5 or str(path[0]) != "relics" or not ALLOWED_RELIC_IDS.has(path[1]):
				return false
	return true

func _changes_are_sorted(changes: Array) -> bool:
	var previous := ""
	var seen: Dictionary = {}
	for change_value in changes:
		if change_value is not Dictionary:
			return false
		var qualified := _qualified_path(change_value)
		if qualified.is_empty() or seen.has(qualified) or (not previous.is_empty() and qualified < previous):
			return false
		seen[qualified] = true
		previous = qualified
	return true

func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	var keys: Array = value.keys()
	keys.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	return keys == sorted_expected

func _change(dataset: String, path: Array, value) -> Dictionary:
	return {"dataset": dataset, "path": path, "value": value}

func _qualified_path(change: Dictionary) -> String:
	var parts: PackedStringArray = []
	for part in change.get("path", []):
		parts.append(str(part))
	return "%s.%s" % [str(change.get("dataset", "")), ".".join(parts)]

func _canonical(value):
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var normalized: Dictionary = {}
		for key in keys:
			normalized[str(key)] = _canonical(value[key])
		return normalized
	if value is Array:
		var normalized_array: Array = []
		for item in value:
			normalized_array.append(_canonical(item))
		return normalized_array
	if typeof(value) == TYPE_FLOAT and float(value) == round(float(value)):
		return int(round(float(value)))
	return value

func _append_error(errors: Array, code: String) -> void:
	if not errors.has(code):
		errors.append(code)

func _is_integer_number(value) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == round(float(value)))
