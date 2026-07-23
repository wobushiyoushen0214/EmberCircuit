extends SceneTree

const GATE_PATH := "res://scripts/tools/CharacterParityCandidateGate.gd"
const CHALLENGES := [0, 1, 2, 3]
const ROLE_BANDS := [[18, 21], [11, 16], [8, 13], [6, 9]]
const SHA := "1111111111111111111111111111111111111111111111111111111111111111"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists(GATE_PATH), "AC-024-08 character parity gate exists")
	if not ResourceLoader.exists(GATE_PATH):
		_finish()
		return
	var gate = load(GATE_PATH).new()
	_check(gate.has_method("evaluate_role"), "AC-024-08 gate exposes evaluate_role")
	_check(gate.has_method("evaluate_combined_64"), "AC-024-10 gate exposes evaluate_combined_64")
	if gate.has_method("evaluate_role"):
		_test_valid_boundaries(gate)
		_test_band_failures(gate)
		_test_identity_and_matrix(gate)
		_test_fixed_error_order(gate)
	if gate.has_method("evaluate_combined_64"):
		_test_combined_boundaries(gate)
		_test_combined_thresholds(gate)
		_test_selected_role_identity(gate)
	_finish()

func _test_valid_boundaries(gate) -> void:
	for wins in [[18, 11, 8, 6], [21, 16, 13, 9]]:
		var verdict: Dictionary = gate.evaluate_role(_role_report("arc_tinker", "A1", wins), "arc_tinker")
		_check(bool(verdict.get("eligible", false)) and bool(verdict.get("pass", false)), "AC-024-08 all inclusive role-band boundaries pass: %s" % str(wins))
		_check((verdict.get("failure_codes", []) as Array).is_empty(), "AC-024-08 valid role report has no failures: %s" % str(wins))
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(_role_report("ember_exile", "E2", [19, 13, 10, 7])))
	_check(bool(gate.evaluate_role(round_trip, "ember_exile").get("pass", false)), "AC-024-08 saved and reloaded integer counts pass")
	var raw: Array = gate.evaluate_role(_role_report("pyre_ascetic", "Y3", [20, 14, 11, 8]), "pyre_ascetic").get("raw_totals", {}).get("case_totals", [])
	_check(raw.size() == 4 and int(raw[0].get("wins", -1)) == 20 and int(raw[3].get("losses", -1)) == 56, "AC-024-08 verdict exposes four raw case totals")

func _test_band_failures(gate) -> void:
	var expected_codes := ["role_win_band_c0", "role_win_band_c1", "role_win_band_c2", "role_win_band_c3"]
	for challenge_index in range(CHALLENGES.size()):
		for value in [int(ROLE_BANDS[challenge_index][0]) - 1, int(ROLE_BANDS[challenge_index][1]) + 1]:
			var wins := [19, 13, 10, 7]
			wins[challenge_index] = value
			var verdict: Dictionary = gate.evaluate_role(_role_report("arc_tinker", "A2", wins), "arc_tinker")
			_check(bool(verdict.get("eligible", false)) and not bool(verdict.get("pass", true)), "AC-024-08 an out-of-band raw win count remains eligible but fails")
			_check(_codes(verdict) == [expected_codes[challenge_index]], "AC-024-08 C%d raw boundary uses its fixed code at %d" % [challenge_index, value])
	var rounded_lie := _role_report("arc_tinker", "A3", [17, 13, 10, 7])
	_case_for(rounded_lie, 0)["win_rate"] = 0.30
	_check(_codes(gate.evaluate_role(rounded_lie, "arc_tinker")).has("role_win_band_c0"), "AC-024-08 gate uses raw wins rather than rounded rate")

