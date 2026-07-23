class_name BalanceEvidenceDigest
extends RefCounted

const SCHEMA_VERSION := 1
const CHARACTER_IDS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const CHALLENGE_LEVELS := [0, 1, 2, 3]
const ERROR_ORDER := [
	"input_missing",
	"identity_mismatch",
	"case_matrix_mismatch",
	"gate_invalid",
	"report_file_missing",
	"repeat_mismatch",
	"output_write_failed",
]

func build(report: Dictionary, gate_verdict: Dictionary, report_path: String, repeat_path: String = "") -> Dictionary:
	var errors: Array = []
	_validate_report(report, errors)
	_validate_gate(gate_verdict, errors)
	var report_exists := FileAccess.file_exists(report_path)
	if not report_exists:
		_append_error(errors, "report_file_missing")
	else:
		_validate_source_binding(report, report_path, errors)
	var repeat_identical := false
	var repeat_sha := ""
	if not repeat_path.is_empty():
		if not report_exists or not FileAccess.file_exists(repeat_path):
			_append_error(errors, "repeat_mismatch")
		else:
			var report_bytes := FileAccess.get_file_as_bytes(report_path)
			var repeat_bytes := FileAccess.get_file_as_bytes(repeat_path)
			repeat_identical = report_bytes == repeat_bytes
			if not repeat_identical:
				_append_error(errors, "repeat_mismatch")
			else:
				repeat_sha = _sha256_bytes(repeat_bytes)
	if not errors.is_empty():
		return _rejected(errors)

	var rows := _build_rows(report.get("cases", []))
	var digest := {
		"schema_version": SCHEMA_VERSION,
		"source_report_path": report_path,
		"source_report_sha256": _sha256_file(report_path),
		"repeat_report_path": repeat_path,
		"repeat_report_sha256": repeat_sha,
		"repeat_identical": repeat_identical,
		"candidate_identity": (report.get("candidate_overlay", {}) as Dictionary).duplicate(true),
		"strategy_profile": report.get("strategy_profile"),
		"iterations_per_case": report.get("iterations_per_case"),
		"case_count": report.get("case_count"),
		"case_rows": rows,
		"gate_verdict": {
			"eligible": gate_verdict.get("eligible"),
			"pass": gate_verdict.get("pass"),
			"failure_codes": (gate_verdict.get("failure_codes", []) as Array).duplicate(true),
		},
	}
	return {"ok": true, "digest": digest, "errors": []}

func write_digest(output_path: String, report: Dictionary, gate_verdict: Dictionary, report_path: String, repeat_path: String = "") -> Dictionary:
	var result := build(report, gate_verdict, report_path, repeat_path)
	if not bool(result.get("ok", false)):
		return result
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return _rejected(["output_write_failed"])
	file.store_string(JSON.stringify(result.get("digest", {})))
	file.flush()
	if file.get_error() != OK:
		file.close()
		return _rejected(["output_write_failed"])
	file.close()
	return result

