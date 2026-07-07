extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const MapViewScript = preload("res://scripts/map/MapView.gd")

func _init() -> void:
	var map_config: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var generated: Dictionary = MapGeneratorScript.generate(map_config.get("chapter_one", {}))
	var layers: Array = generated.get("layers", [])
	var start_id: String = str(generated.get("start_node_id", ""))
	var available: Array[String] = [start_id]
	var completed := {}

	var view = MapViewScript.new()
	view.size = Vector2(1000, 360)
	view.set_map_state(generated, available, completed, "")
	_check(view.get_node_button_count() == _node_count(layers), "map view creates one button per node")
	_check(view.get_available_button_count() == 1, "map view tracks available buttons")

	var selected: Array[String] = []
	view.node_selected.connect(func(node_id: String) -> void:
		selected.append(node_id)
	)
	view._on_node_button_pressed(start_id)
	_check(selected.size() == 1 and selected[0] == start_id, "available map node emits selection")

	var unavailable_id: String = _first_unavailable_node_id(layers, start_id)
	view._on_node_button_pressed(unavailable_id)
	_check(selected.size() == 1, "unavailable map node does not emit selection")

	view.free()
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

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
