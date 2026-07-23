extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const MAP_SEED_SAMPLE_COUNT := 24

var _failure_count: int = 0

func _init() -> void:
	_test_layer_encounter_bands()
	var map_config: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var level_tree: Dictionary = DataLoaderScript.load_json("res://data/config/level_tree.json")
	for chapter_id in map_config.get("chapter_sequence", ["chapter_one"]):
		var chapter_config: Dictionary = map_config.get(str(chapter_id), {}).duplicate(true)
		chapter_config["level_tree_constraints"] = level_tree.get("chapters", {}).get(str(chapter_id), {}).duplicate(true)
		chapter_config["route_constraints"] = level_tree.get("route_constraints", {}).duplicate(true)
		_validate_generated_chapter_seeds(chapter_config, str(chapter_id))
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

	if _failure_count > 0:
		print("Map generator test failed with %d assertion(s)." % _failure_count)
		quit(1)
		return
	print("Map generator smoke test passed.")
	quit(0)

func _test_layer_encounter_bands() -> void:
	var legacy_config := _layer_band_fixture()
	var band_config: Dictionary = legacy_config.duplicate(true)
	band_config["encounter_layer_bands"] = {
		"combat": [
			{"layers": [0, 0], "encounter_ids": ["intro_patrol"]},
			{"layers": [1, 2], "encounter_ids": ["polluted_lab", "cinder_kennels"]},
			{"layers": [3, 6], "encounter_ids": ["iron_checkpoint", "cinder_kennels"]}
		]
	}
	var generated: Dictionary = MapGeneratorScript.generate(band_config)
	var layers: Array = generated.get("layers", [])
	_check(str(layers[0][0].get("encounter_id", "")) == "intro_patrol", "AC-023-06 L0 combat uses intro_patrol only")
	var json_like_band_config: Dictionary = band_config.duplicate(true)
	var json_like_bands: Array = json_like_band_config["encounter_layer_bands"]["combat"]
	for band_value in json_like_bands:
		var band: Dictionary = band_value
		var integer_layers: Array = band.get("layers", [])
		band["layers"] = [float(integer_layers[0]), float(integer_layers[1])]
	var json_like_generated: Dictionary = MapGeneratorScript.generate(json_like_band_config)
	_check(str((json_like_generated.get("layers", [])[0][0] as Dictionary).get("encounter_id", "")) == "intro_patrol", "AC-023-06 JSON-like integer floats still use layer bands")
	for layer_index in [1, 2]:
		var encounter_id := str(layers[layer_index][0].get("encounter_id", ""))
		_check(encounter_id in ["polluted_lab", "cinder_kennels"], "AC-023-06 L%d combat uses the L1-L2 pool" % layer_index)
	for layer_index in [3, 4, 5, 6]:
		var encounter_id := str(layers[layer_index][0].get("encounter_id", ""))
		_check(encounter_id in ["iron_checkpoint", "cinder_kennels"], "AC-023-06 L%d combat uses the L3-L6 pool" % layer_index)
	_check(str(layers[7][0].get("encounter_id", "")) == "legacy_boss", "AC-023-06 boss ignores combat layer bands")

	var elite_config: Dictionary = band_config.duplicate(true)
	# The fixture's final layer remains a boss; add an elite node without changing the layer layout.
	elite_config["fixed_layers"] = {
		"0": ["combat"], "1": ["combat"], "2": ["combat"], "3": ["combat"],
		"4": ["elite"], "5": ["combat"], "6": ["combat"], "7": ["boss"]
	}
	var elite_generated: Dictionary = MapGeneratorScript.generate(elite_config)
	_check(str((elite_generated.get("layers", [])[4][0] as Dictionary).get("encounter_id", "")) == "legacy_elite", "AC-023-06 elite ignores combat layer bands")

	for malformed_value in [
		{"combat": "malformed"},
		{"combat": []},
		{"combat": [{"layers": [9, 10], "encounter_ids": ["unused"]}]}]:
		var fallback_config: Dictionary = legacy_config.duplicate(true)
		fallback_config["encounter_layer_bands"] = malformed_value
		var fallback_generated: Dictionary = MapGeneratorScript.generate(fallback_config)
		var expected_generated: Dictionary = MapGeneratorScript.generate(legacy_config)
		_check(fallback_generated == expected_generated, "AC-023-06 malformed or non-matching band falls back without graph drift")

