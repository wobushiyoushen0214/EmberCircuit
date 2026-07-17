class_name BalanceSimulator
extends RefCounted

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const NumericalPressureMetricsScript = preload("res://scripts/tools/NumericalPressureMetrics.gd")

const DEFAULT_MAX_TURNS := 60
const DEFAULT_ITERATIONS := 8
const DEFAULT_CAMPAIGN_ITERATIONS := 4

var card_data: Dictionary = {}
var enemy_data: Dictionary = {}
var relic_data: Dictionary = {}
var potion_data: Dictionary = {}
var encounter_data: Dictionary = {}
var event_data: Dictionary = {}
var player_data: Dictionary = {}
var challenge_data: Dictionary = {}
var economy_data: Dictionary = {}
var map_generation_data: Dictionary = {}
var level_tree_data: Dictionary = {}
var progression_data: Dictionary = {}
var numerical_tree_data: Dictionary = {}

func load_default_data() -> void:
	card_data = DataLoaderScript.load_json("res://data/cards/cards.json")
	enemy_data = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	relic_data = DataLoaderScript.load_json("res://data/relics/relics.json")
	potion_data = DataLoaderScript.load_json("res://data/potions/potions.json")
	encounter_data = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	event_data = DataLoaderScript.load_json("res://data/events/events.json")
	player_data = DataLoaderScript.load_json("res://data/config/player.json")
	challenge_data = DataLoaderScript.load_json("res://data/config/challenges.json")
	economy_data = DataLoaderScript.load_json("res://data/config/economy.json")
	map_generation_data = DataLoaderScript.load_json("res://data/config/map_generation.json")
	level_tree_data = DataLoaderScript.load_json("res://data/config/level_tree.json")
	progression_data = DataLoaderScript.load_json("res://data/config/progression_systems.json")
	numerical_tree_data = DataLoaderScript.load_json("res://data/config/numerical_tree.json")

func run_suite(options: Dictionary = {}) -> Dictionary:
	if card_data.is_empty():
		load_default_data()

	var iterations: int = max(1, int(options.get("iterations", DEFAULT_ITERATIONS)))
	var max_turns: int = max(1, int(options.get("max_turns", DEFAULT_MAX_TURNS)))
	var character_ids: Array = _option_or_default(options, "character_ids", _all_character_ids())
	var challenge_levels: Array = _option_or_default(options, "challenge_levels", _all_challenge_levels())
	var encounter_ids: Array = _option_or_default(options, "encounter_ids", _all_encounter_ids())

	var report := {
		"version": 1,
		"simulation_model": "single_encounter_heuristic_ai",
		"strategy_profile": "current-greedy",
		"iterations_per_case": iterations,
		"max_turns": max_turns,
		"case_count": character_ids.size() * challenge_levels.size() * encounter_ids.size(),
		"cases": []
	}

	for character_id_value in character_ids:
		var character_id: String = str(character_id_value)
		for challenge_level_value in challenge_levels:
			var challenge_level: int = int(challenge_level_value)
			for encounter_id_value in encounter_ids:
				var encounter_id: String = str(encounter_id_value)
				report["cases"].append(_run_case(character_id, challenge_level, encounter_id, iterations, max_turns))

	report["summary"] = _build_report_summary(report["cases"])
	return report

func run_campaign_suite(options: Dictionary = {}) -> Dictionary:
	if card_data.is_empty():
		load_default_data()

	var iterations: int = max(1, int(options.get("iterations", DEFAULT_CAMPAIGN_ITERATIONS)))
	var max_turns: int = max(1, int(options.get("max_turns", DEFAULT_MAX_TURNS)))
	var character_ids: Array = _option_or_default(options, "character_ids", _all_character_ids())
	var challenge_levels: Array = _option_or_default(options, "challenge_levels", _all_challenge_levels())

	var report := {
		"version": 1,
		"simulation_model": "campaign_route_heuristic_ai",
		"strategy_profile": "current-greedy",
		"seed_model": "paired_by_iteration",
		"iterations_per_case": iterations,
		"max_turns_per_combat": max_turns,
		"case_count": character_ids.size() * challenge_levels.size(),
		"cases": []
	}

	for character_id_value in character_ids:
		var character_id: String = str(character_id_value)
		for challenge_level_value in challenge_levels:
			var challenge_level: int = int(challenge_level_value)
			report["cases"].append(_run_campaign_case(character_id, challenge_level, iterations, max_turns))

	report["summary"] = _build_campaign_report_summary(report["cases"])
	return report

func _run_case(character_id: String, challenge_level: int, encounter_id: String, iterations: int, max_turns: int) -> Dictionary:
	var character: Dictionary = _character_config(character_id)
	var challenge: Dictionary = _challenge_config(challenge_level)
	var encounter: Dictionary = _encounter_config(encounter_id)
	var runs: Array = []
	for iteration in range(iterations):
		var seed_text: String = "%s|%d|%s|%d" % [character_id, challenge_level, encounter_id, iteration]
		runs.append(_run_single_combat(character_id, challenge_level, encounter_id, max_turns, _stable_text_seed(seed_text)))

	return _aggregate_case(character, challenge, encounter, runs)

func _run_campaign_case(character_id: String, challenge_level: int, iterations: int, max_turns: int) -> Dictionary:
	var character: Dictionary = _character_config(character_id)
	var challenge: Dictionary = _challenge_config(challenge_level)
	var runs: Array = []
	for iteration in range(iterations):
		var seed_text: String = "campaign|%d" % iteration
		runs.append(_run_campaign_once(character_id, challenge_level, max_turns, _stable_text_seed(seed_text)))
	return _aggregate_campaign_case(character, challenge, runs)

func _run_campaign_once(character_id: String, challenge_level: int, max_turns: int, seed_value: int) -> Dictionary:
	seed(seed_value)
	var character: Dictionary = _character_config(character_id)
	var challenge: Dictionary = _challenge_config(challenge_level)
	var modifiers: Dictionary = challenge.get("modifiers", {})
	var state := {
		"character_id": character_id,
		"challenge_level": challenge_level,
		"hp": _starting_hp_for_character(character_id, modifiers),
		"max_hp": int(character.get("max_hp", 72)),
		"gold": int(character.get("starting_gold", 0)),
		"deck_ids": character.get("starter_deck_ids", []).duplicate(true),
		"relic_ids": character.get("starter_relic_ids", []).duplicate(true),
		"potion_ids": [],
		"skill_book_id": "steel_manual",
		"deck_mastery_id": "",
		"remove_count": 0,
		"completed_event_ids": {},
		"chapters_completed": 0,
		"nodes_completed": 0,
		"combats_won": 0,
		"elites_won": 0,
		"bosses_won": 0,
		"events_seen": 0,
		"shops_seen": 0,
		"campfires_seen": 0,
		"treasures_seen": 0,
		"events_choice_ids": [],
		"cards_added": 0,
		"cards_removed": 0,
		"cards_upgraded": 0,
		"relics_added": 0,
		"potions_gained": 0,
		"potions_used": 0,
		"cards_added_ids": [],
		"cards_removed_ids": [],
		"cards_upgraded_ids": [],
		"card_offer_counts_by_id": {},
		"card_acquisition_counts_by_id": {},
		"card_acquisition_sources_by_id": {},
		"card_removal_counts_by_id": {},
		"card_upgrade_counts_by_id": {},
		"card_play_counts_by_id": {},
		"relics_added_ids": [],
		"potions_gained_ids": [],
		"potions_used_ids": [],
		"turns": 0,
		"cards_played": 0,
		"path": [],
		"failed_at": "",
		"failed_reason": "",
		"failed_node_type": "",
		"failed_encounter_id": ""
	}

	var chapter_ids: Array = _chapter_sequence()
	for chapter_index in range(chapter_ids.size()):
		var chapter_id: String = str(chapter_ids[chapter_index])
		var graph: Dictionary = _generate_chapter_graph(chapter_id, seed_value, character_id, state)
		var node_id: String = str(graph.get("start_node_id", ""))
		var chapter_finished := false
		while not node_id.is_empty():
			var node: Dictionary = _graph_node_by_id(graph, node_id)
			if node.is_empty():
				state["failed_at"] = "%s:%s" % [chapter_id, node_id]
				state["failed_reason"] = "missing_node"
				return _campaign_result(false, state)
			var node_result: Dictionary = _resolve_campaign_node(state, node, chapter_id, max_turns, seed_value)
			_append_path_entry(state, chapter_id, node, node_result)
			if not bool(node_result.get("completed", false)):
				state["failed_at"] = "%s:%s" % [chapter_id, node.get("id", "")]
				state["failed_reason"] = str(node_result.get("reason", "node_failed"))
				state["failed_node_type"] = str(node.get("type", ""))
				state["failed_encounter_id"] = str(node_result.get("encounter_id", ""))
				return _campaign_result(false, state)
			state["nodes_completed"] = int(state.get("nodes_completed", 0)) + 1
			if str(node.get("type", "")) == "boss":
				chapter_finished = true
				break
			var candidates: Array = _successor_nodes(graph, node_id)
			if candidates.is_empty():
				break
			node_id = _choose_next_campaign_node(state, candidates, graph)
		if not chapter_finished:
			state["failed_at"] = chapter_id
			state["failed_reason"] = "chapter_route_incomplete"
			return _campaign_result(false, state)
		state["chapters_completed"] = int(state.get("chapters_completed", 0)) + 1
		if chapter_index < chapter_ids.size() - 1:
			_apply_campaign_chapter_transition_recovery(state)

	return _campaign_result(true, state)

func _apply_campaign_chapter_transition_recovery(state: Dictionary) -> void:
	state["hp"] = int(state.get("max_hp", state.get("hp", 1)))

func _resolve_campaign_node(state: Dictionary, node: Dictionary, chapter_id: String, max_turns: int, seed_value: int) -> Dictionary:
	var node_type: String = str(node.get("type", ""))
	match node_type:
		"combat", "elite", "boss":
			return _resolve_campaign_combat(state, node, chapter_id, max_turns, seed_value)
		"event":
			_simulate_campaign_event(state, node, chapter_id, seed_value)
		"shop":
			_simulate_campaign_shop(state, chapter_id, seed_value)
		"campfire":
			_simulate_campaign_campfire(state)
		"treasure":
			_simulate_campaign_treasure(state, chapter_id, seed_value)
		_:
			return {"completed": false, "reason": "unknown_node_type"}
	return {"completed": true, "reason": "ok"}

func _resolve_campaign_combat(state: Dictionary, node: Dictionary, chapter_id: String, max_turns: int, seed_value: int) -> Dictionary:
	var encounter_id: String = str(node.get("encounter_id", ""))
	if encounter_id.is_empty():
		return {"completed": false, "reason": "missing_encounter"}
	var potion_ids: Array = state.get("potion_ids", [])
	var potions_before: int = potion_ids.size()
	var combat_result: Dictionary = _run_single_combat_with_loadout(
		str(state.get("character_id", "")),
		int(state.get("challenge_level", 0)),
		encounter_id,
		max_turns,
		_stable_text_seed("%s|%s|%s|%d|%d" % [chapter_id, str(node.get("id", "")), encounter_id, int(state.get("nodes_completed", 0)), seed_value]),
		state.get("deck_ids", []),
		state.get("relic_ids", []),
		int(state.get("hp", 1)),
		potion_ids,
		_campaign_modifier_sources(state)
	)
	var used_potion_ids: Array = combat_result.get("potions_used_ids", [])
	state["potion_ids"] = combat_result.get("potions_remaining", potion_ids)
	state["potions_used"] = int(state.get("potions_used", 0)) + max(0, potions_before - (state.get("potion_ids", []) as Array).size())
	var campaign_used_potion_ids: Array = state.get("potions_used_ids", [])
	campaign_used_potion_ids.append_array(used_potion_ids)
	state["potions_used_ids"] = campaign_used_potion_ids
	state["turns"] = int(state.get("turns", 0)) + int(combat_result.get("turns", 0))
	state["cards_played"] = int(state.get("cards_played", 0)) + int(combat_result.get("cards_played", 0))
	_merge_count_dictionary(state, "card_play_counts_by_id", combat_result.get("card_play_counts_by_id", {}))
	if not bool(combat_result.get("won", false)):
		state["hp"] = int(combat_result.get("player_hp_remaining", state.get("hp", 0)))
		return {"completed": false, "reason": str(combat_result.get("phase", "combat_failed")), "encounter_id": encounter_id}

	state["hp"] = int(combat_result.get("player_hp_remaining", state.get("hp", 1)))
	state["combats_won"] = int(state.get("combats_won", 0)) + 1
	if str(node.get("type", "")) == "elite":
		state["elites_won"] = int(state.get("elites_won", 0)) + 1
	if str(node.get("type", "")) == "boss":
		state["bosses_won"] = int(state.get("bosses_won", 0)) + 1

	var encounter: Dictionary = _encounter_config(encounter_id)
	state["gold"] = int(state.get("gold", 0)) + _campaign_encounter_gold_reward(encounter, chapter_id, reward_seed_text(state, node, encounter_id, seed_value))
	var reward_seed: String = "campaign_reward|%s|%s|%s|%d|%d" % [
		chapter_id,
		str(node.get("id", "")),
		encounter_id,
		seed_value,
		int(state.get("nodes_completed", 0))
	]
	var card_reward_count: int = max(0, int(encounter.get("card_reward_count", 0)))
	_offer_card_reward(state, card_reward_count, "%s|card" % reward_seed)
	if bool(encounter.get("relic_reward", false)):
		_offer_relic_reward(state, "%s|relic" % reward_seed)
	if _campaign_encounter_allows_potion_reward(encounter) and _has_empty_potion_slot(state):
		_offer_potion_reward(state, "%s|potion" % reward_seed)
	if str(node.get("type", "")) == "elite" and str(state.get("deck_mastery_id", "")).is_empty():
		state["deck_mastery_id"] = _choose_campaign_deck_mastery(state.get("deck_ids", []))

	return {"completed": true, "reason": "ok", "encounter_id": encounter_id}

func reward_seed_text(state: Dictionary, node: Dictionary, encounter_id: String, seed_value: int) -> String:
	return "%s|%s|%d|%d" % [
		str(node.get("id", "")),
		encounter_id,
		seed_value,
		int(state.get("nodes_completed", 0))
	]

