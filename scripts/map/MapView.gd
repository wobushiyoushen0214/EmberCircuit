class_name EmberMapView
extends Control

signal node_selected(node_id: String)
signal node_previewed(node_id: String)

const NODE_SIZE := Vector2(132, 58)
const MIN_NODE_SIZE := Vector2(78, 44)
const H_MARGIN := 44.0
const V_MARGIN := 24.0
const PREVIEW_PANEL_SIZE := Vector2(300, 420)
const PREVIEW_PANEL_RIGHT_MARGIN := 20.0
const PREVIEW_PANEL_GAP := 20.0
const TYPE_ICON_PATHS := {
	"combat": "res://assets/art/map_node_combat.svg",
	"elite": "res://assets/art/map_node_elite.svg",
	"boss": "res://assets/art/map_node_boss.svg",
	"event": "res://assets/art/map_node_event.svg",
	"shop": "res://assets/art/map_node_shop.svg",
	"campfire": "res://assets/art/map_node_campfire.svg",
	"treasure": "res://assets/art/map_node_treasure.svg"
}

var graph: Dictionary = {}
var available_node_ids: Array[String] = []
var completed_node_ids: Dictionary = {}
var current_node_id: String = ""
var node_positions: Dictionary = {}
var node_buttons: Dictionary = {}
var last_previewed_node_id: String = ""
var previewed_node_id: String = ""
var preview_successor_ids: Array[String] = []
var icon_cache: Dictionary = {}
var last_risk_badge_texts: Array[String] = []
var preview_panel: PanelContainer
var preview_title_label: Label
var preview_risk_label: Label
var preview_reward_label: Label
var preview_description_label: Label
var preview_successors_label: Label
var preview_detail_title: String = "暂无可预览节点"
var preview_detail_risk: String = "未知"
var preview_detail_reward: String = "待确认"
var preview_detail_description: String = "暂无节点说明。"
var preview_detail_successors: Array[String] = []
var preview_details_are_explicit: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(0, 330)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_preview_panel()
	_layout_preview_panel()

func set_map_state(new_graph: Dictionary, new_available_ids: Array[String], new_completed_ids: Dictionary, new_current_node_id: String = "") -> void:
	_ensure_preview_panel()
	graph = new_graph.duplicate(true)
	available_node_ids = new_available_ids.duplicate()
	completed_node_ids = new_completed_ids.duplicate(true)
	current_node_id = new_current_node_id
	preview_details_are_explicit = false
	if not previewed_node_id.is_empty() and _node_by_id(previewed_node_id).is_empty():
		previewed_node_id = ""
		preview_successor_ids.clear()
	_rebuild_buttons()
	queue_redraw()

func get_node_button_count() -> int:
	return node_buttons.size()

func get_available_button_count() -> int:
	var count := 0
	for node_id in node_buttons.keys():
		if available_node_ids.has(str(node_id)):
			count += 1
	return count

func get_icon_button_count() -> int:
	var count := 0
	for button_value in node_buttons.values():
		var button := button_value as Button
		if button != null and button.icon != null:
			count += 1
	return count

func get_risk_badge_count() -> int:
	var count := 0
	for button_value in node_buttons.values():
		var button := button_value as Button
		if button != null and button.has_node("RiskBadge"):
			count += 1
	return count

func get_risk_badge_texts() -> Array[String]:
	return last_risk_badge_texts.duplicate()

func get_previewed_successor_count() -> int:
	return preview_successor_ids.size()

func set_preview_details(title: String, risk: String, reward: String, description: String, successor_nodes: Array[String]) -> void:
	preview_detail_title = title
	preview_detail_risk = risk
	preview_detail_reward = reward
	preview_detail_description = description
	preview_detail_successors = successor_nodes.duplicate()
	preview_details_are_explicit = true
	_refresh_preview_panel_text()

func set_preview_title(title: String) -> void:
	preview_detail_title = title
	preview_details_are_explicit = true
	_refresh_preview_panel_text()

func set_preview_risk(risk: String) -> void:
	preview_detail_risk = risk
	preview_details_are_explicit = true
	_refresh_preview_panel_text()

