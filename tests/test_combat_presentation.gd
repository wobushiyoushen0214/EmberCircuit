extends SceneTree

var failed: bool = false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main.debug_viewport_size_override = Vector2(1280, 720)
	root.add_child(main)
	await process_frame
	await process_frame
	main._on_character_selected("ember_exile")

	var card_index := _first_playable_card(main)
	_check(card_index >= 0, "presentation fixture exposes a playable card")
	if card_index >= 0:
		var refresh_before: int = main.refresh_call_count
		main._on_card_pressed(card_index)
		_check(main.refresh_call_count == refresh_before + 1, "card impact settles through one UI refresh")
		_check(main.combat_presentation_sequence == ["card:lock", "card:windup", "card:impact", "card:resolved", "card:unlock"], "card presentation order is deterministic")
		_check(not main.combat_presentation_busy, "card input lock is released after settlement")

	var enemy_payloads: Array[Dictionary] = main._capture_enemy_action_visuals()
	var enemy_refresh_before: int = main.refresh_call_count
	main._on_end_turn_pressed()
	_check(main.refresh_call_count == enemy_refresh_before + 1, "enemy turn and next hand settle through one UI refresh")
	_check(main.combat_presentation_sequence == ["enemy:lock", "enemy:windup", "enemy:impact", "enemy:resolved", "enemy:unlock"], "enemy presentation order is deterministic")
	_check(main.last_enemy_action_animation_count == enemy_payloads.size(), "enemy windup animates each forecast actor")
	_check(not main.combat_presentation_busy and main.combat.phase == "player", "next hand is interactive only after enemy settlement")

	var energy_before_lock: int = int(main.combat.player.get("energy", 0))
	var locked_card_index := _first_playable_card(main)
	var ticket: int = main._begin_combat_presentation("test:lock")
	main._on_card_pressed(locked_card_index)
	main._on_end_turn_pressed()
	main._on_potion_pressed(0)
	_check(int(main.combat.player.get("energy", 0)) == energy_before_lock and main.combat.phase == "player", "presentation lock rejects card, turn and potion actions")
	main._end_combat_presentation(ticket, "test:unlock")

	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Combat presentation test passed.")
	quit(0)

func _first_playable_card(main) -> int:
	for index in range(main.combat.hand.size()):
		if main.combat.can_play_card(index):
			return index
	return -1

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)
