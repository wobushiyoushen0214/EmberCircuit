extends SceneTree

const NumericalPressureMetricsScript = preload("res://scripts/tools/NumericalPressureMetrics.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(NumericalPressureMetricsScript.nearest_rank([9, 1, 7, 3, 5], 0.50) == 5.0, "nearest-rank p50 sorts values and selects ceil(p*n)-1")
	_check(NumericalPressureMetricsScript.nearest_rank([9, 1, 7, 3, 5], 0.90) == 9.0, "nearest-rank p90 selects the deterministic upper observation")
	_check(NumericalPressureMetricsScript.nearest_rank([], 0.50) == 0.0, "nearest-rank returns zero for an empty sample")
	_check(NumericalPressureMetricsScript.effective_hp_for_enemies([101], 1.0, 0.96) == 97, "single-enemy effective HP applies multipliers and rounds up")
	_check(NumericalPressureMetricsScript.effective_hp_for_enemies([33, 33], 1.05, 1.0) == 70, "multi-enemy effective HP rounds each enemy before summing")
	_check(NumericalPressureMetricsScript.effective_hp_for_enemies([10], 0.05, 0.05) == 1, "effective HP keeps a low-base enemy alive under floored multipliers")
	_check(NumericalPressureMetricsScript.effective_hp_for_enemies([999], 0.05, 0.05) == 10, "enemy and boss HP multipliers each have the runtime 0.1 floor")
	_check(NumericalPressureMetricsScript.effective_hp_for_enemies([0], 1.0, 1.0) == 1, "each enemy effective HP has the runtime minimum of one")
	_check(is_equal_approx(NumericalPressureMetricsScript.safe_ratio(97.0, 104.0), 97.0 / 104.0), "safe ratio preserves a valid boss-to-elite quotient")
	_check(NumericalPressureMetricsScript.safe_ratio(97.0, 0.0) == 0.0, "safe ratio returns zero for a non-positive denominator")

	var runs: Array = []
	for index in range(62):
		var hp_lost: int = 0 if index < 40 else index - 39
		var turns: int = index + 1
		runs.append({
			"won": true,
			"lost": false,
			"timeout": false,
			"player_hp_lost": hp_lost,
			"turns": turns,
			"cards_played": turns * 2,
		})
	runs.append({
		"won": false,
		"lost": true,
		"timeout": false,
		"player_hp_lost": 0,
		"turns": 97,
		"cards_played": 194,
	})
	runs.append({
		"won": false,
		"lost": true,
		"timeout": false,
		"player_hp_lost": 99,
		"turns": 101,
		"cards_played": 202,
	})
	var aggregate: Dictionary = NumericalPressureMetricsScript.aggregate_runs(runs, {
		"tier": "normal",
		"minimum_samples": 64,
		"win_rate_min": 0.70,
		"win_rate_max": 0.95,
		"perfect_win_rate_max": 0.55,
		"expected_turns_min": 3,
		"expected_turns_max": 6,
	})
	_check(int(aggregate.get("runs", 0)) == 64 and bool(aggregate.get("pressure_gate_eligible", false)), "64 runs satisfy the pressure hard gate")
	_check(int(aggregate.get("wins", 0)) == 62, "aggregate fixture retains two distinct failure runs")
	_check(int(aggregate.get("zero_damage_win_count", -1)) == 40, "a zero-HP-loss failure is not counted as a perfect win")
	_check(is_equal_approx(float(aggregate.get("perfect_win_rate", -1.0)), 40.0 / 64.0), "perfect win rate uses all runs rather than wins as its denominator")
	_check(float(aggregate.get("hp_loss_p50", -1.0)) == 0.0 and float(aggregate.get("hp_loss_p90", -1.0)) == 17.0, "HP-loss percentiles include zero-loss and high-loss failures")
	_check(int(aggregate.get("turn_sample_count", 0)) == 62, "turn percentiles exclude both failure runs")
	_check(float(aggregate.get("turns_p50", -1.0)) == 31.0 and float(aggregate.get("turns_p90", -1.0)) == 56.0, "turn percentiles use nearest-rank over wins only")
	_check(is_equal_approx(float(aggregate.get("cards_played_per_turn", -1.0)), 2.0), "cards per turn divides total cards by total turns")
	_check(aggregate.get("risk_flags", []) == ["normal_too_easy", "encounter_too_slow"], "aggregate preserves all risks in stable priority order")
	_check(str(aggregate.get("risk_flag", "")) == "normal_too_easy", "legacy risk flag exposes the highest-priority risk")

	var attrition_contract := {
		"tier": "normal",
		"minimum_samples": 64,
		"win_rate_min": 0.70,
		"win_rate_max": 0.95,
		"perfect_win_rate_max": 0.55,
		"hp_loss_p50_min": 7,
		"hp_loss_p90_min": 10,
		"expected_turns_min": 5,
		"expected_turns_max": 9,
	}
	var high_attrition_runs: Array = []
	for index in range(64):
		high_attrition_runs.append({
			"won": true,
			"timeout": false,
			"player_hp_lost": 24 if index < 48 else 36,
			"turns": 7,
			"cards_played": 14,
		})
	var high_attrition: Dictionary = NumericalPressureMetricsScript.aggregate_runs(high_attrition_runs, attrition_contract)
	_check(is_equal_approx(float(high_attrition.get("win_rate", 0.0)), 1.0) and float(high_attrition.get("hp_loss_p50", 0.0)) == 24.0 and float(high_attrition.get("hp_loss_p90", 0.0)) == 36.0, "high-win fixture retains substantial median and tail attrition")
	_check((high_attrition.get("risk_flags", []) as Array).is_empty(), "high-win high-attrition combat is not misreported as too easy")

	var low_attrition_runs: Array = []
	for index in range(64):
		low_attrition_runs.append({
			"won": true,
			"timeout": false,
			"player_hp_lost": 1,
			"turns": 7,
			"cards_played": 14,
		})
	var low_attrition: Dictionary = NumericalPressureMetricsScript.aggregate_runs(low_attrition_runs, attrition_contract)
	_check(float(low_attrition.get("hp_loss_p50", 0.0)) == 1.0 and float(low_attrition.get("hp_loss_p90", 0.0)) == 1.0, "low-attrition fixture remains below both attrition floors")
	_check(low_attrition.get("risk_flags", []) == ["normal_too_easy"], "high-win low-attrition combat reports normal_too_easy")

	var small_sample: Dictionary = NumericalPressureMetricsScript.aggregate_runs(runs.slice(0, 63), {
		"tier": "normal",
		"minimum_samples": 64,
		"win_rate_min": 0.70,
		"win_rate_max": 0.95,
		"perfect_win_rate_max": 0.55,
		"expected_turns_min": 3,
		"expected_turns_max": 80,
	})
	_check(not bool(small_sample.get("pressure_gate_eligible", true)), "fewer than 64 runs remain diagnostic-only")
	_check(not (small_sample.get("risk_flags", []) as Array).has("normal_too_easy"), "diagnostic-only samples cannot trigger a tier too-easy risk")

	var tail_slow_runs: Array = []
	for index in range(64):
		var turns: int = 5 if index < 50 else 9
		tail_slow_runs.append({"won": true, "player_hp_lost": 1, "turns": turns, "cards_played": turns * 2})
	var tail_slow: Dictionary = NumericalPressureMetricsScript.aggregate_runs(tail_slow_runs, {
		"tier": "elite",
		"minimum_samples": 64,
		"win_rate_min": 0.45,
		"win_rate_max": 1.0,
		"perfect_win_rate_max": 1.0,
		"expected_turns_min": 3,
		"expected_turns_max": 6,
	})
	_check(float(tail_slow.get("turns_p50", 0.0)) == 5.0 and float(tail_slow.get("turns_p90", 0.0)) == 9.0, "tail-slow fixture keeps its median in range while p90 exceeds the tail allowance")
	_check((tail_slow.get("risk_flags", []) as Array).has("encounter_too_slow"), "p90 above max plus half-range ceiling triggers the slow-tail risk")

	var no_wins_runs: Array = []
	for index in range(64):
		no_wins_runs.append({
			"won": false,
			"lost": false,
			"timeout": true,
			"player_hp_lost": 70,
			"turns": 30 + index,
			"cards_played": 0,
		})
	var no_wins: Dictionary = NumericalPressureMetricsScript.aggregate_runs(no_wins_runs, {
		"tier": "normal",
		"minimum_samples": 64,
		"win_rate_min": 0.70,
		"win_rate_max": 0.95,
		"perfect_win_rate_max": 0.55,
		"expected_turns_min": 3,
		"expected_turns_max": 6,
	})
	var no_wins_risks: Array = no_wins.get("risk_flags", [])
	_check(int(no_wins.get("turn_sample_count", -1)) == 0, "all-failure timeout fixture has no winning-turn sample")
	_check(no_wins_risks.has("timeout_check") and no_wins_risks.has("normal_too_lethal"), "all-failure timeout fixture preserves timeout and lethal risks")
	_check(not no_wins_risks.has("encounter_too_fast") and not no_wins_risks.has("encounter_too_slow"), "duration risks require at least one winning-turn sample")

	var timeout_priority: Dictionary = NumericalPressureMetricsScript.aggregate_runs([
		{"won": true, "timeout": true, "player_hp_lost": 0, "turns": 1, "cards_played": 2},
	], {
		"tier": "boss",
		"minimum_samples": 1,
		"win_rate_min": 0.25,
		"win_rate_max": 0.85,
		"perfect_win_rate_max": 0.15,
		"expected_turns_min": 8,
		"expected_turns_max": 14,
	})
	_check(timeout_priority.get("risk_flags", []) == ["timeout_check", "boss_too_easy", "encounter_too_fast"], "timeout, tier pressure, and duration risks compose in declared priority")
	_check(str(timeout_priority.get("risk_flag", "")) == "timeout_check", "timeout remains the compatible primary risk")

	var cycle_metrics: Dictionary = NumericalPressureMetricsScript.action_cycle_metrics([
		{"effects": [{"type": "block", "target": "self", "amount": 6}]},
		{"effects": [{"type": "damage", "target": "player", "amount": 5, "hits": 2}]},
		{"effects": [{"type": "apply_status", "target": "player", "status": "weak", "amount": 1}]},
		{"effects": [{"type": "damage", "target": "player", "amount": 7}]},
		{"effects": [{"type": "block", "target": "self", "amount": 4}]},
	])
	_check(int(cycle_metrics.get("action_count", 0)) == 5 and int(cycle_metrics.get("direct_damage_action_count", 0)) == 2, "action pressure counts only actions with direct player damage")
	_check(is_equal_approx(float(cycle_metrics.get("attack_action_ratio", 0.0)), 0.4), "action pressure reports the direct-damage ratio")
	_check(int(cycle_metrics.get("longest_zero_direct_damage_actions", 0)) == 2, "zero-damage windows join the cycle tail and head")
	_check(int(cycle_metrics.get("first_three_action_damage_total", 0)) == 10, "first-three pressure starts at action zero and includes multi-hit damage")
	var short_cycle: Dictionary = NumericalPressureMetricsScript.action_cycle_metrics([
		{"effects": [{"type": "damage", "target": "player", "amount": 4}]},
		{"effects": [{"type": "block", "target": "self", "amount": 4}]},
	])
	_check(int(short_cycle.get("first_three_action_damage_total", 0)) == 8, "first-three pressure repeats short cycles with modulo")
	var passive_cycle: Dictionary = NumericalPressureMetricsScript.action_cycle_metrics([
		{"effects": [{"type": "block", "target": "self", "amount": 2}]},
		{"effects": [{"type": "apply_status", "target": "player", "status": "frail", "amount": 1}]},
	])
	_check(int(passive_cycle.get("longest_zero_direct_damage_actions", 0)) == 2, "an all-passive cycle caps its zero-damage window at the cycle length")

	if not _failures.is_empty():
		push_error("Numerical pressure metrics test failed with %d issue(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Numerical pressure metrics test passed.")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
