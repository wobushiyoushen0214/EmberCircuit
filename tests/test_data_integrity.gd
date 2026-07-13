extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const AudioManagerScript = preload("res://scripts/core/AudioManager.gd")

const CHARACTER_ART_PATHS := {
	"ember_exile": "res://assets/art/generated/player_ember_exile_pc.png",
	"arc_tinker": "res://assets/art/generated/player_arc_tinker_pc.png",
	"pyre_ascetic": "res://assets/art/generated/player_pyre_ascetic_pc.png"
}

var failed: bool = false

func _init() -> void:
	var card_data: Dictionary = DataLoaderScript.load_json("res://data/cards/cards.json")
	var enemy_data: Dictionary = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	var relic_data: Dictionary = DataLoaderScript.load_json("res://data/relics/relics.json")
	var potion_data: Dictionary = DataLoaderScript.load_json("res://data/potions/potions.json")
	var event_data: Dictionary = DataLoaderScript.load_json("res://data/events/events.json")
	var encounter_data: Dictionary = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	var map_generation_data: Dictionary = DataLoaderScript.load_json("res://data/config/map_generation.json")
	var player_data: Dictionary = DataLoaderScript.load_json("res://data/config/player.json")
	var economy_data: Dictionary = DataLoaderScript.load_json("res://data/config/economy.json")
	var art_data: Dictionary = DataLoaderScript.load_json("res://data/config/art_assets.json")
	var vfx_data: Dictionary = DataLoaderScript.load_json("res://data/config/vfx_profiles.json")
	var achievement_data: Dictionary = DataLoaderScript.load_json("res://data/config/achievements.json")
	var challenge_data: Dictionary = DataLoaderScript.load_json("res://data/config/challenges.json")
	var progression_data: Dictionary = DataLoaderScript.load_json("res://data/config/progression_systems.json")
	var monster_scaling_data: Dictionary = DataLoaderScript.load_json("res://data/config/monster_scaling.json")
	var level_tree_data: Dictionary = DataLoaderScript.load_json("res://data/config/level_tree.json")
	var card_balance_data: Dictionary = DataLoaderScript.load_json("res://data/config/card_balance_budgets.json")

	var cards_by_id: Dictionary = DataLoaderScript.index_by_id(card_data.get("cards", []))
	var enemies_by_id: Dictionary = DataLoaderScript.index_by_id(enemy_data.get("enemies", []))
	var encounters_by_id: Dictionary = DataLoaderScript.index_by_id(encounter_data.get("encounters", []))
	var relics_by_id: Dictionary = DataLoaderScript.index_by_id(relic_data.get("relics", []))
	var potions_by_id: Dictionary = DataLoaderScript.index_by_id(potion_data.get("potions", []))
	var events_by_id: Dictionary = DataLoaderScript.index_by_id(event_data.get("events", []))
	var card_art_slots_by_id: Dictionary = DataLoaderScript.index_by_id(art_data.get("card_art_slots", []))
	var relic_icon_slots_by_id: Dictionary = DataLoaderScript.index_by_id(art_data.get("relic_icon_slots", []))
	var potion_icon_slots_by_id: Dictionary = DataLoaderScript.index_by_id(art_data.get("potion_icon_slots", []))
	var event_art_slots_by_id: Dictionary = DataLoaderScript.index_by_id(art_data.get("event_art_slots", []))
	var battle_background_slots_by_id: Dictionary = DataLoaderScript.index_by_id(art_data.get("battle_background_slots", []))
	var vfx_profiles_by_id: Dictionary = DataLoaderScript.index_by_id(vfx_data.get("profiles", []))
	var achievements_by_id: Dictionary = DataLoaderScript.index_by_id(achievement_data.get("achievements", []))
	var audio_manager = AudioManagerScript.new()
	var audio_profiles: Dictionary = audio_manager.event_profiles.duplicate(true)
	var audio_stream_paths: Dictionary = audio_manager.event_stream_paths.duplicate(true)
	var audio_stream_asset_count: int = audio_manager.stream_asset_count()
	var music_stream_paths: Dictionary = audio_manager.music_stream_paths.duplicate(true)
	var music_stream_asset_count: int = audio_manager.music_asset_count()
	audio_manager.free()

	var reward_generation: Dictionary = economy_data.get("reward_generation", {})
	var shop_config: Dictionary = economy_data.get("shop", {})
	var treasure_config: Dictionary = economy_data.get("treasure", {})
	var combat_gold_config: Dictionary = economy_data.get("combat_gold_rewards", {})
	_check(int(shop_config.get("remove_card_price", 0)) > 0, "shop remove card base price is positive")
	_check(int(shop_config.get("remove_card_price_increase", 0)) > 0, "shop remove card price increase is positive")
	_check(not str(shop_config.get("remove_card_note", "")).is_empty(), "shop remove card pricing has balance note")
	_validate_price_table(shop_config.get("card_prices", {}), "shop card prices")
	_validate_price_table(shop_config.get("potion_prices", {}), "shop potion prices")
	_validate_price_table(shop_config.get("relic_prices", {}), "shop relic prices")
	_check(int(treasure_config.get("gold_min", 0)) > 0, "treasure gold minimum is positive")
	_check(int(treasure_config.get("gold_max", 0)) >= int(treasure_config.get("gold_min", 0)), "treasure gold range is valid")
	_check(int(treasure_config.get("relic_choices", 0)) >= 1, "treasure has at least one relic choice")
	_check(not str(treasure_config.get("design_note", "")).is_empty(), "treasure config has design note")
	_check(not str(treasure_config.get("balance_note", "")).is_empty(), "treasure config has balance note")
	_validate_combat_gold_rewards(combat_gold_config)
	_validate_rarity_weights(reward_generation.get("card_rarity_weights", {}), "combat card reward rarity weights")
	_validate_rarity_weights(reward_generation.get("shop_card_rarity_weights", {}), "shop card reward rarity weights")
	_validate_rarity_weights(reward_generation.get("relic_rarity_weights", {}), "relic reward rarity weights")
	_validate_rarity_weights(reward_generation.get("shop_relic_rarity_weights", {}), "shop relic rarity weights")
	_validate_rarity_weights(reward_generation.get("potion_rarity_weights", {}), "potion reward rarity weights")
	_check(not str(reward_generation.get("weight_note", "")).is_empty(), "reward generation has balance note")

	var character_ids: Dictionary = {}
	var exclusive_card_count_by_character: Dictionary = {}
	var exclusive_event_count_by_character: Dictionary = {}
	var exclusive_relic_count_by_character: Dictionary = {}
	_check(player_data.get("characters", []).size() >= 3, "player config has at least three playable characters")
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		var character_id: String = str(character_dict.get("id", ""))
		character_ids[character_id] = true
		exclusive_card_count_by_character[character_id] = 0
		exclusive_event_count_by_character[character_id] = 0
		exclusive_relic_count_by_character[character_id] = 0
		_check(not character_id.is_empty(), "character has id")
		_check(character_dict.has("name"), "character has name: %s" % character_id)
		_check(character_dict.has("archetype_note"), "character has archetype_note: %s" % character_id)
		_check(character_dict.has("design_note"), "character has design_note: %s" % character_id)
		_check(character_dict.has("balance_note"), "character has balance_note: %s" % character_id)
		_check(character_dict.has("implementation_note"), "character has implementation_note: %s" % character_id)
		_check(character_dict.get("reward_pool_tags", []).has("shared"), "character reward pool includes shared tag: %s" % character_id)
		_check(CHARACTER_ART_PATHS.has(character_id), "character has configured portrait art: %s" % character_id)
		_validate_svg_art_quality(str(CHARACTER_ART_PATHS.get(character_id, "")), "character portrait art quality: %s" % character_id, 10, true)
		var ending: Dictionary = character_dict.get("ending", {})
		_check(ending.has("victory_title"), "character ending has victory_title: %s" % character_id)
		_check(ending.has("epilogue"), "character ending has epilogue: %s" % character_id)
		_check(ending.has("completion_mark"), "character ending has completion_mark: %s" % character_id)
		_check(ending.get("meta_unlocks", []).size() >= 1, "character ending has meta unlocks: %s" % character_id)
		_check(character_dict.get("starter_deck_ids", []).size() >= 10, "character starter deck has enough cards: %s" % character_id)
		for card_id in character_dict.get("starter_deck_ids", []):
			_check(cards_by_id.has(str(card_id)), "character starter deck references existing card: %s" % str(card_id))
		for relic_id in character_dict.get("starter_relic_ids", []):
			_check(relics_by_id.has(str(relic_id)), "character starter relic references existing relic: %s" % str(relic_id))
		for potion_id in character_dict.get("starting_potions", []):
			_check(potions_by_id.has(str(potion_id)), "character starting potion references existing potion: %s" % str(potion_id))
	_check(character_ids.has(str(player_data.get("default_character_id", ""))), "default character id references a playable character")
	_validate_progression_systems(progression_data, character_ids)
	_validate_monster_scaling(monster_scaling_data, level_tree_data, map_generation_data, encounter_data, enemies_by_id)
	_validate_card_balance_budgets(card_balance_data, card_data.get("cards", []))

	_check(achievements_by_id.size() >= 9, "achievement config has enough first-pass achievements")
	for achievement_id in achievements_by_id.keys():
		var achievement: Dictionary = achievements_by_id.get(achievement_id, {})
		_check(achievement.has("name"), "achievement has name: %s" % achievement_id)
		_check(achievement.has("category"), "achievement has category: %s" % achievement_id)
		_check(achievement.has("description"), "achievement has description: %s" % achievement_id)
		_check(achievement.has("reward_note"), "achievement has reward_note: %s" % achievement_id)
		_check(achievement.has("design_note"), "achievement has design_note: %s" % achievement_id)
		_check(achievement.has("implementation_note"), "achievement has implementation_note: %s" % achievement_id)
		_validate_achievement_condition(achievement.get("condition", {}), character_ids, map_generation_data, "achievement %s" % achievement_id)
	_validate_challenge_levels(challenge_data.get("levels", []))

	_check(audio_stream_paths.size() >= audio_profiles.size(), "audio stream manifest covers configured audio events")
	_check(audio_stream_asset_count == audio_stream_paths.size(), "audio stream manifest assets all exist")
	for audio_event_id in audio_profiles.keys():
		var audio_event: String = str(audio_event_id)
		_check(audio_stream_paths.has(audio_event), "audio event has generated stream path: %s" % audio_event)
		_validate_wav_asset(str(audio_stream_paths.get(audio_event, "")), "audio event wav: %s" % audio_event)
	_check(music_stream_paths.size() >= 10, "music stream manifest covers core runtime contexts")
	_check(music_stream_asset_count == music_stream_paths.size(), "music stream manifest assets all exist")
	for music_context_id in music_stream_paths.keys():
		var music_context: String = str(music_context_id)
		_validate_wav_asset(str(music_stream_paths.get(music_context, "")), "music context wav: %s" % music_context)

	var card_type_frames: Dictionary = art_data.get("card_type_frames", {})
	var card_type_frame_notes: Dictionary = art_data.get("card_type_frame_notes", {})
	for card_type in ["attack", "skill", "power", "status", "curse", "default"]:
		var frame_path: String = str(card_type_frames.get(card_type, ""))
		_check(_resource_or_svg_file_exists(frame_path), "art card type frame exists: %s" % card_type)
		_validate_svg_art_quality(frame_path, "card type frame art quality: %s" % card_type, 10, true)
		_check(not str(card_type_frame_notes.get(card_type, "")).is_empty(), "art card type frame has note: %s" % card_type)
	for map_node_type in ["combat", "elite", "boss", "event", "shop", "campfire", "treasure"]:
		var map_icon_path: String = "res://assets/art/map_node_%s.svg" % map_node_type
		_check(_resource_or_svg_file_exists(map_icon_path), "map node icon exists: %s" % map_node_type)
		if map_node_type == "treasure":
			_validate_svg_art_quality(map_icon_path, "map node icon art quality: %s" % map_node_type, 8, true)
	var fallbacks: Dictionary = art_data.get("fallbacks", {})
	_validate_svg_art_quality(str(fallbacks.get("relic_icon", "")), "fallback relic icon art quality", 7, true)
	_validate_svg_art_quality(str(fallbacks.get("potion_icon", "")), "fallback potion icon art quality", 7, true)
	_validate_svg_art_quality(str(fallbacks.get("event_art", "")), "fallback event art quality", 8, true)
	_check(card_art_slots_by_id.size() >= card_data.get("cards", []).size(), "art manifest covers card art slots")
	_check(relic_icon_slots_by_id.size() >= relic_data.get("relics", []).size(), "art manifest covers relic icon slots")
	_check(potion_icon_slots_by_id.size() >= potion_data.get("potions", []).size(), "art manifest covers potion icon slots")
	_check(event_art_slots_by_id.size() >= event_data.get("events", []).size(), "art manifest covers event art slots")
	_check(battle_background_slots_by_id.size() >= map_generation_data.get("chapter_sequence", []).size(), "art manifest covers chapter battle backgrounds")
	for chapter_id in map_generation_data.get("chapter_sequence", []):
		var chapter_id_string: String = str(chapter_id)
		var background_slot: Dictionary = battle_background_slots_by_id.get(chapter_id_string, {})
		_validate_art_slot(background_slot, "battle background slot %s" % chapter_id_string, "res://assets/art/backgrounds/")
		_validate_svg_art_quality(str(background_slot.get("asset_path", "")), "battle background art quality: %s" % chapter_id_string, 16, true)

	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		var card_id: String = str(card_dict.get("id", ""))
		_check(card_dict.has("design_note"), "card has design_note: %s" % card_dict.get("id", "unknown"))
		_check(card_dict.has("balance_note"), "card has balance_note: %s" % card_dict.get("id", "unknown"))
		_check(card_dict.has("upgrade_note"), "card has upgrade_note: %s" % card_dict.get("id", "unknown"))
		var card_art_slot: Dictionary = card_art_slots_by_id.get(card_id, {})
		_validate_art_slot(card_art_slot, "card art slot %s" % card_id, "res://assets/art/cards/")
		_validate_svg_art_quality(str(card_art_slot.get("asset_path", "")), "card art quality: %s" % card_id, 10, true)
		for character_id_value in card_dict.get("character_ids", []):
			var card_character_id: String = str(character_id_value)
			_check(character_ids.has(card_character_id), "card character_ids references playable character: %s" % card_dict.get("id", "unknown"))
			exclusive_card_count_by_character[card_character_id] = int(exclusive_card_count_by_character.get(card_character_id, 0)) + 1
	for character_id in exclusive_card_count_by_character.keys():
		if str(character_id) == "arc_tinker":
			_check(int(exclusive_card_count_by_character.get(character_id, 0)) >= 10, "arc tinker has a ten-card dedicated pool")
		if str(character_id) == "pyre_ascetic":
			_check(int(exclusive_card_count_by_character.get(character_id, 0)) >= 9, "pyre ascetic has a dedicated card pool")

	_check(vfx_profiles_by_id.size() >= 4, "vfx profile config has enough profiles")
	for card_type in ["attack", "skill", "power", "default"]:
		var profile_id: String = str(vfx_data.get("card_type_profiles", {}).get(card_type, ""))
		_check(vfx_profiles_by_id.has(profile_id), "vfx card type mapping references profile: %s" % card_type)
	for event_type in ["enemy_hit", "player_hit", "enemy_defeated", "phase"]:
		var feedback_profile_id: String = str(vfx_data.get("feedback_event_profiles", {}).get(event_type, ""))
		_check(vfx_profiles_by_id.has(feedback_profile_id), "vfx feedback event mapping references profile: %s" % event_type)
		_check(int(vfx_profiles_by_id.get(feedback_profile_id, {}).get("ray_count", 0)) > 0, "vfx feedback profile has ray_count: %s" % event_type)
	for profile_id in vfx_profiles_by_id.keys():
		var profile: Dictionary = vfx_profiles_by_id.get(profile_id, {})
		_check(profile.has("display_name"), "vfx profile has display_name: %s" % profile_id)
		_check(profile.has("effect_shape"), "vfx profile has effect_shape: %s" % profile_id)
		_check(int(profile.get("particle_count", 0)) > 0, "vfx profile has positive particle_count: %s" % profile_id)
		_check(profile.get("color", []).size() == 4, "vfx profile has RGBA color: %s" % profile_id)
		_check(audio_profiles.has(str(profile.get("audio_event", ""))), "vfx profile audio event exists: %s" % profile_id)
		_check(_resource_or_svg_file_exists(str(profile.get("sprite_path", ""))), "vfx profile sprite exists: %s" % profile_id)
		_check(float(profile.get("sprite_scale", 0.0)) > 0.0, "vfx profile has positive sprite_scale: %s" % profile_id)
		_check(float(profile.get("sprite_duration", 0.0)) > 0.0, "vfx profile has positive sprite_duration: %s" % profile_id)
		_check(profile.has("design_note"), "vfx profile has design_note: %s" % profile_id)
		_check(profile.has("balance_note"), "vfx profile has balance_note: %s" % profile_id)
		_check(profile.has("implementation_note"), "vfx profile has implementation_note: %s" % profile_id)

	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		var relic_id: String = str(relic_dict.get("id", ""))
		_check(relic_dict.has("design_note"), "relic has design_note: %s" % relic_dict.get("id", "unknown"))
		_check(relic_dict.has("balance_note"), "relic has balance_note: %s" % relic_dict.get("id", "unknown"))
		_check(relic_dict.has("implementation_note"), "relic has implementation_note: %s" % relic_dict.get("id", "unknown"))
		var relic_icon_slot: Dictionary = relic_icon_slots_by_id.get(relic_id, {})
		_validate_art_slot(relic_icon_slot, "relic icon slot %s" % relic_id, "res://assets/art/relics/")
		_validate_svg_art_quality(str(relic_icon_slot.get("asset_path", "")), "relic icon art quality: %s" % relic_id, 10, true)
		for character_id_value in relic_dict.get("character_ids", []):
			var relic_character_id: String = str(character_id_value)
			_check(character_ids.has(relic_character_id), "relic character_ids references playable character: %s" % relic_dict.get("id", "unknown"))
			exclusive_relic_count_by_character[relic_character_id] = int(exclusive_relic_count_by_character.get(relic_character_id, 0)) + 1
	for character_id in exclusive_relic_count_by_character.keys():
		if str(character_id) == "arc_tinker":
			_check(int(exclusive_relic_count_by_character.get(character_id, 0)) >= 3, "arc tinker has dedicated relics")
		if str(character_id) == "pyre_ascetic":
			_check(int(exclusive_relic_count_by_character.get(character_id, 0)) >= 4, "pyre ascetic has dedicated relics")

	_check(event_data.get("events", []).size() >= 10, "first chapter has at least 10 events")
	for chapter_id in map_generation_data.get("chapter_sequence", ["chapter_one"]):
		var chapter_config: Dictionary = map_generation_data.get(str(chapter_id), {})
		for event_id in chapter_config.get("event_pool", []):
			_check(events_by_id.has(str(event_id)), "%s event pool references existing event: %s" % [str(chapter_id), str(event_id)])
		for encounter_type in chapter_config.get("encounter_by_type", {}).keys():
			for encounter_id in chapter_config.get("encounter_by_type", {}).get(encounter_type, []):
				_check(encounters_by_id.has(str(encounter_id)), "%s %s pool references existing encounter" % [str(chapter_id), str(encounter_type)])

	for encounter in encounter_data.get("encounters", []):
		var encounter_dict: Dictionary = encounter
		_check(encounter_dict.has("design_note"), "encounter has design_note: %s" % encounter_dict.get("id", "unknown"))
		_check(encounter_dict.has("balance_note"), "encounter has balance_note: %s" % encounter_dict.get("id", "unknown"))
		for enemy_id in encounter_dict.get("enemy_ids", []):
			_check(enemies_by_id.has(str(enemy_id)), "encounter references existing enemy: %s" % str(enemy_id))

	for event in event_data.get("events", []):
		var event_dict: Dictionary = event
		var event_id: String = str(event_dict.get("id", ""))
		_check(event_dict.has("design_note"), "event has design_note: %s" % event_dict.get("id", "unknown"))
		_check(event_dict.has("balance_note"), "event has balance_note: %s" % event_dict.get("id", "unknown"))
		var event_art_slot: Dictionary = event_art_slots_by_id.get(event_id, {})
		_validate_art_slot(event_art_slot, "event art slot %s" % event_id, "res://assets/art/events/")
		_validate_svg_art_quality(str(event_art_slot.get("asset_path", "")), "event art quality: %s" % event_id, 12, true)
		for character_id_value in event_dict.get("character_ids", []):
			var event_character_id: String = str(character_id_value)
			_check(character_ids.has(event_character_id), "event character_ids references playable character: %s" % event_dict.get("id", "unknown"))
			exclusive_event_count_by_character[event_character_id] = int(exclusive_event_count_by_character.get(event_character_id, 0)) + 1
		_validate_event_conditions(event_dict.get("availability_conditions", []), cards_by_id, relics_by_id, events_by_id, "event availability %s" % event_id)
		for choice in event_dict.get("choices", []):
			var choice_dict: Dictionary = choice
			_validate_event_effects(choice_dict.get("effects", []), cards_by_id, relics_by_id, potions_by_id, events_by_id, "event choice %s" % choice_dict.get("id", "unknown"))
			_validate_event_conditions(choice_dict.get("conditions", []), cards_by_id, relics_by_id, events_by_id, "event choice %s" % choice_dict.get("id", "unknown"))
			for result in choice_dict.get("random_results", []):
				var result_dict: Dictionary = result
				_check(result_dict.has("id"), "random event result has id")
				_check(int(result_dict.get("weight", 0)) >= 0, "random event result has non-negative weight")
				_validate_event_effects(result_dict.get("effects", []), cards_by_id, relics_by_id, potions_by_id, events_by_id, "random event result %s" % result_dict.get("id", "unknown"))
	for character_id in exclusive_event_count_by_character.keys():
		if str(character_id) == "arc_tinker":
			_check(int(exclusive_event_count_by_character.get(character_id, 0)) >= 3, "arc tinker has dedicated events")
		if str(character_id) == "pyre_ascetic":
			_check(int(exclusive_event_count_by_character.get(character_id, 0)) >= 3, "pyre ascetic has dedicated events")

	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		var potion_id: String = str(potion_dict.get("id", ""))
		_check(potion_dict.has("design_note"), "potion has design_note: %s" % potion_dict.get("id", "unknown"))
		_check(potion_dict.has("balance_note"), "potion has balance_note: %s" % potion_dict.get("id", "unknown"))
		_check(potion_dict.has("implementation_note"), "potion has implementation_note: %s" % potion_dict.get("id", "unknown"))
		var potion_icon_slot: Dictionary = potion_icon_slots_by_id.get(potion_id, {})
		_validate_art_slot(potion_icon_slot, "potion icon slot %s" % potion_id, "res://assets/art/potions/")
		_validate_svg_art_quality(str(potion_icon_slot.get("asset_path", "")), "potion icon art quality: %s" % potion_id, 10, true)

	for enemy in enemy_data.get("enemies", []):
		var enemy_dict: Dictionary = enemy
		var sprite_key: String = str(enemy_dict.get("sprite_key", ""))
		var enemy_art_path: String = _enemy_art_path(sprite_key)
		_check(not sprite_key.is_empty(), "enemy has sprite_key: %s" % enemy_dict.get("id", "unknown"))
		_check(_resource_or_svg_file_exists(enemy_art_path), "enemy sprite art exists: %s" % sprite_key)
		_validate_svg_art_quality(enemy_art_path, "enemy sprite art quality: %s" % sprite_key, 12, true)
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

	if failed:
		quit(1)
		return
	print("Data integrity smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)

func _enemy_art_path(sprite_key: String) -> String:
	if sprite_key == "placeholder_ash_hound":
		return "res://assets/art/generated/enemy_ash_hound_v3_pc.png"
	if sprite_key == "placeholder_twinblade_executor":
		return "res://assets/art/generated/enemy_twinblade_executor_v2_pc.png"
	if sprite_key == "placeholder_forge_bishop":
		return "res://assets/art/generated/enemy_forge_bishop_v2_pc.png"
	if sprite_key == "placeholder_plague_alchemist":
		return "res://assets/art/generated/enemy_plague_alchemist_v2_pc.png"
	if sprite_key == "placeholder_bomb_mite":
		return "res://assets/art/generated/enemy_bomb_mite_v2_pc.png"
	if sprite_key.begins_with("placeholder_"):
		return "res://assets/art/enemy_%s.svg" % sprite_key.trim_prefix("placeholder_")
	return "res://assets/art/enemy_%s.svg" % sprite_key

func _validate_art_slot(slot: Dictionary, context: String, expected_slot_prefix: String) -> void:
	_check(not slot.is_empty(), "%s exists" % context)
	_check(_resource_or_svg_file_exists(str(slot.get("asset_path", ""))), "%s current asset_path exists" % context)
	_check(str(slot.get("slot_path", "")).begins_with(expected_slot_prefix), "%s has stable replacement slot_path" % context)
	_check(slot.has("design_note"), "%s has design_note" % context)
	_check(slot.has("replacement_note"), "%s has replacement_note" % context)
	_check(slot.has("implementation_note"), "%s has implementation_note" % context)

func _validate_svg_art_quality(path: String, context: String, min_shape_count: int, require_gradient: bool) -> void:
	if _is_raster_art_path(path):
		_validate_raster_art_quality(path, context)
		return
	if not path.ends_with(".svg"):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "%s svg can be read" % context)
	if file == null:
		return
	var svg: String = file.get_as_text()
	_check(svg.length() >= 800, "%s svg has enough source detail" % context)
	if require_gradient:
		_check(svg.find("<linearGradient") != -1 or svg.find("<radialGradient") != -1, "%s svg uses gradient lighting" % context)
	var shape_count: int = 0
	for token in ["<path", "<rect", "<circle", "<ellipse", "<polygon", "<polyline", "<line"]:
		shape_count += _count_substring(svg, token)
	_check(shape_count >= min_shape_count, "%s svg has layered shape detail" % context)

