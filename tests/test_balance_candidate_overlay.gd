extends SceneTree

const HELPER_PATH := "res://scripts/tools/BalanceCandidateOverlay.gd"
const SIMULATOR_PATH := "res://scripts/tools/BalanceSimulator.gd"
const CLI_PATH := "res://tools/run_balance_simulation.gd"
const VALID_FIXTURE_PATH := "res://tests/fixtures/balance_candidates/valid-minimal.json"
const FORBIDDEN_FIXTURE_PATH := "res://tests/fixtures/balance_candidates/invalid-forbidden.json"

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_valid_overlay_metadata_and_copy()
	_test_invalid_overlays_fail_closed()
	_test_simulator_overlay_lifecycle()
	_test_cli_contract()
	_test_attrition_contract()
	if failed:
		quit(1)
		return
	print("Balance candidate overlay tests passed.")
	quit(0)

func _test_valid_overlay_metadata_and_copy() -> void:
	if not ResourceLoader.exists(HELPER_PATH):
		_check(false, "AC-023-01 overlay helper exists at the planned calculation-layer path")
		return
	var helper_script = load(HELPER_PATH)
	_check(helper_script != null, "AC-023-01 overlay helper loads")
	if helper_script == null:
		return
	var helper = helper_script.new()
	_check(helper.has_method("load_and_apply"), "AC-023-01 overlay helper exposes load_and_apply")
	if not helper.has_method("load_and_apply"):
		return

	var datasets := {
		"map_generation": {"chapter_one": {"marker": "map-original"}},
		"level_tree": {"route_constraints": {"max_pressure_nodes_between_campfires": 4}},
		"economy": {
			"campfire": {"heal_percent_of_max_hp": 25},
			"marker": "economy-original"
		}
	}
	var input_snapshot := JSON.stringify(datasets)
	var result: Dictionary = helper.call("load_and_apply", VALID_FIXTURE_PATH, datasets)
	_check(bool(result.get("ok", false)), "AC-023-01 valid overlay is accepted")
	_check((result.get("errors", []) as Array).is_empty(), "AC-023-01 valid overlay has no errors")

	var metadata: Dictionary = result.get("metadata", {})
	var metadata_keys: Array = metadata.keys()
	metadata_keys.sort()
	_check(metadata_keys == ["applied_fields", "candidate_id", "schema_version", "sha256"], "AC-023-01 metadata contains only the frozen identity fields")
	_check(int(metadata.get("schema_version", 0)) == 1, "AC-023-01 metadata keeps schema version one")
	_check(str(metadata.get("candidate_id", "")) == "valid-minimal", "AC-023-01 metadata keeps candidate id")
	_check(str(metadata.get("sha256", "")) == _sha256_file(VALID_FIXTURE_PATH), "AC-023-01 metadata SHA matches exact fixture bytes")
	_check(metadata.get("applied_fields", []) == ["economy.campfire.heal_percent_of_max_hp"], "AC-023-01 applied fields use sorted dataset-qualified paths")

	var output_datasets: Dictionary = result.get("datasets", {})
	_check(output_datasets.keys().size() == 3, "AC-023-01 output contains exactly the three allowed datasets")
	_check(int(output_datasets.get("economy", {}).get("campfire", {}).get("heal_percent_of_max_hp", 0)) == 30, "AC-023-01 valid value is applied to the copied economy dataset")
	_check(JSON.stringify(datasets) == input_snapshot, "AC-023-01 input datasets remain byte-equivalent after apply")
	var output_economy: Dictionary = output_datasets.get("economy", {})
	var output_campfire: Dictionary = output_economy.get("campfire", {})
	output_campfire["heal_percent_of_max_hp"] = 45
	_check(int(datasets.get("economy", {}).get("campfire", {}).get("heal_percent_of_max_hp", 0)) == 25, "AC-023-01 output mutations cannot reach input dictionaries")

