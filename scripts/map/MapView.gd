class_name EmberMapView
extends Control

signal node_selected(node_id: String)
signal node_previewed(node_id: String)

const NODE_SIZE := Vector2(132, 58)
const MIN_NODE_SIZE := Vector2(96, 44)
const H_MARGIN := 44.0
const V_MARGIN := 24.0
const TYPE_ICON_PATHS := {
	"combat": "res://assets/art/map_node_combat.svg",
	"elite": "res://assets/art/map_node_elite.svg",
	"boss": "res://assets/art/map_node_boss.svg",
	"event": "res://assets/art/map_node_event.svg",
	"shop": "res://assets/art/map_node_shop.svg",
	"campfire": "res://assets/art/map_node_campfire.svg"
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

func _ready() -> void:
	custom_minimum_size = Vector2(0, 330)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_map_state(new_graph: Dictionary, new_available_ids: Array[String], new_completed_ids: Dictionary, new_current_node_id: String = "") -> void:
	graph = new_graph.duplicate(true)
	available_node_ids = new_available_ids.duplicate()
	completed_node_ids = new_completed_ids.duplicate(true)
	current_node_id = new_current_node_id
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

func get_previewed_successor_count() -> int:
	return preview_successor_ids.size()

func set_preview_node(node_id: String, successor_ids: Array[String] = []) -> void:
	previewed_node_id = node_id
	preview_successor_ids = successor_ids.duplicate()
	_refresh_button_styles()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not graph.is_empty():
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

func _rebuild_buttons() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	node_buttons.clear()
	node_positions.clear()

	for layer in graph.get("layers", []):
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			var node_id: String = str(node_dict.get("id", ""))
			if node_id.is_empty():
				continue
			var button := Button.new()
			button.custom_minimum_size = NODE_SIZE
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
			add_child(button)
			node_buttons[node_id] = button

	_layout_buttons()

func _layout_buttons() -> void:
	var layers: Array = graph.get("layers", [])
	if layers.is_empty():
		return

	var node_size: Vector2 = _node_size(layers)
	var node_gap_y: float = _node_vertical_gap(layers, node_size.y)
	var usable_width: float = max(size.x - H_MARGIN * 2.0, node_size.x)
	var layer_gap: float = 0.0
	if layers.size() > 1:
		layer_gap = usable_width / float(layers.size() - 1)

	for layer_index in range(layers.size()):
		var layer_nodes: Array = layers[layer_index]
		var total_height: float = float(layer_nodes.size()) * node_size.y + float(max(0, layer_nodes.size() - 1)) * node_gap_y
		var start_y: float = max(V_MARGIN, (size.y - total_height) * 0.5)
		for node_index in range(layer_nodes.size()):
			var node: Dictionary = layer_nodes[node_index]
			var node_id: String = str(node.get("id", ""))
			if not node_buttons.has(node_id):
				continue
			var x: float = H_MARGIN + float(layer_index) * layer_gap - node_size.x * 0.5
			if layers.size() == 1:
				x = (size.x - node_size.x) * 0.5
			x = clamp(x, H_MARGIN * 0.25, max(H_MARGIN * 0.25, size.x - node_size.x - H_MARGIN * 0.25))
			var y: float = start_y + float(node_index) * (node_size.y + node_gap_y)
			var button: Button = node_buttons[node_id]
			button.custom_minimum_size = node_size
			button.position = Vector2(x, y)
			button.size = node_size
			button.pivot_offset = node_size * 0.5
			button.disabled = not available_node_ids.has(node_id)
			button.text = _button_text(node)
			button.icon = _type_texture(str(node.get("type", "")))
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
		detail = str(node.get("event_id", ""))
	elif node_type == "shop":
		detail = "购买卡牌、药水或删卡"
	elif node_type == "campfire":
		detail = "恢复生命或升级卡牌"
	elif node.has("encounter_id"):
		detail = str(node.get("encounter_id", ""))
	return "%s [%s]\n%s" % [node.get("name", "节点"), node_type, detail]

func _type_texture(node_type: String) -> Texture2D:
	var icon_path: String = str(TYPE_ICON_PATHS.get(node_type, TYPE_ICON_PATHS.get("event", "")))
	if icon_path.is_empty():
		return null
	if icon_cache.has(icon_path):
		return icon_cache[icon_path]
	var texture := load(icon_path) as Texture2D
	icon_cache[icon_path] = texture
	return texture

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
	for layer_index in range(layers.size()):
		var center_x := _layer_center_x(layer_index, layers.size())
		draw_line(Vector2(center_x, 18.0), Vector2(center_x, max(18.0, size.y - 18.0)), Color(0.18, 0.22, 0.27, 0.35), 1.0, true)

func _layer_center_x(layer_index: int, layer_count: int) -> float:
	var node_size: Vector2 = _node_size()
	if layer_count <= 1:
		return size.x * 0.5
	var usable_width: float = max(size.x - H_MARGIN * 2.0, node_size.x)
	var layer_gap: float = usable_width / float(layer_count - 1)
	return clamp(H_MARGIN + float(layer_index) * layer_gap, H_MARGIN * 0.25 + node_size.x * 0.5, max(H_MARGIN * 0.25 + node_size.x * 0.5, size.x - H_MARGIN * 0.25 - node_size.x * 0.5))

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
	return Vector2(width, height)

func _node_vertical_gap(layers: Array, node_height: float) -> float:
	var max_nodes_in_layer := 1
	for layer in layers:
		var layer_nodes: Array = layer
		max_nodes_in_layer = max(max_nodes_in_layer, layer_nodes.size())
	if max_nodes_in_layer <= 1:
		return 16.0
	var remaining_height: float = size.y - V_MARGIN * 2.0 - float(max_nodes_in_layer) * node_height
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
