extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

var failed: bool = false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManagerScript.set_storage_namespace("test_visual_bounds")
	SaveManagerScript.cleanup_storage_namespace()
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

	var compact_welcome_page := main.app_shell.active_page as Control
	var compact_primary_action := compact_welcome_page.find_child("PrimaryAction", true, false) as Button if compact_welcome_page != null else null
	var compact_utility_row := compact_welcome_page.find_child("UtilityActionRow", true, false) as Control if compact_welcome_page != null else null
	_check(main.app_shell.visible and not main.page_scroll.visible, "compact welcome uses the full-screen AppShell without legacy chrome")
	_check(_control_inside_viewport(compact_welcome_page, viewport_size), "compact welcome page stays inside the viewport")
	_check(_control_inside_viewport(compact_primary_action, viewport_size), "compact welcome primary command stays inside the viewport")
	_check(_visible_children_fit_horizontally(compact_utility_row, viewport_size.x), "compact welcome utility commands fit the viewport")
	main._on_new_run_pressed()
	await process_frame
	await process_frame
	var compact_character_page := main.app_shell.active_page as Control
	var compact_roster_scroll := compact_character_page.get_node_or_null("CharacterRosterScroll") as ScrollContainer if compact_character_page != null else null
	var compact_footer := compact_character_page.get_node_or_null("CharacterFooterCompact") as Control if compact_character_page != null else null
	_check(_control_inside_viewport(compact_character_page, viewport_size), "compact character page stays inside the viewport")
	_check(_control_inside_viewport(compact_roster_scroll, viewport_size), "compact character roster stays inside its horizontal viewport")
	_check(_control_inside_viewport(compact_footer, viewport_size), "compact character footer stays inside the viewport")

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
	_check(desktop_main.app_shell.visible and not desktop_main.page_scroll.visible, "desktop welcome uses the full-screen AppShell")
	_check(desktop_main.welcome_open and desktop_main.last_welcome_action_count == 5, "desktop welcome exposes the complete five-command navigation")
	var desktop_welcome_page := desktop_main.app_shell.active_page as Control
	var desktop_primary_action := desktop_welcome_page.find_child("PrimaryAction", true, false) as Button if desktop_welcome_page != null else null
	var desktop_utility_actions := desktop_welcome_page.find_child("UtilityActionRow", true, false) as Container if desktop_welcome_page != null else null
	_check(_control_inside_viewport(desktop_welcome_page, desktop_size) and _control_inside_viewport(desktop_primary_action, desktop_size), "desktop welcome page and primary command stay inside the viewport")
	_check(desktop_utility_actions != null and desktop_utility_actions.get_child_count() == 3 and _visible_children_fit_horizontally(desktop_utility_actions, desktop_size.x), "desktop welcome utility row stays complete and bounded")
	desktop_main._on_new_run_pressed()
	await process_frame
	await process_frame
	_check(desktop_main.app_shell.visible and not desktop_main.page_scroll.visible, "desktop character select keeps legacy chrome hidden")
	_check(desktop_main.last_combat_layout_overflow <= 0.0, "desktop character select fits intended height budget")
	var desktop_character_page := desktop_main.app_shell.active_page as Control
	var desktop_challenge_row := desktop_character_page.get_node_or_null("ChallengeTrack") as HBoxContainer if desktop_character_page != null else null
	var desktop_roster_flow := desktop_character_page.get_node_or_null("CharacterRoster") as HFlowContainer if desktop_character_page != null else null
	var desktop_character_actions := desktop_character_page.get_node_or_null("CharacterActionRow") as HBoxContainer if desktop_character_page != null else null
	var desktop_character_footer := desktop_character_page.get_node_or_null("CharacterFooter") as Control if desktop_character_page != null else null
	_check(_control_inside_viewport(desktop_character_page, desktop_size) and _control_inside_viewport(desktop_character_actions, desktop_size) and _control_inside_viewport(desktop_character_footer, desktop_size), "desktop character page, footer and action row stay inside the viewport")
	_check(desktop_challenge_row != null and desktop_challenge_row.get_child_count() == 4 and _control_inside_viewport(desktop_challenge_row, desktop_size), "desktop complete challenge track stays in its own row")
	_check(desktop_roster_flow != null and desktop_roster_flow.get_child_count() >= 3, "desktop roster renders all character cards in one section")
	if desktop_roster_flow != null:
		_check(_visible_children_fit_horizontally(desktop_roster_flow, desktop_size.x), "desktop roster cards fit viewport width")
		_check(_children_share_row(desktop_roster_flow), "desktop roster cards stay on one visual row")
		_check(_control_above(desktop_roster_flow, desktop_character_footer), "desktop roster stays above the fixed character footer")

	desktop_main._on_character_selected("ember_exile")
	await process_frame
	await process_frame
	_check(_visible_children_fit_horizontally(desktop_main.root_box, desktop_size.x), "desktop combat visible page sections fit width")
	_check(desktop_main.last_combat_layout_overflow <= 0.0, "desktop combat fits intended height budget")
	_check(desktop_main.character_summary_label.text.contains("生命") and desktop_main.character_summary_label.text.contains("势能"), "desktop combat player summary remains readable")
	_check(not desktop_main.status_label.text.contains("□") and not desktop_main.log_label.text.contains("□"), "desktop combat text avoids missing-glyph boxes")
	_check(_control_above(desktop_main.hand_frame, desktop_main.controls_scroll), "desktop combat hand stays above bottom controls")
	_check(_hand_cards_fit_hand_tray(desktop_main), "desktop combat rotated hand cards stay inside hand tray")
	_check(_hand_card_rotation_readable(desktop_main, 3.3), "desktop combat hand card rotation stays readable")
	_check(_hand_cards_form_fan(desktop_main), "desktop combat hand forms a restrained bottom fan")
	_check(_pc_hand_cards_show_rules(desktop_main), "desktop combat hand shows concise rules text on the card face")
	_check(_control_inside_horizontal(desktop_main.player_stage_plate, desktop_main.enemy_stage_panel) and _control_inside_vertical(desktop_main.player_stage_plate, desktop_main.enemy_stage_panel), "desktop player health plate stays inside battle stage")

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
	var default_pc_welcome_page := default_pc_main.app_shell.active_page as Control
	var default_pc_primary_action := default_pc_welcome_page.find_child("PrimaryAction", true, false) as Button if default_pc_welcome_page != null else null
	var default_pc_utility_row := default_pc_welcome_page.find_child("UtilityActionRow", true, false) as Container if default_pc_welcome_page != null else null
	_check(default_pc_main.app_shell.visible and not default_pc_main.page_scroll.visible and default_pc_main.last_welcome_action_count == 5, "default PC welcome uses the complete AppShell navigation")
	_check(_control_inside_viewport(default_pc_welcome_page, default_pc_size) and _control_inside_viewport(default_pc_primary_action, default_pc_size), "default PC welcome page and primary command stay inside 720p")
	_check(default_pc_utility_row != null and default_pc_utility_row.get_child_count() == 3 and _visible_children_fit_horizontally(default_pc_utility_row, default_pc_size.x), "default PC welcome utilities stay complete and bounded")
	_check(is_equal_approx(default_pc_main._scroll_content_width(), default_pc_size.x - default_pc_main._root_horizontal_margin()), "default PC layout does not reserve space for a disabled vertical scrollbar")
	default_pc_main._on_new_run_pressed()
	await process_frame
	await process_frame
	var default_pc_character_page := default_pc_main.app_shell.active_page as Control
	var default_pc_roster_flow := default_pc_character_page.get_node_or_null("CharacterRoster") as HFlowContainer if default_pc_character_page != null else null
	var default_pc_challenge_track := default_pc_character_page.get_node_or_null("ChallengeTrack") as HBoxContainer if default_pc_character_page != null else null
	var default_pc_character_footer := default_pc_character_page.get_node_or_null("CharacterFooter") as Control if default_pc_character_page != null else null
	var default_pc_character_actions := default_pc_character_page.get_node_or_null("CharacterActionRow") as Control if default_pc_character_page != null else null
	_check(default_pc_roster_flow != null and default_pc_roster_flow.get_child_count() == 3, "default PC character select renders all three character cards")
	_check(_children_share_row(default_pc_roster_flow), "default PC character cards stay on one visual row")
	_check(default_pc_challenge_track != null and default_pc_challenge_track.get_child_count() == 4 and _control_inside_viewport(default_pc_challenge_track, default_pc_size), "default PC complete challenge track stays inside 720p")
	_check(_control_inside_viewport(default_pc_character_page, default_pc_size) and _control_inside_viewport(default_pc_character_footer, default_pc_size) and _control_inside_viewport(default_pc_character_actions, default_pc_size), "default PC character page and fixed commands stay inside 720p")
	_check(default_pc_main.app_shell.visible and not default_pc_main.page_scroll.visible, "default PC character select keeps all legacy chrome hidden")
	default_pc_main._on_character_selected("arc_tinker")
	await process_frame
	await process_frame
	_check(default_pc_main._is_pc_layout(), "default 1280x720 viewport uses PC combat layout")
	_check(int(default_pc_main.page_scroll.get("vertical_scroll_mode")) == 0 and not default_pc_main.page_scroll.get_v_scroll_bar().visible, "default PC combat never exposes a page scrollbar")
	_check(int(default_pc_main.hand_scroll.get("horizontal_scroll_mode")) == 3, "default PC hand keeps horizontal navigation without a visible scrollbar")
	_check(not default_pc_main.hand_scroll.get_h_scroll_bar().visible and not default_pc_main.controls_scroll.get_h_scroll_bar().visible, "default PC hand and control strips hide scrollbars")
	_check(default_pc_main.controls_scroll.visible and _control_inside_viewport(default_pc_main.controls_scroll, default_pc_size), "default PC combat control strip stays visible inside the viewport")
	_check(default_pc_main.deck_button.visible and _control_inside_viewport(default_pc_main.deck_button, default_pc_size), "default PC deck button stays visible inside the viewport")
	_check(default_pc_main.settings_button.visible and _control_inside_viewport(default_pc_main.settings_button, default_pc_size), "default PC settings button stays visible inside the viewport")
	_check(default_pc_main.end_turn_button.visible and _control_inside_viewport(default_pc_main.end_turn_button, default_pc_size), "default PC end-turn button stays visible inside the viewport")
	_check(default_pc_main.end_turn_button.get_parent() == default_pc_main.hand_right_hud, "default PC end-turn button lives beside the hand instead of overflowing the bottom strip")
	_check(_control_inside_horizontal(default_pc_main.end_turn_button, default_pc_main.hand_frame) and _control_inside_vertical(default_pc_main.end_turn_button, default_pc_main.hand_frame), "default PC end-turn button stays inside the hand tray")
	_check(not default_pc_main.title_label.visible and not default_pc_main.character_frame.visible, "default PC combat hides non-combat chrome")
	_check(default_pc_main.last_combat_layout_overflow <= 0.0, "default PC combat fits 720p height budget")
	_check(_control_above(default_pc_main.battle_board_panel, default_pc_main.hand_frame), "default PC battle stage stays above the hand tray")
	_check(_control_above(default_pc_main.hand_frame, default_pc_main.controls_scroll), "default PC combat hand stays above bottom controls")
	_check(_hand_cards_fit_hand_tray(default_pc_main), "default PC rotated hand cards stay inside hand tray")
	_check(_hand_card_rotation_readable(default_pc_main, 3.3), "default PC hand card rotation stays readable")
	_check(_hand_cards_form_fan(default_pc_main), "default PC hand forms a restrained bottom fan")
	_check(_pc_hand_cards_show_rules(default_pc_main), "default PC hand cards retain art and visible rules text")
	_check(_pc_enemy_stage_info_readable(default_pc_main), "default PC enemy name, state and health plates remain readable")
	_check(_potion_belt_stays_outside_enemy_stage(default_pc_main), "default PC potion belt stays out of the enemy stage")
	_check(_control_inside_horizontal(default_pc_main.player_stage_plate, default_pc_main.enemy_stage_panel) and _control_inside_vertical(default_pc_main.player_stage_plate, default_pc_main.enemy_stage_panel), "default PC player health plate stays inside battle stage")
	var original_relic_ids: Array = default_pc_main.run_relic_ids.duplicate()
	default_pc_main.run_relic_ids = ["heavy_gear", "war_drum_fragment", "molten_core_ring", "shield_break_wedge", "blank_contract", "echo_stone"]
	default_pc_main._refresh_relic_belt()
	await process_frame
	await process_frame
	_check(default_pc_main.last_relic_belt_layout_count == 6 and default_pc_main.last_relic_belt_icon_node_count == 6, "default PC relic belt renders six production icons")
	_check(default_pc_main.last_relic_belt_overflow_count == 0, "default PC relic belt fits its six visible slots without overflow")
	_check(_control_inside_viewport(default_pc_main.relic_belt_row, default_pc_size), "default PC six-relic belt stays inside the 720p viewport")
	default_pc_main.run_relic_ids = original_relic_ids
	default_pc_main._refresh_relic_belt()
	default_pc_main._on_card_previewed(0)
	_check(default_pc_main.card_detail_preview.visible, "default PC card hover shows the large detail preview")
	_check(_control_inside_viewport(default_pc_main.card_detail_preview, default_pc_size), "default PC large card preview stays inside the 720p viewport")
	_check(_preview_stays_above_hand(default_pc_main), "default PC large card preview stays above the hand tray")
	_check(_pc_hover_preview_has_description(default_pc_main, 0), "default PC hover preview owns the complete card description")
	_check(_preview_tracks_source_card(default_pc_main, 0), "default PC hover preview stays horizontally anchored to its source card")
	default_pc_main._hide_card_detail_preview(0)
	default_pc_main._on_pile_hud_pressed("抽牌")
	await process_frame
	await process_frame
	_check(default_pc_main.pile_overlay.visible and default_pc_main.pile_panel.visible, "default PC draw pile viewer opens")
	_check(_control_inside_viewport(default_pc_main.pile_panel, default_pc_size), "default PC pile viewer stays inside 720p viewport")
	_check(default_pc_main.pile_cards_flow.custom_minimum_size.x <= default_pc_main.pile_panel.custom_minimum_size.x, "default PC pile card grid stays bounded by the modal")
	default_pc_main._close_pile_view(false)
	default_pc_main._on_deck_view_pressed()
	await process_frame
	await process_frame
	var deck_toolbar := default_pc_main.reward_row.get_node_or_null("DeckToolbar") as Control
	_check(deck_toolbar != null and default_pc_main.last_deck_view_toolbar_visible, "default PC deck view renders its toolbar")
	_check(_control_inside_viewport(default_pc_main.reward_scroll, default_pc_size), "default PC deck grid viewport stays inside 720p")
	_check(_control_inside_vertical(deck_toolbar, default_pc_main.reward_scroll), "default PC deck toolbar stays inside the deck viewport")
	_check(not default_pc_main.controls_scroll.visible, "default PC deck view hides the unrelated bottom control strip")
	_check(default_pc_main.last_deck_view_visible_card_count == default_pc_main.run_deck_ids.size(), "default PC deck view exposes the complete deck")
	default_pc_main._on_close_deck_view_pressed()
	await process_frame
	await process_frame
	_check(default_pc_main.controls_scroll.visible and default_pc_main.hand_frame.visible, "closing the deck view restores combat controls and hand")
	var phase_pc_host := Control.new()
	phase_pc_host.custom_minimum_size = default_pc_size
	phase_pc_host.size = default_pc_size
	phase_pc_host.clip_contents = true
	root.add_child(phase_pc_host)
	var phase_pc_main = scene.instantiate()
	phase_pc_main.debug_viewport_size_override = default_pc_size
	phase_pc_host.add_child(phase_pc_main)
	await process_frame
	await process_frame
	phase_pc_main._on_character_selected("arc_tinker")
	phase_pc_main.route_nodes = [{"id": "phase_bounds_boss", "type": "boss", "encounter_id": "chapter_one_boss"}]
	phase_pc_main.current_node_id = "phase_bounds_boss"
	phase_pc_main.current_node_index = 0
	phase_pc_main.available_node_ids.clear()
	phase_pc_main.available_node_ids.append("phase_bounds_boss")
	phase_pc_main._start_current_node()
	var bounds_boss: Dictionary = phase_pc_main.combat.enemies[0]
	var bounds_phase_hp: int = int(floor(float(int(bounds_boss.get("max_hp", 1))) * 0.50))
	phase_pc_main.combat._damage_enemy(bounds_boss, max(1, int(bounds_boss.get("hp", 1)) - bounds_phase_hp), {"name": "阶段边界测试", "ignore_player_modifiers": true})
	phase_pc_main._refresh_combat()
	await process_frame
	await process_frame
	var phase_banner := phase_pc_main.enemy_stage_stack.get_node_or_null("BossPhaseBanner") as Control
	var phase_badge := phase_pc_main.enemy_stage_stack.find_child("BossPhaseBadge", true, false) as Control
	var phase_threshold_0 := phase_pc_main.enemy_stage_stack.find_child("BossPhaseThreshold_0", true, false) as Control
	var phase_threshold_1 := phase_pc_main.enemy_stage_stack.find_child("BossPhaseThreshold_1", true, false) as Control
	_check(phase_banner != null and phase_badge != null and phase_threshold_0 != null and phase_threshold_1 != null, "default PC boss phase renders banner, badge and two threshold markers")
	_check(_control_inside_horizontal(phase_banner, phase_pc_main.enemy_stage_panel) and _control_inside_vertical(phase_banner, phase_pc_main.enemy_stage_panel), "default PC boss phase banner stays inside the battle stage")
	_check(_control_inside_horizontal(phase_badge, phase_pc_main.enemy_stage_panel) and _control_inside_vertical(phase_badge, phase_pc_main.enemy_stage_panel), "default PC boss phase badge stays inside the battle stage")
	_check(phase_pc_main.last_combat_layout_overflow <= 0.0 and not phase_pc_main.page_scroll.get_v_scroll_bar().visible, "default PC boss phase presentation keeps the 720p page fixed")
	phase_pc_main._restore_battle_stage_processing()
	var hit_stop_stage: Control = phase_pc_main.enemy_stage_stack
	var hit_stop_original_mode: int = Node.PROCESS_MODE_ALWAYS
	hit_stop_stage.process_mode = hit_stop_original_mode
	var hit_stop_time_scale: float = Engine.time_scale
	phase_pc_main._request_hit_stop(0.050)
	_check(hit_stop_stage.process_mode == Node.PROCESS_MODE_DISABLED and phase_pc_main.hit_stop_active, "local hit stop disables only the battle stage while active")
	await create_timer(0.030, true, false, true).timeout
	phase_pc_main._request_hit_stop(0.120)
	await create_timer(0.040, true, false, true).timeout
	_check(hit_stop_stage.process_mode == Node.PROCESS_MODE_DISABLED and phase_pc_main.hit_stop_active, "overlapping local hit stop remains active past the first request deadline")
	await create_timer(0.110, true, false, true).timeout
	_check(hit_stop_stage.process_mode == hit_stop_original_mode and not phase_pc_main.hit_stop_active and is_equal_approx(Engine.time_scale, hit_stop_time_scale), "local hit stop restores the original stage process mode without changing global time")
	phase_pc_main._request_hit_stop(0.200)
	_check(hit_stop_stage.process_mode == Node.PROCESS_MODE_DISABLED, "exit recovery probe starts with the battle stage disabled")
	phase_pc_host.remove_child(phase_pc_main)
	_check(hit_stop_stage.process_mode == hit_stop_original_mode and not phase_pc_main.hit_stop_active and is_equal_approx(Engine.time_scale, hit_stop_time_scale), "leaving the tree restores battle-stage processing immediately")
	phase_pc_main.queue_free()
	phase_pc_host.queue_free()
	await process_frame

	var defeat_pc_host := Control.new()
	defeat_pc_host.custom_minimum_size = default_pc_size
	defeat_pc_host.size = default_pc_size
	defeat_pc_host.clip_contents = true
	root.add_child(defeat_pc_host)
	var defeat_pc_main = scene.instantiate()
	defeat_pc_main.debug_viewport_size_override = default_pc_size
	defeat_pc_host.add_child(defeat_pc_main)
	await process_frame
	await process_frame
	defeat_pc_main._on_character_selected("ember_exile")
	defeat_pc_main.combat.phase = "lost"
	defeat_pc_main.combat.player["hp"] = 0
	defeat_pc_main._refresh_combat()
	await process_frame
	await process_frame
	var defeat_stage := defeat_pc_main.reward_row.get_node_or_null("PcDefeatExperience") as PanelContainer
	var defeat_scene := defeat_stage.find_child("DefeatScene", true, false) as Control if defeat_stage != null else null
	var defeat_summary := defeat_stage.find_child("DefeatSummary", true, false) as Control if defeat_stage != null else null
	var defeat_actions := defeat_stage.find_child("DefeatActions", true, false) as Control if defeat_stage != null else null
	_check(defeat_stage != null and defeat_pc_main.reward_row.get_child_count() == 1, "default PC defeat uses one complete outcome stage")
	_check(int(defeat_pc_main.page_scroll.get("vertical_scroll_mode")) == 0 and int(defeat_pc_main.reward_scroll.get("vertical_scroll_mode")) == 0, "default PC defeat does not expose page or reward scrolling")
	_check(not defeat_pc_main.page_scroll.get_v_scroll_bar().visible and not defeat_pc_main.reward_scroll.get_v_scroll_bar().visible, "default PC defeat hides system scrollbars")
	_check(not defeat_pc_main.controls_scroll.visible and not defeat_pc_main.title_label.visible and not defeat_pc_main.log_label.visible and not defeat_pc_main.character_frame.visible, "default PC defeat removes legacy chrome and duplicate bottom actions")
	_check(_control_inside_viewport(defeat_pc_main.reward_scroll, default_pc_size) and _control_inside_vertical(defeat_stage, defeat_pc_main.reward_scroll), "default PC defeat stage stays inside the 720p reward viewport")
	_check(_control_inside_vertical(defeat_scene, defeat_stage) and _control_inside_horizontal(defeat_scene, defeat_stage), "default PC defeat battle scene stays inside its stage")
	_check(_control_inside_vertical(defeat_summary, defeat_stage) and _control_inside_horizontal(defeat_summary, defeat_stage), "default PC defeat summary stays inside its stage")
	_check(_control_inside_vertical(defeat_actions, defeat_stage) and _control_inside_horizontal(defeat_actions, defeat_stage), "default PC defeat actions stay inside its stage")
	_check(_visible_children_fit_horizontally(defeat_actions, default_pc_size.x), "default PC defeat actions fit one row")
	_check(defeat_pc_main.last_combat_layout_overflow <= 0.0, "default PC defeat fits the 720p height budget")
	defeat_pc_host.queue_free()
	await process_frame

	var short_pc_size := Vector2(1280, 700)
	var short_pc_host := Control.new()
	short_pc_host.custom_minimum_size = short_pc_size
	short_pc_host.size = short_pc_size
	short_pc_host.clip_contents = true
	root.add_child(short_pc_host)
	var short_pc_main = scene.instantiate()
	short_pc_main.debug_viewport_size_override = short_pc_size
	short_pc_host.add_child(short_pc_main)
	await process_frame
	await process_frame
	_check(not short_pc_main._is_pc_layout(), "a maximized window with less than 720 content pixels avoids the fixed PC layout")
	_check(int(short_pc_main.page_scroll.get("vertical_scroll_mode")) == 1, "a short PC window keeps vertical scrolling available instead of clipping bottom controls")
	short_pc_host.queue_free()
	await process_frame

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
	var map_preview_panel := default_pc_main.map_view.get_node_or_null("NodePreviewPanel") as Control
	_check(map_preview_panel != null and map_preview_panel.visible, "default PC map renders a fixed node-detail panel")
	_check(not default_pc_main.log_label.visible, "default PC map removes the legacy RichTextLabel detail strip")
	_check(int(default_pc_main.map_scroll.get("horizontal_scroll_mode")) == 0 and not default_pc_main.map_scroll.get_h_scroll_bar().visible, "default PC map fits without a horizontal scrollbar")
	_check(default_pc_main.map_view.find_children("*", "ScrollContainer", true, false).is_empty(), "default PC map detail panel contains no nested scroll containers")
	_jump_to_node_type(default_pc_main, "campfire")
	await process_frame
	await process_frame
	var campfire_stage := default_pc_main.reward_row.get_node_or_null("PcCampfireExperience") as PanelContainer
	var campfire_forge_button := campfire_stage.find_child("CampfireForgeButton", true, false) as Button if campfire_stage != null else null
	_check(campfire_stage != null and default_pc_main.reward_row.get_child_count() == 1, "default PC campfire uses one illustrated decision stage")
	_check(int(default_pc_main.reward_scroll.get("vertical_scroll_mode")) == 0 and not default_pc_main.reward_scroll.get_v_scroll_bar().visible, "default PC campfire arrival does not expose a page scrollbar")
	_check(_control_inside_vertical(campfire_stage, default_pc_main.reward_scroll), "default PC campfire decision stage stays inside the reward viewport")
	_check(campfire_forge_button != null, "default PC campfire exposes the forge action")
	if campfire_forge_button != null:
		campfire_forge_button.pressed.emit()
	await process_frame
	await process_frame
	var campfire_forge_stage := default_pc_main.reward_row.get_node_or_null("PcCampfireForgeSelection") as PanelContainer
	var campfire_forge_grid := campfire_forge_stage.find_child("CampfireUpgradeCards", true, false) as GridContainer if campfire_forge_stage != null else null
	_check(campfire_forge_stage != null and campfire_forge_grid != null, "default PC forge action opens a complete card-selection stage")
	_check(int(default_pc_main.reward_scroll.get("vertical_scroll_mode")) == 3 and not default_pc_main.reward_scroll.get_v_scroll_bar().visible, "default PC forge selection keeps wheel navigation without a visible scrollbar")
	_check(campfire_forge_grid != null and campfire_forge_grid.get_child_count() == default_pc_main._campfire_upgrade_candidates().size(), "default PC forge grid includes every upgradeable card")
	var original_campfire_deck: Array = default_pc_main.run_deck_ids.duplicate()
	var initial_campfire_candidates: Array = default_pc_main._campfire_upgrade_candidates()
	if not initial_campfire_candidates.is_empty():
		var repeated_card_id: String = str(initial_campfire_candidates[0].get("entry_id", ""))
		for extra_copy in range(6):
			default_pc_main.run_deck_ids.append(repeated_card_id)
		default_pc_main._refresh()
		await process_frame
		await process_frame
		campfire_forge_stage = default_pc_main.reward_row.get_node_or_null("PcCampfireForgeSelection") as PanelContainer
		campfire_forge_grid = campfire_forge_stage.find_child("CampfireUpgradeCards", true, false) as GridContainer if campfire_forge_stage != null else null
		var long_deck_candidates: Array = default_pc_main._campfire_upgrade_candidates()
		var campfire_scroll_bar: VScrollBar = default_pc_main.reward_scroll.get_v_scroll_bar()
		_check(long_deck_candidates.size() > 10 and campfire_forge_grid != null and campfire_forge_grid.get_child_count() == long_deck_candidates.size(), "long PC deck renders every forge candidate across more than two rows")
		_check(campfire_scroll_bar.max_value > campfire_scroll_bar.page and not campfire_scroll_bar.visible, "long PC forge grid is scrollable while the system scrollbar stays hidden")
		default_pc_main.reward_scroll.scroll_vertical = int(campfire_scroll_bar.max_value)
		await process_frame
		await process_frame
		var last_forge_card := campfire_forge_grid.get_child(campfire_forge_grid.get_child_count() - 1) as Control if campfire_forge_grid != null and campfire_forge_grid.get_child_count() > 0 else null
		_check(_control_inside_vertical(last_forge_card, default_pc_main.reward_scroll), "long PC forge grid can scroll its final card fully into view")
	default_pc_main.run_deck_ids = original_campfire_deck
	default_pc_main.campfire_upgrade_selection_open = false
	_jump_to_event_id(default_pc_main, "broken_reactor")
	await process_frame
	await process_frame
	_check(default_pc_main.last_event_choice_layout_count == 4, "default PC event renders all four structured choice layouts")
	var event_stage := default_pc_main.reward_row.get_node_or_null("PcEventExperience") as PanelContainer
	var event_choice_buttons := event_stage.find_child("EventChoiceButtons", true, false) as VBoxContainer if event_stage != null else null
	_check(event_stage != null and default_pc_main.reward_row.get_child_count() == 1, "default PC event uses one complete decision stage")
	_check(event_choice_buttons != null and event_choice_buttons.get_child_count() == 4, "default PC event keeps four choices in one decision column")
	_check(int(default_pc_main.reward_scroll.get("vertical_scroll_mode")) == 0 and not default_pc_main.reward_scroll.get_v_scroll_bar().visible, "default PC event does not expose a page scrollbar")
	_check(_control_inside_vertical(event_stage, default_pc_main.reward_scroll), "default PC event stage stays inside the reward viewport")
	_check(_visible_children_inside_vertical(event_choice_buttons, default_pc_main.reward_scroll), "default PC event choices stay inside the reward viewport")
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
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
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