func _campaign_encounter_gold_reward(encounter: Dictionary, chapter_id: String, reward_key: String) -> int:
	if encounter.is_empty() or _encounter_skips_economy_rewards(encounter):
		return 0
	var tier: String = str(encounter.get("tier", "normal"))
	var by_tier: Dictionary = economy_data.get("combat_gold_rewards", {}).get("by_tier", {})
	if not by_tier.has(tier):
		return max(0, int(encounter.get("gold_reward", 0)))
	var tier_range: Dictionary = by_tier.get(tier, {})
	var min_gold: int = int(tier_range.get("min", encounter.get("gold_reward", 0)))
	var max_gold: int = int(tier_range.get("max", min_gold))
	if max_gold < min_gold:
		max_gold = min_gold
	var span: int = max_gold - min_gold + 1
	var chapter_bonus: int = int(economy_data.get("combat_gold_rewards", {}).get("chapter_bonus", {}).get(chapter_id, 0))
	return max(0, min_gold + _deterministic_index("campaign_gold|%s|%s|%s" % [chapter_id, reward_key, tier], span) + chapter_bonus)

func _encounter_skips_economy_rewards(encounter: Dictionary) -> bool:
	return int(encounter.get("card_reward_count", 3)) <= 0 and not bool(encounter.get("relic_reward", false)) and int(encounter.get("gold_reward", 0)) <= 0

func _campaign_encounter_allows_potion_reward(encounter: Dictionary) -> bool:
	return int(encounter.get("card_reward_count", 0)) > 0

func _simulate_campaign_event(state: Dictionary, node: Dictionary, chapter_id: String, seed_value: int) -> void:
	state["events_seen"] = int(state.get("events_seen", 0)) + 1
	var event_id: String = str(node.get("event_id", ""))
	if event_id.is_empty():
		var event_pool: Array = _filtered_event_pool_for_character(
			map_generation_data.get(chapter_id, {}).get("event_pool", []),
			str(state.get("character_id", "")),
			state
		)
		if not event_pool.is_empty():
			var event_index: int = _deterministic_index("event_fallback|%s|%d|%d" % [chapter_id, seed_value, int(state.get("nodes_completed", 0))], event_pool.size())
			event_id = str(event_pool[event_index])
	var event: Dictionary = _event_by_id(event_id)
	if event.is_empty():
		_simulate_fallback_campaign_event(state, chapter_id, seed_value)
		return

	var best_choice: Dictionary = {}
	var best_effects: Array = []
	var best_score := -999999.0
	for choice in event.get("choices", []):
		var choice_dict: Dictionary = choice
		if not _event_choice_available(state, choice_dict):
			continue
		var effects: Array = _resolve_campaign_event_choice_effects(choice_dict, event_id, state, seed_value)
		var score: float = _event_choice_score(state, effects)
		if score > best_score:
			best_score = score
			best_choice = choice_dict
			best_effects = effects
	if best_choice.is_empty():
		_simulate_fallback_campaign_event(state, chapter_id, seed_value)
		return

	var choice_ids: Array = state.get("events_choice_ids", [])
	choice_ids.append("%s:%s" % [event_id, str(best_choice.get("id", ""))])
	state["events_choice_ids"] = choice_ids
	for effect in best_effects:
		var effect_dict: Dictionary = effect
		_apply_campaign_event_effect(state, effect_dict)
	if bool(event.get("one_time", false)):
		var completed: Dictionary = state.get("completed_event_ids", {})
		completed[event_id] = true
		state["completed_event_ids"] = completed

func _simulate_fallback_campaign_event(state: Dictionary, chapter_id: String, seed_value: int) -> void:
	var roll: int = _deterministic_index("event|%s|%d|%d" % [chapter_id, seed_value, int(state.get("nodes_completed", 0))], 100)
	var hp: int = int(state.get("hp", 0))
	var max_hp: int = int(state.get("max_hp", 1))
	if hp < int(ceil(float(max_hp) * 0.50)):
		state["hp"] = min(max_hp, hp + 10)
	elif roll < 45:
		state["gold"] = int(state.get("gold", 0)) + 22
	elif roll < 75:
		_offer_card_reward(state, 2, "campaign_event_card|%s|%d" % [chapter_id, seed_value])
	else:
		_offer_potion_reward(state, "campaign_event_potion|%s|%d" % [chapter_id, seed_value])

func _simulate_campaign_treasure(state: Dictionary, chapter_id: String, seed_value: int) -> void:
	state["treasures_seen"] = int(state.get("treasures_seen", 0)) + 1
	var treasure_config: Dictionary = economy_data.get("treasure", {})
	var gold_min: int = max(0, int(treasure_config.get("gold_min", 0)))
	var gold_max: int = max(gold_min, int(treasure_config.get("gold_max", gold_min)))
	var range_size: int = gold_max - gold_min + 1
	var gold_reward: int = gold_min + _deterministic_index("treasure_gold|%s|%d|%d" % [chapter_id, seed_value, int(state.get("nodes_completed", 0))], range_size)
	state["gold"] = int(state.get("gold", 0)) + gold_reward
	_offer_relic_reward(state, "campaign_treasure_relic|%s|%d|%d" % [chapter_id, seed_value, int(state.get("nodes_completed", 0))])

func _event_by_id(event_id: String) -> Dictionary:
	for event in event_data.get("events", []):
		var event_dict: Dictionary = event
		if str(event_dict.get("id", "")) == event_id:
			return event_dict
	return {}

func _event_choice_available(state: Dictionary, choice: Dictionary) -> bool:
	for condition in choice.get("conditions", []):
		var condition_dict: Dictionary = condition
		if _event_condition_failed(state, condition_dict):
			return false
	return true

func _event_condition_failed(state: Dictionary, condition: Dictionary) -> bool:
	match str(condition.get("type", "")):
		"min_gold":
			return int(state.get("gold", 0)) < int(condition.get("amount", 0))
		"min_hp":
			return int(state.get("hp", 0)) < int(condition.get("amount", 1))
		"has_empty_potion_slot":
			return not _has_empty_potion_slot(state)
		"has_removable_card":
			return _first_non_starter_card_index(state.get("deck_ids", [])) < 0
		"missing_relic":
			var missing_relic_id: String = str(condition.get("relic_id", ""))
			return not missing_relic_id.is_empty() and (state.get("relic_ids", []) as Array).has(missing_relic_id)
		"has_relic":
			return not (state.get("relic_ids", []) as Array).has(str(condition.get("relic_id", "")))
		"deck_contains_card":
			return not _deck_contains_card(state.get("deck_ids", []), str(condition.get("card_id", "")))
		"event_not_completed":
			return (state.get("completed_event_ids", {}) as Dictionary).has(str(condition.get("event_id", "")))
		"event_completed":
			return not bool((state.get("completed_event_ids", {}) as Dictionary).get(str(condition.get("event_id", "")), false))
		_:
			return false

func _resolve_campaign_event_choice_effects(choice: Dictionary, event_id: String, state: Dictionary, seed_value: int) -> Array:
	var random_results: Array = choice.get("random_results", [])
	if random_results.is_empty():
		return choice.get("effects", [])
	var selected: Dictionary = _select_weighted_campaign_event_result(
		random_results,
		"%s|%s|%s|%d|%d|%d" % [
			event_id,
			str(choice.get("id", "")),
			str(choice.get("random_seed", "run")),
			seed_value,
			int(state.get("nodes_completed", 0)),
			int(state.get("gold", 0))
		]
	)
	return selected.get("effects", [])

func _select_weighted_campaign_event_result(results: Array, seed_text: String) -> Dictionary:
	var total_weight := 0
	for result in results:
		var result_dict: Dictionary = result
		total_weight += max(0, int(result_dict.get("weight", 1)))
	if total_weight <= 0:
		return results[0] if not results.is_empty() else {}
	var roll: int = _deterministic_index(seed_text, total_weight)
	var cursor := 0
	for result in results:
		var result_dict: Dictionary = result
		cursor += max(0, int(result_dict.get("weight", 1)))
		if roll < cursor:
			return result_dict
	return results[0] if not results.is_empty() else {}

func _event_choice_score(state: Dictionary, effects: Array) -> float:
	var score := 0.0
	for effect in effects:
		var effect_dict: Dictionary = effect
		score += _event_effect_score(state, effect_dict)
	return score

func _event_effect_score(state: Dictionary, effect: Dictionary) -> float:
	var hp: int = int(state.get("hp", 0))
	var max_hp: int = int(state.get("max_hp", 1))
	var missing_hp: int = max(0, max_hp - hp)
	match str(effect.get("type", "")):
		"gain_gold":
			return float(int(effect.get("amount", 0))) * 0.10
		"lose_gold":
			return -float(int(effect.get("amount", 0))) * 0.10
		"lose_hp":
			var amount: int = int(effect.get("amount", 0))
			var low_hp_multiplier := 2.1 if hp <= int(ceil(float(max_hp) * 0.45)) else 1.25
			return -float(amount) * low_hp_multiplier
		"heal_percent":
			var heal: int = max(1, int(ceil(float(max_hp) * float(int(effect.get("amount", 0))) / 100.0)))
			return float(min(missing_hp, heal)) * 1.6
		"add_card":
			var card: Dictionary = _card_by_id(str(effect.get("card_id", "")))
			return _card_reward_score(card, str(state.get("character_id", ""))) if not card.is_empty() else 0.0
		"gain_relic":
			var relic: Dictionary = _relic_by_id(str(effect.get("relic_id", "")))
			if relic.is_empty() or (state.get("relic_ids", []) as Array).has(str(relic.get("id", ""))):
				return 0.0
			return _relic_score(relic)
		"gain_potion":
			var potion: Dictionary = _potion_config(str(effect.get("potion_id", "")))
			if potion.is_empty() or not _has_empty_potion_slot(state):
				return 0.0
			return _potion_score(potion) * 0.35
		"remove_first_non_starter_card":
			return _remove_non_starter_card_effect_score(state)
		"complete_event":
			return 7.0
		_:
			return 0.0

func _apply_campaign_event_effect(state: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("type", "")):
		"gain_gold":
			state["gold"] = int(state.get("gold", 0)) + int(effect.get("amount", 0))
		"lose_gold":
			state["gold"] = max(0, int(state.get("gold", 0)) - int(effect.get("amount", 0)))
		"lose_hp":
			state["hp"] = max(1, int(state.get("hp", 1)) - int(effect.get("amount", 0)))
		"heal_percent":
			var max_hp: int = int(state.get("max_hp", 1))
			var heal: int = max(1, int(ceil(float(max_hp) * float(int(effect.get("amount", 0))) / 100.0)))
			state["hp"] = min(max_hp, int(state.get("hp", 0)) + heal)
		"add_card":
			var card_id: String = str(effect.get("card_id", ""))
			_add_campaign_card(state, card_id, "event")
		"gain_relic":
			var relic_id: String = str(effect.get("relic_id", ""))
			var relic_ids: Array = state.get("relic_ids", [])
			if not relic_id.is_empty() and not relic_ids.has(relic_id):
				relic_ids.append(relic_id)
				state["relics_added"] = int(state.get("relics_added", 0)) + 1
				var added_ids: Array = state.get("relics_added_ids", [])
				added_ids.append(relic_id)
				state["relics_added_ids"] = added_ids
		"gain_potion":
			var potion_id: String = str(effect.get("potion_id", ""))
			if not potion_id.is_empty() and _has_empty_potion_slot(state):
				var potion_ids: Array = state.get("potion_ids", [])
				potion_ids.append(potion_id)
				state["potions_gained"] = int(state.get("potions_gained", 0)) + 1
				var gained_ids: Array = state.get("potions_gained_ids", [])
				gained_ids.append(potion_id)
				state["potions_gained_ids"] = gained_ids
		"remove_first_non_starter_card":
			var deck_ids: Array = state.get("deck_ids", [])
			var remove_index: int = _first_non_starter_card_index(deck_ids)
			if remove_index >= 0:
				var removed_card_id: String = str(deck_ids[remove_index])
				deck_ids.remove_at(remove_index)
				state["cards_removed"] = int(state.get("cards_removed", 0)) + 1
				var removed_ids: Array = state.get("cards_removed_ids", [])
				removed_ids.append(removed_card_id)
				state["cards_removed_ids"] = removed_ids
				_record_card_removed(state, removed_card_id)
		"complete_event":
			var event_id: String = str(effect.get("event_id", ""))
			if not event_id.is_empty():
				var completed: Dictionary = state.get("completed_event_ids", {})
				completed[event_id] = true
				state["completed_event_ids"] = completed
		_:
			pass

func _remove_non_starter_card_effect_score(state: Dictionary) -> float:
	var deck_ids: Array = state.get("deck_ids", [])
	var remove_index: int = _first_non_starter_card_index(deck_ids)
	if remove_index < 0:
		return 0.0
	var entry: String = str(deck_ids[remove_index])
	var score: float = _deck_entry_card_score(entry, str(state.get("character_id", "")))
	return clamp(7.5 - max(0.0, score) * 0.45, -4.0, 8.0)

func _first_non_starter_card_index(deck_ids: Array) -> int:
	for i in range(deck_ids.size()):
		var card: Dictionary = _card_by_id(_base_card_id(str(deck_ids[i])))
		if not card.is_empty() and str(card.get("rarity", "")) != "starter":
			return i
	return -1

func _deck_contains_card(deck_ids: Array, card_id: String) -> bool:
	if card_id.is_empty():
		return false
	for entry in deck_ids:
		if _base_card_id(str(entry)) == card_id:
			return true
	return false

