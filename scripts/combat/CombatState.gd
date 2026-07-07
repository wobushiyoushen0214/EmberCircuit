class_name CombatState
extends RefCounted

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

signal changed

var cards_by_id: Dictionary = {}
var enemies_by_id: Dictionary = {}
var relics_by_id: Dictionary = {}
var encounters_by_id: Dictionary = {}

var player: Dictionary = {}
var enemies: Array = []
var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var owned_relic_ids: Array = []
var log_entries: Array[String] = []
var feedback_events: Array = []

var phase: String = "setup"
var turn: int = 0
var selected_encounter_id: String = "intro_patrol"
var attack_cards_played_this_turn: int = 0
var relic_used_this_turn: Dictionary = {}
var skill_block_bonus_percent: int = 0

func setup(
	card_data: Dictionary,
	enemy_data: Dictionary,
	relic_data: Dictionary,
	encounter_data: Dictionary,
	player_data: Dictionary,
	encounter_id: String = "intro_patrol",
	deck_override: Array = [],
	relic_override: Array = [],
	player_hp_override: int = -1
) -> void:
	cards_by_id = DataLoaderScript.index_by_id(card_data.get("cards", []))
	enemies_by_id = DataLoaderScript.index_by_id(enemy_data.get("enemies", []))
	relics_by_id = DataLoaderScript.index_by_id(relic_data.get("relics", []))
	encounters_by_id = DataLoaderScript.index_by_id(encounter_data.get("encounters", []))
	selected_encounter_id = encounter_id
	if relic_override.is_empty():
		owned_relic_ids = relic_data.get("starter_relics", []).duplicate(true)
	else:
		owned_relic_ids = relic_override.duplicate(true)

	var player_config: Dictionary = player_data.get("player", {})
	var starting_hp: int = int(player_config.get("starting_hp", 72))
	if player_hp_override >= 0:
		starting_hp = player_hp_override
	player = {
		"name": player_config.get("name", "余烬流亡者"),
		"hp": starting_hp,
		"max_hp": int(player_config.get("max_hp", 72)),
		"block": 0,
		"energy": int(player_config.get("max_energy", 3)),
		"max_energy": int(player_config.get("max_energy", 3)),
		"momentum": int(player_config.get("starting_momentum", 0)),
		"momentum_max": int(player_config.get("momentum_max", 6)),
		"statuses": {}
	}

	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	enemies.clear()
	log_entries.clear()
	feedback_events.clear()
	turn = 0
	phase = "setup"
	attack_cards_played_this_turn = 0
	relic_used_this_turn.clear()
	skill_block_bonus_percent = 0

	_apply_setup_relics()
	var deck_ids: Array = deck_override
	if deck_ids.is_empty():
		deck_ids = card_data.get("starter_deck", {}).get("cards", [])
	_build_starting_deck(deck_ids)
	_load_encounter(encounter_id)
	_roll_enemy_intents()
	_log("进入遭遇：%s" % encounters_by_id.get(encounter_id, {}).get("name", encounter_id))
	start_player_turn()
	_apply_relics("combat_start", {})
	emit_signal("changed")

func start_player_turn() -> void:
	if phase == "won" or phase == "lost":
		return

	turn += 1
	phase = "player"
	player["block"] = 0
	player["energy"] = int(player.get("max_energy", 3))
	attack_cards_played_this_turn = 0
	relic_used_this_turn.clear()
	_apply_burn_to_player()
	if phase == "lost":
		emit_signal("changed")
		return

	draw_cards(5)
	_log("第 %d 回合开始：抽 5 张牌，能量恢复到 %d。" % [turn, player["energy"]])
	_apply_relics("turn_start", {})
	emit_signal("changed")

func draw_cards(amount: int) -> void:
	for _i in range(amount):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				_log("抽牌堆和弃牌堆都为空。")
				return
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
			_log("弃牌堆洗回抽牌堆。")

		var card: Dictionary = draw_pile.pop_back()
		hand.append(card)
		_log("抽到：%s" % card.get("name", card.get("id", "未知卡牌")))