func _test_invalid_overlays_fail_closed() -> void:
	var helper_script = load(HELPER_PATH)
	if helper_script == null:
		_check(false, "AC-023-02 overlay helper loads")
		return
	var invalid_cases := [
		{
			"name": "missing",
			"path": "/tmp/ember023-overlay-missing.json",
			"error": "overlay_file_missing"
		},
		{
			"name": "json",
			"path": _write_text_fixture("json", "{not-json"),
			"error": "overlay_json_invalid"
		},
		{
			"name": "schema",
			"path": _write_json_fixture("schema", {"schema_version": 2, "candidate_id": "schema", "changes": [_heal_change(30)]}),
			"error": "schema_version_unsupported"
		},
		{
			"name": "candidate-id",
			"path": _write_json_fixture("candidate-id", {"schema_version": 1, "candidate_id": "bad id", "changes": [_heal_change(30)]}),
			"error": "candidate_id_invalid"
		},
		{
			"name": "changes-empty",
			"path": _write_json_fixture("changes-empty", {"schema_version": 1, "candidate_id": "changes-empty", "changes": []}),
			"error": "changes_empty"
		},
		{
			"name": "dataset",
			"path": FORBIDDEN_FIXTURE_PATH,
			"error": "dataset_forbidden"
		},
		{
			"name": "path",
			"path": _write_json_fixture("path", {"schema_version": 1, "candidate_id": "path", "changes": [{"dataset": "economy", "path": ["reward_generation", "combat_card_accept_score"], "value": 1}]}),
			"error": "path_forbidden"
		},
		{
			"name": "duplicate",
			"path": _write_json_fixture("duplicate", {"schema_version": 1, "candidate_id": "duplicate", "changes": [_heal_change(30), _heal_change(31)]}),
			"error": "path_duplicate"
		},
		{
			"name": "value",
			"path": _write_json_fixture("value", {"schema_version": 1, "candidate_id": "value", "changes": [_heal_change(101)]}),
			"error": "value_invalid"
		},
		{
			"name": "value-near-integer",
			"path": _write_json_fixture("value-near-integer", {"schema_version": 1, "candidate_id": "value-near-integer", "changes": [{"dataset": "economy", "path": ["campfire", "heal_percent_of_max_hp"], "value": 30.0000001}]}),
			"error": "value_invalid"
		},
		{
			"name": "value-layer-bands",
			"path": _write_json_fixture("value-layer-bands", {"schema_version": 1, "candidate_id": "value-layer-bands", "changes": [{"dataset": "map_generation", "path": ["chapter_one", "encounter_layer_bands"], "value": {"combat": [{"layers": [0, 2], "encounter_ids": ["intro_patrol"]}, {"layers": [2, 3], "encounter_ids": ["polluted_lab"]}]}}]}),
			"error": "value_invalid"
		},
		{
			"name": "value-pressure",
			"path": _write_json_fixture("value-pressure", {"schema_version": 1, "candidate_id": "value-pressure", "changes": [{"dataset": "level_tree", "path": ["route_constraints", "max_pressure_nodes_between_campfires"], "value": 0}]}),
			"error": "value_invalid"
		},
		{
			"name": "value-campfire",
			"path": _write_json_fixture("value-campfire", {"schema_version": 1, "candidate_id": "value-campfire", "changes": [{"dataset": "level_tree", "path": ["chapters", "chapter_one", "node_budget", "campfire"], "value": [2, 1]}]}),
			"error": "value_invalid"
		},
		{
			"name": "value-rarity",
			"path": _write_json_fixture("value-rarity", {"schema_version": 1, "candidate_id": "value-rarity", "changes": [{"dataset": "economy", "path": ["reward_generation", "card_rarity_weights"], "value": {"common": 60, "uncommon": 30, "rare": 9}}]}),
			"error": "value_invalid"
		},
		{
			"name": "unknown-top-level-field",
			"path": _write_json_fixture("unknown-top-level-field", {"schema_version": 1, "candidate_id": "unknown-top-level-field", "changes": [_heal_change(30)], "unexpected": true}),
			"error": "value_invalid"
		},
		{
			"name": "unknown-change-field",
			"path": _write_json_fixture("unknown-change-field", {"schema_version": 1, "candidate_id": "unknown-change-field", "changes": [{"dataset": "economy", "path": ["campfire", "heal_percent_of_max_hp"], "value": 30, "unexpected": true}]}),
			"error": "value_invalid"
		}
	]
	if FileAccess.file_exists("/tmp/ember023-overlay-missing.json"):
		DirAccess.remove_absolute("/tmp/ember023-overlay-missing.json")
	for case_value in invalid_cases:
		var invalid_case: Dictionary = case_value
		var datasets := _datasets_fixture()
		var input_snapshot := JSON.stringify(datasets)
		var helper = helper_script.new()
		var result: Dictionary = helper.call("load_and_apply", str(invalid_case.get("path", "")), datasets)
		var context := "AC-023-02 %s" % str(invalid_case.get("name", ""))
		_check(not bool(result.get("ok", true)), "%s fails closed" % context)
		_check(result.get("errors", []) == [invalid_case.get("error", "")], "%s returns only its fixed error code" % context)
		_check((result.get("metadata", {}) as Dictionary).is_empty(), "%s exposes no candidate metadata" % context)
		_check((result.get("datasets", {}) as Dictionary).is_empty(), "%s returns zero candidate datasets" % context)
		_check(JSON.stringify(datasets) == input_snapshot, "%s cannot mutate caller datasets" % context)

