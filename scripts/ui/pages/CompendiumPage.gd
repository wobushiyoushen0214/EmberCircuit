extends Control

signal tab_selected(tab_id: String)
signal filter_selected(filter_id: String)
signal sort_selected(sort_id: String)
signal query_changed(query: String)
signal clear_query_requested
signal close_requested

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _rail: VBoxContainer
var _search: LineEdit
var _filter: OptionButton
var _sort: OptionButton
var _items: GridContainer
var _selected_tab := "cards"

func _init() -> void:
	name = "CompendiumPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	_selected_tab = str(model.get("selected_tab", "cards"))
	custom_minimum_size = Vector2(maxf(960.0, float(model.get("available_width", 1280.0))), maxf(640.0, float(model.get("available_height", 720.0))))
	_clear(_rail)
	_clear(_items)
	var categories: Array = model.get("categories", ["cards", "relics", "potions", "enemies", "events", "challenges"])
	for category in categories:
		var tab_id := str(category)
		var button := Button.new()
		button.name = "CompendiumTab_%s" % tab_id
		button.text = _tab_title(tab_id)
		button.custom_minimum_size = Vector2(148, 44)
		button.disabled = tab_id == _selected_tab
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_button(button, "secondary" if button.disabled else "utility")
		button.pressed.connect(func() -> void: tab_selected.emit(tab_id))
		_rail.add_child(button)
	_configure_selector(_filter, model.get("filters", []), str(model.get("selected_filter", "all")))
	_configure_selector(_sort, model.get("sorts", []), str(model.get("selected_sort", "name")))
	_search.text = str(model.get("query", ""))
	var visible_count := 0
	for raw in model.get("items", []):
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw
		if _append_item(item):
			visible_count += 1
	if visible_count == 0:
		_add_empty_state()

func _build_shell() -> void:
	var scrim := ColorRect.new()
	scrim.name = "CompendiumScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = _theme.color("menu_scrim", "bg_ink")
	add_child(scrim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	margin.add_child(split)
	var rail_panel := PanelContainer.new()
	rail_panel.name = "CompendiumRailPanel"
	rail_panel.custom_minimum_size = Vector2(180, 0)
	rail_panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	split.add_child(rail_panel)
	_rail = VBoxContainer.new()
	_rail.name = "CompendiumRail"
	_rail.add_theme_constant_override("separation", 6)
	rail_panel.add_child(_rail)
	var main := VBoxContainer.new()
	main.name = "CompendiumMain"
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 10)
	split.add_child(main)
	var header := VBoxContainer.new()
	header.name = "CompendiumPageHeader"
	header.add_theme_constant_override("separation", 2)
	main.add_child(header)
	var eyebrow := Label.new()
	eyebrow.text = "ARCHIVE / DISCOVERY"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	header.add_child(eyebrow)
	var title := Label.new()
	title.name = "CompendiumPageTitle"
	title.text = "回路图鉴"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "只显示已经发现的资料；未见内容不会泄露名称、数值或设计注释。"
	subtitle.add_theme_color_override("font_color", _theme.color("text_muted"))
	header.add_child(subtitle)
	var toolbar := HBoxContainer.new()
	toolbar.name = "CompendiumToolbar"
	toolbar.add_theme_constant_override("separation", 8)
	main.add_child(toolbar)
	_search = LineEdit.new()
	_search.name = "CompendiumSearch"
	_search.placeholder_text = "搜索当前分类"
	_search.max_length = 32
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(320, 44)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.focus_mode = Control.FOCUS_ALL
	_search.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	_search.text_changed.connect(func(query: String) -> void: query_changed.emit(query))
	toolbar.add_child(_search)
	_filter = OptionButton.new()
	_filter.name = "CompendiumFilter"
	_filter.custom_minimum_size = Vector2(150, 44)
	_filter.focus_mode = Control.FOCUS_ALL
	_filter.tooltip_text = "筛选当前分类"
	_apply_button(_filter, "secondary")
	_filter.item_selected.connect(_on_filter_selected)
	toolbar.add_child(_filter)
	_sort = OptionButton.new()
	_sort.name = "CompendiumSort"
	_sort.custom_minimum_size = Vector2(150, 44)
	_sort.focus_mode = Control.FOCUS_ALL
	_sort.tooltip_text = "排序当前分类"
	_apply_button(_sort, "secondary")
	_sort.item_selected.connect(_on_sort_selected)
	toolbar.add_child(_sort)
	var close := Button.new()
	close.name = "CompendiumCloseButton"
	close.text = "返回"
	close.custom_minimum_size = Vector2(108, 44)
	_apply_button(close, "primary")
	close.pressed.connect(func() -> void: close_requested.emit())
	toolbar.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.name = "CompendiumItemsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.set("horizontal_scroll_mode", 0)
	scroll.set("vertical_scroll_mode", 1)
	main.add_child(scroll)
	_items = GridContainer.new()
	_items.name = "CompendiumItems"
	_items.columns = 2
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("h_separation", 8)
	_items.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_items)