func _control_inside_horizontal(child: Control, parent: Control) -> bool:
	if child == null or parent == null or not child.visible or not parent.visible:
		return false
	var child_rect: Rect2 = child.get_global_rect()
	var parent_rect: Rect2 = parent.get_global_rect()
	if child_rect.position.x < parent_rect.position.x - 1.0 or child_rect.end.x > parent_rect.end.x + 1.0:
		push_error("Horizontal overflow: child=%s parent=%s" % [str(child_rect), str(parent_rect)])
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
			push_error("Hand card bounds metrics: position=%s size=%s base=%s rest=%s rotation=%s" % [str(button.position), str(button.size), str(button.get_meta("hand_layout_base_position", Vector2.ZERO)), str(button.get_meta("hand_rest_position", Vector2.ZERO)), str(button.rotation_degrees)])
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

func _hand_cards_form_fan(main) -> bool:
	if main == null or main.hand_row == null or main.hand_row.get_child_count() < 3:
		return true
	var first := main.hand_row.get_child(0) as Button
	var center := main.hand_row.get_child(int(main.hand_row.get_child_count() / 2.0)) as Button
	var last := main.hand_row.get_child(main.hand_row.get_child_count() - 1) as Button
	if first == null or center == null or last == null:
		return false
	var first_rest: Vector2 = first.get_meta("hand_rest_position", first.position)
	var center_rest: Vector2 = center.get_meta("hand_rest_position", center.position)
	var last_rest: Vector2 = last.get_meta("hand_rest_position", last.position)
	var forms_fan: bool = first.rotation_degrees < 0.0 \
		and last.rotation_degrees > 0.0 \
		and center_rest.y <= first_rest.y \
		and center_rest.y <= last_rest.y
	if not forms_fan:
		push_error("Hand fan metrics: rotations=%s/%s/%s rest_y=%s/%s/%s" % [str(first.rotation_degrees), str(center.rotation_degrees), str(last.rotation_degrees), str(first_rest.y), str(center_rest.y), str(last_rest.y)])
	return forms_fan

