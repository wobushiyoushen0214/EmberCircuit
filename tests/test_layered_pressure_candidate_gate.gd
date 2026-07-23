extends SceneTree

const GATE_PATH := "res://scripts/tools/LayeredPressureCandidateGate.gd"
const CHARACTERS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const CHALLENGES := [0, 1, 2, 3]
const OVERLAY_SHA := "1111111111111111111111111111111111111111111111111111111111111111"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(GATE_PATH):
		_check(false, "AC-023-07 layered pressure candidate gate exists")
		_finish()
		return
	var gate_script = load(GATE_PATH)
	var gate = gate_script.new() if gate_script != null else null
	_check(gate != null and gate.has_method("evaluate_direction"), "AC-023-07 gate exposes evaluate_direction")
	_check(gate != null and gate.has_method("evaluate_hard"), "AC-023-07 gate exposes evaluate_hard")
	if gate == null or not gate.has_method("evaluate_direction") or not gate.has_method("evaluate_hard"):
		_finish()
		return
	_test_direction_gate(gate)
	_test_hard_contract(gate)
	_test_hard_threshold_failures(gate)
	_finish()

func _test_direction_gate(gate) -> void:
	var baseline := _direction_report([16, 8, 5, 3], [76, 60, 35, 19], "baseline-022")
	var candidate := _direction_report([16, 8, 5, 3], [84, 66, 35, 19], "023-P1")
	var passed: Dictionary = gate.evaluate_direction(baseline, candidate)
	_check(bool(passed.get("eligible", false)) and bool(passed.get("pass", false)), "AC-023-07 valid raw 64 direction report passes")
	_check((passed.get("failure_codes", []) as Array).is_empty(), "AC-023-07 valid direction verdict has no failures")
	var challenge_totals: Array = passed.get("raw_totals", {}).get("candidate_challenges", [])
	_check(challenge_totals.size() == 4 and int(challenge_totals[0].get("first_act_completed", 0)) == 84, "AC-023-07 direction verdict exposes raw challenge totals")

	var wins_regressed: Dictionary = candidate.duplicate(true)
	_set_case_value(wins_regressed, "ember_exile", 2, "wins", 0)
	_set_case_value(wins_regressed, "ember_exile", 2, "win_rate", 0.999)
	_check(_failures_for(gate.evaluate_direction(baseline, wins_regressed)).has("direction_wins_regressed"), "AC-023-07 direction wins use raw integers rather than rounded rate")

	var act1_regressed: Dictionary = candidate.duplicate(true)
	_set_first_act_completed(act1_regressed, "ember_exile", 3, 0)
	_check(_failures_for(gate.evaluate_direction(baseline, act1_regressed)).has("direction_act1_regressed"), "AC-023-07 direction rejects first-act raw regression")

	var gain_low: Dictionary = candidate.duplicate(true)
	_set_first_act_completed(gain_low, "ember_exile", 0, int(_case_for(gain_low, "ember_exile", 0).get("chapter_attribution", [])[0].get("completed_runs", 0)) - 1)
	_check(_failures_for(gate.evaluate_direction(baseline, gain_low)).has("direction_act1_gain_low"), "AC-023-07 direction enforces C0 and C1 first-act gains")

	var impossible_completed: Dictionary = candidate.duplicate(true)
	_set_first_act_completed(impossible_completed, "ember_exile", 0, 999)
	_check(_failures_for(gate.evaluate_direction(baseline, impossible_completed)).has("input_missing"), "AC-023-07 direction rejects first-act completed counts above runs")
	var negative_completed: Dictionary = candidate.duplicate(true)
	_set_first_act_completed(negative_completed, "ember_exile", 0, -1)
	_check(_failures_for(gate.evaluate_direction(baseline, negative_completed)).has("input_missing"), "AC-023-07 direction rejects negative first-act completed counts")
	var mismatched_entries: Dictionary = candidate.duplicate(true)
	(_case_for(mismatched_entries, "ember_exile", 0).get("chapter_attribution", []) as Array)[0]["entry_runs"] = 63
	_check(_failures_for(gate.evaluate_direction(baseline, mismatched_entries)).has("input_missing"), "AC-023-07 direction requires first-act entry runs to equal case runs")

	var wrong_iterations: Dictionary = candidate.duplicate(true)
	wrong_iterations["iterations_per_case"] = 128
	_check(_failures_for(gate.evaluate_direction(baseline, wrong_iterations)).has("required_iterations"), "AC-023-07 direction rejects a misnamed 128 report")
	var hard_disguise: Dictionary = candidate.duplicate(true)
	_case_for(hard_disguise, "ember_exile", 0)["attribution_gate_eligible"] = true
	_check(_failures_for(gate.evaluate_direction(baseline, hard_disguise)).has("required_iterations"), "AC-023-07 64 direction cannot masquerade as attribution eligible")