func _resource_or_svg_file_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		return true
	return (path.ends_with(".svg") or _is_raster_art_path(path)) and FileAccess.file_exists(path)

func _is_raster_art_path(path: String) -> bool:
	return path.ends_with(".png") or path.ends_with(".jpg") or path.ends_with(".jpeg") or path.ends_with(".webp")

func _validate_raster_art_quality(path: String, context: String) -> void:
	var image := Image.new()
	var error: Error = image.load(path)
	_check(error == OK, "%s raster can be read" % context)
	if error != OK:
		return
	_check(image.get_width() >= 512, "%s raster has usable width" % context)
	_check(image.get_height() >= 512, "%s raster has usable height" % context)

func _validate_wav_asset(path: String, context: String) -> void:
	_check(path.begins_with("res://assets/audio/"), "%s uses audio asset path" % context)
	_check(path.ends_with(".wav"), "%s uses wav extension" % context)
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "%s can be read" % context)
	if file == null:
		return
	_check(file.get_length() > 1000, "%s has non-empty audio data" % context)
	var header: PackedByteArray = file.get_buffer(12)
	_check(header.size() == 12, "%s has wav header" % context)
	if header.size() == 12:
		_check(header.slice(0, 4).get_string_from_ascii() == "RIFF", "%s has RIFF header" % context)
		_check(header.slice(8, 12).get_string_from_ascii() == "WAVE", "%s has WAVE format" % context)