func _simulate_campaign_shop(state: Dictionary, chapter_id: String, seed_value: int) -> void:
	state["shops_seen"] = int(state.get("shops_seen", 0)) + 1
	var deck_ids: Array = state.get("deck_ids", [])
	var hp: int = int(state.get("hp", 0))
	var max_hp: int = int(state.get("max_hp", 1))
	var hp_ratio: float = float(hp) / float(max(1, max_hp))
	var bought_potion := false
	if hp_ratio < 0.75:
		bought_potion = _buy_best_shop_potion(state, chapter_id, seed_value)

	var card_options: Array = _generate_card_options(str(state.get("character_id", "")), 3, "shop_card|%s|%d" % [chapter_id, seed_value], "shop_card")
	_record_card_offers(state, card_options)
	var best_card: Dictionary = _best_card_option(card_options, str(state.get("character_id", "")))
	if not best_card.is_empty():
		var card_price: int = _card_price(best_card)
		var shop_accept_score: float = float(economy_data.get("reward_generation", {}).get("shop_card_accept_score", 7.0))
		if int(state.get("gold", 0)) >= card_price and _card_reward_score(best_card, str(state.get("character_id", ""))) >= shop_accept_score:
			_add_campaign_card(state, str(best_card.get("id", "")), "shop")
			state["gold"] = int(state.get("gold", 0)) - card_price

	if not bought_potion:
		_buy_best_shop_potion(state, chapter_id, seed_value)

	var remove_price: int = _remove_card_price(int(state.get("remove_count", 0)))
	var remove_index: int = _worst_deck_card_index(deck_ids)
	if deck_ids.size() > 10 and _should_shop_remove_card(state, remove_price, remove_index, hp_ratio):
		var removed_card_id: String = str(deck_ids[remove_index])
		deck_ids.remove_at(remove_index)
		state["gold"] = int(state.get("gold", 0)) - remove_price
		state["remove_count"] = int(state.get("remove_count", 0)) + 1
		state["cards_removed"] = int(state.get("cards_removed", 0)) + 1
		var removed_ids: Array = state.get("cards_removed_ids", [])
		removed_ids.append(removed_card_id)
		state["cards_removed_ids"] = removed_ids
		_record_card_removed(state, removed_card_id)

func _buy_best_shop_potion(state: Dictionary, chapter_id: String, seed_value: int) -> bool:
	if not _has_empty_potion_slot(state):
		return false
	var potion_options: Array = _generate_potion_options(2, "shop_potion|%s|%d" % [chapter_id, seed_value])
	var best_potion: Dictionary = _best_potion_option(potion_options)
	if best_potion.is_empty():
		return false
	var potion_price: int = _potion_price(best_potion)
	if int(state.get("gold", 0)) < potion_price:
		return false
	var potion_ids: Array = state.get("potion_ids", [])
	potion_ids.append(str(best_potion.get("id", "")))
	state["gold"] = int(state.get("gold", 0)) - potion_price
	state["potions_gained"] = int(state.get("potions_gained", 0)) + 1
	var gained_ids: Array = state.get("potions_gained_ids", [])
	gained_ids.append(str(best_potion.get("id", "")))
	state["potions_gained_ids"] = gained_ids
	return true

func _should_shop_remove_card(state: Dictionary, remove_price: int, remove_index: int, hp_ratio: float) -> bool:
	if remove_index < 0 or int(state.get("gold", 0)) < remove_price:
		return false
	if hp_ratio < 0.55 and _has_empty_potion_slot(state):
		var remaining_gold: int = int(state.get("gold", 0)) - remove_price
		if remaining_gold < _lowest_potion_price():
			return false
	var deck_ids: Array = state.get("deck_ids", [])
	var entry: String = str(deck_ids[remove_index])
	var card: Dictionary = _card_by_id(_base_card_id(entry))
	if card.is_empty():
		return false
	if str(card.get("rarity", "")) != "starter" and (entry.ends_with("+") or _deck_entry_card_score(entry, str(state.get("character_id", ""))) >= 7.0):
		return false
	return true

func _lowest_potion_price() -> int:
	var prices: Dictionary = economy_data.get("shop", {}).get("potion_prices", {})
	var lowest := 999999
	for price in prices.values():
		lowest = min(lowest, int(price))
	return lowest if lowest < 999999 else 35

func _simulate_campaign_campfire(state: Dictionary) -> void:
	state["campfires_seen"] = int(state.get("campfires_seen", 0)) + 1
	var hp: int = int(state.get("hp", 0))
	var max_hp: int = int(state.get("max_hp", 1))
	if hp <= int(ceil(float(max_hp) * 0.72)):
		var heal_percent: int = int(economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 30))
		state["hp"] = min(max_hp, hp + int(ceil(float(max_hp) * float(heal_percent) / 100.0)))
		return
	var deck_ids: Array = state.get("deck_ids", [])
	var upgrade_index: int = _best_upgrade_index(deck_ids)
	if upgrade_index >= 0:
		var upgraded_card_id: String = "%s+" % _base_card_id(str(deck_ids[upgrade_index]))
		deck_ids[upgrade_index] = upgraded_card_id
		state["cards_upgraded"] = int(state.get("cards_upgraded", 0)) + 1
		var upgraded_ids: Array = state.get("cards_upgraded_ids", [])
		upgraded_ids.append(upgraded_card_id)
		state["cards_upgraded_ids"] = upgraded_ids
		_record_card_upgraded(state, upgraded_card_id)

func _campaign_modifier_sources(state: Dictionary) -> Array:
	var sources: Array = []
	var skill_book: Dictionary = _progression_entry_by_id("skill_books", str(state.get("skill_book_id", "steel_manual")))
	if not skill_book.is_empty():
		sources.append({
			"id": "skill_book_%s" % str(skill_book.get("id", "steel_manual")),
			"name": "技能书：%s" % str(skill_book.get("name", "钢铁手册")),
			"effects": skill_book.get("effects", []).duplicate(true)
		})
	var mastery: Dictionary = _progression_entry_by_id("deck_masteries", str(state.get("deck_mastery_id", "")))
	if not mastery.is_empty():
		sources.append({
			"id": "deck_mastery_%s" % str(mastery.get("id", "")),
			"name": "卡组专精：%s" % str(mastery.get("name", "锻造")),
			"effects": mastery.get("effects", []).duplicate(true)
		})
	return sources

func _progression_entry_by_id(section: String, entry_id: String) -> Dictionary:
	if entry_id.is_empty():
		return {}
	for entry_value in progression_data.get(section, []):
		var entry: Dictionary = entry_value
		if str(entry.get("id", "")) == entry_id:
			return entry
	return {}

func _choose_campaign_deck_mastery(deck_ids: Array) -> String:
	var best_id: String = ""
	var best_score: float = -999999.0
	for mastery_value in progression_data.get("deck_masteries", []):
		var mastery: Dictionary = mastery_value
		if not _campaign_mastery_requirements_met(deck_ids, mastery.get("requirements", {})):
			continue
		var score: float = _relic_score(mastery)
		if score > best_score:
			best_score = score
			best_id = str(mastery.get("id", ""))
	return best_id

func _campaign_mastery_requirements_met(deck_ids: Array, requirements: Dictionary) -> bool:
	if requirements.has("min_type_count"):
		var type_counts: Dictionary = {}
		for entry_value in deck_ids:
			var card: Dictionary = _card_by_id(_base_card_id(str(entry_value)))
			var card_type: String = str(card.get("type", ""))
			type_counts[card_type] = int(type_counts.get(card_type, 0)) + 1
		for card_type_value in requirements.get("min_type_count", {}).keys():
			if int(type_counts.get(str(card_type_value), 0)) < int(requirements.get("min_type_count", {}).get(card_type_value, 0)):
				return false
		return true
	if requirements.has("min_zero_cost_cards"):
		var zero_cost_count: int = 0
		for entry_value in deck_ids:
			var entry: String = str(entry_value)
			var card: Dictionary = _card_by_id(_base_card_id(entry))
			var cost: int = int(card.get("upgrade", {}).get("cost", card.get("cost", -1))) if entry.ends_with("+") else int(card.get("cost", -1))
			if cost == 0:
				zero_cost_count += 1
		return zero_cost_count >= int(requirements.get("min_zero_cost_cards", 0))
	if requirements.has("min_burn_creator_cards"):
		var creator_count: int = 0
		for entry_value in deck_ids:
			var entry: String = str(entry_value)
			var card: Dictionary = _card_by_id(_base_card_id(entry))
			var effects: Array = card.get("upgrade", {}).get("effects", []) if entry.ends_with("+") else card.get("effects", [])
			for effect_value in effects:
				var effect: Dictionary = effect_value
				if str(effect.get("type", "")) == "create_card" and str(effect.get("card_id", "")) == "searing_wound":
					creator_count += 1
					break
		return creator_count >= int(requirements.get("min_burn_creator_cards", 0))
	return false

func _run_single_combat(character_id: String, challenge_level: int, encounter_id: String, max_turns: int, seed_value: int) -> Dictionary:
	var character: Dictionary = _character_config(character_id)
	var challenge: Dictionary = _challenge_config(challenge_level)
	var modifiers: Dictionary = challenge.get("modifiers", {})
	return _run_single_combat_with_loadout(
		character_id,
		challenge_level,
		encounter_id,
		max_turns,
		seed_value,
		character.get("starter_deck_ids", []).duplicate(true),
		character.get("starter_relic_ids", []).duplicate(true),
		_starting_hp_for_character(character_id, modifiers),
		[]
	)

func _run_single_combat_with_loadout(
	character_id: String,
	challenge_level: int,
	encounter_id: String,
	max_turns: int,
	seed_value: int,
	deck_ids: Array,
	relic_ids: Array,
	player_hp: int,
	potion_ids: Array,
	run_modifier_sources: Array = []
) -> Dictionary:
	seed(seed_value)
	var challenge: Dictionary = _challenge_config(challenge_level)
	var modifiers: Dictionary = challenge.get("modifiers", {})
	var combat_player_data: Dictionary = player_data.duplicate(true)
	combat_player_data["selected_character_id"] = character_id
	combat_player_data["challenge_modifiers"] = modifiers.duplicate(true)
	combat_player_data["run_modifier_sources"] = run_modifier_sources.duplicate(true)

	var combat = CombatStateScript.new()
	combat.setup(
		card_data,
		enemy_data,
		relic_data,
		encounter_data,
		combat_player_data,
		encounter_id,
		deck_ids,
		relic_ids,
		player_hp
	)
	combat.consume_feedback_events()

	var starting_hp: int = int(combat.player.get("hp", 0))
	var starting_enemy_hp: int = _total_enemy_max_hp(combat)
	var cards_played := 0
	var card_play_counts_by_id: Dictionary = {}
	var timeout := false
	var used_potion_ids: Array = []

	while not combat.is_won() and not combat.is_lost():
		if int(combat.turn) > max_turns:
			timeout = true
			break
		if combat.phase != "player":
			break
		var potion_uses_this_turn := 0
		while potion_uses_this_turn < 2:
			var used_potion_id: String = _try_use_potion(combat, potion_ids)
			if used_potion_id.is_empty():
				break
			used_potion_ids.append(used_potion_id)
			potion_uses_this_turn += 1
			combat.consume_feedback_events()
			if combat.is_won() or combat.is_lost():
				break
		combat.consume_feedback_events()
		var plays_this_turn := 0
		while combat.phase == "player" and plays_this_turn < 40:
			var decision: Dictionary = _choose_card(combat)
			if decision.is_empty():
				break
			var hand_index: int = int(decision.get("hand_index", -1))
			var played_card_id := ""
			if hand_index >= 0 and hand_index < combat.hand.size():
				played_card_id = _base_card_id(str(combat.hand[hand_index].get("id", "")))
			if not combat.play_card(hand_index, int(decision.get("target_index", -1))):
				break
			_increment_count(card_play_counts_by_id, played_card_id)
			cards_played += 1
			plays_this_turn += 1
			combat.consume_feedback_events()
			if combat.is_won() or combat.is_lost():
				break
		if not combat.is_won() and not combat.is_lost():
			combat.end_player_turn()
			combat.consume_feedback_events()

	var result_phase: String = "timeout" if timeout else str(combat.phase)
	return {
		"phase": result_phase,
		"won": combat.is_won(),
		"lost": combat.is_lost(),
		"timeout": timeout,
		"turns": int(combat.turn),
		"player_hp_remaining": int(combat.player.get("hp", 0)),
		"player_hp_lost": max(0, starting_hp - int(combat.player.get("hp", 0))),
		"enemy_hp_removed": max(0, starting_enemy_hp - _total_enemy_hp(combat)),
		"cards_played": cards_played,
		"card_play_counts_by_id": card_play_counts_by_id,
		"potions_remaining": potion_ids.duplicate(true),
		"potions_used_ids": used_potion_ids
	}

func _choose_card(combat) -> Dictionary:
	var incoming_damage: int = _incoming_damage(combat)
	var best_score := -999999.0
	var best_decision: Dictionary = {}
	for hand_index in range(combat.hand.size()):
		if not combat.can_play_card(hand_index):
			continue
		var card: Dictionary = combat.hand[hand_index]
		for target_index in _target_indices_for_card(combat, card):
			var score: float = _score_card(combat, card, int(target_index), incoming_damage)
			if score > best_score:
				best_score = score
				best_decision = {"hand_index": hand_index, "target_index": int(target_index), "score": score}
	if best_score <= 0.15:
		return {}
	return best_decision

func _target_indices_for_card(combat, card: Dictionary) -> Array:
	var target_mode: String = str(card.get("target", "enemy"))
	if target_mode == "self" or target_mode == "all_enemies":
		return [_focus_target_index(combat)]
	var result: Array = []
	for i in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[i]
		if int(enemy.get("hp", 0)) > 0:
			result.append(i)
	return result if not result.is_empty() else [-1]

func _focus_target_index(combat) -> int:
	var best_index := -1
	var best_score := -999999.0
	for i in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[i]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var threat: int = _intent_damage(enemy)
		var hp: int = int(enemy.get("hp", 0))
		var score: float = float(threat * 5) + max(0.0, 80.0 - float(hp)) * 0.25
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

func _score_card(combat, card: Dictionary, target_index: int, incoming_damage: int) -> float:
	var score := 0.0
	var projected_block: int = int(combat.player.get("block", 0))
	var card_type: String = str(card.get("type", ""))
	if card_type == "power":
		score += 3.0 if int(combat.turn) <= 3 else 0.6

	for effect in card.get("effects", []):
		var effect_dict: Dictionary = effect
		if _effect_condition_failed_for_score(combat, effect_dict):
			continue
		match str(effect_dict.get("type", "")):
			"damage":
				score += _damage_score(combat, card, effect_dict, target_index)
			"block":
				var block_amount: int = _estimate_block(combat, card, effect_dict)
				var missing_block: int = max(0, incoming_damage - projected_block)
				score += float(min(block_amount, missing_block)) * 2.8
				score += float(max(0, block_amount - missing_block)) * 0.45
				projected_block += block_amount
			"draw":
				score += float(int(effect_dict.get("amount", 0))) * 1.4
			"gain_energy":
				score += float(int(effect_dict.get("amount", 0))) * 2.2
			"gain_momentum":
				score += float(int(effect_dict.get("amount", 0))) * 1.0
			"lose_momentum":
				score -= float(int(effect_dict.get("amount", 0))) * 0.7
			"damage_self":
				score -= float(int(effect_dict.get("amount", 0))) * 1.4
			"apply_status":
				score += _status_effect_score(combat, effect_dict, target_index, projected_block, incoming_damage)
			"create_card":
				score += _create_card_score(effect_dict)

	score -= float(int(card.get("cost", 0))) * 0.08
	if int(card.get("cost", 0)) == 0:
		score += 0.25
	return score

