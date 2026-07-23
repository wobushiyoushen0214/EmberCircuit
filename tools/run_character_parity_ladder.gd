extends SceneTree

const CatalogScript = preload("res://scripts/tools/CharacterParityCandidateCatalog.gd")
const GateScript = preload("res://scripts/tools/CharacterParityCandidateGate.gd")
const HardGateScript = preload("res://scripts/tools/LayeredPressureCandidateGate.gd")
const DigestScript = preload("res://scripts/tools/BalanceEvidenceDigest.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const OverlayScript = preload("res://scripts/tools/BalanceCandidateOverlay.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const LayeredRunnerScript = preload("res://tools/run_layered_pressure_ladder.gd")
const SimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")

const FIXTURE_DIR := "res://tests/fixtures/balance_candidates/"
const ALL_STEPS := ["B0", "A1", "A2", "A3", "E1", "E2", "E3", "Y1", "Y2", "Y3"]
const ROLE_PLAN := [
	{"key": "arc", "character_id": "arc_tinker", "steps": ["A1", "A2", "A3"], "paused_status": "paused_no_arc_candidate_passed"},
	{"key": "ember", "character_id": "ember_exile", "steps": ["E1", "E2", "E3"], "paused_status": "paused_no_ember_candidate_passed"},
	{"key": "pyre", "character_id": "pyre_ascetic", "steps": ["Y1", "Y2", "Y3"], "paused_status": "paused_no_pyre_candidate_passed"}
]
const ALL_CHARACTERS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const CHALLENGES := [0, 1, 2, 3]
const COMBINED_OVERLAY_PATH := "/tmp/ember024-C1-overlay.json"
const PRIMARY_128_PATH := "/tmp/ember024-C1-128.json"
const REPEAT_128_PATH := "/tmp/ember024-C1-128-repeat.json"
const EVIDENCE_DIR := "res://.trellis/evidence/batch-024"
const VERDICT_PATH := "res://.trellis/evidence/batch-024/character-parity-verdict.json"
const SAMPLE_BUDGET := 6912

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var verdict := run_ladder()
	if not bool(verdict.get("ok", false)):
		push_error("Character parity ladder failed: %s" % str(verdict.get("errors", [])))
		quit(1)
		return
	print("Character parity ladder complete: status=%s selected=%s" % [str(verdict.get("status", "")), str(verdict.get("selected_steps", {}))])
	quit(0)

func run_ladder() -> Dictionary:
	return run_ladder_with_adapter(self, GateScript.new(), HardGateScript.new())

static func run_ladder_with_adapter(adapter, role_gate, hard_gate = null) -> Dictionary:
	var verdict := _run_ladder_core(adapter, role_gate, hard_gate)
	if adapter._write_verdict(verdict) != OK:
		verdict["ok"] = false
		verdict["status"] = "execution_failed"
		verdict["errors"] = ["evidence_write_failed"]
	return verdict

static func _run_ladder_core(adapter, role_gate, hard_gate = null) -> Dictionary:
	var preflight: Dictionary = adapter._validate_candidates()
	if not bool(preflight.get("ok", false)):
		return _base_verdict(false, "preflight_failed", preflight, [], {}, 0, preflight.get("errors", []))
	var total_formal_runs := 0
	var step_results: Array = []
	if not sample_budget_allows(total_formal_runs, _formal_runs(64, ALL_CHARACTERS)):
		return _budget_failure(preflight, step_results, {}, total_formal_runs)
	var baseline_report: Dictionary = adapter._run_report("B0", 64, ALL_CHARACTERS)
	if baseline_report.is_empty():
		return _base_verdict(false, "execution_failed", preflight, [], {}, total_formal_runs, ["input_missing"])
	total_formal_runs += _formal_runs(64, ALL_CHARACTERS)
	var baseline_gate := {"eligible": true, "pass": true, "failure_codes": []}
	var baseline_artifact := _persist_report(adapter, "B0", 64, baseline_report, baseline_gate)
	if not bool(baseline_artifact.get("ok", false)):
		step_results.append({"step_id": "B0", "status": "evidence_write_failed", "failure_codes": ["evidence_write_failed"]})
		return _execution_failure(preflight, step_results, {}, total_formal_runs, "evidence_write_failed")
	step_results.append({"step_id": "B0", "status": "baseline_64_complete", "gate": baseline_gate, "failure_codes": [], "artifact": baseline_artifact})
	var selected_steps: Dictionary = {}
	var selected_reports: Dictionary = {}
	for role_value in ROLE_PLAN:
		var role: Dictionary = role_value
		var role_selected := ""
		for step_value in role.get("steps", []):
			var step := str(step_value)
			var character_id := str(role.get("character_id", ""))
			if not sample_budget_allows(total_formal_runs, _formal_runs(64, [character_id])):
				return _budget_failure(preflight, step_results, selected_steps, total_formal_runs)
			var report: Dictionary = adapter._run_report(step, 64, [character_id])
			if report.is_empty():
				return _base_verdict(false, "execution_failed", preflight, step_results, selected_steps, total_formal_runs, ["input_missing"])
			total_formal_runs += _formal_runs(64, [character_id])
			var gate: Dictionary = role_gate.evaluate_role(report, character_id)
			var passed := _gate_passed(gate)
			var artifact := _persist_report(adapter, step, 64, report, gate)
			if not bool(artifact.get("ok", false)):
				step_results.append({"step_id": step, "character_id": character_id, "status": "evidence_write_failed", "failure_codes": ["evidence_write_failed"]})
				return _execution_failure(preflight, step_results, selected_steps, total_formal_runs, "evidence_write_failed")
			step_results.append({"step_id": step, "character_id": character_id, "status": "selected_role_64" if passed else "rejected_role_64", "gate": gate, "failure_codes": gate.get("failure_codes", []), "artifact": artifact})
			if passed:
				role_selected = step
				var role_key := str(role.get("key", ""))
				selected_steps[role_key] = step
				selected_reports[role_key] = report.duplicate(true)
				break
		if role_selected.is_empty():
			return _base_verdict(true, str(role.get("paused_status", "")), preflight, step_results, selected_steps, total_formal_runs, [])
	var composition: Dictionary = adapter._compose_selected(selected_steps)
	if not bool(composition.get("ok", false)):
		return _base_verdict(false, "execution_failed", preflight, step_results, selected_steps, total_formal_runs, composition.get("errors", ["identity_mismatch"]))
	var candidate_id := str(composition.get("candidate_id", ""))
	if not sample_budget_allows(total_formal_runs, _formal_runs(64, ALL_CHARACTERS)):
		return _budget_failure(preflight, step_results, selected_steps, total_formal_runs)
	var combined_report: Dictionary = adapter._run_report(candidate_id, 64, ALL_CHARACTERS)
	if combined_report.is_empty():
		return _base_verdict(false, "execution_failed", preflight, step_results, selected_steps, total_formal_runs, ["input_missing"])
	total_formal_runs += _formal_runs(64, ALL_CHARACTERS)
	var combined_gate: Dictionary = role_gate.evaluate_combined_64(combined_report, selected_reports)
	var combined_passed := _gate_passed(combined_gate)
	var combined_artifact := _persist_report(adapter, "C1", 64, combined_report, combined_gate)
	if not bool(combined_artifact.get("ok", false)):
		step_results.append({"step_id": candidate_id, "status": "evidence_write_failed", "failure_codes": ["evidence_write_failed"]})
		return _execution_failure(preflight, step_results, selected_steps, total_formal_runs, "evidence_write_failed")
	step_results.append({"step_id": candidate_id, "status": "combined_64_passed" if combined_passed else "rejected_combined_64", "gate": combined_gate, "failure_codes": combined_gate.get("failure_codes", []), "artifact": combined_artifact})
	var verdict := _base_verdict(true, "combined_64_passed" if combined_passed else "paused_no_character_parity_candidate_passed", preflight, step_results, selected_steps, total_formal_runs, [])
	verdict["selected_candidate"] = (combined_report.get("candidate_overlay", {"candidate_id": candidate_id}) as Dictionary).duplicate(true)
	if not combined_passed or hard_gate == null:
		return verdict

	if not sample_budget_allows(total_formal_runs, _formal_runs(128, ALL_CHARACTERS)):
		return _budget_failure(preflight, step_results, selected_steps, total_formal_runs)
	var primary: Dictionary = adapter._run_report(candidate_id, 128, ALL_CHARACTERS)
	if primary.is_empty():
		return _report_stage_failure(preflight, step_results, selected_steps, total_formal_runs, candidate_id, "input_missing")
	total_formal_runs += _formal_runs(128, ALL_CHARACTERS)
	if adapter._save_report(primary, PRIMARY_128_PATH) != OK:
		return _report_stage_failure(preflight, step_results, selected_steps, total_formal_runs, candidate_id, "evidence_write_failed")
	if not sample_budget_allows(total_formal_runs, _formal_runs(128, ALL_CHARACTERS)):
		return _budget_failure(preflight, step_results, selected_steps, total_formal_runs)
	var repeat: Dictionary = adapter._run_report(candidate_id, 128, ALL_CHARACTERS)
	if repeat.is_empty():
		return _report_stage_failure(preflight, step_results, selected_steps, total_formal_runs, candidate_id, "input_missing", adapter, primary)
	total_formal_runs += _formal_runs(128, ALL_CHARACTERS)
	if adapter._save_report(repeat, REPEAT_128_PATH) != OK:
		return _report_stage_failure(preflight, step_results, selected_steps, total_formal_runs, candidate_id, "evidence_write_failed", adapter, primary)
	var result_128 := {
		"step_id": candidate_id,
		"report_128_path": PRIMARY_128_PATH,
		"report_128_sha256": adapter._sha256_file(PRIMARY_128_PATH),
		"repeat_128_path": REPEAT_128_PATH,
		"repeat_128_sha256": adapter._sha256_file(REPEAT_128_PATH),
		"failure_codes": []
	}
	var digest_128_path := "%s/024-C1-128.json" % EVIDENCE_DIR
	if not adapter._files_identical(PRIMARY_128_PATH, REPEAT_128_PATH):
		var repeat_digest_128_path := "%s/024-C1-128-repeat.json" % EVIDENCE_DIR
		var repeat_gate := {"eligible": true, "pass": false, "failure_codes": ["repeat_mismatch"]}
		if adapter._write_digest(digest_128_path, primary, repeat_gate, PRIMARY_128_PATH) != OK or adapter._write_digest(repeat_digest_128_path, repeat, repeat_gate, REPEAT_128_PATH) != OK:
			result_128["status"] = "evidence_write_failed"
			result_128["failure_codes"] = ["evidence_write_failed"]
			step_results.append(result_128)
			return _execution_failure(preflight, step_results, selected_steps, total_formal_runs, "evidence_write_failed")
		result_128["digest_path"] = digest_128_path
		result_128["digest_sha256"] = adapter._sha256_file(digest_128_path)
		result_128["repeat_digest_path"] = repeat_digest_128_path
		result_128["repeat_digest_sha256"] = adapter._sha256_file(repeat_digest_128_path)
		result_128["status"] = "rejected_repeat_mismatch"
		result_128["failure_codes"] = ["repeat_mismatch"]
		step_results.append(result_128)
		var mismatch := _base_verdict(true, "paused_no_character_parity_candidate_passed", preflight, step_results, selected_steps, total_formal_runs, [])
		mismatch["selected_candidate"] = verdict["selected_candidate"]
		return mismatch
	var hard: Dictionary = hard_gate.evaluate_hard(primary, 128)
	var hard_passed := _gate_passed(hard)
	if adapter._write_digest(digest_128_path, primary, hard, PRIMARY_128_PATH, REPEAT_128_PATH) != OK:
		result_128["status"] = "evidence_write_failed"
		result_128["failure_codes"] = ["evidence_write_failed"]
		step_results.append(result_128)
		return _execution_failure(preflight, step_results, selected_steps, total_formal_runs, "evidence_write_failed")
	result_128["digest_path"] = digest_128_path
	result_128["digest_sha256"] = adapter._sha256_file(digest_128_path)
	result_128["status"] = "selected_128_candidate" if hard_passed else "rejected_hard_gate"
	result_128["hard"] = hard
	result_128["failure_codes"] = hard.get("failure_codes", [])
	step_results.append(result_128)
	var final := _base_verdict(true, "selected_128_candidate" if hard_passed else "paused_no_character_parity_candidate_passed", preflight, step_results, selected_steps, total_formal_runs, [])
	final["selected_candidate"] = verdict["selected_candidate"]
	return final

static func _gate_passed(gate: Dictionary) -> bool:
	return bool(gate.get("eligible", false)) and bool(gate.get("pass", false)) and (gate.get("failure_codes", []) as Array).is_empty()

static func _formal_runs(iterations: int, character_ids: Array) -> int:
	return iterations * character_ids.size() * CHALLENGES.size()

static func sample_budget_allows(current_runs: int, requested_runs: int) -> bool:
	return current_runs >= 0 and requested_runs >= 0 and current_runs + requested_runs <= SAMPLE_BUDGET

static func _persist_report(adapter, step: String, iterations: int, report: Dictionary, gate: Dictionary) -> Dictionary:
	var file_step := "C1" if step == "C1" else step
	var report_path := "/tmp/ember024-%s-%d.json" % [file_step, iterations]
	var digest_path := "%s/024-%s-%d.json" % [EVIDENCE_DIR, file_step, iterations]
	if adapter._save_report(report, report_path) != OK or adapter._write_digest(digest_path, report, gate, report_path) != OK:
		return {"ok": false, "report_path": report_path, "digest_path": digest_path}
	return {"ok": true, "report_path": report_path, "report_sha256": adapter._sha256_file(report_path), "digest_path": digest_path, "digest_sha256": adapter._sha256_file(digest_path)}

static func _base_verdict(ok: bool, status: String, preflight: Dictionary, steps: Array, selected_steps: Dictionary, total_formal_runs: int, errors: Array) -> Dictionary:
	return {
		"schema_version": 1,
		"ok": ok,
		"status": status,
		"candidate_order": ALL_STEPS.duplicate(),
		"selected_steps": selected_steps.duplicate(true),
		"selected_candidate": {},
		"steps": steps.duplicate(true),
		"preflight": preflight.duplicate(true),
		"total_formal_runs": total_formal_runs,
		"production_applied": false,
		"matrix_updated": false,
		"playtest_package_eligible": false,
		"errors": errors.duplicate()
	}

static func _execution_failure(preflight: Dictionary, steps: Array, selected_steps: Dictionary, total_formal_runs: int, code: String) -> Dictionary:
	return _base_verdict(false, "execution_failed", preflight, steps, selected_steps, total_formal_runs, [code])

static func _report_stage_failure(preflight: Dictionary, steps: Array, selected_steps: Dictionary, total_formal_runs: int, step_id: String, code: String, adapter = null, primary: Dictionary = {}) -> Dictionary:
	var result := {"step_id": step_id, "status": "execution_failed", "failure_codes": [code]}
	if not primary.is_empty():
		var digest_path := "%s/024-C1-128.json" % EVIDENCE_DIR
		var failure_gate := {"eligible": true, "pass": false, "failure_codes": [code]}
		if adapter == null or adapter._write_digest(digest_path, primary, failure_gate, PRIMARY_128_PATH) != OK:
			result["failure_codes"] = ["evidence_write_failed"]
			steps.append(result)
			return _execution_failure(preflight, steps, selected_steps, total_formal_runs, "evidence_write_failed")
		result["report_128_path"] = PRIMARY_128_PATH
		result["report_128_sha256"] = adapter._sha256_file(PRIMARY_128_PATH)
		result["digest_path"] = digest_path
		result["digest_sha256"] = adapter._sha256_file(digest_path)
	steps.append(result)
	return _execution_failure(preflight, steps, selected_steps, total_formal_runs, code)

static func _budget_failure(preflight: Dictionary, steps: Array, selected_steps: Dictionary, total_formal_runs: int) -> Dictionary:
	return _base_verdict(false, "sample_budget_exceeded", preflight, steps, selected_steps, total_formal_runs, ["sample_budget_exceeded"])

func _validate_candidates() -> Dictionary:
	var payloads := _load_payloads()
	var source_datasets := {
		"map_generation": DataLoaderScript.load_json("res://data/config/map_generation.json"),
		"level_tree": DataLoaderScript.load_json("res://data/config/level_tree.json"),
		"economy": DataLoaderScript.load_json("res://data/config/economy.json"),
		"player": DataLoaderScript.load_json("res://data/config/player.json"),
		"relics": DataLoaderScript.load_json("res://data/relics/relics.json")
	}
	return validate_candidate_preflight(payloads, source_datasets)

static func validate_candidate_preflight(payloads: Dictionary, source_datasets: Dictionary) -> Dictionary:
	var errors: Array = []
	var catalog_result: Dictionary = CatalogScript.new().validate(payloads)
	errors.append_array(catalog_result.get("errors", []))
	for dataset_name in ["map_generation", "level_tree", "economy", "player", "relics"]:
		if source_datasets.get(dataset_name) is not Dictionary:
			errors.append("%s:input_missing" % dataset_name)
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "candidate_order": ALL_STEPS.duplicate(), "graph_seed_count": 32, "graphs_validated": 0}
	var graph_validator := Callable(LayeredRunnerScript, "candidate_graph_is_valid")
	if not graph_validator.is_valid():
		return {"ok": false, "errors": ["graph_validator_missing"], "candidate_order": ALL_STEPS.duplicate(), "graph_seed_count": 32, "graphs_validated": 0}
	var graphs_validated := 0
	for step_value in ALL_STEPS:
		var step := str(step_value)
		var fixture_path := "%s024-%s.json" % [FIXTURE_DIR, step]
		var applied: Dictionary = OverlayScript.new().load_and_apply(fixture_path, source_datasets)
		if not bool(applied.get("ok", false)):
			errors.append("%s:overlay_invalid" % step)
			continue
		var datasets: Dictionary = applied.get("datasets", {})
		var map_generation: Dictionary = datasets.get("map_generation", {})
		var level_tree: Dictionary = datasets.get("level_tree", {})
		var chapters: Array = map_generation.get("chapter_sequence", []) if map_generation.get("chapter_sequence") is Array else []
		if chapters.size() != 3:
			errors.append("%s:graph_invalid" % step)
			continue
		var step_valid := true
		for chapter_id_value in chapters:
			var chapter_id := str(chapter_id_value)
			var chapter: Dictionary = (map_generation.get(chapter_id, {}) as Dictionary).duplicate(true)
			chapter["level_tree_constraints"] = (level_tree.get("chapters", {}).get(chapter_id, {}) as Dictionary).duplicate(true)
			chapter["route_constraints"] = (level_tree.get("route_constraints", {}) as Dictionary).duplicate(true)
			for seed_index in range(32):
				var config := chapter.duplicate(true)
				config["seed"] = int(chapter.get("seed", 1)) + seed_index * 7919
				var graph: Dictionary = MapGeneratorScript.generate(config)
				if not bool(graph_validator.call(graph, config)):
					step_valid = false
					break
				graphs_validated += 1
			if not step_valid:
				break
		if not step_valid:
			errors.append("%s:graph_invalid" % step)
	return {"ok": errors.is_empty(), "errors": errors, "candidate_order": ALL_STEPS.duplicate(), "graph_seed_count": 32, "graphs_validated": graphs_validated}

