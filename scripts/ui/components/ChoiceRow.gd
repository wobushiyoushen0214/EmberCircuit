extends PanelContainer

signal choice_pressed(choice_id: String)

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var choice_id: String = ""
var button: Button
var _theme := ForgeThemeScript.new()

func _init() -> void:
	custom_minimum_size = Vector2(220, 56)
	_build()

func configure(model: Dictionary) -> void:
	choice_id = str(model.get("id", model.get("choice_id", "choice")))
	name = str(model.get("node_name", "ChoiceRow_%s" % choice_id))
	button.name = "ChoiceButton"
	button.text = str(model.get("label", model.get("title", "继续")))
	button.tooltip_text = str(model.get("tooltip", model.get("description", "")))
	button.disabled = bool(model.get("disabled", false))
	if button.disabled and button.tooltip_text.is_empty():
		button.tooltip_text = str(model.get("blocked_reason", "暂不可用"))
	button.add_theme_font_size_override("font_size", _theme.font_size("body"))

func set_disabled(reason: String) -> void:
	button.disabled = true
	button.tooltip_text = reason

func _build() -> void:
	add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	button = Button.new()
	button.custom_minimum_size = Vector2(220, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style("secondary", "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style("secondary", "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	button.pressed.connect(func() -> void: choice_pressed.emit(choice_id))
	add_child(button)
