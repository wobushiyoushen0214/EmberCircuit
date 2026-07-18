extends PanelContainer

signal continue_requested
signal retry_requested
signal new_run_requested
signal deck_requested
signal export_requested
signal profile_requested

const OutcomeStageScript = preload("res://scripts/ui/components/OutcomeStage.gd")
const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _mode := "victory"
var _root_box: VBoxContainer

func _init() -> void:
	name = "OutcomePage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	_root_box = VBoxContainer.new()
	_root_box.name = "OutcomeRoot"
	_root_box.add_theme_constant_override("separation", 10)
	_root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_root_box)

func configure(model: Dictionary) -> void:
	_mode = str(model.get("mode", "victory"))
	name = "RunCompletionPanel" if _mode == "victory" else "PcDefeatExperience"
	_root_box.name = "OutcomeRoot"
	custom_minimum_size = Vector2(max(640.0, float(model.get("available_width", 960.0))), max(360.0, float(model.get("available_height", 520.0))))
	size = custom_minimum_size
	_clear()
	if _mode == "victory":
		_build_victory(model)
	else:
		_build_defeat(model)

func _build_victory(model: Dictionary) -> void:
	var body := HBoxContainer.new()
	body.name = "RunCompletionBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	_root_box.add_child(body)
	var scene := _new_scene_panel("RunCompletionScene", model, false)
	scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scene)
	var details := OutcomeStageScript.new()
	details.name = "RunCompletionDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.configure(model)
	body.add_child(details)
	var actions := _new_actions("RunCompletionActions")
	_root_box.add_child(actions)
	_add_action(actions, "OutcomeContinueButton", "再来一局", "primary", func() -> void: continue_requested.emit())
	_add_action(actions, "OutcomeDeckButton", "查看最终牌组", "secondary", func() -> void: deck_requested.emit())
	_add_action(actions, "OutcomeExportButton", "导出试玩报告", "utility", func() -> void: export_requested.emit())
	_add_action(actions, "OutcomeProfileButton", "打开档案", "utility", func() -> void: profile_requested.emit())

func _build_defeat(model: Dictionary) -> void:
	var body := HBoxContainer.new()
	body.name = "DefeatBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	_root_box.add_child(body)
	var scene := _new_scene_panel("DefeatScene", model, true)
	scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scene)
	var summary := OutcomeStageScript.new()
	summary.name = "DefeatSummary"
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.configure(model)
	body.add_child(summary)
	var actions := _new_actions("DefeatActions")
	_root_box.add_child(actions)
	_add_action(actions, "DefeatDeckButton", "最终牌组", "primary", func() -> void: deck_requested.emit())
	_add_action(actions, "DefeatExportButton", "导出报告", "event", func() -> void: export_requested.emit())
	_add_action(actions, "DefeatProfileButton", "局外档案", "relic", func() -> void: profile_requested.emit())
	var persistence_error := str(model.get("persistence_error", ""))
	if not persistence_error.is_empty():
		var save_retry := _add_action(actions, "DefeatCleanupRetryButton", "重试保存", "danger", func() -> void: retry_requested.emit())
		save_retry.tooltip_text = persistence_error
	var restart := _add_action(actions, "DefeatRetryButton", "重新出发", "success", func() -> void: new_run_requested.emit())
	restart.disabled = not persistence_error.is_empty()
	restart.tooltip_text = "请先完成终局存储重试。" if restart.disabled else "开始新的跑团。"

func _new_scene_panel(node_name: String, model: Dictionary, defeat: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = Vector2(420, 300)
	panel.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	var stack := Control.new()
	stack.name = "OutcomeSceneStack"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(stack)
	var background := TextureRect.new()
	background.name = "DefeatBackground" if defeat else "RunCompletionBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_path := str(model.get("art_path", ""))
	if art_path.is_empty():
		art_path = "res://assets/art/battle_bg_chapter_one.svg"
	background.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	background.set_meta("art_path", art_path)
	background.set_meta("chapter_id", str(model.get("chapter_id", "")))
	stack.add_child(background)
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.02, 0.025, 0.03, 0.62)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(scrim)
	if defeat:
		var player := TextureRect.new()
		player.name = "DefeatedPlayer"
		player.custom_minimum_size = Vector2(180, 220)
		player.position = Vector2(18, 22)
		player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var player_path := str(model.get("player_art_path", ""))
		player.texture = load(player_path) if ResourceLoader.exists(player_path) else null
		player.set_meta("character_id", str(model.get("character_id", "")))
		player.set_meta("art_path", player_path)
		stack.add_child(player)
		var survivors: Array = model.get("surviving_enemies", [])
		for index in range(min(3, survivors.size())):
			var enemy: Dictionary = survivors[index]
			var slot := PanelContainer.new()
			slot.name = "DefeatEnemy_%d" % index
			slot.custom_minimum_size = Vector2(100, 78)
			slot.position = Vector2(230 + index * 108, 34)
			slot.set_meta("enemy_id", str(enemy.get("id", "")))
			slot.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
			var label := Label.new()
			label.text = str(enemy.get("name", enemy.get("id", "敌人")))
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(label)
			stack.add_child(slot)
	return panel

func _new_actions(node_name: String) -> HBoxContainer:
	var actions := HBoxContainer.new()
	actions.name = node_name
	actions.custom_minimum_size = Vector2(0, 48)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	return actions

func _add_action(parent: Container, node_name: String, label: String, variant: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(148, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style(variant, "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _clear() -> void:
	for child in _root_box.get_children():
		child.queue_free()
	for child in get_children():
		if child != _root_box:
			child.queue_free()
