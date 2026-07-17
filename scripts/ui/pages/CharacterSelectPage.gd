extends Control

signal character_preview_requested(character_id: String)
signal challenge_delta_requested(level: int)
signal confirm_requested(character_id: String, challenge_level: int)
signal back_requested

const CharacterStageCardScript = preload("res://scripts/ui/components/CharacterStageCard.gd")
const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var header: VBoxContainer
var cards: Array[Button] = []
var character_stages: Array = []
var challenge_buttons: Array[Button] = []
var confirm_button: Button
var back_button: Button
var deck_preview_overlay: Control
var deck_preview_label: Label

var selected_character_id: String = ""
var selected_challenge_level: int = 0

var _theme := ForgeThemeScript.new()
var _character_names: Dictionary = {}
var _challenge_models: Dictionary = {}
var _unlocked_challenge_max := 0
var _available_width := 1280.0
var _page_height := 430.0
var _compact := false
var _challenge_track: HBoxContainer
var _roster: Control
var _card_parent: Container
var _footer: PanelContainer
var _footer_margin: MarginContainer
var _footer_summary: Label
var _action_row: HBoxContainer
var _deck_preview_title: Label
var _deck_preview_close: Button
var _focus_before_overlay: Control
var _page_padding: float = 20.0

func _init() -> void:
	name = "CharacterSelectPage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	set_process_unhandled_key_input(true)

func configure(model: Dictionary) -> void:
	selected_character_id = str(model.get("selected_character_id", "ember_exile"))
	selected_challenge_level = int(model.get("selected_challenge_level", 0))
	_unlocked_challenge_max = int(model.get("unlocked_challenge_max", 0))
	_available_width = max(280.0, float(model.get("available_width", 1280.0)))
	_compact = bool(model.get("compact", _available_width < 760.0))
	_page_padding = 12.0 if _compact else 20.0
	var available_height: float = float(model.get("available_height", 720.0))
	_page_height = max(458.0, available_height)
	custom_minimum_size = Vector2(_available_width, _page_height)
	size = custom_minimum_size
	_clear_page()
	_build_scrim()
	_build_header()
	_build_challenge_track(model.get("challenges", []))
	_build_roster(model.get("characters", []))
	_build_footer()
	_build_deck_preview()
	_layout_page()
	_configure_focus_order()
	_focus_initial.call_deferred()

func close_deck_preview() -> void:
	if deck_preview_overlay == null:
		return
	deck_preview_overlay.hide()
	if _focus_before_overlay != null and is_instance_valid(_focus_before_overlay) and _focus_before_overlay.is_inside_tree():
		_focus_before_overlay.grab_focus()
	_focus_before_overlay = null

func focus_initial() -> void:
	_focus_initial()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and header != null:
		_layout_page()

func _unhandled_key_input(event: InputEvent) -> void:
	if deck_preview_overlay != null and deck_preview_overlay.visible and event.is_action_pressed("ui_cancel"):
		close_deck_preview()
		get_viewport().set_input_as_handled()

func _build_header() -> void:
	header = VBoxContainer.new()
	header.name = "CharacterPageHeader"
	header.add_theme_constant_override("separation", 2)
	add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "新跑团 / 角色校准"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	header.add_child(eyebrow)

	var title := Label.new()
	title.text = "选择回路行者"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	header.add_child(title)

func _build_scrim() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CharacterMenuScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = _theme.color("menu_scrim", "bg_ink")
	add_child(scrim)

