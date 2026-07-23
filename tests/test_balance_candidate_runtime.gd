extends SceneTree

const SIMULATOR_PATH := "res://scripts/tools/BalanceSimulator.gd"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_ac_024_03_five_dataset_lifecycle()
	if not _failures.is_empty():
		push_error("Balance candidate runtime test failed with %d assertion(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Balance candidate runtime test passed.")
	quit(0)

func _test_ac_024_03_five_dataset_lifecycle() -> void:
	var simulator_script = load(SIMULATOR_PATH)
	_check(simulator_script != null, "AC-024-03 simulator loads")
	if simulator_script == null:
		return
	var simulator = simulator_script.new()
	simulator.load_default_data()
	var original_snapshots := _five_dataset_snapshots(simulator)
	var valid_path := _write_json("valid", _valid_payload())

	var context: Dictionary = simulator._apply_candidate_overlay({"candidate_overlay_path": valid_path})
	_check(bool(context.get("ok", false)) and bool(context.get("applied", false)), "AC-024-03 direct apply accepts five-dataset overlay")
	if bool(context.get("ok", false)):
		_check(simulator.map_generation_data.get("chapter_one", {}).has("encounter_layer_bands"), "AC-024-03 map dataset is assigned")
		_check(int(simulator.level_tree_data.get("route_constraints", {}).get("max_pressure_nodes_between_campfires", 0)) == 3, "AC-024-03 level tree dataset is assigned")
		_check(int(simulator.economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 0)) == 30, "AC-024-03 economy dataset is assigned")
		_check(int(_entity_by_id(simulator.player_data.get("characters", []), "arc_tinker").get("starting_momentum", -1)) == 0, "AC-024-03 player dataset is assigned")
		_check(int((_entity_by_id(simulator.relic_data.get("relics", []), "ash_rosary").get("effects", [{}]) as Array)[0].get("amount", -1)) == 3, "AC-024-03 relic dataset is assigned")
		simulator._restore_candidate_overlay(context)
	_check(_five_dataset_snapshots(simulator) == original_snapshots, "AC-024-03 direct restore returns all five datasets exactly")

	var options := {
		"iterations": 1,
		"max_turns": 1,
		"character_ids": ["arc_tinker"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v3",
	}
	var candidate_options: Dictionary = options.duplicate(true)
	candidate_options["candidate_overlay_path"] = valid_path
	var candidate_report: Dictionary = simulator.run_campaign_suite(candidate_options)
	var metadata: Dictionary = candidate_report.get("candidate_overlay", {})
	var expected_fields := [
		"economy.campfire.heal_percent_of_max_hp",
		"level_tree.route_constraints.max_pressure_nodes_between_campfires",
		"map_generation.chapter_one.encounter_layer_bands",
		"player.characters.arc_tinker.starter_deck_ids",
		"player.characters.arc_tinker.starting_momentum",
		"relics.relics.ash_rosary.effects.0.amount",
	]
	_check(str(metadata.get("candidate_id", "")) == "runtime-five-datasets", "AC-024-03 report exposes candidate identity")
	_check(metadata.get("applied_fields", []) == expected_fields, "AC-024-03 report exposes sorted applied fields")
	_check(_five_dataset_snapshots(simulator) == original_snapshots, "AC-024-03 campaign return restores all five datasets")

	var same_instance_default: Dictionary = simulator.run_campaign_suite(options)
	var fresh_simulator = simulator_script.new()
	var fresh_default: Dictionary = fresh_simulator.run_campaign_suite(options)
	_check(JSON.stringify(same_instance_default) == JSON.stringify(fresh_default), "AC-024-03 overlay then default is byte-identical to a fresh default")
	_check(not same_instance_default.has("candidate_overlay"), "AC-024-03 default report has no candidate metadata")

	var rejected_path := _write_json("rejected", {
		"schema_version": 1,
		"candidate_id": "runtime-rejected",
		"changes": [{"dataset": "player", "path": ["characters", "arc_tinker", "max_hp"], "value": 1}],
	})
	var rejected_options: Dictionary = options.duplicate(true)
	rejected_options["candidate_overlay_path"] = rejected_path
	var rejected_report: Dictionary = simulator.run_campaign_suite(rejected_options)
	_check(bool(rejected_report.get("candidate_overlay_rejected", false)), "AC-024-03 invalid overlay returns rejection report")
	_check(rejected_report.get("candidate_overlay_errors", []) == ["path_forbidden"], "AC-024-03 invalid player path keeps its fixed error")
	_check(_five_dataset_snapshots(simulator) == original_snapshots, "AC-024-03 rejected overlay cannot change any dataset")
	var after_rejection_default: Dictionary = simulator.run_campaign_suite(options)
	_check(JSON.stringify(after_rejection_default) == JSON.stringify(fresh_default), "AC-024-03 rejection then default is byte-identical to a fresh default")

func _valid_payload() -> Dictionary:
	return {
		"schema_version": 1,
		"candidate_id": "runtime-five-datasets",
		"changes": [
			{
				"dataset": "map_generation",
				"path": ["chapter_one", "encounter_layer_bands"],
				"value": {"combat": [
					{"layers": [0, 0], "encounter_ids": ["intro_patrol"]},
					{"layers": [1, 2], "encounter_ids": ["intro_patrol", "polluted_lab", "cinder_kennels"]},
					{"layers": [3, 6], "encounter_ids": ["polluted_lab", "iron_checkpoint", "cinder_kennels"]},
				]},
			},
			{"dataset": "level_tree", "path": ["route_constraints", "max_pressure_nodes_between_campfires"], "value": 3},
			{"dataset": "economy", "path": ["campfire", "heal_percent_of_max_hp"], "value": 30},
			{"dataset": "player", "path": ["characters", "arc_tinker", "starting_momentum"], "value": 0},
			{"dataset": "player", "path": ["characters", "arc_tinker", "starter_deck_ids"], "value": ["spark_throw", "spark_throw", "relay_strike", "pressure_probe", "pressure_probe", "soot_step", "soot_step", "ash_guard", "ash_guard", "static_primer"]},
			{"dataset": "relics", "path": ["relics", "ash_rosary", "effects", "0", "amount"], "value": 3},
		],
	}

func _five_dataset_snapshots(simulator) -> Dictionary:
	return {
		"map_generation": JSON.stringify(simulator.map_generation_data),
		"level_tree": JSON.stringify(simulator.level_tree_data),
		"economy": JSON.stringify(simulator.economy_data),
		"player": JSON.stringify(simulator.player_data),
		"relics": JSON.stringify(simulator.relic_data),
	}

func _entity_by_id(collection_value, entity_id: String) -> Dictionary:
	if collection_value is not Array:
		return {}
	for entity_value in collection_value:
		if entity_value is Dictionary and str((entity_value as Dictionary).get("id", "")) == entity_id:
			return entity_value
	return {}

func _write_json(name: String, payload: Dictionary) -> String:
	var path := "/tmp/ember024-runtime-%s.json" % name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "AC-024-03 fixture can be written: %s" % name)
		return path
	file.store_string(JSON.stringify(payload))
	file.close()
	return path

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
