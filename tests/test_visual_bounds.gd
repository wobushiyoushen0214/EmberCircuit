extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

var failed: bool = false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var viewport_size := Vector2(390, 640)
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

	_check(_control_width_fits(main.page_scroll, viewport_size.x), "page scroll fits compact viewport width")
	_check(_control_width_fits(main.page_margin, viewport_size.x), "page margin fits compact viewport width")
	_check(_control_width_fits(main.root_box, viewport_size.x), "root content fits compact viewport width")
	_check(_visible_children_fit_horizontally(main.root_box, viewport_size.x), "character select visible page sections fit compact width")
	_check(main.reward_row.custom_minimum_size.x <= main.last_reward_flow_available_width, "character select reward flow is bounded to visible width")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "character select reward controls fit compact width")
	_check(_control_above(main.reward_scroll, main.controls_scroll), "compact character select reward area stays above bottom controls")
	_check(_control_bottom_fits(main.root_box, viewport_size.y), "compact character select page fits initial viewport height")

	main._on_character_selected("ember_exile")
	await process_frame
	await process_frame
	_check(_visible_children_fit_horizontally(main.root_box, viewport_size.x), "combat visible page sections fit compact width")
	_check(main.last_combat_layout_overflow <= 0.0, "combat compact page height remains within intended budget")
	_check(_control_width_fits(main.battle_board_panel, viewport_size.x), "combat board fits compact viewport width")
	_check(_visible_children_fit_horizontally(main.battle_mid_row, viewport_size.x), "combat middle row fits compact viewport width")
	_check(_control_above(main.log_label, main.hand_frame), "compact combat log stays above hand")
	_check(_control_above(main.hand_frame, main.controls_scroll), "compact combat hand stays above bottom controls")
	_check(_control_bottom_fits(main.root_box, viewport_size.y), "compact combat page fits initial viewport height")
	_check(_hand_cards_fit_buttons(main), "compact combat hand card contents stay inside card frames")

	main.combat.phase = "won"
	main._advance_to_next_node()
	await process_frame
	await process_frame
	_check(_control_width_fits(main.map_scroll, viewport_size.x), "map scroll fits compact viewport width")
	_check(main.map_view.custom_minimum_size.x >= main._scroll_content_width(), "map content may scroll inside its own viewport")
	_check(_visible_children_fit_horizontally(main.root_box, viewport_size.x), "map page sections fit compact width")

	main._on_compendium_pressed()
	await process_frame
	await process_frame
	_check(main.compendium_open and main.last_compendium_panel_visible, "compact compendium opens")
	_check(main.last_compendium_card_width <= main.last_reward_flow_available_width, "compact compendium cards stay inside reward width")
	_check(_visible_children_fit_horizontally(main.root_box, viewport_size.x), "compact compendium page sections fit compact width")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact compendium entries fit compact width")
	_check(not main.last_compendium_reveal_all_details, "compact compendium defaults to hidden undiscovered details")
	main._on_compendium_reveal_toggle_pressed()
	await process_frame
	await process_frame
	_check(main.last_compendium_reveal_all_details, "compact compendium can toggle full detail mode")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact detail-toggle compendium entries fit compact width")
	main._on_compendium_reveal_toggle_pressed()
	await process_frame
	await process_frame
	main._on_compendium_filter_pressed("undiscovered")
	await process_frame
	await process_frame
	_check(main.last_compendium_filter == "undiscovered", "compact compendium can apply discovery filters")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact discovery-filtered compendium entries fit compact width")
	main._on_compendium_filter_pressed("all")
	await process_frame
	await process_frame
	main._on_compendium_search_changed("裂击")
	await process_frame
	await process_frame
	_check(main.last_compendium_search == "裂击", "compact compendium can apply search")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact searched compendium entries fit compact width")
	main._on_compendium_search_clear_pressed()
	await process_frame
	await process_frame
	_check(main.last_compendium_search.is_empty(), "compact compendium can clear search")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact cleared compendium entries fit compact width")
	main._on_compendium_filter_pressed("attack")
	await process_frame
	await process_frame
	_check(main.last_compendium_filter == "attack", "compact compendium can apply card filters")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact filtered card compendium entries fit compact width")
	main._on_compendium_sort_pressed("cost")
	await process_frame
	await process_frame
	_check(main.last_compendium_sort == "cost", "compact compendium can apply card sorting")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact sorted card compendium entries fit compact width")
	main._on_compendium_tab_pressed("enemies")
	await process_frame
	await process_frame
	_check(main.last_compendium_tab == "enemies", "compact compendium can switch tabs")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact enemy compendium entries fit compact width")
	main._on_compendium_filter_pressed("boss")
	await process_frame
	await process_frame
	_check(main.last_compendium_filter == "boss", "compact compendium can apply enemy filters")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact filtered enemy compendium entries fit compact width")
	main._on_compendium_tab_pressed("events")
	await process_frame
	await process_frame
	_check(main.last_compendium_tab == "events", "compact compendium can switch to event tab")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact event compendium entries fit compact width")
	main._on_compendium_filter_pressed("character:arc_tinker")
	await process_frame
	await process_frame
	_check(main.last_compendium_filter == "character:arc_tinker", "compact compendium can apply character filters")
	_check(_visible_children_fit_horizontally(main.reward_row, viewport_size.x), "compact character-filtered compendium entries fit compact width")

	var desktop_size := Vector2(1600, 900)
	var desktop_host := Control.new()
	desktop_host.custom_minimum_size = desktop_size
	desktop_host.size = desktop_size
	desktop_host.clip_contents = true
	root.add_child(desktop_host)
	var desktop_main = scene.instantiate()
	desktop_main.debug_viewport_size_override = desktop_size
	desktop_host.add_child(desktop_main)
	await process_frame
	await process_frame
	_check(_control_width_fits(desktop_main.page_scroll, desktop_size.x), "desktop page scroll fits viewport width")
	_check(_visible_children_fit_horizontally(desktop_main.root_box, desktop_size.x), "desktop character select visible page sections fit width")
	_check(desktop_main.last_combat_layout_overflow <= 0.0, "desktop character select fits intended height budget")
	_check(desktop_main.reward_row.get_child_count() >= 2, "desktop character select separates challenge controls and roster")
	var desktop_challenge_row := desktop_main.reward_row.get_child(0) as HBoxContainer
	var desktop_roster_flow := desktop_main.reward_row.get_child(1) as HFlowContainer
	_check(desktop_challenge_row != null and desktop_challenge_row.get_child_count() == 3, "desktop challenge controls stay in their own row")
	_check(desktop_roster_flow != null and desktop_roster_flow.get_child_count() >= 3, "desktop roster renders all character cards in one section")
	if desktop_roster_flow != null:
		_check(_visible_children_fit_horizontally(desktop_roster_flow, desktop_size.x), "desktop roster cards fit viewport width")
		_check(_children_share_row(desktop_roster_flow), "desktop roster cards stay on one visual row")
		_check(_control_above(desktop_roster_flow, desktop_main.controls_scroll), "desktop roster stays above bottom controls")
	_check(_control_above(desktop_main.reward_scroll, desktop_main.controls_scroll), "desktop character reward area stays above bottom controls")

	desktop_main._on_character_selected("ember_exile")
	await process_frame
	await process_frame
	_check(_visible_children_fit_horizontally(desktop_main.root_box, desktop_size.x), "desktop combat visible page sections fit width")
	_check(desktop_main.last_combat_layout_overflow <= 0.0, "desktop combat fits intended height budget")
	_check(desktop_main.character_summary_label.text.contains("生命") and desktop_main.character_summary_label.text.contains("势能"), "desktop combat player summary remains readable")
	_check(not desktop_main.status_label.text.contains("□") and not desktop_main.log_label.text.contains("□"), "desktop combat text avoids missing-glyph boxes")
	_check(_control_above(desktop_main.hand_frame, desktop_main.controls_scroll), "desktop combat hand stays above bottom controls")

	main.free()
	host.free()
	desktop_main.free()
	desktop_host.free()
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	if failed:
		quit(1)
		return
	print("Visual bounds smoke test passed.")
	quit(0)

