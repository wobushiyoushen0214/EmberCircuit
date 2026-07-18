extends PanelContainer

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var title_label: Label
var subtitle_label: Label
var stats_box: Container
var unlock_box: Container

func _init() -> void:
	custom_minimum_size = Vector2(480, 260)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", _theme.panel_style("wood"))
	_build()

func configure(model: Dictionary) -> void:
	title_label.text = str(model.get("title", "终局"))
	subtitle_label.text = str(model.get("subtitle", ""))
	_clear(stats_box)
	_clear(unlock_box)
	var stats: Dictionary = model.get("stats", {})
	var stat_entries: Array = model.get("stat_entries", [])
	if stat_entries.is_empty():
		stat_entries = [
			["生命", "%d/%d" % [int(stats.get("hp", 0)), int(stats.get("max_hp", 0))]],
			["金币", "%d" % int(stats.get("gold", 0))],
			["牌组", "%d 张" % int(stats.get("deck_size", 0))],
			["遗物", "%d" % int(stats.get("relic_count", 0))],
			["药水", "%d" % int(stats.get("potion_count", 0))]
		]
	for spec in stat_entries:
		var row := Label.new()
		row.name = "OutcomeStat_%s" % str(spec[0])
		row.text = "%s  ·  %s" % [str(spec[0]), str(spec[1])]
		row.custom_minimum_size = Vector2(128, 26)
		row.add_theme_color_override("font_color", _theme.color("text_primary"))
		stats_box.add_child(row)
	var unlocks: Array = model.get("unlocks", [])
	if unlocks.is_empty():
		var none := Label.new()
		none.text = "暂无新增解锁"
		none.add_theme_color_override("font_color", _theme.color("text_muted"))
		unlock_box.add_child(none)
	else:
		for unlock in unlocks:
			var label := Label.new()
			label.text = "· %s" % str(unlock)
			label.custom_minimum_size = Vector2(180, 24)
			label.add_theme_color_override("font_color", _theme.color("brass_bright"))
			unlock_box.add_child(label)

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var eyebrow := Label.new()
	eyebrow.text = "EMBER CIRCUIT  /  RUN SUMMARY"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	box.add_child(eyebrow)
	title_label = Label.new()
	title_label.name = "OutcomeTitle"
	title_label.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title_label.add_theme_color_override("font_color", _theme.color("text_primary"))
	box.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.name = "OutcomeSubtitle"
	subtitle_label.custom_minimum_size = Vector2(380, 48)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.max_lines_visible = 3
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label.add_theme_color_override("font_color", _theme.color("text_muted"))
	box.add_child(subtitle_label)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(44, 2)
	rule.color = _theme.color("ember")
	box.add_child(rule)
	var stats_title := Label.new()
	stats_title.text = "本局摘要"
	stats_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	stats_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	box.add_child(stats_title)
	stats_box = GridContainer.new()
	stats_box.name = "OutcomeStats"
	(stats_box as GridContainer).columns = 3
	stats_box.add_theme_constant_override("h_separation", 8)
	stats_box.add_theme_constant_override("v_separation", 4)
	box.add_child(stats_box)
	var unlock_title := Label.new()
	unlock_title.text = "局外解锁"
	unlock_title.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	unlock_title.add_theme_color_override("font_color", _theme.color("text_primary"))
	box.add_child(unlock_title)
	unlock_box = HFlowContainer.new()
	unlock_box.name = "OutcomeUnlocks"
	unlock_box.add_theme_constant_override("h_separation", 8)
	unlock_box.add_theme_constant_override("v_separation", 4)
	box.add_child(unlock_box)

func _clear(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
