extends VBoxContainer

signal preview_requested(character_id: String)
signal deck_preview_requested(character_id: String, deck_summary: String)

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var character_id: String = ""
var select_button: Button
var selection_state_label: Label
var relic_label: Label
var deck_button: Button
var name_label: Label
var archetype_label: Label
var stats_label: Label
var resources_label: Label
var portrait: TextureRect

var _theme := ForgeThemeScript.new()
var _selected: bool = false
var _compact: bool = false
var _deck_summary: String = ""
var _accent_color := Color(0.85, 0.36, 0.17)
var _stage_panel: PanelContainer
var _portrait_frame: PanelContainer
var _portrait_placeholder: Label
var _accent_rail: ColorRect

func _init() -> void:
	name = "CharacterStageCard"
	custom_minimum_size = Vector2(320, 420)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	_build_content()

func configure(model: Dictionary, selected: bool, compact: bool = false) -> void:
	character_id = str(model.get("id", ""))
	_selected = selected
	_compact = compact
	_deck_summary = str(model.get("deck_summary", "未提供起始牌组明细。"))
	var configured_accent: Variant = model.get("accent_color")
	_accent_color = configured_accent if configured_accent is Color else _theme.color("ember")
	name = "CharacterStage_%s" % character_id
	name_label.text = str(model.get("name", character_id if not character_id.is_empty() else "回路行者"))
	archetype_label.text = str(model.get("archetype", model.get("summary", "等待校准的战斗协议。")))
	stats_label.text = "生命 %d  ·  能量 %d  ·  势能 %d/%d" % [
		int(model.get("max_hp", 0)),
		int(model.get("max_energy", 0)),
		int(model.get("starting_momentum", 0)),
		int(model.get("momentum_max", 0))
	]
	resources_label.text = "金币 %d  ·  药水槽 %d" % [
		int(model.get("starting_gold", 0)),
		int(model.get("potion_slots", 0))
	]
	var relic_names: String = str(model.get("relic_names", ""))
	relic_label.text = "起始遗物  %s" % (relic_names if not relic_names.is_empty() else "未配置")
	var deck_count: int = int(model.get("deck_count", 0))
	deck_button.text = "查看起始牌组" if deck_count <= 0 else "查看起始牌组 · %d 张" % deck_count
	deck_button.tooltip_text = "起始牌组\n%s" % _deck_summary
	select_button.tooltip_text = str(model.get("tooltip", "%s\n%s" % [name_label.text, archetype_label.text]))
	var texture_value: Variant = model.get("texture")
	portrait.texture = _focused_portrait_texture(texture_value) if texture_value is Texture2D else null
	portrait.visible = portrait.texture != null
	_portrait_placeholder.visible = portrait.texture == null
	_portrait_frame.custom_minimum_size.y = 150.0 if _compact else 270.0
	set_selected_state(_selected)

func set_stage_height(stage_height: float) -> void:
	custom_minimum_size.y = max(244.0, stage_height)
	var reserved_height := _theme.metric("character_stage_reserved_height", 244.0)
	var minimum_portrait := _theme.metric("character_portrait_min_compact" if _compact else "character_portrait_min_desktop", 150.0 if _compact else 270.0)
	var maximum_portrait := _theme.metric("character_portrait_max_compact" if _compact else "character_portrait_max_desktop", 280.0 if _compact else 650.0)
	_portrait_frame.custom_minimum_size.y = clamp(custom_minimum_size.y - reserved_height, minimum_portrait, maximum_portrait)

func set_selected_state(selected: bool) -> void:
	_selected = selected
	selection_state_label.text = "已选择" if selected else "选择此角色"
	selection_state_label.add_theme_color_override("font_color", _accent_color if selected else _theme.color("text_muted"))
	_accent_rail.color = _accent_color if selected else _theme.color("border_subtle")
	_stage_panel.add_theme_stylebox_override("panel", _stage_style())
	_apply_select_button_styles()