func _run_report(step: String, iterations: int, character_ids: Array) -> Dictionary:
	var overlay_path := COMBINED_OVERLAY_PATH if step.begins_with("024-C1-") else "%s024-%s.json" % [FIXTURE_DIR, step]
	var options := {
		"iterations": iterations,
		"max_turns": 80,
		"character_ids": character_ids.duplicate(),
		"challenge_levels": CHALLENGES.duplicate(),
		"strategy_profile": "competent-player-v3",
		"candidate_diagnostics": "attrition-v1",
		"candidate_overlay_path": overlay_path
	}
	var report: Dictionary = SimulatorScript.new().run_campaign_suite(options)
	if bool(report.get("candidate_overlay_rejected", false)):
		return {}
	report["selected_candidate"] = (report.get("candidate_overlay", {}) as Dictionary).duplicate(true)
	return report

func _compose_selected(selected_steps: Dictionary) -> Dictionary:
	var result: Dictionary = CatalogScript.new().compose_selected(_load_payloads(), selected_steps)
	if not bool(result.get("ok", false)):
		return result
	var payload: Dictionary = result.get("payload", {})
	if _write_json(COMBINED_OVERLAY_PATH, payload) != OK:
		return {"ok": false, "candidate_id": "", "payload": {}, "errors": ["input_missing"]}
	return {"ok": true, "candidate_id": str(payload.get("candidate_id", "")), "payload": payload, "errors": []}

