extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

var failed: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main._ready()
	var signal_clear_probe := HBoxContainer.new()
	var signal_clear_button := Button.new()
	root.add_child(signal_clear_probe)
	signal_clear_probe.add_child(signal_clear_button)
	signal_clear_button.pressed.connect(func() -> void: main._clear_container(signal_clear_probe))
	signal_clear_button.pressed.emit()
	if not _check(signal_clear_probe.get_child_count() == 0 and signal_clear_button.is_queued_for_deletion(), "active signal buttons are detached and queued instead of freed synchronously"):
		return
	signal_clear_probe.queue_free()

	if not _check(main.welcome_open and not main.character_select_open, "main scene starts at welcome page"):
		return
	if not _check(main.last_music_context == "menu", "welcome page uses menu music context"):
		return
	if not _check(main.last_welcome_action_count == 3, "welcome page exposes new run, continue and archive actions"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row.get_child_count() >= 3, "welcome page renders a bounded primary action area"):
		return
	if not _check(not main.battle_board_panel.visible and not main.hand_frame.visible and not main.character_frame.visible, "welcome page hides run-only regions"):
		return
	main._on_new_run_pressed()
	if not _check(not main.welcome_open and main.character_select_open, "new run opens character selection"):
		return
	if not _check(main.last_music_context == "menu", "character selection uses menu music context"):
		return
	if not _check(main.screen_background_art != null and main.screen_background_art.visible and main.last_ui_backdrop_loaded, "main scene renders the generated UI backdrop"):
		return
	if not _check(main.last_character_selection_title == "选择角色", "character selection has a title"):
		return
	if not _check(main.last_character_selection_ids.has("ember_exile") and main.last_character_selection_ids.has("arc_tinker") and main.last_character_selection_ids.has("pyre_ascetic"), "character selection lists playable characters"):
		return
	if not _check(main.reward_row.get_child_count() >= 2 and main.last_character_button_icon_count >= 3, "character selection renders separated challenge and character sections"):
		return
	if not _check(main.reward_row.visible and main.last_character_button_icon_count >= 3, "character selection shows visible art-backed character cards"):
		return
	if not _check(main.last_character_selection_confirm_visible and main.last_character_selection_selected_id == "ember_exile", "character selection shows explicit confirmation for the selected character"):
		return
	main._on_character_preview_selected("arc_tinker")
	if not _check(main.character_select_open and main.combat == null and main.selected_character_id == "arc_tinker" and main.last_character_selection_selected_id == "arc_tinker", "character click previews without starting the run"):
		return
	main._on_character_preview_selected("ember_exile")
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer, "character selection uses a bounded wrapping reward area"):
		return
	if not _check(main.last_combat_layout_overflow <= 0.0, "character selection page fits inside the configured viewport"):
		return
	if not _check(not main.potion_row.visible and not main.enemy_row.visible and not main.hand_row.visible, "character selection hides empty combat rows"):
		return
	if not _check(not main.battle_board_panel.visible and not main.hand_frame.visible, "character selection hides combat board frames"):
		return
	if not _check(main.reward_row.custom_minimum_size.y >= 200.0 and main.log_label.custom_minimum_size.y <= 140.0, "character selection keeps character cards in first viewport"):
		return
	if not _check(main.save_button.disabled and main.deck_button.disabled, "character selection disables run-only buttons"):
		return
	if not _check(not main.settings_button.disabled, "character selection keeps settings available"):
		return
	if main._is_pc_layout():
		if not _check(not main.end_turn_button.visible and not main.save_button.visible and not main.deck_button.visible, "PC character selection hides combat-only and run-only control buttons"):
			return
		if not _check(main.restart_button.visible and main.load_button.visible and main.profile_button.visible and main.compendium_button.visible and main.settings_button.visible, "PC character selection keeps only menu controls visible"):
			return
		if not _check(_control_has_texture_named(main.compendium_button, "MenuButtonIcon") and main.compendium_button.custom_minimum_size.x <= 92.0, "PC character selection renders compendium as a compact menu tool button"):
			return
	if not _check(main.last_challenge_button_count == 3 and main.last_challenge_level == 0 and main.last_challenge_unlocked_max == 0, "character selection shows locked base challenge selector"):
		return
	if not _check(main.last_challenge_summary.contains("普通模式"), "base challenge summary is readable"):
		return
	if not _check(main.last_tutorial_visible and main.last_tutorial_step_id == "character_select", "character selection shows first tutorial hint"):
		return
	if not _check(main.status_label.tooltip_text.contains("引导") and main.last_tutorial_body.contains("余烬流亡者"), "tutorial hint exposes readable guidance text"):
		return
	main._on_tutorial_pressed()
	if not _check(not main.last_tutorial_visible and main._tutorial_step_completed("character_select"), "tutorial button completes current contextual hint"):
		return
	main._on_tutorial_pressed()
	if not _check(main.tutorial_open and main.last_tutorial_page_visible and main.last_tutorial_summary.contains("引导目录"), "tutorial page opens after current hint is completed"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer and main.last_tutorial_button_count >= 3, "tutorial page uses bounded action buttons"):
		return
	main._on_close_tutorial_pressed()
	if not _check(main.character_select_open and not main.tutorial_open, "closing tutorial returns to character selection"):
		return
	main._on_settings_pressed()
	if not _check(main.settings_open and main.last_settings_panel_visible, "settings page opens from character selection"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer and main.last_settings_button_count >= 13, "settings page uses bounded action buttons"):
		return
	if not _check(main.last_settings_summary.contains("音效") and main.last_settings_summary.contains("音乐") and main.last_settings_summary.contains("震屏") and main.last_settings_summary.contains("新手引导"), "settings page shows readable settings summary"):
		return
	main._on_settings_reset_pressed()
	if not _check(main.last_settings_save_ok and main.last_settings_audio_enabled and main.last_settings_music_enabled and is_equal_approx(main.last_settings_master_volume, 1.0) and is_equal_approx(main.last_settings_music_volume, 0.65) and main.last_tutorial_visible, "settings reset restores default audio/music/tutorial settings and saves"):
		return
	main._on_settings_volume_down()
	if not _check(is_equal_approx(main.last_settings_master_volume, 0.9), "settings volume down applies runtime volume"):
		return
	main._on_settings_music_volume_down()
	if not _check(is_equal_approx(main.last_settings_music_volume, 0.6), "settings music volume down applies runtime volume"):
		return
	main._on_settings_toggle_music()
	if not _check(not main.last_settings_music_enabled, "settings can disable music"):
		return
	main._on_settings_toggle_screen_shake()
	main._on_settings_toggle_hit_stop()
	main._on_settings_toggle_floating_text()
	if not _check(not main.last_settings_screen_shake_enabled and not main.last_settings_hit_stop_enabled and not main.last_settings_floating_text_enabled, "settings toggles combat feedback options"):
		return
	main._on_settings_toggle_tutorial()
	if not _check(not main._setting_enabled("tutorial_enabled", true), "settings can disable tutorial hints"):
		return
	main._on_settings_reset_tutorial_pressed()
	if not _check(main._setting_enabled("tutorial_enabled", true) and main._tutorial_completed_steps().is_empty(), "settings can reset tutorial progress"):
		return
	main._on_settings_reset_pressed()
	main._on_close_settings_pressed()
	if not _check(main.character_select_open and not main.settings_open and main.last_settings_audio_enabled, "closing settings returns to character selection with defaults restored"):
		return
	main._on_compendium_pressed()
	if not _check(main.compendium_open and main.last_compendium_panel_visible and main.last_compendium_tab == "cards", "compendium opens from character selection on card tab"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer and main.last_compendium_tab_button_count == 8, "compendium uses bounded tab buttons and action area"):
		return
	if not _check(main.last_compendium_search_control_count == 2 and main.last_compendium_filter_button_count >= 10 and main.last_compendium_sort_button_count >= 4, "compendium exposes search, filter and sort controls"):
		return
	if not _check(main.last_compendium_item_count == main.card_data.get("cards", []).size() and main.last_compendium_total_count == main.card_data.get("cards", []).size() and main.last_compendium_summary.contains("显示："), "compendium card tab lists all configured cards"):
		return
	if not _check(main.last_compendium_discovered_count == 0 and main.last_compendium_undiscovered_count == main.card_data.get("cards", []).size() and main.last_compendium_summary.contains("发现：0/"), "fresh profile compendium marks card entries undiscovered"):
		return
	if not _check(not main.last_compendium_reveal_all_details and main.last_compendium_locked_item_count == main.card_data.get("cards", []).size() and main.last_compendium_summary.contains("详情：隐藏未见"), "fresh profile compendium hides undiscovered card details by default"):
		return
	if not _check(main.last_compendium_item_titles.size() > 0 and main.last_compendium_item_titles[0] == "未知卡牌" and main.last_compendium_item_bodies[0].contains("显示卡牌资料"), "undiscovered card entries render locked player-facing copy"):
		return
	main._on_compendium_filter_pressed("undiscovered")
	if not _check(main.last_compendium_filter == "undiscovered" and main.last_compendium_item_count == main.card_data.get("cards", []).size(), "compendium can filter undiscovered cards"):
		return
	main._on_compendium_filter_pressed("discovered")
	if not _check(main.last_compendium_filter == "discovered" and main.last_compendium_item_count == 0, "compendium can filter discovered cards on a fresh profile"):
		return
	main._on_compendium_filter_pressed("all")
	main._on_compendium_search_changed("ember_strike")
	if not _check(main.last_compendium_search == "ember_strike" and main.last_compendium_item_count == 0 and main.last_compendium_summary.contains("搜索：ember_strike"), "hidden compendium search does not reveal undiscovered internal ids"):
		return
	main._on_compendium_reveal_toggle_pressed()
	if not _check(main.last_compendium_reveal_all_details and main.last_compendium_item_count == _count_items_by_text_field(main.card_data.get("cards", []), "id", "ember_strike") and main.last_compendium_locked_item_count == 0 and main.last_compendium_summary.contains("详情：全显"), "compendium reveal mode restores full data search for balancing"):
		return
	main._on_compendium_search_clear_pressed()
	if not _check(main.last_compendium_search.is_empty() and main.last_compendium_item_count == main.card_data.get("cards", []).size(), "compendium card search can be cleared"):
		return
	main._on_compendium_filter_pressed("attack")
	if not _check(main.last_compendium_filter == "attack" and main.last_compendium_item_count == _count_items_by_field(main.card_data.get("cards", []), "type", "attack") and main.last_compendium_summary.contains("筛选：攻击"), "compendium card filter limits entries"):
		return
	main._on_compendium_sort_pressed("cost")
	if not _check(main.last_compendium_sort == "cost" and main.last_compendium_summary.contains("排序：费用"), "compendium card sort changes active order"):
		return
	main._on_compendium_filter_pressed("character:arc_tinker")
	if not _check(main.last_compendium_filter == "character:arc_tinker" and main.last_compendium_item_count == _count_items_available_to_character(main.card_data.get("cards", []), "arc_tinker"), "compendium card filter can show one character's available cards"):
		return
	main._on_compendium_tab_pressed("relics")
	if not _check(main.last_compendium_tab == "relics" and main.last_compendium_item_count == main.relic_data.get("relics", []).size(), "compendium relic tab lists all configured relics"):
		return
	main._on_compendium_filter_pressed("exclusive")
	if not _check(main.last_compendium_filter == "exclusive" and main.last_compendium_item_count == _count_items_with_character_scope(main.relic_data.get("relics", []), true), "compendium relic filter can show character-specific relics"):
		return
	main._on_compendium_filter_pressed("character:pyre_ascetic")
	if not _check(main.last_compendium_filter == "character:pyre_ascetic" and main.last_compendium_item_count == _count_items_available_to_character(main.relic_data.get("relics", []), "pyre_ascetic"), "compendium relic filter can show one character's available relics"):
		return
	main._on_compendium_tab_pressed("potions")
	if not _check(main.last_compendium_tab == "potions" and main.last_compendium_item_count == main.potion_data.get("potions", []).size(), "compendium potion tab lists all configured potions"):
		return
	main._on_compendium_sort_pressed("target")
	if not _check(main.last_compendium_sort == "target" and main.last_compendium_summary.contains("排序：目标"), "compendium potion sort changes active order"):
		return
	main._on_compendium_tab_pressed("enemies")
	if not _check(main.last_compendium_tab == "enemies" and main.last_compendium_item_count == main.enemy_data.get("enemies", []).size(), "compendium enemy tab lists all configured enemies"):
		return
	main._on_compendium_filter_pressed("boss")
	if not _check(main.last_compendium_filter == "boss" and main.last_compendium_item_count == _count_items_by_field(main.enemy_data.get("enemies", []), "tier", "boss"), "compendium enemy filter can show bosses"):
		return
	main._on_compendium_tab_pressed("events")
	if not _check(main.last_compendium_tab == "events" and main.last_compendium_item_count == main.event_data.get("events", []).size() and main.last_compendium_summary.contains("事件总数"), "compendium event tab lists all configured events"):
		return
	main._on_compendium_search_changed("电弧工作台")
	if not _check(main.last_compendium_search == "电弧工作台" and main.last_compendium_item_count == _count_items_by_text_field(main.event_data.get("events", []), "name", "电弧工作台"), "compendium event search limits entries by text"):
		return
	main._on_compendium_search_clear_pressed()
	if not _check(main.last_compendium_search.is_empty() and main.last_compendium_item_count == main.event_data.get("events", []).size(), "compendium event search can be cleared"):
		return
	main._on_compendium_filter_pressed("exclusive")
	if not _check(main.last_compendium_filter == "exclusive" and main.last_compendium_item_count == _count_items_with_character_scope(main.event_data.get("events", []), true), "compendium event filter can show character-specific events"):
		return
	main._on_compendium_filter_pressed("character:arc_tinker")
	if not _check(main.last_compendium_filter == "character:arc_tinker" and main.last_compendium_item_count == _count_items_available_to_character(main.event_data.get("events", []), "arc_tinker"), "compendium event filter can show one character's available events"):
		return
	main._on_compendium_sort_pressed("choices")
	if not _check(main.last_compendium_sort == "choices" and main.last_compendium_summary.contains("排序：选择"), "compendium event sort changes active order"):
		return
	main._on_compendium_tab_pressed("challenges")
	if not _check(main.last_compendium_tab == "challenges" and main.last_compendium_item_count == main.challenge_data.get("levels", []).size() and main.last_compendium_summary.contains("挑战等级"), "compendium challenge tab lists all configured challenge levels"):
		return
	main._on_compendium_filter_pressed("hp_loss")
	if not _check(main.last_compendium_filter == "hp_loss" and main.last_compendium_item_count == _count_challenges_with_starting_hp_loss(main.challenge_data.get("levels", [])), "compendium challenge filter can show hp-loss modifiers"):
		return
	main._on_close_compendium_pressed()
	if not _check(main.character_select_open and not main.compendium_open, "closing compendium returns to character selection"):
		return
	var compact_main = scene.instantiate()
	compact_main.debug_viewport_size_override = Vector2(540, 540)
	compact_main._ready()
	if not _check(compact_main.welcome_open and compact_main.last_combat_layout_overflow <= 0.0, "compact welcome page fits a 540px viewport"):
		return
	compact_main._on_new_run_pressed()
	if not _check(compact_main.page_scroll != null and compact_main.last_combat_layout_overflow <= 0.0, "compact character selection fits a 540px viewport with page scroll fallback"):
		return
	var compact_roster_scroll := compact_main.reward_row.get_child(1) as ScrollContainer
	var compact_roster := compact_roster_scroll.get_child(0) as HBoxContainer if compact_roster_scroll != null and compact_roster_scroll.get_child_count() > 0 else null
	var compact_card := compact_roster.get_child(0) as Button if compact_roster != null and compact_roster.get_child_count() > 0 else null
	if not _check(compact_roster_scroll != null and compact_roster_scroll.custom_minimum_size.x <= compact_main.last_reward_flow_available_width, "compact character roster scroll stays inside the reward width"):
		return
	if not _check(compact_card != null and compact_roster.custom_minimum_size.x >= compact_card.custom_minimum_size.x, "compact character cards are available inside the horizontal roster"):
		return
	compact_main._on_character_preview_selected("arc_tinker")
	compact_main._on_character_confirm_pressed()
	if not _check(compact_main.last_combat_layout_overflow <= 0.0, "compact combat layout fits a 540px viewport"):
		return
	var compact_hud_width: float = compact_main.last_combat_hud_block_count * compact_main._hud_block_width() + float(compact_main.last_combat_hud_block_count - 1) * 6.0
	if not _check(compact_hud_width <= compact_main._scroll_content_width(), "compact combat HUD stays inside the visible width"):
		return
	var compact_enemy_count: int = max(1, compact_main.combat.enemies.size())
	var compact_mid_width: float = compact_main._potion_row_width() + float(compact_enemy_count) * compact_main._enemy_panel_width() + float(max(0, compact_enemy_count - 1)) * float(compact_main._enemy_panel_gap()) + 10.0
	if not _check(compact_mid_width <= compact_main._layout_viewport_size().x - compact_main._root_horizontal_margin(), "compact enemy and potion row stays inside the battle board width"):
		return
	compact_main.combat.phase = "won"
	compact_main._advance_to_next_node()
	if not _check(compact_main.map_scroll != null and compact_main.map_scroll.visible and compact_main.map_view.get_parent() == compact_main.map_scroll, "compact map is constrained inside a horizontal scroll region"):
		return
	if not _check(compact_main.map_view.custom_minimum_size.x >= compact_main._scroll_content_width() and compact_main.map_scroll.custom_minimum_size.y <= 330.0, "compact map keeps a bounded viewport with scrollable route width"):
		return
	if not _check(compact_main.last_combat_layout_overflow <= 0.0, "compact map choice keeps page controls inside the viewport"):
		return
	_jump_to_event_id(compact_main, "broken_reactor")
	var compact_event_panel := compact_main.reward_row.get_child(0) as PanelContainer
	if not _check(compact_event_panel != null and compact_event_panel.custom_minimum_size.x <= compact_main.last_reward_flow_available_width, "compact event story panel stays inside the reward scroll width"):
		return
	compact_main.free()
	main._on_character_selected("ember_exile")
	if not _check(not main.character_select_open, "selecting a character starts the run"):
		return
	if not _check(main._profile_stat("runs_started") >= 1 and main._profile_unlocked_achievements().has("first_ignition"), "starting a run updates profile stats and unlocks first ignition"):
		return
	main._on_profile_pressed()
	if not _check(main.profile_open and main.last_profile_panel_visible, "profile page opens from an active run"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer and main.last_profile_button_count >= main.last_profile_total_count, "profile page uses bounded achievement buttons"):
		return
	if not _check(main.last_profile_summary.contains("档案统计") and main.last_profile_summary.contains("跑团开始"), "profile page shows readable run statistics"):
		return
	var active_run_character_id: String = main.selected_character_id
	main._on_profile_character_pressed("arc_tinker")
	if not _check(main.profile_character_id == "arc_tinker" and main.selected_character_id == active_run_character_id and main.last_profile_character_selector_count >= 3, "profile character tabs do not mutate the active run character"):
		return
	main._on_close_profile_pressed()
	if not _check(not main.profile_open, "profile page closes back to current run"):
		return
	if not _check(main.route_nodes.size() >= 8, "chapter route loads from data"):
		return
	if not _check(str(main._current_node().get("type", "")) == "combat", "run starts at first combat node"):
		return
	if not _check(main.last_music_context == "combat", "normal combat uses combat music context"):
		return
	if not _check(main._discovered_ids("cards").has("ember_strike") and main._discovered_ids("cards").has("ash_guard") and main._discovered_ids("cards").has("cooling_breath"), "starting a run discovers starter cards"):
		return
	if not _check(main._discovered_ids("relics").has("ember_bottle") and main._discovered_ids("relics").has("cracked_charm"), "starting a run discovers starter relics"):
		return
	if not _check(main._discovered_ids("challenges").has("0"), "starting a run discovers the selected challenge level"):
		return
	if not _check(not main._discovered_ids("enemies").is_empty(), "starting combat discovers encountered enemies"):
		return
	if not _check(main.run_deck_ids.size() >= 10, "starter deck is loaded"):
		return
	if not _check(main._max_potion_slots() == 2, "player potion slots load from data"):
		return
	if not _check(main.selected_character_id == "ember_exile", "default character is ember exile"):
		return
	if not _check(main.player_portrait != null and main.player_portrait.texture != null, "default character portrait loads"):
		return
	main._on_character_selected("arc_tinker")
	if not _check(main.selected_character_id == "arc_tinker", "character run can switch to arc tinker"):
		return
	if not _check(main.player_portrait != null and main.player_portrait.texture != null, "arc tinker portrait loads"):
		return
	if not _check(main.run_max_hp == 68 and main.run_hp == 68, "arc tinker HP loads from character data"):
		return
	if not _check(main.run_deck_ids.has("spark_throw") and main.run_deck_ids.has("pressure_probe"), "arc tinker starter deck loads from character data"):
		return
	if not _check(main.run_relic_ids.has("arc_capacitor"), "arc tinker starter relic loads from character data"):
		return
	if not _check(main._max_potion_slots() == 3, "arc tinker potion slots load from character data"):
		return
	if not _check(str(main.combat.player.get("name", "")) == "电弧工匠", "combat receives selected character config"):
		return
	if not _check(int(main.combat.player.get("momentum", 0)) >= 2, "arc tinker starts combat with momentum package"):
		return
	if not _check(str(main._create_save_state().get("selected_character_id", "")) == "arc_tinker", "save state includes selected character"):
		return
	var arc_reward_pool: Array = main._generate_card_rewards(999)
	if not _check(_reward_pool_has_card(arc_reward_pool, "static_primer") and _reward_pool_has_card(arc_reward_pool, "arc_needles"), "arc tinker reward pool includes dedicated cards"):
		return
	var arc_relic_pool: Array = main._generate_relic_rewards(999)
	if not _check(_reward_pool_has_relic(arc_relic_pool, "spark_coil") and _reward_pool_has_relic(arc_relic_pool, "micro_dynamo"), "arc tinker relic pool includes dedicated relics"):
		return
	if not _check(main._asset_loaded(main._relic_icon_path(arc_relic_pool[0])), "relic icon path loads from art manifest"):
		return
	var arc_event_pool: Array = main._map_config_for_current_character("chapter_one").get("event_pool", [])
	if not _check(arc_event_pool.has("arc_workbench") and arc_event_pool.has("livewire_nest"), "arc tinker map event pool includes dedicated events"):
		return
	_jump_to_event_id(main, "arc_workbench")
	var deck_size_before_arc_event: int = main.run_deck_ids.size()
	var arc_event: Dictionary = main._event_by_id("arc_workbench")
	main._on_event_choice_pressed(arc_event.get("choices", [])[0])
	if not _check(main.run_deck_ids.size() == deck_size_before_arc_event + 1 and main.run_deck_ids.has("static_primer"), "arc tinker dedicated event grants a dedicated card"):
		return
	main._on_character_selected("pyre_ascetic")
	if not _check(main.selected_character_id == "pyre_ascetic", "character run can switch to pyre ascetic"):
		return
	if not _check(main.player_portrait != null and main.player_portrait.texture != null, "pyre ascetic portrait loads"):
		return
	if not _check(main.run_max_hp == 72 and main.run_hp == 72, "pyre ascetic HP loads from character data"):
		return
	if not _check(main.run_deck_ids.has("penitent_cut") and main.run_deck_ids.has("kindle_pain"), "pyre ascetic starter deck loads from character data"):
		return
	if not _check(main.run_relic_ids.has("penitent_censer"), "pyre ascetic starter relic loads from character data"):
		return
	if not _check(str(main.combat.player.get("name", "")) == "熔痕苦修者", "combat receives pyre ascetic character config"):
		return
	var pyre_reward_pool: Array = main._generate_card_rewards(999)
	if not _check(_reward_pool_has_card(pyre_reward_pool, "blood_kindling") and _reward_pool_has_card(pyre_reward_pool, "white_flame_oath"), "pyre ascetic reward pool includes dedicated cards"):
		return
	if not _check(not _reward_pool_has_card(pyre_reward_pool, "static_primer") and not _reward_pool_has_card(pyre_reward_pool, "arc_needles"), "pyre ascetic reward pool excludes arc tinker dedicated cards"):
		return
	var pyre_relic_pool: Array = main._generate_relic_rewards(999)
	if not _check(_reward_pool_has_relic(pyre_relic_pool, "red_wick") and _reward_pool_has_relic(pyre_relic_pool, "white_flame_brand"), "pyre ascetic relic pool includes dedicated relics"):
		return
	if not _check(not _reward_pool_has_relic(pyre_relic_pool, "spark_coil") and not _reward_pool_has_relic(pyre_relic_pool, "micro_dynamo"), "pyre ascetic relic pool excludes arc tinker dedicated relics"):
		return
	var pyre_event_pool: Array = main._map_config_for_current_character("chapter_one").get("event_pool", [])
	if not _check(pyre_event_pool.has("scar_chapel") and pyre_event_pool.has("red_wick_altar") and pyre_event_pool.has("white_flame_branding"), "pyre ascetic map event pool includes dedicated events"):
		return
	if not _check(not pyre_event_pool.has("arc_workbench") and not pyre_event_pool.has("livewire_nest"), "pyre ascetic map event pool excludes arc tinker events"):
		return
	_jump_to_event_id(main, "scar_chapel")
	var deck_size_before_pyre_event: int = main.run_deck_ids.size()
	var pyre_event: Dictionary = main._event_by_id("scar_chapel")
	main._on_event_choice_pressed(pyre_event.get("choices", [])[0])
	if not _check(main.run_deck_ids.size() == deck_size_before_pyre_event + 1 and main.run_deck_ids.has("blood_kindling"), "pyre ascetic dedicated event grants a dedicated card"):
		return
	main._on_character_selected("ember_exile")
	if not _check(main.selected_character_id == "ember_exile" and main._max_potion_slots() == 2, "switching back to default character resets run config"):
		return
	var discovery_main = scene.instantiate()
	discovery_main._ready()
	discovery_main._on_compendium_pressed()
	discovery_main._on_compendium_tab_pressed("cards")
	discovery_main._on_compendium_filter_pressed("discovered")
	if not _check(discovery_main.last_compendium_tab == "cards" and discovery_main.last_compendium_filter == "discovered" and discovery_main.last_compendium_item_count == _count_items_in_discovery(discovery_main.card_data.get("cards", []), discovery_main._discovered_ids("cards")), "compendium discovered filter reflects profile card discoveries"):
		discovery_main.free()
		return
	discovery_main.free()
	var ember_reward_pool: Array = main._generate_card_rewards(999)
	if not _check(not _reward_pool_has_card(ember_reward_pool, "static_primer") and not _reward_pool_has_card(ember_reward_pool, "arc_needles"), "default character reward pool excludes arc tinker dedicated cards"):
		return
	if not _check(not _reward_pool_has_card(ember_reward_pool, "blood_kindling") and not _reward_pool_has_card(ember_reward_pool, "white_flame_oath"), "default character reward pool excludes pyre ascetic dedicated cards"):
		return
	var ember_relic_pool: Array = main._generate_relic_rewards(999)
	if not _check(not _reward_pool_has_relic(ember_relic_pool, "spark_coil") and not _reward_pool_has_relic(ember_relic_pool, "micro_dynamo"), "default character relic pool excludes arc tinker dedicated relics"):
		return
	if not _check(not _reward_pool_has_relic(ember_relic_pool, "red_wick") and not _reward_pool_has_relic(ember_relic_pool, "white_flame_brand"), "default character relic pool excludes pyre ascetic dedicated relics"):
		return
	if not _check(_reward_pool_has_relic(ember_relic_pool, "old_compass"), "default character relic pool includes implemented map relics"):
		return
	main.run_relic_ids.append("old_compass")
	var compass_node_id: String = _node_with_compass_extra(main)
	if not _check(not compass_node_id.is_empty(), "generated route has a node where old compass can add a route option"):
		return
	var base_map_options: Array[String] = main._next_node_ids(compass_node_id)
	var compass_map_options: Array[String] = main._map_relic_augmented_node_ids(compass_node_id, base_map_options)
	if not _check(compass_map_options.size() > base_map_options.size(), "old compass adds an extra map choice"):
		return
	if not _check(main.last_map_relic_extra_choice_count > 0 and main.last_map_relic_extra_choice_ids.size() == main.last_map_relic_extra_choice_count, "old compass records added map choices"):
		return
	main.run_relic_ids.erase("old_compass")
	var ember_event_pool: Array = main._map_config_for_current_character("chapter_one").get("event_pool", [])
	if not _check(not ember_event_pool.has("arc_workbench") and not ember_event_pool.has("livewire_nest"), "default character map event pool excludes arc tinker dedicated events"):
		return
	if not _check(not ember_event_pool.has("scar_chapel") and not ember_event_pool.has("red_wick_altar"), "default character map event pool excludes pyre ascetic dedicated events"):
		return
	if not _check(main.event_data.get("events", []).size() >= 10, "chapter one event pool has enough events"):
		return
	if not _check(main.map_generation_data.get("chapter_one", {}).get("event_pool", []).has("coolant_cache"), "map generation references expanded event pool"):
		return
	if main._is_pc_layout():
		if not _check(main.combat_hud_row.visible and main.last_combat_hud_block_count == 5, "PC combat keeps five long-lived resources in the top HUD"):
			return
		if not _check(main.last_combat_hud_text.contains("生命") and main.last_combat_hud_text.contains("金币") and main.last_combat_hud_text.contains("势能") and main.last_combat_hud_text.contains("回合"), "PC combat top HUD records long-lived battle status"):
			return
		if not _check(not main.last_combat_hud_text.contains("抽牌") and not main.last_combat_hud_text.contains("弃牌") and not main.last_combat_hud_text.contains("消耗"), "PC combat removes card piles from the top HUD"):
			return
		if not _check(main.last_hand_dock_control_count == 4 and main.hand_left_hud.visible and main.hand_right_hud.visible, "PC combat renders energy and pile controls beside the hand"):
			return
		var first_hud_block := main.combat_hud_row.get_child(0) as Control
		if not _check(_has_generated_texture_background(first_hud_block), "PC combat HUD uses generated resource chip art"):
			return
		if not _check(main.last_combat_hud_icon_node_count >= main.last_combat_hud_block_count, "PC combat HUD uses SVG icons instead of single-character badges"):
			return
		if not _check(_control_has_texture_named(first_hud_block, "HudIcon"), "PC combat first HUD block contains an icon texture"):
			return
		if not _check(main.last_combat_hud_text.contains("回合"), "PC combat HUD records turn and phase information"):
			return
		main._on_pile_hud_pressed("抽牌")
		await process_frame
		if not _check(main.pile_view_open and main.last_pile_view_visible and main.last_pile_view_kind == "draw", "PC combat draw pile HUD opens the pile viewer"):
			return
		if not _check(main.last_pile_view_tab_count == 3 and main.last_pile_view_card_count == main.combat.draw_pile.size(), "pile viewer renders tabs and the current draw pile count"):
			return
		if not _check(main.last_pile_view_art_node_count == main.last_pile_view_card_count, "pile viewer renders card artwork for every visible pile card"):
			return
		main._open_pile_view("discard")
		await process_frame
		if not _check(main.last_pile_view_kind == "discard" and main.last_pile_view_card_count == main.combat.discard_pile.size(), "pile viewer switches to the discard pile"):
			return
		main._close_pile_view(false)
		if not _check(not main.pile_view_open and not main.pile_overlay.visible, "pile viewer closes without leaving a blocking overlay"):
			return
	else:
		if not _check(main.combat_hud_row.visible and main.last_combat_hud_block_count >= 7, "compact combat renders structured resource HUD blocks"):
			return
		if not _check(main.last_combat_hud_text.contains("生命") and main.last_combat_hud_text.contains("能量") and main.last_combat_hud_text.contains("势能"), "compact combat HUD records primary player resources"):
			return
		if not _check(main.last_combat_hud_text.contains("抽牌") and main.last_combat_hud_text.contains("弃牌") and main.last_combat_hud_text.contains("消耗"), "compact combat HUD records card pile counts"):
			return
	if main._is_pc_layout():
		if not _check(not main.title_label.visible and not main.run_label.visible and not main.status_label.visible, "PC combat hides page chrome to prioritize the battle stage"):
			return
		if not _check(not main.character_frame.visible and main.last_character_panel_style_applied and main.character_frame.get_theme_stylebox("panel") != null, "PC combat hides the redundant player panel while keeping its style configured"):
			return
	else:
		if not _check(main.character_frame.visible and main.last_character_panel_style_applied and main.character_frame.get_theme_stylebox("panel") != null, "compact combat renders a styled player panel"):
			return
		if not _check(main.relic_belt_row.visible and main.last_relic_belt_layout_count == min(main.run_relic_ids.size(), main._relic_belt_cap()), "compact player panel renders a compact relic icon belt"):
			return
	if not _check(main.last_relic_belt_icon_node_count == main.last_relic_belt_layout_count and main.last_relic_icon_loaded, "relic belt loads relic icons from art manifest"):
		return
	if not _check(main._asset_loaded(main.last_relic_icon_path), "relic belt icon path is a valid resource"):
		return
	if not _check(main.last_relic_belt_tooltips.size() == main.last_relic_belt_layout_count and main.last_relic_belt_tooltips[0].contains("余烬瓶"), "relic belt records readable relic tooltips"):
		return
	if not _check(main.battle_board_panel.visible and main.last_battle_board_style_applied and main.battle_board_panel.get_theme_stylebox("panel") != null, "combat renders a styled battle board"):
		return
	if not _check(main.battle_background.visible and main.battle_background.texture != null, "combat renders a visible chapter battle background"):
		return
	if not _check(main.last_battle_background_chapter_id == main.current_chapter_id, "combat records the current chapter for battle background"):
		return
	if not _check(main.last_battle_background_loaded and main._asset_loaded(main.last_battle_background_path), "combat loads battle background from art manifest"):
		return
	if not _check(main.enemy_stage_panel.visible and main.last_enemy_stage_style_applied and main.enemy_stage_panel.get_theme_stylebox("panel") != null, "combat renders a styled enemy stage"):
		return
	if main._is_pc_layout():
		if not _check(main.battle_forecast_layer != null and main.last_stage_forecast_marker_count >= main.combat.enemies.size(), "PC combat renders battlefield forecast markers"):
			return
		if not _check(main.last_stage_forecast_icon_count >= main.combat.enemies.size(), "PC combat renders visual intent icons"):
			return
		if not _check(main.battle_foreground_layer != null and main.last_stage_foreground_layer_count >= 4, "PC combat renders foreground depth shading over the battle stage"):
			return
		if not _check(main.player_stage_plate != null and main.last_player_stage_plate_visible, "PC combat renders a player health plate inside the battle stage"):
			return
		if not _check(main.last_player_stage_hp_text == "%d/%d" % [int(main.combat.player.get("hp", 0)), int(main.combat.player.get("max_hp", 0))], "player stage plate records current health"):
			return
		if not _check(main.player_stage_block_icon != null and main.player_stage_block_icon.texture != null and not main.last_player_stage_block_text.is_empty(), "player stage plate uses a shield icon and visible block value"):
			return
	if not _check(main.hand_frame.visible and main.last_hand_frame_style_applied and main.hand_frame.get_theme_stylebox("panel") != null, "combat renders a styled hand frame"):
		return
	if not _check(main.hand_scroll.visible and main.hand_row.get_parent() == main.hand_scroll, "combat hand is constrained inside a horizontal scroll region"):
		return
	if not _check(not main.reward_row.visible and not main.last_combat_reward_region_visible, "player combat phase hides empty reward region"):
		return
	if not _check(main.last_combat_layout_estimated_height <= (720.0 if main._is_pc_layout() else 700.0), "combat layout keeps core regions within first viewport budget"):
		return
	if not _check(main.last_combat_layout_available_height >= 720.0, "combat layout reads the configured viewport height"):
		return
	if not _check(main.last_combat_layout_overflow <= 0.0 and main.last_combat_layout_total_height <= main.last_combat_layout_available_height, "combat layout keeps the full page inside the viewport"):
		return
	if main._is_pc_layout():
		if not _check(main.battle_board_panel.custom_minimum_size.y <= 430.0 and main.log_label.custom_minimum_size.y <= 40.0, "PC combat uses a large stage and compact log strip"):
			return
		if not _check(main.hand_frame.custom_minimum_size.y <= 230.0 and main.hand_row.custom_minimum_size.y <= 220.0, "PC combat keeps vertical hand cards inside the 720p budget"):
			return
	else:
		if not _check(main.battle_board_panel.custom_minimum_size.y <= 300.0 and main.log_label.custom_minimum_size.y <= 100.0, "compact combat layout uses compact board and log heights"):
			return
		if not _check(main.hand_frame.custom_minimum_size.y <= 150.0 and main.hand_row.custom_minimum_size.y <= 140.0, "compact combat layout uses a compact hand frame"):
			return
	if not _check(main.enemy_row.get_child_count() == main.combat.enemies.size(), "combat renders one visual panel per enemy"):
		return
	if not _check(main.enemy_visuals_by_id.size() >= main.combat.enemies.size(), "combat indexes enemy visuals for feedback effects"):
		return
	if not _check(main.last_enemy_intent_badge_count >= main.combat.enemies.size(), "combat renders one intent badge per enemy"):
		return
	if not _check(main.last_enemy_intent_badge_texts.size() >= main.combat.enemies.size(), "combat records enemy intent badge text telemetry"):
		return
	var first_enemy_intent: Dictionary = main.combat.enemies[0].get("current_action", {}).get("intent", {})
	var first_enemy_intent_text: String = main._intent_text(first_enemy_intent)
	if not _check(not first_enemy_intent_text.is_empty() and main.last_enemy_intent_badge_texts[0].contains(first_enemy_intent_text), "enemy intent badge text matches current enemy action"):
		return
	var first_enemy_panel = main.enemy_row.get_child(0)
	if not _check(first_enemy_panel.get_child_count() >= 3, "enemy visual panel includes art, intent badge, and button"):
		return
	var first_enemy_texture_rect := first_enemy_panel.find_child("EnemyStageArt", true, false) as TextureRect
	if first_enemy_texture_rect == null:
		first_enemy_texture_rect = first_enemy_panel.get_child(0) as TextureRect
	if not _check(first_enemy_texture_rect != null and first_enemy_texture_rect.texture != null, "enemy visual panel loads placeholder art"):
		return
	var first_enemy_badge := first_enemy_panel.find_child("EnemyStageIntentBadge", true, false) as PanelContainer
	if first_enemy_badge == null:
		first_enemy_badge = first_enemy_panel.get_child(1) as PanelContainer
	if not _check(first_enemy_badge != null and first_enemy_badge.get_theme_stylebox("panel") != null, "enemy visual panel renders a styled intent badge"):
		return
	var first_enemy_badge_label_text := _first_label_text(first_enemy_badge)
	if not _check(not first_enemy_badge_label_text.is_empty(), "enemy intent badge renders readable label text"):
		return
	if main._is_pc_layout():
		var first_enemy_hit_area := first_enemy_panel.find_child("EnemyHitArea", true, false) as Button
		if not _check(first_enemy_hit_area != null and first_enemy_hit_area.get_theme_stylebox("normal") != null, "PC enemy uses a styled full-body click target"):
			return
		var first_enemy_hp_plate := first_enemy_panel.find_child("EnemyHpPlate", true, false) as PanelContainer
		if not _check(first_enemy_hp_plate != null and first_enemy_hp_plate.custom_minimum_size.y <= 30.0 and first_enemy_hp_plate.custom_minimum_size.x <= 160.0, "PC enemy health plate stays compact at the feet"):
			return
	if not _check(main.hand_row.get_child_count() == main.combat.hand.size(), "combat renders one styled hand button per card"):
		return
	if main._is_pc_layout():
		if not _check(_has_generated_texture_background(main.hand_frame), "PC hand tray uses generated UI art"):
			return
		if not _check(_has_generated_texture_background(main.end_turn_button), "PC end-turn button uses generated UI art"):
			return
		if not _check(_control_has_texture_named(main.deck_button, "CompactButtonIcon") and _control_has_texture_named(main.settings_button, "CompactButtonIcon"), "PC combat utility buttons use HUD icons"):
			return
	var first_hand_button = main.hand_row.get_child(0)
	var first_hand_button_cast := first_hand_button as Button
	if not _check(first_hand_button_cast != null and first_hand_button_cast.get_theme_stylebox("normal") != null, "hand card button has a stylebox"):
		return
	if main._is_pc_layout():
		if not _check(first_hand_button_cast.custom_minimum_size.y <= 220.0 and first_hand_button_cast.custom_minimum_size.x <= 170.0, "PC hand card button keeps a vertical card proportion in the visible combat viewport"):
			return
	else:
		if not _check(first_hand_button_cast.custom_minimum_size.y <= 140.0 and first_hand_button_cast.custom_minimum_size.x <= 136.0, "compact hand card button is sized for the visible combat viewport"):
			return
	if not _check(main.last_hand_card_layout_count == main.combat.hand.size(), "hand card buttons use structured card layout"):
		return
	if not _check(main.last_hand_card_art_node_count == main.combat.hand.size() and main.last_hand_card_art_loaded, "hand card layout loads art manifest assets"):
		return
	if not _check(main._asset_loaded(main.last_hand_card_art_path), "hand card art path is a valid resource"):
		return
	if not _check(first_hand_button_cast.get_child_count() >= 1 and first_hand_button_cast.get_child(0) is MarginContainer, "hand card button contains a visual layout root"):
		return
	if main._is_pc_layout():
		if not _check(_pc_hand_card_uses_full_background(first_hand_button_cast), "PC hand card uses full-card art as the background"):
			return
		if not _check(_control_has_node_named(first_hand_button_cast, "CardRarityGem") and _control_has_node_named(first_hand_button_cast, "CardLeftRail"), "PC hand card renders physical card trim and rarity gem"):
			return
		if not _check(main.last_hand_card_material_frame_count == main.combat.hand.size() and _control_has_node_named(first_hand_button_cast, "CardMaterialFrame"), "PC hand cards load bitmap material frames"):
			return
	var first_hand_card: Dictionary = main.combat.hand[0]
	if not _check(main.last_hand_card_cost_texts[0] == str(int(first_hand_card.get("cost", 0))), "hand card layout records visible cost badge"):
		return
	if not _check(main.last_hand_card_name_texts[0] == str(first_hand_card.get("name", "卡牌")), "hand card layout records visible card name"):
		return
	if not _check(main.last_hand_card_type_texts[0] == main._card_type_display_name(str(first_hand_card.get("type", ""))), "hand card layout records localized card type"):
		return
	if not _check(main.last_hand_card_rarity_texts[0] == main._rarity_display_name(str(first_hand_card.get("rarity", ""))), "hand card layout records localized rarity"):
		return
	var expected_potion_children: int = main._max_potion_slots() if main._is_pc_layout() else main._max_potion_slots() + 1
	if not _check(main.potion_row.get_child_count() == expected_potion_children, "combat renders potion slots"):
		return
	if main._is_pc_layout():
		if not _check(main.potion_row.get_parent() == main.combat_hud_row, "PC combat keeps potion belt in the HUD instead of over the battlefield"):
			return
	var first_potion_index := 0 if main._is_pc_layout() else 1
	var first_potion_button := main.potion_row.get_child(first_potion_index) as Button
	if not _check(first_potion_button != null and first_potion_button.get_child_count() >= 1 and first_potion_button.get_child(0) is MarginContainer, "potion slot button contains a structured item layout"):
		return
	if not _check(main.last_potion_slot_layout_count == main._max_potion_slots(), "potion slots use structured item layouts"):
		return
	if main._is_pc_layout():
		if not _check(main.last_potion_slot_icon_node_count <= main.last_potion_slot_layout_count, "PC empty potion sockets do not render fake potion icons"):
			return
	elif not _check(main.last_potion_slot_icon_node_count == main.last_potion_slot_layout_count, "potion slot layouts load icon nodes"):
		return
	if not _check(main.last_potion_icon_loaded and main._asset_loaded(main.last_potion_icon_path), "potion slot icon path loads from art manifest"):
		return
	if main._is_pc_layout():
		if not _check(not main.feedback_label.visible and main.last_feedback_label_suppressed_for_stage, "PC combat replaces routine start feedback toast with stage effects"):
			return
	else:
		if not _check(main.feedback_label.visible, "combat feedback label is visible after combat start feedback"):
			return
	if not _check(main.feedback_overlay != null and main.feedback_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "combat feedback overlay exists and ignores input"):
		return
	if not _check(main.cinematic_overlay != null and main.cinematic_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "cinematic overlay exists and ignores input"):
		return
	var playable_card_index: int = _first_playable_card_index(main)
	if not _check(playable_card_index >= 0, "combat has a playable card for card motion feedback"):
		return
	var playable_card: Dictionary = main.combat.hand[playable_card_index]
	var playable_card_type: String = str(playable_card.get("type", ""))
	main._on_card_previewed(playable_card_index)
	if not _check(main.last_card_preview_index == playable_card_index, "card hover preview records hand index"):
		return
	if not _check(not main.last_card_preview_card_id.is_empty(), "card hover preview records card id"):
		return
	if not _check(not main.last_card_preview_target_id.is_empty(), "card hover preview records target id"):
		return
	if not _check(main.last_card_target_line_count > 0, "card hover preview requests a target line"):
		return
	var target_line_count_before_play: int = main.last_card_target_line_count
	var play_animation_count_before: int = main.last_card_play_animation_count
	var player_action_count_before: int = main.last_player_action_animation_count
	main._on_card_pressed(playable_card_index)
	if not _check(main.last_card_play_animation_count == play_animation_count_before + 1, "playing a card requests card flight animation"):
		return
	if not _check(not main.last_card_play_card_id.is_empty(), "card flight records played card id"):
		return
	if not _check(not main.last_card_play_target_id.is_empty(), "card flight records target id"):
		return
	if not _check(main.last_card_play_trajectory_points.size() == 3, "card flight records a three-point trajectory"):
		return
	if not _check(main.last_card_target_line_count > target_line_count_before_play, "playing a card also requests a persistent target line"):
		return
	if not _check(main.last_card_trail_segment_count >= 16, "card targeting records a curved multi-segment trajectory"):
		return
	if not _check(main.last_player_action_animation_count == player_action_count_before + 1, "playing a card requests a player stage action"):
		return
	if not _check(main.last_player_action_animation_type == playable_card_type, "player stage action follows the played card type"):
		return
	if not _check(main.last_card_effect_profile == _expected_card_effect_profile(playable_card_type), "card flight records type-specific effect profile"):
		return
	if not _check(main.last_card_particle_count > 0, "card flight records type-specific particle count"):
		return
	if not _check(main.last_card_audio_event == _expected_card_audio_event(playable_card_type), "card flight maps to type-specific audio event"):
		return
	var vfx_profile: Dictionary = main._vfx_profile(main.last_card_effect_profile)
	if not _check(not vfx_profile.is_empty(), "card flight effect profile comes from vfx config"):
		return
	if not _check(int(vfx_profile.get("particle_count", 0)) == main.last_card_particle_count, "card flight particle count comes from vfx config"):
		return
	if not _check(str(vfx_profile.get("audio_event", "")) == main.last_card_audio_event, "card flight audio event comes from vfx config"):
		return
	if not _check(str(vfx_profile.get("sprite_path", "")) == main.last_card_vfx_asset_path, "card flight vfx asset path comes from vfx config"):
		return
	if not _check(main.last_card_vfx_asset_loaded, "card flight loads configured vfx asset"):
		return
	if not _check(main.last_card_flight_uses_card_art, "card flight uses the played card art instead of a flat text tile"):
		return
	var enemy_action_payloads: Array[Dictionary] = main._capture_enemy_action_visuals()
	if not _check(not enemy_action_payloads.is_empty(), "combat exposes enemy stage actions from forecast intents"):
		return
	main._play_enemy_action_visuals(enemy_action_payloads)
	if not _check(main.last_enemy_action_animation_count == enemy_action_payloads.size(), "enemy stage actions animate every living forecast actor"):
		return
	if not _check(main.last_enemy_action_ids.size() == enemy_action_payloads.size(), "enemy stage action telemetry records actor ids"):
		return

	main.run_potion_ids = ["volatile_vial"]
	var enemy_reaction_count_before: int = main.last_enemy_reaction_animation_count
	var first_enemy_hp_before: int = int(main.combat.enemies[0].get("hp", 0))
	main._on_potion_pressed(0)
	if not _check(main.run_potion_ids.is_empty(), "using a potion consumes a run potion slot"):
		return
	if not _check(int(main.combat.enemies[0].get("hp", 0)) == first_enemy_hp_before - 12, "main scene potion button applies combat effect"):
		return
	if main._is_pc_layout():
		if not _check(not main.feedback_label.visible and main.last_feedback_label_suppressed_for_stage, "PC combat keeps routine damage feedback in battlefield VFX instead of a toast"):
			return
	else:
		if not _check(main.feedback_label.visible and not main.feedback_label.text.is_empty(), "combat feedback label shows latest feedback"):
			return
	if not _check(_has_feedback_type(main.last_feedback_events, "enemy_hit"), "main scene consumes enemy hit feedback"):
		return
	if not _check(main.last_feedback_audio_event == "hit", "enemy hit feedback maps to hit audio event"):
		return
	if not _check(main.last_flash_target_id == str(main.combat.enemies[0].get("id", "")), "enemy hit feedback records target flash id"):
		return
	if not _check(main.last_feedback_visual_type == "enemy_hit", "enemy hit feedback records primary visual type"):
		return
	if not _check(main.last_hit_stop_duration > 0.0, "enemy hit feedback requests hit stop"):
		return
	if not _check(main.last_screen_shake_intensity > 0.0, "enemy hit feedback requests screen shake"):
		return
	if not _check(main.last_floating_text_count > 0, "enemy hit feedback requests floating combat text"):
		return
	if not _check(main.last_impact_effect_type == "enemy_hit", "enemy hit feedback requests impact effect"):
		return
	if not _check(main.last_impact_effect_count > 0, "enemy hit feedback counts impact effects"):
		return
	var hit_vfx_profile: Dictionary = main._vfx_profile(main.last_impact_vfx_profile)
	if not _check(main.last_impact_vfx_profile == main._feedback_vfx_profile("enemy_hit"), "enemy hit impact uses configured feedback vfx profile"):
		return
	if not _check(str(hit_vfx_profile.get("sprite_path", "")) == main.last_impact_vfx_asset_path, "enemy hit impact records configured vfx asset path"):
		return
	if not _check(main.last_impact_vfx_asset_loaded, "enemy hit impact loads configured vfx asset"):
		return
	if not _check(int(hit_vfx_profile.get("ray_count", 0)) == main.last_impact_ray_count, "enemy hit impact uses configured ray count"):
		return
	if not _check(main.last_enemy_reaction_animation_count > enemy_reaction_count_before, "enemy hit feedback requests actor recoil motion"):
		return
	var player_reaction_count_before: int = main.last_player_reaction_animation_count
	main.combat.feedback_events.append({
		"type": "player_hit",
		"message": "玩家动作反馈测试",
		"target_id": "player",
		"amount": 3,
		"severity": "danger",
		"turn": main.combat.turn
	})
	main._refresh_feedback()
	if not _check(main.last_player_reaction_animation_count > player_reaction_count_before, "player hit feedback requests actor recoil motion"):
		return
	var block_reaction_count_before: int = main.last_player_reaction_animation_count
	main.combat.feedback_events.append({
		"type": "block_absorb",
		"message": "护甲吸收 6",
		"target_id": "player",
		"amount": 6,
		"severity": "block",
		"turn": main.combat.turn
	})
	main._refresh_feedback()
	if not _check(main.last_feedback_audio_event == "block", "shield absorption feedback maps to block audio"):
		return
	if not _check(main.last_impact_vfx_profile == main._feedback_vfx_profile("block_absorb"), "shield absorption uses configured shield impact profile"):
		return
	if not _check(main.last_player_reaction_animation_count > block_reaction_count_before, "shield absorption requests a defensive player pulse"):
		return

	main.user_settings["screen_shake_enabled"] = false
	main.user_settings["hit_stop_enabled"] = false
	main.user_settings["floating_text_enabled"] = false
	main._save_user_settings()
	main.combat.feedback_events.append({
		"type": "enemy_hit",
		"message": "设置测试命中",
		"target_id": str(main.combat.enemies[0].get("id", "")),
		"amount": 4,
		"severity": "hit",
		"turn": main.combat.turn
	})
	main._refresh_feedback()
	if not _check(main.last_hit_stop_duration == 0.0 and main.last_screen_shake_intensity == 0.0 and main.last_floating_text_count == 0, "disabled feedback settings suppress hit stop, shake, and floating text requests"):
		return
	if not _check(main.last_impact_effect_count > 0, "disabled feedback settings keep impact vfx active"):
		return
	main._on_settings_reset_pressed()

	var first_enemy_id: String = str(main.combat.enemies[0].get("id", ""))
	main.combat.feedback_events.append({
		"type": "phase",
		"message": "炉心主教：过载祷文",
		"target_id": first_enemy_id,
		"amount": 1,
		"severity": "phase",
		"turn": main.combat.turn
	})
	main._refresh_feedback()
	if not _check(main.last_cinematic_event_type == "phase", "phase feedback opens cinematic prompt"):
		return
	if not _check(main.last_cinematic_title.contains("BOSS"), "phase cinematic prompt has boss title"):
		return
	if not _check(main.last_cinematic_subtitle.contains("过载祷文"), "phase cinematic prompt shows phase message"):
		return
	if not _check(main.cinematic_overlay.visible, "phase cinematic prompt is visible"):
		return
	if not _check(main.last_feedback_audio_event == "phase", "phase feedback maps to phase audio"):
		return
	if not _check(main.last_impact_effect_type == "phase", "phase feedback requests phase impact effect"):
		return
	var phase_vfx_profile: Dictionary = main._vfx_profile(main.last_impact_vfx_profile)
	if not _check(main.last_impact_vfx_profile == main._feedback_vfx_profile("phase"), "phase impact uses configured feedback vfx profile"):
		return
	if not _check(str(phase_vfx_profile.get("sprite_path", "")) == main.last_impact_vfx_asset_path, "phase impact records configured vfx asset path"):
		return
	if not _check(main.last_impact_vfx_asset_loaded, "phase impact loads configured vfx asset"):
		return
	if not _check(int(phase_vfx_profile.get("ray_count", 0)) == main.last_impact_ray_count, "phase impact uses configured ray count"):
		return
	if not _check(main.last_phase_animation_target_id == first_enemy_id, "phase feedback requests boss character animation"):
		return

	main.combat.feedback_events.append({
		"type": "won",
		"message": "战斗胜利",
		"target_id": "",
		"amount": 0,
		"severity": "success",
		"turn": main.combat.turn
	})
	main._refresh_feedback()
	if not _check(main.last_cinematic_event_type == "won", "victory feedback opens cinematic prompt"):
		return
	if not _check(main.last_cinematic_title.contains("胜利"), "victory cinematic prompt has victory title"):
		return
	if not _check(main.last_feedback_audio_event == "victory", "victory feedback maps to victory audio"):
		return

	var gold_before_combat_reward: int = main.run_gold
	main.combat.phase = "won"
	main._refresh_combat()
	if not _check(main.last_combat_gold_reward > 0 and main.run_gold == gold_before_combat_reward + main.last_combat_gold_reward, "combat reward grants configured gold once"):
		return
	if not _check(main.last_reward_gold_panel_count == 1, "combat reward screen renders a gold reward panel"):
		return
	var gold_after_combat_reward: int = main.run_gold
	main._refresh_combat()
	if not _check(main.run_gold == gold_after_combat_reward, "refreshing combat reward screen does not grant duplicate gold"):
		return
	if not _check(main.last_reward_card_layout_count == main.reward_options.size() and main.last_reward_card_layout_count > 0, "combat rewards use structured card layout"):
		return
	if not _check(main.last_reward_card_art_node_count == main.last_reward_card_layout_count and main.last_reward_card_art_loaded, "combat reward card layouts load art manifest assets"):
		return
	if not _check(main.last_reward_generation_context == "potion_reward" and main.last_generated_card_reward_rarities.size() == main.reward_options.size(), "combat rewards record weighted rarity generation"):
		return
	if not _check(main.last_reward_potion_layout_count == main.potion_reward_options.size(), "combat potion rewards use structured item layout"):
		return
	if not _check(main.last_reward_potion_icon_node_count == main.last_reward_potion_layout_count, "combat potion reward layouts load icon nodes"):
		return
	if not _check(main.last_reward_action_button_count >= 2, "combat reward screen uses structured action buttons"):
		return
	if not _check(main.last_reward_action_icon_node_count == main.last_reward_action_button_count, "combat reward action buttons load icon nodes"):
		return
	if main._is_pc_layout():
		var reward_action_column := main.reward_row.get_node_or_null("RewardActionColumn") as VBoxContainer
		if not _check(reward_action_column != null and reward_action_column.get_child_count() == main.last_reward_action_button_count, "PC combat reward actions share one dedicated command column"):
			return
	var first_reward_card_button := _first_structured_button(main.reward_row)
	if not _check(first_reward_card_button != null and first_reward_card_button.get_child_count() >= 1 and first_reward_card_button.get_child(0) is MarginContainer, "combat reward card button contains a visual layout root"):
		return
	main._advance_to_next_node()
	if not _check(main.current_node_id.is_empty(), "completed node opens map choice"):
		return
	if not _check(main.last_music_context == "map", "map choice uses map music context"):
		return
	if not _check(not main.available_node_ids.is_empty(), "map choice exposes reachable nodes"):
		return
	if not _check(main.map_view.visible, "map choice shows visual map view"):
		return
	if not _check(main.map_scroll != null and main.map_scroll.visible and main.map_view.get_parent() == main.map_scroll, "map choice constrains the visual map inside a scroll region"):
		return
	if not _check(main.last_combat_layout_overflow <= 0.0 and main.map_view.custom_minimum_size.y <= 680.0 and main.log_label.custom_minimum_size.y <= 120.0, "map choice keeps immersive map, log, and controls inside the viewport"):
		return
	if not _check(main.map_view.get_node_button_count() == main.route_nodes.size(), "map view renders every route node"):
		return
	if not _check(main.map_view.get_available_button_count() == main.available_node_ids.size(), "map view marks available nodes"):
		return
	if not _check(main.log_label.text.contains("地图图例"), "map choice shows map legend"):
		return
	if not _check(main.last_map_preview_text.contains("节点详情") and main.last_map_preview_text.contains("后续可达"), "map choice shows node detail preview"):
		return
	if not _check(main.last_map_preview_text.contains("风险：") and main.last_map_preview_text.contains("收益："), "map node preview shows risk and reward forecast"):
		return
	if not _check(not main.last_map_preview_risk_level.is_empty() and not main.last_map_preview_reward_summary.is_empty(), "map node preview records risk level and reward summary"):
		return
	if not _check(not main.last_map_preview_node_id.is_empty(), "map choice records default preview node"):
		return
	var preview_node_id: String = str(main.available_node_ids[0])
	main._on_map_node_previewed(preview_node_id)
	if not _check(main.last_map_preview_node_id == preview_node_id and main.log_label.text.contains("节点详情"), "map node preview updates detail panel"):
		return
	if not _check(main.log_label.text.contains("风险：") and main.log_label.text.contains("收益："), "map node preview keeps risk and reward visible in the log panel"):
		return
	if not _check(main.map_view.previewed_node_id == preview_node_id, "map node preview highlights the active route in map view"):
		return
	if not _check(main.map_view.get_previewed_successor_count() == main._successor_node_ids(preview_node_id).size(), "map route preview stores successor count"):
		return

	_jump_to_node_type(main, "campfire")
	if not _check(str(main._current_node().get("type", "")) == "campfire", "campfire node can start"):
		return
	if not _check(main.last_music_context == "campfire", "campfire uses campfire music context"):
		return
	if not _check(main.last_campfire_button_style_count > 0, "campfire actions use styled buttons"):
		return
	if not _check(main.last_campfire_card_layout_count > 0 and main.last_campfire_card_art_node_count == main.last_campfire_card_layout_count, "campfire upgrade candidates use structured card layout"):
		return
	var first_campfire_card_button := main.reward_row.get_child(2) as Button
	if not _check(first_campfire_card_button != null and first_campfire_card_button.get_child_count() >= 1 and first_campfire_card_button.get_child(0) is MarginContainer, "campfire upgrade card button contains a visual layout root"):
		return
	var first_card_before: String = str(main.run_deck_ids[0])
	var first_card: Dictionary = main._card_by_id(first_card_before)
	if not _check(main._upgrade_preview_text(first_card).contains("=>"), "upgrade preview shows before and after"):
		return
	main._on_upgrade_card_pressed(0)
	if not _check(str(main.run_deck_ids[0]) == "%s+" % first_card_before, "campfire upgrades selected card"):
		return
	main._on_deck_view_pressed()
	if not _check(main.deck_view_open, "deck view opens"):
		return
	if not _check(main.log_label.text.contains("+"), "deck view shows upgraded card marker"):
		return
	if not _check(main.last_deck_view_toolbar_visible and main.last_deck_view_filter_button_count == 6 and main.last_deck_view_sort_option_count == 4, "deck view renders filter and sort controls"):
		return
	if not _check(main.last_deck_view_visible_card_count == main.run_deck_ids.size() and main.last_deck_view_card_layout_count == main.run_deck_ids.size(), "deck view renders the complete deck instead of a five-card preview"):
		return
	if not _check(main.last_deck_view_card_art_node_count == main.last_deck_view_card_layout_count, "deck view renders artwork for every visible card"):
		return
	var first_deck_preview_button := main.reward_row.get_child(1) as Button
	if not _check(first_deck_preview_button != null and first_deck_preview_button.get_child_count() >= 1 and first_deck_preview_button.get_child(0) is MarginContainer, "deck view preview card contains a visual layout root"):
		return
	var deck_summary: Dictionary = main._deck_summary()
	main._on_deck_view_filter_pressed("attack")
	if not _check(main.deck_view_filter == "attack" and main.last_deck_view_visible_card_count == int(deck_summary.get("attack", 0)), "deck view filters attack cards"):
		return
	main._on_deck_view_filter_pressed("upgraded")
	if not _check(main.last_deck_view_visible_card_count == int(deck_summary.get("upgraded", 0)), "deck view filters upgraded cards"):
		return
	main.deck_view_filter = "all"
	main.deck_view_sort = "cost"
	main._refresh_deck_view()
	var cost_sorted_cards: Array[Dictionary] = main._deck_view_cards()
	for i in range(1, cost_sorted_cards.size()):
		if not _check(int(cost_sorted_cards[i - 1].get("cost", 0)) <= int(cost_sorted_cards[i].get("cost", 0)), "deck cost sorting is nondecreasing"):
			return
	if not _check(main.last_deck_view_cost_curve_text.contains("0费") and main.last_deck_view_cost_curve_text.contains("平均"), "deck view reports a cost curve and average cost"):
		return
	main._on_close_deck_view_pressed()
	if not _check(not main.deck_view_open, "deck view closes"):
		return
	if not _check(main.current_node_id.is_empty() and not main.available_node_ids.is_empty(), "campfire returns to map choice after upgrade"):
		return

	_jump_to_node_type(main, "campfire")
	main.run_hp = 10
	main._on_campfire_heal_pressed()
	if not _check(main.run_hp > 10, "campfire healing restores HP"):
		return

	_jump_to_event_id(main, "broken_reactor")
	if not _check(str(main._current_node().get("type", "")) == "event", "event node can start"):
		return
	if not _check(main.last_music_context == "event", "event node uses event music context"):
		return
	if not _check(main._discovered_ids("events").has("broken_reactor"), "entering an event discovers it in the profile"):
		return
	var event: Dictionary = main._event_by_id("broken_reactor")
	if not _check(main.reward_row.get_child_count() >= event.get("choices", []).size() + 1 and main.reward_row.get_child(0) is PanelContainer, "event screen renders an illustrated story panel before choices"):
		return
	if not _check(main.last_event_art_loaded and main._asset_loaded(main.last_event_art_path), "event story panel loads art from the manifest"):
		return
	if not _check(main.last_event_panel_title == "破裂反应炉" and main.last_event_panel_body.contains("废弃反应炉"), "event story panel records readable event title and body"):
		return
	if not _check(main.last_event_panel_choice_count == event.get("choices", []).size(), "event story panel records the visible choice count"):
		return
	if not _check(main.last_event_choice_style_count > 0, "event choices use styled buttons"):
		return
	if not _check(main.last_event_choice_layout_count == event.get("choices", []).size(), "event choices use structured wrapping layouts"):
		return
	var first_event_choice_button := main.reward_row.get_child(1) as Button
	if not _check(first_event_choice_button != null and first_event_choice_button.get_child_count() >= 1 and first_event_choice_button.get_child(0) is MarginContainer, "event choice button contains a structured text layout"):
		return
	var gold_before_event: int = main.run_gold
	main._on_event_choice_pressed(event.get("choices", [])[0])
	if not _check(main.run_gold == gold_before_event + 35, "event choice applies gold effect"):
		return
	if not _check(main.current_node_id.is_empty() and not main.available_node_ids.is_empty(), "event returns to map choice after choice"):
		return

	_jump_to_node_type(main, "event")
	main.run_potion_ids.clear()
	var potion_event: Dictionary = main._event_by_id("coolant_cache")
	main._on_event_choice_pressed(potion_event.get("choices", [])[0])
	if not _check(main.run_potion_ids.size() == 1, "event choice can grant a potion"):
		return
	if not _check(str(main.run_potion_ids[0]) == "guard_tonic", "event grants the configured potion id"):
		return

	_jump_to_event_id(main, "coolant_cache")
	main.run_potion_ids = ["guard_tonic", "coolant_phial"]
	var blocked_choice: Dictionary = main._event_by_id("coolant_cache").get("choices", [])[0]
	var blocked_reason: String = main._event_choice_blocked_reason(blocked_choice)
	if not _check(blocked_reason.contains("药水槽"), "event choice condition detects full potion slots"):
		return
	main._on_event_choice_pressed(blocked_choice)
	if not _check(main.last_event_choice_blocked_reason.contains("药水槽"), "blocked event choice records blocked reason"):
		return
	if not _check(str(main._current_node().get("event_id", "")) == "coolant_cache", "blocked event choice does not advance node"):
		return

	_jump_to_event_id(main, "lost_caravan")
	main.run_potion_ids.clear()
	var random_choice: Dictionary = main._event_by_id("lost_caravan").get("choices", [])[1]
	var gold_before_random: int = main.run_gold
	main._on_event_choice_pressed(random_choice)
	if not _check(not main.last_event_result_id.is_empty(), "random event choice records selected result id"):
		return
	if not _check(main.last_event_result_id == "coin_cache" or main.last_event_result_id == "volatile_pack", "random event result comes from configured result ids"):
		return
	if main.last_event_result_id == "coin_cache":
		if not _check(main.run_gold == gold_before_random + 30, "random event coin result applies gold"):
			return
	else:
		if not _check(main.run_potion_ids.has("volatile_vial"), "random event potion result applies potion"):
			return
	if not _check(bool(main.completed_event_ids.get("lost_caravan", false)), "one-time event is recorded as completed"):
		return
	if not _check(bool(main._create_save_state().get("completed_event_ids", {}).get("lost_caravan", false)), "save state includes completed one-time events"):
		return

	var chapter_two_pool_before_chain: Array = main._map_config_for_current_character("chapter_two").get("event_pool", [])
	if not _check(not chapter_two_pool_before_chain.has("calibrator_return"), "chain follow-up stays out of chapter two before its prerequisite"):
		return
	_jump_to_event_id(main, "mute_calibrator")
	var chain_start: Dictionary = main._event_by_id("mute_calibrator")
	var chain_gold_before: int = max(main.run_gold, 25)
	main.run_gold = chain_gold_before
	main._on_event_choice_pressed(chain_start.get("choices", [])[0])
	if not _check(main.run_gold == chain_gold_before - 25, "chain event can spend configured gold"):
		return
	if not _check(bool(main.completed_event_ids.get("mute_calibrator", false)), "chain event records the prerequisite flag"):
		return
	var chapter_two_pool_after_chain: Array = main._map_config_for_current_character("chapter_two").get("event_pool", [])
	if not _check(chapter_two_pool_after_chain.has("calibrator_return"), "chain follow-up enters chapter two pool after its prerequisite"):
		return
	var chapter_two_guaranteed_events: Array = main._map_config_for_current_character("chapter_two").get("guaranteed_event_ids", [])
	if not _check(chapter_two_guaranteed_events.has("calibrator_return"), "unlocked chain follow-up is guaranteed to appear once on the chapter two map"):
		return
	if not _check(bool(main._create_save_state().get("completed_event_ids", {}).get("mute_calibrator", false)), "chain prerequisite persists in run save state"):
		return
	_jump_to_event_id(main, "calibrator_return")
	var chain_follow_up: Dictionary = main._event_by_id("calibrator_return")
	var deck_size_before_chain_reward: int = main.run_deck_ids.size()
	main._on_event_choice_pressed(chain_follow_up.get("choices", [])[0])
	if not _check(main.run_deck_ids.size() == deck_size_before_chain_reward + 1 and main.run_deck_ids.has("calibration_protocol"), "chain follow-up grants its event-exclusive card"):
		return
	if not _check(bool(main.completed_event_ids.get("calibrator_return", false)), "chain follow-up records one-time completion"):
		return
	var oversized_card_rewards: Array = main._generate_card_rewards(100)
	if not _check(not _shop_options_have_id(oversized_card_rewards, "calibration_protocol"), "event-exclusive chain card stays out of ordinary reward pools"):
		return

	_jump_to_node_type(main, "treasure")
	if not _check(str(main._current_node().get("type", "")) == "treasure", "treasure node can start"):
		return
	if not _check(main.last_music_context == "reward", "treasure node uses reward music context"):
		return
	if not _check(main.last_treasure_gold_reward >= int(main.economy_data.get("treasure", {}).get("gold_min", 0)), "treasure generates configured gold reward"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer and main.last_combat_layout_overflow <= 0.0, "treasure rewards stay inside a bounded wrapping reward area"):
		return
	if not _check(main.last_treasure_relic_layout_count == main.relic_reward_options.size() and main.last_treasure_relic_layout_count > 0, "treasure relic choices use structured item layout"):
		return
	if not _check(main.last_treasure_relic_icon_node_count == main.last_treasure_relic_layout_count and main.last_relic_icon_loaded, "treasure relic choices load icon nodes"):
		return
	var treasure_summary_panel := main.reward_row.get_child(0) as PanelContainer
	var first_treasure_relic_button := main.reward_row.get_child(1) as Button
	if not _check(treasure_summary_panel != null and first_treasure_relic_button != null and first_treasure_relic_button.get_child_count() >= 1, "treasure screen renders a summary panel before relic choices"):
		return
	var gold_before_treasure: int = main.run_gold
	var relic_count_before_treasure: int = main.run_relic_ids.size()
	var treasure_gold: int = main.last_treasure_gold_reward
	var treasure_relic_id: String = str(main.relic_reward_options[0].get("id", ""))
	main._on_treasure_relic_pressed(treasure_relic_id)
	if not _check(main.run_gold == gold_before_treasure + treasure_gold, "treasure claim grants gold"):
		return
	if not _check(main.run_relic_ids.size() == relic_count_before_treasure + 1 and main.run_relic_ids.has(treasure_relic_id), "treasure claim grants selected relic"):
		return
	if not _check(main.current_node_id.is_empty() and not main.available_node_ids.is_empty(), "treasure returns to map choice after claim"):
		return

	_jump_to_node_type(main, "shop")
	if not _check(str(main._current_node().get("type", "")) == "shop", "shop node can start"):
		return
	if not _check(main.last_music_context == "shop", "shop node uses shop music context"):
		return
	if not _check(main.last_shop_button_style_count >= 4, "shop actions use styled buttons"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer and main.last_combat_layout_overflow <= 0.0, "shop offers stay inside a bounded wrapping reward area"):
		return
	if not _check(main.last_shop_card_layout_count == main.shop_card_options.size() and main.last_shop_card_layout_count > 0, "shop card offers use structured card layout"):
		return
	if not _check(main.last_generated_card_reward_rarities.size() == main.shop_card_options.size(), "shop card generation records rarity results"):
		return
	if not _check(main.last_shop_card_art_node_count == main.last_shop_card_layout_count, "shop card layouts load art nodes"):
		return
	var first_shop_card_button := main.reward_row.get_child(0) as Button
	if not _check(first_shop_card_button != null and first_shop_card_button.get_child_count() >= 1 and first_shop_card_button.get_child(0) is MarginContainer, "shop card button contains a visual layout root"):
		return
	if not _check(main.last_shop_relic_layout_count == main.shop_relic_options.size() and main.last_shop_relic_layout_count > 0, "shop relic offers use structured item layout"):
		return
	if not _check(main.last_shop_relic_icon_node_count == main.last_shop_relic_layout_count and main.last_relic_icon_loaded, "shop relic offers load icon nodes"):
		return
	var first_shop_relic_button := main.reward_row.get_child(main.shop_card_options.size()) as Button
	if not _check(first_shop_relic_button != null and first_shop_relic_button.get_child_count() >= 1 and first_shop_relic_button.get_child(0) is MarginContainer, "shop relic button contains a structured item layout root"):
		return
	if not _check(main.last_shop_potion_layout_count == main.shop_potion_options.size() and main.last_shop_potion_layout_count > 0, "shop potion offers use structured item layout"):
		return
	if not _check(main.last_shop_potion_icon_node_count == main.last_shop_potion_layout_count, "shop potion layouts load icon nodes"):
		return
	var first_shop_potion_button := main.reward_row.get_child(main.shop_card_options.size() + main.shop_relic_options.size()) as Button
	if not _check(first_shop_potion_button != null and first_shop_potion_button.get_child_count() >= 1 and first_shop_potion_button.get_child(0) is MarginContainer, "shop potion button contains a structured item layout root"):
		return
	if not _check(main.last_reward_card_art_loaded and main._asset_loaded(main.last_reward_card_art_path), "shop card buttons load art manifest assets"):
		return
	if not _check(main.last_relic_icon_loaded and main._asset_loaded(main.last_relic_icon_path), "shop relic buttons load art manifest assets"):
		return
	if not _check(main.last_potion_icon_loaded and main._asset_loaded(main.last_potion_icon_path), "shop potion buttons load art manifest assets"):
		return
	var relic_count_before_shop: int = main.run_relic_ids.size()
	var gold_before_relic: int = main.run_gold
	var shop_relic: Dictionary = main.shop_relic_options[0]
	var relic_price: int = main._relic_price(shop_relic)
	main.run_gold = max(main.run_gold, relic_price)
	main._on_shop_buy_relic_pressed(str(shop_relic.get("id", "")), relic_price)
	if not _check(main.run_relic_ids.size() == relic_count_before_shop + 1 and main.run_relic_ids.has(str(shop_relic.get("id", ""))), "shop purchase adds a relic"):
		return
	if not _check(main.run_gold == max(gold_before_relic, relic_price) - relic_price, "shop relic purchase spends gold"):
		return
	if not _check(not _shop_options_have_id(main.shop_relic_options, str(shop_relic.get("id", ""))), "shop relic purchase removes bought offer"):
		return
	var potion_count_before: int = main.run_potion_ids.size()
	var gold_before_potion: int = main.run_gold
	var shop_potion: Dictionary = main._generate_potion_rewards(1)[0]
	var potion_price: int = main._potion_price(shop_potion)
	main.run_gold = max(main.run_gold, potion_price)
	main._on_shop_buy_potion_pressed(str(shop_potion.get("id", "")), potion_price)
	if not _check(main.run_potion_ids.size() == potion_count_before + 1, "shop purchase adds a potion"):
		return
	if not _check(main.run_gold == max(gold_before_potion, potion_price) - potion_price, "shop potion purchase spends gold"):
		return

	var deck_size_before: int = main.run_deck_ids.size()
	var gold_before: int = main.run_gold
	var shop_card: Dictionary = main._generate_card_rewards(1)[0]
	var price: int = main._card_price(shop_card)
	main.run_gold = max(main.run_gold, price)
	main._on_shop_buy_card_pressed(str(shop_card.get("id", "")), price)
	if not _check(main.run_deck_ids.size() == deck_size_before + 1, "shop purchase adds a card"):
		return
	if not _check(main.run_gold == max(gold_before, price) - price, "shop purchase spends gold"):
		return
	var remove_price_before: int = main._remove_card_price()
	var remove_increase: int = int(main.economy_data.get("shop", {}).get("remove_card_price_increase", 0))
	var remove_count_before: int = main.run_shop_remove_count
	var deck_size_before_remove: int = main.run_deck_ids.size()
	var selected_remove_index: int = main.run_deck_ids.size() - 1
	var selected_remove_entry: String = str(main.run_deck_ids[selected_remove_index])
	main.run_gold = remove_price_before
	main._on_shop_remove_card_pressed()
	if not _check(main.shop_remove_selection_open, "shop removal opens card selection mode"):
		return
	if not _check(main.run_deck_ids.size() == deck_size_before_remove, "shop removal does not auto-remove a card before selection"):
		return
	if not _check(main.last_shop_remove_candidate_count == main.run_deck_ids.size() and main.last_shop_remove_card_layout_count == main.last_shop_remove_candidate_count, "shop removal renders selectable deck cards"):
		return
	if not _check(main.last_shop_remove_card_art_node_count == main.last_shop_remove_card_layout_count, "shop removal selectable cards load art nodes"):
		return
	main._on_shop_remove_card_selected(selected_remove_index)
	if not _check(main.run_deck_ids.size() == deck_size_before_remove - 1, "shop removal removes one card"):
		return
	if not _check(not main.run_deck_ids.has(selected_remove_entry), "shop removal removes the selected card"):
		return
	if not _check(main.run_gold == 0, "shop removal spends current removal price"):
		return
	if not _check(main.run_shop_remove_count == remove_count_before + 1, "shop removal increments run removal count"):
		return
	if not _check(main._remove_card_price() == remove_price_before + remove_increase, "shop removal price increases after use"):
		return
	if not _check(int(main._create_save_state().get("run_shop_remove_count", -1)) == main.run_shop_remove_count, "save state includes shop removal count"):
		return
	if not _check(main._profile_stat("cards_removed") >= 1 and main._profile_unlocked_achievements().has("first_surgery"), "shop removal updates profile and unlocks first surgery achievement"):
		return

	_jump_to_node_type(main, "boss")
	if not _check(main.last_music_context == "boss", "active boss combat uses boss music context"):
		return
	main.combat.phase = "won"
	main._refresh_combat()
	if not _check(main.last_music_context == "reward", "won combat reward screen uses reward music context"):
		return
	if not _check(main.reward_row.visible and not main.battle_board_panel.visible, "victory reward screen hides the combat board to fit the viewport"):
		return
	if not _check(main.reward_scroll.visible and main.reward_row is HFlowContainer, "victory reward screen uses a bounded wrapping reward area"):
		return
	if not _check(main.last_combat_layout_overflow <= 0.0 and main.last_combat_layout_total_height <= main.last_combat_layout_available_height, "victory reward screen keeps the full page inside the viewport"):
		return
	if not _check(main.last_combat_gold_reward > 0 and main.last_reward_gold_panel_count == 1, "boss reward screen grants and displays configured gold"):
		return
	if not _check(main.last_reward_relic_layout_count == main.relic_reward_options.size() and main.last_reward_relic_layout_count > 0, "boss relic rewards use structured item layout"):
		return
	if not _check(main.last_reward_relic_icon_node_count == main.last_reward_relic_layout_count and main.last_relic_icon_loaded, "boss relic reward layouts load icon nodes"):
		return
	main._advance_to_next_node()
	if not _check(main.current_chapter_id == "chapter_two", "chapter one boss completion advances to chapter two"):
		return
	if not _check(main.completed_chapter_ids.has("chapter_one"), "completed chapter list records chapter one"):
		return
	if not _check(main._profile_stat("bosses_defeated") >= 1 and main._profile_unlocked_achievements().has("boss_breaker"), "boss completion updates profile and unlocks boss breaker"):
		return
	if not _check(main.player_profile.get("completed_chapters", []).has("chapter_one") and main._profile_unlocked_achievements().has("lower_city_charted"), "chapter one completion is recorded in profile achievements"):
		return
	if not _check(str(main._current_node().get("type", "")) == "combat", "chapter two starts at first combat node"):
		return
	if not _check(main.last_music_context == "combat", "new chapter normal combat returns to combat music context"):
		return
	if not _check(main.last_battle_background_chapter_id == "chapter_two" and main.last_battle_background_path.contains("chapter_two"), "chapter two combat loads chapter-specific battle background"):
		return
	if not _check(_route_has_encounter(main.route_nodes, "chapter_two_boss"), "chapter two route includes configured boss encounter"):
		return
	if not _check(str(main._create_save_state().get("current_chapter_id", "")) == "chapter_two", "save state includes current chapter"):
		return

	_jump_to_node_type(main, "boss")
	main.combat.phase = "won"
	main._advance_to_next_node()
	if not _check(main.current_chapter_id == "chapter_three", "chapter two boss completion advances to chapter three"):
		return
	if not _check(main.completed_chapter_ids.has("chapter_two"), "completed chapter list records chapter two"):
		return
	if not _check(str(main._current_node().get("type", "")) == "combat", "chapter three starts at first combat node"):
		return
	if not _check(main.last_battle_background_chapter_id == "chapter_three" and main.last_battle_background_path.contains("chapter_three"), "chapter three combat loads chapter-specific battle background"):
		return
	if not _check(_route_has_encounter(main.route_nodes, "chapter_three_boss"), "chapter three route includes configured final boss encounter"):
		return

	_jump_to_node_type(main, "boss")
	main.combat.phase = "won"
	main._refresh_combat()
	if not _check(main.last_combat_gold_reward == 0, "final boss reward screen grants no gold"):
		return
	if not _check(main.reward_options.is_empty(), "final boss reward screen grants no card options"):
		return
	if not _check(main.relic_reward_options.is_empty(), "final boss reward screen grants no relic options"):
		return
	if not _check(main.potion_reward_options.is_empty(), "final boss reward screen grants no potion options"):
		return
	if not _check(main.card_reward_done and main.relic_reward_done and main.potion_reward_done, "final boss reward screen allows immediate completion"):
		return
	main._advance_to_next_node()
	if not _check(main.run_completed, "chapter three boss completion ends the run"):
		return
	if not _check(main.last_music_context == "victory", "run completion uses victory music context"):
		return
	if not _check(main.completed_chapter_ids.has("chapter_three"), "completed chapter list records chapter three"):
		return
	if not _check(main.last_run_completion_title.contains("最终胜利"), "run completion has final victory title"):
		return
	if not _check(main.last_run_completion_summary.contains("局外解锁"), "run completion summary shows meta unlocks"):
		return
	if not _check(main.last_run_unlocks.has("挑战模式：回路核心重构"), "run completion unlocks challenge mode"):
		return
	if not _check(main._profile_stat("runs_completed") >= 1 and main._profile_unlocked_achievements().has("circuit_closed"), "full run completion updates profile and unlocks circuit closed"):
		return
	if not _check(main.player_profile.get("character_completions", []).has("ember_exile") and main._profile_unlocked_achievements().has("ember_exile_mark"), "ember exile completion is recorded in profile achievements"):
		return
	if not _check(main._max_unlocked_challenge_level() >= 1, "normal completion unlocks challenge level one"):
		return
	if not _check(main.feedback_label.visible and main.feedback_label.text.contains("最终胜利"), "run completion shows final victory feedback"):
		return
	if not _check(main.last_run_completion_panel_visible, "run completion shows dedicated ending panel"):
		return
	if not _check(main.last_run_completion_art_loaded and main.last_run_completion_art_path.contains("chapter_three"), "run completion loads chapter ending art"):
		return
	if not _check(main.last_run_completion_stat_chip_count >= 6, "run completion shows resource stat chips"):
		return
	if not _check(main.last_run_completion_unlock_chip_count >= main.last_run_unlocks.size(), "run completion shows unlock chips"):
		return
	if not _check(main.last_run_completion_action_count >= 3, "run completion shows ending action buttons including profile"):
		return
	main._on_profile_pressed()
	if not _check(main.profile_open and main.last_profile_summary.contains("完整通关") and main.last_profile_summary.contains("余烬流亡者"), "completion profile page shows win stats and completed character"):
		return
	main._on_close_profile_pressed()
	if not _check(main.run_completed and not main.profile_open, "closing completion profile returns to run completion"):
		return

	main._on_new_run_pressed()
	if not _check(main.character_select_open and main.last_challenge_unlocked_max >= 1, "new run after completion exposes unlocked challenge selector"):
		return
	main._on_challenge_up_pressed()
	if not _check(main.selected_challenge_level == 1 and main.last_challenge_level == 1, "challenge selector can raise to challenge one"):
		return
	main._on_character_selected("ember_exile")
	if not _check(main.current_challenge_level == 1 and int(main._create_save_state().get("current_challenge_level", 0)) == 1, "challenge level one is applied and saved in the run state"):
		return
	var challenge_enemy: Dictionary = main.combat.enemies[0]
	var challenge_enemy_data: Dictionary = main._enemy_by_id(str(challenge_enemy.get("id", "")))
	if not _check(int(challenge_enemy.get("max_hp", 0)) > int(challenge_enemy_data.get("max_hp", 0)), "challenge one increases enemy max HP"):
		return

	main._on_character_selected("arc_tinker")
	_complete_run_by_boss_jumps(main)
	if not _check(main.run_completed, "arc tinker can reach run completion"):
		return
	if not _check(main.last_run_completion_title.contains("电弧工匠重写"), "arc tinker has character-specific victory title"):
		return
	if not _check(main.last_run_completion_summary.contains("蓝色回路"), "arc tinker completion summary shows character epilogue"):
		return
	if not _check(main.last_run_unlocks.has("局外记录：电弧工匠通关印记"), "arc tinker completion unlocks character mark"):
		return
	if not _check(main.last_run_unlocks.has("挑战变体：过载工具台"), "arc tinker completion unlocks character variant"):
		return
	if not _check(main.player_profile.get("character_completions", []).has("arc_tinker") and main._profile_unlocked_achievements().has("arc_tinker_mark"), "arc tinker completion is recorded in profile achievements"):
		return
	if not _check(main._profile_stat("best_challenge_level_completed") >= 1 and main._profile_unlocked_achievements().has("challenge_one_clear"), "challenge one completion records challenge progress and achievement"):
		return
	if not _check(main._max_unlocked_challenge_level() >= 2, "challenge one completion unlocks challenge two"):
		return

	main._on_character_selected("pyre_ascetic")
	_complete_run_by_boss_jumps(main)
	if not _check(main.run_completed, "pyre ascetic can reach run completion"):
		return
	if not _check(main.last_run_completion_title.contains("熔痕苦修者净化"), "pyre ascetic has character-specific victory title"):
		return
	if not _check(main.last_run_completion_summary.contains("白焰"), "pyre ascetic completion summary shows character epilogue"):
		return
	if not _check(main.last_run_unlocks.has("局外记录：熔痕苦修者通关印记"), "pyre ascetic completion unlocks character mark"):
		return
	if not _check(main.last_run_unlocks.has("挑战变体：白焰忏悔室"), "pyre ascetic completion unlocks character variant"):
		return
	if not _check(main.player_profile.get("character_completions", []).has("pyre_ascetic") and main._profile_unlocked_achievements().has("pyre_ascetic_mark"), "pyre ascetic completion is recorded in profile achievements"):
		return

	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	main.free()
	print("Run flow smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("Test failed: %s" % message)
		failed = true
		quit(1)
		return false
	return true

func _count_items_by_field(items: Array, field: String, expected: String) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if str(item_dict.get(field, "")) == expected:
			count += 1
	return count

func _count_items_by_text_field(items: Array, field: String, text: String) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if str(item_dict.get(field, "")).contains(text):
			count += 1
	return count

func _count_items_with_character_scope(items: Array, exclusive: bool) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		var character_ids: Array = item_dict.get("character_ids", [])
		var is_exclusive := not character_ids.is_empty()
		if exclusive == is_exclusive:
			count += 1
	return count

func _count_items_available_to_character(items: Array, character_id: String) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		var character_ids: Array = item_dict.get("character_ids", [])
		if character_ids.is_empty() or character_ids.has(character_id):
			count += 1
	return count

func _count_items_in_discovery(items: Array, discovered_ids: Array) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if discovered_ids.has(str(item_dict.get("id", ""))):
			count += 1
	return count

func _count_challenges_with_starting_hp_loss(levels: Array) -> int:
	var count := 0
	for level in levels:
		var level_dict: Dictionary = level
		var modifiers: Dictionary = level_dict.get("modifiers", {})
		if int(modifiers.get("player_starting_hp_loss", 0)) > 0:
			count += 1
	return count

func _jump_to_node_type(main, node_type: String) -> void:
	for node in main.route_nodes:
		var node_dict: Dictionary = node
		if str(node_dict.get("type", "")) == node_type:
			main.current_node_id = str(node_dict.get("id", ""))
			main.current_node_index = main._node_index_by_id(main.current_node_id)
			main.available_node_ids.clear()
			main._start_current_node()
			return

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
		main.combat.phase = "won"
		main._advance_to_next_node()

func _has_feedback_type(events: Array, event_type: String) -> bool:
	for event in events:
		var event_dict: Dictionary = event
		if str(event_dict.get("type", "")) == event_type:
			return true
	return false

func _shop_options_have_id(options: Array, item_id: String) -> bool:
	for option in options:
		var option_dict: Dictionary = option
		if str(option_dict.get("id", "")) == item_id:
			return true
	return false

func _first_playable_card_index(main) -> int:
	if main.combat == null:
		return -1
	for i in range(main.combat.hand.size()):
		if main.combat.can_play_card(i):
			return i
	return -1

func _pc_hand_card_uses_full_background(button: Button) -> bool:
	if button == null or button.get_child_count() == 0:
		return false
	var root := button.get_child(0) as MarginContainer
	if root == null or root.get_child_count() == 0:
		return false
	var stack := root.get_child(0) as Control
	if stack == null or stack.get_child_count() == 0:
		return false
	var art := stack.get_child(0) as TextureRect
	if art == null or art.texture == null:
		return false
	return art.name == "FullCardArt" \
		and art.anchor_left <= 0.01 \
		and art.anchor_top <= 0.01 \
		and art.anchor_right >= 0.99 \
		and art.anchor_bottom >= 0.99

func _has_generated_texture_background(control: Control) -> bool:
	if control == null:
		return false
	var texture := control.get_node_or_null("GeneratedTextureBackground") as TextureRect
	return texture != null and texture.texture != null

func _control_has_texture_named(control: Node, node_name: String) -> bool:
	if control == null:
		return false
	var texture_rect := control as TextureRect
	if control.name == node_name and texture_rect != null and texture_rect.texture != null:
		return true
	for child in control.get_children():
		if _control_has_texture_named(child, node_name):
			return true
	return false

func _control_has_node_named(control: Node, node_name: String) -> bool:
	if control == null:
		return false
	if control.name == node_name:
		return true
	for child in control.get_children():
		if _control_has_node_named(child, node_name):
			return true
	return false

func _first_label_text(control: Node) -> String:
	if control == null:
		return ""
	if control is Label:
		return (control as Label).text
	for child in control.get_children():
		var found := _first_label_text(child)
		if not found.is_empty():
			return found
	return ""

func _first_structured_button(control: Node) -> Button:
	if control == null:
		return null
	for child in control.get_children():
		var button := child as Button
		if button != null and button.get_child_count() >= 1 and button.get_child(0) is MarginContainer:
			return button
	return null

func _expected_card_effect_profile(card_type: String) -> String:
	match card_type:
		"attack":
			return "attack_slash"
		"skill":
			return "skill_guard"
		"power":
			return "power_pulse"
		_:
			return "card_default"

func _expected_card_audio_event(card_type: String) -> String:
	match card_type:
		"attack":
			return "card_attack"
		"skill":
			return "card_skill"
		"power":
			return "card_power"
		_:
			return "card_play"

func _route_has_encounter(route_nodes: Array, encounter_id: String) -> bool:
	for node in route_nodes:
		var node_dict: Dictionary = node
		if str(node_dict.get("encounter_id", "")) == encounter_id:
			return true
	return false

func _node_with_compass_extra(main) -> String:
	for node in main.route_nodes:
		var node_dict: Dictionary = node
		var node_id: String = str(node_dict.get("id", ""))
		if node_id.is_empty():
			continue
		var base_options: Array[String] = main._next_node_ids(node_id)
		if base_options.is_empty():
			continue
		if not main._same_layer_extra_node_candidates(node_id, base_options).is_empty():
			return node_id
	return ""

func _reward_pool_has_card(pool: Array, card_id: String) -> bool:
	for card in pool:
		var card_dict: Dictionary = card
		if str(card_dict.get("id", "")) == card_id:
			return true
	return false

func _reward_pool_has_relic(pool: Array, relic_id: String) -> bool:
	for relic in pool:
		var relic_dict: Dictionary = relic
		if str(relic_dict.get("id", "")) == relic_id:
			return true
	return false