func can_play_card(hand_index: int) -> bool:
	if phase != "player":
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false
	var card: Dictionary = hand[hand_index]
	return int(card.get("cost", 0)) <= int(player.get("energy", 0))

func play_card(hand_index: int, target_index: int = -1) -> bool:
	if not can_play_card(hand_index):
		_log("无法打出这张牌。")
		emit_signal("changed")
		return false

	target_index = _normalize_target_index(target_index)
	var card: Dictionary = hand[hand_index]
	hand.remove_at(hand_index)
	player["energy"] = int(player["energy"]) - int(card.get("cost", 0))
	_log("打出 %s，剩余能量 %d。" % [card.get("name", card.get("id", "卡牌")), player["energy"]])

	_resolve_card(card, target_index)
	_apply_relics("card_played", {"card": card})

	if bool(card.get("exhaust", false)):
		exhaust_pile.append(card)
		_log("%s 被消耗。" % card.get("name", "卡牌"))
	else:
		discard_pile.append(card)

	_check_combat_end()
	emit_signal("changed")
	return true

func can_use_potion(potion: Dictionary) -> bool:
	if phase != "player":
		return false
	return not potion.is_empty()

func use_potion(potion: Dictionary, target_index: int = -1) -> bool:
	if not can_use_potion(potion):
		_log("无法使用药水。")
		emit_signal("changed")
		return false

	target_index = _normalize_target_index(target_index)
	_log("使用药水：%s。" % potion.get("name", potion.get("id", "药水")))
	_push_feedback("potion", "使用药水：%s" % potion.get("name", potion.get("id", "药水")), "", 0, "info")
	for effect in potion.get("effects", []):
		var effect_dict: Dictionary = effect
		_resolve_potion_effect(potion, effect_dict, target_index)

	_check_combat_end()
	emit_signal("changed")
	return true

func end_player_turn() -> void:
	if phase != "player":
		return

	while not hand.is_empty():
		discard_pile.append(hand.pop_back())

	_log("玩家结束回合，手牌进入弃牌堆。")
	phase = "enemy"
	_enemy_turn()
	_check_combat_end()
	if phase != "won" and phase != "lost":
		start_player_turn()
	emit_signal("changed")

func get_alive_enemies() -> Array:
	var alive: Array = []
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			alive.append(enemy)
	return alive

func is_won() -> bool:
	return phase == "won"

func is_lost() -> bool:
	return phase == "lost"

func consume_feedback_events() -> Array:
	var events := feedback_events.duplicate(true)
	feedback_events.clear()
	return events

func _build_starting_deck(card_ids: Array) -> void:
	for card_entry in card_ids:
		var card_key: String = str(card_entry)
		var upgraded: bool = card_key.ends_with("+")
		var card_id: String = card_key
		if upgraded:
			card_id = card_key.substr(0, card_key.length() - 1)
		if cards_by_id.has(card_id):
			var card: Dictionary = cards_by_id[card_id].duplicate(true)
			if upgraded:
				card = _apply_card_upgrade(card)
			draw_pile.append(card)
		else:
			_log("缺失初始牌：%s" % str(card_id))
	draw_pile.shuffle()

func _apply_card_upgrade(card: Dictionary) -> Dictionary:
	var upgrade: Dictionary = card.get("upgrade", {})
	if upgrade.is_empty():
		return card
	var upgraded_card: Dictionary = card.duplicate(true)
	upgraded_card["upgraded"] = true
	upgraded_card["name"] = "%s+" % str(card.get("name", card.get("id", "卡牌")))
	for key in upgrade.keys():
		upgraded_card[key] = upgrade[key]
	return upgraded_card

func _load_encounter(encounter_id: String) -> void:
	var encounter: Dictionary = encounters_by_id.get(encounter_id, {})
	for enemy_id in encounter.get("enemy_ids", []):
		var data: Dictionary = enemies_by_id.get(enemy_id, {})
		if data.is_empty():
			_log("缺失敌人：%s" % str(enemy_id))
			continue

		enemies.append({
			"id": data.get("id", enemy_id),
			"name": data.get("name", enemy_id),
			"hp": int(data.get("max_hp", 1)),
			"max_hp": int(data.get("max_hp", 1)),
			"block": 0,
			"statuses": {},
			"data": data,
			"intent_index": 0,
			"phase_index": -1,
			"phase_id": "",
			"phase_name": "",
			"phase_data": {},
			"current_action": {}
		})

