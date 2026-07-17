extends PanelContainer

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")
var variant: String = "iron"
var _theme := ForgeThemeScript.new()

func _init() -> void:
	name = "ForgePanel"
	custom_minimum_size = Vector2(44, 44)
	_apply_style()

func _ready() -> void:
	_apply_style()

func _apply_style() -> void:
	add_theme_stylebox_override("panel", _theme.panel_style(variant))
