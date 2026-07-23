extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const OverlayScript = preload("res://scripts/tools/BalanceCandidateOverlay.gd")
const GateScript = preload("res://scripts/tools/LayeredPressureCandidateGate.gd")
const SimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")

const STEPS := ["P1", "P2", "P3", "P4", "P5"]
const CHARACTERS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const CHALLENGES := [0, 1, 2, 3]
const FIXTURE_DIR := "res://tests/fixtures/balance_candidates/"
const BASELINE_PATH := "/tmp/ember023-baseline-64.json"
const VERDICT_PATH := "/tmp/ember023-layered-ladder-verdict.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var verdict := run_ladder()
	var save_error := _write_json(VERDICT_PATH, verdict)
	if save_error != OK or not bool(verdict.get("ok", false)):
		push_error("Layered pressure ladder failed: %s" % str(verdict.get("errors", [])))
		quit(1)
		return
	print("Layered pressure ladder complete: selected=%s verdict=%s" % [str(verdict.get("selected_step", "")), VERDICT_PATH])
	quit(0)

func run_ladder() -> Dictionary:
	return run_ladder_with_adapter(self, GateScript.new())

static func run_ladder_with_adapter(adapter, gate) -> Dictionary:
	var preflight: Dictionary = adapter._validate_candidates()
	if not bool(preflight.get("ok", false)):
		return {"schema_version": 1, "ok": false, "status": "preflight_failed", "candidate_order": STEPS.duplicate(), "selected_step": "", "errors": preflight.get("errors", []), "steps": []}
	adapter._remove_if_exists(BASELINE_PATH)
	var baseline_report: Dictionary = adapter._run_report("", 64)
	if baseline_report.is_empty():
		return {"schema_version": 1, "ok": false, "status": "baseline_failed", "candidate_order": STEPS.duplicate(), "selected_step": "", "errors": ["input_missing"], "steps": []}
	var baseline_identity := {
		"schema_version": 1,
		"candidate_id": "baseline-022",
		"sha256": adapter._baseline_sha256(),
		"applied_fields": ["baseline-022-production-config"]
	}
	baseline_report["candidate_overlay"] = baseline_identity.duplicate(true)
	baseline_report["selected_candidate"] = baseline_identity.duplicate(true)
	if adapter._save_report(baseline_report, BASELINE_PATH) != OK:
		return {"schema_version": 1, "ok": false, "status": "baseline_save_failed", "candidate_order": STEPS.duplicate(), "selected_step": "", "errors": ["input_missing"], "steps": []}

	var step_results: Array = []
	var selected_step := ""
	for step_value in STEPS:
		var step := str(step_value)
		var report_64_path := "/tmp/ember023-%s-64.json" % step
		var report_128_path := "/tmp/ember023-%s-128.json" % step
		var repeat_128_path := "/tmp/ember023-%s-128-repeat.json" % step
		adapter._remove_if_exists(report_64_path)
		adapter._remove_if_exists(report_128_path)
		adapter._remove_if_exists(repeat_128_path)
		var report: Dictionary = adapter._run_report(step, 64)
		if report.is_empty():
			step_results.append({"step_id": step, "status": "report_64_failed", "report_64_path": report_64_path, "failures": ["input_missing"]})
			return _execution_failure(preflight, step_results, step, "report_64_failed", adapter)
		if adapter._save_report(report, report_64_path) != OK:
			step_results.append({"step_id": step, "status": "report_64_save_failed", "report_64_path": report_64_path, "failures": ["input_missing"]})
			return _execution_failure(preflight, step_results, step, "report_64_save_failed", adapter)
		var direction: Dictionary = gate.evaluate_direction(baseline_report, report)
		var step_result := {
			"step_id": step,
			"candidate_id": "023-%s" % step,
			"overlay_path": "%s023-%s.json" % [FIXTURE_DIR, step],
			"overlay_sha256": adapter._sha256_file("%s023-%s.json" % [FIXTURE_DIR, step]),
			"report_64_path": report_64_path,
			"report_64_sha256": adapter._sha256_file(report_64_path),
			"direction": direction,
			"failures": direction.get("failure_codes", [])
		}
		if not direction_allows_hard(direction):
			step_result["status"] = "rejected_direction_gate"
			step_results.append(step_result)
			continue

		var report_128: Dictionary = adapter._run_report(step, 128)
		if report_128.is_empty():
			step_result["status"] = "report_128_failed"
			step_result["failures"] = ["input_missing"]
			step_result["report_128_path"] = report_128_path
			step_results.append(step_result)
			return _execution_failure(preflight, step_results, step, "report_128_failed", adapter)
		if adapter._save_report(report_128, report_128_path) != OK:
			step_result["status"] = "report_128_save_failed"
			step_result["failures"] = ["input_missing"]
			step_result["report_128_path"] = report_128_path
			step_results.append(step_result)
			return _execution_failure(preflight, step_results, step, "report_128_save_failed", adapter)
		var repeat_128: Dictionary = adapter._run_report(step, 128)
		if repeat_128.is_empty():
			step_result["status"] = "report_128_repeat_failed"
			step_result["failures"] = ["input_missing"]
			step_result["report_128_path"] = report_128_path
			step_result["report_128_sha256"] = adapter._sha256_file(report_128_path)
			step_result["repeat_128_path"] = repeat_128_path
			step_results.append(step_result)
			return _execution_failure(preflight, step_results, step, "report_128_repeat_failed", adapter)
		if adapter._save_report(repeat_128, repeat_128_path) != OK:
			step_result["status"] = "report_128_repeat_save_failed"
			step_result["failures"] = ["input_missing"]
			step_result["report_128_path"] = report_128_path
			step_result["report_128_sha256"] = adapter._sha256_file(report_128_path)
			step_result["repeat_128_path"] = repeat_128_path
			step_results.append(step_result)
			return _execution_failure(preflight, step_results, step, "report_128_repeat_save_failed", adapter)

		step_result["report_128_path"] = report_128_path
		step_result["report_128_sha256"] = adapter._sha256_file(report_128_path)
		step_result["repeat_128_path"] = repeat_128_path
		step_result["repeat_128_sha256"] = adapter._sha256_file(repeat_128_path)
		if not adapter._files_identical(report_128_path, repeat_128_path):
			step_result["status"] = "rejected_repeat_mismatch"
			step_result["failures"] = ["report_repeat_mismatch"]
			step_results.append(step_result)
			continue

		var hard: Dictionary = gate.evaluate_hard(report_128, 128)
		step_result["hard"] = hard
		step_result["failures"] = hard.get("failure_codes", [])
		if bool(hard.get("eligible", false)) and bool(hard.get("pass", false)) and (hard.get("failure_codes", []) as Array).is_empty():
			step_result["status"] = "selected_128_candidate"
			selected_step = step
			step_results.append(step_result)
			break
		step_result["status"] = "rejected_hard_gate"
		step_results.append(step_result)
	return {
		"schema_version": 1,
		"ok": true,
		"status": "selected_128_candidate" if not selected_step.is_empty() else "paused_no_layered_candidate_passed",
		"candidate_order": STEPS.duplicate(),
		"selected_step": selected_step,
		"baseline_report_path": BASELINE_PATH,
		"baseline_report_sha256": adapter._sha256_file(BASELINE_PATH),
		"preflight": preflight,
		"steps": step_results,
		"errors": []
	}

