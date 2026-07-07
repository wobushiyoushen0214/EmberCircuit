class_name EmberMapView
extends Control

signal node_selected(node_id: String)

const NODE_SIZE := Vector2(132, 58)
const H_MARGIN := 44.0
const V_MARGIN := 24.0

var graph: Dictionary = {}
var available_node_ids: Array[String] = []
var completed_node_ids: Dictionary = {}
var current_node_id: String = ""
var node_positions: Dictionary = {}
var node_buttons: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 330)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_map_state(new_graph: Dictionary, new_available_ids: Array[String], new_completed_ids: Dictionary, new_current_node_id: String = "") -> void:
	graph = new_graph.duplicate(true)
	available_node_ids = new_available_ids.duplicate()
	completed_node_ids = new_completed_ids.duplicate(true)
	current_node_id = new_current_node_id
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not graph.is_empty():
		_layout_buttons()
		queue_redraw()

func _draw() -> void:
	if graph.is_empty() or node_positions.is_empty():
		return

	for edge in graph.get("edges", []):
		var edge_dict: Dictionary = edge
		var from_id: String = str(edge_dict.get("from", ""))
		var to_id: String = str(edge_dict.get("to", ""))
		if not node_positions.has(from_id) or not node_positions.has(to_id):
			continue
		var from_pos: Vector2 = node_positions[from_id] + NODE_SIZE * 0.5
		var to_pos: Vector2 = node_positions[to_id] + NODE_SIZE * 0.5
		var color := Color(0.33, 0.39, 0.46, 0.7)
		var width := 2.0
		if completed_node_ids.has(from_id) and (completed_node_ids.has(to_id) or available_node_ids.has(to_id)):
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
			button.tooltip_text = _tooltip_text(node_dict)
			button.disabled = not available_node_ids.has(node_id)
			button.pressed.connect(_on_node_button_pressed.bind(node_id))
			add_child(button)
			node_buttons[node_id] = button

	_layout_buttons()

func _layout_buttons() -> void:
	var layers: Array = graph.get("layers", [])
	if layers.is_empty():
		return

	var usable_width: float = max(size.x - H_MARGIN * 2.0, NODE_SIZE.x)
	var layer_gap: float = 0.0
	if layers.size() > 1:
		layer_gap = usable_width / float(layers.size() - 1)

	for layer_index in range(layers.size()):
		var layer_nodes: Array = layers[layer_index]
		var total_height: float = float(layer_nodes.size()) * NODE_SIZE.y + float(max(0, layer_nodes.size() - 1)) * 16.0
		var start_y: float = max(V_MARGIN, (size.y - total_height) * 0.5)
		for node_index in range(layer_nodes.size()):
			var node: Dictionary = layer_nodes[node_index]
			var node_id: String = str(node.get("id", ""))
			if not node_buttons.has(node_id):
				continue
			var x: float = H_MARGIN + float(layer_index) * layer_gap - NODE_SIZE.x * 0.5
			if layers.size() == 1:
				x = (size.x - NODE_SIZE.x) * 0.5
			x = clamp(x, H_MARGIN * 0.25, max(H_MARGIN * 0.25, size.x - NODE_SIZE.x - H_MARGIN * 0.25))
			var y: float = start_y + float(node_index) * (NODE_SIZE.y + 16.0)
			var button: Button = node_buttons[node_id]
			button.position = Vector2(x, y)
			button.size = NODE_SIZE
			button.disabled = not available_node_ids.has(node_id)
			button.text = _button_text(node)
			node_positions[node_id] = button.position

func _button_text(node: Dictionary) -> String:
	var node_id: String = str(node.get("id", ""))
	var marker := " "
	if completed_node_ids.has(node_id):
		marker = "x"
	elif available_node_ids.has(node_id):
		marker = ">"
	elif node_id == current_node_id:
		marker = "*"
	return "%s %s\n%s" % [marker, _type_icon(str(node.get("type", ""))), node.get("name", "节点")]

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

func _type_icon(node_type: String) -> String:
	match node_type:
		"combat":
			return "剑"
		"elite":
			return "冠"
		"boss":
			return "王"
		"event":
			return "?"
		"shop":
			return "店"
		"campfire":
			return "火"
		_:
			return "点"

func _on_node_button_pressed(node_id: String) -> void:
	if not available_node_ids.has(node_id):
		return
	emit_signal("node_selected", node_id)