func _pc_hand_cards_show_rules(main) -> bool:
	if main == null or main.hand_row == null:
		return true
	var card_count := 0
	for child in main.hand_row.get_children():
		var button := child as Button
		if button == null or not button.visible:
			continue
		card_count += 1
		var desc_panel := button.find_child("CardDescriptionPanel", true, false) as Control
		var desc_text := button.find_child("CardDescriptionText", true, false) as Label
		var art := button.find_child("FullCardArt", true, false) as TextureRect
		var type_panel := button.find_child("CardTypePanel", true, false) as Control
		if desc_panel == null or desc_text == null or desc_text.text.is_empty():
			push_error("PC hand card is missing visible rules text: %s" % button.name)
			return false
		if art == null or type_panel == null:
			push_error("PC hand card missing illustrated structure: %s" % button.name)
			return false
	return card_count > 0

func _pc_hover_preview_has_description(main, hand_index: int) -> bool:
	if main == null or main.card_detail_preview == null or main.combat == null:
		return false
	if hand_index < 0 or hand_index >= main.combat.hand.size():
		return false
	var desc_panel := main.card_detail_preview.find_child("CardDescriptionPanel", true, false) as Control
	var desc_text := main.card_detail_preview.find_child("CardDescriptionText", true, false) as Label
	if desc_panel == null or desc_text == null or not main.card_detail_preview.tooltip_text.is_empty():
		return false
	return desc_text.text == str(main.combat.hand[hand_index].get("description", ""))