func _build_challenge_track(raw_challenges: Array) -> void:
	_challenge_track = HBoxContainer.new()
	_challenge_track.name = "ChallengeTrack"
	_challenge_track.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	add_child(_challenge_track)
	_challenge_models.clear()
	challenge_buttons.clear()
	var challenges: Array = raw_challenges
	if challenges.is_empty():
		challenges = [
			{"level": 0, "short_name": "普通", "description": "标准三章跑团。"},
			{"level": 1, "short_name": "挑战 1", "description": "敌人生命提高。"},
			{"level": 2, "short_name": "挑战 2", "description": "灼热开局。"},
			{"level": 3, "short_name": "挑战 3", "description": "高压意图。"}
		]
	var count: int = max(1, challenges.size())
	var gap_total := float(max(0, count - 1)) * _theme.spacing("card_gap")
	var content_width: float = max(280.0, _available_width - _page_padding * 2.0)
	var track_budget: float = content_width if _compact else min(560.0, content_width * 0.52)
	var button_width: float = floor((track_budget - gap_total) / float(count))
	button_width = clamp(button_width, 72.0 if _compact else 96.0, 128.0)
	for raw in challenges:
		var challenge: Dictionary
		if raw is Dictionary:
			challenge = raw
		else:
			var raw_level := int(raw)
			challenge = {
				"level": raw_level,
				"short_name": "普通" if raw_level == 0 else "挑战 %d" % raw_level,
				"description": ""
			}
		var level := int(challenge.get("level", 0))
		_challenge_models[level] = challenge
		var button := Button.new()
		button.name = "Challenge_%d" % level
		button.custom_minimum_size = Vector2(button_width, 44)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", _theme.font_size("caption"))
		button.set_meta("challenge_level", level)
		button.disabled = level > _unlocked_challenge_max
		button.pressed.connect(_on_challenge_pressed.bind(level))
		_challenge_track.add_child(button)
		challenge_buttons.append(button)
	_update_challenge_buttons()

func _build_roster(raw_characters: Array) -> void:
	_character_names.clear()
	cards.clear()
	character_stages.clear()
	var characters: Array = raw_characters
	if _compact:
		var roster_scroll := ScrollContainer.new()
		roster_scroll.name = "CharacterRosterScroll"
		roster_scroll.set("horizontal_scroll_mode", 1)
		roster_scroll.set("vertical_scroll_mode", 0)
		roster_scroll.clip_contents = true
		var roster_row := HBoxContainer.new()
		roster_row.name = "CharacterRoster"
		roster_row.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
		roster_scroll.add_child(roster_row)
		_roster = roster_scroll
		_card_parent = roster_row
	else:
		var roster_flow := HFlowContainer.new()
		roster_flow.name = "CharacterRoster"
		roster_flow.add_theme_constant_override("h_separation", int(_theme.spacing("card_gap")))
		roster_flow.add_theme_constant_override("v_separation", int(_theme.spacing("card_gap")))
		_roster = roster_flow
		_card_parent = roster_flow
	add_child(_roster)

	if selected_character_id.is_empty() and not characters.is_empty():
		var first_character = characters[0]
		if first_character is Dictionary:
			selected_character_id = str(first_character.get("id", ""))
	var count: int = max(1, characters.size())
	var gap_total := float(max(0, count - 1)) * _theme.spacing("card_gap")
	var content_width: float = max(280.0, _available_width - _page_padding * 2.0)
	var desktop_card_width: float = clamp(floor((content_width - gap_total) / float(count)), 286.0, 420.0)
	var compact_card_width: float = clamp(floor(content_width * 0.82), 268.0, 320.0)
	for raw in characters:
		if not raw is Dictionary:
			continue
		var character: Dictionary = raw
		var character_id := str(character.get("id", ""))
		if character_id.is_empty():
			continue
		_character_names[character_id] = str(character.get("name", character_id))
		var stage = CharacterStageCardScript.new()
		stage.custom_minimum_size = Vector2(compact_card_width if _compact else desktop_card_width, 252)
		stage.configure(character, character_id == selected_character_id, _compact)
		stage.preview_requested.connect(_on_character_pressed)
		stage.deck_preview_requested.connect(_open_deck_preview)
		_card_parent.add_child(stage)
		cards.append(stage.select_button)
		character_stages.append(stage)
	if _compact and _card_parent is HBoxContainer:
		var required_width := 0.0
		for card in cards:
			required_width += card.custom_minimum_size.x
		required_width += float(max(0, cards.size() - 1)) * _theme.spacing("card_gap")
		_card_parent.custom_minimum_size = Vector2(max(content_width, required_width), 252)

