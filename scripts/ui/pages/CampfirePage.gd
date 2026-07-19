extends Control

signal rest_requested
signal forge_requested
signal upgrade_card_requested(deck_index: int)
signal forge_back_requested
signal leave

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _arrival_actions: VBoxContainer
var _forge_panel: VBoxContainer
var _candidate_column: VBoxContainer
var _rest_button: Button
var _forge_button: Button
var _room_art: TextureRect
var _vital_gauge: ProgressBar
var _vital_label: Label

func _init() -> void:
	name = "CampfirePage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var requested_mode := str(model.get("mode", "arrival"))
	var mode := requested_mode if requested_mode == "arrival" or requested_mode == "forge" else "arrival"
	var model_is_safe := requested_mode == "arrival" or requested_mode == "forge"
	var node: Dictionary = model.get("node", {})
	var stage := get_node("PcCampfireExperience")
	var story := stage.find_child("CampfireStory", true, false)
	var title := story.find_child("CampfireTitle", true, false) as Label
	var body := story.find_child("CampfireBody", true, false) as Label
	if title != null:
		title.text = str(node.get("name", "废墟锻炉"))
	var hp := int(model.get("hp", 0))
	var max_hp: int = maxi(1, int(model.get("max_hp", 1)))
	var heal_percent := int(model.get("heal_percent", 30))
	_room_art.texture = _load_texture(str(model.get("art_path", "")))
	_vital_gauge.max_value = max_hp
	_vital_gauge.value = clampi(hp, 0, max_hp)
	_vital_label.text = "炉行者生命  %d / %d" % [hp, max_hp]
	if body != null:
		body.text = (
			"选择一张牌，将它送入余烬锻炉。" if mode == "forge"
			else "当前生命 %d/%d。休息恢复 %d%%，或锻造升级一张牌。" % [hp, max_hp, heal_percent]
		)
	_rest_button.text = "休息\n恢复 %d%%" % heal_percent
	_rest_button.disabled = not model_is_safe
	_rest_button.focus_mode = Control.FOCUS_NONE if _rest_button.disabled else Control.FOCUS_ALL
	_rest_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if _rest_button.disabled else Control.CURSOR_POINTING_HAND
	_clear_candidates()
	var candidates: Array = model.get("upgrade_candidates", [])
	_forge_button.disabled = candidates.is_empty() or not model_is_safe
	_forge_button.tooltip_text = "页面状态不可用" if not model_is_safe else ("没有可升级卡牌" if candidates.is_empty() else "打开锻造选择")
	_forge_button.focus_mode = Control.FOCUS_NONE if _forge_button.disabled else Control.FOCUS_ALL
	_forge_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if _forge_button.disabled else Control.CURSOR_POINTING_HAND
	_arrival_actions.visible = mode == "arrival"
	_forge_panel.visible = mode == "forge"
	_candidate_column.visible = mode == "forge"
	if mode != "forge":
		return
	if candidates.is_empty():
		var empty := Label.new()
		empty.name = "CampfireForgeEmpty"
		empty.text = "没有可升级卡牌。"
		_candidate_column.add_child(empty)
	else:
		for raw in candidates:
			if not raw is Dictionary:
				continue
			var candidate: Dictionary = raw
			var index := int(candidate.get("deck_index", 0))
			var button := Button.new()
			button.name = "CampfireUpgrade_%d" % index
			button.custom_minimum_size = Vector2(260, 56)
			button.text = "%s\n%s" % [str(candidate.get("name", candidate.get("id", "卡牌"))), str(candidate.get("description", ""))]
			button.pressed.connect(func() -> void: upgrade_card_requested.emit(index))
			_apply_button(button, "secondary")
			_candidate_column.add_child(button)

