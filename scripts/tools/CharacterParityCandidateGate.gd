class_name CharacterParityCandidateGate
extends RefCounted

const ERROR_ORDER := [
	"input_missing", "identity_mismatch", "required_iterations", "case_matrix_mismatch", "character_scope_mismatch",
	"role_win_band_c0", "role_win_band_c1", "role_win_band_c2", "role_win_band_c3", "aggregate_win_band_failed",
	"cell_win_band_failed", "character_gap_high", "challenge_not_monotonic", "selected_role_case_mismatch", "evidence_write_failed", "repeat_mismatch"
]
const CHALLENGE_LEVELS := [0, 1, 2, 3]
const ROLE_WIN_BANDS := [[18, 21], [11, 16], [8, 13], [6, 9]]
const ROLE_FAILURE_CODES := ["role_win_band_c0", "role_win_band_c1", "role_win_band_c2", "role_win_band_c3"]
const CHARACTER_STEP_PREFIX := {
	"arc_tinker": "A",
	"ember_exile": "E",
	"pyre_ascetic": "Y"
}
const ROLE_CHARACTER_IDS := {"arc": "arc_tinker", "ember": "ember_exile", "pyre": "pyre_ascetic"}
const COMBINED_AGGREGATE_BANDS := [[52, 63], [33, 49], [24, 44], [16, 28]]
const COMBINED_CELL_BANDS := [[16, 23], [9, 18], [6, 16], [4, 11]]

func evaluate_role(report: Dictionary, character_id: String) -> Dictionary:
	var validation := _validate_role_report(report, character_id)
	var errors: Array = validation.get("errors", []).duplicate()
	var cases: Array = validation.get("cases", [])
	var raw_totals := {"case_totals": _raw_case_rows(cases)}
	if not errors.is_empty():
		return _verdict(false, false, errors, raw_totals)
	for case_value in cases:
		var case: Dictionary = case_value
		var challenge_level := int(case.get("challenge_level", -1))
		var wins := int(case.get("wins", -1))
		var band: Array = ROLE_WIN_BANDS[challenge_level]
		if wins < int(band[0]) or wins > int(band[1]):
			_append_error(errors, ROLE_FAILURE_CODES[challenge_level])
	return _verdict(errors.is_empty(), true, errors, raw_totals)

func evaluate_combined_64(report: Dictionary, selected_role_reports: Dictionary) -> Dictionary:
	var errors: Array = []
	var selected_cases: Dictionary = {}
	var selected_steps: Dictionary = {}
	if not _has_exact_keys(selected_role_reports, ["arc", "ember", "pyre"]):
		_append_error(errors, "input_missing")
	else:
		for role_value in ["arc", "ember", "pyre"]:
			var role := str(role_value)
			var character_id := str(ROLE_CHARACTER_IDS[role])
			var selected_value = selected_role_reports.get(role)
			if selected_value is not Dictionary:
				_append_error(errors, "input_missing")
				continue
			var selected: Dictionary = selected_value
			var role_validation := _validate_role_report(selected, character_id)
			for code_value in role_validation.get("errors", []):
				_append_error(errors, str(code_value))
			var identity: Dictionary = selected.get("candidate_overlay", {}) if selected.get("candidate_overlay") is Dictionary else {}
			selected_steps[role] = str(identity.get("candidate_id", "")).trim_prefix("024-")
			for case_value in selected.get("cases", []):
				if case_value is Dictionary:
					var case: Dictionary = case_value
					selected_cases["%s:%d" % [character_id, _integer_or(case.get("challenge_level"), -1)]] = _case_signature(case)

	var validation := _validate_combined_report(report, selected_steps)
	for code_value in validation.get("errors", []):
		_append_error(errors, str(code_value))
	var cases: Array = validation.get("cases", [])
	for case_value in cases:
		var case: Dictionary = case_value
		var key := "%s:%d" % [str(case.get("character_id", "")), _integer_or(case.get("challenge_level"), -1)]
		if not selected_cases.has(key) or selected_cases[key] != _case_signature(case):
			_append_error(errors, "selected_role_case_mismatch")
	var raw_totals := {"case_totals": _raw_case_rows(cases), "challenge_totals": _raw_challenge_rows(cases)}
	if not errors.is_empty():
		return _verdict(false, false, errors, raw_totals)

	var challenge_rows: Array = raw_totals["challenge_totals"]
	for challenge_index in range(CHALLENGE_LEVELS.size()):
		var aggregate: Dictionary = challenge_rows[challenge_index]
		var aggregate_band: Array = COMBINED_AGGREGATE_BANDS[challenge_index]
		var aggregate_wins := int(aggregate.get("wins", -1))
		if aggregate_wins < int(aggregate_band[0]) or aggregate_wins > int(aggregate_band[1]):
			_append_error(errors, "aggregate_win_band_failed")
		var minimum := 999
		var maximum := -1
		for case_value in cases:
			var case: Dictionary = case_value
			if int(case.get("challenge_level", -1)) != challenge_index:
				continue
			var wins := int(case.get("wins", -1))
			var cell_band: Array = COMBINED_CELL_BANDS[challenge_index]
			if wins < int(cell_band[0]) or wins > int(cell_band[1]):
				_append_error(errors, "cell_win_band_failed")
			minimum = min(minimum, wins)
			maximum = max(maximum, wins)
		if maximum - minimum > 5:
			_append_error(errors, "character_gap_high")
	for challenge_index in range(1, challenge_rows.size()):
		if int(challenge_rows[challenge_index].get("wins", 0)) >= int(challenge_rows[challenge_index - 1].get("wins", 0)) + 2:
			_append_error(errors, "challenge_not_monotonic")
	return _verdict(errors.is_empty(), true, errors, raw_totals)

