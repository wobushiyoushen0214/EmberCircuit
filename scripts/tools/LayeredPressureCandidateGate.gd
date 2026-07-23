class_name LayeredPressureCandidateGate
extends RefCounted

const ERROR_ORDER := [
	"input_missing",
	"identity_mismatch",
	"required_iterations",
	"case_matrix_mismatch",
	"direction_wins_regressed",
	"direction_act1_regressed",
	"direction_act1_gain_low",
	"average_win_rate_outside_target",
	"cell_win_rate_outside_tolerance",
	"character_gap_high",
	"challenge_not_monotonic",
	"failure_concentration_high",
	"final_gold_outside_target",
	"final_deck_outside_target"
]
const CHARACTER_IDS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const CHALLENGE_LEVELS := [0, 1, 2, 3]
const TARGET_RANGES_BPS := [[2700, 3300], [1700, 2600], [1200, 2300], [800, 1500]]
const CELL_TOLERANCE_BPS := 300
const CHARACTER_GAP_BPS := 900
const MONOTONIC_TOLERANCE_BPS := 100
const FAILURE_SHARE_BPS := 5000
const ECONOMY_TOLERANCE := 0.5

func evaluate_direction(baseline_report: Dictionary, candidate_report: Dictionary) -> Dictionary:
	var baseline_validation := _validate_report(baseline_report, 64, false)
	var candidate_validation := _validate_report(candidate_report, 64, false)
	var errors: Array = []
	_append_errors(errors, baseline_validation.get("errors", []))
	_append_errors(errors, candidate_validation.get("errors", []))
	if not errors.is_empty():
		return _verdict(false, false, errors, {"baseline": _raw_totals(baseline_validation), "candidate": _raw_totals(candidate_validation)})
	var baseline_totals: Dictionary = _challenge_totals(baseline_validation.get("cases", []))
	var candidate_totals: Dictionary = _challenge_totals(candidate_validation.get("cases", []))
	var baseline_wins := [16, 8, 5, 3]
	var baseline_first_act := [76, 60, 35, 19]
	for challenge_index in range(CHALLENGE_LEVELS.size()):
		var challenge_level: int = CHALLENGE_LEVELS[challenge_index]
		var baseline_row: Dictionary = baseline_totals.get(challenge_level, {})
		var candidate_row: Dictionary = candidate_totals.get(challenge_level, {})
		if int(baseline_row.get("wins", -1)) != baseline_wins[challenge_index] or int(baseline_row.get("first_act_completed", -1)) != baseline_first_act[challenge_index]:
			_append_error(errors, "identity_mismatch")
		if int(candidate_row.get("wins", -1)) < int(baseline_row.get("wins", 0)):
			_append_error(errors, "direction_wins_regressed")
		if int(candidate_row.get("first_act_completed", -1)) < int(baseline_row.get("first_act_completed", 0)):
			_append_error(errors, "direction_act1_regressed")
		if challenge_level in [0, 1] and int(candidate_row.get("first_act_completed", -1)) < ([84, 66][challenge_level]):
			_append_error(errors, "direction_act1_gain_low")
	var raw_totals := {
		"baseline_challenges": _raw_challenge_rows(baseline_totals),
		"candidate_challenges": _raw_challenge_rows(candidate_totals)
	}
	var normalized_errors := _sorted_errors(errors)
	return _verdict(normalized_errors.is_empty(), true, normalized_errors, raw_totals)