func _build_shell() -> void:
	var stage := PanelContainer.new()
	stage.name = "PcCampfireExperience"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_left = 24
	stage.offset_right = -24
	stage.offset_top = 24
	stage.offset_bottom = -24
	stage.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	add_child(stage)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	stage.add_child(split)
	var story := VBoxContainer.new()
	story.name = "CampfireStory"
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.add_theme_constant_override("separation", 10)
	split.add_child(story)
	var eyebrow := Label.new()
	eyebrow.text = "安全节点  /  一次整备机会"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption", 12))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	story.add_child(eyebrow)
	var title := Label.new()
	title.name = "CampfireTitle"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	story.add_child(title)
	var body := Label.new()
	body.name = "CampfireBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 40)
	body.add_theme_color_override("font_color", _theme.color("text_muted"))
	story.add_child(body)
	var art_frame := PanelContainer.new()
	art_frame.name = "CampfireArtFrame"
	art_frame.custom_minimum_size = Vector2(0, 360)
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.clip_contents = true
	art_frame.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	story.add_child(art_frame)
	_room_art = TextureRect.new()
	_room_art.name = "CampfireRoomArt"
	_room_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_room_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_room_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_room_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(_room_art)
	var action_panel := PanelContainer.new()
	action_panel.name = "CampfireActionPanel"
	action_panel.custom_minimum_size = Vector2(340, 0)
	action_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	split.add_child(action_panel)
	var actions := VBoxContainer.new()
	actions.name = "CampfireActions"
	actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	action_panel.add_child(actions)
	var action_title := Label.new()
	action_title.text = "整备抉择"
	action_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	action_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	actions.add_child(action_title)
	_vital_label = Label.new()
	_vital_label.name = "CampfireVitalLabel"
	_vital_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	actions.add_child(_vital_label)
	_vital_gauge = ProgressBar.new()
	_vital_gauge.name = "CampfireVitalGauge"
	_vital_gauge.custom_minimum_size = Vector2(0, 22)
	_vital_gauge.show_percentage = false
	_vital_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vital_gauge.add_theme_stylebox_override("background", _progress_style(_theme.color("bg_ink"), _theme.color("border_subtle")))
	_vital_gauge.add_theme_stylebox_override("fill", _progress_style(_theme.color("ember"), _theme.color("brass_bright")))
	actions.add_child(_vital_gauge)
	_arrival_actions = VBoxContainer.new()
	_arrival_actions.name = "CampfireArrivalActions"
	_arrival_actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arrival_actions.add_theme_constant_override("separation", 8)
	actions.add_child(_arrival_actions)
	_rest_button = Button.new()
	_rest_button.name = "CampfireRestButton"
	_rest_button.custom_minimum_size = Vector2(280, 104)
	_rest_button.pressed.connect(func() -> void:
		if not _rest_button.disabled:
			rest_requested.emit()
	)
	_apply_button(_rest_button, "primary")
	_arrival_actions.add_child(_rest_button)
	_forge_button = Button.new()
	_forge_button.name = "CampfireForgeButton"
	_forge_button.custom_minimum_size = Vector2(280, 92)
	_forge_button.text = "打开锻造"
	_forge_button.pressed.connect(func() -> void:
		if not _forge_button.disabled:
			forge_requested.emit()
	)
	_apply_button(_forge_button, "secondary")
	_arrival_actions.add_child(_forge_button)
	var action_spacer := Control.new()
	action_spacer.name = "CampfireActionSpacer"
	action_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrival_actions.add_child(action_spacer)
	var leave_button := Button.new()
	leave_button.name = "CampfireLeaveButton"
	leave_button.text = "离开篝火"
	leave_button.custom_minimum_size = Vector2(280, 48)
	leave_button.pressed.connect(func() -> void: leave.emit())
	_apply_button(leave_button, "secondary")
	_arrival_actions.add_child(leave_button)
	_forge_panel = VBoxContainer.new()
	_forge_panel.name = "CampfireForgePanel"
	_forge_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_forge_panel.add_theme_constant_override("separation", 8)
	actions.add_child(_forge_panel)
	var candidate_scroll := ScrollContainer.new()
	candidate_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_forge_panel.add_child(candidate_scroll)
	_candidate_column = VBoxContainer.new()
	_candidate_column.name = "CampfireForgeCandidates"
	_candidate_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_candidate_column.add_theme_constant_override("separation", 6)
	candidate_scroll.add_child(_candidate_column)
	var back_button := Button.new()
	back_button.name = "CampfireForgeBack"
	back_button.text = "返回篝火"
	back_button.custom_minimum_size = Vector2(280, 48)
	back_button.pressed.connect(func() -> void: forge_back_requested.emit())
	_apply_button(back_button, "secondary")
	_forge_panel.add_child(back_button)
	_forge_panel.visible = false

func _clear_candidates() -> void:
	for child in _candidate_column.get_children():
		_candidate_column.remove_child(child)
		child.queue_free()

func _apply_button(button: Button, variant: String) -> void:
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style(variant, "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))

func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _progress_style(surface: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = surface
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style
