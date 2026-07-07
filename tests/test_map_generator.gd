extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")

func _init() -> void:
	var map_config: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var chapter_config: Dictionary = map_config.get("chapter_one", {})
	var generated: Dictionary = MapGeneratorScript.generate(chapter_config)
	var layers: Array = generated.get("layers", [])
	var edges: Array = generated.get("edges", [])

	_check(layers.size() == int(chapter_config.get("layers", 0)), "map has configured layer count")
	_check(not edges.is_empty(), "map has edges")
	_check(str(layers[0][0].get("type", "")) == "combat", "first layer starts with combat")
	_check(str(layers[layers.size() - 1][0].get("type", "")) == "boss", "last layer has boss")
	_check(_has_path_to_boss(generated), "generated map has path from start to boss")

	print("Map generator smoke test passed.")
	quit(0)

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

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