func _roll_enemy_intents() -> void:
	for enemy in enemies:
		if int(enemy.get("hp", 0)) <= 0:
			enemy["current_action"] = {}
			continue
		var actions: Array = _enemy_actions(enemy)
		if actions.is_empty():
			enemy["current_action"] = {}
			continue
		var index := int(enemy.get("intent_index", 0)) % actions.size()
		enemy["current_action"] = actions[index]

func _advance_enemy_intent(enemy: Dictionary) -> void:
	var actions: Array = _enemy_actions(enemy)
	if actions.is_empty():
		return
	enemy["intent_index"] = int(enemy.get("intent_index", 0)) + 1
	var index := int(enemy.get("intent_index", 0)) % actions.size()
	enemy["current_action"] = actions[index]

func _enemy_actions(enemy: Dictionary) -> Array:
	var phase_data: Dictionary = enemy.get("phase_data", {})
	var phase_actions: Array = phase_data.get("actions", [])
	if not phase_actions.is_empty():
		return phase_actions
	return enemy.get("data", {}).get("actions", [])

func _enemy_turn() -> void:
	_log("敌人回合开始。")
	for enemy in enemies:
		if int(enemy.get("hp", 0)) <= 0:
			continue

		enemy["block"] = 0
		_apply_burn_to_enemy(enemy)
		if int(enemy.get("hp", 0)) <= 0:
			continue

		var action: Dictionary = enemy.get("current_action", {})
		_log("%s 执行意图：%s。" % [enemy.get("name", "敌人"), action.get("id", "无行动")])
		for effect in action.get("effects", []):
			_resolve_enemy_effect(enemy, effect)
			if phase == "lost":
				return
		_advance_enemy_intent(enemy)

	_roll_enemy_intents()

func _resolve_card(card: Dictionary, target_index: int) -> void:
	for effect in card.get("effects", []):
		if _effect_condition_failed(effect):
			continue

		var effect_type := str(effect.get("type", ""))
		match effect_type:
			"damage":
				_resolve_player_damage_effect(card, effect, target_index)
			"block":
				var amount := _calculate_block_amount(card, effect)
				_gain_player_block(amount)
			"draw":
				draw_cards(int(effect.get("amount", 0)))
			"gain_momentum":
				_gain_momentum(int(effect.get("amount", 0)))
			"lose_momentum":
				_lose_momentum(int(effect.get("amount", 0)))
			"gain_energy":
				_gain_energy(int(effect.get("amount", 0)))
			"apply_status":
				_apply_status_from_card(effect, target_index)
			"create_card":
				_create_card(str(effect.get("card_id", "")), str(effect.get("destination", "discard")), int(effect.get("amount", 1)))
			"damage_self":
				_lose_player_hp(int(effect.get("amount", 0)), "卡牌代价")
			_:
				_log("未实现的卡牌效果：%s" % effect_type)

func _resolve_potion_effect(potion: Dictionary, effect: Dictionary, target_index: int) -> void:
	var effect_type := str(effect.get("type", ""))
	match effect_type:
		"damage":
			var amount := int(effect.get("amount", 0))
			var hits := int(effect.get("hits", 1))
			var source := {
				"name": potion.get("name", "药水"),
				"type": "potion",
				"ignore_player_modifiers": true
			}
			var target_mode := str(effect.get("target", potion.get("target", "enemy")))
			if target_mode == "all_enemies":
				for enemy in enemies:
					if int(enemy.get("hp", 0)) > 0:
						for _i in range(hits):
							_damage_enemy(enemy, amount, source)
			else:
				var enemy := _get_enemy_at(target_index)
				if not enemy.is_empty():
					for _i in range(hits):
						_damage_enemy(enemy, amount, source)
		"block":
			_gain_player_block(int(effect.get("amount", 0)))
		"draw":
			draw_cards(int(effect.get("amount", 0)))
		"gain_momentum":
			_gain_momentum(int(effect.get("amount", 0)))
		"gain_energy":
			_gain_energy(int(effect.get("amount", 0)))
		"apply_status":
			_apply_status_from_potion(effect, target_index)
		"heal":
			_heal_player(int(effect.get("amount", 0)), str(potion.get("name", "药水")))
		_:
			_log("未实现的药水效果：%s" % effect_type)