func _datasets_fixture() -> Dictionary:
	return {
		"map_generation": {"chapter_one": {"marker": "map-original"}},
		"level_tree": {"route_constraints": {"max_pressure_nodes_between_campfires": 4}},
		"economy": {"campfire": {"heal_percent_of_max_hp": 25}}
	}

func _heal_change(value: int) -> Dictionary:
	return {"dataset": "economy", "path": ["campfire", "heal_percent_of_max_hp"], "value": value}

func _write_json_fixture(name: String, payload: Dictionary) -> String:
	return _write_text_fixture(name, JSON.stringify(payload))

func _write_text_fixture(name: String, text: String) -> String:
	var path := "/tmp/ember023-overlay-%s.json" % name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "test fixture can be written: %s" % name)
		return path
	file.store_string(text)
	file.close()
	return path

func _test_simulator_overlay_lifecycle() -> void:
	var simulator_script = load(SIMULATOR_PATH)
	_check(simulator_script != null, "AC-023-03 BalanceSimulator loads")
	if simulator_script == null:
		return
	var simulator = simulator_script.new()
	simulator.load_default_data()
	var data_snapshots := {
		"map_generation": JSON.stringify(simulator.map_generation_data),
		"level_tree": JSON.stringify(simulator.level_tree_data),
		"economy": JSON.stringify(simulator.economy_data)
	}
	var file_hashes := {
		"map_generation": _sha256_file("res://data/config/map_generation.json"),
		"level_tree": _sha256_file("res://data/config/level_tree.json"),
		"economy": _sha256_file("res://data/config/economy.json")
	}
	var default_options := {
		"iterations": 1,
		"max_turns": 20,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v3"
	}
	var candidate_options: Dictionary = default_options.duplicate(true)
	candidate_options["candidate_overlay_path"] = VALID_FIXTURE_PATH
	var candidate_report: Dictionary = simulator.run_campaign_suite(candidate_options)
	var candidate_metadata: Dictionary = candidate_report.get("candidate_overlay", {})
	_check(str(candidate_metadata.get("candidate_id", "")) == "valid-minimal", "AC-023-03 candidate report records overlay identity")
	_check(str(candidate_metadata.get("sha256", "")).length() == 64, "AC-023-03 candidate report records overlay SHA")
	_check(candidate_metadata.get("applied_fields", []) == ["economy.campfire.heal_percent_of_max_hp"], "AC-023-03 candidate report records applied fields")

	var same_instance_default: Dictionary = simulator.run_campaign_suite(default_options)
	var fresh_simulator = simulator_script.new()
	var fresh_default: Dictionary = fresh_simulator.run_campaign_suite(default_options)
	_check(JSON.stringify(same_instance_default) == JSON.stringify(fresh_default), "AC-023-03 overlay context is restored before same-instance default run")
	_check(not same_instance_default.has("candidate_overlay"), "AC-023-03 default report has no candidate metadata")
	_check(not same_instance_default.has("candidate_diagnostics"), "AC-023-03 default report has no diagnostics field")
	_check(JSON.stringify(simulator.map_generation_data) == data_snapshots["map_generation"], "AC-023-03 map data reference is restored")
	_check(JSON.stringify(simulator.level_tree_data) == data_snapshots["level_tree"], "AC-023-03 level tree data reference is restored")
	_check(JSON.stringify(simulator.economy_data) == data_snapshots["economy"], "AC-023-03 economy data reference is restored")
	_check(_sha256_file("res://data/config/map_generation.json") == file_hashes["map_generation"], "AC-023-03 map production bytes remain unchanged")
	_check(_sha256_file("res://data/config/level_tree.json") == file_hashes["level_tree"], "AC-023-03 level tree production bytes remain unchanged")
	_check(_sha256_file("res://data/config/economy.json") == file_hashes["economy"], "AC-023-03 economy production bytes remain unchanged")

