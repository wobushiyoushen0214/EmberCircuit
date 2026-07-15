extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

var failed: bool = false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManagerScript.set_storage_namespace("test_card_drag")
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var viewport_size := Vector2(1280, 720)
	var host := Control.new()
	host.custom_minimum_size = viewport_size
	host.size = viewport_size
	host.clip_contents = true
	root.add_child(host)

	var main = scene.instantiate()
	main.debug_viewport_size_override = viewport_size
	host.add_child(main)
	await process_frame
	await process_frame
	main._on_character_selected("ember_exile")
	await process_frame
	await process_frame

	var attack_index: int = _first_enemy_target_card(main)
	_check(attack_index >= 0, "opening hand contains a playable enemy-target card")
	if attack_index < 0:
		_finish()
		return
	var source_button := main.hand_buttons_by_index.get(attack_index, null) as Button
	var target_control: Control = main._enemy_combat_target_control(str(main.combat.enemies[0].get("id", "")), 0)
	_check(source_button != null and target_control != null, "drag test resolves source card and enemy target controls")
	if source_button == null or target_control == null:
		_finish()
		return
	var source: Vector2 = source_button.get_global_rect().get_center()
	var target: Vector2 = target_control.get_global_rect().get_center()
	var hand_before: int = main.combat.hand.size()
	var energy_before: int = int(main.combat.player.get("energy", 0))
	var played_before: int = main.last_card_drag_played_count

	_send_card_press(main, attack_index, source)
	_send_mouse_motion(main, target, source, MOUSE_BUTTON_MASK_LEFT)
	await process_frame
	_check(main.card_drag_active, "mouse motion with left button starts card drag")
	_check(main.last_card_drag_valid and main.last_card_drag_target_id == str(main.combat.enemies[0].get("id", "")), "enemy card drag snaps to the hovered living enemy")
	_check(main.last_card_drag_curve_point_count == 25, "active card drag builds a 25-point curved trajectory")
	_send_mouse_release(main, target)
	await process_frame
	await process_frame
	_check(not main.card_drag_active and main.last_card_drag_played_count == played_before + 1, "releasing on a valid enemy plays exactly one card")
	_check(main.combat.hand.size() == hand_before - 1, "valid drag removes one card from hand")
	_check(int(main.combat.player.get("energy", 0)) < energy_before, "valid drag spends the card energy cost")

	var cancel_index: int = _first_playable_card(main)
	_check(cancel_index >= 0, "hand keeps a playable card for cancellation test")
	if cancel_index >= 0:
		var cancel_button := main.hand_buttons_by_index.get(cancel_index, null) as Button
		var cancel_source: Vector2 = cancel_button.get_global_rect().get_center()
		var invalid_drop := Vector2(cancel_source.x, 690.0)
		var cancel_hand_before: int = main.combat.hand.size()
		var cancelled_before: int = main.last_card_drag_cancelled_count
		_send_card_press(main, cancel_index, cancel_source)
		_send_mouse_motion(main, invalid_drop, cancel_source, MOUSE_BUTTON_MASK_LEFT)
		await process_frame
		_check(main.card_drag_active and not main.last_card_drag_valid, "drag outside battlefield remains invalid")
		_send_mouse_release(main, invalid_drop)
		await process_frame
		await process_frame
		_check(not main.card_drag_active and main.last_card_drag_cancelled_count == cancelled_before + 1, "invalid drop cancels and requests hand return")
		_check(main.combat.hand.size() == cancel_hand_before, "cancelled drag does not consume a card")

	var resize_index: int = _first_playable_card(main)
	_check(resize_index >= 0, "hand keeps a playable card for resize cancellation test")
	if resize_index >= 0:
		var resize_button := main.hand_buttons_by_index.get(resize_index, null) as Button
		var resize_source: Vector2 = resize_button.get_global_rect().get_center()
		var resize_hand_before: int = main.combat.hand.size()
		var resize_cancelled_before: int = main.last_card_drag_cancelled_count
		_send_card_press(main, resize_index, resize_source)
		_send_mouse_motion(main, resize_source + Vector2(0, -120), resize_source, MOUSE_BUTTON_MASK_LEFT)
		_check(main.card_drag_active, "resize test starts an active card drag")
		main._refresh_after_resize()
		await process_frame
		await process_frame
		_check(not main.card_drag_active and main.card_drag_candidate_index == -1, "layout refresh cancels active card drag state")
		_check(main.last_card_drag_cancelled_count == resize_cancelled_before + 1, "layout refresh records exactly one cancelled drag")
		_check(main.combat.hand.size() == resize_hand_before, "layout refresh never consumes the dragged card")

	_finish()

func _send_card_press(main, card_index: int, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	event.global_position = position
	main._on_hand_card_gui_input(event, card_index)

func _send_mouse_release(main, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position
	event.global_position = position
	main._handle_card_drag_input(event)

func _send_mouse_motion(main, position: Vector2, previous: Vector2, button_mask: int) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = position - previous
	event.button_mask = button_mask
	main._handle_card_drag_input(event)

func _first_enemy_target_card(main) -> int:
	for index in range(main.combat.hand.size()):
		if main.combat.can_play_card(index) and main._card_targets_enemy(main.combat.hand[index]):
			return index
	return -1

func _first_playable_card(main) -> int:
	for index in range(main.combat.hand.size()):
		if main.combat.can_play_card(index):
			return index
	return -1

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)

func _finish() -> void:
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
	if failed:
		quit(1)
	else:
		print("Card drag interaction smoke test passed.")
		quit(0)