func _validate_combined_report(report: Dictionary, selected_steps: Dictionary) -> Dictionary:
	var errors: Array = []
	if report.is_empty():
		return {"errors": ["input_missing"], "cases": []}
	if not _integer_equals(report.get("version"), 1) or not _integer_equals(report.get("campaign_attribution_schema_version"), 1) or not _integer_equals(report.get("campaign_strategy_schema_version"), 1):
		_append_error(errors, "identity_mismatch")
	if report.get("simulation_model") != "campaign_route_heuristic_ai" or report.get("strategy_profile") != "competent-player-v3" or not _is_false_bool(report.get("strategy_profile_fallback")) or report.get("seed_model") != "paired_by_iteration" or not _integer_equals(report.get("max_turns_per_combat"), 80):
		_append_error(errors, "identity_mismatch")
	if report.get("candidate_diagnostics") != "attrition-v1":
		_append_error(errors, "input_missing")
	var overlay: Dictionary = report.get("candidate_overlay", {}) if report.get("candidate_overlay") is Dictionary else {}
	var selected: Dictionary = report.get("selected_candidate", {}) if report.get("selected_candidate") is Dictionary else {}
	if not _valid_candidate_identity(overlay):
		_append_error(errors, "input_missing")
	elif selected_steps.size() == 3 and str(overlay.get("candidate_id", "")) != "024-C1-%s-%s-%s" % [selected_steps.get("arc", ""), selected_steps.get("ember", ""), selected_steps.get("pyre", "")]:
		_append_error(errors, "identity_mismatch")
	if selected.is_empty():
		_append_error(errors, "input_missing")
	elif not _valid_candidate_identity(selected) or not _candidate_identities_match(selected, overlay):
		_append_error(errors, "identity_mismatch")
	if not _integer_equals(report.get("iterations_per_case"), 64):
		_append_error(errors, "required_iterations")
	var cases_value = report.get("cases")
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
		var key := "%s:%d" % [character_id, challenge_level]
		if not ROLE_CHARACTER_IDS.values().has(character_id):
			_append_error(errors, "character_scope_mismatch")
		if not CHALLENGE_LEVELS.has(challenge_level) or seen.has(key):
			_append_error(errors, "case_matrix_mismatch")
		else:
			seen[key] = true
		if not _integer_equals(case.get("runs"), 64) or not _is_integer_number(case.get("wins")):
			_append_error(errors, "required_iterations")
		var wins := _integer_or(case.get("wins"), -1)
		if wins < 0 or wins > 64:
			_append_error(errors, "case_matrix_mismatch")
		if not _integer_equals(case.get("campaign_attribution_schema_version"), 1) or not _integer_equals(case.get("campaign_strategy_schema_version"), 1) or case.get("strategy_profile") != "competent-player-v3" or not _is_false_bool(case.get("strategy_profile_fallback")):
			_append_error(errors, "identity_mismatch")
		if case.get("candidate_diagnostics") != "attrition-v1" or case.get("attrition_by_layer") is not Array or case.get("attrition_by_encounter") is not Array:
			_append_error(errors, "input_missing")
		if typeof(case.get("attribution_gate_eligible")) != TYPE_BOOL or bool(case.get("attribution_gate_eligible")):
			_append_error(errors, "required_iterations")
		_validate_case_raw_inputs(case, 64, errors)
		cases.append(case)
	if seen.size() != 12:
		_append_error(errors, "case_matrix_mismatch")
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left := "%s:%02d" % [str(a.get("character_id", "")), int(a.get("challenge_level", -1))]
		var right := "%s:%02d" % [str(b.get("character_id", "")), int(b.get("challenge_level", -1))]
		return left < right)
	return {"errors": _sorted_errors(errors), "cases": cases}

