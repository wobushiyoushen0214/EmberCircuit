extends SceneTree

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

func _init() -> void:
	var card_data: Dictionary = DataLoaderScript.load_json("res://data/cards/cards.json")
	var enemy_data: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var relic_data: Dictionary = DataLoaderScript.load_json("res://data/relics/relics.json")
	var potion_data: Dictionary = DataLoaderScript.load_json("res://data/potions/potions.json")
	var encounter_data: Dictionary = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	var player_data: Dictionary = DataLoaderScript.load_json("res://data/config/player.json")

	var combat = CombatStateScript.new()
	combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol")
	combat.consume_feedback_events()

	_check(combat.phase == "player", "combat starts in player phase")
	_check(combat.hand.size() >= 5, "player draws opening hand")
	_check(combat.enemies.size() == 2, "intro encounter has two enemies")
	_check(int(combat.player.get("energy", 0)) == 3, "player starts with 3 energy")

	var playable_index := _first_feedback_card(combat)
	_check(playable_index >= 0, "opening hand has a card that emits combat feedback")
	var played := combat.play_card(playable_index, 0)
	_check(played, "play_card returns true")
	_check(int(combat.player.get("energy", 0)) <= 3, "playing a card updates energy")
	var card_feedback: Array = combat.consume_feedback_events()
	_check(_has_feedback_type(card_feedback, "enemy_hit") or _has_feedback_type(card_feedback, "block"), "playing a card emits feedback")

	combat.end_player_turn()
	_check(combat.phase == "player" or combat.phase == "won" or combat.phase == "lost", "turn loop advances after enemy turn")

	var upgraded_combat = CombatStateScript.new()
	upgraded_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ember_strike+"], [], 72)
	_check(upgraded_combat.hand.size() == 1, "upgraded one-card deck draws one card")
	var upgraded_card: Dictionary = upgraded_combat.hand[0]
	_check(bool(upgraded_card.get("upgraded", false)), "upgraded deck entry marks card upgraded")
	_check(str(upgraded_card.get("name", "")).ends_with("+"), "upgraded card name has plus suffix")
	_check(str(upgraded_card.get("description", "")).contains("9"), "upgraded card uses upgraded description")

	var potions_by_id: Dictionary = DataLoaderScript.index_by_id(potion_data.get("potions", []))
	var potion_combat = CombatStateScript.new()
	potion_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], [], 72)
	potion_combat.consume_feedback_events()
	var enemy_hp_before: int = int(potion_combat.enemies[0].get("hp", 0))
	var energy_before: int = int(potion_combat.player.get("energy", 0))
	_check(potion_combat.use_potion(potions_by_id.get("volatile_vial", {}), 0), "damage potion can be used in player phase")
	_check(int(potion_combat.enemies[0].get("hp", 0)) == enemy_hp_before - 12, "damage potion applies fixed damage")
	_check(int(potion_combat.player.get("energy", 0)) == energy_before, "using a potion does not spend energy")
	var potion_feedback: Array = potion_combat.consume_feedback_events()
	_check(_has_feedback_type(potion_feedback, "potion"), "using a potion emits potion feedback")
	_check(_has_feedback_type(potion_feedback, "enemy_hit"), "damage potion emits enemy hit feedback")

	var boss_combat = CombatStateScript.new()
	boss_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "chapter_one_boss", ["ash_guard"], [], 72)
	boss_combat.consume_feedback_events()
	var boss: Dictionary = boss_combat.enemies[0]
	_check(str(boss.get("phase_id", "")) == "", "boss starts without an active phase")
	boss_combat._damage_enemy(boss, 85, {"name": "测试伤害", "ignore_player_modifiers": true})
	_check(str(boss.get("phase_id", "")) == "second_sermon", "boss enters second phase below 66 percent HP")
	_check(str(boss.get("current_action", {}).get("id", "")) == "cinder_cross", "boss phase resets intent to phase action loop")
	_check(int(boss.get("block", 0)) >= 16, "boss phase entry applies block")
	var phase_feedback: Array = boss_combat.consume_feedback_events()
	_check(_has_feedback_type(phase_feedback, "phase"), "boss phase transition emits phase feedback")
	boss_combat._damage_enemy(boss, 100, {"name": "测试伤害", "ignore_player_modifiers": true})
	_check(str(boss.get("phase_id", "")) == "final_rite", "boss enters final phase below 33 percent HP")
	_check(str(boss.get("current_action", {}).get("id", "")) == "final_rain", "boss final phase uses final action loop")

	print("Combat core smoke test passed.")
	quit(0)

func _first_playable_card(combat) -> int:
	for i in range(combat.hand.size()):
		if combat.can_play_card(i):
			return i
	return -1

func _first_feedback_card(combat) -> int:
	for i in range(combat.hand.size()):
		if not combat.can_play_card(i):
			continue
		var card: Dictionary = combat.hand[i]
		for effect in card.get("effects", []):
			var effect_dict: Dictionary = effect
			var effect_type: String = str(effect_dict.get("type", ""))
			if effect_type == "damage" or effect_type == "block":
				return i
	return _first_playable_card(combat)

func _has_feedback_type(events: Array, event_type: String) -> bool:
	for event in events:
		var event_dict: Dictionary = event
		if str(event_dict.get("type", "")) == event_type:
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
