extends SceneTree

var failed: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main._ready()

	if not _check(main.route_nodes.size() >= 8, "chapter route loads from data"):
		return
	if not _check(str(main._current_node().get("type", "")) == "combat", "run starts at first combat node"):
		return
	if not _check(main.run_deck_ids.size() >= 10, "starter deck is loaded"):
		return
	if not _check(main._max_potion_slots() == 2, "player potion slots load from data"):
		return
	if not _check(main.event_data.get("events", []).size() >= 10, "chapter one event pool has enough events"):
		return
	if not _check(main.map_generation_data.get("chapter_one", {}).get("event_pool", []).has("coolant_cache"), "map generation references expanded event pool"):
		return
	if not _check(main.enemy_row.get_child_count() == main.combat.enemies.size(), "combat renders one visual panel per enemy"):
		return
	var first_enemy_panel = main.enemy_row.get_child(0)
	if not _check(first_enemy_panel.get_child_count() >= 2, "enemy visual panel includes art and button"):
		return
	var first_enemy_art = first_enemy_panel.get_child(0)
	var first_enemy_texture_rect := first_enemy_art as TextureRect
	if not _check(first_enemy_texture_rect != null and first_enemy_texture_rect.texture != null, "enemy visual panel loads placeholder art"):
		return
	if not _check(main.hand_row.get_child_count() == main.combat.hand.size(), "combat renders one styled hand button per card"):
		return
	var first_hand_button = main.hand_row.get_child(0)
	var first_hand_button_cast := first_hand_button as Button
	if not _check(first_hand_button_cast != null and first_hand_button_cast.get_theme_stylebox("normal") != null, "hand card button has a stylebox"):
		return
	if not _check(main.potion_row.get_child_count() == main._max_potion_slots() + 1, "combat renders potion slots"):
		return
	var first_potion_button := main.potion_row.get_child(1) as Button
	if not _check(first_potion_button != null and first_potion_button.icon != null, "potion slot button loads potion placeholder icon"):
		return

	main.run_potion_ids = ["volatile_vial"]
	var first_enemy_hp_before: int = int(main.combat.enemies[0].get("hp", 0))
	main._on_potion_pressed(0)
	if not _check(main.run_potion_ids.is_empty(), "using a potion consumes a run potion slot"):
		return
	if not _check(int(main.combat.enemies[0].get("hp", 0)) == first_enemy_hp_before - 12, "main scene potion button applies combat effect"):
		return

	main.combat.phase = "won"
	main._advance_to_next_node()
	if not _check(main.current_node_id.is_empty(), "completed node opens map choice"):
		return
	if not _check(not main.available_node_ids.is_empty(), "map choice exposes reachable nodes"):
		return
	if not _check(main.map_view.visible, "map choice shows visual map view"):
		return
	if not _check(main.map_view.get_node_button_count() == main.route_nodes.size(), "map view renders every route node"):
		return
	if not _check(main.map_view.get_available_button_count() == main.available_node_ids.size(), "map view marks available nodes"):
		return
	if not _check(main.log_label.text.contains("地图图例"), "map choice shows map legend"):
		return

	_jump_to_node_type(main, "campfire")
	if not _check(str(main._current_node().get("type", "")) == "campfire", "campfire node can start"):
		return
	var first_card_before: String = str(main.run_deck_ids[0])
	var first_card: Dictionary = main._card_by_id(first_card_before)
	if not _check(main._upgrade_preview_text(first_card).contains("=>"), "upgrade preview shows before and after"):
		return
	main._on_upgrade_card_pressed(0)
	if not _check(str(main.run_deck_ids[0]) == "%s+" % first_card_before, "campfire upgrades selected card"):
		return
	main._on_deck_view_pressed()
	if not _check(main.deck_view_open, "deck view opens"):
		return
	if not _check(main.log_label.text.contains("+"), "deck view shows upgraded card marker"):
		return
	main._on_close_deck_view_pressed()
	if not _check(not main.deck_view_open, "deck view closes"):
		return
	if not _check(main.current_node_id.is_empty() and not main.available_node_ids.is_empty(), "campfire returns to map choice after upgrade"):
		return

	_jump_to_node_type(main, "campfire")
	main.run_hp = 10
	main._on_campfire_heal_pressed()
	if not _check(main.run_hp > 10, "campfire healing restores HP"):
		return

	_jump_to_node_type(main, "event")
	if not _check(str(main._current_node().get("type", "")) == "event", "event node can start"):
		return
	var gold_before_event: int = main.run_gold
	var event: Dictionary = main._event_by_id("broken_reactor")
	main._on_event_choice_pressed(event.get("choices", [])[0])
	if not _check(main.run_gold == gold_before_event + 35, "event choice applies gold effect"):
		return
	if not _check(main.current_node_id.is_empty() and not main.available_node_ids.is_empty(), "event returns to map choice after choice"):
		return

	_jump_to_node_type(main, "event")
	main.run_potion_ids.clear()
	var potion_event: Dictionary = main._event_by_id("coolant_cache")
	main._on_event_choice_pressed(potion_event.get("choices", [])[0])
	if not _check(main.run_potion_ids.size() == 1, "event choice can grant a potion"):
		return
	if not _check(str(main.run_potion_ids[0]) == "guard_tonic", "event grants the configured potion id"):
		return

	_jump_to_node_type(main, "shop")
	if not _check(str(main._current_node().get("type", "")) == "shop", "shop node can start"):
		return
	var potion_count_before: int = main.run_potion_ids.size()
	var gold_before_potion: int = main.run_gold
	var shop_potion: Dictionary = main._generate_potion_rewards(1)[0]
	var potion_price: int = main._potion_price(shop_potion)
	main.run_gold = max(main.run_gold, potion_price)
	main._on_shop_buy_potion_pressed(str(shop_potion.get("id", "")), potion_price)
	if not _check(main.run_potion_ids.size() == potion_count_before + 1, "shop purchase adds a potion"):
		return
	if not _check(main.run_gold == max(gold_before_potion, potion_price) - potion_price, "shop potion purchase spends gold"):
		return

	var deck_size_before: int = main.run_deck_ids.size()
	var gold_before: int = main.run_gold
	var shop_card: Dictionary = main._generate_card_rewards(1)[0]
	var price: int = main._card_price(shop_card)
	main.run_gold = max(main.run_gold, price)
	main._on_shop_buy_card_pressed(str(shop_card.get("id", "")), price)
	if not _check(main.run_deck_ids.size() == deck_size_before + 1, "shop purchase adds a card"):
		return
	if not _check(main.run_gold == max(gold_before, price) - price, "shop purchase spends gold"):
		return

	main.free()
	print("Run flow smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("Test failed: %s" % message)
		failed = true
		quit(1)
		return false
	return true

func _jump_to_node_type(main, node_type: String) -> void:
	for node in main.route_nodes:
		var node_dict: Dictionary = node
		if str(node_dict.get("type", "")) == node_type:
			main.current_node_id = str(node_dict.get("id", ""))
			main.current_node_index = main._node_index_by_id(main.current_node_id)
			main.available_node_ids.clear()
			main._start_current_node()
			return
