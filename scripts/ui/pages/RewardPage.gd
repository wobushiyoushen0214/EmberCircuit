extends Control

signal claim_card(item_id: String)
signal claim_relic(item_id: String)
signal claim_potion(item_id: String)
signal skip
signal save
signal continue_requested

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _action_column: VBoxContainer

func _init() -> void:
	name = "RewardPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var mode_label := find_child("RewardMode", true, false) as Label
	var gold_label := find_child("RewardGoldReceipt", true, false) as Label
	if mode_label != null:
		mode_label.text = "奖励 · %s" % str(model.get("mode", "combat"))
	if gold_label != null:
		gold_label.text = "金币收据  ·  +%d" % int(model.get("gold", 0))
	_clear_actions()
	_add_items(model.get("cards", []), "RewardCard", "card", model)
	_add_items(model.get("relics", []), "RewardRelic", "relic", model)
	_add_items(model.get("potions", []), "RewardPotion", "potion", model)
	var continue_button := Button.new()
	continue_button.name = "RewardContinueButton"
	continue_button.text = "继续"
	continue_button.custom_minimum_size = Vector2(220, 52)
	_apply_button(continue_button, "primary")
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	_action_column.add_child(continue_button)

func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var room := VBoxContainer.new()
	room.name = "RewardRoom"
	room.add_theme_constant_override("separation", 10)
	margin.add_child(room)
	var header := HBoxContainer.new()
	header.name = "RewardHeader"
	var mode := Label.new()
	mode.name = "RewardMode"
	mode.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	mode.add_theme_color_override("font_color", _theme.color("text_primary"))
	header.add_child(mode)
	room.add_child(header)
	var gold := Label.new()
	gold.name = "RewardGoldReceipt"
	gold.add_theme_color_override("font_color", _theme.color("brass_bright"))
	room.add_child(gold)
	var panel := PanelContainer.new()
	panel.name = "RewardActionColumn"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	room.add_child(panel)
	_action_column = VBoxContainer.new()
	_action_column.name = "RewardActions"
	_action_column.add_theme_constant_override("separation", 8)
	panel.add_child(_action_column)

func _add_items(items: Array, prefix: String, kind: String, model: Dictionary) -> void:
	for raw in items:
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw
		var id := str(item.get("id", "item_%d" % _action_column.get_child_count()))
		var button := Button.new()
		button.name = "%s_%s" % [prefix, id]
		button.custom_minimum_size = Vector2(300, 72)
		button.text = "%s\n%s" % [str(item.get("name", id)), str(item.get("description", ""))]
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
		_action_column.add_child(button)

func _clear_actions() -> void:
	for child in _action_column.get_children():
		child.queue_free()

func _apply_button(button: Button, variant: String) -> void:
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style(variant, "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
