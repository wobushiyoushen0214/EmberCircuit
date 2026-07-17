extends Control

signal rest_requested
signal forge_requested
signal upgrade_card_requested(deck_index: int)
signal leave

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _candidate_column: VBoxContainer
var _rest_button: Button
var _forge_button: Button

func _init() -> void:
	name = "CampfirePage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var node: Dictionary = model.get("node", {})
	var stage := get_node("PcCampfireExperience")
	var story := stage.find_child("CampfireStory", true, false)
	var title := story.find_child("CampfireTitle", true, false) as Label
	var body := story.find_child("CampfireBody", true, false) as Label
	if title != null:
		title.text = str(node.get("name", "废墟锻炉"))
	var hp := int(model.get("hp", 0))
	var max_hp: int = maxi(1, int(model.get("max_hp", 1)))
	var heal_percent := int(model.get("heal_percent", 30))
	if body != null:
		body.text = "当前生命 %d/%d。休息恢复 %d%%，或锻造升级一张牌。" % [hp, max_hp, heal_percent]
	_rest_button.text = "休息\n恢复 %d%%" % heal_percent
	_clear_candidates()
	var candidates: Array = model.get("upgrade_candidates", [])
	_forge_button.disabled = candidates.is_empty()
	_forge_button.tooltip_text = "没有可升级卡牌" if candidates.is_empty() else "打开锻造选择"
	if candidates.is_empty():
		var empty := Label.new()
		empty.text = "没有可升级卡牌。"
		_candidate_column.add_child(empty)
	else:
		for raw in candidates:
			if not raw is Dictionary:
				continue
			var candidate: Dictionary = raw
			var index := int(candidate.get("deck_index", 0))
			var button := Button.new()
			button.name = "CampfireUpgrade_%d" % index
			button.custom_minimum_size = Vector2(260, 56)
			button.text = "%s\n%s" % [str(candidate.get("name", candidate.get("id", "卡牌"))), str(candidate.get("description", ""))]
			button.pressed.connect(func() -> void: upgrade_card_requested.emit(index))
			_apply_button(button, "secondary")
			_candidate_column.add_child(button)

func _build_shell() -> void:
	var stage := PanelContainer.new()
	stage.name = "PcCampfireExperience"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_left = 24
	stage.offset_right = -24
	stage.offset_top = 24
	stage.offset_bottom = -24
	stage.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	add_child(stage)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	stage.add_child(split)
	var story := VBoxContainer.new()
	story.name = "CampfireStory"
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_theme_constant_override("separation", 10)
	split.add_child(story)
	var title := Label.new()
	title.name = "CampfireTitle"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	story.add_child(title)
	var body := Label.new()
	body.name = "CampfireBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", _theme.color("text_muted"))
	story.add_child(body)
	var actions := VBoxContainer.new()
	actions.name = "CampfireActions"
	actions.custom_minimum_size = Vector2(340, 0)
	actions.add_theme_constant_override("separation", 8)
	split.add_child(actions)
	_rest_button = Button.new()
	_rest_button.name = "CampfireRestButton"
	_rest_button.custom_minimum_size = Vector2(280, 56)
	_rest_button.pressed.connect(func() -> void: rest_requested.emit())
	_apply_button(_rest_button, "primary")
	actions.add_child(_rest_button)
	_forge_button = Button.new()
	_forge_button.name = "CampfireForgeButton"
	_forge_button.custom_minimum_size = Vector2(280, 56)
	_forge_button.text = "打开锻造"
	_forge_button.pressed.connect(func() -> void: forge_requested.emit())
	_apply_button(_forge_button, "secondary")
	actions.add_child(_forge_button)
	_candidate_column = VBoxContainer.new()
	_candidate_column.name = "CampfireForgeCandidates"
	_candidate_column.add_theme_constant_override("separation", 6)
	actions.add_child(_candidate_column)

func _clear_candidates() -> void:
	for child in _candidate_column.get_children():
		child.queue_free()

func _apply_button(button: Button, variant: String) -> void:
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style(variant, "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