func _resolve_player_damage_effect(card: Dictionary, effect: Dictionary, target_index: int) -> void:
	var base_amount := int(effect.get("amount", 0))
	var hits := int(effect.get("hits", 1))
	var extra_per_momentum := int(effect.get("extra_hit_per_momentum", 0))
	if extra_per_momentum > 0:
		hits += int(floor(float(player.get("momentum", 0)) / float(extra_per_momentum)))

	var bonus_per_momentum := int(effect.get("bonus_per_momentum", 0))
	if bonus_per_momentum > 0:
		base_amount += int(player.get("momentum", 0)) * bonus_per_momentum

	var target_mode := str(effect.get("target", card.get("target", "enemy")))
	if target_mode == "all_enemies":
		for enemy in enemies:
			if int(enemy.get("hp", 0)) > 0:
				for _i in range(hits):
					_damage_enemy(enemy, base_amount, card)
	else:
		var enemy := _get_enemy_at(target_index)
		if not enemy.is_empty():
			for _i in range(hits):
				_damage_enemy(enemy, base_amount, card)

	if bool(effect.get("consume_momentum", false)):
		_log("清空 %d 点势能。" % int(player.get("momentum", 0)))
		player["momentum"] = 0

func _resolve_enemy_effect(enemy: Dictionary, effect: Dictionary) -> void:
	var effect_type := str(effect.get("type", ""))
	match effect_type:
		"damage":
			var hits := int(effect.get("hits", 1))
			for _i in range(hits):
				_damage_player(int(effect.get("amount", 0)), enemy)
		"block":
			enemy["block"] = int(enemy.get("block", 0)) + int(effect.get("amount", 0))
			_log("%s 获得 %d 点护甲。" % [enemy.get("name", "敌人"), int(effect.get("amount", 0))])
		"apply_status":
			var target := str(effect.get("target", "player"))
			if target == "self":
				_add_status(enemy["statuses"], str(effect.get("status", "")), int(effect.get("amount", 0)))
				_log("%s 获得状态 %s x%d。" % [enemy.get("name", "敌人"), effect.get("status", ""), int(effect.get("amount", 0))])
			else:
				_add_status(player["statuses"], str(effect.get("status", "")), int(effect.get("amount", 0)))
				_log("玩家获得状态 %s x%d。" % [effect.get("status", ""), int(effect.get("amount", 0))])
		"create_card":
			_create_card(str(effect.get("card_id", "")), str(effect.get("destination", "discard")), int(effect.get("amount", 1)))
		_:
			_log("未实现的敌人效果：%s" % effect_type)

func _calculate_block_amount(card: Dictionary, effect: Dictionary) -> int:
	var amount := int(effect.get("amount", 0))
	if int(effect.get("bonus_if_momentum_at_least", -1)) >= 0 and int(player.get("momentum", 0)) >= int(effect.get("bonus_if_momentum_at_least", 0)):
		amount += int(effect.get("bonus", 0))
	if card.get("type", "") == "skill" and skill_block_bonus_percent > 0:
		amount = int(ceil(float(amount) * (100.0 + float(skill_block_bonus_percent)) / 100.0))
	if _status_amount(player["statuses"], "frail") > 0:
		amount = int(floor(float(amount) * 0.75))
	return max(amount, 0)

func _gain_player_block(amount: int) -> void:
	var plating := _status_amount(player["statuses"], "plating")
	if plating > 0:
		amount += plating
	player["block"] = int(player.get("block", 0)) + amount
	_log("玩家获得 %d 点护甲。" % amount)
	_push_feedback("block", "获得 %d 点护甲" % amount, "player", amount, "info")
	_apply_relics("block_gained", {"amount": amount})

	var counter_damage := _status_amount(player["statuses"], "counter_pressure") * 2 + _status_amount(player["statuses"], "counter_pressure_plus") * 3
	if counter_damage > 0:
		var enemy := _first_alive_enemy()
		if not enemy.is_empty():
			_log("反压姿态触发。")
			_damage_enemy(enemy, counter_damage, {"name": "反压姿态", "type": "power"})

