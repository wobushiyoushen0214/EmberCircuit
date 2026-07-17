class_name NumericalTreeAuditor
extends RefCounted

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const NumericalPressureMetricsScript = preload("res://scripts/tools/NumericalPressureMetrics.gd")

var card_data: Dictionary = {}
var enemy_data: Dictionary = {}
var encounter_data: Dictionary = {}
var player_data: Dictionary = {}
var relic_data: Dictionary = {}
var challenge_data: Dictionary = {}
var economy_data: Dictionary = {}
var map_generation_data: Dictionary = {}
var level_tree_data: Dictionary = {}
var progression_data: Dictionary = {}
var numerical_tree_data: Dictionary = {}
var monster_scaling_data: Dictionary = {}

func load_default_data() -> void:
	card_data = DataLoaderScript.load_json("res://data/cards/cards.json")
	enemy_data = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	encounter_data = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	player_data = DataLoaderScript.load_json("res://data/config/player.json")
	relic_data = DataLoaderScript.load_json("res://data/relics/relics.json")
	challenge_data = DataLoaderScript.load_json("res://data/config/challenges.json")
	economy_data = DataLoaderScript.load_json("res://data/config/economy.json")
	map_generation_data = DataLoaderScript.load_json("res://data/config/map_generation.json")
	level_tree_data = DataLoaderScript.load_json("res://data/config/level_tree.json")
	progression_data = DataLoaderScript.load_json("res://data/config/progression_systems.json")
	numerical_tree_data = DataLoaderScript.load_json("res://data/config/numerical_tree.json")
	monster_scaling_data = DataLoaderScript.load_json("res://data/config/monster_scaling.json")

func build_report() -> Dictionary:
	if numerical_tree_data.is_empty():
		load_default_data()
	var card_rows: Array = _audit_cards()
	var player_rows: Array = _audit_players()
	var monster_rows: Array = _audit_monsters()
	var economy_report: Dictionary = _audit_economy()
	var progression_report: Dictionary = _audit_progression()
	return {
		"version": int(numerical_tree_data.get("version", 1)),
		"audit_model": "static_numerical_tree",
		"cards": card_rows,
		"players": player_rows,
		"monsters": monster_rows,
		"economy": economy_report,
		"progression": progression_report,
		"summary": _build_summary(card_rows, player_rows, monster_rows, economy_report, progression_report)
	}

func save_report(report: Dictionary, output_path: String) -> Error:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(report, "\t"))
	return OK

func _audit_cards() -> Array:
	var rows: Array = []
	for card_value in card_data.get("cards", []):
		var card: Dictionary = card_value
		if str(card.get("type", "")) in ["status", "curse"]:
			continue
		var base_score: float = _score_card(card, false)
		var upgrade_score: float = _score_card(card, true)
		var budget: Dictionary = _card_budget(card)
		var upgrade_budget: Dictionary = _card_upgrade_budget(card)
		var issues: Array = []
		var severity := "ok"
		var hard_tolerance: float = float(numerical_tree_data.get("cards", {}).get("hard_tolerance", 1.5))
		if base_score < float(budget.get("min", 0.0)):
			issues.append("under_budget")
			if float(budget.get("min", 0.0)) - base_score > hard_tolerance:
				severity = "warning"
		elif base_score > float(budget.get("max", 999.0)):
			issues.append("over_budget")
			if base_score - float(budget.get("max", 999.0)) > hard_tolerance:
				severity = "warning"
		var delta: float = upgrade_score - base_score + _upgrade_cost_saving_score(card)
		if card.has("upgrade"):
			if delta < float(upgrade_budget.get("min", 0.0)):
				issues.append("upgrade_low_delta")
				if float(upgrade_budget.get("min", 0.0)) - delta > hard_tolerance:
					severity = "warning"
			elif delta > float(upgrade_budget.get("max", 999.0)):
				issues.append("upgrade_high_delta")
				if delta - float(upgrade_budget.get("max", 999.0)) > hard_tolerance:
					severity = "warning"
		if severity == "ok" and not issues.is_empty():
			severity = "advisory"
		rows.append({
			"id": str(card.get("id", "")),
			"name": str(card.get("name", "")),
			"cost": int(card.get("cost", 0)),
			"type": str(card.get("type", "")),
			"rarity": str(card.get("rarity", "")),
			"base_score": _round_to(base_score, 2),
			"target_min": _round_to(float(budget.get("min", 0.0)), 2),
			"target_max": _round_to(float(budget.get("max", 0.0)), 2),
			"upgrade_delta": _round_to(delta, 2),
			"upgrade_delta_min": _round_to(float(upgrade_budget.get("min", 0.0)), 2),
			"upgrade_delta_max": _round_to(float(upgrade_budget.get("max", 0.0)), 2),
			"severity": severity,
			"issues": issues
		})
	return rows

