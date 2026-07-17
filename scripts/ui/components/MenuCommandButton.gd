extends Button

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")
const ForgeMotionScript = preload("res://scripts/ui/ForgeMotion.gd")

var title_label: Label
var subtitle_label: Label
var body_label: Label
var status_label: Label
var command_index_label: Label
var chevron_label: Label
var reduced_motion: bool = false

var _theme := ForgeThemeScript.new()
var _motion := ForgeMotionScript.new()
var _variant: String = "primary"
var _available: bool = true
var _hovered: bool = false
var _accent_rail: ColorRect
var _top_glint: ColorRect
var _state_wash: ColorRect
var _content_margin: MarginContainer
var _content_row: HBoxContainer
var _index_divider: ColorRect
var _text_stack: VBoxContainer
var _emphasis_tween: Tween

func _init() -> void:
	name = "MenuCommandButton"
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = false
	_build_content()
	button_down.connect(_set_pressed_visual.bind(true))
	button_up.connect(_set_pressed_visual.bind(false))
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func configure(model: Dictionary) -> void:
	_variant = str(model.get("variant", "primary"))
	title_label.text = str(model.get("title", ""))
	subtitle_label.text = str(model.get("subtitle", ""))
	body_label.text = str(model.get("body", ""))
	status_label.text = str(model.get("status", ""))
	command_index_label.text = str(model.get("index", ""))
	subtitle_label.visible = not subtitle_label.text.is_empty()
	body_label.visible = false
	_apply_variant_layout()
	set_available(bool(model.get("enabled", true)), status_label.text)

func set_available(available: bool, status_text: String = "") -> void:
	_available = available
	disabled = not available
	focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	if not status_text.is_empty():
		status_label.text = status_text
	status_label.visible = _variant != "utility" and not status_label.text.is_empty()
	chevron_label.visible = _variant != "utility" and available
	_apply_visual_state()

func _build_content() -> void:
	_state_wash = ColorRect.new()
	_state_wash.name = "CommandStateWash"
	_state_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_state_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_wash.color = _theme.color("menu_command_wash")
	_state_wash.modulate.a = 0.0
	add_child(_state_wash)

	_accent_rail = ColorRect.new()
	_accent_rail.name = "CommandAccentRail"
	_accent_rail.anchor_bottom = 1.0
	_accent_rail.offset_left = 0.0
	_accent_rail.offset_right = _theme.metric("menu_command_rail_width", 3.0)
	_accent_rail.offset_top = 10.0
	_accent_rail.offset_bottom = -10.0
	_accent_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accent_rail.color = _theme.color("ember")
	_accent_rail.modulate.a = 0.72
	add_child(_accent_rail)

	_top_glint = ColorRect.new()
	_top_glint.name = "CommandTopGlint"
	_top_glint.anchor_right = 1.0
	_top_glint.offset_left = 18.0
	_top_glint.offset_right = -18.0
	_top_glint.offset_top = 2.0
	_top_glint.offset_bottom = 3.0
	_top_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_glint.color = _theme.color("menu_command_glint")
	_top_glint.modulate.a = 0.34
	add_child(_top_glint)

	_content_margin = MarginContainer.new()
	_content_margin.name = "CommandContentMargin"
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_margin)

	_content_row = HBoxContainer.new()
	_content_row.name = "CommandContent"
	_content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_row.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	_content_margin.add_child(_content_row)

	command_index_label = Label.new()
	command_index_label.name = "CommandIndex"
	command_index_label.custom_minimum_size.x = _theme.metric("menu_command_index_width", 28.0)
	command_index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	command_index_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	_content_row.add_child(command_index_label)

	_index_divider = ColorRect.new()
	_index_divider.name = "CommandIndexDivider"
	_index_divider.custom_minimum_size = Vector2(1.0, 26.0)
	_index_divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_index_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_index_divider.color = _theme.color("menu_command_divider")
	_content_row.add_child(_index_divider)

	_text_stack = VBoxContainer.new()
	_text_stack.name = "CommandText"
	_text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_stack.add_theme_constant_override("separation", 1)
	_content_row.add_child(_text_stack)

	title_label = Label.new()
	title_label.name = "CommandTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_text_stack.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.name = "CommandSubtitle"
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	subtitle_label.visible = false
	_text_stack.add_child(subtitle_label)

	body_label = Label.new()
	body_label.name = "CommandBody"
	body_label.visible = false
	_text_stack.add_child(body_label)

	status_label = Label.new()
	status_label.name = "CommandStatus"
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	_content_row.add_child(status_label)

	chevron_label = Label.new()
	chevron_label.name = "CommandChevron"
	chevron_label.text = ">"
	chevron_label.custom_minimum_size.x = 18.0
	chevron_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chevron_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chevron_label.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	_content_row.add_child(chevron_label)