func _damage_enemy(enemy: Dictionary, amount: int, card: Dictionary) -> void:
	if int(enemy.get("hp", 0)) <= 0:
		return

	if not bool(card.get("ignore_player_modifiers", false)):
		amount += _status_amount(player["statuses"], "strength")
		if _status_amount(player["statuses"], "weak") > 0:
			amount = int(floor(float(amount) * 0.75))
	if _status_amount(enemy["statuses"], "vulnerable") > 0:
		amount = int(ceil(float(amount) * 1.5))
	amount = max(amount, 0)

	var before_block: int = int(enemy.get("block", 0))
	var blocked: int = int(min(before_block, amount))
	enemy["block"] = before_block - blocked
	var hp_damage: int = amount - blocked
	enemy["hp"] = max(0, int(enemy.get("hp", 0)) - hp_damage)
	_log("%s 对 %s 造成 %d 点伤害（格挡 %d）。" % [card.get("name", "攻击"), enemy.get("name", "敌人"), hp_damage, blocked])
	_push_feedback("enemy_hit", "%s -%d" % [enemy.get("name", "敌人"), hp_damage], str(enemy.get("id", "")), hp_damage, "hit")

	if before_block > 0 and int(enemy.get("block", 0)) == 0:
		_apply_relics("enemy_block_broken", {"enemy": enemy})

	if int(enemy.get("hp", 0)) <= 0:
		_log("%s 被击败。" % enemy.get("name", "敌人"))
		_push_feedback("enemy_defeated", "%s 被击败" % enemy.get("name", "敌人"), str(enemy.get("id", "")), 0, "success")
	else:
		_check_enemy_phase_transitions(enemy)

func _damage_player(amount: int, enemy: Dictionary) -> void:
	amount += _status_amount(enemy.get("statuses", {}), "strength")
	if _status_amount(enemy.get("statuses", {}), "weak") > 0:
		amount = int(floor(float(amount) * 0.75))
	if _status_amount(player["statuses"], "vulnerable") > 0:
		amount = int(ceil(float(amount) * 1.5))
	amount = max(amount, 0)

	var before_block: int = int(player.get("block", 0))
	var blocked: int = int(min(before_block, amount))
	player["block"] = before_block - blocked
	var hp_damage: int = amount - blocked
	_lose_player_hp(hp_damage, "%s 的攻击" % enemy.get("name", "敌人"))
	_log("%s 攻击造成 %d 点生命伤害（格挡 %d）。" % [enemy.get("name", "敌人"), hp_damage, blocked])
	_push_feedback("player_hit", "玩家 -%d" % hp_damage, "player", hp_damage, "danger")

func _lose_player_hp(amount: int, reason: String) -> void:
	amount = max(amount, 0)
	if amount <= 0:
		return
	player["hp"] = max(0, int(player.get("hp", 0)) - amount)
	_log("玩家因 %s 失去 %d 点生命。" % [reason, amount])
	if int(player.get("hp", 0)) <= 0:
		phase = "lost"
		_log("玩家战败。")
		_push_feedback("lost", "战败", "player", 0, "danger")

func _heal_player(amount: int, source: String) -> void:
	amount = max(amount, 0)
	if amount <= 0:
		return
	var before: int = int(player.get("hp", 0))
	player["hp"] = min(int(player.get("max_hp", before)), before + amount)
	_log("玩家通过 %s 恢复 %d 点生命（%d -> %d）。" % [source, int(player["hp"]) - before, before, int(player["hp"])])
	_push_feedback("heal", "恢复 %d 点生命" % (int(player["hp"]) - before), "player", int(player["hp"]) - before, "success")

func _gain_momentum(amount: int) -> void:
	var before := int(player.get("momentum", 0))
	player["momentum"] = clamp(before + amount, 0, int(player.get("momentum_max", 6)))
	_log("获得 %d 点势能（%d -> %d）。" % [amount, before, int(player["momentum"])])