func _audit_players() -> Array:
	var rows: Array = []
	var cards_by_id: Dictionary = DataLoaderScript.index_by_id(card_data.get("cards", []))
	var relics_by_id: Dictionary = DataLoaderScript.index_by_id(relic_data.get("relics", []))
	var player_targets: Dictionary = numerical_tree_data.get("players", {})
	var starter_targets: Dictionary = numerical_tree_data.get("cards", {}).get("starter_deck", {})
	var character_targets: Dictionary = player_targets.get("character_targets", {})
	var opening_targets: Dictionary = numerical_tree_data.get("pressure_contract", {}).get("opening_package_targets", {})
	var default_skill_book: Dictionary = _default_skill_book()
	var default_character_id: String = str(player_data.get("default_character_id", ""))
	var legacy_player: Dictionary = player_data.get("player", {})
	for character_value in player_data.get("characters", []):
		var character: Dictionary = character_value
		var character_id: String = str(character.get("id", ""))
		var target: Dictionary = character_targets.get(character_id, {})
		var issues: Array = []
		var deck_ids: Array = character.get("starter_deck_ids", [])
		var attack_count := 0
		var skill_count := 0
		var zero_cost_count := 0
		var deck_score := 0.0
		var missing_card_ids: Array = []
		for card_id_value in deck_ids:
			var card_id: String = str(card_id_value).trim_suffix("+")
			var card: Dictionary = cards_by_id.get(card_id, {})
			if card.is_empty():
				missing_card_ids.append(card_id)
				continue
			match str(card.get("type", "")):
				"attack":
					attack_count += 1
				"skill":
					skill_count += 1
			if int(card.get("cost", 0)) == 0:
				zero_cost_count += 1
			deck_score += _score_card(card, false)

		var hp_range: Array = target.get("max_hp", player_targets.get("max_hp_range", [0, 999]))
		var attack_range: Array = target.get("starter_attack_count", starter_targets.get("attack_count_range", [0, 999]))
		var skill_range: Array = target.get("starter_skill_count", starter_targets.get("skill_count_range", [0, 999]))
		var zero_cost_range: Array = target.get("starter_zero_cost_count", starter_targets.get("zero_cost_count_range", [0, 999]))
		var deck_score_range: Array = target.get("starter_deck_score", [0.0, 9999.0])
		if not missing_card_ids.is_empty():
			issues.append("starter_cards_missing")
		if deck_ids.size() != int(starter_targets.get("target_size", 10)):
			issues.append("starter_deck_size_out_of_range")
		if _int_outside_range(int(character.get("max_hp", 0)), hp_range):
			issues.append("max_hp_out_of_range")
		if bool(player_targets.get("starting_hp_must_equal_max", true)) and int(character.get("starting_hp", 0)) != int(character.get("max_hp", 0)):
			issues.append("starting_hp_not_max")
		if int(character.get("max_energy", 0)) != int(player_targets.get("required_max_energy", 3)):
			issues.append("max_energy_mismatch")
		if _int_outside_range(int(character.get("momentum_max", 0)), player_targets.get("momentum_max_range", [0, 999])):
			issues.append("momentum_max_out_of_range")
		if _int_outside_range(int(character.get("starting_gold", 0)), player_targets.get("starting_gold_range", [0, 999])):
			issues.append("starting_gold_out_of_range")
		if _int_outside_range(int(character.get("potion_slots", 0)), player_targets.get("potion_slot_range", [0, 999])):
			issues.append("potion_slots_out_of_range")
		if _int_outside_range((character.get("starter_relic_ids", []) as Array).size(), player_targets.get("starter_relic_count_range", [0, 999])):
			issues.append("starter_relic_count_out_of_range")
		if _int_outside_range(attack_count, attack_range):
			issues.append("starter_attack_count_out_of_range")
		if _int_outside_range(skill_count, skill_range):
			issues.append("starter_skill_count_out_of_range")
		if _int_outside_range(zero_cost_count, zero_cost_range):
			issues.append("starter_zero_cost_count_out_of_range")
		if _float_outside_range(deck_score, deck_score_range):
			issues.append("starter_deck_score_out_of_range")
		if character_id == default_character_id and not _legacy_player_matches_character(legacy_player, character):
			issues.append("legacy_player_mismatch")

		var opening_contributions: Array = [{
			"category": "starter_deck",
			"source_id": character_id,
			"trigger": "loadout",
			"effect_type": "starter_deck_score",
			"raw_amount": _round_to(deck_score, 2),
			"point_weight": 1.0,
			"score": _round_to(deck_score, 2),
		}]
		var opening_exclusions: Array = []
		var starting_momentum: int = max(0, int(character.get("starting_momentum", 0)))
		if starting_momentum > 0:
			opening_contributions.append(_opening_contribution("starting_momentum", character_id, {
				"trigger": "combat_setup",
				"type": "gain_momentum",
				"amount": starting_momentum,
			}))
		for relic_id_value in character.get("starter_relic_ids", []):
			var relic_id: String = str(relic_id_value)
			var relic: Dictionary = relics_by_id.get(relic_id, {})
			if relic.is_empty():
				opening_exclusions.append({"category": "starter_relic", "source_id": relic_id, "reason": "missing_source"})
				continue
			for effect_value in relic.get("effects", []):
				var effect: Dictionary = effect_value
				var contribution: Dictionary = _opening_contribution("starter_relic", relic_id, effect)
				if contribution.is_empty():
					opening_exclusions.append(_opening_exclusion("starter_relic", relic_id, effect))
				else:
					opening_contributions.append(contribution)
		if not default_skill_book.is_empty():
			var skill_book_id: String = str(default_skill_book.get("id", ""))
			for effect_value in default_skill_book.get("effects", []):
				var effect: Dictionary = effect_value
				var contribution: Dictionary = _opening_contribution("skill_book", skill_book_id, effect)
				if contribution.is_empty():
					opening_exclusions.append(_opening_exclusion("skill_book", skill_book_id, effect))
				else:
					opening_contributions.append(contribution)
		var opening_score := 0.0
		for contribution_value in opening_contributions:
			opening_score += float((contribution_value as Dictionary).get("score", 0.0))
		var opening_range: Array = opening_targets.get(character_id, [0.0, 9999.0])
		var opening_issues: Array = []
		if opening_score < float(opening_range[0]):
			opening_issues.append("opening_package_low")
		elif opening_score > float(opening_range[1]):
			opening_issues.append("opening_package_high")

		rows.append({
			"id": character_id,
			"name": str(character.get("name", character_id)),
			"max_hp": int(character.get("max_hp", 0)),
			"starting_hp": int(character.get("starting_hp", 0)),
			"max_energy": int(character.get("max_energy", 0)),
			"momentum_max": int(character.get("momentum_max", 0)),
			"starting_gold": int(character.get("starting_gold", 0)),
			"potion_slots": int(character.get("potion_slots", 0)),
			"starter_deck_size": deck_ids.size(),
			"starter_attack_count": attack_count,
			"starter_skill_count": skill_count,
			"starter_zero_cost_count": zero_cost_count,
			"starter_relic_count": (character.get("starter_relic_ids", []) as Array).size(),
			"starter_deck_score": _round_to(deck_score, 2),
			"starter_deck_score_target": deck_score_range,
			"opening_package_score": _round_to(opening_score, 2),
			"opening_package_target_min": float(opening_range[0]),
			"opening_package_target_max": float(opening_range[1]),
			"opening_package_contributions": opening_contributions,
			"opening_package_exclusions": opening_exclusions,
			"opening_package_severity": "warning" if not opening_issues.is_empty() else "ok",
			"opening_package_issues": opening_issues,
			"missing_card_ids": missing_card_ids,
			"severity": "warning" if not issues.is_empty() else "ok",
			"issues": issues
		})
	return rows