func set_preview_reward(reward: String) -> void:
	preview_detail_reward = reward
	preview_details_are_explicit = true
	_refresh_preview_panel_text()

func set_preview_description(description: String) -> void:
	preview_detail_description = description
	preview_details_are_explicit = true
	_refresh_preview_panel_text()

func set_preview_successors(successor_nodes: Array[String]) -> void:
	preview_detail_successors = successor_nodes.duplicate()
	preview_details_are_explicit = true
	_refresh_preview_panel_text()

func set_preview_node(node_id: String, successor_ids: Array[String] = []) -> void:
	previewed_node_id = node_id
	preview_successor_ids = successor_ids.duplicate()
	if not preview_details_are_explicit:
		_set_preview_details_from_graph(node_id, successor_ids)
	_refresh_button_styles()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_preview_panel()
		if not graph.is_empty():
			_layout_buttons()
			queue_redraw()

func _draw() -> void:
	if graph.is_empty() or node_positions.is_empty():
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.07, 0.085, 0.94), true)
	_draw_layer_guides()

	for edge in graph.get("edges", []):
		var edge_dict: Dictionary = edge
		var from_id: String = str(edge_dict.get("from", ""))
		var to_id: String = str(edge_dict.get("to", ""))
		if not node_positions.has(from_id) or not node_positions.has(to_id):
			continue
		var node_size: Vector2 = _node_size()
		var from_pos: Vector2 = node_positions[from_id] + node_size * 0.5
		var to_pos: Vector2 = node_positions[to_id] + node_size * 0.5
		var color := Color(0.33, 0.39, 0.46, 0.7)
		var width := 2.0
		if _edge_is_previewed(from_id, to_id):
			color = Color(0.63, 0.91, 1.0, 0.98)
			width = 5.0
		elif completed_node_ids.has(from_id) and (completed_node_ids.has(to_id) or available_node_ids.has(to_id)):
			color = Color(0.95, 0.68, 0.22, 0.95)
			width = 3.0
		elif available_node_ids.has(to_id):
			color = Color(0.47, 0.73, 0.94, 0.88)
			width = 2.5
		draw_line(from_pos, to_pos, color, width, true)

func _ensure_preview_panel() -> void:
	if is_instance_valid(preview_panel):
		return

	preview_panel = PanelContainer.new()
	preview_panel.name = "NodePreviewPanel"
	preview_panel.custom_minimum_size = PREVIEW_PANEL_SIZE
	preview_panel.size = PREVIEW_PANEL_SIZE
	preview_panel.clip_contents = true
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.z_index = 20
	preview_panel.add_theme_stylebox_override("panel", _preview_panel_style())
	add_child(preview_panel)

	var content := Control.new()
	content.name = "PreviewContent"
	content.size = PREVIEW_PANEL_SIZE
	content.clip_contents = true
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(content)

	var heading := _create_preview_label(content, "PreviewHeading", Rect2(16, 14, 268, 20), 12, 1)
	heading.text = "节点详情"
	heading.add_theme_color_override("font_color", Color(0.49, 0.75, 0.88))

	preview_title_label = _create_preview_label(content, "PreviewTitle", Rect2(16, 39, 268, 48), 18, 2)
	preview_title_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.77))
	preview_risk_label = _create_preview_label(content, "PreviewRisk", Rect2(16, 96, 268, 42), 13, 2)
	preview_risk_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.58))
	preview_reward_label = _create_preview_label(content, "PreviewReward", Rect2(16, 146, 268, 54), 13, 3)
	preview_reward_label.add_theme_color_override("font_color", Color(0.72, 0.91, 0.68))
	preview_description_label = _create_preview_label(content, "PreviewDescription", Rect2(16, 208, 268, 112), 12, 6)
	preview_successors_label = _create_preview_label(content, "PreviewSuccessors", Rect2(16, 330, 268, 76), 12, 4)
	preview_successors_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.94))

	_layout_preview_panel()
	_refresh_preview_panel_text()

func _create_preview_label(parent: Control, label_name: String, bounds: Rect2, font_size: int, max_lines: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = bounds.position
	label.size = bounds.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.max_lines_visible = max_lines
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.93))
	label.add_theme_constant_override("line_spacing", 2)
	parent.add_child(label)
	return label