func _test_cli_contract() -> void:
	var cli_script = load(CLI_PATH)
	_check(cli_script != null, "AC-023-04 balance CLI loads")
	if cli_script == null:
		return
	var parsed: Dictionary = cli_script.parse_options_for_args([
		"--mode=campaign",
		"--candidate-overlay=%s" % VALID_FIXTURE_PATH,
		"--candidate-diagnostics=attrition-v1",
		"--strategy-profile=unknown-profile",
		"--iterations=1",
		"--max-turns=1",
		"--characters=ember_exile",
		"--challenges=0"
	])
	_check(str(parsed.get("candidate_overlay_path", "")) == VALID_FIXTURE_PATH, "AC-023-04 CLI maps candidate overlay to the API option")
	_check(str(parsed.get("candidate_diagnostics", "")) == "attrition-v1", "AC-023-04 CLI maps candidate diagnostics to the API option")
	var historical: Dictionary = cli_script.parse_options_for_args(["--mode=single", "--iterations=1"])
	_check(not historical.has("candidate_overlay_path") and not historical.has("candidate_diagnostics"), "AC-023-04 omitted candidate flags preserve the historical option shape")

	var simulator_script = load(SIMULATOR_PATH)
	_check(simulator_script != null, "AC-023-04 simulator loads for compatibility checks")
	if simulator_script == null:
		return
	var simulator = simulator_script.new()
	var campaign_options := {
		"iterations": 1,
		"max_turns": 1,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "unknown-profile"
	}
	var fallback_report: Dictionary = simulator.run_campaign_suite(campaign_options)
	_check(str(fallback_report.get("strategy_profile", "")) == "current-greedy" and bool(fallback_report.get("strategy_profile_fallback", false)), "AC-023-04 unknown strategy keeps explicit current-greedy fallback")
	var single_options := {
		"iterations": 1,
		"max_turns": 1,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"encounter_ids": ["intro_patrol"]
	}
	var single_baseline: Dictionary = simulator.run_suite(single_options)
	var single_candidate_options: Dictionary = single_options.duplicate(true)
	single_candidate_options["candidate_overlay_path"] = VALID_FIXTURE_PATH
	single_candidate_options["candidate_diagnostics"] = "attrition-v1"
	var single_candidate: Dictionary = simulator.run_suite(single_candidate_options)
	_check(JSON.stringify(single_candidate) == JSON.stringify(single_baseline), "AC-023-04 single mode preserves its historical report when candidate flags are present")

	var output_path := "/tmp/ember023-ac04-rejected-report.json"
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)
	var child_arguments := PackedStringArray([
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--script",
		CLI_PATH,
		"--",
		"--mode=campaign",
		"--candidate-overlay=%s" % FORBIDDEN_FIXTURE_PATH,
		"--iterations=1",
		"--max-turns=1",
		"--characters=ember_exile",
		"--challenges=0",
		"--output=%s" % output_path
	])
	var child_output: Array = []
	var exit_code: int = OS.execute(OS.get_executable_path(), child_arguments, child_output, true)
	_check(exit_code == 1, "AC-023-04 invalid overlay CLI exits with status one")
	_check(not FileAccess.file_exists(output_path), "AC-023-04 rejected CLI run does not save a successful report")