func _default_skill_book() -> Dictionary:
	for book_value in progression_data.get("skill_books", []):
		var book: Dictionary = book_value
		if str(book.get("unlock", {}).get("type", "")) == "default":
			return book
	return {}

func _opening_contribution(category: String, source_id: String, effect: Dictionary) -> Dictionary:
	if not _opening_effect_is_deterministic(effect):
		return {}
	var effect_type: String = str(effect.get("type", ""))
	var points: Dictionary = numerical_tree_data.get("effect_points", {})
	var point_weight := 0.0
	match effect_type:
		"gain_block", "block":
			point_weight = float(points.get("block", 0.0))
		"draw":
			point_weight = float(points.get("draw", 0.0))
		"gain_momentum":
			point_weight = float(points.get("gain_momentum", 0.0))
		"gain_energy":
			point_weight = float(points.get("gain_energy", 0.0))
		_:
			return {}
	var raw_amount: int = max(0, int(effect.get("amount", 0)))
	return {
		"category": category,
		"source_id": source_id,
		"trigger": str(effect.get("trigger", "")),
		"effect_type": effect_type,
		"raw_amount": raw_amount,
		"point_weight": point_weight,
		"score": _round_to(float(raw_amount) * point_weight, 2),
	}

func _opening_effect_is_deterministic(effect: Dictionary) -> bool:
	for key_value in effect.keys():
		var key: String = str(key_value)
		if key.begins_with("requires_") or key in ["min_hp_lost", "min_card_cost", "card_cost_equals", "card_type", "card_id", "every_n_attack_cards"]:
			return false
	var trigger: String = str(effect.get("trigger", ""))
	if trigger == "combat_setup":
		return true
	if trigger == "combat_start":
		return true
	return trigger == "turn_start" and bool(effect.get("first_turn_only", false))

func _opening_exclusion(category: String, source_id: String, effect: Dictionary) -> Dictionary:
	return {
		"category": category,
		"source_id": source_id,
		"trigger": str(effect.get("trigger", "")),
		"effect_type": str(effect.get("type", "")),
		"reason": "conditional_trigger" if not _opening_effect_is_deterministic(effect) else "unsupported_effect",
	}

func _legacy_player_matches_character(legacy_player: Dictionary, character: Dictionary) -> bool:
	for key in ["id", "max_hp", "starting_hp", "max_energy", "starting_momentum", "momentum_max", "starting_gold", "potion_slots"]:
		if legacy_player.get(key) != character.get(key):
			return false
	return legacy_player.get("starter_deck_ids", []) == character.get("starter_deck_ids", []) and legacy_player.get("starter_relic_ids", []) == character.get("starter_relic_ids", [])

func _int_outside_range(value: int, range_value: Array) -> bool:
	return range_value.size() < 2 or value < int(range_value[0]) or value > int(range_value[1])

func _float_outside_range(value: float, range_value: Array) -> bool:
	return range_value.size() < 2 or value < float(range_value[0]) or value > float(range_value[1])

func _score_card(card: Dictionary, upgraded: bool) -> float:
	var source: Dictionary = card
	if upgraded and card.has("upgrade"):
		source = _merged_upgrade_card(card)
	var score := 0.0
	for effect_value in source.get("effects", []):
		var effect: Dictionary = effect_value
		score += _score_effect(source, effect)
	if str(source.get("type", "")) == "power":
		score *= float(numerical_tree_data.get("effect_points", {}).get("power_setup_multiplier", 1.0))
	if bool(source.get("exhaust", false)):
		score *= float(numerical_tree_data.get("effect_points", {}).get("exhaust_multiplier", 1.0))
	return score

func _merged_upgrade_card(card: Dictionary) -> Dictionary:
	var merged: Dictionary = card.duplicate(true)
	var upgrade: Dictionary = card.get("upgrade", {})
	if upgrade.has("cost"):
		merged["cost"] = upgrade.get("cost")
	if upgrade.has("effects"):
		merged["effects"] = upgrade.get("effects", [])
	if upgrade.has("exhaust"):
		merged["exhaust"] = upgrade.get("exhaust")
	return merged

