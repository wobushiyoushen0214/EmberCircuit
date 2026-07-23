extends SceneTree
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const OverlayScript = preload("res://scripts/tools/BalanceCandidateOverlay.gd")
const CATALOG_PATH := "res://scripts/tools/CharacterParityCandidateCatalog.gd"
const RUNNER_PATH := "res://tools/run_character_parity_ladder.gd"
const FIXTURE_DIR := "res://tests/fixtures/balance_candidates/"
const STEPS := ["B0", "A1", "A2", "A3", "E1", "E2", "E3", "Y1", "Y2", "Y3"]
var _failures: Array[String] = []
class ScriptedRoleGate:
	extends RefCounted
	var pass_steps: Array = []
	var calls: Array = []
	var combined_pass := true
	func _init(steps: Array, combined_value: bool = true) -> void:
		pass_steps = steps.duplicate()
		combined_pass = combined_value
	func evaluate_role(report: Dictionary, character_id: String) -> Dictionary:
		var step := str(report.get("test_step", ""))
		calls.append("%s:%s" % [character_id, step])
		var passed := pass_steps.has(step)
		return {"eligible": true, "pass": passed, "failure_codes": [] if passed else ["role_win_band_c0"], "raw_totals": {}}
	func evaluate_combined_64(report: Dictionary, selected_reports: Dictionary) -> Dictionary:
		calls.append("combined:%s:%d" % [str(report.get("test_step", "")), selected_reports.size()])
		return {"eligible": true, "pass": combined_pass, "failure_codes": [] if combined_pass else ["aggregate_win_band_failed"], "raw_totals": {}}
class ScriptedRoleAdapter:
	extends RefCounted
	var report_calls: Array = []
	var compose_calls: Array = []
	var save_calls: Array = []
	var digest_calls: Array = []
	var verdict_calls: Array = []
	var repeat_identical := true
	var fail_digest_path := ""
	var fail_verdict := false
	var fail_report_number := -1
	var fail_save_path := ""
	func _validate_candidates() -> Dictionary:
		return {"ok": true, "errors": [], "candidate_order": STEPS.duplicate(), "graph_seed_count": 32}
	func _run_report(step: String, iterations: int, character_ids: Array) -> Dictionary:
		report_calls.append("%s:%d:%s" % [step, iterations, ",".join(PackedStringArray(character_ids))])
		if report_calls.size() == fail_report_number: return {}
		return {"test_step": step, "iterations_per_case": iterations, "character_ids": character_ids.duplicate()}
	func _compose_selected(selected_steps: Dictionary) -> Dictionary:
		compose_calls.append(selected_steps.duplicate(true))
		var candidate_id := "024-C1-%s-%s-%s" % [selected_steps.get("arc", ""), selected_steps.get("ember", ""), selected_steps.get("pyre", "")]
		return {"ok": true, "candidate_id": candidate_id, "payload": {"schema_version": 1, "candidate_id": candidate_id, "changes": []}, "errors": []}
	func _save_report(_report: Dictionary, path: String) -> Error:
		save_calls.append(path)
		return ERR_CANT_CREATE if path == fail_save_path else OK
	func _files_identical(_first_path: String, _second_path: String) -> bool:
		return repeat_identical
	func _sha256_file(_path: String) -> String:
		return "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	func _write_digest(output_path: String, _report: Dictionary, _gate: Dictionary, report_path: String, repeat_path: String = "") -> Error:
		digest_calls.append({"output": output_path, "report": report_path, "repeat": repeat_path})
		return ERR_CANT_CREATE if output_path == fail_digest_path else OK
	func _write_verdict(verdict: Dictionary) -> Error:
		verdict_calls.append(str(verdict.get("status", "")))
		return ERR_CANT_CREATE if fail_verdict else OK
class ScriptedHardGate:
	extends RefCounted
	var should_pass := true
	var calls: Array = []
	func _init(pass_value: bool) -> void:
		should_pass = pass_value
	func evaluate_hard(report: Dictionary, expected_iterations: int) -> Dictionary:
		calls.append("%s:%d" % [str(report.get("test_step", "")), expected_iterations])
		return {"eligible": true, "pass": should_pass, "failure_codes": [] if should_pass else ["average_win_rate_outside_target"], "raw_totals": {}}