static func _execution_failure(preflight: Dictionary, step_results: Array, failed_step: String, failure_code: String, adapter) -> Dictionary:
	return {
		"schema_version": 1,
		"ok": false,
		"status": "execution_failed",
		"candidate_order": STEPS.duplicate(),
		"selected_step": "",
		"failed_step": failed_step,
		"baseline_report_path": BASELINE_PATH,
		"baseline_report_sha256": adapter._sha256_file(BASELINE_PATH),
		"preflight": preflight,
		"steps": step_results,
		"errors": [failure_code]
	}

static func direction_allows_hard(direction_verdict: Dictionary) -> bool:
	return bool(direction_verdict.get("eligible", false)) and bool(direction_verdict.get("pass", false)) and (direction_verdict.get("failure_codes", []) as Array).is_empty()

func _run_report(step: String, iterations: int) -> Dictionary:
	var options := {
		"iterations": iterations,
		"max_turns": 80,
		"character_ids": CHARACTERS.duplicate(),
		"challenge_levels": CHALLENGES.duplicate(),
		"strategy_profile": "competent-player-v3",
		"candidate_diagnostics": "attrition-v1"
	}
	if not step.is_empty():
		options["candidate_overlay_path"] = "%s023-%s.json" % [FIXTURE_DIR, step]
	var simulator = SimulatorScript.new()
	var report: Dictionary = simulator.run_campaign_suite(options)
	if bool(report.get("candidate_overlay_rejected", false)):
		return {}
	if not step.is_empty():
		report["selected_candidate"] = (report.get("candidate_overlay", {}) as Dictionary).duplicate(true)
	return report