func _score_effect(card: Dictionary, effect: Dictionary) -> float:
	var points: Dictionary = numerical_tree_data.get("effect_points", {})
	var target: String = str(effect.get("target", card.get("target", "enemy")))
	var target_multiplier: float = _target_multiplier(target)
	var condition_multiplier: float = float(points.get("conditional_multiplier", 1.0)) if _effect_is_conditional(effect) else 1.0
	match str(effect.get("type", "")):
		"damage":
			var amount: int = _estimated_damage_amount(effect)
			var hits: int = _estimated_hits(effect)
			var score := float(amount * hits) * float(points.get("damage", 1.0)) * target_multiplier * condition_multiplier
			if effect.has("bonus_if_momentum_at_least"):
				score += float(int(effect.get("bonus", 0)) * hits) * float(points.get("damage", 1.0)) * target_multiplier * float(points.get("conditional_multiplier", 1.0))
			return score
		"block":
			var block_amount: int = int(effect.get("amount", 0))
			if effect.has("bonus"):
				block_amount += int(round(float(effect.get("bonus", 0)) * float(points.get("conditional_multiplier", 1.0))))
			return float(block_amount) * float(points.get("block", 1.0))
		"draw":
			return float(int(effect.get("amount", 0))) * float(points.get("draw", 0.0))
		"gain_energy":
			return float(int(effect.get("amount", 0))) * float(points.get("gain_energy", 0.0))
		"gain_momentum":
			return float(int(effect.get("amount", 0))) * float(points.get("gain_momentum", 0.0))
		"lose_momentum":
			return float(int(effect.get("amount", 0))) * float(points.get("lose_momentum", 0.0))
		"damage_self":
			return float(int(effect.get("amount", 0))) * float(points.get("damage_self", 0.0))
		"create_card":
			return _score_created_card(effect)
		"apply_status":
			return _score_status(effect, target) * condition_multiplier
		_:
			return 0.0

func _estimated_damage_amount(effect: Dictionary) -> int:
	var points: Dictionary = numerical_tree_data.get("effect_points", {})
	var amount: int = int(effect.get("amount", 0))
	amount += int(effect.get("bonus_per_momentum", 0)) * int(points.get("expected_momentum", 0))
	return max(0, amount)

func _estimated_hits(effect: Dictionary) -> int:
	var points: Dictionary = numerical_tree_data.get("effect_points", {})
	var hits: int = max(1, int(effect.get("hits", 1)))
	var extra_hit_per_momentum: int = int(effect.get("extra_hit_per_momentum", 0))
	if extra_hit_per_momentum > 0:
		hits += int(floor(float(points.get("expected_momentum", 0)) / float(extra_hit_per_momentum)))
	return max(1, hits)

func _effect_is_conditional(effect: Dictionary) -> bool:
	return effect.has("requires_momentum_at_least")

func _score_created_card(effect: Dictionary) -> float:
	var points: Dictionary = numerical_tree_data.get("effect_points", {})
	var amount: int = max(1, int(effect.get("amount", 1)))
	var destination: String = str(effect.get("destination", "discard"))
	if str(effect.get("card_id", "")) == "searing_wound":
		var key := "create_searing_wound_hand" if destination == "hand" else "create_searing_wound_discard"
		return float(amount) * float(points.get(key, 0.0))
	return float(amount) * float(points.get("create_other_card", 0.0))

func _score_status(effect: Dictionary, target: String) -> float:
	var points: Dictionary = numerical_tree_data.get("effect_points", {})
	var statuses: Dictionary = points.get("statuses", {})
	var status_id: String = str(effect.get("status", ""))
	var status_target := "self" if target == "self" else "enemy"
	var key := "%s_%s" % [status_id, status_target]
	var fallback := 1.0 if status_target == "enemy" else -1.0
	return float(int(effect.get("amount", 0))) * float(statuses.get(key, fallback)) * _target_multiplier(target)

func _target_multiplier(target: String) -> float:
	return float(numerical_tree_data.get("effect_points", {}).get("target_multipliers", {}).get(target, 1.0))

func _card_budget(card: Dictionary) -> Dictionary:
	var cards_config: Dictionary = numerical_tree_data.get("cards", {})
	var cost_targets: Dictionary = cards_config.get("cost_targets", {})
	var cost_budget: Dictionary = cost_targets.get(str(int(card.get("cost", 0))), {})
	var rarity: String = str(card.get("rarity", "common"))
	var rarity_mod: Dictionary = cards_config.get("rarity_modifiers", {}).get(rarity, {})
	var min_multiplier: float = float(rarity_mod.get("min_multiplier", 1.0))
	var max_multiplier: float = float(rarity_mod.get("max_multiplier", 1.0))
	return {
		"min": float(cost_budget.get("min", 0.0)) * min_multiplier,
		"max": float(cost_budget.get("max", 0.0)) * max_multiplier
	}

func _card_upgrade_budget(card: Dictionary) -> Dictionary:
	var cost_targets: Dictionary = numerical_tree_data.get("cards", {}).get("cost_targets", {})
	var cost_budget: Dictionary = cost_targets.get(str(int(card.get("cost", 0))), {})
	return {
		"min": float(cost_budget.get("upgrade_delta_min", 0.0)),
		"max": float(cost_budget.get("upgrade_delta_max", 999.0))
	}

