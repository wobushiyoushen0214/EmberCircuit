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
	var budget_locked_transitions: Dictionary = _apply_node_budget(node_type_layers, config)

	for layer_index in range(layer_count):
		var node_types: Array = node_type_layers[layer_index]
		var layer_nodes: Array = []
		for node_index in range(node_types.size()):
			var node_type: String = str(node_types[node_index])
			layer_nodes.append(_make_node(config, layer_index, node_index, node_type, rng, used_event_ids, guaranteed_event_ids))
		layers.append(layer_nodes)

	var edges: Array = _connect_layers(layers, budget_locked_transitions)
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

static func _apply_node_budget(node_type_layers: Array, config: Dictionary) -> Dictionary:
	if node_type_layers.size() < 2:
		return {}
	var chapter_constraints: Dictionary = config.get("level_tree_constraints", {})
	var node_budget: Dictionary = chapter_constraints.get("node_budget", {})
	if node_budget.is_empty():
		return {}

	var budget_types: Array = []
	var bounds_by_type: Dictionary = {}
	for node_type_value in node_budget.keys():
		var node_type: String = str(node_type_value)
		var bounds_value: Variant = node_budget.get(node_type, [])
		if not (bounds_value is Array):
			return {}
		var bounds: Array = bounds_value
		if bounds.size() != 2 or int(bounds[0]) < 0 or int(bounds[1]) < int(bounds[0]):
			return {}
		budget_types.append(node_type)
		bounds_by_type[node_type] = [int(bounds[0]), int(bounds[1])]
	budget_types.sort()
	if not budget_types.has("combat") or not budget_types.has("boss"):
		return {}

	var type_indexes: Dictionary = {}
	var empty_counts: Array = []
	for type_index in range(budget_types.size()):
		type_indexes[str(budget_types[type_index])] = type_index
		empty_counts.append(0)

	var route_constraints: Dictionary = config.get("route_constraints", {})
	var early_latest_layer: int = min(int(chapter_constraints.get("early_elite_latest_layer", 3)), node_type_layers.size() - 2)
	var early_elite_max_count: int = int(chapter_constraints.get("early_elite_max_count", 1))
	var safe_window: int = max(1, int(chapter_constraints.get("boss_safe_window_layers", 2)))
	var first_safe_layer: int = max(1, node_type_layers.size() - 1 - safe_window)
	var require_recovery: bool = bool(route_constraints.get("require_campfire_or_shop_before_boss", false))
	var prevent_forced_elite: bool = bool(route_constraints.get("no_forced_elite_after_treasure", false))
	var max_pressure_without_campfire: int = max(0, int(route_constraints.get("max_pressure_nodes_between_campfires", 0)))
	var initial_state := {
		"counts": empty_counts,
		"schedule": [],
		"cost": 0,
		"previous_type": "",
		"has_recovery": false,
		"early_elite_count": 0,
		"pressure_since_campfire": 0,
	}
	var states: Dictionary = {_budget_state_key(empty_counts, "", false, 0, 0): initial_state}

	for layer_index in range(node_type_layers.size()):
		var allowed_types: Array = []
		if layer_index == 0:
			allowed_types = ["combat"]
		elif layer_index == node_type_layers.size() - 1:
			allowed_types = ["boss"]
		else:
			for node_type_value in budget_types:
				var node_type: String = str(node_type_value)
				if node_type != "boss":
					allowed_types.append(node_type)

		var next_states: Dictionary = {}
		var state_keys: Array = states.keys()
		state_keys.sort()
		for state_key_value in state_keys:
			var state: Dictionary = states[state_key_value]
			for node_type_value in allowed_types:
				var node_type: String = str(node_type_value)
				var previous_type: String = str(state.get("previous_type", ""))
				if prevent_forced_elite and previous_type == "treasure" and node_type == "elite":
					continue
				var pressure_since_campfire: int = int(state.get("pressure_since_campfire", 0))
				if node_type == "campfire":
					pressure_since_campfire = 0
				elif node_type in ["combat", "elite", "boss"]:
					pressure_since_campfire += 1
				if max_pressure_without_campfire > 0 and pressure_since_campfire > max_pressure_without_campfire:
					continue

				var early_elite_count: int = int(state.get("early_elite_count", 0))
				if node_type == "elite" and layer_index >= 1 and layer_index <= early_latest_layer:
					var early_layer: Array = node_type_layers[layer_index]
					if early_layer.size() > 1:
						continue
					early_elite_count += early_layer.size()
					if early_elite_count > early_elite_max_count:
						continue

				var counts: Array = (state.get("counts", []) as Array).duplicate()
				var type_index: int = int(type_indexes.get(node_type, -1))
				if type_index < 0:
					continue
				counts[type_index] = int(counts[type_index]) + 1
				var remaining_slots: int = node_type_layers.size() - layer_index - 1
				if not _budget_counts_can_finish(counts, budget_types, bounds_by_type, remaining_slots):
					continue

				var has_recovery: bool = bool(state.get("has_recovery", false))
				if layer_index >= first_safe_layer and layer_index < node_type_layers.size() - 1 and node_type in ["campfire", "shop"]:
					has_recovery = true
				var candidate_schedule: Array = (state.get("schedule", []) as Array).duplicate()
				candidate_schedule.append(node_type)
				var layer_types: Array = node_type_layers[layer_index]
				var cost: int = int(state.get("cost", 0)) + _layer_type_replacement_cost(layer_types, node_type)
				var next_state := {
					"counts": counts,
					"schedule": candidate_schedule,
					"cost": cost,
					"previous_type": node_type,
					"has_recovery": has_recovery,
					"early_elite_count": early_elite_count,
					"pressure_since_campfire": pressure_since_campfire,
				}
				var next_key: String = _budget_state_key(counts, node_type, has_recovery, early_elite_count, pressure_since_campfire)
				var existing: Dictionary = next_states.get(next_key, {})
				if existing.is_empty() or cost < int(existing.get("cost", 0)) or (cost == int(existing.get("cost", 0)) and _budget_schedule_key(candidate_schedule) < _budget_schedule_key(existing.get("schedule", []))):
					next_states[next_key] = next_state
		states = next_states
		if states.is_empty():
			return {}

	var best_state: Dictionary = {}
	var final_state_keys: Array = states.keys()
	final_state_keys.sort()
	for state_key_value in final_state_keys:
		var state: Dictionary = states[state_key_value]
		if require_recovery and not bool(state.get("has_recovery", false)):
			continue
		if best_state.is_empty() or int(state.get("cost", 0)) < int(best_state.get("cost", 0)) or (int(state.get("cost", 0)) == int(best_state.get("cost", 0)) and _budget_schedule_key(state.get("schedule", [])) < _budget_schedule_key(best_state.get("schedule", []))):
			best_state = state
	if best_state.is_empty():
		return {}

	var schedule: Array = best_state.get("schedule", [])
	for layer_index in range(node_type_layers.size()):
		var layer_types: Array = node_type_layers[layer_index]
		for node_index in range(layer_types.size()):
			layer_types[node_index] = str(schedule[layer_index])
	return _introduce_budget_route_variants(node_type_layers, schedule, config)