func _validate_role_report(report: Dictionary, character_id: String) -> Dictionary:
	var errors: Array = []
	if report.is_empty():
		_append_error(errors, "input_missing")
		return {"errors": _sorted_errors(errors), "cases": []}
	if not CHARACTER_STEP_PREFIX.has(character_id):
		_append_error(errors, "character_scope_mismatch")
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
	var selected_value = report.get("selected_candidate")
	var selected: Dictionary = selected_value if selected_value is Dictionary else {}
	if not _valid_candidate_identity(overlay):
		_append_error(errors, "input_missing")
	if selected.is_empty():
		_append_error(errors, "input_missing")
	elif not _valid_candidate_identity(selected) or not _candidate_identities_match(selected, overlay):
		_append_error(errors, "identity_mismatch")
	if _valid_candidate_identity(overlay) and CHARACTER_STEP_PREFIX.has(character_id):
		var candidate_id := str(overlay.get("candidate_id", ""))
		var prefix := str(CHARACTER_STEP_PREFIX[character_id])
		if candidate_id not in ["024-%s1" % prefix, "024-%s2" % prefix, "024-%s3" % prefix]:
			_append_error(errors, "identity_mismatch")
	if not _integer_equals(report.get("iterations_per_case"), 64):
		_append_error(errors, "required_iterations")

	var cases_value = report.get("cases")
	if not _integer_equals(report.get("case_count"), 4) or cases_value is not Array or (cases_value as Array).size() != 4:
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
		var case_character := str(case.get("character_id", "")) if case.get("character_id") is String else ""
		var challenge_level := _integer_or(case.get("challenge_level"), -1)
		var case_runs := _integer_or(case.get("runs"), -1)
		var case_wins := _integer_or(case.get("wins"), -1)
		if case_character != character_id:
			_append_error(errors, "character_scope_mismatch")
		if not _is_integer_number(case.get("challenge_level")) or not CHALLENGE_LEVELS.has(challenge_level) or seen.has(challenge_level):
			_append_error(errors, "case_matrix_mismatch")
		else:
			seen[challenge_level] = true
		if not _is_integer_number(case.get("runs")) or case_runs != 64 or not _is_integer_number(case.get("wins")):
			_append_error(errors, "required_iterations")
		if case_wins < 0 or case_wins > 64:
			_append_error(errors, "case_matrix_mismatch")
		if not _integer_equals(case.get("campaign_attribution_schema_version"), 1) or not _integer_equals(case.get("campaign_strategy_schema_version"), 1) or case.get("strategy_profile") != "competent-player-v3" or not _is_false_bool(case.get("strategy_profile_fallback")):
			_append_error(errors, "identity_mismatch")
		if case.get("candidate_diagnostics") != "attrition-v1" or case.get("attrition_by_layer") is not Array or case.get("attrition_by_encounter") is not Array:
			_append_error(errors, "input_missing")
		if typeof(case.get("attribution_gate_eligible")) != TYPE_BOOL or bool(case.get("attribution_gate_eligible")):
			_append_error(errors, "required_iterations")
		_validate_case_raw_inputs(case, case_runs, errors)
		cases.append(case)
	if seen.size() != 4:
		_append_error(errors, "case_matrix_mismatch")
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("challenge_level", -1)) < int(b.get("challenge_level", -1)))
	return {"errors": _sorted_errors(errors), "cases": cases}

func _validate_case_raw_inputs(case: Dictionary, case_runs: int, errors: Array) -> void:
	var attribution_value = case.get("chapter_attribution")
	var first_value = (attribution_value as Array)[0] if attribution_value is Array and not (attribution_value as Array).is_empty() else null
	if first_value is not Dictionary:
		_append_error(errors, "input_missing")
	else:
		var first: Dictionary = first_value
		var entry_runs = first.get("entry_runs")
		var completed_runs = first.get("completed_runs")
		if first.get("chapter_id") != "chapter_one" or not _is_integer_number(entry_runs) or not _is_integer_number(completed_runs):
			_append_error(errors, "input_missing")
		elif int(entry_runs) != case_runs or int(completed_runs) < 0 or int(completed_runs) > int(entry_runs):
			_append_error(errors, "input_missing")
	var concentration_value = case.get("failure_concentration")
	if concentration_value is not Dictionary:
		_append_error(errors, "input_missing")
	else:
		var concentration: Dictionary = concentration_value
		var losses := _integer_or(concentration.get("losses"), -1)
		var top_failures := _integer_or(concentration.get("top_encounter_failures"), -1)
		var wins := _integer_or(case.get("wins"), -1)
		if losses != case_runs - wins or top_failures < 0 or top_failures > losses or concentration.get("top_encounter_id") is not String:
			_append_error(errors, "input_missing")
	if not _is_number(case.get("avg_final_gold")) or not _is_number(case.get("avg_final_deck_size")):
		_append_error(errors, "input_missing")