func _test_hard_contract(gate) -> void:
	for iterations in [128, 256]:
		var report := _hard_report(iterations)
		var verdict: Dictionary = gate.evaluate_hard(report, iterations)
		_check(bool(verdict.get("eligible", false)) and bool(verdict.get("pass", false)), "AC-023-07 valid %d hard report passes the shared gate" % iterations)
		_check((verdict.get("failure_codes", []) as Array).is_empty(), "AC-023-07 valid %d hard report has no failures" % iterations)
	var round_tripped: Dictionary = JSON.parse_string(JSON.stringify(_hard_report(128)))
	_check(bool(gate.evaluate_hard(round_tripped, 128).get("pass", false)), "AC-023-07 a saved and reloaded raw report preserves exact integer counts")

	var wrong_expected: Dictionary = gate.evaluate_hard(_hard_report(128), 64)
	_check(not bool(wrong_expected.get("eligible", true)) and _failures_for(wrong_expected).has("required_iterations"), "AC-023-07 hard gate only accepts expected iterations 128 or 256")
	_check(_failures_for(gate.evaluate_hard(_hard_report(128), 256)).has("required_iterations"), "AC-023-07 128 report cannot pass the 256 gate")
	_check(_failures_for(gate.evaluate_hard({}, 128)).has("input_missing"), "AC-023-07 missing hard input fails closed")

	var wrong_identity := _hard_report(128)
	wrong_identity["selected_candidate"]["sha256"] = "2222222222222222222222222222222222222222222222222222222222222222"
	_check(_failures_for(gate.evaluate_hard(wrong_identity, 128)).has("identity_mismatch"), "AC-023-07 selected candidate identity must match report overlay")
	var wrong_matrix := _hard_report(128)
	wrong_matrix["cases"].pop_back()
	_check(_failures_for(gate.evaluate_hard(wrong_matrix, 128)).has("case_matrix_mismatch"), "AC-023-07 hard gate requires the exact 3x4 case matrix")
	var malformed_identity := _hard_report(128)
	malformed_identity["candidate_overlay"] = "malformed"
	_check(_failures_for(gate.evaluate_hard(malformed_identity, 128)).has("input_missing"), "AC-023-07 malformed identity fields fail closed with input_missing")

	var malformed_attribution := _hard_report(128)
	_case_for(malformed_attribution, "ember_exile", 0)["chapter_attribution"] = "malformed"
	_check(_failures_for(gate.evaluate_hard(malformed_attribution, 128)).has("input_missing"), "AC-023-07 malformed chapter attribution fails closed with input_missing")
	var malformed_attribution_entry := _direction_report([16, 8, 5, 3], [84, 66, 35, 19], "023-P1")
	_case_for(malformed_attribution_entry, "ember_exile", 0)["chapter_attribution"] = ["malformed"]
	_check(_failures_for(gate.evaluate_direction(_direction_report([16, 8, 5, 3], [76, 60, 35, 19], "baseline-022"), malformed_attribution_entry)).has("input_missing"), "AC-023-07 malformed chapter attribution entry fails closed with input_missing")
	var malformed_completed_count := _hard_report(128)
	(_case_for(malformed_completed_count, "ember_exile", 0).get("chapter_attribution", []) as Array)[0]["completed_runs"] = {"forged": 128}
	_check(_failures_for(gate.evaluate_hard(malformed_completed_count, 128)).has("input_missing"), "AC-023-07 malformed first-act completed count fails closed with input_missing")
	var malformed_run_count := _hard_report(128)
	_case_for(malformed_run_count, "ember_exile", 0)["runs"] = {"forged": 128}
	_check(_failures_for(gate.evaluate_hard(malformed_run_count, 128)).has("required_iterations"), "AC-023-07 malformed case run count fails closed with required_iterations")

	var string_version := _hard_report(128)
	string_version["version"] = "1"
	_check(_failures_for(gate.evaluate_hard(string_version, 128)).has("identity_mismatch"), "AC-023-07 top-level identity integers reject string coercion")
	var integer_fallback := _hard_report(128)
	integer_fallback["strategy_profile_fallback"] = 0
	_check(_failures_for(gate.evaluate_hard(integer_fallback, 128)).has("identity_mismatch"), "AC-023-07 top-level identity booleans reject integer coercion")
	var string_iterations := _hard_report(128)
	string_iterations["iterations_per_case"] = "128"
	_check(_failures_for(gate.evaluate_hard(string_iterations, 128)).has("required_iterations"), "AC-023-07 iterations reject string coercion")
	var string_case_count := _hard_report(128)
	string_case_count["case_count"] = "12"
	_check(_failures_for(gate.evaluate_hard(string_case_count, 128)).has("case_matrix_mismatch"), "AC-023-07 case count rejects string coercion")
	var missing_overlay_schema := _hard_report(128)
	missing_overlay_schema["candidate_overlay"].erase("schema_version")
	_check(_failures_for(gate.evaluate_hard(missing_overlay_schema, 128)).has("input_missing"), "AC-023-07 overlay identity requires schema version one")
	var fake_overlay_sha := _hard_report(128)
	fake_overlay_sha["candidate_overlay"]["sha256"] = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
	fake_overlay_sha["selected_candidate"]["sha256"] = fake_overlay_sha["candidate_overlay"]["sha256"]
	_check(_failures_for(gate.evaluate_hard(fake_overlay_sha, 128)).has("input_missing"), "AC-023-07 overlay identity requires lowercase hexadecimal SHA")
	var malformed_applied_fields := _hard_report(128)
	malformed_applied_fields["candidate_overlay"]["applied_fields"] = [123]
	malformed_applied_fields["selected_candidate"]["applied_fields"] = [123]
	_check(_failures_for(gate.evaluate_hard(malformed_applied_fields, 128)).has("input_missing"), "AC-023-07 overlay applied fields require non-empty strings")
	var missing_selected_schema := _hard_report(128)
	missing_selected_schema["selected_candidate"].erase("schema_version")
	_check(_failures_for(gate.evaluate_hard(missing_selected_schema, 128)).has("identity_mismatch"), "AC-023-07 selected identity includes schema version")
	var string_case_schema := _hard_report(128)
	_case_for(string_case_schema, "ember_exile", 0)["campaign_attribution_schema_version"] = "1"
	_check(_failures_for(gate.evaluate_hard(string_case_schema, 128)).has("identity_mismatch"), "AC-023-07 per-case identity integers reject string coercion")
	var integer_case_eligibility := _hard_report(128)
	_case_for(integer_case_eligibility, "ember_exile", 0)["attribution_gate_eligible"] = 1
	_check(_failures_for(gate.evaluate_hard(integer_case_eligibility, 128)).has("required_iterations"), "AC-023-07 per-case eligibility rejects integer coercion")

