extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const NumericalTreeAuditorScript = preload("res://scripts/tools/NumericalTreeAuditor.gd")
const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var tree: Dictionary = DataLoaderScript.load_json("res://data/config/numerical_tree.json")
	var players: Dictionary = DataLoaderScript.load_json("res://data/config/player.json")
	var cards: Dictionary = DataLoaderScript.load_json("res://data/cards/cards.json")
	var enemies: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var encounters: Dictionary = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	var progression: Dictionary = DataLoaderScript.load_json("res://data/config/progression_systems.json")
	var challenges: Dictionary = DataLoaderScript.load_json("res://data/config/challenges.json")
	var economy: Dictionary = DataLoaderScript.load_json("res://data/config/economy.json")
	var audit_report: Dictionary = NumericalTreeAuditorScript.new().build_report()

	_check(int(tree.get("version", 0)) == 3, "numerical tree exposes pressure contract schema version three")
	_check_pressure_contract(tree.get("pressure_contract", {}))
	_check_human_playtest_targets(tree.get("human_playtest_targets", {}))
	_check_inventory(tree.get("audit_inventory", {}), cards, enemies, encounters, progression, challenges, economy, audit_report)
	_check_matrix(tree, players, cards, progression, challenges, audit_report)
	if failed:
		quit(1)
		return
	print("Numerical balance matrix contract test passed.")
	quit(0)

func _check_human_playtest_targets(targets: Dictionary) -> void:
	_check(int(targets.get("schema_version", 0)) == 1, "human playtest targets expose a versioned contract")
	_check(int(targets.get("report_schema_version", 0)) == PlaytestTelemetryScript.SCHEMA_VERSION, "human targets match the runtime report schema")
	_check(targets.get("win_rate_denominator_outcomes", []) == ["victory", "defeat"], "human win rate excludes unfinished runs from its denominator")
	_check(targets.get("excluded_outcomes", []) == ["abandoned", "in_progress"], "human targets name unfinished outcomes explicitly")
	_check(int(targets.get("directional_finished_runs_per_cell", 0)) >= 10, "human directional review requires a useful sample per character and challenge")
	_check(int(targets.get("hard_gate_finished_runs_per_cell", 0)) >= 30, "human hard gate requires a larger sample per character and challenge")
	_check(int(targets.get("hard_gate_finished_runs_per_cell", 0)) > int(targets.get("directional_finished_runs_per_cell", 0)), "human hard gate sample exceeds directional sample")
	_check(is_equal_approx(float(targets.get("max_character_win_rate_gap", 0.0)), 0.05), "human character win-rate gap target remains five percent")
	_check(float(targets.get("single_failure_encounter_share_max", 0.0)) <= 0.5, "human failure concentration has an explicit ceiling")
	_check(float(targets.get("max_abandon_rate", 0.0)) <= 0.35, "human abandon rate has an explicit ceiling outside the win-rate denominator")
	_check(int(targets.get("minimum_card_comparison_runs", 0)) >= 20, "human card comparisons require enough acquired or played runs")

func _check_pressure_contract(contract: Dictionary) -> void:
	_check(int(contract.get("schema_version", 0)) == 1, "pressure contract exposes schema version one")
	_check(int(contract.get("minimum_iterations", 0)) == 64, "single encounter pressure hard gate requires 64 iterations")
	var tier_targets: Dictionary = contract.get("single_encounter_tier_targets", {})
	_check(tier_targets.keys().size() == 3, "pressure contract freezes exactly three encounter tiers")
	for tier in ["normal", "elite", "boss"]:
		var target: Dictionary = tier_targets.get(tier, {})
		_check(target.has("win_rate_min") and target.has("win_rate_max") and target.has("perfect_win_rate_max"), "pressure target is complete: %s" % tier)
		_check(float(target.get("win_rate_min", 1.0)) < float(target.get("win_rate_max", 0.0)), "pressure target win-rate range is ordered: %s" % tier)
		_check(float(target.get("perfect_win_rate_max", -1.0)) >= 0.0 and float(target.get("perfect_win_rate_max", 2.0)) <= 1.0, "pressure target perfect-win ceiling is normalized: %s" % tier)