func _count_substring(text: String, needle: String) -> int:
	var count: int = 0
	var start: int = 0
	while true:
		var found: int = text.find(needle, start)
		if found == -1:
			break
		count += 1
		start = found + needle.length()
	return count

func _validate_rarity_weights(weights: Dictionary, context: String) -> void:
	_check(not weights.is_empty(), "%s exists" % context)
	var total_weight: int = 0
	for rarity in ["common", "uncommon", "rare"]:
		var weight: int = int(weights.get(rarity, 0))
		_check(weight > 0, "%s has positive %s weight" % [context, rarity])
		total_weight += weight
	_check(total_weight == 100, "%s sum to 100" % context)

func _validate_price_table(prices: Dictionary, context: String) -> void:
	_check(not prices.is_empty(), "%s exists" % context)
	for rarity in ["common", "uncommon", "rare"]:
		_check(int(prices.get(rarity, 0)) > 0, "%s has positive %s price" % [context, rarity])

func _validate_combat_gold_rewards(config: Dictionary) -> void:
	_check(not config.is_empty(), "combat gold reward config exists")
	var by_tier: Dictionary = config.get("by_tier", {})
	for tier in ["normal", "elite", "boss"]:
		var tier_range: Dictionary = by_tier.get(tier, {})
		var min_gold: int = int(tier_range.get("min", -1))
		var max_gold: int = int(tier_range.get("max", -1))
		_check(min_gold >= 0, "combat gold %s minimum is non-negative" % tier)
		_check(max_gold >= min_gold, "combat gold %s range is valid" % tier)
	var chapter_bonus: Dictionary = config.get("chapter_bonus", {})
	for chapter_id in ["chapter_one", "chapter_two", "chapter_three"]:
		_check(int(chapter_bonus.get(chapter_id, -1)) >= 0, "combat gold chapter bonus exists: %s" % chapter_id)
	_check(not str(config.get("design_note", "")).is_empty(), "combat gold config has design note")
	_check(not str(config.get("balance_note", "")).is_empty(), "combat gold config has balance note")
	_check(not str(config.get("implementation_note", "")).is_empty(), "combat gold config has implementation note")

