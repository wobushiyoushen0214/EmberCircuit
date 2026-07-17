extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const NumericalTreeAuditorScript = preload("res://scripts/tools/NumericalTreeAuditor.gd")
const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")
const MainScript = preload("res://scripts/main/Main.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player_data: Dictionary = DataLoaderScript.load_json("res://data/config/player.json")
	var card_data: Dictionary = DataLoaderScript.load_json("res://data/cards/cards.json")
	var enemy_data: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var relic_data: Dictionary = DataLoaderScript.load_json("res://data/relics/relics.json")
	var economy_data: Dictionary = DataLoaderScript.load_json("res://data/config/economy.json")
	var numerical_tree: Dictionary = DataLoaderScript.load_json("res://data/config/numerical_tree.json")
	var monster_scaling: Dictionary = DataLoaderScript.load_json("res://data/config/monster_scaling.json")
	var characters: Array = player_data.get("characters", [])
	var ember: Dictionary = _row_by_id(characters, "ember_exile")
	var arc: Dictionary = _row_by_id(characters, "arc_tinker")
	var pyre: Dictionary = _row_by_id(characters, "pyre_ascetic")
	var expected_starter_decks := {
		"ember_exile": ["ember_strike", "ember_strike", "ember_strike", "ember_strike", "ember_strike", "ash_guard", "ash_guard", "ash_guard", "ash_guard", "cooling_breath"],
		"arc_tinker": ["spark_throw", "spark_throw", "spark_throw", "pressure_probe", "pressure_probe", "soot_step", "soot_step", "ash_guard", "ash_guard", "static_primer"],
		"pyre_ascetic": ["ember_strike", "ember_strike", "penitent_cut", "penitent_cut", "scar_guard", "scar_guard", "scar_guard", "scar_guard", "kindle_pain", "cooling_breath"],
	}
	for character in [ember, arc, pyre]:
		var character_id: String = str(character.get("id", ""))
		_check(character.get("starter_deck_ids", []) == expected_starter_decks.get(character_id, []), "%s starter deck exactly matches the frozen ten-card order" % character_id)
	_check(player_data.get("player", {}).get("starter_deck_ids", []) == expected_starter_decks.get("ember_exile", []), "legacy Ember starter deck remains synchronized with the formal character")
	_check(int(player_data.get("player", {}).get("starting_gold", -1)) == 55 and int(ember.get("starting_gold", -1)) == 55, "legacy and formal Ember configurations use 55 starting gold")
	_check(int(arc.get("starting_gold", -1)) == 52 and int(pyre.get("starting_gold", -1)) == 50, "Arc and Pyre use 52/50 starting gold")
	var starting_gold_range: Array = numerical_tree.get("players", {}).get("starting_gold_range", [])
	_check(starting_gold_range.size() == 2 and int(starting_gold_range[0]) == 50 and int(starting_gold_range[1]) == 55, "numerical tree freezes the 50-55 starting-gold band")
	_check(_count_id(pyre.get("starter_deck_ids", []), "penitent_cut") == 2 and _count_id(pyre.get("starter_deck_ids", []), "ember_strike") == 2, "Pyre opens with two penitent cuts and two ember strikes")

	var ember_strike: Dictionary = _row_by_id(card_data.get("cards", []), "ember_strike")
	var spark_throw: Dictionary = _row_by_id(card_data.get("cards", []), "spark_throw")
	var static_primer: Dictionary = _row_by_id(card_data.get("cards", []), "static_primer")
	var penitent_cut: Dictionary = _row_by_id(card_data.get("cards", []), "penitent_cut")
	var scar_guard: Dictionary = _row_by_id(card_data.get("cards", []), "scar_guard")
	_check(_effect_amount(ember_strike, "damage") == 6 and _upgrade_effect_amount(ember_strike, "damage") == 8, "ember strike is rebaselined to 6/8 damage")
	_check(_effect_amount(spark_throw, "damage") == 3 and _upgrade_effect_amount(spark_throw, "damage") == 5, "spark throw is rebaselined to 3/5 damage")
	_check(int(static_primer.get("cost", -1)) == 0 and int(static_primer.get("upgrade", {}).get("cost", -1)) == 0, "static primer remains a one-copy zero-cost exhaust starter")
	_check(_effect_amount(penitent_cut, "damage") == 6 and _upgrade_effect_amount(penitent_cut, "damage") == 8, "penitent cut is rebaselined to 6/8 damage")
	_check(_effect_amount(scar_guard, "block") == 7 and _upgrade_effect_amount(scar_guard, "block") == 10, "scar guard keeps 7/10 active block while free opening block is removed")

	var ember_bottle: Dictionary = _row_by_id(relic_data.get("relics", []), "ember_bottle")
	var cracked_charm: Dictionary = _row_by_id(relic_data.get("relics", []), "cracked_charm")
	var insulated_battery: Dictionary = _row_by_id(relic_data.get("relics", []), "insulated_battery")
	var ash_rosary: Dictionary = _row_by_id(relic_data.get("relics", []), "ash_rosary")
	_check(_effect_amount(ember_bottle, "gain_block") == 3, "ember bottle grants three opening block")
	_check(_effect_amount(insulated_battery, "gain_block") == 2, "insulated battery grants two opening block")
	_check(_effect_amount(ash_rosary, "gain_block") == 1, "ash rosary grants one opening block")
	var charm_effect: Dictionary = (cracked_charm.get("effects", []) as Array)[0]
	_check(str(charm_effect.get("trigger", "")) == "player_hp_lost" and int(charm_effect.get("min_hp_lost", 0)) == 1 and bool(charm_effect.get("once_per_combat", false)) and str(charm_effect.get("type", "")) == "draw" and int(charm_effect.get("amount", 0)) == 1, "cracked charm draws once after the first real HP loss")

	var auditor = NumericalTreeAuditorScript.new()
	var report: Dictionary = auditor.build_report()
	var report_players: Array = report.get("players", [])
	var expected_scores := {
		"ember_exile": [73.86, 79.14],
		"arc_tinker": [65.97, 75.77],
		"pyre_ascetic": [76.21, 79.73],
	}
	for character_id in expected_scores:
		var row: Dictionary = _row_by_id(report_players, character_id)
		var expected: Array = expected_scores[character_id]
		_check(is_equal_approx(float(row.get("starter_deck_score", -1.0)), float(expected[0])), "%s starter deck score matches the frozen candidate" % character_id)
		_check(is_equal_approx(float(row.get("opening_package_score", -1.0)), float(expected[1])), "%s opening package score matches the frozen candidate" % character_id)
		_check(str(row.get("opening_package_severity", "")) == "ok" and (row.get("opening_package_issues", []) as Array).is_empty(), "%s opening package is inside its target" % character_id)
	_check((numerical_tree.get("audit_inventory", {}).get("pressure_contract", {}).get("opening_package_warning_ids", []) as Array).is_empty(), "opening warning inventory is empty after rebaseline")
	_check(int(numerical_tree.get("version", 0)) == 4 and int(numerical_tree.get("pressure_contract", {}).get("schema_version", 0)) == 2, "formal numerical baseline is version four with attrition-aware pressure schema two")

	var simulator = BalanceSimulatorScript.new()
	simulator.load_default_data()
	var single_result: Dictionary = simulator._run_single_combat("ember_exile", 0, "intro_patrol", 30, 1717)
	_check(int(single_result.get("player_starting_block", -1)) == 6, "single combat applies Ember bottle plus the default steel manual before turn one")
	var single_report: Dictionary = simulator.run_suite({
		"iterations": 1,
		"max_turns": 30,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
		"encounter_ids": ["intro_patrol"],
	})
	var single_case: Dictionary = (single_report.get("cases", []) as Array)[0]
	_check(str(single_case.get("loadout_profile", "")) == "starter_deck_relics_default_skill_book", "single report names the default skill-book loadout")
	_check(str(single_case.get("skill_book_id", "")) == "steel_manual", "single report declares steel manual as the active default skill book")
	_check(int(economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 0)) == 25, "campfire recovery is rebaselined to twenty-five percent")
	for max_hp in [69, 70]:
		var campfire_state := {"hp": 0, "max_hp": max_hp, "campfires_seen": 0, "deck_ids": []}
		simulator._simulate_campaign_campfire(campfire_state)
		_check(int(campfire_state.get("hp", 0)) == 18, "campaign campfire restores eighteen HP at max HP %d" % max_hp)
	var main = MainScript.new()
	var composite_intents := [
		{"intent": {"type": "attack_block", "amount": 5, "hits": 1, "block": 6}, "text": "攻击 5 x1，并获得 6 护甲", "compact": "5+盾6", "damage": 5},
		{"intent": {"type": "attack_buff", "amount": 6, "hits": 1, "status": "strength", "status_amount": 1}, "text": "攻击 6 x1，并强化 strength x1", "compact": "6+强1", "damage": 6},
		{"intent": {"type": "attack_status_card", "amount": 5, "hits": 1, "card_id": "searing_wound", "card_amount": 1}, "text": "攻击 5 x1，并加入 1 张 searing_wound", "compact": "5+伤1", "damage": 5},
	]
	for fixture_value in composite_intents:
		var fixture: Dictionary = fixture_value
		var intent: Dictionary = fixture.get("intent", {})
		var intent_type: String = str(intent.get("type", ""))
		_check(main._intent_projects_to_player(intent_type), "%s projects its attack toward the player" % intent_type)
		_check(main._intent_icon_path(intent_type) == main._intent_icon_path("attack"), "%s uses the attack intent icon" % intent_type)
		_check(main._stage_forecast_color(intent_type).is_equal_approx(main._stage_forecast_color("attack")), "%s uses the attack forecast primary color" % intent_type)
		_check(main._intent_badge_font_color(intent_type).is_equal_approx(Color(1.0, 0.84, 0.94, 1.0)), "%s registers the composite-attack badge and icon color" % intent_type)
		_check(main._intent_text(intent) == str(fixture.get("text", "")), "%s explains damage and its secondary effect" % str(intent.get("type", "")))
		_check(main._intent_compact_text(intent) == str(fixture.get("compact", "")), "%s compact badge retains the secondary effect" % str(intent.get("type", "")))
		_check(simulator._intent_damage({"current_action": {"intent": intent}, "statuses": {}}) == int(fixture.get("damage", 0)), "%s counts as projected incoming damage" % str(intent.get("type", "")))
	var forge_bishop: Dictionary = _row_by_id(enemy_data.get("enemies", []), "forge_bishop")
	var final_rite: Dictionary = _row_by_id(forge_bishop.get("phases", []), "final_rite")
	var ashen_edict: Dictionary = _row_by_id(final_rite.get("actions", []), "ashen_edict")
	var ashen_intent: Dictionary = ashen_edict.get("intent", {})
	_check(str(ashen_intent.get("status", "")) == "vulnerable" and int(ashen_intent.get("status_amount", 0)) == 1, "Ashen Edict intent declares the vulnerable effect that its real action resolves")
	_check(main._intent_text(ashen_intent) == "攻击 6 x1，并施加 vulnerable x1，并加入 1 张 searing_wound", "Ashen Edict detailed forecast exposes damage, vulnerable, and the wound card")
	_check(main._intent_compact_text(ashen_intent) == "6+易1+伤1", "Ashen Edict compact forecast retains vulnerable and the wound card")
	main.free()
	var monster_rows: Array = report.get("monsters", [])
	var encounter_expectations := {
		"intro_patrol": [62, 23, 5.0 / 6.0, 46],
		"polluted_lab": [64, 22, 3.0 / 5.0, 27],
		"iron_checkpoint": [74, 22, 3.0 / 5.0, 28],
		"cinder_kennels": [62, 23, 4.0 / 6.0, 39],
		"executor_elite": [86, 22, 1.0, 48],
		"furnace_colossus_elite": [96, 18, 1.0, 38],
		"chapter_one_boss": [116, 24, 4.0 / 5.0, 27],
	}
	for encounter_id in encounter_expectations:
		var encounter_row: Dictionary = _row_by_id(monster_rows, encounter_id)
		var expected: Array = encounter_expectations[encounter_id]
		_check(int(encounter_row.get("total_hp", 0)) == int(expected[0]) and int(encounter_row.get("peak_damage", 0)) == int(expected[1]), "%s matches the frozen HP and peak damage" % encounter_id)
		_check(is_equal_approx(float(encounter_row.get("base_attack_action_ratio", 0.0)), float(expected[2])), "%s matches the frozen attack-action ratio" % encounter_id)
		_check(int(encounter_row.get("base_longest_zero_direct_damage_actions", 99)) <= 1, "%s has no multi-action zero-damage window" % encounter_id)
		_check(int(encounter_row.get("base_first_three_action_damage_total", 0)) == int(expected[3]), "%s matches the frozen first-three pressure" % encounter_id)
		_check(str(encounter_row.get("pressure_severity", "")) == "ok" and (encounter_row.get("pressure_issues", []) as Array).is_empty(), "%s passes every static pressure gate" % encounter_id)
	var boss_row: Dictionary = _row_by_id(monster_rows, "chapter_one_boss")
	_check(is_equal_approx(float(boss_row.get("effective_hp", 0.0)), 112.0) and is_equal_approx(float(boss_row.get("chapter_highest_elite_effective_hp", 0.0)), 96.0), "chapter one hierarchy is 112 boss EHP over 96 elite EHP")
	_check(is_equal_approx(float(boss_row.get("boss_to_highest_elite_ehp_ratio", 0.0)), 1.1667), "chapter one boss-to-elite EHP ratio is 1.1667")
	var chapter_one_scaling: Dictionary = monster_scaling.get("chapters", {}).get("chapter_one", {})
	_check(int(chapter_one_scaling.get("normal", {}).get("max_action_damage", 0)) == 15 and int(chapter_one_scaling.get("elite", {}).get("max_action_damage", 0)) == 22, "normal and elite first-act peak budgets match the candidate")
	_check(int(chapter_one_scaling.get("boss", {}).get("hp_max", 0)) == 116 and int(chapter_one_scaling.get("boss", {}).get("max_action_damage", 0)) == 24, "first-act boss scaling permits 116 HP and 24 peak damage")

	if not _failures.is_empty():
		push_error("Act 1 rebaseline test failed with %d issue(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Act 1 rebaseline test passed.")
	quit(0)

func _row_by_id(rows: Array, row_id: String) -> Dictionary:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == row_id:
			return row
	return {}

func _count_id(rows: Array, row_id: String) -> int:
	var count := 0
	for value in rows:
		if str(value) == row_id:
			count += 1
	return count

func _effect_amount(entry: Dictionary, effect_type: String) -> int:
	for effect_value in entry.get("effects", []):
		var effect: Dictionary = effect_value
		if str(effect.get("type", "")) == effect_type:
			return int(effect.get("amount", -1))
	return -1

func _upgrade_effect_amount(entry: Dictionary, effect_type: String) -> int:
	return _effect_amount(entry.get("upgrade", {}), effect_type)

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