func _load_payloads() -> Dictionary:
	var payloads: Dictionary = {}
	for step_value in ALL_STEPS:
		var step := str(step_value)
		var path := "%s024-%s.json" % [FIXTURE_DIR, step]
		if not FileAccess.file_exists(path):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) == OK and parser.data is Dictionary:
			payloads[step] = parser.data
	return payloads

func _write_json(path: String, value: Dictionary) -> Error:
	var absolute_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var parent := absolute_path.get_base_dir()
	if not parent.is_empty() and not DirAccess.dir_exists_absolute(parent):
		var directory_error := DirAccess.make_dir_recursive_absolute(parent)
		if directory_error != OK:
			return directory_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	return _store_json(file, value)

static func _store_json(file, value: Dictionary) -> Error:
	file.store_string(JSON.stringify(value, "  ", true) + "\n")
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	return write_error

func _save_report(report: Dictionary, path: String) -> Error:
	return _write_json(path, report)

func _files_identical(first_path: String, second_path: String) -> bool:
	if not FileAccess.file_exists(first_path) or not FileAccess.file_exists(second_path):
		return false
	return FileAccess.get_file_as_bytes(first_path) == FileAccess.get_file_as_bytes(second_path)

func _sha256_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()

func _write_digest(output_path: String, report: Dictionary, gate: Dictionary, report_path: String, repeat_path: String = "") -> Error:
	var absolute_path := ProjectSettings.globalize_path(output_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		return directory_error
	var result: Dictionary = DigestScript.new().write_digest(output_path, report, gate, report_path, repeat_path)
	return OK if bool(result.get("ok", false)) else ERR_CANT_CREATE

func _write_verdict(verdict: Dictionary) -> Error:
	return _write_json(VERDICT_PATH, verdict)
