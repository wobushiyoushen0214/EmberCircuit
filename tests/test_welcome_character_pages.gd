extends SceneTree

const WelcomePageScript = preload("res://scripts/ui/pages/WelcomePage.gd")
const CharacterSelectPageScript = preload("res://scripts/ui/pages/CharacterSelectPage.gd")
const AppShellScript = preload("res://scripts/ui/AppShell.gd")
const CharacterStageCardScript = preload("res://scripts/ui/components/CharacterStageCard.gd")

var failed := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var welcome = WelcomePageScript.new()
	root.add_child(welcome)
	welcome.configure({
		"continue_available": false,
		"title": "EmberCircuit / 余烬回路",
		"subtitle": "穿过失控回路，关闭核心。",
		"available_width": 1280.0
	})
	await process_frame
	if not _check(welcome.get_node_or_null("MenuScrim") != null and welcome.find_child("BrandStage", true, false) != null, "welcome is a full-screen game menu instead of a reward-card row"):
		return
	if not _check(welcome.primary_action != null and welcome.primary_action.title_label.text == "开始新跑团", "welcome exposes primary new-run action"):
		return
	var primary_index := welcome.primary_action.find_child("CommandIndex", true, false) as Label
	var primary_chevron := welcome.primary_action.find_child("CommandChevron", true, false) as Label
	var primary_rail := welcome.primary_action.find_child("CommandAccentRail", true, false) as ColorRect
	if not _check(primary_index != null and primary_index.text == "01" and primary_chevron != null and primary_rail != null, "welcome primary action uses a dedicated game-menu command hierarchy"):
		return
	if not _check(welcome.primary_action.size.x >= 360.0 and welcome.primary_action.size.x <= 440.0 and welcome.primary_action.size.y >= 60.0 and welcome.primary_action.size.y <= 72.0, "welcome primary command keeps a compact game-menu proportion instead of an input-field strip"):
		return
	var primary_focus_style := welcome.primary_action.get_theme_stylebox("focus") as StyleBoxFlat
	if not _check(primary_focus_style != null and primary_focus_style.border_width_left >= 2 and primary_focus_style.border_width_top == 0 and primary_focus_style.border_width_right == 0 and primary_focus_style.border_width_bottom == 0, "welcome focus uses a command rail instead of a bright perimeter box"):
		return
	if not _check(welcome.secondary_action != null and welcome.secondary_action.title_label.text == "继续跑团" and welcome.secondary_action.disabled, "welcome disables continue without save"):
		return
	if not _check(welcome.secondary_action.tooltip_text.contains("没有") or welcome.secondary_action.body_label.text.contains("没有"), "welcome explains disabled continue reason"):
		return
	if not _check(welcome.secondary_action.title_label.get_theme_color("font_color") == Color("9a9288") and welcome.secondary_action.mouse_default_cursor_shape == Control.CURSOR_ARROW, "welcome disabled continue applies a real disabled content and cursor state"):
		return
	if not _check(welcome.tool_action != null and welcome.tool_action.title_label.text == "回路档案", "welcome keeps archive in utility tier"):
		return
	if not _check(welcome.profile_action != null and welcome.settings_action != null and welcome.find_child("UtilityActionRow", true, false) != null, "welcome consolidates profile, archive and settings into one utility row"):
		return
	var utility_style := welcome.profile_action.get_theme_stylebox("normal") as StyleBoxFlat
	if not _check(utility_style != null and utility_style.border_width_left == 0 and utility_style.border_width_top == 0 and utility_style.border_width_right == 0 and utility_style.border_width_bottom == 0, "welcome utility commands remain quiet without three decorative underlines"):
		return
	if not _check(welcome.find_child("MenuFooter", true, false) == null, "welcome removes prototype-style feature copy below the command stack"):
		return
	if not _check(welcome.primary_action.has_focus(), "welcome gives real initial keyboard focus to the primary command"):
		return
	var next_focus := welcome.primary_action.get_node_or_null(welcome.primary_action.focus_neighbor_bottom) as Control
	if not _check(next_focus == welcome.profile_action, "welcome focus order skips unavailable continue and reaches the first utility command"):
		return
	var new_run_count := [0]
	welcome.new_run_requested.connect(func() -> void: new_run_count[0] += 1)
	welcome.request_new_run()
	if not _check(new_run_count[0] == 1, "welcome emits new run signal"):
		return
	var mounted_host := HFlowContainer.new()
	root.add_child(mounted_host)
	var mounted_shell = AppShellScript.new()
	root.add_child(mounted_shell)
	mounted_shell.set_page_host(mounted_host)
	var mounted_welcome = WelcomePageScript.new()
	mounted_welcome.configure({"continue_available": true})
	mounted_shell.mount_page(mounted_welcome, "welcome")
	if not _check(mounted_host.get_child_count() == 1, "AppShell mounts one complete page root"):
		return
	if not _check(mounted_host.get_child(0) == mounted_welcome, "AppShell keeps the page root instead of flattening its children"):
		return
	if not _check(mounted_welcome.find_child("PageHeader", true, false) == mounted_welcome.header and mounted_welcome.is_ancestor_of(mounted_welcome.header), "AppShell preserves the complete welcome hierarchy inside the mounted page root"):
		return

	var portrait_image := Image.create(100, 180, false, Image.FORMAT_RGBA8)
	portrait_image.fill(Color(0.8, 0.3, 0.1, 1.0))
	var portrait_texture := ImageTexture.create_from_image(portrait_image)
	var character = CharacterSelectPageScript.new()
	root.add_child(character)
	character.configure({
		"selected_character_id": "ember_exile",
		"selected_challenge_level": 0,
		"unlocked_challenge_max": 0,
		"characters": [
			{"id": "ember_exile", "name": "余烬流亡者", "archetype": "均衡攻防与势能循环。", "max_hp": 70, "max_energy": 3, "starting_momentum": 0, "momentum_max": 6, "relic_names": "冷却余烬瓶、裂纹护符", "deck_count": 10, "deck_summary": "余烬打击 x5、灰烬防御 x4、冷却吐息 x1", "texture": portrait_texture},
			{"id": "arc_tinker", "name": "电弧工匠", "archetype": "零费序列与药水窗口。", "max_hp": 69, "max_energy": 3, "starting_momentum": 1, "momentum_max": 5, "relic_names": "蓝弧电容、绝缘电池", "deck_count": 10, "deck_summary": "火花投掷 x3、压力探针 x2"},
			{"id": "pyre_ascetic", "name": "熔痕苦修者", "archetype": "自伤与灼伤转化。", "max_hp": 70, "max_energy": 3, "starting_momentum": 0, "momentum_max": 7, "relic_names": "苦修香炉、灰烬念珠", "deck_count": 10, "deck_summary": "苦修斩 x2、裂痕防御 x4"}
		],
		"challenges": [
			{"level": 0, "short_name": "普通", "description": "标准三章跑团。"},
			{"level": 1, "short_name": "挑战 1", "description": "敌人生命提高。"},
			{"level": 2, "short_name": "挑战 2", "description": "灼热开局。"},
			{"level": 3, "short_name": "挑战 3", "description": "高压意图。"}
		],
		"available_width": 1280.0,
		"compact": false
	})
	await process_frame
	if not _check(character.get_node_or_null("CharacterPageHeader") != null and character.get_node_or_null("CharacterFooter") != null, "character selection has a stable header, stage and footer hierarchy"):
		return
	if not _check(character.cards.size() == 3, "character page renders three playable cards"):
		return
	if not _check(character.challenge_buttons.size() == 4 and character.challenge_buttons[0].text.contains("普通") and character.challenge_buttons[3].text.contains("3"), "character page renders the complete configured challenge track"):
		return
	if not _check(character.challenge_buttons[1].disabled and character.challenge_buttons[2].disabled and character.challenge_buttons[3].disabled, "locked challenge levels are disabled through the configured maximum"):
		return
	for locked_challenge in character.challenge_buttons.slice(1):
		if not _check(locked_challenge.mouse_default_cursor_shape == Control.CURSOR_ARROW and locked_challenge.focus_mode == Control.FOCUS_NONE, "locked challenges expose a non-interactive cursor and leave the focus order"):
			return
	if not _check(character.confirm_button != null and character.confirm_button.text.contains("余烬流亡者"), "character page keeps stable confirmation action"):
		return
	var selected_stage = character.character_stages[0]
	if not _check(selected_stage is CharacterStageCardScript and selected_stage.selection_state_label.text.contains("已选择"), "selected character has an explicit non-color state"):
		return
	var focused_portrait := selected_stage.portrait.texture as AtlasTexture
	if not _check(focused_portrait != null and focused_portrait.region.position.y == 0.0 and focused_portrait.region.size.y < portrait_texture.get_height(), "character stage crops the upper-body focal region instead of center-cutting faces"):
		return
	if not _check(selected_stage.relic_label.text.contains("冷却余烬瓶") and selected_stage.deck_button.tooltip_text.contains("余烬打击"), "character stage preserves relic and starter-deck information"):
		return
	var card_focus := character.cards[0].get_theme_stylebox("focus") as StyleBoxFlat
	if not _check(card_focus != null and card_focus.border_width_left >= 2, "character cards use a visible two-pixel keyboard focus ring"):
		return
	if not _check(character.cards[0].has_focus(), "character page gives real initial focus to the selected character"):
		return
	var preview_id := [""]
	character.character_preview_requested.connect(func(id: String) -> void: preview_id[0] = id)
	character.cards[1].emit_signal("pressed")
	if not _check(preview_id[0] == "arc_tinker" and not character.confirm_button.disabled, "character preview emits without confirming run"):
		return
	var challenge_level := [-1]
	character.challenge_delta_requested.connect(func(level: int) -> void: challenge_level[0] = level)
	character.challenge_buttons[0].emit_signal("pressed")
	if not _check(challenge_level[0] == 0, "challenge selection emits selected level"):
		return
	selected_stage.deck_button.emit_signal("pressed")
	if not _check(character.deck_preview_overlay.visible and character.deck_preview_label.text.contains("余烬打击"), "starter deck opens in an in-page detail overlay"):
		return
	character.close_deck_preview()
	if not _check(not character.deck_preview_overlay.visible, "starter deck detail overlay has an explicit close path"):
		return
	root.remove_child(character)
	var character_layout_shell = AppShellScript.new()
	root.add_child(character_layout_shell)
	if not _check(character_layout_shell.mount_page(character, "character_layout"), "character page mounts into the full-screen app shell"):
		return
	await process_frame
	await process_frame
	var desktop_roster := character.get_node_or_null("CharacterRoster") as Control
	if not _check(desktop_roster != null and desktop_roster.size.x <= character.size.x - 39.0 and desktop_roster.size.y <= character.size.y - 160.0, "character roster cannot retain a transient doubled viewport size"):
		return
	for stage in character.character_stages:
		var portrait_stage := stage.find_child("PortraitStage", true, false) as Control
		if not _check(stage.position.y <= 1.0 and stage.position.x + stage.size.x <= desktop_roster.size.x + 1.0 and stage.size.y <= desktop_roster.size.y + 1.0, "all desktop character stages remain on one visible bounded row"):
			return
		if not _check(portrait_stage != null and portrait_stage.position.y <= 64.0, "character portrait starts near the top instead of being vertically centered below an empty panel"):
			return
		if not _check(portrait_stage.size.y >= 288.0, "desktop character portrait consumes the available card height instead of staying at a fixed 270 pixels"):
			return

	var compact_character = CharacterSelectPageScript.new()
	root.add_child(compact_character)
	compact_character.configure({
		"selected_character_id": "ember_exile",
		"selected_challenge_level": 0,
		"unlocked_challenge_max": 0,
		"characters": [{"id": "ember_exile", "name": "余烬流亡者", "deck_count": 10, "deck_summary": "余烬打击 x5"}],
		"challenges": [{"level": 0, "short_name": "普通", "description": "标准三章跑团。"}],
		"compact": true,
		"available_width": 360.0
	})
	await process_frame
	if not _check(compact_character.get_node_or_null("CharacterRosterScroll") != null and compact_character.get_node_or_null("CharacterFooterCompact") != null, "compact character selection uses bounded horizontal stages and a stacked footer"):
		return
	root.remove_child(welcome)
	welcome.free()
	root.remove_child(character_layout_shell)
	character_layout_shell.free()
	root.remove_child(compact_character)
	compact_character.free()
	root.remove_child(mounted_shell)
	mounted_shell.free()
	root.remove_child(mounted_host)
	mounted_host.free()
	print("PASS: welcome character pages")
	quit()

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	failed = true
	printerr("FAIL: %s" % message)
	quit(1)
	return false