func _lose_momentum(amount: int) -> void:
	var before := int(player.get("momentum", 0))
	player["momentum"] = max(0, before - amount)
	_log("失去 %d 点势能（%d -> %d）。" % [amount, before, int(player["momentum"])])

func _gain_energy(amount: int) -> void:
	player["energy"] = int(player.get("energy", 0)) + amount
	_log("获得 %d 点能量，当前 %d。" % [amount, int(player["energy"])])

func _apply_status_from_card(effect: Dictionary, target_index: int) -> void:
	var status := str(effect.get("status", ""))
	var amount := int(effect.get("amount", 0))
	var target := str(effect.get("target", "enemy"))
	if target == "self":
		_add_status(player["statuses"], status, amount)
		_log("玩家获得状态 %s x%d。" % [status, amount])
	elif target == "all_enemies":
		for enemy in enemies:
			if int(enemy.get("hp", 0)) > 0:
				_add_status(enemy["statuses"], status, amount)
	else:
		var enemy := _get_enemy_at(target_index)
		if not enemy.is_empty():
			_add_status(enemy["statuses"], status, amount)
			_log("%s 获得状态 %s x%d。" % [enemy.get("name", "敌人"), status, amount])

func _apply_status_from_potion(effect: Dictionary, target_index: int) -> void:
	var status := str(effect.get("status", ""))
	var amount := int(effect.get("amount", 0))
	var target := str(effect.get("target", "enemy"))
	if target == "self":
		_add_status(player["statuses"], status, amount)
		_log("玩家获得状态 %s x%d。" % [status, amount])
	elif target == "all_enemies":
		for enemy in enemies:
			if int(enemy.get("hp", 0)) > 0:
				_add_status(enemy["statuses"], status, amount)
		_log("所有敌人获得状态 %s x%d。" % [status, amount])
	else:
		var enemy := _get_enemy_at(target_index)
		if not enemy.is_empty():
			_add_status(enemy["statuses"], status, amount)
			_log("%s 获得状态 %s x%d。" % [enemy.get("name", "敌人"), status, amount])

func _create_card(card_id: String, destination: String, amount: int) -> void:
	if not cards_by_id.has(card_id):
		_log("无法创建缺失卡牌：%s" % card_id)
		return

	for _i in range(amount):
		var card: Dictionary = cards_by_id[card_id].duplicate(true)
		match destination:
			"hand":
				hand.append(card)
			"draw":
				draw_pile.append(card)
			"discard":
				discard_pile.append(card)
			_:
				discard_pile.append(card)
		_log("生成卡牌：%s -> %s。" % [card.get("name", card_id), destination])
		_apply_relics("card_created", {"card_id": card_id})

func _effect_condition_failed(effect: Dictionary) -> bool:
	if effect.has("requires_momentum_at_least") and int(player.get("momentum", 0)) < int(effect.get("requires_momentum_at_least", 0)):
		return true
	return false

func _apply_setup_relics() -> void:
	for relic_id in owned_relic_ids:
		var relic: Dictionary = relics_by_id.get(relic_id, {})
		for effect in relic.get("effects", []):
			if effect.get("trigger", "") != "setup":
				continue
			match str(effect.get("type", "")):
				"momentum_max_bonus":
					player["momentum_max"] = int(player.get("momentum_max", 6)) + int(effect.get("amount", 0))
				"skill_block_bonus_percent":
					skill_block_bonus_percent += int(effect.get("amount", 0))

func _apply_relics(trigger: String, context: Dictionary) -> void:
	for relic_id in owned_relic_ids:
		var relic: Dictionary = relics_by_id.get(relic_id, {})
		for effect in relic.get("effects", []):
			if effect.get("trigger", "") != trigger:
				continue
			if _relic_condition_failed(relic_id, effect, context):
				continue
			_resolve_relic_effect(relic, effect, context)
			if bool(effect.get("once_per_turn", false)):
				relic_used_this_turn[relic_id] = true