func _preview_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.095, 0.11, 0.98)
	style.border_color = Color(0.35, 0.50, 0.58, 0.96)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _layout_preview_panel() -> void:
	if not is_instance_valid(preview_panel):
		return
	preview_panel.visible = size.x >= 960.0 and size.y >= PREVIEW_PANEL_SIZE.y
	preview_panel.position = Vector2(
		max(0.0, floor(size.x - PREVIEW_PANEL_SIZE.x - PREVIEW_PANEL_RIGHT_MARGIN)),
		max(0.0, floor((size.y - PREVIEW_PANEL_SIZE.y) * 0.5))
	)
	preview_panel.size = PREVIEW_PANEL_SIZE

func _refresh_preview_panel_text() -> void:
	_ensure_preview_panel()
	preview_title_label.text = preview_detail_title if not preview_detail_title.is_empty() else "暂无可预览节点"
	preview_risk_label.text = "风险\n%s" % (preview_detail_risk if not preview_detail_risk.is_empty() else "未知")
	preview_reward_label.text = "收益\n%s" % (preview_detail_reward if not preview_detail_reward.is_empty() else "待确认")
	preview_description_label.text = "说明\n%s" % (preview_detail_description if not preview_detail_description.is_empty() else "暂无节点说明。")
	var successor_lines: Array[String] = []
	for successor in preview_detail_successors:
		if not successor.is_empty():
			successor_lines.append("- %s" % successor)
	if successor_lines.is_empty():
		successor_lines.append("终点或当前路线末端")
	preview_successors_label.text = "后续节点\n%s" % "\n".join(successor_lines)

func _set_preview_details_from_graph(node_id: String, successor_ids: Array[String]) -> void:
	var node: Dictionary = _node_by_id(node_id)
	if node.is_empty():
		preview_detail_title = "暂无可预览节点"
		preview_detail_risk = "未知"
		preview_detail_reward = "待确认"
		preview_detail_description = "暂无节点说明。"
		preview_detail_successors.clear()
		_refresh_preview_panel_text()
		return

	var node_type: String = str(node.get("type", ""))
	preview_detail_title = "%s [%s]" % [node.get("name", node_id), _type_label(node_type)]
	preview_detail_risk = _risk_tooltip(node).trim_prefix("风险：")
	preview_detail_reward = _preview_reward_text(node_type)
	var tooltip: String = _tooltip_text(node)
	var detail_start: int = tooltip.find("\n")
	preview_detail_description = tooltip.substr(detail_start + 1) if detail_start >= 0 else tooltip
	preview_detail_successors.clear()
	for successor_id in successor_ids:
		var successor: Dictionary = _node_by_id(successor_id)
		if successor.is_empty():
			preview_detail_successors.append(successor_id)
			continue
		preview_detail_successors.append("%s [%s]" % [successor.get("name", successor_id), _type_label(str(successor.get("type", "")))])
	_refresh_preview_panel_text()

func _preview_reward_text(node_type: String) -> String:
	match node_type:
		"combat":
			return "金币与卡牌奖励。"
		"elite":
			return "遗物、更多金币与卡牌奖励。"
		"boss":
			return "章节推进与 Boss 奖励。"
		"event":
			return "由事件选项和当前资源决定。"
		"shop":
			return "可购买卡牌、遗物、药水或删卡。"
		"campfire":
			return "恢复生命或升级卡牌。"
		"treasure":
			return "金币与遗物奖励。"
		_:
			return "待确认"

func _node_layout_rect() -> Rect2:
	var right_edge: float = size.x
	if is_instance_valid(preview_panel) and preview_panel.visible:
		right_edge = min(right_edge, preview_panel.position.x - PREVIEW_PANEL_GAP)
	return Rect2(Vector2.ZERO, Vector2(max(MIN_NODE_SIZE.x + H_MARGIN * 0.5, right_edge), size.y))