func _upgrade_cost_saving_score(card: Dictionary) -> float:
	var upgrade: Dictionary = card.get("upgrade", {})
	if upgrade.is_empty() or not upgrade.has("cost"):
		return 0.0
	var base_cost: int = int(card.get("cost", 0))
	var upgrade_cost: int = int(upgrade.get("cost", base_cost))
	var saved_cost: int = max(0, base_cost - upgrade_cost)
	return float(saved_cost) * float(numerical_tree_data.get("effect_points", {}).get("upgrade_cost_saving", 0.0))

func _audit_monsters() -> Array:
	var rows: Array = []
	var enemies_by_id: Dictionary = DataLoaderScript.index_by_id(enemy_data.get("enemies", []))
	var encounters_by_id: Dictionary = DataLoaderScript.index_by_id(encounter_data.get("encounters", []))
	var challenge_modifiers: Dictionary = _challenge_modifiers(0)
	for chapter_id_value in map_generation_data.get("chapter_sequence", []):
		var chapter_id: String = str(chapter_id_value)
		var chapter_config: Dictionary = map_generation_data.get(chapter_id, {})
		var encounter_by_type: Dictionary = chapter_config.get("encounter_by_type", {})
		for node_type_value in encounter_by_type.keys():
			var node_type: String = str(node_type_value)
			var tier := "normal" if node_type == "combat" else node_type
			for encounter_id_value in encounter_by_type.get(node_type, []):
				var encounter_id: String = str(encounter_id_value)
				var encounter: Dictionary = encounters_by_id.get(encounter_id, {})
				if encounter.is_empty():
					continue
				rows.append(_audit_encounter(chapter_id, tier, encounter, enemies_by_id, challenge_modifiers))
	_apply_monster_pressure_hierarchy(rows)
	return rows

func _audit_encounter(chapter_id: String, tier: String, encounter: Dictionary, enemies_by_id: Dictionary, challenge_modifiers: Dictionary) -> Dictionary:
	var total_hp := 0
	var base_enemy_hps: Array = []
	var peak_damage := 0
	var peak_block := 0
	var max_phase_entry_categories := 0
	var phase_entry_category_rows: Array = []
	var base_action_count := 0
	var base_direct_damage_action_count := 0
	var base_longest_zero_direct_damage_actions := 0
	var base_first_three_action_damage_total := 0
	var pressure_profiles: Array = []
	var enemy_ids: Array = encounter.get("enemy_ids", [])
	for enemy_id_value in enemy_ids:
		var enemy: Dictionary = enemies_by_id.get(str(enemy_id_value), {})
		var enemy_hp: int = int(enemy.get("max_hp", 0))
		total_hp += enemy_hp
		base_enemy_hps.append(enemy_hp)
		peak_damage += _peak_enemy_action_damage(enemy)
		peak_block = max(peak_block, _peak_enemy_block(enemy))
		var base_metrics: Dictionary = NumericalPressureMetricsScript.action_cycle_metrics(enemy.get("actions", []))
		base_action_count += int(base_metrics.get("action_count", 0))
		base_direct_damage_action_count += int(base_metrics.get("direct_damage_action_count", 0))
		base_longest_zero_direct_damage_actions = max(base_longest_zero_direct_damage_actions, int(base_metrics.get("longest_zero_direct_damage_actions", 0)))
		base_first_three_action_damage_total += int(base_metrics.get("first_three_action_damage_total", 0))
		for phase_value in enemy.get("phases", []):
			var phase: Dictionary = phase_value
			var categories := _phase_entry_effect_categories(phase.get("on_enter_effects", []))
			max_phase_entry_categories = max(max_phase_entry_categories, categories.size())
			phase_entry_category_rows.append({
				"enemy_id": str(enemy.get("id", "")),
				"phase_id": str(phase.get("id", "")),
				"categories": categories,
			})
			var phase_metrics: Dictionary = NumericalPressureMetricsScript.action_cycle_metrics(phase.get("actions", []))
			phase_metrics["enemy_id"] = str(enemy.get("id", ""))
			phase_metrics["phase_id"] = str(phase.get("id", ""))
			pressure_profiles.append(phase_metrics)
	var budget: Dictionary = numerical_tree_data.get("monsters", {}).get("chapter_targets", {}).get(chapter_id, {}).get(tier, {})
	var encounter_constraints: Dictionary = monster_scaling_data.get("encounter_constraints", {})
	var phase_entry_category_limit := int(encounter_constraints.get("boss_phase_enter_max_effect_categories", 1))
	var phase_transition_mode := str(encounter_constraints.get("boss_phase_transition_mode", ""))
	var hp_range: Array = budget.get("encounter_hp", [0, 9999])
	var damage_range: Array = budget.get("peak_damage", [0, 9999])
	var issues: Array = []
	var pressure_issues: Array = []
	var pressure_targets: Dictionary = numerical_tree_data.get("pressure_contract", {}).get("encounter_structure", {})
	var base_attack_action_ratio := float(base_direct_damage_action_count) / float(max(1, base_action_count))
	var minimum_attack_action_ratio: float = float(pressure_targets.get("minimum_attack_action_ratio", 0.0))
	var maximum_zero_damage_actions: int = int(pressure_targets.get("maximum_zero_direct_damage_actions", 999))
	var first_three_damage_minimum: float = float(damage_range[0]) * float(pressure_targets.get("first_three_damage_to_peak_min_multiplier", 0.0))
	if base_attack_action_ratio < minimum_attack_action_ratio:
		pressure_issues.append("attack_action_ratio_low")
	if base_longest_zero_direct_damage_actions > maximum_zero_damage_actions:
		pressure_issues.append("zero_damage_streak_high")
	if float(base_first_three_action_damage_total) < first_three_damage_minimum:
		pressure_issues.append("first_three_action_damage_low")
	if total_hp < int(hp_range[0]):
		issues.append("encounter_hp_low")
	elif total_hp > int(hp_range[1]):
		issues.append("encounter_hp_high")
	if peak_damage < int(damage_range[0]):
		issues.append("peak_damage_low")
	elif peak_damage > int(damage_range[1]):
		issues.append("peak_damage_high")
	if tier == "boss" and max_phase_entry_categories > phase_entry_category_limit:
		issues.append("boss_phase_entry_categories_high")
	if tier == "boss" and phase_transition_mode != "highest_reached_only":
		issues.append("boss_phase_transition_mode_unknown")
	var enemy_hp_multiplier: float = float(challenge_modifiers.get("enemy_hp_multiplier", 1.0))
	var boss_hp_multiplier: float = float(challenge_modifiers.get("boss_hp_multiplier", 1.0)) if tier == "boss" else 1.0
	var effective_hp: int = NumericalPressureMetricsScript.effective_hp_for_enemies(base_enemy_hps, enemy_hp_multiplier, boss_hp_multiplier)
	return {
		"id": str(encounter.get("id", "")),
		"name": str(encounter.get("name", "")),
		"chapter_id": chapter_id,
		"tier": tier,
		"enemy_count": enemy_ids.size(),
		"total_hp": total_hp,
		"target_hp_min": int(hp_range[0]),
		"target_hp_max": int(hp_range[1]),
		"peak_damage": peak_damage,
		"target_peak_damage_min": int(damage_range[0]),
		"target_peak_damage_max": int(damage_range[1]),
		"peak_block": peak_block,
		"max_phase_entry_effect_categories": max_phase_entry_categories,
		"phase_entry_effect_category_limit": phase_entry_category_limit,
		"phase_transition_mode": phase_transition_mode,
		"phase_entry_categories": phase_entry_category_rows,
		"base_action_count": base_action_count,
		"base_direct_damage_action_count": base_direct_damage_action_count,
		"base_attack_action_ratio": base_attack_action_ratio,
		"base_longest_zero_direct_damage_actions": base_longest_zero_direct_damage_actions,
		"base_first_three_action_damage_total": base_first_three_action_damage_total,
		"pressure_profiles": pressure_profiles,
		"effective_hp_challenge_level": 0,
		"effective_hp": effective_hp,
		"chapter_highest_elite_effective_hp": 0.0,
		"boss_to_highest_elite_ehp_ratio": 0.0,
		"pressure_severity": "warning" if not pressure_issues.is_empty() else "ok",
		"pressure_issues": pressure_issues,
		"severity": "warning" if not issues.is_empty() else "ok",
		"issues": issues
	}

