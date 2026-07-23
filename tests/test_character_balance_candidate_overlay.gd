extends SceneTree

const OVERLAY_PATH := "res://scripts/tools/BalanceCandidateOverlay.gd"
const SELECTOR_PATH := "res://scripts/tools/BalanceCandidateSelector.gd"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_ac_024_01_character_path_allowlist_and_values()
	_test_ac_024_02_selector_identity_and_isolation()
	if not _failures.is_empty():
		push_error("Character balance candidate overlay test failed with %d assertion(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Character balance candidate overlay test passed.")
	quit(0)

func _test_ac_024_01_character_path_allowlist_and_values() -> void:
	var overlay_script = load(OVERLAY_PATH)
	_check(overlay_script != null, "AC-024-01 overlay helper loads")
	if overlay_script == null:
		return
	var helper = overlay_script.new()
	var ten_cards := ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "ember_strike", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"]
	var legal_changes := [
		{"dataset": "player", "path": ["characters", "arc_tinker", "starting_momentum"], "value": 0},
		{"dataset": "player", "path": ["characters", "arc_tinker", "starter_deck_ids"], "value": ten_cards},
		{"dataset": "player", "path": ["characters", "ember_exile", "starter_deck_ids"], "value": ten_cards},
		{"dataset": "player", "path": ["characters", "pyre_ascetic", "starter_deck_ids"], "value": ten_cards},
		{"dataset": "relics", "path": ["relics", "ember_bottle", "effects", "0", "amount"], "value": 5},
		{"dataset": "relics", "path": ["relics", "ash_rosary", "effects", "0", "amount"], "value": 3},
	]
	for index in range(legal_changes.size()):
		var errors: Array = helper._validate_payload(_payload("legal-%d" % index, legal_changes[index]))
		_check(errors.is_empty(), "AC-024-01 legal path %d passes exact validation" % index)

	var invalid_cases := [
		{"name": "unknown-dataset", "change": {"dataset": "cards", "path": ["characters", "arc_tinker", "starting_momentum"], "value": 0}, "error": "dataset_forbidden"},
		{"name": "unknown-player-path", "change": {"dataset": "player", "path": ["characters", "arc_tinker", "max_hp"], "value": 1}, "error": "path_forbidden"},
		{"name": "wrong-momentum-type", "change": {"dataset": "player", "path": ["characters", "arc_tinker", "starting_momentum"], "value": "0"}, "error": "value_invalid"},
		{"name": "momentum-out-of-range", "change": {"dataset": "player", "path": ["characters", "arc_tinker", "starting_momentum"], "value": 6}, "error": "value_invalid"},
		{"name": "deck-not-ten", "change": {"dataset": "player", "path": ["characters", "ember_exile", "starter_deck_ids"], "value": ten_cards.slice(0, 9)}, "error": "value_invalid"},
		{"name": "deck-empty-id", "change": {"dataset": "player", "path": ["characters", "pyre_ascetic", "starter_deck_ids"], "value": ["", "a", "b", "c", "d", "e", "f", "g", "h", "i"]}, "error": "value_invalid"},
		{"name": "relic-path-forbidden", "change": {"dataset": "relics", "path": ["relics", "ember_bottle", "effects", "0", "type"], "value": 5}, "error": "path_forbidden"},
		{"name": "relic-amount-out-of-range", "change": {"dataset": "relics", "path": ["relics", "ash_rosary", "effects", "0", "amount"], "value": 0}, "error": "value_invalid"},
	]
	for invalid_case_value in invalid_cases:
		var invalid_case: Dictionary = invalid_case_value
		var path := _write_payload(str(invalid_case.get("name", "invalid")), _payload(str(invalid_case.get("name", "invalid")), invalid_case.get("change", {})))
		var result: Dictionary = helper.load_and_apply(path, _datasets())
		var context := "AC-024-01 %s" % str(invalid_case.get("name", "invalid"))
		_check(not bool(result.get("ok", true)), "%s fails closed" % context)
		_check(result.get("errors", []) == [invalid_case.get("error", "")], "%s returns its fixed error" % context)
		_check((result.get("datasets", {}) as Dictionary).is_empty(), "%s returns no candidate datasets" % context)