func _append_item(item: Dictionary) -> bool:
	var id := str(item.get("id", "item_%d" % _items.get_child_count()))
	var kind := str(item.get("kind", "card"))
	var discovered := bool(item.get("discovered", false))
	var panel := PanelContainer.new()
	panel.name = "CompendiumItem_%s" % id
	panel.custom_minimum_size = Vector2(460, 112)
	panel.tooltip_text = str(item.get("tooltip", "")) if discovered else "未发现条目"
	panel.add_theme_stylebox_override("panel", _theme.panel_style("wood" if discovered else "iron"))
	_items.add_child(panel)
	var box := VBoxContainer.new()
	box.name = _template_name(kind)
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := Label.new()
	title.name = "CompendiumItemTitle"
	title.text = str(item.get("title", "条目")) if discovered else "未发现条目"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	title.add_theme_color_override("font_color", _theme.color("text_primary" if discovered else "text_muted"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "CompendiumItemSubtitle"
	subtitle.text = str(item.get("subtitle", "")) if discovered else "继续探索以解锁"
	subtitle.add_theme_color_override("font_color", _theme.color("brass_bright" if discovered else "text_disabled"))
	box.add_child(subtitle)
	var body := Label.new()
	body.name = "CompendiumItemBody"
	body.text = str(item.get("body", "")) if discovered else "内容将在首次发现后显示。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", _theme.color("text_muted"))
	box.add_child(body)
	return true

func _add_empty_state() -> void:
	var panel := PanelContainer.new()
	panel.name = "CompendiumEmptyState"
	panel.custom_minimum_size = Vector2(0, 180)
	panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	_items.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var label := Label.new()
	label.text = "没有匹配的图鉴条目"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", _theme.color("text_muted"))
	box.add_child(label)
	var clear := Button.new()
	clear.name = "CompendiumClearSearchButton"
	clear.text = "清空搜索"
	clear.custom_minimum_size = Vector2(156, 44)
	clear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_button(clear, "primary")
	clear.pressed.connect(func() -> void: clear_query_requested.emit())
	box.add_child(clear)

func _apply_button(button: Button, variant: String) -> void:
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("disabled", _theme.button_style(variant, "disabled"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))

func _configure_selector(selector: OptionButton, options: Array, selected_id: String) -> void:
	selector.clear()
	var selected_index := 0
	for option_value in options:
		if not option_value is Dictionary:
			continue
		var option: Dictionary = option_value
		var option_id := str(option.get("id", ""))
		selector.add_item(str(option.get("label", option_id)))
		var index := selector.item_count - 1
		selector.set_item_metadata(index, option_id)
		if option_id == selected_id:
			selected_index = index
	if selector.item_count > 0:
		selector.select(selected_index)

func _on_filter_selected(index: int) -> void:
	if index >= 0 and index < _filter.item_count:
		filter_selected.emit(str(_filter.get_item_metadata(index)))

func _on_sort_selected(index: int) -> void:
	if index >= 0 and index < _sort.item_count:
		sort_selected.emit(str(_sort.get_item_metadata(index)))

func _template_name(kind: String) -> String:
	match kind:
		"relic", "potion":
			return "CompendiumRelicTemplate"
		"event", "challenge":
			return "CompendiumEventTemplate"
		_:
			return "CompendiumCardTemplate"

func _tab_title(tab_id: String) -> String:
	return {
		"cards": "卡牌",
		"relics": "遗物",
		"potions": "药水",
		"enemies": "敌人",
		"events": "事件",
		"challenges": "挑战"
	}.get(tab_id, tab_id)

func _clear(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
