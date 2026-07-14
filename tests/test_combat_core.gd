extends SceneTree

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

var failed: bool = false

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

	var challenge_player_data: Dictionary = player_data.duplicate(true)
	challenge_player_data["challenge_modifiers"] = {
		"enemy_hp_multiplier": 1.1,
		"enemy_damage_multiplier": 1.1
	}
	var challenge_combat = CombatStateScript.new()
	challenge_combat.setup(card_data, enemy_data, relic_data, encounter_data, challenge_player_data, "intro_patrol")
	_check(int(challenge_combat.enemies[0].get("max_hp", 0)) > int(combat.enemies[0].get("max_hp", 0)), "challenge modifiers increase enemy max HP")
	_check(challenge_combat._modified_enemy_damage(10) == 11, "challenge modifiers increase enemy damage")

	var arc_player_data: Dictionary = player_data.duplicate(true)
	arc_player_data["selected_character_id"] = "arc_tinker"
	var arc_combat = CombatStateScript.new()
	arc_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol")
	_check(str(arc_combat.player.get("name", "")) == "电弧工匠", "combat can load selected character name")
	_check(int(arc_combat.player.get("max_hp", 0)) == 69, "combat can load selected character HP")
	_check(arc_combat.owned_relic_ids.has("arc_capacitor"), "combat can load selected character starter relic")
	_check(_combat_has_card(arc_combat, "spark_throw"), "combat can load selected character starter deck")
	_check(int(arc_combat.player.get("momentum", 0)) >= 2, "combat applies selected character starting momentum and starter relic")

	var arc_relic_combat = CombatStateScript.new()
	arc_relic_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol", ["spark_throw"], ["spark_coil"], 68)
	arc_relic_combat.consume_feedback_events()
	var momentum_before_arc_relic: int = int(arc_relic_combat.player.get("momentum", 0))
	_check(arc_relic_combat.play_card(0, 0), "arc dedicated relic test can play a zero-cost card")
	_check(int(arc_relic_combat.player.get("momentum", 0)) == momentum_before_arc_relic + 1, "spark coil grants momentum on first zero-cost card")

	var induction_combat = CombatStateScript.new()
	induction_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol", ["induction_coil"], ["__test_no_relic__"], 68)
	var induction_momentum_before: int = int(induction_combat.player.get("momentum", 0))
	_check(induction_combat.play_card(0, 0), "induction coil can be played")
	_check(int(induction_combat.player.get("block", 0)) == 6 and int(induction_combat.player.get("momentum", 0)) == induction_momentum_before + 1, "induction coil grants configured block and momentum")

	var grounding_combat = CombatStateScript.new()
	grounding_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol", ["grounding_field"], ["__test_no_relic__"], 68)
	grounding_combat.player["momentum"] = 3
	_check(grounding_combat.play_card(0, 0), "grounding field can be played")
	_check(int(grounding_combat.player.get("block", 0)) == 13 and int(grounding_combat.player.get("momentum", 0)) == 1, "grounding field converts momentum into high block")

	var momentum_gate_combat = CombatStateScript.new()
	momentum_gate_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol", ["magnetic_lance"], ["__test_no_relic__"], 68)
	momentum_gate_combat.player["momentum"] = 1
	_check(not momentum_gate_combat.can_play_card(0), "momentum-spending cards are disabled below their resource cost")
	momentum_gate_combat.player["momentum"] = 2
	var lance_enemy_hp_before: int = int(momentum_gate_combat.enemies[0].get("hp", 0))
	_check(momentum_gate_combat.play_card(0, 0), "magnetic lance can be played at its momentum requirement")
	_check(int(momentum_gate_combat.player.get("momentum", 0)) == 0 and lance_enemy_hp_before - int(momentum_gate_combat.enemies[0].get("hp", 0)) == 22, "magnetic lance consumes momentum and deals configured damage")

	var battery_combat = CombatStateScript.new()
	battery_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol", ["arc_battery"], ["__test_no_relic__"], 68)
	var battery_energy_before: int = int(battery_combat.player.get("energy", 0))
	var battery_momentum_before: int = int(battery_combat.player.get("momentum", 0))
	_check(battery_combat.play_card(0, 0), "spare battery can be played")
	_check(int(battery_combat.player.get("energy", 0)) == battery_energy_before + 1 and int(battery_combat.player.get("momentum", 0)) == battery_momentum_before + 1, "spare battery grants its one-shot resource package")
	_check(battery_combat.exhaust_pile.size() == 1, "spare battery exhausts after use")

	var feedback_shell_combat = CombatStateScript.new()
	feedback_shell_combat.setup(card_data, enemy_data, relic_data, encounter_data, arc_player_data, "intro_patrol", ["feedback_shell"], ["__test_no_relic__"], 68)
	var shell_momentum_before: int = int(feedback_shell_combat.player.get("momentum", 0))
	_check(feedback_shell_combat.play_card(0, 0), "feedback shell can be played")
	_check(int(feedback_shell_combat.player.get("statuses", {}).get("plating", 0)) == 1 and int(feedback_shell_combat.player.get("momentum", 0)) == shell_momentum_before + 2, "feedback shell grants plating and momentum")

	var pyre_player_data: Dictionary = player_data.duplicate(true)
	pyre_player_data["selected_character_id"] = "pyre_ascetic"
	var pyre_combat = CombatStateScript.new()
	pyre_combat.setup(card_data, enemy_data, relic_data, encounter_data, pyre_player_data, "intro_patrol")
	_check(str(pyre_combat.player.get("name", "")) == "熔痕苦修者", "combat can load pyre ascetic character name")
	_check(int(pyre_combat.player.get("max_hp", 0)) == 70, "combat can load pyre ascetic HP")
	_check(pyre_combat.owned_relic_ids.has("penitent_censer"), "combat can load pyre ascetic starter relic")
	_check(_combat_has_card(pyre_combat, "penitent_cut"), "combat can load pyre ascetic starter deck")

	var reversal_combat = CombatStateScript.new()
	reversal_combat.setup(card_data, enemy_data, relic_data, encounter_data, pyre_player_data, "intro_patrol", ["ash_reversal"], ["__test_no_relic__"], 72)
	var reversal_hp_before: int = int(reversal_combat.player.get("hp", 0))
	var reversal_momentum_before: int = int(reversal_combat.player.get("momentum", 0))
	_check(reversal_combat.play_card(0, 0), "ash reversal can be played")
	_check(int(reversal_combat.player.get("hp", 0)) == reversal_hp_before - 1 and int(reversal_combat.player.get("block", 0)) == 8, "ash reversal converts health into block")
	_check(int(reversal_combat.player.get("momentum", 0)) == reversal_momentum_before + 2, "ash reversal grants configured momentum")

	var pyre_relic_combat = CombatStateScript.new()
	pyre_relic_combat.setup(card_data, enemy_data, relic_data, encounter_data, pyre_player_data, "intro_patrol", ["wound_offering"], ["penitent_censer"], 72)
	pyre_relic_combat.consume_feedback_events()
	var pyre_enemy_hp_before: int = int(pyre_relic_combat.enemies[0].get("hp", 0))
	_check(pyre_relic_combat.play_card(0, 0), "pyre starter relic test can play wound offering")
	_check(int(pyre_relic_combat.enemies[0].get("hp", 0)) == pyre_enemy_hp_before - 2, "penitent censer damages enemies when searing wound is created")
	_check(_combat_has_card(pyre_relic_combat, "searing_wound"), "wound offering creates a searing wound card")

	var playable_index := _first_feedback_card(combat)
	_check(playable_index >= 0, "opening hand has a card that emits combat feedback")
	var played := combat.play_card(playable_index, 0)
	_check(played, "play_card returns true")
	_check(int(combat.player.get("energy", 0)) <= 3, "playing a card updates energy")
	var card_feedback: Array = combat.consume_feedback_events()
	_check(_has_feedback_type(card_feedback, "enemy_hit") or _has_feedback_type(card_feedback, "block"), "playing a card emits feedback")

	combat.end_player_turn()
	_check(combat.phase == "player" or combat.phase == "won" or combat.phase == "lost", "turn loop advances after enemy turn")

	var absorb_combat = CombatStateScript.new()
	absorb_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], ["__test_no_relic__"], 70)
	absorb_combat.consume_feedback_events()
	absorb_combat.player["block"] = 20
	var absorb_hp_before: int = int(absorb_combat.player.get("hp", 0))
	absorb_combat._damage_player(7, absorb_combat.enemies[0])
	var absorb_feedback: Array = absorb_combat.consume_feedback_events()
	_check(int(absorb_combat.player.get("hp", 0)) == absorb_hp_before, "fully blocked attack does not reduce player health")
	_check(int(absorb_combat.player.get("block", 0)) == 13, "fully blocked attack consumes the correct block amount")
	_check(_has_feedback_type(absorb_feedback, "block_absorb"), "fully blocked attack emits shield absorption feedback")
	_check(not _has_feedback_type(absorb_feedback, "player_hit"), "fully blocked attack does not emit misleading player hit feedback")

	var enemy_absorb_combat = CombatStateScript.new()
	enemy_absorb_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ember_strike"], ["__test_no_relic__"], 70)
	enemy_absorb_combat.consume_feedback_events()
	enemy_absorb_combat.enemies[0]["block"] = 20
	var enemy_absorb_hp_before: int = int(enemy_absorb_combat.enemies[0].get("hp", 0))
	enemy_absorb_combat._damage_enemy(enemy_absorb_combat.enemies[0], 7, {"name": "测试攻击", "type": "attack"})
	var enemy_absorb_feedback: Array = enemy_absorb_combat.consume_feedback_events()
	_check(int(enemy_absorb_combat.enemies[0].get("hp", 0)) == enemy_absorb_hp_before, "fully blocked player attack does not reduce enemy health")
	_check(_has_feedback_type(enemy_absorb_feedback, "enemy_block_absorb"), "fully blocked player attack emits enemy shield absorption feedback")
	_check(not _has_feedback_type(enemy_absorb_feedback, "enemy_hit"), "fully blocked player attack does not emit misleading enemy hit feedback")

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

	var cinder_lens_combat = CombatStateScript.new()
	cinder_lens_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard", "ember_strike", "cooling_breath", "soot_step", "spark_throw", "pressure_probe"], ["cinder_lens"], 72)
	cinder_lens_combat.consume_feedback_events()
	cinder_lens_combat.draw_pile = [cinder_lens_combat.cards_by_id.get("ember_strike", {}).duplicate(true)]
	cinder_lens_combat.player["momentum"] = 2
	var cinder_lens_hand_before_low: int = cinder_lens_combat.hand.size()
	cinder_lens_combat._apply_relics("turn_start", {})
	_check(cinder_lens_combat.hand.size() == cinder_lens_hand_before_low, "cinder lens does not draw below momentum threshold")
	cinder_lens_combat.player["momentum"] = 3
	cinder_lens_combat._apply_relics("turn_start", {})
	_check(cinder_lens_combat.hand.size() == cinder_lens_hand_before_low + 1, "cinder lens draws when momentum threshold is met")

	var canteen_combat = CombatStateScript.new()
	canteen_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard", "ember_strike", "cooling_breath", "soot_step", "spark_throw", "pressure_probe", "chain_cut"], ["pressure_canteen"], 72)
	canteen_combat.consume_feedback_events()
	var canteen_hand_before: int = canteen_combat.hand.size()
	_check(canteen_combat.use_potion(potions_by_id.get("guard_tonic", {}), 0), "pressure canteen test can use a potion")
	_check(canteen_combat.hand.size() == canteen_hand_before + 2, "pressure canteen draws two after first potion use")
	canteen_combat.draw_pile = [canteen_combat.cards_by_id.get("ember_strike", {}).duplicate(true)]
	var canteen_hand_before_second: int = canteen_combat.hand.size()
	_check(canteen_combat.use_potion(potions_by_id.get("guard_tonic", {}), 0), "pressure canteen test can use a second potion")
	_check(canteen_combat.hand.size() == canteen_hand_before_second, "pressure canteen only triggers once per combat")

	var blood_clamp_combat = CombatStateScript.new()
	blood_clamp_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], ["blood_rust_clamp"], 72)
	blood_clamp_combat.consume_feedback_events()
	var clamp_momentum_before: int = int(blood_clamp_combat.player.get("momentum", 0))
	blood_clamp_combat._lose_player_hp(2, "遗物测试")
	_check(int(blood_clamp_combat.player.get("momentum", 0)) == clamp_momentum_before + 1, "blood rust clamp grants momentum after first HP loss")
	blood_clamp_combat._lose_player_hp(2, "遗物测试")
	_check(int(blood_clamp_combat.player.get("momentum", 0)) == clamp_momentum_before + 1, "blood rust clamp only triggers once per turn")

	var twin_valve_combat = CombatStateScript.new()
	twin_valve_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard", "cooling_breath"], ["twin_valve"], 72)
	twin_valve_combat.consume_feedback_events()
	var twin_energy_before: int = int(twin_valve_combat.player.get("energy", 0))
	var twin_skill_index: int = _first_card_with_type(twin_valve_combat, "skill")
	var twin_skill_cost: int = int(twin_valve_combat.hand[twin_skill_index].get("cost", 0)) if twin_skill_index >= 0 else 0
	_check(twin_skill_index >= 0 and twin_valve_combat.play_card(twin_skill_index, 0), "twin valve test can play first skill")
	_check(int(twin_valve_combat.player.get("energy", 0)) == twin_energy_before - twin_skill_cost + 1, "twin valve refunds one energy on first skill each turn")

	var venting_low_combat = CombatStateScript.new()
	venting_low_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["venting_slash"], ["__test_no_relic__"], 72)
	venting_low_combat.consume_feedback_events()
	venting_low_combat.draw_pile = [venting_low_combat.cards_by_id.get("ember_strike", {}).duplicate(true)]
	venting_low_combat.player["momentum"] = 2
	var venting_low_enemy_hp_before: int = int(venting_low_combat.enemies[0].get("hp", 0))
	_check(venting_low_combat.play_card(0, 0), "venting slash can be played below momentum threshold")
	_check(venting_low_enemy_hp_before - int(venting_low_combat.enemies[0].get("hp", 0)) == 6, "venting slash deals base damage")
	_check(venting_low_combat.hand.is_empty(), "venting slash does not draw below momentum threshold")

	var venting_high_combat = CombatStateScript.new()
	venting_high_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["venting_slash"], ["__test_no_relic__"], 72)
	venting_high_combat.consume_feedback_events()
	venting_high_combat.draw_pile = [venting_high_combat.cards_by_id.get("ember_strike", {}).duplicate(true)]
	venting_high_combat.player["momentum"] = 3
	_check(venting_high_combat.play_card(0, 0), "venting slash can be played at momentum threshold")
	_check(venting_high_combat.hand.size() == 1, "venting slash draws when momentum threshold is met")

	var stoke_guard_combat = CombatStateScript.new()
	stoke_guard_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["stoke_guard"], ["__test_no_relic__"], 72)
	stoke_guard_combat.consume_feedback_events()
	var stoke_momentum_before: int = int(stoke_guard_combat.player.get("momentum", 0))
	_check(stoke_guard_combat.play_card(0, 0), "stoke guard can be played")
	_check(int(stoke_guard_combat.player.get("block", 0)) == 5, "stoke guard grants block")
	_check(int(stoke_guard_combat.player.get("momentum", 0)) == stoke_momentum_before + 1, "stoke guard grants momentum")

	var rupture_signal_combat = CombatStateScript.new()
	rupture_signal_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["rupture_signal"], ["__test_no_relic__"], 72)
	rupture_signal_combat.consume_feedback_events()
	_check(rupture_signal_combat.play_card(0, 0), "rupture signal can be played")
	for enemy in rupture_signal_combat.enemies:
		var enemy_dict: Dictionary = enemy
		_check(rupture_signal_combat._status_amount(enemy_dict.get("statuses", {}), "weak") == 1, "rupture signal applies weak to every enemy")

	var redline_engine_combat = CombatStateScript.new()
	redline_engine_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["redline_engine"], ["__test_no_relic__"], 72)
	redline_engine_combat.consume_feedback_events()
	_check(redline_engine_combat.play_card(0, 0), "redline engine can be played")
	_check(redline_engine_combat._status_amount(redline_engine_combat.player.get("statuses", {}), "strength") == 1, "redline engine grants strength")
	_check(int(redline_engine_combat.player.get("momentum", 0)) == 2, "redline engine grants momentum")
	_check(redline_engine_combat._status_amount(redline_engine_combat.player.get("statuses", {}), "burn") == 1, "redline engine applies self burn as a cost")

	var calibration_protocol_combat = CombatStateScript.new()
	calibration_protocol_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["calibration_protocol"], ["__test_no_relic__"], 72)
	calibration_protocol_combat.consume_feedback_events()
	_check(calibration_protocol_combat.play_card(0, 0), "calibration protocol can be played")
	_check(calibration_protocol_combat._status_amount(calibration_protocol_combat.player.get("statuses", {}), "plating") == 1, "calibration protocol grants persistent plating")
	_check(int(calibration_protocol_combat.player.get("momentum", 0)) == 1, "calibration protocol grants momentum")

	var vulnerable_combat = CombatStateScript.new()
	vulnerable_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["heat_chain"], ["__test_no_relic__"], 72)
	vulnerable_combat.consume_feedback_events()
	var vulnerable_enemy: Dictionary = vulnerable_combat.enemies[0]
	vulnerable_combat._add_status(vulnerable_enemy["statuses"], "vulnerable", 1)
	var vulnerable_enemy_hp_before: int = int(vulnerable_enemy.get("hp", 0))
	_check(vulnerable_combat.play_card(0, 0), "vulnerable test can play a multi-hit card")
	_check(vulnerable_enemy_hp_before - int(vulnerable_enemy.get("hp", 0)) == 15, "vulnerable boosts every hit from one damage effect")
	_check(vulnerable_combat._status_amount(vulnerable_enemy.get("statuses", {}), "vulnerable") == 0, "vulnerable is consumed after the next damage effect")

	var weak_combat = CombatStateScript.new()
	weak_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ember_strike"], ["__test_no_relic__"], 72)
	weak_combat.consume_feedback_events()
	var weak_enemy: Dictionary = weak_combat.enemies[0]
	weak_combat._add_status(weak_combat.player["statuses"], "weak", 1)
	var weak_enemy_hp_before: int = int(weak_enemy.get("hp", 0))
	_check(weak_combat.play_card(0, 0), "weak test can play an attack")
	_check(weak_enemy_hp_before - int(weak_enemy.get("hp", 0)) == 5, "weak reduces the next player damage effect")
	_check(weak_combat._status_amount(weak_combat.player.get("statuses", {}), "weak") == 0, "player weak is consumed after attacking")

	var frail_combat = CombatStateScript.new()
	frail_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], ["__test_no_relic__"], 72)
	frail_combat.consume_feedback_events()
	frail_combat._add_status(frail_combat.player["statuses"], "frail", 1)
	_check(frail_combat.play_card(0, 0), "frail test can play a block card")
	_check(int(frail_combat.player.get("block", 0)) == 4, "frail reduces the next player block effect")
	_check(frail_combat._status_amount(frail_combat.player.get("statuses", {}), "frail") == 0, "player frail is consumed after blocking")

	var player_vulnerable_combat = CombatStateScript.new()
	player_vulnerable_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], ["__test_no_relic__"], 72)
	player_vulnerable_combat.consume_feedback_events()
	player_vulnerable_combat._add_status(player_vulnerable_combat.player["statuses"], "vulnerable", 1)
	var player_hp_before_vulnerable_hit: int = int(player_vulnerable_combat.player.get("hp", 0))
	player_vulnerable_combat._resolve_enemy_effect(player_vulnerable_combat.enemies[0], {"type": "damage", "amount": 10, "hits": 2})
	_check(player_hp_before_vulnerable_hit - int(player_vulnerable_combat.player.get("hp", 0)) == 30, "player vulnerable boosts every hit from one enemy damage effect")
	_check(player_vulnerable_combat._status_amount(player_vulnerable_combat.player.get("statuses", {}), "vulnerable") == 0, "player vulnerable is consumed after the next incoming damage effect")

	var enemy_thorn_combat = CombatStateScript.new()
	enemy_thorn_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "iron_checkpoint", ["heat_chain"], ["__test_no_relic__"], 72)
	enemy_thorn_combat.consume_feedback_events()
	var thorn_enemy: Dictionary = enemy_thorn_combat.enemies[1]
	enemy_thorn_combat._add_status(thorn_enemy["statuses"], "thorn", 2)
	var player_hp_before_enemy_thorn: int = int(enemy_thorn_combat.player.get("hp", 0))
	_check(enemy_thorn_combat.play_card(0, 1), "enemy thorn test can play a multi-hit attack")
	_check(player_hp_before_enemy_thorn - int(enemy_thorn_combat.player.get("hp", 0)) == 6, "enemy thorn damages player once per attack hit")
	var enemy_thorn_feedback: Array = enemy_thorn_combat.consume_feedback_events()
	_check(_has_feedback_type(enemy_thorn_feedback, "player_hit"), "enemy thorn emits player hit feedback")

	var player_thorn_combat = CombatStateScript.new()
	player_thorn_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], ["__test_no_relic__"], 72)
	player_thorn_combat.consume_feedback_events()
	var thorn_attacker: Dictionary = player_thorn_combat.enemies[0]
	player_thorn_combat._add_status(player_thorn_combat.player["statuses"], "thorn", 3)
	var attacker_hp_before_player_thorn: int = int(thorn_attacker.get("hp", 0))
	player_thorn_combat._resolve_enemy_effect(thorn_attacker, {"type": "damage", "amount": 2, "hits": 2})
	_check(attacker_hp_before_player_thorn - int(thorn_attacker.get("hp", 0)) == 6, "player thorn damages attacking enemy once per hit")
	var player_thorn_feedback: Array = player_thorn_combat.consume_feedback_events()
	_check(_has_feedback_type(player_thorn_feedback, "enemy_hit"), "player thorn emits enemy hit feedback")

	var boss_combat = CombatStateScript.new()
	boss_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "chapter_one_boss", ["ash_guard"], [], 72)
	boss_combat.consume_feedback_events()
	var boss: Dictionary = boss_combat.enemies[0]
	var second_phase_entry_block: int = _phase_entry_block_amount(enemy_data, "forge_bishop", "second_sermon")
	_check(str(boss.get("phase_id", "")) == "", "boss starts without an active phase")
	var second_phase_target_hp: int = int(floor(float(int(boss.get("max_hp", 1))) * 0.50))
	var second_phase_probe_damage: int = max(1, int(boss.get("hp", 1)) - second_phase_target_hp)
	boss_combat._damage_enemy(boss, second_phase_probe_damage, {"name": "测试伤害", "ignore_player_modifiers": true})
	_check(str(boss.get("phase_id", "")) == "second_sermon", "boss enters second phase below 66 percent HP")
	_check(str(boss.get("current_action", {}).get("id", "")) == "cinder_cross", "boss phase resets intent to phase action loop")
	_check(int(boss.get("block", 0)) >= second_phase_entry_block, "boss phase entry applies block")
	var phase_feedback: Array = boss_combat.consume_feedback_events()
	_check(_has_feedback_type(phase_feedback, "phase"), "boss phase transition emits phase feedback")
	var final_phase_threshold: int = int(floor(float(int(boss.get("max_hp", 1))) * 0.33))
	var final_phase_probe_damage: int = max(1, int(boss.get("hp", 1)) + int(boss.get("block", 0)) - final_phase_threshold + 1)
	boss_combat._damage_enemy(boss, final_phase_probe_damage, {"name": "测试伤害", "ignore_player_modifiers": true})
	_check(str(boss.get("phase_id", "")) == "final_rite", "boss enters final phase below 33 percent HP")
	_check(str(boss.get("current_action", {}).get("id", "")) == "final_rain", "boss final phase uses final action loop")

	var win_combat = CombatStateScript.new()
	win_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], [], 72)
	win_combat.consume_feedback_events()
	for enemy in win_combat.enemies:
		var enemy_dict: Dictionary = enemy
		win_combat._damage_enemy(enemy_dict, 999, {"name": "测试斩杀", "ignore_player_modifiers": true})
	win_combat._check_combat_end()
	var win_feedback: Array = win_combat.consume_feedback_events()
	_check(win_combat.phase == "won", "direct lethal damage can win combat")
	_check(_has_feedback_type(win_feedback, "won"), "combat victory emits feedback")

	var loss_combat = CombatStateScript.new()
	loss_combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, "intro_patrol", ["ash_guard"], [], 1)
	loss_combat.consume_feedback_events()
	loss_combat.end_player_turn()
	var loss_feedback: Array = loss_combat.consume_feedback_events()
	_check(loss_combat.phase == "lost", "enemy turn can defeat player")
	_check(_has_feedback_type(loss_feedback, "lost"), "combat defeat emits feedback")

	if failed:
		quit(1)
		return
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