func _rebuild_buttons() -> void:
	_ensure_preview_panel()
	for child in get_children():
		if child == preview_panel:
			continue
		remove_child(child)
		child.free()
	node_buttons.clear()
	node_positions.clear()
	last_risk_badge_texts.clear()

	for layer in graph.get("layers", []):
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			var node_id: String = str(node_dict.get("id", ""))
			if node_id.is_empty():
				continue
			var button := Button.new()
			button.custom_minimum_size = NODE_SIZE
			button.clip_contents = true
			button.text = _button_text(node_dict)
			button.icon = _type_texture(str(node_dict.get("type", "")))
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.tooltip_text = _tooltip_text(node_dict)
			button.disabled = not available_node_ids.has(node_id)
			button.pressed.connect(_on_node_button_pressed.bind(node_id))
			button.mouse_entered.connect(_on_node_button_previewed.bind(node_id))
			button.focus_entered.connect(_on_node_button_previewed.bind(node_id))
			_add_risk_badge(button, node_dict)
			add_child(button)
			node_buttons[node_id] = button

	if preview_panel != null:
		move_child(preview_panel, get_child_count() - 1)
	_layout_buttons()

func _layout_buttons() -> void:
	var layers: Array = graph.get("layers", [])
	if layers.is_empty():
		return

	_layout_preview_panel()
	var layout_rect: Rect2 = _node_layout_rect()
	var node_size: Vector2 = _node_size(layers)
	var node_gap_y: float = _node_vertical_gap(layers, node_size.y)

	for layer_index in range(layers.size()):
		var layer_nodes: Array = layers[layer_index]
		var total_height: float = float(layer_nodes.size()) * node_size.y + float(max(0, layer_nodes.size() - 1)) * node_gap_y
		var start_y: float = max(layout_rect.position.y + V_MARGIN, layout_rect.position.y + (layout_rect.size.y - total_height) * 0.5)
		for node_index in range(layer_nodes.size()):
			var node: Dictionary = layer_nodes[node_index]
			var node_id: String = str(node.get("id", ""))
			if not node_buttons.has(node_id):
				continue
			var x: float = _layer_center_x(layer_index, layers.size()) - node_size.x * 0.5
			var y: float = start_y + float(node_index) * (node_size.y + node_gap_y)
			var button: Button = node_buttons[node_id]
			button.custom_minimum_size = node_size
			button.position = Vector2(x, y)
			button.size = node_size
			button.pivot_offset = node_size * 0.5
			button.disabled = not available_node_ids.has(node_id)
			button.text = _button_text(node)
			button.icon = _type_texture(str(node.get("type", "")))
			_update_risk_badge(button, node)
			_apply_button_style(button, node)
			node_positions[node_id] = button.position

func _button_text(node: Dictionary) -> String:
	var node_id: String = str(node.get("id", ""))
	var marker := "锁定"
	if completed_node_ids.has(node_id):
		marker = "已完成"
	elif available_node_ids.has(node_id):
		marker = "可前往"
	elif node_id == current_node_id:
		marker = "当前位置"
	if node_id == previewed_node_id:
		marker = "预览中"
	return "%s\n%s" % [node.get("name", "节点"), marker]

func _tooltip_text(node: Dictionary) -> String:
	var detail := ""
	var node_type: String = str(node.get("type", ""))
	if node_type == "event":
		detail = "事件选项可能改变生命、金币、牌组或遗物。"
	elif node_type == "shop":
		detail = "购买卡牌、遗物、药水或删卡。"
	elif node_type == "campfire":
		detail = "恢复生命或升级卡牌。"
	elif node_type == "treasure":
		detail = "获得金币和一件遗物。"
	elif node_type == "elite":
		detail = "高风险战斗，通常提供遗物和更多金币。"
	elif node_type == "boss":
		detail = "章节终点战，胜利后推进章节或结局。"
	elif node_type == "combat":
		detail = "标准战斗，胜利后获得金币和卡牌奖励。"
	return "%s [%s]\n%s" % [node.get("name", "节点"), _type_label(node_type), detail]

func _add_risk_badge(button: Button, node: Dictionary) -> void:
	var badge := PanelContainer.new()
	badge.name = "RiskBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(24, 18)
	badge.clip_contents = true
	button.add_child(badge)

	var label := Label.new()
	label.name = "RiskBadgeText"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 10)
	badge.add_child(label)
	_update_risk_badge(button, node)