func evaluate_hard(report: Dictionary, expected_iterations: int) -> Dictionary:
	var errors: Array = []
	if expected_iterations not in [128, 256]:
		_append_error(errors, "required_iterations")
	var validation := _validate_report(report, expected_iterations, true)
	_append_errors(errors, validation.get("errors", []))
	var raw_totals := _raw_totals(validation)
	if not errors.is_empty():
		return _verdict(false, false, errors, raw_totals)

	var challenge_totals: Dictionary = _challenge_totals(validation.get("cases", []))
	var challenge_rows: Array = _raw_challenge_rows(challenge_totals)
	for challenge_index in range(CHALLENGE_LEVELS.size()):
		var challenge_level: int = CHALLENGE_LEVELS[challenge_index]
		var row: Dictionary = challenge_totals.get(challenge_level, {})
		var target: Array = TARGET_RANGES_BPS[challenge_index]
		if not _ratio_in_range(int(row.get("wins", 0)), int(row.get("runs", 0)), int(target[0]), int(target[1])):
			_append_error(errors, "average_win_rate_outside_target")
		for case_value in validation.get("cases", []):
			var case: Dictionary = case_value
			if int(case.get("challenge_level", -1)) != challenge_level:
				continue
			var expanded_lower: int = max(0, int(target[0]) - CELL_TOLERANCE_BPS)
			var expanded_upper: int = int(target[1]) + CELL_TOLERANCE_BPS
			if not _ratio_in_range(int(case.get("wins", 0)), int(case.get("runs", 0)), expanded_lower, expanded_upper):
				_append_error(errors, "cell_win_rate_outside_tolerance")
		var rates: Array = []
		for case_value in validation.get("cases", []):
			var case: Dictionary = case_value
			if int(case.get("challenge_level", -1)) == challenge_level:
				rates.append({"wins": int(case.get("wins", 0)), "runs": int(case.get("runs", 0))})
		if _ratio_gap_exceeds(rates, CHARACTER_GAP_BPS):
			_append_error(errors, "character_gap_high")
		challenge_rows[challenge_index]["character_gap_bps"] = _ratio_gap_bps(rates)
	for challenge_index in range(1, challenge_rows.size()):
		var previous: Dictionary = challenge_rows[challenge_index - 1]
		var current: Dictionary = challenge_rows[challenge_index]
		if _ratio_increases_by_more_than(current, previous, MONOTONIC_TOLERANCE_BPS):
			_append_error(errors, "challenge_not_monotonic")

	for case_value in validation.get("cases", []):
		var case: Dictionary = case_value
		var losses: int = int(case.get("runs", 0)) - int(case.get("wins", 0))
		var concentration: Dictionary = case.get("failure_concentration", {})
		var top_failures: int = int(concentration.get("top_encounter_failures", 0))
		if losses < 0 or top_failures < 0 or top_failures * 10000 > losses * FAILURE_SHARE_BPS:
			_append_error(errors, "failure_concentration_high")
		var final_gold: float = float(case.get("avg_final_gold", -INF))
		if final_gold < 100.0 - ECONOMY_TOLERANCE or final_gold > 180.0 + ECONOMY_TOLERANCE:
			_append_error(errors, "final_gold_outside_target")
		var final_deck: float = float(case.get("avg_final_deck_size", -INF))
		if final_deck < 16.0 - ECONOMY_TOLERANCE or final_deck > 19.0 + ECONOMY_TOLERANCE:
			_append_error(errors, "final_deck_outside_target")
	raw_totals["challenge_totals"] = challenge_rows
	raw_totals["case_totals"] = _raw_case_rows(validation.get("cases", []))
	var normalized_errors := _sorted_errors(errors)
	return _verdict(normalized_errors.is_empty(), true, normalized_errors, raw_totals)

