extends Control

signal claim_card(item_id: String)
signal claim_relic(item_id: String)
signal claim_potion(item_id: String)
signal skip
signal save
signal skip_card_requested
signal skip_potion_requested
signal save_requested
signal claim_mastery(mastery_id: String)
signal continue_requested

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _action_column: VBoxContainer
var _offer_flow: HFlowContainer
var _receipt_status: VBoxContainer
var _receipt_icon: TextureRect
var _offer_count: Label
var _offer_scroll: ScrollContainer

func _init() -> void:
	name = "RewardPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var requested_mode := str(model.get("mode", "combat"))
	var mode := requested_mode if requested_mode == "combat" or requested_mode == "treasure" else "combat"
	var model_is_safe := requested_mode == "combat" or requested_mode == "treasure"
	var mode_label := find_child("RewardMode", true, false) as Label
	var gold_label := find_child("RewardGoldReceipt", true, false) as Label
	if mode_label != null:
		mode_label.text = "战斗奖励" if mode == "combat" else "宝箱战利品"
	if gold_label != null:
		gold_label.text = "金币收据  ·  +%d" % int(model.get("gold", 0))
	_clear_actions()
	_clear_offers()
	_clear_receipt_status()
	_receipt_icon.texture = _load_texture("res://assets/art/map_node_treasure.svg")
	_add_receipt_line("金币", "+%d" % int(model.get("gold", 0)), "brass_bright")
	if mode == "combat":
		_add_receipt_line("卡牌", "已处理" if bool(model.get("card_done", false)) else "待选择", "text_muted")
		_add_receipt_line("遗物", "已处理" if bool(model.get("relic_done", false)) else "待选择", "text_muted")
		_add_receipt_line("药水", "已处理" if bool(model.get("potion_done", false)) else "待选择", "text_muted")
	_add_items(model.get("cards", []) if model_is_safe and mode == "combat" else [], "RewardCard", "card", model)
	_add_items(model.get("relics", []) if model_is_safe else [], "RewardRelic", "relic", model)
	_add_items(model.get("potions", []) if model_is_safe else [], "RewardPotion", "potion", model)
	if mode == "combat" and model_is_safe:
		if not bool(model.get("card_done", false)):
			_add_action("RewardSkipCard", "跳过卡牌", "保持牌组精简", Callable(self, "_emit_skip_card"))
		if not bool(model.get("potion_done", false)):
			_add_action("RewardSkipPotion", "跳过药水", "保留当前药水槽", Callable(self, "_emit_skip_potion"))
		_add_masteries(model.get("masteries", []))
		_add_action("RewardSaveButton", "保存进度", "保存当前奖励处理状态", Callable(self, "_emit_save"))
	if _offer_flow.get_child_count() == 0:
		var empty := Label.new()
		empty.name = "RewardOfferEmpty"
		empty.text = "奖励已处理完毕。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(520, 220)
		empty.add_theme_color_override("font_color", _theme.color("text_muted"))
		_offer_flow.add_child(empty)
	_relayout_offers()
	call_deferred("_fit_offer_cards_to_viewport")
	_offer_count.text = "%d 项待处理" % _pending_offer_count(model, mode)
	var action_spacer := Control.new()
	action_spacer.name = "RewardActionSpacer"
	action_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_column.add_child(action_spacer)
	var continue_button := _add_action(
		"RewardContinueButton",
		"继续路线",
		str(model.get("continue_reason", "进入下个节点")),
		Callable(self, "_emit_continue"),
		"primary"
	)
	var can_continue := bool(model.get("can_continue", false)) if model_is_safe else false
	continue_button.disabled = not can_continue
	continue_button.focus_mode = Control.FOCUS_ALL if can_continue else Control.FOCUS_NONE
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_continue else Control.CURSOR_ARROW
	if not can_continue:
		continue_button.tooltip_text = str(model.get("continue_reason", "完成当前奖励后继续"))

