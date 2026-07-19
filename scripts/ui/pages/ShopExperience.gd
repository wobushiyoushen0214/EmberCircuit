extends Control

signal buy_card(item_id: String)
signal buy_relic(item_id: String)
signal buy_potion(item_id: String)
signal open_remove
signal remove_card(deck_index: int)
signal cancel_remove
signal leave

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _gold_label: Label
var _card_shelf: VBoxContainer
var _relic_shelf: VBoxContainer
var _potion_shelf: VBoxContainer
var _store_shelves: HBoxContainer
var _store_actions: HBoxContainer
var _remove_selection: PanelContainer
var _remove_list: VBoxContainer
var _remove_button: Button

func _init() -> void:
	name = "ShopExperience"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var requested_mode := str(model.get("mode", "store"))
	var mode := requested_mode if requested_mode == "store" or requested_mode == "remove" else "store"
	var gold := int(model.get("gold", 0))
	var remove_price := int(model.get("remove_price", 0))
	_gold_label.text = "金币  %d" % gold
	var inventory_is_safe := requested_mode == "store" or requested_mode == "remove"
	_populate(_card_shelf, model.get("cards", []) if inventory_is_safe else [], "ShopCard", gold, "card")
	_populate(_relic_shelf, model.get("relics", []) if inventory_is_safe else [], "ShopRelic", gold, "relic")
	_populate(_potion_shelf, model.get("potions", []) if inventory_is_safe else [], "ShopPotion", gold, "potion")
	_remove_button.text = "删卡柜台  ·  %d 金币" % remove_price
	var remove_disabled_reason := str(model.get("remove_disabled_reason", ""))
	if not inventory_is_safe:
		remove_disabled_reason = "页面状态不可用"
	if remove_disabled_reason.is_empty() and gold < remove_price:
		remove_disabled_reason = "金币不足"
	_set_disabled_state(_remove_button, remove_disabled_reason)
	_remove_button.tooltip_text = "选择一张牌移出牌组" if remove_disabled_reason.is_empty() else remove_disabled_reason
	_store_shelves.visible = mode == "store"
	_store_actions.visible = mode == "store"
	_remove_selection.visible = mode == "remove"
	_populate_remove(model.get("remove_candidates", []) if mode == "remove" else [])

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
	hero_row.add_theme_constant_override("separation", 12)
	hero.add_child(hero_row)
	var merchant_icon := TextureRect.new()
	merchant_icon.name = "ShopMerchantIcon"
	merchant_icon.custom_minimum_size = Vector2(38, 38)
	merchant_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	merchant_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	merchant_icon.texture = _load_texture("res://assets/art/map_node_shop.svg")
	merchant_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_row.add_child(merchant_icon)
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
	_store_shelves = HBoxContainer.new()
	_store_shelves.name = "ShopShelves"
	_store_shelves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_store_shelves.add_theme_constant_override("separation", 12)
	column.add_child(_store_shelves)
	_card_shelf = _new_shelf(_store_shelves, "ShopCardShelf", "卡牌")
	_relic_shelf = _new_shelf(_store_shelves, "ShopRelicShelf", "遗物")
	_potion_shelf = _new_shelf(_store_shelves, "ShopPotionShelf", "药水")
	_store_actions = HBoxContainer.new()
	_store_actions.name = "ShopStoreActions"
	_store_actions.add_theme_constant_override("separation", 8)
	column.add_child(_store_actions)
	_remove_button = Button.new()
	_remove_button.name = "ShopRemoveCounter"
	_remove_button.custom_minimum_size = Vector2(220, 48)
	_remove_button.pressed.connect(func() -> void:
		if not _remove_button.disabled:
			open_remove.emit()
	)
	_remove_button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
	_remove_button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
	_remove_button.add_theme_stylebox_override("disabled", _theme.button_style("secondary", "disabled"))
	_remove_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	_store_actions.add_child(_remove_button)
	var store_action_spacer := Control.new()
	store_action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	store_action_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_store_actions.add_child(store_action_spacer)
	var leave_button := Button.new()
	leave_button.name = "ShopLeaveButton"
	leave_button.text = "离开商店"
	leave_button.custom_minimum_size = Vector2(180, 48)
	leave_button.pressed.connect(func() -> void: leave.emit())
	leave_button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
	leave_button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
	leave_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	_store_actions.add_child(leave_button)
	_remove_selection = PanelContainer.new()
	_remove_selection.name = "ShopRemoveSelection"
	_remove_selection.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_remove_selection.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	column.add_child(_remove_selection)
	var remove_column := VBoxContainer.new()
	remove_column.add_theme_constant_override("separation", 8)
	_remove_selection.add_child(remove_column)
	var remove_title := Label.new()
	remove_title.text = "选择要移除的卡牌"
	remove_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	remove_column.add_child(remove_title)
	var remove_scroll := ScrollContainer.new()
	remove_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	remove_column.add_child(remove_scroll)
	_remove_list = VBoxContainer.new()
	_remove_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_remove_list.add_theme_constant_override("separation", 6)
	remove_scroll.add_child(_remove_list)
	var cancel_button := Button.new()
	cancel_button.name = "ShopRemoveCancel"
	cancel_button.text = "返回货架"
	cancel_button.custom_minimum_size = Vector2(180, 48)
	cancel_button.pressed.connect(func() -> void: cancel_remove.emit())
	cancel_button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
	cancel_button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
	cancel_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	remove_column.add_child(cancel_button)
	_remove_selection.visible = false