func _validate_candidates() -> Dictionary:
	var payloads: Dictionary = {}
	var load_errors: Array = []
	for step_value in STEPS:
		var step := str(step_value)
		var path := "%s023-%s.json" % [FIXTURE_DIR, step]
		if not FileAccess.file_exists(path):
			load_errors.append("%s:input_missing" % step)
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or parser.data is not Dictionary:
			load_errors.append("%s:input_missing" % step)
			continue
		payloads[step] = parser.data
	if not load_errors.is_empty():
		return {"ok": false, "errors": load_errors, "candidate_order": STEPS.duplicate(), "graph_seed_count": 32}
	var payload_validation := validate_candidate_payloads(payloads)
	if not bool(payload_validation.get("ok", false)):
		payload_validation["candidate_order"] = STEPS.duplicate()
		payload_validation["graph_seed_count"] = 32
		return payload_validation
	var errors: Array = []
	var source_datasets := {
		"map_generation": DataLoaderScript.load_json("res://data/config/map_generation.json"),
		"level_tree": DataLoaderScript.load_json("res://data/config/level_tree.json"),
		"economy": DataLoaderScript.load_json("res://data/config/economy.json")
	}
	for step_value in STEPS:
		var step := str(step_value)
		var path := "%s023-%s.json" % [FIXTURE_DIR, step]
		var applied: Dictionary = OverlayScript.new().load_and_apply(path, source_datasets)
		if not bool(applied.get("ok", false)):
			errors.append("%s:overlay_invalid" % step)
		elif not _candidate_graphs_generate(applied.get("datasets", {})):
			errors.append("%s:graph_invalid" % step)
	return {"ok": errors.is_empty(), "errors": errors, "candidate_order": STEPS.duplicate(), "graph_seed_count": 32}

static func validate_candidate_payloads(payloads: Dictionary) -> Dictionary:
	var errors: Array = []
	var previous_changes: Array = []
	for step_value in STEPS:
		var step := str(step_value)
		var payload_value = payloads.get(step)
		if payload_value is not Dictionary:
			errors.append("%s:input_missing" % step)
			continue
		var payload: Dictionary = payload_value
		var changes_value = payload.get("changes")
		if not _integer_equals(payload.get("schema_version"), 1) or payload.get("candidate_id") != "023-%s" % step or changes_value is not Array:
			errors.append("%s:identity_mismatch" % step)
			continue
		var changes: Array = changes_value
		var expected_changes := _expected_changes(step)
		if _canonical(changes) != _canonical(expected_changes):
			errors.append("%s:exact_changes_mismatch" % step)
		if not previous_changes.is_empty() and (changes.size() <= previous_changes.size() or _canonical(changes.slice(0, previous_changes.size())) != _canonical(previous_changes)):
			errors.append("%s:prefix_mismatch" % step)
		previous_changes = changes.duplicate(true)
	return {"ok": errors.is_empty(), "errors": errors}