func _check_inventory(inventory: Dictionary, cards: Dictionary, enemies: Dictionary, encounters: Dictionary, progression: Dictionary, challenges: Dictionary, economy: Dictionary, audit_report: Dictionary) -> void:
	var card_inventory: Dictionary = inventory.get("cards", {})
	var all_cards: Array = cards.get("cards", [])
	var auditable_cards: Array = all_cards.filter(func(card: Dictionary) -> bool: return not str(card.get("type", "")) in ["status", "curse"])
	_check(all_cards.size() == int(card_inventory.get("total_count", -1)), "inventory tracks every card")
	_check(auditable_cards.size() == int(card_inventory.get("auditable_count", -1)), "inventory tracks every auditable card")
	_check(all_cards.size() - auditable_cards.size() == int(card_inventory.get("status_count", -1)), "inventory tracks excluded status and curse cards")
	var shared_count := 0
	var exclusive_counts: Dictionary = {}
	for card_value in auditable_cards:
		var card: Dictionary = card_value
		var character_ids: Array = card.get("character_ids", [])
		if character_ids.is_empty():
			shared_count += 1
		for character_id_value in character_ids:
			var character_id := str(character_id_value)
			exclusive_counts[character_id] = int(exclusive_counts.get(character_id, 0)) + 1
	_check(shared_count == int(card_inventory.get("shared_auditable_count", -1)), "inventory tracks shared auditable cards")
	_check(_count_dictionaries_equal(exclusive_counts, card_inventory.get("exclusive_counts", {})), "inventory tracks every character-exclusive card")

	var summary: Dictionary = audit_report.get("summary", {})
	_check(int(summary.get("card_count", -1)) == int(card_inventory.get("auditable_count", -2)), "static report card coverage matches inventory")
	_check(int(summary.get("card_advisory_count", -1)) == int(card_inventory.get("expected_advisory_count", -2)), "static report advisory count matches reviewed baseline")
	var warning_ids: Array = []
	for row_value in audit_report.get("cards", []):
		var row: Dictionary = row_value
		if str(row.get("severity", "")) == "warning":
			warning_ids.append(str(row.get("id", "")))
	warning_ids.sort()
	var expected_warning_ids: Array = card_inventory.get("expected_warning_ids", []).duplicate()
	expected_warning_ids.sort()
	_check(warning_ids == expected_warning_ids, "static report warnings match reviewed exceptions")

	var monster_inventory: Dictionary = inventory.get("monsters", {})
	_check((enemies.get("enemies", []) as Array).size() == int(monster_inventory.get("enemy_count", -1)), "inventory tracks every enemy")
	_check((encounters.get("encounters", []) as Array).size() == int(monster_inventory.get("encounter_count", -1)), "inventory tracks every encounter")
	_check(_count_dictionaries_equal(_count_by_key(encounters.get("encounters", []), "tier"), monster_inventory.get("encounter_tier_counts", {})), "inventory tracks encounter tiers")
	_check(int(summary.get("monster_encounter_count", -1)) == int(monster_inventory.get("audited_map_encounter_count", -2)), "static report encounter coverage matches inventory")
	_check(int(summary.get("monster_warning_count", -1)) == 0, "every map encounter stays inside its numerical budget")
	var pressure_inventory: Dictionary = inventory.get("pressure_contract", {})
	var opening_warning_ids: Array = []
	for row_value in audit_report.get("players", []):
		var row: Dictionary = row_value
		if str(row.get("opening_package_severity", "")) == "warning":
			opening_warning_ids.append(str(row.get("id", "")))
	opening_warning_ids.sort()
	var expected_opening_warning_ids: Array = pressure_inventory.get("opening_package_warning_ids", []).duplicate()
	expected_opening_warning_ids.sort()
	_check(opening_warning_ids == expected_opening_warning_ids, "inventory freezes every opening package warning")
	var monster_pressure_warning_ids: Array = []
	for row_value in audit_report.get("monsters", []):
		var row: Dictionary = row_value
		if str(row.get("pressure_severity", "")) == "warning":
			monster_pressure_warning_ids.append(str(row.get("id", "")))
	monster_pressure_warning_ids.sort()
	var expected_monster_pressure_warning_ids: Array = pressure_inventory.get("monster_pressure_warning_ids", []).duplicate()
	expected_monster_pressure_warning_ids.sort()
	_check(monster_pressure_warning_ids == expected_monster_pressure_warning_ids, "inventory freezes every monster pressure warning")
	_check(int(summary.get("opening_package_warning_count", 0)) == 3, "static summary records all three opening package warnings")
	_check(int(summary.get("monster_pressure_warning_count", 0)) == 16, "static summary records all sixteen monster pressure warnings")

	var progression_inventory: Dictionary = inventory.get("progression", {})
	var trees: Array = progression.get("character_trees", [])
	_check(trees.size() == int(progression_inventory.get("tree_count", -1)), "inventory tracks every progression tree")
	for tree_value in trees:
		var character_tree: Dictionary = tree_value
		var nodes: Array = character_tree.get("nodes", [])
		_check(nodes.size() == int(progression_inventory.get("nodes_per_tree", -1)), "progression tree node count matches inventory")
		_check(_sum_node_cost(nodes) == int(progression_inventory.get("cost_per_tree", -1)), "progression tree cost matches inventory")
	_check(int(audit_report.get("progression", {}).get("full_run_marks", -1)) == int(progression_inventory.get("full_run_marks", -2)), "progression reward cadence matches inventory")

	var challenge_inventory: Dictionary = inventory.get("challenges", {})
	var levels: Array = challenges.get("levels", [])
	_check(levels.size() == int(challenge_inventory.get("level_count", -1)), "inventory tracks every challenge")
	var level_ids: Array = levels.map(func(level: Dictionary) -> int: return int(level.get("level", -1)))
	_check(_int_arrays_equal(level_ids, challenge_inventory.get("levels", [])), "inventory tracks challenge ids in order")
	_check_economy_snapshot(inventory.get("economy_snapshot", {}), economy)

