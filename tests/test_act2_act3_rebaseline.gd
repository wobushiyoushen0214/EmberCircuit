extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var economy: Dictionary = DataLoaderScript.load_json("res://data/config/economy.json")
	var tree: Dictionary = DataLoaderScript.load_json("res://data/config/numerical_tree.json")
	var enemies: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var challenges: Dictionary = DataLoaderScript.load_json("res://data/config/challenges.json")

	var rebaseline: Dictionary = tree.get("campaign_rebaseline", {})
	_check(str(rebaseline.get("status", "")) == "paused_no_candidate_passed", "campaign rebaseline pauses when every frozen candidate fails")
	_check(str(rebaseline.get("selected_step", "")) == "" and str(rebaseline.get("direction_report_path", "")) == "", "campaign rebaseline does not select an unverified candidate")
	_check(rebaseline.get("candidate_order", []) == ["R1", "R2", "R2-A", "R2-B"], "campaign rebaseline preserves the frozen candidate order")
	var candidate_results: Array = rebaseline.get("candidate_results", [])
	_check(candidate_results.size() == 4, "campaign rebaseline records all four frozen candidate outcomes")
	if candidate_results.size() == 4:
		var r1_result: Dictionary = candidate_results[0]
		var r2_result: Dictionary = candidate_results[1]
		var r2a_result: Dictionary = candidate_results[2]
		var r2b_result: Dictionary = candidate_results[3]
		_check(str(r1_result.get("step_id", "")) == "R1" and str(r1_result.get("status", "")) == "rejected_direction_gate" and str(r1_result.get("report_sha256", "")).length() == 64, "R1 rejection records its independent 128 report evidence")
		_check(str(r2_result.get("step_id", "")) == "R2" and str(r2_result.get("status", "")) == "rejected_direction_gate" and str(r2_result.get("report_sha256", "")).length() == 64, "R2 rejection records its independent 128 report evidence")
		_check(str(r2a_result.get("step_id", "")) == "R2-A" and str(r2a_result.get("status", "")) == "rejected_static_gate" and str(r2a_result.get("hard_warning", "")) == "null_workshop:encounter_hp_low", "R2-A rejection records the static budget hard warning")
		_check(str(r2b_result.get("step_id", "")) == "R2-B" and str(r2b_result.get("status", "")) == "not_run_inherits_static_gate" and str(r2b_result.get("inherited_from", "")) == "R2-A", "R2-B stops without duplicating an inherited static failure")

	var reward_generation: Dictionary = economy.get("reward_generation", {})
	var potion_reward: Dictionary = economy.get("potion_reward", {})
	var chapter_bonus: Dictionary = economy.get("combat_gold_rewards", {}).get("chapter_bonus", {})
	_check(is_equal_approx(float(reward_generation.get("combat_card_accept_score", -1.0)), 8.2), "paused rebaseline restores the baseline combat reward accept threshold")
	_check(int(reward_generation.get("skip_reward_when_deck_at_least", -1)) == 15, "paused rebaseline restores the baseline reward skip deck size")
	_check(int(potion_reward.get("drop_chance_percent", -1)) == 45, "paused rebaseline restores the baseline potion drop chance")
	_check([int(chapter_bonus.get("chapter_one", -1)), int(chapter_bonus.get("chapter_two", -1)), int(chapter_bonus.get("chapter_three", -1))] == [0, 3, 6], "paused rebaseline restores the baseline chapter gold bonuses")

	var snapshot: Dictionary = tree.get("audit_inventory", {}).get("economy_snapshot", {})
	_check(is_equal_approx(float(snapshot.get("combat_card_reward_accept_score", -1.0)), 8.2), "numerical snapshot tracks the baseline reward threshold")
	_check(int(snapshot.get("skip_reward_when_deck_at_least", -1)) == 15 and int(snapshot.get("potion_drop_chance_percent", -1)) == 45, "numerical snapshot tracks the baseline skip and potion values")

	var enemies_by_id := _index_by_id(enemies.get("enemies", []))
	var frozen_act1_hp := {
		"soot_raider": 34,
		"ash_hound": 28,
		"plague_alchemist": 40,
		"iron_shell_guard": 40,
		"bomb_mite": 24,
		"thorn_shield": 34,
		"ember_wraith": 34,
		"twinblade_executor": 86,
		"furnace_colossus": 96,
		"forge_bishop": 116,
	}
	for enemy_id in frozen_act1_hp:
		_check(int((enemies_by_id.get(enemy_id, {}) as Dictionary).get("max_hp", -1)) == int(frozen_act1_hp[enemy_id]), "R1 freezes Act 1 enemy HP: %s" % enemy_id)

	var baseline_act2_hp := {
		"volt_cultist": 46,
		"glass_sentinel": 54,
		"null_mender": 42,
		"storm_cantor": 48,
		"prism_scrapper": 52,
		"rust_colossus": 106,
		"storm_archon": 116,
	}
	for enemy_id in baseline_act2_hp:
		var enemy: Dictionary = enemies_by_id.get(enemy_id, {})
		_check(int(enemy.get("max_hp", -1)) == int(baseline_act2_hp[enemy_id]), "paused rebaseline restores baseline Act 2 HP: %s" % enemy_id)
		_check(not str(enemy.get("balance_note", "")).contains("R2-A"), "paused rebaseline removes rejected Act 2 candidate notes: %s" % enemy_id)

	var targets: Dictionary = tree.get("campaign_targets", {})
	_check(targets.get("normal_win_rate_range", []) == [0.27, 0.33], "normal campaign target remains frozen")
	_check(targets.get("challenge_1_win_rate_range", []) == [0.17, 0.26] and targets.get("challenge_2_win_rate_range", []) == [0.12, 0.23] and targets.get("challenge_3_win_rate_range", []) == [0.08, 0.15], "challenge campaign targets remain frozen")
	_check(is_equal_approx(float(targets.get("max_character_win_rate_gap", -1.0)), 0.09) and int(targets.get("minimum_iterations_for_hard_gate", 0)) == 128, "character gap and hard-gate sample floor remain frozen")
	_check((tree.get("campaign_matrix", {}).get("rows", []) as Array).size() == 12, "R1 preserves the formal twelve-cell matrix")
	_check((challenges.get("levels", []) as Array).size() == 4, "R1 preserves all four challenge levels")

	if failed:
		quit(1)
		return
	print("Act 2/3 campaign rebaseline contract test passed.")
	quit(0)

func _index_by_id(rows: Array) -> Dictionary:
	var indexed: Dictionary = {}
	for row_value in rows:
		var row: Dictionary = row_value
		indexed[str(row.get("id", ""))] = row
	return indexed

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