func _candidate_graphs_generate(datasets: Dictionary) -> bool:
	var map_generation: Dictionary = datasets.get("map_generation", {})
	var level_tree: Dictionary = datasets.get("level_tree", {})
	for chapter_id_value in map_generation.get("chapter_sequence", []):
		var chapter_id := str(chapter_id_value)
		var chapter: Dictionary = (map_generation.get(chapter_id, {}) as Dictionary).duplicate(true)
		chapter["level_tree_constraints"] = (level_tree.get("chapters", {}).get(chapter_id, {}) as Dictionary).duplicate(true)
		chapter["route_constraints"] = (level_tree.get("route_constraints", {}) as Dictionary).duplicate(true)
		for seed_index in range(32):
			var config: Dictionary = chapter.duplicate(true)
			config["seed"] = int(chapter.get("seed", 1)) + seed_index * 7919
			var graph: Dictionary = MapGeneratorScript.generate(config)
			if not candidate_graph_is_valid(graph, config):
				return false
	return true

static func candidate_graph_is_valid(graph: Dictionary, config: Dictionary) -> bool:
	var layers_value = graph.get("layers")
	var edges_value = graph.get("edges")
	if layers_value is not Array or edges_value is not Array:
		return false
	var layers: Array = layers_value
	if layers.size() != int(config.get("layers", 0)) or layers.is_empty():
		return false
	var node_by_id: Dictionary = {}
	var boss_count := 0
	for layer_index in range(layers.size()):
		var layer_value = layers[layer_index]
		if layer_value is not Array or (layer_value as Array).is_empty():
			return false
		for node_value in layer_value:
			if node_value is not Dictionary:
				return false
			var node: Dictionary = node_value
			var node_id = node.get("id")
			if node_id is not String or str(node_id).is_empty() or node_by_id.has(node_id) or int(node.get("layer", -1)) != layer_index:
				return false
			node_by_id[node_id] = node
			if node.get("type") == "boss":
				boss_count += 1
	if boss_count != 1 or not node_by_id.has(graph.get("start_node_id")) or not node_by_id.has(graph.get("boss_node_id")):
		return false
	var paths := _complete_paths(graph)
	if paths.is_empty():
		return false
	var chapter_constraints_value = config.get("level_tree_constraints", {})
	var route_constraints_value = config.get("route_constraints", {})
	if chapter_constraints_value is not Dictionary or route_constraints_value is not Dictionary:
		return false
	var chapter_constraints: Dictionary = chapter_constraints_value
	var route_constraints: Dictionary = route_constraints_value
	var budgets_value = chapter_constraints.get("node_budget", {})
	if budgets_value is not Dictionary:
		return false
	var budgets: Dictionary = budgets_value
	var max_pressure := int(route_constraints.get("max_pressure_nodes_between_campfires", 0))
	var safe_window := int(chapter_constraints.get("boss_safe_window_layers", 2))
	var first_safe_layer: int = max(1, layers.size() - 1 - safe_window)
	var require_recovery := bool(route_constraints.get("require_campfire_or_shop_before_boss", false))
	var complete_nodes: Dictionary = {}
	for path_value in paths:
		if path_value is not Array or (path_value as Array).size() != layers.size():
			return false
		var path: Array = path_value
		var counts: Dictionary = {}
		var pressure := 0
		var has_recovery := false
		for layer_index in range(path.size()):
			var node_id := str(path[layer_index])
			if not node_by_id.has(node_id):
				return false
			var node: Dictionary = node_by_id[node_id]
			if int(node.get("layer", -1)) != layer_index:
				return false
			var node_type := str(node.get("type", ""))
			counts[node_type] = int(counts.get(node_type, 0)) + 1
			complete_nodes[node_id] = true
			if layer_index >= first_safe_layer and layer_index < layers.size() - 1 and node_type in ["campfire", "shop"]:
				has_recovery = true
			if node_type == "campfire":
				pressure = 0
			elif node_type in ["combat", "elite", "boss"]:
				pressure += 1
				if max_pressure <= 0 or pressure > max_pressure:
					return false
		for node_type_value in budgets.keys():
			var bounds_value = budgets.get(node_type_value)
			if bounds_value is not Array or (bounds_value as Array).size() != 2:
				return false
			var bounds: Array = bounds_value
			var count := int(counts.get(node_type_value, 0))
			if count < int(bounds[0]) or count > int(bounds[1]):
				return false
		if require_recovery and not has_recovery:
			return false
	if complete_nodes.size() != node_by_id.size():
		return false
	var branching_count := 0
	var minimum_choices := int(route_constraints.get("minimum_choices_on_branch_layer", 2))
	for layer_value in layers:
		if (layer_value as Array).size() >= minimum_choices:
			branching_count += 1
	if branching_count < int(route_constraints.get("minimum_branching_layers", 0)):
		return false
	return true