func _build_footer() -> void:
	_footer = PanelContainer.new()
	_footer.name = "CharacterFooterCompact" if _compact else "CharacterFooter"
	_footer.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	add_child(_footer)

	_footer_margin = MarginContainer.new()
	_footer_margin.add_theme_constant_override("margin_left", int(_theme.spacing("panel_gap")))
	_footer_margin.add_theme_constant_override("margin_right", int(_theme.spacing("panel_gap")))
	_footer_margin.add_theme_constant_override("margin_top", 8)
	_footer_margin.add_theme_constant_override("margin_bottom", 8)
	_footer.add_child(_footer_margin)
	_footer_summary = Label.new()
	_footer_summary.max_lines_visible = 1
	_footer_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_footer_summary.add_theme_font_size_override("font_size", _theme.font_size("body" if not _compact else "caption"))
	_footer_summary.add_theme_color_override("font_color", _theme.color("text_primary"))
	_footer_margin.add_child(_footer_summary)

	_action_row = HBoxContainer.new()
	_action_row.name = "CharacterActionRow"
	_action_row.alignment = BoxContainer.ALIGNMENT_END
	_action_row.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	add_child(_action_row)

	back_button = Button.new()
	back_button.name = "CharacterBackButton"
	back_button.text = "返回主菜单"
	back_button.custom_minimum_size = Vector2(124 if not _compact else 104, 44)
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_action_styles(back_button, false)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	_action_row.add_child(back_button)

	confirm_button = Button.new()
	confirm_button.name = "CharacterConfirmButton"
	confirm_button.custom_minimum_size = Vector2(232 if not _compact else 216, 44)
	confirm_button.focus_mode = Control.FOCUS_ALL
	confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_action_styles(confirm_button, true)
	confirm_button.pressed.connect(func() -> void: confirm_requested.emit(selected_character_id, selected_challenge_level))
	_action_row.add_child(confirm_button)
	_update_footer()

func _build_deck_preview() -> void:
	deck_preview_overlay = Control.new()
	deck_preview_overlay.name = "StarterDeckOverlay"
	deck_preview_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_preview_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_preview_overlay.z_index = 100
	add_child(deck_preview_overlay)

	var scrim := ColorRect.new()
	scrim.name = "DeckOverlayScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scrim_color := _theme.color("bg_ink")
	scrim_color.a = 0.88
	scrim.color = scrim_color
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_preview_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_preview_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "DeckPreviewPanel"
	panel.custom_minimum_size = Vector2(min(560.0, _available_width - 32.0), 238)
	panel.add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", int(_theme.spacing("card_gap")))
	panel.add_child(content)
	var eyebrow := Label.new()
	eyebrow.text = "起始配置 / 牌组明细"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	content.add_child(eyebrow)
	_deck_preview_title = Label.new()
	_deck_preview_title.add_theme_font_size_override("font_size", _theme.font_size("heading_md"))
	_deck_preview_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	content.add_child(_deck_preview_title)
	deck_preview_label = Label.new()
	deck_preview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_preview_label.add_theme_font_size_override("font_size", _theme.font_size("body"))
	deck_preview_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	content.add_child(deck_preview_label)
	_deck_preview_close = Button.new()
	_deck_preview_close.text = "关闭牌组详情"
	_deck_preview_close.custom_minimum_size = Vector2(168, 44)
	_deck_preview_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	_apply_action_styles(_deck_preview_close, false)
	_deck_preview_close.pressed.connect(close_deck_preview)
	content.add_child(_deck_preview_close)
	deck_preview_overlay.hide()

