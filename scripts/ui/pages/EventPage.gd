extends Control

signal choice_selected(choice_id: String)
signal continue_requested

const ChoiceRowScript = preload("res://scripts/ui/components/ChoiceRow.gd")
const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _choice_column: VBoxContainer
var _event_art: TextureRect
var _choice_count: Label

func _init() -> void:
	name = "EventPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var event: Dictionary = model.get("event", {})
	var node: Dictionary = model.get("node", {})
	var story_panel := get_node("PcEventExperience/StoryPanel")
	var story_title := story_panel.find_child("StoryTitle", true, false) as Label
	var story_body := story_panel.find_child("StoryBody", true, false) as Label
	if story_title != null:
		story_title.text = str(event.get("name", node.get("name", "未知事件")))
	if story_body != null:
		story_body.text = str(event.get("body", "炉火在沉默中等待你的决定。"))
	_event_art.texture = _load_texture(str(event.get("art_path", "")))
	_clear_choices()
	var choices: Array = model.get("choices", [])
	_choice_count.text = "%d 项可选回应" % choices.size()
	if choices.is_empty():
		var continue_button := Button.new()
		continue_button.name = "EventChoice_continue"
		continue_button.text = "继续"
		continue_button.custom_minimum_size = Vector2(220, 52)
		_apply_button(continue_button, "primary")
		continue_button.pressed.connect(func() -> void: continue_requested.emit())
		_choice_column.add_child(continue_button)
		return
	for raw in choices:
		if not raw is Dictionary:
			continue
		var choice: Dictionary = raw
		var id := str(choice.get("id", "choice_%d" % _choice_column.get_child_count()))
		var blocked_reason := str(choice.get("blocked_reason", ""))
		var row = ChoiceRowScript.new()
		row.name = "ChoiceRow_%s" % id
		row.custom_minimum_size = Vector2(320, 104 if choices.size() <= 4 else 84)
		row.configure({
			"id": id,
			"label": str(choice.get("label", "回应")),
			"description": str(choice.get("description", "")),
			"disabled": not blocked_reason.is_empty() or bool(choice.get("disabled", false)),
			"blocked_reason": blocked_reason,
			"tooltip": blocked_reason if not blocked_reason.is_empty() else str(choice.get("description", ""))
		})
		row.button.name = "EventChoice_%s" % id
		if row.button.disabled:
			row.button.focus_mode = Control.FOCUS_NONE
			row.button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		row.choice_pressed.connect(func(selected_id: String) -> void:
			if not row.button.disabled:
				choice_selected.emit(selected_id)
		)
		_choice_column.add_child(row)

func _build_shell() -> void:
	var room := HBoxContainer.new()
	room.name = "PcEventExperience"
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room.add_theme_constant_override("separation", 18)
	room.offset_left = 24
	room.offset_right = -24
	room.offset_top = 24
	room.offset_bottom = -24
	add_child(room)
	var story := PanelContainer.new()
	story.name = "StoryPanel"
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	room.add_child(story)
	var story_box := VBoxContainer.new()
	story_box.add_theme_constant_override("separation", 10)
	story.add_child(story_box)
	var eyebrow := Label.new()
	eyebrow.name = "EventEyebrow"
	eyebrow.text = "未知信号  /  现场记录"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption", 12))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	story_box.add_child(eyebrow)
	var story_title := Label.new()
	story_title.name = "StoryTitle"
	story_title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	story_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	story_box.add_child(story_title)
	var story_body := Label.new()
	story_body.name = "StoryBody"
	story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_body.custom_minimum_size = Vector2(0, 44)
	story_body.add_theme_color_override("font_color", _theme.color("text_muted"))
	story_box.add_child(story_body)
	var art_frame := PanelContainer.new()
	art_frame.name = "EventArtFrame"
	art_frame.custom_minimum_size = Vector2(0, 360)
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.clip_contents = true
	art_frame.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	story_box.add_child(art_frame)
	_event_art = TextureRect.new()
	_event_art.name = "EventArt"
	_event_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_event_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_event_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(_event_art)
	var decision := PanelContainer.new()
	decision.name = "EventChoicePanel"
	decision.custom_minimum_size = Vector2(360, 0)
	decision.size_flags_vertical = Control.SIZE_EXPAND_FILL
	decision.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	room.add_child(decision)
	var decision_box := VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 10)
	decision.add_child(decision_box)
	var decision_title := Label.new()
	decision_title.text = "作出抉择"
	decision_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	decision_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	decision_box.add_child(decision_title)
	_choice_count = Label.new()
	_choice_count.name = "EventChoiceCount"
	_choice_count.add_theme_color_override("font_color", _theme.color("text_muted"))
	decision_box.add_child(_choice_count)
	_choice_column = VBoxContainer.new()
	_choice_column.name = "EventChoiceButtons"
	_choice_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choice_column.add_theme_constant_override("separation", 8)
	decision_box.add_child(_choice_column)

func _clear_choices() -> void:
	for child in _choice_column.get_children():
		_choice_column.remove_child(child)
		child.queue_free()

func _apply_button(button: Button, variant: String) -> void:
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))

func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
