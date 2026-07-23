extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const OverlayScript = preload("res://scripts/tools/BalanceCandidateOverlay.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const FIXTURE_DIR := "res://tests/fixtures/balance_candidates/"
const LADDER_PATH := "res://tools/run_layered_pressure_ladder.gd"
const STEPS := ["P1", "P2", "P3", "P4", "P5"]
const SEED_COUNT := 32

var _failures: Array[String] = []

class ScriptedGate:
	extends RefCounted
	var direction_pass_steps: Array = []
	var hard_pass_steps: Array = []
	var hard_calls: Array = []

	func _init(direction_steps: Array, hard_steps: Array) -> void:
		direction_pass_steps = direction_steps.duplicate()
		hard_pass_steps = hard_steps.duplicate()

	func evaluate_direction(_baseline: Dictionary, candidate: Dictionary) -> Dictionary:
		var step := str(candidate.get("test_step", ""))
		var passed := direction_pass_steps.has(step)
		return {"eligible": true, "pass": passed, "failure_codes": [] if passed else ["direction_wins_regressed"]}

	func evaluate_hard(report: Dictionary, _expected_iterations: int) -> Dictionary:
		var step := str(report.get("test_step", ""))
		hard_calls.append(step)
		var passed := hard_pass_steps.has(step)
		return {"eligible": true, "pass": passed, "failure_codes": [] if passed else ["average_win_rate_outside_target"]}

class ScriptedLadderAdapter:
	extends RefCounted
	var report_failures: Dictionary = {}
	var save_failures: Dictionary = {}
	var repeat_mismatch_steps: Dictionary = {}
	var report_calls: Array = []

	func _validate_candidates() -> Dictionary:
		return {"ok": true, "errors": [], "candidate_order": STEPS.duplicate(), "graph_seed_count": 32}

	func _remove_if_exists(_path: String) -> void:
		pass

	func _run_report(step: String, iterations: int) -> Dictionary:
		var key := "%s:%d" % [step, iterations]
		report_calls.append(key)
		return {} if report_failures.has(key) else {"test_step": step, "iterations": iterations}

	func _baseline_sha256() -> String:
		return "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

	func _save_report(_report: Dictionary, path: String) -> Error:
		return ERR_CANT_CREATE if save_failures.has(path) else OK

	func _sha256_file(_path: String) -> String:
		return "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

	func _files_identical(first_path: String, _second_path: String) -> bool:
		for step in STEPS:
			if first_path.contains("-%s-" % step) and repeat_mismatch_steps.has(step):
				return false
		return true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_ladder_static_contract()
	var map_generation: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var level_tree: Dictionary = DataLoaderScript.load_json("res://data/config/level_tree.json")
	var economy: Dictionary = DataLoaderScript.load_json("res://data/config/economy.json")
	_test_production_pause_contract(map_generation, level_tree, economy)
	_check(_graph_digest(map_generation, level_tree) == "b61ca0a471c8797eae2d2c01efed49f8c29726042306f921d7da71520c6bae9a", "AC-023-08 no-overlay 32-seed graph digest remains frozen")
	var previous_changes: Array = []
	for step in STEPS:
		var fixture_path := "%s023-%s.json" % [FIXTURE_DIR, step]
		_check(FileAccess.file_exists(fixture_path), "AC-023-08 %s fixture exists" % step)
		if not FileAccess.file_exists(fixture_path):
			continue
		var payload: Dictionary = _read_json(fixture_path)
		var expected_changes: Array = _expected_changes(step)
		_check(int(payload.get("schema_version", 0)) == 1, "AC-023-08 %s uses schema version one" % step)
		_check(str(payload.get("candidate_id", "")) == "023-%s" % step, "AC-023-08 %s candidate id is exact" % step)
		_check(_canonical_json(payload.get("changes", [])) == _canonical_json(expected_changes), "AC-023-08 %s changes match the frozen exact values" % step)
		if not previous_changes.is_empty():
			_check(_canonical_json((payload.get("changes", []) as Array).slice(0, previous_changes.size())) == _canonical_json(previous_changes), "AC-023-08 %s preserves the previous changes as a strict prefix" % step)
		_check((payload.get("changes", []) as Array).size() > previous_changes.size(), "AC-023-08 %s adds exactly a later cumulative change set" % step)
		previous_changes = (payload.get("changes", []) as Array).duplicate(true)
		var applied := OverlayScript.new().load_and_apply(fixture_path, {"map_generation": map_generation, "level_tree": level_tree, "economy": economy})
		_check(bool(applied.get("ok", false)), "AC-023-08 %s overlay applies through the production validator" % step)
		if bool(applied.get("ok", false)):
			_validate_candidate_graphs(step, applied.get("datasets", {}))

	if _failures.is_empty():
		print("Layered pressure rebaseline fixture test passed.")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("Layered pressure rebaseline fixture test failed with %d assertion(s)." % _failures.size())
	quit(1)

func _test_ladder_static_contract() -> void:
	_check(ResourceLoader.exists(LADDER_PATH), "AC-023-09 layered pressure ladder exists")
	if not ResourceLoader.exists(LADDER_PATH):
		return
	var source := FileAccess.get_file_as_string(LADDER_PATH)
	_check(source.contains('const STEPS := ["P1", "P2", "P3", "P4", "P5"]'), "AC-023-09 ladder order is frozen to P1-P5")
	_check(source.contains('/tmp/ember023-%s-64.json'), "AC-023-09 every step uses an independent 64 report path")
	_check(source.contains("direction_allows_hard"), "AC-023-09 ladder has an explicit direction-to-hard decision")
	var runner_script = load(LADDER_PATH)
	var payload_validator := Callable(runner_script, "validate_candidate_payloads")
	_check(payload_validator.is_valid(), "AC-023-08 runner exposes executable exact candidate preflight")
	if payload_validator.is_valid():
		var payloads: Dictionary = {}
		for step in STEPS:
			payloads[step] = _read_json("%s023-%s.json" % [FIXTURE_DIR, step])
		_check(bool(payload_validator.call(payloads).get("ok", false)), "AC-023-08 runner accepts only the frozen P1-P5 payloads")
		var altered_payloads: Dictionary = payloads.duplicate(true)
		altered_payloads["P3"]["changes"].pop_back()
		_check(not bool(payload_validator.call(altered_payloads).get("ok", true)), "AC-023-08 runner rejects a valid overlay that changes the frozen P1-P5 ladder")
	var graph_validator := Callable(runner_script, "candidate_graph_is_valid")
	_check(graph_validator.is_valid(), "AC-023-08 runner exposes executable full-path graph preflight")
	var ladder_executor := Callable(runner_script, "run_ladder_with_adapter")
	_check(ladder_executor.is_valid(), "AC-023-09 runner exposes an executable orchestration seam")
	if ladder_executor.is_valid():
		_test_ladder_branches(ladder_executor)
	var direction_callable := Callable(runner_script, "direction_allows_hard")
	_check(direction_callable.is_valid(), "AC-023-09 direction decision is callable without constructing the runner")
	if direction_callable.is_valid():
		_check(not bool(direction_callable.call({"eligible": false, "pass": false, "failure_codes": ["direction_wins_regressed"]})), "AC-023-09 direction failure is fail-closed and cannot request hard samples")
	_check(source.contains("evaluate_hard"), "AC-023-10 ladder calls the shared hard gate")
	_check(source.contains("report_repeat_mismatch") and source.contains("repeat_128_path"), "AC-023-10 ladder compares primary and repeat 128 artifacts")
	_check(source.contains("selected_128_candidate") and source.contains("break"), "AC-023-10 ladder stops at the first hard pass")

func _test_ladder_branches(ladder_executor: Callable) -> void:
	var direction_fail_adapter := ScriptedLadderAdapter.new()
	var direction_fail_verdict: Dictionary = ladder_executor.call(direction_fail_adapter, ScriptedGate.new([], []))
	_check(bool(direction_fail_verdict.get("ok", false)) and str(direction_fail_verdict.get("status", "")) == "paused_no_layered_candidate_passed", "AC-023-09 all direction rejects are a normal paused verdict")
	_check(direction_fail_adapter.report_calls.has("P1:64") and not direction_fail_adapter.report_calls.has("P1:128"), "AC-023-09 a direction failure never requests 128 samples")

	var mismatch_adapter := ScriptedLadderAdapter.new()
	mismatch_adapter.repeat_mismatch_steps["P1"] = true
	var mismatch_gate := ScriptedGate.new(["P1"], [])
	var mismatch_verdict: Dictionary = ladder_executor.call(mismatch_adapter, mismatch_gate)
	_check(bool(mismatch_verdict.get("ok", false)) and str((mismatch_verdict.get("steps", []) as Array)[0].get("status", "")) == "rejected_repeat_mismatch", "AC-023-10 repeat mismatch is a candidate rejection")
	_check(mismatch_adapter.report_calls.count("P1:128") == 2 and not mismatch_gate.hard_calls.has("P1"), "AC-023-10 repeat mismatch never reaches the hard gate")

	var selected_adapter := ScriptedLadderAdapter.new()
	var selected_verdict: Dictionary = ladder_executor.call(selected_adapter, ScriptedGate.new(["P1", "P2"], ["P1"]))
	_check(str(selected_verdict.get("selected_step", "")) == "P1" and str(selected_verdict.get("status", "")) == "selected_128_candidate", "AC-023-10 first hard pass selects the current step")
	_check(not selected_adapter.report_calls.has("P2:64"), "AC-023-10 first hard pass stops before later candidates")

	var report_failure_adapter := ScriptedLadderAdapter.new()
	report_failure_adapter.report_failures["P1:64"] = true
	var report_failure: Dictionary = ladder_executor.call(report_failure_adapter, ScriptedGate.new([], []))
	_check(not bool(report_failure.get("ok", true)) and str(report_failure.get("status", "")) == "execution_failed", "AC-023-09 report generation failure is fatal")
	_check(not report_failure_adapter.report_calls.has("P2:64"), "AC-023-09 report generation failure stops the ladder")

	var save_failure_adapter := ScriptedLadderAdapter.new()
	save_failure_adapter.save_failures["/tmp/ember023-P1-64.json"] = true
	var save_failure: Dictionary = ladder_executor.call(save_failure_adapter, ScriptedGate.new([], []))
	_check(not bool(save_failure.get("ok", true)) and str(save_failure.get("status", "")) == "execution_failed", "AC-023-09 report save failure is fatal")
	_check(not save_failure_adapter.report_calls.has("P2:64"), "AC-023-09 report save failure stops the ladder")

	var hard_report_failure_adapter := ScriptedLadderAdapter.new()
	hard_report_failure_adapter.report_failures["P1:128"] = true
	var hard_report_failure: Dictionary = ladder_executor.call(hard_report_failure_adapter, ScriptedGate.new(["P1"], []))
	_check(not bool(hard_report_failure.get("ok", true)) and str(hard_report_failure.get("status", "")) == "execution_failed", "AC-023-10 primary 128 generation failure is fatal")

	var repeat_save_failure_adapter := ScriptedLadderAdapter.new()
	repeat_save_failure_adapter.save_failures["/tmp/ember023-P1-128-repeat.json"] = true
	var repeat_save_failure: Dictionary = ladder_executor.call(repeat_save_failure_adapter, ScriptedGate.new(["P1"], []))
	_check(not bool(repeat_save_failure.get("ok", true)) and str(repeat_save_failure.get("status", "")) == "execution_failed", "AC-023-10 repeat report save failure is fatal")

func _test_production_pause_contract(map_generation: Dictionary, level_tree: Dictionary, economy: Dictionary) -> void:
	var tree: Dictionary = DataLoaderScript.load_json("res://data/config/numerical_tree.json")
	var rebaseline: Dictionary = tree.get("campaign_rebaseline_023", {})
	_check(str(rebaseline.get("status", "")) == "paused_no_layered_candidate_passed", "AC-023-11 no selected candidate records the 023 paused status")
	_check(str(rebaseline.get("selected_step", "")).is_empty(), "AC-023-11 no selected candidate leaves selected_step empty")
	_check(rebaseline.get("candidate_order", []) == STEPS, "AC-023-11 records the complete P1-P5 candidate order")
	_check(str(rebaseline.get("verdict_path", "")) == "/tmp/ember023-layered-ladder-verdict.json", "AC-023-11 records the ladder verdict path")
	_check(str(rebaseline.get("verdict_sha256", "")).length() == 64, "AC-023-11 records the ladder verdict SHA")
	_check(rebaseline.get("production_applied", true) == false and rebaseline.get("playtest_package_eligible", true) == false, "AC-023-11 paused branch cannot apply production or unlock the package")
	var results: Array = rebaseline.get("candidate_results", [])
	_check(results.size() == STEPS.size(), "AC-023-11 paused branch records every candidate result")
	for result_value in results:
		var result: Dictionary = result_value
		_check(str(result.get("status", "")) == "rejected_hard_gate", "AC-023-11 every direction-eligible candidate records hard-gate rejection")
		_check(str(result.get("report_128_path", "")).ends_with("-128.json"), "AC-023-11 candidate records its primary 128 artifact")
		_check(str(result.get("repeat_128_path", "")).ends_with("-128-repeat.json"), "AC-023-11 candidate records its repeat 128 artifact")
		_check((result.get("failure_codes", []) as Array).has("average_win_rate_outside_target"), "AC-023-11 candidate records raw hard-gate failure codes")
	_check(not map_generation.get("chapter_one", {}).has("encounter_layer_bands"), "AC-023-11 paused branch leaves production map bands unchanged")
	_check(int(level_tree.get("route_constraints", {}).get("max_pressure_nodes_between_campfires", -1)) == 4, "AC-023-11 paused branch leaves pressure budget at the frozen baseline")
	for chapter_id in ["chapter_one", "chapter_two", "chapter_three"]:
		_check(_canonical_json(level_tree.get("chapters", {}).get(chapter_id, {}).get("node_budget", {}).get("campfire", [])) == [1, 2], "AC-023-11 paused branch leaves campfire budget unchanged: %s" % chapter_id)
	_check(int(economy.get("campfire", {}).get("heal_percent_of_max_hp", -1)) == 25, "AC-023-11 paused branch leaves campfire healing unchanged")
	_check(_canonical_json(economy.get("reward_generation", {}).get("card_rarity_weights", {})) == {"common": 65, "uncommon": 28, "rare": 7}, "AC-023-11 paused branch leaves rarity weights unchanged")
	var matrix: Dictionary = tree.get("campaign_matrix", {})
	_check(str(matrix.get("strategy_profile", "")) == "current-greedy" and int(matrix.get("iterations_per_cell", -1)) == 256 and str(matrix.get("seed_model", "")) == "paired_by_iteration", "AC-023-11 paused branch preserves the formal matrix identity")
	_check((matrix.get("rows", []) as Array).size() == 12, "AC-023-11 paused branch preserves all formal matrix rows")

func _expected_changes(step: String) -> Array:
	var changes: Array = [{
		"dataset": "map_generation",
		"path": ["chapter_one", "encounter_layer_bands"],
		"value": {"combat": [
			{"layers": [0, 0], "encounter_ids": ["intro_patrol"]},
			{"layers": [1, 2], "encounter_ids": ["intro_patrol", "polluted_lab", "cinder_kennels"]},
			{"layers": [3, 6], "encounter_ids": ["polluted_lab", "iron_checkpoint", "cinder_kennels"]}
		]}
	}]
	if step in ["P2", "P3", "P4", "P5"]:
		changes.append({"dataset": "level_tree", "path": ["route_constraints", "max_pressure_nodes_between_campfires"], "value": 3})
	if step in ["P3", "P4", "P5"]:
		for chapter_id in ["chapter_one", "chapter_two", "chapter_three"]:
			changes.append({"dataset": "level_tree", "path": ["chapters", chapter_id, "node_budget", "campfire"], "value": [2, 2]})
	if step in ["P4", "P5"]:
		changes.append({"dataset": "economy", "path": ["campfire", "heal_percent_of_max_hp"], "value": 30})
	if step == "P5":
		changes.append({"dataset": "economy", "path": ["reward_generation", "card_rarity_weights"], "value": {"common": 60, "uncommon": 30, "rare": 10}})
	return changes

func _validate_candidate_graphs(step: String, datasets: Dictionary) -> void:
	var map_generation: Dictionary = datasets.get("map_generation", {})
	var level_tree: Dictionary = datasets.get("level_tree", {})
	for chapter_id_value in map_generation.get("chapter_sequence", []):
		var chapter_id := str(chapter_id_value)
		var chapter: Dictionary = (map_generation.get(chapter_id, {}) as Dictionary).duplicate(true)
		chapter["level_tree_constraints"] = (level_tree.get("chapters", {}).get(chapter_id, {}) as Dictionary).duplicate(true)
		chapter["route_constraints"] = (level_tree.get("route_constraints", {}) as Dictionary).duplicate(true)
		for seed_index in range(SEED_COUNT):
			var seed_config: Dictionary = chapter.duplicate(true)
			seed_config["seed"] = int(chapter.get("seed", 1)) + seed_index * 7919
			var graph: Dictionary = MapGeneratorScript.generate(seed_config)
			var graph_validator := Callable(load(LADDER_PATH), "candidate_graph_is_valid")
			if graph_validator.is_valid():
				_check(bool(graph_validator.call(graph, seed_config)), "AC-023-08 runner enforces the same complete path budget: %s/%s/%d" % [step, chapter_id, seed_index])
				if step == "P1" and chapter_id == "chapter_one" and seed_index == 0:
					var broken_graph: Dictionary = graph.duplicate(true)
					var start_id := str(broken_graph.get("start_node_id", ""))
					var kept_edges: Array = []
					for edge_value in broken_graph.get("edges", []):
						if str((edge_value as Dictionary).get("from", "")) != start_id:
							kept_edges.append(edge_value)
					broken_graph["edges"] = kept_edges
					_check(not bool(graph_validator.call(broken_graph, seed_config)), "AC-023-08 runner rejects a graph with no complete start-to-boss path")
			_validate_graph(graph, seed_config, "%s/%s/%d" % [step, chapter_id, seed_index])

func _graph_digest(map_generation: Dictionary, level_tree: Dictionary) -> String:
	var graphs: Array = []
	for chapter_id_value in map_generation.get("chapter_sequence", []):
		var chapter_id := str(chapter_id_value)
		var chapter: Dictionary = (map_generation.get(chapter_id, {}) as Dictionary).duplicate(true)
		chapter["level_tree_constraints"] = (level_tree.get("chapters", {}).get(chapter_id, {}) as Dictionary).duplicate(true)
		chapter["route_constraints"] = (level_tree.get("route_constraints", {}) as Dictionary).duplicate(true)
		for seed_index in range(SEED_COUNT):
			var seed_config: Dictionary = chapter.duplicate(true)
			seed_config["seed"] = int(chapter.get("seed", 1)) + seed_index * 7919
			graphs.append(MapGeneratorScript.generate(seed_config))
	return JSON.stringify(graphs).sha256_text()

func _validate_graph(graph: Dictionary, config: Dictionary, context: String) -> void:
	var layers: Array = graph.get("layers", [])
	if config.has("encounter_layer_bands"):
		for layer_index in range(layers.size()):
			for node_value in layers[layer_index]:
				var node: Dictionary = node_value
				if str(node.get("type", "")) != "combat":
					continue
				var expected_pool: Array = []
				for band_value in config.get("encounter_layer_bands", {}).get("combat", []):
					var band: Dictionary = band_value
					var band_layers: Array = band.get("layers", [])
					if layer_index >= int(band_layers[0]) and layer_index <= int(band_layers[1]):
						expected_pool = band.get("encounter_ids", [])
				_check(expected_pool.has(str(node.get("encounter_id", ""))), "AC-023-08 %s layer %d uses its candidate encounter band" % [context, layer_index])
	var paths: Array = _complete_paths(graph)
	_check(not paths.is_empty(), "AC-023-08 %s has a complete path" % context)
	var constraints: Dictionary = config.get("level_tree_constraints", {})
	var route_constraints: Dictionary = config.get("route_constraints", {})
	var budgets: Dictionary = constraints.get("node_budget", {})
	var max_pressure: int = int(route_constraints.get("max_pressure_nodes_between_campfires", 0))
	var safe_window: int = int(constraints.get("boss_safe_window_layers", 2))
	var first_safe_layer: int = max(1, layers.size() - 1 - safe_window)
	var complete_nodes: Dictionary = {}
	for path_value in paths:
		var path: Array = path_value
		_check(path.size() == layers.size(), "AC-023-08 %s path visits every layer" % context)
		var counts: Dictionary = {}
		var pressure := 0
		var has_recovery := false
		for node_id_value in path:
			var node := _node_by_id(layers, str(node_id_value))
			var node_type := str(node.get("type", ""))
			counts[node_type] = int(counts.get(node_type, 0)) + 1
			complete_nodes[str(node_id_value)] = true
			var layer_index := int(node.get("layer", -1))
			if layer_index >= first_safe_layer and layer_index < layers.size() - 1 and node_type in ["campfire", "shop"]:
				has_recovery = true
			if node_type == "campfire":
				pressure = 0
			elif node_type in ["combat", "elite", "boss"]:
				pressure += 1
				_check(pressure <= max_pressure, "AC-023-08 %s path stays under pressure limit" % context)
		for node_type_value in budgets.keys():
			var node_type := str(node_type_value)
			var bounds: Array = budgets.get(node_type, [])
			var count := int(counts.get(node_type, 0))
			_check(count >= int(bounds[0]) and count <= int(bounds[1]), "AC-023-08 %s path respects %s budget" % [context, node_type])
		_check(has_recovery, "AC-023-08 %s path has pre-boss recovery" % context)
	for layer in layers:
		for node_value in layer:
			_check(complete_nodes.has(str((node_value as Dictionary).get("id", ""))), "AC-023-08 %s has no dead-end node" % context)
	var branching_count := 0
	var minimum_choices := int(route_constraints.get("minimum_choices_on_branch_layer", 2))
	for layer in layers:
		if (layer as Array).size() >= minimum_choices:
			branching_count += 1
	_check(branching_count >= int(route_constraints.get("minimum_branching_layers", 0)), "AC-023-08 %s preserves route branching" % context)

func _complete_paths(graph: Dictionary) -> Array:
	var outgoing: Dictionary = {}
	for edge_value in graph.get("edges", []):
		var edge: Dictionary = edge_value
		var from_id := str(edge.get("from", ""))
		var targets: Array = outgoing.get(from_id, [])
		targets.append(str(edge.get("to", "")))
		outgoing[from_id] = targets
	var paths: Array = []
	_collect_paths(str(graph.get("start_node_id", "")), str(graph.get("boss_node_id", "")), outgoing, [], {}, paths)
	return paths

func _collect_paths(current_id: String, boss_id: String, outgoing: Dictionary, path: Array, active: Dictionary, paths: Array) -> void:
	if current_id.is_empty() or active.has(current_id):
		return
	var next_path := path.duplicate()
	next_path.append(current_id)
	if current_id == boss_id:
		paths.append(next_path)
		return
	active[current_id] = true
	for target_id in outgoing.get(current_id, []):
		_collect_paths(str(target_id), boss_id, outgoing, next_path, active, paths)
	active.erase(current_id)

func _node_by_id(layers: Array, node_id: String) -> Dictionary:
	for layer in layers:
		for node_value in layer:
			var node: Dictionary = node_value
			if str(node.get("id", "")) == node_id:
				return node
	return {}

func _read_json(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not (parser.data is Dictionary):
		return {}
	return parser.data

func _canonical_json(value):
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var normalized: Dictionary = {}
		for key in keys:
			normalized[str(key)] = _canonical_json(value[key])
		return normalized
	if value is Array:
		var normalized_array: Array = []
		for item in value:
			normalized_array.append(_canonical_json(item))
		return normalized_array
	if typeof(value) == TYPE_FLOAT and is_equal_approx(float(value), round(float(value))):
		return int(round(float(value)))
	return value

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
