extends Control

signal buy_card(item_id: String)
signal buy_relic(item_id: String)
signal buy_potion(item_id: String)
signal open_remove
signal remove_card(deck_index: int)
signal leave

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _gold_label: Label
var _card_shelf: VBoxContainer
var _relic_shelf: VBoxContainer
var _potion_shelf: VBoxContainer
var _remove_button: Button

func _init() -> void:
	name = "ShopExperience"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var gold := int(model.get("gold", 0))
	var remove_price := int(model.get("remove_price", 0))
	_gold_label.text = "金币  %d" % gold
	_populate(_card_shelf, model.get("cards", []), "ShopCard", gold, "card")
	_populate(_relic_shelf, model.get("relics", []), "ShopRelic", gold, "relic")
	_populate(_potion_shelf, model.get("potions", []), "ShopPotion", gold, "potion")
	_remove_button.text = "删卡柜台  ·  %d 金币" % remove_price
	_remove_button.disabled = gold < remove_price
	_remove_button.tooltip_text = "金币不足" if _remove_button.disabled else "选择一张牌移出牌组"

func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var hero := PanelContainer.new()
	hero.name = "ShopMerchantHero"
	hero.custom_minimum_size = Vector2(0, 72)
	hero.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	var hero_row := HBoxContainer.new()
	hero.add_child(hero_row)
	var merchant := Label.new()
	merchant.text = "旧货架商人  ·  炉边交易"
	merchant.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	merchant.add_theme_color_override("font_color", _theme.color("text_primary"))
	hero_row.add_child(merchant)
	_gold_label = Label.new()
	_gold_label.name = "ShopGoldHUD"
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_color_override("font_color", _theme.color("brass_bright"))
	hero_row.add_child(_gold_label)
	column.add_child(hero)
	var shelves := HBoxContainer.new()
	shelves.name = "ShopShelves"
	shelves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shelves.add_theme_constant_override("separation", 12)
	column.add_child(shelves)
	_card_shelf = _new_shelf(shelves, "ShopCardShelf", "卡牌")
	_relic_shelf = _new_shelf(shelves, "ShopRelicShelf", "遗物")
	_potion_shelf = _new_shelf(shelves, "ShopPotionShelf", "药水")
	_remove_button = Button.new()
	_remove_button.name = "ShopRemoveCounter"
	_remove_button.custom_minimum_size = Vector2(220, 48)
	_remove_button.pressed.connect(func() -> void: open_remove.emit())
	_remove_button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
	_remove_button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
	_remove_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	column.add_child(_remove_button)

func _new_shelf(parent: Container, node_name: String, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	box.add_child(heading)
	var shelf := VBoxContainer.new()
	shelf.name = "%sItems" % node_name
	shelf.add_theme_constant_override("separation", 6)
	box.add_child(shelf)
	panel.add_child(box)
	return shelf

func _populate(shelf: VBoxContainer, items: Array, prefix: String, gold: int, kind: String) -> void:
	for child in shelf.get_children():
		child.queue_free()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "售罄"
		shelf.add_child(empty)
		return
	for raw in items:
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw
		var id := str(item.get("id", "item_%d" % shelf.get_child_count()))
		var price := int(item.get("price", 0))
		var button := Button.new()
		button.name = "%s_%s" % [prefix, id]
		button.custom_minimum_size = Vector2(220, 78)
		button.text = "%s\n%d 金币" % [str(item.get("name", id)), price]
		button.tooltip_text = str(item.get("description", ""))
		button.disabled = gold < price or bool(item.get("sold_out", false)) or (kind == "potion" and not bool(item.get("slots_available", true)))
		if button.disabled:
			button.tooltip_text = "金币不足" if gold < price else ("药水槽已满" if kind == "potion" else "已售罄")
		button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
		button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
		button.add_theme_stylebox_override("disabled", _theme.button_style("secondary", "disabled"))
		button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
		if kind == "card":
			button.pressed.connect(func() -> void: buy_card.emit(id))
		elif kind == "relic":
			button.pressed.connect(func() -> void: buy_relic.emit(id))
		else:
			button.pressed.connect(func() -> void: buy_potion.emit(id))
		shelf.add_child(button)
