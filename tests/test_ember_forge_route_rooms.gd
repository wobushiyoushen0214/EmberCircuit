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
		"available_width": 1280.0,
		"available_height": 720.0
	})
	await process_frame
	if not _check(map_page.get_node_or_null("EmberMapView") != null and map_page.node_selected.get_connections().size() >= 0, "map page owns the original map view signal surface"):
		return
	if not _check(map_page.find_child("MapRiskSummary", true, false) != null and map_page.find_child("MapRoutePreview", true, false) != null, "map page exposes risk and successor preview hierarchy"):
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

	var shop_page = ShopExperienceScript.new()
	root.add_child(shop_page)
	shop_page.configure({
		"gold": 20,
		"remove_price": 75,
		"cards": [{"id": "ember_strike", "name": "余烬打击", "price": 30, "description": "造成伤害。"}],
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

	var campfire_page = CampfirePageScript.new()
	root.add_child(campfire_page)
	campfire_page.configure({
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

	var reward_page = RewardPageScript.new()
	root.add_child(reward_page)
	reward_page.configure({
		"mode": "combat",
		"gold": 55,
		"cards": [{"id": "banked_pressure", "name": "蓄压", "description": "保留势能。"}],
		"relics": [{"id": "cold_vial", "name": "冷却余烬瓶", "description": "降低热量。"}],
		"potions": [{"id": "ash_tonic", "name": "灰烬药剂", "description": "恢复生命。"}],
		"card_done": false,
		"relic_done": false,
		"potion_done": false
	})
	await process_frame
	if not _check(reward_page.find_child("RewardGoldReceipt", true, false) != null and reward_page.find_child("RewardActionColumn", true, false) != null, "reward page uses receipt then action-column hierarchy"):
		return
	if not _check(reward_page.find_child("RewardCard_banked_pressure", true, false) != null and reward_page.find_child("RewardRelic_cold_vial", true, false) != null and reward_page.find_child("RewardPotion_ash_tonic", true, false) != null, "reward page exposes card, relic and potion stages"):
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