func _new_shelf(parent: Container, node_name: String, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	box.add_child(heading)
	var shelf := VBoxContainer.new()
	shelf.name = "%sItems" % node_name
	shelf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 6)
	box.add_child(shelf)
	panel.add_child(box)
	return shelf

func _populate(shelf: VBoxContainer, items: Array, prefix: String, gold: int, kind: String) -> void:
	for child in shelf.get_children():
		shelf.remove_child(child)
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
		button.custom_minimum_size = Vector2(220, 112)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.text = ""
		button.clip_contents = true
		button.tooltip_text = str(item.get("description", ""))
		var disabled_reason := str(item.get("disabled_reason", ""))
		if disabled_reason.is_empty() and gold < price:
			disabled_reason = "金币不足"
		elif disabled_reason.is_empty() and bool(item.get("sold_out", false)):
			disabled_reason = "已售罄"
		elif disabled_reason.is_empty() and kind == "potion" and not bool(item.get("slots_available", true)):
			disabled_reason = "药水槽已满"
		_set_disabled_state(button, disabled_reason)
		if not disabled_reason.is_empty():
			button.tooltip_text = disabled_reason
		_add_item_layout(button, item, price, disabled_reason, kind)
		button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
		button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
		button.add_theme_stylebox_override("disabled", _theme.button_style("secondary", "disabled"))
		button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
		if kind == "card":
			button.pressed.connect(func() -> void:
				if not button.disabled:
					buy_card.emit(id)
			)
		elif kind == "relic":
			button.pressed.connect(func() -> void:
				if not button.disabled:
					buy_relic.emit(id)
			)
		else:
			button.pressed.connect(func() -> void:
				if not button.disabled:
					buy_potion.emit(id)
			)
		shelf.add_child(button)

func _populate_remove(candidates: Array) -> void:
	for child in _remove_list.get_children():
		_remove_list.remove_child(child)
		child.queue_free()
	var candidate_count := 0
	for raw in candidates:
		if not raw is Dictionary:
			continue
		var candidate: Dictionary = raw
		var deck_index := int(candidate.get("deck_index", -1))
		if deck_index < 0:
			continue
		var button := Button.new()
		button.name = "ShopRemoveCard_%d" % deck_index
		button.text = str(candidate.get("name", candidate.get("id", "未知卡牌")))
		button.tooltip_text = str(candidate.get("description", "从牌组中永久移除"))
		button.custom_minimum_size = Vector2(260, 52)
		button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
		button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
		button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
		button.pressed.connect(func() -> void: remove_card.emit(deck_index))
		_remove_list.add_child(button)
		candidate_count += 1
	if candidate_count == 0:
		var empty := Label.new()
		empty.name = "ShopRemoveEmpty"
		empty.text = "当前没有可移除的卡牌"
		_remove_list.add_child(empty)

func _set_disabled_state(button: Button, reason: String) -> void:
	button.disabled = not reason.is_empty()
	button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND

func _add_item_layout(button: Button, item: Dictionary, price: int, disabled_reason: String, kind: String) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 12
	margin.offset_right = -12
	margin.offset_top = 10
	margin.offset_bottom = -10
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(78, 78)
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	row.add_child(art_frame)
	var art := TextureRect.new()
	art.name = "ShopItemArt_%s" % str(item.get("id", kind))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _load_texture(str(item.get("art_path", "")))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 4)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var title := Label.new()
	title.text = str(item.get("name", item.get("id", "商品")))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", _theme.font_size("body", 15))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var price_label := Label.new()
	price_label.text = "%d 金币" % price
	price_label.add_theme_color_override("font_color", _theme.color("brass_bright") if disabled_reason.is_empty() else _theme.color("text_disabled"))
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(price_label)
	var description := Label.new()
	description.text = disabled_reason if not disabled_reason.is_empty() else str(item.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_font_size_override("font_size", _theme.font_size("caption", 12))
	description.add_theme_color_override("font_color", _theme.color("text_disabled") if not disabled_reason.is_empty() else _theme.color("text_muted"))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(description)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
