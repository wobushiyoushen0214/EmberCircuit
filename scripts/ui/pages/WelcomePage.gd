extends Control

signal new_run_requested
signal continue_requested
signal archive_requested
signal profile_requested
signal settings_requested

const MenuCommandButtonScript = preload("res://scripts/ui/components/MenuCommandButton.gd")
const PageHeaderScript = preload("res://scripts/ui/components/PageHeader.gd")
const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var header
var primary_action
var secondary_action
var tool_action
var profile_action
var settings_action
var brand_stage: VBoxContainer
var utility_action_row: HFlowContainer
var _theme := ForgeThemeScript.new()

func _init() -> void:
	name = "WelcomePage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scrim := ColorRect.new()
	scrim.name = "MenuScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = _theme.color("menu_scrim", "bg_ink")
	add_child(scrim)

	var center := CenterContainer.new()
	center.name = "BrandStageCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = -18.0
	add_child(center)

	brand_stage = VBoxContainer.new()
	brand_stage.name = "BrandStage"
	brand_stage.custom_minimum_size = Vector2(480, 0)
	brand_stage.add_theme_constant_override("separation", int(_theme.spacing("section_gap")))
	center.add_child(brand_stage)

	header = PageHeaderScript.new()
	header.name = "PageHeader"
	brand_stage.add_child(header)

	var command_column := VBoxContainer.new()
	command_column.name = "PrimaryCommandColumn"
	command_column.add_theme_constant_override("separation", 12)
	brand_stage.add_child(command_column)

	primary_action = _new_action("PrimaryAction")
	secondary_action = _new_action("ContinueAction")
	command_column.add_child(primary_action)
	command_column.add_child(secondary_action)

	var utility_margin := MarginContainer.new()
	utility_margin.name = "UtilityActionMargin"
	utility_margin.add_theme_constant_override("margin_top", 8)
	command_column.add_child(utility_margin)

	utility_action_row = HFlowContainer.new()
	utility_action_row.name = "UtilityActionRow"
	utility_action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_action_row.alignment = FlowContainer.ALIGNMENT_CENTER
	utility_action_row.add_theme_constant_override("h_separation", int(_theme.spacing("card_gap")))
	utility_action_row.add_theme_constant_override("v_separation", int(_theme.spacing("card_gap")))
	utility_margin.add_child(utility_action_row)

	profile_action = _new_action("ProfileAction")
	tool_action = _new_action("ArchiveAction")
	settings_action = _new_action("SettingsAction")
	utility_action_row.add_child(profile_action)
	utility_action_row.add_child(tool_action)
	utility_action_row.add_child(settings_action)

	primary_action.pressed.connect(func() -> void: new_run_requested.emit())
	secondary_action.pressed.connect(func() -> void: continue_requested.emit())
	tool_action.pressed.connect(func() -> void: archive_requested.emit())
	profile_action.pressed.connect(func() -> void: profile_requested.emit())
	settings_action.pressed.connect(func() -> void: settings_requested.emit())