func _raw_case_rows(cases: Array) -> Array:
	var rows: Array = []
	for case_value in cases:
		var case: Dictionary = case_value
		var runs := _integer_or(case.get("runs"), 0)
		var wins := _integer_or(case.get("wins"), 0)
		var concentration: Dictionary = case.get("failure_concentration", {}) if case.get("failure_concentration") is Dictionary else {}
		rows.append({
			"character_id": str(case.get("character_id", "")),
			"challenge_level": _integer_or(case.get("challenge_level"), -1),
			"runs": runs,
			"wins": wins,
			"first_act_entry_runs": _first_act_value(case, "entry_runs"),
			"first_act_completed": _first_act_value(case, "completed_runs"),
			"losses": _integer_or(concentration.get("losses"), 0),
			"top_encounter_id": str(concentration.get("top_encounter_id", "")),
			"top_encounter_failures": _integer_or(concentration.get("top_encounter_failures"), 0),
			"avg_final_gold": case.get("avg_final_gold", null),
			"avg_final_deck_size": case.get("avg_final_deck_size", null)
		})
	return rows

func _raw_challenge_rows(cases: Array) -> Array:
	var rows: Array = []
	for challenge_level in CHALLENGE_LEVELS:
		var runs := 0
		var wins := 0
		for case_value in cases:
			var case: Dictionary = case_value
			if int(case.get("challenge_level", -1)) == challenge_level:
				runs += _integer_or(case.get("runs"), 0)
				wins += _integer_or(case.get("wins"), 0)
		rows.append({"challenge_level": challenge_level, "runs": runs, "wins": wins})
	return rows

func _case_signature(case: Dictionary) -> Dictionary:
	var runs := _integer_or(case.get("runs"), 0)
	var wins := _integer_or(case.get("wins"), 0)
	var concentration: Dictionary = case.get("failure_concentration", {}) if case.get("failure_concentration") is Dictionary else {}
	return {
		"runs": runs,
		"wins": wins,
		"first_act_entry_runs": _first_act_value(case, "entry_runs"),
		"first_act_completed": _first_act_value(case, "completed_runs"),
		"losses": _integer_or(concentration.get("losses"), 0),
		"top_encounter_id": str(concentration.get("top_encounter_id", "")),
		"top_encounter_failures": _integer_or(concentration.get("top_encounter_failures"), 0),
		"avg_final_gold": case.get("avg_final_gold", null),
		"avg_final_deck_size": case.get("avg_final_deck_size", null)
	}

func _first_act_value(case: Dictionary, field: String) -> int:
	var attribution = case.get("chapter_attribution")
	if attribution is not Array or (attribution as Array).is_empty() or (attribution as Array)[0] is not Dictionary:
		return 0
	return _integer_or(((attribution as Array)[0] as Dictionary).get(field), 0)

func _valid_candidate_identity(identity: Dictionary) -> bool:
	if not _integer_equals(identity.get("schema_version"), 1) or identity.get("candidate_id") is not String or str(identity.get("candidate_id", "")).is_empty():
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
	if value is not String or str(value).length() != 64:
		return false
	for character in str(value):
		if not "0123456789abcdef".contains(character):
			return false
	return true

func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	var keys: Array = value.keys()
	keys.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	return keys == sorted_expected

func _verdict(pass_value: bool, eligible: bool, errors: Array, raw_totals: Dictionary) -> Dictionary:
	var normalized := _sorted_errors(errors)
	return {"eligible": eligible, "pass": pass_value and eligible, "failure_codes": normalized, "raw_totals": raw_totals}

func _append_error(errors: Array, code: String) -> void:
	if ERROR_ORDER.has(code) and not errors.has(code):
		errors.append(code)

func _sorted_errors(errors: Array) -> Array:
	var result: Array = []
	for code_value in errors:
		_append_error(result, str(code_value))
	result.sort_custom(func(a, b) -> bool: return ERROR_ORDER.find(a) < ERROR_ORDER.find(b))
	return result

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