func _check_matrix(tree: Dictionary, players: Dictionary, cards: Dictionary, progression: Dictionary, challenges: Dictionary, audit_report: Dictionary) -> void:
	var matrix: Dictionary = tree.get("campaign_matrix", {})
	var character_ids: Array = matrix.get("character_ids", [])
	var challenge_levels: Array = matrix.get("challenge_levels", [])
	var rows: Array = matrix.get("rows", [])
	_check(str(matrix.get("seed_model", "")) == "paired_by_iteration", "matrix declares paired iteration seeds")
	_check(str(matrix.get("strategy_profile", "")) == "current-greedy", "campaign matrix declares the current greedy strategy baseline")
	_check(int(matrix.get("iterations_per_cell", 0)) >= int(tree.get("campaign_targets", {}).get("minimum_iterations_for_hard_gate", 0)), "matrix baseline meets the hard-gate sample floor")
	_check(rows.size() == character_ids.size() * challenge_levels.size(), "matrix contains the full character by challenge product")
	_check(character_ids == (players.get("characters", []) as Array).map(func(player: Dictionary) -> String: return str(player.get("id", ""))), "matrix character axis matches playable characters")
	_check(_int_arrays_equal(challenge_levels, (challenges.get("levels", []) as Array).map(func(level: Dictionary) -> int: return int(level.get("level", -1)))), "matrix challenge axis matches configured challenges")

	var players_by_id: Dictionary = DataLoaderScript.index_by_id(players.get("characters", []))
	var challenge_by_level: Dictionary = {}
	for level_value in challenges.get("levels", []):
		var level: Dictionary = level_value
		challenge_by_level[int(level.get("level", -1))] = level
	var report_players_by_id: Dictionary = DataLoaderScript.index_by_id(audit_report.get("players", []))
	var progression_cost_by_character: Dictionary = {}
	for tree_value in progression.get("character_trees", []):
		var character_tree: Dictionary = tree_value
		progression_cost_by_character[str(character_tree.get("character_id", ""))] = _sum_node_cost(character_tree.get("nodes", []))
	var shared_auditable_count := _shared_auditable_card_count(cards.get("cards", []))
	var seen: Dictionary = {}
	var rates_by_challenge: Dictionary = {}
	var out_of_tolerance_cells: Array = []
	var flagged_cells: Array = []
	var target_issues: Array = []
	var targets: Dictionary = tree.get("campaign_targets", {})
	var individual_tolerance: float = float(targets.get("individual_win_rate_tolerance", 0.0))
	for row_value in rows:
		var row: Dictionary = row_value
		var character_id := str(row.get("character_id", ""))
		var challenge_level := int(row.get("challenge_level", -1))
		var key := "%s:%d" % [character_id, challenge_level]
		_check(not seen.has(key), "matrix cell is unique: %s" % key)
		seen[key] = true
		var player: Dictionary = players_by_id.get(character_id, {})
		var level: Dictionary = challenge_by_level.get(challenge_level, {})
		var modifiers: Dictionary = level.get("modifiers", {})
		var report_player: Dictionary = report_players_by_id.get(character_id, {})
		_check(not player.is_empty() and not level.is_empty(), "matrix cell references configured axes: %s" % key)
		_check(int(row.get("base_max_hp", -1)) == int(player.get("max_hp", -2)), "matrix base hp matches player: %s" % key)
		_check(int(row.get("player_starting_hp_loss", -1)) == int(modifiers.get("player_starting_hp_loss", -2)), "matrix hp loss matches challenge: %s" % key)
		_check(int(row.get("effective_starting_hp", -1)) == int(player.get("starting_hp", 0)) - int(modifiers.get("player_starting_hp_loss", 0)), "matrix effective hp is executable: %s" % key)
		_check(is_equal_approx(float(row.get("enemy_hp_multiplier", -1.0)), float(modifiers.get("enemy_hp_multiplier", -2.0))), "matrix enemy hp multiplier matches challenge: %s" % key)
		_check(is_equal_approx(float(row.get("boss_hp_multiplier", -1.0)), float(modifiers.get("boss_hp_multiplier", -2.0))), "matrix boss hp multiplier matches challenge: %s" % key)
		_check(is_equal_approx(float(row.get("enemy_damage_multiplier", -1.0)), float(modifiers.get("enemy_damage_multiplier", -2.0))), "matrix enemy damage multiplier matches challenge: %s" % key)
		_check(is_equal_approx(float(row.get("starter_deck_score", -1.0)), float(report_player.get("starter_deck_score", -2.0))), "matrix starter score matches static audit: %s" % key)
		_check(int(row.get("accessible_auditable_cards", -1)) == shared_auditable_count + _exclusive_auditable_card_count(cards.get("cards", []), character_id), "matrix card pool coverage matches data: %s" % key)
		_check(int(row.get("progression_total_cost", -1)) == int(progression_cost_by_character.get(character_id, -2)), "matrix progression cost matches data: %s" % key)
		var target_range: Array = _target_range(targets, challenge_level)
		_check(_float_arrays_equal(row.get("target_win_rate_range", []), target_range), "matrix target range matches campaign target: %s" % key)
		var rate := float(row.get("observed_win_rate", -1.0))
		if target_range.size() != 2 or rate < float(target_range[0]) - individual_tolerance or rate > float(target_range[1]) + individual_tolerance:
			out_of_tolerance_cells.append(key)
		if str(row.get("risk_flag", "ok")) != "ok":
			flagged_cells.append(key)
		_check(float(row.get("avg_final_gold", -1.0)) >= 0.0 and float(row.get("avg_final_deck_size", -1.0)) > 0.0, "matrix cell includes economy outcomes: %s" % key)
		if not rates_by_challenge.has(challenge_level):
			rates_by_challenge[challenge_level] = []
		(rates_by_challenge[challenge_level] as Array).append(rate)

	var previous_average := 1.0
	for challenge_level_value in challenge_levels:
		var challenge_level := int(challenge_level_value)
		var rates: Array = rates_by_challenge.get(challenge_level, [])
		var average := _average(rates)
		var target_range := _target_range(targets, challenge_level)
		if average < float(target_range[0]):
			target_issues.append("challenge_%d:average_win_rate_low" % challenge_level)
		elif average > float(target_range[1]):
			target_issues.append("challenge_%d:average_win_rate_high" % challenge_level)
		if _maximum(rates) - _minimum(rates) > float(targets.get("max_character_win_rate_gap", 1.0)):
			target_issues.append("challenge_%d:character_win_rate_gap_high" % challenge_level)
		if average > previous_average + float(targets.get("challenge_monotonic_tolerance", 0.0)):
			target_issues.append("challenge_%d:win_rate_not_monotonic" % challenge_level)
		previous_average = average
	out_of_tolerance_cells.sort()
	flagged_cells.sort()
	target_issues.sort()
	var expected_out_of_tolerance: Array = matrix.get("expected_out_of_tolerance_cells", []).duplicate()
	var expected_flagged: Array = matrix.get("expected_flagged_cells", []).duplicate()
	var expected_target_issues: Array = matrix.get("expected_target_issues", []).duplicate()
	expected_out_of_tolerance.sort()
	expected_flagged.sort()
	expected_target_issues.sort()
	_check(out_of_tolerance_cells == expected_out_of_tolerance, "matrix declares every individual win-rate exception")
	_check(flagged_cells == expected_flagged, "matrix declares every simulator risk flag")
	_check(target_issues == expected_target_issues, "matrix declares every aggregate target issue")

