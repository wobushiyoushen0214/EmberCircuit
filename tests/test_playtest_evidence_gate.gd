extends SceneTree

const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")
const PlaytestEvidenceGateScript = preload("res://scripts/core/PlaytestEvidenceGate.gd")

const CHARACTER_IDS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const CHALLENGE_LEVELS := [0, 1, 2, 3]

var failed := false

func _init() -> void:
	_test_schema_migration_and_retention()
	_test_retention_hard_boundaries()
	_test_cohort_reports_and_merge_conflicts()
	_test_card_comparison_sample_gate()
	if failed:
		quit(1)
		return
	print("Playtest evidence gate tests passed.")
	quit(0)

func _test_schema_migration_and_retention() -> void:
	_check(PlaytestTelemetryScript.SCHEMA_VERSION == 2, "telemetry schema is upgraded to v2")
	var legacy_run := _run("legacy-001", "victory", "0.1.0.8", "legacy-fingerprint", "ember_exile", 0, 1)
	legacy_run.erase("sample_kind")
	legacy_run.erase("gate_eligible")
	var legacy_store := PlaytestTelemetryScript.normalize_store({
		"version": 1,
		"runs": [legacy_run]
	})
	var legacy: Dictionary = legacy_store.get("runs", [])[0]
	_check(str(legacy.get("sample_kind", "")) == "legacy_unapproved", "v1 runs migrate as unapproved legacy samples")
	_check(not bool(legacy.get("gate_eligible", true)), "v1 runs cannot enter the 12/30 evidence gate")

	var runs: Array = []
	var sequence := 0
	for character_id in CHARACTER_IDS:
		for challenge_level in CHALLENGE_LEVELS:
			for sample_index in range(35):
				runs.append(_run(
					"finished-%s-%d-%02d" % [character_id, challenge_level, sample_index],
					"victory" if sample_index % 2 == 0 else "defeat",
					"0.1.0.9",
					"fingerprint-current",
					character_id,
					challenge_level,
					2,
					sequence
				))
				sequence += 1
	for abandoned_index in range(200):
		runs.append(_run(
			"abandoned-%03d" % abandoned_index,
			"abandoned",
			"0.1.0.9",
			"fingerprint-current",
			"ember_exile",
			0,
			2,
			sequence + abandoned_index
		))
	var retained := PlaytestTelemetryScript.normalize_store({"version": 2, "runs": runs})
	var finished_counts: Dictionary = {}
	var abandoned_count := 0
	for run_value in retained.get("runs", []):
		var run: Dictionary = run_value
		if str(run.get("outcome", "")) == "abandoned":
			abandoned_count += 1
		else:
			var cell := "%s|%d" % [str(run.get("character_id", "")), int(run.get("challenge_level", 0))]
			finished_counts[cell] = int(finished_counts.get(cell, 0)) + 1
	_check(finished_counts.size() == 12, "retention preserves all twelve character/challenge cells")
	for character_id in CHARACTER_IDS:
		for challenge_level in CHALLENGE_LEVELS:
			var cell := "%s|%d" % [character_id, challenge_level]
			_check(int(finished_counts.get(cell, 0)) == 35, "retention preserves 35 finished runs for %s" % cell)
	_check(abandoned_count == 96, "abandoned history is capped separately at 96 runs")

	var finished_duplicate := _run("duplicate-terminal", "victory", "0.1.0.9", "fingerprint-current", "ember_exile", 0, 2, 900)
	var abandoned_duplicate := finished_duplicate.duplicate(true)
	abandoned_duplicate["outcome"] = "abandoned"
	var terminal_priority := PlaytestEvidenceGateScript.retain_runs([finished_duplicate, abandoned_duplicate])
	_check(terminal_priority.size() == 1 and str(terminal_priority[0].get("outcome", "")) == "victory", "finished terminal rows take priority over abandoned duplicates")

