extends Button

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")
const ForgeMotionScript = preload("res://scripts/ui/ForgeMotion.gd")

var title_label: Label
var subtitle_label: Label
var body_label: Label
var icon_view: TextureRect
var reduced_motion: bool = false

var _theme := ForgeThemeScript.new()
var _motion := ForgeMotionScript.new()
var _content_box: HBoxContainer
var _text_box: VBoxContainer
var _variant: String = "neutral"
var _accent_rule: ColorRect
var _lower_rule: ColorRect

func _init() -> void:
	name = "ActionCard"
	custom_minimum_size = Vector2(160, 52)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = false
	text = ""
	_build_content()
	button_down.connect(_set_pressed_visual.bind(true))
	button_up.connect(_set_pressed_visual.bind(false))
	mouse_exited.connect(_restore_press_visual)
	focus_exited.connect(_restore_press_visual)

func configure(model: Dictionary) -> void:
	if title_label == null:
		_build_content()
	title_label.text = str(model.get("title", ""))
	subtitle_label.text = str(model.get("subtitle", ""))
	body_label.text = str(model.get("body", ""))
	subtitle_label.visible = not subtitle_label.text.is_empty()
	body_label.visible = not body_label.text.is_empty()
	_variant = str(model.get("variant", "neutral"))
	var icon_texture = model.get("icon")
	icon_view.texture = icon_texture if icon_texture is Texture2D else null
	icon_view.visible = icon_view.texture != null
	_accent_rule.visible = _variant == "primary"
	_lower_rule.visible = _variant != "utility"
	_accent_rule.color = _theme.color("ember")
	_lower_rule.color = Color(_theme.color("border_subtle"), 0.55)
	_apply_typography()
	add_theme_stylebox_override("normal", _theme.button_style(_variant, "normal"))
	add_theme_stylebox_override("hover", _theme.button_style(_variant, "hover"))
	add_theme_stylebox_override("pressed", _theme.button_style(_variant, "pressed"))
	add_theme_stylebox_override("disabled", _theme.button_style(_variant, "disabled"))
	_update_focus_style()

func _ready() -> void:
	_update_focus_style()

func _build_content() -> void:
	_content_box = HBoxContainer.new()
	_content_box.name = "ActionContent"
	_content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_box.offset_left = _theme.spacing("panel_gap")
	_content_box.offset_right = -_theme.spacing("panel_gap")
	_content_box.offset_top = 6.0
	_content_box.offset_bottom = -6.0
	_content_box.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	_content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_content_box)

	icon_view = TextureRect.new()
	icon_view.name = "ActionIcon"
	icon_view.custom_minimum_size = Vector2(24, 24)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_view.visible = false
	_content_box.add_child(icon_view)

	_text_box = VBoxContainer.new()
	_text_box.name = "ActionText"
	_text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_box.add_theme_constant_override("separation", 2)
	_content_box.add_child(_text_box)

	title_label = Label.new()
	title_label.name = "ActionTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_color_override("font_color", _theme.color("text_primary"))
	_text_box.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.name = "ActionSubtitle"
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	subtitle_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	subtitle_label.visible = false
	_text_box.add_child(subtitle_label)
	body_label = Label.new()
	body_label.name = "ActionBody"
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", _theme.font_size("body"))
	body_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	body_label.visible = false
	_text_box.add_child(body_label)

	_accent_rule = ColorRect.new()
	_accent_rule.name = "CommandAccent"
	_accent_rule.anchor_left = 0.5
	_accent_rule.anchor_right = 0.5
	_accent_rule.offset_left = -44.0
	_accent_rule.offset_top = 4.0
	_accent_rule.offset_right = 44.0
	_accent_rule.offset_bottom = 6.0
	_accent_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_accent_rule)

	_lower_rule = ColorRect.new()
	_lower_rule.name = "CommandLowerRule"
	_lower_rule.anchor_left = 0.0
	_lower_rule.anchor_top = 1.0
	_lower_rule.anchor_right = 1.0
	_lower_rule.anchor_bottom = 1.0
	_lower_rule.offset_left = 14.0
	_lower_rule.offset_top = -4.0
	_lower_rule.offset_right = -14.0
	_lower_rule.offset_bottom = -3.0
	_lower_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lower_rule)
	_apply_typography()

func _apply_typography() -> void:
	if title_label == null:
		return
	var title_size: int = _theme.font_size("heading_sm", _theme.font_size("button"))
	if _variant == "primary":
		title_size = 18
	elif _variant == "utility":
		title_size = 14
	title_label.add_theme_font_size_override("font_size", title_size)

func _update_focus_style() -> void:
	add_theme_stylebox_override("focus", _theme.focus_style("card"))

func _set_pressed_visual(is_pressed: bool) -> void:
	_motion.press_scale(self, is_pressed, reduced_motion)

func _restore_press_visual() -> void:
	_motion.press_scale(self, false, reduced_motion)