func _test_ac_024_02_selector_identity_and_isolation() -> void:
	var selector_script = load(SELECTOR_PATH)
	_check(selector_script != null, "AC-024-02 selector helper loads")
	if selector_script != null:
		var selector = selector_script.new()
		var direct_source := _selector_datasets()["player"] as Dictionary
		var direct_source_snapshot := JSON.stringify(direct_source)
		var direct_copy := direct_source.duplicate(true)
		var direct_result: Dictionary = selector.apply("player", direct_copy, ["characters", "arc_tinker", "starting_momentum"], 0)
		_check(bool(direct_result.get("ok", false)), "AC-024-02 direct selector uniquely matches Arc")
		_check(int(_entity_by_id(direct_copy["characters"], "arc_tinker").get("starting_momentum", -1)) == 0, "AC-024-02 direct selector writes the target field")
		_check(JSON.stringify(_entity_by_id(direct_copy["characters"], "other_character")) == JSON.stringify(_entity_by_id(direct_source["characters"], "other_character")), "AC-024-02 direct selector preserves other entities")
		_check(JSON.stringify(direct_source) == direct_source_snapshot, "AC-024-02 direct selector caller can preserve source via deep copy")

	var overlay_script = load(OVERLAY_PATH)
	_check(overlay_script != null, "AC-024-02 overlay helper loads")
	if overlay_script == null:
		return
	var helper = overlay_script.new()
	var source_datasets := _selector_datasets()
	var source_snapshot := JSON.stringify(source_datasets)
	var other_character_snapshot := JSON.stringify(_entity_by_id(source_datasets["player"]["characters"], "other_character"))
	var other_relic_snapshot := JSON.stringify(_entity_by_id(source_datasets["relics"]["relics"], "other_relic"))
	var arc_deck := ["arc-0", "arc-1", "arc-2", "arc-3", "arc-4", "arc-5", "arc-6", "arc-7", "arc-8", "arc-9"]
	var ember_deck := ["ember-0", "ember-1", "ember-2", "ember-3", "ember-4", "ember-5", "ember-6", "ember-7", "ember-8", "ember-9"]
	var pyre_deck := ["pyre-0", "pyre-1", "pyre-2", "pyre-3", "pyre-4", "pyre-5", "pyre-6", "pyre-7", "pyre-8", "pyre-9"]
	var changes := [
		{"dataset": "player", "path": ["characters", "arc_tinker", "starting_momentum"], "value": 0},
		{"dataset": "player", "path": ["characters", "arc_tinker", "starter_deck_ids"], "value": arc_deck},
		{"dataset": "player", "path": ["characters", "ember_exile", "starter_deck_ids"], "value": ember_deck},
		{"dataset": "player", "path": ["characters", "pyre_ascetic", "starter_deck_ids"], "value": pyre_deck},
		{"dataset": "relics", "path": ["relics", "ember_bottle", "effects", "0", "amount"], "value": 5},
		{"dataset": "relics", "path": ["relics", "ash_rosary", "effects", "0", "amount"], "value": 3},
	]
	var path := _write_payload("selector-success", {"schema_version": 1, "candidate_id": "selector-success", "changes": changes})
	var result: Dictionary = helper.load_and_apply(path, source_datasets)
	_check(bool(result.get("ok", false)), "AC-024-02 overlay delegates all five entity selectors")
	_check(JSON.stringify(source_datasets) == source_snapshot, "AC-024-02 overlay never mutates source datasets")
	if bool(result.get("ok", false)):
		var candidate_datasets: Dictionary = result.get("datasets", {})
		var candidate_player: Dictionary = candidate_datasets.get("player", {})
		var candidate_relics: Dictionary = candidate_datasets.get("relics", {})
		_check(int(_entity_by_id(candidate_player.get("characters", []), "arc_tinker").get("starting_momentum", -1)) == 0, "AC-024-02 Arc momentum changes by id")
		_check(_entity_by_id(candidate_player.get("characters", []), "arc_tinker").get("starter_deck_ids", []) == arc_deck, "AC-024-02 Arc deck changes by id")
		_check(_entity_by_id(candidate_player.get("characters", []), "ember_exile").get("starter_deck_ids", []) == ember_deck, "AC-024-02 Ember deck changes by id")
		_check(_entity_by_id(candidate_player.get("characters", []), "pyre_ascetic").get("starter_deck_ids", []) == pyre_deck, "AC-024-02 Pyre deck changes by id")
		_check(int((_entity_by_id(candidate_relics.get("relics", []), "ember_bottle").get("effects", [{}]) as Array)[0].get("amount", -1)) == 5, "AC-024-02 Ember Bottle amount changes by id")
		_check(int((_entity_by_id(candidate_relics.get("relics", []), "ash_rosary").get("effects", [{}]) as Array)[0].get("amount", -1)) == 3, "AC-024-02 Ash Rosary amount changes by id")
		_check(JSON.stringify(_entity_by_id(candidate_player.get("characters", []), "other_character")) == other_character_snapshot, "AC-024-02 overlay preserves other characters")
		_check(JSON.stringify(_entity_by_id(candidate_relics.get("relics", []), "other_relic")) == other_relic_snapshot, "AC-024-02 overlay preserves other relics")

	var missing_datasets := _selector_datasets()
	(missing_datasets["player"]["characters"] as Array).remove_at(1)
	var missing_path := _write_payload("selector-missing", _payload("selector-missing", changes[0]))
	var missing_result: Dictionary = helper.load_and_apply(missing_path, missing_datasets)
	_check(not bool(missing_result.get("ok", true)), "AC-024-02 missing id fails closed")
	_check(missing_result.get("errors", []) == ["selector_not_found"], "AC-024-02 missing id returns selector_not_found")
	_check((missing_result.get("datasets", {}) as Dictionary).is_empty(), "AC-024-02 missing id returns no candidate datasets")

	var ambiguous_datasets := _selector_datasets()
	(ambiguous_datasets["relics"]["relics"] as Array).append(_entity_by_id(ambiguous_datasets["relics"]["relics"], "ash_rosary").duplicate(true))
	var ambiguous_path := _write_payload("selector-ambiguous", _payload("selector-ambiguous", changes[5]))
	var ambiguous_result: Dictionary = helper.load_and_apply(ambiguous_path, ambiguous_datasets)
	_check(not bool(ambiguous_result.get("ok", true)), "AC-024-02 duplicate id fails closed")
	_check(ambiguous_result.get("errors", []) == ["selector_ambiguous"], "AC-024-02 duplicate id returns selector_ambiguous")
	_check((ambiguous_result.get("datasets", {}) as Dictionary).is_empty(), "AC-024-02 duplicate id returns no candidate datasets")