func _test_retention_hard_boundaries() -> void:
	var cell_runs: Array = []
	for index in range(41):
		cell_runs.append(_run("cell-boundary-%02d" % index, "victory", "0.1.0.20", "fingerprint-boundary", "ember_exile", 0, 2, index))
	var retained_cell := PlaytestEvidenceGateScript.retain_runs(cell_runs)
	_check(retained_cell.size() == 40, "forty-one finished runs are truncated to the latest forty")
	_check(not _has_run_id(retained_cell, "cell-boundary-00") and _has_run_id(retained_cell, "cell-boundary-40"), "per-cell retention evicts only the oldest finished run")

	var cohort_runs: Array = []
	for cohort_index in range(5):
		cohort_runs.append(_run("cohort-boundary-%d" % cohort_index, "victory", "0.1.0.%d" % (30 + cohort_index), "fingerprint-%d" % cohort_index, "ember_exile", 0, 2, cohort_index * 24))
	var retained_cohorts := PlaytestEvidenceGateScript.retain_runs(cohort_runs)
	_check(retained_cohorts.size() == 4, "five cohorts are truncated to the latest four")
	_check(not _has_run_id(retained_cohorts, "cohort-boundary-0"), "the oldest cohort is fully removed")
	for cohort_index in range(1, 5):
		_check(_has_run_id(retained_cohorts, "cohort-boundary-%d" % cohort_index), "recent cohort %d is retained" % cohort_index)

	var mixed_runs: Array = []
	for index in range(40):
		mixed_runs.append(_run("human-retention-%02d" % index, "victory", "0.1.0.40", "fingerprint-mixed", "ember_exile", 0, 2, index))
	for index in range(10):
		var fixture := _run("fixture-retention-%02d" % index, "victory", "0.1.0.40", "fingerprint-mixed", "ember_exile", 0, 2, 100 + index)
		fixture["sample_kind"] = "fixture"
		fixture["gate_eligible"] = false
		mixed_runs.append(fixture)
	var retained_mixed := PlaytestEvidenceGateScript.retain_runs(mixed_runs)
	_check(_count_sample_kind(retained_mixed, "human") == 40, "same-cohort fixtures cannot evict retained human evidence")
	_check(_count_sample_kind(retained_mixed, "fixture") == 10, "fixture diagnostics remain available outside human cell quotas")

