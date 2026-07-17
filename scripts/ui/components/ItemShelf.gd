extends VBoxContainer

signal item_pressed(item_id: String)

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _item_prefix := "Item"

func configure(items: Array, prefix: String = "Item", empty_text: String = "暂无库存") -> void:
	_item_prefix = prefix
	_clear()
	if items.is_empty():
		var empty := Label.new()
		empty.name = "%sEmpty" % prefix
		empty.text = empty_text
		empty.add_theme_color_override("font_color", _theme.color("text_muted"))
		add_child(empty)
		return
	for raw in items:
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw
		var id := str(item.get("id", "item_%d" % get_child_count()))
		var button := Button.new()
		button.name = "%s_%s" % [prefix, id]
		button.custom_minimum_size = Vector2(220, 76)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.text = _item_text(item)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.tooltip_text = str(item.get("description", ""))
		button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
		button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
		button.add_theme_stylebox_override("pressed", _theme.button_style("secondary", "pressed"))
		button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
		button.pressed.connect(func() -> void: item_pressed.emit(id))
		add_child(button)

func _item_text(item: Dictionary) -> String:
	var title := str(item.get("name", item.get("title", "物品")))
	var price: Variant = item.get("price", null)
	if price == null:
		return title
	return "%s\n%d 金币" % [title, int(price)]

func _clear() -> void:
	for child in get_children():
		child.queue_free()
