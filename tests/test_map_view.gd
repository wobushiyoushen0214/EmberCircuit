extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const MapViewScript = preload("res://scripts/map/MapView.gd")

var failure_count: int = 0

func _init() -> void:
	var map_config: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var generated: Dictionary = MapGeneratorScript.generate(map_config.get("chapter_one", {}))
	var layers: Array = generated.get("layers", [])
	var start_id: String = str(generated.get("start_node_id", ""))
	var available: Array[String] = [start_id]
	var completed := {}

	var view = MapViewScript.new()
	view.size = Vector2(1280, 468)
	root.add_child(view)
	view.set_map_state(generated, available, completed, "")
	_check(view.get_node_button_count() == _node_count(layers), "map view creates one button per node")
	_check(view.get_available_button_count() == 1, "map view tracks available buttons")
	_check(view.get_icon_button_count() == view.get_node_button_count(), "map view assigns an icon to every node button")
	_check(view.get_risk_badge_count() == view.get_node_button_count(), "map view assigns a risk badge to every node")
	var risk_badge_texts: Array[String] = view.get_risk_badge_texts()
	_check(risk_badge_texts.has("中") and risk_badge_texts.has("高") and risk_badge_texts.has("极") and risk_badge_texts.has("?") and risk_badge_texts.has("低"), "map view risk badges cover route risk levels")
	var start_button := view.node_buttons.get(start_id, null) as Button
	_check(start_button != null and start_button.tooltip_text.contains("普通战斗") and not start_button.tooltip_text.contains("[combat]"), "map node tooltip uses localized type labels")
	_check(start_button != null and start_button.has_node("RiskBadge"), "map node button contains a risk badge child")

	var selected: Array[String] = []
	view.node_selected.connect(func(node_id: String) -> void:
		selected.append(node_id)
	)
	var previewed: Array[String] = []
	view.node_previewed.connect(func(node_id: String) -> void:
		previewed.append(node_id)
	)
	view._on_node_button_previewed(start_id)
	_check(previewed.size() == 1 and previewed[0] == start_id, "map node preview emits signal")
	_check(view.last_previewed_node_id == start_id, "map view records last previewed node")
	var successor_ids: Array[String] = _successor_ids(generated, start_id)
	view.set_preview_node(start_id, successor_ids)
	_check(view.previewed_node_id == start_id, "map view stores active preview node")
	_check(view.get_previewed_successor_count() == successor_ids.size(), "map view stores active preview successors")
	view._on_node_button_pressed(start_id)
	_check(selected.size() == 1 and selected[0] == start_id, "available map node emits selection")

	var unavailable_id: String = _first_unavailable_node_id(layers, start_id)
	view._on_node_button_pressed(unavailable_id)
	_check(selected.size() == 1, "unavailable map node does not emit selection")

	_check(view.has_method("set_preview_details"), "map view exposes a complete preview details API")
	_check(view.has_method("set_preview_title"), "map view exposes a preview title API")
	_check(view.has_method("set_preview_risk"), "map view exposes a preview risk API")
	_check(view.has_method("set_preview_reward"), "map view exposes a preview reward API")
	_check(view.has_method("set_preview_description"), "map view exposes a preview description API")
	_check(view.has_method("set_preview_successors"), "map view exposes a preview successors API")
	if view.has_method("set_preview_details"):
		var preview_successors: Array[String] = ["余烬商店 [商店]", "旧锅炉房 [普通战斗]"]
		view.set_preview_details(
			"熔炉守卫 [精英战斗]",
			"高：敌人会快速叠加灼烧。",
			"遗物、80-100 金币与卡牌奖励。",
			"这是一段需要换行的节点说明，用来验证固定高度的详情面板不会被文本内容撑高。",
			preview_successors
		)

	var preview_panel := view.get_node_or_null("NodePreviewPanel") as PanelContainer
	_check(preview_panel != null, "map view owns a node preview panel")
	if preview_panel != null:
		_check(preview_panel.size == Vector2(300, 420), "PC node preview panel has a fixed size")
		_check(preview_panel.custom_minimum_size == Vector2(300, 420), "PC node preview panel minimum size matches its fixed size")
		_check(Rect2(Vector2.ZERO, view.size).encloses(preview_panel.get_rect()), "node preview panel fits inside the 1280x468 map region")
		_check(not _contains_control_type(preview_panel, "ScrollContainer"), "node preview panel has no scroll container")
		_check(not _contains_control_type(preview_panel, "RichTextLabel"), "node preview panel has no rich text label")

		var title_label := preview_panel.find_child("PreviewTitle", true, false) as Label
		var risk_label := preview_panel.find_child("PreviewRisk", true, false) as Label
		var reward_label := preview_panel.find_child("PreviewReward", true, false) as Label
		var description_label := preview_panel.find_child("PreviewDescription", true, false) as Label
		var successors_label := preview_panel.find_child("PreviewSuccessors", true, false) as Label
		_check(title_label != null and title_label.text == "熔炉守卫 [精英战斗]", "preview API sets the node title")
		_check(risk_label != null and risk_label.text.contains("高：敌人会快速叠加灼烧。"), "preview API sets the node risk")
		_check(reward_label != null and reward_label.text.contains("遗物、80-100 金币与卡牌奖励。"), "preview API sets the node reward")
		_check(description_label != null and description_label.text.contains("固定高度"), "preview API sets the node description")
		_check(successors_label != null and successors_label.text.contains("余烬商店") and successors_label.text.contains("旧锅炉房"), "preview API sets successor nodes")
		_check(_preview_labels_are_bounded(preview_panel), "preview labels wrap or clip inside fixed bounds")

		var panel_size_before_long_text: Vector2 = preview_panel.size
		var description_size_before_long_text: Vector2 = description_label.size if description_label != null else Vector2.ZERO
		if view.has_method("set_preview_description"):
			view.set_preview_description("超长说明。".repeat(200))
		_check(preview_panel.size == panel_size_before_long_text, "long preview text cannot grow the panel")
		_check(description_label != null and description_label.size == description_size_before_long_text, "long preview text cannot grow its label")

		for button_value in view.node_buttons.values():
			var node_button := button_value as Button
			_check(node_button != null and not node_button.get_rect().intersects(preview_panel.get_rect(), true), "map node layout avoids the preview panel")

		var preview_panel_id: int = preview_panel.get_instance_id()
		view.set_map_state(generated, available, completed, "")
		var rebuilt_preview_panel := view.get_node_or_null("NodePreviewPanel") as PanelContainer
		_check(rebuilt_preview_panel != null and rebuilt_preview_panel.get_instance_id() == preview_panel_id, "map rebuild preserves the preview panel")

	var dense_graph := _ten_layer_graph()
	view.set_map_state(dense_graph, ["dense_0"], {}, "")
	_check(_node_buttons_do_not_overlap(view), "ten-layer PC map keeps every route node separated beside the fixed preview panel")

	view.free()
	if failure_count > 0:
		push_error("Map view smoke test failed with %d assertion(s)." % failure_count)
		quit(1)
		return
	print("Map view smoke test passed.")
	quit(0)

