class_name GameState
extends RefCounted

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

var gold: int = 0
var deck_ids: Array = []
var relic_ids: Array = []
var current_hp: int = 0
var max_hp: int = 0
var selected_character_id: String = ""

func setup_from_data(card_data: Dictionary, relic_data: Dictionary, player_data: Dictionary, character_id: String = "") -> void:
	selected_character_id = _valid_character_id(player_data, character_id)
	var player := _character_config(player_data, selected_character_id)
	max_hp = int(player.get("max_hp", 72))
	current_hp = int(player.get("starting_hp", max_hp))
	gold = int(player.get("starting_gold", 0))
	deck_ids = player.get("starter_deck_ids", card_data.get("starter_deck", {}).get("cards", [])).duplicate(true)
	relic_ids = player.get("starter_relic_ids", relic_data.get("starter_relics", [])).duplicate(true)

func _valid_character_id(player_data: Dictionary, character_id: String) -> String:
	var requested_id := character_id
	if requested_id.is_empty():
		requested_id = str(player_data.get("default_character_id", ""))
	if requested_id.is_empty():
		requested_id = str(player_data.get("player", {}).get("id", "ember_exile"))
	if not _character_config(player_data, requested_id).is_empty():
		return requested_id
	return str(player_data.get("player", {}).get("id", "ember_exile"))

func _character_config(player_data: Dictionary, character_id: String) -> Dictionary:
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		if str(character_dict.get("id", "")) == character_id:
			return character_dict
	var fallback_player: Dictionary = player_data.get("player", {})
	if str(fallback_player.get("id", "")) == character_id or character_id.is_empty():
		return fallback_player
	return {}