func _test_identity_and_matrix(gate) -> void:
	var missing_case := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	missing_case["cases"].pop_back()
	_check(_codes(gate.evaluate_role(missing_case, "arc_tinker")).has("case_matrix_mismatch"), "AC-024-08 missing challenge case is rejected")

	var duplicate_case := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	duplicate_case["cases"][3]["challenge_level"] = 2
	_check(_codes(gate.evaluate_role(duplicate_case, "arc_tinker")).has("case_matrix_mismatch"), "AC-024-08 duplicate challenge case is rejected")

	var wrong_character := _role_report("ember_exile", "E1", [19, 13, 10, 7])
	_check(_codes(gate.evaluate_role(wrong_character, "arc_tinker")).has("character_scope_mismatch"), "AC-024-08 report cannot cross character scope")

	var mixed_character := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	mixed_character["cases"][0]["character_id"] = "ember_exile"
	_check(_codes(gate.evaluate_role(mixed_character, "arc_tinker")).has("character_scope_mismatch"), "AC-024-08 a mixed-character 4-case report is rejected")

	var wrong_iterations := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	wrong_iterations["iterations_per_case"] = 128
	_check(_codes(gate.evaluate_role(wrong_iterations, "arc_tinker")).has("required_iterations"), "AC-024-08 role gate requires 64 iterations")

	var wrong_runs := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	wrong_runs["cases"][0]["runs"] = 63
	_check(_codes(gate.evaluate_role(wrong_runs, "arc_tinker")).has("required_iterations"), "AC-024-08 every role case requires 64 runs")

	var wrong_identity := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	wrong_identity["selected_candidate"]["sha256"] = "2222222222222222222222222222222222222222222222222222222222222222"
	_check(_codes(gate.evaluate_role(wrong_identity, "arc_tinker")).has("identity_mismatch"), "AC-024-08 selected identity must match overlay")

	var wrong_role_step := _role_report("arc_tinker", "E1", [19, 13, 10, 7])
	_check(_codes(gate.evaluate_role(wrong_role_step, "arc_tinker")).has("identity_mismatch"), "AC-024-08 candidate step must match the requested role")

	var malformed_first_act := _role_report("arc_tinker", "A1", [19, 13, 10, 7])
	_case_for(malformed_first_act, 0)["chapter_attribution"] = []
	_check(_codes(gate.evaluate_role(malformed_first_act, "arc_tinker")).has("input_missing"), "AC-024-08 malformed first-act raw input fails closed")

func _test_fixed_error_order(gate) -> void:
	var report := _role_report("ember_exile", "E1", [19, 13, 10, 7])
	report.erase("candidate_diagnostics")
	report["strategy_profile"] = "current-greedy"
	report["iterations_per_case"] = 128
	report["cases"].pop_back()
	var codes := _codes(gate.evaluate_role(report, "arc_tinker"))
	_check(codes == ["input_missing", "identity_mismatch", "required_iterations", "case_matrix_mismatch", "character_scope_mismatch"], "AC-024-08 structural failures use the frozen error order")

func _test_combined_boundaries(gate) -> void:
	for challenge_cells in [
		[[17, 17, 18], [11, 11, 11], [8, 8, 8], [5, 5, 6]],
		[[21, 21, 21], [16, 16, 17], [14, 15, 15], [9, 9, 10]]
	]:
		var bundle := _combined_bundle(challenge_cells)
		var verdict: Dictionary = gate.evaluate_combined_64(bundle["report"], bundle["selected"])
		_check(bool(verdict.get("eligible", false)) and bool(verdict.get("pass", false)), "AC-024-10 inclusive aggregate boundaries pass: %s" % str(challenge_cells))
		_check(_codes(verdict).is_empty(), "AC-024-10 valid combined report has no failures")
	var raw_bundle := _combined_bundle([[18, 19, 20], [12, 13, 14], [9, 10, 11], [6, 7, 8]])
	var raw: Dictionary = gate.evaluate_combined_64(raw_bundle["report"], raw_bundle["selected"]).get("raw_totals", {})
	_check((raw.get("case_totals", []) as Array).size() == 12 and int((raw.get("challenge_totals", []) as Array)[0].get("wins", -1)) == 57, "AC-024-10 combined verdict exposes 12 cells and four aggregates")