func _validate_report(report: Dictionary, expected_iterations: int, hard_gate: bool) -> Dictionary:
	var errors: Array = []
	if report.is_empty():
		_append_error(errors, "input_missing")
		return {"errors": errors, "cases": []}
	if not _integer_equals(report.get("version"), 1) or not _integer_equals(report.get("campaign_attribution_schema_version"), 1) or not _integer_equals(report.get("campaign_strategy_schema_version"), 1):
		_append_error(errors, "identity_mismatch")
	if report.get("simulation_model") != "campaign_route_heuristic_ai" or report.get("strategy_profile") != "competent-player-v3" or not _is_false_bool(report.get("strategy_profile_fallback")):
		_append_error(errors, "identity_mismatch")
	if report.get("seed_model") != "paired_by_iteration" or not _integer_equals(report.get("max_turns_per_combat"), 80):
		_append_error(errors, "identity_mismatch")
	if report.get("candidate_diagnostics") != "attrition-v1":
		_append_error(errors, "input_missing")
	var overlay_value = report.get("candidate_overlay")
	var overlay: Dictionary = overlay_value if overlay_value is Dictionary else {}
	if not _valid_candidate_identity(overlay):
		_append_error(errors, "input_missing")
	var selected_value = report.get("selected_candidate")
	var selected: Dictionary = selected_value if selected_value is Dictionary else {}
	if hard_gate:
		if selected.is_empty():
			_append_error(errors, "input_missing")
		elif not _valid_candidate_identity(selected) or not _candidate_identities_match(selected, overlay):
			_append_error(errors, "identity_mismatch")
	if not _integer_equals(report.get("iterations_per_case"), expected_iterations):
		_append_error(errors, "required_iterations")
	var cases_value = report.get("cases", [])
	if not _integer_equals(report.get("case_count"), 12) or cases_value is not Array or (cases_value as Array).size() != 12:
		_append_error(errors, "case_matrix_mismatch")
	var cases: Array = []
	var seen: Dictionary = {}
	if cases_value is not Array:
		return {"errors": _sorted_errors(errors), "cases": cases}
	for case_value in cases_value:
		if case_value is not Dictionary:
			_append_error(errors, "case_matrix_mismatch")
			continue
		var case: Dictionary = case_value
		var character_id := str(case.get("character_id", "")) if case.get("character_id") is String else ""
		var challenge_level := _integer_or(case.get("challenge_level"), -1)
		var case_runs := _integer_or(case.get("runs"), -1)
		var case_wins := _integer_or(case.get("wins"), -1)
		var key := "%s:%d" % [character_id, challenge_level]
		if not _is_integer_number(case.get("challenge_level")) or not CHARACTER_IDS.has(character_id) or not CHALLENGE_LEVELS.has(challenge_level) or seen.has(key):
			_append_error(errors, "case_matrix_mismatch")
		else:
			seen[key] = true
		if not _is_integer_number(case.get("runs")) or case_runs != expected_iterations or not _is_integer_number(case.get("wins")):
			_append_error(errors, "required_iterations")
		if case_wins < 0 or case_wins > expected_iterations:
			_append_error(errors, "case_matrix_mismatch")
		if not _integer_equals(case.get("campaign_attribution_schema_version"), 1) or not _integer_equals(case.get("campaign_strategy_schema_version"), 1) or case.get("strategy_profile") != "competent-player-v3" or not _is_false_bool(case.get("strategy_profile_fallback")):
			_append_error(errors, "identity_mismatch")
		var chapter_attribution = case.get("chapter_attribution", [])
		var first_chapter_value = (chapter_attribution as Array)[0] if chapter_attribution is Array and not (chapter_attribution as Array).is_empty() else null
		if first_chapter_value is not Dictionary:
			_append_error(errors, "input_missing")
		else:
			var first_chapter: Dictionary = first_chapter_value
			var entry_runs_value = first_chapter.get("entry_runs")
			var completed_runs_value = first_chapter.get("completed_runs")
			if str(first_chapter.get("chapter_id", "")) != "chapter_one" or not _is_integer_number(entry_runs_value) or not _is_integer_number(completed_runs_value):
				_append_error(errors, "input_missing")
			else:
				var entry_runs := int(entry_runs_value)
				var completed_runs := int(completed_runs_value)
				if entry_runs != case_runs or completed_runs < 0 or completed_runs > entry_runs:
					_append_error(errors, "input_missing")
		if case.get("candidate_diagnostics") != "attrition-v1" or not (case.get("attrition_by_layer") is Array) or not (case.get("attrition_by_encounter") is Array):
			_append_error(errors, "input_missing")
		var concentration_value = case.get("failure_concentration")
		if concentration_value is not Dictionary or not _is_integer_number((concentration_value as Dictionary).get("losses")) or not _is_integer_number((concentration_value as Dictionary).get("top_encounter_failures")) or not _is_number(case.get("avg_final_gold")) or not _is_number(case.get("avg_final_deck_size")):
			_append_error(errors, "input_missing")
		var attribution_eligible_value = case.get("attribution_gate_eligible")
		if typeof(attribution_eligible_value) != TYPE_BOOL or bool(attribution_eligible_value) != hard_gate:
			_append_error(errors, "required_iterations")
		cases.append(case)
	if seen.size() != 12:
		_append_error(errors, "case_matrix_mismatch")
	return {"errors": _sorted_errors(errors), "cases": cases}

