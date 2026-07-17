extends SceneTree

const NumericalTreeAuditorScript = preload("res://scripts/tools/NumericalTreeAuditor.gd")

const REPORT_PATH := "/tmp/embercircuit_numerical_tree_test_report.json"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var auditor = NumericalTreeAuditorScript.new()
	var report: Dictionary = auditor.build_report()
	_check(str(report.get("audit_model", "")) == "static_numerical_tree", "numerical tree auditor reports model")
	_check((auditor.numerical_tree_data.get("pressure_contract", {}).get("opening_package_targets", {}) as Dictionary).size() == 3, "opening targets live under the independent pressure contract")
	_check(not (auditor.numerical_tree_data.get("players", {}) as Dictionary).has("opening_package_targets"), "opening targets do not alter the legacy player-budget namespace")
	var cards: Array = report.get("cards", [])
	var players: Array = report.get("players", [])
	var monsters: Array = report.get("monsters", [])
	_check(cards.size() >= 40, "numerical tree auditor scores the card pool")
	_check(players.size() == 3, "numerical tree auditor scores every playable character")
	_check(monsters.size() >= 12, "numerical tree auditor scores configured encounters")
	var summary: Dictionary = report.get("summary", {})
	_check(int(summary.get("card_count", 0)) == cards.size(), "numerical tree card summary is consistent")
	_check(int(summary.get("player_count", 0)) == players.size(), "numerical tree player summary is consistent")
	_check(int(summary.get("monster_encounter_count", 0)) == monsters.size(), "numerical tree monster summary is consistent")
	var category_fixture := [
		{"type": "block", "target": "self", "amount": 8},
		{"type": "apply_status", "target": "self", "status": "strength", "amount": 1},
		{"type": "create_card", "target": "player", "card_id": "searing_wound", "amount": 1},
	]
	_check(auditor._phase_entry_effect_categories(category_fixture) == ["block", "status_card", "strength"], "phase entry audit distinguishes block, strength, and status-card pressure")
	var synthetic_multi_enemy: Dictionary = auditor._audit_encounter(
		"chapter_one",
		"elite",
		{"id": "synthetic_multi_enemy", "name": "Synthetic", "enemy_ids": ["synthetic_a", "synthetic_b"]},
		{
			"synthetic_a": {"id": "synthetic_a", "max_hp": 33, "actions": []},
			"synthetic_b": {"id": "synthetic_b", "max_hp": 33, "actions": []},
		},
		{"enemy_hp_multiplier": 1.05, "boss_hp_multiplier": 1.0}
	)
	_check(is_equal_approx(float(synthetic_multi_enemy.get("effective_hp", 0.0)), 70.0), "auditor delegates multi-enemy effective HP to per-enemy ceiling semantics")
	for monster_value in monsters:
		var monster: Dictionary = monster_value
		if str(monster.get("tier", "")) == "boss":
			_check(int(monster.get("max_phase_entry_effect_categories", -1)) <= int(monster.get("phase_entry_effect_category_limit", 0)), "boss phase entry stays inside the configured pressure-category limit: %s" % str(monster.get("id", "")))
			_check(str(monster.get("phase_transition_mode", "")) == "highest_reached_only", "boss audit declares the runtime multi-threshold transition rule: %s" % str(monster.get("id", "")))
	var intro_patrol: Dictionary = _row_by_id(monsters, "intro_patrol")
	_check(int(intro_patrol.get("base_direct_damage_action_count", 0)) == 5 and int(intro_patrol.get("base_action_count", 0)) == 6, "intro patrol has five direct-damage actions across its six-action base cycles")
	_check(is_equal_approx(float(intro_patrol.get("base_attack_action_ratio", 0.0)), 5.0 / 6.0), "intro patrol exposes its rebaselined attack-action ratio")
	_check(int(intro_patrol.get("base_longest_zero_direct_damage_actions", 0)) == 1, "intro patrol has at most one consecutive zero-damage base action")
	_check(int(intro_patrol.get("base_first_three_action_damage_total", 0)) == 46, "intro patrol sums both rebaselined enemies across their first three repeated actions")
	var chapter_one_boss: Dictionary = _row_by_id(monsters, "chapter_one_boss")
	_check(int(chapter_one_boss.get("base_direct_damage_action_count", 0)) == 4 and int(chapter_one_boss.get("base_action_count", 0)) == 5, "chapter one boss has four direct-damage actions in its five-action base cycle")
	_check(is_equal_approx(float(chapter_one_boss.get("base_attack_action_ratio", 0.0)), 0.8), "chapter one boss exposes its rebaselined attack-action ratio")
	_check(int(chapter_one_boss.get("base_longest_zero_direct_damage_actions", 0)) == 1, "chapter one boss has only one zero-damage action")
	_check(int(chapter_one_boss.get("base_first_three_action_damage_total", 0)) == 27, "chapter one boss first-three pressure begins at action zero")
	_check(int(chapter_one_boss.get("effective_hp_challenge_level", -1)) == 0 and is_equal_approx(float(chapter_one_boss.get("effective_hp", 0.0)), 112.0), "chapter one boss C0 effective HP includes the boss multiplier")
	_check(is_equal_approx(float(chapter_one_boss.get("chapter_highest_elite_effective_hp", 0.0)), 96.0), "chapter one hierarchy records the highest elite C0 effective HP")
	_check(is_equal_approx(float(chapter_one_boss.get("boss_to_highest_elite_ehp_ratio", 0.0)), 1.1667), "chapter one boss-to-elite effective HP ratio clears the hierarchy gate")
	var boss_pressure_issues: Array = chapter_one_boss.get("pressure_issues", [])
	_check(boss_pressure_issues.is_empty(), "chapter one boss has no remaining static pressure issue")
	_check(str(chapter_one_boss.get("severity", "")) == "ok" and (chapter_one_boss.get("issues", []) as Array).is_empty(), "pressure issues do not alter the legacy monster budget result")
	_check(str(chapter_one_boss.get("pressure_severity", "")) == "ok", "chapter one boss pressure clears its independent severity")
	_check((chapter_one_boss.get("pressure_profiles", []) as Array).size() == 2, "chapter one boss phases remain separate pressure profiles")
	_check(int(summary.get("player_warning_count", -1)) == 0, "playable characters satisfy the numerical tree")
	_check(int(summary.get("monster_warning_count", -1)) == 0, "legacy monster budget warning count remains unchanged")
	_check(int(summary.get("monster_pressure_warning_count", 0)) > 0, "summary exposes independent monster pressure warnings")
	_check(report.get("economy", {}).has("expected_final_gold_range"), "numerical tree report includes economy targets")
	_check((report.get("progression", {}).get("trees", []) as Array).size() >= 3, "numerical tree report includes progression trees")
	var ember_strike: Dictionary = _row_by_id(cards, "ember_strike")
	_check(not ember_strike.is_empty(), "numerical tree report includes starter attack")
	_check(float(ember_strike.get("base_score", 0.0)) > 0.0, "numerical tree scores starter attack above zero")
	var pressure_surge: Dictionary = _row_by_id(cards, "pressure_surge")
	_check(is_equal_approx(float(pressure_surge.get("base_score", 0.0)), 12.6), "numerical tree scores unconditional damage plus the weighted momentum bonus")
	_check(not (pressure_surge.get("issues", []) as Array).has("under_budget"), "conditional bonus damage no longer produces a false under-budget advisory")
	var ash_guard: Dictionary = _row_by_id(cards, "ash_guard")
	_check(is_equal_approx(float(ash_guard.get("base_score", 0.0)), 7.04), "numerical tree weights only ash guard's conditional block bonus")
	var ember_exile: Dictionary = _row_by_id(players, "ember_exile")
	_check(int(ember_exile.get("max_hp", 0)) == 70 and int(ember_exile.get("starter_deck_size", 0)) == 10, "default character matches stable starter budget")
	_check(is_equal_approx(float(ember_exile.get("starter_deck_score", 0.0)), 73.86), "default starter deck matches the rebaseline effect-point score")
	var arc_tinker: Dictionary = _row_by_id(players, "arc_tinker")
	var pyre_ascetic: Dictionary = _row_by_id(players, "pyre_ascetic")
	_check(is_equal_approx(float(ember_exile.get("opening_package_score", 0.0)), 79.14), "ember opening package includes the reduced deterministic relics and steel manual")
	_check(is_equal_approx(float(arc_tinker.get("opening_package_score", 0.0)), 75.77), "arc opening package trades pure setup for a second active defense card")
	_check(is_equal_approx(float(pyre_ascetic.get("opening_package_score", 0.0)), 79.73), "pyre opening package shifts power from free relic block into active starter defense")
	_check(is_equal_approx(float(ember_exile.get("opening_package_target_min", 0.0)), 72.0) and is_equal_approx(float(ember_exile.get("opening_package_target_max", 0.0)), 80.0), "ember opening package exposes its rebaseline target")
	_check(is_equal_approx(float(arc_tinker.get("opening_package_target_min", 0.0)), 70.0) and is_equal_approx(float(arc_tinker.get("opening_package_target_max", 0.0)), 78.0), "arc opening package exposes its rebaseline target")
	_check(is_equal_approx(float(pyre_ascetic.get("opening_package_target_min", 0.0)), 72.0) and is_equal_approx(float(pyre_ascetic.get("opening_package_target_max", 0.0)), 80.0), "pyre opening package exposes its rebaseline target")
	for player in [ember_exile, arc_tinker, pyre_ascetic]:
		_check(str(player.get("opening_package_severity", "")) == "ok", "opening package is inside the independent target: %s" % str(player.get("id", "")))
		_check((player.get("opening_package_issues", []) as Array).is_empty(), "opening package has no pressure issue after rebaseline: %s" % str(player.get("id", "")))
		_check(_opening_contributions_complete(player), "opening package contributions are complete and sum to the reported score: %s" % str(player.get("id", "")))
	_check(_opening_has_category(ember_exile, "starter_deck") and _opening_has_category(ember_exile, "starter_relic") and _opening_has_category(ember_exile, "skill_book"), "ember opening package separates deck, relic, and skill-book contributions")
	_check(_opening_has_category(arc_tinker, "starting_momentum"), "arc opening package records base momentum separately")
	_check(_row_by_source_id(pyre_ascetic.get("opening_package_exclusions", []), "penitent_censer").get("reason", "") == "conditional_trigger", "pyre censer is excluded because its value depends on creating a wound")
	var conditional_opening_effect := {"trigger": "combat_start", "type": "gain_block", "amount": 5, "requires_momentum_at_least": 3}
	_check(auditor._opening_contribution("starter_relic", "conditional_fixture", conditional_opening_effect).is_empty(), "conditional combat-start effects are not counted as deterministic opening value")
	_check(str(auditor._opening_exclusion("starter_relic", "conditional_fixture", conditional_opening_effect).get("reason", "")) == "conditional_trigger", "conditional combat-start effects explain their exclusion")
	for condition_fixture in [
		{"key": "min_card_cost", "value": 2},
		{"key": "card_type", "value": "attack"},
		{"key": "every_n_attack_cards", "value": 3},
	]:
		var conditioned_effect := {"trigger": "combat_start", "type": "gain_block", "amount": 5}
		conditioned_effect[str(condition_fixture.get("key", ""))] = condition_fixture.get("value")
		var source_id: String = "conditional_%s" % str(condition_fixture.get("key", ""))
		_check(auditor._opening_contribution("starter_relic", source_id, conditioned_effect).is_empty(), "runtime relic condition is excluded from deterministic opening value: %s" % source_id)
		_check(str(auditor._opening_exclusion("starter_relic", source_id, conditioned_effect).get("reason", "")) == "conditional_trigger", "runtime relic condition reports conditional_trigger: %s" % source_id)
	var error: Error = auditor.save_report(report, REPORT_PATH)
	_check(error == OK and FileAccess.file_exists(REPORT_PATH), "numerical tree auditor saves JSON report")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(REPORT_PATH))
	_check(saved is Dictionary and str(saved.get("audit_model", "")) == "static_numerical_tree", "saved numerical tree report is valid JSON")
	if not _failures.is_empty():
		push_error("Numerical tree auditor test failed with %d issue(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Numerical tree auditor smoke test passed.")
	quit(0)