func _test_attrition_contract() -> void:
	var simulator_script = load(SIMULATOR_PATH)
	_check(simulator_script != null, "AC-023-05 simulator loads for attrition aggregation")
	if simulator_script == null:
		return
	var simulator = simulator_script.new()
	simulator.load_default_data()
	var character: Dictionary = simulator._character_config("ember_exile")
	var challenge: Dictionary = simulator._challenge_config(0)
	var run_a := {
		"won": true,
		"path": [
			{"chapter_id": "chapter_one", "node_id": "event_a", "node_type": "event", "encounter_id": "", "completed": true, "hp": 70},
			{"chapter_id": "chapter_one", "node_id": "zeta_a", "node_type": "combat", "encounter_id": "zeta", "completed": true, "hp": 60},
			{"chapter_id": "chapter_one", "node_id": "alpha_a", "node_type": "elite", "encounter_id": "alpha", "completed": false, "hp": 0}
		],
		"attrition_events": [
			{"chapter_id": "chapter_one", "layer": 2, "node_type": "combat", "encounter_id": "zeta", "hp_before": 70, "hp_after": 60, "hp_lost": 10, "completed": true},
			{"chapter_id": "chapter_one", "layer": 3, "node_type": "elite", "encounter_id": "alpha", "hp_before": 60, "hp_after": 0, "hp_lost": 60, "completed": false}
		]
	}
	var run_b := {
		"won": false,
		"path": [
			{"chapter_id": "chapter_one", "node_id": "zeta_b", "node_type": "combat", "encounter_id": "zeta", "completed": true, "hp": 64}
		],
		"attrition_events": [
			{"chapter_id": "chapter_one", "layer": 2, "node_type": "combat", "encounter_id": "zeta", "hp_before": 70, "hp_after": 64, "hp_lost": 6, "completed": true}
		]
	}
	var run_timeout := {
		"won": false,
		"path": [
			{"chapter_id": "chapter_one", "node_id": "timeout_c", "node_type": "combat", "encounter_id": "timeout", "completed": false, "hp": 54}
		],
		"attrition_events": [
			{"chapter_id": "chapter_one", "layer": 4, "node_type": "combat", "encounter_id": "timeout", "hp_before": 64, "hp_after": 54, "hp_lost": 10, "completed": false}
		]
	}
	var runs: Array = [run_a, run_b, run_timeout]
	_check(simulator.has_method("_aggregate_campaign_attrition"), "AC-023-05 simulator exposes the planned adjacent attrition aggregation helper")
	if not simulator.has_method("_aggregate_campaign_attrition"):
		return
	var attrition: Dictionary = simulator.call("_aggregate_campaign_attrition", runs)
	var by_layer: Array = attrition.get("attrition_by_layer", [])
	var expected_layers := [
		{"chapter_id": "chapter_one", "layer": 2, "visits": 2, "combat_visits": 2, "combat_wins": 2, "combat_deaths": 0, "hp_lost_total": 16, "avg_hp_lost": 8.0, "avg_hp_before": 70.0, "avg_hp_after": 62.0},
		{"chapter_id": "chapter_one", "layer": 3, "visits": 1, "combat_visits": 1, "combat_wins": 0, "combat_deaths": 1, "hp_lost_total": 60, "avg_hp_lost": 60.0, "avg_hp_before": 60.0, "avg_hp_after": 0.0},
		{"chapter_id": "chapter_one", "layer": 4, "visits": 1, "combat_visits": 1, "combat_wins": 0, "combat_deaths": 0, "hp_lost_total": 10, "avg_hp_lost": 10.0, "avg_hp_before": 64.0, "avg_hp_after": 54.0}
	]
	_check(by_layer == expected_layers, "AC-023-05 attrition by layer keeps raw counts, three-decimal means, and layer ordering")
	var by_encounter: Array = attrition.get("attrition_by_encounter", [])
	var expected_encounters := [
		{"encounter_id": "alpha", "visits": 1, "wins": 0, "deaths": 1, "hp_lost_total": 60, "avg_hp_lost": 60.0, "avg_hp_before": 60.0, "avg_hp_after": 0.0},
		{"encounter_id": "timeout", "visits": 1, "wins": 0, "deaths": 0, "hp_lost_total": 10, "avg_hp_lost": 10.0, "avg_hp_before": 64.0, "avg_hp_after": 54.0},
		{"encounter_id": "zeta", "visits": 2, "wins": 2, "deaths": 0, "hp_lost_total": 16, "avg_hp_lost": 8.0, "avg_hp_before": 70.0, "avg_hp_after": 62.0}
	]
	_check(by_encounter == expected_encounters, "AC-023-05 attrition by encounter keeps raw counts, three-decimal means, and encounter ordering")
	var default_case: Dictionary = simulator._aggregate_campaign_case(character, challenge, [run_a, run_b])
	_check(not default_case.has("attrition_by_layer") and not default_case.has("attrition_by_encounter"), "AC-023-05 default aggregation does not add attrition fields")

	var runtime_options := {
		"iterations": 1,
		"max_turns": 1,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v3"
	}
	var runtime_attrition_options: Dictionary = runtime_options.duplicate(true)
	runtime_attrition_options["candidate_diagnostics"] = "attrition-v1"
	var runtime_report: Dictionary = simulator.run_campaign_suite(runtime_attrition_options)
	_check(str(runtime_report.get("candidate_diagnostics", "")) == "attrition-v1", "AC-023-05 attrition report records its opt-in diagnostics identity")
	var runtime_cases: Array = runtime_report.get("cases", [])
	_check(runtime_cases.size() == 1, "AC-023-05 attrition runtime keeps the requested case axis")
	if runtime_cases.size() == 1:
		var runtime_case: Dictionary = runtime_cases[0]
		var runtime_layers: Array = runtime_case.get("attrition_by_layer", [])
		var runtime_encounters: Array = runtime_case.get("attrition_by_encounter", [])
		_check(str(runtime_case.get("candidate_diagnostics", "")) == "attrition-v1", "AC-023-05 attrition case records its diagnostics identity")
		_check(not runtime_layers.is_empty() and not runtime_encounters.is_empty(), "AC-023-05 runtime captures at least one combat attrition event")
		var runtime_deaths := 0
		for encounter_row_value in runtime_encounters:
			runtime_deaths += int((encounter_row_value as Dictionary).get("deaths", 0))
		_check(runtime_deaths == 0, "AC-023-05 positive-HP max-turn timeout is not counted as a death")
		var sample_runs: Array = runtime_case.get("sample_runs", [])
		var saw_combat_path := false
		for sample_value in sample_runs:
			var sample: Dictionary = sample_value
			for path_value in sample.get("path", []):
				var path_entry: Dictionary = path_value
				if str(path_entry.get("node_type", "")) not in ["combat", "elite", "boss"]:
					continue
				saw_combat_path = true
				_check(path_entry.has("layer") and path_entry.has("hp_before") and path_entry.has("hp_after") and path_entry.has("hp_lost"), "AC-023-05 attrition combat sample path includes layer and HP snapshots")
				_check(int(path_entry.get("hp_lost", -1)) == max(0, int(path_entry.get("hp_before", 0)) - int(path_entry.get("hp_after", 0))), "AC-023-05 sample hp_lost follows the frozen non-negative formula")
		_check(saw_combat_path, "AC-023-05 attrition sample contains a combat path entry")

	var runtime_default: Dictionary = simulator.run_campaign_suite(runtime_options)
	var unknown_options: Dictionary = runtime_options.duplicate(true)
	unknown_options["candidate_diagnostics"] = "unknown-diagnostics"
	var runtime_unknown: Dictionary = simulator.run_campaign_suite(unknown_options)
	_check(JSON.stringify(runtime_unknown) == JSON.stringify(runtime_default), "AC-023-05 unknown candidate diagnostics preserve the default report")
	_check(not runtime_default.has("candidate_diagnostics"), "AC-023-05 default report has no candidate diagnostics identity")
	var default_cases: Array = runtime_default.get("cases", [])
	if default_cases.size() == 1:
		var runtime_default_case: Dictionary = default_cases[0]
		_check(not runtime_default_case.has("candidate_diagnostics") and not runtime_default_case.has("attrition_by_layer") and not runtime_default_case.has("attrition_by_encounter"), "AC-023-05 default runtime case has no attrition fields")
		for sample_value in runtime_default_case.get("sample_runs", []):
			for path_value in (sample_value as Dictionary).get("path", []):
				var path_entry: Dictionary = path_value
				_check(not path_entry.has("layer") and not path_entry.has("hp_before") and not path_entry.has("hp_after") and not path_entry.has("hp_lost"), "AC-023-05 default sample path keeps the historical field set")

func _sha256_file(path: String) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