func _relic_condition_failed(relic_id: String, effect: Dictionary, context: Dictionary) -> bool:
	if bool(effect.get("first_turn_only", false)) and turn != 1:
		return true
	if bool(effect.get("once_per_turn", false)) and bool(relic_used_this_turn.get(relic_id, false)):
		return true
	if effect.has("min_card_cost"):
		var card: Dictionary = context.get("card", {})
		if int(card.get("cost", 0)) < int(effect.get("min_card_cost", 0)):
			return true
	if effect.has("card_cost_equals"):
		var card_equal: Dictionary = context.get("card", {})
		if int(card_equal.get("cost", -99)) != int(effect.get("card_cost_equals", 0)):
			return true
	if effect.has("card_type"):
		var typed_card: Dictionary = context.get("card", {})
		if str(typed_card.get("type", "")) != str(effect.get("card_type", "")):
			return true
	if effect.has("card_id") and context.has("card_id"):
		if str(context.get("card_id", "")) != str(effect.get("card_id", "")):
			return true
	if effect.has("every_n_attack_cards"):
		var card_for_count: Dictionary = context.get("card", {})
		if str(card_for_count.get("type", "")) == "attack":
			attack_cards_played_this_turn += 1
		if attack_cards_played_this_turn <= 0 or attack_cards_played_this_turn % int(effect.get("every_n_attack_cards", 1)) != 0:
			return true
	return false

func _resolve_relic_effect(relic: Dictionary, effect: Dictionary, context: Dictionary) -> void:
	match str(effect.get("type", "")):
		"draw":
			_log("遗物 %s 触发：抽 %d 张牌。" % [relic.get("name", "遗物"), int(effect.get("amount", 0))])
			draw_cards(int(effect.get("amount", 0)))
		"gain_block":
			_log("遗物 %s 触发。" % relic.get("name", "遗物"))
			_gain_player_block(int(effect.get("amount", 0)))
		"gain_momentum":
			_log("遗物 %s 触发。" % relic.get("name", "遗物"))
			_gain_momentum(int(effect.get("amount", 0)))
		"gain_energy":
			_log("遗物 %s 触发。" % relic.get("name", "遗物"))
			_gain_energy(int(effect.get("amount", 0)))
		"damage_broken_enemy":
			var enemy: Dictionary = context.get("enemy", {})
			if not enemy.is_empty() and int(enemy.get("hp", 0)) > 0:
				enemy["hp"] = max(0, int(enemy.get("hp", 0)) - int(effect.get("amount", 0)))
				_log("遗物 %s 对 %s 造成 %d 点破盾伤害。" % [relic.get("name", "遗物"), enemy.get("name", "敌人"), int(effect.get("amount", 0))])
		"damage_all_enemies":
			_log("遗物 %s 触发，对所有敌人造成 %d 点伤害。" % [relic.get("name", "遗物"), int(effect.get("amount", 0))])
			for enemy in enemies:
				if int(enemy.get("hp", 0)) > 0:
					enemy["hp"] = max(0, int(enemy.get("hp", 0)) - int(effect.get("amount", 0)))
					if int(enemy.get("hp", 0)) > 0:
						_check_enemy_phase_transitions(enemy)
		_:
			pass

func _apply_burn_to_player() -> void:
	var burn := _status_amount(player["statuses"], "burn")
	if burn <= 0:
		return
	_lose_player_hp(burn, "灼烧")
	player["statuses"]["burn"] = max(0, burn - 1)
	_log("玩家灼烧衰减到 %d。" % int(player["statuses"]["burn"]))

func _apply_burn_to_enemy(enemy: Dictionary) -> void:
	var burn := _status_amount(enemy["statuses"], "burn")
	if burn <= 0:
		return
	enemy["hp"] = max(0, int(enemy.get("hp", 0)) - burn)
	enemy["statuses"]["burn"] = max(0, burn - 1)
	_log("%s 受到 %d 点灼烧伤害。" % [enemy.get("name", "敌人"), burn])
	_push_feedback("enemy_hit", "%s 灼烧 -%d" % [enemy.get("name", "敌人"), burn], str(enemy.get("id", "")), burn, "hit")
	if int(enemy.get("hp", 0)) <= 0:
		_log("%s 被灼烧击败。" % enemy.get("name", "敌人"))
		_push_feedback("enemy_defeated", "%s 被灼烧击败" % enemy.get("name", "敌人"), str(enemy.get("id", "")), 0, "success")
	else:
		_check_enemy_phase_transitions(enemy)

