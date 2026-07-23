extends SceneTree

const DIGEST_PATH := "res://scripts/tools/BalanceEvidenceDigest.gd"
const IDENTITY_SHA := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_ac_024_04_valid_compact_digest()
	_test_ac_024_05_fail_closed_and_write()
	if not _failures.is_empty():
		push_error("Balance evidence digest test failed with %d assertion(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Balance evidence digest test passed.")
	quit(0)

func _test_ac_024_04_valid_compact_digest() -> void:
	_check(ResourceLoader.exists(DIGEST_PATH), "AC-024-04 evidence digest helper exists")
	if not ResourceLoader.exists(DIGEST_PATH):
		return
	var digest_script = load(DIGEST_PATH)
	_check(digest_script != null, "AC-024-04 evidence digest helper loads")
	if digest_script == null:
		return
	var helper = digest_script.new()
	for case_count in [4, 12]:
		var iterations := 64 if case_count == 4 else 128
		var report := _report(iterations, ["ember_exile"] if case_count == 4 else ["pyre_ascetic", "arc_tinker", "ember_exile"])
		var report_path := _write_report("valid-%d" % case_count, report)
		var gate_verdict := {
			"eligible": true,
			"pass": case_count == 12,
			"failure_codes": [] if case_count == 12 else ["direction_act1_gain_low"],
			"failures": ["ignored-extra"],
			"raw_totals": {"ignored": true},
		}
		var result: Dictionary = helper.build(report, gate_verdict, report_path)
		var context := "AC-024-04 %d-case" % case_count
		_check(bool(result.get("ok", false)), "%s valid report builds" % context)
		_check((result.get("errors", []) as Array).is_empty(), "%s build has no errors" % context)
		if not bool(result.get("ok", false)):
			continue
		var digest: Dictionary = result.get("digest", {})
		var digest_keys: Array = digest.keys()
		digest_keys.sort()
		_check(digest_keys == ["candidate_identity", "case_count", "case_rows", "gate_verdict", "iterations_per_case", "repeat_identical", "repeat_report_path", "repeat_report_sha256", "schema_version", "source_report_path", "source_report_sha256", "strategy_profile"], "%s has only frozen top-level fields" % context)
		_check(int(digest.get("schema_version", 0)) == 1, "%s keeps schema version one" % context)
		_check(str(digest.get("source_report_path", "")) == report_path, "%s keeps source report path" % context)
		_check(str(digest.get("source_report_sha256", "")) == _sha256_file(report_path), "%s hashes exact source report bytes" % context)
		_check(str(digest.get("repeat_report_path", "")).is_empty() and str(digest.get("repeat_report_sha256", "")).is_empty() and not bool(digest.get("repeat_identical", true)), "%s records absence of repeat explicitly" % context)
		_check(digest.get("candidate_identity", {}) == report.get("candidate_overlay", {}), "%s preserves exact candidate identity" % context)
		_check(str(digest.get("strategy_profile", "")) == "competent-player-v3", "%s preserves strategy profile" % context)
		_check(int(digest.get("iterations_per_case", 0)) == iterations and int(digest.get("case_count", 0)) == case_count, "%s preserves matrix dimensions" % context)
		_check(digest.get("gate_verdict", {}) == {"eligible": true, "pass": case_count == 12, "failure_codes": [] if case_count == 12 else ["direction_act1_gain_low"]}, "%s keeps only strict gate inputs" % context)
		var rows: Array = digest.get("case_rows", [])
		_check(rows.size() == case_count, "%s keeps every raw case row" % context)
		_check(_rows_are_sorted(rows), "%s sorts by character id then challenge" % context)
		if rows.is_empty():
			continue
		var first_row: Dictionary = rows[0]
		var expected_character := "ember_exile" if case_count == 4 else "arc_tinker"
		var offset := _character_offset(expected_character)
		var expected_losses := offset + 1
		_check(first_row == {
			"character_id": expected_character,
			"challenge_level": 0,
			"runs": iterations,
			"wins": iterations - expected_losses,
			"first_act_entry_runs": iterations,
			"first_act_completed": iterations - offset,
			"losses": expected_losses,
			"top_encounter_id": "encounter-%s-0" % expected_character,
			"top_encounter_failures": expected_losses / 2,
			"avg_final_gold": 120.5 + offset,
			"avg_final_deck_size": 16.25 + offset,
		}, "%s preserves raw first row fields exactly" % context)