func _update_risk_badge(button: Button, node: Dictionary) -> void:
	var badge := button.get_node_or_null("RiskBadge") as PanelContainer
	if badge == null:
		return
	var badge_size := Vector2(24, 18)
	if button.size.x < 116.0:
		badge_size = Vector2(22, 16)
	badge.custom_minimum_size = badge_size
	badge.size = badge_size
	badge.position = Vector2(max(2.0, button.size.x - badge_size.x - 5.0), 4.0)
	badge.tooltip_text = _risk_tooltip(node)
	badge.add_theme_stylebox_override("panel", _risk_badge_style(_risk_level(node)))

	var label := badge.get_node_or_null("RiskBadgeText") as Label
	if label == null:
		return
	var risk_text: String = _risk_badge_text(_risk_level(node))
	label.text = risk_text
	label.size = badge_size
	label.add_theme_color_override("font_color", _risk_badge_font_color(_risk_level(node)))
	if not last_risk_badge_texts.has(risk_text):
		last_risk_badge_texts.append(risk_text)

func _risk_level(node: Dictionary) -> String:
	var explicit_level: String = str(node.get("risk_level", ""))
	if not explicit_level.is_empty():
		return explicit_level
	match str(node.get("type", "")):
		"boss":
			return "extreme"
		"elite":
			return "high"
		"combat":
			return "medium"
		"event":
			return "unknown"
		"shop", "campfire", "treasure":
			return "low"
		_:
			return "unknown"

func _risk_badge_text(risk_level: String) -> String:
	match risk_level:
		"low":
			return "低"
		"medium":
			return "中"
		"high":
			return "高"
		"extreme":
			return "极"
		_:
			return "?"

func _risk_tooltip(node: Dictionary) -> String:
	match _risk_level(node):
		"low":
			return "风险：低。通常是休整、商店、宝箱或低压路线。"
		"medium":
			return "风险：中。标准战斗，会消耗生命但提供金币和卡牌奖励。"
		"high":
			return "风险：高。精英节点压力更大，通常回报遗物和更多金币。"
		"extreme":
			return "风险：极高。Boss 节点会决定章节推进或最终结局。"
		_:
			return "风险：未知。事件结果取决于可选项和当前资源。"

func _risk_badge_style(risk_level: String) -> StyleBoxFlat:
	var bg := Color(0.11, 0.14, 0.14, 0.94)
	var border := Color(0.48, 0.56, 0.58, 0.95)
	match risk_level:
		"low":
			bg = Color(0.08, 0.24, 0.16, 0.96)
			border = Color(0.50, 0.90, 0.55, 0.96)
		"medium":
			bg = Color(0.20, 0.16, 0.08, 0.96)
			border = Color(0.95, 0.72, 0.30, 0.96)
		"high":
			bg = Color(0.27, 0.12, 0.07, 0.96)
			border = Color(1.0, 0.45, 0.25, 0.96)
		"extreme":
			bg = Color(0.28, 0.06, 0.12, 0.96)
			border = Color(1.0, 0.34, 0.55, 0.98)
		_:
			bg = Color(0.12, 0.16, 0.24, 0.96)
			border = Color(0.58, 0.72, 0.96, 0.96)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _risk_badge_font_color(risk_level: String) -> Color:
	match risk_level:
		"low":
			return Color(0.88, 1.0, 0.82)
		"medium":
			return Color(1.0, 0.94, 0.70)
		"high":
			return Color(1.0, 0.84, 0.72)
		"extreme":
			return Color(1.0, 0.80, 0.88)
		_:
			return Color(0.86, 0.92, 1.0)

func _type_label(node_type: String) -> String:
	match node_type:
		"combat":
			return "普通战斗"
		"elite":
			return "精英战斗"
		"boss":
			return "Boss"
		"event":
			return "事件"
		"shop":
			return "商店"
		"campfire":
			return "篝火"
		"treasure":
			return "宝箱"
		_:
			return "未知"

