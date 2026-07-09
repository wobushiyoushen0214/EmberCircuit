extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")

func _init() -> void:
	var map_config: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	for chapter_id in map_config.get("chapter_sequence", ["chapter_one"]):
		var chapter_config: Dictionary = map_config.get(str(chapter_id), {})
		_validate_generated_chapter(chapter_config, str(chapter_id))

	print("Map generator smoke test passed.")
	quit(0)

func _validate_generated_chapter(chapter_config: Dictionary, chapter_id: String) -> void:
	var generated: Dictionary = MapGeneratorScript.generate(chapter_config)
	var layers: Array = generated.get("layers", [])
	var edges: Array = generated.get("edges", [])

	_check(layers.size() == int(chapter_config.get("layers", 0)), "%s map has configured layer count" % chapter_id)
	_check(not edges.is_empty(), "%s map has edges" % chapter_id)
	_check(str(layers[0][0].get("type", "")) == "combat", "%s first layer starts with combat" % chapter_id)
	_check(str(layers[layers.size() - 1][0].get("type", "")) == "boss", "%s last layer has boss" % chapter_id)
	_check(_has_path_to_boss(generated), "%s generated map has path from start to boss" % chapter_id)
	_check(_event_ids_are_unique(layers), "%s generated map avoids duplicate event ids while pool is available" % chapter_id)

func _has_path_to_boss(generated: Dictionary) -> bool:
	var start_id: String = str(generated.get("start_node_id", ""))
	var boss_id: String = str(generated.get("boss_node_id", ""))
	var edges: Array = generated.get("edges", [])
	var frontier: Array[String] = [start_id]
	var visited: Dictionary = {}

	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		if current == boss_id:
			return true
		if visited.has(current):
			continue
		visited[current] = true
		for edge in edges:
			var edge_dict: Dictionary = edge
			if str(edge_dict.get("from", "")) == current:
				frontier.append(str(edge_dict.get("to", "")))
	return false

func _event_ids_are_unique(layers: Array) -> bool:
	var seen: Dictionary = {}
	for layer in layers:
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			if str(node_dict.get("type", "")) != "event":
				continue
			var event_id: String = str(node_dict.get("event_id", ""))
			if seen.has(event_id):
				return false
			seen[event_id] = true
	return true

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