func _challenge_modifiers(level: int) -> Dictionary:
	for level_value in challenge_data.get("levels", []):
		var challenge_level: Dictionary = level_value
		if int(challenge_level.get("level", -1)) == level:
			return (challenge_level.get("modifiers", {}) as Dictionary).duplicate(true)
	return {}

func _apply_monster_pressure_hierarchy(rows: Array) -> void:
	var highest_elite_by_chapter: Dictionary = {}
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("tier", "")) != "elite":
			continue
		var chapter_id: String = str(row.get("chapter_id", ""))
		highest_elite_by_chapter[chapter_id] = max(float(highest_elite_by_chapter.get(chapter_id, 0.0)), float(row.get("effective_hp", 0.0)))
	var minimum_boss_elite_ratio: float = float(numerical_tree_data.get("pressure_contract", {}).get("encounter_structure", {}).get("minimum_boss_to_highest_elite_ehp_ratio", 0.0))
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var highest_elite_ehp: float = float(highest_elite_by_chapter.get(str(row.get("chapter_id", "")), 0.0))
		row["chapter_highest_elite_effective_hp"] = _round_to(highest_elite_ehp, 2)
		if str(row.get("tier", "")) == "boss" and highest_elite_ehp > 0.0:
			var ratio: float = NumericalPressureMetricsScript.safe_ratio(float(row.get("effective_hp", 0.0)), highest_elite_ehp)
			row["boss_to_highest_elite_ehp_ratio"] = _round_to(ratio, 4)
			var pressure_issues: Array = row.get("pressure_issues", [])
			if ratio < minimum_boss_elite_ratio:
				pressure_issues.append("boss_elite_ehp_ratio_low")
			row["pressure_issues"] = pressure_issues
			row["pressure_severity"] = "warning" if not pressure_issues.is_empty() else "ok"
		rows[index] = row

func _phase_entry_effect_categories(effects: Array) -> Array:
	var seen: Dictionary = {}
	for effect_value in effects:
		var effect: Dictionary = effect_value
		var effect_type := str(effect.get("type", ""))
		var category := effect_type
		match effect_type:
			"block":
				category = "block"
			"apply_status":
				category = "strength" if str(effect.get("target", "")) == "self" and str(effect.get("status", "")) == "strength" else "status"
			"create_card":
				category = "status_card"
		if not category.is_empty():
			seen[category] = true
	var categories: Array = seen.keys()
	categories.sort()
	return categories

func _peak_enemy_action_damage(enemy: Dictionary) -> int:
	var peak := 0
	for action_value in enemy.get("actions", []):
		peak = max(peak, _action_damage(action_value))
	for phase_value in enemy.get("phases", []):
		var phase: Dictionary = phase_value
		for action_value in phase.get("actions", []):
			peak = max(peak, _action_damage(action_value))
	return peak