func _check_economy_snapshot(snapshot: Dictionary, economy: Dictionary) -> void:
	var rewards: Dictionary = economy.get("combat_gold_rewards", {}).get("by_tier", {})
	var treasure: Dictionary = economy.get("treasure", {})
	var shop: Dictionary = economy.get("shop", {})
	var potion: Dictionary = economy.get("potion_reward", {})
	var reward_generation: Dictionary = economy.get("reward_generation", {})
	_check(_int_arrays_equal(_range_from_dictionary(rewards.get("normal", {})), snapshot.get("normal_gold", [])), "economy snapshot tracks normal gold")
	_check(_int_arrays_equal(_range_from_dictionary(rewards.get("elite", {})), snapshot.get("elite_gold", [])), "economy snapshot tracks elite gold")
	_check(_int_arrays_equal(_range_from_dictionary(rewards.get("boss", {})), snapshot.get("boss_gold", [])), "economy snapshot tracks boss gold")
	_check(_int_arrays_equal([int(treasure.get("gold_min", -1)), int(treasure.get("gold_max", -1))], snapshot.get("treasure_gold", [])), "economy snapshot tracks treasure gold")
	_check(int(shop.get("remove_card_price", -1)) == int(snapshot.get("shop_remove_base", -2)), "economy snapshot tracks removal base")
	_check(int(shop.get("remove_card_price_increase", -1)) == int(snapshot.get("shop_remove_increase", -2)), "economy snapshot tracks removal increase")
	_check(int(potion.get("drop_chance_percent", -1)) == int(snapshot.get("potion_drop_chance_percent", -2)), "economy snapshot tracks potion chance")
	_check(is_equal_approx(float(reward_generation.get("combat_card_accept_score", -1.0)), float(snapshot.get("combat_card_reward_accept_score", -2.0))), "economy snapshot tracks reward threshold")
	_check(int(reward_generation.get("skip_reward_when_deck_at_least", -1)) == int(snapshot.get("skip_reward_when_deck_at_least", -2)), "economy snapshot tracks deck skip threshold")