func _test_hard_threshold_failures(gate) -> void:
	var average_low := _hard_report(128)
	for character_id in CHARACTERS:
		_set_case_value(average_low, character_id, 0, "wins", 1)
		_set_case_value(average_low, character_id, 0, "win_rate", 0.30)
	var average_failures := _failures_for(gate.evaluate_hard(average_low, 128))
	_check(average_failures.has("average_win_rate_outside_target") and average_failures.has("cell_win_rate_outside_tolerance"), "AC-023-07 hard averages and cells use raw win counts")

	var gap_high := _hard_report(128)
	_set_case_value(gap_high, "ember_exile", 0, "wins", 31)
	_set_case_value(gap_high, "arc_tinker", 0, "wins", 46)
	_set_case_value(gap_high, "pyre_ascetic", 0, "wins", 38)
	_check(_failures_for(gate.evaluate_hard(gap_high, 128)).has("character_gap_high"), "AC-023-07 hard gate rejects a per-challenge character gap above nine percent")
	var gap_edge := _hard_report(128)
	_set_case_value(gap_edge, "ember_exile", 0, "wins", 31)
	_set_case_value(gap_edge, "arc_tinker", 0, "wins", 42)
	_set_case_value(gap_edge, "pyre_ascetic", 0, "wins", 38)
	_check(not _failures_for(gate.evaluate_hard(gap_edge, 128)).has("character_gap_high"), "AC-023-07 exact nine percent character gap remains eligible")

	var not_monotonic := _hard_report(128)
	for character_id in CHARACTERS:
		_set_case_value(not_monotonic, character_id, 2, "wins", 16)
		_set_case_value(not_monotonic, character_id, 3, "wins", 19)
	_check(_failures_for(gate.evaluate_hard(not_monotonic, 128)).has("challenge_not_monotonic"), "AC-023-07 adjacent challenge averages allow at most one percent inverse drift")

	var concentrated := _hard_report(128)
	var concentrated_case := _case_for(concentrated, "ember_exile", 0)
	var losses := int(concentrated_case.get("runs", 0)) - int(concentrated_case.get("wins", 0))
	concentrated_case["failure_concentration"]["top_encounter_failures"] = losses / 2 + 1
	concentrated_case["failure_concentration"]["top_encounter_share"] = 0.001
	_check(_failures_for(gate.evaluate_hard(concentrated, 128)).has("failure_concentration_high"), "AC-023-07 failure concentration uses raw failures rather than rounded share")

	var gold_bad := _hard_report(128)
	_set_case_value(gold_bad, "ember_exile", 0, "avg_final_gold", 99.499)
	_check(_failures_for(gate.evaluate_hard(gold_bad, 128)).has("final_gold_outside_target"), "AC-023-07 final gold rejects values beyond the half-point tolerance")
	var deck_bad := _hard_report(128)
	_set_case_value(deck_bad, "ember_exile", 0, "avg_final_deck_size", 19.501)
	_check(_failures_for(gate.evaluate_hard(deck_bad, 128)).has("final_deck_outside_target"), "AC-023-07 final deck rejects values beyond the half-point tolerance")