func _layout_page() -> void:
	# The configured viewport is authoritative. A page mounted with full anchors can
	# briefly receive a doubled rect while Godot resolves its old offsets; feeding
	# that transient size back into custom minimums permanently inflated the roster.
	var width: float = _available_width
	var height: float = _page_height
	var content_width: float = max(280.0, width - _page_padding * 2.0)
	if _compact:
		header.position = Vector2(_page_padding, _page_padding)
		header.size = Vector2(content_width, 44)
		_challenge_track.position = Vector2(_page_padding, _page_padding + 52.0)
		_challenge_track.size = Vector2(content_width, 44)
		var footer_height: float = 96.0
		var roster_y: float = _page_padding + 104.0
		var footer_y: float = height - _page_padding - footer_height
		_roster.position = Vector2(_page_padding, roster_y)
		_roster.size = Vector2(content_width, max(244.0, footer_y - roster_y - 8.0))
		_roster.custom_minimum_size = _roster.size
		_footer.position = Vector2(_page_padding, footer_y)
		_footer.size = Vector2(content_width, footer_height)
		_footer_margin.add_theme_constant_override("margin_right", int(_theme.spacing("panel_gap")))
		_action_row.position = Vector2(_page_padding + _theme.spacing("panel_gap"), footer_y + 44.0)
		_action_row.size = Vector2(content_width - _theme.spacing("panel_gap") * 2.0, 44)
		var action_width: float = max(0.0, _action_row.size.x - _theme.spacing("card_gap"))
		back_button.custom_minimum_size.x = min(112.0, floor(action_width * 0.34))
		confirm_button.custom_minimum_size.x = max(160.0, action_width - back_button.custom_minimum_size.x)
	else:
		var challenge_width: float = min(_challenge_track.get_combined_minimum_size().x, content_width * 0.56)
		header.position = Vector2(_page_padding, _page_padding)
		header.size = Vector2(max(260.0, content_width - challenge_width - _theme.spacing("section_gap")), 56)
		_challenge_track.position = Vector2(_page_padding + content_width - challenge_width, _page_padding + 4.0)
		_challenge_track.size = Vector2(challenge_width, 48)
		var footer_height: float = 60.0
		var roster_y: float = _page_padding + 64.0
		var footer_y: float = height - _page_padding - footer_height
		_roster.position = Vector2(_page_padding, roster_y)
		_roster.size = Vector2(content_width, max(252.0, footer_y - roster_y - 8.0))
		_roster.custom_minimum_size = _roster.size
		_footer.position = Vector2(_page_padding, footer_y)
		_footer.size = Vector2(content_width, footer_height)
		var action_width: float = back_button.custom_minimum_size.x + confirm_button.custom_minimum_size.x + _theme.spacing("card_gap")
		_footer_margin.add_theme_constant_override("margin_right", int(action_width + _theme.spacing("section_gap")))
		_action_row.position = Vector2(_page_padding + content_width - action_width - _theme.spacing("panel_gap"), footer_y + 8.0)
		_action_row.size = Vector2(action_width, 44)
	if _card_parent != null:
		for stage in character_stages:
			stage.set_stage_height(max(244.0, _roster.size.y))
		_card_parent.custom_minimum_size.y = _roster.size.y
		_card_parent.queue_sort()
	_challenge_track.queue_sort()
	_action_row.queue_sort()

func _on_character_pressed(character_id: String) -> void:
	if not _character_names.has(character_id):
		return
	selected_character_id = character_id
	for stage in character_stages:
		stage.set_selected_state(stage.character_id == selected_character_id)
	_update_footer()
	character_preview_requested.emit(character_id)

func _on_challenge_pressed(level: int) -> void:
	if level > _unlocked_challenge_max or not _challenge_models.has(level):
		return
	selected_challenge_level = level
	_update_challenge_buttons()
	_update_footer()
	challenge_delta_requested.emit(level)

func _update_challenge_buttons() -> void:
	for button in challenge_buttons:
		var level := int(button.get_meta("challenge_level", 0))
		var challenge: Dictionary = _challenge_models.get(level, {})
		var short_name := str(challenge.get("short_name", "普通" if level == 0 else "挑战 %d" % level))
		var selected := level == selected_challenge_level
		button.disabled = level > _unlocked_challenge_max
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
		button.text = "%s\n%s" % [short_name, "未解锁" if button.disabled else ("当前" if selected else "选择")]
		var description := str(challenge.get("description", ""))
		var modifier := str(challenge.get("modifier_summary", ""))
		var configured_tooltip := str(challenge.get("tooltip", ""))
		var detail := configured_tooltip if not configured_tooltip.is_empty() else "\n".join([description, modifier]).strip_edges()
		button.tooltip_text = "%s\n挑战等级 %d 尚未解锁。" % [detail, level] if button.disabled else detail
		_apply_challenge_styles(button, selected)

func _update_footer() -> void:
	if confirm_button == null or _footer_summary == null:
		return
	var display := str(_character_names.get(selected_character_id, "尚未选择"))
	var challenge: Dictionary = _challenge_models.get(selected_challenge_level, {})
	var challenge_name := str(challenge.get("short_name", "普通" if selected_challenge_level == 0 else "挑战 %d" % selected_challenge_level))
	_footer_summary.text = "当前配置  %s  ·  %s" % [display, challenge_name]
	confirm_button.text = "以%s开始" % display
	confirm_button.disabled = not _character_names.has(selected_character_id) or selected_challenge_level > _unlocked_challenge_max