func _validate_card_balance_budgets(config: Dictionary, cards: Array) -> void:
	_check(not config.is_empty(), "card balance budget config exists")
	var allowed_cost_range: Array = config.get("allowed_cost_range", [])
	_check(allowed_cost_range.size() == 2, "card balance budget has allowed cost range")
	var min_cost: int = int(allowed_cost_range[0]) if allowed_cost_range.size() == 2 else 0
	var max_cost: int = int(allowed_cost_range[1]) if allowed_cost_range.size() == 2 else 3
	var budgets: Dictionary = config.get("cost_budgets", {})
	for cost in range(min_cost, max_cost + 1):
		var budget: Dictionary = budgets.get(str(cost), {})
		_check(not budget.is_empty(), "card balance budget exists for cost %d" % cost)
		_check(int(budget.get("single_damage_max", 0)) > 0, "card balance single damage cap is positive for cost %d" % cost)
		_check(int(budget.get("all_damage_max", 0)) >= 0, "card balance all damage cap is non-negative for cost %d" % cost)
		_check(int(budget.get("block_max", 0)) >= 0, "card balance block cap is non-negative for cost %d" % cost)
	for card_value in cards:
		var card: Dictionary = card_value
		var card_id: String = str(card.get("id", ""))
		var card_type: String = str(card.get("type", ""))
		if card_type in ["status", "curse"]:
			continue
		var cost: int = int(card.get("cost", -1))
		_check(cost >= min_cost and cost <= max_cost, "card cost fits configured range: %s" % card_id)
		var budget: Dictionary = budgets.get(str(cost), {})
		if budget.is_empty():
			continue
		var direct_single_damage: int = 0
		var direct_all_damage: int = 0
		var direct_block: int = 0
		for effect_value in card.get("effects", []):
			var effect: Dictionary = effect_value
			match str(effect.get("type", "")):
				"damage":
					var amount: int = int(effect.get("amount", 0)) * max(1, int(effect.get("hits", 1)))
					if str(effect.get("target", card.get("target", "enemy"))) == "all_enemies":
						direct_all_damage += amount
					else:
						direct_single_damage += amount
				"block":
					direct_block += int(effect.get("amount", 0))
		var has_downside: bool = _card_has_budget_downside(card, config.get("over_budget_downside_effect_types", []))
		_check(direct_single_damage <= int(budget.get("single_damage_max", 0)) or has_downside, "card single damage fits budget or has explicit downside: %s" % card_id)
		_check(direct_all_damage <= int(budget.get("all_damage_max", 0)) or has_downside, "card all-enemy damage fits budget or has explicit downside: %s" % card_id)
		_check(direct_block <= int(budget.get("block_max", 0)) or has_downside, "card block fits budget or has explicit downside: %s" % card_id)
	_check(not str(config.get("design_note", "")).is_empty(), "card balance budget has design note")
	_check(not str(config.get("balance_note", "")).is_empty(), "card balance budget has balance note")
	_check(not str(config.get("implementation_note", "")).is_empty(), "card balance budget has implementation note")