func configure(model: Dictionary) -> void:
	var available_width := float(model.get("available_width", 1280.0))
	var compact := available_width < 620.0
	brand_stage.custom_minimum_size.x = max(280.0, min(480.0, available_width - (40.0 if compact else 64.0)))
	header.configure(
		str(model.get("title", "余烬回路")),
		str(model.get("subtitle", "穿过失控回路，关闭核心。")),
		str(model.get("eyebrow", "EMBER CIRCUIT")),
		true
	)
	header.title_label.add_theme_font_size_override("font_size", 44 if compact else 56)
	header.subtitle_label.add_theme_font_size_override("font_size", 14 if compact else 16)

	_configure_action(primary_action, {
		"title": "开始新跑团",
		"index": "01",
		"variant": "primary"
	}, min(420.0, brand_stage.custom_minimum_size.x), 64.0)
	var available := bool(model.get("continue_available", false))
	_configure_action(secondary_action, {
		"title": "继续跑团",
		"index": "02",
		"status": "最近存档" if available else "暂无存档",
		"body": "读取最近一次保存。" if available else "当前没有可读取的跑团存档。",
		"enabled": available,
		"variant": "secondary"
	}, min(380.0, brand_stage.custom_minimum_size.x), 52.0)
	secondary_action.set_available(available, "最近存档" if available else "暂无存档")
	secondary_action.tooltip_text = "读取最近一次保存。" if available else "当前没有可读取的跑团存档。"

	_configure_action(profile_action, {"title": "档案", "variant": "utility"}, 104.0, 44.0)
	_configure_action(tool_action, {"title": "回路档案", "variant": "utility"}, 104.0, 44.0)
	_configure_action(settings_action, {"title": "设置", "variant": "utility"}, 104.0, 44.0)
	var utility_width: float = max(88.0, floor((brand_stage.custom_minimum_size.x - _theme.spacing("card_gap") * 2.0) / 3.0))
	for action in [profile_action, tool_action, settings_action]:
		action.custom_minimum_size.x = min(104.0, utility_width)

	var reduced_motion := bool(model.get("reduced_motion", false))
	for action in [primary_action, secondary_action, profile_action, tool_action, settings_action]:
		action.reduced_motion = reduced_motion
	_configure_focus_order()
	_focus_initial()

func request_new_run() -> void:
	new_run_requested.emit()

func focus_initial() -> void:
	_focus_initial()

func _ready() -> void:
	_focus_initial.call_deferred()

func _new_action(node_name: String) -> Button:
	var action = MenuCommandButtonScript.new()
	action.name = node_name
	action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return action

func _configure_action(action, model: Dictionary, width: float, height: float) -> void:
	action.configure(model)
	action.custom_minimum_size = Vector2(max(44.0, width), max(44.0, height))

func _configure_focus_order() -> void:
	var first_utility: Control = profile_action
	var last_command: Control = secondary_action if not secondary_action.disabled else primary_action
	primary_action.focus_neighbor_top = primary_action.get_path_to(settings_action)
	primary_action.focus_neighbor_bottom = primary_action.get_path_to(secondary_action if not secondary_action.disabled else first_utility)
	primary_action.focus_neighbor_left = primary_action.get_path_to(primary_action)
	primary_action.focus_neighbor_right = primary_action.get_path_to(primary_action)
	if not secondary_action.disabled:
		secondary_action.focus_neighbor_top = secondary_action.get_path_to(primary_action)
		secondary_action.focus_neighbor_bottom = secondary_action.get_path_to(first_utility)
		secondary_action.focus_neighbor_left = secondary_action.get_path_to(secondary_action)
		secondary_action.focus_neighbor_right = secondary_action.get_path_to(secondary_action)
	profile_action.focus_neighbor_top = profile_action.get_path_to(last_command)
	profile_action.focus_neighbor_bottom = profile_action.get_path_to(primary_action)
	profile_action.focus_neighbor_left = profile_action.get_path_to(settings_action)
	profile_action.focus_neighbor_right = profile_action.get_path_to(tool_action)
	tool_action.focus_neighbor_top = tool_action.get_path_to(last_command)
	tool_action.focus_neighbor_bottom = tool_action.get_path_to(primary_action)
	tool_action.focus_neighbor_left = tool_action.get_path_to(profile_action)
	tool_action.focus_neighbor_right = tool_action.get_path_to(settings_action)
	settings_action.focus_neighbor_top = settings_action.get_path_to(last_command)
	settings_action.focus_neighbor_bottom = settings_action.get_path_to(primary_action)
	settings_action.focus_neighbor_left = settings_action.get_path_to(tool_action)
	settings_action.focus_neighbor_right = settings_action.get_path_to(profile_action)

func _focus_initial() -> void:
	if primary_action != null and primary_action.is_inside_tree():
		primary_action.grab_focus()
