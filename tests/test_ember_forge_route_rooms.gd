extends SceneTree

const MapPageScript = preload("res://scripts/ui/pages/MapPage.gd")
const EventPageScript = preload("res://scripts/ui/pages/EventPage.gd")
const ShopExperienceScript = preload("res://scripts/ui/pages/ShopExperience.gd")
const CampfirePageScript = preload("res://scripts/ui/pages/CampfirePage.gd")
const RewardPageScript = preload("res://scripts/ui/pages/RewardPage.gd")
const ChoiceRowScript = preload("res://scripts/ui/components/ChoiceRow.gd")
const ItemShelfScript = preload("res://scripts/ui/components/ItemShelf.gd")
const CardCompareScript = preload("res://scripts/ui/components/CardCompare.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var choice_row = ChoiceRowScript.new()
	var item_shelf = ItemShelfScript.new()
	var card_compare = CardCompareScript.new()
	if not _check(choice_row != null and item_shelf != null and card_compare != null, "018B shared route-room components instantiate"):
		return

	var map_page = MapPageScript.new()
	root.add_child(map_page)
	map_page.configure({
		"graph": {"layers": [[{"id": "start", "type": "combat", "name": "余烬门"}], [{"id": "shop", "type": "shop", "name": "旧货架"}], [{"id": "boss", "type": "boss", "name": "核心"}]]},
		"available_node_ids": ["shop"],
		"completed_node_ids": ["start"],
		"current_node_id": "start",
		"preview_successor_ids": ["shop"],
		"preview_title": "旧货架 [商店]",
		"preview_risk": "低风险 · 可安全整备",
		"preview_reward": "购买卡牌、遗物与药水",
		"preview_description": "废弃货架仍保留着可用物资。",
		"preview_successors": ["核心 [首领]"],
		"available_width": 1280.0,
		"available_height": 720.0
	})
	await process_frame
	if not _check(map_page.get_node_or_null("EmberMapView") != null and map_page.node_selected.get_connections().size() >= 0, "map page owns the original map view signal surface"):
		return
	if not _check(map_page.find_child("MapRiskSummary", true, false) != null and map_page.find_child("MapRoutePreview", true, false) != null, "map page exposes risk and successor preview hierarchy"):
		return
	var map_preview := map_page.map_view.get_node_or_null("NodePreviewPanel") as PanelContainer
	if not _check(
		map_preview.find_child("PreviewTitle", true, false).text == "旧货架 [商店]"
		and map_preview.find_child("PreviewRisk", true, false).text == "风险\n低风险 · 可安全整备"
		and map_preview.find_child("PreviewReward", true, false).text == "收益\n购买卡牌、遗物与药水"
		and map_preview.find_child("PreviewDescription", true, false).text == "说明\n废弃货架仍保留着可用物资。"
		and map_preview.find_child("PreviewSuccessors", true, false).text == "后续节点\n- 核心 [首领]",
		"map page forwards exact preview title, risk, reward, description and successors"
	):
		return
	var selected_map_nodes: Array[String] = []
	map_page.node_selected.connect(func(node_id: String) -> void: selected_map_nodes.append(node_id))
	var available_shop_button := map_page.map_view.node_buttons.get("shop", null) as Button
	_click_control(available_shop_button)
	await process_frame
	if not _check(selected_map_nodes == ["shop"], "map page routes a real mouse click through its decorative chrome to an available node"):
		return

	var event_page = EventPageScript.new()
	root.add_child(event_page)
	event_page.configure({
		"event": {"id": "ash_gate", "name": "灰门", "body": "炉门要求你支付代价。"},
		"node": {"id": "event_1", "name": "灰门"},
		"choices": [
			{"id": "pay", "label": "支付 10 金币", "description": "获得一件遗物。"},
			{"id": "locked", "label": "需要更多金币", "description": "当前不可用。", "blocked_reason": "金币不足"}
		]
	})
	await process_frame
	if not _check(event_page.get_node_or_null("PcEventExperience") != null and event_page.find_child("EventChoiceButtons", true, false) != null, "event page keeps the PC story-room and choice column"):
		return
	if not _check(event_page.find_child("EventChoice_locked", true, false) != null, "event page renders blocked choice with stable identity"):
		return
	var locked_choice := event_page.find_child("EventChoice_locked", true, false) as Button
	if not _check(locked_choice.disabled and locked_choice.tooltip_text.contains("金币不足"), "event page shows disabled reason without enabling the choice"):
		return
	var selected_event_choices: Array[String] = []
	event_page.choice_selected.connect(func(choice_id: String) -> void: selected_event_choices.append(choice_id))
	locked_choice.emit_signal("pressed")
	if not _check(selected_event_choices.is_empty(), "event disabled choice never emits choice_selected"):
		return
	event_page.configure({
		"event": {"id": "spent_gate", "name": "熄灭的灰门", "body": "这里已没有更多决定。"},
		"choices": []
	})
	await process_frame
	var continue_choice := event_page.find_child("EventChoice_continue", true, false) as Button
	var continue_count := [0]
	event_page.continue_requested.connect(func() -> void: continue_count[0] += 1)
	continue_choice.emit_signal("pressed")
	if not _check(continue_count[0] == 1, "event empty choices expose a working continue action"):
		return
	event_page.configure({"event": {"id": "spent_gate", "name": "熄灭的灰门"}, "choices": []})
	await process_frame
	if not _check(event_page.find_child("EventChoice_continue", true, false) != null, "event repeated configure preserves stable choice names"):
		return

	var shop_page = ShopExperienceScript.new()
	root.add_child(shop_page)
	shop_page.configure({
		"mode": "store",
		"gold": 20,
		"remove_price": 75,
		"cards": [
			{"id": "ember_strike", "name": "余烬打击", "price": 30, "description": "造成伤害。"},
			{"id": "sealed_stock", "name": "封存货物", "price": 10, "description": "本应可购买。", "disabled_reason": "本轮已购买"}
		],
		"relics": [{"id": "cold_vial", "name": "冷却余烬瓶", "price": 60, "description": "降低热量。"}],
		"potions": [{"id": "ash_tonic", "name": "灰烬药剂", "price": 20, "description": "恢复生命。", "slots_available": false}],
		"remove_candidates": [{"deck_index": 0, "id": "strike", "name": "打击"}]
	})
	await process_frame
	if not _check(shop_page.find_child("ShopMerchantHero", true, false) != null and shop_page.find_child("ShopGoldHUD", true, false) != null, "shop page has merchant hero and persistent gold HUD"):
		return
	if not _check(shop_page.find_child("ShopCardShelf", true, false) != null and shop_page.find_child("ShopRelicShelf", true, false) != null and shop_page.find_child("ShopPotionShelf", true, false) != null and shop_page.find_child("ShopRemoveCounter", true, false) != null, "shop page separates cards, relics, potions and remove-card counter"):
		return
	var shop_card := shop_page.find_child("ShopCard_ember_strike", true, false) as Button
	if not _check(shop_card != null and shop_card.disabled and shop_card.tooltip_text.contains("金币不足"), "shop page explains unaffordable inventory"):
		return
	var disabled_stock := shop_page.find_child("ShopCard_sealed_stock", true, false) as Button
	var bought_shop_cards: Array[String] = []
	shop_page.buy_card.connect(func(item_id: String) -> void: bought_shop_cards.append(item_id))
	disabled_stock.emit_signal("pressed")
	if not _check(disabled_stock.disabled and disabled_stock.tooltip_text == "本轮已购买" and bought_shop_cards.is_empty(), "shop honors exact disabled reason and emits no purchase"):
		return
	var leave_count := [0]
	shop_page.leave.connect(func() -> void: leave_count[0] += 1)
	var shop_leave := shop_page.find_child("ShopLeaveButton", true, false) as Button
	shop_leave.emit_signal("pressed")
	if not _check(leave_count[0] == 1, "shop store mode exposes a working leave action"):
		return
	shop_page.configure({
		"mode": "remove",
		"gold": 120,
		"remove_price": 75,
		"remove_candidates": [
			{"deck_index": 2, "id": "strike", "name": "打击"},
			{"deck_index": 9, "id": "strike", "name": "打击+"}
		]
	})
	await process_frame
	var remove_two := shop_page.find_child("ShopRemoveCard_2", true, false) as Button
	var remove_nine := shop_page.find_child("ShopRemoveCard_9", true, false) as Button
	var removed_deck_indices: Array[int] = []
	shop_page.remove_card.connect(func(deck_index: int) -> void: removed_deck_indices.append(deck_index))
	remove_nine.emit_signal("pressed")
	if not _check(
		remove_two != null and remove_nine != null
		and removed_deck_indices == [9]
		and not shop_page.find_child("ShopShelves", true, false).visible,
		"shop remove mode keeps duplicate cards distinct by real deck index"
	):
		return
	var cancel_remove_count := [0]
	shop_page.cancel_remove.connect(func() -> void: cancel_remove_count[0] += 1)
	var cancel_remove := shop_page.find_child("ShopRemoveCancel", true, false) as Button
	cancel_remove.emit_signal("pressed")
	if not _check(cancel_remove_count[0] == 1, "shop remove mode exposes an explicit cancel action"):
		return
	shop_page.configure({
		"mode": "remove",
		"gold": 120,
		"remove_price": 75,
		"remove_candidates": [{"deck_index": 9, "id": "strike", "name": "打击+"}]
	})
	await process_frame
	if not _check(shop_page.find_child("ShopRemoveCard_9", true, false) != null, "shop repeated remove configure preserves real-index names"):
		return
	var repeated_store_model := {
		"mode": "store",
		"gold": 120,
		"remove_price": 75,
		"cards": [{"id": "ember_strike", "name": "余烬打击", "price": 30}],
		"relics": [],
		"potions": []
	}
	shop_page.configure(repeated_store_model)
	await process_frame
	shop_page.configure(repeated_store_model)
	await process_frame
	if not _check(shop_page.find_child("ShopCard_ember_strike", true, false) != null, "shop repeated store configure preserves inventory names"):
		return
	var open_remove_count := [0]
	shop_page.open_remove.connect(func() -> void: open_remove_count[0] += 1)
	shop_page.configure({"mode": "unknown", "gold": 999, "remove_price": 1, "cards": repeated_store_model.cards})
	await process_frame
	var unknown_shop_remove := shop_page.find_child("ShopRemoveCounter", true, false) as Button
	unknown_shop_remove.emit_signal("pressed")
	if not _check(
		shop_page.find_child("ShopCard_ember_strike", true, false) == null
		and unknown_shop_remove.disabled and open_remove_count[0] == 0,
		"shop unknown mode falls back to an empty read-only store"
	):
		return

	var campfire_page = CampfirePageScript.new()
	root.add_child(campfire_page)
	campfire_page.configure({
		"mode": "arrival",
		"node": {"id": "fire_1", "name": "废墟锻炉"},
		"hp": 31,
		"max_hp": 70,
		"heal_percent": 30,
		"upgrade_open": false,
		"upgrade_candidates": [{"deck_index": 2, "id": "ash_guard", "name": "灰烬防御", "description": "获得护甲。"}]
	})
	await process_frame
	if not _check(campfire_page.get_node_or_null("PcCampfireExperience") != null and campfire_page.find_child("CampfireRestButton", true, false) != null and campfire_page.find_child("CampfireForgeButton", true, false) != null, "campfire page exposes rest and forge actions"):
		return
	if not _check(campfire_page.find_child("CampfireRestButton", true, false).custom_minimum_size.x >= 44.0 and campfire_page.find_child("CampfireRestButton", true, false).custom_minimum_size.y >= 44.0, "campfire actions keep the shared interactive minimum"):
		return
	if not _check(
		campfire_page.find_child("CampfireUpgrade_2", true, false) == null
		and not campfire_page.find_child("CampfireForgeCandidates", true, false).visible,
		"campfire arrival mode does not expose forge candidates"
	):
		return
	var campfire_leave_count := [0]
	campfire_page.leave.connect(func() -> void: campfire_leave_count[0] += 1)
	var campfire_leave := campfire_page.find_child("CampfireLeaveButton", true, false) as Button
	campfire_leave.emit_signal("pressed")
	if not _check(campfire_leave_count[0] == 1, "campfire arrival mode exposes a working leave action"):
		return
	campfire_page.configure({
		"mode": "forge",
		"node": {"id": "fire_1", "name": "废墟锻炉"},
		"hp": 31,
		"max_hp": 70,
		"heal_percent": 30,
		"upgrade_candidates": [
			{"deck_index": 2, "id": "ash_guard", "name": "灰烬防御", "description": "获得护甲。"},
			{"deck_index": 9, "id": "ash_guard", "name": "灰烬防御+", "description": "获得更多护甲。"}
		]
	})
	await process_frame
	var upgrade_two := campfire_page.find_child("CampfireUpgrade_2", true, false) as Button
	var upgrade_nine := campfire_page.find_child("CampfireUpgrade_9", true, false) as Button
	var upgraded_deck_indices: Array[int] = []
	campfire_page.upgrade_card_requested.connect(func(deck_index: int) -> void: upgraded_deck_indices.append(deck_index))
	upgrade_nine.emit_signal("pressed")
	if not _check(
		upgrade_two != null and upgrade_nine != null
		and upgraded_deck_indices == [9]
		and not campfire_page.find_child("CampfireArrivalActions", true, false).visible,
		"campfire forge mode keeps duplicate cards distinct by real deck index"
	):
		return
	var forge_back_count := [0]
	campfire_page.forge_back_requested.connect(func() -> void: forge_back_count[0] += 1)
	var forge_back := campfire_page.find_child("CampfireForgeBack", true, false) as Button
	forge_back.emit_signal("pressed")
	if not _check(forge_back_count[0] == 1 and upgraded_deck_indices == [9], "campfire forge back never triggers an upgrade"):
		return
	campfire_page.configure({
		"mode": "forge",
		"node": {"id": "fire_1", "name": "废墟锻炉"},
		"upgrade_candidates": [{"deck_index": 9, "id": "ash_guard", "name": "灰烬防御+"}]
	})
	await process_frame
	if not _check(campfire_page.find_child("CampfireUpgrade_9", true, false) != null, "campfire repeated forge configure preserves real-index names"):
		return
	campfire_page.configure({"mode": "unknown", "upgrade_candidates": [{"deck_index": 9, "id": "ash_guard"}]})
	await process_frame
	if not _check(
		campfire_page.find_child("CampfireUpgrade_9", true, false) == null
		and campfire_page.find_child("CampfireRestButton", true, false).disabled
		and campfire_page.find_child("CampfireForgeButton", true, false).disabled,
		"campfire unknown mode falls back to a read-only arrival"
	):
		return

	var reward_page = RewardPageScript.new()
	root.add_child(reward_page)
	reward_page.configure({
		"mode": "combat",
		"gold": 55,
		"cards": [{
			"id": "banked_pressure",
			"name": "蓄压",
			"cost": 2,
			"type": "skill",
			"rarity": "uncommon",
			"description": "保留势能，并在下一回合继续获得额外资源；这是一段故意超过两行显示区域的奖励卡牌说明，用来验证文字不会挤掉能耗信息。"
		}],
		"relics": [{"id": "cold_vial", "name": "冷却余烬瓶", "description": "降低热量。"}],
		"potions": [{"id": "ash_tonic", "name": "灰烬药剂", "description": "恢复生命。"}],
		"card_done": false,
		"relic_done": false,
		"potion_done": false,
		"masteries": [{"id": "pressure_cycle", "name": "压力循环", "description": "保留更多势能。"}],
		"can_continue": false,
		"continue_reason": "先处理全部奖励"
	})
	await process_frame
	if not _check(reward_page.find_child("RewardGoldReceipt", true, false) != null and reward_page.find_child("RewardActionColumn", true, false) != null, "reward page uses receipt then action-column hierarchy"):
		return
	if not _check(reward_page.find_child("RewardCard_banked_pressure", true, false) != null and reward_page.find_child("RewardRelic_cold_vial", true, false) != null and reward_page.find_child("RewardPotion_ash_tonic", true, false) != null, "reward page exposes card, relic and potion stages"):
		return
	var reward_card := reward_page.find_child("RewardCard_banked_pressure", true, false) as Button
	var reward_cost := reward_page.find_child("RewardOfferCost_banked_pressure", true, false) as Label
	var reward_description := reward_page.find_child("RewardOfferDescription_banked_pressure", true, false) as Label
	if not _check(
		reward_cost != null and reward_cost.visible and reward_cost.text == "能耗 2"
		and reward_card.get_global_rect().encloses(reward_cost.get_global_rect()),
		"reward card keeps its energy cost visible inside the bounded offer surface"
	):
		return
	if not _check(
		reward_description != null
		and reward_description.max_lines_visible == 2
		and reward_description.clip_text
		and reward_description.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS
		and reward_card.tooltip_text.contains("故意超过两行显示区域"),
		"reward card clamps long rules text while preserving the full description in its tooltip"
	):
		return
	var skipped_cards := [0]
	var skipped_potions := [0]
	var save_requests := [0]
	var claimed_masteries: Array[String] = []
	var reward_continue_count := [0]
	reward_page.skip_card_requested.connect(func() -> void: skipped_cards[0] += 1)
	reward_page.skip_potion_requested.connect(func() -> void: skipped_potions[0] += 1)
	reward_page.save_requested.connect(func() -> void: save_requests[0] += 1)
	reward_page.claim_mastery.connect(func(mastery_id: String) -> void: claimed_masteries.append(mastery_id))
	reward_page.continue_requested.connect(func() -> void: reward_continue_count[0] += 1)
	var skip_card := reward_page.find_child("RewardSkipCard", true, false) as Button
	var skip_potion := reward_page.find_child("RewardSkipPotion", true, false) as Button
	var save_reward := reward_page.find_child("RewardSaveButton", true, false) as Button
	var mastery_reward := reward_page.find_child("RewardMastery_pressure_cycle", true, false) as Button
	var reward_continue := reward_page.find_child("RewardContinueButton", true, false) as Button
	skip_card.emit_signal("pressed")
	skip_potion.emit_signal("pressed")
	save_reward.emit_signal("pressed")
	mastery_reward.emit_signal("pressed")
	reward_continue.emit_signal("pressed")
	if not _check(
		skipped_cards[0] == 1 and skipped_potions[0] == 1 and save_requests[0] == 1
		and claimed_masteries == ["pressure_cycle"] and reward_continue_count[0] == 0
		and reward_continue.disabled and reward_continue.tooltip_text == "先处理全部奖励"
		and reward_continue.focus_mode == Control.FOCUS_NONE
		and reward_continue.mouse_default_cursor_shape == Control.CURSOR_ARROW,
		"combat reward exposes split actions and enforces the exact continue gate"
	):
		return
	reward_page.configure({
		"mode": "treasure",
		"gold": 80,
		"cards": [],
		"relics": [{"id": "ember_key", "name": "余烬钥匙", "description": "开启下一道门。"}],
		"potions": [],
		"relic_done": false,
		"can_continue": true
	})
	await process_frame
	var treasure_continue := reward_page.find_child("RewardContinueButton", true, false) as Button
	treasure_continue.emit_signal("pressed")
	if not _check(
		reward_page.find_child("RewardSkipCard", true, false) == null
		and reward_page.find_child("RewardSkipPotion", true, false) == null
		and reward_page.find_child("RewardSaveButton", true, false) == null
		and reward_page.find_child("RewardMastery_pressure_cycle", true, false) == null
		and reward_page.find_child("RewardRelic_ember_key", true, false) != null
		and reward_continue_count[0] == 1,
		"treasure reward hides combat-only actions and keeps continue available"
	):
		return
	reward_page.configure({"mode": "unknown", "can_continue": true, "relics": [{"id": "unsafe", "name": "不应显示"}]})
	await process_frame
	if not _check(
		reward_page.find_child("RewardRelic_unsafe", true, false) == null
		and reward_page.find_child("RewardSaveButton", true, false) == null
		and reward_page.find_child("RewardContinueButton", true, false).disabled,
		"reward unknown mode falls back to a read-only combat state"
	):
		return

	root.remove_child(map_page)
	map_page.free()
	root.remove_child(event_page)
	event_page.free()
	root.remove_child(shop_page)
	shop_page.free()
	root.remove_child(campfire_page)
	campfire_page.free()
	root.remove_child(reward_page)
	reward_page.free()
	choice_row.free()
	item_shelf.free()
	card_compare.free()
	print("PASS: ember forge route rooms")
	quit()

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: %s" % message)
	quit(1)
	return false

func _click_control(control: Control) -> void:
	if control == null:
		return
	var click_position := control.get_global_rect().get_center()
	for is_pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = click_position
		event.global_position = click_position
		event.pressed = is_pressed
		root.push_input(event)