class ScriptedJsonFile:
	extends RefCounted
	var write_error: Error
	var closed := false
	func _init(error_value: Error) -> void: write_error = error_value
	func store_string(_value: String) -> void: pass
	func flush() -> void: pass
	func get_error() -> Error: return write_error
	func close() -> void: closed = true
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	_check(ResourceLoader.exists(CATALOG_PATH), "AC-024-07 exact character parity catalog exists")
	var payloads: Dictionary = {}
	for step_value in STEPS:
		var step := str(step_value)
		var path := "%s024-%s.json" % [FIXTURE_DIR, step]
		_check(FileAccess.file_exists(path), "AC-024-07 fixture exists: %s" % step)
		if FileAccess.file_exists(path):
			payloads[step] = _read_json(path)
	if ResourceLoader.exists(CATALOG_PATH) and payloads.size() == STEPS.size():
		_test_exact_catalog(payloads)
		_test_catalog_rejections(payloads)
		_test_unique_composition(payloads)
	_test_role_ladder_control()
	_finish()
func _test_role_ladder_control() -> void:
	_check(ResourceLoader.exists(RUNNER_PATH), "AC-024-09 character parity ladder exists")
	if not ResourceLoader.exists(RUNNER_PATH):
		return
	var runner_script = load(RUNNER_PATH)
	var execute := Callable(runner_script, "run_ladder_with_adapter")
	_check(execute.is_valid(), "AC-024-09 runner exposes an executable orchestration seam")
	if not execute.is_valid():
		return
	var store_json := Callable(runner_script, "_store_json")
	_check(store_json.is_valid(), "AC-024-12 runner exposes its post-open JSON write check")
	if store_json.is_valid():
		var failed_file := ScriptedJsonFile.new(ERR_CANT_CREATE)
		_check(store_json.call(failed_file, {"status": "test"}) == ERR_CANT_CREATE and failed_file.closed, "AC-024-12 an opened file's flush error is fatal and closes the handle")
	var arc_adapter := ScriptedRoleAdapter.new()
	var arc_result: Dictionary = execute.call(arc_adapter, ScriptedRoleGate.new([]))
	_check(str(arc_result.get("status", "")) == "paused_no_arc_candidate_passed", "AC-024-09 Arc exhaustion returns the frozen pause code")
	_check(arc_adapter.report_calls == ["B0:64:ember_exile,arc_tinker,pyre_ascetic", "A1:64:arc_tinker", "A2:64:arc_tinker", "A3:64:arc_tinker"], "AC-024-09 Arc exhaustion stops before Ember, Pyre, combination and 128")
	var ember_adapter := ScriptedRoleAdapter.new()
	var ember_result: Dictionary = execute.call(ember_adapter, ScriptedRoleGate.new(["A1"]))
	_check(str(ember_result.get("status", "")) == "paused_no_ember_candidate_passed", "AC-024-09 Ember exhaustion returns the frozen pause code")
	_check(ember_adapter.report_calls == ["B0:64:ember_exile,arc_tinker,pyre_ascetic", "A1:64:arc_tinker", "E1:64:ember_exile", "E2:64:ember_exile", "E3:64:ember_exile"], "AC-024-09 Ember exhaustion stops before Pyre, combination and 128")
	var pyre_adapter := ScriptedRoleAdapter.new()
	var pyre_result: Dictionary = execute.call(pyre_adapter, ScriptedRoleGate.new(["A1", "E1"]))
	_check(str(pyre_result.get("status", "")) == "paused_no_pyre_candidate_passed", "AC-024-09 Pyre exhaustion returns the frozen pause code")
	_check(not _calls_contain(pyre_adapter.report_calls, "024-C1") and not _calls_contain(pyre_adapter.report_calls, ":128:"), "AC-024-09 Pyre exhaustion never requests combination or 128")
	var selected_adapter := ScriptedRoleAdapter.new()
	var selected_gate := ScriptedRoleGate.new(["A2", "E1", "Y3"])
	var selected: Dictionary = execute.call(selected_adapter, selected_gate)
	_check(str(selected.get("status", "")) == "combined_64_passed" and selected.get("selected_steps", {}) == {"arc": "A2", "ember": "E1", "pyre": "Y3"}, "AC-024-09 each role selects its first passing step")
	_check(not _calls_contain(selected_adapter.report_calls, "A3:") and not _calls_contain(selected_adapter.report_calls, "E2:") and selected_adapter.report_calls.count("Y3:64:pyre_ascetic") == 1, "AC-024-09 later steps are skipped after each first pass")
	_check(selected_adapter.compose_calls == [{"arc": "A2", "ember": "E1", "pyre": "Y3"}] and selected_adapter.report_calls.count("024-C1-A2-E1-Y3:64:ember_exile,arc_tinker,pyre_ascetic") == 1, "AC-024-10 runner composes and runs exactly one C1")
	_check(str((selected.get("selected_candidate", {}) as Dictionary).get("candidate_id", "")) == "024-C1-A2-E1-Y3", "AC-024-10 verdict binds the unique C1 identity")
	_check(int(selected.get("total_formal_runs", -1)) == 3072, "AC-024-10 selected branch counts B0, executed role runs and one combined 64")
	var combined_fail_adapter := ScriptedRoleAdapter.new()
	var combined_fail: Dictionary = execute.call(combined_fail_adapter, ScriptedRoleGate.new(["A1", "E1", "Y1"], false))
	_check(str(combined_fail.get("status", "")) == "paused_no_character_parity_candidate_passed", "AC-024-10 combined 64 failure stops with the frozen pause code")
	_check(not _calls_contain(combined_fail_adapter.report_calls, ":128:"), "AC-024-10 combined 64 failure never requests 128")
	_test_128_ladder_control(runner_script, execute)