func _preview_tracks_source_card(main, hand_index: int) -> bool:
	if main == null or not main.hand_buttons_by_index.has(hand_index):
		return false
	var source := main.hand_buttons_by_index.get(hand_index) as Button
	if source == null:
		return false
	return abs(source.get_global_rect().get_center().x - main.card_detail_preview.get_global_rect().get_center().x) <= 2.0

func _preview_stays_above_hand(main) -> bool:
	if main == null or main.card_detail_preview == null or main.hand_frame == null:
		return false
	var preview_rect: Rect2 = main.card_detail_preview.get_global_rect()
	var hand_rect: Rect2 = main.hand_frame.get_global_rect()
	if preview_rect.end.y > hand_rect.position.y + 1.0:
		push_error("Preview overlaps hand: preview=%s hand=%s" % [str(preview_rect), str(hand_rect)])
		return false
	return true

func _pc_enemy_stage_info_readable(main) -> bool:
	if main == null or main.enemy_row == null:
		return false
	var readable_count := 0
	for child in main.enemy_row.get_children():
		var panel := child as Control
		if panel == null:
			continue
		var info_strip := panel.find_child("EnemyInfoStrip", true, false) as Control
		var name_label := panel.find_child("EnemyNameLabel", true, false) as Label
		var state_label := panel.find_child("EnemyStateLabel", true, false) as Label
		var hp_label := panel.find_child("EnemyHpValue", true, false) as Label
		if info_strip == null or name_label == null or state_label == null or hp_label == null:
			return false
		if info_strip.size.y < 25.0 or name_label.get_theme_font_size("font_size") < 12 or state_label.get_theme_font_size("font_size") < 10 or hp_label.get_theme_font_size("font_size") < 11:
			return false
		readable_count += 1
	return readable_count > 0

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