func _card_has_budget_downside(card: Dictionary, allowed_types: Array) -> bool:
	for effect_value in card.get("effects", []):
		var effect: Dictionary = effect_value
		var effect_type: String = str(effect.get("type", ""))
		if not allowed_types.has(effect_type):
			continue
		if effect_type == "apply_status":
			if str(effect.get("target", "self")) == "self" and str(effect.get("status", "")) in ["vulnerable", "frail", "weak", "burn"]:
				return true
			continue
		if effect_type == "create_card":
			if str(effect.get("card_id", "")) == "searing_wound":
				return true
			continue
		return true
	return false

func _validate_progression_systems(progression_data: Dictionary, character_ids: Dictionary) -> void:
	_check(not progression_data.is_empty(), "progression system config exists")
	var currency: Dictionary = progression_data.get("currency", {})
	_check(str(currency.get("id", "")) == "forge_marks", "progression currency uses forge marks")
	_check(int(currency.get("boss_reward", 0)) > 0, "boss forge mark reward is positive")
	_check(int(currency.get("full_run_bonus", 0)) > 0, "full run forge mark reward is positive")
	_check(not str(currency.get("design_note", "")).is_empty(), "progression currency has design note")
	_check(not str(currency.get("balance_note", "")).is_empty(), "progression currency has balance note")

	var trees: Array = progression_data.get("character_trees", [])
	_check(trees.size() == character_ids.size(), "progression has one character tree per playable character")
	var seen_tree_characters: Dictionary = {}
	var known_node_ids: Dictionary = {}
	for tree_value in trees:
		var tree: Dictionary = tree_value
		var character_id: String = str(tree.get("character_id", ""))
		_check(character_ids.has(character_id), "character tree references playable character: %s" % character_id)
		_check(not seen_tree_characters.has(character_id), "character tree is unique: %s" % character_id)
		seen_tree_characters[character_id] = true
		_check(not str(tree.get("name", "")).is_empty(), "character tree has name: %s" % character_id)
		var nodes: Array = tree.get("nodes", [])
		_check(nodes.size() == 3, "character tree has three nodes: %s" % character_id)
		var local_node_ids: Dictionary = {}
		for node_value in nodes:
			var node: Dictionary = node_value
			var node_id: String = str(node.get("id", ""))
			_check(not node_id.is_empty(), "character tree node has id: %s" % character_id)
			_check(not known_node_ids.has(node_id), "character tree node id is globally unique: %s" % node_id)
			_check(not local_node_ids.has(node_id), "character tree node id is unique in tree: %s" % node_id)
			known_node_ids[node_id] = true
			local_node_ids[node_id] = true
			_check(int(node.get("cost", 0)) > 0, "character tree node has positive cost: %s" % node_id)
			_check(not str(node.get("name", "")).is_empty(), "character tree node has name: %s" % node_id)
			_check(not str(node.get("description", "")).is_empty(), "character tree node has description: %s" % node_id)
			_check(not str(node.get("design_note", "")).is_empty(), "character tree node has design note: %s" % node_id)
			_check(not str(node.get("balance_note", "")).is_empty(), "character tree node has balance note: %s" % node_id)
			_check(not node.get("effects", []).is_empty(), "character tree node has effects: %s" % node_id)
			for effect_value in node.get("effects", []):
				var effect: Dictionary = effect_value
				_check(str(effect.get("type", "")) in ["max_hp_bonus", "starting_gold_bonus", "starting_momentum_bonus", "potion_slot_bonus", "combat_start_block"], "character tree node uses supported effect: %s" % node_id)
				_check(int(effect.get("amount", 0)) > 0, "character tree effect has positive amount: %s" % node_id)
	for tree_value in trees:
		var tree: Dictionary = tree_value
		for node_value in tree.get("nodes", []):
			var node: Dictionary = node_value
			for prerequisite_value in node.get("prerequisites", []):
				var prerequisite_id: String = str(prerequisite_value)
				_check(known_node_ids.has(prerequisite_id), "character tree prerequisite exists: %s" % prerequisite_id)
				_check(prerequisite_id != str(node.get("id", "")), "character tree node cannot require itself: %s" % prerequisite_id)
	for character_id_value in character_ids.keys():
		_check(seen_tree_characters.has(str(character_id_value)), "playable character has progression tree: %s" % str(character_id_value))

	var skill_books: Array = progression_data.get("skill_books", [])
	_check(skill_books.size() == 4, "progression has four skill books")
	var skill_book_ids: Dictionary = {}
	for book_value in skill_books:
		var book: Dictionary = book_value
		var book_id: String = str(book.get("id", ""))
		_check(not book_id.is_empty(), "skill book has id")
		_check(not skill_book_ids.has(book_id), "skill book id is unique: %s" % book_id)
		skill_book_ids[book_id] = true
		_check(not str(book.get("name", "")).is_empty(), "skill book has name: %s" % book_id)
		_check(not str(book.get("description", "")).is_empty(), "skill book has description: %s" % book_id)
		_check(not str(book.get("design_note", "")).is_empty(), "skill book has design note: %s" % book_id)
		_check(not str(book.get("balance_note", "")).is_empty(), "skill book has balance note: %s" % book_id)
		_validate_progression_unlock(book.get("unlock", {}), "skill book %s" % book_id)
		_validate_rule_source_effects(book.get("effects", []), "skill book %s" % book_id)

	var masteries: Array = progression_data.get("deck_masteries", [])
	_check(masteries.size() == 4, "progression has four deck masteries")
	var mastery_ids: Dictionary = {}
	for mastery_value in masteries:
		var mastery: Dictionary = mastery_value
		var mastery_id: String = str(mastery.get("id", ""))
		_check(not mastery_id.is_empty(), "deck mastery has id")
		_check(not mastery_ids.has(mastery_id), "deck mastery id is unique: %s" % mastery_id)
		mastery_ids[mastery_id] = true
		_check(not str(mastery.get("name", "")).is_empty(), "deck mastery has name: %s" % mastery_id)
		_check(not str(mastery.get("description", "")).is_empty(), "deck mastery has description: %s" % mastery_id)
		_check(not str(mastery.get("design_note", "")).is_empty(), "deck mastery has design note: %s" % mastery_id)
		_check(not str(mastery.get("balance_note", "")).is_empty(), "deck mastery has balance note: %s" % mastery_id)
		_validate_mastery_requirements(mastery.get("requirements", {}), "deck mastery %s" % mastery_id)
		_validate_rule_source_effects(mastery.get("effects", []), "deck mastery %s" % mastery_id)