func _test_ac_024_05_fail_closed_and_write() -> void:
	if not ResourceLoader.exists(DIGEST_PATH):
		_check(false, "AC-024-05 evidence digest helper exists")
		return
	var digest_script = load(DIGEST_PATH)
	var helper = digest_script.new() if digest_script != null else null
	_check(helper != null and helper.has_method("write_digest"), "AC-024-05 digest helper exposes write_digest")
	if helper == null:
		return
	var report := _report(64, ["ember_exile"])
	var report_path := _write_report("ac05-primary", report)
	var valid_gate := {"eligible": true, "pass": false, "failure_codes": ["direction_act1_gain_low"]}

	var invalid_identity: Dictionary = report.duplicate(true)
	invalid_identity["selected_candidate"]["candidate_id"] = "different-candidate"
	_assert_failure(helper.build(invalid_identity, valid_gate, _write_report("ac05-invalid-identity", invalid_identity)), ["identity_mismatch"], "AC-024-05 mismatched identity")

	var duplicate_case: Dictionary = report.duplicate(true)
	duplicate_case["cases"][3] = (duplicate_case["cases"][0] as Dictionary).duplicate(true)
	_assert_failure(helper.build(duplicate_case, valid_gate, _write_report("ac05-duplicate-case", duplicate_case)), ["case_matrix_mismatch"], "AC-024-05 duplicate case")
	var missing_case: Dictionary = report.duplicate(true)
	missing_case["cases"].pop_back()
	_assert_failure(helper.build(missing_case, valid_gate, _write_report("ac05-missing-case", missing_case)), ["case_matrix_mismatch"], "AC-024-05 missing case")
	var wrong_runs: Dictionary = report.duplicate(true)
	wrong_runs["cases"][0]["runs"] = 63
	_assert_failure(helper.build(wrong_runs, valid_gate, _write_report("ac05-wrong-runs", wrong_runs)), ["case_matrix_mismatch"], "AC-024-05 runs mismatch")
	var malformed_case: Dictionary = report.duplicate(true)
	malformed_case["cases"][0].erase("failure_concentration")
	_assert_failure(helper.build(malformed_case, valid_gate, _write_report("ac05-malformed-case", malformed_case)), ["input_missing"], "AC-024-05 malformed raw case")

	var invalid_gate := {"eligible": 1, "pass": false, "failure_codes": ["direction_act1_gain_low"]}
	_assert_failure(helper.build(report, invalid_gate, report_path), ["gate_invalid"], "AC-024-05 strict gate booleans")
	var invalid_gate_codes := {"eligible": true, "pass": false, "failure_codes": [123]}
	_assert_failure(helper.build(report, invalid_gate_codes, report_path), ["gate_invalid"], "AC-024-05 strict gate failure codes")
	var impossible_pass := {"eligible": false, "pass": true, "failure_codes": []}
	_assert_failure(helper.build(report, impossible_pass, report_path), ["gate_invalid"], "AC-024-05 pass requires eligible gate")
	var passing_with_failures := {"eligible": true, "pass": true, "failure_codes": ["direction_act1_gain_low"]}
	_assert_failure(helper.build(report, passing_with_failures, report_path), ["gate_invalid"], "AC-024-05 passing gate cannot keep failures")
	var duplicate_gate_codes := {"eligible": true, "pass": false, "failure_codes": ["direction_act1_gain_low", "direction_act1_gain_low"]}
	_assert_failure(helper.build(report, duplicate_gate_codes, report_path), ["gate_invalid"], "AC-024-05 gate failure codes are unique")

	var missing_report_path := "/tmp/ember024-evidence-missing-report.json"
	if FileAccess.file_exists(missing_report_path):
		DirAccess.remove_absolute(missing_report_path)
	_assert_failure(helper.build(report, valid_gate, missing_report_path), ["report_file_missing"], "AC-024-05 missing source report")
	var different_report := _report(64, ["arc_tinker"])
	var different_report_path := _write_report("ac05-different-source", different_report)
	_assert_failure(helper.build(report, valid_gate, different_report_path), ["identity_mismatch"], "AC-024-05 report Dictionary binds to source file")
	var invalid_json_path := _write_text("ac05-invalid-source", "{not-json")
	_assert_failure(helper.build(report, valid_gate, invalid_json_path), ["input_missing"], "AC-024-05 source file must be valid report JSON")

	var repeat_identical_path := _write_text("ac05-repeat-identical", FileAccess.get_file_as_string(report_path))
	var repeated: Dictionary = helper.build(report, valid_gate, report_path, repeat_identical_path)
	_check(bool(repeated.get("ok", false)), "AC-024-05 byte-identical repeat builds")
	if bool(repeated.get("ok", false)):
		var repeated_digest: Dictionary = repeated.get("digest", {})
		_check(bool(repeated_digest.get("repeat_identical", false)), "AC-024-05 identical repeat is explicit")
		_check(str(repeated_digest.get("repeat_report_path", "")) == repeat_identical_path, "AC-024-05 repeat path is preserved")
		_check(str(repeated_digest.get("repeat_report_sha256", "")) == _sha256_file(repeat_identical_path), "AC-024-05 repeat SHA hashes exact bytes")
	var repeat_mismatch_path := _write_text("ac05-repeat-mismatch", FileAccess.get_file_as_string(report_path) + "\n")
	_assert_failure(helper.build(report, valid_gate, report_path, repeat_mismatch_path), ["repeat_mismatch"], "AC-024-05 repeat byte mismatch")

	var combined_identity: Dictionary = report.duplicate(true)
	combined_identity["selected_candidate"]["candidate_id"] = "different-candidate"
	combined_identity["cases"][0]["runs"] = 63
	_assert_failure(
		helper.build(combined_identity, invalid_gate, missing_report_path, "/tmp/ember024-evidence-missing-repeat.json"),
		["identity_mismatch", "case_matrix_mismatch", "gate_invalid", "report_file_missing", "repeat_mismatch"],
		"AC-024-05 stable error ordering"
	)

	if not helper.has_method("write_digest"):
		return
	var output_path := "/tmp/ember024-evidence-digest.json"
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)
	var write_result: Dictionary = helper.write_digest(output_path, report, valid_gate, report_path, repeat_identical_path)
	_check(bool(write_result.get("ok", false)) and FileAccess.file_exists(output_path), "AC-024-05 valid digest writes JSON")
	if bool(write_result.get("ok", false)) and FileAccess.file_exists(output_path):
		_check(FileAccess.get_file_as_string(output_path) == JSON.stringify(write_result.get("digest", {})), "AC-024-05 written bytes equal returned digest serialization")
	var unwritable_path := "/tmp/ember024-evidence-output-directory"
	DirAccess.make_dir_recursive_absolute(unwritable_path)
	_assert_failure(helper.write_digest(unwritable_path, report, valid_gate, report_path), ["output_write_failed"], "AC-024-05 output I/O failure")

