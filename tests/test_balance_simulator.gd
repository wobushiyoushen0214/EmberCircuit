extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")

const REPORT_PATH := "/tmp/embercircuit_balance_test_report.json"

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulator = BalanceSimulatorScript.new()
	var pressure_card := {"target": "enemy", "type": "attack"}
	var pressure_effect := {"type": "damage", "amount": 9, "bonus_if_momentum_at_least": 3, "bonus": 5}
	var low_pressure_combat := {"player": {"momentum": 2, "statuses": {}}}
	var high_pressure_combat := {"player": {"momentum": 3, "statuses": {}}}
	_check(simulator._estimate_damage_amount(low_pressure_combat, pressure_card, pressure_effect) == 9, "balance AI keeps base damage below the momentum threshold")
	_check(simulator._estimate_damage_amount(high_pressure_combat, pressure_card, pressure_effect) == 14, "balance AI values conditional damage at the momentum threshold")
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
	_check(str(report.get("strategy_profile", "")) == "current-greedy", "single encounter report declares the current greedy strategy baseline")
	var cases: Array = report.get("cases", [])
	_check(cases.size() == 2, "balance simulator returns case rows")
	for case in cases:
		var case_dict: Dictionary = case
		_check(str(case_dict.get("character_id", "")) == "ember_exile", "case records character")
		_check(int(case_dict.get("runs", 0)) == 3, "case records run count")
		_check(float(case_dict.get("win_rate", -1.0)) >= 0.0 and float(case_dict.get("win_rate", -1.0)) <= 1.0, "case win rate is normalized")
		_check(float(case_dict.get("loss_rate", -1.0)) >= 0.0 and float(case_dict.get("loss_rate", -1.0)) <= 1.0, "case loss rate is normalized")
		_check(float(case_dict.get("avg_turns", 0.0)) > 0.0, "case records average turns")
		_check(str(case_dict.get("chapter_id", "")) == "chapter_one", "single encounter case records its chapter")
		_check(str(case_dict.get("loadout_profile", "")) == "starter_deck_relics", "single encounter case declares its starter loadout")
		_check(str(case_dict.get("strategy_profile", "")) == "current-greedy", "single encounter case declares the current greedy strategy")
		_check(int(case_dict.get("pressure_contract_version", 0)) == 1, "single encounter case declares pressure schema version one")
		_check(not bool(case_dict.get("pressure_gate_eligible", true)), "three-run cases remain diagnostic-only")
		for field in ["zero_damage_win_count", "perfect_win_rate", "hp_loss_p50", "hp_loss_p90", "turn_sample_count", "turns_p50", "turns_p90", "cards_played_per_turn", "expected_turns_min", "expected_turns_max", "risk_flags"]:
			_check(case_dict.has(field), "single encounter case exposes pressure field %s" % field)
		_check(int(case_dict.get("zero_damage_win_count", -1)) >= 0 and float(case_dict.get("perfect_win_rate", -1.0)) >= 0.0, "single encounter case reports zero-damage wins and perfect rate")
		_check(float(case_dict.get("hp_loss_p50", -1.0)) >= 0.0 and float(case_dict.get("hp_loss_p90", -1.0)) >= float(case_dict.get("hp_loss_p50", -1.0)), "single encounter case reports ordered HP-loss percentiles")
		_check(int(case_dict.get("turn_sample_count", -1)) == int(case_dict.get("wins", 0)), "single encounter turn samples include wins only")
		_check(float(case_dict.get("turns_p90", -1.0)) >= float(case_dict.get("turns_p50", -1.0)), "single encounter case reports ordered winning-turn percentiles")
		_check(float(case_dict.get("cards_played_per_turn", -1.0)) >= 0.0, "single encounter case reports cards per turn")
		var expected_turns: Array = [8, 12] if str(case_dict.get("encounter_tier", "")) == "boss" else [3, 6]
		_check(int(case_dict.get("expected_turns_min", 0)) == int(expected_turns[0]) and int(case_dict.get("expected_turns_max", 0)) == int(expected_turns[1]), "single encounter case binds configured expected turns")
		var risk_flags: Array = case_dict.get("risk_flags", [])
		_check(str(case_dict.get("risk_flag", "")) == (str(risk_flags[0]) if not risk_flags.is_empty() else "ok"), "legacy risk flag matches the first composite pressure risk")
		_check(not risk_flags.has("%s_too_easy" % str(case_dict.get("encounter_tier", "normal"))), "diagnostic-only cases cannot produce a tier too-easy risk")
		var case_modifiers: Dictionary = case_dict.get("challenge_modifiers", {})
		_check(is_equal_approx(float(case_modifiers.get("enemy_hp_multiplier", 0.0)), 1.0) and is_equal_approx(float(case_modifiers.get("boss_hp_multiplier", 0.0)), 0.96), "single encounter report snapshots complete challenge modifiers")
		_check(_valid_risk_flag(str(case_dict.get("risk_flag", ""))), "case risk flag is recognized")

	var repeat_report: Dictionary = simulator.run_suite(options)
	_check(JSON.stringify(report.get("cases", [])) == JSON.stringify(repeat_report.get("cases", [])), "balance simulator is deterministic for the same options")

	var intro_pressure_report: Dictionary = simulator.run_suite({
		"iterations": 64,
		"max_turns": 30,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"encounter_ids": ["intro_patrol"],
	})
	var intro_pressure_case: Dictionary = (intro_pressure_report.get("cases", []) as Array)[0]
	_check(bool(intro_pressure_case.get("pressure_gate_eligible", false)), "64 intro seeds satisfy the pressure evidence gate")
	_check(str(intro_pressure_case.get("risk_flag", "")) == "normal_too_easy", "Ember intro patrol is primarily classified as normal too easy")
	var intro_risk_flags: Array = intro_pressure_case.get("risk_flags", [])
	_check(not intro_risk_flags.is_empty() and str(intro_risk_flags[0]) == "normal_too_easy", "Ember intro composite risks preserve too-easy priority")

	var boss_pressure_report: Dictionary = simulator.run_suite({
		"iterations": 64,
		"max_turns": 30,
		"character_ids": ["ember_exile", "arc_tinker", "pyre_ascetic"],
		"challenge_levels": [0],
		"encounter_ids": ["chapter_one_boss"],
	})
	_check(int(boss_pressure_report.get("case_count", 0)) == 3, "boss pressure fixture covers all three starter loadouts")
	for boss_case_value in boss_pressure_report.get("cases", []):
		var boss_case: Dictionary = boss_case_value
		_check(bool(boss_case.get("pressure_gate_eligible", false)), "64 boss seeds satisfy the pressure evidence gate: %s" % str(boss_case.get("character_id", "")))
		_check(str(boss_case.get("risk_flag", "")) == "boss_too_easy", "starter-only chapter one boss is primarily too easy: %s" % str(boss_case.get("character_id", "")))
		var boss_risk_flags: Array = boss_case.get("risk_flags", [])
		_check(not boss_risk_flags.is_empty() and str(boss_risk_flags[0]) == "boss_too_easy", "boss composite risks preserve too-easy priority: %s" % str(boss_case.get("character_id", "")))

	var chain_state := {"completed_event_ids": {}, "gold": 50, "hp": 50, "max_hp": 72, "deck_ids": [], "relic_ids": [], "potion_ids": [], "character_id": "ember_exile"}
	var chapter_two_events: Array = simulator.map_generation_data.get("chapter_two", {}).get("event_pool", [])
	var chain_pool_before: Array = simulator._filtered_event_pool_for_character(chapter_two_events, "ember_exile", chain_state)
	_check(not chain_pool_before.has("calibrator_return"), "balance simulator hides chain follow-up before prerequisite")
	simulator._apply_campaign_event_effect(chain_state, {"type": "lose_gold", "amount": 25})
	simulator._apply_campaign_event_effect(chain_state, {"type": "complete_event", "event_id": "mute_calibrator"})
	_check(int(chain_state.get("gold", 0)) == 25 and bool(chain_state.get("completed_event_ids", {}).get("mute_calibrator", false)), "balance simulator applies chain cost and completion flag")
	var chain_pool_after: Array = simulator._filtered_event_pool_for_character(chapter_two_events, "ember_exile", chain_state)
	_check(chain_pool_after.has("calibrator_return"), "balance simulator exposes chain follow-up after prerequisite")
	var removal_state := {
		"character_id": "ember_exile",
		"deck_ids": ["ember_strike+", "ash_guard", "ignition+", "smelt_plating"],
		"cards_removed": 0,
		"cards_removed_ids": [],
		"card_removal_counts_by_id": {},
	}
	simulator._apply_campaign_event_effect(removal_state, {"type": "remove_first_non_starter_card"})
	_check(removal_state.get("deck_ids", []) == ["ember_strike+", "ash_guard", "smelt_plating"], "campaign event removes the first non-starter card and preserves upgraded starters")
	_check(int(removal_state.get("card_removal_counts_by_id", {}).get("ignition", 0)) == 1, "campaign event removal telemetry normalizes an upgraded card id")
	var starter_only_state := {"character_id": "ember_exile", "deck_ids": ["ember_strike+", "ash_guard"]}
	simulator._apply_campaign_event_effect(starter_only_state, {"type": "remove_first_non_starter_card"})
	_check(starter_only_state.get("deck_ids", []) == ["ember_strike+", "ash_guard"], "campaign event does not remove a starter when no non-starter card exists")
	_check(int(simulator.economy_data.get("potion_reward", {}).get("combat_drop_count", -1)) == 1, "campaign potion reward count matches the real reward configuration")
	var chain_graph: Dictionary = simulator._generate_chapter_graph("chapter_two", 37, "ember_exile", chain_state)
	_check(_graph_has_event(chain_graph, "calibrator_return"), "balance simulator chapter map places the unlocked guaranteed follow-up")
	var treasure_state: Dictionary = chain_state.duplicate(true)
	var treasure_gold_before: int = int(treasure_state.get("gold", 0))
	var treasure_result: Dictionary = simulator._resolve_campaign_node(treasure_state, {"id": "test_treasure", "type": "treasure"}, "chapter_one", 30, 19)
	_check(bool(treasure_result.get("completed", false)), "balance simulator resolves treasure nodes")
	_check(int(treasure_state.get("gold", 0)) > treasure_gold_before and int(treasure_state.get("treasures_seen", 0)) == 1, "balance simulator treasure grants gold and records the visit")
	_check(simulator._campaign_node_score(treasure_state, {"type": "treasure"}) > simulator._campaign_node_score(treasure_state, {"type": "combat"}), "campaign route AI values risk-free treasure above normal combat")
	var early_route_state := {"hp": 70, "max_hp": 70, "relic_ids": ["ember_bottle", "cracked_charm"]}
	var transitional_route_state := {"hp": 70, "max_hp": 70, "relic_ids": ["ember_bottle", "cracked_charm", "counter_spring"]}
	var mature_route_state := {"hp": 70, "max_hp": 70, "relic_ids": ["ember_bottle", "cracked_charm", "counter_spring", "iron_heart"]}
	_check(simulator._campaign_node_score(early_route_state, {"type": "elite"}) < simulator._campaign_node_score(early_route_state, {"type": "combat"}), "campaign route AI avoids optional elites before the build matures")
	_check(simulator._campaign_node_score(mature_route_state, {"type": "elite"}) > simulator._campaign_node_score(mature_route_state, {"type": "combat"}), "campaign route AI pursues elite rewards after the build matures")
	var lookahead_graph := {
		"layers": [
			[{"id": "treasure_path", "type": "treasure"}, {"id": "safe_path", "type": "combat"}],
			[{"id": "forced_elite", "type": "elite"}, {"id": "safe_event", "type": "event"}],
		],
		"edges": [
			{"from": "treasure_path", "to": "forced_elite"},
			{"from": "safe_path", "to": "safe_event"},
		],
	}
	_check(simulator._choose_next_campaign_node(early_route_state, lookahead_graph.get("layers", [])[0], lookahead_graph) == "safe_path", "campaign route lookahead rejects a tempting reward that forces an immature elite fight")
	_check(simulator._choose_next_campaign_node(transitional_route_state, lookahead_graph.get("layers", [])[0], lookahead_graph) == "treasure_path", "campaign route lookahead evaluates an elite after applying the treasure relic")
	_check(simulator._choose_next_campaign_node(mature_route_state, lookahead_graph.get("layers", [])[0], lookahead_graph) == "treasure_path", "campaign route lookahead takes the elite reward line after the build matures")
	_check(simulator._campaign_encounter_allows_potion_reward(simulator._encounter_config("intro_patrol")), "normal combat permits potion rewards")
	_check(not simulator._campaign_encounter_allows_potion_reward(simulator._encounter_config("chapter_three_boss")), "final boss without card rewards cannot grant a campaign potion")
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
	_check(str(campaign_report.get("strategy_profile", "")) == "current-greedy", "campaign simulator declares the current greedy strategy baseline")
	_check(str(campaign_report.get("seed_model", "")) == "paired_by_iteration", "campaign simulator pairs random environments across characters and challenges")
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
	var campaign_modifiers: Dictionary = campaign_case.get("challenge_modifiers", {})
	_check(is_equal_approx(float(campaign_modifiers.get("enemy_hp_multiplier", 0.0)), 1.0) and is_equal_approx(float(campaign_modifiers.get("boss_hp_multiplier", 0.0)), 0.96), "campaign report snapshots complete challenge modifiers")
	_check(_valid_campaign_risk_flag(str(campaign_case.get("risk_flag", ""))), "campaign risk flag is recognized")
	_check(str(campaign_case.get("risk_flag", "")) == "campaign_insufficient_samples", "small campaign samples are not treated as balance proof")
	_check((campaign_report.get("summary", {}).get("target_issues", []) as Array).has("challenge_0:insufficient_samples"), "campaign summary reports an insufficient hard-gate sample")
	_check(campaign_report.get("summary", {}).has("challenge_targets"), "campaign summary exposes configured challenge target rows")
	var campaign_samples: Array = campaign_case.get("sample_runs", [])
	_check(not campaign_samples.is_empty() and str(campaign_samples[0].get("skill_book_id", "")) == "steel_manual", "campaign reports the active default skill book")

	if failed:
		quit(1)
		return
	print("Balance simulator smoke test passed.")
	quit(0)

func _valid_risk_flag(flag: String) -> bool:
	return [
		"ok",
		"timeout_check",
		"normal_too_lethal",
		"elite_too_lethal",
		"boss_too_lethal",
		"normal_too_easy",
		"elite_too_easy",
		"boss_too_easy",
		"encounter_too_fast",
		"encounter_too_slow",
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
		"campaign_insufficient_samples",
		"campaign_win_rate_low",
		"campaign_win_rate_high",
		"campaign_gold_starved",
		"campaign_gold_hoarding",
		"campaign_deck_too_thin",
		"campaign_deck_bloat",
		"campaign_failure_concentration",
		"campaign_fails_chapter_one",
		"campaign_fails_before_finale",
	].has(flag)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)
