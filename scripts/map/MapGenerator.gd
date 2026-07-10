class_name MapGenerator
extends RefCounted

static func generate(config: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", 1))

	var layer_count: int = int(config.get("layers", 8))
	var min_nodes: int = int(config.get("min_nodes_per_layer", 2))
	var max_nodes: int = int(config.get("max_nodes_per_layer", 4))
	var layers: Array = []
	var used_event_ids: Dictionary = {}
	var guaranteed_event_ids: Array = config.get("guaranteed_event_ids", []).duplicate(true)
	var node_type_layers: Array = []

	for layer_index in range(layer_count):
		var node_types: Array = _node_types_for_layer(config, layer_index, rng, min_nodes, max_nodes)
		node_type_layers.append(node_types)
	_apply_tree_constraints(node_type_layers, config, min_nodes, max_nodes)

	for layer_index in range(layer_count):
		var node_types: Array = node_type_layers[layer_index]
		var layer_nodes: Array = []
		for node_index in range(node_types.size()):
			var node_type: String = str(node_types[node_index])
			layer_nodes.append(_make_node(config, layer_index, node_index, node_type, rng, used_event_ids, guaranteed_event_ids))
		layers.append(layer_nodes)

	var edges: Array = _connect_layers(layers)
	_ensure_route_edges(layers, edges, config.get("route_constraints", {}))
	return {
		"layers": layers,
		"edges": edges,
		"start_node_id": layers[0][0].get("id", ""),
		"boss_node_id": layers[layer_count - 1][0].get("id", "")
	}

static func _apply_tree_constraints(node_type_layers: Array, config: Dictionary, min_nodes: int, max_nodes: int) -> void:
	if node_type_layers.is_empty():
		return
	var chapter_constraints: Dictionary = config.get("level_tree_constraints", {})
	var route_constraints: Dictionary = config.get("route_constraints", {})
	if chapter_constraints.is_empty() and route_constraints.is_empty():
		return

	node_type_layers[0] = ["combat"]
	node_type_layers[node_type_layers.size() - 1] = ["boss"]

	var early_latest_layer: int = min(int(chapter_constraints.get("early_elite_latest_layer", 3)), node_type_layers.size() - 2)
	var early_elite_max_count: int = int(chapter_constraints.get("early_elite_max_count", 1))
	var early_elite_count: int = 0
	for layer_index in range(1, early_latest_layer + 1):
		var layer_types: Array = node_type_layers[layer_index]
		var elite_seen_in_layer: bool = false
		for node_index in range(layer_types.size()):
			if str(layer_types[node_index]) != "elite":
				continue
			if elite_seen_in_layer or early_elite_count >= early_elite_max_count:
				layer_types[node_index] = "combat"
			else:
				elite_seen_in_layer = true
				early_elite_count += 1

	var minimum_branching_layers: int = int(route_constraints.get("minimum_branching_layers", 0))
	var minimum_choices: int = max(2, int(route_constraints.get("minimum_choices_on_branch_layer", 2)))
	var branching_count: int = 0
	for layer_index in range(1, node_type_layers.size() - 1):
		if node_type_layers[layer_index].size() >= minimum_choices:
			branching_count += 1
	for layer_index in range(1, node_type_layers.size() - 1):
		if branching_count >= minimum_branching_layers:
			break
		var layer_types: Array = node_type_layers[layer_index]
		if layer_types.size() >= minimum_choices:
			continue
		while layer_types.size() < minimum_choices and layer_types.size() < max(max_nodes, minimum_choices):
			layer_types.append("combat")
		branching_count += 1

	if bool(route_constraints.get("require_campfire_or_shop_before_boss", false)):
		var safe_window: int = max(1, int(chapter_constraints.get("boss_safe_window_layers", 2)))
		var first_safe_layer: int = max(1, node_type_layers.size() - 1 - safe_window)
		var has_recovery: bool = false
		for layer_index in range(first_safe_layer, node_type_layers.size() - 1):
			for node_type_value in node_type_layers[layer_index]:
				if str(node_type_value) in ["campfire", "shop"]:
					has_recovery = true
					break
			if has_recovery:
				break
		if not has_recovery:
			var recovery_layer: Array = node_type_layers[node_type_layers.size() - 2]
			if recovery_layer.is_empty():
				recovery_layer.append("campfire")
			else:
				recovery_layer[recovery_layer.size() - 1] = "campfire"

	if bool(route_constraints.get("no_forced_elite_after_treasure", false)):
		for layer_index in range(node_type_layers.size() - 1):
			if not node_type_layers[layer_index].has("treasure"):
				continue
			var next_layer: Array = node_type_layers[layer_index + 1]
			var has_non_elite: bool = false
			for node_type_value in next_layer:
				if str(node_type_value) != "elite":
					has_non_elite = true
					break
			if not has_non_elite and not next_layer.is_empty():
				next_layer[next_layer.size() - 1] = "combat"

static func _node_types_for_layer(config: Dictionary, layer_index: int, rng: RandomNumberGenerator, min_nodes: int, max_nodes: int) -> Array:
	var fixed_layers: Dictionary = config.get("fixed_layers", {})
	var fixed_key: String = str(layer_index)
	if fixed_layers.has(fixed_key):
		return fixed_layers[fixed_key].duplicate(true)

	var count: int = rng.randi_range(min_nodes, max_nodes)
	var result: Array = []
	for _i in range(count):
		result.append(_weighted_node_type(config.get("node_weights", {}), rng))
	return result

static func _weighted_node_type(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total: int = 0
	for key in weights.keys():
		total += int(weights[key])
	if total <= 0:
		return "combat"

	var roll: int = rng.randi_range(1, total)
	var cursor: int = 0
	for key in weights.keys():
		cursor += int(weights[key])
		if roll <= cursor:
			return str(key)
	return "combat"

static func _make_node(config: Dictionary, layer_index: int, node_index: int, node_type: String, rng: RandomNumberGenerator, used_event_ids: Dictionary, guaranteed_event_ids: Array) -> Dictionary:
	var node := {
		"id": "L%d_N%d" % [layer_index, node_index],
		"layer": layer_index,
		"index": node_index,
		"type": node_type,
		"name": _display_name(node_type)
	}

	if node_type == "combat" or node_type == "elite" or node_type == "boss":
		var encounter_pool: Array = config.get("encounter_by_type", {}).get(node_type, [])
		if not encounter_pool.is_empty():
			node["encounter_id"] = encounter_pool[rng.randi_range(0, encounter_pool.size() - 1)]
	elif node_type == "event":
		var event_pool: Array = config.get("event_pool", [])
		if not event_pool.is_empty():
			var event_id: String = str(guaranteed_event_ids.pop_front()) if not guaranteed_event_ids.is_empty() else _pick_event_id(event_pool, rng, used_event_ids, bool(config.get("unique_events", true)))
			node["event_id"] = event_id
			used_event_ids[event_id] = true

	return node

static func _pick_event_id(event_pool: Array, rng: RandomNumberGenerator, used_event_ids: Dictionary, unique_events: bool) -> String:
	var available: Array = []
	if unique_events:
		for event_id in event_pool:
			var event_key: String = str(event_id)
			if not used_event_ids.has(event_key):
				available.append(event_key)
	if available.is_empty():
		for event_id in event_pool:
			available.append(str(event_id))
	return str(available[rng.randi_range(0, available.size() - 1)])

static func _connect_layers(layers: Array) -> Array:
	var edges: Array = []
	for layer_index in range(layers.size() - 1):
		var current_layer: Array = layers[layer_index]
		var next_layer: Array = layers[layer_index + 1]
		for node_index in range(current_layer.size()):
			var from_id: String = str(current_layer[node_index].get("id", ""))
			var primary_target_index: int = min(node_index, next_layer.size() - 1)
			edges.append({"from": from_id, "to": next_layer[primary_target_index].get("id", "")})
			if node_index + 1 < next_layer.size():
				edges.append({"from": from_id, "to": next_layer[node_index + 1].get("id", "")})
	return edges

static func _ensure_route_edges(layers: Array, edges: Array, route_constraints: Dictionary) -> void:
	if not bool(route_constraints.get("no_forced_elite_after_treasure", false)):
		return
	for layer_index in range(layers.size() - 1):
		var next_layer: Array = layers[layer_index + 1]
		for node_value in layers[layer_index]:
			var node: Dictionary = node_value
			if str(node.get("type", "")) != "treasure":
				continue
			var from_id: String = str(node.get("id", ""))
			var has_safe_exit: bool = false
			for edge_value in edges:
				var edge: Dictionary = edge_value
				if str(edge.get("from", "")) != from_id:
					continue
				var target_id: String = str(edge.get("to", ""))
				for target_value in next_layer:
					var target: Dictionary = target_value
					if str(target.get("id", "")) == target_id and str(target.get("type", "")) != "elite":
						has_safe_exit = true
						break
				if has_safe_exit:
					break
			if has_safe_exit:
				continue
			for target_value in next_layer:
				var target: Dictionary = target_value
				if str(target.get("type", "")) != "elite":
					edges.append({"from": from_id, "to": str(target.get("id", ""))})
					break

static func _display_name(node_type: String) -> String:
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
			return "未知节点"
