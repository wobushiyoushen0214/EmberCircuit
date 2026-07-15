extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

var failed := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var host := Control.new()
	host.size = Vector2(1280, 720)
	host.custom_minimum_size = host.size
	root.add_child(host)

	var main = scene.instantiate()
	main.debug_viewport_size_override = Vector2(1280, 720)
	host.add_child(main)
	await process_frame
	await process_frame
	main._on_character_selected("ember_exile")
	await process_frame
	await process_frame

	_check(main._combat_hotkeys_allowed(), "PC player turn enables combat hotkeys")
	main._on_card_previewed(0)
	_check(main.card_detail_preview.visible and main._combat_hotkeys_allowed(), "hover preview does not block PC combat hotkeys")
	main._hide_card_detail_preview(0)
	var target_before: int = main.selected_enemy_index
	main._unhandled_input(_key_event(KEY_TAB))
	await process_frame
	_check(main.selected_enemy_index != target_before, "Tab cycles to the next living enemy")
	_check(main.last_combat_hotkey_action == "cycle_target" and main.last_combat_hotkey_index == main.selected_enemy_index, "target hotkey records action telemetry")

	main._open_pile_view("draw")
	var blocked_count: int = main.last_combat_hotkey_count
	var blocked_turn: int = main.combat.turn
	main._unhandled_input(_key_event(KEY_SPACE))
	await process_frame
	_check(main.last_combat_hotkey_count == blocked_count and main.combat.turn == blocked_turn, "pile overlay blocks combat hotkeys")
	main._close_pile_view(false)

	main.card_drag_active = true
	_check(not main._handle_combat_hotkey(_key_event(KEY_SPACE)), "active card drag blocks combat hotkeys")
	main.card_drag_active = false
	var text_input := LineEdit.new()
	host.add_child(text_input)
	text_input.grab_focus()
	await process_frame
	_check(not main._combat_hotkeys_allowed(), "focused text input blocks combat hotkeys")
	text_input.release_focus()
	text_input.queue_free()
	await process_frame

	main.run_potion_ids = ["volatile_vial"]
	var enemy_hp_before: int = int(main.combat.enemies[main.selected_enemy_index].get("hp", 0))
	main._unhandled_input(_key_event(KEY_1))
	await process_frame
	_check(main.run_potion_ids.is_empty(), "number key consumes the matching potion slot")
	_check(int(main.combat.enemies[main.selected_enemy_index].get("hp", 0)) == enemy_hp_before - 12, "potion hotkey resolves the configured potion effect")
	_check(main.last_combat_hotkey_action == "use_potion" and main.last_combat_hotkey_index == 0, "potion hotkey records slot telemetry")
	_check(main._potion_index_for_key(KEY_KP_3) == 2, "numeric keypad maps to the matching potion slot")
	_check(not main._handle_combat_hotkey(_key_event(KEY_2)), "empty potion slot does not consume a hotkey action")

	var turn_before: int = main.combat.turn
	main._unhandled_input(_key_event(KEY_SPACE))
	await process_frame
	await process_frame
	_check(main.last_combat_hotkey_action == "end_turn", "Space resolves the end-turn command")
	_check(main.combat.turn > turn_before or main.combat.phase in ["won", "lost"], "end-turn hotkey advances combat state")

	host.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("PC combat hotkey smoke test passed.")
		quit(0)

func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = false
	return event

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
