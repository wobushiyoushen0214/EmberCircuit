class_name GameState
extends RefCounted

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")

var gold: int = 0
var deck_ids: Array = []
var relic_ids: Array = []
var current_hp: int = 0
var max_hp: int = 0

func setup_from_data(card_data: Dictionary, relic_data: Dictionary, player_data: Dictionary) -> void:
	var player := player_data.get("player", {})
	max_hp = int(player.get("max_hp", 72))
	current_hp = int(player.get("starting_hp", max_hp))
	gold = int(player.get("starting_gold", 0))
	deck_ids = card_data.get("starter_deck", {}).get("cards", []).duplicate(true)
	relic_ids = relic_data.get("starter_relics", []).duplicate(true)