func _type_texture(node_type: String) -> Texture2D:
	var icon_path: String = str(TYPE_ICON_PATHS.get(node_type, TYPE_ICON_PATHS.get("event", "")))
	if icon_path.is_empty():
		return null
	if icon_cache.has(icon_path):
		return icon_cache[icon_path]
	var texture := _load_texture(icon_path)
	icon_cache[icon_path] = texture
	return texture

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded_resource = load(path)
		if loaded_resource is Texture2D:
			return loaded_resource
	if path.ends_with(".svg") and FileAccess.file_exists(path):
		var svg_text: String = FileAccess.get_file_as_string(path)
		if svg_text.is_empty():
			return null
		var image := Image.new()
		var error: Error = image.load_svg_from_string(svg_text, 1.0)
		if error != OK or image.get_width() <= 0 or image.get_height() <= 0:
			return null
		return ImageTexture.create_from_image(image)
	return null

func _type_base_color(node_type: String) -> Color:
	match node_type:
		"combat":
			return Color(0.35, 0.18, 0.16)
		"elite":
			return Color(0.40, 0.25, 0.11)
		"boss":
			return Color(0.34, 0.10, 0.18)
		"event":
			return Color(0.17, 0.23, 0.34)
		"shop":
			return Color(0.16, 0.30, 0.22)
		"campfire":
			return Color(0.35, 0.20, 0.12)
		"treasure":
			return Color(0.33, 0.27, 0.11)
		_:
			return Color(0.18, 0.20, 0.23)

func _type_border_color(node_type: String) -> Color:
	match node_type:
		"combat":
			return Color(0.84, 0.39, 0.30)
		"elite":
			return Color(0.95, 0.68, 0.22)
		"boss":
			return Color(0.98, 0.34, 0.47)
		"event":
			return Color(0.47, 0.73, 0.94)
		"shop":
			return Color(0.41, 0.82, 0.55)
		"campfire":
			return Color(0.95, 0.56, 0.25)
		"treasure":
			return Color(0.98, 0.78, 0.29)
		_:
			return Color(0.50, 0.55, 0.61)

func _apply_button_style(button: Button, node: Dictionary) -> void:
	var node_type: String = str(node.get("type", ""))
	var node_id: String = str(node.get("id", ""))
	var base := _type_base_color(node_type)
	var border := _type_border_color(node_type)
	var font_color := Color(0.93, 0.95, 0.96)
	var border_width := 1

	if completed_node_ids.has(node_id):
		base = Color(0.20, 0.18, 0.15)
		border = Color(0.95, 0.68, 0.22)
		border_width = 2
	elif node_id == previewed_node_id:
		base = base.lerp(Color(0.13, 0.32, 0.38), 0.42)
		border = Color(0.63, 0.91, 1.0)
		border_width = 3
	elif available_node_ids.has(node_id):
		base = base.lerp(Color(0.11, 0.18, 0.20), 0.22)
		border_width = 2
	elif preview_successor_ids.has(node_id):
		base = base.lerp(Color(0.12, 0.27, 0.31), 0.35)
		border = Color(0.54, 0.78, 0.86)
		border_width = 2
	else:
		base = Color(0.09, 0.10, 0.12)
		border = Color(0.24, 0.27, 0.31)
		font_color = Color(0.55, 0.59, 0.64)

	button.add_theme_stylebox_override("normal", _button_style(base, border, border_width))
	button.add_theme_stylebox_override("hover", _button_style(base.lerp(Color.WHITE, 0.10), border.lerp(Color.WHITE, 0.12), border_width + 1))
	button.add_theme_stylebox_override("pressed", _button_style(base.darkened(0.12), border, border_width + 1))
	button.add_theme_stylebox_override("disabled", _button_style(base, border, border_width))
	button.add_theme_stylebox_override("focus", _button_style(Color(0, 0, 0, 0), Color(0.63, 0.91, 1.0), 2))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.96, 0.91, 0.78))
	button.add_theme_color_override("font_disabled_color", font_color)
	button.add_theme_font_size_override("font_size", 13)

func _button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _refresh_button_styles() -> void:
	for layer in graph.get("layers", []):
		for node in layer:
			var node_dict: Dictionary = node
			var node_id: String = str(node_dict.get("id", ""))
			if not node_buttons.has(node_id):
				continue
			var button := node_buttons[node_id] as Button
			if button == null:
				continue
			button.text = _button_text(node_dict)
			_apply_button_style(button, node_dict)