func _damage_score(combat, card: Dictionary, effect: Dictionary, target_index: int) -> float:
	var target_mode: String = str(effect.get("target", card.get("target", "enemy")))
	var amount: int = _estimate_damage_amount(combat, card, effect)
	var hits: int = _estimate_hits(combat, effect)
	if target_mode == "all_enemies":
		var total := 0.0
		for enemy in combat.enemies:
			var enemy_dict: Dictionary = enemy
			if int(enemy_dict.get("hp", 0)) > 0:
				total += _single_enemy_damage_score(enemy_dict, amount, hits)
		return total
	if target_index < 0 or target_index >= combat.enemies.size():
		return 0.0
	return _single_enemy_damage_score(combat.enemies[target_index], amount, hits)

func _single_enemy_damage_score(enemy: Dictionary, amount: int, hits: int) -> float:
	var block: int = int(enemy.get("block", 0))
	var hp: int = int(enemy.get("hp", 0))
	var adjusted_amount: int = amount
	if _status_amount(enemy.get("statuses", {}), "vulnerable") > 0:
		adjusted_amount = int(ceil(float(adjusted_amount) * 1.5))
	var raw_damage: int = max(0, adjusted_amount * hits)
	var effective_damage: int = max(0, raw_damage - block)
	var capped_damage: int = min(hp, effective_damage)
	var score: float = float(capped_damage) * 2.35 + float(min(block, raw_damage)) * 0.45
	if capped_damage >= hp:
		score += 12.0
	return score

func _estimate_damage_amount(combat, card: Dictionary, effect: Dictionary) -> int:
	var amount: int = int(effect.get("amount", 0))
	amount += int(combat.player.get("momentum", 0)) * int(effect.get("bonus_per_momentum", 0))
	var bonus_threshold: int = int(effect.get("bonus_if_momentum_at_least", -1))
	if bonus_threshold >= 0 and int(combat.player.get("momentum", 0)) >= bonus_threshold:
		amount += int(effect.get("bonus", 0))
	if not bool(card.get("ignore_player_modifiers", false)):
		amount += _status_amount(combat.player.get("statuses", {}), "strength")
		if _status_amount(combat.player.get("statuses", {}), "weak") > 0:
			amount = int(floor(float(amount) * 0.75))
	return max(0, amount)

func _estimate_hits(combat, effect: Dictionary) -> int:
	var hits: int = int(effect.get("hits", 1))
	var extra_per_momentum: int = int(effect.get("extra_hit_per_momentum", 0))
	if extra_per_momentum > 0:
		hits += int(floor(float(combat.player.get("momentum", 0)) / float(extra_per_momentum)))
	return max(1, hits)

func _estimate_block(combat, card: Dictionary, effect: Dictionary) -> int:
	var amount: int = int(effect.get("amount", 0))
	if int(effect.get("bonus_if_momentum_at_least", -1)) >= 0 and int(combat.player.get("momentum", 0)) >= int(effect.get("bonus_if_momentum_at_least", 0)):
		amount += int(effect.get("bonus", 0))
	if _status_amount(combat.player.get("statuses", {}), "frail") > 0:
		amount = int(floor(float(amount) * 0.75))
	return max(0, amount)

func _status_effect_score(combat, effect: Dictionary, target_index: int, projected_block: int, incoming_damage: int) -> float:
	var amount: int = int(effect.get("amount", 0))
	var target: String = str(effect.get("target", "enemy"))
	match str(effect.get("status", "")):
		"vulnerable":
			if target == "self":
				var exposed_damage: int = max(0, incoming_damage - projected_block)
				return -float(amount) * (3.0 + float(exposed_damage) * 0.65)
			return float(amount) * _enemy_status_target_multiplier(combat, target, target_index) * 5.2
		"weak":
			if target == "self":
				return -float(amount) * 3.2
			var prevented: int = _target_intent_damage_for_status(combat, target, target_index)
			return float(amount) * (3.2 + float(prevented) * 0.28)
		"burn":
			if target == "self":
				return -float(amount) * 2.0
			var burn_damage: int = min(3, amount) * amount - int(floor(float(min(3, amount) * (min(3, amount) - 1)) / 2.0))
			return float(max(amount, burn_damage)) * _enemy_status_target_multiplier(combat, target, target_index) * 1.7
		"strength":
			return float(amount) * (5.0 if target == "self" else 1.8)
		"plating", "counter_pressure", "counter_pressure_plus":
			return float(amount) * 4.2
		_:
			return float(amount) * (1.0 if target != "self" else 0.8)

func _status_score(effect: Dictionary) -> float:
	var amount: int = int(effect.get("amount", 0))
	var target: String = str(effect.get("target", "enemy"))
	match str(effect.get("status", "")):
		"vulnerable":
			return float(amount) * (4.4 if target != "self" else -3.0)
		"weak":
			return float(amount) * (4.0 if target != "self" else -3.2)
		"burn":
			return float(amount) * (2.6 if target != "self" else -2.0)
		"strength":
			return float(amount) * (5.0 if target == "self" else 1.8)
		"plating", "counter_pressure", "counter_pressure_plus":
			return float(amount) * 4.2
		_:
			return float(amount) * (1.0 if target != "self" else 0.8)

func _enemy_status_target_multiplier(combat, target: String, target_index: int) -> float:
	if target == "all_enemies":
		var alive := 0
		for enemy in combat.enemies:
			var enemy_dict: Dictionary = enemy
			if int(enemy_dict.get("hp", 0)) > 0:
				alive += 1
		return max(1.0, float(alive))
	if target_index < 0 or target_index >= combat.enemies.size():
		return 1.0
	var enemy: Dictionary = combat.enemies[target_index]
	var hp: int = int(enemy.get("hp", 0))
	return 1.25 if hp >= 35 else 0.9

func _target_intent_damage_for_status(combat, target: String, target_index: int) -> int:
	if target == "all_enemies":
		var total := 0
		for enemy in combat.enemies:
			var enemy_dict: Dictionary = enemy
			if int(enemy_dict.get("hp", 0)) > 0:
				total += _intent_damage(enemy_dict)
		return total
	if target_index < 0 or target_index >= combat.enemies.size():
		return 0
	return _intent_damage(combat.enemies[target_index])

func _create_card_score(effect: Dictionary) -> float:
	var card_id: String = str(effect.get("card_id", ""))
	var destination: String = str(effect.get("destination", "discard"))
	var amount: int = int(effect.get("amount", 1))
	if card_id == "searing_wound":
		return -1.2 * float(amount) if destination != "hand" else -2.4 * float(amount)
	return 0.25 * float(amount)

func _incoming_damage(combat) -> int:
	var total := 0
	var player_vulnerable_charges: int = _status_amount(combat.player.get("statuses", {}), "vulnerable")
	for enemy in combat.enemies:
		var enemy_dict: Dictionary = enemy
		if int(enemy_dict.get("hp", 0)) <= 0:
			continue
		var damage: int = _intent_damage_against_player(combat, enemy_dict, player_vulnerable_charges > 0)
		total += damage
		if damage > 0 and player_vulnerable_charges > 0:
			player_vulnerable_charges -= 1
	return total

func _intent_damage(enemy: Dictionary) -> int:
	var intent: Dictionary = enemy.get("current_action", {}).get("intent", {})
	var intent_type: String = str(intent.get("type", ""))
	if intent_type != "attack" and intent_type != "attack_debuff":
		return 0
	var amount: int = int(intent.get("amount", 0))
	amount += _status_amount(enemy.get("statuses", {}), "strength")
	if _status_amount(enemy.get("statuses", {}), "weak") > 0:
		amount = int(floor(float(amount) * 0.75))
	return max(0, amount * int(intent.get("hits", 1)))

func _intent_damage_against_player(combat, enemy: Dictionary, apply_player_vulnerable: bool) -> int:
	var intent: Dictionary = enemy.get("current_action", {}).get("intent", {})
	var intent_type: String = str(intent.get("type", ""))
	if intent_type != "attack" and intent_type != "attack_debuff":
		return 0
	var amount: int = int(intent.get("amount", 0))
	var multiplier: float = max(0.1, float(combat.challenge_modifiers.get("enemy_damage_multiplier", 1.0)))
	amount = int(ceil(float(amount) * multiplier))
	amount += _status_amount(enemy.get("statuses", {}), "strength")
	if _status_amount(enemy.get("statuses", {}), "weak") > 0:
		amount = int(floor(float(amount) * 0.75))
	if apply_player_vulnerable:
		amount = int(ceil(float(amount) * 1.5))
	return max(0, amount * int(intent.get("hits", 1)))

func _effect_condition_failed_for_score(combat, effect: Dictionary) -> bool:
	if effect.has("requires_momentum_at_least") and int(combat.player.get("momentum", 0)) < int(effect.get("requires_momentum_at_least", 0)):
		return true
	return false

func _try_use_potion(combat, potion_ids: Array) -> String:
	if potion_ids.is_empty() or combat.phase != "player":
		return ""
	var incoming_damage: int = _incoming_damage(combat)
	var current_block: int = int(combat.player.get("block", 0))
	var hp: int = int(combat.player.get("hp", 0))
	var max_hp: int = int(combat.player.get("max_hp", hp))
	for i in range(potion_ids.size()):
		var potion: Dictionary = _potion_config(str(potion_ids[i]))
		if potion.is_empty():
			continue
		var should_use := false
		for effect in potion.get("effects", []):
			var effect_dict: Dictionary = effect
			match str(effect_dict.get("type", "")):
				"heal":
					should_use = hp <= int(ceil(float(max_hp) * 0.38))
				"block":
					should_use = incoming_damage > current_block + 4
				"apply_status":
					should_use = incoming_damage > current_block and str(effect_dict.get("status", "")) == "weak"
				"damage":
					should_use = _potion_damage_can_finish(combat, effect_dict) or _potion_damage_is_good_boss_pressure(combat, effect_dict)
				"draw", "gain_energy", "gain_momentum":
					should_use = str(_encounter_config(str(combat.selected_encounter_id)).get("tier", "")) == "boss"
			if should_use:
				var target_index: int = _potion_target_index(combat, potion)
				if combat.use_potion(potion, target_index):
					var used_potion_id: String = str(potion_ids[i])
					potion_ids.remove_at(i)
					return used_potion_id
	return ""

func _potion_damage_can_finish(combat, effect: Dictionary) -> bool:
	var amount: int = int(effect.get("amount", 0)) * int(effect.get("hits", 1))
	if str(effect.get("target", "enemy")) == "all_enemies":
		for enemy in combat.enemies:
			var enemy_dict: Dictionary = enemy
			if int(enemy_dict.get("hp", 0)) > 0 and int(enemy_dict.get("hp", 0)) <= amount:
				return true
		return false
	var target_index: int = _focus_target_index(combat)
	if target_index < 0:
		return false
	var enemy: Dictionary = combat.enemies[target_index]
	return int(enemy.get("hp", 0)) <= amount

func _potion_damage_is_good_boss_pressure(combat, effect: Dictionary) -> bool:
	if str(_encounter_config(str(combat.selected_encounter_id)).get("tier", "")) != "boss":
		return false
	var amount: int = int(effect.get("amount", 0)) * int(effect.get("hits", 1))
	if amount <= 0:
		return false
	var remaining_hp: int = _total_enemy_hp(combat)
	return remaining_hp <= max(60, amount * 5)

func _potion_target_index(combat, potion: Dictionary) -> int:
	var target_mode: String = str(potion.get("target", "enemy"))
	if target_mode == "self" or target_mode == "all_enemies":
		return _focus_target_index(combat)
	return _focus_target_index(combat)

func _generate_chapter_graph(chapter_id: String, seed_value: int, character_id: String, state: Dictionary = {}) -> Dictionary:
	var chapter_config: Dictionary = map_generation_data.get(chapter_id, {}).duplicate(true)
	if chapter_config.is_empty():
		return {}
	var filtered_event_pool: Array = _filtered_event_pool_for_character(chapter_config.get("event_pool", []), character_id, state)
	var guaranteed_event_ids: Array = []
	for event_id_value in filtered_event_pool:
		var event: Dictionary = _event_by_id(str(event_id_value))
		if bool(event.get("guaranteed_when_available", false)):
			guaranteed_event_ids.append(str(event_id_value))
	chapter_config["event_pool"] = filtered_event_pool
	chapter_config["guaranteed_event_ids"] = guaranteed_event_ids
	chapter_config["level_tree_constraints"] = level_tree_data.get("chapters", {}).get(chapter_id, {}).duplicate(true)
	chapter_config["route_constraints"] = level_tree_data.get("route_constraints", {}).duplicate(true)
	chapter_config["seed"] = int(chapter_config.get("seed", 1)) + _deterministic_index("chapter|%s|%d" % [chapter_id, seed_value], 100000)
	return MapGeneratorScript.generate(chapter_config)

func _filtered_event_pool_for_character(event_pool: Array, character_id: String, state: Dictionary = {}) -> Array:
	var filtered: Array = []
	for event_id_value in event_pool:
		var event_id: String = str(event_id_value)
		var event: Dictionary = _event_by_id(event_id)
		if event.is_empty() or _event_available_for_character(event, character_id, state):
			filtered.append(event_id)
	return filtered

func _event_available_for_character(event: Dictionary, character_id: String, state: Dictionary = {}) -> bool:
	var character_ids: Array = event.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(character_id):
		return false
	for condition in event.get("availability_conditions", []):
		var condition_dict: Dictionary = condition
		if _event_condition_failed(state, condition_dict):
			return false
	return true

func _graph_node_by_id(graph: Dictionary, node_id: String) -> Dictionary:
	for layer in graph.get("layers", []):
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			if str(node_dict.get("id", "")) == node_id:
				return node_dict
	return {}