func _test_128_ladder_control(runner_script, execute: Callable) -> void:
	_check(_method_argument_count(runner_script, "run_ladder_with_adapter") >= 3, "AC-024-11 runner accepts the shared hard gate")
	if _method_argument_count(runner_script, "run_ladder_with_adapter") < 3:
		return
	var budget_check := Callable(runner_script, "sample_budget_allows")
	_check(budget_check.is_valid(), "AC-024-13 runner exposes the formal sample budget check")
	if budget_check.is_valid():
		_check(bool(budget_check.call(0, 6912)) and bool(budget_check.call(6911, 1)) and not bool(budget_check.call(0, 6913)) and not bool(budget_check.call(6912, 1)), "AC-024-13 budget accepts 6912 and rejects 6913 before launch")
	var selected_adapter := ScriptedRoleAdapter.new()
	var selected_hard := ScriptedHardGate.new(true)
	var selected: Dictionary = execute.call(selected_adapter, ScriptedRoleGate.new(["A1", "E1", "Y1"]), selected_hard)
	_check(str(selected.get("status", "")) == "selected_128_candidate", "AC-024-11 byte-identical 128 plus shared hard PASS selects C1")
	_check(selected_adapter.report_calls.count("024-C1-A1-E1-Y1:128:ember_exile,arc_tinker,pyre_ascetic") == 2, "AC-024-11 selected branch runs exactly primary and repeat 128")
	_check(selected_adapter.save_calls.has("/tmp/ember024-C1-128.json") and selected_adapter.save_calls.has("/tmp/ember024-C1-128-repeat.json"), "AC-024-11 both 128 artifacts are saved")
	_check(selected_hard.calls == ["024-C1-A1-E1-Y1:128"], "AC-024-11 shared hard gate is called once with the primary report")
	_check(not _calls_contain(selected_adapter.report_calls, ":256:"), "AC-024-11 selected 128 never runs 256 in task 024-02")
	_check(selected_adapter.digest_calls.size() == 6 and selected_adapter.verdict_calls == ["selected_128_candidate"], "AC-024-12 every executed report stage has a digest and the final verdict is written once")
	if not selected_adapter.digest_calls.is_empty():
		_check((selected_adapter.digest_calls.back() as Dictionary).get("repeat", "") == "/tmp/ember024-C1-128-repeat.json", "AC-024-12 the 128 digest binds the repeat artifact")
	var mismatch_adapter := ScriptedRoleAdapter.new()
	mismatch_adapter.repeat_identical = false
	var mismatch_hard := ScriptedHardGate.new(true)
	var mismatch: Dictionary = execute.call(mismatch_adapter, ScriptedRoleGate.new(["A1", "E1", "Y1"]), mismatch_hard)
	_check(str(mismatch.get("status", "")) == "paused_no_character_parity_candidate_passed" and _verdict_has_step_failure(mismatch, "repeat_mismatch"), "AC-024-11 repeat mismatch pauses with the fixed failure code")
	_check(mismatch_hard.calls.is_empty(), "AC-024-11 repeat mismatch never reaches the shared hard gate")
	_check(mismatch_adapter.digest_calls.size() == 7, "AC-024-12 repeat mismatch writes one compact digest for each non-identical 128 report")
	if mismatch_adapter.digest_calls.size() == 7:
		var mismatch_primary_digest: Dictionary = mismatch_adapter.digest_calls[5]
		var mismatch_repeat_digest: Dictionary = mismatch_adapter.digest_calls[6]
		_check(mismatch_primary_digest.get("output", "") == "res://.trellis/evidence/batch-024/024-C1-128.json" and mismatch_primary_digest.get("report", "") == "/tmp/ember024-C1-128.json" and mismatch_primary_digest.get("repeat", "") == "", "AC-024-12 repeat mismatch preserves the primary 128 report in a standalone digest")
		_check(mismatch_repeat_digest.get("output", "") == "res://.trellis/evidence/batch-024/024-C1-128-repeat.json" and mismatch_repeat_digest.get("report", "") == "/tmp/ember024-C1-128-repeat.json" and mismatch_repeat_digest.get("repeat", "") == "", "AC-024-12 repeat mismatch preserves the repeat 128 report in a standalone digest")
	var mismatch_step: Dictionary = (mismatch.get("steps", []) as Array).back()
	_check(mismatch_step.has("digest_path") and mismatch_step.has("repeat_digest_path"), "AC-024-12 repeat mismatch verdict binds both standalone digest artifacts")
	var rejected_adapter := ScriptedRoleAdapter.new()
	var rejected_hard := ScriptedHardGate.new(false)
	var rejected: Dictionary = execute.call(rejected_adapter, ScriptedRoleGate.new(["A1", "E1", "Y1"]), rejected_hard)
	_check(str(rejected.get("status", "")) == "paused_no_character_parity_candidate_passed", "AC-024-11 shared hard failure pauses without selecting")
	_check(not _calls_contain(rejected_adapter.report_calls, ":256:"), "AC-024-11 hard failure never runs 256")
	for failure_value in [
		{"report_number": 6, "save_path": "", "code": "input_missing", "primary_digest": false},
		{"report_number": -1, "save_path": "/tmp/ember024-C1-128.json", "code": "evidence_write_failed", "primary_digest": false},
		{"report_number": 7, "save_path": "", "code": "input_missing", "primary_digest": true},
		{"report_number": -1, "save_path": "/tmp/ember024-C1-128-repeat.json", "code": "evidence_write_failed", "primary_digest": true}
	]:
		var failure: Dictionary = failure_value
		var failed_adapter := ScriptedRoleAdapter.new()
		failed_adapter.fail_report_number = int(failure["report_number"])
		failed_adapter.fail_save_path = str(failure["save_path"])
		var failed: Dictionary = execute.call(failed_adapter, ScriptedRoleGate.new(["A1", "E1", "Y1"]), ScriptedHardGate.new(true))
		var code := str(failure["code"])
		_check(not bool(failed.get("ok", true)) and failed.get("errors", []) == [code] and _verdict_has_step_failure(failed, code), "AC-024-11 128 report/save failure uses a fixed code and records the failed step: %s" % str(failure))
		var primary_digest_written: bool = failed_adapter.digest_calls.size() == 6 and str((failed_adapter.digest_calls.back() as Dictionary).get("output", "")) == "res://.trellis/evidence/batch-024/024-C1-128.json"
		_check(primary_digest_written == bool(failure["primary_digest"]), "AC-024-12 a saved primary 128 report gets a standalone digest before a repeat-stage failure: %s" % str(failure))
		if bool(failure["primary_digest"]):
			_check(((failed.get("steps", []) as Array).back() as Dictionary).has("digest_path"), "AC-024-12 repeat-stage failure verdict binds the saved primary digest: %s" % str(failure))
	var digest_fail_adapter := ScriptedRoleAdapter.new()
	digest_fail_adapter.fail_digest_path = "res://.trellis/evidence/batch-024/024-E1-64.json"
	var digest_fail: Dictionary = execute.call(digest_fail_adapter, ScriptedRoleGate.new(["A1", "E1", "Y1"]), ScriptedHardGate.new(true))
	_check(not bool(digest_fail.get("ok", true)) and str(digest_fail.get("status", "")) == "execution_failed" and digest_fail.get("errors", []).has("evidence_write_failed"), "AC-024-12 digest write failure stops fail-closed")
	_check(not _calls_contain(digest_fail_adapter.report_calls, "Y1:"), "AC-024-12 evidence failure stops before later role reports")
	var verdict_fail_adapter := ScriptedRoleAdapter.new()
	verdict_fail_adapter.fail_verdict = true
	var verdict_fail: Dictionary = execute.call(verdict_fail_adapter, ScriptedRoleGate.new([]), ScriptedHardGate.new(true))
	_check(not bool(verdict_fail.get("ok", true)) and verdict_fail.get("errors", []).has("evidence_write_failed"), "AC-024-12 final verdict write failure is fatal")
	var maximum_adapter := ScriptedRoleAdapter.new()
	var maximum: Dictionary = execute.call(maximum_adapter, ScriptedRoleGate.new(["A3", "E3", "Y3"]), ScriptedHardGate.new(true))
	_check(str(maximum.get("status", "")) == "selected_128_candidate" and int(maximum.get("total_formal_runs", -1)) == 6912, "AC-024-13 worst-case frozen funnel stops exactly at 6912 formal runs")