func _direction_report(wins: Array, act1_completed: Array, candidate_id: String) -> Dictionary:
	return _report(64, wins, act1_completed, candidate_id, false)

func _hard_report(iterations: int) -> Dictionary:
	var scale := iterations / 128
	return _report(iterations, [115 * scale, 82 * scale, 67 * scale, 44 * scale], [220 * scale, 190 * scale, 160 * scale, 130 * scale], "023-P1", true)

func _report(iterations: int, wins_by_challenge: Array, act1_by_challenge: Array, candidate_id: String, attribution_eligible: bool) -> Dictionary:
	var cases: Array = []
	for character_index in range(CHARACTERS.size()):
		for challenge_index in range(CHALLENGES.size()):
			var wins := _split_total(int(wins_by_challenge[challenge_index]), character_index)
			var completed := _split_total(int(act1_by_challenge[challenge_index]), character_index)
			var losses := iterations - wins
			cases.append({
				"campaign_attribution_schema_version": 1,
				"campaign_strategy_schema_version": 1,
				"strategy_profile": "competent-player-v3",
				"strategy_profile_fallback": false,
				"candidate_diagnostics": "attrition-v1",
				"attribution_gate_eligible": attribution_eligible,
				"character_id": CHARACTERS[character_index],
				"challenge_level": CHALLENGES[challenge_index],
				"runs": iterations,
				"wins": wins,
				"win_rate": snappedf(float(wins) / float(iterations), 0.001),
				"avg_final_gold": 140.0,
				"avg_final_deck_size": 17.0,
				"chapter_attribution": [{"chapter_id": "chapter_one", "entry_runs": iterations, "completed_runs": completed}],
				"failure_concentration": {"losses": losses, "top_encounter_failures": losses / 3, "top_encounter_share": 0.333},
				"attrition_by_layer": [],
				"attrition_by_encounter": []
			})
	var identity := {"schema_version": 1, "candidate_id": candidate_id, "sha256": OVERLAY_SHA, "applied_fields": ["map_generation.chapter_one.encounter_layer_bands"]}
	return {
		"version": 1,
		"campaign_attribution_schema_version": 1,
		"campaign_strategy_schema_version": 1,
		"simulation_model": "campaign_route_heuristic_ai",
		"strategy_profile": "competent-player-v3",
		"strategy_profile_fallback": false,
		"seed_model": "paired_by_iteration",
		"iterations_per_case": iterations,
		"max_turns_per_combat": 80,
		"case_count": 12,
		"candidate_diagnostics": "attrition-v1",
		"candidate_overlay": identity.duplicate(true),
		"selected_candidate": identity.duplicate(true),
		"cases": cases
	}

func _split_total(total: int, index: int) -> int:
	return total / CHARACTERS.size() + (1 if index < total % CHARACTERS.size() else 0)

func _case_for(report: Dictionary, character_id: String, challenge_level: int) -> Dictionary:
	for case_value in report.get("cases", []):
		var case: Dictionary = case_value
		if str(case.get("character_id", "")) == character_id and int(case.get("challenge_level", -1)) == challenge_level:
			return case
	return {}

func _set_case_value(report: Dictionary, character_id: String, challenge_level: int, field: String, value) -> void:
	_case_for(report, character_id, challenge_level)[field] = value

func _set_first_act_completed(report: Dictionary, character_id: String, challenge_level: int, value: int) -> void:
	var case := _case_for(report, character_id, challenge_level)
	(case.get("chapter_attribution", []) as Array)[0]["completed_runs"] = value

func _failures_for(verdict: Dictionary) -> Array:
	return verdict.get("failure_codes", [])

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)

func _finish() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		print("Layered pressure candidate gate test failed with %d assertion(s)." % _failures.size())
		quit(1)
		return
	print("Layered pressure candidate gate test passed.")
	quit(0)