func _validate_progression_unlock(unlock: Dictionary, context: String) -> void:
	match str(unlock.get("type", "")):
		"default":
			pass
		"chapter_completed":
			_check(["chapter_one", "chapter_two", "chapter_three"].has(str(unlock.get("chapter_id", ""))), "%s unlock references known chapter" % context)
		_:
			_check(false, "%s has a supported unlock condition" % context)

func _validate_mastery_requirements(requirements: Dictionary, context: String) -> void:
	_check(not requirements.is_empty(), "%s has requirements" % context)
	if requirements.has("min_type_count"):
		var type_counts: Dictionary = requirements.get("min_type_count", {})
		_check(type_counts.size() == 1, "%s has one card type requirement" % context)
		for card_type_value in type_counts.keys():
			_check(["attack", "skill", "power"].has(str(card_type_value)), "%s references supported card type" % context)
			_check(int(type_counts.get(card_type_value, 0)) > 0, "%s type requirement is positive" % context)
	elif requirements.has("min_zero_cost_cards") or requirements.has("min_burn_creator_cards"):
		var requirement_key: String = "min_zero_cost_cards" if requirements.has("min_zero_cost_cards") else "min_burn_creator_cards"
		_check(int(requirements.get(requirement_key, 0)) > 0, "%s numeric requirement is positive" % context)
	else:
		_check(false, "%s has supported requirements" % context)