func _test_combined_thresholds(gate) -> void:
	var aggregate_low := _combined_bundle([[16, 17, 18], [11, 11, 11], [8, 8, 8], [5, 5, 6]])
	_check(_codes(gate.evaluate_combined_64(aggregate_low["report"], aggregate_low["selected"])).has("aggregate_win_band_failed"), "AC-024-10 aggregate lower boundary minus one fails")
	var aggregate_high := _combined_bundle([[21, 21, 22], [16, 16, 17], [14, 15, 15], [9, 9, 10]])
	_check(_codes(gate.evaluate_combined_64(aggregate_high["report"], aggregate_high["selected"])).has("aggregate_win_band_failed"), "AC-024-10 aggregate upper boundary plus one fails")

	var cell_bad := _combined_bundle([[15, 21, 21], [12, 13, 14], [9, 10, 11], [6, 7, 8]])
	_check(_codes(gate.evaluate_combined_64(cell_bad["report"], cell_bad["selected"])).has("cell_win_band_failed"), "AC-024-10 a cell outside its raw band fails")

	var gap_edge := _combined_bundle([[16, 21, 18], [12, 13, 14], [9, 10, 11], [6, 7, 8]])
	_check(not _codes(gate.evaluate_combined_64(gap_edge["report"], gap_edge["selected"])).has("character_gap_high"), "AC-024-10 exact five-win character gap passes")
	var gap_high := _combined_bundle([[16, 22, 18], [12, 13, 14], [9, 10, 11], [6, 7, 8]])
	_check(_codes(gate.evaluate_combined_64(gap_high["report"], gap_high["selected"])).has("character_gap_high"), "AC-024-10 six-win character gap fails")

	var monotonic_edge := _combined_bundle([[18, 19, 20], [12, 13, 14], [8, 8, 8], [8, 8, 9]])
	_check(not _codes(gate.evaluate_combined_64(monotonic_edge["report"], monotonic_edge["selected"])).has("challenge_not_monotonic"), "AC-024-10 next challenge may increase by one aggregate win")
	var monotonic_bad := _combined_bundle([[18, 19, 20], [12, 13, 14], [8, 8, 8], [8, 9, 9]])
	_check(_codes(gate.evaluate_combined_64(monotonic_bad["report"], monotonic_bad["selected"])).has("challenge_not_monotonic"), "AC-024-10 next challenge increasing by two aggregate wins fails")

func _test_selected_role_identity(gate) -> void:
	var bundle := _combined_bundle([[18, 19, 20], [12, 13, 14], [9, 10, 11], [6, 7, 8]])
	var row_mismatch: Dictionary = bundle["report"].duplicate(true)
	_case_for_character(row_mismatch, "arc_tinker", 0)["avg_final_gold"] = 139.0
	_check(_codes(gate.evaluate_combined_64(row_mismatch, bundle["selected"])).has("selected_role_case_mismatch"), "AC-024-10 combined raw rows must equal selected role rows")
	var near_row_mismatch: Dictionary = bundle["report"].duplicate(true)
	_case_for_character(near_row_mismatch, "arc_tinker", 0)["avg_final_gold"] = 139.999999
	_check(_codes(gate.evaluate_combined_64(near_row_mismatch, bundle["selected"])).has("selected_role_case_mismatch"), "AC-024-10 exact row equality cannot normalize a near-integer float")
	var loss_row_mismatch: Dictionary = bundle["report"].duplicate(true)
	_case_for_character(loss_row_mismatch, "arc_tinker", 0)["failure_concentration"]["losses"] = 45
	var loss_codes := _codes(gate.evaluate_combined_64(loss_row_mismatch, bundle["selected"]))
	_check(loss_codes.has("input_missing") and loss_codes.has("selected_role_case_mismatch"), "AC-024-10 validates and compares the report's exact losses field")

	var identity_mismatch: Dictionary = bundle["report"].duplicate(true)
	identity_mismatch["candidate_overlay"]["candidate_id"] = "024-C1-A2-E1-Y2"
	identity_mismatch["selected_candidate"]["candidate_id"] = "024-C1-A2-E1-Y2"
	_check(_codes(gate.evaluate_combined_64(identity_mismatch, bundle["selected"])).has("identity_mismatch"), "AC-024-10 C1 identity must bind the three selected steps")

	var missing_selected: Dictionary = (bundle["selected"] as Dictionary).duplicate(true)
	missing_selected.erase("pyre")
	_check(_codes(gate.evaluate_combined_64(bundle["report"], missing_selected)).has("input_missing"), "AC-024-10 all three selected role reports are required")

