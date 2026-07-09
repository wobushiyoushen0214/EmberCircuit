extends SceneTree

const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const AudioManagerScript = preload("res://scripts/core/AudioManager.gd")

const CHARACTER_ART_PATHS := {
	"ember_exile": "res://assets/art/player_ember_exile.svg",
	"arc_tinker": "res://assets/art/player_arc_tinker.svg",
	"pyre_ascetic": "res://assets/art/player_pyre_ascetic.svg"
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
	_check(int(shop_config.get("remove_card_price", 0)) > 0, "shop remove card base price is positive")
	_check(int(shop_config.get("remove_card_price_increase", 0)) > 0, "shop remove card price increase is positive")
	_check(not str(shop_config.get("remove_card_note", "")).is_empty(), "shop remove card pricing has balance note")
	_validate_rarity_weights(reward_generation.get("card_rarity_weights", {}), "combat card reward rarity weights")
	_validate_rarity_weights(reward_generation.get("shop_card_rarity_weights", {}), "shop card reward rarity weights")
	_validate_rarity_weights(reward_generation.get("relic_rarity_weights", {}), "relic reward rarity weights")
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
			_check(int(exclusive_card_count_by_character.get(character_id, 0)) >= 6, "arc tinker has a dedicated card pool")
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
		for choice in event_dict.get("choices", []):
			var choice_dict: Dictionary = choice
			_validate_event_effects(choice_dict.get("effects", []), cards_by_id, relics_by_id, potions_by_id, "event choice %s" % choice_dict.get("id", "unknown"))
			_validate_event_conditions(choice_dict.get("conditions", []), cards_by_id, relics_by_id, events_by_id, "event choice %s" % choice_dict.get("id", "unknown"))
			for result in choice_dict.get("random_results", []):
				var result_dict: Dictionary = result
				_check(result_dict.has("id"), "random event result has id")
				_check(int(result_dict.get("weight", 0)) >= 0, "random event result has non-negative weight")
				_validate_event_effects(result_dict.get("effects", []), cards_by_id, relics_by_id, potions_by_id, "random event result %s" % result_dict.get("id", "unknown"))
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
	return path.ends_with(".svg") and FileAccess.file_exists(path)

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

func _validate_event_effects(effects: Array, cards_by_id: Dictionary, relics_by_id: Dictionary, potions_by_id: Dictionary, context: String) -> void:
	for effect in effects:
		var effect_dict: Dictionary = effect
		match str(effect_dict.get("type", "")):
			"add_card":
				_check(cards_by_id.has(str(effect_dict.get("card_id", ""))), "%s references existing card" % context)
			"gain_relic":
				_check(relics_by_id.has(str(effect_dict.get("relic_id", ""))), "%s references existing relic" % context)
			"gain_potion":
				_check(potions_by_id.has(str(effect_dict.get("potion_id", ""))), "%s references existing potion" % context)

func _validate_event_conditions(conditions: Array, cards_by_id: Dictionary, relics_by_id: Dictionary, events_by_id: Dictionary, context: String) -> void:
	for condition in conditions:
		var condition_dict: Dictionary = condition
		match str(condition_dict.get("type", "")):
			"missing_relic", "has_relic":
				_check(relics_by_id.has(str(condition_dict.get("relic_id", ""))), "%s condition references existing relic" % context)
			"deck_contains_card":
				_check(cards_by_id.has(str(condition_dict.get("card_id", ""))), "%s condition references existing card" % context)
			"event_not_completed":
				_check(events_by_id.has(str(condition_dict.get("event_id", ""))), "%s condition references existing event" % context)
			"min_gold", "min_hp", "has_empty_potion_slot", "has_removable_card":
				pass
			_:
				_check(false, "%s has known condition type" % context)
