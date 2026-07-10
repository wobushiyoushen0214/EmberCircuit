extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")

func _init() -> void:
	var map_config: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var level_tree: Dictionary = DataLoaderScript.load_json("res://data/config/level_tree.json")
	for chapter_id in map_config.get("chapter_sequence", ["chapter_one"]):
		var chapter_config: Dictionary = map_config.get(str(chapter_id), {}).duplicate(true)
		chapter_config["level_tree_constraints"] = level_tree.get("chapters", {}).get(str(chapter_id), {}).duplicate(true)
		chapter_config["route_constraints"] = level_tree.get("route_constraints", {}).duplicate(true)
		_validate_generated_chapter(chapter_config, str(chapter_id))
	var guaranteed_graph: Dictionary = MapGeneratorScript.generate({
		"seed": 11,
		"layers": 3,
		"min_nodes_per_layer": 1,
		"max_nodes_per_layer": 1,
		"fixed_layers": {"0": ["combat"], "1": ["event"], "2": ["boss"]},
		"event_pool": ["ordinary_event", "chain_follow_up"],
		"guaranteed_event_ids": ["chain_follow_up"],
		"encounter_by_type": {"combat": ["intro_patrol"], "boss": ["chapter_one_boss"]}
	})
	_check(_has_event_id(guaranteed_graph.get("layers", []), "chain_follow_up"), "map generator places an available guaranteed chain event")

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
	_check(_has_node_type(layers, "treasure"), "%s generated map includes a treasure node" % chapter_id)
	_check(_has_path_to_boss(generated), "%s generated map has path from start to boss" % chapter_id)
	_check(_event_ids_are_unique(layers), "%s generated map avoids duplicate event ids while pool is available" % chapter_id)
	_validate_tree_constraints(generated, chapter_config, chapter_id)

func _validate_tree_constraints(generated: Dictionary, chapter_config: Dictionary, chapter_id: String) -> void:
	var layers: Array = generated.get("layers", [])
	var chapter_constraints: Dictionary = chapter_config.get("level_tree_constraints", {})
	var route_constraints: Dictionary = chapter_config.get("route_constraints", {})
	var branching_layers: int = 0
	var minimum_choices: int = int(route_constraints.get("minimum_choices_on_branch_layer", 2))
	for layer in layers:
		if (layer as Array).size() >= minimum_choices:
			branching_layers += 1
	_check(branching_layers >= int(route_constraints.get("minimum_branching_layers", 0)), "%s map satisfies minimum branching layers" % chapter_id)

	var early_elite_count: int = 0
	var early_latest: int = min(int(chapter_constraints.get("early_elite_latest_layer", 3)), layers.size() - 2)
	for layer_index in range(1, early_latest + 1):
		var elites_in_layer: int = 0
		for node_value in layers[layer_index]:
			if str((node_value as Dictionary).get("type", "")) == "elite":
				elites_in_layer += 1
		early_elite_count += elites_in_layer
		_check(elites_in_layer <= 1, "%s early layer has at most one elite" % chapter_id)
	_check(early_elite_count <= int(chapter_constraints.get("early_elite_max_count", 1)), "%s map satisfies early elite cap" % chapter_id)

	var safe_window: int = int(chapter_constraints.get("boss_safe_window_layers", 2))
	var recovery_found: bool = false
	for layer_index in range(max(1, layers.size() - 1 - safe_window), layers.size() - 1):
		for node_value in layers[layer_index]:
			if str((node_value as Dictionary).get("type", "")) in ["campfire", "shop"]:
				recovery_found = true
	_check(recovery_found, "%s map has recovery candidate before boss" % chapter_id)
	_check(_treasures_have_non_elite_exit(generated), "%s treasure nodes are not forced into elites" % chapter_id)

func _treasures_have_non_elite_exit(generated: Dictionary) -> bool:
	var node_by_id: Dictionary = {}
	for layer in generated.get("layers", []):
		for node_value in layer:
			var node: Dictionary = node_value
			node_by_id[str(node.get("id", ""))] = node
	for layer in generated.get("layers", []):
		for node_value in layer:
			var node: Dictionary = node_value
			if str(node.get("type", "")) != "treasure":
				continue
			var safe_exit: bool = false
			for edge_value in generated.get("edges", []):
				var edge: Dictionary = edge_value
				if str(edge.get("from", "")) != str(node.get("id", "")):
					continue
				if str(node_by_id.get(str(edge.get("to", "")), {}).get("type", "")) != "elite":
					safe_exit = true
			if not safe_exit:
				return false
	return true

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

func _has_node_type(layers: Array, node_type: String) -> bool:
	for layer in layers:
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			if str(node_dict.get("type", "")) == node_type:
				return true
	return false

func _has_event_id(layers: Array, event_id: String) -> bool:
	for layer in layers:
		var layer_nodes: Array = layer
		for node in layer_nodes:
			var node_dict: Dictionary = node
			if str(node_dict.get("type", "")) == "event" and str(node_dict.get("event_id", "")) == event_id:
				return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
