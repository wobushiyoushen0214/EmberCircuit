extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")
const BalanceCliScript = preload("res://tools/run_balance_simulation.gd")
const CombatStateScript = preload("res://scripts/combat/CombatState.gd")

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
	simulator.load_default_data()
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
	var lethal_fixture = CombatStateScript.new()
	lethal_fixture.phase = "player"
	lethal_fixture.turn = 2
	lethal_fixture.player = {"hp": 30, "max_hp": 70, "block": 0, "energy": 2, "max_energy": 3, "momentum": 0, "statuses": {}}
	lethal_fixture.enemies = [{"id": "fixture_enemy", "hp": 6, "max_hp": 20, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 8, "hits": 1}}}]
	lethal_fixture.hand = [
		{"id": "fixture_overblock", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
		{"id": "fixture_exact_lethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 6}]},
	]
	var legacy_lethal_fixture_decision: Dictionary = simulator._choose_card(lethal_fixture)
	_check(int(legacy_lethal_fixture_decision.get("hand_index", -1)) == 0, "legacy scorer baseline prefers the oversized block fixture")
	for legacy_profile in ["current-greedy", "competent-player-v1"]:
		var legacy_profile_decision: Dictionary = simulator._choose_card(lethal_fixture, legacy_profile)
		_check(int(legacy_profile_decision.get("hand_index", -1)) == int(legacy_lethal_fixture_decision.get("hand_index", -2)), "%s preserves the legacy scorer choice" % legacy_profile)
	for competent_combat_profile in ["competent-combat-v1", "competent-player-v2"]:
		var competent_lethal_decision: Dictionary = simulator._choose_card(lethal_fixture, competent_combat_profile)
		_check(int(competent_lethal_decision.get("hand_index", -1)) == 1 and int(competent_lethal_decision.get("target_index", -1)) == 0, "%s prioritizes an executable immediate lethal" % competent_combat_profile)
	var phase_block_card := {"id": "fixture_phase_block_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 37, "hits": 2}]}
	var phase_block_fixture = _combat_choice_fixture(30, 0, 0, 70, [phase_block_card])
	phase_block_fixture.enemies = [{
		"id": "fixture_phase_guard",
		"name": "阶段守卫",
		"hp": 70,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": -1,
		"data": {"phases": [{"id": "guarded", "hp_percent_below": 66, "on_enter_effects": [{"type": "block", "amount": 8, "target": "self"}], "actions": []}]},
		"current_action": {"intent": {"type": "attack", "amount": 0, "hits": 1}},
	}]
	var phase_block_actual = _combat_choice_fixture(30, 0, 0, 70, [phase_block_card])
	phase_block_actual.enemies = phase_block_fixture.enemies.duplicate(true)
	_check(phase_block_actual.play_card(0, 0) and int((phase_block_actual.enemies[0] as Dictionary).get("hp", 0)) == 4, "CombatState applies boss phase block between attack hits")
	_check(not simulator._card_has_immediate_lethal(phase_block_fixture, phase_block_card, 0), "competent combat does not classify a multi-hit attack as lethal through boss phase block")
	var phase_vulnerable_card := {"id": "fixture_phase_vulnerable_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 4, "hits": 2}]}
	var phase_vulnerable_fixture = _combat_choice_fixture(30, 0, 0, 10, [phase_vulnerable_card])
	phase_vulnerable_fixture.enemies = [{
		"id": "fixture_phase_vulnerable_enemy",
		"hp": 10,
		"max_hp": 10,
		"block": 0,
		"statuses": {},
		"phase_index": -1,
		"data": {"phases": [{"id": "exposed", "hp_percent_below": 60, "on_enter_effects": [{"type": "apply_status", "target": "self", "status": "vulnerable", "amount": 1}], "actions": []}]},
		"current_action": {},
	}]
	var phase_vulnerable_actual = _combat_choice_fixture(30, 0, 0, 10, [phase_vulnerable_card])
	phase_vulnerable_actual.enemies = phase_vulnerable_fixture.enemies.duplicate(true)
	_check(phase_vulnerable_actual.play_card(0, 0) and phase_vulnerable_actual.phase == "won", "CombatState recalculates later player hits after a boss phase applies vulnerable")
	_check(simulator._card_has_immediate_lethal(phase_vulnerable_fixture, phase_vulnerable_card, 0), "competent combat recalculates every player hit from the latest boss phase statuses")
	var defense_gap_fixture = _combat_choice_fixture(30, 0, 8, 40, [
		{"id": "fixture_exact_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 8}]},
		{"id": "fixture_overblock", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
		{"id": "fixture_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 6}]},
	])
	_check(int(simulator._choose_card(defense_gap_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "competent combat fills the real defense gap without rewarding excess block")
	var covered_defense_fixture = _combat_choice_fixture(30, 8, 8, 40, [
		{"id": "fixture_wasted_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
		{"id": "fixture_effective_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 6}]},
	])
	_check(int(simulator._choose_card(covered_defense_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat does not prefer wasted block after the incoming gap is covered")
	var fatal_defense_fixture = _combat_choice_fixture(5, 0, 9, 40, [
		{"id": "fixture_survival_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 5}]},
		{"id": "fixture_nonlethal_damage", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 12}]},
	])
	_check(int(simulator._choose_card(fatal_defense_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "competent combat prioritizes defense that prevents lethal incoming damage")
	var runtime_block_bonus_fixture = _combat_choice_fixture(3, 0, 10, 40, [
		{"id": "fixture_runtime_bonus_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 6}]},
		{"id": "fixture_runtime_bonus_attack", "type": "attack", "target": "enemy", "cost": 3, "effects": [{"type": "damage", "amount": 12}]},
	])
	runtime_block_bonus_fixture.skill_block_bonus_percent = 25
	_check(int(simulator._choose_card(runtime_block_bonus_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat includes runtime skill block bonuses when identifying a survival play")
	var plating_block_bonus_fixture = _combat_choice_fixture(3, 0, 10, 40, runtime_block_bonus_fixture.hand)
	plating_block_bonus_fixture.player["statuses"] = {"plating": 2}
	_check(int(simulator._choose_card(plating_block_bonus_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "competent combat includes plating when identifying a survival play")
	var runtime_block_gap_fixture = _combat_choice_fixture(30, 0, 10, 40, [
		{"id": "fixture_runtime_gap_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 8}]},
		{"id": "fixture_runtime_gap_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 8}]},
	])
	runtime_block_gap_fixture.skill_block_bonus_percent = 25
	runtime_block_gap_fixture.player["statuses"] = {"frail": 1, "plating": 3}
	_check(int(simulator._choose_card(runtime_block_gap_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat uses runtime block gain when filling a nonlethal defense gap")
	var block_trigger_fixture = _combat_choice_fixture(4, 0, 10, 40, [
		{"id": "fixture_block_trigger_guard", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 5}]},
		{"id": "fixture_block_trigger_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 12}]},
	])
	block_trigger_fixture.owned_relic_ids = ["fixture_bastion_forging"]
	block_trigger_fixture.relics_by_id = {"fixture_bastion_forging": {"effects": [{"trigger": "block_gained", "type": "gain_block", "amount": 3, "once_per_combat": true}]}}
	var block_trigger_actual = _combat_choice_fixture(4, 0, 10, 40, block_trigger_fixture.hand)
	block_trigger_actual.owned_relic_ids = block_trigger_fixture.owned_relic_ids.duplicate(true)
	block_trigger_actual.relics_by_id = block_trigger_fixture.relics_by_id.duplicate(true)
	_check(block_trigger_actual.play_card(0, 0) and int(block_trigger_actual.player.get("block", 0)) == 8, "CombatState applies a first block-gained growth trigger to the card's runtime block")
	_check(int(simulator._choose_card(block_trigger_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat includes an available block-gained growth trigger in survival scoring")
	var multi_block_trigger_fixture = _combat_choice_fixture(1, 0, 10, 40, [
		{"id": "fixture_multi_block_trigger_guard", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 4}, {"type": "block", "amount": 4}]},
		{"id": "fixture_multi_block_trigger_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 12}]},
	])
	multi_block_trigger_fixture.player["statuses"] = {"frail": 1}
	multi_block_trigger_fixture.owned_relic_ids = ["fixture_multi_bastion"]
	multi_block_trigger_fixture.relics_by_id = {"fixture_multi_bastion": {"effects": [{"trigger": "block_gained", "type": "gain_block", "amount": 3, "once_per_combat": true}]}}
	var multi_block_trigger_actual = _combat_choice_fixture(1, 0, 10, 40, multi_block_trigger_fixture.hand)
	multi_block_trigger_actual.player["statuses"] = {"frail": 1}
	multi_block_trigger_actual.owned_relic_ids = multi_block_trigger_fixture.owned_relic_ids.duplicate(true)
	multi_block_trigger_actual.relics_by_id = multi_block_trigger_fixture.relics_by_id.duplicate(true)
	_check(multi_block_trigger_actual.play_card(0, 0) and int(multi_block_trigger_actual.player.get("block", 0)) == 10, "CombatState consumes frail and resolves block-gained triggers after each block effect")
	_check(simulator._estimated_card_block_gain(multi_block_trigger_fixture, multi_block_trigger_fixture.hand[0]) == 10, "competent combat mirrors per-effect frail consumption and block-gained triggers")
	_check(int(simulator._choose_card(multi_block_trigger_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat recognizes multi-effect block that prevents lethal")
	var damage_then_block_fixture = _combat_choice_fixture(5, 0, 10, 40, [
		{"id": "fixture_damage_then_false_block", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1, "consume_momentum": true}, {"type": "block", "amount": 1, "bonus_if_momentum_at_least": 3, "bonus": 9}]},
		{"id": "fixture_damage_then_safe_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 6}]},
	])
	damage_then_block_fixture.player["momentum"] = 3
	var damage_then_block_actual = _combat_choice_fixture(5, 0, 10, 40, damage_then_block_fixture.hand)
	damage_then_block_actual.player["momentum"] = 3
	(damage_then_block_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]
	_check(damage_then_block_actual.play_card(0, 0) and int(damage_then_block_actual.player.get("block", 0)) == 1 and int(damage_then_block_actual.player.get("momentum", -1)) == 0, "CombatState consumes momentum in a damage effect before a later conditional block effect")
	damage_then_block_actual.end_player_turn()
	_check(damage_then_block_actual.phase == "lost", "CombatState confirms the damage-then-block card is not a survival play")
	var damage_then_safe_actual = _combat_choice_fixture(5, 0, 10, 40, damage_then_block_fixture.hand)
	damage_then_safe_actual.player["momentum"] = 3
	(damage_then_safe_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]
	_check(damage_then_safe_actual.play_card(1, 0), "CombatState accepts the alternate safe block")
	damage_then_safe_actual.end_player_turn()
	_check(damage_then_safe_actual.phase != "lost" and int(damage_then_safe_actual.player.get("hp", 0)) == 1, "CombatState confirms the alternate block survives")
	_check(simulator._estimated_card_block_gain(damage_then_block_fixture, damage_then_block_fixture.hand[0]) == 1, "competent combat consumes momentum in prior damage before estimating later block")
	_check(int(simulator._choose_card(damage_then_block_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat rejects false survival from pre-damage momentum")
	var unavailable_block_trigger_fixture = _combat_choice_fixture(4, 0, 10, 40, [
		{"id": "fixture_unavailable_block_trigger", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 5}]},
	])
	unavailable_block_trigger_fixture.owned_relic_ids = ["fixture_first_turn_bastion"]
	unavailable_block_trigger_fixture.relics_by_id = {"fixture_first_turn_bastion": {"effects": [{"trigger": "block_gained", "type": "gain_block", "amount": 3, "first_turn_only": true}]}}
	var unavailable_block_trigger_actual = _combat_choice_fixture(4, 0, 10, 40, unavailable_block_trigger_fixture.hand)
	unavailable_block_trigger_actual.owned_relic_ids = unavailable_block_trigger_fixture.owned_relic_ids.duplicate(true)
	unavailable_block_trigger_actual.relics_by_id = unavailable_block_trigger_fixture.relics_by_id.duplicate(true)
	_check(unavailable_block_trigger_actual.play_card(0, 0) and int(unavailable_block_trigger_actual.player.get("block", 0)) == 5, "CombatState does not apply a first-turn-only block trigger on turn two")
	_check(simulator._estimated_card_block_gain(unavailable_block_trigger_fixture, unavailable_block_trigger_fixture.hand[0]) == 5, "competent combat excludes a block-gained trigger whose real first-turn condition fails")
	var self_vulnerable_defense_fixture = _combat_choice_fixture(10, 0, 22, 40, [
		{"id": "fixture_exposed_overblock", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 22}, {"type": "apply_status", "target": "self", "status": "vulnerable", "amount": 1}]},
		{"id": "fixture_clean_survival_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 13}]},
	])
	var exposed_defense_actual = _combat_choice_fixture(10, 0, 22, 40, self_vulnerable_defense_fixture.hand)
	(exposed_defense_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 22, "hits": 1, "target": "player"}]
	_check(exposed_defense_actual.play_card(0, 0), "CombatState accepts the exposed overblock fixture card")
	exposed_defense_actual.end_player_turn()
	_check(exposed_defense_actual.phase == "lost", "CombatState self vulnerable turns the apparent overblock into a lethal defense")
	var clean_defense_actual = _combat_choice_fixture(10, 0, 22, 40, self_vulnerable_defense_fixture.hand)
	(clean_defense_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 22, "hits": 1, "target": "player"}]
	_check(clean_defense_actual.play_card(1, 0), "CombatState accepts the clean survival block fixture card")
	clean_defense_actual.end_player_turn()
	_check(clean_defense_actual.phase != "lost" and int(clean_defense_actual.player.get("hp", 0)) == 1, "CombatState clean block survives the same incoming attack")
	_check(int(simulator._choose_card(self_vulnerable_defense_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat evaluates survival after the card's self vulnerable effect")
	var zero_cost_starter_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_zero_cost_starter", "type": "skill", "target": "self", "cost": 0, "effects": [{"type": "draw", "amount": 1}, {"type": "gain_energy", "amount": 1}]},
		{"id": "fixture_starter_payoff", "type": "attack", "target": "enemy", "cost": 2, "effects": [{"type": "damage", "amount": 8}]},
	])
	_check(int(simulator._choose_card(zero_cost_starter_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "competent combat plays a zero-cost draw and energy starter before its payoff")
	var vulnerable_starter_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_vulnerable_starter", "type": "skill", "target": "enemy", "cost": 1, "effects": [{"type": "apply_status", "target": "enemy", "status": "vulnerable", "amount": 1}]},
		{"id": "fixture_vulnerable_payoff", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 8}]},
	])
	_check(int(simulator._choose_card(vulnerable_starter_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat applies vulnerable before a same-turn attack payoff")
	var saturated_vulnerable_fixture = _combat_choice_fixture(30, 0, 0, 40, vulnerable_starter_fixture.hand)
	(saturated_vulnerable_fixture.enemies[0] as Dictionary)["statuses"] = {"vulnerable": 1}
	_check(int(simulator._choose_card(saturated_vulnerable_fixture, "competent-combat-v1").get("hand_index", -1)) == 1, "competent combat does not reapply already sufficient vulnerable")
	var self_vulnerable_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_self_vulnerable", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 22}, {"type": "apply_status", "target": "self", "status": "vulnerable", "amount": 1}]},
		{"id": "fixture_self_vulnerable_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 3}]},
	])
	_check(int(simulator._choose_card(self_vulnerable_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat does not treat self vulnerable as an attack starter")
	var self_burn_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_self_burn", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "apply_status", "target": "self", "status": "burn", "amount": 1}]},
		{"id": "fixture_self_burn_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 3}]},
	])
	_check(int(simulator._choose_card(self_burn_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat does not treat self burn as an attack starter")
	var weak_starter_fixture = _combat_choice_fixture(30, 0, 12, 40, [
		{"id": "fixture_weak_starter", "type": "skill", "target": "enemy", "cost": 1, "effects": [{"type": "apply_status", "target": "enemy", "status": "weak", "amount": 1}]},
		{"id": "fixture_weak_payoff", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 6}]},
	])
	_check(int(simulator._choose_card(weak_starter_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "competent combat applies weak before the same-turn defense payoff")
	var weak_survival_fixture = _combat_choice_fixture(8, 0, 10, 40, [
		{"id": "fixture_weak_survival", "type": "skill", "target": "all_enemies", "cost": 1, "effects": [{"type": "apply_status", "target": "all_enemies", "status": "weak", "amount": 1}]},
		{"id": "fixture_weak_survival_attack", "type": "attack", "target": "enemy", "cost": 3, "effects": [{"type": "damage", "amount": 12}]},
	])
	_check(int(simulator._choose_card(weak_survival_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat prioritizes weak when weak alone prevents lethal incoming damage")
	var aoe_weak_partial_cap_fixture = _combat_choice_fixture(8, 0, 8, 40, weak_survival_fixture.hand)
	(aoe_weak_partial_cap_fixture.enemies[0] as Dictionary)["statuses"] = {"weak": 1}
	aoe_weak_partial_cap_fixture.enemies.append({"id": "fixture_unweakened_enemy", "hp": 40, "max_hp": 40, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 2, "hits": 1}}})
	_check(int(simulator._choose_card(aoe_weak_partial_cap_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat keeps AOE weak eligible when only the focus enemy is already weak and another target needs weak to prevent lethal")
	var aoe_weak_marginal_value_fixture = _combat_choice_fixture(30, 0, 20, 40, [
		{"id": "fixture_marginal_aoe_weak", "type": "skill", "target": "all_enemies", "cost": 1, "effects": [{"type": "apply_status", "target": "all_enemies", "status": "weak", "amount": 1}]},
		{"id": "fixture_marginal_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 3}]},
	])
	(aoe_weak_marginal_value_fixture.enemies[0] as Dictionary)["statuses"] = {"weak": 1}
	aoe_weak_marginal_value_fixture.enemies.append({"id": "fixture_zero_threat_unweakened_enemy", "hp": 40, "max_hp": 40, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 0, "hits": 1}}})
	_check(int(simulator._choose_card(aoe_weak_marginal_value_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat values only the missing target's marginal AOE weak benefit")
	var aoe_weak_block_marginal_fixture = _combat_choice_fixture(30, 0, 20, 40, [
		{"id": "fixture_marginal_block_aoe_weak", "type": "skill", "target": "all_enemies", "cost": 1, "effects": [{"type": "apply_status", "target": "all_enemies", "status": "weak", "amount": 1}]},
		{"id": "fixture_marginal_block_followup", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 15}]},
		{"id": "fixture_marginal_block_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 3}]},
	])
	(aoe_weak_block_marginal_fixture.enemies[0] as Dictionary)["statuses"] = {"weak": 1}
	aoe_weak_block_marginal_fixture.enemies.append({"id": "fixture_zero_threat_block_target", "hp": 40, "max_hp": 40, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 0, "hits": 1}}})
	_check(int(simulator._choose_card(aoe_weak_block_marginal_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat does not award a block-starter bonus when AOE weak has zero marginal prevention")
	var burn_starter_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_burn_starter", "type": "skill", "target": "enemy", "cost": 0, "effects": [{"type": "apply_status", "target": "enemy", "status": "burn", "amount": 2}]},
		{"id": "fixture_burn_payoff", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 8}]},
	])
	_check(int(simulator._choose_card(burn_starter_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat plays a zero-cost burn starter before spending energy on its payoff")
	var saturated_burn_fixture = _combat_choice_fixture(30, 0, 0, 40, burn_starter_fixture.hand)
	(saturated_burn_fixture.enemies[0] as Dictionary)["statuses"] = {"burn": 3}
	_check(int(simulator._choose_card(saturated_burn_fixture, "competent-combat-v1").get("hand_index", -1)) == 1, "competent combat does not reapply already sufficient burn")
	var ember_momentum_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_ember_momentum", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "gain_momentum", "amount": 1}]},
		{"id": "fixture_ember_payoff", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 4, "bonus_if_momentum_at_least": 3, "bonus": 12}]},
	])
	ember_momentum_fixture.player["momentum"] = 2
	_check(int(simulator._choose_card(ember_momentum_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "Ember fixture gains momentum before the threshold payoff")
	var saturated_momentum_fixture = _combat_choice_fixture(30, 0, 0, 40, ember_momentum_fixture.hand)
	saturated_momentum_fixture.player["momentum"] = 3
	_check(int(simulator._choose_card(saturated_momentum_fixture, "competent-combat-v1").get("hand_index", -1)) == 1, "Ember fixture spends an already active momentum threshold instead of over-starting")
	var momentum_cost_followup_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_momentum_cost_starter", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "gain_momentum", "amount": 3}]},
		{"id": "fixture_momentum_cost_payoff", "type": "attack", "target": "enemy", "cost": 2, "effects": [{"type": "lose_momentum", "amount": 2}, {"type": "damage", "amount": 22}]},
		{"id": "fixture_momentum_cost_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 8}]},
	])
	_check(int(simulator._choose_card(momentum_cost_followup_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat recognizes a momentum starter that enables a lose-momentum follow-up")
	var arc_energy_fixture = _combat_choice_fixture(30, 0, 0, 40, [
		{"id": "fixture_arc_energy", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "draw", "amount": 1}, {"type": "gain_energy", "amount": 2}]},
		{"id": "fixture_arc_payoff", "type": "attack", "target": "enemy", "cost": 2, "effects": [{"type": "damage", "amount": 8}]},
	])
	_check(int(simulator._choose_card(arc_energy_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "Arc fixture uses net energy generation before the payoff")
	var pyre_safe_fixture = _combat_choice_fixture(6, 0, 0, 40, [
		{"id": "fixture_pyre_safe_start", "type": "skill", "target": "self", "cost": 0, "effects": [{"type": "damage_self", "amount": 2}, {"type": "apply_status", "target": "self", "status": "burn", "amount": 1}, {"type": "draw", "amount": 1}]},
		{"id": "fixture_pyre_payoff", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 8}]},
	])
	_check(int(simulator._choose_card(pyre_safe_fixture, "competent-combat-v1").get("hand_index", -1)) == 0, "Pyre fixture accepts survivable self-damage and burn setup")
	var pyre_unsafe_fixture = _combat_choice_fixture(2, 0, 0, 10, [
		{"id": "fixture_pyre_unsafe_lethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 10}, {"type": "damage_self", "amount": 2}]},
		{"id": "fixture_pyre_safe_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 5}]},
	])
	var pyre_actual_order_fixture = _combat_choice_fixture(2, 0, 0, 10, pyre_unsafe_fixture.hand)
	_check(pyre_actual_order_fixture.play_card(0, 0) and pyre_actual_order_fixture.phase == "lost", "CombatState resolves post-lethal self-damage and records player loss")
	_check(int(simulator._choose_card(pyre_unsafe_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "Pyre fixture rejects a card whose real resolution order kills the player")
	var thorn_lethal_fixture = _combat_choice_fixture(2, 0, 0, 4, [
		{"id": "fixture_thorn_fatal_lethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 2, "hits": 2}]},
		{"id": "fixture_thorn_safe_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
	])
	(thorn_lethal_fixture.enemies[0] as Dictionary)["statuses"] = {"thorn": 1}
	var thorn_actual_order_fixture = _combat_choice_fixture(2, 0, 0, 4, thorn_lethal_fixture.hand)
	(thorn_actual_order_fixture.enemies[0] as Dictionary)["statuses"] = {"thorn": 1}
	_check(thorn_actual_order_fixture.play_card(0, 0) and thorn_actual_order_fixture.phase == "lost", "CombatState resolves thorn once per attack hit and can turn lethal into a player loss")
	_check(int(simulator._choose_card(thorn_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat rejects an attack whose target thorn kills the player")
	var consumed_status_thorn_fixture = _combat_choice_fixture(4, 0, 0, 8, [
		{"id": "fixture_consumed_status_thorn_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 2}, {"type": "damage", "amount": 2, "hits": 3}]},
		{"id": "fixture_consumed_status_safe_skill", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "draw", "amount": 1}]},
	])
	(consumed_status_thorn_fixture.enemies[0] as Dictionary)["statuses"] = {"vulnerable": 1, "thorn": 1}
	var consumed_status_thorn_actual = _combat_choice_fixture(4, 0, 0, 8, consumed_status_thorn_fixture.hand)
	(consumed_status_thorn_actual.enemies[0] as Dictionary)["statuses"] = {"vulnerable": 1, "thorn": 1}
	_check(consumed_status_thorn_actual.play_card(0, 0) and consumed_status_thorn_actual.phase == "lost", "CombatState consumes vulnerable after the first damage effect and requires four thorn hits for the real lethal")
	_check(int(simulator._choose_card(consumed_status_thorn_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat consumes vulnerable between damage effects when estimating lethal thorn cost")
	var consumed_player_weak_fixture = _combat_choice_fixture(30, 0, 8, 6, [
		{"id": "fixture_consumed_player_weak_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 2}, {"type": "damage", "amount": 5}]},
		{"id": "fixture_consumed_player_weak_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	consumed_player_weak_fixture.player["statuses"] = {"weak": 1}
	var consumed_player_weak_actual = _combat_choice_fixture(30, 0, 8, 6, consumed_player_weak_fixture.hand)
	consumed_player_weak_actual.player["statuses"] = {"weak": 1}
	_check(consumed_player_weak_actual.play_card(0, 0) and consumed_player_weak_actual.phase == "won", "CombatState consumes player weak after the first damage effect so the second effect completes lethal")
	_check(int(simulator._choose_card(consumed_player_weak_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat consumes player weak between damage effects when identifying immediate lethal")
	var phase_thorn_card := {"id": "fixture_phase_thorn_fatal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 37, "hits": 3}]}
	var phase_thorn_fixture = _combat_choice_fixture(3, 0, 0, 70, [
		phase_thorn_card,
		{"id": "fixture_phase_thorn_safe_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
	])
	phase_thorn_fixture.enemies = [{
		"id": "fixture_phase_thorn_guard",
		"name": "阶段尖刺守卫",
		"hp": 70,
		"max_hp": 100,
		"block": 0,
		"statuses": {"thorn": 1},
		"phase_index": -1,
		"data": {"phases": [{"id": "guarded", "hp_percent_below": 66, "on_enter_effects": [{"type": "block", "amount": 8, "target": "self"}], "actions": []}]},
		"current_action": {"intent": {"type": "attack", "amount": 0, "hits": 1}},
	}]
	var phase_thorn_actual = _combat_choice_fixture(3, 0, 0, 70, phase_thorn_fixture.hand)
	phase_thorn_actual.enemies = phase_thorn_fixture.enemies.duplicate(true)
	_check(phase_thorn_actual.play_card(0, 0) and phase_thorn_actual.phase == "lost", "CombatState phase block forces the third thorn hit and kills the player")
	_check(int(simulator._choose_card(phase_thorn_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat includes boss phase block when estimating thorn HP cost")
	var growth_attack_relics := {"fixture_offense_forging": {"effects": [{"trigger": "card_played", "type": "bonus_damage", "amount": 2, "card_type": "attack", "once_per_combat": true}]}}
	var growth_thorn_fixture = _combat_choice_fixture(2, 0, 0, 4, [
		{"id": "fixture_growth_thorn_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 2}]},
		{"id": "fixture_growth_thorn_safe_skill", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "draw", "amount": 1}]},
	])
	(growth_thorn_fixture.enemies[0] as Dictionary)["statuses"] = {"thorn": 1}
	growth_thorn_fixture.owned_relic_ids = ["fixture_offense_forging"]
	growth_thorn_fixture.relics_by_id = growth_attack_relics.duplicate(true)
	var growth_thorn_actual = _combat_choice_fixture(2, 0, 0, 4, growth_thorn_fixture.hand)
	(growth_thorn_actual.enemies[0] as Dictionary)["statuses"] = {"thorn": 1}
	growth_thorn_actual.owned_relic_ids = growth_thorn_fixture.owned_relic_ids.duplicate(true)
	growth_thorn_actual.relics_by_id = growth_attack_relics.duplicate(true)
	_check(growth_thorn_actual.play_card(0, 0) and growth_thorn_actual.phase == "lost", "CombatState card-played bonus damage triggers a second thorn hit and kills the player")
	_check(int(simulator._choose_card(growth_thorn_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat includes card-played bonus damage in thorn HP cost")
	var growth_lethal_fixture = _combat_choice_fixture(30, 0, 0, 4, [
		{"id": "fixture_growth_lethal_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 2}]},
		{"id": "fixture_growth_lethal_draw", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "draw", "amount": 4}]},
	])
	growth_lethal_fixture.owned_relic_ids = ["fixture_offense_forging"]
	growth_lethal_fixture.relics_by_id = growth_attack_relics.duplicate(true)
	_check(int(simulator._choose_card(growth_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat recognizes lethal completed by a card-played bonus damage source")
	var post_status_growth_fixture = _combat_choice_fixture(30, 0, 8, 9, [
		{"id": "fixture_post_status_growth_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 6}, {"type": "apply_status", "target": "enemy", "status": "vulnerable", "amount": 1}]},
		{"id": "fixture_post_status_growth_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	post_status_growth_fixture.owned_relic_ids = ["fixture_offense_forging"]
	post_status_growth_fixture.relics_by_id = growth_attack_relics.duplicate(true)
	var post_status_growth_actual = _combat_choice_fixture(30, 0, 8, 9, post_status_growth_fixture.hand)
	post_status_growth_actual.owned_relic_ids = post_status_growth_fixture.owned_relic_ids.duplicate(true)
	post_status_growth_actual.relics_by_id = growth_attack_relics.duplicate(true)
	_check(post_status_growth_actual.play_card(0, 0) and post_status_growth_actual.phase == "won", "CombatState applies card vulnerable before card-played bonus damage and completes lethal")
	_check(int(simulator._choose_card(post_status_growth_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat uses the post-card vulnerable snapshot for bonus-damage lethal")
	var post_momentum_growth_relics := {"fixture_momentum_forging": {"effects": [{"trigger": "card_played", "type": "bonus_damage", "amount": 2, "card_type": "attack", "requires_momentum_at_least": 2, "once_per_combat": true}]}}
	var post_momentum_growth_fixture = _combat_choice_fixture(30, 0, 8, 4, [
		{"id": "fixture_post_momentum_growth_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "gain_momentum", "amount": 2}, {"type": "damage", "amount": 2}]},
		{"id": "fixture_post_momentum_growth_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	post_momentum_growth_fixture.owned_relic_ids = ["fixture_momentum_forging"]
	post_momentum_growth_fixture.relics_by_id = post_momentum_growth_relics.duplicate(true)
	var post_momentum_growth_actual = _combat_choice_fixture(30, 0, 8, 4, post_momentum_growth_fixture.hand)
	post_momentum_growth_actual.owned_relic_ids = post_momentum_growth_fixture.owned_relic_ids.duplicate(true)
	post_momentum_growth_actual.relics_by_id = post_momentum_growth_relics.duplicate(true)
	_check(post_momentum_growth_actual.play_card(0, 0) and post_momentum_growth_actual.phase == "won", "CombatState evaluates card-played bonus momentum conditions after resolving the card")
	_check(int(simulator._choose_card(post_momentum_growth_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat uses post-card momentum for bonus-damage lethal")
	var thorn_momentum_relics := {
		"fixture_pain_engine": {"effects": [{"trigger": "player_hp_lost", "type": "gain_momentum", "amount": 1, "min_hp_lost": 1, "once_per_turn": true}]},
		"fixture_thorn_momentum_forging": {"effects": [{"trigger": "card_played", "type": "bonus_damage", "amount": 1, "requires_momentum_at_least": 1}]},
	}
	var thorn_momentum_fixture = _combat_choice_fixture(5, 0, 8, 3, [
		{"id": "fixture_thorn_momentum_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "damage", "amount": 1, "requires_momentum_at_least": 1}]},
		{"id": "fixture_thorn_momentum_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	(thorn_momentum_fixture.enemies[0] as Dictionary)["statuses"] = {"thorn": 1}
	thorn_momentum_fixture.owned_relic_ids = ["fixture_pain_engine", "fixture_thorn_momentum_forging"]
	thorn_momentum_fixture.relics_by_id = thorn_momentum_relics.duplicate(true)
	var thorn_momentum_actual = _combat_choice_fixture(5, 0, 8, 3, thorn_momentum_fixture.hand)
	(thorn_momentum_actual.enemies[0] as Dictionary)["statuses"] = {"thorn": 1}
	thorn_momentum_actual.owned_relic_ids = thorn_momentum_fixture.owned_relic_ids.duplicate(true)
	thorn_momentum_actual.relics_by_id = thorn_momentum_relics.duplicate(true)
	_check(thorn_momentum_actual.play_card(0, 0) and thorn_momentum_actual.phase == "won" and int(thorn_momentum_actual.player.get("momentum", 0)) == 1, "CombatState thorn HP loss grants momentum before later card effects and card-played bonus damage")
	_check(int(simulator._choose_card(thorn_momentum_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat propagates thorn-triggered momentum into later damage and card-played lethal")
	var nested_card_played_relics := {
		"fixture_card_guard": {"effects": [{"trigger": "card_played", "type": "gain_block", "amount": 1}]},
		"fixture_guard_charge": {"effects": [{"trigger": "block_gained", "type": "gain_momentum", "amount": 1, "once_per_turn": true}]},
		"fixture_charged_strike": {"effects": [{"trigger": "card_played", "type": "bonus_damage", "amount": 2, "requires_momentum_at_least": 1}]},
	}
	var nested_card_played_fixture = _combat_choice_fixture(30, 0, 8, 3, [
		{"id": "fixture_nested_card_played_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
		{"id": "fixture_nested_card_played_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	nested_card_played_fixture.owned_relic_ids = ["fixture_card_guard", "fixture_guard_charge", "fixture_charged_strike"]
	nested_card_played_fixture.relics_by_id = nested_card_played_relics.duplicate(true)
	var nested_card_played_actual = _combat_choice_fixture(30, 0, 8, 3, nested_card_played_fixture.hand)
	nested_card_played_actual.owned_relic_ids = nested_card_played_fixture.owned_relic_ids.duplicate(true)
	nested_card_played_actual.relics_by_id = nested_card_played_relics.duplicate(true)
	_check(nested_card_played_actual.play_card(0, 0) and nested_card_played_actual.phase == "won" and int(nested_card_played_actual.player.get("momentum", 0)) == 1, "CombatState card-played block triggers block-gained momentum before a later conditional bonus damage relic")
	_check(int(simulator._choose_card(nested_card_played_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat resolves nested card-played block triggers before later bonus damage")
	var card_created_relics := {"fixture_ember_ritual": {"effects": [{"trigger": "card_created", "type": "damage_all_enemies", "amount": 2, "card_id": "searing_wound", "once_per_combat": true}]}}
	var card_created_lethal_fixture = _combat_choice_fixture(10, 0, 20, 2, [
		{"id": "fixture_card_created_lethal", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "create_card", "card_id": "searing_wound", "destination": "discard", "amount": 1}]},
		{"id": "fixture_card_created_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	card_created_lethal_fixture.cards_by_id = {"searing_wound": {"id": "searing_wound", "name": "灼伤", "type": "status", "cost": 1, "effects": []}}
	card_created_lethal_fixture.owned_relic_ids = ["fixture_ember_ritual"]
	card_created_lethal_fixture.relics_by_id = card_created_relics.duplicate(true)
	var card_created_lethal_actual = _combat_choice_fixture(10, 0, 20, 2, card_created_lethal_fixture.hand)
	card_created_lethal_actual.cards_by_id = card_created_lethal_fixture.cards_by_id.duplicate(true)
	card_created_lethal_actual.owned_relic_ids = card_created_lethal_fixture.owned_relic_ids.duplicate(true)
	card_created_lethal_actual.relics_by_id = card_created_relics.duplicate(true)
	_check(card_created_lethal_actual.play_card(0, 0) and card_created_lethal_actual.phase == "won", "CombatState create-card immediately triggers card-created all-enemy lethal damage")
	_check(int(simulator._choose_card(card_created_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat recognizes create-card relic damage as immediate lethal")
	var block_break_lethal_fixture = _combat_choice_fixture(30, 0, 20, 4, [
		{"id": "fixture_block_break_lethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 3}]},
		{"id": "fixture_block_break_overblock", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	(block_break_lethal_fixture.enemies[0] as Dictionary)["block"] = 3
	block_break_lethal_fixture.owned_relic_ids = ["shield_break_wedge"]
	block_break_lethal_fixture.relics_by_id = {"shield_break_wedge": simulator._relic_by_id("shield_break_wedge").duplicate(true)}
	var block_break_lethal_actual = _combat_choice_fixture(30, 0, 20, 4, block_break_lethal_fixture.hand)
	(block_break_lethal_actual.enemies[0] as Dictionary)["block"] = 3
	block_break_lethal_actual.owned_relic_ids = block_break_lethal_fixture.owned_relic_ids.duplicate(true)
	block_break_lethal_actual.relics_by_id = block_break_lethal_fixture.relics_by_id.duplicate(true)
	_check(block_break_lethal_actual.play_card(0, 0) and block_break_lethal_actual.phase == "won", "CombatState shield-break relic damage completes immediate lethal")
	_check(simulator._card_has_immediate_lethal(block_break_lethal_fixture, block_break_lethal_fixture.hand[0], 0), "competent combat includes enemy-block-broken relic damage in immediate lethal")
	_check(int(simulator._choose_card(block_break_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat prioritizes a shield-break relic lethal over defensive scoring")
	var bonus_break_thorn_card := {"id": "fixture_bonus_break_thorn", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var bonus_break_thorn_fixture = _combat_choice_fixture(4, 0, 0, 4, [bonus_break_thorn_card])
	(bonus_break_thorn_fixture.enemies[0] as Dictionary)["block"] = 3
	(bonus_break_thorn_fixture.enemies[0] as Dictionary)["statuses"] = {"thorn": 2}
	bonus_break_thorn_fixture.owned_relic_ids = ["offense_forging", "shield_break_wedge"]
	bonus_break_thorn_fixture.relics_by_id = {
		"offense_forging": simulator._progression_entry_by_id("deck_masteries", "offense_forging").duplicate(true),
		"shield_break_wedge": simulator._relic_by_id("shield_break_wedge").duplicate(true),
	}
	var bonus_break_thorn_actual = _combat_choice_fixture(4, 0, 0, 4, [bonus_break_thorn_card])
	(bonus_break_thorn_actual.enemies[0] as Dictionary)["block"] = 3
	(bonus_break_thorn_actual.enemies[0] as Dictionary)["statuses"] = {"thorn": 2}
	bonus_break_thorn_actual.owned_relic_ids = bonus_break_thorn_fixture.owned_relic_ids.duplicate(true)
	bonus_break_thorn_actual.relics_by_id = bonus_break_thorn_fixture.relics_by_id.duplicate(true)
	_check(bonus_break_thorn_actual.play_card(0, 0) and bonus_break_thorn_actual.phase == "lost" and int(bonus_break_thorn_actual.player.get("hp", -1)) == 0, "CombatState still resolves bonus-attack thorn after shield-break relic damage kills the enemy")
	_check(simulator._card_player_hp_cost_is_fatal(bonus_break_thorn_fixture, bonus_break_thorn_card, 0), "competent combat counts bonus-attack thorn even when shield-break relic damage completes lethal")
	var counter_pressure_lethal_fixture = _combat_choice_fixture(5, 0, 0, 2, [
		{"id": "fixture_counter_pressure_lethal", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 1}]},
		{"id": "fixture_counter_pressure_nonlethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
	])
	counter_pressure_lethal_fixture.player["statuses"] = {"counter_pressure": 1}
	(counter_pressure_lethal_fixture.enemies[0] as Dictionary)["statuses"] = {"thorn": 3}
	var counter_pressure_lethal_actual = _combat_choice_fixture(5, 0, 0, 2, counter_pressure_lethal_fixture.hand)
	counter_pressure_lethal_actual.player["statuses"] = {"counter_pressure": 1}
	(counter_pressure_lethal_actual.enemies[0] as Dictionary)["statuses"] = {"thorn": 3}
	_check(counter_pressure_lethal_actual.play_card(0, 0) and counter_pressure_lethal_actual.phase == "won", "CombatState block gain triggers counter-pressure lethal damage")
	_check(int(counter_pressure_lethal_actual.player.get("hp", 0)) == 5, "CombatState counter-pressure power damage does not trigger enemy thorn")
	_check(simulator._card_has_immediate_lethal(counter_pressure_lethal_fixture, counter_pressure_lethal_fixture.hand[0], 0), "competent combat includes deterministic single-target counter-pressure lethal")
	_check(int(simulator._choose_card(counter_pressure_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat prioritizes a counter-pressure block lethal")
	var phase_created_lethal_fixture = _combat_choice_fixture(30, 0, 20, 34, [
		{"id": "fixture_phase_created_lethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
		{"id": "fixture_phase_created_overblock", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	phase_created_lethal_fixture.enemies = [
		{"id": "fixture_phase_creator", "hp": 34, "max_hp": 100, "block": 0, "statuses": {}, "phase_index": 0, "data": {"phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": []},
			{"id": "heart_exposed", "hp_percent_below": 33, "on_enter_effects": [{"type": "create_card", "target": "player", "card_id": "searing_wound", "destination": "discard", "amount": 2}]},
		]}, "current_action": {"intent": {"type": "attack", "amount": 20, "hits": 1}}},
		{"id": "fixture_phase_created_secondary", "hp": 6, "max_hp": 6, "block": 0, "statuses": {}, "phase_index": -1, "data": {}, "current_action": {"intent": {"type": "attack", "amount": 0, "hits": 1}}},
	]
	phase_created_lethal_fixture.cards_by_id = {"searing_wound": {"id": "searing_wound", "name": "灼伤", "type": "status", "cost": 1, "effects": []}}
	phase_created_lethal_fixture.owned_relic_ids = ["burn_needle"]
	phase_created_lethal_fixture.relics_by_id = {"burn_needle": simulator._relic_by_id("burn_needle").duplicate(true)}
	var phase_created_lethal_actual = _combat_choice_fixture(30, 0, 20, 34, phase_created_lethal_fixture.hand)
	phase_created_lethal_actual.enemies = phase_created_lethal_fixture.enemies.duplicate(true)
	phase_created_lethal_actual.cards_by_id = phase_created_lethal_fixture.cards_by_id.duplicate(true)
	phase_created_lethal_actual.owned_relic_ids = phase_created_lethal_fixture.owned_relic_ids.duplicate(true)
	phase_created_lethal_actual.relics_by_id = phase_created_lethal_fixture.relics_by_id.duplicate(true)
	_check(phase_created_lethal_actual.play_card(0, 0) and int((phase_created_lethal_actual.enemies[1] as Dictionary).get("hp", -1)) == 0, "CombatState phase-entry card creation triggers card-created AOE lethal")
	_check(simulator._card_has_immediate_lethal(phase_created_lethal_fixture, phase_created_lethal_fixture.hand[0], 0), "competent combat includes phase-entry create-card relic damage in immediate lethal")
	_check(int(simulator._choose_card(phase_created_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat prioritizes phase-entry card-created AOE lethal")
	var phase_intent_card := {"id": "fixture_phase_intent_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var phase_intent_fixture = _combat_choice_fixture(5, 0, 2, 34, [phase_intent_card])
	phase_intent_fixture.enemies = [{
		"id": "fixture_phase_intent_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": [{"intent": {"type": "attack", "amount": 2, "hits": 1}, "effects": [{"type": "damage", "amount": 2, "hits": 1, "target": "player"}]}]},
			{"id": "enraged", "hp_percent_below": 33, "on_enter_effects": [], "actions": [{"intent": {"type": "attack", "amount": 10, "hits": 1}, "effects": [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]}]},
		]},
		"current_action": {"intent": {"type": "attack", "amount": 2, "hits": 1}, "effects": [{"type": "damage", "amount": 2, "hits": 1, "target": "player"}]},
	}]
	var phase_intent_actual = _combat_choice_fixture(5, 0, 2, 34, [phase_intent_card])
	phase_intent_actual.enemies = phase_intent_fixture.enemies.duplicate(true)
	_check(phase_intent_actual.play_card(0, 0) and int((phase_intent_actual.enemies[0] as Dictionary).get("current_action", {}).get("intent", {}).get("amount", 0)) == 10, "CombatState switches to the new phase's first action immediately after crossing the threshold")
	phase_intent_actual.end_player_turn()
	_check(phase_intent_actual.phase == "lost", "CombatState resolves the new phase's lethal action on the same enemy turn")
	_check(simulator._estimated_incoming_damage_after_card_statuses(phase_intent_fixture, phase_intent_card, 0) == 10, "competent combat estimates incoming damage from the newly entered phase action")
	var phase_player_status_card := {"id": "fixture_phase_player_status", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "block", "amount": 6}]}
	var phase_player_status_fixture = _combat_choice_fixture(5, 0, 2, 34, [phase_player_status_card])
	phase_player_status_fixture.enemies = [{
		"id": "fixture_phase_player_status_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": [{"intent": {"type": "attack", "amount": 2, "hits": 1}, "effects": [{"type": "damage", "amount": 2, "hits": 1, "target": "player"}]}]},
			{"id": "exposing", "hp_percent_below": 33, "on_enter_effects": [{"type": "apply_status", "target": "player", "status": "vulnerable", "amount": 1}], "actions": [{"intent": {"type": "attack", "amount": 10, "hits": 1}, "effects": [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]}]},
		]},
		"current_action": {"intent": {"type": "attack", "amount": 2, "hits": 1}, "effects": [{"type": "damage", "amount": 2, "hits": 1, "target": "player"}]},
	}]
	var phase_player_status_actual = _combat_choice_fixture(5, 0, 2, 34, [phase_player_status_card])
	phase_player_status_actual.enemies = phase_player_status_fixture.enemies.duplicate(true)
	_check(phase_player_status_actual.play_card(0, 0) and int(phase_player_status_actual.player.get("block", 0)) == 6 and int(phase_player_status_actual.player.get("statuses", {}).get("vulnerable", 0)) == 1, "CombatState applies a player-target phase status before the later card block")
	phase_player_status_actual.end_player_turn()
	_check(phase_player_status_actual.phase == "lost", "CombatState phase-entry vulnerable makes the new phase attack lethal through later block")
	_check(simulator._estimated_incoming_damage_after_card_statuses(phase_player_status_fixture, phase_player_status_card, 0) == 15, "competent combat includes player-target phase status in new-action incoming damage")
	var phase_player_damage_card := {"id": "fixture_phase_player_damage", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var phase_player_damage_fixture = _combat_choice_fixture(1, 0, 0, 34, [phase_player_damage_card])
	phase_player_damage_fixture.enemies = [{
		"id": "fixture_phase_player_damage_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": []},
			{"id": "eruption", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 1, "hits": 1}], "actions": []},
		]},
		"current_action": {},
	}]
	var phase_player_damage_actual = _combat_choice_fixture(1, 0, 0, 34, [phase_player_damage_card])
	phase_player_damage_actual.enemies = phase_player_damage_fixture.enemies.duplicate(true)
	_check(phase_player_damage_actual.play_card(0, 0) and phase_player_damage_actual.phase == "lost" and int(phase_player_damage_actual.player.get("hp", -1)) == 0, "CombatState resolves player-target phase damage during the card")
	_check(simulator._card_player_hp_cost_is_fatal(phase_player_damage_fixture, phase_player_damage_card, 0), "competent combat treats lethal player-target phase damage as a fatal card cost")
	var phase_player_thorn_card := {"id": "fixture_phase_player_thorn", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var phase_player_thorn_fixture = _combat_choice_fixture(20, 0, 0, 2, [phase_player_thorn_card])
	phase_player_thorn_fixture.player["statuses"] = {"thorn": 1}
	phase_player_thorn_fixture.enemies = [{
		"id": "fixture_phase_player_thorn_enemy",
		"hp": 2,
		"max_hp": 6,
		"block": 0,
		"statuses": {},
		"phase_index": -1,
		"data": {"actions": [], "phases": [{"id": "thorn_window", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 1, "hits": 1}], "actions": []}]},
		"current_action": {},
	}]
	var phase_player_thorn_actual = _combat_choice_fixture(20, 0, 0, 2, [phase_player_thorn_card])
	phase_player_thorn_actual.player["statuses"] = {"thorn": 1}
	phase_player_thorn_actual.enemies = phase_player_thorn_fixture.enemies.duplicate(true)
	_check(phase_player_thorn_actual.play_card(0, 0) and phase_player_thorn_actual.phase == "won" and int((phase_player_thorn_actual.enemies[0] as Dictionary).get("hp", -1)) == 0, "CombatState applies player thorn after each phase-entry damage hit and can complete lethal")
	_check(simulator._card_has_immediate_lethal(phase_player_thorn_fixture, phase_player_thorn_card, 0), "competent combat includes player-thorn lethal triggered by phase-entry damage")
	var phase_action_fallback_card := {"id": "fixture_phase_action_fallback", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var phase_action_fallback_fixture = _combat_choice_fixture(20, 0, 2, 34, [phase_action_fallback_card])
	phase_action_fallback_fixture.enemies = [{
		"id": "fixture_phase_action_fallback_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {
			"actions": [{"intent": {"type": "attack", "amount": 10, "hits": 1}, "effects": [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]}],
			"phases": [
				{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": [{"intent": {"type": "attack", "amount": 2, "hits": 1}, "effects": [{"type": "damage", "amount": 2, "hits": 1, "target": "player"}]}]},
				{"id": "fallback", "hp_percent_below": 33, "on_enter_effects": [], "actions": []},
			],
		},
		"current_action": {"intent": {"type": "attack", "amount": 2, "hits": 1}, "effects": [{"type": "damage", "amount": 2, "hits": 1, "target": "player"}]},
	}]
	var phase_action_fallback_actual = _combat_choice_fixture(20, 0, 2, 34, [phase_action_fallback_card])
	phase_action_fallback_actual.enemies = phase_action_fallback_fixture.enemies.duplicate(true)
	_check(phase_action_fallback_actual.play_card(0, 0) and int((phase_action_fallback_actual.enemies[0] as Dictionary).get("current_action", {}).get("intent", {}).get("amount", 0)) == 10, "CombatState falls back to base enemy actions when a new phase has no actions")
	_check(simulator._estimated_incoming_damage_after_card_statuses(phase_action_fallback_fixture, phase_action_fallback_card, 0) == 10, "competent combat uses base enemy actions after entering an actionless phase")
	var recursive_phase_action_card := {"id": "fixture_recursive_phase_action", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var recursive_phase_action_fixture = _combat_choice_fixture(30, 0, 0, 35, [recursive_phase_action_card])
	recursive_phase_action_fixture.enemies = [{
		"id": "fixture_recursive_phase_action_enemy",
		"hp": 35,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"actions": [], "phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": []},
			{"id": "forge", "hp_percent_below": 34, "on_enter_effects": [{"type": "create_card", "target": "player", "card_id": "searing_wound", "destination": "discard", "amount": 1}], "actions": [{"intent": {"type": "attack", "amount": 5, "hits": 1}, "effects": [{"type": "damage", "amount": 5, "hits": 1, "target": "player"}]}]},
			{"id": "final", "hp_percent_below": 33, "on_enter_effects": [], "actions": [{"intent": {"type": "attack", "amount": 20, "hits": 1}, "effects": [{"type": "damage", "amount": 20, "hits": 1, "target": "player"}]}]},
		]},
		"current_action": {},
	}]
	recursive_phase_action_fixture.cards_by_id = {"searing_wound": {"id": "searing_wound", "name": "灼伤", "type": "status", "cost": 1, "effects": []}}
	recursive_phase_action_fixture.owned_relic_ids = ["fixture_recursive_phase_relic"]
	recursive_phase_action_fixture.relics_by_id = {"fixture_recursive_phase_relic": {"effects": [{"trigger": "card_created", "type": "damage_all_enemies", "amount": 2, "card_id": "searing_wound", "once_per_combat": true}]}}
	var recursive_phase_action_actual = _combat_choice_fixture(30, 0, 0, 35, [recursive_phase_action_card])
	recursive_phase_action_actual.enemies = recursive_phase_action_fixture.enemies.duplicate(true)
	recursive_phase_action_actual.cards_by_id = recursive_phase_action_fixture.cards_by_id.duplicate(true)
	recursive_phase_action_actual.owned_relic_ids = recursive_phase_action_fixture.owned_relic_ids.duplicate(true)
	recursive_phase_action_actual.relics_by_id = recursive_phase_action_fixture.relics_by_id.duplicate(true)
	_check(recursive_phase_action_actual.play_card(0, 0) and int((recursive_phase_action_actual.enemies[0] as Dictionary).get("phase_index", -1)) == 2 and int((recursive_phase_action_actual.enemies[0] as Dictionary).get("current_action", {}).get("intent", {}).get("amount", 0)) == 20, "CombatState keeps the newest phase action after a card-created relic recursively advances the same enemy")
	_check(simulator._estimated_incoming_damage_after_card_statuses(recursive_phase_action_fixture, recursive_phase_action_card, 0) == 20, "competent combat keeps the newest recursive phase action instead of restoring the outer phase action")
	var post_phase_block_fixture = _combat_choice_fixture(8, 0, 0, 34, [
		{"id": "fixture_post_phase_block", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "block", "amount": 7}]},
		{"id": "fixture_post_phase_resource", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "gain_energy", "amount": 1}]},
	])
	post_phase_block_fixture.enemies = [{
		"id": "fixture_post_phase_block_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"actions": [], "phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": []},
			{"id": "blast", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 7, "hits": 1}], "actions": []},
		]},
		"current_action": {},
	}]
	var post_phase_block_actual = _combat_choice_fixture(8, 0, 0, 34, post_phase_block_fixture.hand)
	post_phase_block_actual.enemies = post_phase_block_fixture.enemies.duplicate(true)
	_check(post_phase_block_actual.play_card(0, 0) and int(post_phase_block_actual.player.get("hp", 0)) == 1 and int(post_phase_block_actual.player.get("block", 0)) == 7, "CombatState resolves phase damage before the card's later block")
	var post_phase_resource_actual = _combat_choice_fixture(8, 0, 0, 34, post_phase_block_fixture.hand)
	post_phase_resource_actual.enemies = post_phase_block_fixture.enemies.duplicate(true)
	_check(post_phase_resource_actual.play_card(1, 0) and int(post_phase_resource_actual.player.get("hp", 0)) == 1 and int(post_phase_resource_actual.player.get("energy", 0)) == 3, "CombatState gives the alternate card the same phase damage before its later resource")
	_check(int(simulator._choose_card(post_phase_block_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat does not let post-phase block retroactively offset already resolved phase damage")
	var spent_initial_block_card := {"id": "fixture_spent_initial_block", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]}
	var spent_initial_block_fixture = _combat_choice_fixture(10, 5, 5, 34, [spent_initial_block_card])
	spent_initial_block_fixture.enemies = [{
		"id": "fixture_spent_initial_block_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"actions": [], "phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": []},
			{"id": "double_hit", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 5, "hits": 1}], "actions": [{"intent": {"type": "attack", "amount": 5, "hits": 1}, "effects": [{"type": "damage", "target": "player", "amount": 5, "hits": 1}]}]},
		]},
		"current_action": {},
	}]
	var spent_initial_block_actual = _combat_choice_fixture(10, 5, 5, 34, [spent_initial_block_card])
	spent_initial_block_actual.enemies = spent_initial_block_fixture.enemies.duplicate(true)
	_check(spent_initial_block_actual.play_card(0, 0) and int(spent_initial_block_actual.player.get("block", 0)) == 0 and int(spent_initial_block_actual.player.get("hp", 0)) == 10, "CombatState phase damage consumes all initial block before the new phase action")
	spent_initial_block_actual.end_player_turn()
	_check(int(spent_initial_block_actual.player.get("hp", 0)) == 5, "CombatState cannot reuse phase-spent initial block against the later action")
	var spent_initial_summary: Dictionary = simulator._estimated_card_survival_summary(spent_initial_block_fixture, spent_initial_block_card, 0)
	_check(int(spent_initial_summary.get("player_hp", 0)) == 10 and int(spent_initial_summary.get("remaining_block", -1)) == 0 and int(spent_initial_summary.get("future_incoming", 0)) == 5 and bool(spent_initial_summary.get("survives", false)), "competent survival summary preserves phase-spent initial block and post-card HP")
	var reduced_hp_survival_fixture = _combat_choice_fixture(10, 0, 0, 34, [
		{"id": "fixture_reduced_hp_risky", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "gain_energy", "amount": 1}]},
		{"id": "fixture_reduced_hp_safe", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "block", "amount": 6}]},
	])
	reduced_hp_survival_fixture.enemies = [{
		"id": "fixture_reduced_hp_survival_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"actions": [], "phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": []},
			{"id": "pressure", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 6, "hits": 1}], "actions": [{"intent": {"type": "attack", "amount": 6, "hits": 1}, "effects": [{"type": "damage", "target": "player", "amount": 6, "hits": 1}]}]},
		]},
		"current_action": {},
	}]
	var reduced_hp_risky_actual = _combat_choice_fixture(10, 0, 0, 34, reduced_hp_survival_fixture.hand)
	reduced_hp_risky_actual.enemies = reduced_hp_survival_fixture.enemies.duplicate(true)
	_check(reduced_hp_risky_actual.play_card(0, 0) and int(reduced_hp_risky_actual.player.get("hp", 0)) == 4, "CombatState phase damage reduces HP before the future action")
	reduced_hp_risky_actual.end_player_turn()
	_check(reduced_hp_risky_actual.phase == "lost", "CombatState future action kills the phase-damaged risky line")
	var reduced_hp_safe_actual = _combat_choice_fixture(10, 0, 0, 34, reduced_hp_survival_fixture.hand)
	reduced_hp_safe_actual.enemies = reduced_hp_survival_fixture.enemies.duplicate(true)
	_check(reduced_hp_safe_actual.play_card(1, 0) and int(reduced_hp_safe_actual.player.get("hp", 0)) == 4 and int(reduced_hp_safe_actual.player.get("block", 0)) == 6, "CombatState later block remains available for the future phase action")
	reduced_hp_safe_actual.end_player_turn()
	_check(reduced_hp_safe_actual.phase != "lost" and int(reduced_hp_safe_actual.player.get("hp", 0)) == 4, "CombatState later block saves the phase-damaged safe line")
	var reduced_hp_risky_summary: Dictionary = simulator._estimated_card_survival_summary(reduced_hp_survival_fixture, reduced_hp_survival_fixture.hand[0], 0)
	var reduced_hp_safe_summary: Dictionary = simulator._estimated_card_survival_summary(reduced_hp_survival_fixture, reduced_hp_survival_fixture.hand[1], 0)
	_check(int(reduced_hp_risky_summary.get("player_hp", 0)) == 4 and int(reduced_hp_risky_summary.get("remaining_block", -1)) == 0 and int(reduced_hp_risky_summary.get("future_incoming", 0)) == 6 and not bool(reduced_hp_risky_summary.get("survives", true)), "competent survival summary rejects future lethal against phase-reduced HP")
	_check(int(reduced_hp_safe_summary.get("player_hp", 0)) == 4 and int(reduced_hp_safe_summary.get("remaining_block", 0)) == 6 and bool(reduced_hp_safe_summary.get("survives", false)), "competent survival summary keeps post-phase block for the future action")
	var spent_card_block_fixture = _combat_choice_fixture(5, 0, 0, 34, [
		{"id": "fixture_spent_card_block_safe", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "block", "amount": 4}, {"type": "damage", "amount": 1}]},
		{"id": "fixture_spent_card_block_risky", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "gain_energy", "amount": 1}, {"type": "damage", "amount": 1}]},
	])
	spent_card_block_fixture.enemies = [{
		"id": "fixture_spent_card_block_enemy",
		"hp": 34,
		"max_hp": 100,
		"block": 0,
		"statuses": {},
		"phase_index": 0,
		"data": {"actions": [], "phases": [
			{"id": "outer", "hp_percent_below": 66, "on_enter_effects": [], "actions": []},
			{"id": "guard_check", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 4, "hits": 1}], "actions": [{"intent": {"type": "attack", "amount": 4, "hits": 1}, "effects": [{"type": "damage", "target": "player", "amount": 4, "hits": 1}]}]},
		]},
		"current_action": {},
	}]
	var spent_card_block_safe_actual = _combat_choice_fixture(5, 0, 0, 34, spent_card_block_fixture.hand)
	spent_card_block_safe_actual.enemies = spent_card_block_fixture.enemies.duplicate(true)
	_check(spent_card_block_safe_actual.play_card(0, 0) and int(spent_card_block_safe_actual.player.get("hp", 0)) == 5 and int(spent_card_block_safe_actual.player.get("block", 0)) == 0, "CombatState spends the card's early block to absorb phase-entry damage")
	spent_card_block_safe_actual.end_player_turn()
	_check(spent_card_block_safe_actual.phase != "lost" and int(spent_card_block_safe_actual.player.get("hp", 0)) == 1, "CombatState confirms early card block keeps the phase line alive")
	var spent_card_block_risky_actual = _combat_choice_fixture(5, 0, 0, 34, spent_card_block_fixture.hand)
	spent_card_block_risky_actual.enemies = spent_card_block_fixture.enemies.duplicate(true)
	_check(spent_card_block_risky_actual.play_card(1, 0) and int(spent_card_block_risky_actual.player.get("hp", 0)) == 1, "CombatState phase damage reaches HP when the alternate card has no block")
	spent_card_block_risky_actual.end_player_turn()
	_check(spent_card_block_risky_actual.phase == "lost", "CombatState confirms the resource line dies to the future phase action")
	var spent_card_block_summary: Dictionary = simulator._estimated_card_survival_summary(spent_card_block_fixture, spent_card_block_fixture.hand[0], 0)
	_check(int(spent_card_block_summary.get("spent_card_block", 0)) == 4 and bool(spent_card_block_summary.get("survives", false)), "competent survival summary records card block consumed while preventing phase damage")
	_check(int(simulator._choose_card(spent_card_block_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat gives highest nonlethal priority to early card block that prevents phase death")
	var ordered_enemy_effect_card := {"id": "fixture_ordered_enemy_effects", "type": "skill", "target": "self", "cost": 0, "effects": [{"type": "draw", "amount": 1}]}
	var ordered_enemy_effect_fixture = _combat_choice_fixture(25, 0, 22, 40, [ordered_enemy_effect_card])
	ordered_enemy_effect_fixture.enemies = [
		{"id": "plague_alchemist", "hp": 40, "max_hp": 40, "block": 0, "statuses": {}, "data": {}, "current_action": {"id": "acid", "intent": {"type": "attack_debuff", "amount": 7, "status": "vulnerable"}, "effects": [{"type": "damage", "amount": 7, "target": "player"}, {"type": "apply_status", "target": "player", "status": "vulnerable", "amount": 1}]}},
		{"id": "bomb_mite", "hp": 24, "max_hp": 24, "block": 0, "statuses": {}, "data": {}, "current_action": {"id": "burst", "intent": {"type": "attack", "amount": 15, "hits": 1}, "effects": [{"type": "damage", "amount": 15, "hits": 1, "target": "player"}]}},
	]
	var ordered_enemy_effect_actual = _combat_choice_fixture(25, 0, 22, 40, [ordered_enemy_effect_card])
	ordered_enemy_effect_actual.enemies = ordered_enemy_effect_fixture.enemies.duplicate(true)
	_check(ordered_enemy_effect_actual.play_card(0, 0), "CombatState accepts the ordered enemy-effect fixture card")
	ordered_enemy_effect_actual.end_player_turn()
	_check(ordered_enemy_effect_actual.phase == "lost", "CombatState acid vulnerable increases the later enemy burst and kills the player")
	var ordered_enemy_effect_summary: Dictionary = simulator._estimated_card_survival_summary(ordered_enemy_effect_fixture, ordered_enemy_effect_card, 0)
	_check(int(ordered_enemy_effect_summary.get("future_incoming", 0)) == 30 and not bool(ordered_enemy_effect_summary.get("survives", true)), "competent survival summary executes enemy action effects in order across enemies")
	var burn_before_action_card := {"id": "fixture_burn_before_action", "type": "skill", "target": "self", "cost": 0, "effects": [{"type": "draw", "amount": 1}]}
	var burn_before_action_fixture = _combat_choice_fixture(10, 0, 20, 1, [burn_before_action_card])
	burn_before_action_fixture.enemies = [{
		"id": "fixture_burn_before_action_enemy",
		"hp": 1,
		"max_hp": 20,
		"block": 7,
		"statuses": {"burn": 1},
		"data": {},
		"current_action": {"id": "fatal_attack", "intent": {"type": "attack", "amount": 20, "hits": 1}, "effects": [{"type": "damage", "amount": 20, "hits": 1, "target": "player"}]},
	}]
	var burn_before_action_actual = _combat_choice_fixture(10, 0, 20, 1, [burn_before_action_card])
	burn_before_action_actual.enemies = burn_before_action_fixture.enemies.duplicate(true)
	_check(burn_before_action_actual.play_card(0, 0), "CombatState accepts the burn-before-action fixture card")
	burn_before_action_actual.end_player_turn()
	_check(burn_before_action_actual.phase == "won" and int(burn_before_action_actual.player.get("hp", 0)) == 10, "CombatState clears enemy block and burn defeats the enemy before its prepared action")
	var burn_before_action_summary: Dictionary = simulator._estimated_card_survival_summary(burn_before_action_fixture, burn_before_action_card, 0)
	_check(int(burn_before_action_summary.get("future_incoming", -1)) == 0 and bool(burn_before_action_summary.get("survives", false)), "competent survival summary resolves enemy turn-start burn before the enemy action")
	var burn_phase_kill_fixture = _combat_choice_fixture(10, 0, 20, 2, [burn_before_action_card])
	burn_phase_kill_fixture.player["statuses"] = {"thorn": 1}
	burn_phase_kill_fixture.enemies = [{
		"id": "fixture_burn_phase_kill_enemy",
		"hp": 2,
		"max_hp": 6,
		"block": 0,
		"statuses": {"burn": 1},
		"phase_index": -1,
		"data": {"phases": [{"id": "burn_phase", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 1, "hits": 1}], "actions": [{"id": "fatal_attack", "intent": {"type": "attack", "amount": 20, "hits": 1}, "effects": [{"type": "damage", "amount": 20, "hits": 1, "target": "player"}]}]}]},
		"current_action": {"id": "old_attack", "intent": {"type": "attack", "amount": 20, "hits": 1}, "effects": [{"type": "damage", "amount": 20, "hits": 1, "target": "player"}]},
	}]
	var burn_phase_kill_actual = _combat_choice_fixture(10, 0, 20, 2, [burn_before_action_card])
	burn_phase_kill_actual.player["statuses"] = {"thorn": 1}
	burn_phase_kill_actual.enemies = burn_phase_kill_fixture.enemies.duplicate(true)
	_check(burn_phase_kill_actual.play_card(0, 0), "CombatState accepts the burn phase-kill fixture card")
	burn_phase_kill_actual.end_player_turn()
	_check(burn_phase_kill_actual.phase == "won" and int(burn_phase_kill_actual.player.get("hp", 0)) == 9, "CombatState skips a boss action when phase-entry damage triggers player thorn lethal")
	var burn_phase_kill_summary: Dictionary = simulator._estimated_card_survival_summary(burn_phase_kill_fixture, burn_before_action_card, 0)
	_check(bool(burn_phase_kill_summary.get("survives", false)), "competent survival summary skips an action after burn-triggered phase effects kill the enemy")
	var burn_phase_incoming_fixture = _combat_choice_fixture(20, 0, 20, 2, [burn_before_action_card])
	burn_phase_incoming_fixture.enemies = [{
		"id": "fixture_burn_phase_incoming_enemy",
		"hp": 2,
		"max_hp": 6,
		"block": 0,
		"statuses": {"burn": 1},
		"phase_index": -1,
		"data": {"phases": [{"id": "burn_phase", "hp_percent_below": 33, "on_enter_effects": [{"type": "damage", "target": "player", "amount": 4, "hits": 1}], "actions": [{"id": "followup_attack", "intent": {"type": "attack", "amount": 6, "hits": 1}, "effects": [{"type": "damage", "amount": 6, "hits": 1, "target": "player"}]}]}]},
		"current_action": {"id": "old_attack", "intent": {"type": "attack", "amount": 20, "hits": 1}, "effects": [{"type": "damage", "amount": 20, "hits": 1, "target": "player"}]},
	}]
	var burn_phase_incoming_actual = _combat_choice_fixture(20, 0, 20, 2, [burn_before_action_card])
	burn_phase_incoming_actual.enemies = burn_phase_incoming_fixture.enemies.duplicate(true)
	_check(burn_phase_incoming_actual.play_card(0, 0), "CombatState accepts the burn phase-incoming fixture card")
	burn_phase_incoming_actual.end_player_turn()
	_check(burn_phase_incoming_actual.phase != "lost" and int(burn_phase_incoming_actual.player.get("hp", 0)) == 10, "CombatState combines burn-triggered phase-entry damage with the new phase action")
	var burn_phase_incoming_summary: Dictionary = simulator._estimated_card_survival_summary(burn_phase_incoming_fixture, burn_before_action_card, 0)
	_check(int(burn_phase_incoming_summary.get("future_incoming", 0)) == 10 and bool(burn_phase_incoming_summary.get("survives", false)), "competent survival summary includes burn-triggered phase-entry damage in future incoming")
	var all_enemy_prepare_fixture = _combat_choice_fixture(12, 0, 10, 30, [burn_before_action_card])
	all_enemy_prepare_fixture.enemies = [
		{
			"id": "fixture_prepare_attacker",
			"hp": 30,
			"max_hp": 30,
			"block": 0,
			"statuses": {},
			"data": {},
			"current_action": {"id": "attack", "intent": {"type": "attack", "amount": 10, "hits": 1}, "effects": [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]},
		},
		{
			"id": "fixture_prepare_phase_support",
			"hp": 2,
			"max_hp": 4,
			"block": 0,
			"statuses": {"burn": 1},
			"phase_index": -1,
			"data": {"phases": [{"id": "expose", "hp_percent_below": 25, "on_enter_effects": [{"type": "apply_status", "target": "player", "status": "vulnerable", "amount": 1}], "actions": []}]},
			"current_action": {},
		},
	]
	var all_enemy_prepare_actual = _combat_choice_fixture(12, 0, 10, 30, [burn_before_action_card])
	all_enemy_prepare_actual.enemies = all_enemy_prepare_fixture.enemies.duplicate(true)
	_check(all_enemy_prepare_actual.play_card(0, 0), "CombatState accepts the all-enemy prepare fixture card")
	all_enemy_prepare_actual.end_player_turn()
	_check(all_enemy_prepare_actual.phase == "lost", "CombatState prepares every enemy before the first action so the later burn phase can expose the player")
	var all_enemy_prepare_summary: Dictionary = simulator._estimated_card_survival_summary(all_enemy_prepare_fixture, burn_before_action_card, 0)
	_check(int(all_enemy_prepare_summary.get("future_incoming", 0)) == 15 and not bool(all_enemy_prepare_summary.get("survives", true)), "competent survival summary prepares all enemies before resolving any enemy action")
	var thorn_phase_multi_hit_card := {"id": "fixture_thorn_phase_multi_hit", "type": "skill", "target": "self", "cost": 0, "effects": [{"type": "draw", "amount": 1}]}
	var thorn_phase_multi_hit_fixture = _combat_choice_fixture(9, 0, 8, 2, [thorn_phase_multi_hit_card])
	thorn_phase_multi_hit_fixture.player["statuses"] = {"thorn": 1}
	thorn_phase_multi_hit_fixture.enemies = [{
		"id": "fixture_thorn_phase_multi_hit_enemy",
		"hp": 2,
		"max_hp": 6,
		"block": 0,
		"statuses": {},
		"phase_index": -1,
		"data": {"phases": [{"id": "enraged", "hp_percent_below": 33, "on_enter_effects": [{"type": "apply_status", "target": "self", "status": "strength", "amount": 1}], "actions": []}]},
		"current_action": {"id": "multi_hit", "intent": {"type": "attack", "amount": 4, "hits": 2}, "effects": [{"type": "damage", "amount": 4, "hits": 2, "target": "player"}]},
	}]
	var thorn_phase_multi_hit_actual = _combat_choice_fixture(9, 0, 8, 2, [thorn_phase_multi_hit_card])
	thorn_phase_multi_hit_actual.player["statuses"] = {"thorn": 1}
	thorn_phase_multi_hit_actual.enemies = thorn_phase_multi_hit_fixture.enemies.duplicate(true)
	_check(thorn_phase_multi_hit_actual.play_card(0, 0), "CombatState accepts the thorn phase multi-hit fixture card")
	thorn_phase_multi_hit_actual.end_player_turn()
	_check(thorn_phase_multi_hit_actual.phase == "lost", "CombatState recalculates later enemy hits after player thorn triggers a strength phase")
	var thorn_phase_multi_hit_summary: Dictionary = simulator._estimated_card_survival_summary(thorn_phase_multi_hit_fixture, thorn_phase_multi_hit_card, 0)
	_check(int(thorn_phase_multi_hit_summary.get("future_incoming", 0)) == 9 and not bool(thorn_phase_multi_hit_summary.get("survives", true)), "competent survival summary recalculates every enemy hit from the latest phase statuses")
	var next_turn_player_burn_card := {"id": "fixture_next_turn_player_burn", "type": "skill", "target": "self", "cost": 0, "effects": [{"type": "apply_status", "target": "self", "status": "burn", "amount": 2}]}
	var next_turn_player_burn_fixture = _combat_choice_fixture(2, 0, 0, 40, [next_turn_player_burn_card])
	var next_turn_player_burn_actual = _combat_choice_fixture(2, 0, 0, 40, [next_turn_player_burn_card])
	_check(next_turn_player_burn_actual.play_card(0, 0) and int(next_turn_player_burn_actual.player.get("statuses", {}).get("burn", 0)) == 2, "CombatState accepts the next-turn player-burn fixture card")
	next_turn_player_burn_actual.end_player_turn()
	_check(next_turn_player_burn_actual.phase == "lost" and int(next_turn_player_burn_actual.player.get("hp", -1)) == 0, "CombatState starts the next player turn and resolves lethal player burn after enemy actions")
	var next_turn_player_burn_summary: Dictionary = simulator._estimated_card_survival_summary(next_turn_player_burn_fixture, next_turn_player_burn_card, 0)
	_check(int(next_turn_player_burn_summary.get("future_incoming", -1)) == 0 and not bool(next_turn_player_burn_summary.get("survives", true)), "competent survival summary includes lethal player burn at the next player-turn start")
	var self_burn_choice_fixture = _combat_choice_fixture(2, 0, 0, 40, [
		{"id": "fixture_self_burn_high_damage", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 30}, {"type": "apply_status", "target": "self", "status": "burn", "amount": 2}]},
		{"id": "fixture_self_burn_safe_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
	])
	var self_burn_choice_risky_actual = _combat_choice_fixture(2, 0, 0, 40, self_burn_choice_fixture.hand)
	_check(self_burn_choice_risky_actual.play_card(0, 0), "CombatState accepts the high-damage self-burn fixture card")
	self_burn_choice_risky_actual.end_player_turn()
	_check(self_burn_choice_risky_actual.phase == "lost", "CombatState confirms the nonlethal high-damage self-burn line dies at the next player-turn start")
	var self_burn_choice_safe_actual = _combat_choice_fixture(2, 0, 0, 40, self_burn_choice_fixture.hand)
	_check(self_burn_choice_safe_actual.play_card(1, 0), "CombatState accepts the safe comparison attack")
	self_burn_choice_safe_actual.end_player_turn()
	_check(self_burn_choice_safe_actual.phase != "lost" and int(self_burn_choice_safe_actual.player.get("hp", 0)) == 2, "CombatState confirms the comparison attack survives without self burn")
	_check(int(simulator._choose_card(self_burn_choice_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat rejects a nonlethal high-damage card whose self burn kills at the next player-turn start")
	var partial_lethal_self_burn_fixture = _combat_choice_fixture(2, 0, 0, 1, [
		{"id": "fixture_partial_lethal_self_burn", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}, {"type": "apply_status", "target": "self", "status": "burn", "amount": 2}]},
		{"id": "fixture_partial_lethal_safe_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 1}]},
	])
	partial_lethal_self_burn_fixture.enemies = [
		{"id": "fixture_partial_lethal_target", "hp": 1, "max_hp": 1, "block": 0, "statuses": {}, "data": {"actions": []}, "current_action": {}},
		{"id": "fixture_partial_lethal_survivor", "hp": 20, "max_hp": 20, "block": 0, "statuses": {}, "data": {"actions": []}, "current_action": {}},
	]
	var partial_lethal_risky_actual = _combat_choice_fixture(2, 0, 0, 1, partial_lethal_self_burn_fixture.hand)
	partial_lethal_risky_actual.enemies = partial_lethal_self_burn_fixture.enemies.duplicate(true)
	_check(partial_lethal_risky_actual.play_card(0, 0), "CombatState accepts the partial-lethal self-burn fixture card")
	partial_lethal_risky_actual.end_player_turn()
	_check(partial_lethal_risky_actual.phase == "lost" and int((partial_lethal_risky_actual.enemies[1] as Dictionary).get("hp", 0)) > 0, "CombatState confirms partial lethal does not skip next-turn player burn while another enemy survives")
	var partial_lethal_safe_actual = _combat_choice_fixture(2, 0, 0, 1, partial_lethal_self_burn_fixture.hand)
	partial_lethal_safe_actual.enemies = partial_lethal_self_burn_fixture.enemies.duplicate(true)
	_check(partial_lethal_safe_actual.play_card(1, 0), "CombatState accepts the safe partial-lethal comparison card")
	partial_lethal_safe_actual.end_player_turn()
	_check(partial_lethal_safe_actual.phase != "lost" and int(partial_lethal_safe_actual.player.get("hp", 0)) == 2, "CombatState confirms the safe partial-lethal line survives without self burn")
	_check(int(simulator._choose_card(partial_lethal_self_burn_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent immediate lethal rejects a partial kill whose self burn is fatal on the next player turn")
	var card_played_energy_starter_fixture = _combat_choice_fixture(30, 0, 0, 20, [
		{"id": "fixture_card_played_energy_starter", "type": "attack", "target": "enemy", "cost": 0, "effects": [{"type": "damage", "amount": 1}]},
		{"id": "fixture_card_played_energy_spender", "type": "attack", "target": "enemy", "cost": 2, "effects": [{"type": "damage", "amount": 10}]},
		{"id": "fixture_card_played_energy_lethal", "type": "attack", "target": "enemy", "cost": 3, "effects": [{"type": "damage", "amount": 20}]},
	])
	card_played_energy_starter_fixture.player["energy"] = 2
	card_played_energy_starter_fixture.owned_relic_ids = ["blank_contract"]
	card_played_energy_starter_fixture.relics_by_id = {"blank_contract": simulator._relic_by_id("blank_contract").duplicate(true)}
	var card_played_energy_starter_actual = _combat_choice_fixture(30, 0, 0, 20, card_played_energy_starter_fixture.hand)
	card_played_energy_starter_actual.player["energy"] = 2
	card_played_energy_starter_actual.owned_relic_ids = card_played_energy_starter_fixture.owned_relic_ids.duplicate(true)
	card_played_energy_starter_actual.relics_by_id = card_played_energy_starter_fixture.relics_by_id.duplicate(true)
	_check(card_played_energy_starter_actual.play_card(0, 0) and int(card_played_energy_starter_actual.player.get("energy", 0)) == 3, "CombatState zero-cost card triggers card-played energy before the follow-up")
	_check(card_played_energy_starter_actual.play_card(1, 0) and card_played_energy_starter_actual.phase == "won", "CombatState card-played energy unlocks the three-cost lethal follow-up")
	_check(int(simulator._choose_card(card_played_energy_starter_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat treats card-played energy as a zero-cost starter resource")
	var card_played_block_relics := {
		"fixture_card_played_guard": {"effects": [{"trigger": "card_played", "type": "gain_block", "amount": 3, "card_type": "skill", "once_per_combat": true}]},
		"fixture_nested_guard": {"effects": [{"trigger": "block_gained", "type": "gain_block", "amount": 2, "once_per_combat": true}]},
	}
	var card_played_block_fixture = _combat_choice_fixture(5, 0, 9, 40, [
		{"id": "fixture_card_played_survival", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "draw", "amount": 1}]},
		{"id": "fixture_card_played_risky_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 12}]},
	])
	card_played_block_fixture.owned_relic_ids = ["fixture_card_played_guard", "fixture_nested_guard"]
	card_played_block_fixture.relics_by_id = card_played_block_relics.duplicate(true)
	var card_played_block_actual = _combat_choice_fixture(5, 0, 9, 40, card_played_block_fixture.hand)
	(card_played_block_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 9, "hits": 1, "target": "player"}]
	card_played_block_actual.owned_relic_ids = card_played_block_fixture.owned_relic_ids.duplicate(true)
	card_played_block_actual.relics_by_id = card_played_block_relics.duplicate(true)
	_check(card_played_block_actual.play_card(0, 0) and int(card_played_block_actual.player.get("block", 0)) == 5, "CombatState card-played block enters the nested block-gained chain")
	card_played_block_actual.end_player_turn()
	_check(card_played_block_actual.phase != "lost" and int(card_played_block_actual.player.get("hp", 0)) == 1, "CombatState nested card-played block prevents lethal incoming damage")
	_check(simulator._estimated_card_block_gain(card_played_block_fixture, card_played_block_fixture.hand[0], 0) == 5, "competent combat includes card-played and nested block-gained armor")
	_check(int(simulator._choose_card(card_played_block_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat prioritizes card-played relic armor that prevents lethal")
	var conditional_status_order_fixture = _combat_choice_fixture(5, 0, 10, 40, [
		{"id": "fixture_conditional_exposed_guard", "type": "skill", "target": "self", "cost": 1, "effects": [
			{"type": "gain_momentum", "amount": 3},
			{"type": "block", "amount": 6},
			{"type": "apply_status", "target": "self", "status": "vulnerable", "amount": 1, "requires_momentum_at_least": 3},
		]},
		{"id": "fixture_conditional_clean_guard", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 6}]},
	])
	var conditional_status_order_actual = _combat_choice_fixture(5, 0, 10, 40, conditional_status_order_fixture.hand)
	(conditional_status_order_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]
	_check(conditional_status_order_actual.play_card(0, 0), "CombatState accepts the conditional exposed guard")
	conditional_status_order_actual.end_player_turn()
	_check(conditional_status_order_actual.phase == "lost", "CombatState evaluates conditional self vulnerable after the card gains momentum")
	var conditional_clean_guard_actual = _combat_choice_fixture(5, 0, 10, 40, conditional_status_order_fixture.hand)
	(conditional_clean_guard_actual.enemies[0] as Dictionary)["current_action"]["effects"] = [{"type": "damage", "amount": 10, "hits": 1, "target": "player"}]
	_check(conditional_clean_guard_actual.play_card(1, 0), "CombatState accepts the clean conditional-order guard")
	conditional_clean_guard_actual.end_player_turn()
	_check(conditional_clean_guard_actual.phase != "lost" and int(conditional_clean_guard_actual.player.get("hp", 0)) == 1, "CombatState clean guard survives the same incoming damage")
	_check(simulator._estimated_incoming_damage_after_card_statuses(conditional_status_order_fixture, conditional_status_order_fixture.hand[0], 0) == 15, "competent combat evaluates conditional statuses with same-card momentum order")
	_check(int(simulator._choose_card(conditional_status_order_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat rejects false survival from a dynamically enabled self vulnerable")
	var unavailable_growth_relics := {"fixture_late_forging": {"effects": [{"trigger": "card_played", "type": "bonus_damage", "amount": 2, "card_type": "attack", "first_turn_only": true}]}}
	var unavailable_growth_fixture = _combat_choice_fixture(30, 0, 8, 4, [
		{"id": "fixture_late_growth_attack", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 2}]},
		{"id": "fixture_late_growth_block", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	unavailable_growth_fixture.owned_relic_ids = ["fixture_late_forging"]
	unavailable_growth_fixture.relics_by_id = unavailable_growth_relics.duplicate(true)
	var unavailable_growth_actual = _combat_choice_fixture(30, 0, 8, 4, unavailable_growth_fixture.hand)
	unavailable_growth_actual.owned_relic_ids = unavailable_growth_fixture.owned_relic_ids.duplicate(true)
	unavailable_growth_actual.relics_by_id = unavailable_growth_relics.duplicate(true)
	_check(unavailable_growth_actual.play_card(0, 0) and unavailable_growth_actual.phase != "won", "CombatState does not trigger first-turn-only bonus damage on turn two")
	_check(int(simulator._choose_card(unavailable_growth_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat excludes unavailable first-turn-only bonus damage")
	var cadence_growth_relics := {"fixture_cadence_forging": {"effects": [{"trigger": "card_played", "type": "bonus_damage", "amount": 2, "card_type": "attack", "every_n_attack_cards": 2}]}}
	var cadence_growth_fixture = _combat_choice_fixture(30, 0, 8, 4, unavailable_growth_fixture.hand)
	cadence_growth_fixture.owned_relic_ids = ["fixture_cadence_forging"]
	cadence_growth_fixture.relics_by_id = cadence_growth_relics.duplicate(true)
	var cadence_growth_actual = _combat_choice_fixture(30, 0, 8, 4, unavailable_growth_fixture.hand)
	cadence_growth_actual.owned_relic_ids = cadence_growth_fixture.owned_relic_ids.duplicate(true)
	cadence_growth_actual.relics_by_id = cadence_growth_relics.duplicate(true)
	_check(cadence_growth_actual.play_card(0, 0) and cadence_growth_actual.phase != "won", "CombatState does not trigger every-second-attack bonus damage on the first attack")
	_check(int(simulator._choose_card(cadence_growth_fixture, "competent-player-v2").get("hand_index", -1)) == 1, "competent combat respects every-n-attack bonus damage cadence")
	var multi_lethal_fixture = _combat_choice_fixture(30, 0, 0, 5, [
		{"id": "fixture_multi_lethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 5}]},
	])
	multi_lethal_fixture.enemies = [
		{"id": "low_threat_lethal", "hp": 5, "max_hp": 5, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 3, "hits": 1}}},
		{"id": "high_threat_lethal", "hp": 5, "max_hp": 5, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 12, "hits": 1}}},
	]
	_check(int(simulator._choose_card(multi_lethal_fixture, "competent-combat-v1").get("target_index", -1)) == 1, "competent combat targets the higher-threat enemy when multiple lethal targets exist")
	var aoe_secondary_lethal_fixture = _combat_choice_fixture(30, 0, 20, 20, [
		{"id": "fixture_aoe_secondary_lethal", "type": "attack", "target": "all_enemies", "cost": 1, "effects": [{"type": "damage", "amount": 3, "target": "all_enemies"}]},
		{"id": "fixture_aoe_secondary_overblock", "type": "skill", "target": "self", "cost": 1, "effects": [{"type": "block", "amount": 20}]},
	])
	aoe_secondary_lethal_fixture.enemies.append({"id": "fixture_low_threat_aoe_lethal", "hp": 3, "max_hp": 3, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 0, "hits": 1}}})
	var aoe_secondary_lethal_actual = _combat_choice_fixture(30, 0, 20, 20, aoe_secondary_lethal_fixture.hand)
	aoe_secondary_lethal_actual.enemies = aoe_secondary_lethal_fixture.enemies.duplicate(true)
	_check(aoe_secondary_lethal_actual.play_card(0, 0) and int((aoe_secondary_lethal_actual.enemies[1] as Dictionary).get("hp", -1)) == 0, "CombatState AOE damage immediately kills a non-focus enemy")
	_check(int(simulator._choose_card(aoe_secondary_lethal_fixture, "competent-player-v2").get("hand_index", -1)) == 0, "competent combat recognizes immediate AOE lethal on a non-focus enemy")
	var multi_threat_fixture = _combat_choice_fixture(30, 0, 0, 30, [
		{"id": "fixture_multi_nonlethal", "type": "attack", "target": "enemy", "cost": 1, "effects": [{"type": "damage", "amount": 5}]},
	])
	multi_threat_fixture.enemies = [
		{"id": "low_threat_target", "hp": 30, "max_hp": 30, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 3, "hits": 1}}},
		{"id": "high_threat_target", "hp": 30, "max_hp": 30, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 12, "hits": 1}}},
	]
	var multi_threat_decision: Dictionary = simulator._choose_card(multi_threat_fixture, "competent-player-v2")
	_check(int(multi_threat_decision.get("target_index", -1)) == 1, "competent combat targets the highest current threat when no lethal exists")
	_check(simulator._choose_card(multi_threat_fixture, "competent-player-v2") == multi_threat_decision, "competent multi-enemy targeting is deterministic for identical input")
	var blocked_threat_fixture = _combat_choice_fixture(30, 0, 0, 30, multi_threat_fixture.hand)
	blocked_threat_fixture.enemies = [
		{"id": "open_low_threat_target", "hp": 30, "max_hp": 30, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 3, "hits": 1}}},
		{"id": "blocked_high_threat_target", "hp": 30, "max_hp": 30, "block": 1, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 12, "hits": 1}}},
	]
	_check(int(simulator._choose_card(blocked_threat_fixture, "competent-player-v2").get("target_index", -1)) == 1, "nonlethal target ordering keeps threat ahead of small damage-efficiency differences")
	var multi_hp_tiebreak_fixture = _combat_choice_fixture(30, 0, 0, 30, multi_threat_fixture.hand)
	multi_hp_tiebreak_fixture.enemies = [
		{"id": "higher_hp_target", "hp": 30, "max_hp": 30, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 8, "hits": 1}}},
		{"id": "lower_hp_target", "hp": 20, "max_hp": 30, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": 8, "hits": 1}}},
	]
	_check(int(simulator._choose_card(multi_hp_tiebreak_fixture, "competent-combat-v1").get("target_index", -1)) == 1, "competent targeting breaks equal threat by lower HP")
	var stable_index_fixture = _combat_choice_fixture(30, 0, 0, 30, multi_threat_fixture.hand)
	stable_index_fixture.enemies.append(stable_index_fixture.enemies[0].duplicate(true))
	_check(int(simulator._choose_card(stable_index_fixture, "competent-combat-v1").get("target_index", -1)) == 0, "competent targeting breaks exact ties by stable lower index")
	var safe_elite_summary: Dictionary = simulator._elite_prediction_summary(70, [
		{"won": true, "player_hp_remaining": 14},
		{"won": true, "player_hp_remaining": 14},
		{"won": false, "player_hp_remaining": 0},
	])
	_check(int(safe_elite_summary.get("wins", 0)) == 2 and int(safe_elite_summary.get("minimum_safe_hp", 0)) == 14 and int(safe_elite_summary.get("median_winning_hp", 0)) == 14 and bool(safe_elite_summary.get("safe", false)), "elite gate accepts 2-of-3 wins at the exact ceil twenty-percent median boundary")
	var even_median_boundary_summary: Dictionary = simulator._elite_prediction_summary(70, [
		{"won": true, "player_hp_remaining": 13},
		{"won": true, "player_hp_remaining": 15},
		{"won": false, "player_hp_remaining": 0},
	])
	_check(int(even_median_boundary_summary.get("median_winning_hp", 0)) == 14 and bool(even_median_boundary_summary.get("safe", false)), "elite gate uses the arithmetic median for two wins at the safety boundary")
	var low_median_elite_summary: Dictionary = simulator._elite_prediction_summary(70, [
		{"won": true, "player_hp_remaining": 12},
		{"won": true, "player_hp_remaining": 13},
		{"won": false, "player_hp_remaining": 0},
	])
	_check(int(low_median_elite_summary.get("wins", 0)) == 2 and int(low_median_elite_summary.get("median_winning_hp", 0)) == 12 and not bool(low_median_elite_summary.get("safe", true)), "elite gate rejects a 2-of-3 result below the HP median boundary")
	var one_win_elite_summary: Dictionary = simulator._elite_prediction_summary(70, [
		{"won": true, "player_hp_remaining": 70},
		{"won": false, "player_hp_remaining": 0},
		{"won": false, "player_hp_remaining": 0},
	])
	_check(int(one_win_elite_summary.get("wins", 0)) == 1 and not bool(one_win_elite_summary.get("safe", true)), "elite gate rejects fewer than two wins even with high surviving HP")
	var ember_prediction_character: Dictionary = simulator._character_config("ember_exile")
	var elite_prediction_state := {
		"character_id": "ember_exile",
		"challenge_level": 0,
		"hp": 70,
		"max_hp": 70,
		"deck_ids": ember_prediction_character.get("starter_deck_ids", []).duplicate(true),
		"relic_ids": ember_prediction_character.get("starter_relic_ids", []).duplicate(true),
		"potion_ids": ["coolant_phial"],
		"skill_book_id": "steel_manual",
		"deck_mastery_id": "",
	}
	var elite_prediction: Dictionary = simulator._elite_survival_prediction(elite_prediction_state.duplicate(true), "executor_elite", "competent")
	var elite_prediction_seeds: Array = elite_prediction.get("seed_values", [])
	var unique_elite_prediction_seeds: Dictionary = {}
	for prediction_seed in elite_prediction_seeds:
		unique_elite_prediction_seeds[int(prediction_seed)] = true
	_check(elite_prediction_seeds.size() == 3 and unique_elite_prediction_seeds.size() == 3, "elite prediction uses exactly three unique stable seeds")
	_check(bool(elite_prediction.get("safe", false)) == (int(elite_prediction.get("wins", 0)) >= 2 and int(elite_prediction.get("median_winning_hp", 0)) >= int(elite_prediction.get("minimum_safe_hp", 1))), "elite prediction safe flag follows the 2-of-3 and HP median gate")
	_check(simulator._elite_survival_prediction(elite_prediction_state.duplicate(true), "executor_elite", "competent") == elite_prediction, "elite prediction is deterministic for identical combat input")
	var elite_prediction_cache_key: String = simulator._elite_prediction_cache_key(elite_prediction_state, "executor_elite", "competent")
	_check(elite_prediction_cache_key == simulator._elite_prediction_cache_key(elite_prediction_state.duplicate(true), "executor_elite", "competent"), "elite prediction cache key is stable for identical deep input")
	var short_horizon_prediction_state: Dictionary = elite_prediction_state.duplicate(true)
	short_horizon_prediction_state["max_turns"] = 1
	var short_horizon_prediction: Dictionary = simulator._elite_survival_prediction(short_horizon_prediction_state, "executor_elite", "competent")
	var short_horizon_respected := true
	for short_horizon_outcome_value in short_horizon_prediction.get("outcomes", []):
		var short_horizon_outcome: Dictionary = short_horizon_outcome_value
		if not bool(short_horizon_outcome.get("timeout", false)) or int(short_horizon_outcome.get("turns", 0)) != 2:
			short_horizon_respected = false
	_check(short_horizon_respected, "elite prediction uses the campaign max-turn horizon")
	_check(simulator._elite_prediction_cache_key(short_horizon_prediction_state, "executor_elite", "competent") != elite_prediction_cache_key, "elite prediction cache key covers the campaign max-turn horizon")
	var elite_key_variants: Array = []
	var character_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	character_key_variant["character_id"] = "arc_tinker"
	elite_key_variants.append([character_key_variant, "executor_elite", "competent", "character"])
	var challenge_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	challenge_key_variant["challenge_level"] = 1
	elite_key_variants.append([challenge_key_variant, "executor_elite", "competent", "challenge"])
	var hp_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	hp_key_variant["hp"] = 69
	elite_key_variants.append([hp_key_variant, "executor_elite", "competent", "hp"])
	var max_hp_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	max_hp_key_variant["max_hp"] = 71
	elite_key_variants.append([max_hp_key_variant, "executor_elite", "competent", "max_hp"])
	var deck_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	var upgraded_key_deck: Array = (deck_key_variant.get("deck_ids", []) as Array).duplicate(true)
	upgraded_key_deck[0] = "%s+" % str(upgraded_key_deck[0])
	deck_key_variant["deck_ids"] = upgraded_key_deck
	elite_key_variants.append([deck_key_variant, "executor_elite", "competent", "deck upgrade"])
	var relic_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	(relic_key_variant["relic_ids"] as Array).append("counter_spring")
	elite_key_variants.append([relic_key_variant, "executor_elite", "competent", "relic"])
	var potion_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	(potion_key_variant["potion_ids"] as Array).append("spark_bomb")
	elite_key_variants.append([potion_key_variant, "executor_elite", "competent", "potion"])
	var growth_key_variant: Dictionary = elite_prediction_state.duplicate(true)
	growth_key_variant["deck_mastery_id"] = "offense_forging"
	elite_key_variants.append([growth_key_variant, "executor_elite", "competent", "growth source"])
	elite_key_variants.append([elite_prediction_state.duplicate(true), "rust_colossus_elite", "competent", "encounter"])
	elite_key_variants.append([elite_prediction_state.duplicate(true), "executor_elite", "current", "combat profile"])
	for key_variant_value in elite_key_variants:
		var key_variant: Array = key_variant_value
		_check(simulator._elite_prediction_cache_key(key_variant[0], str(key_variant[1]), str(key_variant[2])) != elite_prediction_cache_key, "elite prediction cache key covers %s" % str(key_variant[3]))
	var route_preview_key_state_a: Dictionary = elite_prediction_state.duplicate(true)
	route_preview_key_state_a["gold"] = 70
	var route_preview_key_state_b: Dictionary = route_preview_key_state_a.duplicate(true)
	route_preview_key_state_b["relic_ids"] = ["counter_spring", "cracked_charm"]
	_check((route_preview_key_state_a.get("relic_ids", []) as Array).size() == (route_preview_key_state_b.get("relic_ids", []) as Array).size(), "route preview cache regression fixture keeps equal relic counts")
	_check(simulator._campaign_preview_state_key(route_preview_key_state_a) != simulator._campaign_preview_state_key(route_preview_key_state_b), "route preview cache key distinguishes equal-count states with different prediction inputs")
	var side_effect_prediction_state: Dictionary = elite_prediction_state.duplicate(true)
	var side_effect_prediction_before: Dictionary = side_effect_prediction_state.duplicate(true)
	simulator._elite_survival_prediction(side_effect_prediction_state, "executor_elite", "competent")
	_check(side_effect_prediction_state == side_effect_prediction_before, "elite prediction does not mutate real state or potion inventory")
	seed(4242)
	var expected_rng_after_prediction: int = randi()
	seed(4242)
	var rng_side_effect_prediction_state: Dictionary = elite_prediction_state.duplicate(true)
	rng_side_effect_prediction_state["hp"] = 68
	rng_side_effect_prediction_state["max_turns"] = 1
	simulator._elite_survival_prediction(rng_side_effect_prediction_state, "executor_elite", "competent")
	_check(randi() == expected_rng_after_prediction, "elite prediction miss preserves the caller global RNG state")
	var cached_prediction_state: Dictionary = elite_prediction_state.duplicate(true)
	cached_prediction_state["elite_prediction_cache"] = {elite_prediction_cache_key: elite_prediction.duplicate(true)}
	var cached_prediction: Dictionary = simulator._elite_survival_prediction(cached_prediction_state, "executor_elite", "competent")
	_check(bool(cached_prediction.get("cache_hit", false)) and cached_prediction.get("seed_values", []) == elite_prediction.get("seed_values", []) and cached_prediction.get("outcomes", []) == elite_prediction.get("outcomes", []), "elite prediction reuses an exact complete-key cache hit")
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
	for elite_gate_state in [v1_meta_fixture, v2_meta_fixture]:
		elite_gate_state["challenge_level"] = 0
		elite_gate_state["potion_ids"] = ["coolant_phial"]
		elite_gate_state["skill_book_id"] = "steel_manual"
		elite_gate_state["deck_mastery_id"] = ""
	var unsafe_elite_prediction := {"wins": 1, "winning_hp": [30], "median_winning_hp": 30, "minimum_safe_hp": 14, "safe": false, "seed_values": [11, 12, 13], "outcomes": []}
	var safe_elite_prediction := {"wins": 2, "winning_hp": [14, 20], "median_winning_hp": 14, "minimum_safe_hp": 14, "safe": true, "seed_values": [21, 22, 23], "outcomes": []}
	var unsafe_v2_route_state: Dictionary = v2_meta_fixture.duplicate(true)
	unsafe_v2_route_state["strategy_component_diagnostics"] = true
	unsafe_v2_route_state["route_choice_reason_counts"] = {}
	unsafe_v2_route_state["optional_elite_offer_count"] = 0
	unsafe_v2_route_state["optional_elite_accept_count"] = 0
	var unsafe_elite_key: String = simulator._elite_prediction_cache_key(unsafe_v2_route_state, "executor_elite", "competent-player-v2")
	unsafe_v2_route_state["elite_prediction_cache"] = {unsafe_elite_key: unsafe_elite_prediction}
	var elite_gate_candidates := [
		{"id": "unsafe_optional_elite", "type": "elite", "encounter_id": "executor_elite"},
		{"id": "safe_combat", "type": "combat", "encounter_id": "intro_patrol"},
	]
	_check(simulator._choose_next_campaign_node(unsafe_v2_route_state, elite_gate_candidates) == "safe_combat", "v2 hard-rejects an unsafe optional elite when a safe candidate exists")
	_check(int((unsafe_v2_route_state.get("route_choice_reason_counts", {}) as Dictionary).get("elite_safety_rejected", 0)) == 1 and int(unsafe_v2_route_state.get("optional_elite_accept_count", -1)) == 0, "v2 records elite_safety_rejected without accepting the unsafe elite")
	var exact_v2_policy_state: Dictionary = v2_meta_fixture.duplicate(true)
	var exact_v2_policy_key: String = simulator._elite_prediction_cache_key(exact_v2_policy_state, "executor_elite", "competent-player-v2")
	exact_v2_policy_state["elite_prediction_cache"] = {exact_v2_policy_key: unsafe_elite_prediction}
	_check(simulator._choose_next_campaign_node(exact_v2_policy_state, elite_gate_candidates) == "safe_combat", "elite gate predicts with the exact competent-player-v2 combat and potion policy")
	_check((exact_v2_policy_state.get("elite_prediction_cache", {}) as Dictionary).size() == 1, "elite gate reuses the exact v2 policy cache key without running a mismatched policy")
	var forced_unsafe_v2_state: Dictionary = unsafe_v2_route_state.duplicate(true)
	forced_unsafe_v2_state["route_choice_reason_counts"] = {}
	_check(simulator._choose_next_campaign_node(forced_unsafe_v2_state, [elite_gate_candidates[0]]) == "unsafe_optional_elite", "v2 gate does not reject a forced elite with no safe alternative")
	_check(int((forced_unsafe_v2_state.get("route_choice_reason_counts", {}) as Dictionary).get("elite_safety_rejected", 0)) == 0, "forced elite does not emit an optional safety rejection reason")
	var safe_v2_route_state: Dictionary = v2_meta_fixture.duplicate(true)
	var safe_elite_key: String = simulator._elite_prediction_cache_key(safe_v2_route_state, "executor_elite", "competent-player-v2")
	safe_v2_route_state["elite_prediction_cache"] = {safe_elite_key: safe_elite_prediction}
	_check(simulator._choose_next_campaign_node(safe_v2_route_state, elite_gate_candidates) == "unsafe_optional_elite", "v2 may accept an optional elite that passes the prediction gate")
	var v1_unsafe_cache_state: Dictionary = v1_meta_fixture.duplicate(true)
	v1_unsafe_cache_state["elite_prediction_cache"] = {simulator._elite_prediction_cache_key(v1_unsafe_cache_state, "executor_elite", "competent"): unsafe_elite_prediction}
	_check(simulator._choose_next_campaign_node(v1_unsafe_cache_state, elite_gate_candidates) == "unsafe_optional_elite", "competent-player-v1 ignores the v2 elite safety gate")
	var unsafe_future_state: Dictionary = unsafe_v2_route_state.duplicate(true)
	unsafe_future_state["route_choice_reason_counts"] = {}
	var future_treasure_node := {"id": "future_treasure_path", "type": "treasure"}
	var future_preview_state: Dictionary = simulator._campaign_preview_state_after_node(unsafe_future_state, future_treasure_node)
	var future_elite_key: String = simulator._elite_prediction_cache_key(future_preview_state, "executor_elite", "competent-player-v2")
	(unsafe_future_state["elite_prediction_cache"] as Dictionary)[future_elite_key] = unsafe_elite_prediction
	var unsafe_future_graph := {
		"layers": [
			[future_treasure_node, {"id": "future_safe_path", "type": "combat", "encounter_id": "intro_patrol"}],
			[{"id": "future_unsafe_elite", "type": "elite", "encounter_id": "executor_elite"}, {"id": "future_safe_event", "type": "event"}],
		],
		"edges": [
			{"from": "future_treasure_path", "to": "future_unsafe_elite"},
			{"from": "future_safe_path", "to": "future_safe_event"},
		],
	}
	_check(simulator._choose_next_campaign_node(unsafe_future_state, unsafe_future_graph.get("layers", [])[0], unsafe_future_graph) == "future_safe_path", "future treasure value cannot offset a cached unsafe elite hard rejection")
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

func _combat_choice_fixture(player_hp: int, player_block: int, incoming_damage: int, enemy_hp: int, hand: Array):
	var combat = CombatStateScript.new()
	combat.phase = "player"
	combat.turn = 2
	combat.player = {"hp": player_hp, "max_hp": 70, "block": player_block, "energy": 3, "max_energy": 3, "momentum": 0, "statuses": {}}
	combat.enemies = [{"id": "fixture_enemy", "hp": enemy_hp, "max_hp": enemy_hp, "block": 0, "statuses": {}, "current_action": {"intent": {"type": "attack", "amount": incoming_damage, "hits": 1}}}]
	combat.hand = hand.duplicate(true)
	return combat

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
