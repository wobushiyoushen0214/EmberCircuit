extends SceneTree

const OutcomePageScript = preload("res://scripts/ui/pages/OutcomePage.gd")
const OutcomeStageScript = preload("res://scripts/ui/components/OutcomeStage.gd")
const SettingsPageScript = preload("res://scripts/ui/pages/SettingsPage.gd")
const CompendiumPageScript = preload("res://scripts/ui/pages/CompendiumPage.gd")
const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManagerScript.set_storage_namespace("test_ui_outcome_settings_compendium")
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())

	var stage = OutcomeStageScript.new()
	if not _check(stage != null, "outcome stage instantiates"):
		return

	var victory = OutcomePageScript.new()
	root.add_child(victory)
	victory.configure({
		"mode": "victory",
		"title": "核心已封锁",
		"subtitle": "三章通关",
		"stats": {"hp": 38, "max_hp": 70, "gold": 122, "deck_size": 18},
		"unlocks": ["炉印 +2"],
		"persistence_error": ""
	})
	await process_frame
	if not _check(victory.name == "RunCompletionPanel", "victory keeps RunCompletionPanel identity"):
		return
	if not _check(victory.find_child("OutcomeStats", true, false) != null and victory.find_child("OutcomeContinueButton", true, false) != null, "victory exposes stats and continue action"):
		return
	var outcome_root := victory.find_child("OutcomeRoot", true, false) as VBoxContainer
	if not _check(outcome_root != null and outcome_root.size_flags_vertical == Control.SIZE_EXPAND_FILL, "outcome stage fills the PC page while actions remain anchored below"):
		return

	var defeat = OutcomePageScript.new()
	root.add_child(defeat)
	defeat.configure({
		"mode": "defeat",
		"title": "回路熄灭",
		"subtitle": "终局存储需要重试",
		"stats": {"hp": 0, "max_hp": 70, "gold": 22, "deck_size": 14},
		"unlocks": [],
		"persistence_error": "终局存档写入失败"
	})
	await process_frame
	if not _check(defeat.name == "PcDefeatExperience", "defeat keeps PcDefeatExperience identity"):
		return
	var retry := defeat.find_child("DefeatCleanupRetryButton", true, false) as Button
	if not _check(retry != null and not retry.disabled and retry.tooltip_text.contains("终局存档"), "defeat exposes persistence retry without enabling restart"):
		return
	if not _check((defeat.find_child("DefeatRetryButton", true, false) as Button).disabled, "defeat restart remains disabled while persistence is unresolved"):
		return

	var settings = SettingsPageScript.new()
	root.add_child(settings)
	settings.configure({
		"settings": {
			"audio_enabled": true,
			"master_volume": 0.8,
			"music_enabled": true,
			"music_volume": 0.5,
			"screen_shake_enabled": true,
			"hit_stop_enabled": true,
			"floating_text_enabled": true,
			"tutorial_enabled": true,
			"reduced_motion": false,
			"flash_intensity": 0.75,
			"particle_density": 0.5
		},
		"source_page": "map",
		"available_width": 1280.0,
		"available_height": 720.0
	})
	await process_frame
	for group_name in ["SettingsAudioGroup", "SettingsFeedbackGroup", "SettingsAccessibilityGroup", "SettingsTutorialGroup"]:
		if not _check(settings.find_child(group_name, true, false) != null, "settings exposes group %s" % group_name):
			return
	var reduced_motion := settings.find_child("SettingsReducedMotion", true, false) as CheckButton
	var flash_slider := settings.find_child("SettingsFlashIntensity", true, false) as HSlider
	var particle_slider := settings.find_child("SettingsParticleDensity", true, false) as HSlider
	if not _check(reduced_motion != null and flash_slider != null and particle_slider != null, "settings exposes accessibility motion controls"):
		return
	if not _check(reduced_motion.custom_minimum_size.y >= 44.0 and flash_slider.custom_minimum_size.y >= 44.0, "settings interactive controls keep 44px minimum"):
		return
	if not _check(is_equal_approx(flash_slider.value, 0.75) and is_equal_approx(particle_slider.value, 0.5), "settings displays normalized effect values"):
		return
	var reset_button := settings.find_child("SettingsResetButton", true, false) as Button
	if not _check(reset_button != null and settings.find_child("SettingsResetConfirm", true, false) != null, "settings keeps explicit reset confirmation"):
		return
	var settings_grid := settings.find_child("SettingsDesktopGrid", true, false) as GridContainer
	if not _check(settings_grid != null and settings_grid.columns == 2, "desktop settings uses a compact two-column group grid"):
		return
	if not _check(settings.find_child("SettingsPageTitle", true, false) != null and settings.find_child("SettingsFooter", true, false) != null, "settings exposes a stable header and footer hierarchy"):
		return

	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(main)
	await process_frame
	await process_frame
	main._on_settings_pressed()
	await process_frame
	if not _check(main.app_shell.visible and not main.page_scroll.visible and main.app_shell.active_page_id == "settings", "real settings route mounts the full-screen AppShell page"):
		return
	if not _check(main.app_shell.active_page != null and main.app_shell.active_page.name == "SettingsPage" and main.last_settings_panel_visible and main.last_settings_button_count >= 13, "real settings route keeps legacy probes while rendering SettingsPage"):
		return
	main._on_close_settings_pressed()
	await process_frame
	if not _check(main.app_shell.active_page_id == "welcome", "closing settings restores its welcome source page"):
		return
	main._on_compendium_pressed()
	await process_frame
	if not _check(main.app_shell.visible and not main.page_scroll.visible and main.app_shell.active_page_id == "compendium", "real compendium route mounts the full-screen AppShell page"):
		return
	var mounted_compendium := main.app_shell.active_page as Control
	if not _check(mounted_compendium != null and mounted_compendium.name == "CompendiumPage" and main.last_compendium_panel_visible and main.last_compendium_tab_button_count == 8, "real compendium route keeps legacy probes while rendering CompendiumPage"):
		return
	var hidden_first_card: Dictionary = main.card_data.get("cards", [])[0]
	if not _check(not _node_text(mounted_compendium).contains(str(hidden_first_card.get("name", ""))), "real compendium VM does not leak undiscovered names into the mounted page"):
		return
	main._on_close_compendium_pressed()
	await process_frame
	if not _check(main.app_shell.active_page_id == "welcome", "closing compendium restores its welcome source page"):
		return
	main.welcome_open = false
	main.character_select_open = false
	main.run_completed = true
	main.completed_chapter_ids = ["chapter_one", "chapter_two", "chapter_three"]
	main.run_hp = 38
	main.run_max_hp = 70
	main.run_gold = 122
	main.run_deck_ids = ["ember_strike", "ash_guard"]
	main._refresh()
	await process_frame
	if not _check(main.app_shell.visible and not main.page_scroll.visible and main.app_shell.active_page_id == "outcome", "real victory route mounts the full-screen outcome page"):
		return
	if not _check(main.app_shell.active_page != null and main.app_shell.active_page.name == "RunCompletionPanel" and main.last_run_completion_panel_visible and main.last_run_completion_action_count >= 3, "real victory route keeps completion identity and probes"):
		return
	main.run_completed = false
	main._on_character_selected("ember_exile")
	main.combat.phase = "lost"
	main.combat.player["hp"] = 0
	main._refresh()
	await process_frame
	if not _check(main.app_shell.visible and not main.page_scroll.visible and main.app_shell.active_page_id == "outcome", "real defeat route mounts the full-screen outcome page"):
		return
	if not _check(main.app_shell.active_page != null and main.app_shell.active_page.name == "PcDefeatExperience" and main.last_defeat_panel_visible and main.last_defeat_action_count >= 4, "real defeat route keeps outcome identity and probes"):
		return

	var compendium = CompendiumPageScript.new()
	root.add_child(compendium)
	compendium.configure({
		"selected_tab": "cards",
		"selected_filter": "all",
		"selected_sort": "name",
		"query": "",
		"available_width": 1280.0,
		"available_height": 720.0,
		"categories": ["cards", "relics", "potions", "enemies", "events", "challenges"],
		"filters": [{"id": "all", "label": "全部"}, {"id": "attack", "label": "攻击"}],
		"sorts": [{"id": "name", "label": "名称"}, {"id": "cost", "label": "费用"}],
		"items": [
			{"id": "ember_strike", "kind": "card", "discovered": true, "title": "余烬打击", "subtitle": "攻击", "body": "造成伤害。"},
			{"id": "secret_card", "kind": "card", "discovered": false, "title": "绝密卡牌", "subtitle": "稀有", "body": "泄露数值 999", "tooltip": "隐藏设计注释"},
			{"id": "cold_vial", "kind": "relic", "discovered": true, "title": "冷却余烬瓶", "body": "降低热量。"},
			{"id": "ash_gate", "kind": "event", "discovered": true, "title": "灰门", "body": "事件记录。"}
		]
	})
	await process_frame
	if not _check(compendium.find_child("CompendiumRail", true, false) != null and compendium.find_children("CompendiumTab_*", "Button", true, false).size() == 6, "compendium exposes six-category rail"):
		return
	if not _check(compendium.find_child("CompendiumSearch", true, false) != null and compendium.find_child("CompendiumCardTemplate", true, false) != null and compendium.find_child("CompendiumRelicTemplate", true, false) != null and compendium.find_child("CompendiumEventTemplate", true, false) != null, "compendium exposes search and content templates"):
		return
	var filter_control := compendium.find_child("CompendiumFilter", true, false) as OptionButton
	var sort_control := compendium.find_child("CompendiumSort", true, false) as OptionButton
	if not _check(filter_control != null and sort_control != null and filter_control.item_count == 2 and sort_control.item_count == 2 and filter_control.custom_minimum_size.y >= 44.0, "compendium exposes keyboard-sized filter and sort controls from its VM"):
		return
	var compendium_grid := compendium.find_child("CompendiumItems", true, false) as GridContainer
	if not _check(compendium_grid != null and compendium_grid.columns == 2 and compendium.find_child("CompendiumPageTitle", true, false) != null, "desktop compendium uses a two-column content grid and page header"):
		return
	var locked := compendium.find_child("CompendiumItem_secret_card", true, false) as Control
	if not _check(locked != null and not _node_text(locked).contains("绝密卡牌") and not _node_text(locked).contains("999") and not locked.tooltip_text.contains("隐藏设计注释"), "locked compendium item leaks no hidden details"):
		return
	compendium.configure({
		"selected_tab": "cards",
		"query": "不存在",
		"categories": ["cards", "relics", "potions", "enemies", "events", "challenges"],
		"items": []
	})
	await process_frame
	if not _check(compendium.find_child("CompendiumEmptyState", true, false) != null and compendium.find_child("CompendiumClearSearchButton", true, false) != null, "compendium empty state provides recovery action"):
		return

	victory.queue_free()
	defeat.queue_free()
	settings.queue_free()
	compendium.queue_free()
	stage.queue_free()
	main.queue_free()
	await process_frame
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
	print("PASS: ui outcome compatibility")
	quit()

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: %s" % message)
	quit(1)
	return false

func _node_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	if node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		parts.append(_node_text(child))
	return "\n".join(parts)