func _row_by_id(rows: Array, row_id: String) -> Dictionary:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == row_id:
			return row
	return {}

func _row_by_source_id(rows: Array, source_id: String) -> Dictionary:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("source_id", "")) == source_id:
			return row
	return {}

func _opening_has_category(player: Dictionary, category: String) -> bool:
	for contribution_value in player.get("opening_package_contributions", []):
		var contribution: Dictionary = contribution_value
		if str(contribution.get("category", "")) == category:
			return true
	return false

func _opening_contributions_complete(player: Dictionary) -> bool:
	var contributions: Array = player.get("opening_package_contributions", [])
	if contributions.is_empty():
		return false
	var summed_score := 0.0
	for contribution_value in contributions:
		var contribution: Dictionary = contribution_value
		for key in ["category", "source_id", "trigger", "effect_type", "raw_amount", "point_weight", "score"]:
			if not contribution.has(key):
				return false
		if str(contribution.get("category", "")).is_empty() or str(contribution.get("source_id", "")).is_empty() or str(contribution.get("trigger", "")).is_empty() or str(contribution.get("effect_type", "")).is_empty():
			return false
		summed_score += float(contribution.get("score", 0.0))
	return is_equal_approx(snappedf(summed_score, 0.01), float(player.get("opening_package_score", 0.0)))

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