static func _introduce_budget_route_variants(node_type_layers: Array, schedule: Array, config: Dictionary) -> Dictionary:
	var locked_transitions: Dictionary = {}
	var route_constraints: Dictionary = config.get("route_constraints", {})
	var chapter_constraints: Dictionary = config.get("level_tree_constraints", {})
	var desired_blocks := 1
	var early_latest_layer: int = min(int(chapter_constraints.get("early_elite_latest_layer", 3)), node_type_layers.size() - 2)
	var safe_window: int = max(1, int(chapter_constraints.get("boss_safe_window_layers", 2)))
	var first_safe_layer: int = max(1, node_type_layers.size() - 1 - safe_window)
	var require_recovery: bool = bool(route_constraints.get("require_campfire_or_shop_before_boss", false))
	var prevent_forced_elite: bool = bool(route_constraints.get("no_forced_elite_after_treasure", false))
	var elite_bounds: Array = chapter_constraints.get("node_budget", {}).get("elite", [0, 0])
	var layer_index := 1
	while layer_index < node_type_layers.size() - 2 and locked_transitions.size() < desired_blocks:
		var first_type: String = str(schedule[layer_index])
		var second_type: String = str(schedule[layer_index + 1])
		var pair_types := [first_type, second_type]
		if first_type == second_type or (pair_types.has("treasure") and pair_types.has("elite")):
			layer_index += 1
			continue
		if pair_types.has("elite") and int(elite_bounds[0]) == 0:
			layer_index += 1
			continue
		if pair_types.has("elite") and layer_index <= early_latest_layer:
			layer_index += 1
			continue
		var previous_type: String = str(schedule[layer_index - 1])
		var next_type: String = str(schedule[layer_index + 2])
		if prevent_forced_elite and ((previous_type == "treasure" and pair_types.has("elite")) or (pair_types.has("treasure") and next_type == "elite")):
			layer_index += 1
			continue
		var pair_has_recovery: bool = pair_types.has("campfire") or pair_types.has("shop")
		if require_recovery and pair_has_recovery and layer_index < first_safe_layer and layer_index + 1 >= first_safe_layer:
			layer_index += 1
			continue
		var swapped_schedule: Array = schedule.duplicate()
		swapped_schedule[layer_index] = second_type
		swapped_schedule[layer_index + 1] = first_type
		var max_pressure_without_campfire: int = max(0, int(route_constraints.get("max_pressure_nodes_between_campfires", 0)))
		if max_pressure_without_campfire > 0 and not _schedule_respects_pressure_cadence(swapped_schedule, max_pressure_without_campfire):
			layer_index += 1
			continue

		var first_layer: Array = node_type_layers[layer_index]
		var second_layer: Array = node_type_layers[layer_index + 1]
		if first_layer.size() < 2 or second_layer.size() < 2:
			layer_index += 1
			continue
		for node_index in range(first_layer.size()):
			first_layer[node_index] = first_type if node_index % 2 == 0 else second_type
		for node_index in range(second_layer.size()):
			second_layer[node_index] = second_type if node_index % 2 == 0 else first_type
		locked_transitions[layer_index] = true
		layer_index += 2
	_introduce_optional_budget_choices(node_type_layers, schedule, config, locked_transitions)
	return locked_transitions

