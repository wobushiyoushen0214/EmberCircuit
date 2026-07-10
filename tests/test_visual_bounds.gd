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
	_check(_hand_cards_fit_hand_tray(desktop_main), "desktop combat rotated hand cards stay inside hand tray")
	_check(_hand_card_rotation_readable(desktop_main, 2.5), "desktop combat hand card rotation stays readable")
	_check(_pc_card_description_blocks_readable(desktop_main, 64.0), "desktop combat hand card descriptions have readable space")

	var default_pc_size := Vector2(1280, 720)
	var default_pc_host := Control.new()
	default_pc_host.custom_minimum_size = default_pc_size
	default_pc_host.size = default_pc_size
	default_pc_host.clip_contents = true
	root.add_child(default_pc_host)
	var default_pc_main = scene.instantiate()
	default_pc_main.debug_viewport_size_override = default_pc_size
	default_pc_host.add_child(default_pc_main)
	await process_frame
	await process_frame
	default_pc_main._on_character_selected("arc_tinker")
	await process_frame
	await process_frame
	_check(default_pc_main._is_pc_layout(), "default 1280x720 viewport uses PC combat layout")
	_check(not default_pc_main.title_label.visible and not default_pc_main.character_frame.visible, "default PC combat hides non-combat chrome")
	_check(default_pc_main.last_combat_layout_overflow <= 0.0, "default PC combat fits 720p height budget")
	_check(_control_above(default_pc_main.hand_frame, default_pc_main.controls_scroll), "default PC combat hand stays above bottom controls")
	_check(_hand_cards_fit_hand_tray(default_pc_main), "default PC rotated hand cards stay inside hand tray")
	_check(_hand_card_rotation_readable(default_pc_main, 2.5), "default PC hand card rotation stays readable")
	_check(_pc_card_description_blocks_readable(default_pc_main, 62.0), "default PC hand card descriptions have readable space")
	_check(_potion_belt_stays_outside_enemy_stage(default_pc_main), "default PC potion belt stays out of the enemy stage")
	default_pc_main._on_pile_hud_pressed("抽牌")
	await process_frame
	await process_frame
	_check(default_pc_main.pile_overlay.visible and default_pc_main.pile_panel.visible, "default PC draw pile viewer opens")
	_check(_control_inside_viewport(default_pc_main.pile_panel, default_pc_size), "default PC pile viewer stays inside 720p viewport")
	_check(default_pc_main.pile_cards_flow.custom_minimum_size.x <= default_pc_main.pile_panel.custom_minimum_size.x, "default PC pile card grid stays bounded by the modal")
	default_pc_main._close_pile_view(false)
	default_pc_main.combat.phase = "won"
	default_pc_main._refresh_combat()
	await process_frame
	await process_frame
	var reward_action_column := default_pc_main.reward_row.get_node_or_null("RewardActionColumn") as VBoxContainer
	_check(reward_action_column != null, "default PC combat reward uses a dedicated action column")
	_check(_children_share_row(default_pc_main.reward_row), "default PC combat rewards stay on one visual row")
	_check(_visible_children_inside_vertical(default_pc_main.reward_row, default_pc_main.reward_scroll), "default PC combat reward items stay inside the reward viewport")
	_check(_control_above(default_pc_main.reward_scroll, default_pc_main.controls_scroll), "default PC combat reward viewport stays above bottom controls")
	default_pc_main.card_reward_done = true
	default_pc_main.relic_reward_done = true
	default_pc_main.potion_reward_done = true
	default_pc_main._advance_to_next_node()
	await process_frame
	await process_frame
	_jump_to_event_id(default_pc_main, "mute_calibrator")
	await process_frame
	await process_frame
	_check(default_pc_main.last_event_choice_layout_count == 3, "default PC event renders structured choice layouts")
	_check(_children_share_row(default_pc_main.reward_row), "default PC event story and choices stay on one visual row")
	_check(_visible_children_inside_vertical(default_pc_main.reward_row, default_pc_main.reward_scroll), "default PC event story and choices stay inside the reward viewport")
	_complete_run_by_boss_jumps(default_pc_main)
	await process_frame
	await process_frame
	_check(default_pc_main.run_completed, "default PC run can reach completion view")
	_check(default_pc_main.last_run_completion_panel_visible, "default PC completion view renders ending panel")
	_check(default_pc_main.last_run_completion_art_loaded, "default PC completion view loads ending art")
	_check(default_pc_main.last_run_completion_action_count >= 3, "default PC completion view keeps ending actions visible")
	_check(default_pc_main.last_combat_layout_overflow <= 0.0, "default PC completion view fits 720p height budget")
	_check(_visible_children_fit_horizontally(default_pc_main.root_box, default_pc_size.x), "default PC completion visible sections fit width")
	_check(_control_above(default_pc_main.reward_scroll, default_pc_main.controls_scroll), "default PC completion reward panel stays above bottom controls")
	var completion_actions := default_pc_main.reward_row.get_node_or_null("RunCompletionPanel/RunCompletionActions") as Control
	_check(_control_inside_vertical(completion_actions, default_pc_main.reward_scroll), "default PC completion actions stay inside reward viewport")

	main.free()
	host.free()
	desktop_main.free()
	desktop_host.free()
	default_pc_main.free()
	default_pc_host.free()
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

func _control_inside_vertical(child: Control, parent: Control) -> bool:
	if child == null or parent == null or not child.visible or not parent.visible:
		return false
	var child_rect: Rect2 = child.get_global_rect()
	var parent_rect: Rect2 = parent.get_global_rect()
	if child_rect.position.y < parent_rect.position.y - 1.0 or child_rect.end.y > parent_rect.end.y + 1.0:
		push_error("Vertical overflow: child=%s parent=%s" % [str(child_rect), str(parent_rect)])
		return false
	return true