func _validate_rule_source_effects(effects: Array, context: String) -> void:
	_check(not effects.is_empty(), "%s has effects" % context)
	for effect_value in effects:
		var effect: Dictionary = effect_value
		_check(["combat_start", "card_played", "block_gained", "card_created"].has(str(effect.get("trigger", ""))), "%s uses supported trigger" % context)
		_check(["gain_block", "draw", "bonus_damage", "gain_momentum", "damage_all_enemies"].has(str(effect.get("type", ""))), "%s uses supported effect" % context)
		_check(int(effect.get("amount", 0)) > 0, "%s effect amount is positive" % context)
		if effect.has("card_cost_equals"):
			_check(int(effect.get("card_cost_equals", -1)) >= 0, "%s cost condition is non-negative" % context)
		if effect.has("card_type"):
			_check(["attack", "skill", "power"].has(str(effect.get("card_type", ""))), "%s card type condition is supported" % context)
		if effect.has("once_per_turn"):
			_check(bool(effect.get("once_per_turn")), "%s once per turn flag is true when present" % context)
		if effect.has("once_per_combat"):
			_check(bool(effect.get("once_per_combat")), "%s once per combat flag is true when present" % context)

func _validate_monster_scaling(monster_scaling_data: Dictionary, level_tree_data: Dictionary, map_generation_data: Dictionary, encounter_data: Dictionary, enemies_by_id: Dictionary) -> void:
	_check(not monster_scaling_data.is_empty(), "monster scaling config exists")
	var chapters: Dictionary = monster_scaling_data.get("chapters", {})
	var encounter_by_id: Dictionary = DataLoaderScript.index_by_id(encounter_data.get("encounters", []))
	for chapter_id_value in map_generation_data.get("chapter_sequence", []):
		var chapter_id: String = str(chapter_id_value)
		var chapter_budgets: Dictionary = chapters.get(chapter_id, {})
		_check(not chapter_budgets.is_empty(), "monster scaling has chapter budgets: %s" % chapter_id)
		for tier in ["normal", "elite", "boss"]:
			var budget: Dictionary = chapter_budgets.get(tier, {})
			_check(not budget.is_empty(), "monster scaling has %s budget for %s" % [tier, chapter_id])
			var hp_min: int = int(budget.get("hp_min", 0))
			var hp_max: int = int(budget.get("hp_max", 0))
			_check(hp_min > 0 and hp_max >= hp_min, "monster scaling HP range is valid: %s %s" % [chapter_id, tier])
			_check(int(budget.get("max_action_damage", 0)) > 0, "monster scaling has peak damage cap: %s %s" % [chapter_id, tier])
			_check(int(budget.get("max_block", -1)) >= 0, "monster scaling has block cap: %s %s" % [chapter_id, tier])
			_check(int(budget.get("expected_turns_min", 0)) > 0 and int(budget.get("expected_turns_max", 0)) >= int(budget.get("expected_turns_min", 0)), "monster scaling has valid expected turn range: %s %s" % [chapter_id, tier])
		var map_chapter: Dictionary = map_generation_data.get(chapter_id, {})
		for encounter_tier_value in map_chapter.get("encounter_by_type", {}).keys():
			var map_node_type: String = str(encounter_tier_value)
			var encounter_tier: String = "normal" if map_node_type == "combat" else map_node_type
			var budget: Dictionary = chapter_budgets.get(encounter_tier, {})
			for encounter_id_value in map_chapter.get("encounter_by_type", {}).get(map_node_type, []):
				var encounter_id: String = str(encounter_id_value)
				var encounter: Dictionary = encounter_by_id.get(encounter_id, {})
				_check(not encounter.is_empty(), "scaling encounter exists: %s" % encounter_id)
				_check(str(encounter.get("tier", "")) == encounter_tier, "scaling encounter tier matches map pool: %s" % encounter_id)
				_validate_encounter_against_budget(encounter, budget, enemies_by_id, "%s %s" % [chapter_id, encounter_id])
	_validate_level_tree(level_tree_data, map_generation_data)
	var constraints: Dictionary = monster_scaling_data.get("encounter_constraints", {})
	_check(int(constraints.get("max_normal_enemy_count", 0)) >= 1, "scaling has normal encounter count cap")
	_check(int(constraints.get("max_elite_enemy_count", 0)) >= 1, "scaling has elite encounter count cap")
	_check(float(constraints.get("two_enemy_peak_damage_multiplier", 0.0)) >= 1.0, "scaling has two enemy pressure multiplier")
	_check(int(constraints.get("boss_phase_enter_max_effect_categories", 0)) >= 1, "scaling limits boss phase entry pressure")
	_check(not str(constraints.get("design_note", "")).is_empty(), "scaling constraints have design note")
	_check(not str(constraints.get("balance_note", "")).is_empty(), "scaling constraints have balance note")

func _validate_encounter_against_budget(encounter: Dictionary, budget: Dictionary, enemies_by_id: Dictionary, context: String) -> void:
	for enemy_id_value in encounter.get("enemy_ids", []):
		var enemy_id: String = str(enemy_id_value)
		var enemy: Dictionary = enemies_by_id.get(enemy_id, {})
		_check(not enemy.is_empty(), "%s references enemy for scaling" % context)
		if enemy.is_empty():
			continue
		var hp: int = int(enemy.get("max_hp", 0))
		_check(hp >= int(budget.get("hp_min", 0)) and hp <= int(budget.get("hp_max", 0)), "%s enemy HP fits chapter/tier budget: %s" % [context, enemy_id])
		var peak_damage: int = _peak_enemy_action_damage(enemy)
		_check(peak_damage <= int(budget.get("max_action_damage", 0)), "%s enemy peak action damage fits budget: %s" % [context, enemy_id])
		var peak_block: int = _peak_enemy_block(enemy)
		_check(peak_block <= int(budget.get("max_block", 0)), "%s enemy peak block fits budget: %s" % [context, enemy_id])

func _peak_enemy_action_damage(enemy: Dictionary) -> int:
	var peak: int = 0
	for action_value in enemy.get("actions", []):
		peak = max(peak, _action_damage(action_value))
	for phase_value in enemy.get("phases", []):
		var phase: Dictionary = phase_value
		for action_value in phase.get("actions", []):
			peak = max(peak, _action_damage(action_value))
	return peak

func _peak_enemy_block(enemy: Dictionary) -> int:
	var peak: int = 0
	for action_value in enemy.get("actions", []):
		peak = max(peak, _action_block(action_value))
	for phase_value in enemy.get("phases", []):
		var phase: Dictionary = phase_value
		for action_value in phase.get("actions", []):
			peak = max(peak, _action_block(action_value))
		for effect_value in phase.get("on_enter_effects", []):
			var effect: Dictionary = effect_value
			if str(effect.get("type", "")) == "block":
				peak = max(peak, int(effect.get("amount", 0)))
	return peak

func _action_damage(action_value: Variant) -> int:
	var action: Dictionary = action_value
	var total: int = 0
	for effect_value in action.get("effects", []):
		var effect: Dictionary = effect_value
		if str(effect.get("type", "")) == "damage" and str(effect.get("target", "")) == "player":
			total += int(effect.get("amount", 0)) * max(1, int(effect.get("hits", 1)))
	return total

