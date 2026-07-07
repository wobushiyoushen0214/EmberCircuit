class_name MapGenerator
extends RefCounted

static func generate(config: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", 1))

	var layer_count: int = int(config.get("layers", 8))
	var min_nodes: int = int(config.get("min_nodes_per_layer", 2))
	var max_nodes: int = int(config.get("max_nodes_per_layer", 4))
	var layers: Array = []

	for layer_index in range(layer_count):
		var node_types: Array = _node_types_for_layer(config, layer_index, rng, min_nodes, max_nodes)
		var layer_nodes: Array = []
		for node_index in range(node_types.size()):
			var node_type: String = str(node_types[node_index])
			layer_nodes.append(_make_node(config, layer_index, node_index, node_type, rng))
		layers.append(layer_nodes)

	var edges: Array = _connect_layers(layers)
	return {
		"layers": layers,
		"edges": edges,
		"start_node_id": layers[0][0].get("id", ""),
		"boss_node_id": layers[layer_count - 1][0].get("id", "")
	}

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

static func _make_node(config: Dictionary, layer_index: int, node_index: int, node_type: String, rng: RandomNumberGenerator) -> Dictionary:
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
			node["event_id"] = event_pool[rng.randi_range(0, event_pool.size() - 1)]

	return node

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
		_:
			return "未知节点"