func _save_report(report: Dictionary, path: String) -> Error:
	var simulator = SimulatorScript.new()
	return simulator.save_report(report, path)

func _write_json(path: String, value: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(value, "\t"))
	return OK

func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _baseline_sha256() -> String:
	var source := FileAccess.get_file_as_string("res://data/config/map_generation.json") + FileAccess.get_file_as_string("res://data/config/level_tree.json") + FileAccess.get_file_as_string("res://data/config/economy.json")
	return source.sha256_text()

func _sha256_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(FileAccess.get_file_as_bytes(path)) != OK:
		return ""
	return context.finish().hex_encode()

func _files_identical(first_path: String, second_path: String) -> bool:
	if not FileAccess.file_exists(first_path) or not FileAccess.file_exists(second_path):
		return false
	return FileAccess.get_file_as_bytes(first_path) == FileAccess.get_file_as_bytes(second_path)

static func _complete_paths(graph: Dictionary) -> Array:
	var outgoing: Dictionary = {}
	var edges_value = graph.get("edges")
	if edges_value is not Array:
		return []
	for edge_value in edges_value:
		if edge_value is not Dictionary:
			return []
		var edge: Dictionary = edge_value
		var from_id = edge.get("from")
		var to_id = edge.get("to")
		if from_id is not String or to_id is not String:
			return []
		var targets: Array = outgoing.get(from_id, [])
		targets.append(to_id)
		outgoing[from_id] = targets
	var paths: Array = []
	_collect_paths(str(graph.get("start_node_id", "")), str(graph.get("boss_node_id", "")), outgoing, [], {}, paths)
	return paths

static func _collect_paths(current_id: String, boss_id: String, outgoing: Dictionary, path: Array, active: Dictionary, paths: Array) -> void:
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

static func _expected_changes(step: String) -> Array:
	var changes: Array = [{"dataset": "map_generation", "path": ["chapter_one", "encounter_layer_bands"], "value": {"combat": [
		{"layers": [0, 0], "encounter_ids": ["intro_patrol"]},
		{"layers": [1, 2], "encounter_ids": ["intro_patrol", "polluted_lab", "cinder_kennels"]},
		{"layers": [3, 6], "encounter_ids": ["polluted_lab", "iron_checkpoint", "cinder_kennels"]}
	]}}]
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

static func _integer_equals(value, expected: int) -> bool:
	return (typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == floor(float(value)))) and int(value) == expected

static func _canonical(value):
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var result: Dictionary = {}
		for key in keys:
			result[str(key)] = _canonical(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_canonical(item))
		return result
	if typeof(value) == TYPE_FLOAT and float(value) == floor(float(value)):
		return int(value)
	return value