static func _introduce_optional_budget_choices(node_type_layers: Array, schedule: Array, config: Dictionary, locked_transitions: Dictionary) -> void:
	var chapter_constraints: Dictionary = config.get("level_tree_constraints", {})
	var node_budget: Dictionary = chapter_constraints.get("node_budget", {})
	var route_constraints: Dictionary = config.get("route_constraints", {})
	var min_counts: Dictionary = {}
	var max_counts: Dictionary = {}
	for node_type_value in schedule:
		var node_type: String = str(node_type_value)
		min_counts[node_type] = int(min_counts.get(node_type, 0)) + 1
		max_counts[node_type] = int(max_counts.get(node_type, 0)) + 1
	var max_pressure_without_campfire: int = max(0, int(route_constraints.get("max_pressure_nodes_between_campfires", 0)))
	var safe_window: int = max(1, int(chapter_constraints.get("boss_safe_window_layers", 2)))
	var first_safe_layer: int = max(1, node_type_layers.size() - 1 - safe_window)
	var require_recovery: bool = bool(route_constraints.get("require_campfire_or_shop_before_boss", false))
	var prevent_forced_elite: bool = bool(route_constraints.get("no_forced_elite_after_treasure", false))
	var early_latest_layer: int = min(int(chapter_constraints.get("early_elite_latest_layer", 3)), node_type_layers.size() - 2)
	var early_elite_limit: int = int(chapter_constraints.get("early_elite_max_count", 1))
	var optional_choice_target: int = max(1, int(ceil(float(int(route_constraints.get("minimum_branching_layers", 2))) / 2.0)))
	var optional_choice_count := 0
	var alternate_priority := ["elite", "treasure", "event", "campfire", "combat"]
	var elite_bounds: Array = node_budget.get("elite", [0, 0])
	var elite_choice_required: bool = elite_bounds.size() == 2 and int(elite_bounds[0]) == 0 and int(elite_bounds[1]) > 0
	var base_elite_count: int = int(max_counts.get("elite", 0))
	var elite_choice_added := false

	for layer_index in range(1, node_type_layers.size() - 1):
		if optional_choice_count >= optional_choice_target and (not elite_choice_required or elite_choice_added):
			break
		if locked_transitions.has(layer_index) or locked_transitions.has(layer_index - 1):
			continue
		var layer_types: Array = node_type_layers[layer_index]
		if layer_types.size() < 2:
			continue
		var base_type: String = str(schedule[layer_index])
		var base_bounds: Array = node_budget.get(base_type, [])
		if base_bounds.size() != 2:
			continue
		var layer_alternate_priority: Array = alternate_priority
		if elite_choice_required and not elite_choice_added:
			if base_elite_count > 0:
				if base_type != "elite":
					continue
				layer_alternate_priority = ["event", "treasure", "campfire", "combat"]
			else:
				layer_alternate_priority = ["elite"]
		for alternate_type_value in layer_alternate_priority:
			var alternate_type: String = str(alternate_type_value)
			if alternate_type == base_type:
				continue
			var alternate_bounds: Array = node_budget.get(alternate_type, [])
			if alternate_bounds.size() != 2:
				continue
			if int(min_counts.get(base_type, 0)) - 1 < int(base_bounds[0]):
				continue
			if int(max_counts.get(alternate_type, 0)) + 1 > int(alternate_bounds[1]):
				continue
			if alternate_type == "elite" and layer_index <= early_latest_layer and _early_elite_node_count(node_type_layers, early_latest_layer) >= early_elite_limit:
				continue
			var alternate_schedule: Array = schedule.duplicate()
			alternate_schedule[layer_index] = alternate_type
			if max_pressure_without_campfire > 0 and not _schedule_respects_pressure_cadence(alternate_schedule, max_pressure_without_campfire):
				continue
			# trellis-minimal: pressure-3 is the new candidate contract; legacy max4 graphs retain their exact route search.
			if max_pressure_without_campfire <= 3 and max_pressure_without_campfire > 0:
				var original_type = layer_types[1]
				layer_types[1] = alternate_type
				var pressure_states: Dictionary = {0: true}
				var all_combinations_safe := true
				for candidate_layer_value in node_type_layers:
					var next_pressure_states: Dictionary = {}
					for pressure_value in pressure_states.keys():
						for candidate_type_value in candidate_layer_value:
							var next_pressure: int = int(pressure_value)
							var candidate_type := str(candidate_type_value)
							if candidate_type == "campfire":
								next_pressure = 0
							elif candidate_type in ["combat", "elite", "boss"]:
								next_pressure += 1
							if next_pressure > max_pressure_without_campfire:
								all_combinations_safe = false
								break
							next_pressure_states[next_pressure] = true
						if not all_combinations_safe:
							break
					if not all_combinations_safe:
						break
					pressure_states = next_pressure_states
				layer_types[1] = original_type
				if not all_combinations_safe:
					continue
			if require_recovery and not _schedule_has_safe_recovery(alternate_schedule, first_safe_layer):
				continue
			if prevent_forced_elite and not _schedule_avoids_forced_elite_after_treasure(alternate_schedule):
				continue
			layer_types[1] = alternate_type
			min_counts[base_type] = int(min_counts.get(base_type, 0)) - 1
			max_counts[alternate_type] = int(max_counts.get(alternate_type, 0)) + 1
			if alternate_type == "elite" or base_type == "elite":
				elite_choice_added = true
			optional_choice_count += 1
			break