func _apply_variant_layout() -> void:
	var is_utility := _variant == "utility"
	var horizontal_margin := int(_theme.metric("menu_command_content_margin", 18.0))
	_content_margin.add_theme_constant_override("margin_left", 8 if is_utility else horizontal_margin)
	_content_margin.add_theme_constant_override("margin_right", 8 if is_utility else horizontal_margin)
	_content_margin.add_theme_constant_override("margin_top", 6)
	_content_margin.add_theme_constant_override("margin_bottom", 6)
	command_index_label.visible = not is_utility
	_index_divider.visible = not is_utility
	_accent_rail.visible = _variant == "primary"
	_top_glint.visible = _variant == "primary"
	status_label.visible = not is_utility and not status_label.text.is_empty()
	chevron_label.visible = not is_utility and _available
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if is_utility else HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_size_override("font_size", _theme.font_size("button") if is_utility else (18 if _variant == "primary" else 16))
	if is_utility:
		custom_minimum_size = Vector2(_theme.metric("menu_utility_width", 104.0), _theme.metric("menu_utility_height", 44.0))
	elif _variant == "primary":
		custom_minimum_size = Vector2(_theme.metric("menu_primary_width", 420.0), _theme.metric("menu_primary_height", 64.0))
	else:
		custom_minimum_size = Vector2(_theme.metric("menu_secondary_width", 380.0), _theme.metric("menu_secondary_height", 52.0))

func _apply_visual_state() -> void:
	add_theme_stylebox_override("normal", _theme.menu_command_style(_variant, "normal"))
	add_theme_stylebox_override("hover", _theme.menu_command_style(_variant, "hover"))
	add_theme_stylebox_override("pressed", _theme.menu_command_style(_variant, "pressed"))
	add_theme_stylebox_override("disabled", _theme.menu_command_style(_variant, "disabled"))
	add_theme_stylebox_override("focus", _theme.menu_command_focus_style(_variant))
	var title_color := _theme.color("text_disabled_strong") if not _available else (_theme.color("text_muted") if _variant == "utility" else _theme.color("text_primary"))
	var detail_color := _theme.color("text_disabled_muted") if not _available else _theme.color("text_muted")
	title_label.add_theme_color_override("font_color", title_color)
	subtitle_label.add_theme_color_override("font_color", detail_color)
	body_label.add_theme_color_override("font_color", detail_color)
	status_label.add_theme_color_override("font_color", detail_color)
	command_index_label.add_theme_color_override("font_color", _theme.color("text_disabled_muted") if not _available else _theme.color("brass_bright"))
	chevron_label.add_theme_color_override("font_color", _theme.color("brass_bright"))

func _on_mouse_entered() -> void:
	if disabled:
		return
	_hovered = true
	_animate_emphasis(true)

func _on_mouse_exited() -> void:
	_hovered = false
	_set_pressed_visual(false)
	_animate_emphasis(has_focus())

func _on_focus_entered() -> void:
	_animate_emphasis(true)

func _on_focus_exited() -> void:
	_set_pressed_visual(false)
	_animate_emphasis(_hovered)

func _animate_emphasis(is_emphasized: bool) -> void:
	if _emphasis_tween != null and _emphasis_tween.is_valid():
		_emphasis_tween.kill()
	var wash_alpha := 1.0 if is_emphasized and _variant != "utility" else (0.7 if is_emphasized else 0.0)
	var rail_alpha := 1.0 if is_emphasized else 0.72
	var glint_alpha := 0.72 if is_emphasized else 0.34
	if reduced_motion or not is_inside_tree():
		_state_wash.modulate.a = wash_alpha
		_accent_rail.modulate.a = rail_alpha
		_top_glint.modulate.a = glint_alpha
		return
	_emphasis_tween = create_tween()
	_emphasis_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_emphasis_tween.set_parallel(true)
	var duration_seconds := _motion.duration("hover") / 1000.0
	_emphasis_tween.tween_property(_state_wash, "modulate:a", wash_alpha, duration_seconds)
	_emphasis_tween.tween_property(_accent_rail, "modulate:a", rail_alpha, duration_seconds)
	_emphasis_tween.tween_property(_top_glint, "modulate:a", glint_alpha, duration_seconds)

func _set_pressed_visual(is_pressed: bool) -> void:
	if disabled:
		return
	_motion.press_scale(self, is_pressed, reduced_motion, "menu_press")