func _layer_band_fixture() -> Dictionary:
	return {
		"seed": 2306,
		"layers": 8,
		"min_nodes_per_layer": 1,
		"max_nodes_per_layer": 1,
		"fixed_layers": {
			"0": ["combat"], "1": ["combat"], "2": ["combat"], "3": ["combat"],
			"4": ["combat"], "5": ["combat"], "6": ["combat"], "7": ["boss"]
		},
		"encounter_by_type": {
			"combat": ["legacy_a", "legacy_b"],
			"elite": ["legacy_elite"],
			"boss": ["legacy_boss"]
		}
	}

func _validate_generated_chapter_seeds(chapter_config: Dictionary, chapter_id: String) -> void:
	var base_seed: int = int(chapter_config.get("seed", 1))
	for sample_index in range(MAP_SEED_SAMPLE_COUNT):
		var seeded_config: Dictionary = chapter_config.duplicate(true)
		var seed_value: int = base_seed + sample_index * 7919
		seeded_config["seed"] = seed_value
		var generated: Dictionary = MapGeneratorScript.generate(seeded_config)
		var repeated: Dictionary = MapGeneratorScript.generate(seeded_config)
		_check(generated == repeated, "%s seed %d is deterministic" % [chapter_id, seed_value])
		_validate_generated_chapter(generated, seeded_config, chapter_id, seed_value)

func _validate_generated_chapter(generated: Dictionary, chapter_config: Dictionary, chapter_id: String, seed_value: int) -> void:
	var layers: Array = generated.get("layers", [])
	var edges: Array = generated.get("edges", [])

	_check(layers.size() == int(chapter_config.get("layers", 0)), "%s map has configured layer count" % chapter_id)
	_check(not edges.is_empty(), "%s map has edges" % chapter_id)
	_check(str(layers[0][0].get("type", "")) == "combat", "%s first layer starts with combat" % chapter_id)
	_check(str(layers[layers.size() - 1][0].get("type", "")) == "boss", "%s last layer has boss" % chapter_id)
	var node_budget: Dictionary = chapter_config.get("level_tree_constraints", {}).get("node_budget", {})
	if int(node_budget.get("treasure", [0, 0])[0]) > 0:
		_check(_has_node_type(layers, "treasure"), "%s generated map includes a required treasure node" % chapter_id)
	_check(_has_path_to_boss(generated), "%s generated map has path from start to boss" % chapter_id)
	_check(_event_ids_are_unique(layers), "%s generated map avoids duplicate event ids while pool is available" % chapter_id)
	_check(_mixed_type_layer_count(layers) >= 2, "%s seed %d keeps at least two route-choice layers with different node types" % [chapter_id, seed_value])
	_validate_complete_paths(generated, chapter_config, chapter_id, seed_value)
	_validate_tree_constraints(generated, chapter_config, chapter_id)

