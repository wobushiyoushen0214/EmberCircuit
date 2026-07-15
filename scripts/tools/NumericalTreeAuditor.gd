class_name NumericalTreeAuditor
extends RefCounted

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

var card_data: Dictionary = {}
var enemy_data: Dictionary = {}
var encounter_data: Dictionary = {}
var player_data: Dictionary = {}
var economy_data: Dictionary = {}
var map_generation_data: Dictionary = {}
var level_tree_data: Dictionary = {}
var progression_data: Dictionary = {}
var numerical_tree_data: Dictionary = {}

func load_default_data() -> void:
	card_data = DataLoaderScript.load_json("res://data/cards/cards.json")
	enemy_data = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	encounter_data = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	player_data = DataLoaderScript.load_json("res://data/config/player.json")
	economy_data = DataLoaderScript.load_json("res://data/config/economy.json")
	map_generation_data = DataLoaderScript.load_json("res://data/config/map_generation.json")
	level_tree_data = DataLoaderScript.load_json("res://data/config/level_tree.json")
	progression_data = DataLoaderScript.load_json("res://data/config/progression_systems.json")
	numerical_tree_data = DataLoaderScript.load_json("res://data/config/numerical_tree.json")

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
	var player_targets: Dictionary = numerical_tree_data.get("players", {})
	var starter_targets: Dictionary = numerical_tree_data.get("cards", {}).get("starter_deck", {})
	var character_targets: Dictionary = player_targets.get("character_targets", {})
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
			"missing_card_ids": missing_card_ids,
			"severity": "warning" if not issues.is_empty() else "ok",
			"issues": issues
		})
	return rows

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
				rows.append(_audit_encounter(chapter_id, tier, encounter, enemies_by_id))
	return rows

func _audit_encounter(chapter_id: String, tier: String, encounter: Dictionary, enemies_by_id: Dictionary) -> Dictionary:
	var total_hp := 0
	var peak_damage := 0
	var peak_block := 0
	var enemy_ids: Array = encounter.get("enemy_ids", [])
	for enemy_id_value in enemy_ids:
		var enemy: Dictionary = enemies_by_id.get(str(enemy_id_value), {})
		total_hp += int(enemy.get("max_hp", 0))
		peak_damage += _peak_enemy_action_damage(enemy)
		peak_block = max(peak_block, _peak_enemy_block(enemy))
	var budget: Dictionary = numerical_tree_data.get("monsters", {}).get("chapter_targets", {}).get(chapter_id, {}).get(tier, {})
	var hp_range: Array = budget.get("encounter_hp", [0, 9999])
	var damage_range: Array = budget.get("peak_damage", [0, 9999])
	var issues: Array = []
	if total_hp < int(hp_range[0]):
		issues.append("encounter_hp_low")
	elif total_hp > int(hp_range[1]):
		issues.append("encounter_hp_high")
	if peak_damage < int(damage_range[0]):
		issues.append("peak_damage_low")
	elif peak_damage > int(damage_range[1]):
		issues.append("peak_damage_high")
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
		"severity": "warning" if not issues.is_empty() else "ok",
		"issues": issues
	}

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
	var monster_warnings := 0
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
	for row_value in monster_rows:
		var row: Dictionary = row_value
		if str(row.get("severity", "ok")) != "ok":
			monster_warnings += 1
	return {
		"card_count": card_rows.size(),
		"card_issue_row_count": card_issue_rows,
		"card_advisory_count": card_advisories,
		"card_warning_count": card_warnings,
		"player_count": player_rows.size(),
		"player_warning_count": player_warnings,
		"monster_encounter_count": monster_rows.size(),
		"monster_warning_count": monster_warnings,
		"economy_warning_count": (economy_report.get("issues", []) as Array).size(),
		"progression_warning_count": (progression_report.get("issues", []) as Array).size(),
		"total_advisory_count": card_advisories,
		"total_warning_count": card_warnings + player_warnings + monster_warnings + (economy_report.get("issues", []) as Array).size() + (progression_report.get("issues", []) as Array).size()
	}

func _round_to(value: float, decimals: int) -> float:
	var scale: float = pow(10.0, float(decimals))
	return round(value * scale) / scale