func _successor_nodes(graph: Dictionary, node_id: String) -> Array:
	var result: Array = []
	for edge in graph.get("edges", []):
		var edge_dict: Dictionary = edge
		if str(edge_dict.get("from", "")) == node_id:
			var node: Dictionary = _graph_node_by_id(graph, str(edge_dict.get("to", "")))
			if not node.is_empty():
				result.append(node)
	return result

func _choose_next_campaign_node(state: Dictionary, candidates: Array, graph: Dictionary = {}) -> String:
	var best_id := ""
	var best_score := -999999.0
	var route_score_cache: Dictionary = {}
	for node in candidates:
		var node_dict: Dictionary = node
		var score: float = _campaign_route_preview_score(state, graph, str(node_dict.get("id", "")), 3, route_score_cache) if not graph.is_empty() else _campaign_node_score(state, node_dict)
		if score > best_score:
			best_score = score
			best_id = str(node_dict.get("id", ""))
	return best_id

func _campaign_route_preview_score(state: Dictionary, graph: Dictionary, node_id: String, depth: int, cache: Dictionary) -> float:
	if node_id.is_empty():
		return -999999.0
	var cache_key := "%s|%d|%s" % [node_id, depth, _campaign_preview_state_key(state)]
	if cache.has(cache_key):
		return float(cache[cache_key])
	var node: Dictionary = _graph_node_by_id(graph, node_id)
	if node.is_empty():
		return -999999.0
	var score: float = _campaign_node_score(state, node)
	var next_state: Dictionary = _campaign_preview_state_after_node(state, node)
	if depth > 1 and str(node.get("type", "")) != "boss":
		var best_future_score := -999999.0
		for successor_value in _successor_nodes(graph, node_id):
			var successor: Dictionary = successor_value
			best_future_score = max(best_future_score, _campaign_route_preview_score(next_state, graph, str(successor.get("id", "")), depth - 1, cache))
		if best_future_score > -999998.0:
			score += best_future_score
	cache[cache_key] = score
	return score

func _campaign_preview_state_key(state: Dictionary) -> String:
	return "%d|%d|%d|%d" % [
		int(state.get("hp", 0)),
		int(state.get("max_hp", 1)),
		int(state.get("gold", 0)),
		(state.get("relic_ids", []) as Array).size(),
	]

func _campaign_preview_state_after_node(state: Dictionary, node: Dictionary) -> Dictionary:
	var preview: Dictionary = state.duplicate(true)
	var node_type: String = str(node.get("type", ""))
	if node_type == "campfire":
		var hp: int = int(preview.get("hp", 0))
		var max_hp: int = max(1, int(preview.get("max_hp", 1)))
		if hp <= int(ceil(float(max_hp) * 0.72)):
			var heal_percent: int = int(economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 30))
			preview["hp"] = min(max_hp, hp + int(ceil(float(max_hp) * float(heal_percent) / 100.0)))
	if node_type == "treasure" or node_type == "elite":
		var relic_ids: Array = preview.get("relic_ids", []).duplicate(true)
		relic_ids.append("__route_preview_relic_%s" % str(node.get("id", node_type)))
		preview["relic_ids"] = relic_ids
	if node_type == "treasure":
		var treasure: Dictionary = economy_data.get("treasure", {})
		var min_gold: int = int(treasure.get("gold_min", 0))
		var max_gold: int = max(min_gold, int(treasure.get("gold_max", min_gold)))
		preview["gold"] = int(preview.get("gold", 0)) + int(round(float(min_gold + max_gold) * 0.5))
	return preview

func _campaign_node_score(state: Dictionary, node: Dictionary) -> float:
	var node_type: String = str(node.get("type", ""))
	var hp_ratio: float = float(state.get("hp", 0)) / max(1.0, float(state.get("max_hp", 1)))
	var score := 0.0
	match node_type:
		"campfire":
			score = 25.0 if hp_ratio < 0.72 else 7.0
		"elite":
			var relic_count: int = (state.get("relic_ids", []) as Array).size()
			if hp_ratio > 0.86:
				score = 12.0 if relic_count >= 4 else -8.0
			else:
				score = -12.0
		"shop":
			score = 12.0 if int(state.get("gold", 0)) >= 80 else 3.0
		"event":
			score = 8.0 if hp_ratio < 0.75 else 5.0
		"treasure":
			score = 14.0
		"combat":
			score = 6.0
		"boss":
			score = 100.0
		_:
			score = 0.0
	return score

func _append_path_entry(state: Dictionary, chapter_id: String, node: Dictionary, node_result: Dictionary) -> void:
	var path: Array = state.get("path", [])
	path.append({
		"chapter_id": chapter_id,
		"node_id": str(node.get("id", "")),
		"node_type": str(node.get("type", "")),
		"encounter_id": str(node_result.get("encounter_id", node.get("encounter_id", ""))),
		"event_id": str(node.get("event_id", "")),
		"completed": bool(node_result.get("completed", false)),
		"hp": int(state.get("hp", 0)),
		"gold": int(state.get("gold", 0)),
		"deck_size": (state.get("deck_ids", []) as Array).size(),
		"relic_count": (state.get("relic_ids", []) as Array).size()
	})
	state["path"] = path

func _campaign_result(won: bool, state: Dictionary) -> Dictionary:
	return {
		"won": won,
		"lost": not won,
		"chapters_completed": int(state.get("chapters_completed", 0)),
		"nodes_completed": int(state.get("nodes_completed", 0)),
		"combats_won": int(state.get("combats_won", 0)),
		"elites_won": int(state.get("elites_won", 0)),
		"bosses_won": int(state.get("bosses_won", 0)),
		"events_seen": int(state.get("events_seen", 0)),
		"shops_seen": int(state.get("shops_seen", 0)),
		"campfires_seen": int(state.get("campfires_seen", 0)),
		"cards_added": int(state.get("cards_added", 0)),
		"cards_removed": int(state.get("cards_removed", 0)),
		"cards_upgraded": int(state.get("cards_upgraded", 0)),
		"relics_added": int(state.get("relics_added", 0)),
		"potions_gained": int(state.get("potions_gained", 0)),
		"potions_used": int(state.get("potions_used", 0)),
		"turns": int(state.get("turns", 0)),
		"cards_played": int(state.get("cards_played", 0)),
		"final_hp": int(state.get("hp", 0)),
		"final_gold": int(state.get("gold", 0)),
		"final_deck_size": (state.get("deck_ids", []) as Array).size(),
		"final_relic_count": (state.get("relic_ids", []) as Array).size(),
		"final_deck_ids": state.get("deck_ids", []),
		"final_relic_ids": state.get("relic_ids", []),
		"final_potion_ids": state.get("potion_ids", []),
		"skill_book_id": str(state.get("skill_book_id", "")),
		"deck_mastery_id": str(state.get("deck_mastery_id", "")),
		"events_choice_ids": state.get("events_choice_ids", []),
		"cards_added_ids": state.get("cards_added_ids", []),
		"cards_removed_ids": state.get("cards_removed_ids", []),
		"cards_upgraded_ids": state.get("cards_upgraded_ids", []),
		"card_offer_counts_by_id": state.get("card_offer_counts_by_id", {}),
		"card_acquisition_counts_by_id": state.get("card_acquisition_counts_by_id", {}),
		"card_acquisition_sources_by_id": state.get("card_acquisition_sources_by_id", {}),
		"card_removal_counts_by_id": state.get("card_removal_counts_by_id", {}),
		"card_upgrade_counts_by_id": state.get("card_upgrade_counts_by_id", {}),
		"card_play_counts_by_id": state.get("card_play_counts_by_id", {}),
		"relics_added_ids": state.get("relics_added_ids", []),
		"potions_gained_ids": state.get("potions_gained_ids", []),
		"potions_used_ids": state.get("potions_used_ids", []),
		"failed_at": str(state.get("failed_at", "")),
		"failed_reason": str(state.get("failed_reason", "")),
		"failed_node_type": str(state.get("failed_node_type", "")),
		"failed_encounter_id": str(state.get("failed_encounter_id", "")),
		"path": state.get("path", [])
	}

func _add_campaign_card(state: Dictionary, card_entry: String, source: String) -> void:
	var card_id := _base_card_id(card_entry)
	if card_id.is_empty() or _card_by_id(card_id).is_empty():
		return
	var deck_ids: Array = state.get("deck_ids", [])
	deck_ids.append(card_entry)
	state["cards_added"] = int(state.get("cards_added", 0)) + 1
	var added_ids: Array = state.get("cards_added_ids", [])
	added_ids.append(card_entry)
	state["cards_added_ids"] = added_ids
	var acquisition_counts: Dictionary = state.get("card_acquisition_counts_by_id", {})
	_increment_count(acquisition_counts, card_id)
	state["card_acquisition_counts_by_id"] = acquisition_counts
	var sources_by_id: Dictionary = state.get("card_acquisition_sources_by_id", {})
	var source_counts: Dictionary = sources_by_id.get(card_id, {})
	_increment_count(source_counts, source if not source.is_empty() else "unknown")
	sources_by_id[card_id] = source_counts
	state["card_acquisition_sources_by_id"] = sources_by_id

func _record_card_offers(state: Dictionary, cards: Array) -> void:
	var offer_counts: Dictionary = state.get("card_offer_counts_by_id", {})
	for card_value in cards:
		var card: Dictionary = card_value
		_increment_count(offer_counts, _base_card_id(str(card.get("id", ""))))
	state["card_offer_counts_by_id"] = offer_counts

func _record_card_removed(state: Dictionary, card_entry: String) -> void:
	var counts: Dictionary = state.get("card_removal_counts_by_id", {})
	_increment_count(counts, _base_card_id(card_entry))
	state["card_removal_counts_by_id"] = counts

func _record_card_upgraded(state: Dictionary, card_entry: String) -> void:
	var counts: Dictionary = state.get("card_upgrade_counts_by_id", {})
	_increment_count(counts, _base_card_id(card_entry))
	state["card_upgrade_counts_by_id"] = counts

func _increment_count(counts: Dictionary, key: String, amount: int = 1) -> void:
	if key.is_empty() or amount <= 0:
		return
	counts[key] = int(counts.get(key, 0)) + amount

func _merge_count_dictionary(state: Dictionary, field_name: String, incoming_value) -> void:
	if not incoming_value is Dictionary:
		return
	var merged: Dictionary = state.get(field_name, {})
	var incoming: Dictionary = incoming_value
	for key_value in incoming.keys():
		_increment_count(merged, str(key_value), int(incoming.get(key_value, 0)))
	state[field_name] = merged

func _offer_card_reward(state: Dictionary, amount: int, seed_text: String) -> void:
	if amount <= 0:
		return
	var options: Array = _generate_card_options(str(state.get("character_id", "")), amount, seed_text, "combat_card")
	_record_card_offers(state, options)
	var best_card: Dictionary = _best_card_option(options, str(state.get("character_id", "")))
	if best_card.is_empty():
		return
	var reward_config: Dictionary = economy_data.get("reward_generation", {})
	var accept_score: float = float(reward_config.get("combat_card_accept_score", 5.0))
	var skip_deck_size: int = int(reward_config.get("skip_reward_when_deck_at_least", 13))
	if _card_reward_score(best_card, str(state.get("character_id", ""))) < accept_score and (state.get("deck_ids", []) as Array).size() >= skip_deck_size:
		return
	_add_campaign_card(state, str(best_card.get("id", "")), "combat_reward")

func _offer_relic_reward(state: Dictionary, seed_text: String) -> void:
	var options: Array = _generate_relic_options(str(state.get("character_id", "")), state.get("relic_ids", []), 3, seed_text)
	var best_relic: Dictionary = _best_relic_option(options)
	if best_relic.is_empty():
		return
	var relic_ids: Array = state.get("relic_ids", [])
	relic_ids.append(str(best_relic.get("id", "")))
	state["relics_added"] = int(state.get("relics_added", 0)) + 1
	var added_ids: Array = state.get("relics_added_ids", [])
	added_ids.append(str(best_relic.get("id", "")))
	state["relics_added_ids"] = added_ids

func _offer_potion_reward(state: Dictionary, seed_text: String) -> void:
	if not _has_empty_potion_slot(state):
		return
	var potion_reward_config: Dictionary = economy_data.get("potion_reward", {})
	var option_count: int = max(0, int(potion_reward_config.get("combat_drop_count", 1)))
	if option_count <= 0:
		return
	var chance_percent: int = clampi(int(potion_reward_config.get("drop_chance_percent", 100)), 0, 100)
	if chance_percent <= 0 or _deterministic_index("potion_drop|%s" % seed_text, 100) >= chance_percent:
		return
	var options: Array = _generate_potion_options(option_count, seed_text)
	var best_potion: Dictionary = _best_potion_option(options)
	if best_potion.is_empty():
		return
	var potion_ids: Array = state.get("potion_ids", [])
	potion_ids.append(str(best_potion.get("id", "")))
	state["potions_gained"] = int(state.get("potions_gained", 0)) + 1
	var gained_ids: Array = state.get("potions_gained_ids", [])
	gained_ids.append(str(best_potion.get("id", "")))
	state["potions_gained_ids"] = gained_ids

func _generate_card_options(character_id: String, amount: int, seed_text: String, context: String) -> Array:
	var pool: Array = []
	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		var rarity: String = str(card_dict.get("rarity", ""))
		var type: String = str(card_dict.get("type", ""))
		if rarity == "starter" or rarity == "status" or type == "status" or type == "curse":
			continue
		if _card_available_for_character(card_dict, character_id):
			pool.append(card_dict)
	return _weighted_rarity_selection(pool, amount, _rarity_weights_for_context(context), seed_text)

func _generate_relic_options(character_id: String, owned_relic_ids: Array, amount: int, seed_text: String) -> Array:
	var pool: Array = []
	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		var relic_id: String = str(relic_dict.get("id", ""))
		if relic_id.is_empty() or owned_relic_ids.has(relic_id) or str(relic_dict.get("rarity", "")) == "starter":
			continue
		if _relic_available_for_character(relic_dict, character_id):
			pool.append(relic_dict)
	return _weighted_rarity_selection(pool, amount, _rarity_weights_for_context("relic_reward"), seed_text)

func _generate_potion_options(amount: int, seed_text: String) -> Array:
	var pool: Array = []
	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		if not str(potion_dict.get("id", "")).is_empty():
			pool.append(potion_dict)
	return _weighted_rarity_selection(pool, amount, _rarity_weights_for_context("potion_reward"), seed_text)