func _test_exact_catalog(payloads: Dictionary) -> void:
	var catalog = load(CATALOG_PATH).new()
	var result: Dictionary = catalog.validate(payloads)
	_check(bool(result.get("ok", false)), "AC-024-07 catalog accepts the ten frozen fixtures")
	_check(result.get("errors", []) == [], "AC-024-07 valid catalog has no errors")
	var source_datasets := {
		"map_generation": DataLoaderScript.load_json("res://data/config/map_generation.json"),
		"level_tree": DataLoaderScript.load_json("res://data/config/level_tree.json"),
		"economy": DataLoaderScript.load_json("res://data/config/economy.json"),
		"player": DataLoaderScript.load_json("res://data/config/player.json"),
		"relics": DataLoaderScript.load_json("res://data/relics/relics.json")
	}
	for step_value in STEPS:
		var step := str(step_value)
		var payload: Dictionary = payloads.get(step, {})
		_check(payload.keys().size() == 3 and payload.has("schema_version") and payload.has("candidate_id") and payload.has("changes"), "AC-024-07 %s has no extra top-level fields" % step)
		_check(int(payload.get("schema_version", 0)) == 1, "AC-024-07 %s uses schema v1" % step)
		_check(str(payload.get("candidate_id", "")) == "024-%s" % step, "AC-024-07 %s identity is exact" % step)
		_check(_canonical(payload.get("changes", [])) == _canonical(_expected_changes(step)), "AC-024-07 %s changes are exact" % step)
		_check(_qualified_paths(payload.get("changes", [])) == _sorted(_qualified_paths(payload.get("changes", []))), "AC-024-07 %s changes use qualified-path order" % step)
		var applied: Dictionary = OverlayScript.new().load_and_apply("%s024-%s.json" % [FIXTURE_DIR, step], source_datasets)
		_check(bool(applied.get("ok", false)), "AC-024-07 %s passes the production overlay validator" % step)
	var preflight_callable := Callable(load(RUNNER_PATH), "validate_candidate_preflight")
	_check(preflight_callable.is_valid(), "AC-024-13 runner exposes executable 32-seed preflight")
	if preflight_callable.is_valid():
		var preflight: Dictionary = preflight_callable.call(payloads, source_datasets)
		_check(bool(preflight.get("ok", false)) and int(preflight.get("graph_seed_count", 0)) == 32 and int(preflight.get("graphs_validated", 0)) == 960, "AC-024-13 all ten fixtures pass three-chapter 32-seed graph preflight")
