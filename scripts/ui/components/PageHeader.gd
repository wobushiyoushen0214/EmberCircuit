extends VBoxContainer

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var eyebrow_label: Label
var title_label: Label
var subtitle_label: Label
var back_button: Button
var accent_rule: ColorRect

var _theme := ForgeThemeScript.new()
var _back_callback: Callable

func _init() -> void:
	name = "PageHeader"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)

	eyebrow_label = Label.new()
	eyebrow_label.name = "PageEyebrow"
	eyebrow_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	eyebrow_label.add_theme_color_override("font_color", _theme.color("brass_bright"))
	eyebrow_label.visible = false
	add_child(eyebrow_label)

	title_label = Label.new()
	title_label.name = "PageTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title_label.add_theme_color_override("font_color", _theme.color("text_primary"))
	add_child(title_label)

	accent_rule = ColorRect.new()
	accent_rule.name = "HeaderAccent"
	accent_rule.custom_minimum_size = Vector2(40, 2)
	accent_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	accent_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_rule.color = _theme.color("ember")
	add_child(accent_rule)

	subtitle_label = Label.new()
	subtitle_label.name = "PageSubtitle"
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", _theme.font_size("body"))
	subtitle_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	add_child(subtitle_label)

func configure(title: String, subtitle: String = "", eyebrow: String = "", centered: bool = false) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.visible = not subtitle.is_empty()
	eyebrow_label.text = eyebrow
	eyebrow_label.visible = not eyebrow.is_empty()
	var text_alignment := HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	eyebrow_label.horizontal_alignment = text_alignment
	title_label.horizontal_alignment = text_alignment
	subtitle_label.horizontal_alignment = text_alignment
	accent_rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if centered else Control.SIZE_SHRINK_BEGIN

func set_back_action(callback: Callable) -> void:
	if back_button == null:
		back_button = Button.new()
		back_button.name = "HeaderBackButton"
		back_button.text = "返回"
		back_button.custom_minimum_size = Vector2(88, 44)
		back_button.focus_mode = Control.FOCUS_ALL
		back_button.add_theme_stylebox_override("normal", _theme.button_style("utility", "normal"))
		back_button.add_theme_stylebox_override("hover", _theme.button_style("utility", "hover"))
		back_button.add_theme_stylebox_override("pressed", _theme.button_style("utility", "pressed"))
		back_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
		add_child(back_button)
		move_child(back_button, 0)
	if _back_callback.is_valid() and back_button.pressed.is_connected(_back_callback):
		back_button.pressed.disconnect(_back_callback)
	_back_callback = callback
	if callback.is_valid():
		back_button.pressed.connect(callback)