func _build_content() -> void:
	_stage_panel = PanelContainer.new()
	_stage_panel.name = "CharacterStagePanel"
	_stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_stage_panel)

	var margin := MarginContainer.new()
	margin.name = "StageContentMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(_theme.spacing("panel_gap")))
	margin.add_theme_constant_override("margin_right", int(_theme.spacing("panel_gap")))
	margin.add_theme_constant_override("margin_top", int(_theme.spacing("panel_gap")))
	margin.add_theme_constant_override("margin_bottom", int(_theme.spacing("panel_gap")))
	_stage_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "StageContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.name = "PortraitStage"
	_portrait_frame.custom_minimum_size = Vector2(0, 270)
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_portrait_frame)

	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_frame.add_child(portrait)

	var placeholder_center := CenterContainer.new()
	placeholder_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(placeholder_center)
	_portrait_placeholder = Label.new()
	_portrait_placeholder.text = "回路行者"
	_portrait_placeholder.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	_portrait_placeholder.add_theme_color_override("font_color", _theme.color("text_muted"))
	placeholder_center.add_child(_portrait_placeholder)

	var portrait_overlay := Control.new()
	portrait_overlay.name = "PortraitOverlay"
	portrait_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(portrait_overlay)
	_accent_rail = ColorRect.new()
	_accent_rail.name = "SelectionRail"
	_accent_rail.anchor_bottom = 1.0
	_accent_rail.offset_right = 4.0
	_accent_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_overlay.add_child(_accent_rail)

	var identity_row := HBoxContainer.new()
	identity_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	content.add_child(identity_row)
	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", _theme.font_size("heading_md"))
	name_label.add_theme_color_override("font_color", _theme.color("text_primary"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(name_label)
	selection_state_label = Label.new()
	selection_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	selection_state_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	selection_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(selection_state_label)

	archetype_label = Label.new()
	archetype_label.max_lines_visible = 2
	archetype_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	archetype_label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	archetype_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	archetype_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(archetype_label)
	stats_label = _new_info_label(_theme.color("text_primary"))
	content.add_child(stats_label)
	resources_label = _new_info_label(_theme.color("text_muted"))
	content.add_child(resources_label)
	relic_label = _new_info_label(_theme.color("brass_bright"))
	relic_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(relic_label)

	select_button = Button.new()
	select_button.name = "CharacterSelectButton"
	select_button.focus_mode = Control.FOCUS_ALL
	select_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	select_button.text = ""
	select_button.pressed.connect(func() -> void: preview_requested.emit(character_id))
	_stage_panel.add_child(select_button)

	deck_button = Button.new()
	deck_button.name = "StarterDeckButton"
	deck_button.custom_minimum_size = Vector2(0, 44)
	deck_button.focus_mode = Control.FOCUS_ALL
	deck_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	deck_button.add_theme_font_size_override("font_size", _theme.font_size("button"))
	deck_button.pressed.connect(func() -> void: deck_preview_requested.emit(character_id, _deck_summary))
	add_child(deck_button)
	_apply_deck_button_styles()

func _new_info_label(font_color: Color) -> Label:
	var label := Label.new()
	label.max_lines_visible = 1
	label.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _focused_portrait_texture(source_texture: Texture2D) -> Texture2D:
	var source_size := source_texture.get_size()
	if source_size.x <= 1.0 or source_size.y <= 1.0:
		return source_texture
	var crop_height_ratio := _theme.metric("character_portrait_crop_height_ratio", 0.9)
	var crop_height: float = minf(source_size.y, source_size.x * crop_height_ratio)
	if crop_height >= source_size.y - 1.0:
		return source_texture
	var focused_texture := AtlasTexture.new()
	focused_texture.atlas = source_texture
	focused_texture.region = Rect2(0.0, 0.0, source_size.x, crop_height)
	return focused_texture

func _stage_style() -> StyleBoxFlat:
	var style := _theme.panel_style("wood" if _selected else "iron")
	style.border_color = _accent_color if _selected else _theme.color("border_subtle")
	style.set_border_width_all(2 if _selected else 1)
	if _selected:
		style.shadow_color = Color(_accent_color, 0.20)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 3)
	return style

func _transparent_button_style(border_color: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = border_color
	style.set_border_width_all(width)
	style.set_corner_radius_all(_theme.radius("card"))
	return style

func _apply_select_button_styles() -> void:
	select_button.add_theme_stylebox_override("normal", _transparent_button_style())
	select_button.add_theme_stylebox_override("hover", _transparent_button_style(_accent_color, 1))
	select_button.add_theme_stylebox_override("pressed", _transparent_button_style(_accent_color, 2))
	select_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))

func _apply_deck_button_styles() -> void:
	deck_button.add_theme_stylebox_override("normal", _theme.button_style("secondary", "normal"))
	deck_button.add_theme_stylebox_override("hover", _theme.button_style("secondary", "hover"))
	deck_button.add_theme_stylebox_override("pressed", _theme.button_style("secondary", "pressed"))
	deck_button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