func _first_card_with_type(combat, card_type: String) -> int:
	for i in range(combat.hand.size()):
		if not combat.can_play_card(i):
			continue
		var card: Dictionary = combat.hand[i]
		if str(card.get("type", "")) == card_type:
			return i
	return -1

func _has_feedback_type(events: Array, event_type: String) -> bool:
	for event in events:
		var event_dict: Dictionary = event
		if str(event_dict.get("type", "")) == event_type:
			return true
	return false

func _combat_has_card(combat, card_id: String) -> bool:
	for pile in [combat.hand, combat.draw_pile, combat.discard_pile, combat.exhaust_pile]:
		for card in pile:
			var card_dict: Dictionary = card
			if str(card_dict.get("id", "")) == card_id:
				return true
	return false

func _phase_entry_block_amount(enemy_data: Dictionary, enemy_id: String, phase_id: String) -> int:
	for enemy in enemy_data.get("enemies", []):
		var enemy_dict: Dictionary = enemy
		if str(enemy_dict.get("id", "")) != enemy_id:
			continue
		for phase in enemy_dict.get("phases", []):
			var phase_dict: Dictionary = phase
			if str(phase_dict.get("id", "")) != phase_id:
				continue
			for effect in phase_dict.get("on_enter_effects", []):
				var effect_dict: Dictionary = effect
				if str(effect_dict.get("type", "")) == "block":
					return int(effect_dict.get("amount", 0))
	return 0

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)