func _node_count(layers: Array) -> int:
	var count := 0
	for layer in layers:
		count += (layer as Array).size()
	return count

func _first_unavailable_node_id(layers: Array, start_id: String) -> String:
	for layer in layers:
		for node in (layer as Array):
			var node_dict: Dictionary = node
			var node_id: String = str(node_dict.get("id", ""))
			if node_id != start_id:
				return node_id
	return ""

func _successor_ids(graph: Dictionary, node_id: String) -> Array[String]:
	var result: Array[String] = []
	for edge in graph.get("edges", []):
		var edge_dict: Dictionary = edge
		if str(edge_dict.get("from", "")) == node_id:
			result.append(str(edge_dict.get("to", "")))
	return result

func _ten_layer_graph() -> Dictionary:
	var layers: Array = []
	var edges: Array = []
	for layer_index in range(10):
		var node_id := "dense_%d" % layer_index
		layers.append([{
			"id": node_id,
			"name": "节点%d" % (layer_index + 1),
			"type": "boss" if layer_index == 9 else "combat",
			"risk": "medium"
		}])
		if layer_index > 0:
			edges.append({"from": "dense_%d" % (layer_index - 1), "to": node_id})
	return {"layers": layers, "edges": edges}

func _node_buttons_do_not_overlap(view) -> bool:
	var buttons: Array = view.node_buttons.values()
	for first_index in range(buttons.size()):
		var first := buttons[first_index] as Button
		if first == null:
			return false
		for second_index in range(first_index + 1, buttons.size()):
			var second := buttons[second_index] as Button
			if second == null or first.get_rect().intersects(second.get_rect(), true):
				return false
	return true

func _contains_control_type(root: Node, type_name: String) -> bool:
	if root.is_class(type_name):
		return true
	for child in root.get_children():
		if _contains_control_type(child, type_name):
			return true
	return false

func _preview_labels_are_bounded(panel: PanelContainer) -> bool:
	for child_name in ["PreviewTitle", "PreviewRisk", "PreviewReward", "PreviewDescription", "PreviewSuccessors"]:
		var label := panel.find_child(child_name, true, false) as Label
		if label == null or not label.clip_text:
			return false
		if label.get_rect().end.x > panel.size.x or label.get_rect().end.y > panel.size.y:
			return false
	var description_label := panel.find_child("PreviewDescription", true, false) as Label
	var successors_label := panel.find_child("PreviewSuccessors", true, false) as Label
	return (
		description_label.autowrap_mode != TextServer.AUTOWRAP_OFF
		and successors_label.autowrap_mode != TextServer.AUTOWRAP_OFF
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failure_count += 1
		push_error("Test failed: %s" % message)