func _validate_complete_paths(generated: Dictionary, chapter_config: Dictionary, chapter_id: String, seed_value: int) -> void:
	var layers: Array = generated.get("layers", [])
	var node_by_id: Dictionary = {}
	for layer in layers:
		for node_value in layer:
			var node: Dictionary = node_value
			node_by_id[str(node.get("id", ""))] = node

	var complete_paths: Array = _complete_paths(generated)
	_check(not complete_paths.is_empty(), "%s seed %d has a complete start-to-boss path" % [chapter_id, seed_value])
	var node_budget: Dictionary = chapter_config.get("level_tree_constraints", {}).get("node_budget", {})
	var complete_route_nodes: Dictionary = {}
	var minimum_elites_on_path := 999
	var maximum_elites_on_path := -1
	var boss_safe_window: int = int(chapter_config.get("level_tree_constraints", {}).get("boss_safe_window_layers", 2))
	var first_safe_layer: int = max(1, layers.size() - 1 - boss_safe_window)
	var require_pre_boss_recovery: bool = bool(chapter_config.get("route_constraints", {}).get("require_campfire_or_shop_before_boss", false))
	var max_pressure_without_campfire: int = max(0, int(chapter_config.get("route_constraints", {}).get("max_pressure_nodes_between_campfires", 0)))
	_check(max_pressure_without_campfire > 0, "%s config explicitly enables the pressure cadence constraint" % chapter_id)

	for path_index in range(complete_paths.size()):
		var path: Array = complete_paths[path_index]
		_check(path.size() == layers.size(), "%s seed %d path %d visits every layer" % [chapter_id, seed_value, path_index])
		var counts: Dictionary = {}
		var has_pre_boss_recovery: bool = false
		var pressure_since_campfire := 0
		for node_id_value in path:
			var node_id: String = str(node_id_value)
			var node: Dictionary = node_by_id.get(node_id, {})
			var node_type: String = str(node.get("type", ""))
			counts[node_type] = int(counts.get(node_type, 0)) + 1
			complete_route_nodes[node_id] = true
			var layer_index: int = int(node.get("layer", -1))
			if layer_index >= first_safe_layer and layer_index < layers.size() - 1 and node_type in ["campfire", "shop"]:
				has_pre_boss_recovery = true
			if node_type == "campfire":
				pressure_since_campfire = 0
			elif node_type in ["combat", "elite", "boss"]:
				pressure_since_campfire += 1
				if max_pressure_without_campfire > 0:
					_check(pressure_since_campfire <= max_pressure_without_campfire, "%s seed %d path %d never exceeds %d pressure nodes between campfires" % [chapter_id, seed_value, path_index, max_pressure_without_campfire])

		for node_type_value in node_budget.keys():
			var node_type: String = str(node_type_value)
			var bounds: Array = node_budget.get(node_type, [])
			var count: int = int(counts.get(node_type, 0))
			_check(count >= int(bounds[0]) and count <= int(bounds[1]), "%s seed %d path %d has %d %s nodes, expected [%d, %d]" % [chapter_id, seed_value, path_index, count, node_type, int(bounds[0]), int(bounds[1])])
		minimum_elites_on_path = min(minimum_elites_on_path, int(counts.get("elite", 0)))
		maximum_elites_on_path = max(maximum_elites_on_path, int(counts.get("elite", 0)))
		if require_pre_boss_recovery:
			_check(has_pre_boss_recovery, "%s seed %d path %d has recovery in the boss safe window" % [chapter_id, seed_value, path_index])
	var elite_bounds: Array = node_budget.get("elite", [0, 0])
	if int(elite_bounds[0]) == 0 and int(elite_bounds[1]) > 0:
		if minimum_elites_on_path != 0 or maximum_elites_on_path < 1:
			print("Elite route diagnostic %s seed %d: %s" % [chapter_id, seed_value, JSON.stringify(layers)])
		_check(minimum_elites_on_path == 0 and maximum_elites_on_path >= 1, "%s seed %d offers both a safe route and an optional elite route (observed %d-%d)" % [chapter_id, seed_value, minimum_elites_on_path, maximum_elites_on_path])

	for layer in layers:
		for node_value in layer:
			var node: Dictionary = node_value
			var node_id: String = str(node.get("id", ""))
			_check(complete_route_nodes.has(node_id), "%s seed %d node %s belongs to a complete route" % [chapter_id, seed_value, node_id])

	var boss_count: int = 0
	for layer in layers:
		for node_value in layer:
			if str((node_value as Dictionary).get("type", "")) == "boss":
				boss_count += 1
	_check(boss_count == 1, "%s seed %d has exactly one boss" % [chapter_id, seed_value])

func _complete_paths(generated: Dictionary) -> Array:
	var outgoing: Dictionary = {}
	for edge_value in generated.get("edges", []):
		var edge: Dictionary = edge_value
		var from_id: String = str(edge.get("from", ""))
		var targets: Array = outgoing.get(from_id, [])
		targets.append(str(edge.get("to", "")))
		outgoing[from_id] = targets

	var paths: Array = []
	_collect_complete_paths(str(generated.get("start_node_id", "")), str(generated.get("boss_node_id", "")), outgoing, [], {}, paths)
	return paths

func _collect_complete_paths(current_id: String, boss_id: String, outgoing: Dictionary, path: Array, active: Dictionary, paths: Array) -> void:
	if current_id.is_empty() or active.has(current_id):
		return
	var next_path: Array = path.duplicate()
	next_path.append(current_id)
	if current_id == boss_id:
		paths.append(next_path)
		return

	active[current_id] = true
	for target_id_value in outgoing.get(current_id, []):
		_collect_complete_paths(str(target_id_value), boss_id, outgoing, next_path, active, paths)
	active.erase(current_id)

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

func _mixed_type_layer_count(layers: Array) -> int:
	var count := 0
	for layer_value in layers:
		var seen_types: Dictionary = {}
		for node_value in layer_value:
			seen_types[str((node_value as Dictionary).get("type", ""))] = true
		if seen_types.size() >= 2:
			count += 1
	return count

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
		_failure_count += 1
		if _failure_count == 1:
			push_error("Test failed: %s" % message)