func _test_cohort_reports_and_merge_conflicts() -> void:
	var runs: Array = []
	for index in range(12):
		var older := _run("older-%02d" % index, "victory" if index < 6 else "defeat", "0.1.0.9", "fingerprint-a", "arc_tinker", 1, 2, index)
		older["card_telemetry"] = {"ember_strike": {"plays": 1}}
		if str(older.get("outcome", "")) == "defeat":
			older["failure"] = {"encounter_id": "forge_bishop"}
		runs.append(older)
	for index in range(30):
		var newer := _run("newer-%02d" % index, "defeat", "0.1.0.10", "fingerprint-b", "ember_exile", 0, 2, 100 + index)
		newer["failure"] = {"encounter_id": "storm_archon"}
		newer["card_telemetry"] = {"ash_guard": {"plays": 1}}
		runs.append(newer)
	var fixture := _run("fixture-newest", "victory", "0.1.0.11", "fingerprint-fixture", "pyre_ascetic", 3, 2, 200)
	fixture["sample_kind"] = "fixture"
	fixture["gate_eligible"] = false
	runs.append(fixture)
	var same_cohort_fixture := _run("fixture-same-cohort", "victory", "0.1.0.10", "fingerprint-b", "ember_exile", 0, 2, 201)
	same_cohort_fixture["sample_kind"] = "fixture"
	same_cohort_fixture["gate_eligible"] = false
	same_cohort_fixture["card_telemetry"] = {"fixture_only_card": {"plays": 99}}
	runs.append(same_cohort_fixture)
	var report := PlaytestTelemetryScript.build_report({"version": 2, "runs": runs}, {
		"generated_at_utc": "2026-07-20T12:00:00Z",
		"expected_character_ids": CHARACTER_IDS,
		"expected_challenge_levels": CHALLENGE_LEVELS
	})
	var cohorts: Array = report.get("cohorts", [])
	_check(cohorts.size() == 3, "report keeps gameplay and fixture cohorts separate")
	var older_cohort := _cohort_by_version(cohorts, "0.1.0.9")
	var newer_cohort := _cohort_by_version(cohorts, "0.1.0.10")
	_check(is_equal_approx(float(older_cohort.get("summary", {}).get("win_rate", 0.0)), 0.5), "older cohort keeps its own win rate")
	_check(is_equal_approx(float(newer_cohort.get("summary", {}).get("win_rate", 1.0)), 0.0), "newer cohort keeps its own win rate")
	_check(int(newer_cohort.get("summary", {}).get("total_runs", 0)) == 30, "same-cohort fixture rows do not enter human summary totals")
	_check(_coverage_status(older_cohort, "arc_tinker", 1) == "directional_ready", "twelve finished runs reach directional status")
	_check(_coverage_status(newer_cohort, "ember_exile", 0) == "hard_gate_ready", "thirty finished runs reach hard-gate status")
	_check(_coverage_status(newer_cohort, "arc_tinker", 1) == "insufficient", "missing character/challenge cells remain insufficient")
	_check(int(older_cohort.get("coverage", {}).get("missing_finished_for_directional", -1)) == 132, "directional coverage reports the exact twelve-cell gap")
	_check(int(newer_cohort.get("coverage", {}).get("missing_finished_for_hard_gate", -1)) == 330, "hard-gate coverage reports the exact twelve-cell gap")
	_check(_report_card(older_cohort.get("card_telemetry", []), "ember_strike").get("plays", 0) == 12, "older cohort keeps its own card telemetry")
	_check(_report_card(newer_cohort.get("card_telemetry", []), "ash_guard").get("plays", 0) == 30, "newer cohort keeps its own card telemetry")
	_check(_report_card(newer_cohort.get("card_telemetry", []), "fixture_only_card").is_empty(), "same-cohort fixture cards do not enter human evidence")
	_check(str((older_cohort.get("failure_encounters", [])[0] as Dictionary).get("encounter_id", "")) == "forge_bishop", "older cohort keeps its own failure concentration")
	_check(str((newer_cohort.get("failure_encounters", [])[0] as Dictionary).get("encounter_id", "")) == "storm_archon", "newer cohort keeps its own failure concentration")
	_check(str(report.get("game_version", "")) == "0.1.0.10", "top-level compatibility fields select the latest eligible cohort")
	_check(int(report.get("summary", {}).get("finished_runs", 0)) == 30, "top-level compatibility summary maps only to the primary cohort")
	_check(_report_card(report.get("card_telemetry", []), "ash_guard").get("plays", 0) == 30, "primary card telemetry does not mix the older cohort")
	_check(report.get("by_character", []).size() == 1 and str(report.get("by_character", [])[0].get("character_id", "")) == "ember_exile", "primary character rows exclude other cohorts")
	_check(report.get("by_challenge", []).size() == 1 and int(report.get("by_challenge", [])[0].get("challenge_level", -1)) == 0, "primary challenge rows exclude other cohorts")
	_check(report.get("by_character_challenge", []).size() == 1 and str(report.get("by_character_challenge", [])[0].get("character_id", "")) == "ember_exile", "primary character/challenge rows exclude other cohorts")
	_check(report.get("failure_encounters", []).size() == 1 and str(report.get("failure_encounters", [])[0].get("encounter_id", "")) == "storm_archon", "primary failure rows exclude other cohorts")
	_check(report.get("runs", []).size() == 30 and str(report.get("runs", [])[0].get("game_version", "")) == "0.1.0.10", "primary raw runs exclude other cohorts")

	var gate = PlaytestEvidenceGateScript.new()
	_check(gate.has_method("merge_reports"), "evidence gate exposes multi-report merge")
	if not gate.has_method("merge_reports"):
		return
	var older_report := PlaytestTelemetryScript.build_report({"version": 2, "runs": runs.slice(0, 12)}, {
		"generated_at_utc": "2026-07-18T12:00:00Z",
		"expected_character_ids": CHARACTER_IDS,
		"expected_challenge_levels": CHALLENGE_LEVELS
	})
	var deduplicated: Dictionary = gate.call("merge_reports", [older_report, older_report], {})
	_check(bool(deduplicated.get("ok", false)), "identical reports merge successfully")
	_check(int(deduplicated.get("report", {}).get("summary", {}).get("total_runs", 0)) == 12, "identical run ids are deduplicated")
	_check(int(deduplicated.get("report", {}).get("coverage", {}).get("total_cells", 0)) == 12, "merged reports preserve the expected coverage matrix")
	var conflict_report: Dictionary = older_report.duplicate(true)
	conflict_report["runs"][0]["outcome"] = "defeat"
	conflict_report["cohorts"][0]["runs"][0]["outcome"] = "defeat"
	var conflict: Dictionary = gate.call("merge_reports", [older_report, conflict_report], {})
	_check(not bool(conflict.get("ok", true)) and str(conflict.get("error_code", "")) == "duplicate_run_conflict", "conflicting terminal rows are rejected")

	var reordered_report: Dictionary = older_report.duplicate(true)
	var original_run: Dictionary = reordered_report["cohorts"][0]["runs"][0]
	var reordered_run: Dictionary = {}
	var reversed_keys: Array = original_run.keys()
	reversed_keys.reverse()
	for key_value in reversed_keys:
		reordered_run[key_value] = original_run[key_value]
	reordered_report["cohorts"][0]["runs"][0] = reordered_run
	var reordered_duplicate: Dictionary = gate.call("merge_reports", [older_report, reordered_report], {})
	_check(bool(reordered_duplicate.get("ok", false)), "dictionary key order does not create a duplicate-run conflict")

	var newer_report := PlaytestTelemetryScript.build_report({"version": 2, "runs": runs.slice(12, 42)}, {
		"expected_character_ids": CHARACTER_IDS,
		"expected_challenge_levels": CHALLENGE_LEVELS
	})
	var tampered_report: Dictionary = older_report.duplicate(true)
	var newer_cohort_id := str(newer_report.get("primary_cohort_id", ""))
	for run_value in tampered_report["cohorts"][0]["runs"]:
		(run_value as Dictionary)["cohort_id"] = newer_cohort_id
	var regrouped: Dictionary = gate.call("merge_reports", [tampered_report, newer_report], {})
	_check(bool(regrouped.get("ok", false)) and int(regrouped.get("report", {}).get("cohort_count", 0)) == 2, "merged reports recompute cohort identity from schema, version, and fingerprint")

	var malformed: Dictionary = gate.call("merge_reports", [{"runs": [{"run_id": "malformed", "outcome": "victory", "summary": "not-an-object"}]}], {})
	_check(not bool(malformed.get("ok", true)) and str(malformed.get("error_code", "")) == "malformed_run", "malformed report rows are rejected without entering aggregation")
	var malformed_report: Dictionary = gate.call("merge_reports", [{"cohorts": "not-an-array"}], {})
	_check(not bool(malformed_report.get("ok", true)) and str(malformed_report.get("error_code", "")) == "malformed_report", "malformed report containers are rejected before coverage inference")
	var in_progress: Dictionary = gate.call("merge_reports", [{"runs": [_run("still-running", "in_progress", "0.1.0.10", "fingerprint-b", "ember_exile", 0, 2)]}], {})
	_check(not bool(in_progress.get("ok", true)) and str(in_progress.get("error_code", "")) == "malformed_run", "in-progress rows are rejected by the terminal report merger")
	var unknown_outcome: Dictionary = gate.call("merge_reports", [{"runs": [_run("unknown-outcome", "timeout", "0.1.0.10", "fingerprint-b", "ember_exile", 0, 2)]}], {})
	_check(not bool(unknown_outcome.get("ok", true)) and str(unknown_outcome.get("error_code", "")) == "malformed_run", "unknown terminal outcomes are rejected")

