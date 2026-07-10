extends SceneTree

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

var failed: bool = false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var default_profile: Dictionary = SaveManagerScript.default_profile()
	_check(default_profile.has("forge_marks") and default_profile.has("purchased_upgrade_node_ids") and default_profile.has("equipped_skill_book_by_character"), "profile schema includes progression fields")
	var migrated_profile := SaveManagerScript.normalized_profile({"stats": {"runs_started": 2}})
	_check(int(migrated_profile.get("forge_marks", -1)) == 0 and migrated_profile.get("purchased_upgrade_node_ids", []).is_empty(), "old profile migrates with empty progression state")

	SaveManagerScript.save_profile(default_profile)
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main._ready()
	_check(main.progression_data.get("character_trees", []).size() == 3, "progression config has three character trees")
	_check(main.progression_data.get("skill_books", []).size() >= 4, "progression config has skill books")
	_check(main.progression_data.get("deck_masteries", []).size() >= 4, "progression config has deck masteries")
	_check(main.monster_scaling_data.get("chapters", {}).size() == 3, "monster scaling config has three chapter budgets")
	_check(main.level_tree_data.get("chapters", {}).size() == 3, "level tree config has three chapter trees")

	main.player_profile["forge_marks"] = 12
	main._on_upgrade_node_pressed("arc_insulated_lining")
	main._on_upgrade_node_pressed("arc_auxiliary_coil")
	main._on_upgrade_node_pressed("arc_spare_rack")
	_check(main._purchased_upgrade_node_ids().has("arc_insulated_lining") and main._purchased_upgrade_node_ids().has("arc_auxiliary_coil") and main._purchased_upgrade_node_ids().has("arc_spare_rack"), "character tree purchases respect sequential prerequisites")
	_check(main._progression_currency_amount() == 0, "character tree purchases deduct exact forge mark costs")

	main.player_profile["completed_chapters"] = ["chapter_one"]
	main._on_skill_book_equipped("swift_current_notes")
	_check(main._equipped_skill_book_for_character("ember_exile") == "swift_current_notes", "unlocked skill book equips for the active character")
	main.selected_character_id = "arc_tinker"
	main._on_skill_book_equipped("steel_manual")
	main._on_character_selected("arc_tinker")
	_check(main.run_max_hp == 71 and main.run_hp == 71, "character tree max HP upgrade is snapshotted into a new run")
	_check(main._max_potion_slots() == 4, "character tree potion slot upgrade is snapshotted into a new run")
	_check(main.run_skill_book_id == "steel_manual", "equipped skill book is snapshotted into a new run")
	_check(int(main.combat.player.get("momentum", 0)) >= 3, "character tree starting momentum and starter relic both apply")
	_check(int(main.combat.player.get("block", 0)) >= 8, "skill book combat start block combines with starter relic block")

	var run_state: Dictionary = main._create_save_state()
	_check(run_state.get("run_progression_node_ids", []).size() == 3 and not run_state.get("run_character_config", {}).is_empty(), "run save stores progression snapshot instead of reading live profile")
	main.player_profile["forge_marks"] = 3
	main._on_upgrade_node_pressed("pyre_ash_skin")
	_check(main.run_max_hp == 71, "buying another meta node does not alter an active run snapshot")

	main.run_deck_ids = ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "spark_throw", "pressure_probe", "ash_guard", "ash_guard", "shield_pulse", "shield_pulse"]
	var eligible_mastery_ids: Array[String] = []
	for mastery_value in main._eligible_deck_masteries():
		eligible_mastery_ids.append(str(mastery_value.get("id", "")))
	_check(eligible_mastery_ids.has("offense_forging"), "six-attack deck satisfies offense forging requirement")
	_check(not eligible_mastery_ids.has("overload_forging"), "deck without three zero-cost cards does not satisfy overload forging")
	main.route_nodes = [{"id": "elite_mastery", "type": "elite", "encounter_id": "executor_elite"}]
	main.current_node_id = "elite_mastery"
	main.current_node_index = 0
	main.combat.phase = "won"
	main.reward_generated_for = "elite_mastery:executor_elite"
	main.card_reward_done = true
	main.relic_reward_done = true
	main.potion_reward_done = true
	main._refresh_rewards()
	_check(main.last_mastery_reward_pending and main.last_mastery_reward_option_count >= 1, "first eligible elite victory opens deck mastery selection")
	main._on_deck_mastery_pressed("offense_forging")
	_check(main.run_deck_mastery_id == "offense_forging" and not main.last_mastery_reward_pending, "deck mastery selection is stored and closes the reward gate")
	_check(str(main._create_save_state().get("run_deck_mastery_id", "")) == "offense_forging", "run save stores selected deck mastery")

	var card_data: Dictionary = DataLoaderScript.load_json("res://data/cards/cards.json")
	var enemy_data: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var relic_data: Dictionary = DataLoaderScript.load_json("res://data/relics/relics.json")
	var encounter_data: Dictionary = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	var player_data: Dictionary = DataLoaderScript.load_json("res://data/config/player.json")

	var mastery_player_data: Dictionary = player_data.duplicate(true)
	mastery_player_data["runtime_player_config"] = player_data.get("player", {}).duplicate(true)
	mastery_player_data["run_modifier_sources"] = [
		{"id": "test_offense_mastery", "name": "测试攻势锻造", "effects": [ {"trigger": "card_played", "type": "bonus_damage", "amount": 2, "card_type": "attack", "once_per_combat": true} ]}
	]
	var mastery_combat = CombatStateScript.new()
	mastery_combat.setup(card_data, enemy_data, relic_data, encounter_data, mastery_player_data, "intro_patrol", ["spark_throw"], [], 72)
	var mastery_enemy_hp: int = int(mastery_combat.enemies[0].get("hp", 0))
	_check(mastery_combat.play_card(0, 0), "deck mastery test can play a starter attack")
	_check(int(mastery_combat.enemies[0].get("hp", 0)) == mastery_enemy_hp - 6, "offense forging adds its one-time 2 damage without duplicating card damage")

	var book_player_data: Dictionary = player_data.duplicate(true)
	book_player_data["runtime_player_config"] = player_data.get("player", {}).duplicate(true)
	book_player_data["run_modifier_sources"] = [
		{"id": "test_swift_book", "name": "测试迅流笔记", "effects": [ {"trigger": "card_played", "type": "draw", "amount": 1, "card_cost_equals": 0, "once_per_combat": true} ]}
	]
	var book_combat = CombatStateScript.new()
	book_combat.setup(card_data, enemy_data, relic_data, encounter_data, book_player_data, "intro_patrol", ["spark_throw", "spark_throw", "spark_throw", "spark_throw", "spark_throw", "ember_strike", "ash_guard"], [], 72)
	var hand_before_book: int = book_combat.hand.size()
	var draw_before_book: int = book_combat.draw_pile.size()
	var zero_cost_hand_index: int = -1
	for i in range(book_combat.hand.size()):
		if int(book_combat.hand[i].get("cost", -1)) == 0:
			zero_cost_hand_index = i
			break
	_check(zero_cost_hand_index >= 0 and book_combat.play_card(zero_cost_hand_index, 0), "skill book test can play a zero-cost card")
	_check(book_combat.hand.size() == hand_before_book and book_combat.draw_pile.size() == draw_before_book - 1, "swift current draws exactly one card on its first zero-cost play")

	main.free()
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	if failed:
		quit(1)
		return
	print("Progression systems smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)