func _open_deck_preview(character_id: String, deck_summary: String) -> void:
	if deck_preview_overlay == null:
		return
	_focus_before_overlay = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	_deck_preview_title.text = "%s · 起始牌组" % str(_character_names.get(character_id, character_id))
	deck_preview_label.text = deck_summary if not deck_summary.is_empty() else "未提供起始牌组明细。"
	deck_preview_overlay.show()
	if _deck_preview_close.is_inside_tree():
		_deck_preview_close.grab_focus()

func _configure_focus_order() -> void:
	for index in range(cards.size()):
		var current: Control = cards[index]
		var previous: Control = cards[(index - 1 + cards.size()) % cards.size()]
		var next: Control = cards[(index + 1) % cards.size()]
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_right = current.get_path_to(next)
		if confirm_button != null:
			current.focus_neighbor_bottom = current.get_path_to(confirm_button)
	for index in range(challenge_buttons.size()):
		var current_challenge: Control = challenge_buttons[index]
		var previous_challenge: Control = challenge_buttons[(index - 1 + challenge_buttons.size()) % challenge_buttons.size()]
		var next_challenge: Control = challenge_buttons[(index + 1) % challenge_buttons.size()]
		current_challenge.focus_neighbor_left = current_challenge.get_path_to(previous_challenge)
		current_challenge.focus_neighbor_right = current_challenge.get_path_to(next_challenge)

func _focus_initial() -> void:
	for stage in character_stages:
		if stage.character_id == selected_character_id and stage.select_button.is_inside_tree():
			stage.select_button.grab_focus()
			return
	if not cards.is_empty() and cards[0].is_inside_tree():
		cards[0].grab_focus()

func _apply_action_styles(button: Button, primary: bool) -> void:
	button.add_theme_stylebox_override("normal", _action_style("primary" if primary else "normal"))
	button.add_theme_stylebox_override("hover", _action_style("hover"))
	button.add_theme_stylebox_override("pressed", _action_style("pressed"))
	button.add_theme_stylebox_override("focus", _action_style("focus"))
	button.add_theme_stylebox_override("disabled", _action_style("disabled"))

func _apply_challenge_styles(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _challenge_style("selected" if selected else "normal"))
	button.add_theme_stylebox_override("hover", _challenge_style("hover"))
	button.add_theme_stylebox_override("pressed", _challenge_style("selected"))
	button.add_theme_stylebox_override("focus", _challenge_style("focus"))
	button.add_theme_stylebox_override("disabled", _challenge_style("disabled"))

func _action_style(state: String) -> StyleBoxFlat:
	var style := _theme.button_style("neutral")
	if state == "primary":
		style.bg_color = _theme.color("panel_wood")
		style.border_color = _theme.color("ember")
		style.set_border_width_all(2)
	elif state == "hover" or state == "pressed":
		style.bg_color = _theme.color("panel_wood")
		style.border_color = _theme.color("brass_bright")
	elif state == "focus":
		style.border_color = _theme.color("focus_ring")
		style.set_border_width_all(max(2, int(_theme.spacing("focus_width", 2.0))))
	elif state == "disabled":
		style = _theme.button_style("neutral", "disabled")
	return style

func _challenge_style(state: String) -> StyleBoxFlat:
	var style := _theme.button_style("neutral")
	if state == "selected":
		style.bg_color = _theme.color("panel_wood")
		style.border_color = _theme.color("ember")
		style.set_border_width_all(2)
	elif state == "hover":
		style.border_color = _theme.color("brass_bright")
	elif state == "focus":
		style.border_color = _theme.color("focus_ring")
		style.set_border_width_all(max(2, int(_theme.spacing("focus_width", 2.0))))
	elif state == "disabled":
		style = _theme.button_style("neutral", "disabled")
	return style

func _clear_page() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	header = null
	confirm_button = null
	back_button = null
	deck_preview_overlay = null
	deck_preview_label = null
	_challenge_track = null
	_roster = null
	_card_parent = null
	_footer = null
	_footer_margin = null
	_footer_summary = null
	_action_row = null
	_deck_preview_title = null
	_deck_preview_close = null
	cards.clear()
	character_stages.clear()
	challenge_buttons.clear()