func _peak_enemy_block(enemy: Dictionary) -> int:
	var peak := 0
	for action_value in enemy.get("actions", []):
		peak = max(peak, _action_block(action_value))
	for phase_value in enemy.get("phases", []):
		var phase: Dictionary = phase_value
		for action_value in phase.get("actions", []):
			peak = max(peak, _action_block(action_value))
		for effect_value in phase.get("on_enter_effects", []):
			var effect: Dictionary = effect_value
			if str(effect.get("type", "")) == "block":
				peak = max(peak, int(effect.get("amount", 0)))
	return peak

func _action_damage(action_value: Variant) -> int:
	var action: Dictionary = action_value
	var total := 0
	for effect_value in action.get("effects", []):
		var effect: Dictionary = effect_value
		if str(effect.get("type", "")) == "damage" and str(effect.get("target", "")) == "player":
			total += int(effect.get("amount", 0)) * max(1, int(effect.get("hits", 1)))
	return total

func _action_block(action_value: Variant) -> int:
	var action: Dictionary = action_value
	var total := 0
	for effect_value in action.get("effects", []):
		var effect: Dictionary = effect_value
		if str(effect.get("type", "")) == "block":
			total += int(effect.get("amount", 0))
	return total

func _audit_economy() -> Dictionary:
	var target: Dictionary = numerical_tree_data.get("economy", {})
	var current_shop: Dictionary = economy_data.get("shop", {})
	var current_rewards: Dictionary = economy_data.get("combat_gold_rewards", {})
	var current_treasure: Dictionary = economy_data.get("treasure", {})
	var reward_generation: Dictionary = economy_data.get("reward_generation", {})
	var issues: Array = []
	var potion_reward: Dictionary = economy_data.get("potion_reward", {})
	var actual_drop_chance: int = int(potion_reward.get("drop_chance_percent", 100))
	if int(potion_reward.get("combat_drop_count", 0)) > 0 and actual_drop_chance != int(target.get("potion_drop_chance_percent", 100)):
		issues.append("potion_drop_chance_mismatch")
	if int(current_shop.get("remove_card_price", 0)) != int(target.get("shop_remove_base", 0)):
		issues.append("remove_price_mismatch")
	if int(current_shop.get("remove_card_price_increase", 0)) != int(target.get("shop_remove_increase", 0)):
		issues.append("remove_price_increase_mismatch")
	if not is_equal_approx(float(reward_generation.get("combat_card_accept_score", 0.0)), float(target.get("combat_card_reward_accept_score", 0.0))):
		issues.append("combat_card_accept_score_mismatch")
	if int(reward_generation.get("skip_reward_when_deck_at_least", 0)) != int(target.get("skip_reward_when_deck_at_least", 0)):
		issues.append("skip_reward_deck_size_mismatch")
	var normal_range: Dictionary = current_rewards.get("by_tier", {}).get("normal", {})
	if not _dictionary_matches_range(normal_range, target.get("normal_gold", [])):
		issues.append("normal_gold_range_mismatch")
	var elite_range: Dictionary = current_rewards.get("by_tier", {}).get("elite", {})
	if not _dictionary_matches_range(elite_range, target.get("elite_gold", [])):
		issues.append("elite_gold_range_mismatch")
	var boss_range: Dictionary = current_rewards.get("by_tier", {}).get("boss", {})
	if not _dictionary_matches_range(boss_range, target.get("boss_gold", [])):
		issues.append("boss_gold_range_mismatch")
	var treasure_range := {"min": int(current_treasure.get("gold_min", 0)), "max": int(current_treasure.get("gold_max", 0))}
	if not _dictionary_matches_range(treasure_range, target.get("treasure_gold", [])):
		issues.append("treasure_gold_range_mismatch")
	return {
		"remove_card_price": int(current_shop.get("remove_card_price", 0)),
		"remove_card_price_target": int(target.get("shop_remove_base", 0)),
		"remove_card_price_increase": int(current_shop.get("remove_card_price_increase", 0)),
		"remove_card_price_increase_target": int(target.get("shop_remove_increase", 0)),
		"potion_drop_count": int(potion_reward.get("combat_drop_count", 0)),
		"potion_drop_chance_percent": actual_drop_chance,
		"potion_drop_chance_target": int(target.get("potion_drop_chance_percent", 100)),
		"combat_card_accept_score": float(reward_generation.get("combat_card_accept_score", 0.0)),
		"combat_card_accept_score_target": float(target.get("combat_card_reward_accept_score", 0.0)),
		"skip_reward_when_deck_at_least": int(reward_generation.get("skip_reward_when_deck_at_least", 0)),
		"skip_reward_when_deck_at_least_target": int(target.get("skip_reward_when_deck_at_least", 0)),
		"normal_gold": [int(normal_range.get("min", 0)), int(normal_range.get("max", 0))],
		"elite_gold": [int(elite_range.get("min", 0)), int(elite_range.get("max", 0))],
		"boss_gold": [int(boss_range.get("min", 0)), int(boss_range.get("max", 0))],
		"treasure_gold": [int(current_treasure.get("gold_min", 0)), int(current_treasure.get("gold_max", 0))],
		"expected_final_gold_range": target.get("expected_final_gold_range", []),
		"expected_final_deck_size_range": target.get("expected_final_deck_size_range", []),
		"severity": "warning" if not issues.is_empty() else "ok",
		"issues": issues
	}

func _dictionary_matches_range(actual: Dictionary, expected: Array) -> bool:
	return expected.size() >= 2 and int(actual.get("min", -1)) == int(expected[0]) and int(actual.get("max", -1)) == int(expected[1])