func _add_status(statuses: Dictionary, status: String, amount: int) -> void:
	if status.is_empty() or amount == 0:
		return
	statuses[status] = int(statuses.get(status, 0)) + amount
	if int(statuses[status]) <= 0:
		statuses.erase(status)

func _status_amount(statuses: Dictionary, status: String) -> int:
	return int(statuses.get(status, 0))

func _normalize_target_index(target_index: int) -> int:
	if target_index >= 0 and target_index < enemies.size() and int(enemies[target_index].get("hp", 0)) > 0:
		return target_index
	for i in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) > 0:
			return i
	return -1

func _get_enemy_at(index: int) -> Dictionary:
	if index < 0 or index >= enemies.size():
		return {}
	if int(enemies[index].get("hp", 0)) <= 0:
		return {}
	return enemies[index]

func _first_alive_enemy() -> Dictionary:
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			return enemy
	return {}

func _check_enemy_phase_transitions(enemy: Dictionary) -> void:
	var phases: Array = enemy.get("data", {}).get("phases", [])
	if phases.is_empty() or int(enemy.get("hp", 0)) <= 0:
		return

	var current_phase_index: int = int(enemy.get("phase_index", -1))
	for i in range(phases.size()):
		if i <= current_phase_index:
			continue
		var phase_data: Dictionary = phases[i]
		if _enemy_phase_threshold_met(enemy, phase_data):
			_enter_enemy_phase(enemy, i, phase_data)

func _enemy_phase_threshold_met(enemy: Dictionary, phase_data: Dictionary) -> bool:
	var hp: int = int(enemy.get("hp", 0))
	if phase_data.has("hp_below"):
		return hp <= int(phase_data.get("hp_below", 0))
	var percent: int = int(phase_data.get("hp_percent_below", -1))
	if percent < 0:
		return false
	var max_hp: int = max(1, int(enemy.get("max_hp", 1)))
	return hp * 100 <= max_hp * percent

func _enter_enemy_phase(enemy: Dictionary, phase_index: int, phase_data: Dictionary) -> void:
	enemy["phase_index"] = phase_index
	enemy["phase_id"] = str(phase_data.get("id", "phase_%d" % phase_index))
	enemy["phase_name"] = str(phase_data.get("name", enemy["phase_id"]))
	enemy["phase_data"] = phase_data
	enemy["intent_index"] = 0
	_log("%s 进入阶段：%s。" % [enemy.get("name", "敌人"), enemy.get("phase_name", "新阶段")])
	_push_feedback("phase", "%s：%s" % [enemy.get("name", "敌人"), enemy.get("phase_name", "新阶段")], str(enemy.get("id", "")), phase_index, "phase")
	for effect in phase_data.get("on_enter_effects", []):
		var effect_dict: Dictionary = effect
		_resolve_enemy_effect(enemy, effect_dict)
	var actions: Array = _enemy_actions(enemy)
	enemy["current_action"] = actions[0] if not actions.is_empty() else {}

func _check_combat_end() -> void:
	if phase == "won" or phase == "lost":
		return
	if int(player.get("hp", 0)) <= 0:
		phase = "lost"
		_push_feedback("lost", "战败", "player", 0, "danger")
		return
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			return
	phase = "won"
	_log("战斗胜利。")
	_push_feedback("won", "战斗胜利", "", 0, "success")

func _log(message: String) -> void:
	log_entries.append(message)
	if log_entries.size() > 80:
		log_entries.pop_front()

func _push_feedback(event_type: String, message: String, target_id: String = "", amount: int = 0, severity: String = "info") -> void:
	feedback_events.append({
		"type": event_type,
		"message": message,
		"target_id": target_id,
		"amount": amount,
		"severity": severity,
		"turn": turn
	})
	if feedback_events.size() > 40:
		feedback_events.pop_front()