func _weighted_rarity_selection(pool: Array, amount: int, weights: Dictionary, seed_text: String) -> Array:
	if amount <= 0 or pool.is_empty():
		return []
	var sorted_pool: Array = pool.duplicate()
	sorted_pool.sort_custom(Callable(self, "_compare_content_by_id"))
	if amount >= sorted_pool.size():
		return sorted_pool
	var buckets: Dictionary = {}
	for item in sorted_pool:
		var item_dict: Dictionary = item
		var rarity: String = str(item_dict.get("rarity", "common"))
		if not buckets.has(rarity):
			buckets[rarity] = []
		var bucket: Array = buckets.get(rarity, [])
		bucket.append(item_dict)
		buckets[rarity] = bucket
	var selected: Array = []
	for slot in range(amount):
		var rarity_choice: String = _weighted_available_rarity(buckets, weights, "%s|rarity|%d" % [seed_text, slot])
		if rarity_choice.is_empty():
			break
		var rarity_bucket: Array = buckets.get(rarity_choice, [])
		if rarity_bucket.is_empty():
			break
		var selected_index: int = _deterministic_index("%s|item|%d|%s" % [seed_text, slot, rarity_choice], rarity_bucket.size())
		selected.append(rarity_bucket[selected_index])
		rarity_bucket.remove_at(selected_index)
		buckets[rarity_choice] = rarity_bucket
	return selected

func _weighted_available_rarity(buckets: Dictionary, weights: Dictionary, seed_text: String) -> String:
	var rarity_order: Array[String] = ["common", "uncommon", "rare"]
	for rarity in buckets.keys():
		var rarity_string: String = str(rarity)
		if not rarity_order.has(rarity_string):
			rarity_order.append(rarity_string)
	var weighted_rarities: Array[String] = []
	var total_weight := 0
	for rarity in rarity_order:
		var bucket: Array = buckets.get(rarity, [])
		if bucket.is_empty():
			continue
		var weight: int = max(0, int(weights.get(rarity, 1)))
		if weight <= 0:
			continue
		weighted_rarities.append(rarity)
		total_weight += weight
	if weighted_rarities.is_empty():
		return ""
	var roll: int = _deterministic_index(seed_text, total_weight)
	var cursor := 0
	for rarity in weighted_rarities:
		cursor += max(0, int(weights.get(rarity, 1)))
		if roll < cursor:
			return rarity
	return weighted_rarities[weighted_rarities.size() - 1]

func _rarity_weights_for_context(context: String) -> Dictionary:
	var config: Dictionary = economy_data.get("reward_generation", {})
	match context:
		"shop_card":
			return config.get("shop_card_rarity_weights", config.get("card_rarity_weights", {}))
		"relic_reward":
			return config.get("relic_rarity_weights", {})
		"shop_potion", "potion_reward":
			return config.get("potion_rarity_weights", {})
		_:
			return config.get("card_rarity_weights", {})

func _best_card_option(options: Array, character_id: String) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -999999.0
	for option in options:
		var card: Dictionary = option
		var score: float = _card_reward_score(card, character_id)
		if score > best_score:
			best_score = score
			best = card
	return best

func _card_reward_score(card: Dictionary, _character_id: String) -> float:
	var score := 0.0
	match str(card.get("rarity", "common")):
		"rare":
			score += 3.0
		"uncommon":
			score += 1.4
	if str(card.get("type", "")) == "power":
		score += 4.0
	for effect in card.get("effects", []):
		var effect_dict: Dictionary = effect
		match str(effect_dict.get("type", "")):
			"damage":
				var damage_target_multiplier := 1.15 if str(effect_dict.get("target", card.get("target", ""))) == "all_enemies" else 0.88
				score += float(int(effect_dict.get("amount", 0)) * int(effect_dict.get("hits", 1))) * damage_target_multiplier
				score += float(int(effect_dict.get("bonus_per_momentum", 0))) * 2.0
				if effect_dict.has("bonus_if_momentum_at_least"):
					var conditional_multiplier: float = float(numerical_tree_data.get("effect_points", {}).get("conditional_multiplier", 0.72))
					score += float(int(effect_dict.get("bonus", 0)) * int(effect_dict.get("hits", 1))) * damage_target_multiplier * conditional_multiplier
			"block":
				score += float(int(effect_dict.get("amount", 0))) * 0.75
			"draw":
				score += float(int(effect_dict.get("amount", 0))) * 3.0
			"gain_energy":
				score += float(int(effect_dict.get("amount", 0))) * 4.0
			"gain_momentum":
				score += float(int(effect_dict.get("amount", 0))) * 1.8
			"apply_status":
				score += _status_score(effect_dict) * 0.85
			"create_card":
				score += _create_card_score(effect_dict)
			"damage_self":
				score -= float(int(effect_dict.get("amount", 0))) * 1.2
	score -= float(int(card.get("cost", 0))) * 1.1
	return score

