extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")

const REPORT_PATH := "/tmp/embercircuit_balance_test_report.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulator = BalanceSimulatorScript.new()
	var options := {
		"iterations": 3,
		"max_turns": 30,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"encounter_ids": ["intro_patrol", "chapter_one_boss"]
	}
	var report: Dictionary = simulator.run_suite(options)
	_check(int(report.get("case_count", 0)) == 2, "balance simulator creates one case per encounter")
	_check(int(report.get("iterations_per_case", 0)) == 3, "balance simulator records iteration count")
	_check(str(report.get("simulation_model", "")) == "single_encounter_heuristic_ai", "balance simulator reports model")
	var cases: Array = report.get("cases", [])
	_check(cases.size() == 2, "balance simulator returns case rows")
	for case in cases:
		var case_dict: Dictionary = case
		_check(str(case_dict.get("character_id", "")) == "ember_exile", "case records character")
		_check(int(case_dict.get("runs", 0)) == 3, "case records run count")
		_check(float(case_dict.get("win_rate", -1.0)) >= 0.0 and float(case_dict.get("win_rate", -1.0)) <= 1.0, "case win rate is normalized")
		_check(float(case_dict.get("loss_rate", -1.0)) >= 0.0 and float(case_dict.get("loss_rate", -1.0)) <= 1.0, "case loss rate is normalized")
		_check(float(case_dict.get("avg_turns", 0.0)) > 0.0, "case records average turns")
		_check(_valid_risk_flag(str(case_dict.get("risk_flag", ""))), "case risk flag is recognized")

	var repeat_report: Dictionary = simulator.run_suite(options)
	_check(JSON.stringify(report.get("cases", [])) == JSON.stringify(repeat_report.get("cases", [])), "balance simulator is deterministic for the same options")

	var error: Error = simulator.save_report(report, REPORT_PATH)
	_check(error == OK and FileAccess.file_exists(REPORT_PATH), "balance simulator can save JSON report")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(REPORT_PATH))
	_check(saved is Dictionary and int(saved.get("case_count", 0)) == 2, "saved balance report is valid JSON")

	var campaign_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 2,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0]
	})
	_check(str(campaign_report.get("simulation_model", "")) == "campaign_route_heuristic_ai", "campaign simulator reports model")
	_check(int(campaign_report.get("case_count", 0)) == 1, "campaign simulator creates one case per character and challenge")
	var campaign_cases: Array = campaign_report.get("cases", [])
	_check(campaign_cases.size() == 1, "campaign simulator returns case rows")
	var campaign_case: Dictionary = campaign_cases[0]
	_check(str(campaign_case.get("character_id", "")) == "ember_exile", "campaign case records character")
	_check(int(campaign_case.get("runs", 0)) == 2, "campaign case records run count")
	_check(float(campaign_case.get("win_rate", -1.0)) >= 0.0 and float(campaign_case.get("win_rate", -1.0)) <= 1.0, "campaign win rate is normalized")
	_check(float(campaign_case.get("avg_chapters_completed", -1.0)) >= 0.0 and float(campaign_case.get("avg_chapters_completed", -1.0)) <= 3.0, "campaign records chapter progress")
	_check(float(campaign_case.get("avg_nodes_completed", -1.0)) >= 0.0, "campaign records node progress")
	_check(campaign_case.has("failure_reasons") and campaign_case.has("failure_points"), "campaign records failure breakdowns")
	_check(_valid_campaign_risk_flag(str(campaign_case.get("risk_flag", ""))), "campaign risk flag is recognized")

	print("Balance simulator smoke test passed.")
	quit(0)

func _valid_risk_flag(flag: String) -> bool:
	return [
		"ok",
		"timeout_check",
		"normal_too_lethal",
		"elite_too_lethal",
		"boss_too_lethal",
		"normal_too_slow",
		"elite_too_slow",
		"boss_too_slow"
	].has(flag)

func _valid_campaign_risk_flag(flag: String) -> bool:
	return [
		"ok",
		"campaign_fails_chapter_one",
		"campaign_fails_before_finale",
		"campaign_low_win_rate",
		"campaign_too_easy"
	].has(flag)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