func _count_by_key(rows: Array, key: String) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in rows:
		var row: Dictionary = row_value
		var value := str(row.get(key, ""))
		counts[value] = int(counts.get(value, 0)) + 1
	return counts

func _sum_node_cost(nodes: Array) -> int:
	var total := 0
	for node_value in nodes:
		total += int((node_value as Dictionary).get("cost", 0))
	return total

func _shared_auditable_card_count(rows: Array) -> int:
	var count := 0
	for card_value in rows:
		var card: Dictionary = card_value
		if not str(card.get("type", "")) in ["status", "curse"] and (card.get("character_ids", []) as Array).is_empty():
			count += 1
	return count

func _exclusive_auditable_card_count(rows: Array, character_id: String) -> int:
	var count := 0
	for card_value in rows:
		var card: Dictionary = card_value
		if not str(card.get("type", "")) in ["status", "curse"] and (card.get("character_ids", []) as Array).has(character_id):
			count += 1
	return count

func _target_range(targets: Dictionary, challenge_level: int) -> Array:
	return targets.get("normal_win_rate_range" if challenge_level == 0 else "challenge_%d_win_rate_range" % challenge_level, [])

func _range_from_dictionary(value: Dictionary) -> Array:
	return [int(value.get("min", -1)), int(value.get("max", -1))]

func _count_dictionaries_equal(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for key in actual.keys():
		if not expected.has(key) or int(actual.get(key, -1)) != int(expected.get(key, -2)):
			return false
	return true

func _int_arrays_equal(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in range(actual.size()):
		if int(actual[index]) != int(expected[index]):
			return false
	return true

func _float_arrays_equal(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in range(actual.size()):
		if not is_equal_approx(float(actual[index]), float(expected[index])):
			return false
	return true

func _average(values: Array) -> float:
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(max(1, values.size()))

func _minimum(values: Array) -> float:
	var result := 1.0
	for value in values:
		result = min(result, float(value))
	return result

func _maximum(values: Array) -> float:
	var result := 0.0
	for value in values:
		result = max(result, float(value))
	return result

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		failed = true