func _visible_children_inside_vertical(container: Control, parent: Control) -> bool:
	if container == null or parent == null:
		return false
	for child in container.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		if not _control_inside_vertical(control, parent):
			push_error("Vertical overflow: %s rect=%s viewport=%s" % [control.name, str(control.get_global_rect()), str(parent.get_global_rect())])
			return false
	return true

func _potion_belt_stays_outside_enemy_stage(main) -> bool:
	if main == null or main.potion_row == null or main.enemy_row == null or not main.potion_row.visible:
		return true
	var potion_rect: Rect2 = main.potion_row.get_global_rect()
	if main.enemy_stage_panel != null and main.potion_row.get_parent() == main.combat_hud_row:
		var stage_rect: Rect2 = main.enemy_stage_panel.get_global_rect()
		if potion_rect.end.y > stage_rect.position.y + 1.0:
			push_error("Potion belt intrudes into enemy stage: potion=%s stage=%s" % [str(potion_rect), str(stage_rect)])
			return false
	for child in main.enemy_row.get_children():
		var enemy_panel := child as Control
		if enemy_panel == null or not enemy_panel.visible:
			continue
		if potion_rect.intersects(enemy_panel.get_global_rect(), true):
			push_error("Potion belt overlaps enemy panel: potion=%s enemy=%s" % [str(potion_rect), str(enemy_panel.get_global_rect())])
			return false
	return true

func _jump_to_event_id(main, event_id: String) -> void:
	for i in range(main.route_nodes.size()):
		var node_dict: Dictionary = main.route_nodes[i]
		if str(node_dict.get("type", "")) == "event":
			node_dict["event_id"] = event_id
			main.route_nodes[i] = node_dict
			main.current_node_id = str(node_dict.get("id", ""))
			main.current_node_index = main._node_index_by_id(main.current_node_id)
			main.available_node_ids.clear()
			main._start_current_node()
			return

func _complete_run_by_boss_jumps(main) -> void:
	for _i in range(3):
		_jump_to_node_type(main, "boss")
		if main.combat != null:
			main.combat.phase = "won"
		main._advance_to_next_node()

func _jump_to_node_type(main, node_type: String) -> void:
	for i in range(main.route_nodes.size()):
		var node_dict: Dictionary = main.route_nodes[i]
		if str(node_dict.get("type", "")) == node_type:
			main.current_node_id = str(node_dict.get("id", ""))
			main.current_node_index = main._node_index_by_id(main.current_node_id)
			main.available_node_ids.clear()
			main._start_current_node()
			return

func _control_bottom_fits(control: Control, viewport_height: float) -> bool:
	if control == null or not control.visible:
		return true
	var rect: Rect2 = control.get_global_rect()
	if rect.end.y > viewport_height + 1.0:
		push_error("Vertical overflow: %s rect=%s viewport_height=%s" % [control.name, str(rect), str(viewport_height)])
		return false
	return true

func _control_inside_viewport(control: Control, viewport_size: Vector2) -> bool:
	if control == null or not control.visible:
		return false
	var rect: Rect2 = control.get_global_rect()
	if rect.position.x < -1.0 or rect.position.y < -1.0 or rect.end.x > viewport_size.x + 1.0 or rect.end.y > viewport_size.y + 1.0:
		push_error("Control outside viewport: %s rect=%s viewport=%s" % [control.name, str(rect), str(viewport_size)])
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

func _hand_cards_fit_hand_tray(main) -> bool:
	if main == null or main.hand_row == null or main.hand_scroll == null:
		return true
	var bounds: Rect2 = main.hand_scroll.get_global_rect().grow(1.0)
	for child in main.hand_row.get_children():
		var button := child as Button
		if button == null or not button.visible:
			continue
		if not _control_corners_inside_rect(button, bounds):
			return false
	return true

func _hand_card_rotation_readable(main, max_degrees: float) -> bool:
	if main == null or main.hand_row == null:
		return true
	for child in main.hand_row.get_children():
		var button := child as Button
		if button == null or not button.visible:
			continue
		if abs(button.rotation_degrees) > max_degrees:
			push_error("Hand card rotation too large: %s rotation=%s max=%s" % [button.name, str(button.rotation_degrees), str(max_degrees)])
			return false
	return true

func _pc_card_description_blocks_readable(main, minimum_height: float) -> bool:
	if main == null or main.hand_row == null:
		return true
	for child in main.hand_row.get_children():
		var button := child as Button
		if button == null or not button.visible:
			continue
		var desc_panel := button.find_child("CardDescriptionPanel", true, false) as Control
		var desc_text := button.find_child("CardDescriptionText", true, false) as Label
		if desc_panel == null or desc_text == null:
			push_error("PC hand card missing description block: %s" % button.name)
			return false
		var desc_height: float = desc_panel.get_rect().size.y
		if desc_height < minimum_height:
			push_error("PC hand card description too short: %s height=%s min=%s" % [button.name, str(desc_height), str(minimum_height)])
			return false
		if desc_text.get_theme_font_size("font_size") > 10:
			push_error("PC hand card description font too large: %s" % button.name)
			return false
	return true

func _control_corners_inside_rect(control: Control, bounds: Rect2) -> bool:
	var control_size: Vector2 = control.size
	if control_size.x <= 0.0 or control_size.y <= 0.0:
		control_size = control.custom_minimum_size
	var transform: Transform2D = control.get_global_transform()
	var corners: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(control_size.x, 0.0),
		control_size,
		Vector2(0.0, control_size.y)
	]
	for corner in corners:
		var global_point: Vector2 = transform * corner
		if not bounds.has_point(global_point):
			push_error("Control corner outside bounds: %s corner=%s bounds=%s" % [control.name, str(global_point), str(bounds)])
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
