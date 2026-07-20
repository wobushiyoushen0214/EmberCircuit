extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")
const BalanceCliScript = preload("res://tools/run_balance_simulation.gd")

const REPORT_PATH := "/tmp/embercircuit_balance_test_report.json"
const COMPONENT_DIAGNOSTIC_FIELDS := [
	"strategy_components",
	"node_visit_counts",
	"elite_visits",
	"elite_wins",
	"elite_deaths",
	"optional_elite_offer_count",
	"optional_elite_accept_count",
	"route_choice_reason_counts",
]

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var competent_cli_options: Dictionary = BalanceCliScript.parse_options_for_args([
		"--mode=campaign",
		"--strategy-profile=competent-player-v1",
		"--iterations=128",
		"--max-turns=80",
		"--challenges=0,1,2,3",
		"--output=/tmp/ember020-competent-player-v1-128.json",
	])
	_check(str(competent_cli_options.get("strategy_profile", "")) == "competent-player-v1", "campaign CLI accepts the competent strategy profile")
	_check(str(competent_cli_options.get("mode", "")) == "campaign", "campaign CLI preserves campaign mode")
	_check(int(competent_cli_options.get("iterations", 0)) == 128 and int(competent_cli_options.get("max_turns", 0)) == 80, "campaign CLI parses paired run sizes")
	_check(competent_cli_options.get("challenge_levels", []) == [0, 1, 2, 3], "campaign CLI parses challenge levels")
	_check(str(competent_cli_options.get("output_path", "")) == "/tmp/ember020-competent-player-v1-128.json", "campaign CLI parses output path")
	var simulator = BalanceSimulatorScript.new()
	var combat_cli_options: Dictionary = BalanceCliScript.parse_options_for_args([
		"--mode=campaign",
		"--strategy-profile=competent-combat-v1",
		"--strategy-diagnostics=component-v1",
	])
	_check(str(combat_cli_options.get("strategy_profile", "")) == "competent-combat-v1", "campaign CLI accepts the competent combat component profile")
	_check(str(combat_cli_options.get("strategy_diagnostics", "")) == "component-v1", "campaign CLI accepts component strategy diagnostics")
	for known_profile in ["current-greedy", "competent-player-v1", "competent-combat-v1", "competent-player-v2"]:
		var known_config: Dictionary = simulator._campaign_strategy_config(known_profile)
		_check(str(known_config.get("profile", "")) == known_profile and not bool(known_config.get("fallback", true)), "campaign API accepts strategy profile %s without fallback" % known_profile)
	var component_mapping_expectations := {
		"current-greedy": {"meta": "current", "combat": "current", "elite_safety": "off"},
		"competent-player-v1": {"meta": "competent", "combat": "current", "elite_safety": "off"},
		"competent-combat-v1": {"meta": "current", "combat": "competent", "elite_safety": "off"},
		"competent-player-v2": {"meta": "competent", "combat": "competent", "elite_safety": "predictive-v1"},
	}
	for profile_value in component_mapping_expectations.keys():
		_check(simulator._campaign_strategy_components(str(profile_value)) == component_mapping_expectations.get(profile_value, {}), "strategy profile %s maps to its exact components" % str(profile_value))
	var unknown_component_config: Dictionary = simulator._campaign_strategy_config("unknown-component-profile")
	_check(str(unknown_component_config.get("profile", "")) == "current-greedy" and bool(unknown_component_config.get("fallback", false)), "unknown component profile explicitly falls back to current-greedy")
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
		_check(str(case_dict.get("loadout_profile", "")) == "starter_deck_relics_default_skill_book", "single encounter case declares its complete default loadout")
		_check(str(case_dict.get("skill_book_id", "")) == "steel_manual", "single encounter case declares the default steel manual")
		_check(str(case_dict.get("strategy_profile", "")) == "current-greedy", "single encounter case declares the current greedy strategy")
		_check(int(case_dict.get("pressure_contract_version", 0)) == 2, "single encounter case declares attrition-aware pressure schema version two")
		_check(not bool(case_dict.get("pressure_gate_eligible", true)), "three-run cases remain diagnostic-only")
		for field in ["zero_damage_win_count", "perfect_win_rate", "hp_loss_p50", "hp_loss_p90", "turn_sample_count", "turns_p50", "turns_p90", "cards_played_per_turn", "expected_turns_min", "expected_turns_max", "risk_flags"]:
			_check(case_dict.has(field), "single encounter case exposes pressure field %s" % field)
		_check(int(case_dict.get("zero_damage_win_count", -1)) >= 0 and float(case_dict.get("perfect_win_rate", -1.0)) >= 0.0, "single encounter case reports zero-damage wins and perfect rate")
		_check(float(case_dict.get("hp_loss_p50", -1.0)) >= 0.0 and float(case_dict.get("hp_loss_p90", -1.0)) >= float(case_dict.get("hp_loss_p50", -1.0)), "single encounter case reports ordered HP-loss percentiles")
		_check(int(case_dict.get("turn_sample_count", -1)) == int(case_dict.get("wins", 0)), "single encounter turn samples include wins only")
		_check(float(case_dict.get("turns_p90", -1.0)) >= float(case_dict.get("turns_p50", -1.0)), "single encounter case reports ordered winning-turn percentiles")
		_check(float(case_dict.get("cards_played_per_turn", -1.0)) >= 0.0, "single encounter case reports cards per turn")
		var expected_turns: Array = [8, 12] if str(case_dict.get("encounter_tier", "")) == "boss" else ([7, 13] if str(case_dict.get("encounter_tier", "")) == "elite" else [5, 9])
		_check(int(case_dict.get("expected_turns_min", 0)) == int(expected_turns[0]) and int(case_dict.get("expected_turns_max", 0)) == int(expected_turns[1]), "single encounter case binds configured expected turns")
		var risk_flags: Array = case_dict.get("risk_flags", [])
		_check(str(case_dict.get("risk_flag", "")) == (str(risk_flags[0]) if not risk_flags.is_empty() else "ok"), "legacy risk flag matches the first composite pressure risk")
		_check(not risk_flags.has("%s_too_easy" % str(case_dict.get("encounter_tier", "normal"))), "diagnostic-only cases cannot produce a tier too-easy risk")
		var case_modifiers: Dictionary = case_dict.get("challenge_modifiers", {})
		_check(is_equal_approx(float(case_modifiers.get("enemy_hp_multiplier", 0.0)), 1.0) and is_equal_approx(float(case_modifiers.get("boss_hp_multiplier", 0.0)), 0.96), "single encounter report snapshots complete challenge modifiers")
		_check(_valid_risk_flag(str(case_dict.get("risk_flag", ""))), "case risk flag is recognized")

	var repeat_report: Dictionary = simulator.run_suite(options)
	_check(JSON.stringify(report.get("cases", [])) == JSON.stringify(repeat_report.get("cases", [])), "balance simulator is deterministic for the same options")

	var act1_pressure_report: Dictionary = simulator.run_suite({
		"iterations": 64,
		"max_turns": 30,
		"character_ids": ["ember_exile", "arc_tinker", "pyre_ascetic"],
		"challenge_levels": [0],
		"encounter_ids": ["intro_patrol", "polluted_lab", "iron_checkpoint", "cinder_kennels", "executor_elite", "furnace_colossus_elite", "chapter_one_boss"],
	})
	_check(int(act1_pressure_report.get("case_count", 0)) == 21, "Act 1 pressure fixture covers three starter loadouts across seven encounters")
	for act1_case_value in act1_pressure_report.get("cases", []):
		var act1_case: Dictionary = act1_case_value
		var case_key := "%s/%s" % [str(act1_case.get("character_id", "")), str(act1_case.get("encounter_id", ""))]
		_check(bool(act1_case.get("pressure_gate_eligible", false)), "64 paired seeds satisfy the pressure gate: %s" % case_key)
		_check((act1_case.get("risk_flags", []) as Array).is_empty() and str(act1_case.get("risk_flag", "")) == "ok", "Act 1 case has no forbidden pressure risk: %s" % case_key)
		if str(act1_case.get("character_id", "")) == "arc_tinker":
			_check(float(act1_case.get("cards_played_per_turn", 99.0)) <= 5.3, "Arc high-tempo starter loop stays below the measured runaway action ceiling: %s" % case_key)

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
	var competent_mature_route_state := {
		"hp": 68,
		"max_hp": 70,
		"gold": 70,
		"character_id": "ember_exile",
		"strategy_profile": "competent-player-v1",
		"relic_ids": ["ember_bottle", "cracked_charm"],
		"deck_ids": ["ember_strike+", "ember_strike+", "ash_guard+", "ash_guard+", "pressure_surge+", "furnace_prayer", "slag_bomb", "sealed_front", "equilibrium_core", "cooling_breath+"]
	}
	_check(simulator._campaign_node_score(competent_mature_route_state, {"type": "elite", "encounter_id": "executor_elite"}) > simulator._campaign_node_score(competent_mature_route_state, {"type": "combat", "encounter_id": "intro_patrol"}), "competent route profile can pursue an elite with a mature deck before four relics")
	_check(simulator._campaign_node_score(competent_mature_route_state, {"type": "combat", "encounter_id": "intro_patrol"}) > simulator._campaign_node_score(competent_mature_route_state, {"type": "combat", "encounter_id": "iron_checkpoint"}), "competent route profile discounts a statically higher-pressure encounter")
	var competent_relic_route_state: Dictionary = competent_mature_route_state.duplicate(true)
	competent_relic_route_state["relic_ids"] = ["ember_bottle", "cracked_charm", "counter_spring", "iron_heart"]
	_check(simulator._campaign_node_score(competent_relic_route_state, {"type": "elite", "encounter_id": "executor_elite"}) > simulator._campaign_node_score(competent_mature_route_state, {"type": "elite", "encounter_id": "executor_elite"}), "competent route profile includes relic maturity in elite risk tolerance")
	var competent_campfire_preview := simulator._campaign_preview_state_after_node({"hp": 54, "max_hp": 70, "strategy_profile": "competent-player-v1"}, {"id": "preview_campfire", "type": "campfire"})
	_check(int(competent_campfire_preview.get("hp", 0)) > 54, "competent route preview predicts the eighty-percent campfire rest decision")
	var equal_route_candidates := [{"id": "zeta_path", "type": "combat"}, {"id": "alpha_path", "type": "combat"}]
	_check(simulator._choose_next_campaign_node(competent_mature_route_state, equal_route_candidates) == "alpha_path", "competent route profile resolves equal scores by stable node id")
	var competent_reward_state := {
		"character_id": "ember_exile",
		"strategy_profile": "competent-player-v1",
		"deck_ids": ["ember_strike", "ember_strike", "ember_strike", "ash_guard", "ash_guard", "cooling_breath"]
	}
	var surge_card: Dictionary = simulator._card_by_id("pressure_surge")
	var repeated_strike_card: Dictionary = simulator._card_by_id("ember_strike")
	_check(simulator._campaign_card_reward_score(competent_reward_state, surge_card) > simulator._campaign_card_reward_score(competent_reward_state, repeated_strike_card), "competent reward score values an eligible momentum card above a repeated starter attack")
	_check(simulator._best_upgrade_index(["ember_strike+", "ash_guard"], "ember_exile", "competent-player-v1") == 1, "competent upgrade scoring resolves upgraded ids before reading the next upgrade")
	var competent_campfire_state := {
		"hp": 54,
		"max_hp": 70,
		"character_id": "ember_exile",
		"strategy_profile": "competent-player-v1",
		"deck_ids": ["ember_strike", "ash_guard"],
		"campfire_heal_count": 0,
		"campfire_upgrade_count": 0
	}
	simulator._simulate_campaign_campfire(competent_campfire_state)
	_check(int(competent_campfire_state.get("campfire_heal_count", 0)) == 1 and int(competent_campfire_state.get("campfire_upgrade_count", 0)) == 0, "competent campfire rests at or below eighty percent HP")
	var competent_potion_ids: Array = ["coolant_phial"]
	var competent_potion_result: Dictionary = simulator._run_single_combat_with_loadout(
		"ember_exile",
		0,
		"intro_patrol",
		5,
		303,
		["ember_strike", "ember_strike", "ember_strike", "ember_strike", "ember_strike", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"],
		["ember_bottle", "cracked_charm"],
		34,
		competent_potion_ids,
		simulator._campaign_modifier_sources({"skill_book_id": "steel_manual", "deck_mastery_id": ""}),
		"competent-player-v1"
	)
	_check((competent_potion_result.get("potions_used_ids", []) as Array).has("coolant_phial"), "competent potion policy uses a healing potion below fifty percent HP")
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
	_check_component_diagnostics_absent(campaign_report, "default current-greedy diagnostics-off")
	var unknown_diagnostics_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 1,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_diagnostics": "unknown-diagnostics"
	})
	_check_component_diagnostics_absent(unknown_diagnostics_report, "unknown diagnostics")
	var v1_diagnostics_off_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 1,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v1"
	})
	_check_component_diagnostics_absent(v1_diagnostics_off_report, "competent-player-v1 diagnostics-off")
	var component_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 1,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v2",
		"strategy_diagnostics": "component-v1"
	})
	var component_case: Dictionary = (component_report.get("cases", []) as Array)[0]
	var expected_components := {"meta": "competent", "combat": "competent", "elite_safety": "predictive-v1"}
	_check(component_report.get("strategy_components", {}) == expected_components, "component diagnostics expose the v2 strategy component mapping at report level")
	_check(component_case.get("strategy_components", {}) == expected_components, "component diagnostics expose the v2 strategy component mapping at case level")
	var component_samples: Array = component_case.get("sample_runs", [])
	_check(not component_samples.is_empty() and component_samples[0].get("strategy_components", {}) == expected_components, "component diagnostics expose the v2 strategy component mapping in samples")
	var telemetry_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 1,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v1",
		"strategy_diagnostics": "component-v1"
	})
	var telemetry_case: Dictionary = (telemetry_report.get("cases", []) as Array)[0]
	var telemetry_samples: Array = telemetry_case.get("sample_runs", [])
	var telemetry_sample: Dictionary = telemetry_samples[0] if not telemetry_samples.is_empty() else {}
	for component_field in COMPONENT_DIAGNOSTIC_FIELDS.slice(1):
		_check(telemetry_case.has(component_field), "component diagnostics expose %s" % component_field)
		_check(telemetry_sample.has(component_field), "component diagnostic samples expose %s" % component_field)
	_check(int(telemetry_case.get("elite_visits", -1)) == int(telemetry_case.get("elite_wins", -2)) + int(telemetry_case.get("elite_deaths", -2)), "component elite visits equal wins plus deaths")
	_check(int(telemetry_case.get("optional_elite_accept_count", -1)) <= int(telemetry_case.get("optional_elite_offer_count", -1)), "component elite accepts cannot exceed offers")
	var sampled_path: Array = telemetry_sample.get("path", [])
	var sampled_node_visit_total := 0
	for node_visit_count in (telemetry_sample.get("node_visit_counts", {}) as Dictionary).values():
		sampled_node_visit_total += int(node_visit_count)
	_check(sampled_node_visit_total == sampled_path.size() and sampled_node_visit_total > 0, "sample node visit counts match the actual visited path")
	var sampled_elite_visits := 0
	var sampled_elite_wins := 0
	var sampled_elite_deaths := 0
	for path_value in sampled_path:
		var path_node: Dictionary = path_value
		if str(path_node.get("node_type", "")) == "elite":
			sampled_elite_visits += 1
			if bool(path_node.get("completed", false)):
				sampled_elite_wins += 1
			else:
				sampled_elite_deaths += 1
	_check(sampled_elite_visits > 0, "component fixture reaches a real elite node")
	_check(int(telemetry_sample.get("elite_visits", -1)) == sampled_elite_visits and int(telemetry_sample.get("elite_wins", -1)) == sampled_elite_wins and int(telemetry_sample.get("elite_deaths", -1)) == sampled_elite_deaths, "sample elite telemetry matches actual elite path outcomes")
	_check(telemetry_case.get("node_visit_counts", {}) == telemetry_sample.get("node_visit_counts", {}) and telemetry_case.get("route_choice_reason_counts", {}) == telemetry_sample.get("route_choice_reason_counts", {}), "single-run case preserves sampled node and route telemetry")
	_check(int(telemetry_case.get("elite_visits", -1)) == int(telemetry_sample.get("elite_visits", -2)) and int(telemetry_case.get("elite_wins", -1)) == int(telemetry_sample.get("elite_wins", -2)) and int(telemetry_case.get("elite_deaths", -1)) == int(telemetry_sample.get("elite_deaths", -2)), "single-run case preserves sampled elite outcomes")
	_check(int(telemetry_sample.get("optional_elite_offer_count", 0)) > 0, "component fixture records a real optional elite offer")
	_check(int(telemetry_case.get("optional_elite_offer_count", -1)) == int(telemetry_sample.get("optional_elite_offer_count", -2)) and int(telemetry_case.get("optional_elite_accept_count", -1)) == int(telemetry_sample.get("optional_elite_accept_count", -2)), "single-run case preserves sampled optional elite offer and accept counts")
	var tied_diagnostic_state := {
		"strategy_profile": "competent-player-v1",
		"strategy_component_diagnostics": true,
		"route_choice_reason_counts": {},
		"optional_elite_offer_count": 0,
		"optional_elite_accept_count": 0,
	}
	var tied_diagnostic_candidates := [{"id": "zeta_path", "type": "combat"}, {"id": "alpha_path", "type": "combat"}]
	_check(simulator._choose_next_campaign_node(tied_diagnostic_state, tied_diagnostic_candidates) == "alpha_path", "diagnostic route keeps stable node-id tie breaking")
	_check(int((tied_diagnostic_state.get("route_choice_reason_counts", {}) as Dictionary).get("stable_node_id_tiebreak", 0)) == 1, "diagnostic route records the stable tie-break reason code")
	var current_tied_diagnostic_state := tied_diagnostic_state.duplicate(true)
	current_tied_diagnostic_state["strategy_profile"] = "current-greedy"
	current_tied_diagnostic_state["route_choice_reason_counts"] = {}
	_check(simulator._choose_next_campaign_node(current_tied_diagnostic_state, tied_diagnostic_candidates) == "alpha_path", "diagnostic current profile resolves ties by stable node id without changing diagnostics-off history")
	_check(int((current_tied_diagnostic_state.get("route_choice_reason_counts", {}) as Dictionary).get("stable_node_id_tiebreak", 0)) == 1, "diagnostic current profile records the stable tie-break reason")
	for tied_profile in ["current-greedy", "competent-player-v1", "competent-combat-v1", "competent-player-v2"]:
		var profile_tie_state := tied_diagnostic_state.duplicate(true)
		profile_tie_state["strategy_profile"] = tied_profile
		profile_tie_state["route_choice_reason_counts"] = {}
		_check(simulator._choose_next_campaign_node(profile_tie_state, tied_diagnostic_candidates) == "alpha_path", "diagnostics stabilize ties for profile %s" % tied_profile)
		_check(int((profile_tie_state.get("route_choice_reason_counts", {}) as Dictionary).get("stable_node_id_tiebreak", 0)) == 1, "diagnostics record tie-break for profile %s" % tied_profile)
	var historical_current_tie_state := {"strategy_profile": "current-greedy"}
	_check(simulator._choose_next_campaign_node(historical_current_tie_state, tied_diagnostic_candidates) == "zeta_path", "diagnostics-off current preserves its historical first-candidate tie behavior")
	var scored_diagnostic_state := tied_diagnostic_state.duplicate(true)
	scored_diagnostic_state["route_choice_reason_counts"] = {}
	var scored_candidates := [{"id": "ordinary_combat", "type": "combat"}, {"id": "risk_free_treasure", "type": "treasure"}]
	_check(simulator._choose_next_campaign_node(scored_diagnostic_state, scored_candidates) == "risk_free_treasure", "diagnostic route selects the strictly highest score")
	_check(int((scored_diagnostic_state.get("route_choice_reason_counts", {}) as Dictionary).get("highest_score", 0)) == 1, "diagnostic route records the highest-score reason code")
	var late_high_score_state := tied_diagnostic_state.duplicate(true)
	late_high_score_state["route_choice_reason_counts"] = {}
	var late_high_score_candidates := [{"id": "zeta_combat", "type": "combat"}, {"id": "alpha_combat", "type": "combat"}, {"id": "final_treasure", "type": "treasure"}]
	_check(simulator._choose_next_campaign_node(late_high_score_state, late_high_score_candidates) == "final_treasure", "a later unique maximum supersedes an earlier tie")
	_check(int((late_high_score_state.get("route_choice_reason_counts", {}) as Dictionary).get("highest_score", 0)) == 1, "route reason describes the final maximum rather than an earlier discarded tie")
	var forced_elite_state := tied_diagnostic_state.duplicate(true)
	forced_elite_state["optional_elite_offer_count"] = 0
	forced_elite_state["optional_elite_accept_count"] = 0
	simulator._choose_next_campaign_node(forced_elite_state, [{"id": "forced_elite", "type": "elite"}])
	_check(int(forced_elite_state.get("optional_elite_offer_count", -1)) == 0 and int(forced_elite_state.get("optional_elite_accept_count", -1)) == 0, "a forced elite without a non-elite alternative is not counted as optional")
	var optional_elite_state := tied_diagnostic_state.duplicate(true)
	optional_elite_state["optional_elite_offer_count"] = 0
	optional_elite_state["optional_elite_accept_count"] = 0
	simulator._choose_next_campaign_node(optional_elite_state, [{"id": "optional_elite", "type": "elite"}, {"id": "safe_combat", "type": "combat"}])
	_check(int(optional_elite_state.get("optional_elite_offer_count", 0)) == 1 and int(optional_elite_state.get("optional_elite_accept_count", -1)) == 0, "an offered but rejected elite records optional offer without accept")
	var v1_meta_fixture := {
		"hp": 68,
		"max_hp": 70,
		"gold": 70,
		"character_id": "ember_exile",
		"strategy_profile": "competent-player-v1",
		"relic_ids": ["ember_bottle", "cracked_charm"],
		"deck_ids": ["ember_strike+", "ash_guard+", "pressure_surge+", "furnace_prayer", "slag_bomb", "sealed_front"]
	}
	var v2_meta_fixture: Dictionary = v1_meta_fixture.duplicate(true)
	v2_meta_fixture["strategy_profile"] = "competent-player-v2"
	var accepted_optional_elite_state: Dictionary = v1_meta_fixture.duplicate(true)
	accepted_optional_elite_state["strategy_component_diagnostics"] = true
	accepted_optional_elite_state["route_choice_reason_counts"] = {}
	accepted_optional_elite_state["optional_elite_offer_count"] = 0
	accepted_optional_elite_state["optional_elite_accept_count"] = 0
	_check(simulator._choose_next_campaign_node(accepted_optional_elite_state, [{"id": "accepted_elite", "type": "elite", "encounter_id": "executor_elite"}, {"id": "safe_combat", "type": "combat", "encounter_id": "intro_patrol"}]) == "accepted_elite", "mature competent meta fixture accepts the optional elite")
	_check(int(accepted_optional_elite_state.get("optional_elite_offer_count", 0)) == 1 and int(accepted_optional_elite_state.get("optional_elite_accept_count", 0)) == 1, "accepted optional elite records one offer and one accept")
	_check(is_equal_approx(simulator._campaign_node_score(v1_meta_fixture, {"type": "elite", "encounter_id": "executor_elite"}), simulator._campaign_node_score(v2_meta_fixture, {"type": "elite", "encounter_id": "executor_elite"})), "v2 uses the same competent meta route scoring as v1")
	_check(simulator._best_upgrade_index(["ember_strike", "ash_guard", "pressure_surge"], "ember_exile", "competent-player-v2") == simulator._best_upgrade_index(["ember_strike", "ash_guard", "pressure_surge"], "ember_exile", "competent-player-v1"), "v2 uses the same competent meta upgrade scoring as v1")
	var meta_reward_options := [simulator._card_by_id("pressure_surge"), simulator._card_by_id("ember_strike")]
	_check(str(simulator._best_campaign_card_option(v1_meta_fixture, meta_reward_options).get("id", "")) == str(simulator._best_campaign_card_option(v2_meta_fixture, meta_reward_options).get("id", "")), "v2 uses the same competent meta reward choice as v1")
	var v1_campfire_meta := {"hp": 54, "max_hp": 70, "character_id": "ember_exile", "strategy_profile": "competent-player-v1", "deck_ids": ["ember_strike", "ash_guard"], "campfire_heal_count": 0, "campfire_upgrade_count": 0}
	var v2_campfire_meta: Dictionary = v1_campfire_meta.duplicate(true)
	v2_campfire_meta["strategy_profile"] = "competent-player-v2"
	simulator._simulate_campaign_campfire(v1_campfire_meta)
	simulator._simulate_campaign_campfire(v2_campfire_meta)
	_check(int(v1_campfire_meta.get("hp", 0)) == int(v2_campfire_meta.get("hp", -1)) and int(v2_campfire_meta.get("campfire_heal_count", 0)) == 1, "v2 uses the same competent meta campfire policy as v1")
	var v1_meta_potions: Array = ["coolant_phial"]
	var v2_meta_potions: Array = ["coolant_phial"]
	var v1_meta_potion_result: Dictionary = simulator._run_single_combat_with_loadout("ember_exile", 0, "intro_patrol", 1, 411, ["ember_strike", "ash_guard"], ["ember_bottle", "cracked_charm"], 34, v1_meta_potions, simulator._campaign_modifier_sources({"skill_book_id": "steel_manual", "deck_mastery_id": ""}), "competent-player-v1")
	var v2_meta_potion_result: Dictionary = simulator._run_single_combat_with_loadout("ember_exile", 0, "intro_patrol", 1, 411, ["ember_strike", "ash_guard"], ["ember_bottle", "cracked_charm"], 34, v2_meta_potions, simulator._campaign_modifier_sources({"skill_book_id": "steel_manual", "deck_mastery_id": ""}), "competent-player-v2")
	_check((v1_meta_potion_result.get("potions_used_ids", []) as Array) == (v2_meta_potion_result.get("potions_used_ids", []) as Array) and (v2_meta_potion_result.get("potions_used_ids", []) as Array).has("coolant_phial"), "v2 uses the same competent meta potion threshold as v1")
	var repeated_component_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 1,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "competent-player-v2",
		"strategy_diagnostics": "component-v1"
	})
	_check(JSON.stringify(component_report) == JSON.stringify(repeated_component_report), "component diagnostics are deterministic for identical options")
	var explicit_current_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 2,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "current-greedy"
	})
	_check(JSON.stringify(campaign_report.get("cases", [])) == JSON.stringify(explicit_current_report.get("cases", [])), "explicit current-greedy profile preserves the default campaign behavior")
	_check(int(campaign_report.get("campaign_strategy_schema_version", 0)) == 1, "campaign report declares strategy schema version one")
	_check(int(campaign_case.get("campaign_strategy_schema_version", 0)) == 1, "campaign case declares strategy schema version one")
	_check(not bool(campaign_case.get("strategy_profile_fallback", true)), "known current-greedy profile does not fall back")
	var fallback_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 1,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"strategy_profile": "unknown-profile"
	})
	_check(str(fallback_report.get("strategy_profile", "")) == "current-greedy" and bool(fallback_report.get("strategy_profile_fallback", false)), "unknown campaign profile falls back to current-greedy explicitly")
	_check(bool((fallback_report.get("cases", []) as Array)[0].get("strategy_profile_fallback", false)), "campaign case preserves an unknown-profile fallback marker")
	for decision_field in ["campfire_heal_count", "campfire_upgrade_count", "card_reward_offer_count", "card_reward_accept_count", "card_reward_skip_count", "shop_card_purchase_count", "shop_potion_purchase_count", "potions_used_count"]:
		_check(campaign_case.has(decision_field) and float(campaign_case.get(decision_field, -1.0)) >= 0.0, "campaign decision telemetry exposes non-negative %s" % decision_field)
	_check(str(campaign_case.get("character_id", "")) == "ember_exile", "campaign case records character")
	_check(int(campaign_case.get("runs", 0)) == 2, "campaign case records run count")
	_check(float(campaign_case.get("win_rate", -1.0)) >= 0.0 and float(campaign_case.get("win_rate", -1.0)) <= 1.0, "campaign win rate is normalized")
	_check(float(campaign_case.get("avg_chapters_completed", -1.0)) >= 0.0 and float(campaign_case.get("avg_chapters_completed", -1.0)) <= 3.0, "campaign records chapter progress")
	_check(float(campaign_case.get("avg_nodes_completed", -1.0)) >= 0.0, "campaign records node progress")
	_check(campaign_case.has("failure_reasons") and campaign_case.has("failure_points"), "campaign records failure breakdowns")
	_check(campaign_case.has("failure_node_types") and campaign_case.has("failure_encounters"), "campaign records failure node types and encounter ids")
	_check(int(campaign_report.get("campaign_attribution_schema_version", 0)) == 1, "campaign report declares attribution schema version one")
	_check(int(campaign_case.get("campaign_attribution_schema_version", 0)) == 1, "campaign case declares attribution schema version one")
	_check(campaign_case.has("chapter_attribution") and (campaign_case.get("chapter_attribution", []) as Array).size() == 3, "campaign case aggregates one attribution row per chapter")
	_check(campaign_case.has("chapter_transition_attribution") and (campaign_case.get("chapter_transition_attribution", []) as Array).size() == 2, "campaign case aggregates one row per chapter transition")
	for chapter_attribution_value in campaign_case.get("chapter_attribution", []):
		var chapter_attribution: Dictionary = chapter_attribution_value
		_check(chapter_attribution.has("entry_runs") and chapter_attribution.has("completed_runs") and chapter_attribution.has("failed_runs"), "chapter attribution records reach and outcome counts")
		_check(float(chapter_attribution.get("entry_rate", -1.0)) >= 0.0 and float(chapter_attribution.get("entry_rate", -1.0)) <= 1.0, "chapter attribution entry rate is normalized")
		_check(float(chapter_attribution.get("completion_rate", -1.0)) >= 0.0 and float(chapter_attribution.get("completion_rate", -1.0)) <= 1.0, "chapter attribution completion rate is normalized")
		_check(float(chapter_attribution.get("conditional_completion_rate", -1.0)) >= 0.0 and float(chapter_attribution.get("conditional_completion_rate", -1.0)) <= 1.0, "chapter attribution conditional completion rate is normalized")
		_check(chapter_attribution.has("avg_entry_hp") and chapter_attribution.has("avg_exit_hp") and chapter_attribution.has("avg_exit_deck_size"), "chapter attribution records resource maturity")
	for transition_attribution_value in campaign_case.get("chapter_transition_attribution", []):
		var transition_attribution: Dictionary = transition_attribution_value
		_check(transition_attribution.has("from_chapter_id") and transition_attribution.has("to_chapter_id") and transition_attribution.has("transition_runs"), "chapter transition attribution identifies both chapters")
		_check(transition_attribution.has("avg_post_transition_hp_ratio") and transition_attribution.has("avg_gold") and transition_attribution.has("avg_deck_size"), "chapter transition attribution records post-transition resources")
	var campaign_modifiers: Dictionary = campaign_case.get("challenge_modifiers", {})
	_check(is_equal_approx(float(campaign_modifiers.get("enemy_hp_multiplier", 0.0)), 1.0) and is_equal_approx(float(campaign_modifiers.get("boss_hp_multiplier", 0.0)), 0.96), "campaign report snapshots complete challenge modifiers")
	_check(_valid_campaign_risk_flag(str(campaign_case.get("risk_flag", ""))), "campaign risk flag is recognized")
	_check(str(campaign_case.get("risk_flag", "")) == "campaign_insufficient_samples", "small campaign samples are not treated as balance proof")
	_check((campaign_report.get("summary", {}).get("target_issues", []) as Array).has("challenge_0:insufficient_samples"), "campaign summary reports an insufficient hard-gate sample")
	_check(campaign_report.get("summary", {}).has("challenge_targets"), "campaign summary exposes configured challenge target rows")
	var character_attribution_rows: Array = campaign_report.get("summary", {}).get("character_attribution", [])
	var challenge_attribution_rows: Array = campaign_report.get("summary", {}).get("challenge_attribution", [])
	_check(character_attribution_rows.size() == 1, "campaign summary exposes character attribution rows")
	_check(challenge_attribution_rows.size() == 1, "campaign summary exposes challenge attribution rows")
	var character_attribution: Dictionary = character_attribution_rows[0] if not character_attribution_rows.is_empty() else {}
	_check(str(character_attribution.get("character_id", "")) == "ember_exile" and int(character_attribution.get("case_count", 0)) == 1, "character attribution identifies its case axis")
	_check(character_attribution.has("average_win_rate") and character_attribution.has("average_chapters_completed") and character_attribution.has("attribution_gate_eligible"), "character attribution exposes aggregate progress and sample gate")
	var challenge_attribution: Dictionary = challenge_attribution_rows[0] if not challenge_attribution_rows.is_empty() else {}
	_check(int(challenge_attribution.get("challenge_level", -1)) == 0 and challenge_attribution.has("attribution_gate_eligible"), "challenge attribution identifies its challenge axis and sample gate")
	var campaign_samples: Array = campaign_case.get("sample_runs", [])
	_check(not campaign_samples.is_empty() and str(campaign_samples[0].get("skill_book_id", "")) == "steel_manual", "campaign reports the active default skill book")
	_check(not campaign_samples.is_empty() and int(campaign_samples[0].get("campaign_strategy_schema_version", 0)) == 1, "campaign sample declares strategy schema version one")
	_check(not campaign_samples.is_empty() and str(campaign_samples[0].get("strategy_profile", "")) == "current-greedy", "campaign sample declares its strategy profile")
	_check(not campaign_samples.is_empty() and campaign_samples[0].has("campfire_heal_count") and campaign_samples[0].has("potions_used_count"), "campaign sample preserves decision telemetry")
	_check(not campaign_samples.is_empty() and campaign_samples[0].has("chapter_snapshots") and campaign_samples[0].has("chapter_transition_snapshots"), "campaign sample run preserves raw attribution snapshots")
	var repeated_campaign_report: Dictionary = simulator.run_campaign_suite({
		"iterations": 2,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0]
	})
	_check(JSON.stringify(campaign_report.get("cases", [])) == JSON.stringify(repeated_campaign_report.get("cases", [])), "campaign attribution is deterministic for the same options")

	var attribution_report_64: Dictionary = simulator.run_campaign_suite({
		"iterations": 64,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0]
	})
	var attribution_case_64: Dictionary = attribution_report_64.get("cases", [])[0]
	_check(not bool(attribution_case_64.get("attribution_gate_eligible", true)), "64-run campaign attribution remains below the hard gate")
	_check(attribution_case_64.has("failure_concentration"), "64-run campaign exposes failure concentration diagnostics")
	_check((attribution_case_64.get("failure_concentration", {}).get("attribution_flags", []) as Array).is_empty(), "64-run campaign does not emit hard attribution flags")

	var attribution_report_128: Dictionary = simulator.run_campaign_suite({
		"iterations": 128,
		"max_turns": 35,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0]
	})
	var attribution_case_128: Dictionary = attribution_report_128.get("cases", [])[0]
	_check(bool(attribution_case_128.get("attribution_gate_eligible", false)), "128-run campaign attribution reaches the hard gate")
	_check(float(attribution_case_128.get("failure_concentration", {}).get("top_encounter_share", -1.0)) >= 0.0, "128-run campaign reports failure encounter share")
	_check(float(attribution_case_128.get("failure_concentration", {}).get("top_encounter_share", 2.0)) <= 1.0, "128-run failure encounter share is normalized")


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

func _check_component_diagnostics_absent(report: Dictionary, context: String) -> void:
	for field in COMPONENT_DIAGNOSTIC_FIELDS:
		_check(not report.has(field), "%s report does not leak 021 field %s" % [context, field])
	for case_value in report.get("cases", []):
		var case_dict: Dictionary = case_value
		for field in COMPONENT_DIAGNOSTIC_FIELDS:
			_check(not case_dict.has(field), "%s case does not leak 021 field %s" % [context, field])
		for sample_value in case_dict.get("sample_runs", []):
			var sample: Dictionary = sample_value
			for field in COMPONENT_DIAGNOSTIC_FIELDS:
				_check(not sample.has(field), "%s sample does not leak 021 field %s" % [context, field])

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)