func _test_card_comparison_sample_gate() -> void:
	var runs: Array = []
	for index in range(40):
		var run := _run("card-gate-%02d" % index, "victory" if index % 2 == 0 else "defeat", "0.1.0.10", "fingerprint-card-gate", "ember_exile", 0, 2, 300 + index)
		if index < 20:
			run["card_telemetry"] = {"ember_strike": {"acquisitions": 1, "plays": 1}}
		runs.append(run)
	var report := PlaytestEvidenceGateScript.build_report(runs)
	var card := _report_card(report.get("card_telemetry", []), "ember_strike")
	_check(bool(card.get("acquisition_comparison_available", false)), "card acquisition comparison remains available for compatibility")
	_check(bool(card.get("play_comparison_available", false)), "card play comparison remains available for compatibility")
	_check(bool(card.get("acquisition_sample_ready", false)), "card acquisition comparison reaches the twenty-per-side sample gate")
	_check(bool(card.get("play_sample_ready", false)), "card play comparison reaches the twenty-per-side sample gate")
	_check(int(card.get("comparison_sample_threshold", 0)) == 20, "card rows expose the comparison sample threshold")

func _run(run_id: String, outcome: String, game_version: String, fingerprint: String, character_id: String, challenge_level: int, schema_version: int, sequence: int = 0) -> Dictionary:
	return {
		"schema_version": schema_version,
		"run_id": run_id,
		"started_at_utc": "2026-07-%02dT10:00:00Z" % (1 + sequence / 24),
		"finished_at_utc": "2026-07-%02dT11:00:00Z" % (1 + sequence / 24),
		"outcome": outcome,
		"game_version": game_version,
		"engine_version": "4.7.stable",
		"config_fingerprint": fingerprint,
		"sample_kind": "human",
		"gate_eligible": true,
		"character_id": character_id,
		"challenge_level": challenge_level,
		"starting": {},
		"final": {},
		"summary": {},
		"route": [],
		"card_telemetry": {}
	}

func _cohort_by_version(cohorts: Array, game_version: String) -> Dictionary:
	for cohort_value in cohorts:
		var cohort: Dictionary = cohort_value
		if str(cohort.get("game_version", "")) == game_version:
			return cohort
	return {}

func _coverage_status(cohort: Dictionary, character_id: String, challenge_level: int) -> String:
	var cells: Array = cohort.get("coverage", {}).get("cells", [])
	for cell_value in cells:
		var cell: Dictionary = cell_value
		if str(cell.get("character_id", "")) == character_id and int(cell.get("challenge_level", -1)) == challenge_level:
			return str(cell.get("status", ""))
	return ""

func _report_card(rows: Array, card_id: String) -> Dictionary:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == card_id:
			return row
	return {}

func _has_run_id(runs: Array, run_id: String) -> bool:
	for run_value in runs:
		if str((run_value as Dictionary).get("run_id", "")) == run_id:
			return true
	return false

func _count_sample_kind(runs: Array, sample_kind: String) -> int:
	var count := 0
	for run_value in runs:
		if str((run_value as Dictionary).get("sample_kind", "")) == sample_kind:
			count += 1
	return count

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