func _action_block(action_value: Variant) -> int:
	var action: Dictionary = action_value
	var total: int = 0
	for effect_value in action.get("effects", []):
		var effect: Dictionary = effect_value
		if str(effect.get("type", "")) == "block":
			total += int(effect.get("amount", 0))
	return total

func _validate_level_tree(level_tree_data: Dictionary, map_generation_data: Dictionary) -> void:
	_check(not level_tree_data.is_empty(), "level tree config exists")
	var chapters: Dictionary = level_tree_data.get("chapters", {})
	for chapter_id_value in map_generation_data.get("chapter_sequence", []):
		var chapter_id: String = str(chapter_id_value)
		var config: Dictionary = chapters.get(chapter_id, {})
		var map_chapter: Dictionary = map_generation_data.get(chapter_id, {})
		_check(not config.is_empty(), "level tree has chapter config: %s" % chapter_id)
		_check(int(config.get("layers", 0)) == int(map_chapter.get("layers", -1)), "level tree layers match map generation: %s" % chapter_id)
		_check(int(config.get("early_elite_latest_layer", -1)) >= 0, "level tree defines early elite bound: %s" % chapter_id)
		_check(int(config.get("early_elite_max_count", -1)) >= 0, "level tree defines early elite count cap: %s" % chapter_id)
		_check(int(config.get("boss_safe_window_layers", 0)) >= 1, "level tree defines boss safe window: %s" % chapter_id)
		var node_budget: Dictionary = config.get("node_budget", {})
		for node_type in ["combat", "elite", "campfire", "shop", "event", "treasure", "boss"]:
			var range: Array = node_budget.get(node_type, [])
			_check(range.size() == 2, "level tree has %s node range: %s" % [node_type, chapter_id])
			if range.size() == 2:
				_check(int(range[0]) >= 0 and int(range[1]) >= int(range[0]), "level tree %s node range is valid: %s" % [node_type, chapter_id])
	var route_constraints: Dictionary = level_tree_data.get("route_constraints", {})
	_check(int(route_constraints.get("minimum_branching_layers", 0)) >= 1, "level tree has branching layer requirement")
	_check(int(route_constraints.get("minimum_choices_on_branch_layer", 0)) >= 2, "level tree has branching choice requirement")
	_check(route_constraints.has("no_forced_elite_after_treasure"), "level tree specifies treasure-to-elite constraint")
	_check(route_constraints.has("require_campfire_or_shop_before_boss"), "level tree specifies pre-boss recovery constraint")
	_check(not str(route_constraints.get("design_note", "")).is_empty(), "level tree has design note")
	_check(not str(route_constraints.get("balance_note", "")).is_empty(), "level tree has balance note")

func _validate_achievement_condition(condition: Dictionary, character_ids: Dictionary, map_generation_data: Dictionary, context: String) -> void:
	_check(not condition.is_empty(), "%s has condition" % context)
	match str(condition.get("type", "")):
		"runs_started_at_least", "runs_completed_at_least", "bosses_defeated_at_least", "cards_removed_at_least", "challenge_completed_at_least":
			_check(int(condition.get("amount", 0)) > 0, "%s count condition has positive amount" % context)
		"chapter_completed":
			var chapter_id: String = str(condition.get("chapter_id", ""))
			_check(map_generation_data.get("chapter_sequence", []).has(chapter_id), "%s references configured chapter" % context)
		"character_completed":
			_check(character_ids.has(str(condition.get("character_id", ""))), "%s references playable character" % context)
		_:
			_check(false, "%s has known achievement condition type" % context)

func _validate_challenge_levels(levels: Array) -> void:
	_check(levels.size() >= 4, "challenge config has base and first three challenge levels")
	var seen_levels: Dictionary = {}
	for challenge in levels:
		var challenge_dict: Dictionary = challenge
		var level: int = int(challenge_dict.get("level", -1))
		_check(level >= 0, "challenge level is non-negative")
		_check(not seen_levels.has(level), "challenge level is unique: %d" % level)
		seen_levels[level] = true
		_check(challenge_dict.has("name"), "challenge has name: %d" % level)
		_check(challenge_dict.has("short_name"), "challenge has short_name: %d" % level)
		_check(challenge_dict.has("description"), "challenge has description: %d" % level)
		_check(challenge_dict.has("reward_note"), "challenge has reward_note: %d" % level)
		_check(challenge_dict.has("design_note"), "challenge has design_note: %d" % level)
		_check(challenge_dict.has("balance_note"), "challenge has balance_note: %d" % level)
		_check(challenge_dict.has("implementation_note"), "challenge has implementation_note: %d" % level)
		var modifiers: Dictionary = challenge_dict.get("modifiers", {})
		_check(float(modifiers.get("enemy_hp_multiplier", 0.0)) > 0.0, "challenge has positive enemy hp multiplier: %d" % level)
		_check(float(modifiers.get("enemy_damage_multiplier", 0.0)) > 0.0, "challenge has positive enemy damage multiplier: %d" % level)
		_check(int(modifiers.get("player_starting_hp_loss", -1)) >= 0, "challenge has non-negative starting hp loss: %d" % level)
	_check(seen_levels.has(0), "challenge config includes level 0")

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

func _validate_event_effects(effects: Array, cards_by_id: Dictionary, relics_by_id: Dictionary, potions_by_id: Dictionary, events_by_id: Dictionary, context: String) -> void:
	for effect in effects:
		var effect_dict: Dictionary = effect
		match str(effect_dict.get("type", "")):
			"add_card":
				_check(cards_by_id.has(str(effect_dict.get("card_id", ""))), "%s references existing card" % context)
			"gain_relic":
				_check(relics_by_id.has(str(effect_dict.get("relic_id", ""))), "%s references existing relic" % context)
			"gain_potion":
				_check(potions_by_id.has(str(effect_dict.get("potion_id", ""))), "%s references existing potion" % context)
			"complete_event":
				_check(events_by_id.has(str(effect_dict.get("event_id", ""))), "%s references existing completed event" % context)

func _validate_event_conditions(conditions: Array, cards_by_id: Dictionary, relics_by_id: Dictionary, events_by_id: Dictionary, context: String) -> void:
	for condition in conditions:
		var condition_dict: Dictionary = condition
		match str(condition_dict.get("type", "")):
			"missing_relic", "has_relic":
				_check(relics_by_id.has(str(condition_dict.get("relic_id", ""))), "%s condition references existing relic" % context)
			"deck_contains_card":
				_check(cards_by_id.has(str(condition_dict.get("card_id", ""))), "%s condition references existing card" % context)
			"event_not_completed", "event_completed":
				_check(events_by_id.has(str(condition_dict.get("event_id", ""))), "%s condition references existing event" % context)
			"min_gold", "min_hp", "has_empty_potion_slot", "has_removable_card":
				pass
			_:
				_check(false, "%s has known condition type" % context)