static func _early_elite_node_count(node_type_layers: Array, early_latest_layer: int) -> int:
	var count := 0
	for layer_index in range(1, min(early_latest_layer + 1, node_type_layers.size())):
		for node_type_value in node_type_layers[layer_index]:
			if str(node_type_value) == "elite":
				count += 1
	return count

static func _schedule_has_safe_recovery(schedule: Array, first_safe_layer: int) -> bool:
	for layer_index in range(first_safe_layer, schedule.size() - 1):
		if str(schedule[layer_index]) in ["campfire", "shop"]:
			return true
	return false

static func _schedule_avoids_forced_elite_after_treasure(schedule: Array) -> bool:
	for layer_index in range(schedule.size() - 1):
		if str(schedule[layer_index]) == "treasure" and str(schedule[layer_index + 1]) == "elite":
			return false
	return true

static func _schedule_respects_pressure_cadence(schedule: Array, max_pressure_without_campfire: int) -> bool:
	var pressure_since_campfire := 0
	for node_type_value in schedule:
		var node_type: String = str(node_type_value)
		if node_type == "campfire":
			pressure_since_campfire = 0
		elif node_type in ["combat", "elite", "boss"]:
			pressure_since_campfire += 1
			if pressure_since_campfire > max_pressure_without_campfire:
				return false
	return true

static func _budget_counts_can_finish(counts: Array, budget_types: Array, bounds_by_type: Dictionary, remaining_slots: int) -> bool:
	var required_slots: int = 0
	var available_slots: int = 0
	for type_index in range(budget_types.size()):
		var node_type: String = str(budget_types[type_index])
		var bounds: Array = bounds_by_type.get(node_type, [])
		var count: int = int(counts[type_index])
		if count > int(bounds[1]):
			return false
		required_slots += max(0, int(bounds[0]) - count)
		available_slots += max(0, int(bounds[1]) - count)
	return required_slots <= remaining_slots and available_slots >= remaining_slots

static func _layer_type_replacement_cost(layer_types: Array, node_type: String) -> int:
	var replacement_count: int = 0
	for existing_type_value in layer_types:
		if str(existing_type_value) != node_type:
			replacement_count += 1
	return replacement_count

static func _budget_state_key(counts: Array, previous_type: String, has_recovery: bool, early_elite_count: int, pressure_since_campfire: int) -> String:
	var count_parts := PackedStringArray()
	for count_value in counts:
		count_parts.append(str(int(count_value)))
	return "%s|%s|%d|%d|%d" % [",".join(count_parts), previous_type, int(has_recovery), early_elite_count, pressure_since_campfire]