func _test_catalog_rejections(payloads: Dictionary) -> void:
	var catalog = load(CATALOG_PATH).new()
	var extra_step: Dictionary = payloads.duplicate(true)
	extra_step["A4"] = extra_step["A3"].duplicate(true)
	extra_step["A4"]["candidate_id"] = "024-A4"
	_check(not bool(catalog.validate(extra_step).get("ok", true)), "AC-024-07 rejects A4")
	var missing_step: Dictionary = payloads.duplicate(true)
	missing_step.erase("E2")
	_check(not bool(catalog.validate(missing_step).get("ok", true)), "AC-024-07 rejects a missing frozen step")
	var extra_field: Dictionary = payloads.duplicate(true)
	extra_field["A1"]["future_field"] = true
	_check(not bool(catalog.validate(extra_field).get("ok", true)), "AC-024-07 rejects extra payload fields")
	var wrong_order: Dictionary = payloads.duplicate(true)
	wrong_order["A1"]["changes"].reverse()
	_check(not bool(catalog.validate(wrong_order).get("ok", true)), "AC-024-07 rejects change order drift")
	var unknown_card: Dictionary = payloads.duplicate(true)
	_set_change_value(unknown_card["E1"]["changes"], "player.characters.ember_exile.starter_deck_ids", ["unknown_card", "ember_strike", "ember_strike", "ember_strike", "pressure_probe", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"])
	_check(not bool(catalog.validate(unknown_card).get("ok", true)), "AC-024-07 rejects an unknown candidate card id")
	var unknown_relic: Dictionary = payloads.duplicate(true)
	_set_change_path(unknown_relic["Y3"]["changes"], "relics.relics.ash_rosary.effects.0.amount", ["relics", "unknown_relic", "effects", "0", "amount"])
	_check(not bool(catalog.validate(unknown_relic).get("ok", true)), "AC-024-07 rejects an unknown candidate relic id")
	var broken_cumulative: Dictionary = payloads.duplicate(true)
	_set_change_value(broken_cumulative["A3"]["changes"], "player.characters.arc_tinker.starter_deck_ids", _arc_a2_deck())
	_check(not bool(catalog.validate(broken_cumulative).get("ok", true)), "AC-024-07 rejects cumulative ladder drift")
	var near_integer_value: Dictionary = payloads.duplicate(true)
	_set_change_value(near_integer_value["E3"]["changes"], "relics.relics.ember_bottle.effects.0.amount", 5.000001)
	var near_integer_result: Dictionary = catalog.validate(near_integer_value)
	_check(not bool(near_integer_result.get("ok", true)) and near_integer_result.get("errors", []).has("E3:exact_changes_mismatch"), "AC-024-07 exact catalog rejects a near-integer fixture value")
func _test_unique_composition(payloads: Dictionary) -> void:
	var catalog = load(CATALOG_PATH).new()
	var selected := {"arc": "A2", "ember": "E2", "pyre": "Y2"}
	var result: Dictionary = catalog.compose_selected(payloads, selected)
	_check(bool(result.get("ok", false)), "AC-024-07 composes one C1 from three selected roles")
	var payload: Dictionary = result.get("payload", {})
	_check(str(payload.get("candidate_id", "")) == "024-C1-A2-E2-Y2", "AC-024-07 C1 identity binds all selected steps")
	_check(_canonical(payload.get("changes", [])) == _canonical(_merge_selected(payloads, ["A2", "E2", "Y2"])), "AC-024-07 C1 is the sorted deduplicated selected union")
	var paths := _qualified_paths(payload.get("changes", []))
	_check(paths == _sorted(paths) and paths.size() == _unique_count(paths), "AC-024-07 C1 changes are sorted and unique")
	_check(not bool(catalog.compose_selected(payloads, {"arc": "A4", "ember": "E2", "pyre": "Y2"}).get("ok", true)), "AC-024-07 composition rejects A4")
	_check(not bool(catalog.compose_selected(payloads, {"arc": "E1", "ember": "E2", "pyre": "Y2"}).get("ok", true)), "AC-024-07 composition rejects a cross-role step")
	_check(not bool(catalog.compose_selected(payloads, {"arc": "A2", "ember": "E2"}).get("ok", true)), "AC-024-07 composition requires all three roles")
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
func _arc_a2_deck() -> Array: return ["spark_throw", "spark_throw", "relay_strike", "pressure_probe", "pressure_probe", "soot_step", "soot_step", "ash_guard", "ash_guard", "static_primer"]
func _arc_a3_deck() -> Array: return ["spark_throw", "spark_throw", "relay_strike", "pressure_probe", "induction_coil", "soot_step", "soot_step", "ash_guard", "ash_guard", "static_primer"]
func _ember_e1_deck() -> Array: return ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "pressure_probe", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"]
func _ember_e2_deck() -> Array: return ["ember_strike", "ember_strike", "ember_strike", "pressure_probe", "pressure_probe", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"]
func _pyre_y1_deck() -> Array: return ["brand_strike", "brand_strike", "penitent_cut", "penitent_cut", "scar_guard", "scar_guard", "scar_guard", "scar_guard", "kindle_pain", "cooling_breath"]
func _pyre_y2_deck() -> Array: return ["brand_strike", "brand_strike", "penitent_cut", "penitent_cut", "scar_guard", "scar_guard", "scar_guard", "scar_guard", "kindle_pain", "wound_offering"]
func _change(dataset: String, path: Array, value) -> Dictionary: return {"dataset": dataset, "path": path, "value": value}
func _merge_selected(payloads: Dictionary, steps: Array) -> Array:
	var by_path: Dictionary = {}
	for step_value in steps:
		for change_value in (payloads.get(str(step_value), {}) as Dictionary).get("changes", []):
			var change: Dictionary = change_value
			by_path[_qualified_path(change)] = change.duplicate(true)
	var keys: Array = by_path.keys()
	keys.sort()
	var merged: Array = []
	for key in keys:
		merged.append(by_path[key])
	return merged
func _set_change_value(changes: Array, qualified_path: String, value) -> void:
	for change_value in changes:
		var change: Dictionary = change_value
		if _qualified_path(change) == qualified_path:
			change["value"] = value
			return
func _set_change_path(changes: Array, qualified_path: String, path: Array) -> void:
	for change_value in changes:
		var change: Dictionary = change_value
		if _qualified_path(change) == qualified_path:
			change["path"] = path
			return
func _qualified_paths(changes_value) -> Array:
	var paths: Array = []
	if changes_value is Array:
		for change_value in changes_value:
			if change_value is Dictionary:
				paths.append(_qualified_path(change_value))
	return paths
func _qualified_path(change: Dictionary) -> String:
	var parts: PackedStringArray = []
	for part in change.get("path", []):
		parts.append(str(part))
	return "%s.%s" % [str(change.get("dataset", "")), ".".join(parts)]
func _sorted(values: Array) -> Array: var result := values.duplicate(); result.sort(); return result
func _unique_count(values: Array) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()
func _calls_contain(calls: Array, needle: String) -> bool:
	for value in calls:
		if str(value).contains(needle):
			return true
	return false
func _method_argument_count(script, method_name: String) -> int:
	for method_value in script.get_script_method_list():
		var method: Dictionary = method_value
		if str(method.get("name", "")) == method_name:
			return (method.get("args", []) as Array).size()
	return -1
func _verdict_has_step_failure(verdict: Dictionary, code: String) -> bool:
	for step_value in verdict.get("steps", []):
		if (step_value as Dictionary).get("failure_codes", []).has(code):
			return true
	return false
func _read_json(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or parser.data is not Dictionary:
		return {}
	return parser.data
func _canonical(value):
	if value is Dictionary:
		var normalized: Dictionary = {}
		for key in value:
			normalized[key] = _canonical(value[key])
		return normalized
	if value is Array:
		return (value as Array).map(func(item): return _canonical(item))
	return int(value) if typeof(value) == TYPE_FLOAT and float(value) == round(float(value)) else value
func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
func _finish() -> void:
	if _failures.is_empty():
		print("Character parity rebaseline test passed.")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("Character parity rebaseline test failed with %d assertion(s)." % _failures.size())
	quit(1)