func _role_report(character_id: String, step: String, wins: Array) -> Dictionary:
	var cases: Array = []
	for challenge_index in range(CHALLENGES.size()):
		var case_wins := int(wins[challenge_index])
		var losses := 64 - case_wins
		cases.append({
			"campaign_attribution_schema_version": 1,
			"campaign_strategy_schema_version": 1,
			"strategy_profile": "competent-player-v3",
			"strategy_profile_fallback": false,
			"candidate_diagnostics": "attrition-v1",
			"attribution_gate_eligible": false,
			"character_id": character_id,
			"challenge_level": challenge_index,
			"runs": 64,
			"wins": case_wins,
			"win_rate": snappedf(float(case_wins) / 64.0, 0.001),
			"avg_final_gold": 140.0,
			"avg_final_deck_size": 17.0,
			"chapter_attribution": [{"chapter_id": "chapter_one", "entry_runs": 64, "completed_runs": 40}],
			"failure_concentration": {"losses": losses, "top_encounter_id": "intro_patrol", "top_encounter_failures": losses / 3, "top_encounter_share": 0.333},
			"attrition_by_layer": [],
			"attrition_by_encounter": []
		})
	var identity := {"schema_version": 1, "candidate_id": "024-%s" % step, "sha256": SHA, "applied_fields": ["map_generation.chapter_one.encounter_layer_bands"]}
	return {
		"version": 1,
		"campaign_attribution_schema_version": 1,
		"campaign_strategy_schema_version": 1,
		"simulation_model": "campaign_route_heuristic_ai",
		"strategy_profile": "competent-player-v3",
		"strategy_profile_fallback": false,
		"seed_model": "paired_by_iteration",
		"iterations_per_case": 64,
		"max_turns_per_combat": 80,
		"case_count": 4,
		"candidate_diagnostics": "attrition-v1",
		"candidate_overlay": identity.duplicate(true),
		"selected_candidate": identity.duplicate(true),
		"cases": cases
	}

func _combined_bundle(challenge_cells: Array) -> Dictionary:
	var arc_wins: Array = []
	var ember_wins: Array = []
	var pyre_wins: Array = []
	for cells_value in challenge_cells:
		var cells: Array = cells_value
		arc_wins.append(cells[0])
		ember_wins.append(cells[1])
		pyre_wins.append(cells[2])
	var selected := {
		"arc": _role_report("arc_tinker", "A2", arc_wins),
		"ember": _role_report("ember_exile", "E1", ember_wins),
		"pyre": _role_report("pyre_ascetic", "Y3", pyre_wins)
	}
	var cases: Array = []
	for role in ["arc", "ember", "pyre"]:
		cases.append_array(((selected[role] as Dictionary).get("cases", []) as Array).duplicate(true))
	var identity := {"schema_version": 1, "candidate_id": "024-C1-A2-E1-Y3", "sha256": SHA, "applied_fields": ["map_generation.chapter_one.encounter_layer_bands"]}
	var report: Dictionary = (selected["arc"] as Dictionary).duplicate(true)
	report["case_count"] = 12
	report["candidate_overlay"] = identity.duplicate(true)
	report["selected_candidate"] = identity.duplicate(true)
	report["cases"] = cases
	return {"report": report, "selected": selected}

func _case_for(report: Dictionary, challenge_level: int) -> Dictionary:
	for case_value in report.get("cases", []):
		var case: Dictionary = case_value
		if int(case.get("challenge_level", -1)) == challenge_level:
			return case
	return {}

func _case_for_character(report: Dictionary, character_id: String, challenge_level: int) -> Dictionary:
	for case_value in report.get("cases", []):
		var case: Dictionary = case_value
		if str(case.get("character_id", "")) == character_id and int(case.get("challenge_level", -1)) == challenge_level:
			return case
	return {}

func _codes(verdict: Dictionary) -> Array:
	return verdict.get("failure_codes", [])

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("Character parity candidate gate test passed.")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("Character parity candidate gate test failed with %d assertion(s)." % _failures.size())
	quit(1)