func _on_node_button_pressed(node_id: String) -> void:
	if not available_node_ids.has(node_id):
		return
	emit_signal("node_selected", node_id)

func _on_node_button_previewed(node_id: String) -> void:
	if node_id.is_empty():
		return
	last_previewed_node_id = node_id
	if is_inside_tree() and node_buttons.has(node_id):
		_animate_preview_button(node_id)
	emit_signal("node_previewed", node_id)

func _animate_preview_button(node_id: String) -> void:
	var button := node_buttons.get(node_id, null) as Button
	if button == null:
		return
	button.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.035, 1.035), 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.14)

func _draw_layer_guides() -> void:
	var layers: Array = graph.get("layers", [])
	if layers.is_empty():
		return
	var layout_rect: Rect2 = _node_layout_rect()
	for layer_index in range(layers.size()):
		var center_x := _layer_center_x(layer_index, layers.size())
		draw_line(Vector2(center_x, layout_rect.position.y + 18.0), Vector2(center_x, max(layout_rect.position.y + 18.0, layout_rect.end.y - 18.0)), Color(0.18, 0.22, 0.27, 0.35), 1.0, true)

func _layer_center_x(layer_index: int, layer_count: int) -> float:
	var layout_rect: Rect2 = _node_layout_rect()
	var node_size: Vector2 = _node_size()
	if layer_count <= 1:
		return layout_rect.get_center().x
	var first_center: float = layout_rect.position.x + H_MARGIN * 0.25 + node_size.x * 0.5
	var last_center: float = max(first_center, layout_rect.end.x - H_MARGIN * 0.25 - node_size.x * 0.5)
	var layer_gap: float = (last_center - first_center) / float(layer_count - 1)
	return first_center + float(layer_index) * layer_gap

func _node_size(layers_override: Array = []) -> Vector2:
	var layers: Array = layers_override
	if layers.is_empty():
		layers = graph.get("layers", [])
	var max_nodes_in_layer := 1
	for layer in layers:
		var layer_nodes: Array = layer
		max_nodes_in_layer = max(max_nodes_in_layer, layer_nodes.size())
	if size.y <= 1.0:
		return NODE_SIZE
	var available_height: float = max(MIN_NODE_SIZE.y, size.y - V_MARGIN * 2.0)
	var gap_total: float = float(max(0, max_nodes_in_layer - 1)) * 10.0
	var height: float = floor((available_height - gap_total) / float(max_nodes_in_layer))
	height = clamp(height, MIN_NODE_SIZE.y, NODE_SIZE.y)
	var width: float = clamp(round(height * 2.28), MIN_NODE_SIZE.x, NODE_SIZE.x)
	if layers.size() > 1:
		var layout_width: float = _node_layout_rect().size.x
		var horizontal_width: float = floor((layout_width - H_MARGIN * 0.5) / float(layers.size()) - 8.0)
		width = clamp(min(width, horizontal_width), MIN_NODE_SIZE.x, NODE_SIZE.x)
	return Vector2(width, height)

func _node_vertical_gap(layers: Array, node_height: float) -> float:
	var max_nodes_in_layer := 1
	for layer in layers:
		var layer_nodes: Array = layer
		max_nodes_in_layer = max(max_nodes_in_layer, layer_nodes.size())
	if max_nodes_in_layer <= 1:
		return 16.0
	var remaining_height: float = _node_layout_rect().size.y - V_MARGIN * 2.0 - float(max_nodes_in_layer) * node_height
	return clamp(floor(remaining_height / float(max_nodes_in_layer - 1)), 8.0, 16.0)

func _edge_is_previewed(from_id: String, to_id: String) -> bool:
	if previewed_node_id.is_empty():
		return false
	if from_id == previewed_node_id and preview_successor_ids.has(to_id):
		return true
	if to_id == previewed_node_id and (completed_node_ids.has(from_id) or from_id == current_node_id):
		return true
	return false

func _node_by_id(node_id: String) -> Dictionary:
	for layer in graph.get("layers", []):
		for node in layer:
			var node_dict: Dictionary = node
			if str(node_dict.get("id", "")) == node_id:
				return node_dict
	return {}