func _audit_progression() -> Dictionary:
	var target: Dictionary = numerical_tree_data.get("progression", {})
	var currency: Dictionary = progression_data.get("currency", {})
	var full_run_marks: int = int(currency.get("boss_reward", 0)) * map_generation_data.get("chapter_sequence", []).size() + int(currency.get("full_run_bonus", 0))
	var tree_rows: Array = []
	var issues: Array = []
	var node_count_range: Array = target.get("character_tree_node_count_range", [0, 999])
	var total_cost_range: Array = target.get("character_tree_total_cost_range", [0, 999])
	var full_run_range: Array = target.get("full_run_unlock_count_range", [0.0, 999.0])
	var allowed_effects: Array = target.get("allowed_effects", [])
	if int(currency.get("boss_reward", 0)) != int(target.get("boss_reward", 0)):
		issues.append("boss_reward_mismatch")
	if int(currency.get("full_run_bonus", 0)) != int(target.get("full_run_bonus", 0)):
		issues.append("full_run_bonus_mismatch")
	for tree_value in progression_data.get("character_trees", []):
		var tree: Dictionary = tree_value
		var nodes: Array = tree.get("nodes", [])
		var total_cost := 0
		var node_order: Dictionary = {}
		for node_index in range(nodes.size()):
			var node_value: Variant = nodes[node_index]
			var node: Dictionary = node_value
			node_order[str(node.get("id", ""))] = node_index
			total_cost += int(node.get("cost", 0))
		var unlock_runs := float(total_cost) / float(max(1, full_run_marks))
		var tree_issues: Array = []
		if nodes.size() < int(node_count_range[0]) or nodes.size() > int(node_count_range[1]):
			tree_issues.append("node_count_out_of_range")
		if total_cost < int(total_cost_range[0]) or total_cost > int(total_cost_range[1]):
			tree_issues.append("total_cost_out_of_range")
		if unlock_runs < float(full_run_range[0]) or unlock_runs > float(full_run_range[1]):
			tree_issues.append("unlock_runs_out_of_range")
		for node_index in range(nodes.size()):
			var node: Dictionary = nodes[node_index]
			for effect_value in node.get("effects", []):
				var effect: Dictionary = effect_value
				if not allowed_effects.has(str(effect.get("type", ""))):
					tree_issues.append("unsupported_effect:%s" % str(node.get("id", "")))
			for prerequisite_value in node.get("prerequisites", []):
				var prerequisite_id: String = str(prerequisite_value)
				if not node_order.has(prerequisite_id):
					tree_issues.append("missing_prerequisite:%s" % prerequisite_id)
				elif int(node_order.get(prerequisite_id, 999)) >= node_index:
					tree_issues.append("prerequisite_not_earlier:%s" % prerequisite_id)
		if not tree_issues.is_empty():
			issues.append("%s:%s" % [str(tree.get("character_id", "")), ",".join(PackedStringArray(tree_issues))])
		tree_rows.append({
			"character_id": str(tree.get("character_id", "")),
			"node_count": nodes.size(),
			"total_cost": total_cost,
			"full_run_marks": full_run_marks,
			"estimated_full_runs_to_unlock": _round_to(unlock_runs, 2),
			"issues": tree_issues
		})
	return {
		"boss_reward": int(currency.get("boss_reward", 0)),
		"full_run_bonus": int(currency.get("full_run_bonus", 0)),
		"full_run_marks": full_run_marks,
		"trees": tree_rows,
		"severity": "warning" if not issues.is_empty() else "ok",
		"issues": issues
	}

func _build_summary(card_rows: Array, player_rows: Array, monster_rows: Array, economy_report: Dictionary, progression_report: Dictionary) -> Dictionary:
	var card_warnings := 0
	var card_advisories := 0
	var card_issue_rows := 0
	var player_warnings := 0
	var opening_package_warnings := 0
	var monster_warnings := 0
	var monster_pressure_warnings := 0
	for row_value in card_rows:
		var row: Dictionary = row_value
		if not (row.get("issues", []) as Array).is_empty():
			card_issue_rows += 1
		if str(row.get("severity", "ok")) == "warning":
			card_warnings += 1
		elif str(row.get("severity", "ok")) == "advisory":
			card_advisories += 1
	for row_value in player_rows:
		var row: Dictionary = row_value
		if str(row.get("severity", "ok")) != "ok":
			player_warnings += 1
		if str(row.get("opening_package_severity", "ok")) != "ok":
			opening_package_warnings += 1
	for row_value in monster_rows:
		var row: Dictionary = row_value
		if str(row.get("severity", "ok")) != "ok":
			monster_warnings += 1
		if str(row.get("pressure_severity", "ok")) != "ok":
			monster_pressure_warnings += 1
	return {
		"card_count": card_rows.size(),
		"card_issue_row_count": card_issue_rows,
		"card_advisory_count": card_advisories,
		"card_warning_count": card_warnings,
		"player_count": player_rows.size(),
		"player_warning_count": player_warnings,
		"opening_package_warning_count": opening_package_warnings,
		"monster_encounter_count": monster_rows.size(),
		"monster_warning_count": monster_warnings,
		"monster_pressure_warning_count": monster_pressure_warnings,
		"economy_warning_count": (economy_report.get("issues", []) as Array).size(),
		"progression_warning_count": (progression_report.get("issues", []) as Array).size(),
		"total_advisory_count": card_advisories,
		"total_warning_count": card_warnings + player_warnings + monster_warnings + (economy_report.get("issues", []) as Array).size() + (progression_report.get("issues", []) as Array).size()
	}

func _round_to(value: float, decimals: int) -> float:
	var scale: float = pow(10.0, float(decimals))
	return round(value * scale) / scale