func _challenge_totals(cases: Array) -> Dictionary:
	var totals: Dictionary = {}
	for challenge_level in CHALLENGE_LEVELS:
		totals[challenge_level] = {"challenge_level": challenge_level, "runs": 0, "wins": 0, "first_act_completed": 0}
	for case_value in cases:
		var case: Dictionary = case_value
		var challenge_level: int = _integer_or(case.get("challenge_level"), -1)
		if not totals.has(challenge_level):
			continue
		var row: Dictionary = totals[challenge_level]
		row["runs"] = int(row.get("runs", 0)) + _integer_or(case.get("runs"), 0)
		row["wins"] = int(row.get("wins", 0)) + _integer_or(case.get("wins"), 0)
		row["first_act_completed"] = int(row.get("first_act_completed", 0)) + _first_act_completed(case)
	return totals

func _raw_totals(validation: Dictionary) -> Dictionary:
	var totals := {"case_totals": _raw_case_rows(validation.get("cases", [])), "challenge_totals": _raw_challenge_rows(_challenge_totals(validation.get("cases", [])))}
	return totals

func _raw_case_rows(cases: Array) -> Array:
	var rows: Array = []
	for case_value in cases:
		var case: Dictionary = case_value
		var runs := _integer_or(case.get("runs"), 0)
		var wins := _integer_or(case.get("wins"), 0)
		rows.append({"character_id": str(case.get("character_id", "")), "challenge_level": _integer_or(case.get("challenge_level"), -1), "runs": runs, "wins": wins, "first_act_completed": _first_act_completed(case), "losses": runs - wins, "avg_final_gold": case.get("avg_final_gold", null), "avg_final_deck_size": case.get("avg_final_deck_size", null)})
	return rows

func _raw_challenge_rows(totals: Dictionary) -> Array:
	var rows: Array = []
	for challenge_level in CHALLENGE_LEVELS:
		rows.append(totals.get(challenge_level, {"challenge_level": challenge_level, "runs": 0, "wins": 0, "first_act_completed": 0}).duplicate(true))
	return rows

func _first_act_completed(case: Dictionary) -> int:
	var attribution = case.get("chapter_attribution", [])
	if attribution is not Array or (attribution as Array).is_empty():
		return 0
	var first_value = (attribution as Array)[0]
	if first_value is not Dictionary:
		return 0
	return _integer_or((first_value as Dictionary).get("completed_runs"), 0)

func _ratio_in_range(numerator: int, denominator: int, lower_bps: int, upper_bps: int) -> bool:
	if denominator <= 0 or numerator < 0:
		return false
	return numerator * 10000 >= denominator * lower_bps and numerator * 10000 <= denominator * upper_bps

func _ratio_gap_exceeds(rates: Array, limit_bps: int) -> bool:
	if rates.size() < 2:
		return false
	var maximum: Dictionary = rates[0]
	var minimum: Dictionary = rates[0]
	for rate_value in rates:
		var rate: Dictionary = rate_value
		if _ratio_greater(rate, maximum):
			maximum = rate
		if _ratio_greater(minimum, rate):
			minimum = rate
	var difference: int = int(maximum.get("wins", 0)) * int(minimum.get("runs", 0)) - int(minimum.get("wins", 0)) * int(maximum.get("runs", 0))
	var denominator: int = int(maximum.get("runs", 0)) * int(minimum.get("runs", 0))
	return difference * 10000 > limit_bps * denominator

