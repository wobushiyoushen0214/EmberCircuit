extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

func _init() -> void:
	var card_data: Dictionary = DataLoaderScript.load_json("res://data/cards/cards.json")
	var enemy_data: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var relic_data: Dictionary = DataLoaderScript.load_json("res://data/relics/relics.json")
	var potion_data: Dictionary = DataLoaderScript.load_json("res://data/potions/potions.json")
	var event_data: Dictionary = DataLoaderScript.load_json("res://data/events/events.json")
	var map_generation_data: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")

	var cards_by_id: Dictionary = DataLoaderScript.index_by_id(card_data.get("cards", []))
	var relics_by_id: Dictionary = DataLoaderScript.index_by_id(relic_data.get("relics", []))
	var potions_by_id: Dictionary = DataLoaderScript.index_by_id(potion_data.get("potions", []))
	var events_by_id: Dictionary = DataLoaderScript.index_by_id(event_data.get("events", []))

	_check(event_data.get("events", []).size() >= 10, "first chapter has at least 10 events")
	for event_id in map_generation_data.get("chapter_one", {}).get("event_pool", []):
		_check(events_by_id.has(str(event_id)), "map event pool references existing event: %s" % str(event_id))

	for event in event_data.get("events", []):
		var event_dict: Dictionary = event
		_check(event_dict.has("design_note"), "event has design_note: %s" % event_dict.get("id", "unknown"))
		_check(event_dict.has("balance_note"), "event has balance_note: %s" % event_dict.get("id", "unknown"))
		for choice in event_dict.get("choices", []):
			var choice_dict: Dictionary = choice
			for effect in choice_dict.get("effects", []):
				var effect_dict: Dictionary = effect
				match str(effect_dict.get("type", "")):
					"add_card":
						_check(cards_by_id.has(str(effect_dict.get("card_id", ""))), "event references existing card")
					"gain_relic":
						_check(relics_by_id.has(str(effect_dict.get("relic_id", ""))), "event references existing relic")
					"gain_potion":
						_check(potions_by_id.has(str(effect_dict.get("potion_id", ""))), "event references existing potion")

	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		_check(potion_dict.has("design_note"), "potion has design_note: %s" % potion_dict.get("id", "unknown"))
		_check(potion_dict.has("balance_note"), "potion has balance_note: %s" % potion_dict.get("id", "unknown"))
		_check(potion_dict.has("implementation_note"), "potion has implementation_note: %s" % potion_dict.get("id", "unknown"))

	for enemy in enemy_data.get("enemies", []):
		var enemy_dict: Dictionary = enemy
		_validate_actions(enemy_dict.get("actions", []), cards_by_id, "enemy %s base actions" % enemy_dict.get("id", "unknown"))
		if str(enemy_dict.get("tier", "")) == "boss":
			_check(enemy_dict.get("phases", []).size() >= 2, "boss has at least two configured phases")
		for phase in enemy_dict.get("phases", []):
			var phase_dict: Dictionary = phase
			_check(phase_dict.has("id"), "enemy phase has id")
			_check(phase_dict.has("name"), "enemy phase has name")
			_check(phase_dict.has("phase_note"), "enemy phase has phase_note")
			_check(phase_dict.has("hp_percent_below") or phase_dict.has("hp_below"), "enemy phase has HP threshold")
			_validate_effects(phase_dict.get("on_enter_effects", []), cards_by_id, "phase %s entry effects" % phase_dict.get("id", "unknown"))
			_validate_actions(phase_dict.get("actions", []), cards_by_id, "phase %s actions" % phase_dict.get("id", "unknown"))

	print("Data integrity smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)

func _validate_actions(actions: Array, cards_by_id: Dictionary, context: String) -> void:
	_check(not actions.is_empty(), "%s has actions" % context)
	for action in actions:
		var action_dict: Dictionary = action
		_check(action_dict.has("id"), "%s action has id" % context)
		_check(action_dict.has("intent"), "%s action has intent" % context)
		_validate_effects(action_dict.get("effects", []), cards_by_id, "%s action %s effects" % [context, action_dict.get("id", "unknown")])

func _validate_effects(effects: Array, cards_by_id: Dictionary, context: String) -> void:
	for effect in effects:
		var effect_dict: Dictionary = effect
		if str(effect_dict.get("type", "")) == "create_card":
			_check(cards_by_id.has(str(effect_dict.get("card_id", ""))), "%s references existing created card" % context)