func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var room := VBoxContainer.new()
	room.name = "RewardRoom"
	room.add_theme_constant_override("separation", 12)
	margin.add_child(room)
	var header_panel := PanelContainer.new()
	header_panel.name = "RewardHeaderPanel"
	header_panel.custom_minimum_size = Vector2(0, 68)
	header_panel.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	room.add_child(header_panel)
	var header := HBoxContainer.new()
	header.name = "RewardHeader"
	header.add_theme_constant_override("separation", 16)
	header_panel.add_child(header)
	var mode := Label.new()
	mode.name = "RewardMode"
	mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	mode.add_theme_color_override("font_color", _theme.color("text_primary"))
	header.add_child(mode)
	var gold := Label.new()
	gold.name = "RewardGoldReceipt"
	gold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold.add_theme_color_override("font_color", _theme.color("brass_bright"))
	header.add_child(gold)
	var content := HBoxContainer.new()
	content.name = "RewardContent"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	room.add_child(content)
	var receipt_panel := PanelContainer.new()
	receipt_panel.name = "RewardReceiptPanel"
	receipt_panel.custom_minimum_size = Vector2(220, 0)
	receipt_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	receipt_panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	content.add_child(receipt_panel)
	var receipt_box := VBoxContainer.new()
	receipt_box.add_theme_constant_override("separation", 10)
	receipt_panel.add_child(receipt_box)
	var receipt_title := Label.new()
	receipt_title.text = "本场结算"
	receipt_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	receipt_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	receipt_box.add_child(receipt_title)
	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(0, 126)
	receipt_box.add_child(icon_center)
	_receipt_icon = TextureRect.new()
	_receipt_icon.name = "RewardReceiptIcon"
	_receipt_icon.custom_minimum_size = Vector2(104, 104)
	_receipt_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_receipt_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_receipt_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(_receipt_icon)
	_receipt_status = VBoxContainer.new()
	_receipt_status.name = "RewardReceiptStatus"
	_receipt_status.add_theme_constant_override("separation", 8)
	receipt_box.add_child(_receipt_status)
	var offer_panel := PanelContainer.new()
	offer_panel.name = "RewardOfferPanel"
	offer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offer_panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	content.add_child(offer_panel)
	var offer_box := VBoxContainer.new()
	offer_box.add_theme_constant_override("separation", 8)
	offer_panel.add_child(offer_box)
	var offer_header := HBoxContainer.new()
	offer_box.add_child(offer_header)
	var offer_title := Label.new()
	offer_title.text = "选择战利品"
	offer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	offer_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	offer_header.add_child(offer_title)
	_offer_count = Label.new()
	_offer_count.name = "RewardOfferCount"
	_offer_count.add_theme_color_override("font_color", _theme.color("text_muted"))
	offer_header.add_child(_offer_count)
	_offer_scroll = ScrollContainer.new()
	_offer_scroll.name = "RewardOfferScroll"
	_offer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_offer_scroll.resized.connect(_fit_offer_cards_to_viewport)
	offer_box.add_child(_offer_scroll)
	_offer_flow = HFlowContainer.new()
	_offer_flow.name = "RewardOfferFlow"
	_offer_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offer_flow.add_theme_constant_override("h_separation", 10)
	_offer_flow.add_theme_constant_override("v_separation", 10)
	_offer_scroll.add_child(_offer_flow)
	var panel := PanelContainer.new()
	panel.name = "RewardActionColumn"
	panel.custom_minimum_size = Vector2(252, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	content.add_child(panel)
	var action_box := VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 10)
	panel.add_child(action_box)
	var action_title := Label.new()
	action_title.text = "处理奖励"
	action_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	action_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	action_box.add_child(action_title)
	_action_column = VBoxContainer.new()
	_action_column.name = "RewardActions"
	_action_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_column.add_theme_constant_override("separation", 8)
	action_box.add_child(_action_column)

func _add_items(items: Array, prefix: String, kind: String, model: Dictionary) -> void:
	for raw in items:
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw
		var id := str(item.get("id", "item_%d" % _action_column.get_child_count()))
		var button := Button.new()
		button.name = "%s_%s" % [prefix, id]
		button.custom_minimum_size = Vector2(178, 196)
		button.text = ""
		button.clip_contents = true
		_apply_button(button, "secondary")
		if (kind == "card" and bool(model.get("card_done", false))) or (kind == "relic" and bool(model.get("relic_done", false))) or (kind == "potion" and bool(model.get("potion_done", false))):
			button.disabled = true
			button.tooltip_text = "已领取"
		elif kind == "card":
			button.pressed.connect(func() -> void: claim_card.emit(id))
		elif kind == "relic":
			button.pressed.connect(func() -> void: claim_relic.emit(id))
		else:
			button.pressed.connect(func() -> void: claim_potion.emit(id))
		_add_offer_layout(button, item, kind)
		_offer_flow.add_child(button)

