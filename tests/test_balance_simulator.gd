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

	var chain_state := {"completed_event_ids": {}, "gold": 50, "hp": 50, "max_hp": 72, "deck_ids": [], "relic_ids": [], "potion_ids": [], "character_id": "ember_exile"}
	var chapter_two_events: Array = simulator.map_generation_data.get("chapter_two", {}).get("event_pool", [])
	var chain_pool_before: Array = simulator._filtered_event_pool_for_character(chapter_two_events, "ember_exile", chain_state)
	_check(not chain_pool_before.has("calibrator_return"), "balance simulator hides chain follow-up before prerequisite")
	simulator._apply_campaign_event_effect(chain_state, {"type": "lose_gold", "amount": 25})
	simulator._apply_campaign_event_effect(chain_state, {"type": "complete_event", "event_id": "mute_calibrator"})
	_check(int(chain_state.get("gold", 0)) == 25 and bool(chain_state.get("completed_event_ids", {}).get("mute_calibrator", false)), "balance simulator applies chain cost and completion flag")
	var chain_pool_after: Array = simulator._filtered_event_pool_for_character(chapter_two_events, "ember_exile", chain_state)
	_check(chain_pool_after.has("calibrator_return"), "balance simulator exposes chain follow-up after prerequisite")
	var chain_graph: Dictionary = simulator._generate_chapter_graph("chapter_two", 37, "ember_exile", chain_state)
	_check(_graph_has_event(chain_graph, "calibrator_return"), "balance simulator chapter map places the unlocked guaranteed follow-up")
	var treasure_state: Dictionary = chain_state.duplicate(true)
	var treasure_gold_before: int = int(treasure_state.get("gold", 0))
	var treasure_result: Dictionary = simulator._resolve_campaign_node(treasure_state, {"id": "test_treasure", "type": "treasure"}, "chapter_one", 30, 19)
	_check(bool(treasure_result.get("completed", false)), "balance simulator resolves treasure nodes")
	_check(int(treasure_state.get("gold", 0)) > treasure_gold_before and int(treasure_state.get("treasures_seen", 0)) == 1, "balance simulator treasure grants gold and records the visit")
	_check(simulator._campaign_node_score(treasure_state, {"type": "treasure"}) > simulator._campaign_node_score(treasure_state, {"type": "combat"}), "campaign route AI values risk-free treasure above normal combat")
	var mastery_deck: Array = ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "ember_strike", "pressure_probe", "ash_guard", "ash_guard", "ash_guard", "ash_guard"]
	_check(simulator._campaign_mastery_requirements_met(mastery_deck, {"min_type_count": {"attack": 6}}), "campaign simulator evaluates deck mastery type thresholds")
	_check(simulator._choose_campaign_deck_mastery(mastery_deck) == "offense_forging", "campaign simulator chooses an eligible deck mastery after elite victory")
	var modifier_sources: Array = simulator._campaign_modifier_sources({"skill_book_id": "steel_manual", "deck_mastery_id": "offense_forging"})
	_check(modifier_sources.size() == 2, "campaign simulator passes skill book and deck mastery into combat")

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
	_check(campaign_case.has("failure_node_types") and campaign_case.has("failure_encounters"), "campaign records failure node types and encounter ids")
	_check(_valid_campaign_risk_flag(str(campaign_case.get("risk_flag", ""))), "campaign risk flag is recognized")
	var campaign_samples: Array = campaign_case.get("sample_runs", [])
	_check(not campaign_samples.is_empty() and str(campaign_samples[0].get("skill_book_id", "")) == "steel_manual", "campaign reports the active default skill book")

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

func _graph_has_event(graph: Dictionary, event_id: String) -> bool:
	for layer in graph.get("layers", []):
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			if str(node_dict.get("type", "")) == "event" and str(node_dict.get("event_id", "")) == event_id:
				return true
	return false

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