func _payload(candidate_id: String, change: Dictionary) -> Dictionary:
	return {"schema_version": 1, "candidate_id": candidate_id, "changes": [change]}

func _datasets() -> Dictionary:
	return {
		"map_generation": {},
		"level_tree": {},
		"economy": {},
		"player": {"characters": []},
		"relics": {"relics": []},
	}

func _selector_datasets() -> Dictionary:
	return {
		"map_generation": {"chapter_one": {"marker": "map-original"}},
		"level_tree": {"route_constraints": {"max_pressure_nodes_between_campfires": 4}},
		"economy": {"campfire": {"heal_percent_of_max_hp": 25}},
		"player": {
			"characters": [
				{"id": "ember_exile", "starting_momentum": 0, "starter_deck_ids": ["ember-old"]},
				{"id": "arc_tinker", "starting_momentum": 1, "starter_deck_ids": ["arc-old"]},
				{"id": "pyre_ascetic", "starting_momentum": 0, "starter_deck_ids": ["pyre-old"]},
				{"id": "other_character", "starting_momentum": 4, "starter_deck_ids": ["other-old"], "marker": {"nested": true}},
			]
		},
		"relics": {
			"relics": [
				{"id": "ember_bottle", "effects": [{"trigger": "combat_start", "type": "gain_block", "amount": 3}]},
				{"id": "ash_rosary", "effects": [{"trigger": "combat_start", "type": "gain_block", "amount": 1}]},
				{"id": "other_relic", "effects": [{"trigger": "setup", "type": "marker", "amount": 9}], "marker": {"nested": true}},
			]
		},
	}

func _entity_by_id(collection_value, entity_id: String) -> Dictionary:
	if collection_value is not Array:
		return {}
	for entity_value in collection_value:
		if entity_value is Dictionary and str((entity_value as Dictionary).get("id", "")) == entity_id:
			return entity_value
	return {}

func _write_payload(name: String, payload: Dictionary) -> String:
	var path := "/tmp/ember024-ac01-%s.json" % name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "AC-024-01 fixture can be written: %s" % name)
		return path
	file.store_string(JSON.stringify(payload))
	file.close()
	return path

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