func _best_relic_option(options: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -999999.0
	for option in options:
		var relic: Dictionary = option
		var score: float = _relic_score(relic)
		if score > best_score:
			best_score = score
			best = relic
	return best

func _relic_score(relic: Dictionary) -> float:
	var score := 0.0
	match str(relic.get("rarity", "common")):
		"rare":
			score += 8.0
		"uncommon":
			score += 5.0
		_:
			score += 3.0
	for effect in relic.get("effects", []):
		var effect_dict: Dictionary = effect
		var effect_score := 0.0
		match str(effect_dict.get("type", "")):
			"gain_energy":
				effect_score += 7.0
			"draw":
				effect_score += 5.0
			"gain_momentum", "momentum_max_bonus":
				effect_score += 4.0
			"gain_block", "skill_block_bonus_percent":
				effect_score += 3.2
			"damage_all_enemies", "damage_broken_enemy":
				effect_score += 4.5
			_:
				effect_score += 1.0
		var amount: int = int(effect_dict.get("amount", 1))
		if amount > 1:
			effect_score += float(amount - 1) * 0.75
		match str(effect_dict.get("trigger", "")):
			"setup", "turn_start":
				effect_score *= 1.08
			"card_played":
				effect_score *= 1.0
			"potion_used":
				effect_score *= 0.72
			"player_hp_lost":
				effect_score *= 0.68
		if bool(effect_dict.get("once_per_combat", false)):
			effect_score *= 0.58
		if bool(effect_dict.get("once_per_turn", false)):
			effect_score *= 0.78
		if effect_dict.has("requires_momentum_at_least"):
			effect_score *= 0.72
		if effect_dict.has("min_hp_lost"):
			effect_score *= 0.9
		if effect_dict.has("card_type") or effect_dict.has("card_cost_equals") or effect_dict.has("min_card_cost"):
			effect_score *= 0.82
		score += effect_score
	return score

func _best_potion_option(options: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -999999.0
	for option in options:
		var potion: Dictionary = option
		var score: float = _potion_score(potion)
		if score > best_score:
			best_score = score
			best = potion
	return best

func _potion_score(potion: Dictionary) -> float:
	var score := 0.0
	match str(potion.get("rarity", "common")):
		"rare":
			score += 3.0
		"uncommon":
			score += 1.5
	for effect in potion.get("effects", []):
		var effect_dict: Dictionary = effect
		match str(effect_dict.get("type", "")):
			"damage":
				score += float(int(effect_dict.get("amount", 0))) * (1.5 if str(effect_dict.get("target", "")) == "all_enemies" else 1.0)
			"block", "heal":
				score += float(int(effect_dict.get("amount", 0))) * 1.1
			"draw":
				score += float(int(effect_dict.get("amount", 0))) * 2.3
			"gain_energy":
				score += float(int(effect_dict.get("amount", 0))) * 3.0
			"gain_momentum":
				score += float(int(effect_dict.get("amount", 0))) * 1.5
			"apply_status":
				score += _status_score(effect_dict)
	return score

func _card_available_for_character(card: Dictionary, character_id: String) -> bool:
	var character_ids: Array = card.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(character_id):
		return false
	var pool_tags: Array = card.get("pool_tags", [])
	if pool_tags.is_empty():
		return true
	var character_tags: Array = _character_config(character_id).get("reward_pool_tags", ["shared", character_id])
	for tag in pool_tags:
		if character_tags.has(str(tag)):
			return true
	return false

func _relic_available_for_character(relic: Dictionary, character_id: String) -> bool:
	var character_ids: Array = relic.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(character_id):
		return false
	var pool_tags: Array = relic.get("pool_tags", [])
	if pool_tags.is_empty():
		return true
	var character_tags: Array = _character_config(character_id).get("reward_pool_tags", ["shared", character_id])
	for tag in pool_tags:
		if character_tags.has(str(tag)):
			return true
	return false

func _has_empty_potion_slot(state: Dictionary) -> bool:
	var character: Dictionary = _character_config(str(state.get("character_id", "")))
	return (state.get("potion_ids", []) as Array).size() < int(character.get("potion_slots", 2))

func _remove_card_price(remove_count: int) -> int:
	var shop_config: Dictionary = economy_data.get("shop", {})
	return int(shop_config.get("remove_card_price", 50)) + max(0, remove_count) * max(0, int(shop_config.get("remove_card_price_increase", 25)))

func _card_price(card: Dictionary) -> int:
	var prices: Dictionary = economy_data.get("shop", {}).get("card_prices", {})
	var rarity: String = str(card.get("rarity", "common"))
	return int(prices.get(rarity, prices.get("common", 50)))

func _potion_price(potion: Dictionary) -> int:
	var prices: Dictionary = economy_data.get("shop", {}).get("potion_prices", {})
	var rarity: String = str(potion.get("rarity", "common"))
	return int(prices.get(rarity, prices.get("common", 35)))

func _deck_entry_card_score(entry: String, character_id: String) -> float:
	var card: Dictionary = _card_by_id(_base_card_id(entry))
	if card.is_empty():
		return 0.0
	var score: float = _card_reward_score(card, character_id)
	if entry.ends_with("+"):
		var upgrade: Dictionary = card.get("upgrade", {})
		if upgrade.is_empty():
			score += 2.0
		else:
			var upgraded: Dictionary = card.duplicate(true)
			for key in upgrade.keys():
				upgraded[key] = upgrade[key]
			score = _card_reward_score(upgraded, character_id)
	return score

func _worst_deck_card_index(deck_ids: Array) -> int:
	var worst_index := -1
	var worst_score := 999999.0
	for i in range(deck_ids.size()):
		var card: Dictionary = _card_by_id(_base_card_id(str(deck_ids[i])))
		if card.is_empty():
			continue
		var score: float = _deck_entry_card_score(str(deck_ids[i]), "")
		if str(card.get("rarity", "")) == "starter":
			score -= 2.0
		if score < worst_score:
			worst_score = score
			worst_index = i
	return worst_index

func _best_upgrade_index(deck_ids: Array) -> int:
	var best_index := -1
	var best_delta := -999999.0
	for i in range(deck_ids.size()):
		var entry: String = str(deck_ids[i])
		if entry.ends_with("+"):
			continue
		var card: Dictionary = _card_by_id(entry)
		var upgrade: Dictionary = card.get("upgrade", {})
		if card.is_empty() or upgrade.is_empty():
			continue
		var upgraded: Dictionary = card.duplicate(true)
		for key in upgrade.keys():
			upgraded[key] = upgrade[key]
		var delta: float = _card_reward_score(upgraded, "") - _card_reward_score(card, "")
		if delta > best_delta:
			best_delta = delta
			best_index = i
	return best_index

func _card_by_id(card_id: String) -> Dictionary:
	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		if str(card_dict.get("id", "")) == card_id:
			return card_dict
	return {}

func _relic_by_id(relic_id: String) -> Dictionary:
	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		if str(relic_dict.get("id", "")) == relic_id:
			return relic_dict
	return {}

func _potion_config(potion_id: String) -> Dictionary:
	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		if str(potion_dict.get("id", "")) == potion_id:
			return potion_dict
	return {}

func _compare_content_by_id(left, right) -> bool:
	var left_dict: Dictionary = left
	var right_dict: Dictionary = right
	return str(left_dict.get("id", "")) < str(right_dict.get("id", ""))

func _deterministic_index(seed_text: String, size: int) -> int:
	if size <= 0:
		return 0
	var hash_value: int = seed_text.hash()
	if hash_value < 0:
		hash_value = -hash_value
	return hash_value % size

func _aggregate_case(character: Dictionary, challenge: Dictionary, encounter: Dictionary, runs: Array) -> Dictionary:
	var wins := 0
	var losses := 0
	var timeouts := 0
	var total_turns := 0
	var total_hp_remaining := 0
	var total_hp_lost := 0
	var total_enemy_hp_removed := 0
	var total_cards_played := 0
	var min_hp_remaining := 999999
	var max_turns_seen := 0

	for run in runs:
		var run_dict: Dictionary = run
		if bool(run_dict.get("won", false)):
			wins += 1
		if bool(run_dict.get("lost", false)):
			losses += 1
		if bool(run_dict.get("timeout", false)):
			timeouts += 1
		total_turns += int(run_dict.get("turns", 0))
		total_hp_remaining += int(run_dict.get("player_hp_remaining", 0))
		total_hp_lost += int(run_dict.get("player_hp_lost", 0))
		total_enemy_hp_removed += int(run_dict.get("enemy_hp_removed", 0))
		total_cards_played += int(run_dict.get("cards_played", 0))
		min_hp_remaining = min(min_hp_remaining, int(run_dict.get("player_hp_remaining", 0)))
		max_turns_seen = max(max_turns_seen, int(run_dict.get("turns", 0)))

	var count: int = max(1, runs.size())
	var win_rate: float = float(wins) / float(count)
	var loss_rate: float = float(losses) / float(count)
	var timeout_rate: float = float(timeouts) / float(count)
	var case := {
		"character_id": str(character.get("id", "")),
		"character_name": str(character.get("name", character.get("id", ""))),
		"challenge_level": int(challenge.get("level", 0)),
		"challenge_name": str(challenge.get("short_name", challenge.get("name", ""))),
		"challenge_modifiers": challenge.get("modifiers", {}).duplicate(true),
		"encounter_id": str(encounter.get("id", "")),
		"encounter_name": str(encounter.get("name", encounter.get("id", ""))),
		"encounter_tier": str(encounter.get("tier", "normal")),
		"runs": count,
		"wins": wins,
		"losses": losses,
		"timeouts": timeouts,
		"win_rate": win_rate,
		"loss_rate": loss_rate,
		"timeout_rate": timeout_rate,
		"avg_turns": _rounded_rate(float(total_turns) / float(count)),
		"max_turns_seen": max_turns_seen,
		"avg_player_hp_remaining": _rounded_rate(float(total_hp_remaining) / float(count)),
		"avg_player_hp_lost": _rounded_rate(float(total_hp_lost) / float(count)),
		"min_player_hp_remaining": min_hp_remaining,
		"avg_enemy_hp_removed": _rounded_rate(float(total_enemy_hp_removed) / float(count)),
		"avg_cards_played": _rounded_rate(float(total_cards_played) / float(count))
	}
	var chapter_id: String = _chapter_id_for_encounter(str(encounter.get("id", "")))
	var pressure_contract: Dictionary = numerical_tree_data.get("pressure_contract", {})
	var tier: String = str(encounter.get("tier", "normal"))
	var tier_targets: Dictionary = pressure_contract.get("single_encounter_tier_targets", {}).get(tier, {}).duplicate(true)
	var expected_turns: Array = numerical_tree_data.get("monsters", {}).get("chapter_targets", {}).get(chapter_id, {}).get(tier, {}).get("expected_turns", [0, 999])
	tier_targets["tier"] = tier
	tier_targets["minimum_samples"] = int(pressure_contract.get("minimum_iterations", 64))
	tier_targets["expected_turns_min"] = float(expected_turns[0])
	tier_targets["expected_turns_max"] = float(expected_turns[1])
	var pressure_metrics: Dictionary = NumericalPressureMetricsScript.aggregate_runs(runs, tier_targets)
	case["chapter_id"] = chapter_id
	case["loadout_profile"] = "starter_deck_relics"
	case["strategy_profile"] = "current-greedy"
	case["pressure_contract_version"] = int(pressure_contract.get("schema_version", 0))
	case["expected_turns_min"] = int(expected_turns[0])
	case["expected_turns_max"] = int(expected_turns[1])
	for key in ["pressure_gate_eligible", "zero_damage_win_count", "perfect_win_rate", "hp_loss_p50", "hp_loss_p90", "turn_sample_count", "turns_p50", "turns_p90", "cards_played_per_turn", "risk_flags", "risk_flag"]:
		case[key] = pressure_metrics.get(key)
	return case

func _build_report_summary(cases: Array) -> Dictionary:
	var flagged := 0
	var total_win_rate := 0.0
	for case in cases:
		var case_dict: Dictionary = case
		total_win_rate += float(case_dict.get("win_rate", 0.0))
		if str(case_dict.get("risk_flag", "ok")) != "ok":
			flagged += 1
	var case_count: int = max(1, cases.size())
	return {
		"average_case_win_rate": _rounded_rate(total_win_rate / float(case_count)),
		"flagged_case_count": flagged,
		"ok_case_count": cases.size() - flagged
	}

func _aggregate_campaign_case(character: Dictionary, challenge: Dictionary, runs: Array) -> Dictionary:
	var wins := 0
	var total_chapters := 0
	var total_nodes := 0
	var total_combats := 0
	var total_elites := 0
	var total_bosses := 0
	var total_turns := 0
	var total_cards_played := 0
	var total_final_hp := 0
	var total_final_gold := 0
	var total_deck_size := 0
	var total_relic_count := 0
	var total_cards_added := 0
	var total_cards_removed := 0
	var total_cards_upgraded := 0
	var total_relics_added := 0
	var total_potions_used := 0
	var failure_reasons: Dictionary = {}
	var failure_points: Dictionary = {}
	var failure_node_types: Dictionary = {}
	var failure_encounters: Dictionary = {}

	for run in runs:
		var run_dict: Dictionary = run
		if bool(run_dict.get("won", false)):
			wins += 1
		total_chapters += int(run_dict.get("chapters_completed", 0))
		total_nodes += int(run_dict.get("nodes_completed", 0))
		total_combats += int(run_dict.get("combats_won", 0))
		total_elites += int(run_dict.get("elites_won", 0))
		total_bosses += int(run_dict.get("bosses_won", 0))
		total_turns += int(run_dict.get("turns", 0))
		total_cards_played += int(run_dict.get("cards_played", 0))
		total_final_hp += int(run_dict.get("final_hp", 0))
		total_final_gold += int(run_dict.get("final_gold", 0))
		total_deck_size += int(run_dict.get("final_deck_size", 0))
		total_relic_count += int(run_dict.get("final_relic_count", 0))
		total_cards_added += int(run_dict.get("cards_added", 0))
		total_cards_removed += int(run_dict.get("cards_removed", 0))
		total_cards_upgraded += int(run_dict.get("cards_upgraded", 0))
		total_relics_added += int(run_dict.get("relics_added", 0))
		total_potions_used += int(run_dict.get("potions_used", 0))
		if not bool(run_dict.get("won", false)):
			var reason: String = str(run_dict.get("failed_reason", "unknown"))
			var point: String = str(run_dict.get("failed_at", "unknown"))
			var node_type: String = str(run_dict.get("failed_node_type", "unknown"))
			var encounter_id: String = str(run_dict.get("failed_encounter_id", ""))
			failure_reasons[reason] = int(failure_reasons.get(reason, 0)) + 1
			failure_points[point] = int(failure_points.get(point, 0)) + 1
			failure_node_types[node_type] = int(failure_node_types.get(node_type, 0)) + 1
			if not encounter_id.is_empty():
				failure_encounters[encounter_id] = int(failure_encounters.get(encounter_id, 0)) + 1

	var count: int = max(1, runs.size())
	var case := {
		"character_id": str(character.get("id", "")),
		"character_name": str(character.get("name", character.get("id", ""))),
		"challenge_level": int(challenge.get("level", 0)),
		"challenge_name": str(challenge.get("short_name", challenge.get("name", ""))),
		"challenge_modifiers": challenge.get("modifiers", {}).duplicate(true),
		"runs": count,
		"wins": wins,
		"losses": count - wins,
		"win_rate": _rounded_rate(float(wins) / float(count)),
		"avg_chapters_completed": _rounded_rate(float(total_chapters) / float(count)),
		"avg_nodes_completed": _rounded_rate(float(total_nodes) / float(count)),
		"avg_combats_won": _rounded_rate(float(total_combats) / float(count)),
		"avg_elites_won": _rounded_rate(float(total_elites) / float(count)),
		"avg_bosses_won": _rounded_rate(float(total_bosses) / float(count)),
		"avg_turns": _rounded_rate(float(total_turns) / float(count)),
		"avg_cards_played": _rounded_rate(float(total_cards_played) / float(count)),
		"avg_final_hp": _rounded_rate(float(total_final_hp) / float(count)),
		"avg_final_gold": _rounded_rate(float(total_final_gold) / float(count)),
		"avg_final_deck_size": _rounded_rate(float(total_deck_size) / float(count)),
		"avg_final_relic_count": _rounded_rate(float(total_relic_count) / float(count)),
		"avg_cards_added": _rounded_rate(float(total_cards_added) / float(count)),
		"avg_cards_removed": _rounded_rate(float(total_cards_removed) / float(count)),
		"avg_cards_upgraded": _rounded_rate(float(total_cards_upgraded) / float(count)),
		"avg_relics_added": _rounded_rate(float(total_relics_added) / float(count)),
		"avg_potions_used": _rounded_rate(float(total_potions_used) / float(count)),
		"failure_reasons": failure_reasons,
		"failure_points": failure_points,
		"failure_node_types": failure_node_types,
		"failure_encounters": failure_encounters,
		"win_iteration_indices": _campaign_win_iteration_indices(runs),
		"card_telemetry": _aggregate_campaign_card_telemetry(runs),
		"sample_runs": _sample_campaign_runs(runs)
	}
	case["risk_flag"] = _campaign_risk_flag(case)
	return case

func _campaign_win_iteration_indices(runs: Array) -> Array:
	var indices: Array = []
	for iteration in range(runs.size()):
		var run: Dictionary = runs[iteration]
		if bool(run.get("won", false)):
			indices.append(iteration)
	return indices

func _aggregate_campaign_card_telemetry(runs: Array) -> Array:
	var rows_by_id: Dictionary = {}
	var total_wins := 0
	for run_value in runs:
		var run: Dictionary = run_value
		var won := bool(run.get("won", false))
		if won:
			total_wins += 1
		var offers: Dictionary = run.get("card_offer_counts_by_id", {})
		var acquisitions: Dictionary = run.get("card_acquisition_counts_by_id", {})
		var acquisition_sources: Dictionary = run.get("card_acquisition_sources_by_id", {})
		var removals: Dictionary = run.get("card_removal_counts_by_id", {})
		var upgrades: Dictionary = run.get("card_upgrade_counts_by_id", {})
		var plays: Dictionary = run.get("card_play_counts_by_id", {})
		var observed_ids: Dictionary = {}
		for count_map in [offers, acquisitions, removals, upgrades, plays]:
			for card_id_value in count_map.keys():
				observed_ids[str(card_id_value)] = true
		for card_id_value in acquisition_sources.keys():
			observed_ids[str(card_id_value)] = true

		for card_id_value in observed_ids.keys():
			var card_id := str(card_id_value)
			if card_id.is_empty():
				continue
			var row: Dictionary = rows_by_id.get(card_id, _empty_card_telemetry_row(card_id))
			var acquisition_count := int(acquisitions.get(card_id, 0))
			var play_count := int(plays.get(card_id, 0))
			row["offers"] = int(row.get("offers", 0)) + int(offers.get(card_id, 0))
			row["acquisitions"] = int(row.get("acquisitions", 0)) + acquisition_count
			row["removals"] = int(row.get("removals", 0)) + int(removals.get(card_id, 0))
			row["upgrades"] = int(row.get("upgrades", 0)) + int(upgrades.get(card_id, 0))
			row["plays"] = int(row.get("plays", 0)) + play_count
			if acquisition_count > 0:
				row["acquisition_runs"] = int(row.get("acquisition_runs", 0)) + 1
				if won:
					row["wins_when_acquired"] = int(row.get("wins_when_acquired", 0)) + 1
				else:
					row["losses_when_acquired"] = int(row.get("losses_when_acquired", 0)) + 1
			if play_count > 0:
				row["runs_played"] = int(row.get("runs_played", 0)) + 1
				if won:
					row["wins_when_played"] = int(row.get("wins_when_played", 0)) + 1
				else:
					row["losses_when_played"] = int(row.get("losses_when_played", 0)) + 1
			var row_sources: Dictionary = row.get("acquisition_sources", {})
			var run_sources: Dictionary = acquisition_sources.get(card_id, {})
			for source_value in run_sources.keys():
				_increment_count(row_sources, str(source_value), int(run_sources.get(source_value, 0)))
			row["acquisition_sources"] = row_sources
			rows_by_id[card_id] = row

	var run_count: int = runs.size()
	var total_losses: int = run_count - total_wins
	var rows: Array = []
	for card_id_value in rows_by_id.keys():
		var row: Dictionary = rows_by_id[card_id_value]
		var offers := int(row.get("offers", 0))
		var acquisitions := int(row.get("acquisitions", 0))
		var acquisition_runs := int(row.get("acquisition_runs", 0))
		var runs_played := int(row.get("runs_played", 0))
		var wins_when_acquired := int(row.get("wins_when_acquired", 0))
		var losses_when_acquired := int(row.get("losses_when_acquired", 0))
		var wins_when_played := int(row.get("wins_when_played", 0))
		var losses_when_played := int(row.get("losses_when_played", 0))
		var sources: Dictionary = row.get("acquisition_sources", {})
		var offered_acquisitions := int(sources.get("combat_reward", 0)) + int(sources.get("shop", 0))
		row["offered_acquisitions"] = offered_acquisitions
		row["acquisition_rate_per_offer"] = _rounded_rate(float(offered_acquisitions) / float(offers)) if offers > 0 else 0.0
		row["win_rate_when_acquired"] = _rounded_rate(float(wins_when_acquired) / float(acquisition_runs)) if acquisition_runs > 0 else 0.0
		row["win_rate_when_played"] = _rounded_rate(float(wins_when_played) / float(runs_played)) if runs_played > 0 else 0.0
		var runs_not_acquired: int = max(0, run_count - acquisition_runs)
		var wins_not_acquired: int = max(0, total_wins - wins_when_acquired)
		var losses_not_acquired: int = max(0, total_losses - losses_when_acquired)
		row["runs_not_acquired"] = runs_not_acquired
		row["wins_when_not_acquired"] = wins_not_acquired
		row["losses_when_not_acquired"] = losses_not_acquired
		row["win_rate_when_not_acquired"] = _rounded_rate(float(wins_not_acquired) / float(runs_not_acquired)) if runs_not_acquired > 0 else 0.0
		row["acquisition_comparison_available"] = acquisition_runs > 0 and runs_not_acquired > 0
		row["win_rate_lift_when_acquired"] = _rounded_rate(float(row["win_rate_when_acquired"]) - float(row["win_rate_when_not_acquired"])) if bool(row["acquisition_comparison_available"]) else 0.0
		var runs_not_played: int = max(0, run_count - runs_played)
		var wins_not_played: int = max(0, total_wins - wins_when_played)
		var losses_not_played: int = max(0, total_losses - losses_when_played)
		row["runs_not_played"] = runs_not_played
		row["wins_when_not_played"] = wins_not_played
		row["losses_when_not_played"] = losses_not_played
		row["win_rate_when_not_played"] = _rounded_rate(float(wins_not_played) / float(runs_not_played)) if runs_not_played > 0 else 0.0
		row["play_comparison_available"] = runs_played > 0 and runs_not_played > 0
		row["win_rate_lift_when_played"] = _rounded_rate(float(row["win_rate_when_played"]) - float(row["win_rate_when_not_played"])) if bool(row["play_comparison_available"]) else 0.0
		rows.append(row)
	rows.sort_custom(_compare_content_by_id)
	return rows

func _empty_card_telemetry_row(card_id: String) -> Dictionary:
	return {
		"id": card_id,
		"offers": 0,
		"acquisitions": 0,
		"offered_acquisitions": 0,
		"acquisition_sources": {},
		"acquisition_runs": 0,
		"removals": 0,
		"upgrades": 0,
		"runs_played": 0,
		"plays": 0,
		"wins_when_acquired": 0,
		"losses_when_acquired": 0,
		"wins_when_played": 0,
		"losses_when_played": 0
	}

func _sample_campaign_runs(runs: Array) -> Array:
	var samples: Array = []
	for run in runs:
		var run_dict: Dictionary = run
		if not bool(run_dict.get("won", false)):
			samples.append(_summarize_campaign_run(run_dict))
		if samples.size() >= 3:
			return samples
	for run in runs:
		var run_dict: Dictionary = run
		if bool(run_dict.get("won", false)):
			samples.append(_summarize_campaign_run(run_dict))
		if samples.size() >= 3:
			return samples
	return samples

func _summarize_campaign_run(run: Dictionary) -> Dictionary:
	return {
		"won": bool(run.get("won", false)),
		"chapters_completed": int(run.get("chapters_completed", 0)),
		"nodes_completed": int(run.get("nodes_completed", 0)),
		"combats_won": int(run.get("combats_won", 0)),
		"bosses_won": int(run.get("bosses_won", 0)),
		"turns": int(run.get("turns", 0)),
		"cards_played": int(run.get("cards_played", 0)),
		"final_hp": int(run.get("final_hp", 0)),
		"final_gold": int(run.get("final_gold", 0)),
		"failed_at": str(run.get("failed_at", "")),
		"failed_reason": str(run.get("failed_reason", "")),
		"failed_node_type": str(run.get("failed_node_type", "")),
		"failed_encounter_id": str(run.get("failed_encounter_id", "")),
		"final_deck_ids": run.get("final_deck_ids", []),
		"final_relic_ids": run.get("final_relic_ids", []),
		"final_potion_ids": run.get("final_potion_ids", []),
		"skill_book_id": str(run.get("skill_book_id", "")),
		"deck_mastery_id": str(run.get("deck_mastery_id", "")),
		"events_choice_ids": run.get("events_choice_ids", []),
		"cards_added_ids": run.get("cards_added_ids", []),
		"cards_removed_ids": run.get("cards_removed_ids", []),
		"cards_upgraded_ids": run.get("cards_upgraded_ids", []),
		"card_offer_counts_by_id": run.get("card_offer_counts_by_id", {}),
		"card_acquisition_counts_by_id": run.get("card_acquisition_counts_by_id", {}),
		"card_acquisition_sources_by_id": run.get("card_acquisition_sources_by_id", {}),
		"card_removal_counts_by_id": run.get("card_removal_counts_by_id", {}),
		"card_upgrade_counts_by_id": run.get("card_upgrade_counts_by_id", {}),
		"card_play_counts_by_id": run.get("card_play_counts_by_id", {}),
		"relics_added_ids": run.get("relics_added_ids", []),
		"potions_gained_ids": run.get("potions_gained_ids", []),
		"potions_used_ids": run.get("potions_used_ids", []),
		"path": run.get("path", [])
	}

func _build_campaign_report_summary(cases: Array) -> Dictionary:
	var flagged := 0
	var total_win_rate := 0.0
	var total_chapters := 0.0
	var cases_by_challenge: Dictionary = {}
	for case in cases:
		var case_dict: Dictionary = case
		total_win_rate += float(case_dict.get("win_rate", 0.0))
		total_chapters += float(case_dict.get("avg_chapters_completed", 0.0))
		if str(case_dict.get("risk_flag", "ok")) != "ok":
			flagged += 1
		var challenge_level: int = int(case_dict.get("challenge_level", 0))
		if not cases_by_challenge.has(challenge_level):
			cases_by_challenge[challenge_level] = []
		(cases_by_challenge[challenge_level] as Array).append(case_dict)
	var count: int = max(1, cases.size())
	var target_issues: Array = []
	var challenge_rows: Array = []
	var targets: Dictionary = numerical_tree_data.get("campaign_targets", {})
	var minimum_iterations: int = int(targets.get("minimum_iterations_for_hard_gate", 64))
	var max_character_gap: float = float(targets.get("max_character_win_rate_gap", 1.0))
	for challenge_level_value in cases_by_challenge.keys():
		var challenge_level: int = int(challenge_level_value)
		var challenge_cases: Array = cases_by_challenge.get(challenge_level, [])
		var average_rate := 0.0
		var minimum_rate := 1.0
		var maximum_rate := 0.0
		var enough_samples := true
		for case_value in challenge_cases:
			var case_dict: Dictionary = case_value
			var rate: float = float(case_dict.get("win_rate", 0.0))
			average_rate += rate
			minimum_rate = min(minimum_rate, rate)
			maximum_rate = max(maximum_rate, rate)
			if int(case_dict.get("runs", 0)) < minimum_iterations:
				enough_samples = false
		average_rate /= float(max(1, challenge_cases.size()))
		var target_range: Array = _campaign_win_rate_target(challenge_level)
		var gap: float = maximum_rate - minimum_rate
		var row_issues: Array = []
		if not enough_samples:
			row_issues.append("insufficient_samples")
		elif target_range.size() >= 2:
			if average_rate < float(target_range[0]):
				row_issues.append("average_win_rate_low")
			elif average_rate > float(target_range[1]):
				row_issues.append("average_win_rate_high")
			if challenge_cases.size() > 1 and gap > max_character_gap:
				row_issues.append("character_win_rate_gap_high")
		for issue_value in row_issues:
			target_issues.append("challenge_%d:%s" % [challenge_level, str(issue_value)])
		challenge_rows.append({
			"challenge_level": challenge_level,
			"case_count": challenge_cases.size(),
			"average_win_rate": _rounded_rate(average_rate),
			"target_win_rate_range": target_range,
			"character_win_rate_gap": _rounded_rate(gap),
			"max_character_win_rate_gap": max_character_gap,
			"minimum_iterations_required": minimum_iterations,
			"enough_samples": enough_samples,
			"issues": row_issues
		})
	challenge_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("challenge_level", 0)) < int(b.get("challenge_level", 0)))
	var monotonic_tolerance: float = float(targets.get("challenge_monotonic_tolerance", 0.0))
	for row_index in range(1, challenge_rows.size()):
		var previous_row: Dictionary = challenge_rows[row_index - 1]
		var current_row: Dictionary = challenge_rows[row_index]
		if not bool(previous_row.get("enough_samples", false)) or not bool(current_row.get("enough_samples", false)):
			continue
		if float(current_row.get("average_win_rate", 0.0)) > float(previous_row.get("average_win_rate", 0.0)) + monotonic_tolerance:
			var monotonic_issue := "challenge_%d:win_rate_not_monotonic" % int(current_row.get("challenge_level", 0))
			target_issues.append(monotonic_issue)
			(current_row.get("issues", []) as Array).append("win_rate_not_monotonic")
	return {
		"average_campaign_win_rate": _rounded_rate(total_win_rate / float(count)),
		"average_chapters_completed": _rounded_rate(total_chapters / float(count)),
		"flagged_case_count": flagged,
		"ok_case_count": cases.size() - flagged,
		"target_pass": target_issues.is_empty(),
		"target_issues": target_issues,
		"challenge_targets": challenge_rows
	}

