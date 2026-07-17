class_name NumericalPressureMetrics
extends RefCounted

static func nearest_rank(values: Array, percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array = values.duplicate()
	sorted_values.sort()
	var bounded_percentile: float = clampf(percentile, 0.0, 1.0)
	var index: int = clampi(int(ceil(bounded_percentile * float(sorted_values.size()))) - 1, 0, sorted_values.size() - 1)
	return float(sorted_values[index])

static func effective_hp_for_enemies(enemy_base_hps: Array, enemy_hp_multiplier: float, boss_hp_multiplier: float = 1.0) -> int:
	var total := 0
	var combined_multiplier: float = maxf(0.1, enemy_hp_multiplier) * maxf(0.1, boss_hp_multiplier)
	for hp_value in enemy_base_hps:
		total += max(1, int(ceil(float(int(hp_value)) * combined_multiplier)))
	return total

static func safe_ratio(numerator: float, denominator: float) -> float:
	if denominator <= 0.0:
		return 0.0
	return numerator / denominator

static func aggregate_runs(runs: Array, contract: Dictionary) -> Dictionary:
	var wins := 0
	var timeouts := 0
	var zero_damage_win_count := 0
	var hp_losses: Array = []
	var winning_turns: Array = []
	var total_turns := 0
	var total_cards_played := 0
	for run_value in runs:
		var run: Dictionary = run_value
		var won: bool = bool(run.get("won", false))
		var hp_lost: int = max(0, int(run.get("player_hp_lost", 0)))
		var turns: int = max(0, int(run.get("turns", 0)))
		if won:
			wins += 1
			winning_turns.append(turns)
			if hp_lost == 0:
				zero_damage_win_count += 1
		if bool(run.get("timeout", false)):
			timeouts += 1
		hp_losses.append(hp_lost)
		total_turns += turns
		total_cards_played += max(0, int(run.get("cards_played", 0)))

	var run_count: int = runs.size()
	var result := {
		"runs": run_count,
		"wins": wins,
		"timeouts": timeouts,
		"win_rate": _rate(wins, run_count),
		"timeout_rate": _rate(timeouts, run_count),
		"zero_damage_win_count": zero_damage_win_count,
		"perfect_win_rate": _rate(zero_damage_win_count, run_count),
		"hp_loss_p50": nearest_rank(hp_losses, 0.50),
		"hp_loss_p90": nearest_rank(hp_losses, 0.90),
		"turn_sample_count": winning_turns.size(),
		"turns_p50": nearest_rank(winning_turns, 0.50),
		"turns_p90": nearest_rank(winning_turns, 0.90),
		"cards_played_per_turn": _rate(total_cards_played, total_turns),
		"pressure_gate_eligible": run_count >= max(1, int(contract.get("minimum_samples", 64))),
	}
	var flags: Array = risk_flags(result, contract)
	result["risk_flags"] = flags
	result["risk_flag"] = str(flags[0]) if not flags.is_empty() else "ok"
	return result

static func risk_flags(metrics: Dictionary, contract: Dictionary) -> Array:
	var flags: Array = []
	var tier: String = str(contract.get("tier", "normal"))
	var win_rate: float = float(metrics.get("win_rate", 0.0))
	var perfect_win_rate: float = float(metrics.get("perfect_win_rate", 0.0))
	var turns_p50: float = float(metrics.get("turns_p50", 0.0))
	var turns_p90: float = float(metrics.get("turns_p90", 0.0))
	var expected_turns_min: float = float(contract.get("expected_turns_min", 0.0))
	var expected_turns_max: float = float(contract.get("expected_turns_max", INF))
	if float(metrics.get("timeout_rate", 0.0)) > 0.0:
		flags.append("timeout_check")
	if win_rate < float(contract.get("win_rate_min", 0.0)):
		flags.append("%s_too_lethal" % tier)
	var low_attrition: bool = (
		float(metrics.get("hp_loss_p50", 0.0)) < float(contract.get("hp_loss_p50_min", 0.0))
		and float(metrics.get("hp_loss_p90", 0.0)) < float(contract.get("hp_loss_p90_min", 0.0))
	)
	if bool(metrics.get("pressure_gate_eligible", false)) and (perfect_win_rate > float(contract.get("perfect_win_rate_max", 1.0)) or (win_rate > float(contract.get("win_rate_max", 1.0)) and low_attrition)):
		flags.append("%s_too_easy" % tier)
	if int(metrics.get("turn_sample_count", 0)) > 0:
		if turns_p50 < expected_turns_min:
			flags.append("encounter_too_fast")
		var slow_tail_limit: float = expected_turns_max + ceil((expected_turns_max - expected_turns_min) / 2.0)
		if turns_p50 > expected_turns_max or turns_p90 > slow_tail_limit:
			flags.append("encounter_too_slow")
	return flags

static func action_cycle_metrics(actions: Array) -> Dictionary:
	var action_damages: Array = []
	var direct_damage_action_count := 0
	for action_value in actions:
		var damage: int = _action_direct_damage(action_value)
		action_damages.append(damage)
		if damage > 0:
			direct_damage_action_count += 1
	var action_count: int = actions.size()
	var first_three_damage := 0
	if action_count > 0:
		for index in range(3):
			first_three_damage += int(action_damages[index % action_count])
	return {
		"action_count": action_count,
		"direct_damage_action_count": direct_damage_action_count,
		"attack_action_ratio": _rate(direct_damage_action_count, action_count),
		"longest_zero_direct_damage_actions": _longest_circular_zero_run(action_damages),
		"first_three_action_damage_total": first_three_damage,
	}

static func _action_direct_damage(action_value: Variant) -> int:
	var action: Dictionary = action_value
	var total := 0
	for effect_value in action.get("effects", []):
		var effect: Dictionary = effect_value
		if str(effect.get("type", "")) == "damage" and str(effect.get("target", "")) == "player":
			total += max(0, int(effect.get("amount", 0))) * max(1, int(effect.get("hits", 1)))
	return total

static func _longest_circular_zero_run(action_damages: Array) -> int:
	if action_damages.is_empty():
		return 0
	var has_damage := false
	for damage in action_damages:
		if int(damage) > 0:
			has_damage = true
			break
	if not has_damage:
		return action_damages.size()
	var longest := 0
	var current := 0
	for index in range(action_damages.size() * 2):
		if int(action_damages[index % action_damages.size()]) <= 0:
			current += 1
			longest = min(action_damages.size(), max(longest, current))
		else:
			current = 0
	return longest

static func _rate(numerator: int, denominator: int) -> float:
	if denominator <= 0:
		return 0.0
	return float(numerator) / float(denominator)