func _validate_report(report: Dictionary, errors: Array) -> void:
	if report.is_empty():
		_append_error(errors, "input_missing")
		return
	if not _valid_report_identity(report):
		_append_error(errors, "identity_mismatch")
	var overlay_value = report.get("candidate_overlay")
	var selected_value = report.get("selected_candidate")
	var overlay: Dictionary = overlay_value if overlay_value is Dictionary else {}
	var selected: Dictionary = selected_value if selected_value is Dictionary else {}
	if not _valid_candidate_identity(overlay) or not _valid_candidate_identity(selected) or overlay != selected:
		_append_error(errors, "identity_mismatch")

	var iterations := _integer_or(report.get("iterations_per_case"), -1)
	var case_count := _integer_or(report.get("case_count"), -1)
	var cases_value = report.get("cases")
	if iterations not in [64, 128, 256] or case_count not in [4, 12] or cases_value is not Array or (cases_value as Array).size() != case_count:
		_append_error(errors, "case_matrix_mismatch")
	if cases_value is not Array:
		return

	var seen: Dictionary = {}
	var seen_characters: Dictionary = {}
	for case_value in cases_value:
		if case_value is not Dictionary:
			_append_error(errors, "input_missing")
			continue
		var case: Dictionary = case_value
		var character_value = case.get("character_id")
		var character_id := str(character_value) if character_value is String else ""
		var challenge_level := _integer_or(case.get("challenge_level"), -1)
		var key := "%s:%d" % [character_id, challenge_level]
		if not CHARACTER_IDS.has(character_id) or not CHALLENGE_LEVELS.has(challenge_level) or seen.has(key):
			_append_error(errors, "case_matrix_mismatch")
		else:
			seen[key] = true
			seen_characters[character_id] = true
		_validate_case(case, iterations, errors)
	if case_count == 4:
		if seen.size() != 4 or seen_characters.size() != 1:
			_append_error(errors, "case_matrix_mismatch")
		else:
			var only_character := str(seen_characters.keys()[0])
			for challenge_level in CHALLENGE_LEVELS:
				if not seen.has("%s:%d" % [only_character, challenge_level]):
					_append_error(errors, "case_matrix_mismatch")
	elif case_count == 12:
		if seen.size() != 12 or seen_characters.size() != CHARACTER_IDS.size():
			_append_error(errors, "case_matrix_mismatch")
		else:
			for character_id in CHARACTER_IDS:
				for challenge_level in CHALLENGE_LEVELS:
					if not seen.has("%s:%d" % [character_id, challenge_level]):
						_append_error(errors, "case_matrix_mismatch")

func _valid_report_identity(report: Dictionary) -> bool:
	return (
		_integer_or(report.get("version"), -1) == 1
		and _integer_or(report.get("campaign_attribution_schema_version"), -1) == 1
		and _integer_or(report.get("campaign_strategy_schema_version"), -1) == 1
		and report.get("simulation_model") == "campaign_route_heuristic_ai"
		and report.get("strategy_profile") == "competent-player-v3"
		and typeof(report.get("strategy_profile_fallback")) == TYPE_BOOL
		and not bool(report.get("strategy_profile_fallback"))
		and report.get("seed_model") == "paired_by_iteration"
		and _integer_or(report.get("max_turns_per_combat"), -1) == 80
		and report.get("candidate_diagnostics") == "attrition-v1"
	)

func _valid_candidate_identity(identity: Dictionary) -> bool:
	if _integer_or(identity.get("schema_version"), -1) != 1:
		return false
	if identity.get("candidate_id") is not String or str(identity.get("candidate_id", "")).is_empty():
		return false
	if not _is_lower_hex_sha256(identity.get("sha256")):
		return false
	var fields = identity.get("applied_fields")
	if fields is not Array or (fields as Array).is_empty():
		return false
	for field_value in fields:
		if field_value is not String or str(field_value).is_empty():
			return false
	return true

func _validate_case(case: Dictionary, iterations: int, errors: Array) -> void:
	var runs := _integer_or(case.get("runs"), -1)
	var wins := _integer_or(case.get("wins"), -1)
	if runs != iterations or wins < 0 or wins > iterations:
		_append_error(errors, "case_matrix_mismatch")
	var attribution_value = case.get("chapter_attribution")
	var first_act = (attribution_value as Array)[0] if attribution_value is Array and not (attribution_value as Array).is_empty() else null
	if first_act is not Dictionary:
		_append_error(errors, "input_missing")
	else:
		var entry_runs := _integer_or((first_act as Dictionary).get("entry_runs"), -1)
		var completed_runs := _integer_or((first_act as Dictionary).get("completed_runs"), -1)
		if str((first_act as Dictionary).get("chapter_id", "")) != "chapter_one" or entry_runs != iterations or completed_runs < 0 or completed_runs > iterations:
			_append_error(errors, "input_missing")
	var concentration_value = case.get("failure_concentration")
	if concentration_value is not Dictionary:
		_append_error(errors, "input_missing")
	else:
		var concentration: Dictionary = concentration_value
		var losses := _integer_or(concentration.get("losses"), -1)
		var top_failures := _integer_or(concentration.get("top_encounter_failures"), -1)
		if losses != iterations - wins or concentration.get("top_encounter_id") is not String or top_failures < 0 or top_failures > losses:
			_append_error(errors, "input_missing")
	if not _is_number(case.get("avg_final_gold")) or not _is_number(case.get("avg_final_deck_size")):
		_append_error(errors, "input_missing")

