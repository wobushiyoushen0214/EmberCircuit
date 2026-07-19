extends Control

signal node_selected(node_id: String)
signal node_previewed(node_id: String)

const MapViewScript = preload("res://scripts/map/MapView.gd")
const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var map_view: Control
var _theme := ForgeThemeScript.new()
var _risk_summary: Label
var _route_preview: Label

func _init() -> void:
	name = "MapPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	var width := float(model.get("available_width", 1280.0))
	var height := float(model.get("available_height", 720.0))
	custom_minimum_size = Vector2(width, height)
	map_view.custom_minimum_size = Vector2(max(480.0, width - 48.0), max(360.0, height - 146.0))
	map_view.position = Vector2(24.0, 112.0)
	map_view.size = map_view.custom_minimum_size
	var available_ids: Array[String] = []
	for raw_id in model.get("available_node_ids", []):
		available_ids.append(str(raw_id))
	map_view.set_map_state(
		model.get("graph", {}),
		available_ids,
		_completed_dict(model.get("completed_node_ids", [])),
		str(model.get("current_node_id", ""))
	)
	var successor_ids: Array[String] = []
	for raw_id in model.get("preview_successor_ids", []):
		successor_ids.append(str(raw_id))
	var preview_successors: Array[String] = []
	for raw_successor in model.get("preview_successors", successor_ids):
		preview_successors.append(str(raw_successor))
	map_view.set_preview_details(
		str(model.get("preview_title", "")),
		str(model.get("preview_risk", "")),
		str(model.get("preview_reward", "")),
		str(model.get("preview_description", "")),
		preview_successors
	)
	_risk_summary.text = "路线风险  ·  %s" % str(model.get("risk_summary", "前方节点状态可预览"))
	_route_preview.text = "后继预览  ·  %s" % ", ".join(successor_ids)

func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.name = "MapRoomMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var column := VBoxContainer.new()
	column.name = "MapRoomColumn"
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new()
	title.name = "MapRoomTitle"
	title.text = "路线分叉"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	column.add_child(title)
	_risk_summary = Label.new()
	_risk_summary.name = "MapRiskSummary"
	_risk_summary.add_theme_color_override("font_color", _theme.color("text_muted"))
	column.add_child(_risk_summary)
	_route_preview = Label.new()
	_route_preview.name = "MapRoutePreview"
	_route_preview.add_theme_color_override("font_color", _theme.color("brass_bright"))
	column.add_child(_route_preview)
	map_view = MapViewScript.new()
	map_view.name = "EmberMapView"
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.node_selected.connect(func(id: String) -> void: node_selected.emit(id))
	map_view.node_previewed.connect(func(id: String) -> void: node_previewed.emit(id))
	add_child(map_view)
	move_child(map_view, 0)

func _completed_dict(raw) -> Dictionary:
	if raw is Dictionary:
		return raw.duplicate(true)
	var result := {}
	if raw is Array:
		for item in raw:
			result[str(item)] = true
	return result