func _add_masteries(masteries: Array) -> void:
	for raw in masteries:
		if not raw is Dictionary:
			continue
		var mastery: Dictionary = raw
		var id := str(mastery.get("id", ""))
		if id.is_empty():
			continue
		var button := Button.new()
		button.name = "RewardMastery_%s" % id
		button.text = ""
		button.tooltip_text = str(mastery.get("requirement_text", mastery.get("description", "")))
		button.custom_minimum_size = Vector2(178, 196)
		_apply_button(button, "secondary")
		button.pressed.connect(func() -> void: claim_mastery.emit(id))
		_add_offer_layout(button, mastery, "mastery")
		_offer_flow.add_child(button)

func _add_action(node_name: String, label: String, tooltip: String, callback: Callable, variant: String = "secondary") -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(220, 56)
	_apply_button(button, variant)
	button.pressed.connect(callback)
	_action_column.add_child(button)
	return button

func _emit_skip_card() -> void:
	skip_card_requested.emit()

func _emit_skip_potion() -> void:
	skip_potion_requested.emit()

func _emit_save() -> void:
	save_requested.emit()

func _emit_continue() -> void:
	var button := find_child("RewardContinueButton", true, false) as Button
	if button != null and not button.disabled:
		continue_requested.emit()

func _clear_actions() -> void:
	for child in _action_column.get_children():
		_action_column.remove_child(child)
		child.queue_free()

func _clear_offers() -> void:
	for child in _offer_flow.get_children():
		_offer_flow.remove_child(child)
		child.queue_free()

func _clear_receipt_status() -> void:
	for child in _receipt_status.get_children():
		_receipt_status.remove_child(child)
		child.queue_free()

func _add_receipt_line(label_text: String, value_text: String, value_color: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", _theme.color("text_muted"))
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", _theme.color(value_color))
	row.add_child(value)
	_receipt_status.add_child(row)

func _add_offer_layout(button: Button, item: Dictionary, kind: String) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 10
	margin.offset_right = -10
	margin.offset_top = 10
	margin.offset_bottom = -10
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(0, 112)
	art_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	box.add_child(art_frame)
	var art := TextureRect.new()
	art.name = "RewardOfferArt_%s" % str(item.get("id", kind))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _load_texture(str(item.get("art_path", "")))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art)
	var kind_label := Label.new()
	kind_label.text = {"card": "卡牌", "relic": "遗物", "potion": "药水", "mastery": "专精"}.get(kind, "奖励")
	kind_label.add_theme_font_size_override("font_size", _theme.font_size("caption", 12))
	kind_label.add_theme_color_override("font_color", _theme.color("brass_bright"))
	kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(kind_label)
	var title := Label.new()
	title.text = str(item.get("name", item.get("id", "奖励")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", _theme.font_size("body", 15))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var description := Label.new()
	description.text = str(item.get("description", ""))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_font_size_override("font_size", _theme.font_size("caption", 12))
	description.add_theme_color_override("font_color", _theme.color("text_muted"))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(description)

func _pending_offer_count(model: Dictionary, mode: String) -> int:
	var count := 0
	if mode == "combat" and not bool(model.get("card_done", false)):
		count += (model.get("cards", []) as Array).size()
	if not bool(model.get("relic_done", false)):
		count += (model.get("relics", []) as Array).size()
	if mode == "combat" and not bool(model.get("potion_done", false)):
		count += (model.get("potions", []) as Array).size()
	count += (model.get("masteries", []) as Array).size()
	return count

func _relayout_offers() -> void:
	var offer_buttons: Array[Button] = []
	for child in _offer_flow.get_children():
		if child is Button:
			offer_buttons.append(child)
	var count := offer_buttons.size()
	for button in offer_buttons:
		if count <= 3:
			button.custom_minimum_size = Vector2(204, 430)
		elif count <= 6:
			button.custom_minimum_size = Vector2(178, 238)
		else:
			button.custom_minimum_size = Vector2(178, 196)

func _fit_offer_cards_to_viewport() -> void:
	if _offer_scroll == null or _offer_scroll.size.y <= 0.0:
		return
	var offer_buttons: Array[Button] = []
	for child in _offer_flow.get_children():
		if child is Button:
			offer_buttons.append(child)
	var count := offer_buttons.size()
	if count == 0:
		return
	var available_height := maxf(196.0, _offer_scroll.size.y - 4.0)
	var row_height := available_height if count <= 3 else maxf(196.0, floor((available_height - 10.0) * 0.5))
	for button in offer_buttons:
		button.custom_minimum_size.y = row_height

func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _apply_button(button: Button, variant: String) -> void:
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style(variant, "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