func _control_width_fits(control: Control, viewport_width: float) -> bool:
	if control == null or not control.visible:
		return true
	var rect: Rect2 = control.get_global_rect()
	return rect.position.x >= -1.0 and rect.end.x <= viewport_width + 1.0

func _visible_children_fit_horizontally(container: Control, viewport_width: float) -> bool:
	if container == null or not container.visible:
		return true
	for child in container.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		if _ancestor_allows_horizontal_scroll(control):
			continue
		if not _control_width_fits(control, viewport_width):
			push_error("Horizontal overflow: %s rect=%s viewport=%s" % [control.name, str(control.get_global_rect()), str(viewport_width)])
			return false
		if not _visible_children_fit_horizontally(control, viewport_width):
			return false
	return true

func _ancestor_allows_horizontal_scroll(control: Control) -> bool:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			var scroll := parent as ScrollContainer
			if int(scroll.get("horizontal_scroll_mode")) != 0:
				return true
		parent = parent.get_parent()
	return false

func _children_share_row(container: Control) -> bool:
	var baseline := INF
	for child in container.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		var rect: Rect2 = control.get_global_rect()
		if baseline == INF:
			baseline = rect.position.y
		elif abs(rect.position.y - baseline) > 2.0:
			return false
	return baseline != INF

func _control_above(upper: Control, lower: Control) -> bool:
	if upper == null or lower == null or not upper.visible or not lower.visible:
		return true
	return upper.get_global_rect().end.y <= lower.get_global_rect().position.y + 1.0

func _control_bottom_fits(control: Control, viewport_height: float) -> bool:
	if control == null or not control.visible:
		return true
	var rect: Rect2 = control.get_global_rect()
	if rect.end.y > viewport_height + 1.0:
		push_error("Vertical overflow: %s rect=%s viewport_height=%s" % [control.name, str(rect), str(viewport_height)])
		return false
	return true

func _hand_cards_fit_buttons(main) -> bool:
	if main == null or main.hand_row == null:
		return true
	for child in main.hand_row.get_children():
		var button := child as Button
		if button == null or not button.visible:
			continue
		var bounds: Rect2 = button.get_global_rect().grow(1.0)
		if not _descendants_inside_rect(button, bounds):
			return false
	return true

func _descendants_inside_rect(control: Control, bounds: Rect2) -> bool:
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null or not child_control.visible:
			continue
		var rect: Rect2 = child_control.get_global_rect()
		if not _rect_inside(rect, bounds):
			push_error("Card content overflow: %s rect=%s bounds=%s" % [child_control.name, str(rect), str(bounds)])
			return false
		if not _descendants_inside_rect(child_control, bounds):
			return false
	return true

func _rect_inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x \
		and rect.position.y >= bounds.position.y \
		and rect.end.x <= bounds.end.x \
		and rect.end.y <= bounds.end.y

func _check(condition: bool, message: String) -> bool:
	if not condition:
		failed = true
		push_error("Test failed: %s" % message)
	return condition