func _validate_gate(gate_verdict: Dictionary, errors: Array) -> void:
	var eligible_value = gate_verdict.get("eligible")
	var pass_value = gate_verdict.get("pass")
	var gate_types_valid := typeof(eligible_value) == TYPE_BOOL and typeof(pass_value) == TYPE_BOOL
	if not gate_types_valid:
		_append_error(errors, "gate_invalid")
	var codes = gate_verdict.get("failure_codes")
	if codes is not Array:
		_append_error(errors, "gate_invalid")
		return
	var seen_codes: Dictionary = {}
	for code_value in codes:
		var code := str(code_value) if code_value is String else ""
		if code.is_empty() or seen_codes.has(code):
			_append_error(errors, "gate_invalid")
		else:
			seen_codes[code] = true
	if gate_types_valid and bool(pass_value) != (bool(eligible_value) and (codes as Array).is_empty()):
		_append_error(errors, "gate_invalid")

func _validate_source_binding(report: Dictionary, report_path: String, errors: Array) -> void:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(report_path)) != OK or parser.data is not Dictionary:
		_append_error(errors, "input_missing")
		return
	var normalized_report = JSON.parse_string(JSON.stringify(report))
	if normalized_report is not Dictionary or parser.data != normalized_report:
		_append_error(errors, "identity_mismatch")

func _build_rows(cases_value) -> Array:
	var rows: Array = []
	for case_value in cases_value:
		var case: Dictionary = case_value
		var chapter_attribution: Array = case.get("chapter_attribution", [])
		var first_act: Dictionary = chapter_attribution[0]
		var concentration: Dictionary = case.get("failure_concentration", {})
		rows.append({
			"character_id": case.get("character_id"),
			"challenge_level": case.get("challenge_level"),
			"runs": case.get("runs"),
			"wins": case.get("wins"),
			"first_act_entry_runs": first_act.get("entry_runs"),
			"first_act_completed": first_act.get("completed_runs"),
			"losses": concentration.get("losses"),
			"top_encounter_id": concentration.get("top_encounter_id"),
			"top_encounter_failures": concentration.get("top_encounter_failures"),
			"avg_final_gold": case.get("avg_final_gold"),
			"avg_final_deck_size": case.get("avg_final_deck_size"),
		})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_character := str(left.get("character_id", ""))
		var right_character := str(right.get("character_id", ""))
		if left_character == right_character:
			return int(left.get("challenge_level", -1)) < int(right.get("challenge_level", -1))
		return left_character < right_character
	)
	return rows

func _sha256_file(path: String) -> String:
	return _sha256_bytes(FileAccess.get_file_as_bytes(path))

func _sha256_bytes(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if not bytes.is_empty():
		context.update(bytes)
	return context.finish().hex_encode()

func _is_lower_hex_sha256(value) -> bool:
	if value is not String or str(value).length() != 64:
		return false
	for character in str(value):
		if not "0123456789abcdef".contains(character):
			return false
	return true

func _is_number(value) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]

func _integer_or(value, fallback: int) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT and float(value) == floor(float(value)):
		return int(value)
	return fallback

func _append_error(errors: Array, error_code: String) -> void:
	if ERROR_ORDER.has(error_code) and not errors.has(error_code):
		errors.append(error_code)
		errors.sort_custom(func(left, right) -> bool: return ERROR_ORDER.find(left) < ERROR_ORDER.find(right))

func _rejected(errors: Array) -> Dictionary:
	return {"ok": false, "digest": {}, "errors": errors.duplicate()}
