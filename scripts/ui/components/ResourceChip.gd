extends HBoxContainer

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")
var icon_label: Label
var value_label: Label
var _theme := ForgeThemeScript.new()

func _init() -> void:
	name = "ResourceChip"
	custom_minimum_size = Vector2(72, 44)
	add_theme_constant_override("separation", 6)
	icon_label = Label.new()
	icon_label.add_theme_color_override("font_color", _theme.color("brass_bright"))
	add_child(icon_label)
	value_label = Label.new()
	value_label.add_theme_color_override("font_color", _theme.color("text_primary"))
	value_label.add_theme_font_size_override("font_size", _theme.font_size("body"))
	add_child(value_label)
	add_theme_stylebox_override("panel", _theme.panel_style("iron"))

func configure(label: String, value: Variant, icon: String = "") -> void:
	icon_label.text = icon if not icon.is_empty() else label
	icon_label.tooltip_text = label
	value_label.text = str(value)