static func _budget_schedule_key(schedule: Array) -> String:
	var type_parts := PackedStringArray()
	for node_type_value in schedule:
		type_parts.append(str(node_type_value))
	return "|".join(type_parts)

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

static func _encounter_pool_for_layer(config: Dictionary, node_type: String, layer_index: int) -> Array:
	var legacy_pool: Array = config.get("encounter_by_type", {}).get(node_type, [])
	var layer_bands_value = config.get("encounter_layer_bands", {})
	if layer_bands_value is not Dictionary:
		return legacy_pool
	var bands_value = (layer_bands_value as Dictionary).get(node_type)
	if bands_value is not Array or (bands_value as Array).is_empty():
		return legacy_pool

	var matching_pools: Array = []
	for band_value in bands_value:
		if band_value is not Dictionary:
			return legacy_pool
		var band: Dictionary = band_value
		var layers_value = band.get("layers")
		var encounter_ids_value = band.get("encounter_ids")
		if layers_value is not Array or (layers_value as Array).size() != 2:
			return legacy_pool
		var layers: Array = layers_value
		var start_is_integer: bool = typeof(layers[0]) == TYPE_INT or (typeof(layers[0]) == TYPE_FLOAT and float(layers[0]) == floor(float(layers[0])))
		var end_is_integer: bool = typeof(layers[1]) == TYPE_INT or (typeof(layers[1]) == TYPE_FLOAT and float(layers[1]) == floor(float(layers[1])))
		if not start_is_integer or not end_is_integer or int(layers[0]) < 0 or int(layers[1]) < int(layers[0]):
			return legacy_pool
		if encounter_ids_value is not Array or (encounter_ids_value as Array).is_empty():
			return legacy_pool
		var encounter_ids: Array = encounter_ids_value
		for encounter_id_value in encounter_ids:
			if typeof(encounter_id_value) != TYPE_STRING or str(encounter_id_value).strip_edges().is_empty():
				return legacy_pool
		if layer_index >= int(layers[0]) and layer_index <= int(layers[1]):
			matching_pools.append(encounter_ids)
	return matching_pools[0] if matching_pools.size() == 1 else legacy_pool

static func _make_node(config: Dictionary, layer_index: int, node_index: int, node_type: String, rng: RandomNumberGenerator, used_event_ids: Dictionary, guaranteed_event_ids: Array) -> Dictionary:
	var node := {
		"id": "L%d_N%d" % [layer_index, node_index],
		"layer": layer_index,
		"index": node_index,
		"type": node_type,
		"name": _display_name(node_type)
	}

	if node_type == "combat" or node_type == "elite" or node_type == "boss":
		var encounter_pool: Array = _encounter_pool_for_layer(config, node_type, layer_index)
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

static func _connect_layers(layers: Array, locked_transitions: Dictionary = {}) -> Array:
	var edges: Array = []
	for layer_index in range(layers.size() - 1):
		var current_layer: Array = layers[layer_index]
		var next_layer: Array = layers[layer_index + 1]
		if bool(locked_transitions.get(layer_index, false)):
			for current_node_value in current_layer:
				var current_node: Dictionary = current_node_value
				var current_type: String = str(current_node.get("type", ""))
				var connected := false
				for next_node_value in next_layer:
					var next_node: Dictionary = next_node_value
					if str(next_node.get("type", "")) == current_type:
						continue
					edges.append({"from": str(current_node.get("id", "")), "to": str(next_node.get("id", ""))})
					connected = true
				if not connected and not next_layer.is_empty():
					edges.append({"from": str(current_node.get("id", "")), "to": str(next_layer[0].get("id", ""))})
			continue
		var targets_with_incoming: Dictionary = {}
		for node_index in range(current_layer.size()):
			var from_id: String = str(current_layer[node_index].get("id", ""))
			var primary_target_index: int = min(node_index, next_layer.size() - 1)
			var primary_target_id: String = str(next_layer[primary_target_index].get("id", ""))
			edges.append({"from": from_id, "to": primary_target_id})
			targets_with_incoming[primary_target_id] = true
			if node_index + 1 < next_layer.size():
				var secondary_target_id: String = str(next_layer[node_index + 1].get("id", ""))
				edges.append({"from": from_id, "to": secondary_target_id})
				targets_with_incoming[secondary_target_id] = true
		for node_index in range(next_layer.size()):
			var target_id: String = str(next_layer[node_index].get("id", ""))
			if targets_with_incoming.has(target_id):
				continue
			var source_index: int = min(node_index, current_layer.size() - 1)
			edges.append({"from": str(current_layer[source_index].get("id", "")), "to": target_id})
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
