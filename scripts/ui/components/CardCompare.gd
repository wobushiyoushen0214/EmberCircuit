extends PanelContainer

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var title_label: Label
var detail_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(280, 128)
	add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	title_label = Label.new()
	title_label.name = "CompareTitle"
	title_label.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	title_label.add_theme_color_override("font_color", _theme.color("text_primary"))
	box.add_child(title_label)
	detail_label = Label.new()
	detail_label.name = "CompareDetail"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	box.add_child(detail_label)

func configure(current: Dictionary, upgraded: Dictionary = {}) -> void:
	title_label.text = str(current.get("name", "卡牌对比"))
	var current_text := str(current.get("description", "暂无说明"))
	if upgraded.is_empty():
		detail_label.text = current_text
	else:
		detail_label.text = "%s\n升级后：%s" % [current_text, str(upgraded.get("description", "暂无说明"))]