func _ratio_gap_bps(rates: Array) -> int:
	if rates.size() < 2:
		return 0
	var maximum: Dictionary = rates[0]
	var minimum: Dictionary = rates[0]
	for rate_value in rates:
		var rate: Dictionary = rate_value
		if _ratio_greater(rate, maximum):
			maximum = rate
		if _ratio_greater(minimum, rate):
			minimum = rate
	var numerator_difference: int = int(maximum.get("wins", 0)) * int(minimum.get("runs", 0)) - int(minimum.get("wins", 0)) * int(maximum.get("runs", 0))
	var denominator: int = int(maximum.get("runs", 0)) * int(minimum.get("runs", 0))
	return int((numerator_difference * 10000) / max(1, denominator))

func _ratio_greater(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("wins", 0)) * int(right.get("runs", 0)) > int(right.get("wins", 0)) * int(left.get("runs", 0))

func _ratio_increases_by_more_than(current: Dictionary, previous: Dictionary, tolerance_bps: int) -> bool:
	var difference: int = int(current.get("wins", 0)) * int(previous.get("runs", 0)) - int(previous.get("wins", 0)) * int(current.get("runs", 0))
	return difference * 10000 > tolerance_bps * int(current.get("runs", 0)) * int(previous.get("runs", 0))

func _is_number(value) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]

func _is_integer_number(value) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == floor(float(value)))

func _integer_equals(value, expected: int) -> bool:
	return _is_integer_number(value) and int(value) == expected

func _integer_or(value, fallback: int) -> int:
	return int(value) if _is_integer_number(value) else fallback

func _is_false_bool(value) -> bool:
	return typeof(value) == TYPE_BOOL and not bool(value)

func _valid_candidate_identity(identity: Dictionary) -> bool:
	if not _integer_equals(identity.get("schema_version"), 1):
		return false
	if identity.get("candidate_id") is not String or str(identity.get("candidate_id", "")).is_empty():
		return false
	if not _is_lower_hex_sha256(identity.get("sha256")):
		return false
	var applied_fields = identity.get("applied_fields")
	if applied_fields is not Array or (applied_fields as Array).is_empty():
		return false
	for field_value in applied_fields:
		if field_value is not String or str(field_value).is_empty():
			return false
	return true

func _candidate_identities_match(left: Dictionary, right: Dictionary) -> bool:
	return left.get("schema_version") == right.get("schema_version") and left.get("candidate_id") == right.get("candidate_id") and left.get("sha256") == right.get("sha256") and left.get("applied_fields") == right.get("applied_fields")

func _is_lower_hex_sha256(value) -> bool:
	if value is not String:
		return false
	var sha := str(value)
	if sha.length() != 64:
		return false
	for character in sha:
		if not "0123456789abcdef".contains(character):
			return false
	return true

func _verdict(pass_value: bool, eligible: bool, errors: Array, raw_totals: Dictionary) -> Dictionary:
	var normalized_errors := _sorted_errors(errors)
	return {"eligible": eligible, "pass": pass_value and eligible, "failure_codes": normalized_errors, "failures": normalized_errors.duplicate(), "raw_totals": raw_totals}

func _append_error(errors: Array, code: String) -> void:
	if ERROR_ORDER.has(code) and not errors.has(code):
		errors.append(code)

func _append_errors(errors: Array, values: Array) -> void:
	for value in values:
		_append_error(errors, str(value))

func _sorted_errors(errors: Array) -> Array:
	var result: Array = []
	for error_value in errors:
		_append_error(result, str(error_value))
	result.sort_custom(func(a, b): return ERROR_ORDER.find(a) < ERROR_ORDER.find(b))
	return result