func _report(iterations: int, character_ids: Array) -> Dictionary:
	var cases: Array = []
	for character_id_value in character_ids:
		var character_id := str(character_id_value)
		var offset: int = _character_offset(character_id)
		for challenge_level_value in [3, 2, 1, 0]:
			var challenge_level := int(challenge_level_value)
			var losses: int = offset + challenge_level + 1
			cases.append({
				"character_id": character_id,
				"challenge_level": challenge_level,
				"runs": iterations,
				"wins": iterations - losses,
				"chapter_attribution": [{"chapter_id": "chapter_one", "entry_runs": iterations, "completed_runs": iterations - offset - challenge_level * 2}],
				"failure_concentration": {"losses": losses, "top_encounter_id": "encounter-%s-%d" % [character_id, challenge_level], "top_encounter_failures": losses / 2},
				"avg_final_gold": 120.5 + offset + challenge_level,
				"avg_final_deck_size": 16.25 + offset + challenge_level * 0.1,
			})
	var identity := {"schema_version": 1, "candidate_id": "candidate-%d" % iterations, "sha256": IDENTITY_SHA, "applied_fields": ["player.characters.arc_tinker.starting_momentum"]}
	return {
		"version": 1,
		"campaign_attribution_schema_version": 1,
		"campaign_strategy_schema_version": 1,
		"simulation_model": "campaign_route_heuristic_ai",
		"strategy_profile": "competent-player-v3",
		"strategy_profile_fallback": false,
		"seed_model": "paired_by_iteration",
		"max_turns_per_combat": 80,
		"candidate_diagnostics": "attrition-v1",
		"candidate_overlay": identity.duplicate(true),
		"selected_candidate": identity.duplicate(true),
		"iterations_per_case": iterations,
		"case_count": cases.size(),
		"cases": cases,
	}

func _character_offset(character_id: String) -> int:
	return {"ember_exile": 0, "arc_tinker": 1, "pyre_ascetic": 2}.get(character_id, 9)

func _rows_are_sorted(rows: Array) -> bool:
	for index in range(1, rows.size()):
		var previous: Dictionary = rows[index - 1]
		var current: Dictionary = rows[index]
		var previous_key := "%s:%02d" % [str(previous.get("character_id", "")), int(previous.get("challenge_level", -1))]
		var current_key := "%s:%02d" % [str(current.get("character_id", "")), int(current.get("challenge_level", -1))]
		if previous_key > current_key:
			return false
	return true

func _write_report(name: String, report: Dictionary) -> String:
	return _write_text(name, JSON.stringify(report))

func _write_text(name: String, content: String) -> String:
	var path := "/tmp/ember024-evidence-%s.json" % name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "AC-024-04 source report can be written: %s" % name)
		return path
	file.store_string(content)
	file.close()
	return path

func _sha256_file(path: String) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)

func _assert_failure(result: Dictionary, expected_errors: Array, context: String) -> void:
	_check(not bool(result.get("ok", true)), "%s fails closed" % context)
	_check(result.get("errors", []) == expected_errors, "%s returns stable errors" % context)
	_check((result.get("digest", {}) as Dictionary).is_empty(), "%s returns no success digest" % context)