func _campaign_risk_flag(case: Dictionary) -> String:
	var win_rate: float = float(case.get("win_rate", 0.0))
	var avg_chapters: float = float(case.get("avg_chapters_completed", 0.0))
	var targets: Dictionary = numerical_tree_data.get("campaign_targets", {})
	var minimum_iterations: int = int(targets.get("minimum_iterations_for_hard_gate", 64))
	if int(case.get("runs", 0)) < minimum_iterations:
		return "campaign_insufficient_samples"
	var target_range: Array = _campaign_win_rate_target(int(case.get("challenge_level", 0)))
	var individual_tolerance: float = float(targets.get("individual_win_rate_tolerance", 0.0))
	if target_range.size() >= 2:
		if win_rate < float(target_range[0]) - individual_tolerance:
			return "campaign_win_rate_low"
		if win_rate > float(target_range[1]) + individual_tolerance:
			return "campaign_win_rate_high"
	var economy_targets: Dictionary = numerical_tree_data.get("economy", {})
	var tolerance: float = float(economy_targets.get("campaign_metric_tolerance", 0.0))
	var gold_range: Array = economy_targets.get("expected_final_gold_range", [])
	var avg_gold: float = float(case.get("avg_final_gold", 0.0))
	if gold_range.size() >= 2:
		if avg_gold < float(gold_range[0]) - tolerance:
			return "campaign_gold_starved"
		if avg_gold > float(gold_range[1]) + tolerance:
			return "campaign_gold_hoarding"
	var deck_range: Array = economy_targets.get("expected_final_deck_size_range", [])
	var avg_deck_size: float = float(case.get("avg_final_deck_size", 0.0))
	if deck_range.size() >= 2:
		if avg_deck_size < float(deck_range[0]) - tolerance:
			return "campaign_deck_too_thin"
		if avg_deck_size > float(deck_range[1]) + tolerance:
			return "campaign_deck_bloat"
	var losses: int = int(case.get("losses", 0))
	if losses > 0:
		var peak_failure_count := 0
		for failure_count_value in (case.get("failure_encounters", {}) as Dictionary).values():
			peak_failure_count = max(peak_failure_count, int(failure_count_value))
		var peak_share: float = float(peak_failure_count) / float(losses)
		if peak_share > float(targets.get("single_failure_encounter_share_max", 1.0)):
			return "campaign_failure_concentration"
	if win_rate < 0.05 and avg_chapters < 1.0:
		return "campaign_fails_chapter_one"
	return "ok"

func _campaign_win_rate_target(challenge_level: int) -> Array:
	var targets: Dictionary = numerical_tree_data.get("campaign_targets", {})
	match challenge_level:
		0:
			return targets.get("normal_win_rate_range", [])
		1:
			return targets.get("challenge_1_win_rate_range", [])
		2:
			return targets.get("challenge_2_win_rate_range", [])
		3:
			return targets.get("challenge_3_win_rate_range", [])
		_:
			return []

func _risk_flag(case: Dictionary) -> String:
	var tier: String = str(case.get("encounter_tier", "normal"))
	var win_rate: float = float(case.get("win_rate", 0.0))
	var timeout_rate: float = float(case.get("timeout_rate", 0.0))
	var avg_turns: float = float(case.get("avg_turns", 0.0))
	if timeout_rate > 0.0:
		return "timeout_check"
	if tier == "normal" and win_rate < 0.70:
		return "normal_too_lethal"
	if tier == "elite" and win_rate < 0.45:
		return "elite_too_lethal"
	if tier == "boss" and win_rate < 0.25:
		return "boss_too_lethal"
	if tier == "normal" and avg_turns > 9.0:
		return "normal_too_slow"
	if tier == "elite" and avg_turns > 14.0:
		return "elite_too_slow"
	if tier == "boss" and avg_turns > 20.0:
		return "boss_too_slow"
	return "ok"

func save_report(report: Dictionary, output_path: String) -> Error:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(report, "\t"))
	return OK

func _all_character_ids() -> Array:
	var result: Array = []
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		var character_id: String = str(character_dict.get("id", ""))
		if not character_id.is_empty():
			result.append(character_id)
	return result

func _all_challenge_levels() -> Array:
	var result: Array = []
	for level in challenge_data.get("levels", []):
		var level_dict: Dictionary = level
		result.append(int(level_dict.get("level", 0)))
	return result

func _all_encounter_ids() -> Array:
	var result: Array = []
	for encounter in encounter_data.get("encounters", []):
		var encounter_dict: Dictionary = encounter
		var encounter_id: String = str(encounter_dict.get("id", ""))
		if not encounter_id.is_empty():
			result.append(encounter_id)
	return result

func _chapter_sequence() -> Array:
	var sequence: Array = map_generation_data.get("chapter_sequence", [])
	if sequence.is_empty():
		return ["chapter_one"]
	return sequence

func _chapter_id_for_encounter(encounter_id: String) -> String:
	for chapter_id_value in _chapter_sequence():
		var chapter_id: String = str(chapter_id_value)
		var encounter_by_type: Dictionary = map_generation_data.get(chapter_id, {}).get("encounter_by_type", {})
		for encounter_ids_value in encounter_by_type.values():
			if (encounter_ids_value as Array).has(encounter_id):
				return chapter_id
	return ""

func _option_or_default(options: Dictionary, key: String, default_value: Array) -> Array:
	var value = options.get(key, default_value)
	return value if value is Array and not value.is_empty() else default_value

func _character_config(character_id: String) -> Dictionary:
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		if str(character_dict.get("id", "")) == character_id:
			return character_dict
	return player_data.get("player", {})

func _challenge_config(level: int) -> Dictionary:
	for challenge in challenge_data.get("levels", []):
		var challenge_dict: Dictionary = challenge
		if int(challenge_dict.get("level", 0)) == level:
			return challenge_dict
	return {"level": level, "short_name": "挑战 %d" % level, "modifiers": {}}

func _encounter_config(encounter_id: String) -> Dictionary:
	for encounter in encounter_data.get("encounters", []):
		var encounter_dict: Dictionary = encounter
		if str(encounter_dict.get("id", "")) == encounter_id:
			return encounter_dict
	return {"id": encounter_id, "name": encounter_id, "tier": "normal"}

func _starting_hp_for_character(character_id: String, modifiers: Dictionary) -> int:
	var character: Dictionary = _character_config(character_id)
	var starting_hp: int = int(character.get("starting_hp", character.get("max_hp", 72)))
	return max(1, starting_hp - max(0, int(modifiers.get("player_starting_hp_loss", 0))))

func _base_card_id(entry: String) -> String:
	return entry.substr(0, entry.length() - 1) if entry.ends_with("+") else entry

func _total_enemy_max_hp(combat) -> int:
	var total := 0
	for enemy in combat.enemies:
		var enemy_dict: Dictionary = enemy
		total += int(enemy_dict.get("max_hp", enemy_dict.get("hp", 0)))
	return total

func _total_enemy_hp(combat) -> int:
	var total := 0
	for enemy in combat.enemies:
		var enemy_dict: Dictionary = enemy
		total += max(0, int(enemy_dict.get("hp", 0)))
	return total

func _status_amount(statuses: Dictionary, status_id: String) -> int:
	return int(statuses.get(status_id, 0))

func _stable_text_seed(text: String) -> int:
	var value: int = 2166136261
	for i in range(text.length()):
		value = int((value ^ text.unicode_at(i)) * 16777619) & 0x7fffffff
	return max(1, value)

func _rounded_rate(value: float) -> float:
	return snappedf(value, 0.001)
