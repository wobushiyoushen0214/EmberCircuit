extends Control

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const MapViewScript = preload("res://scripts/map/MapView.gd")

const ENEMY_ART_PATHS := {
	"placeholder_soot_raider": "res://assets/art/enemy_soot_raider.svg",
	"placeholder_ash_hound": "res://assets/art/enemy_ash_hound.svg",
	"placeholder_forge_bishop": "res://assets/art/enemy_forge_bishop.svg"
}
const CARD_FRAME_PATHS := {
	"attack": "res://assets/art/card_attack_frame.svg",
	"skill": "res://assets/art/card_skill_frame.svg",
	"power": "res://assets/art/card_power_frame.svg"
}
const POTION_ART_PATH := "res://assets/art/potion_placeholder.svg"
const RELIC_ART_PATH := "res://assets/art/relic_placeholder.svg"
const EVENT_ART_PATH := "res://assets/art/event_default.svg"
const UI_BACKDROP_PATH := "res://assets/art/ui_backdrop_forge.svg"
const PLAYER_ART_PATHS := {
	"ember_exile": "res://assets/art/player_ember_exile.svg",
	"arc_tinker": "res://assets/art/player_arc_tinker.svg",
	"pyre_ascetic": "res://assets/art/player_pyre_ascetic.svg"
}
const ROOT_MARGIN_LEFT := 14.0
const ROOT_MARGIN_RIGHT := 14.0
const ROOT_MARGIN_TOP := 10.0
const ROOT_MARGIN_BOTTOM := 10.0
const SCROLLBAR_WIDTH_RESERVE := 24.0
const MIN_SAFE_CONTENT_WIDTH := 220.0
const TUTORIAL_STEP_ORDER := [
	"character_select",
	"combat_player",
	"combat_reward",
	"map_choice",
	"event",
	"shop",
	"campfire",
	"deck_view",
	"settings",
	"run_complete"
]
const COMPENDIUM_TAB_ORDER := ["cards", "relics", "potions", "enemies", "events", "challenges"]

var combat
var debug_viewport_size_override: Vector2 = Vector2.ZERO
var selected_enemy_index: int = 0
var selected_character_id: String = "ember_exile"
var character_select_open: bool = false
var card_data: Dictionary = {}
var enemy_data: Dictionary = {}
var relic_data: Dictionary = {}
var potion_data: Dictionary = {}
var encounter_data: Dictionary = {}
var player_data: Dictionary = {}
var economy_data: Dictionary = {}
var route_data: Dictionary = {}
var event_data: Dictionary = {}
var status_data: Dictionary = {}
var map_generation_data: Dictionary = {}
var art_data: Dictionary = {}
var vfx_data: Dictionary = {}
var achievement_data: Dictionary = {}
var challenge_data: Dictionary = {}
var raw_svg_texture_cache: Dictionary = {}

var run_deck_ids: Array = []
var run_relic_ids: Array = []
var run_potion_ids: Array = []
var run_hp: int = 0
var run_max_hp: int = 0
var run_gold: int = 0
var run_shop_remove_count: int = 0
var run_completed: bool = false
var current_chapter_id: String = "chapter_one"
var completed_chapter_ids: Array = []
var selected_challenge_level: int = 0
var current_challenge_level: int = 0
var settings_open: bool = false
var tutorial_open: bool = false
var profile_open: bool = false
var compendium_open: bool = false
var selected_compendium_tab: String = "cards"
var selected_compendium_filter: String = "all"
var selected_compendium_sort: String = "name"
var selected_compendium_search: String = ""
var compendium_reveal_all_details: bool = false
var user_settings: Dictionary = {}
var player_profile: Dictionary = {}

var route_nodes: Array = []
var current_node_index: int = 0
var map_graph: Dictionary = {}
var current_node_id: String = ""
var available_node_ids: Array[String] = []
var completed_node_ids: Dictionary = {}
var completed_event_ids: Dictionary = {}
var reward_options: Array = []
var relic_reward_options: Array = []
var potion_reward_options: Array = []
var shop_card_options: Array = []
var shop_potion_options: Array = []
var reward_generated_for: String = ""
var shop_generated_for: int = -1
var card_reward_done: bool = false
var relic_reward_done: bool = true
var potion_reward_done: bool = true
var deck_view_open: bool = false

var screen_background: ColorRect
var screen_background_art: TextureRect
var page_scroll: ScrollContainer
var page_margin: MarginContainer
var root_box: VBoxContainer
var title_label: Label
var run_label: Label
var status_label: Label
var character_frame: PanelContainer
var character_panel: HBoxContainer
var player_portrait: TextureRect
var character_summary_label: Label
var relic_belt_row: HBoxContainer
var battle_board_panel: PanelContainer
var battle_board_box: VBoxContainer
var battle_mid_row: HBoxContainer
var enemy_stage_panel: PanelContainer
var enemy_stage_stack: Control
var battle_background: TextureRect
var battle_stage_scrim: ColorRect
var hand_frame: PanelContainer
var hand_scroll: ScrollContainer
var combat_hud_row: HBoxContainer
var feedback_label: Label
var feedback_overlay: Control
var cinematic_overlay: Control
var cinematic_panel: PanelContainer
var cinematic_title_label: Label
var cinematic_subtitle_label: Label
var map_scroll: ScrollContainer
var map_view: Control
var potion_row: HBoxContainer
var enemy_row: HBoxContainer
var hand_row: HBoxContainer
var reward_scroll: ScrollContainer
var reward_row: HFlowContainer
var log_label: RichTextLabel
var controls_scroll: ScrollContainer
var controls_row: HBoxContainer
var end_turn_button: Button
var restart_button: Button
var save_button: Button
var load_button: Button
var deck_button: Button
var profile_button: Button
var compendium_button: Button
var settings_button: Button
var tutorial_button: Button
var last_feedback_events: Array = []
var last_feedback_audio_event: String = ""
var last_flash_target_id: String = ""
var last_feedback_visual_type: String = ""
var last_hit_stop_duration: float = 0.0
var last_screen_shake_intensity: float = 0.0
var last_floating_text_count: int = 0
var last_cinematic_event_type: String = ""
var last_cinematic_title: String = ""
var last_cinematic_subtitle: String = ""
var last_impact_effect_type: String = ""
var last_impact_effect_count: int = 0
var last_impact_vfx_profile: String = ""
var last_impact_vfx_asset_path: String = ""
var last_impact_vfx_asset_loaded: bool = false
var last_impact_ray_count: int = 0
var last_phase_animation_target_id: String = ""
var last_card_preview_index: int = -1
var last_card_preview_card_id: String = ""
var last_card_preview_target_id: String = ""
var last_card_target_line_count: int = 0
var last_card_play_animation_count: int = 0
var last_card_play_card_id: String = ""
var last_card_play_target_id: String = ""
var last_card_play_trajectory_points: Array[Vector2] = []
var last_card_effect_profile: String = ""
var last_card_particle_count: int = 0
var last_card_audio_event: String = ""
var last_card_vfx_asset_path: String = ""
var last_card_vfx_asset_loaded: bool = false
var last_hand_card_art_path: String = ""
var last_hand_card_art_loaded: bool = false
var last_hand_card_layout_count: int = 0
var last_hand_card_art_node_count: int = 0
var last_hand_card_cost_texts: Array[String] = []
var last_hand_card_type_texts: Array[String] = []
var last_hand_card_name_texts: Array[String] = []
var last_hand_card_rarity_texts: Array[String] = []
var last_reward_card_art_path: String = ""
var last_reward_card_art_loaded: bool = false
var last_reward_card_layout_count: int = 0
var last_reward_card_art_node_count: int = 0
var last_generated_card_reward_rarities: Array[String] = []
var last_generated_relic_reward_rarities: Array[String] = []
var last_generated_potion_reward_rarities: Array[String] = []
var last_reward_generation_context: String = ""
var last_shop_card_layout_count: int = 0
var last_shop_card_art_node_count: int = 0
var last_campfire_card_layout_count: int = 0
var last_campfire_card_art_node_count: int = 0
var last_deck_view_card_layout_count: int = 0
var last_deck_view_card_art_node_count: int = 0
var last_relic_icon_path: String = ""
var last_relic_icon_loaded: bool = false
var last_relic_belt_layout_count: int = 0
var last_relic_belt_icon_node_count: int = 0
var last_relic_belt_overflow_count: int = 0
var last_relic_belt_tooltips: Array[String] = []
var last_potion_icon_path: String = ""
var last_potion_icon_loaded: bool = false
var last_potion_slot_layout_count: int = 0
var last_potion_slot_icon_node_count: int = 0
var last_shop_potion_layout_count: int = 0
var last_shop_potion_icon_node_count: int = 0
var last_reward_potion_layout_count: int = 0
var last_reward_potion_icon_node_count: int = 0
var last_reward_relic_layout_count: int = 0
var last_reward_relic_icon_node_count: int = 0
var last_event_choice_blocked_reason: String = ""
var last_event_result_id: String = ""
var last_event_result_label: String = ""
var last_event_art_path: String = ""
var last_event_art_loaded: bool = false
var last_event_panel_title: String = ""
var last_event_panel_body: String = ""
var last_event_panel_choice_count: int = 0
var last_run_completion_title: String = ""
var last_run_completion_summary: String = ""
var last_run_unlocks: Array[String] = []
var last_character_selection_title: String = ""
var last_character_selection_ids: Array[String] = []
var last_character_button_icon_count: int = 0
var last_campfire_button_style_count: int = 0
var last_shop_button_style_count: int = 0
var last_event_choice_style_count: int = 0
var last_reward_button_style_count: int = 0
var last_combat_hud_text: String = ""
var last_combat_hud_block_count: int = 0
var last_character_panel_style_applied: bool = false
var last_battle_board_style_applied: bool = false
var last_enemy_stage_style_applied: bool = false
var last_hand_frame_style_applied: bool = false
var last_battle_background_chapter_id: String = ""
var last_battle_background_path: String = ""
var last_battle_background_loaded: bool = false
var last_ui_backdrop_loaded: bool = false
var last_combat_reward_region_visible: bool = false
var last_combat_layout_available_height: float = 0.0
var last_combat_layout_total_height: float = 0.0
var last_combat_layout_estimated_height: float = 0.0
var last_combat_layout_overflow: float = 0.0
var last_reward_scroll_height: float = 0.0
var last_reward_flow_required_width: float = 0.0
var last_reward_flow_available_width: float = 0.0
var last_reward_flow_wrap_needed: bool = false
var last_hand_scroll_width: float = 0.0
var last_hand_required_width: float = 0.0
var last_hand_horizontal_scroll_needed: bool = false
var last_enemy_intent_badge_count: int = 0
var last_enemy_intent_badge_texts: Array[String] = []
var last_enemy_intent_badge_types: Array[String] = []
var last_map_preview_node_id: String = ""
var last_map_preview_text: String = ""
var last_map_relic_extra_choice_count: int = 0
var last_map_relic_extra_choice_ids: Array[String] = []
var last_settings_panel_visible: bool = false
var last_settings_button_count: int = 0
var last_settings_summary: String = ""
var last_settings_audio_enabled: bool = true
var last_settings_master_volume: float = 1.0
var last_settings_music_enabled: bool = true
var last_settings_music_volume: float = 0.65
var last_settings_screen_shake_enabled: bool = true
var last_settings_hit_stop_enabled: bool = true
var last_settings_floating_text_enabled: bool = true
var last_settings_save_ok: bool = false
var last_profile_panel_visible: bool = false
var last_profile_button_count: int = 0
var last_profile_summary: String = ""
var last_profile_unlocked_count: int = 0
var last_profile_total_count: int = 0
var last_profile_last_unlock_text: String = ""
var last_profile_save_ok: bool = false
var last_compendium_panel_visible: bool = false
var last_compendium_tab: String = ""
var last_compendium_filter: String = ""
var last_compendium_sort: String = ""
var last_compendium_search: String = ""
var last_compendium_item_count: int = 0
var last_compendium_total_count: int = 0
var last_compendium_tab_button_count: int = 0
var last_compendium_filter_button_count: int = 0
var last_compendium_sort_button_count: int = 0
var last_compendium_search_control_count: int = 0
var last_compendium_discovered_count: int = 0
var last_compendium_undiscovered_count: int = 0
var last_compendium_summary: String = ""
var last_compendium_card_width: float = 0.0
var last_compendium_reveal_all_details: bool = false
var last_compendium_locked_item_count: int = 0
var last_compendium_item_titles: Array[String] = []
var last_compendium_item_subtitles: Array[String] = []
var last_compendium_item_bodies: Array[String] = []
var last_compendium_item_tooltips: Array[String] = []
var last_challenge_level: int = 0
var last_challenge_unlocked_max: int = 0
var last_challenge_button_count: int = 0
var last_challenge_summary: String = ""
var last_challenge_modifier_summary: String = ""
var last_tutorial_visible: bool = false
var last_tutorial_page_visible: bool = false
var last_tutorial_step_id: String = ""
var last_tutorial_title: String = ""
var last_tutorial_body: String = ""
var last_tutorial_button_count: int = 0
var last_tutorial_completed_count: int = 0
var last_tutorial_summary: String = ""
var enemy_visuals_by_id: Dictionary = {}
var hand_buttons_by_index: Dictionary = {}
var hit_stop_ticket: int = 0
var last_music_context: String = ""
var last_music_stream_path: String = ""
var last_music_stream_loaded: bool = false

func _ready() -> void:
	_load_user_settings()
	_load_player_profile()
	_build_layout()
	_apply_runtime_settings()
	_load_all_data()
	selected_character_id = _valid_character_id(selected_character_id)
	_open_character_select(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_layout_widths()

func _build_layout() -> void:
	screen_background = ColorRect.new()
	screen_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_background.color = Color(0.025, 0.030, 0.035)
	screen_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_background)

	screen_background_art = TextureRect.new()
	screen_background_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_background_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_background_art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	screen_background_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	screen_background_art.modulate = Color(1, 1, 1, 0.46)
	screen_background_art.texture = _load_texture(UI_BACKDROP_PATH)
	screen_background_art.visible = screen_background_art.texture != null
	last_ui_backdrop_loaded = screen_background_art.visible
	add_child(screen_background_art)

	page_scroll = ScrollContainer.new()
	page_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_scroll.clip_contents = true
	page_scroll.set("horizontal_scroll_mode", 0)
	page_scroll.set("vertical_scroll_mode", 1)
	add_child(page_scroll)

	page_margin = MarginContainer.new()
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_margin.add_theme_constant_override("margin_left", int(ROOT_MARGIN_LEFT))
	page_margin.add_theme_constant_override("margin_right", int(ROOT_MARGIN_RIGHT))
	page_margin.add_theme_constant_override("margin_top", int(ROOT_MARGIN_TOP))
	page_margin.add_theme_constant_override("margin_bottom", int(ROOT_MARGIN_BOTTOM))
	page_scroll.add_child(page_margin)

	root_box = VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root_box.add_theme_constant_override("separation", 5)
	page_margin.add_child(root_box)
	_sync_layout_widths()

	title_label = Label.new()
	title_label.text = "EmberCircuit / 余烬回路"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.custom_minimum_size = Vector2(0, 24)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	root_box.add_child(title_label)

	run_label = Label.new()
	run_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	run_label.clip_text = true
	run_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	run_label.custom_minimum_size = Vector2(0, 16)
	run_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	run_label.add_theme_font_size_override("font_size", 12)
	run_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.88))
	root_box.add_child(run_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.custom_minimum_size = Vector2(0, 18)
	status_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.90))
	root_box.add_child(status_label)

	character_frame = PanelContainer.new()
	character_frame.custom_minimum_size = Vector2(0, 58)
	character_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	character_frame.add_theme_stylebox_override("panel", _player_panel_style())
	last_character_panel_style_applied = true
	root_box.add_child(character_frame)

	character_panel = HBoxContainer.new()
	character_panel.custom_minimum_size = Vector2(0, 50)
	character_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	character_panel.add_theme_constant_override("separation", 10)
	character_frame.add_child(character_panel)

	player_portrait = TextureRect.new()
	player_portrait.custom_minimum_size = Vector2(48, 48)
	player_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	player_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character_panel.add_child(player_portrait)

	character_summary_label = Label.new()
	character_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_summary_label.clip_text = true
	character_summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	character_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_summary_label.add_theme_font_size_override("font_size", 12)
	character_summary_label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.90))
	character_panel.add_child(character_summary_label)

	relic_belt_row = HBoxContainer.new()
	relic_belt_row.custom_minimum_size = Vector2(160, 42)
	relic_belt_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	relic_belt_row.alignment = BoxContainer.ALIGNMENT_END
	relic_belt_row.add_theme_constant_override("separation", 5)
	character_panel.add_child(relic_belt_row)

	battle_board_panel = PanelContainer.new()
	battle_board_panel.visible = false
	battle_board_panel.custom_minimum_size = Vector2(0, 244)
	battle_board_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	battle_board_panel.clip_contents = true
	battle_board_panel.add_theme_stylebox_override("panel", _battle_board_style())
	last_battle_board_style_applied = true
	root_box.add_child(battle_board_panel)

	battle_board_box = VBoxContainer.new()
	battle_board_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	battle_board_box.add_theme_constant_override("separation", 5)
	battle_board_panel.add_child(battle_board_box)

	combat_hud_row = HBoxContainer.new()
	combat_hud_row.visible = false
	combat_hud_row.custom_minimum_size = Vector2(0, 38)
	combat_hud_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_hud_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	combat_hud_row.add_theme_constant_override("separation", 6)
	battle_board_box.add_child(combat_hud_row)

	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.visible = false
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.custom_minimum_size = Vector2(0, 28)
	feedback_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	feedback_label.add_theme_font_size_override("font_size", 14)
	feedback_label.add_theme_stylebox_override("normal", _button_style(Color(0.15, 0.16, 0.18), Color(0.44, 0.48, 0.54), 1, 6))
	battle_board_box.add_child(feedback_label)

	map_scroll = ScrollContainer.new()
	map_scroll.visible = false
	map_scroll.custom_minimum_size = Vector2(0, 330)
	map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	map_scroll.clip_contents = true
	map_scroll.set("horizontal_scroll_mode", 1)
	map_scroll.set("vertical_scroll_mode", 0)
	root_box.add_child(map_scroll)

	map_view = MapViewScript.new()
	map_view.visible = false
	map_view.custom_minimum_size = Vector2(0, 330)
	map_view.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	map_view.node_selected.connect(_on_map_node_pressed)
	map_view.node_previewed.connect(_on_map_node_previewed)
	map_scroll.add_child(map_view)

	battle_mid_row = HBoxContainer.new()
	battle_mid_row.custom_minimum_size = Vector2(0, 150)
	battle_mid_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	battle_mid_row.add_theme_constant_override("separation", 10)
	battle_board_box.add_child(battle_mid_row)

	enemy_stage_panel = PanelContainer.new()
	enemy_stage_panel.custom_minimum_size = Vector2(0, 148)
	enemy_stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_stage_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	enemy_stage_panel.clip_contents = true
	enemy_stage_panel.add_theme_stylebox_override("panel", _enemy_stage_style())
	last_enemy_stage_style_applied = true
	battle_mid_row.add_child(enemy_stage_panel)

	enemy_stage_stack = Control.new()
	enemy_stage_stack.custom_minimum_size = Vector2(0, 136)
	enemy_stage_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_stage_stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	enemy_stage_stack.clip_contents = true
	enemy_stage_panel.add_child(enemy_stage_stack)

	battle_background = TextureRect.new()
	battle_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	battle_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	battle_background.modulate = Color(1, 1, 1, 0.86)
	enemy_stage_stack.add_child(battle_background)

	battle_stage_scrim = ColorRect.new()
	battle_stage_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_stage_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_stage_scrim.color = Color(0.02, 0.025, 0.03, 0.18)
	enemy_stage_stack.add_child(battle_stage_scrim)

	enemy_row = HBoxContainer.new()
	enemy_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_row.offset_left = 12
	enemy_row.offset_top = 8
	enemy_row.offset_right = -12
	enemy_row.offset_bottom = -8
	enemy_row.custom_minimum_size = Vector2(0, 136)
	enemy_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 8)
	enemy_stage_stack.add_child(enemy_row)

	potion_row = HBoxContainer.new()
	potion_row.custom_minimum_size = Vector2(344, 52)
	potion_row.alignment = BoxContainer.ALIGNMENT_CENTER
	potion_row.add_theme_constant_override("separation", 6)
	battle_mid_row.add_child(potion_row)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 58)
	log_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	log_label.fit_content = false
	log_label.scroll_following = true
	log_label.add_theme_color_override("default_color", Color(0.86, 0.88, 0.86))
	log_label.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.105, 0.105, 0.84), Color(0.28, 0.30, 0.30), 1, 6))
	root_box.add_child(log_label)

	hand_frame = PanelContainer.new()
	hand_frame.custom_minimum_size = Vector2(0, 150)
	hand_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hand_frame.clip_contents = true
	hand_frame.add_theme_stylebox_override("panel", _hand_frame_style())
	last_hand_frame_style_applied = true
	root_box.add_child(hand_frame)

	hand_scroll = ScrollContainer.new()
	hand_scroll.custom_minimum_size = Vector2(0, 140)
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hand_scroll.clip_contents = true
	hand_scroll.set("horizontal_scroll_mode", 1)
	hand_scroll.set("vertical_scroll_mode", 0)
	hand_frame.add_child(hand_scroll)

	hand_row = HBoxContainer.new()
	hand_row.custom_minimum_size = Vector2(0, 140)
	hand_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hand_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", 6)
	hand_scroll.add_child(hand_row)

	reward_scroll = ScrollContainer.new()
	reward_scroll.custom_minimum_size = Vector2(0, 160)
	reward_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	reward_scroll.clip_contents = true
	reward_scroll.set("horizontal_scroll_mode", 0)
	reward_scroll.set("vertical_scroll_mode", 1)
	root_box.add_child(reward_scroll)

	reward_row = HFlowContainer.new()
	reward_row.custom_minimum_size = Vector2(0, 160)
	reward_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	reward_row.add_theme_constant_override("separation", 6)
	reward_row.add_theme_constant_override("h_separation", 6)
	reward_row.add_theme_constant_override("v_separation", 6)
	reward_scroll.add_child(reward_row)

	controls_scroll = ScrollContainer.new()
	controls_scroll.custom_minimum_size = Vector2(0, 34)
	controls_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	controls_scroll.clip_contents = true
	controls_scroll.set("horizontal_scroll_mode", 1)
	controls_scroll.set("vertical_scroll_mode", 0)
	root_box.add_child(controls_scroll)

	controls_row = HBoxContainer.new()
	controls_row.custom_minimum_size = Vector2(0, 34)
	controls_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	controls_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	controls_row.add_theme_constant_override("separation", 8)
	controls_scroll.add_child(controls_row)

	end_turn_button = Button.new()
	end_turn_button.custom_minimum_size = Vector2(96, 30)
	end_turn_button.text = "结束回合"
	_apply_button_skin(end_turn_button, "primary")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	controls_row.add_child(end_turn_button)

	restart_button = Button.new()
	restart_button.custom_minimum_size = Vector2(88, 30)
	restart_button.text = "新跑团"
	_apply_button_skin(restart_button, "neutral")
	restart_button.pressed.connect(_on_new_run_pressed)
	controls_row.add_child(restart_button)

	save_button = Button.new()
	save_button.custom_minimum_size = Vector2(88, 30)
	save_button.text = "保存跑团"
	_apply_button_skin(save_button, "neutral")
	save_button.pressed.connect(_on_save_pressed)
	controls_row.add_child(save_button)

	load_button = Button.new()
	load_button.custom_minimum_size = Vector2(88, 30)
	load_button.text = "读取跑团"
	_apply_button_skin(load_button, "neutral")
	load_button.pressed.connect(_on_load_pressed)
	controls_row.add_child(load_button)

	deck_button = Button.new()
	deck_button.custom_minimum_size = Vector2(88, 30)
	deck_button.text = "查看牌组"
	_apply_button_skin(deck_button, "neutral")
	deck_button.pressed.connect(_on_deck_view_pressed)
	controls_row.add_child(deck_button)

	profile_button = Button.new()
	profile_button.custom_minimum_size = Vector2(72, 30)
	profile_button.text = "档案"
	_apply_button_skin(profile_button, "relic")
	profile_button.pressed.connect(_on_profile_pressed)
	controls_row.add_child(profile_button)

	compendium_button = Button.new()
	compendium_button.custom_minimum_size = Vector2(72, 30)
	compendium_button.text = "图鉴"
	_apply_button_skin(compendium_button, "event")
	compendium_button.pressed.connect(_on_compendium_pressed)
	controls_row.add_child(compendium_button)

	tutorial_button = Button.new()
	tutorial_button.custom_minimum_size = Vector2(88, 30)
	tutorial_button.text = "引导"
	_apply_button_skin(tutorial_button, "neutral")
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	controls_row.add_child(tutorial_button)

	settings_button = Button.new()
	settings_button.custom_minimum_size = Vector2(72, 30)
	settings_button.text = "设置"
	_apply_button_skin(settings_button, "neutral")
	settings_button.pressed.connect(_on_settings_pressed)
	controls_row.add_child(settings_button)

	feedback_overlay = Control.new()
	feedback_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_overlay.z_index = 20
	add_child(feedback_overlay)

	_build_cinematic_overlay()

func _sync_layout_widths() -> void:
	var content_width: float = _scroll_content_width()
	var page_width: float = content_width + _root_horizontal_margin()
	if page_margin != null:
		page_margin.custom_minimum_size = Vector2(max(MIN_SAFE_CONTENT_WIDTH, page_width), 0)
	if root_box != null:
		root_box.custom_minimum_size = Vector2(content_width, 0)
		root_box.size = Vector2(content_width, root_box.size.y)

func _build_cinematic_overlay() -> void:
	cinematic_overlay = Control.new()
	cinematic_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_overlay.visible = false
	cinematic_overlay.z_index = 30
	add_child(cinematic_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.02, 0.02, 0.03, 0.58)
	cinematic_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_overlay.add_child(center)

	cinematic_panel = PanelContainer.new()
	cinematic_panel.custom_minimum_size = _cinematic_panel_size()
	cinematic_panel.add_theme_stylebox_override("panel", _cinematic_style("phase"))
	center.add_child(cinematic_panel)

	var text_box := VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 10)
	cinematic_panel.add_child(text_box)

	cinematic_title_label = Label.new()
	cinematic_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cinematic_title_label.add_theme_font_size_override("font_size", 34)
	cinematic_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	text_box.add_child(cinematic_title_label)

	cinematic_subtitle_label = Label.new()
	cinematic_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cinematic_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cinematic_subtitle_label.add_theme_font_size_override("font_size", 18)
	cinematic_subtitle_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	text_box.add_child(cinematic_subtitle_label)

func _start_new_run(character_id: String = "") -> void:
	if player_data.is_empty():
		_load_all_data()

	if not character_id.is_empty():
		selected_character_id = character_id
	selected_character_id = _valid_character_id(selected_character_id)
	selected_challenge_level = _valid_challenge_level(selected_challenge_level)
	current_challenge_level = selected_challenge_level
	character_select_open = false
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	var player_config: Dictionary = _current_player_config()
	run_deck_ids = _starter_deck_for_character(player_config)
	run_relic_ids = _starter_relics_for_character(player_config)
	run_potion_ids = player_config.get("starting_potions", []).duplicate(true)
	run_max_hp = int(player_config.get("max_hp", 72))
	run_hp = int(player_config.get("starting_hp", run_max_hp))
	run_hp = max(1, run_hp - _challenge_player_starting_hp_loss(current_challenge_level))
	run_gold = int(player_config.get("starting_gold", 0))
	run_shop_remove_count = 0
	run_completed = false
	current_chapter_id = _first_chapter_id()
	completed_chapter_ids.clear()
	current_node_index = 0
	current_node_id = ""
	available_node_ids.clear()
	completed_node_ids.clear()
	completed_event_ids.clear()
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	shop_card_options.clear()
	shop_potion_options.clear()
	reward_generated_for = ""
	shop_generated_for = -1
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	_build_route()
	_record_current_run_discoveries(false)
	_record_run_started()
	_start_current_node()

func _start_character_run(character_id: String) -> void:
	_start_new_run(character_id)

func _open_character_select(play_audio: bool = true) -> void:
	if player_data.is_empty():
		_load_all_data()
	selected_character_id = _valid_character_id(selected_character_id)
	selected_challenge_level = _valid_challenge_level(selected_challenge_level)
	character_select_open = true
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	combat = null
	run_completed = false
	current_node_id = ""
	available_node_ids.clear()
	if play_audio:
		_audio_event("ui_click")
	_refresh()

func _on_new_run_pressed() -> void:
	_open_character_select()

func _on_character_selected(character_id: String) -> void:
	_start_new_run(character_id)

func _load_all_data() -> void:
	card_data = DataLoaderScript.load_json("res://data/cards/cards.json")
	enemy_data = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	relic_data = DataLoaderScript.load_json("res://data/relics/relics.json")
	potion_data = DataLoaderScript.load_json("res://data/potions/potions.json")
	encounter_data = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	player_data = DataLoaderScript.load_json("res://data/config/player.json")
	economy_data = DataLoaderScript.load_json("res://data/config/economy.json")
	route_data = DataLoaderScript.load_json("res://data/config/chapter_one_route.json")
	event_data = DataLoaderScript.load_json("res://data/events/events.json")
	status_data = DataLoaderScript.load_json("res://data/statuses/statuses.json")
	map_generation_data = DataLoaderScript.load_json("res://data/config/map_generation.json")
	art_data = DataLoaderScript.load_json("res://data/config/art_assets.json")
	vfx_data = DataLoaderScript.load_json("res://data/config/vfx_profiles.json")
	achievement_data = DataLoaderScript.load_json("res://data/config/achievements.json")
	challenge_data = DataLoaderScript.load_json("res://data/config/challenges.json")

func _load_user_settings() -> void:
	user_settings = SaveManagerScript.load_settings()
	_apply_runtime_settings()

func _load_player_profile() -> void:
	player_profile = SaveManagerScript.load_profile()

func _save_player_profile() -> void:
	player_profile = SaveManagerScript.normalized_profile(player_profile)
	last_profile_save_ok = SaveManagerScript.save_profile(player_profile)

func _save_user_settings() -> void:
	user_settings = SaveManagerScript.normalized_settings(user_settings)
	last_settings_save_ok = SaveManagerScript.save_settings(user_settings)
	_apply_runtime_settings()

func _apply_runtime_settings() -> void:
	user_settings = SaveManagerScript.normalized_settings(user_settings)
	last_settings_audio_enabled = _setting_enabled("audio_enabled", true)
	last_settings_master_volume = _setting_float("master_volume", 1.0)
	last_settings_music_enabled = _setting_enabled("music_enabled", true)
	last_settings_music_volume = _setting_float("music_volume", 0.65)
	last_settings_screen_shake_enabled = _setting_enabled("screen_shake_enabled", true)
	last_settings_hit_stop_enabled = _setting_enabled("hit_stop_enabled", true)
	last_settings_floating_text_enabled = _setting_enabled("floating_text_enabled", true)
	if not is_inside_tree():
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("apply_settings"):
		audio.apply_settings(user_settings)

func _setting_enabled(setting_id: String, fallback: bool = true) -> bool:
	return bool(user_settings.get(setting_id, fallback))

func _setting_float(setting_id: String, fallback: float = 0.0) -> float:
	return float(user_settings.get(setting_id, fallback))

func _default_character_id() -> String:
	var configured_id: String = str(player_data.get("default_character_id", ""))
	if not configured_id.is_empty():
		return configured_id
	var characters: Array = player_data.get("characters", [])
	if not characters.is_empty():
		var first_character: Dictionary = characters[0]
		return str(first_character.get("id", "ember_exile"))
	return str(player_data.get("player", {}).get("id", "ember_exile"))

func _valid_character_id(character_id: String) -> String:
	var requested_id: String = character_id
	if requested_id.is_empty():
		requested_id = _default_character_id()
	if not _character_config(requested_id).is_empty():
		return requested_id
	return _default_character_id()

func _character_config(character_id: String) -> Dictionary:
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		if str(character_dict.get("id", "")) == character_id:
			return character_dict
	var fallback_player: Dictionary = player_data.get("player", {})
	if str(fallback_player.get("id", "")) == character_id or character_id.is_empty():
		return fallback_player
	return {}

func _current_player_config() -> Dictionary:
	var config: Dictionary = _character_config(selected_character_id)
	if config.is_empty():
		config = player_data.get("player", {})
	return config

func _player_data_for_current_character() -> Dictionary:
	var normalized_data: Dictionary = player_data.duplicate(true)
	normalized_data["selected_character_id"] = selected_character_id
	normalized_data["player"] = _current_player_config().duplicate(true)
	normalized_data["challenge_level"] = current_challenge_level
	normalized_data["challenge_modifiers"] = _challenge_modifiers(current_challenge_level)
	return normalized_data

func _starter_deck_for_character(player_config: Dictionary) -> Array:
	var configured_deck: Array = player_config.get("starter_deck_ids", [])
	if configured_deck.is_empty():
		configured_deck = card_data.get("starter_deck", {}).get("cards", [])
	return configured_deck.duplicate(true)

func _starter_relics_for_character(player_config: Dictionary) -> Array:
	var configured_relics: Array = player_config.get("starter_relic_ids", [])
	if configured_relics.is_empty():
		configured_relics = relic_data.get("starter_relics", [])
	return configured_relics.duplicate(true)

func _character_display_name(character_id: String = "") -> String:
	var lookup_id: String = selected_character_id if character_id.is_empty() else character_id
	var config: Dictionary = _character_config(lookup_id)
	return str(config.get("name", lookup_id))

func _character_art_path(character_id: String = "") -> String:
	var lookup_id: String = selected_character_id if character_id.is_empty() else character_id
	return str(PLAYER_ART_PATHS.get(lookup_id, PLAYER_ART_PATHS.get("ember_exile", "")))

func _character_selection_tooltip_text(character: Dictionary) -> String:
	return "%s\n\n%s\n\n起始牌组：%s" % [
		str(character.get("name", character.get("id", "角色"))),
		str(character.get("balance_note", "")),
		_card_names(character.get("starter_deck_ids", []))
	]

func _add_character_select_card_layout(button: Button, character: Dictionary, character_texture: Texture2D) -> void:
	var character_id: String = str(character.get("id", ""))
	var compact: bool = button.custom_minimum_size.x < 340.0
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 8
	root.offset_top = 8
	root.offset_right = -8
	root.offset_bottom = -8
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8 if compact else 10)
	root.add_child(row)

	var portrait_frame := PanelContainer.new()
	var portrait_width := 72.0 if compact else 84.0
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.custom_minimum_size = Vector2(portrait_width, 0)
	portrait_frame.add_theme_stylebox_override("panel", _button_style(Color(0.08, 0.09, 0.10, 0.72), Color(0.60, 0.54, 0.42), 1, 6))
	row.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = character_texture
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3 if compact else 4)
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = str(character.get("name", character.get("id", "角色")))
	_configure_character_card_label(name_label, 15 if compact else 17, Color(1.0, 0.96, 0.82), false)
	text_box.add_child(name_label)

	var archetype_label := Label.new()
	archetype_label.text = str(character.get("archetype_note", ""))
	_configure_character_card_label(archetype_label, 11 if compact else 12, Color(0.80, 0.88, 0.88), true)
	text_box.add_child(archetype_label)

	var stats_label := Label.new()
	stats_label.text = "生命 %d | 能量 %d | 药水 %d" % [
		int(character.get("max_hp", 0)),
		int(character.get("max_energy", 0)),
		int(character.get("potion_slots", 0))
	]
	_configure_character_card_label(stats_label, 11, Color(0.95, 0.94, 0.86), false)
	text_box.add_child(stats_label)

	var momentum_label := Label.new()
	momentum_label.text = "势能 %d/%d | 初始遗物" % [
		int(character.get("starting_momentum", 0)),
		int(character.get("momentum_max", 0))
	]
	_configure_character_card_label(momentum_label, 11, Color(0.92, 0.80, 0.58), false)
	text_box.add_child(momentum_label)

	var relic_label := Label.new()
	relic_label.text = _relic_names(character.get("starter_relic_ids", []))
	_configure_character_card_label(relic_label, 10 if compact else 11, _character_accent_color(character_id), true)
	text_box.add_child(relic_label)

func _configure_character_card_label(label: Label, font_size: int, color: Color, wrap: bool) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(0, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

func _character_accent_color(character_id: String) -> Color:
	match character_id:
		"arc_tinker":
			return Color(0.62, 0.90, 1.0)
		"pyre_ascetic":
			return Color(1.0, 0.70, 0.48)
		_:
			return Color(1.0, 0.62, 0.38)

func _character_selection_roster_text() -> String:
	var lines: Array[String] = ["角色档案"]
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		lines.append("%s：%s" % [
			str(character_dict.get("name", character_dict.get("id", "角色"))),
			str(character_dict.get("design_note", ""))
		])
	return "\n".join(lines)

func _add_challenge_selection_controls(parent: Container = null) -> void:
	var target_parent: Container = parent if parent != null else reward_row
	if target_parent == null:
		return
	selected_challenge_level = _valid_challenge_level(selected_challenge_level)
	last_challenge_level = selected_challenge_level
	last_challenge_unlocked_max = _max_unlocked_challenge_level()
	last_challenge_modifier_summary = _challenge_modifier_summary(selected_challenge_level)

	var down_button := Button.new()
	down_button.custom_minimum_size = _challenge_button_size()
	down_button.text = "挑战 -\n当前 %d" % selected_challenge_level
	down_button.disabled = selected_challenge_level <= 0
	_apply_button_skin(down_button, "neutral")
	down_button.pressed.connect(_on_challenge_down_pressed)
	target_parent.add_child(down_button)
	last_challenge_button_count += 1

	var current_button := Button.new()
	current_button.custom_minimum_size = _challenge_button_size()
	current_button.text = "挑战 %d/%d\n%s" % [
		selected_challenge_level,
		last_challenge_unlocked_max,
		str(_challenge_config(selected_challenge_level).get("short_name", "普通"))
	]
	current_button.tooltip_text = _challenge_tooltip_text(selected_challenge_level)
	current_button.disabled = true
	_apply_button_skin(current_button, "relic")
	target_parent.add_child(current_button)
	last_challenge_button_count += 1

	var up_button := Button.new()
	up_button.custom_minimum_size = _challenge_button_size()
	up_button.text = "挑战 +\n最高 %d" % last_challenge_unlocked_max
	up_button.disabled = selected_challenge_level >= last_challenge_unlocked_max
	_apply_button_skin(up_button, "primary")
	up_button.pressed.connect(_on_challenge_up_pressed)
	target_parent.add_child(up_button)
	last_challenge_button_count += 1

func _challenge_button_size() -> Vector2:
	var available_width: float = _scroll_content_width()
	var width: float = floor((available_width - 12.0) / 3.0)
	return Vector2(clamp(width, 96.0, 146.0), clamp(round(76.0 * _page_layout_scale()), 52.0, 76.0))

func _challenge_selection_summary() -> String:
	selected_challenge_level = _valid_challenge_level(selected_challenge_level)
	last_challenge_level = selected_challenge_level
	last_challenge_unlocked_max = _max_unlocked_challenge_level()
	last_challenge_modifier_summary = _challenge_modifier_summary(selected_challenge_level)
	var config: Dictionary = _challenge_config(selected_challenge_level)
	last_challenge_summary = "挑战等级：%d/%d | %s\n%s\n修正：%s" % [
		selected_challenge_level,
		last_challenge_unlocked_max,
		str(config.get("name", "普通模式")),
		str(config.get("description", "")),
		last_challenge_modifier_summary
	]
	return last_challenge_summary

func _challenge_tooltip_text(level: int) -> String:
	var config: Dictionary = _challenge_config(level)
	return "%s\n%s\n%s\n%s" % [
		str(config.get("name", "挑战等级")),
		str(config.get("description", "")),
		str(config.get("design_note", "")),
		str(config.get("balance_note", ""))
	]

func _challenge_modifier_summary(level: int) -> String:
	var modifiers: Dictionary = _challenge_modifiers(level)
	var enemy_hp_percent: int = int(round(float(modifiers.get("enemy_hp_multiplier", 1.0)) * 100.0))
	var enemy_damage_percent: int = int(round(float(modifiers.get("enemy_damage_multiplier", 1.0)) * 100.0))
	var hp_loss: int = int(modifiers.get("player_starting_hp_loss", 0))
	return "生命倍率 %d%% | 伤害倍率 %d%% | 开局 -%dHP" % [enemy_hp_percent, enemy_damage_percent, hp_loss]

func _challenge_log_text(level: int, unlocked_max: int, short_name: String) -> String:
	var modifiers: Dictionary = _challenge_modifiers(level)
	var enemy_hp_percent: int = int(round(float(modifiers.get("enemy_hp_multiplier", 1.0)) * 100.0))
	var enemy_damage_percent: int = int(round(float(modifiers.get("enemy_damage_multiplier", 1.0)) * 100.0))
	var hp_loss: int = int(modifiers.get("player_starting_hp_loss", 0))
	if _scroll_content_width() < 420.0:
		return "挑战 %d/%d %s | HP%d%% 伤害%d%% -%dHP" % [
			level,
			unlocked_max,
			short_name,
			enemy_hp_percent,
			enemy_damage_percent,
			hp_loss
		]
	return "挑战 %d/%d：%s | %s" % [
		level,
		unlocked_max,
		short_name,
		_challenge_modifier_summary(level)
	]

func _challenge_config(level: int) -> Dictionary:
	for config in challenge_data.get("levels", []):
		var config_dict: Dictionary = config
		if int(config_dict.get("level", 0)) == level:
			return config_dict
	return {"level": 0, "name": "普通模式", "short_name": "普通", "description": "", "modifiers": {}}

func _challenge_modifiers(level: int) -> Dictionary:
	return _challenge_config(level).get("modifiers", {})

func _challenge_player_starting_hp_loss(level: int) -> int:
	return max(0, int(_challenge_modifiers(level).get("player_starting_hp_loss", 0)))

func _max_configured_challenge_level() -> int:
	var max_level := 0
	for config in challenge_data.get("levels", []):
		var config_dict: Dictionary = config
		max_level = max(max_level, int(config_dict.get("level", 0)))
	return max_level

func _max_unlocked_challenge_level() -> int:
	var stats: Dictionary = _profile_stats()
	var best_completed: int = int(stats.get("best_challenge_level_completed", 0))
	var runs_completed: int = int(stats.get("runs_completed", 0))
	var unlocked := 0
	if runs_completed > 0:
		unlocked = max(1, best_completed + 1)
	unlocked = min(unlocked, _max_configured_challenge_level())
	stats["max_challenge_level_unlocked"] = max(int(stats.get("max_challenge_level_unlocked", 0)), unlocked)
	player_profile["stats"] = stats
	return min(int(stats.get("max_challenge_level_unlocked", unlocked)), _max_configured_challenge_level())

func _valid_challenge_level(level: int) -> int:
	return clamp(level, 0, _max_unlocked_challenge_level())

func _configured_challenge_level(level: int) -> int:
	return clamp(level, 0, _max_configured_challenge_level())

func _card_names(card_ids: Array) -> String:
	var names: Array[String] = []
	var counts: Dictionary = {}
	for card_id_value in card_ids:
		var card_id: String = str(card_id_value)
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	for card_id in counts.keys():
		var card: Dictionary = _card_by_id(str(card_id))
		var card_name: String = str(card.get("name", card_id))
		var count: int = int(counts.get(card_id, 0))
		names.append("%s x%d" % [card_name, count])
	return "、".join(names)

func _relic_names(relic_ids: Array) -> String:
	var names: Array[String] = []
	for relic_id_value in relic_ids:
		var relic_id: String = str(relic_id_value)
		var relic: Dictionary = _relic_by_id(relic_id)
		names.append(str(relic.get("name", relic_id)))
	return "、".join(names)

func _refresh_character_panel() -> void:
	if character_panel == null or player_portrait == null or character_summary_label == null:
		return
	var config: Dictionary = _current_player_config()
	if config.is_empty():
		character_panel.visible = false
		if character_frame != null:
			character_frame.visible = false
		return
	character_panel.visible = true
	if character_frame != null:
		character_frame.visible = true
	player_portrait.texture = _load_texture(_character_art_path())
	var display_hp: int = int(combat.player.get("hp", run_hp)) if combat != null else run_hp
	if _scroll_content_width() < 420.0:
		character_summary_label.visible = true
		character_summary_label.custom_minimum_size = Vector2(180, 42)
		character_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		character_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		character_summary_label.text = "%s\nHP %d/%d | 能量 %d | 势能 %d/%d" % [
			_character_display_name(),
			display_hp,
			run_max_hp,
			int(config.get("max_energy", 3)),
			int(config.get("starting_momentum", 0)),
			int(config.get("momentum_max", 6))
		]
		character_summary_label.add_theme_font_size_override("font_size", 11)
		character_summary_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	else:
		character_summary_label.visible = true
		character_summary_label.custom_minimum_size = Vector2(0, 42)
		character_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		character_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		character_summary_label.text = "%s | %s\n生命 %d/%d | 能量 %d | 势能 %d/%d | 药水槽 %d" % [
			_character_display_name(),
			str(config.get("archetype_note", "")),
			display_hp,
			run_max_hp,
			int(config.get("max_energy", 3)),
			int(config.get("starting_momentum", 0)),
			int(config.get("momentum_max", 6)),
			int(config.get("potion_slots", 2))
		]
		character_summary_label.add_theme_font_size_override("font_size", 12)
		character_summary_label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.90))
	_refresh_relic_belt()

func _refresh_relic_belt() -> void:
	if relic_belt_row == null:
		return
	_clear_container(relic_belt_row)
	last_relic_belt_layout_count = 0
	last_relic_belt_icon_node_count = 0
	last_relic_belt_overflow_count = 0
	last_relic_belt_tooltips.clear()
	if _scroll_content_width() < 420.0:
		relic_belt_row.visible = false
		relic_belt_row.custom_minimum_size = Vector2.ZERO
		return
	relic_belt_row.visible = not run_relic_ids.is_empty()
	if run_relic_ids.is_empty():
		relic_belt_row.custom_minimum_size = Vector2(80, 42)
		return
	var cap: int = _relic_belt_cap()
	var belt_width: float = float(cap) * 38.0 + float(max(0, cap - 1)) * 5.0
	if run_relic_ids.size() > cap:
		belt_width += 43.0
	relic_belt_row.custom_minimum_size = Vector2(max(80.0, belt_width), 42)
	var shown: int = 0
	for relic_id_value in run_relic_ids:
		if shown >= cap:
			break
		var relic_id: String = str(relic_id_value)
		var relic: Dictionary = _relic_by_id(relic_id)
		var relic_button := _relic_belt_button(relic, relic_id)
		relic_belt_row.add_child(relic_button)
		shown += 1
	last_relic_belt_overflow_count = max(0, run_relic_ids.size() - shown)
	if last_relic_belt_overflow_count > 0:
		var more_button := Button.new()
		more_button.custom_minimum_size = Vector2(38, 38)
		more_button.text = "+%d" % last_relic_belt_overflow_count
		more_button.tooltip_text = "还有 %d 个遗物：%s" % [
			last_relic_belt_overflow_count,
			_relic_names(run_relic_ids.slice(shown, run_relic_ids.size()))
		]
		more_button.focus_mode = Control.FOCUS_NONE
		_apply_button_skin(more_button, "relic")
		relic_belt_row.add_child(more_button)

func _relic_belt_button(relic: Dictionary, fallback_id: String) -> Button:
	var relic_id: String = str(relic.get("id", fallback_id))
	var relic_name: String = str(relic.get("name", relic_id))
	var relic_description: String = str(relic.get("description", ""))
	var icon_path: String = _relic_icon_path(relic)
	var icon_texture: Texture2D = _load_texture(icon_path)
	last_relic_icon_path = icon_path
	last_relic_icon_loaded = icon_texture != null
	last_relic_belt_layout_count += 1
	if icon_texture != null:
		last_relic_belt_icon_node_count += 1
	var tooltip: String = "%s\n%s" % [relic_name, relic_description]
	last_relic_belt_tooltips.append(tooltip)
	var button := Button.new()
	button.custom_minimum_size = Vector2(38, 38)
	button.text = ""
	button.icon = icon_texture
	button.expand_icon = true
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_HELP
	_apply_button_skin(button, "relic")
	return button

func _relic_belt_cap() -> int:
	var available_width: float = _layout_viewport_size().x - _root_horizontal_margin()
	if available_width < 420.0:
		return 2
	if available_width < 900.0:
		return 4
	return 6

func _build_route() -> void:
	var map_config: Dictionary = _map_config_for_current_character(current_chapter_id)
	map_graph = MapGeneratorScript.generate(map_config)
	route_nodes = _flatten_map_nodes(map_graph)
	if route_nodes.is_empty() and current_chapter_id == "chapter_one":
		route_nodes = route_data.get("nodes", []).duplicate(true)
		map_graph = {}
	if route_nodes.is_empty():
		route_nodes = [
			{"id": "fallback_0", "type": "combat", "name": "煤烟巡逻队", "encounter_id": "intro_patrol"},
			{"id": "fallback_1", "type": "campfire", "name": "裂炉营地"},
			{"id": "fallback_2", "type": "shop", "name": "灰市商人"},
			{"id": "fallback_3", "type": "boss", "name": "炉心礼拜堂", "encounter_id": "chapter_one_boss"}
		]
	current_node_id = str(map_graph.get("start_node_id", ""))
	if current_node_id.is_empty() and not route_nodes.is_empty():
		current_node_id = str(route_nodes[0].get("id", "fallback_0"))
	current_node_index = _node_index_by_id(current_node_id)
	available_node_ids = [current_node_id]

func _map_config_for_current_character(chapter_id: String) -> Dictionary:
	var config: Dictionary = map_generation_data.get(chapter_id, {}).duplicate(true)
	var filtered_event_pool: Array = []
	for event_id_value in config.get("event_pool", []):
		var event_id: String = str(event_id_value)
		var event: Dictionary = _event_by_id(event_id)
		if event.is_empty() or _event_available_for_current_character(event):
			filtered_event_pool.append(event_id)
	config["event_pool"] = filtered_event_pool
	return config

func _event_available_for_current_character(event: Dictionary) -> bool:
	var character_ids: Array = event.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(selected_character_id):
		return false
	var pool_tags: Array = event.get("pool_tags", [])
	if pool_tags.is_empty():
		return true
	var character_tags: Array = _current_player_config().get("reward_pool_tags", ["shared", selected_character_id])
	for tag in pool_tags:
		if character_tags.has(str(tag)):
			return true
	return false

func _start_current_node() -> void:
	if current_node_id.is_empty() and not available_node_ids.is_empty():
		combat = null
		_refresh()
		return
	if current_node_id.is_empty() or current_node_index >= route_nodes.size():
		run_completed = true
		combat = null
		_refresh()
		return

	var node: Dictionary = _current_node()
	var node_type: String = str(node.get("type", ""))
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	reward_generated_for = ""
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	selected_enemy_index = 0
	current_node_index = _node_index_by_id(current_node_id)
	available_node_ids.clear()

	if _is_battle_node(node_type):
		var encounter_id: String = str(node.get("encounter_id", "intro_patrol"))
		if _record_encounter_discoveries(encounter_id):
			_save_player_profile()
		combat = CombatStateScript.new()
		combat.setup(card_data, enemy_data, relic_data, encounter_data, _player_data_for_current_character(), encounter_id, run_deck_ids, run_relic_ids, run_hp)
		combat.changed.connect(_refresh)
	else:
		if node_type == "event":
			var event_id: String = str(node.get("event_id", ""))
			if _record_discovered_content("events", event_id):
				_save_player_profile()
		combat = null
	_refresh()

func _refresh() -> void:
	if profile_open:
		_music_context("menu")
		_set_run_controls_enabled(not character_select_open and not run_deck_ids.is_empty())
		_refresh_profile_view()
		return

	if settings_open:
		_music_context("menu")
		_set_run_controls_enabled(not character_select_open and not run_deck_ids.is_empty())
		_refresh_settings_view()
		return

	if tutorial_open:
		_music_context("menu")
		_set_run_controls_enabled(not character_select_open and not run_deck_ids.is_empty())
		_refresh_tutorial_view()
		return

	if compendium_open:
		_music_context("menu")
		_set_run_controls_enabled(not character_select_open and not run_deck_ids.is_empty())
		_refresh_compendium_view()
		return

	last_settings_panel_visible = false
	last_profile_panel_visible = false
	last_tutorial_page_visible = false
	last_compendium_panel_visible = false
	if character_select_open:
		_music_context("menu")
		_set_run_controls_enabled(false)
		_refresh_character_select()
		_apply_tutorial_hint("character_select")
		return

	_set_run_controls_enabled(true)
	_refresh_character_panel()

	if deck_view_open:
		_music_context("map")
		_refresh_deck_view()
		_apply_tutorial_hint("deck_view")
		return

	if run_completed:
		_music_context("victory")
		_refresh_run_completed()
		_apply_tutorial_hint("run_complete")
		return

	if current_node_id.is_empty() and not available_node_ids.is_empty():
		_music_context("map")
		_refresh_map_choices()
		_apply_tutorial_hint("map_choice")
		return

	var node: Dictionary = _current_node()
	var node_type: String = str(node.get("type", ""))
	_refresh_run_header(node)

	if _is_battle_node(node_type):
		_refresh_combat()
		_apply_tutorial_hint("combat_reward" if combat != null and (combat.phase == "won" or combat.phase == "lost") else "combat_player")
	elif node_type == "campfire":
		_music_context("campfire")
		_refresh_campfire(node)
		_apply_tutorial_hint("campfire")
	elif node_type == "shop":
		_music_context("shop")
		_refresh_shop(node)
		_apply_tutorial_hint("shop")
	elif node_type == "event":
		_music_context("event")
		_refresh_event(node)
		_apply_tutorial_hint("event")
	else:
		_refresh_unknown_node(node)
		_apply_tutorial_hint("")

func _set_run_controls_enabled(active_run: bool) -> void:
	if restart_button != null:
		restart_button.disabled = false
	if save_button != null:
		save_button.disabled = not active_run
	if deck_button != null:
		deck_button.disabled = not active_run
	if load_button != null:
		load_button.disabled = false
	if tutorial_button != null:
		tutorial_button.disabled = false
	if profile_button != null:
		profile_button.disabled = false
	if compendium_button != null:
		compendium_button.disabled = false
	if settings_button != null:
		settings_button.disabled = false

func _set_page_regions(character_visible: bool, hud_visible: bool, map_visible: bool, potions_visible: bool, enemies_visible: bool, log_visible: bool, hand_visible: bool, rewards_visible: bool) -> void:
	if character_frame != null:
		character_frame.visible = character_visible
	if character_panel != null:
		character_panel.visible = character_visible
	if battle_board_panel != null:
		battle_board_panel.visible = hud_visible or potions_visible or enemies_visible
	if combat_hud_row != null:
		combat_hud_row.visible = hud_visible
	if map_scroll != null:
		map_scroll.visible = map_visible
	if map_view != null:
		map_view.visible = map_visible
	if potion_row != null:
		potion_row.visible = potions_visible
	if enemy_stage_panel != null:
		enemy_stage_panel.visible = enemies_visible
	if enemy_row != null:
		enemy_row.visible = enemies_visible
	if log_label != null:
		log_label.visible = log_visible
	if hand_frame != null:
		hand_frame.visible = hand_visible
	if hand_scroll != null:
		hand_scroll.visible = hand_visible
	if hand_row != null:
		hand_row.visible = hand_visible
	if reward_scroll != null:
		reward_scroll.visible = rewards_visible
	if reward_row != null:
		reward_row.visible = rewards_visible

func _set_content_heights(log_height: float = 210.0, reward_height: float = 112.0) -> void:
	if log_label != null:
		log_label.custom_minimum_size = Vector2(0, log_height)
	if reward_scroll != null:
		reward_scroll.custom_minimum_size = Vector2(0, reward_height)
	if reward_row != null:
		var content_width: float = _scroll_content_width()
		reward_row.custom_minimum_size = Vector2(content_width, reward_height)
		reward_row.size = Vector2(content_width, max(reward_row.size.y, reward_height))
		last_reward_scroll_height = reward_height

func _apply_character_select_layout_constraints() -> void:
	var scale_y: float = _page_layout_scale()
	var log_height: float = clamp(round(52.0 * scale_y), 44.0, 56.0)
	var reward_height: float = clamp(round(322.0 * scale_y), 232.0, 322.0)
	_set_content_heights(log_height, reward_height)
	_record_scroll_region_metrics()

func _apply_map_layout_constraints() -> void:
	var scale_y: float = _page_layout_scale()
	var map_height: float = clamp(round(316.0 * scale_y), 244.0, 330.0)
	if map_scroll != null:
		map_scroll.custom_minimum_size = Vector2(0, map_height)
	if map_view != null:
		var map_width: float = _map_view_required_width()
		map_view.custom_minimum_size = Vector2(map_width, map_height)
		map_view.size = Vector2(map_width, map_height)
	_set_content_heights(clamp(round(104.0 * scale_y), 82.0, 120.0), 0.0)
	_record_scroll_region_metrics()

func _apply_reward_page_layout_constraints(log_height: float = 170.0, reward_height: float = 190.0) -> void:
	var scale_y: float = _page_layout_scale()
	_set_content_heights(round(log_height * scale_y), round(reward_height * scale_y))
	_record_scroll_region_metrics()

func _apply_combat_layout_constraints(reward_visible: bool) -> void:
	var scale_y: float = _combat_layout_scale()
	if character_frame != null:
		character_frame.custom_minimum_size = Vector2(0, clamp(round(58.0 * scale_y), 42.0, 58.0))
	if character_panel != null:
		character_panel.custom_minimum_size = Vector2(0, clamp(round(50.0 * scale_y), 38.0, 50.0))
	if player_portrait != null:
		var portrait_size: float = clamp(round(48.0 * scale_y), 34.0, 48.0)
		player_portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)

	if battle_board_panel != null:
		battle_board_panel.custom_minimum_size = Vector2(0, clamp(round(244.0 * scale_y), 176.0, 244.0))
	if battle_board_box != null:
		battle_board_box.add_theme_constant_override("separation", max(2, int(round(5.0 * scale_y))))
	if combat_hud_row != null:
		combat_hud_row.custom_minimum_size = Vector2(0, clamp(round(38.0 * scale_y), 27.0, 38.0))
		combat_hud_row.add_theme_constant_override("separation", 6)
	if feedback_label != null:
		feedback_label.custom_minimum_size = Vector2(0, clamp(round(28.0 * scale_y), 20.0, 28.0))
		feedback_label.add_theme_font_size_override("font_size", max(12, int(round(14.0 * scale_y))))
	if battle_mid_row != null:
		battle_mid_row.custom_minimum_size = Vector2(0, clamp(round(150.0 * scale_y), 108.0, 150.0))
	if enemy_stage_panel != null:
		enemy_stage_panel.custom_minimum_size = Vector2(0, clamp(round(148.0 * scale_y), 106.0, 148.0))
	if enemy_stage_stack != null:
		enemy_stage_stack.custom_minimum_size = Vector2(0, clamp(round(136.0 * scale_y), 98.0, 136.0))
	if enemy_row != null:
		enemy_row.custom_minimum_size = Vector2(0, clamp(round(136.0 * scale_y), 98.0, 136.0))
		enemy_row.add_theme_constant_override("separation", _enemy_panel_gap())
	if potion_row != null:
		potion_row.custom_minimum_size = Vector2(_potion_row_width(), clamp(round(52.0 * scale_y), 38.0, 52.0))
		potion_row.add_theme_constant_override("separation", _potion_slot_gap())

	var log_height: float = clamp(round((110.0 if reward_visible else 58.0) * scale_y), 40.0 if not reward_visible else 74.0, 110.0 if reward_visible else 58.0)
	var reward_height: float = round((190.0 if reward_visible else 0.0) * scale_y)
	var hand_frame_height: float = clamp(round(150.0 * scale_y), 124.0, 150.0)
	var hand_scroll_height: float = clamp(hand_frame_height - 10.0, 114.0, 140.0)
	if hand_frame != null:
		hand_frame.custom_minimum_size = Vector2(0, hand_frame_height)
	if hand_scroll != null:
		hand_scroll.custom_minimum_size = Vector2(0, hand_scroll_height)
	if hand_row != null:
		var hand_width: float = _hand_required_width()
		var hand_height: float = hand_scroll_height
		hand_row.custom_minimum_size = Vector2(hand_width, hand_height)
		hand_row.size = Vector2(hand_width, hand_height)
		hand_row.add_theme_constant_override("separation", _hand_card_gap())
	_set_content_heights(log_height, reward_height)
	_record_scroll_region_metrics()

func _combat_layout_scale() -> float:
	var available_height: float = _layout_viewport_size().y - _root_vertical_margin()
	return clamp(available_height / 860.0, 0.70, 1.0)

func _page_layout_scale() -> float:
	var available_height: float = _layout_viewport_size().y - _root_vertical_margin()
	return clamp(available_height / 840.0, 0.68, 1.0)

func _layout_viewport_size() -> Vector2:
	if debug_viewport_size_override.x > 0.0 and debug_viewport_size_override.y > 0.0:
		return debug_viewport_size_override
	var viewport_size: Vector2 = Vector2.ZERO
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		var width := 1280.0
		var height := 720.0
		if ProjectSettings.has_setting("display/window/size/viewport_width"):
			width = float(ProjectSettings.get_setting("display/window/size/viewport_width"))
		if ProjectSettings.has_setting("display/window/size/viewport_height"):
			height = float(ProjectSettings.get_setting("display/window/size/viewport_height"))
		viewport_size = Vector2(width, height)
	return viewport_size

func _scroll_content_width() -> float:
	return max(MIN_SAFE_CONTENT_WIDTH, _layout_viewport_size().x - _root_horizontal_margin() - SCROLLBAR_WIDTH_RESERVE)

func _bounded_width(preferred_width: float, minimum_width: float, maximum_width: float) -> float:
	var available_width: float = _scroll_content_width()
	var safe_minimum: float = min(minimum_width, available_width)
	var safe_maximum: float = min(maximum_width, available_width)
	return clamp(preferred_width, safe_minimum, max(safe_minimum, safe_maximum))

func _map_view_required_width() -> float:
	var layer_count: int = 1
	if not map_graph.is_empty():
		layer_count = max(1, map_graph.get("layers", []).size())
	var minimum_layer_width := 150.0
	var required_width: float = 88.0 + float(layer_count) * minimum_layer_width
	return max(_scroll_content_width(), required_width)

func _character_select_card_size() -> Vector2:
	var available_width: float = _scroll_content_width()
	var gap := 6.0
	var columns := 1
	if available_width >= 1120.0:
		columns = 3
	elif available_width >= 720.0:
		columns = 2
	var width: float = floor((available_width - gap * float(columns - 1)) / float(columns))
	width = _bounded_width(width, 286.0, 380.0)
	var height: float = clamp(round(204.0 * _page_layout_scale()), 146.0, 204.0)
	return Vector2(width, height)

func _large_card_button_size() -> Vector2:
	var scale_y: float = _page_layout_scale()
	return Vector2(clamp(round(158.0 * scale_y), 132.0, 158.0), clamp(round(184.0 * scale_y), 154.0, 184.0))

func _large_item_button_size() -> Vector2:
	var scale_y: float = _page_layout_scale()
	return Vector2(clamp(round(150.0 * scale_y), 128.0, 150.0), clamp(round(118.0 * scale_y), 96.0, 118.0))

func _small_action_button_size() -> Vector2:
	var scale_y: float = _page_layout_scale()
	return Vector2(120, clamp(round(96.0 * scale_y), 78.0, 96.0))

func _event_story_panel_size() -> Vector2:
	var width: float = _bounded_width(_scroll_content_width(), 286.0, 520.0)
	var height: float = clamp(round(138.0 * _page_layout_scale()), 118.0, 138.0)
	return Vector2(width, height)

func _event_story_art_size(panel_width: float) -> Vector2:
	var art_width: float = 130.0
	if panel_width < 340.0:
		art_width = 88.0
	elif panel_width < 440.0:
		art_width = 104.0
	var art_height: float = clamp(round(120.0 * _page_layout_scale()), 96.0, 120.0)
	return Vector2(art_width, art_height)

func _cinematic_panel_size() -> Vector2:
	var viewport_size: Vector2 = _layout_viewport_size()
	var width: float = clamp(viewport_size.x - _root_horizontal_margin() * 2.0, MIN_SAFE_CONTENT_WIDTH, min(620.0, viewport_size.x))
	return Vector2(width, clamp(round(164.0 * _page_layout_scale()), 132.0, 164.0))

func _root_vertical_margin() -> float:
	return ROOT_MARGIN_TOP + ROOT_MARGIN_BOTTOM

func _root_horizontal_margin() -> float:
	return ROOT_MARGIN_LEFT + ROOT_MARGIN_RIGHT

func _hand_card_gap() -> int:
	return 6

func _hand_card_size() -> Vector2:
	var card_count := 5
	if combat != null:
		card_count = max(1, combat.hand.size())
	var available_width: float = _scroll_content_width()
	var width: float = floor((available_width - float(card_count - 1) * float(_hand_card_gap())) / float(card_count))
	width = clamp(width, 88.0, 136.0)
	var height: float = clamp(round(136.0 * _combat_layout_scale()), 112.0, 140.0)
	return Vector2(width, height)

func _hand_required_width() -> float:
	var card_count := 5
	if combat != null:
		card_count = max(1, combat.hand.size())
	var card_size: Vector2 = _hand_card_size()
	return float(card_count) * card_size.x + float(max(0, card_count - 1)) * float(_hand_card_gap())

func _record_scroll_region_metrics() -> void:
	last_reward_flow_available_width = _scroll_content_width()
	last_reward_flow_required_width = _container_required_width(reward_row)
	last_reward_flow_wrap_needed = last_reward_flow_required_width > last_reward_flow_available_width
	last_hand_scroll_width = _scroll_content_width()
	last_hand_required_width = _hand_required_width()
	last_hand_horizontal_scroll_needed = last_hand_required_width > last_hand_scroll_width

func _container_required_width(container: Container) -> float:
	if container == null:
		return 0.0
	var total := 0.0
	var visible_count := 0
	var gap := 0
	if container is HFlowContainer:
		gap = container.get_theme_constant("h_separation")
	elif container is BoxContainer:
		gap = container.get_theme_constant("separation")
	for child in container.get_children():
		var child_control := child as Control
		if child_control == null or not child_control.visible:
			continue
		total += max(child_control.custom_minimum_size.x, child_control.size.x)
		visible_count += 1
	if visible_count > 1:
		total += float(gap) * float(visible_count - 1)
	return total

func _enemy_panel_gap() -> int:
	return 8

func _enemy_panel_width() -> float:
	var enemy_count := 1
	if combat != null:
		enemy_count = max(1, combat.enemies.size())
	var content_width: float = _scroll_content_width()
	var available_width: float = content_width - _potion_row_width() - 20.0
	var width: float = floor((available_width - float(enemy_count - 1) * float(_enemy_panel_gap())) / float(enemy_count))
	var minimum_width := 72.0
	if content_width < 360.0:
		minimum_width = 36.0
	elif content_width < 460.0:
		minimum_width = 44.0
	return clamp(width, minimum_width, 198.0)

func _enemy_panel_height() -> float:
	return clamp(round(132.0 * _combat_layout_scale()), 96.0, 136.0)

func _enemy_art_height() -> float:
	return clamp(round(58.0 * _combat_layout_scale()), 38.0, 62.0)

func _enemy_badge_height() -> float:
	return clamp(round(22.0 * _combat_layout_scale()), 18.0, 24.0)

func _enemy_button_height() -> float:
	return clamp(round(42.0 * _combat_layout_scale()), 32.0, 46.0)

func _potion_slot_gap() -> int:
	return 6

func _potion_slot_button_size() -> Vector2:
	var scale_y: float = _combat_layout_scale()
	var slots := 2
	if player_data != null and not player_data.is_empty():
		slots = max(1, _max_potion_slots())
	var available_width: float = _scroll_content_width()
	var target_minimum := 210.0
	var slot_minimum := 48.0
	if available_width < 420.0:
		target_minimum = 96.0
		slot_minimum = 28.0
	var target_row_width: float = clamp(available_width * (0.38 if slots >= 3 else 0.34), target_minimum, min(344.0, available_width))
	if available_width < 420.0:
		target_row_width = clamp(available_width * (0.30 if slots >= 3 else 0.26), target_minimum, min(132.0, available_width))
	var label_width := 44.0
	if available_width < 420.0:
		label_width = 30.0
	var slot_width: float = floor((target_row_width - label_width - float(slots) * float(_potion_slot_gap())) / float(slots))
	return Vector2(clamp(slot_width, slot_minimum, 96.0), clamp(round(48.0 * scale_y), 34.0, 50.0))

func _potion_row_width() -> float:
	var slots := 2
	if player_data != null and not player_data.is_empty():
		slots = max(1, _max_potion_slots())
	var label_width := 44.0
	if _scroll_content_width() < 420.0:
		label_width = 30.0
	return label_width + float(slots) * _potion_slot_button_size().x + float(max(0, slots)) * float(_potion_slot_gap())

func _hud_block_width() -> float:
	var entries := 7
	var gap := 6.0
	var available_width: float = _scroll_content_width()
	var width: float = floor((available_width - float(entries - 1) * gap) / float(entries))
	var minimum_width := 64.0 if available_width >= 420.0 else 38.0
	return clamp(width, minimum_width, 98.0)

func _estimated_control_height(control: Control) -> float:
	if control == null:
		return 0.0
	if control.custom_minimum_size.y > 0.0:
		return control.custom_minimum_size.y
	if control is BoxContainer:
		var max_child_height := 0.0
		for child in control.get_children():
			var child_control := child as Control
			if child_control != null and child_control.visible:
				max_child_height = max(max_child_height, _estimated_control_height(child_control))
		return max(max_child_height, control.size.y)
	if control is Button:
		return max(control.size.y, 30.0)
	if control is Label:
		var label := control as Label
		return max(label.size.y, float(label.get_theme_font_size("font_size")) + 6.0)
	return max(control.size.y, 0.0)

func _refresh_character_select() -> void:
	last_character_selection_title = "选择角色"
	last_character_selection_ids.clear()
	last_character_button_icon_count = 0
	last_challenge_button_count = 0
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		last_character_selection_ids.append(str(character_dict.get("id", "")))

	run_label.text = "新跑团 | %s" % last_character_selection_title
	status_label.text = "选择本次跑团的角色和挑战等级。不同角色拥有独立初始牌组、起始遗物、生命、势能和药水槽。"
	_set_page_regions(false, false, false, false, false, true, false, true)
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	_apply_character_select_layout_constraints()
	var challenge_summary: String = _challenge_selection_summary()
	var challenge_config: Dictionary = _challenge_config(selected_challenge_level)
	log_label.text = _challenge_log_text(
		selected_challenge_level,
		last_challenge_unlocked_max,
		str(challenge_config.get("short_name", "普通"))
	)
	log_label.tooltip_text = "%s\n\n%s" % [challenge_summary, _character_selection_roster_text()]

	var character_select_width: float = _scroll_content_width()
	var challenge_row := HBoxContainer.new()
	challenge_row.custom_minimum_size = Vector2(character_select_width, _challenge_button_size().y)
	challenge_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	challenge_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	challenge_row.add_theme_constant_override("separation", 8)
	reward_row.add_child(challenge_row)
	_add_challenge_selection_controls(challenge_row)

	var roster_parent: Container = null
	if character_select_width < 720.0:
		var roster_scroll := ScrollContainer.new()
		roster_scroll.custom_minimum_size = Vector2(character_select_width, _character_select_card_size().y)
		roster_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		roster_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		roster_scroll.clip_contents = true
		roster_scroll.set("horizontal_scroll_mode", 1)
		roster_scroll.set("vertical_scroll_mode", 0)
		reward_row.add_child(roster_scroll)

		var roster_row := HBoxContainer.new()
		var card_size: Vector2 = _character_select_card_size()
		var card_count: int = max(1, player_data.get("characters", []).size())
		var required_width: float = card_size.x * float(card_count) + 8.0 * float(max(0, card_count - 1))
		roster_row.custom_minimum_size = Vector2(required_width, card_size.y)
		roster_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		roster_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		roster_row.add_theme_constant_override("separation", 8)
		roster_scroll.add_child(roster_row)
		roster_parent = roster_row
	else:
		var roster_flow := HFlowContainer.new()
		roster_flow.custom_minimum_size = Vector2(character_select_width, _character_select_card_size().y)
		roster_flow.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		roster_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		roster_flow.add_theme_constant_override("separation", 8)
		roster_flow.add_theme_constant_override("h_separation", 8)
		roster_flow.add_theme_constant_override("v_separation", 8)
		reward_row.add_child(roster_flow)
		roster_parent = roster_flow

	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		var character_id: String = str(character_dict.get("id", ""))
		if character_id.is_empty():
			continue
		var button := Button.new()
		button.custom_minimum_size = _character_select_card_size()
		button.tooltip_text = _character_selection_tooltip_text(character_dict)
		button.text = ""
		var character_texture: Texture2D = _load_texture(_character_art_path(character_id))
		if character_texture != null:
			last_character_button_icon_count += 1
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color(0.95, 0.96, 0.92))
		button.add_theme_stylebox_override("normal", _character_button_style(character_id, false, false))
		button.add_theme_stylebox_override("hover", _character_button_style(character_id, true, false))
		button.add_theme_stylebox_override("pressed", _character_button_style(character_id, true, true))
		_configure_button_bounds(button)
		_add_character_select_card_layout(button, character_dict, character_texture)
		button.pressed.connect(_on_character_selected.bind(character_id))
		roster_parent.add_child(button)
	_record_layout_metrics()

func _refresh_run_header(node: Dictionary) -> void:
	run_label.text = "%s | %s | 挑战 %d | 路线 %d/%d：%s [%s] | 金币：%d | 生命：%d/%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [
		_character_display_name(),
		_chapter_display_name(current_chapter_id),
		current_challenge_level,
		current_node_index + 1,
		route_nodes.size(),
		node.get("name", "节点"),
		node.get("type", ""),
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size(),
		", ".join(run_relic_ids),
		_potion_summary()
	]

func _refresh_run_completed() -> void:
	_set_page_regions(false, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(210.0, 116.0)
	last_run_completion_title = _run_completion_title()
	last_run_unlocks = _run_completion_unlocks()
	last_run_completion_summary = _run_completion_summary()
	run_label.text = "跑团完成 | %s | %s | 挑战 %d | 金币：%d | 生命：%d/%d | 牌组：%d 张" % [
		_character_display_name(),
		_chapter_display_name(current_chapter_id),
		current_challenge_level,
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size()
	]
	status_label.text = last_run_completion_title
	feedback_label.text = "最终胜利"
	feedback_label.visible = true
	feedback_label.custom_minimum_size = Vector2(0, 58)
	feedback_label.add_theme_font_size_override("font_size", 26)
	feedback_label.add_theme_stylebox_override("normal", _feedback_style("success"))
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = last_run_completion_summary
	end_turn_button.disabled = true

	var deck_summary_button := Button.new()
	deck_summary_button.custom_minimum_size = Vector2(180, 96)
	deck_summary_button.text = "查看最终牌组"
	_apply_button_skin(deck_summary_button, "primary")
	deck_summary_button.pressed.connect(_on_deck_view_pressed)
	reward_row.add_child(deck_summary_button)

	var profile_summary_button := Button.new()
	profile_summary_button.custom_minimum_size = Vector2(160, 96)
	profile_summary_button.text = "查看档案\n成就 %d/%d" % [last_profile_unlocked_count, last_profile_total_count]
	_apply_button_skin(profile_summary_button, "relic")
	profile_summary_button.pressed.connect(_on_profile_pressed)
	reward_row.add_child(profile_summary_button)

	var restart_run_button := Button.new()
	restart_run_button.custom_minimum_size = Vector2(160, 96)
	restart_run_button.text = "再来一局"
	_apply_button_skin(restart_run_button, "success")
	restart_run_button.pressed.connect(_on_new_run_pressed)
	reward_row.add_child(restart_run_button)
	_record_layout_metrics()

func _run_completion_summary() -> String:
	var summary: Dictionary = _deck_summary()
	var chapter_names: Array[String] = []
	for chapter_id in completed_chapter_ids:
		chapter_names.append(_chapter_display_name(str(chapter_id)))
	var unlock_lines: Array[String] = []
	for unlock in last_run_unlocks:
		unlock_lines.append("- %s" % unlock)
	return "%s\n\n%s\n\n通关角色：%s\n挑战等级：%d\n完成章节：%s\n最终资源：生命 %d/%d | 金币 %d | 遗物 %d | 药水 %d\n牌组统计：总数 %d | 攻击 %d | 技能 %d | 能力 %d | 状态/诅咒 %d | 升级 %d\n\n局外解锁：\n%s" % [
		last_run_completion_title,
		_run_completion_epilogue(),
		_character_display_name(),
		current_challenge_level,
		" -> ".join(chapter_names),
		run_hp,
		run_max_hp,
		run_gold,
		run_relic_ids.size(),
		run_potion_ids.size(),
		run_deck_ids.size(),
		int(summary.get("attack", 0)),
		int(summary.get("skill", 0)),
		int(summary.get("power", 0)),
		int(summary.get("other", 0)),
		int(summary.get("upgraded", 0)),
		"\n".join(unlock_lines)
	]

func _run_completion_title() -> String:
	var ending: Dictionary = _current_player_config().get("ending", {})
	return str(ending.get("victory_title", "最终胜利：回路核心已关闭"))

func _run_completion_epilogue() -> String:
	var ending: Dictionary = _current_player_config().get("ending", {})
	return str(ending.get("epilogue", "回路核心停止轰鸣，远处的余烬重新归于沉默。"))

func _run_completion_unlocks() -> Array[String]:
	var unlocks: Array[String] = []
	if completed_chapter_ids.has("chapter_one"):
		unlocks.append("图鉴条目：余烬下城")
	if completed_chapter_ids.has("chapter_two"):
		unlocks.append("图鉴条目：风暴高塔")
	if completed_chapter_ids.has("chapter_three"):
		unlocks.append("挑战模式：回路核心重构")
		var ending: Dictionary = _current_player_config().get("ending", {})
		var completion_mark: String = str(ending.get("completion_mark", "局外记录：%s通关印记" % _character_display_name()))
		if not completion_mark.is_empty():
			unlocks.append(completion_mark)
		for meta_unlock in ending.get("meta_unlocks", []):
			var unlock_text: String = str(meta_unlock)
			if not unlock_text.is_empty() and not unlocks.has(unlock_text):
				unlocks.append(unlock_text)
	return unlocks

func _refresh_map_choices() -> void:
	_set_page_regions(true, false, true, false, false, true, false, false)
	_apply_map_layout_constraints()
	run_label.text = "%s | %s | 挑战 %d | 地图选择 | 金币：%d | 生命：%d/%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [
		_character_display_name(),
		_chapter_display_name(current_chapter_id),
		current_challenge_level,
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size(),
		", ".join(run_relic_ids),
		_potion_summary()
	]
	status_label.text = "选择下一处节点。当前是分叉地图后端生成的路线；按钮只显示从当前节点可到达的下一层。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	map_view.set_map_state(_map_graph_for_view(), available_node_ids, completed_node_ids, current_node_id)
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	_update_map_preview(_default_map_preview_node_id())
	end_turn_button.disabled = true
	_record_layout_metrics()

func _refresh_deck_view() -> void:
	_set_page_regions(true, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(160.0, 204.0)
	last_deck_view_card_layout_count = 0
	last_deck_view_card_art_node_count = 0
	run_label.text = "%s | %s | 挑战 %d | 牌组查看 | 金币：%d | 生命：%d/%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [
		_character_display_name(),
		_chapter_display_name(current_chapter_id),
		current_challenge_level,
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size(),
		", ".join(run_relic_ids),
		_potion_summary()
	]
	status_label.text = "当前牌组。升级牌以 + 标记；后续会升级为可悬停详情和排序筛选。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true

	var summary: Dictionary = _deck_summary()
	log_label.text = "牌组统计\n攻击：%d\n技能：%d\n能力：%d\n状态/诅咒：%d\n升级牌：%d\n\n%s" % [
		int(summary.get("attack", 0)),
		int(summary.get("skill", 0)),
		int(summary.get("power", 0)),
		int(summary.get("other", 0)),
		int(summary.get("upgraded", 0)),
		_deck_list_text()
	]

	var close_button := Button.new()
	close_button.custom_minimum_size = _small_action_button_size()
	close_button.text = "关闭牌组"
	_apply_button_skin(close_button, "neutral")
	close_button.pressed.connect(_on_close_deck_view_pressed)
	reward_row.add_child(close_button)

	var shown: int = 0
	for entry_value in run_deck_ids:
		var card: Dictionary = _deck_display_card(str(entry_value))
		if card.is_empty():
			continue
		var card_button := Button.new()
		card_button.custom_minimum_size = _large_card_button_size()
		card_button.text = ""
		card_button.tooltip_text = "%s [%d]\n%s\n%s" % [
			card.get("name", "卡牌"),
			int(card.get("cost", 0)),
			_card_type_display_name(str(card.get("type", ""))),
			card.get("description", "")
		]
		var art_path: String = _card_art_path(card)
		var card_texture: Texture2D = _load_texture(art_path)
		_apply_card_button_skin(card_button, str(card.get("type", "")))
		card_button.disabled = true
		_add_structured_card_layout(card_button, card, card_texture, "deck_view")
		reward_row.add_child(card_button)
		shown += 1
		if shown >= 5:
			break
	_record_layout_metrics()

func _refresh_settings_view() -> void:
	last_settings_panel_visible = true
	last_settings_button_count = 0
	_apply_runtime_settings()
	_set_page_regions(false, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(132.0, 216.0)
	run_label.text = "系统设置 | 自动保存到 user://ember_circuit_settings.json"
	status_label.text = "调整音频和战斗表现。设置会立即保存，不写入跑团存档。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	log_label.text = _settings_summary_text()

	_add_settings_button("音频\n%s\n点击切换" % _on_off_text(_setting_enabled("audio_enabled", true)), "potion", Callable(self, "_on_settings_toggle_audio"))
	_add_settings_button("音量 -\n当前 %d%%" % _settings_volume_percent(), "neutral", Callable(self, "_on_settings_volume_down"))
	_add_settings_button("音量 +\n当前 %d%%" % _settings_volume_percent(), "primary", Callable(self, "_on_settings_volume_up"))
	_add_settings_button("音乐\n%s\n点击切换" % _on_off_text(_setting_enabled("music_enabled", true)), "event", Callable(self, "_on_settings_toggle_music"))
	_add_settings_button("BGM -\n当前 %d%%" % _settings_music_volume_percent(), "neutral", Callable(self, "_on_settings_music_volume_down"))
	_add_settings_button("BGM +\n当前 %d%%" % _settings_music_volume_percent(), "primary", Callable(self, "_on_settings_music_volume_up"))
	_add_settings_button("震屏\n%s\n点击切换" % _on_off_text(_setting_enabled("screen_shake_enabled", true)), "event", Callable(self, "_on_settings_toggle_screen_shake"))
	_add_settings_button("受击顿帧\n%s\n点击切换" % _on_off_text(_setting_enabled("hit_stop_enabled", true)), "relic", Callable(self, "_on_settings_toggle_hit_stop"))
	_add_settings_button("漂浮文字\n%s\n点击切换" % _on_off_text(_setting_enabled("floating_text_enabled", true)), "success", Callable(self, "_on_settings_toggle_floating_text"))
	_add_settings_button("新手引导\n%s\n点击切换" % _on_off_text(_setting_enabled("tutorial_enabled", true)), "event", Callable(self, "_on_settings_toggle_tutorial"))
	_add_settings_button("重置引导\n重新显示全部提示", "neutral", Callable(self, "_on_settings_reset_tutorial_pressed"))
	_add_settings_button("恢复默认\n重置全部设置", "danger", Callable(self, "_on_settings_reset_pressed"))
	_add_settings_button("返回\n回到当前页面", "primary", Callable(self, "_on_close_settings_pressed"))
	_apply_tutorial_hint("settings")
	_record_layout_metrics()

func _add_settings_button(text: String, skin: String, pressed_callable: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(158, 92)
	button.text = text
	_apply_button_skin(button, skin)
	button.pressed.connect(pressed_callable)
	reward_row.add_child(button)
	last_settings_button_count += 1

func _settings_summary_text() -> String:
	last_settings_summary = "设置摘要\n音效：%s\n主音量：%d%%\n音乐：%s\nBGM 音量：%d%%\n震屏：%s\n受击顿帧：%s\n漂浮战斗文字：%s\n新手引导：%s\n引导进度：%d/%d\n\n这些设置用于降低强反馈带来的视觉干扰，也方便后续替换正式音效、BGM 和动效资源。" % [
		_on_off_text(_setting_enabled("audio_enabled", true)),
		_settings_volume_percent(),
		_on_off_text(_setting_enabled("music_enabled", true)),
		_settings_music_volume_percent(),
		_on_off_text(_setting_enabled("screen_shake_enabled", true)),
		_on_off_text(_setting_enabled("hit_stop_enabled", true)),
		_on_off_text(_setting_enabled("floating_text_enabled", true)),
		_on_off_text(_setting_enabled("tutorial_enabled", true)),
		_tutorial_completed_steps().size(),
		TUTORIAL_STEP_ORDER.size()
	]
	return last_settings_summary

func _on_off_text(enabled: bool) -> String:
	return "开启" if enabled else "关闭"

func _settings_volume_percent() -> int:
	return int(round(_setting_float("master_volume", 1.0) * 100.0))

func _settings_music_volume_percent() -> int:
	return int(round(_setting_float("music_volume", 0.65) * 100.0))

func _refresh_profile_view() -> void:
	last_profile_panel_visible = true
	last_profile_button_count = 0
	_refresh_achievement_unlocks("profile_view")
	_set_page_regions(false, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(148.0, 224.0)
	run_label.text = "局外档案 | 成就 %d/%d" % [last_profile_unlocked_count, last_profile_total_count]
	status_label.text = "查看跨跑团统计、角色通关记录和成就解锁。档案独立保存，不会被单局读档覆盖。"
	status_label.tooltip_text = status_label.text
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	log_label.text = _profile_summary_text()

	_add_profile_button("返回\n回到当前页面", "primary", Callable(self, "_on_close_profile_pressed"))
	for achievement in achievement_data.get("achievements", []):
		var achievement_dict: Dictionary = achievement
		var achievement_id: String = str(achievement_dict.get("id", ""))
		if achievement_id.is_empty():
			continue
		var unlocked: bool = _profile_unlocked_achievements().has(achievement_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(_profile_achievement_card_width(), 104)
		button.text = _achievement_button_text(achievement_dict, unlocked)
		button.tooltip_text = "%s\n%s\n%s" % [
			str(achievement_dict.get("name", achievement_id)),
			str(achievement_dict.get("description", "")),
			str(achievement_dict.get("design_note", ""))
		]
		_apply_button_skin(button, "success" if unlocked else "neutral")
		button.disabled = true
		reward_row.add_child(button)
		last_profile_button_count += 1
	_record_layout_metrics()

func _add_profile_button(text: String, skin: String, pressed_callable: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(_profile_achievement_card_width(), 96)
	button.text = text
	_apply_button_skin(button, skin)
	button.pressed.connect(pressed_callable)
	reward_row.add_child(button)
	last_profile_button_count += 1

func _profile_achievement_card_width() -> float:
	return _bounded_width(174.0, 146.0, 188.0)

func _achievement_button_text(achievement: Dictionary, unlocked: bool) -> String:
	var state_text := "已解锁" if unlocked else "未解锁"
	return "%s\n%s\n%s" % [
		str(achievement.get("name", achievement.get("id", "成就"))),
		state_text,
		str(achievement.get("description", ""))
	]

func _profile_summary_text() -> String:
	var stats: Dictionary = _profile_stats()
	var completed_chapter_names: Array[String] = []
	for chapter_id in player_profile.get("completed_chapters", []):
		completed_chapter_names.append(_chapter_display_name(str(chapter_id)))
	var character_names: Array[String] = []
	for character_id in player_profile.get("character_completions", []):
		character_names.append(_character_display_name(str(character_id)))
	var last_unlock_names: Array[String] = []
	for achievement_id in player_profile.get("last_unlock_ids", []):
		var achievement: Dictionary = _achievement_by_id(str(achievement_id))
		if not achievement.is_empty():
			last_unlock_names.append(str(achievement.get("name", achievement_id)))
	last_profile_last_unlock_text = "、".join(last_unlock_names)
	last_profile_summary = "档案统计\n跑团开始：%d\n完整通关：%d\n击败 Boss：%d\n商店删卡：%d\n最高金币：%d\n最大牌组：%d\n最高完成挑战：%d\n最高解锁挑战：%d\n\n完成章节：%s\n角色通关：%s\n最近解锁：%s" % [
		int(stats.get("runs_started", 0)),
		int(stats.get("runs_completed", 0)),
		int(stats.get("bosses_defeated", 0)),
		int(stats.get("cards_removed", 0)),
		int(stats.get("best_gold", 0)),
		int(stats.get("highest_deck_size", 0)),
		int(stats.get("best_challenge_level_completed", 0)),
		_max_unlocked_challenge_level(),
		"、".join(completed_chapter_names) if not completed_chapter_names.is_empty() else "无",
		"、".join(character_names) if not character_names.is_empty() else "无",
		last_profile_last_unlock_text if not last_profile_last_unlock_text.is_empty() else "无"
	]
	return last_profile_summary

func _refresh_tutorial_view() -> void:
	last_tutorial_page_visible = true
	last_tutorial_button_count = 0
	last_tutorial_completed_count = _tutorial_completed_steps().size()
	_set_page_regions(false, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(152.0, 224.0)
	run_label.text = "新手引导 | 当前进度 %d/%d" % [last_tutorial_completed_count, TUTORIAL_STEP_ORDER.size()]
	status_label.text = "按当前游戏阶段显示关键提示。完成的提示会自动隐藏，可在设置中重置。"
	status_label.tooltip_text = status_label.text
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	log_label.text = _tutorial_summary_text()

	if not last_tutorial_step_id.is_empty() and _setting_enabled("tutorial_enabled", true):
		_add_tutorial_action_button("完成当前提示\n%s" % last_tutorial_title, "success", Callable(self, "_on_tutorial_complete_current_pressed"))
	_add_tutorial_action_button("引导\n%s" % _on_off_text(_setting_enabled("tutorial_enabled", true)), "event", Callable(self, "_on_settings_toggle_tutorial"))
	_add_tutorial_action_button("重置引导\n重新显示全部提示", "neutral", Callable(self, "_on_settings_reset_tutorial_pressed"))
	_add_tutorial_action_button("返回\n回到当前页面", "primary", Callable(self, "_on_close_tutorial_pressed"))
	_record_layout_metrics()

func _add_tutorial_action_button(text: String, skin: String, pressed_callable: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(170, 92)
	button.text = text
	_apply_button_skin(button, skin)
	button.pressed.connect(pressed_callable)
	reward_row.add_child(button)
	last_tutorial_button_count += 1

func _tutorial_summary_text() -> String:
	var completed_steps: Array = _tutorial_completed_steps()
	var lines: Array[String] = ["引导目录"]
	for step_id_value in TUTORIAL_STEP_ORDER:
		var step_id: String = str(step_id_value)
		var data: Dictionary = _tutorial_step_data(step_id)
		var marker: String = "已完成" if completed_steps.has(step_id) else "待提示"
		lines.append("%s：%s\n%s" % [
			marker,
			str(data.get("title", step_id)),
			str(data.get("body", ""))
		])
	last_tutorial_summary = "\n\n".join(lines)
	return last_tutorial_summary

func _refresh_compendium_view() -> void:
	last_compendium_panel_visible = true
	last_compendium_tab_button_count = 0
	last_compendium_filter_button_count = 0
	last_compendium_sort_button_count = 0
	last_compendium_search_control_count = 0
	last_compendium_item_count = 0
	last_compendium_locked_item_count = 0
	last_compendium_item_titles.clear()
	last_compendium_item_subtitles.clear()
	last_compendium_item_bodies.clear()
	last_compendium_item_tooltips.clear()
	selected_compendium_tab = _valid_compendium_tab(selected_compendium_tab)
	selected_compendium_filter = _valid_compendium_filter(selected_compendium_tab, selected_compendium_filter)
	selected_compendium_sort = _valid_compendium_sort(selected_compendium_tab, selected_compendium_sort)
	selected_compendium_search = _sanitize_compendium_search(selected_compendium_search)
	last_compendium_reveal_all_details = compendium_reveal_all_details
	last_compendium_tab = selected_compendium_tab
	last_compendium_filter = selected_compendium_filter
	last_compendium_sort = selected_compendium_sort
	last_compendium_search = selected_compendium_search
	last_compendium_total_count = _compendium_tab_count(selected_compendium_tab)
	_set_page_regions(false, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(144.0, 236.0)
	run_label.text = "数据图鉴 | %s" % _compendium_tab_title(selected_compendium_tab)
	status_label.text = "查看当前版本已配置的卡牌、遗物、药水、敌人、事件和挑战等级。"
	status_label.tooltip_text = status_label.text
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	log_label.text = _compendium_summary_text(selected_compendium_tab)

	_add_compendium_action_button("返回\n回到当前页面", "primary", Callable(self, "_on_close_compendium_pressed"), "关闭图鉴并回到当前页面。")
	_add_compendium_action_button(_compendium_reveal_button_text(), "event" if compendium_reveal_all_details else "neutral", Callable(self, "_on_compendium_reveal_toggle_pressed"), _compendium_reveal_button_tooltip())
	for tab_id in COMPENDIUM_TAB_ORDER:
		_add_compendium_tab_button(str(tab_id))
	_add_compendium_search_controls()
	_add_compendium_filter_buttons()
	_add_compendium_sort_buttons()
	match selected_compendium_tab:
		"cards":
			_add_compendium_card_entries()
		"relics":
			_add_compendium_relic_entries()
		"potions":
			_add_compendium_potion_entries()
		"enemies":
			_add_compendium_enemy_entries()
		"events":
			_add_compendium_event_entries()
		"challenges":
			_add_compendium_challenge_entries()
	_record_layout_metrics()

func _add_compendium_action_button(text: String, skin: String, pressed_callable: Callable, tooltip_text: String = "") -> void:
	var button := Button.new()
	button.custom_minimum_size = _compendium_tab_button_size()
	button.text = text
	button.tooltip_text = tooltip_text
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_apply_button_skin(button, skin)
	button.pressed.connect(pressed_callable)
	reward_row.add_child(button)
	last_compendium_tab_button_count += 1

func _add_compendium_tab_button(tab_id: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = _compendium_tab_button_size()
	button.text = "%s\n%d 项" % [_compendium_tab_title(tab_id), _compendium_tab_count(tab_id)]
	button.tooltip_text = _compendium_tab_tooltip(tab_id)
	_apply_button_skin(button, "relic" if tab_id == selected_compendium_tab else "neutral")
	button.disabled = tab_id == selected_compendium_tab
	button.pressed.connect(_on_compendium_tab_pressed.bind(tab_id))
	reward_row.add_child(button)
	last_compendium_tab_button_count += 1

func _add_compendium_search_controls() -> void:
	var search := LineEdit.new()
	search.custom_minimum_size = _compendium_search_field_size()
	search.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	search.placeholder_text = "搜索"
	search.text = selected_compendium_search
	search.max_length = 32
	search.tooltip_text = "按名称、说明、注释或选项搜索当前图鉴分类。"
	search.clear_button_enabled = true
	search.text_changed.connect(_on_compendium_search_changed)
	_apply_line_edit_skin(search)
	reward_row.add_child(search)
	last_compendium_search_control_count += 1

	var clear_button := Button.new()
	clear_button.custom_minimum_size = _compendium_control_button_size()
	clear_button.text = "清空\n搜索"
	clear_button.tooltip_text = "清空当前图鉴搜索词。"
	clear_button.clip_text = true
	clear_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_apply_button_skin(clear_button, "neutral")
	clear_button.disabled = selected_compendium_search.is_empty()
	clear_button.pressed.connect(_on_compendium_search_clear_pressed)
	reward_row.add_child(clear_button)
	last_compendium_search_control_count += 1

func _add_compendium_filter_buttons() -> void:
	for option in _compendium_filter_options(selected_compendium_tab):
		var option_dict: Dictionary = option
		var filter_id: String = str(option_dict.get("id", "all"))
		var button := Button.new()
		button.custom_minimum_size = _compendium_control_button_size()
		button.text = "筛选\n%s" % str(option_dict.get("label", filter_id))
		button.tooltip_text = str(option_dict.get("tooltip", "按当前条件筛选图鉴条目。"))
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_apply_button_skin(button, "relic" if filter_id == selected_compendium_filter else str(option_dict.get("skin", "neutral")))
		button.disabled = filter_id == selected_compendium_filter
		button.pressed.connect(_on_compendium_filter_pressed.bind(filter_id))
		reward_row.add_child(button)
		last_compendium_filter_button_count += 1

func _add_compendium_sort_buttons() -> void:
	for option in _compendium_sort_options(selected_compendium_tab):
		var option_dict: Dictionary = option
		var sort_id: String = str(option_dict.get("id", "name"))
		var button := Button.new()
		button.custom_minimum_size = _compendium_control_button_size()
		button.text = "排序\n%s" % str(option_dict.get("label", sort_id))
		button.tooltip_text = str(option_dict.get("tooltip", "按当前字段排序图鉴条目。"))
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_apply_button_skin(button, "potion" if sort_id == selected_compendium_sort else str(option_dict.get("skin", "neutral")))
		button.disabled = sort_id == selected_compendium_sort
		button.pressed.connect(_on_compendium_sort_pressed.bind(sort_id))
		reward_row.add_child(button)
		last_compendium_sort_button_count += 1

func _add_compendium_card_entries() -> void:
	for card in _filtered_sorted_compendium_items("cards"):
		var card_dict: Dictionary = card
		var title: String = "%s [%d]" % [str(card_dict.get("name", "卡牌")), int(card_dict.get("cost", 0))]
		var subtitle: String = "%s | %s | %s | %s" % [
			_compendium_discovery_text("cards", card_dict),
			_card_type_display_name(str(card_dict.get("type", ""))),
			_rarity_display_name(str(card_dict.get("rarity", ""))),
			_target_display_name(str(card_dict.get("target", "")))
		]
		var body: String = str(card_dict.get("description", ""))
		var tooltip: String = "%s\n%s\n\n设计：%s\n平衡：%s\n升级：%s" % [
			title,
			body,
			str(card_dict.get("design_note", "")),
			str(card_dict.get("balance_note", "")),
			str(card_dict.get("upgrade_note", ""))
		]
		_add_compendium_entry("cards", card_dict, title, subtitle, body, tooltip, _load_texture(_card_art_path(card_dict)), str(card_dict.get("type", "skill")))

func _add_compendium_relic_entries() -> void:
	for relic in _filtered_sorted_compendium_items("relics"):
		var relic_dict: Dictionary = relic
		var title: String = str(relic_dict.get("name", "遗物"))
		var subtitle: String = "%s | %s | %s" % [
			_compendium_discovery_text("relics", relic_dict),
			_rarity_display_name(str(relic_dict.get("rarity", ""))),
			_character_scope_text(relic_dict)
		]
		var body: String = str(relic_dict.get("description", ""))
		var tooltip: String = "%s\n%s\n\n设计：%s\n平衡：%s\n实现：%s" % [
			title,
			body,
			str(relic_dict.get("design_note", "")),
			str(relic_dict.get("balance_note", "")),
			str(relic_dict.get("implementation_note", ""))
		]
		_add_compendium_entry("relics", relic_dict, title, subtitle, body, tooltip, _load_texture(_relic_icon_path(relic_dict)), "relic")

func _add_compendium_potion_entries() -> void:
	for potion in _filtered_sorted_compendium_items("potions"):
		var potion_dict: Dictionary = potion
		var title: String = str(potion_dict.get("name", "药水"))
		var subtitle: String = "%s | %s | %s" % [
			_compendium_discovery_text("potions", potion_dict),
			_rarity_display_name(str(potion_dict.get("rarity", ""))),
			_target_display_name(str(potion_dict.get("target", "")))
		]
		var body: String = str(potion_dict.get("description", ""))
		var tooltip: String = "%s\n%s\n\n设计：%s\n平衡：%s\n实现：%s" % [
			title,
			body,
			str(potion_dict.get("design_note", "")),
			str(potion_dict.get("balance_note", "")),
			str(potion_dict.get("implementation_note", ""))
		]
		_add_compendium_entry("potions", potion_dict, title, subtitle, body, tooltip, _load_texture(_potion_icon_path(potion_dict)), "potion")

func _add_compendium_enemy_entries() -> void:
	for enemy in _filtered_sorted_compendium_items("enemies"):
		var enemy_dict: Dictionary = enemy
		var title: String = str(enemy_dict.get("name", "敌人"))
		var subtitle: String = "%s | %s | %dHP | %d 行动" % [
			_compendium_discovery_text("enemies", enemy_dict),
			_enemy_tier_display_name(str(enemy_dict.get("tier", "normal"))),
			int(enemy_dict.get("max_hp", 0)),
			enemy_dict.get("actions", []).size()
		]
		var body: String = _enemy_actions_summary(enemy_dict)
		var tooltip: String = "%s\n%s\n\n设计：%s\n平衡：%s\n意图：%s" % [
			title,
			body,
			str(enemy_dict.get("design_note", "")),
			str(enemy_dict.get("balance_note", "")),
			str(enemy_dict.get("intent_note", ""))
		]
		_add_compendium_entry("enemies", enemy_dict, title, subtitle, body, tooltip, _enemy_texture({"data": enemy_dict}), "enemy")

func _add_compendium_event_entries() -> void:
	for event in _filtered_sorted_compendium_items("events"):
		var event_dict: Dictionary = event
		var title: String = str(event_dict.get("name", "事件"))
		var subtitle: String = "%s | %s | %d 选择" % [
			_compendium_discovery_text("events", event_dict),
			_character_scope_text(event_dict),
			event_dict.get("choices", []).size()
		]
		var body: String = str(event_dict.get("body", ""))
		var tooltip: String = "%s\n%s\n\n选择：%s\n\n设计：%s\n平衡：%s" % [
			title,
			body,
			_event_choices_summary(event_dict),
			str(event_dict.get("design_note", "")),
			str(event_dict.get("balance_note", ""))
		]
		_add_compendium_entry("events", event_dict, title, subtitle, body, tooltip, _load_texture(EVENT_ART_PATH), "event")

func _add_compendium_challenge_entries() -> void:
	for challenge in _filtered_sorted_compendium_items("challenges"):
		var challenge_dict: Dictionary = challenge
		var level: int = int(challenge_dict.get("level", 0))
		var title: String = str(challenge_dict.get("name", "挑战"))
		var subtitle: String = "%s | 等级 %d | %s" % [_compendium_discovery_text("challenges", challenge_dict), level, str(challenge_dict.get("short_name", ""))]
		var body: String = _challenge_modifier_summary(level)
		var tooltip: String = "%s\n%s\n%s\n\n奖励：%s\n设计：%s\n平衡：%s" % [
			title,
			str(challenge_dict.get("description", "")),
			body,
			str(challenge_dict.get("reward_note", "")),
			str(challenge_dict.get("design_note", "")),
			str(challenge_dict.get("balance_note", ""))
		]
		_add_compendium_entry("challenges", challenge_dict, title, subtitle, body, tooltip, null, "event")

func _add_compendium_entry(tab_id: String, item: Dictionary, title: String, subtitle: String, body: String, tooltip: String, texture: Texture2D, skin: String) -> void:
	if _compendium_item_revealed(tab_id, item):
		_add_compendium_item_card(title, subtitle, body, tooltip, texture, skin)
		return
	_add_compendium_item_card(
		_compendium_locked_title(tab_id),
		_compendium_locked_subtitle(tab_id),
		_compendium_locked_body(tab_id),
		_compendium_locked_tooltip(tab_id),
		null,
		"neutral",
		true
	)

func _add_compendium_item_card(title: String, subtitle: String, body: String, tooltip: String, texture: Texture2D, skin: String, locked: bool = false) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_compendium_card_width(), _compendium_card_height())
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.clip_contents = true
	panel.tooltip_text = tooltip
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var palette: Dictionary = _button_skin_palette(skin)
	panel.add_theme_stylebox_override("panel", _button_style(
		palette.get("bg", Color(0.16, 0.17, 0.18)),
		palette.get("border", Color(0.46, 0.50, 0.52)),
		1,
		6
	))
	reward_row.add_child(panel)

	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 7)
	root.add_theme_constant_override("margin_right", 7)
	root.add_theme_constant_override("margin_top", 6)
	root.add_theme_constant_override("margin_bottom", 6)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(root)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 7)
	root.add_child(row)

	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(58, 0)
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_theme_stylebox_override("panel", _button_style(Color(0.08, 0.09, 0.10, 0.74), Color(0.38, 0.40, 0.42), 1, 5))
	row.add_child(art_frame)

	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_frame.add_child(art)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	_add_compendium_label(text_box, title, 13, Color(0.98, 0.95, 0.86), false)
	_add_compendium_label(text_box, subtitle, 10, palette.get("border", Color(0.72, 0.76, 0.74)).lightened(0.16), false)
	_add_compendium_label(text_box, body, 10, Color(0.82, 0.86, 0.84), true)
	last_compendium_item_count += 1
	if locked:
		last_compendium_locked_item_count += 1
	last_compendium_item_titles.append(title)
	last_compendium_item_subtitles.append(subtitle)
	last_compendium_item_bodies.append(body)
	last_compendium_item_tooltips.append(tooltip)

func _add_compendium_label(parent: Control, text: String, font_size: int, color: Color, wrap: bool) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)

func _compendium_summary_text(tab_id: String) -> String:
	var lines: Array[String] = ["图鉴：%s" % _compendium_tab_title(tab_id)]
	var total_count: int = _compendium_tab_count(tab_id)
	var filtered_count: int = _filtered_compendium_items(tab_id).size()
	last_compendium_discovered_count = _compendium_discovered_count(tab_id)
	last_compendium_undiscovered_count = max(0, total_count - last_compendium_discovered_count)
	lines.append("显示：%d/%d | 筛选：%s | 排序：%s" % [
		filtered_count,
		total_count,
		_compendium_filter_label(tab_id, selected_compendium_filter),
		_compendium_sort_label(tab_id, selected_compendium_sort)
	])
	lines.append("发现：%d/%d | 未见：%d" % [
		last_compendium_discovered_count,
		total_count,
		last_compendium_undiscovered_count
	])
	lines.append("详情：%s" % ("全显" if compendium_reveal_all_details else "隐藏未见"))
	if not selected_compendium_search.is_empty():
		lines.append("搜索：%s" % selected_compendium_search)
	match tab_id:
		"cards":
			lines.append("卡牌总数：%d" % card_data.get("cards", []).size())
			lines.append("攻击 %d | 技能 %d | 能力 %d | 状态/诅咒 %d" % [
				_count_items_by_field(card_data.get("cards", []), "type", "attack"),
				_count_items_by_field(card_data.get("cards", []), "type", "skill"),
				_count_items_by_field(card_data.get("cards", []), "type", "power"),
				_count_items_by_field(card_data.get("cards", []), "type", "status") + _count_items_by_field(card_data.get("cards", []), "type", "curse")
			])
		"relics":
			lines.append("遗物总数：%d" % relic_data.get("relics", []).size())
			lines.append("普通 %d | 罕见 %d | 稀有 %d | 初始 %d" % [
				_count_items_by_field(relic_data.get("relics", []), "rarity", "common"),
				_count_items_by_field(relic_data.get("relics", []), "rarity", "uncommon"),
				_count_items_by_field(relic_data.get("relics", []), "rarity", "rare"),
				_count_items_by_field(relic_data.get("relics", []), "rarity", "starter")
			])
		"potions":
			lines.append("药水总数：%d" % potion_data.get("potions", []).size())
			lines.append("药水是一次性战斗资源，使用后不会进入牌堆。")
		"enemies":
			lines.append("敌人总数：%d" % enemy_data.get("enemies", []).size())
			lines.append("普通 %d | 精英 %d | Boss %d" % [
				_count_items_by_field(enemy_data.get("enemies", []), "tier", "normal"),
				_count_items_by_field(enemy_data.get("enemies", []), "tier", "elite"),
				_count_items_by_field(enemy_data.get("enemies", []), "tier", "boss")
			])
		"events":
			lines.append("事件总数：%d" % event_data.get("events", []).size())
			lines.append("通用 %d | 角色专属 %d | 一次性 %d" % [
				_count_compendium_shared_items(event_data.get("events", [])),
				_count_compendium_exclusive_items(event_data.get("events", [])),
				_count_bool_items_by_field(event_data.get("events", []), "one_time", true)
			])
		"challenges":
			lines.append("挑战等级：%d" % challenge_data.get("levels", []).size())
			lines.append(str(challenge_data.get("unlock_rule", {}).get("description", "")))
	lines.append("悬停条目可查看设计、平衡和实现注释。")
	last_compendium_summary = "\n".join(lines)
	return last_compendium_summary

func _compendium_tab_button_size() -> Vector2:
	return Vector2(_bounded_width(118.0, 88.0, 128.0), clamp(round(62.0 * _page_layout_scale()), 52.0, 66.0))

func _compendium_control_button_size() -> Vector2:
	return Vector2(_bounded_width(94.0, 78.0, 112.0), clamp(round(54.0 * _page_layout_scale()), 48.0, 60.0))

func _compendium_search_field_size() -> Vector2:
	return Vector2(_bounded_width(198.0, 142.0, 226.0), clamp(round(54.0 * _page_layout_scale()), 48.0, 60.0))

func _compendium_reveal_button_text() -> String:
	return "详情\n全显" if compendium_reveal_all_details else "详情\n隐藏"

func _compendium_reveal_button_tooltip() -> String:
	return "当前显示所有图鉴详情，用于平衡检查；点击后隐藏未见详情。" if compendium_reveal_all_details else "当前隐藏未见条目的名称、说明和注释；点击后显示全部详情。"

func _compendium_card_width() -> float:
	var available_width: float = _scroll_content_width()
	var gap := 6.0
	var columns := 1
	if available_width >= 980.0:
		columns = 4
	elif available_width >= 720.0:
		columns = 3
	elif available_width >= 470.0:
		columns = 2
	var width: float = floor((available_width - gap * float(columns - 1)) / float(columns))
	last_compendium_card_width = _bounded_width(width, 220.0, 330.0)
	return last_compendium_card_width

func _compendium_card_height() -> float:
	return clamp(round(116.0 * _page_layout_scale()), 96.0, 120.0)

func _valid_compendium_tab(tab_id: String) -> String:
	return tab_id if COMPENDIUM_TAB_ORDER.has(tab_id) else "cards"

func _valid_compendium_filter(tab_id: String, filter_id: String) -> String:
	for option in _compendium_filter_options(tab_id):
		var option_dict: Dictionary = option
		if str(option_dict.get("id", "")) == filter_id:
			return filter_id
	return "all"

func _valid_compendium_sort(tab_id: String, sort_id: String) -> String:
	for option in _compendium_sort_options(tab_id):
		var option_dict: Dictionary = option
		if str(option_dict.get("id", "")) == sort_id:
			return sort_id
	return _default_compendium_sort(tab_id)

func _default_compendium_sort(tab_id: String) -> String:
	return "level" if tab_id == "challenges" else "name"

func _compendium_tab_title(tab_id: String) -> String:
	match tab_id:
		"cards":
			return "卡牌"
		"relics":
			return "遗物"
		"potions":
			return "药水"
		"enemies":
			return "敌人"
		"events":
			return "事件"
		"challenges":
			return "挑战"
		_:
			return "图鉴"

func _compendium_tab_count(tab_id: String) -> int:
	match tab_id:
		"cards":
			return card_data.get("cards", []).size()
		"relics":
			return relic_data.get("relics", []).size()
		"potions":
			return potion_data.get("potions", []).size()
		"enemies":
			return enemy_data.get("enemies", []).size()
		"events":
			return event_data.get("events", []).size()
		"challenges":
			return challenge_data.get("levels", []).size()
		_:
			return 0

func _compendium_tab_tooltip(tab_id: String) -> String:
	match tab_id:
		"cards":
			return "查看所有卡牌的费用、类型、稀有度和设计注释。"
		"relics":
			return "查看所有遗物的稀有度、角色限制和实现状态。"
		"potions":
			return "查看所有药水的目标、稀有度和一次性效果。"
		"enemies":
			return "查看所有敌人的生命、阶级和行动节奏。"
		"events":
			return "查看所有问号事件的选择、角色范围和设计注释。"
		"challenges":
			return "查看挑战等级修正、解锁规则和设计意图。"
		_:
			return "图鉴分类"

func _compendium_filter_options(tab_id: String) -> Array:
	match tab_id:
		"cards":
			var card_options: Array = [
				{"id": "all", "label": "全部", "skin": "neutral", "tooltip": "显示全部卡牌。"},
				{"id": "discovered", "label": "已见", "skin": "success", "tooltip": "只显示已经遇到或获得过的卡牌。"},
				{"id": "undiscovered", "label": "未见", "skin": "neutral", "tooltip": "只显示尚未遇到或获得过的卡牌。"},
				{"id": "attack", "label": "攻击", "skin": "attack", "tooltip": "只显示攻击牌。"},
				{"id": "skill", "label": "技能", "skin": "skill", "tooltip": "只显示技能牌。"},
				{"id": "power", "label": "能力", "skin": "power", "tooltip": "只显示能力牌。"},
				{"id": "starter", "label": "初始", "skin": "neutral", "tooltip": "只显示起始牌。"},
				{"id": "common", "label": "普通", "skin": "neutral", "tooltip": "只显示普通稀有度卡牌。"},
				{"id": "uncommon", "label": "罕见", "skin": "event", "tooltip": "只显示罕见卡牌。"},
				{"id": "rare", "label": "稀有", "skin": "relic", "tooltip": "只显示稀有卡牌。"},
				{"id": "special", "label": "状态", "skin": "danger", "tooltip": "只显示状态牌和诅咒牌。"},
				{"id": "shared", "label": "通用", "skin": "neutral", "tooltip": "只显示无角色限制的卡牌。"},
				{"id": "exclusive", "label": "专属", "skin": "event", "tooltip": "只显示角色专属卡牌。"}
			]
			card_options.append_array(_compendium_character_filter_options("卡牌"))
			return card_options
		"relics":
			var relic_options: Array = [
				{"id": "all", "label": "全部", "skin": "neutral", "tooltip": "显示全部遗物。"},
				{"id": "discovered", "label": "已见", "skin": "success", "tooltip": "只显示已经获得或见过的遗物。"},
				{"id": "undiscovered", "label": "未见", "skin": "neutral", "tooltip": "只显示尚未获得或见过的遗物。"},
				{"id": "starter", "label": "初始", "skin": "neutral", "tooltip": "只显示起始遗物。"},
				{"id": "common", "label": "普通", "skin": "neutral", "tooltip": "只显示普通遗物。"},
				{"id": "uncommon", "label": "罕见", "skin": "event", "tooltip": "只显示罕见遗物。"},
				{"id": "rare", "label": "稀有", "skin": "relic", "tooltip": "只显示稀有遗物。"},
				{"id": "shared", "label": "通用", "skin": "neutral", "tooltip": "只显示通用遗物。"},
				{"id": "exclusive", "label": "专属", "skin": "event", "tooltip": "只显示角色专属遗物。"}
			]
			relic_options.append_array(_compendium_character_filter_options("遗物"))
			return relic_options
		"potions":
			return [
				{"id": "all", "label": "全部", "skin": "neutral", "tooltip": "显示全部药水。"},
				{"id": "discovered", "label": "已见", "skin": "success", "tooltip": "只显示已经获得或见过的药水。"},
				{"id": "undiscovered", "label": "未见", "skin": "neutral", "tooltip": "只显示尚未获得或见过的药水。"},
				{"id": "common", "label": "普通", "skin": "neutral", "tooltip": "只显示普通药水。"},
				{"id": "uncommon", "label": "罕见", "skin": "event", "tooltip": "只显示罕见药水。"},
				{"id": "rare", "label": "稀有", "skin": "relic", "tooltip": "只显示稀有药水。"},
				{"id": "self", "label": "自身", "skin": "potion", "tooltip": "只显示以玩家为目标的药水。"},
				{"id": "enemy", "label": "单体", "skin": "attack", "tooltip": "只显示单体敌人药水。"},
				{"id": "all_enemies", "label": "全体", "skin": "danger", "tooltip": "只显示全体敌人药水。"}
			]
		"enemies":
			return [
				{"id": "all", "label": "全部", "skin": "neutral", "tooltip": "显示全部敌人。"},
				{"id": "discovered", "label": "已见", "skin": "success", "tooltip": "只显示已经遭遇过的敌人。"},
				{"id": "undiscovered", "label": "未见", "skin": "neutral", "tooltip": "只显示尚未遭遇过的敌人。"},
				{"id": "normal", "label": "普通", "skin": "neutral", "tooltip": "只显示普通敌人。"},
				{"id": "elite", "label": "精英", "skin": "event", "tooltip": "只显示精英敌人。"},
				{"id": "boss", "label": "Boss", "skin": "danger", "tooltip": "只显示 Boss。"}
			]
		"events":
			var event_options: Array = [
				{"id": "all", "label": "全部", "skin": "neutral", "tooltip": "显示全部事件。"},
				{"id": "discovered", "label": "已见", "skin": "success", "tooltip": "只显示已经进入过的事件。"},
				{"id": "undiscovered", "label": "未见", "skin": "neutral", "tooltip": "只显示尚未进入过的事件。"},
				{"id": "shared", "label": "通用", "skin": "neutral", "tooltip": "只显示通用事件。"},
				{"id": "exclusive", "label": "专属", "skin": "event", "tooltip": "只显示角色专属事件。"},
				{"id": "one_time", "label": "一次", "skin": "relic", "tooltip": "只显示一次性事件。"}
			]
			event_options.append_array(_compendium_character_filter_options("事件"))
			return event_options
		"challenges":
			return [
				{"id": "all", "label": "全部", "skin": "neutral", "tooltip": "显示全部挑战等级。"},
				{"id": "discovered", "label": "已见", "skin": "success", "tooltip": "只显示已经选择过的挑战等级。"},
				{"id": "undiscovered", "label": "未见", "skin": "neutral", "tooltip": "只显示尚未选择过的挑战等级。"},
				{"id": "base", "label": "普通", "skin": "neutral", "tooltip": "只显示普通模式。"},
				{"id": "challenge", "label": "挑战", "skin": "event", "tooltip": "只显示挑战等级。"},
				{"id": "enemy_hp", "label": "敌血", "skin": "relic", "tooltip": "只显示提高敌人生命的挑战。"},
				{"id": "enemy_damage", "label": "敌伤", "skin": "danger", "tooltip": "只显示提高敌人伤害的挑战。"},
				{"id": "hp_loss", "label": "扣血", "skin": "attack", "tooltip": "只显示开局扣血挑战。"}
			]
		_:
			return [{"id": "all", "label": "全部", "skin": "neutral"}]

func _compendium_sort_options(tab_id: String) -> Array:
	match tab_id:
		"cards":
			return [
				{"id": "name", "label": "名称", "skin": "neutral", "tooltip": "按卡名排序。"},
				{"id": "cost", "label": "费用", "skin": "potion", "tooltip": "按费用从低到高排序。"},
				{"id": "rarity", "label": "稀有", "skin": "relic", "tooltip": "按稀有度排序。"},
				{"id": "type", "label": "类型", "skin": "event", "tooltip": "按卡牌类型排序。"}
			]
		"relics":
			return [
				{"id": "name", "label": "名称", "skin": "neutral", "tooltip": "按遗物名称排序。"},
				{"id": "rarity", "label": "稀有", "skin": "relic", "tooltip": "按稀有度排序。"},
				{"id": "scope", "label": "角色", "skin": "event", "tooltip": "按通用/专属排序。"}
			]
		"potions":
			return [
				{"id": "name", "label": "名称", "skin": "neutral", "tooltip": "按药水名称排序。"},
				{"id": "rarity", "label": "稀有", "skin": "relic", "tooltip": "按稀有度排序。"},
				{"id": "target", "label": "目标", "skin": "potion", "tooltip": "按目标类型排序。"}
			]
		"enemies":
			return [
				{"id": "name", "label": "名称", "skin": "neutral", "tooltip": "按敌人名称排序。"},
				{"id": "tier", "label": "阶级", "skin": "event", "tooltip": "按普通、精英和 Boss 排序。"},
				{"id": "hp", "label": "生命", "skin": "danger", "tooltip": "按最大生命从低到高排序。"}
			]
		"events":
			return [
				{"id": "name", "label": "名称", "skin": "neutral", "tooltip": "按事件名称排序。"},
				{"id": "scope", "label": "角色", "skin": "event", "tooltip": "按通用/专属排序。"},
				{"id": "choices", "label": "选择", "skin": "potion", "tooltip": "按选择数量排序。"}
			]
		"challenges":
			return [
				{"id": "level", "label": "等级", "skin": "neutral", "tooltip": "按挑战等级排序。"},
				{"id": "enemy_hp", "label": "敌血", "skin": "relic", "tooltip": "按敌人生命倍率排序。"},
				{"id": "enemy_damage", "label": "敌伤", "skin": "danger", "tooltip": "按敌人伤害倍率排序。"},
				{"id": "hp_loss", "label": "扣血", "skin": "attack", "tooltip": "按玩家开局扣血排序。"}
			]
		_:
			return [{"id": "name", "label": "名称", "skin": "neutral"}]

func _compendium_character_filter_options(content_label: String) -> Array:
	var options: Array = []
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		var character_id: String = str(character_dict.get("id", ""))
		if character_id.is_empty():
			continue
		var character_name: String = _character_display_name(character_id)
		options.append({
			"id": _compendium_character_filter_id(character_id),
			"label": _compendium_character_short_label(character_id),
			"skin": "event",
			"tooltip": "显示 %s 可用的%s，包含通用和专属内容。" % [character_name, content_label]
		})
	return options

func _compendium_character_filter_id(character_id: String) -> String:
	return "character:%s" % character_id

func _compendium_is_character_filter(filter_id: String) -> bool:
	return filter_id.begins_with("character:")

func _compendium_character_id_from_filter(filter_id: String) -> String:
	return filter_id.replace("character:", "")

func _compendium_character_short_label(character_id: String) -> String:
	match character_id:
		"ember_exile":
			return "余烬"
		"arc_tinker":
			return "电弧"
		"pyre_ascetic":
			return "熔痕"
		_:
			var display_name: String = _character_display_name(character_id)
			return display_name.substr(0, min(2, display_name.length()))

func _compendium_filter_label(tab_id: String, filter_id: String) -> String:
	return _compendium_option_label(_compendium_filter_options(tab_id), filter_id)

func _compendium_sort_label(tab_id: String, sort_id: String) -> String:
	return _compendium_option_label(_compendium_sort_options(tab_id), sort_id)

func _compendium_option_label(options: Array, option_id: String) -> String:
	for option in options:
		var option_dict: Dictionary = option
		if str(option_dict.get("id", "")) == option_id:
			return str(option_dict.get("label", option_id))
	return option_id

func _filtered_sorted_compendium_items(tab_id: String) -> Array:
	var items: Array = _filtered_compendium_items(tab_id)
	for index in range(items.size()):
		var best_index := index
		for candidate_index in range(index + 1, items.size()):
			var candidate: Dictionary = items[candidate_index]
			var best: Dictionary = items[best_index]
			if _compendium_item_less(tab_id, selected_compendium_sort, candidate, best):
				best_index = candidate_index
		if best_index != index:
			var current = items[index]
			items[index] = items[best_index]
			items[best_index] = current
	return items

func _filtered_compendium_items(tab_id: String) -> Array:
	var filtered: Array = []
	for item in _compendium_source_items(tab_id):
		var item_dict: Dictionary = item
		if _compendium_item_matches_filter(tab_id, item_dict, selected_compendium_filter) and _compendium_item_matches_search(tab_id, item_dict, selected_compendium_search):
			filtered.append(item_dict)
	return filtered

func _compendium_source_items(tab_id: String) -> Array:
	match tab_id:
		"cards":
			return card_data.get("cards", [])
		"relics":
			return relic_data.get("relics", [])
		"potions":
			return potion_data.get("potions", [])
		"enemies":
			return enemy_data.get("enemies", [])
		"events":
			return event_data.get("events", [])
		"challenges":
			return challenge_data.get("levels", [])
		_:
			return []

func _compendium_item_matches_filter(tab_id: String, item: Dictionary, filter_id: String) -> bool:
	if filter_id == "all":
		return true
	if filter_id == "discovered":
		return _compendium_item_discovered(tab_id, item)
	if filter_id == "undiscovered":
		return not _compendium_item_discovered(tab_id, item)
	match tab_id:
		"cards":
			return _compendium_card_matches_filter(item, filter_id)
		"relics":
			return _compendium_relic_matches_filter(item, filter_id)
		"potions":
			return _compendium_potion_matches_filter(item, filter_id)
		"enemies":
			return str(item.get("tier", "normal")) == filter_id
		"events":
			return _compendium_event_matches_filter(item, filter_id)
		"challenges":
			return _compendium_challenge_matches_filter(item, filter_id)
		_:
			return true

func _compendium_discovered_count(tab_id: String) -> int:
	var count := 0
	for item in _compendium_source_items(tab_id):
		var item_dict: Dictionary = item
		if _compendium_item_discovered(tab_id, item_dict):
			count += 1
	return count

func _compendium_item_discovered(tab_id: String, item: Dictionary) -> bool:
	var discovery_id: String = _compendium_item_discovery_id(tab_id, item)
	return not discovery_id.is_empty() and _discovered_ids(tab_id).has(discovery_id)

func _compendium_item_revealed(tab_id: String, item: Dictionary) -> bool:
	return compendium_reveal_all_details or _compendium_item_discovered(tab_id, item)

func _compendium_item_discovery_id(tab_id: String, item: Dictionary) -> String:
	if tab_id == "challenges":
		return str(int(item.get("level", 0)))
	return str(item.get("id", ""))

func _compendium_discovery_text(tab_id: String, item: Dictionary) -> String:
	return "已见" if _compendium_item_discovered(tab_id, item) else "未见"

func _compendium_locked_title(tab_id: String) -> String:
	match tab_id:
		"cards":
			return "未知卡牌"
		"relics":
			return "未知遗物"
		"potions":
			return "未知药水"
		"enemies":
			return "未知敌人"
		"events":
			return "未知事件"
		"challenges":
			return "未知挑战"
		_:
			return "未知条目"

func _compendium_locked_subtitle(tab_id: String) -> String:
	return "未见 | 详情隐藏"

func _compendium_locked_body(tab_id: String) -> String:
	match tab_id:
		"cards":
			return "在跑团中看到或获得后显示卡牌资料。"
		"relics":
			return "获得或看到该遗物后显示效果资料。"
		"potions":
			return "获得或看到该药水后显示一次性效果。"
		"enemies":
			return "遭遇该敌人后显示生命与意图资料。"
		"events":
			return "进入该事件后显示正文与选择资料。"
		"challenges":
			return "选择该挑战等级后显示修正规则。"
		_:
			return "发现后显示完整资料。"

func _compendium_locked_tooltip(tab_id: String) -> String:
	return "%s\n%s" % [_compendium_locked_title(tab_id), _compendium_locked_body(tab_id)]

func _compendium_locked_search_fields(tab_id: String) -> Array[String]:
	return [
		"未见",
		"未知",
		"详情隐藏",
		_compendium_tab_title(tab_id),
		_compendium_locked_title(tab_id)
	]

func _compendium_item_matches_search(tab_id: String, item: Dictionary, search_text: String) -> bool:
	var needle: String = _sanitize_compendium_search(search_text).to_lower()
	if needle.is_empty():
		return true
	var fields: Array[String] = _compendium_search_fields(tab_id, item) if _compendium_item_revealed(tab_id, item) else _compendium_locked_search_fields(tab_id)
	for field_text in fields:
		if str(field_text).to_lower().contains(needle):
			return true
	return false

func _compendium_search_fields(tab_id: String, item: Dictionary) -> Array[String]:
	var fields: Array[String] = [
		str(item.get("id", "")),
		str(item.get("name", "")),
		str(item.get("description", "")),
		str(item.get("design_note", "")),
		str(item.get("balance_note", "")),
		str(item.get("implementation_note", "")),
		str(item.get("upgrade_note", ""))
	]
	match tab_id:
		"cards":
			fields.append(str(item.get("type", "")))
			fields.append(str(item.get("rarity", "")))
			fields.append(str(item.get("target", "")))
			fields.append(_card_type_display_name(str(item.get("type", ""))))
			fields.append(_rarity_display_name(str(item.get("rarity", ""))))
			fields.append(_target_display_name(str(item.get("target", ""))))
		"relics":
			fields.append(str(item.get("rarity", "")))
			fields.append(_rarity_display_name(str(item.get("rarity", ""))))
			fields.append(_character_scope_text(item))
		"potions":
			fields.append(str(item.get("rarity", "")))
			fields.append(str(item.get("target", "")))
			fields.append(_rarity_display_name(str(item.get("rarity", ""))))
			fields.append(_target_display_name(str(item.get("target", ""))))
		"enemies":
			fields.append(str(item.get("tier", "")))
			fields.append(_enemy_tier_display_name(str(item.get("tier", ""))))
			fields.append(_enemy_actions_summary(item))
			fields.append(str(item.get("intent_note", "")))
		"events":
			fields.append(str(item.get("body", "")))
			fields.append(_character_scope_text(item))
			fields.append(_event_choices_summary(item))
		"challenges":
			fields.append(str(item.get("short_name", "")))
			fields.append(str(item.get("reward_note", "")))
			fields.append(_challenge_modifier_summary(int(item.get("level", 0))))
	return fields

func _sanitize_compendium_search(search_text: String) -> String:
	return search_text.strip_edges().substr(0, 32)

func _compendium_card_matches_filter(card: Dictionary, filter_id: String) -> bool:
	var card_type: String = str(card.get("type", ""))
	var rarity: String = str(card.get("rarity", ""))
	if _compendium_is_character_filter(filter_id):
		return _compendium_item_available_to_character(card, _compendium_character_id_from_filter(filter_id))
	match filter_id:
		"attack", "skill", "power":
			return card_type == filter_id
		"special":
			return card_type == "status" or card_type == "curse" or rarity == "status" or rarity == "curse"
		"starter", "common", "uncommon", "rare":
			return rarity == filter_id
		"shared":
			return _compendium_character_ids(card).is_empty()
		"exclusive":
			return not _compendium_character_ids(card).is_empty()
		_:
			return true

func _compendium_relic_matches_filter(relic: Dictionary, filter_id: String) -> bool:
	if _compendium_is_character_filter(filter_id):
		return _compendium_item_available_to_character(relic, _compendium_character_id_from_filter(filter_id))
	match filter_id:
		"starter", "common", "uncommon", "rare":
			return str(relic.get("rarity", "")) == filter_id
		"shared":
			return _compendium_character_ids(relic).is_empty()
		"exclusive":
			return not _compendium_character_ids(relic).is_empty()
		_:
			return true

func _compendium_potion_matches_filter(potion: Dictionary, filter_id: String) -> bool:
	match filter_id:
		"common", "uncommon", "rare":
			return str(potion.get("rarity", "")) == filter_id
		"self", "enemy", "all_enemies":
			return str(potion.get("target", "")) == filter_id
		_:
			return true

func _compendium_event_matches_filter(event: Dictionary, filter_id: String) -> bool:
	if _compendium_is_character_filter(filter_id):
		return _compendium_item_available_to_character(event, _compendium_character_id_from_filter(filter_id))
	match filter_id:
		"shared":
			return _compendium_character_ids(event).is_empty()
		"exclusive":
			return not _compendium_character_ids(event).is_empty()
		"one_time":
			return bool(event.get("one_time", false))
		_:
			return true

func _compendium_challenge_matches_filter(challenge: Dictionary, filter_id: String) -> bool:
	var modifiers: Dictionary = challenge.get("modifiers", {})
	match filter_id:
		"base":
			return int(challenge.get("level", 0)) == 0
		"challenge":
			return int(challenge.get("level", 0)) > 0
		"enemy_hp":
			return float(modifiers.get("enemy_hp_multiplier", 1.0)) > 1.0
		"enemy_damage":
			return float(modifiers.get("enemy_damage_multiplier", 1.0)) > 1.0
		"hp_loss":
			return int(modifiers.get("player_starting_hp_loss", 0)) > 0
		_:
			return true

func _compendium_item_less(tab_id: String, sort_id: String, left: Dictionary, right: Dictionary) -> bool:
	var left_key: String = _compendium_sort_key(tab_id, sort_id, left)
	var right_key: String = _compendium_sort_key(tab_id, sort_id, right)
	if left_key == right_key:
		return str(left.get("id", "")) < str(right.get("id", ""))
	return left_key < right_key

func _compendium_sort_key(tab_id: String, sort_id: String, item: Dictionary) -> String:
	var name_key: String = str(item.get("name", item.get("id", ""))).to_lower()
	match tab_id:
		"cards":
			match sort_id:
				"cost":
					return "%03d|%s" % [int(item.get("cost", 0)), name_key]
				"rarity":
					return "%02d|%s" % [_rarity_sort_index(str(item.get("rarity", ""))), name_key]
				"type":
					return "%02d|%s" % [_card_type_sort_index(str(item.get("type", ""))), name_key]
				_:
					return name_key
		"relics":
			match sort_id:
				"rarity":
					return "%02d|%s" % [_rarity_sort_index(str(item.get("rarity", ""))), name_key]
				"scope":
					return "%02d|%s" % [_scope_sort_index(item), name_key]
				_:
					return name_key
		"potions":
			match sort_id:
				"rarity":
					return "%02d|%s" % [_rarity_sort_index(str(item.get("rarity", ""))), name_key]
				"target":
					return "%02d|%s" % [_target_sort_index(str(item.get("target", ""))), name_key]
				_:
					return name_key
		"enemies":
			match sort_id:
				"tier":
					return "%02d|%s" % [_enemy_tier_sort_index(str(item.get("tier", "normal"))), name_key]
				"hp":
					return "%05d|%s" % [int(item.get("max_hp", 0)), name_key]
				_:
					return name_key
		"events":
			match sort_id:
				"scope":
					return "%02d|%s" % [_scope_sort_index(item), name_key]
				"choices":
					return "%03d|%s" % [item.get("choices", []).size(), name_key]
				_:
					return name_key
		"challenges":
			var modifiers: Dictionary = item.get("modifiers", {})
			match sort_id:
				"enemy_hp":
					return "%06.2f|%s" % [float(modifiers.get("enemy_hp_multiplier", 1.0)) * 100.0, name_key]
				"enemy_damage":
					return "%06.2f|%s" % [float(modifiers.get("enemy_damage_multiplier", 1.0)) * 100.0, name_key]
				"hp_loss":
					return "%03d|%s" % [int(modifiers.get("player_starting_hp_loss", 0)), name_key]
				_:
					return "%03d|%s" % [int(item.get("level", 0)), name_key]
		_:
			return name_key

func _compendium_character_ids(item: Dictionary) -> Array:
	var character_ids: Array = item.get("character_ids", [])
	return character_ids

func _compendium_item_available_to_character(item: Dictionary, character_id: String) -> bool:
	var character_ids: Array = _compendium_character_ids(item)
	return character_ids.is_empty() or character_ids.has(character_id)

func _rarity_sort_index(rarity: String) -> int:
	match rarity:
		"starter":
			return 0
		"common":
			return 1
		"uncommon":
			return 2
		"rare":
			return 3
		"status":
			return 4
		"curse":
			return 5
		_:
			return 9

func _card_type_sort_index(card_type: String) -> int:
	match card_type:
		"attack":
			return 0
		"skill":
			return 1
		"power":
			return 2
		"status":
			return 3
		"curse":
			return 4
		_:
			return 9

func _target_sort_index(target: String) -> int:
	match target:
		"self":
			return 0
		"enemy":
			return 1
		"all_enemies":
			return 2
		"random_enemy":
			return 3
		"none":
			return 4
		_:
			return 9

func _enemy_tier_sort_index(tier: String) -> int:
	match tier:
		"normal":
			return 0
		"elite":
			return 1
		"boss":
			return 2
		_:
			return 9

func _scope_sort_index(item: Dictionary) -> int:
	return 1 if not _compendium_character_ids(item).is_empty() else 0

func _count_items_by_field(items: Array, field: String, expected: String) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if str(item_dict.get(field, "")) == expected:
			count += 1
	return count

func _count_bool_items_by_field(items: Array, field: String, expected: bool) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if bool(item_dict.get(field, false)) == expected:
			count += 1
	return count

func _count_compendium_shared_items(items: Array) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if _compendium_character_ids(item_dict).is_empty():
			count += 1
	return count

func _count_compendium_exclusive_items(items: Array) -> int:
	var count := 0
	for item in items:
		var item_dict: Dictionary = item
		if not _compendium_character_ids(item_dict).is_empty():
			count += 1
	return count

func _target_display_name(target: String) -> String:
	match target:
		"enemy":
			return "单体"
		"self":
			return "自身"
		"all_enemies":
			return "全体敌人"
		"random_enemy":
			return "随机敌人"
		"none":
			return "无目标"
		_:
			return target

func _enemy_tier_display_name(tier: String) -> String:
	match tier:
		"normal":
			return "普通"
		"elite":
			return "精英"
		"boss":
			return "Boss"
		_:
			return tier

func _character_scope_text(item: Dictionary) -> String:
	var character_ids: Array = item.get("character_ids", [])
	if character_ids.is_empty():
		return "通用"
	var names: Array[String] = []
	for character_id in character_ids:
		names.append(_character_display_name(str(character_id)))
	return "专属：%s" % "、".join(names)

func _enemy_actions_summary(enemy: Dictionary) -> String:
	var parts: Array[String] = []
	for action in enemy.get("actions", []):
		var action_dict: Dictionary = action
		var intent: Dictionary = action_dict.get("intent", {})
		var intent_type: String = str(intent.get("type", "intent"))
		if intent.has("amount"):
			parts.append("%s %d" % [intent_type, int(intent.get("amount", 0))])
		elif intent.has("status"):
			parts.append("%s %s" % [intent_type, str(intent.get("status", ""))])
		else:
			parts.append(intent_type)
	return " / ".join(parts)

func _event_choices_summary(event: Dictionary) -> String:
	var parts: Array[String] = []
	for choice in event.get("choices", []):
		var choice_dict: Dictionary = choice
		var label: String = str(choice_dict.get("label", choice_dict.get("text", "选择")))
		var effect_texts: Array[String] = []
		for effect in choice_dict.get("effects", []):
			var effect_dict: Dictionary = effect
			effect_texts.append(_event_effect_summary(effect_dict))
		if effect_texts.is_empty():
			parts.append(label)
		else:
			parts.append("%s：%s" % [label, "，".join(effect_texts)])
	return " / ".join(parts)

func _event_effect_summary(effect: Dictionary) -> String:
	var effect_type: String = str(effect.get("type", "effect"))
	match effect_type:
		"gain_gold":
			return "+%d 金币" % int(effect.get("amount", 0))
		"lose_hp":
			return "-%dHP" % int(effect.get("amount", 0))
		"heal_percent":
			return "恢复 %d%%" % int(effect.get("amount", 0))
		"add_card":
			return "获得卡牌 %s" % str(_card_by_id(str(effect.get("card_id", ""))).get("name", effect.get("card_id", "")))
		"gain_relic":
			return "获得遗物 %s" % str(_relic_by_id(str(effect.get("relic_id", ""))).get("name", effect.get("relic_id", "")))
		"gain_potion":
			return "获得药水 %s" % str(_potion_by_id(str(effect.get("potion_id", ""))).get("name", effect.get("potion_id", "")))
		"remove_first_non_starter_card":
			return "删卡"
		_:
			return effect_type

func _apply_tutorial_hint(step_id: String) -> void:
	if status_label == null:
		return
	if step_id.is_empty() or not _setting_enabled("tutorial_enabled", true) or _tutorial_step_completed(step_id):
		last_tutorial_visible = false
		last_tutorial_step_id = ""
		last_tutorial_title = ""
		last_tutorial_body = ""
		if tutorial_button != null:
			tutorial_button.text = "引导"
		status_label.tooltip_text = status_label.text
		return
	var data: Dictionary = _tutorial_step_data(step_id)
	if data.is_empty():
		return
	last_tutorial_visible = true
	last_tutorial_step_id = step_id
	last_tutorial_title = str(data.get("title", step_id))
	last_tutorial_body = str(data.get("body", ""))
	var short_text: String = str(data.get("short", last_tutorial_title))
	status_label.text = "%s | 引导：%s" % [status_label.text, short_text]
	status_label.tooltip_text = "%s\n\n引导：%s\n%s" % [status_label.text, last_tutorial_title, last_tutorial_body]
	if tutorial_button != null:
		tutorial_button.text = "完成引导"

func _tutorial_step_data(step_id: String) -> Dictionary:
	match step_id:
		"character_select":
			return {
				"title": "选择第一名角色",
				"short": "先用余烬流亡者熟悉基础节奏",
				"body": "余烬流亡者生命更高、牌组直接，适合第一次跑团；电弧工匠偏资源节奏，熔痕苦修者偏高风险自伤。"
			}
		"combat_player":
			return {
				"title": "战斗回合",
				"short": "先看对手行动，再分配能量",
				"body": "对手面板会显示下一步行动。优先确认会受到多少伤害，再决定打攻击牌、防御牌或保留资源结束回合。"
			}
		"combat_reward":
			return {
				"title": "战斗奖励",
				"short": "奖励不是越多越好",
				"body": "卡牌会增加牌组厚度。选择能服务当前构筑的卡；不需要的奖励可以跳过，遗物和药水通常更适合作为即时强化。"
			}
		"map_choice":
			return {
				"title": "路线选择",
				"short": "预览后续节点再决定路线",
				"body": "地图节点可预览后续可达位置。普通战斗更稳定，精英风险高但遗物收益强，商店和篝火适合修正牌组。"
			}
		"event":
			return {
				"title": "问号事件",
				"short": "事件选项通常是资源交换",
				"body": "事件可能用生命换金币、卡牌、遗物或删卡机会。被禁用的选项会说明条件不足。"
			}
		"shop":
			return {
				"title": "商店",
				"short": "删卡能提高抽到关键牌的概率",
				"body": "商店可以买卡、药水或删卡。删卡价格会随本局次数递增，优先移除不服务构筑的低质量牌。"
			}
		"campfire":
			return {
				"title": "篝火",
				"short": "低血量休息，稳定时升级核心牌",
				"body": "休息恢复生命，升级能提高单卡效率。若下一条路线有精英或 Boss，生命安全通常优先。"
			}
		"deck_view":
			return {
				"title": "查看牌组",
				"short": "用牌组统计检查构筑方向",
				"body": "牌组查看器会显示攻击、技能、能力、状态/诅咒和升级数量。过多状态牌或低质量牌会降低关键回合稳定性。"
			}
		"settings":
			return {
				"title": "设置",
				"short": "可关闭强反馈或重置引导",
				"body": "设置页可以调整音频、震屏、受击顿帧和漂浮文字。需要重新查看这些提示时，可以重置新手引导。"
			}
		"run_complete":
			return {
				"title": "跑团结算",
				"short": "查看最终牌组，总结构筑表现",
				"body": "最终结算会显示资源、牌组类型统计和局外解锁。查看最终牌组能帮助判断哪些牌真正支撑了通关。"
			}
	return {}

func _tutorial_completed_steps() -> Array:
	var steps: Array = []
	for step_id in user_settings.get("tutorial_completed_steps", []):
		var step_id_string: String = str(step_id)
		if not step_id_string.is_empty() and not steps.has(step_id_string):
			steps.append(step_id_string)
	return steps

func _tutorial_step_completed(step_id: String) -> bool:
	return _tutorial_completed_steps().has(step_id)

func _complete_tutorial_step(step_id: String) -> void:
	if step_id.is_empty():
		return
	var steps: Array = _tutorial_completed_steps()
	if not steps.has(step_id):
		steps.append(step_id)
	user_settings["tutorial_completed_steps"] = steps
	_save_user_settings()

func _profile_stats() -> Dictionary:
	var stats: Dictionary = player_profile.get("stats", {})
	if stats.is_empty():
		player_profile = SaveManagerScript.normalized_profile(player_profile)
		stats = player_profile.get("stats", {})
	return stats

func _profile_unlocked_achievements() -> Array:
	return player_profile.get("unlocked_achievement_ids", [])

func _profile_stat(stat_id: String) -> int:
	return int(_profile_stats().get(stat_id, 0))

func _increment_profile_stat(stat_id: String, amount: int = 1) -> void:
	var stats: Dictionary = _profile_stats()
	stats[stat_id] = max(0, int(stats.get(stat_id, 0)) + amount)
	player_profile["stats"] = stats

func _set_profile_stat_max(stat_id: String, value: int) -> void:
	var stats: Dictionary = _profile_stats()
	stats[stat_id] = max(int(stats.get(stat_id, 0)), value)
	player_profile["stats"] = stats

func _profile_append_unique(field_id: String, value_id: String) -> void:
	if value_id.is_empty():
		return
	var values: Array = player_profile.get(field_id, [])
	if not values.has(value_id):
		values.append(value_id)
	player_profile[field_id] = values

func _profile_discovered() -> Dictionary:
	player_profile = SaveManagerScript.normalized_profile(player_profile)
	return player_profile.get("discovered", {})

func _discovered_ids(category_id: String) -> Array:
	return _profile_discovered().get(category_id, [])

func _record_discovered_content(category_id: String, content_id: String) -> bool:
	var normalized_id: String = content_id.strip_edges()
	if category_id.is_empty() or normalized_id.is_empty():
		return false
	var discovered: Dictionary = _profile_discovered()
	var ids: Array = discovered.get(category_id, [])
	if ids.has(normalized_id):
		return false
	ids.append(normalized_id)
	discovered[category_id] = ids
	player_profile["discovered"] = discovered
	return true

func _record_discovered_item_array(category_id: String, items: Array) -> bool:
	var changed := false
	for item in items:
		var item_dict: Dictionary = item
		var item_id: String = _compendium_item_discovery_id(category_id, item_dict)
		if _record_discovered_content(category_id, item_id):
			changed = true
	return changed

func _record_current_run_discoveries(save_now: bool = true) -> bool:
	var changed := false
	for entry_value in run_deck_ids:
		var card_id: String = _base_card_id(str(entry_value))
		changed = _record_discovered_content("cards", card_id) or changed
	for relic_id_value in run_relic_ids:
		changed = _record_discovered_content("relics", str(relic_id_value)) or changed
	for potion_id_value in run_potion_ids:
		changed = _record_discovered_content("potions", str(potion_id_value)) or changed
	changed = _record_discovered_content("challenges", str(current_challenge_level)) or changed
	if save_now and changed:
		_save_player_profile()
	return changed

func _record_encounter_discoveries(encounter_id: String) -> bool:
	var encounter: Dictionary = _encounter_by_id(encounter_id)
	var changed := false
	for enemy_id_value in encounter.get("enemy_ids", []):
		changed = _record_discovered_content("enemies", str(enemy_id_value)) or changed
	return changed

func _record_run_started() -> void:
	_increment_profile_stat("runs_started", 1)
	_set_profile_stat_max("highest_deck_size", run_deck_ids.size())
	_set_profile_stat_max("best_gold", run_gold)
	_set_profile_stat_max("max_challenge_level_unlocked", _max_unlocked_challenge_level())
	_refresh_achievement_unlocks("run_started")
	_save_player_profile()

func _record_card_removed() -> void:
	_increment_profile_stat("cards_removed", 1)
	_refresh_achievement_unlocks("card_removed")
	_save_player_profile()

func _record_boss_defeated(chapter_id: String) -> void:
	_increment_profile_stat("bosses_defeated", 1)
	_set_profile_stat_max("best_gold", run_gold)
	_set_profile_stat_max("highest_deck_size", run_deck_ids.size())
	_refresh_achievement_unlocks("boss_defeated")
	_save_player_profile()

func _record_chapter_completed(chapter_id: String) -> void:
	_profile_append_unique("completed_chapters", chapter_id)
	_refresh_achievement_unlocks("chapter_completed")
	_save_player_profile()

func _record_run_completed() -> void:
	_increment_profile_stat("runs_completed", 1)
	_set_profile_stat_max("best_gold", run_gold)
	_set_profile_stat_max("highest_deck_size", run_deck_ids.size())
	_set_profile_stat_max("best_challenge_level_completed", current_challenge_level)
	_profile_append_unique("character_completions", selected_character_id)
	for chapter_id in completed_chapter_ids:
		_profile_append_unique("completed_chapters", str(chapter_id))
	_set_profile_stat_max("max_challenge_level_unlocked", _max_unlocked_challenge_level())
	_refresh_achievement_unlocks("run_completed")
	_save_player_profile()

func _refresh_achievement_unlocks(context: String = "") -> Array[String]:
	player_profile = SaveManagerScript.normalized_profile(player_profile)
	var unlocked: Array = player_profile.get("unlocked_achievement_ids", [])
	var newly_unlocked: Array[String] = []
	for achievement in achievement_data.get("achievements", []):
		var achievement_dict: Dictionary = achievement
		var achievement_id: String = str(achievement_dict.get("id", ""))
		if achievement_id.is_empty() or unlocked.has(achievement_id):
			continue
		if _achievement_condition_met(achievement_dict):
			unlocked.append(achievement_id)
			newly_unlocked.append(achievement_id)
	player_profile["unlocked_achievement_ids"] = unlocked
	player_profile["last_unlock_ids"] = newly_unlocked
	last_profile_total_count = achievement_data.get("achievements", []).size()
	last_profile_unlocked_count = unlocked.size()
	return newly_unlocked

func _achievement_condition_met(achievement: Dictionary) -> bool:
	var condition: Dictionary = achievement.get("condition", {})
	var condition_type: String = str(condition.get("type", ""))
	match condition_type:
		"runs_started_at_least":
			return _profile_stat("runs_started") >= int(condition.get("amount", 1))
		"runs_completed_at_least":
			return _profile_stat("runs_completed") >= int(condition.get("amount", 1))
		"bosses_defeated_at_least":
			return _profile_stat("bosses_defeated") >= int(condition.get("amount", 1))
		"cards_removed_at_least":
			return _profile_stat("cards_removed") >= int(condition.get("amount", 1))
		"challenge_completed_at_least":
			return _profile_stat("best_challenge_level_completed") >= int(condition.get("amount", 1))
		"chapter_completed":
			return player_profile.get("completed_chapters", []).has(str(condition.get("chapter_id", "")))
		"character_completed":
			return player_profile.get("character_completions", []).has(str(condition.get("character_id", "")))
	return false

func _achievement_by_id(achievement_id: String) -> Dictionary:
	for achievement in achievement_data.get("achievements", []):
		var achievement_dict: Dictionary = achievement
		if str(achievement_dict.get("id", "")) == achievement_id:
			return achievement_dict
	return {}

func _refresh_combat() -> void:
	if combat == null:
		return
	var reward_visible: bool = combat.phase == "won" or combat.phase == "lost"
	if combat.phase == "lost":
		_music_context("defeat")
	elif combat.phase == "won":
		_music_context("reward")
	elif str(_current_node().get("type", "")) == "boss":
		_music_context("boss")
	else:
		_music_context("combat")
	var hand_visible: bool = not reward_visible
	var board_visible: bool = not reward_visible
	_set_page_regions(true, board_visible, false, board_visible, board_visible, true, hand_visible, reward_visible)
	_apply_combat_layout_constraints(reward_visible)
	status_label.text = "回合 %d | 阶段：%s | 资源见 HUD，下方显示对手行动。" % [
		combat.turn,
		combat.phase
	]
	_refresh_battle_background()
	_refresh_combat_hud()
	_refresh_potions()
	_refresh_enemies()
	_refresh_hand()
	_refresh_rewards()
	_refresh_log()
	_refresh_feedback()
	_record_combat_layout_metrics(reward_visible)
	end_turn_button.disabled = combat.phase != "player"

func _record_combat_layout_metrics(reward_visible: bool) -> void:
	last_combat_reward_region_visible = reward_visible
	_record_layout_metrics()

func _record_layout_metrics() -> void:
	_sync_layout_widths()
	_record_scroll_region_metrics()
	last_combat_layout_available_height = _layout_viewport_size().y
	last_combat_layout_total_height = _root_vertical_margin()
	var visible_child_count := 0
	if root_box != null:
		for child in root_box.get_children():
			var child_control := child as Control
			if child_control != null and child_control.visible:
				last_combat_layout_total_height += _estimated_control_height(child_control)
				visible_child_count += 1
	if visible_child_count > 1 and root_box != null:
		last_combat_layout_total_height += float(root_box.get_theme_constant("separation")) * float(visible_child_count - 1)
	last_combat_layout_estimated_height = last_combat_layout_total_height
	last_combat_layout_overflow = max(0.0, last_combat_layout_total_height - last_combat_layout_available_height)

func _refresh_battle_background() -> void:
	if screen_background_art != null and screen_background_art.texture == null:
		screen_background_art.texture = _load_texture(UI_BACKDROP_PATH)
		screen_background_art.visible = screen_background_art.texture != null
		last_ui_backdrop_loaded = screen_background_art.visible
	last_battle_background_chapter_id = current_chapter_id
	last_battle_background_path = _battle_background_path(current_chapter_id)
	last_battle_background_loaded = _asset_loaded(last_battle_background_path)
	if battle_background == null:
		return
	battle_background.texture = _load_texture(last_battle_background_path)
	battle_background.visible = last_battle_background_loaded

func _refresh_combat_hud() -> void:
	if combat_hud_row == null or combat == null:
		return
	_clear_container(combat_hud_row)
	last_combat_hud_block_count = 0
	var hp: int = int(combat.player.get("hp", 0))
	var max_hp: int = int(combat.player.get("max_hp", 0))
	var block: int = int(combat.player.get("block", 0))
	var energy: int = int(combat.player.get("energy", 0))
	var max_energy: int = int(combat.player.get("max_energy", 0))
	var momentum: int = int(combat.player.get("momentum", 0))
	var momentum_max: int = int(combat.player.get("momentum_max", 0))
	var entries: Array[Dictionary] = [
		{"label": "生命", "value": "%d/%d" % [hp, max_hp], "skin": "danger"},
		{"label": "护甲", "value": "%d" % block, "skin": "primary"},
		{"label": "能量", "value": "%d/%d" % [energy, max_energy], "skin": "relic"},
		{"label": "势能", "value": "%d/%d" % [momentum, momentum_max], "skin": "potion"},
		{"label": "抽牌", "value": "%d" % combat.draw_pile.size(), "skin": "neutral"},
		{"label": "弃牌", "value": "%d" % combat.discard_pile.size(), "skin": "neutral"},
		{"label": "消耗", "value": "%d" % combat.exhaust_pile.size(), "skin": "event"}
	]
	var text_parts: Array[String] = []
	for entry in entries:
		var entry_dict: Dictionary = entry
		var label: String = str(entry_dict.get("label", ""))
		var value: String = str(entry_dict.get("value", ""))
		_add_hud_block(label, value, str(entry_dict.get("skin", "neutral")))
		text_parts.append("%s %s" % [label, value])
	last_combat_hud_text = " | ".join(text_parts)

func _add_hud_block(label_text: String, value_text: String, skin: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_hud_block_width(), round(34.0 * _combat_layout_scale()))
	var palette: Dictionary = _button_skin_palette(skin)
	panel.add_theme_stylebox_override("panel", _button_style(
		palette.get("bg", Color(0.16, 0.17, 0.18)),
		palette.get("border", Color(0.46, 0.50, 0.52)),
		2,
		6
	))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.74))
	box.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", Color(0.96, 0.96, 0.90))
	box.add_child(value)
	combat_hud_row.add_child(panel)
	last_combat_hud_block_count += 1

func _refresh_campfire(node: Dictionary) -> void:
	last_campfire_button_style_count = 0
	last_campfire_card_layout_count = 0
	last_campfire_card_art_node_count = 0
	_set_page_regions(true, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(156.0, 204.0)
	status_label.text = "篝火：选择恢复生命或升级一张牌。升级后的牌会在名称后显示 +。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true

	var heal_button := Button.new()
	heal_button.custom_minimum_size = Vector2(180, 92)
	heal_button.text = "休息\n恢复 %d%% 最大生命" % _campfire_heal_percent()
	_apply_button_skin(heal_button, "success", "campfire")
	heal_button.pressed.connect(_on_campfire_heal_pressed)
	reward_row.add_child(heal_button)

	var upgrade_label := Label.new()
	upgrade_label.text = "可升级："
	upgrade_label.custom_minimum_size = Vector2(90, 0)
	reward_row.add_child(upgrade_label)

	var shown: int = 0
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		if entry.ends_with("+"):
			continue
		var card: Dictionary = _card_by_id(entry)
		if card.is_empty() or not card.has("upgrade"):
			continue
		var button := Button.new()
		button.custom_minimum_size = _large_card_button_size()
		button.text = ""
		button.tooltip_text = _upgrade_preview_text(card)
		var art_path: String = _card_art_path(card)
		var card_texture: Texture2D = _load_texture(art_path)
		_apply_card_button_skin(button, str(card.get("type", "")), "campfire")
		_add_structured_card_layout(button, card, card_texture, "campfire")
		button.pressed.connect(_on_upgrade_card_pressed.bind(i))
		reward_row.add_child(button)
		shown += 1
		if shown >= 4:
			break

	if shown == 0:
		var no_upgrade := Label.new()
		no_upgrade.text = "没有可升级卡牌。"
		reward_row.add_child(no_upgrade)
	_record_layout_metrics()

func _refresh_shop(node: Dictionary) -> void:
	last_shop_button_style_count = 0
	last_shop_card_layout_count = 0
	last_shop_card_art_node_count = 0
	last_shop_potion_layout_count = 0
	last_shop_potion_icon_node_count = 0
	_set_page_regions(true, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(150.0, 204.0)
	if shop_generated_for != current_node_index:
		shop_card_options = _generate_card_rewards(3, "shop_card")
		shop_potion_options = _generate_potion_rewards(2, "shop_potion")
		var discovery_changed: bool = _record_discovered_item_array("cards", shop_card_options)
		discovery_changed = _record_discovered_item_array("potions", shop_potion_options) or discovery_changed
		if discovery_changed:
			_save_player_profile()
		shop_generated_for = current_node_index

	status_label.text = "商店：购买卡牌或移除牌组中的一张牌。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true

	for card in shop_card_options:
		var card_dict: Dictionary = card
		var price: int = _card_price(card_dict)
		var button := Button.new()
		button.custom_minimum_size = _large_card_button_size()
		button.text = ""
		button.tooltip_text = "购买 %s\n%d 金币\n%s" % [card_dict.get("name", "卡牌"), price, card_dict.get("description", "")]
		last_reward_card_art_path = _card_art_path(card_dict)
		last_reward_card_art_loaded = _asset_loaded(last_reward_card_art_path)
		var card_texture: Texture2D = _load_texture(last_reward_card_art_path)
		_apply_card_button_skin(button, str(card_dict.get("type", "")), "shop")
		_add_structured_card_layout(button, card_dict, card_texture, "shop")
		button.disabled = run_gold < price
		button.pressed.connect(_on_shop_buy_card_pressed.bind(str(card_dict.get("id", "")), price))
		reward_row.add_child(button)

	for potion in shop_potion_options:
		var potion_dict: Dictionary = potion
		var potion_price: int = _potion_price(potion_dict)
		var potion_button := Button.new()
		potion_button.custom_minimum_size = _large_item_button_size()
		potion_button.text = ""
		potion_button.tooltip_text = "药水 %s\n%d 金币\n%s" % [potion_dict.get("name", "药水"), potion_price, potion_dict.get("description", "")]
		last_potion_icon_path = _potion_icon_path(potion_dict)
		last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
		var potion_texture: Texture2D = _load_texture(last_potion_icon_path)
		_apply_button_skin(potion_button, "potion", "shop")
		_add_icon_item_layout(
			potion_button,
			str(potion_dict.get("name", "药水")),
			"%d 金币" % potion_price,
			str(potion_dict.get("description", "")),
			potion_texture,
			"potion",
			"shop_potion",
			false
		)
		potion_button.disabled = run_gold < potion_price or not _has_empty_potion_slot()
		potion_button.pressed.connect(_on_shop_buy_potion_pressed.bind(str(potion_dict.get("id", "")), potion_price))
		reward_row.add_child(potion_button)

	var remove_button := Button.new()
	remove_button.custom_minimum_size = Vector2(160, 104)
	var remove_price: int = _remove_card_price()
	remove_button.text = "删卡\n%d 金币\n本局已删 %d 次\n优先移除非初始牌" % [remove_price, run_shop_remove_count]
	_apply_button_skin(remove_button, "danger", "shop")
	remove_button.disabled = run_gold < remove_price or run_deck_ids.is_empty()
	remove_button.pressed.connect(_on_shop_remove_card_pressed)
	reward_row.add_child(remove_button)

	var leave_button := Button.new()
	leave_button.custom_minimum_size = Vector2(120, 104)
	leave_button.text = "离开商店"
	_apply_button_skin(leave_button, "neutral", "shop")
	leave_button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(leave_button)
	_record_layout_metrics()

func _refresh_event(node: Dictionary) -> void:
	last_event_choice_style_count = 0
	last_event_art_path = ""
	last_event_art_loaded = false
	last_event_panel_title = ""
	last_event_panel_body = ""
	last_event_panel_choice_count = 0
	_set_page_regions(true, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(132.0, 204.0)
	var event: Dictionary = _event_by_id(str(node.get("event_id", "")))
	status_label.text = "问号事件：阅读现场信息并选择回应。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true

	_add_event_story_panel(event, node)

	for choice in event.get("choices", []):
		var choice_dict: Dictionary = choice
		var button := Button.new()
		button.custom_minimum_size = Vector2(196, 122)
		var blocked_reason: String = _event_choice_blocked_reason(choice_dict)
		button.text = _event_choice_button_text(choice_dict, blocked_reason)
		_apply_button_skin(button, "event", "event")
		button.disabled = not blocked_reason.is_empty()
		button.pressed.connect(_on_event_choice_pressed.bind(choice_dict))
		reward_row.add_child(button)
		last_event_panel_choice_count += 1

	if event.get("choices", []).is_empty():
		var continue_button := Button.new()
		continue_button.custom_minimum_size = Vector2(120, 104)
		continue_button.text = "继续"
		_apply_button_skin(continue_button, "primary", "event")
		continue_button.pressed.connect(_advance_to_next_node)
		reward_row.add_child(continue_button)
	_record_layout_metrics()

func _add_event_story_panel(event: Dictionary, node: Dictionary) -> void:
	var panel := PanelContainer.new()
	var panel_size: Vector2 = _event_story_panel_size()
	panel.custom_minimum_size = panel_size
	panel.add_theme_stylebox_override("panel", _event_story_panel_style())
	reward_row.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var art_size: Vector2 = _event_story_art_size(panel_size.x)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = art_size
	art_frame.add_theme_stylebox_override("panel", _icon_item_frame_style("event"))
	row.add_child(art_frame)

	var event_title: String = str(event.get("name", node.get("name", "事件")))
	var event_body: String = str(event.get("body", "你遇到了一个未知事件。"))
	last_event_panel_title = event_title
	last_event_panel_body = event_body
	last_event_art_path = _event_art_path(event)
	last_event_art_loaded = _asset_loaded(last_event_art_path)

	var art := TextureRect.new()
	art.custom_minimum_size = art_size
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = _load_texture(last_event_art_path)
	art_frame.add_child(art)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 5)
	row.add_child(text_box)

	var title := Label.new()
	title.text = event_title
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 14 if panel_size.x < 340.0 else 15)
	title.add_theme_color_override("font_color", Color(0.98, 0.93, 0.78))
	text_box.add_child(title)

	var body := Label.new()
	body.text = event_body
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 10 if panel_size.x < 340.0 else 11)
	body.add_theme_color_override("font_color", Color(0.86, 0.88, 0.84))
	text_box.add_child(body)

func _event_story_panel_style() -> StyleBoxFlat:
	return _button_style(Color(0.13, 0.12, 0.15), Color(0.64, 0.52, 0.82), 2, 6)

func _refresh_unknown_node(node: Dictionary) -> void:
	_set_page_regions(true, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(160.0, 120.0)
	status_label.text = "未知节点，自动前进。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true
	var button := Button.new()
	button.text = "继续"
	_apply_button_skin(button, "primary")
	button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(button)
	_record_layout_metrics()

func _refresh_potions() -> void:
	_clear_container(potion_row)
	last_potion_slot_layout_count = 0
	last_potion_slot_icon_node_count = 0
	var label := Label.new()
	label.text = "药水"
	label.custom_minimum_size = Vector2(30 if _scroll_content_width() < 420.0 else 44, 0)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 12)
	potion_row.add_child(label)

	var max_slots: int = _max_potion_slots()
	for i in range(max_slots):
		var button := Button.new()
		button.custom_minimum_size = _potion_slot_button_size()
		_configure_button_bounds(button)
		button.clip_contents = true
		button.add_theme_stylebox_override("normal", _button_style(Color(0.19, 0.21, 0.24), Color(0.89, 0.53, 0.25)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.24, 0.27, 0.31), Color(0.98, 0.70, 0.32)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.14, 0.16, 0.18), Color(0.98, 0.70, 0.32)))
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.13, 0.15), Color(0.35, 0.36, 0.38)))
		button.add_theme_font_size_override("font_size", 12)
		if i < run_potion_ids.size():
			var potion: Dictionary = _potion_by_id(str(run_potion_ids[i]))
			last_potion_icon_path = _potion_icon_path(potion)
			last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
			var potion_texture: Texture2D = _load_texture(last_potion_icon_path)
			button.text = ""
			button.tooltip_text = "%s\n%s" % [potion.get("name", run_potion_ids[i]), potion.get("description", "")]
			_add_icon_item_layout(
				button,
				str(potion.get("name", run_potion_ids[i])),
				"使用",
				str(potion.get("description", "")),
				potion_texture,
				"potion",
				"potion_slot",
				true
			)
			button.disabled = combat == null or combat.phase != "player"
			button.pressed.connect(_on_potion_pressed.bind(i))
		else:
			last_potion_icon_path = _potion_fallback_icon_path()
			last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
			var empty_texture: Texture2D = _load_texture(last_potion_icon_path)
			button.text = ""
			button.tooltip_text = "空药水槽"
			_add_icon_item_layout(
				button,
				"空槽",
				"待拾取",
				"",
				empty_texture,
				"potion",
				"potion_slot",
				true
			)
			button.disabled = true
		potion_row.add_child(button)

func _refresh_enemies() -> void:
	_clear_container(enemy_row)
	enemy_visuals_by_id.clear()
	last_enemy_intent_badge_count = 0
	last_enemy_intent_badge_texts.clear()
	last_enemy_intent_badge_types.clear()
	for i in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[i]
		var enemy_id: String = str(enemy.get("id", ""))
		var panel_width: float = _enemy_panel_width()
		var panel_height: float = _enemy_panel_height()
		var panel := VBoxContainer.new()
		panel.custom_minimum_size = Vector2(panel_width, panel_height)
		panel.add_theme_constant_override("separation", 4)
		enemy_row.add_child(panel)

		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(panel_width, _enemy_art_height())
		art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = _enemy_texture(enemy)
		panel.add_child(art)

		var intent_badge := _enemy_intent_badge(enemy, panel_width)
		panel.add_child(intent_badge)

		var button := Button.new()
		button.custom_minimum_size = Vector2(panel_width, _enemy_button_height())
		button.disabled = int(enemy.get("hp", 0)) <= 0
		button.text = _enemy_button_text(enemy, i == selected_enemy_index)
		button.tooltip_text = _enemy_tooltip_text(enemy)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_stylebox_override("normal", _enemy_button_style(enemy, i == selected_enemy_index, false))
		button.add_theme_stylebox_override("hover", _enemy_button_style(enemy, true, false))
		button.add_theme_stylebox_override("pressed", _enemy_button_style(enemy, true, true))
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.13, 0.13, 0.14), Color(0.34, 0.34, 0.36)))
		button.pressed.connect(_on_enemy_pressed.bind(i))
		panel.add_child(button)
		var visual_entry := {
			"panel": panel,
			"art": art,
			"intent_badge": intent_badge,
			"button": button
		}
		enemy_visuals_by_id["%s:%d" % [enemy_id, i]] = visual_entry
		if not enemy_visuals_by_id.has(enemy_id):
			enemy_visuals_by_id[enemy_id] = visual_entry

func _enemy_button_text(enemy: Dictionary, selected: bool) -> String:
	var prefix := ">> " if selected else ""
	var phase_name: String = str(enemy.get("phase_name", ""))
	var phase_text: String = " [%s]" % phase_name if not phase_name.is_empty() else ""
	var status_text: String = _status_text(enemy.get("statuses", {}))
	return "%s%s%s\nHP %d/%d  护甲 %d  %s" % [
		prefix,
		enemy.get("name", "敌人"),
		phase_text,
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("block", 0)),
		status_text
	]

func _enemy_tooltip_text(enemy: Dictionary) -> String:
	var data: Dictionary = enemy.get("data", {})
	var phase_name: String = str(enemy.get("phase_name", ""))
	var phase_line: String = "阶段：%s\n" % phase_name if not phase_name.is_empty() else ""
	return "%s\n%s类型：%s\n%s" % [
		enemy.get("name", "敌人"),
		phase_line,
		data.get("tier", "normal"),
		data.get("intent_note", "")
	]

func _intent_text(intent: Dictionary) -> String:
	var intent_type: String = str(intent.get("type", "none"))
	match intent_type:
		"attack":
			return "攻击 %d x%d" % [int(intent.get("amount", 0)), int(intent.get("hits", 1))]
		"block":
			return "获得护甲 %d" % int(intent.get("amount", 0))
		"debuff":
			return "施加 %s x%d" % [intent.get("status", ""), int(intent.get("amount", 0))]
		"attack_debuff":
			return "攻击 %d 并施加 %s" % [int(intent.get("amount", 0)), intent.get("status", "")]
		"status_card":
			return "加入状态牌 %s" % intent.get("card_id", "")
		"buff":
			return "强化 %s x%d" % [intent.get("status", ""), int(intent.get("amount", 0))]
		"block_buff":
			return "护甲 %d 并强化" % int(intent.get("amount", 0))
		_:
			return intent_type

func _enemy_intent_badge(enemy: Dictionary, badge_width: float = 210.0) -> PanelContainer:
	var action: Dictionary = enemy.get("current_action", {})
	var intent: Dictionary = action.get("intent", {})
	var intent_type: String = str(intent.get("type", "none"))
	var badge_text: String = _intent_badge_label(intent)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(badge_width, _enemy_badge_height())
	badge.tooltip_text = "敌人意图：%s" % _intent_text(intent)
	badge.add_theme_stylebox_override("panel", _intent_badge_style(intent_type))

	var label := Label.new()
	label.text = badge_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", _intent_badge_font_color(intent_type))
	badge.add_child(label)

	last_enemy_intent_badge_count += 1
	last_enemy_intent_badge_texts.append(badge_text)
	last_enemy_intent_badge_types.append(intent_type)
	return badge

func _intent_badge_label(intent: Dictionary) -> String:
	var intent_type: String = str(intent.get("type", "none"))
	var category := "意图"
	match intent_type:
		"attack":
			category = "攻击"
		"attack_debuff":
			category = "攻击/减益"
		"block":
			category = "护甲"
		"block_buff":
			category = "护甲/强化"
		"debuff", "status_card":
			category = "干扰"
		"buff":
			category = "强化"
	return "%s | %s" % [category, _intent_text(intent)]

func _intent_badge_style(intent_type: String) -> StyleBoxFlat:
	var palette: Dictionary = _intent_badge_palette(intent_type)
	return _button_style(
		palette.get("bg", Color(0.16, 0.17, 0.18)),
		palette.get("border", Color(0.46, 0.50, 0.52)),
		2,
		6
	)

func _intent_badge_font_color(intent_type: String) -> Color:
	var palette: Dictionary = _intent_badge_palette(intent_type)
	return palette.get("font", Color(0.95, 0.96, 0.92))

func _intent_badge_palette(intent_type: String) -> Dictionary:
	match intent_type:
		"attack":
			return {"bg": Color(0.24, 0.10, 0.09), "border": Color(0.92, 0.34, 0.24), "font": Color(1.00, 0.86, 0.78)}
		"attack_debuff":
			return {"bg": Color(0.22, 0.10, 0.18), "border": Color(0.92, 0.38, 0.66), "font": Color(1.00, 0.84, 0.94)}
		"block", "block_buff":
			return {"bg": Color(0.10, 0.19, 0.17), "border": Color(0.40, 0.78, 0.62), "font": Color(0.84, 1.00, 0.92)}
		"debuff", "status_card":
			return {"bg": Color(0.18, 0.13, 0.24), "border": Color(0.70, 0.48, 0.92), "font": Color(0.94, 0.86, 1.00)}
		"buff":
			return {"bg": Color(0.21, 0.17, 0.09), "border": Color(0.90, 0.66, 0.28), "font": Color(1.00, 0.94, 0.78)}
		_:
			return {"bg": Color(0.15, 0.16, 0.18), "border": Color(0.52, 0.56, 0.60), "font": Color(0.90, 0.92, 0.92)}

func _refresh_hand() -> void:
	_clear_container(hand_row)
	hand_buttons_by_index.clear()
	last_hand_card_layout_count = 0
	last_hand_card_art_node_count = 0
	last_hand_card_cost_texts.clear()
	last_hand_card_type_texts.clear()
	last_hand_card_name_texts.clear()
	last_hand_card_rarity_texts.clear()
	if combat.phase == "won" or combat.phase == "lost":
		return

	for i in range(combat.hand.size()):
		var card: Dictionary = combat.hand[i]
		var button := Button.new()
		button.custom_minimum_size = _hand_card_size()
		button.text = ""
		button.tooltip_text = "%s [%d]\n%s\n%s" % [
			card.get("name", "卡牌"),
			int(card.get("cost", 0)),
			card.get("type", ""),
			card.get("description", "")
		]
		last_hand_card_art_path = _card_art_path(card)
		last_hand_card_art_loaded = _asset_loaded(last_hand_card_art_path)
		var card_texture: Texture2D = _load_texture(last_hand_card_art_path)
		button.add_theme_stylebox_override("normal", _card_button_style(str(card.get("type", "")), false, false))
		button.add_theme_stylebox_override("hover", _card_button_style(str(card.get("type", "")), true, false))
		button.add_theme_stylebox_override("pressed", _card_button_style(str(card.get("type", "")), true, true))
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.13, 0.13, 0.15), Color(0.34, 0.34, 0.38)))
		button.disabled = not combat.can_play_card(i)
		_add_structured_card_layout(button, card, card_texture, "hand")
		button.mouse_entered.connect(_on_card_previewed.bind(i))
		button.focus_entered.connect(_on_card_previewed.bind(i))
		button.pressed.connect(_on_card_pressed.bind(i))
		hand_row.add_child(button)
		hand_buttons_by_index[i] = button

func _add_structured_card_layout(button: Button, card: Dictionary, card_texture: Texture2D, telemetry_bucket: String) -> void:
	var card_type: String = str(card.get("type", ""))
	var card_name: String = str(card.get("name", "卡牌"))
	var cost_text: String = str(int(card.get("cost", 0)))
	var type_text: String = _card_type_display_name(card_type)
	var rarity_text: String = _rarity_display_name(str(card.get("rarity", "common")))
	var visible_type_text: String = type_text
	if not rarity_text.is_empty():
		visible_type_text = "%s · %s" % [type_text, rarity_text]
	var compact: bool = telemetry_bucket == "hand" or button.custom_minimum_size.y < 178.0
	var ultra_compact: bool = compact and button.custom_minimum_size.y <= 112.0
	var margin_x: float = 5.0 if ultra_compact else (6.0 if compact else 8.0)
	var margin_y: float = 3.0 if ultra_compact else (4.0 if compact else 7.0)
	var top_height: float = 20.0 if compact else 26.0
	var cost_size := Vector2(24, 20) if compact else Vector2(30, 26)
	var name_font_size: int = 10 if compact else 13
	var cost_font_size: int = 12 if compact else 16
	var art_height: float = 30.0 if ultra_compact else (36.0 if compact else 60.0)
	var type_font_size: int = 8 if compact else 11
	var desc_height: float = 20.0 if ultra_compact else (28.0 if compact else 58.0)
	var desc_font_size: int = 7 if ultra_compact else (8 if compact else 10)
	var child_gap: int = 2 if compact else 4

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = margin_x
	root.offset_top = margin_y
	root.offset_right = -margin_x
	root.offset_bottom = -margin_y
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", child_gap)
	root.add_child(box)

	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.custom_minimum_size = Vector2(0, top_height)
	top_row.add_theme_constant_override("separation", 4 if compact else 5)
	box.add_child(top_row)

	var cost_panel := PanelContainer.new()
	cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_panel.custom_minimum_size = cost_size
	cost_panel.add_theme_stylebox_override("panel", _hand_card_cost_style(card_type))
	top_row.add_child(cost_panel)

	var cost_label := Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = cost_text
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", cost_font_size)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	cost_panel.add_child(cost_label)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", name_font_size)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.88))
	top_row.add_child(name_label)

	var art_frame := PanelContainer.new()
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.custom_minimum_size = Vector2(0, art_height)
	art_frame.add_theme_stylebox_override("panel", _hand_card_art_frame_style(card_type))
	box.add_child(art_frame)

	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(0, art_height)
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = card_texture
	art_frame.add_child(art)

	var type_label := Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.text = visible_type_text
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.custom_minimum_size = Vector2(0, 10 if compact else 0)
	type_label.clip_text = true
	type_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	type_label.add_theme_font_size_override("font_size", type_font_size)
	type_label.add_theme_color_override("font_color", _hand_card_type_color(card_type))
	box.add_child(type_label)

	var desc_panel := PanelContainer.new()
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.custom_minimum_size = Vector2(0, desc_height)
	desc_panel.add_theme_stylebox_override("panel", _hand_card_description_style(card_type))
	box.add_child(desc_panel)

	var desc := Label.new()
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.text = str(card.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.add_theme_font_size_override("font_size", desc_font_size)
	desc.add_theme_color_override("font_color", Color(0.88, 0.90, 0.88))
	desc_panel.add_child(desc)

	_record_structured_card_layout(telemetry_bucket, card_texture != null, cost_text, type_text, card_name, rarity_text)

func _record_structured_card_layout(telemetry_bucket: String, art_loaded: bool, cost_text: String, type_text: String, card_name: String, rarity_text: String) -> void:
	match telemetry_bucket:
		"hand":
			last_hand_card_layout_count += 1
			if art_loaded:
				last_hand_card_art_node_count += 1
			last_hand_card_cost_texts.append(cost_text)
			last_hand_card_type_texts.append(type_text)
			last_hand_card_name_texts.append(card_name)
			last_hand_card_rarity_texts.append(rarity_text)
		"reward":
			last_reward_card_layout_count += 1
			if art_loaded:
				last_reward_card_art_node_count += 1
		"shop":
			last_shop_card_layout_count += 1
			if art_loaded:
				last_shop_card_art_node_count += 1
		"campfire":
			last_campfire_card_layout_count += 1
			if art_loaded:
				last_campfire_card_art_node_count += 1
		"deck_view":
			last_deck_view_card_layout_count += 1
			if art_loaded:
				last_deck_view_card_art_node_count += 1

func _add_icon_item_layout(button: Button, title: String, subtitle: String, description: String, icon_texture: Texture2D, skin: String, telemetry_bucket: String, compact: bool) -> void:
	var margin := 6
	if compact and button.custom_minimum_size.x < 48.0:
		margin = 2
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = margin
	root.offset_top = 5
	root.offset_right = -margin
	root.offset_bottom = -5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	if compact:
		if button.custom_minimum_size.x < 72.0:
			var icon_size: float = clamp(button.custom_minimum_size.x - float(margin * 2), 22.0, 34.0)
			var center := CenterContainer.new()
			center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(center)
			center.add_child(_icon_item_frame(icon_texture, skin, Vector2(icon_size, icon_size)))
			_record_icon_item_layout(telemetry_bucket, icon_texture != null)
			return
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		root.add_child(row)
		var icon_frame := _icon_item_frame(icon_texture, skin, Vector2(34, 34))
		row.add_child(icon_frame)
		var text_box := VBoxContainer.new()
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_box)
		text_box.add_child(_icon_item_label(title, 11, Color(0.95, 0.96, 0.90), HORIZONTAL_ALIGNMENT_LEFT))
		text_box.add_child(_icon_item_label(subtitle, 10, _icon_item_accent_color(skin), HORIZONTAL_ALIGNMENT_LEFT))
	else:
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 4)
		root.add_child(box)
		box.add_child(_icon_item_label(title, 13, Color(0.95, 0.96, 0.90), HORIZONTAL_ALIGNMENT_CENTER))
		box.add_child(_icon_item_frame(icon_texture, skin, Vector2(0, 42)))
		box.add_child(_icon_item_label(subtitle, 11, _icon_item_accent_color(skin), HORIZONTAL_ALIGNMENT_CENTER))
		var desc := _icon_item_label(description, 10, Color(0.82, 0.86, 0.84), HORIZONTAL_ALIGNMENT_CENTER)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(desc)
	_record_icon_item_layout(telemetry_bucket, icon_texture != null)

func _icon_item_frame(icon_texture: Texture2D, skin: String, min_size: Vector2) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = min_size
	frame.add_theme_stylebox_override("panel", _icon_item_frame_style(skin))
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = min_size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = icon_texture
	frame.add_child(icon)
	return frame

func _icon_item_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _icon_item_frame_style(skin: String) -> StyleBoxFlat:
	var palette: Dictionary = _button_skin_palette(skin)
	return _button_style(
		palette.get("bg", Color(0.16, 0.17, 0.18)).darkened(0.16),
		palette.get("border", Color(0.46, 0.50, 0.52)).lightened(0.08),
		1,
		6
	)

func _icon_item_accent_color(skin: String) -> Color:
	var palette: Dictionary = _button_skin_palette(skin)
	return palette.get("border", Color(0.72, 0.76, 0.78)).lightened(0.16)

func _record_icon_item_layout(telemetry_bucket: String, icon_loaded: bool) -> void:
	match telemetry_bucket:
		"potion_slot":
			last_potion_slot_layout_count += 1
			if icon_loaded:
				last_potion_slot_icon_node_count += 1
		"shop_potion":
			last_shop_potion_layout_count += 1
			if icon_loaded:
				last_shop_potion_icon_node_count += 1
		"reward_potion":
			last_reward_potion_layout_count += 1
			if icon_loaded:
				last_reward_potion_icon_node_count += 1
		"reward_relic":
			last_reward_relic_layout_count += 1
			if icon_loaded:
				last_reward_relic_icon_node_count += 1

func _refresh_log() -> void:
	var lines: Array = combat.log_entries.slice(max(0, combat.log_entries.size() - 16), combat.log_entries.size())
	log_label.text = "\n".join(lines)

func _refresh_feedback() -> void:
	if combat == null:
		return
	var events: Array = combat.consume_feedback_events()
	if events.is_empty():
		return
	last_feedback_events = events
	var event: Dictionary = _primary_feedback_event(events)
	_apply_feedback_effects(events, event)
	var message: String = str(event.get("message", ""))
	if message.is_empty():
		return
	var event_type: String = str(event.get("type", ""))
	feedback_label.text = message
	feedback_label.visible = true
	var feedback_height: float = round((36.0 if _is_strong_feedback(event_type) else 28.0) * _combat_layout_scale())
	feedback_label.custom_minimum_size = Vector2(0, feedback_height)
	feedback_label.add_theme_font_size_override("font_size", _feedback_font_size(event_type))
	feedback_label.add_theme_stylebox_override("normal", _feedback_style(str(event.get("severity", "info"))))
	feedback_label.modulate = Color(1, 1, 1, 1)
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		var tween := create_tween()
		feedback_label.scale = Vector2(1.10, 1.10) if _is_strong_feedback(event_type) else Vector2(1.04, 1.04)
		tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.14)
		tween.parallel().tween_property(feedback_label, "modulate", Color(1, 1, 1, 0.88), 0.46)

func _apply_feedback_effects(events: Array, primary_event: Dictionary) -> void:
	last_flash_target_id = ""
	last_feedback_visual_type = str(primary_event.get("type", ""))
	last_feedback_audio_event = _feedback_audio_event(last_feedback_visual_type)
	last_hit_stop_duration = 0.0
	last_screen_shake_intensity = 0.0
	last_floating_text_count = 0
	last_impact_effect_type = ""
	last_impact_effect_count = 0
	last_impact_vfx_profile = ""
	last_impact_vfx_asset_path = ""
	last_impact_vfx_asset_loaded = false
	last_impact_ray_count = 0
	last_phase_animation_target_id = ""
	if not last_feedback_audio_event.is_empty():
		_audio_event(last_feedback_audio_event)

	for event in events:
		var event_dict: Dictionary = event
		var event_type: String = str(event_dict.get("type", ""))
		match str(event_dict.get("type", "")):
			"enemy_hit", "enemy_defeated", "phase":
				var target_id: String = str(event_dict.get("target_id", ""))
				if not target_id.is_empty():
					last_flash_target_id = target_id
					_flash_enemy_target(target_id, str(event_dict.get("severity", "hit")))
			"player_hit":
				last_flash_target_id = "player"
				_flash_player_target(true)
			"block", "heal":
				last_flash_target_id = "player"
				_flash_player_target(false)
			"won", "lost":
				last_flash_target_id = str(event_dict.get("target_id", ""))

		if _feedback_spawns_float(event_type):
			_spawn_floating_feedback(event_dict)
		if _feedback_spawns_impact(event_type):
			_spawn_impact_effect(event_dict)
		var stop_duration: float = _feedback_hit_stop_duration(event_dict)
		if stop_duration > 0.0:
			_request_hit_stop(stop_duration)
		var shake_intensity: float = _feedback_shake_intensity(event_dict)
		if shake_intensity > 0.0:
			_request_screen_shake(shake_intensity, _feedback_shake_duration(event_dict))
		if _is_cinematic_feedback(event_type):
			_show_cinematic_prompt(event_dict)
		if event_type == "phase":
			_play_phase_character_animation(str(event_dict.get("target_id", "")))

func _feedback_audio_event(event_type: String) -> String:
	match event_type:
		"enemy_hit", "enemy_defeated", "player_hit":
			return "hit"
		"block":
			return "block"
		"heal":
			return "heal"
		"phase":
			return "phase"
		"won":
			return "victory"
		"lost":
			return "defeat"
		"potion":
			return "potion"
		_:
			return ""

func _is_cinematic_feedback(event_type: String) -> bool:
	return event_type == "phase" or event_type == "won" or event_type == "lost"

func _show_cinematic_prompt(event: Dictionary) -> void:
	var event_type: String = str(event.get("type", ""))
	last_cinematic_event_type = event_type
	last_cinematic_title = _cinematic_title(event)
	last_cinematic_subtitle = _cinematic_subtitle(event)
	if cinematic_overlay == null or cinematic_panel == null or cinematic_title_label == null or cinematic_subtitle_label == null:
		return
	cinematic_overlay.visible = true
	cinematic_overlay.modulate = Color(1, 1, 1, 1)
	cinematic_panel.custom_minimum_size = _cinematic_panel_size()
	cinematic_panel.add_theme_stylebox_override("panel", _cinematic_style(event_type))
	cinematic_title_label.text = last_cinematic_title
	cinematic_subtitle_label.text = last_cinematic_subtitle
	cinematic_title_label.add_theme_color_override("font_color", _cinematic_title_color(event_type))
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	cinematic_panel.scale = Vector2(1.08, 1.08)
	var tween := create_tween()
	tween.tween_property(cinematic_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(_cinematic_hold_duration(event_type))
	tween.tween_property(cinematic_overlay, "modulate", Color(1, 1, 1, 0), 0.22)
	tween.tween_callback(Callable(self, "_hide_cinematic_prompt"))

func _hide_cinematic_prompt() -> void:
	if cinematic_overlay != null:
		cinematic_overlay.visible = false
		cinematic_overlay.modulate = Color(1, 1, 1, 1)
	if cinematic_panel != null:
		cinematic_panel.scale = Vector2.ONE

func _cinematic_title(event: Dictionary) -> String:
	match str(event.get("type", "")):
		"phase":
			return "BOSS 阶段变更"
		"won":
			return "战斗胜利"
		"lost":
			return "战败"
		_:
			return str(event.get("message", ""))

func _cinematic_subtitle(event: Dictionary) -> String:
	var message: String = str(event.get("message", ""))
	match str(event.get("type", "")):
		"phase":
			return message
		"won":
			return "选择奖励，继续推进这条路线。"
		"lost":
			return "这次构筑已经终止，重开后重新规划牌组节奏。"
		_:
			return message

func _cinematic_title_color(event_type: String) -> Color:
	match event_type:
		"won":
			return Color(0.62, 1.0, 0.66)
		"lost":
			return Color(1.0, 0.42, 0.36)
		_:
			return Color(1.0, 0.86, 0.45)

func _cinematic_hold_duration(event_type: String) -> float:
	return 0.92 if event_type == "phase" else 1.15

func _flash_enemy_target(target_id: String, severity: String) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var visual: Dictionary = enemy_visuals_by_id.get(target_id, {})
	if visual.is_empty():
		return
	var button := visual.get("button") as Control
	var art := visual.get("art") as CanvasItem
	var flash_color := Color(1.0, 0.72, 0.36, 1.0)
	if severity == "success":
		flash_color = Color(0.55, 1.0, 0.62, 1.0)
	elif severity == "phase":
		flash_color = Color(0.92, 0.58, 1.0, 1.0)
	if button != null:
		var tween := create_tween()
		button.modulate = flash_color
		button.scale = Vector2(1.04, 1.04)
		tween.tween_property(button, "modulate", Color.WHITE, 0.18)
		tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.18)
	if art != null:
		var art_tween := create_tween()
		art.modulate = flash_color
		art_tween.tween_property(art, "modulate", Color.WHITE, 0.22)

func _flash_player_target(danger: bool) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var flash_color := Color(1.0, 0.36, 0.30, 1.0) if danger else Color(0.48, 0.78, 1.0, 1.0)
	var target: Control = character_frame if character_frame != null and character_frame.visible else status_label
	var tween := create_tween()
	target.modulate = flash_color
	target.scale = Vector2(1.02, 1.02)
	tween.tween_property(target, "modulate", Color.WHITE, 0.20)
	tween.parallel().tween_property(target, "scale", Vector2.ONE, 0.20)

func _feedback_spawns_float(event_type: String) -> bool:
	return ["enemy_hit", "player_hit", "block", "heal", "enemy_defeated", "phase", "won", "lost"].has(event_type)

func _feedback_spawns_impact(event_type: String) -> bool:
	return ["enemy_hit", "player_hit", "enemy_defeated", "phase"].has(event_type)

func _on_card_previewed(index: int) -> void:
	if combat == null or combat.phase != "player" or index < 0 or index >= combat.hand.size():
		return
	if not combat.can_play_card(index):
		return
	var target_index: int = _normalize_selected_enemy()
	var card: Dictionary = combat.hand[index]
	var payload: Dictionary = _build_card_visual_payload(index, card, target_index)
	last_card_preview_index = index
	last_card_preview_card_id = str(card.get("id", ""))
	last_card_preview_target_id = str(payload.get("target_id", ""))
	_request_card_target_line(payload, false)

func _build_card_visual_payload(hand_index: int, card: Dictionary, target_index: int) -> Dictionary:
	var target_id: String = _card_visual_target_id(card, target_index)
	var start: Vector2 = _card_source_position(hand_index)
	var end: Vector2 = _card_target_position(target_id, target_index)
	var mid: Vector2 = (start + end) * 0.5 + Vector2(0, -72)
	return {
		"hand_index": hand_index,
		"card_id": str(card.get("id", "")),
		"card_name": str(card.get("name", "卡牌")),
		"card_type": str(card.get("type", "")),
		"target_id": target_id,
		"target_index": target_index,
		"points": [start, mid, end]
	}

func _card_visual_target_id(card: Dictionary, target_index: int) -> String:
	if _card_targets_all_enemies(card):
		return "all_enemies"
	if _card_targets_enemy(card):
		if combat != null and target_index >= 0 and target_index < combat.enemies.size():
			return str(combat.enemies[target_index].get("id", "enemy"))
		return "enemy"
	return "player"

func _card_targets_all_enemies(card: Dictionary) -> bool:
	if str(card.get("target", "")) == "all_enemies":
		return true
	for effect in card.get("effects", []):
		var effect_dict: Dictionary = effect
		if str(effect_dict.get("target", "")) == "all_enemies":
			return true
	return false

func _card_targets_enemy(card: Dictionary) -> bool:
	for effect in card.get("effects", []):
		var effect_dict: Dictionary = effect
		var effect_type: String = str(effect_dict.get("type", ""))
		if effect_type != "damage" and effect_type != "apply_status":
			continue
		var target: String = str(effect_dict.get("target", card.get("target", "enemy")))
		if target != "self" and target != "player" and target != "all_enemies":
			return true
	return false

func _card_source_position(hand_index: int) -> Vector2:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return Vector2(128 + hand_index * 158, 560)
	var button := hand_buttons_by_index.get(hand_index, null) as Control
	if button != null:
		return _control_center(button)
	return Vector2(128 + hand_index * 158, 560)

func _card_target_position(target_id: String, target_index: int) -> Vector2:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		if target_id == "player":
			return Vector2(320, 126)
		if target_id == "all_enemies":
			return Vector2(650, 214)
		return Vector2(560 + max(target_index, 0) * 216, 214)
	if target_id == "player":
		return _control_center(status_label)
	if target_id == "all_enemies":
		return _alive_enemy_group_center()
	var visual: Dictionary = _enemy_visual_for_index(target_index)
	if not visual.is_empty():
		var control := visual.get("button") as Control
		if control != null:
			return _control_center(control)
	return _feedback_target_position({"target_id": target_id})

func _alive_enemy_group_center() -> Vector2:
	var points: Array[Vector2] = []
	if combat != null:
		for i in range(combat.enemies.size()):
			if int(combat.enemies[i].get("hp", 0)) <= 0:
				continue
			var visual: Dictionary = _enemy_visual_for_index(i)
			var control := visual.get("button") as Control
			if control != null:
				points.append(_control_center(control))
	if points.is_empty():
		return _control_center(enemy_row)
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())

func _enemy_visual_for_index(enemy_index: int) -> Dictionary:
	if combat == null or enemy_index < 0 or enemy_index >= combat.enemies.size():
		return {}
	var enemy: Dictionary = combat.enemies[enemy_index]
	var indexed_key := "%s:%d" % [str(enemy.get("id", "")), enemy_index]
	return enemy_visuals_by_id.get(indexed_key, enemy_visuals_by_id.get(str(enemy.get("id", "")), {}))

func _request_card_target_line(payload: Dictionary, persistent: bool) -> void:
	last_card_target_line_count += 1
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null:
		return
	var points: Array = payload.get("points", [])
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[points.size() - 1]
	var delta: Vector2 = end - start
	var length: float = max(delta.length(), 1.0)
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = _card_visual_color(str(payload.get("card_type", "")))
	line.size = Vector2(length, 4.0 if persistent else 3.0)
	line.pivot_offset = Vector2(0, line.size.y * 0.5)
	line.position = start - Vector2(0, line.size.y * 0.5)
	line.rotation = delta.angle()
	line.modulate = Color(1, 1, 1, 0.62 if persistent else 0.44)
	feedback_overlay.add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate", Color(1, 1, 1, 0), 0.22 if persistent else 0.16)
	tween.tween_callback(Callable(line, "queue_free"))

func _request_card_play_visual(payload: Dictionary) -> void:
	var points: Array = payload.get("points", [])
	var profile: String = _card_effect_profile(str(payload.get("card_type", "")))
	last_card_play_animation_count += 1
	last_card_play_card_id = str(payload.get("card_id", ""))
	last_card_play_target_id = str(payload.get("target_id", ""))
	last_card_effect_profile = profile
	last_card_particle_count = _card_particle_count(profile)
	last_card_audio_event = _card_audio_event(profile)
	var profile_data: Dictionary = _vfx_profile(profile)
	last_card_vfx_asset_path = _vfx_sprite_path(profile_data)
	last_card_vfx_asset_loaded = _asset_loaded(last_card_vfx_asset_path)
	last_card_play_trajectory_points.clear()
	for point in points:
		last_card_play_trajectory_points.append(point)
	_request_card_target_line(payload, true)
	_audio_event(last_card_audio_event)
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null or points.size() < 3:
		return
	var ghost := PanelContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.custom_minimum_size = Vector2(118, 72)
	ghost.size = ghost.custom_minimum_size
	ghost.pivot_offset = ghost.custom_minimum_size * 0.5
	ghost.add_theme_stylebox_override("panel", _card_flight_style(str(payload.get("card_type", ""))))
	var label := Label.new()
	label.text = str(payload.get("card_name", "卡牌"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.94))
	ghost.add_child(label)
	feedback_overlay.add_child(ghost)
	ghost.position = (points[0] as Vector2) - ghost.custom_minimum_size * 0.5
	ghost.scale = Vector2(0.90, 0.90)
	var tween := create_tween()
	tween.tween_method(Callable(self, "_update_card_flight_position").bind(ghost, points, ghost.custom_minimum_size), 0.0, 1.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.52, 0.52), 0.34)
	tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0.16), 0.34)
	tween.tween_callback(Callable(self, "_spawn_card_resolution_effect").bind(payload))
	tween.tween_callback(Callable(ghost, "queue_free"))

func _update_card_flight_position(progress: float, ghost: Control, points: Array, ghost_size: Vector2) -> void:
	if ghost == null or points.size() < 3:
		return
	var position: Vector2 = _quadratic_bezier(points[0], points[1], points[2], progress)
	ghost.position = position - ghost_size * 0.5
	ghost.rotation = lerp(-0.10, 0.10, progress)

func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab: Vector2 = a.lerp(b, t)
	var bc: Vector2 = b.lerp(c, t)
	return ab.lerp(bc, t)

func _card_visual_color(card_type: String) -> Color:
	return _vfx_profile_color(_vfx_profile(_card_effect_profile(card_type)))

func _card_flight_style(card_type: String) -> StyleBoxFlat:
	var base: Color = _card_visual_color(card_type).darkened(0.55)
	var border: Color = _card_visual_color(card_type)
	return _button_style(base, border, 2, 8)

func _card_effect_profile(card_type: String) -> String:
	var mappings: Dictionary = vfx_data.get("card_type_profiles", {})
	var mapped: String = str(mappings.get(card_type, ""))
	if not mapped.is_empty():
		return mapped
	var default_profile: String = str(mappings.get("default", ""))
	if not default_profile.is_empty():
		return default_profile
	match card_type:
		"attack":
			return "attack_slash"
		"skill":
			return "skill_guard"
		"power":
			return "power_pulse"
		_:
			return "card_default"

func _card_audio_event(profile: String) -> String:
	var profile_data: Dictionary = _vfx_profile(profile)
	var audio_event: String = str(profile_data.get("audio_event", ""))
	if not audio_event.is_empty():
		return audio_event
	match profile:
		"attack_slash":
			return "card_attack"
		"skill_guard":
			return "card_skill"
		"power_pulse":
			return "card_power"
		_:
			return "card_play"

func _card_particle_count(profile: String) -> int:
	var profile_data: Dictionary = _vfx_profile(profile)
	var configured_count: int = int(profile_data.get("particle_count", 0))
	if configured_count > 0:
		return configured_count
	match profile:
		"attack_slash":
			return 7
		"skill_guard":
			return 8
		"power_pulse":
			return 10
		_:
			return 4

func _vfx_profile(profile_id: String) -> Dictionary:
	for profile in vfx_data.get("profiles", []):
		var profile_dict: Dictionary = profile
		if str(profile_dict.get("id", "")) == profile_id:
			return profile_dict
	return {}

func _vfx_profile_color(profile: Dictionary) -> Color:
	var color_values: Array = profile.get("color", [])
	if color_values.size() >= 4:
		return Color(
			float(color_values[0]),
			float(color_values[1]),
			float(color_values[2]),
			float(color_values[3])
		)
	match str(profile.get("id", "")):
		"attack_slash":
			return Color(1.0, 0.42, 0.24, 1.0)
		"skill_guard":
			return Color(0.40, 0.78, 1.0, 1.0)
		"power_pulse":
			return Color(0.88, 0.62, 1.0, 1.0)
		_:
			return Color(0.86, 0.88, 0.92, 1.0)

func _spawn_card_resolution_effect(payload: Dictionary) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null:
		return
	var points: Array = payload.get("points", [])
	if points.is_empty():
		return
	var center: Vector2 = points[points.size() - 1]
	var profile: String = _card_effect_profile(str(payload.get("card_type", "")))
	var profile_data: Dictionary = _vfx_profile(profile)
	var color: Color = _vfx_profile_color(profile_data)
	_spawn_vfx_profile_sprite(center, profile_data, color)
	match profile:
		"attack_slash":
			_spawn_card_particle_line(center, Vector2(-28, -14), 86.0, 5.0, -0.55, color, 0.22)
			_spawn_card_particle_line(center, Vector2(18, 8), 72.0, 4.0, -0.55, color.lightened(0.18), 0.20)
			_spawn_card_particle_line(center, Vector2(-4, 22), 56.0, 3.0, -0.55, Color(1.0, 0.84, 0.52), 0.18)
			for i in range(4):
				var angle := -0.92 + float(i) * 0.42
				_spawn_card_particle_line(center, Vector2(cos(angle), sin(angle)) * 18.0, 26.0, 3.0, angle, color, 0.18)
		"skill_guard":
			_spawn_card_pulse(center, 72.0, color, 0.30)
			_spawn_card_pulse(center, 42.0, color.lightened(0.18), 0.24)
			for i in range(6):
				var angle := TAU * float(i) / 6.0
				_spawn_card_particle_line(center, Vector2(cos(angle), sin(angle)) * 34.0, 20.0, 3.0, angle, color, 0.22)
		"power_pulse":
			_spawn_card_pulse(center, 92.0, color, 0.36)
			_spawn_card_pulse(center, 58.0, color.lightened(0.16), 0.30)
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				_spawn_card_particle_line(center, Vector2(cos(angle), sin(angle)) * 44.0, 34.0, 4.0, angle, color, 0.28)
		_:
			_spawn_card_pulse(center, 52.0, color, 0.24)
			for i in range(3):
				var angle := TAU * float(i) / 3.0
				_spawn_card_particle_line(center, Vector2(cos(angle), sin(angle)) * 24.0, 24.0, 3.0, angle, color, 0.18)

func _vfx_sprite_path(profile: Dictionary) -> String:
	return str(profile.get("sprite_path", ""))

func _vfx_sprite_duration(profile: Dictionary) -> float:
	return max(0.05, float(profile.get("sprite_duration", 0.24)))

func _vfx_sprite_scale(profile: Dictionary) -> float:
	return max(0.1, float(profile.get("sprite_scale", 1.0)))

func _spawn_vfx_profile_sprite(center: Vector2, profile: Dictionary, fallback_color: Color) -> void:
	var sprite_path: String = _vfx_sprite_path(profile)
	if sprite_path.is_empty():
		return
	var texture := _load_texture(sprite_path)
	if texture == null:
		return
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = Vector2(128, 128) * _vfx_sprite_scale(profile)
	sprite.size = sprite.custom_minimum_size
	sprite.pivot_offset = sprite.size * 0.5
	sprite.position = center - sprite.pivot_offset
	sprite.modulate = Color(fallback_color.r, fallback_color.g, fallback_color.b, 0.88)
	feedback_overlay.add_child(sprite)
	var tween := create_tween()
	sprite.scale = Vector2(0.78, 0.78)
	var duration: float = _vfx_sprite_duration(profile)
	tween.tween_property(sprite, "scale", Vector2(1.18, 1.18), duration)
	tween.parallel().tween_property(sprite, "modulate", Color(fallback_color.r, fallback_color.g, fallback_color.b, 0), duration)
	tween.tween_callback(Callable(sprite, "queue_free"))

func _spawn_card_particle_line(center: Vector2, offset: Vector2, length: float, thickness: float, rotation: float, color: Color, duration: float) -> void:
	var particle := ColorRect.new()
	particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle.color = color
	particle.size = Vector2(length, thickness)
	particle.pivot_offset = particle.size * 0.5
	particle.position = center + offset - particle.pivot_offset
	particle.rotation = rotation
	particle.modulate = Color(1, 1, 1, 0.88)
	feedback_overlay.add_child(particle)
	var tween := create_tween()
	tween.tween_property(particle, "position", particle.position + Vector2(cos(rotation), sin(rotation)) * 18.0, duration)
	tween.parallel().tween_property(particle, "scale", Vector2(1.28, 0.32), duration)
	tween.parallel().tween_property(particle, "modulate", Color(1, 1, 1, 0), duration)
	tween.tween_callback(Callable(particle, "queue_free"))

func _spawn_card_pulse(center: Vector2, diameter: float, color: Color, duration: float) -> void:
	var pulse := PanelContainer.new()
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.custom_minimum_size = Vector2(diameter, diameter)
	pulse.size = pulse.custom_minimum_size
	pulse.pivot_offset = pulse.size * 0.5
	pulse.position = center - pulse.pivot_offset
	pulse.add_theme_stylebox_override("panel", _card_pulse_style(color))
	pulse.modulate = Color(1, 1, 1, 0.72)
	feedback_overlay.add_child(pulse)
	var tween := create_tween()
	pulse.scale = Vector2(0.72, 0.72)
	tween.tween_property(pulse, "scale", Vector2(1.22, 1.22), duration)
	tween.parallel().tween_property(pulse, "modulate", Color(1, 1, 1, 0), duration)
	tween.tween_callback(Callable(pulse, "queue_free"))

func _card_pulse_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.03)
	style.border_color = Color(color.r, color.g, color.b, 0.88)
	style.set_border_width_all(3)
	style.set_corner_radius_all(64)
	return style

func _spawn_impact_effect(event: Dictionary) -> void:
	var event_type: String = str(event.get("type", ""))
	last_impact_effect_type = event_type
	last_impact_effect_count += 1
	var profile_id: String = _feedback_vfx_profile(event_type)
	var profile_data: Dictionary = _vfx_profile(profile_id)
	last_impact_vfx_profile = profile_id
	last_impact_vfx_asset_path = _vfx_sprite_path(profile_data)
	last_impact_vfx_asset_loaded = _asset_loaded(last_impact_vfx_asset_path)
	var rays: int = _impact_ray_count(event_type)
	last_impact_ray_count = rays
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null:
		return
	var center: Vector2 = _feedback_target_position(event)
	var color: Color = _impact_effect_color(event)
	_spawn_vfx_profile_sprite(center, profile_data, color)
	var length: float = 70.0 if _is_strong_feedback(event_type) else 46.0
	if not profile_data.is_empty():
		length = float(profile_data.get("ray_length", length))
	var thickness: float = 5.0 if _is_strong_feedback(event_type) else 4.0
	for i in range(rays):
		var ray := ColorRect.new()
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ray.color = color
		ray.size = Vector2(length, thickness)
		ray.pivot_offset = ray.size * 0.5
		ray.position = center - ray.pivot_offset
		ray.rotation = TAU * float(i) / float(rays)
		ray.modulate = Color(1, 1, 1, 0.88)
		feedback_overlay.add_child(ray)
		var tween := create_tween()
		tween.tween_property(ray, "position", ray.position + Vector2(cos(ray.rotation), sin(ray.rotation)) * 22.0, 0.18)
		tween.parallel().tween_property(ray, "scale", Vector2(1.35, 0.35), 0.18)
		tween.parallel().tween_property(ray, "modulate", Color(1, 1, 1, 0), 0.18)
		tween.tween_callback(Callable(ray, "queue_free"))

func _feedback_vfx_profile(event_type: String) -> String:
	var mappings: Dictionary = vfx_data.get("feedback_event_profiles", {})
	var mapped: String = str(mappings.get(event_type, ""))
	if not mapped.is_empty():
		return mapped
	match event_type:
		"player_hit":
			return "impact_player_hit"
		"enemy_defeated":
			return "impact_enemy_defeated"
		"phase":
			return "impact_phase"
		_:
			return "impact_enemy_hit"

func _impact_effect_color(event: Dictionary) -> Color:
	var profile_data: Dictionary = _vfx_profile(_feedback_vfx_profile(str(event.get("type", ""))))
	if not profile_data.is_empty():
		return _vfx_profile_color(profile_data)
	match str(event.get("type", "")):
		"player_hit":
			return Color(1.0, 0.18, 0.12, 1.0)
		"enemy_defeated":
			return Color(0.62, 1.0, 0.50, 1.0)
		"phase":
			return Color(0.95, 0.48, 1.0, 1.0)
		_:
			return Color(1.0, 0.72, 0.26, 1.0)

func _impact_ray_count(event_type: String) -> int:
	var profile_data: Dictionary = _vfx_profile(_feedback_vfx_profile(event_type))
	var configured_count: int = int(profile_data.get("ray_count", 0))
	if configured_count > 0:
		return configured_count
	match event_type:
		"phase":
			return 12
		"enemy_defeated":
			return 9
		_:
			return 5

func _play_phase_character_animation(target_id: String) -> void:
	last_phase_animation_target_id = target_id
	if target_id.is_empty() or DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var visual: Dictionary = enemy_visuals_by_id.get(target_id, {})
	if visual.is_empty():
		return
	var art := visual.get("art") as Control
	var button := visual.get("button") as Control
	if art != null:
		art.pivot_offset = art.size * 0.5
		var art_tween := create_tween()
		art.scale = Vector2(1.16, 1.16)
		art.modulate = Color(1.0, 0.70, 1.0, 1.0)
		art_tween.tween_property(art, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		art_tween.parallel().tween_property(art, "modulate", Color.WHITE, 0.32)
	if button != null:
		button.pivot_offset = button.size * 0.5
		var button_tween := create_tween()
		button.scale = Vector2(1.08, 1.08)
		button_tween.tween_property(button, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _spawn_floating_feedback(event: Dictionary) -> void:
	if not _should_spawn_floating_feedback(event):
		return
	last_floating_text_count += 1
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null:
		return
	var label := Label.new()
	var event_type: String = str(event.get("type", ""))
	label.text = _floating_feedback_text(event)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28 if _is_strong_feedback(event_type) else 22)
	label.add_theme_color_override("font_color", _floating_feedback_color(event))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.custom_minimum_size = Vector2(160, 36)
	feedback_overlay.add_child(label)
	var origin: Vector2 = _feedback_target_position(event)
	var label_size: Vector2 = label.custom_minimum_size
	var start_position: Vector2 = _clamp_feedback_overlay_position(origin - label_size * 0.5, label_size)
	var end_position: Vector2 = _clamp_feedback_overlay_position(start_position + Vector2(0, -32), label_size)
	label.position = start_position
	var tween := create_tween()
	tween.tween_property(label, "position", end_position, 0.52).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.52)
	tween.tween_callback(Callable(label, "queue_free"))

func _should_spawn_floating_feedback(event: Dictionary) -> bool:
	if not _setting_enabled("floating_text_enabled", true):
		return false
	if _layout_viewport_size().x <= 480.0 and str(event.get("target_id", "")) == "player":
		return false
	return true

func _floating_feedback_text(event: Dictionary) -> String:
	var event_type: String = str(event.get("type", ""))
	var amount: int = int(event.get("amount", 0))
	match event_type:
		"enemy_hit", "player_hit":
			return "-%d" % amount
		"block":
			return "+%d 护甲" % amount
		"heal":
			return "+%d 生命" % amount
		"enemy_defeated":
			return "击破"
		"phase":
			return "阶段变更"
		"won":
			return "胜利"
		"lost":
			return "战败"
		_:
			return str(event.get("message", ""))

func _floating_feedback_color(event: Dictionary) -> Color:
	match str(event.get("severity", "info")):
		"danger":
			return Color(1.0, 0.34, 0.30)
		"hit":
			return Color(1.0, 0.72, 0.30)
		"success":
			return Color(0.48, 1.0, 0.58)
		"phase":
			return Color(0.95, 0.62, 1.0)
		_:
			return Color(0.70, 0.88, 1.0)

func _feedback_target_position(event: Dictionary) -> Vector2:
	var target_id: String = str(event.get("target_id", ""))
	if target_id == "player":
		if character_panel != null and character_panel.visible:
			return _control_center(character_panel)
		if player_portrait != null and player_portrait.visible:
			return _control_center(player_portrait)
	var visual: Dictionary = enemy_visuals_by_id.get(target_id, {})
	if not visual.is_empty():
		var control := visual.get("button") as Control
		if control != null:
			return _control_center(control)
	if feedback_label != null:
		return _control_center(feedback_label)
	return Vector2.ZERO

func _clamp_feedback_overlay_position(position: Vector2, label_size: Vector2) -> Vector2:
	if feedback_overlay == null:
		return position
	var overlay_size: Vector2 = feedback_overlay.size
	if overlay_size.x <= 1.0 or overlay_size.y <= 1.0:
		overlay_size = _layout_viewport_size()
	var padding := 8.0
	var top_limit: float = _feedback_overlay_safe_top()
	var max_x: float = max(padding, overlay_size.x - label_size.x - padding)
	var max_y: float = max(top_limit, overlay_size.y - label_size.y - padding)
	return Vector2(
		clamp(position.x, padding, max_x),
		clamp(position.y, top_limit, max_y)
	)

func _feedback_overlay_safe_top() -> float:
	var safe_top := 76.0
	if feedback_overlay == null or status_label == null:
		return safe_top
	var rect: Rect2 = status_label.get_global_rect()
	var overlay_transform: Transform2D = feedback_overlay.get_global_transform_with_canvas()
	var overlay_bottom: Vector2 = overlay_transform.affine_inverse() * Vector2(rect.position.x, rect.end.y)
	return max(safe_top, overlay_bottom.y + 8.0)

func _control_center(control: Control) -> Vector2:
	if control == null:
		return Vector2.ZERO
	var rect: Rect2 = control.get_global_rect()
	if feedback_overlay != null:
		var overlay_transform: Transform2D = feedback_overlay.get_global_transform_with_canvas()
		return overlay_transform.affine_inverse() * (rect.position + rect.size * 0.5)
	return rect.position + rect.size * 0.5

func _feedback_hit_stop_duration(event: Dictionary) -> float:
	match str(event.get("type", "")):
		"enemy_hit", "player_hit":
			return clamp(0.035 + float(int(event.get("amount", 0))) * 0.0015, 0.04, 0.09)
		"enemy_defeated":
			return 0.10
		"phase":
			return 0.12
		"won", "lost":
			return 0.14
		_:
			return 0.0

func _feedback_shake_intensity(event: Dictionary) -> float:
	match str(event.get("type", "")):
		"enemy_hit":
			return clamp(2.0 + float(int(event.get("amount", 0))) * 0.16, 2.0, 7.0)
		"player_hit":
			return clamp(4.0 + float(int(event.get("amount", 0))) * 0.22, 4.0, 11.0)
		"enemy_defeated":
			return 7.0
		"phase":
			return 10.0
		"won", "lost":
			return 12.0
		_:
			return 0.0

func _feedback_shake_duration(event: Dictionary) -> float:
	return 0.30 if _is_strong_feedback(str(event.get("type", ""))) else 0.18

func _request_hit_stop(duration: float) -> void:
	if not _setting_enabled("hit_stop_enabled", true):
		return
	last_hit_stop_duration = max(last_hit_stop_duration, duration)
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	hit_stop_ticket += 1
	_play_hit_stop(duration, hit_stop_ticket, Engine.time_scale)

func _play_hit_stop(duration: float, ticket: int, restore_scale: float) -> void:
	Engine.time_scale = min(restore_scale, 0.08)
	await get_tree().create_timer(duration, true, false, true).timeout
	if ticket == hit_stop_ticket:
		Engine.time_scale = restore_scale

func _request_screen_shake(intensity: float, duration: float) -> void:
	if not _setting_enabled("screen_shake_enabled", true):
		return
	last_screen_shake_intensity = max(last_screen_shake_intensity, intensity)
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or root_box == null:
		return
	var base_position: Vector2 = root_box.position
	var step: float = duration / 4.0
	var tween := create_tween()
	tween.tween_property(root_box, "position", base_position + Vector2(intensity, -intensity * 0.45), step)
	tween.tween_property(root_box, "position", base_position + Vector2(-intensity * 0.80, intensity * 0.55), step)
	tween.tween_property(root_box, "position", base_position + Vector2(intensity * 0.35, intensity * 0.35), step)
	tween.tween_property(root_box, "position", base_position, step)

func _primary_feedback_event(events: Array) -> Dictionary:
	var priority := {
		"lost": 100,
		"won": 95,
		"phase": 90,
		"enemy_defeated": 80,
		"player_hit": 70,
		"enemy_hit": 60,
		"heal": 55,
		"potion": 50,
		"block": 40
	}
	var selected: Dictionary = {}
	var selected_score := -1
	for event in events:
		var event_dict: Dictionary = event
		var score: int = int(priority.get(str(event_dict.get("type", "")), 0))
		if score >= selected_score:
			selected = event_dict
			selected_score = score
	return selected

func _refresh_rewards() -> void:
	last_reward_button_style_count = 0
	last_reward_card_layout_count = 0
	last_reward_card_art_node_count = 0
	last_reward_potion_layout_count = 0
	last_reward_potion_icon_node_count = 0
	last_reward_relic_layout_count = 0
	last_reward_relic_icon_node_count = 0
	_clear_container(reward_row)
	if combat.phase == "lost":
		var lost_label := Label.new()
		lost_label.text = "战败。点击“重开跑团”重新开始。"
		lost_label.add_theme_font_size_override("font_size", 18)
		reward_row.add_child(lost_label)
		return
	if combat.phase != "won":
		return

	var node: Dictionary = _current_node()
	var encounter_id: String = str(node.get("encounter_id", ""))
	if reward_generated_for != encounter_id:
		_grant_encounter_gold(encounter_id)
		reward_options = _generate_card_rewards(3)
		var encounter: Dictionary = _encounter_by_id(encounter_id)
		if bool(encounter.get("relic_reward", false)):
			relic_reward_options = _generate_relic_rewards(3)
			relic_reward_done = relic_reward_options.is_empty()
		else:
			relic_reward_options.clear()
			relic_reward_done = true
		if _has_empty_potion_slot():
			potion_reward_options = _generate_potion_rewards(_potion_reward_count())
			potion_reward_done = potion_reward_options.is_empty()
		else:
			potion_reward_options.clear()
			potion_reward_done = true
		var discovery_changed: bool = _record_discovered_item_array("cards", reward_options)
		discovery_changed = _record_discovered_item_array("relics", relic_reward_options) or discovery_changed
		discovery_changed = _record_discovered_item_array("potions", potion_reward_options) or discovery_changed
		if discovery_changed:
			_save_player_profile()
		card_reward_done = reward_options.is_empty()
		reward_generated_for = encounter_id

	var label := Label.new()
	label.text = "战斗胜利，选择奖励："
	label.custom_minimum_size = Vector2(180, 0)
	reward_row.add_child(label)

	if not card_reward_done:
		for card in reward_options:
			var card_dict: Dictionary = card
			var button := Button.new()
			button.custom_minimum_size = _large_card_button_size()
			button.text = ""
			button.tooltip_text = "选择 %s [%d]\n%s" % [card_dict.get("name", "卡牌"), int(card_dict.get("cost", 0)), card_dict.get("description", "")]
			last_reward_card_art_path = _card_art_path(card_dict)
			last_reward_card_art_loaded = _asset_loaded(last_reward_card_art_path)
			var card_texture: Texture2D = _load_texture(last_reward_card_art_path)
			_apply_card_button_skin(button, str(card_dict.get("type", "")), "reward")
			_add_structured_card_layout(button, card_dict, card_texture, "reward")
			button.pressed.connect(_on_reward_card_pressed.bind(str(card_dict.get("id", ""))))
			reward_row.add_child(button)

		var skip_button := Button.new()
		skip_button.custom_minimum_size = _small_action_button_size()
		skip_button.text = "跳过卡牌"
		_apply_button_skin(skip_button, "neutral", "reward")
		skip_button.pressed.connect(_on_skip_card_reward_pressed)
		reward_row.add_child(skip_button)
	else:
		var card_done_label := Label.new()
		card_done_label.text = "卡牌奖励已处理。"
		card_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(card_done_label)

	if not relic_reward_done:
		for relic in relic_reward_options:
			var relic_dict: Dictionary = relic
			var relic_button := Button.new()
			relic_button.custom_minimum_size = _large_item_button_size()
			relic_button.text = ""
			relic_button.tooltip_text = "遗物：%s\n%s" % [relic_dict.get("name", "遗物"), relic_dict.get("description", "")]
			last_relic_icon_path = _relic_icon_path(relic_dict)
			last_relic_icon_loaded = _asset_loaded(last_relic_icon_path)
			var relic_texture: Texture2D = _load_texture(last_relic_icon_path)
			_apply_button_skin(relic_button, "relic", "reward")
			_add_icon_item_layout(
				relic_button,
				str(relic_dict.get("name", "遗物")),
				"遗物",
				str(relic_dict.get("description", "")),
				relic_texture,
				"relic",
				"reward_relic",
				false
			)
			relic_button.pressed.connect(_on_reward_relic_pressed.bind(str(relic_dict.get("id", ""))))
			reward_row.add_child(relic_button)
	elif not relic_reward_options.is_empty():
		var relic_done_label := Label.new()
		relic_done_label.text = "遗物奖励已处理。"
		relic_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(relic_done_label)

	if not potion_reward_done:
		for potion in potion_reward_options:
			var potion_dict: Dictionary = potion
			var potion_button := Button.new()
			potion_button.custom_minimum_size = _large_item_button_size()
			potion_button.text = ""
			potion_button.tooltip_text = "药水：%s\n%s" % [potion_dict.get("name", "药水"), potion_dict.get("description", "")]
			last_potion_icon_path = _potion_icon_path(potion_dict)
			last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
			var potion_texture: Texture2D = _load_texture(last_potion_icon_path)
			_apply_button_skin(potion_button, "potion", "reward")
			_add_icon_item_layout(
				potion_button,
				str(potion_dict.get("name", "药水")),
				"药水",
				str(potion_dict.get("description", "")),
				potion_texture,
				"potion",
				"reward_potion",
				false
			)
			potion_button.pressed.connect(_on_reward_potion_pressed.bind(str(potion_dict.get("id", ""))))
			reward_row.add_child(potion_button)

		var skip_potion_button := Button.new()
		skip_potion_button.custom_minimum_size = _small_action_button_size()
		skip_potion_button.text = "跳过药水"
		_apply_button_skin(skip_potion_button, "neutral", "reward")
		skip_potion_button.pressed.connect(_on_skip_potion_reward_pressed)
		reward_row.add_child(skip_potion_button)
	elif not potion_reward_options.is_empty():
		var potion_done_label := Label.new()
		potion_done_label.text = "药水奖励已处理。"
		potion_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(potion_done_label)

	var continue_button := Button.new()
	continue_button.custom_minimum_size = _small_action_button_size()
	continue_button.text = "继续"
	_apply_button_skin(continue_button, "primary", "reward")
	continue_button.disabled = not (card_reward_done and relic_reward_done and potion_reward_done)
	continue_button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(continue_button)

func _on_enemy_pressed(index: int) -> void:
	selected_enemy_index = index
	_refresh()

func _on_card_pressed(index: int) -> void:
	if combat != null and combat.phase == "player":
		var target_index: int = _normalize_selected_enemy()
		var payload: Dictionary = {}
		if index >= 0 and index < combat.hand.size() and combat.can_play_card(index):
			payload = _build_card_visual_payload(index, combat.hand[index], target_index)
		if combat.play_card(index, selected_enemy_index):
			if not payload.is_empty():
				_request_card_play_visual(payload)
			else:
				last_card_audio_event = "card_play"
				_audio_event("card_play")
			selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_end_turn_pressed() -> void:
	if combat == null:
		return
	_audio_event("turn_end")
	combat.end_player_turn()
	selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_potion_pressed(slot_index: int) -> void:
	if combat == null or slot_index < 0 or slot_index >= run_potion_ids.size():
		return
	var potion: Dictionary = _potion_by_id(str(run_potion_ids[slot_index]))
	if potion.is_empty():
		_audio_event("error")
		return
	if combat.use_potion(potion, selected_enemy_index):
		run_potion_ids.remove_at(slot_index)
		_audio_event("potion")
	selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_reward_card_pressed(card_id: String) -> void:
	if card_id.is_empty():
		return
	run_deck_ids.append(card_id)
	if _record_discovered_content("cards", card_id):
		_save_player_profile()
	_audio_event("reward")
	var card: Dictionary = _card_by_id(card_id)
	combat.log_entries.append("奖励选择：%s 加入牌组。" % card.get("name", card_id))
	card_reward_done = true
	_refresh()

func _on_skip_card_reward_pressed() -> void:
	combat.log_entries.append("跳过卡牌奖励。")
	_audio_event("ui_click")
	card_reward_done = true
	_refresh()

func _on_reward_relic_pressed(relic_id: String) -> void:
	if relic_id.is_empty():
		return
	run_relic_ids.append(relic_id)
	if _record_discovered_content("relics", relic_id):
		_save_player_profile()
	_audio_event("reward")
	var relic: Dictionary = _relic_by_id(relic_id)
	combat.log_entries.append("遗物获得：%s。" % relic.get("name", relic_id))
	relic_reward_done = true
	_refresh()

func _on_reward_potion_pressed(potion_id: String) -> void:
	if potion_id.is_empty() or not _has_empty_potion_slot():
		_audio_event("error")
		return
	run_potion_ids.append(potion_id)
	if _record_discovered_content("potions", potion_id):
		_save_player_profile()
	_audio_event("reward")
	var potion: Dictionary = _potion_by_id(potion_id)
	combat.log_entries.append("药水获得：%s。" % potion.get("name", potion_id))
	potion_reward_done = true
	_refresh()

func _on_skip_potion_reward_pressed() -> void:
	combat.log_entries.append("跳过药水奖励。")
	_audio_event("ui_click")
	potion_reward_done = true
	_refresh()

func _on_campfire_heal_pressed() -> void:
	var heal_percent: int = _campfire_heal_percent()
	var heal: int = max(1, int(ceil(float(run_max_hp) * float(heal_percent) / 100.0)))
	run_hp = min(run_max_hp, run_hp + heal)
	_audio_event("campfire")
	_advance_to_next_node()

func _on_upgrade_card_pressed(deck_index: int) -> void:
	if deck_index < 0 or deck_index >= run_deck_ids.size():
		return
	var entry: String = str(run_deck_ids[deck_index])
	if not entry.ends_with("+"):
		run_deck_ids[deck_index] = "%s+" % entry
	_audio_event("campfire")
	_advance_to_next_node()

func _on_shop_buy_card_pressed(card_id: String, price: int) -> void:
	if card_id.is_empty() or run_gold < price:
		_audio_event("error")
		return
	run_gold -= price
	run_deck_ids.append(card_id)
	if _record_discovered_content("cards", card_id):
		_save_player_profile()
	_audio_event("shop")
	for i in range(shop_card_options.size()):
		var card: Dictionary = shop_card_options[i]
		if str(card.get("id", "")) == card_id:
			shop_card_options.remove_at(i)
			break
	_refresh()

func _on_shop_buy_potion_pressed(potion_id: String, price: int) -> void:
	if potion_id.is_empty() or run_gold < price or not _has_empty_potion_slot():
		_audio_event("error")
		return
	run_gold -= price
	run_potion_ids.append(potion_id)
	if _record_discovered_content("potions", potion_id):
		_save_player_profile()
	_audio_event("shop")
	for i in range(shop_potion_options.size()):
		var potion: Dictionary = shop_potion_options[i]
		if str(potion.get("id", "")) == potion_id:
			shop_potion_options.remove_at(i)
			break
	_refresh()

func _on_shop_remove_card_pressed() -> void:
	var remove_price: int = _remove_card_price()
	if run_gold < remove_price or run_deck_ids.is_empty():
		_audio_event("error")
		return
	var remove_index: int = _find_removable_card_index()
	if remove_index < 0:
		return
	run_gold -= remove_price
	run_deck_ids.remove_at(remove_index)
	run_shop_remove_count += 1
	_record_card_removed()
	_audio_event("shop")
	_refresh()

func _on_map_node_pressed(node_id: String) -> void:
	if not available_node_ids.has(node_id):
		_audio_event("error")
		return
	_audio_event("map_select")
	current_node_id = node_id
	current_node_index = _node_index_by_id(current_node_id)
	available_node_ids.clear()
	_start_current_node()

func _on_map_node_previewed(node_id: String) -> void:
	if current_node_id.is_empty() and not available_node_ids.is_empty():
		_update_map_preview(node_id)

func _update_map_preview(node_id: String) -> void:
	last_map_preview_node_id = node_id
	last_map_preview_text = _map_node_preview_text(node_id)
	log_label.text = "%s\n\n%s" % [_map_legend_text(), last_map_preview_text]
	if map_view != null and map_view.visible and map_view.has_method("set_preview_node"):
		map_view.set_preview_node(node_id, _successor_node_ids(node_id))

func _on_deck_view_pressed() -> void:
	if character_select_open or run_deck_ids.is_empty():
		_audio_event("error")
		return
	deck_view_open = true
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	_audio_event("ui_click")
	_refresh()

func _on_close_deck_view_pressed() -> void:
	deck_view_open = false
	_audio_event("ui_click")
	_refresh()

func _on_challenge_down_pressed() -> void:
	selected_challenge_level = _valid_challenge_level(selected_challenge_level - 1)
	_audio_event("ui_click")
	_refresh()

func _on_challenge_up_pressed() -> void:
	selected_challenge_level = _valid_challenge_level(selected_challenge_level + 1)
	_audio_event("ui_click")
	_refresh()

func _on_tutorial_pressed() -> void:
	if last_tutorial_visible and not last_tutorial_step_id.is_empty():
		_complete_tutorial_step(last_tutorial_step_id)
		_audio_event("ui_click")
		_refresh()
		return
	tutorial_open = true
	deck_view_open = false
	settings_open = false
	profile_open = false
	compendium_open = false
	_audio_event("ui_click")
	_refresh()

func _on_close_tutorial_pressed() -> void:
	tutorial_open = false
	_audio_event("ui_click")
	_refresh()

func _on_tutorial_complete_current_pressed() -> void:
	_complete_tutorial_step(last_tutorial_step_id)
	_audio_event("ui_click")
	_refresh()

func _on_settings_pressed() -> void:
	settings_open = true
	deck_view_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	_audio_event("ui_click")
	_refresh()

func _on_close_settings_pressed() -> void:
	settings_open = false
	_audio_event("ui_click")
	_refresh()

func _on_profile_pressed() -> void:
	profile_open = true
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	compendium_open = false
	_audio_event("ui_click")
	_refresh()

func _on_close_profile_pressed() -> void:
	profile_open = false
	_audio_event("ui_click")
	_refresh()

func _on_compendium_pressed() -> void:
	if card_data.is_empty():
		_load_all_data()
	compendium_open = true
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	selected_compendium_tab = _valid_compendium_tab(selected_compendium_tab)
	selected_compendium_filter = _valid_compendium_filter(selected_compendium_tab, selected_compendium_filter)
	selected_compendium_sort = _valid_compendium_sort(selected_compendium_tab, selected_compendium_sort)
	_audio_event("ui_click")
	_refresh()

func _on_close_compendium_pressed() -> void:
	compendium_open = false
	_audio_event("ui_click")
	_refresh()

func _on_compendium_tab_pressed(tab_id: String) -> void:
	selected_compendium_tab = _valid_compendium_tab(tab_id)
	selected_compendium_filter = "all"
	selected_compendium_sort = _default_compendium_sort(selected_compendium_tab)
	_audio_event("ui_click")
	_refresh()

func _on_compendium_filter_pressed(filter_id: String) -> void:
	selected_compendium_filter = _valid_compendium_filter(selected_compendium_tab, filter_id)
	_audio_event("ui_click")
	_refresh()

func _on_compendium_reveal_toggle_pressed() -> void:
	compendium_reveal_all_details = not compendium_reveal_all_details
	_audio_event("ui_click")
	_refresh()

func _on_compendium_sort_pressed(sort_id: String) -> void:
	selected_compendium_sort = _valid_compendium_sort(selected_compendium_tab, sort_id)
	_audio_event("ui_click")
	_refresh()

func _on_compendium_search_changed(search_text: String) -> void:
	selected_compendium_search = _sanitize_compendium_search(search_text)
	_refresh()

func _on_compendium_search_clear_pressed() -> void:
	selected_compendium_search = ""
	_audio_event("ui_click")
	_refresh()

func _on_settings_toggle_audio() -> void:
	user_settings["audio_enabled"] = not _setting_enabled("audio_enabled", true)
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _on_settings_volume_down() -> void:
	_change_master_volume(-0.1)

func _on_settings_volume_up() -> void:
	_change_master_volume(0.1)

func _on_settings_toggle_music() -> void:
	user_settings["music_enabled"] = not _setting_enabled("music_enabled", true)
	_save_user_settings()
	_music_context(last_music_context if not last_music_context.is_empty() else "menu")
	_audio_event("ui_click")
	_refresh()

func _on_settings_music_volume_down() -> void:
	_change_music_volume(-0.1)

func _on_settings_music_volume_up() -> void:
	_change_music_volume(0.1)

func _on_settings_toggle_screen_shake() -> void:
	user_settings["screen_shake_enabled"] = not _setting_enabled("screen_shake_enabled", true)
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _on_settings_toggle_hit_stop() -> void:
	user_settings["hit_stop_enabled"] = not _setting_enabled("hit_stop_enabled", true)
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _on_settings_toggle_floating_text() -> void:
	user_settings["floating_text_enabled"] = not _setting_enabled("floating_text_enabled", true)
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _on_settings_toggle_tutorial() -> void:
	user_settings["tutorial_enabled"] = not _setting_enabled("tutorial_enabled", true)
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _on_settings_reset_tutorial_pressed() -> void:
	user_settings["tutorial_enabled"] = true
	user_settings["tutorial_completed_steps"] = []
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _on_settings_reset_pressed() -> void:
	user_settings = SaveManagerScript.default_settings()
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _change_master_volume(delta: float) -> void:
	var next_volume: float = clamp(_setting_float("master_volume", 1.0) + delta, 0.0, 1.0)
	user_settings["master_volume"] = round(next_volume * 10.0) / 10.0
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

func _change_music_volume(delta: float) -> void:
	var next_volume: float = clamp(_setting_float("music_volume", 0.65) + delta, 0.0, 1.0)
	user_settings["music_volume"] = round(next_volume * 10.0) / 10.0
	_save_user_settings()
	_music_context(last_music_context if not last_music_context.is_empty() else "menu")
	_audio_event("ui_click")
	_refresh()

func _on_save_pressed() -> void:
	if character_select_open or run_deck_ids.is_empty():
		_audio_event("error")
		return
	var state := _create_save_state()
	var ok: bool = SaveManagerScript.save_run(state)
	_audio_event("save" if ok else "error")
	if combat != null:
		combat.log_entries.append("跑团已保存。" if ok else "保存失败。")
	_refresh()

func _on_load_pressed() -> void:
	var state: Dictionary = SaveManagerScript.load_run()
	if state.is_empty():
		_audio_event("error")
		if combat != null:
			combat.log_entries.append("没有可读取的存档。")
			_refresh()
		return
	_load_all_data()
	selected_character_id = _valid_character_id(str(state.get("selected_character_id", _default_character_id())))
	character_select_open = false
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	_audio_event("save")
	run_deck_ids = state.get("run_deck_ids", []).duplicate(true)
	run_relic_ids = state.get("run_relic_ids", []).duplicate(true)
	run_potion_ids = state.get("run_potion_ids", []).duplicate(true)
	run_hp = int(state.get("run_hp", 1))
	run_max_hp = int(state.get("run_max_hp", 72))
	run_gold = int(state.get("run_gold", 0))
	run_shop_remove_count = int(state.get("run_shop_remove_count", 0))
	current_challenge_level = _configured_challenge_level(int(state.get("current_challenge_level", 0)))
	selected_challenge_level = _valid_challenge_level(current_challenge_level)
	current_chapter_id = str(state.get("current_chapter_id", _first_chapter_id()))
	completed_chapter_ids = state.get("completed_chapter_ids", []).duplicate(true)
	current_node_index = int(state.get("current_node_index", 0))
	current_node_id = str(state.get("current_node_id", ""))
	available_node_ids = []
	for node_id in state.get("available_node_ids", []):
		available_node_ids.append(str(node_id))
	completed_node_ids = state.get("completed_node_ids", {})
	completed_event_ids = state.get("completed_event_ids", {})
	map_graph = state.get("map_graph", {})
	run_completed = bool(state.get("run_completed", false))
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	shop_card_options.clear()
	shop_potion_options.clear()
	reward_generated_for = ""
	shop_generated_for = -1
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	if map_graph.is_empty():
		_build_route()
	else:
		route_nodes = _flatten_map_nodes(map_graph)
		current_node_index = _node_index_by_id(current_node_id)
	if _record_current_run_discoveries(false):
		_save_player_profile()
	_start_current_node()

func _on_event_choice_pressed(choice: Dictionary) -> void:
	var blocked_reason: String = _event_choice_blocked_reason(choice)
	last_event_choice_blocked_reason = blocked_reason
	if not blocked_reason.is_empty():
		_audio_event("error")
		_refresh()
		return
	last_event_choice_blocked_reason = ""
	var current_event_id: String = str(_current_node().get("event_id", ""))
	for effect in _resolve_event_choice_effects(choice, current_event_id):
		var effect_dict: Dictionary = effect
		_apply_event_effect(effect_dict)
	if not current_event_id.is_empty() and bool(_event_by_id(current_event_id).get("one_time", false)):
		completed_event_ids[current_event_id] = true
	_audio_event("reward")
	_advance_to_next_node()

func _advance_to_next_node() -> void:
	var completed_node: Dictionary = _current_node()
	var completed_node_type: String = str(completed_node.get("type", ""))
	var completed_chapter_id: String = current_chapter_id
	if combat != null:
		if combat.phase == "won":
			run_hp = int(combat.player.get("hp", run_hp))
			if completed_node_type == "boss":
				_record_boss_defeated(completed_chapter_id)
		elif combat.phase == "lost":
			return
	if not current_node_id.is_empty():
		completed_node_ids[current_node_id] = true
	available_node_ids = _map_relic_augmented_node_ids(current_node_id, _next_node_ids(current_node_id))
	current_node_id = ""
	combat = null
	_audio_event("ui_click")
	if available_node_ids.is_empty():
		if _start_next_chapter():
			return
		if not completed_chapter_ids.has(current_chapter_id):
			completed_chapter_ids.append(current_chapter_id)
		_record_chapter_completed(current_chapter_id)
		run_completed = true
		_record_run_completed()
	_refresh()

func _normalize_selected_enemy() -> int:
	if combat == null:
		return 0
	if selected_enemy_index >= 0 and selected_enemy_index < combat.enemies.size() and int(combat.enemies[selected_enemy_index].get("hp", 0)) > 0:
		return selected_enemy_index
	for i in range(combat.enemies.size()):
		if int(combat.enemies[i].get("hp", 0)) > 0:
			return i
	return 0

func _enemy_texture(enemy: Dictionary) -> Texture2D:
	var data: Dictionary = enemy.get("data", {})
	var sprite_key: String = str(data.get("sprite_key", ""))
	var path: String = str(ENEMY_ART_PATHS.get(sprite_key, ""))
	if path.is_empty() and sprite_key.begins_with("placeholder_"):
		path = "res://assets/art/enemy_%s.svg" % sprite_key.trim_prefix("placeholder_")
		if not _asset_loaded(path):
			path = ""
	if path.is_empty():
		path = "res://assets/art/enemy_forge_bishop.svg" if str(data.get("tier", "")) == "boss" else "res://assets/art/enemy_soot_raider.svg"
	return _load_texture(path)

func _asset_slot_by_id(section: String, item_id: String) -> Dictionary:
	for entry in art_data.get(section, []):
		var entry_dict: Dictionary = entry
		if str(entry_dict.get("id", "")) == item_id:
			return entry_dict
	return {}

func _asset_path_from_slot(section: String, item_id: String, fallback_path: String) -> String:
	var slot: Dictionary = _asset_slot_by_id(section, item_id)
	var path: String = str(slot.get("asset_path", ""))
	if path.is_empty():
		path = fallback_path
	return path

func _asset_loaded(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		return true
	return path.ends_with(".svg") and FileAccess.file_exists(path)

func _card_frame_path(card_type: String) -> String:
	var frames: Dictionary = art_data.get("card_type_frames", {})
	var path: String = str(frames.get(card_type, ""))
	if path.is_empty():
		path = str(frames.get("default", ""))
	if path.is_empty():
		path = str(CARD_FRAME_PATHS.get(card_type, ""))
	if path.is_empty():
		path = str(CARD_FRAME_PATHS.get("skill", ""))
	return path

func _card_art_path(card: Dictionary) -> String:
	var card_id: String = str(card.get("id", ""))
	if card_id.ends_with("+"):
		card_id = card_id.substr(0, card_id.length() - 1)
	return _asset_path_from_slot("card_art_slots", card_id, _card_frame_path(str(card.get("type", ""))))

func _relic_icon_path(relic: Dictionary) -> String:
	var fallbacks: Dictionary = art_data.get("fallbacks", {})
	var fallback: String = str(fallbacks.get("relic_icon", RELIC_ART_PATH))
	return _asset_path_from_slot("relic_icon_slots", str(relic.get("id", "")), fallback)

func _potion_fallback_icon_path() -> String:
	var fallbacks: Dictionary = art_data.get("fallbacks", {})
	return str(fallbacks.get("potion_icon", POTION_ART_PATH))

func _potion_icon_path(potion: Dictionary) -> String:
	return _asset_path_from_slot("potion_icon_slots", str(potion.get("id", "")), _potion_fallback_icon_path())

func _event_art_path(event: Dictionary) -> String:
	var fallbacks: Dictionary = art_data.get("fallbacks", {})
	var fallback: String = str(fallbacks.get("event_art", EVENT_ART_PATH))
	return _asset_path_from_slot("event_art_slots", str(event.get("id", "")), fallback)

func _battle_background_path(chapter_id: String) -> String:
	var fallbacks: Dictionary = art_data.get("fallbacks", {})
	var fallback: String = str(fallbacks.get("battle_background", "res://assets/art/battle_bg_chapter_one.svg"))
	return _asset_path_from_slot("battle_background_slots", chapter_id, fallback)

func _card_frame_texture(card_type: String) -> Texture2D:
	var path: String = _card_frame_path(card_type)
	if path.is_empty():
		return null
	return _load_texture(path)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			return texture
	if path.ends_with(".svg") and FileAccess.file_exists(path):
		if raw_svg_texture_cache.has(path):
			return raw_svg_texture_cache.get(path)
		var svg_text: String = FileAccess.get_file_as_string(path)
		if svg_text.is_empty():
			return null
		var image := Image.new()
		var error: Error = image.load_svg_from_string(svg_text, 1.0)
		if error != OK or image.get_width() <= 0 or image.get_height() <= 0:
			return null
		var svg_texture := ImageTexture.create_from_image(image)
		raw_svg_texture_cache[path] = svg_texture
		return svg_texture
	return null

func _player_panel_style() -> StyleBoxFlat:
	return _button_style(Color(0.12, 0.16, 0.16, 0.94), Color(0.46, 0.72, 0.66), 2, 8)

func _battle_board_style() -> StyleBoxFlat:
	return _button_style(Color(0.085, 0.095, 0.10, 0.96), Color(0.40, 0.44, 0.48), 2, 8)

func _enemy_stage_style() -> StyleBoxFlat:
	return _button_style(Color(0.095, 0.09, 0.085, 0.92), Color(0.72, 0.48, 0.30), 2, 8)

func _hand_frame_style() -> StyleBoxFlat:
	return _button_style(Color(0.11, 0.12, 0.15, 0.94), Color(0.46, 0.54, 0.72), 2, 8)

func _card_button_style(card_type: String, highlighted: bool, pressed: bool) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var bg: Color = colors.get("bg", Color(0.18, 0.19, 0.22))
	var border: Color = colors.get("border", Color(0.58, 0.60, 0.64))
	if highlighted:
		bg = bg.lightened(0.10)
		border = border.lightened(0.16)
	if pressed:
		bg = bg.darkened(0.12)
	return _button_style(bg, border, 2, 6)

func _hand_card_cost_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	return _button_style(
		colors.get("border", Color(0.58, 0.60, 0.64)).darkened(0.28),
		colors.get("border", Color(0.58, 0.60, 0.64)).lightened(0.10),
		2,
		8
	)

func _hand_card_art_frame_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	return _button_style(
		colors.get("bg", Color(0.18, 0.19, 0.22)).darkened(0.18),
		colors.get("border", Color(0.58, 0.60, 0.64)).darkened(0.08),
		1,
		6
	)

func _hand_card_description_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	return _button_style(
		colors.get("bg", Color(0.18, 0.19, 0.22)).darkened(0.22),
		colors.get("border", Color(0.58, 0.60, 0.64)).darkened(0.20),
		1,
		6
	)

func _hand_card_type_color(card_type: String) -> Color:
	var colors: Dictionary = _card_colors(card_type)
	return colors.get("border", Color(0.76, 0.78, 0.80)).lightened(0.18)

func _card_type_display_name(card_type: String) -> String:
	match card_type:
		"attack":
			return "攻击"
		"skill":
			return "技能"
		"power":
			return "能力"
		"status":
			return "状态"
		"curse":
			return "诅咒"
		_:
			return card_type

func _rarity_display_name(rarity: String) -> String:
	match rarity:
		"starter":
			return "初始"
		"common":
			return "普通"
		"uncommon":
			return "罕见"
		"rare":
			return "稀有"
		"status":
			return "状态"
		_:
			return rarity

func _enemy_button_style(enemy: Dictionary, selected: bool, pressed: bool) -> StyleBoxFlat:
	var data: Dictionary = enemy.get("data", {})
	var tier: String = str(data.get("tier", "normal"))
	var bg := Color(0.17, 0.18, 0.20)
	var border := Color(0.50, 0.55, 0.60)
	if tier == "elite":
		bg = Color(0.21, 0.18, 0.15)
		border = Color(0.80, 0.54, 0.27)
	elif tier == "boss":
		bg = Color(0.23, 0.14, 0.16)
		border = Color(0.86, 0.34, 0.28)
	if selected:
		bg = bg.lightened(0.10)
		border = border.lightened(0.18)
	if pressed:
		bg = bg.darkened(0.12)
	return _button_style(bg, border, 2, 6)

func _character_button_style(character_id: String, highlighted: bool, pressed: bool) -> StyleBoxFlat:
	var bg := Color(0.16, 0.18, 0.20)
	var border := Color(0.62, 0.68, 0.72)
	if character_id == "arc_tinker":
		bg = Color(0.10, 0.19, 0.22)
		border = Color(0.38, 0.78, 0.96)
	elif character_id == "ember_exile":
		bg = Color(0.22, 0.13, 0.10)
		border = Color(0.88, 0.48, 0.28)
	if highlighted:
		bg = bg.lightened(0.10)
		border = border.lightened(0.14)
	if pressed:
		bg = bg.darkened(0.12)
	return _button_style(bg, border, 2, 6)

func _apply_card_button_skin(button: Button, card_type: String, telemetry_bucket: String = "") -> void:
	_configure_button_bounds(button)
	button.add_theme_stylebox_override("normal", _card_button_style(card_type, false, false))
	button.add_theme_stylebox_override("hover", _card_button_style(card_type, true, false))
	button.add_theme_stylebox_override("pressed", _card_button_style(card_type, true, true))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.13, 0.15), Color(0.34, 0.35, 0.38), 1, 6))
	button.add_theme_color_override("font_color", Color(0.95, 0.96, 0.92))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.60, 0.60))
	button.add_theme_font_size_override("font_size", 14)
	_record_button_skin(telemetry_bucket)

func _apply_button_skin(button: Button, skin: String, telemetry_bucket: String = "") -> void:
	_configure_button_bounds(button)
	var palette: Dictionary = _button_skin_palette(skin)
	var bg: Color = palette.get("bg", Color(0.16, 0.17, 0.18))
	var border: Color = palette.get("border", Color(0.46, 0.50, 0.52))
	button.add_theme_stylebox_override("normal", _button_style(bg, border, 2, 6))
	button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.10), border.lightened(0.16), 2, 6))
	button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.12), border, 2, 6))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.13, 0.15), Color(0.34, 0.35, 0.38), 1, 6))
	button.add_theme_color_override("font_color", Color(0.95, 0.96, 0.92))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.60, 0.60))
	button.add_theme_font_size_override("font_size", 14)
	_record_button_skin(telemetry_bucket)

func _apply_line_edit_skin(line_edit: LineEdit) -> void:
	line_edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line_edit.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line_edit.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.11, 0.12), Color(0.42, 0.48, 0.52), 1, 6))
	line_edit.add_theme_stylebox_override("focus", _button_style(Color(0.12, 0.15, 0.16), Color(0.48, 0.78, 0.82), 2, 6))
	line_edit.add_theme_stylebox_override("read_only", _button_style(Color(0.10, 0.11, 0.12), Color(0.30, 0.34, 0.36), 1, 6))
	line_edit.add_theme_color_override("font_color", Color(0.94, 0.96, 0.94))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.56, 0.62, 0.62))
	line_edit.add_theme_color_override("caret_color", Color(0.72, 0.94, 0.94))
	line_edit.add_theme_font_size_override("font_size", 14)

func _configure_button_bounds(button: Button) -> void:
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _button_skin_palette(skin: String) -> Dictionary:
	match skin:
		"primary":
			return {"bg": Color(0.18, 0.23, 0.22), "border": Color(0.58, 0.78, 0.62)}
		"success":
			return {"bg": Color(0.12, 0.22, 0.16), "border": Color(0.36, 0.78, 0.48)}
		"danger":
			return {"bg": Color(0.24, 0.10, 0.09), "border": Color(0.88, 0.34, 0.26)}
		"event":
			return {"bg": Color(0.18, 0.16, 0.22), "border": Color(0.68, 0.56, 0.88)}
		"potion":
			return {"bg": Color(0.13, 0.20, 0.21), "border": Color(0.42, 0.82, 0.88)}
		"relic":
			return {"bg": Color(0.21, 0.17, 0.12), "border": Color(0.92, 0.66, 0.34)}
		_:
			return {"bg": Color(0.16, 0.17, 0.18), "border": Color(0.46, 0.50, 0.52)}

func _record_button_skin(telemetry_bucket: String) -> void:
	match telemetry_bucket:
		"campfire":
			last_campfire_button_style_count += 1
		"shop":
			last_shop_button_style_count += 1
		"event":
			last_event_choice_style_count += 1
		"reward":
			last_reward_button_style_count += 1

func _card_colors(card_type: String) -> Dictionary:
	match card_type:
		"attack":
			return {"bg": Color(0.24, 0.13, 0.12), "border": Color(0.86, 0.35, 0.25)}
		"skill":
			return {"bg": Color(0.11, 0.19, 0.24), "border": Color(0.32, 0.66, 0.82)}
		"power":
			return {"bg": Color(0.20, 0.16, 0.25), "border": Color(0.70, 0.50, 0.86)}
		"status", "curse":
			return {"bg": Color(0.16, 0.16, 0.16), "border": Color(0.55, 0.55, 0.55)}
		_:
			return {"bg": Color(0.18, 0.19, 0.22), "border": Color(0.58, 0.60, 0.64)}

func _feedback_style(severity: String) -> StyleBoxFlat:
	match severity:
		"danger":
			return _button_style(Color(0.28, 0.09, 0.08), Color(0.95, 0.35, 0.28), 2, 6)
		"hit":
			return _button_style(Color(0.25, 0.14, 0.08), Color(0.95, 0.55, 0.24), 2, 6)
		"success":
			return _button_style(Color(0.10, 0.22, 0.15), Color(0.30, 0.78, 0.45), 2, 6)
		"phase":
			return _button_style(Color(0.22, 0.12, 0.25), Color(0.78, 0.42, 0.92), 2, 6)
		_:
			return _button_style(Color(0.15, 0.16, 0.18), Color(0.44, 0.48, 0.54), 1, 6)

func _cinematic_style(event_type: String) -> StyleBoxFlat:
	match event_type:
		"won":
			return _button_style(Color(0.05, 0.18, 0.09, 0.94), Color(0.42, 1.0, 0.52), 3, 8)
		"lost":
			return _button_style(Color(0.22, 0.04, 0.04, 0.96), Color(1.0, 0.30, 0.24), 3, 8)
		_:
			return _button_style(Color(0.17, 0.07, 0.22, 0.95), Color(0.95, 0.64, 1.0), 3, 8)

func _feedback_font_size(event_type: String) -> int:
	return 18 if _is_strong_feedback(event_type) else 14

func _is_strong_feedback(event_type: String) -> bool:
	return event_type == "phase" or event_type == "won" or event_type == "lost"

func _button_style(bg: Color, border: Color, border_width: int = 2, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.border_blend = true
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_offset = Vector2(0, 1)
	style.shadow_size = 3 if border_width >= 2 else 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _status_text(statuses: Dictionary) -> String:
	if statuses.is_empty():
		return "无"
	var parts: Array[String] = []
	for key in statuses.keys():
		if int(statuses[key]) > 0:
			parts.append("%s:%d" % [_status_display_name(str(key)), int(statuses[key])])
	if parts.is_empty():
		return "无"
	return ", ".join(parts)

func _status_display_name(status_id: String) -> String:
	for status in status_data.get("statuses", []):
		var status_dict: Dictionary = status
		if str(status_dict.get("id", "")) == status_id:
			return str(status_dict.get("name", status_id))
	return status_id

func _generate_card_rewards(amount: int, context: String = "combat_card") -> Array:
	var pool: Array = []
	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		var rarity: String = str(card_dict.get("rarity", ""))
		var type: String = str(card_dict.get("type", ""))
		if rarity == "starter" or rarity == "status" or type == "status" or type == "curse":
			continue
		if not _card_available_for_current_character(card_dict):
			continue
		pool.append(card_dict)
	var selected: Array = _weighted_rarity_selection(pool, amount, _rarity_weights_for_context(context), _reward_seed(context))
	last_generated_card_reward_rarities = _rarities_for_items(selected)
	last_reward_generation_context = context
	return selected

func _card_available_for_current_character(card: Dictionary) -> bool:
	var character_ids: Array = card.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(selected_character_id):
		return false
	var pool_tags: Array = card.get("pool_tags", [])
	if pool_tags.is_empty():
		return true
	var character_tags: Array = _current_player_config().get("reward_pool_tags", ["shared", selected_character_id])
	for tag in pool_tags:
		if character_tags.has(str(tag)):
			return true
	return false

func _generate_relic_rewards(amount: int, context: String = "relic_reward") -> Array:
	var pool: Array = []
	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		var relic_id: String = str(relic_dict.get("id", ""))
		if relic_id.is_empty() or run_relic_ids.has(relic_id):
			continue
		if str(relic_dict.get("rarity", "")) == "starter":
			continue
		if not _relic_available_for_current_character(relic_dict):
			continue
		pool.append(relic_dict)
	var selected: Array = _weighted_rarity_selection(pool, amount, _rarity_weights_for_context(context), _reward_seed(context))
	last_generated_relic_reward_rarities = _rarities_for_items(selected)
	last_reward_generation_context = context
	return selected

func _relic_available_for_current_character(relic: Dictionary) -> bool:
	var character_ids: Array = relic.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(selected_character_id):
		return false
	var pool_tags: Array = relic.get("pool_tags", [])
	if pool_tags.is_empty():
		return true
	var character_tags: Array = _current_player_config().get("reward_pool_tags", ["shared", selected_character_id])
	for tag in pool_tags:
		if character_tags.has(str(tag)):
			return true
	return false

func _generate_potion_rewards(amount: int, context: String = "potion_reward") -> Array:
	var pool: Array = []
	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		if str(potion_dict.get("id", "")).is_empty():
			continue
		pool.append(potion_dict)
	var selected: Array = _weighted_rarity_selection(pool, amount, _rarity_weights_for_context(context), _reward_seed(context))
	last_generated_potion_reward_rarities = _rarities_for_items(selected)
	last_reward_generation_context = context
	return selected

func _rarity_weights_for_context(context: String) -> Dictionary:
	var config: Dictionary = economy_data.get("reward_generation", {})
	match context:
		"shop_card":
			return config.get("shop_card_rarity_weights", config.get("card_rarity_weights", {}))
		"relic_reward":
			return config.get("relic_rarity_weights", {})
		"shop_potion", "potion_reward":
			return config.get("potion_rarity_weights", {})
		_:
			return config.get("card_rarity_weights", {})

func _reward_seed(context: String) -> String:
	return "%s|%s|%s|%d|%d|%d" % [
		context,
		selected_character_id,
		current_chapter_id,
		current_node_index,
		run_deck_ids.size(),
		run_relic_ids.size()
	]

func _weighted_rarity_selection(pool: Array, amount: int, weights: Dictionary, seed: String) -> Array:
	if amount <= 0 or pool.is_empty():
		return []
	var sorted_pool: Array = pool.duplicate()
	sorted_pool.sort_custom(Callable(self, "_compare_content_by_id"))
	if amount >= sorted_pool.size():
		return sorted_pool
	var buckets: Dictionary = {}
	for item in sorted_pool:
		var item_dict: Dictionary = item
		var rarity: String = str(item_dict.get("rarity", "common"))
		if not buckets.has(rarity):
			buckets[rarity] = []
		var bucket: Array = buckets.get(rarity, [])
		bucket.append(item_dict)
		buckets[rarity] = bucket

	var selected: Array = []
	for slot in range(amount):
		var rarity_choice: String = _weighted_available_rarity(buckets, weights, "%s|rarity|%d" % [seed, slot])
		if rarity_choice.is_empty():
			break
		var rarity_bucket: Array = buckets.get(rarity_choice, [])
		if rarity_bucket.is_empty():
			break
		var selected_index: int = _deterministic_index("%s|item|%d|%s" % [seed, slot, rarity_choice], rarity_bucket.size())
		selected.append(rarity_bucket[selected_index])
		rarity_bucket.remove_at(selected_index)
		buckets[rarity_choice] = rarity_bucket
	return selected

func _weighted_available_rarity(buckets: Dictionary, weights: Dictionary, seed: String) -> String:
	var rarity_order: Array[String] = ["common", "uncommon", "rare"]
	for rarity in buckets.keys():
		var rarity_string: String = str(rarity)
		if not rarity_order.has(rarity_string):
			rarity_order.append(rarity_string)
	var weighted_rarities: Array[String] = []
	var total_weight: int = 0
	for rarity in rarity_order:
		var bucket: Array = buckets.get(rarity, [])
		if bucket.is_empty():
			continue
		var weight: int = max(0, int(weights.get(rarity, 1)))
		if weight <= 0:
			continue
		weighted_rarities.append(rarity)
		total_weight += weight
	if weighted_rarities.is_empty():
		for rarity in rarity_order:
			var bucket: Array = buckets.get(rarity, [])
			if not bucket.is_empty():
				return rarity
		return ""
	var roll: int = _deterministic_index(seed, total_weight)
	var cursor: int = 0
	for rarity in weighted_rarities:
		cursor += max(0, int(weights.get(rarity, 1)))
		if roll < cursor:
			return rarity
	return weighted_rarities[weighted_rarities.size() - 1]

func _deterministic_index(seed: String, size: int) -> int:
	if size <= 0:
		return 0
	var hash_value: int = seed.hash()
	if hash_value < 0:
		hash_value = -hash_value
	return hash_value % size

func _compare_content_by_id(left, right) -> bool:
	var left_dict: Dictionary = left
	var right_dict: Dictionary = right
	return str(left_dict.get("id", "")) < str(right_dict.get("id", ""))

func _rarities_for_items(items: Array) -> Array[String]:
	var rarities: Array[String] = []
	for item in items:
		var item_dict: Dictionary = item
		rarities.append(str(item_dict.get("rarity", "common")))
	return rarities

func _grant_encounter_gold(encounter_id: String) -> void:
	var encounter: Dictionary = _encounter_by_id(encounter_id)
	var gold_reward: int = int(encounter.get("gold_reward", 0))
	run_gold += gold_reward
	combat.log_entries.append("获得金币：%d。" % gold_reward)

func _card_price(card: Dictionary) -> int:
	var rarity: String = str(card.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("card_prices", {})
	return int(prices.get(rarity, prices.get("common", 50)))

func _potion_price(potion: Dictionary) -> int:
	var rarity: String = str(potion.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("potion_prices", {})
	return int(prices.get(rarity, prices.get("common", 35)))

func _remove_card_price() -> int:
	var shop_config: Dictionary = economy_data.get("shop", {})
	var base_price: int = int(shop_config.get("remove_card_price", 50))
	var increase: int = int(shop_config.get("remove_card_price_increase", 25))
	return base_price + max(0, run_shop_remove_count) * max(0, increase)

func _campfire_heal_percent() -> int:
	return int(economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 30))

func _potion_reward_count() -> int:
	return int(economy_data.get("potion_reward", {}).get("combat_drop_count", 1))

func _max_potion_slots() -> int:
	return int(_current_player_config().get("potion_slots", 2))

func _has_empty_potion_slot() -> bool:
	return run_potion_ids.size() < _max_potion_slots()

func _event_choice_button_text(choice: Dictionary, blocked_reason: String = "") -> String:
	var text: String = "%s\n%s" % [choice.get("label", "选择"), choice.get("description", "")]
	if not blocked_reason.is_empty():
		text = "%s\n条件不足：%s" % [text, blocked_reason]
	elif choice.has("random_results"):
		text = "%s\n结果：随机" % text
	return text

func _event_choice_blocked_reason(choice: Dictionary) -> String:
	for condition in choice.get("conditions", []):
		var condition_dict: Dictionary = condition
		var reason: String = _event_condition_blocked_reason(condition_dict)
		if not reason.is_empty():
			return reason
	return ""

func _event_condition_blocked_reason(condition: Dictionary) -> String:
	match str(condition.get("type", "")):
		"min_gold":
			var gold: int = int(condition.get("amount", 0))
			if run_gold < gold:
				return "需要 %d 金币" % gold
		"min_hp":
			var hp: int = int(condition.get("amount", 1))
			if run_hp < hp:
				return "需要至少 %d 生命" % hp
		"has_empty_potion_slot":
			if not _has_empty_potion_slot():
				return "需要空药水槽"
		"has_removable_card":
			if _find_removable_card_index() < 0:
				return "没有可移除卡牌"
		"missing_relic":
			var missing_relic_id: String = str(condition.get("relic_id", ""))
			if not missing_relic_id.is_empty() and run_relic_ids.has(missing_relic_id):
				return "已拥有该遗物"
		"has_relic":
			var relic_id: String = str(condition.get("relic_id", ""))
			if not run_relic_ids.has(relic_id):
				return "需要指定遗物"
		"deck_contains_card":
			var card_id: String = str(condition.get("card_id", ""))
			if not _run_deck_contains_card(card_id):
				return "牌组缺少指定卡牌"
		"event_not_completed":
			var event_id: String = str(condition.get("event_id", ""))
			if completed_event_ids.has(event_id):
				return "该事件已完成"
		_:
			return ""
	return ""

func _resolve_event_choice_effects(choice: Dictionary, event_id: String) -> Array:
	last_event_result_id = ""
	last_event_result_label = ""
	var random_results: Array = choice.get("random_results", [])
	if random_results.is_empty():
		return choice.get("effects", [])
	var selected: Dictionary = _select_weighted_event_result(random_results, choice, event_id)
	last_event_result_id = str(selected.get("id", ""))
	last_event_result_label = str(selected.get("label", ""))
	return selected.get("effects", [])

func _select_weighted_event_result(results: Array, choice: Dictionary, event_id: String) -> Dictionary:
	var total_weight: int = 0
	for result in results:
		var result_dict: Dictionary = result
		total_weight += max(0, int(result_dict.get("weight", 1)))
	if total_weight <= 0:
		return results[0] if not results.is_empty() else {}
	var rng := RandomNumberGenerator.new()
	var seed_text: String = "%s|%s|%s|%d|%d|%d" % [
		event_id,
		choice.get("id", ""),
		choice.get("random_seed", "run"),
		current_node_index,
		run_gold,
		run_hp
	]
	rng.seed = _stable_text_seed(seed_text)
	var roll: int = rng.randi_range(1, total_weight)
	var cursor: int = 0
	for result in results:
		var result_dict: Dictionary = result
		cursor += max(0, int(result_dict.get("weight", 1)))
		if roll <= cursor:
			return result_dict
	return results[0]

func _stable_text_seed(text: String) -> int:
	var value: int = 2166136261
	for i in range(text.length()):
		value = int((value ^ text.unicode_at(i)) * 16777619) & 0x7fffffff
	return max(1, value)

func _run_deck_contains_card(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	for entry_value in run_deck_ids:
		var entry: String = str(entry_value)
		var base_id: String = entry.substr(0, entry.length() - 1) if entry.ends_with("+") else entry
		if base_id == card_id:
			return true
	return false

func _apply_event_effect(effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"gain_gold":
			run_gold += int(effect.get("amount", 0))
		"lose_hp":
			run_hp = max(1, run_hp - int(effect.get("amount", 0)))
		"heal_percent":
			var amount: int = int(effect.get("amount", 0))
			var heal: int = max(1, int(ceil(float(run_max_hp) * float(amount) / 100.0)))
			run_hp = min(run_max_hp, run_hp + heal)
		"add_card":
			var card_id: String = str(effect.get("card_id", ""))
			if not card_id.is_empty():
				run_deck_ids.append(card_id)
				if _record_discovered_content("cards", card_id):
					_save_player_profile()
		"gain_relic":
			var relic_id: String = str(effect.get("relic_id", ""))
			if not relic_id.is_empty() and not run_relic_ids.has(relic_id):
				run_relic_ids.append(relic_id)
				if _record_discovered_content("relics", relic_id):
					_save_player_profile()
		"gain_potion":
			var potion_id: String = str(effect.get("potion_id", ""))
			if not potion_id.is_empty() and _has_empty_potion_slot():
				run_potion_ids.append(potion_id)
				if _record_discovered_content("potions", potion_id):
					_save_player_profile()
		"remove_first_non_starter_card":
			var remove_index: int = _find_removable_card_index()
			if remove_index >= 0:
				run_deck_ids.remove_at(remove_index)
		_:
			pass

func _find_removable_card_index() -> int:
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		if entry.ends_with("+"):
			return i
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		var card_id: String = entry.substr(0, entry.length() - 1) if entry.ends_with("+") else entry
		var card: Dictionary = _card_by_id(card_id)
		if str(card.get("rarity", "")) != "starter":
			return i
	return run_deck_ids.size() - 1

func _current_node() -> Dictionary:
	if not current_node_id.is_empty():
		return _node_by_id(current_node_id)
	if current_node_index >= 0 and current_node_index < route_nodes.size():
		return route_nodes[current_node_index]
	return {}

func _is_battle_node(node_type: String) -> bool:
	return node_type == "combat" or node_type == "elite" or node_type == "boss"

func _route_preview() -> String:
	var parts: Array[String] = []
	var layers: Array = map_graph.get("layers", [])
	if not layers.is_empty():
		for layer in layers:
			var layer_nodes: Array = layer
			var node_parts: Array[String] = []
			for node in layer_nodes:
				var node_dict: Dictionary = node
				var node_id: String = str(node_dict.get("id", ""))
				var marker: String = "-"
				if completed_node_ids.has(node_id):
					marker = "x"
				elif node_id == current_node_id:
					marker = ">"
				elif available_node_ids.has(node_id):
					marker = "*"
				node_parts.append("%s%s:%s" % [marker, node_dict.get("name", "节点"), node_dict.get("type", "")])
			parts.append(" | ".join(node_parts))
		return "\n".join(parts)

	for i in range(route_nodes.size()):
		var node: Dictionary = route_nodes[i]
		var marker: String = ">"
		if i < current_node_index:
			marker = "x"
		elif i > current_node_index:
			marker = "-"
		parts.append("%s %s [%s]" % [marker, node.get("name", "节点"), node.get("type", "")])
	return "\n".join(parts)

func _map_graph_for_view() -> Dictionary:
	if not map_graph.is_empty():
		return map_graph
	var layers: Array = []
	var edges: Array = []
	for i in range(route_nodes.size()):
		var node: Dictionary = route_nodes[i]
		layers.append([node])
		if i + 1 < route_nodes.size():
			edges.append({"from": str(node.get("id", "")), "to": str(route_nodes[i + 1].get("id", ""))})
	return {
		"layers": layers,
		"edges": edges,
		"start_node_id": str(route_nodes[0].get("id", "")) if not route_nodes.is_empty() else "",
		"boss_node_id": str(route_nodes[route_nodes.size() - 1].get("id", "")) if not route_nodes.is_empty() else ""
	}

func _map_legend_text() -> String:
	var available_names: Array[String] = []
	for node_id in available_node_ids:
		var node: Dictionary = _node_by_id(node_id)
		available_names.append("%s [%s]" % [node.get("name", node_id), node.get("type", "")])
	return "地图图例：> 可前往，x 已完成，灰色为暂不可达。\n当前可选：%s" % ", ".join(available_names)

func _default_map_preview_node_id() -> String:
	if not last_map_preview_node_id.is_empty() and available_node_ids.has(last_map_preview_node_id):
		return last_map_preview_node_id
	if not available_node_ids.is_empty():
		return str(available_node_ids[0])
	return ""

func _map_node_preview_text(node_id: String) -> String:
	var node: Dictionary = _node_by_id(node_id)
	if node.is_empty():
		return "节点详情：暂无可预览节点。"
	var next_ids: Array[String] = _successor_node_ids(node_id)
	var next_parts: Array[String] = []
	for next_id in next_ids:
		var next_node: Dictionary = _node_by_id(next_id)
		next_parts.append("%s [%s]" % [next_node.get("name", next_id), _node_type_display_name(str(next_node.get("type", "")))])
	if next_parts.is_empty():
		next_parts.append("终点或当前路线末端")
	return "节点详情\n%s [%s]\n%s\n后续可达：%s" % [
		node.get("name", node_id),
		_node_type_display_name(str(node.get("type", ""))),
		_node_detail_text(node),
		", ".join(next_parts)
	]

func _successor_node_ids(node_id: String) -> Array[String]:
	var result: Array[String] = []
	for edge in map_graph.get("edges", []):
		var edge_dict: Dictionary = edge
		if str(edge_dict.get("from", "")) == node_id:
			var target_id: String = str(edge_dict.get("to", ""))
			if not target_id.is_empty() and not result.has(target_id):
				result.append(target_id)
	if result.is_empty() and map_graph.is_empty():
		var node_index: int = _node_index_by_id(node_id)
		var next_index: int = node_index + 1
		if next_index >= 0 and next_index < route_nodes.size():
			result.append(str(route_nodes[next_index].get("id", "")))
	return result

func _map_relic_augmented_node_ids(from_node_id: String, base_ids: Array[String]) -> Array[String]:
	last_map_relic_extra_choice_count = 0
	last_map_relic_extra_choice_ids.clear()
	var result: Array[String] = []
	for node_id in base_ids:
		var node_id_string: String = str(node_id)
		if not node_id_string.is_empty() and not result.has(node_id_string):
			result.append(node_id_string)
	if not _has_run_relic("old_compass") or map_graph.is_empty() or result.is_empty():
		return result
	var amount: int = _relic_effect_amount("old_compass", "map_choice", "extra_route_option")
	if amount <= 0:
		return result
	var candidates: Array[String] = _same_layer_extra_node_candidates(from_node_id, result)
	for slot in range(min(amount, candidates.size())):
		var selected_index: int = _deterministic_index("old_compass|%s|%d|%d" % [from_node_id, slot, run_relic_ids.size()], candidates.size())
		var selected_id: String = candidates[selected_index]
		candidates.remove_at(selected_index)
		if not result.has(selected_id):
			result.append(selected_id)
			last_map_relic_extra_choice_ids.append(selected_id)
	last_map_relic_extra_choice_count = last_map_relic_extra_choice_ids.size()
	return result

func _same_layer_extra_node_candidates(from_node_id: String, current_ids: Array[String]) -> Array[String]:
	var candidates: Array[String] = []
	var target_layer: int = -1
	for node_id in current_ids:
		var node: Dictionary = _node_by_id(str(node_id))
		if node.has("layer"):
			target_layer = int(node.get("layer", -1))
			break
	if target_layer < 0:
		return candidates
	for node in route_nodes:
		var node_dict: Dictionary = node
		var node_id: String = str(node_dict.get("id", ""))
		if node_id.is_empty() or node_id == from_node_id:
			continue
		if completed_node_ids.has(node_id) or current_ids.has(node_id):
			continue
		if int(node_dict.get("layer", -999)) == target_layer:
			candidates.append(node_id)
	candidates.sort()
	return candidates

func _has_run_relic(relic_id: String) -> bool:
	return run_relic_ids.has(relic_id)

func _relic_effect_amount(relic_id: String, trigger: String, effect_type: String) -> int:
	var relic: Dictionary = _relic_by_id(relic_id)
	for effect in relic.get("effects", []):
		var effect_dict: Dictionary = effect
		if str(effect_dict.get("trigger", "")) == trigger and str(effect_dict.get("type", "")) == effect_type:
			return int(effect_dict.get("amount", 0))
	return 0

func _node_type_display_name(node_type: String) -> String:
	match node_type:
		"combat":
			return "普通战斗"
		"elite":
			return "精英战斗"
		"boss":
			return "Boss"
		"event":
			return "事件"
		"shop":
			return "商店"
		"campfire":
			return "篝火"
		_:
			return node_type

func _encounter_by_id(encounter_id: String) -> Dictionary:
	for encounter in encounter_data.get("encounters", []):
		var encounter_dict: Dictionary = encounter
		if str(encounter_dict.get("id", "")) == encounter_id:
			return encounter_dict
	return {}

func _enemy_by_id(enemy_id: String) -> Dictionary:
	for enemy in enemy_data.get("enemies", []):
		var enemy_dict: Dictionary = enemy
		if str(enemy_dict.get("id", "")) == enemy_id:
			return enemy_dict
	return {}

func _card_by_id(card_id: String) -> Dictionary:
	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		if str(card_dict.get("id", "")) == card_id:
			return card_dict
	return {}

func _relic_by_id(relic_id: String) -> Dictionary:
	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		if str(relic_dict.get("id", "")) == relic_id:
			return relic_dict
	return {}

func _potion_by_id(potion_id: String) -> Dictionary:
	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		if str(potion_dict.get("id", "")) == potion_id:
			return potion_dict
	return {}

func _event_by_id(event_id: String) -> Dictionary:
	for event in event_data.get("events", []):
		var event_dict: Dictionary = event
		if str(event_dict.get("id", "")) == event_id:
			return event_dict
	return {}

func _flatten_map_nodes(graph: Dictionary) -> Array:
	var result: Array = []
	for layer in graph.get("layers", []):
		var layer_nodes: Array = layer
		for node in layer_nodes:
			result.append(node)
	return result

func _node_by_id(node_id: String) -> Dictionary:
	for node in route_nodes:
		var node_dict: Dictionary = node
		if str(node_dict.get("id", "")) == node_id:
			return node_dict
	return {}

func _node_index_by_id(node_id: String) -> int:
	for i in range(route_nodes.size()):
		var node: Dictionary = route_nodes[i]
		if str(node.get("id", "")) == node_id:
			return i
	return 0

func _next_node_ids(node_id: String) -> Array[String]:
	var result: Array[String] = []
	for edge in map_graph.get("edges", []):
		var edge_dict: Dictionary = edge
		if str(edge_dict.get("from", "")) == node_id:
			var target_id: String = str(edge_dict.get("to", ""))
			if not target_id.is_empty() and not result.has(target_id):
				result.append(target_id)
	if result.is_empty() and map_graph.is_empty():
		var next_index: int = current_node_index + 1
		if next_index >= 0 and next_index < route_nodes.size():
			result.append(str(route_nodes[next_index].get("id", "")))
	return result

func _node_detail_text(node: Dictionary) -> String:
	var node_type: String = str(node.get("type", ""))
	if _is_battle_node(node_type):
		var encounter_id: String = str(node.get("encounter_id", ""))
		var encounter: Dictionary = _encounter_by_id(encounter_id)
		var enemy_names: Array[String] = []
		for enemy_id in encounter.get("enemy_ids", []):
			var enemy: Dictionary = _enemy_by_id(str(enemy_id))
			enemy_names.append(str(enemy.get("name", enemy_id)))
		return "遭遇：%s\n敌人：%s\n%s" % [
			str(encounter.get("name", encounter_id)),
			", ".join(enemy_names),
			str(encounter.get("design_note", ""))
		]
	if node_type == "event":
		var event_id: String = str(node.get("event_id", ""))
		var event: Dictionary = _event_by_id(event_id)
		return "事件：%s\n%s" % [
			str(event.get("name", event_id)),
			str(event.get("body", ""))
		]
	if node_type == "shop":
		return "购买卡牌和药水，或花费 %d 金币移除一张牌。" % _remove_card_price()
	if node_type == "campfire":
		return "恢复 %d%% 最大生命，或升级一张未升级卡牌。" % _campfire_heal_percent()
	return ""

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()

func _create_save_state() -> Dictionary:
	var hp_to_save: int = run_hp
	if combat != null:
		hp_to_save = int(combat.player.get("hp", run_hp))
	return {
		"version": 1,
		"selected_character_id": selected_character_id,
		"run_deck_ids": run_deck_ids.duplicate(true),
		"run_relic_ids": run_relic_ids.duplicate(true),
		"run_potion_ids": run_potion_ids.duplicate(true),
		"run_hp": hp_to_save,
		"run_max_hp": run_max_hp,
		"run_gold": run_gold,
		"run_shop_remove_count": run_shop_remove_count,
		"current_challenge_level": current_challenge_level,
		"current_chapter_id": current_chapter_id,
		"completed_chapter_ids": completed_chapter_ids.duplicate(true),
		"current_node_index": current_node_index,
		"current_node_id": current_node_id,
		"available_node_ids": available_node_ids.duplicate(true),
		"completed_node_ids": completed_node_ids.duplicate(true),
		"completed_event_ids": completed_event_ids.duplicate(true),
		"map_graph": map_graph.duplicate(true),
		"run_completed": run_completed
	}

func _deck_summary() -> Dictionary:
	var summary := {
		"attack": 0,
		"skill": 0,
		"power": 0,
		"other": 0,
		"upgraded": 0
	}
	for entry_value in run_deck_ids:
		var entry: String = str(entry_value)
		var upgraded: bool = entry.ends_with("+")
		var card_id: String = entry.substr(0, entry.length() - 1) if upgraded else entry
		var card: Dictionary = _card_by_id(card_id)
		var card_type: String = str(card.get("type", "other"))
		if upgraded:
			summary["upgraded"] = int(summary["upgraded"]) + 1
		if summary.has(card_type):
			summary[card_type] = int(summary[card_type]) + 1
		else:
			summary["other"] = int(summary["other"]) + 1
	return summary

func _deck_list_text() -> String:
	var lines: Array[String] = []
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		var upgraded: bool = entry.ends_with("+")
		var card_id: String = entry.substr(0, entry.length() - 1) if upgraded else entry
		var card: Dictionary = _card_by_id(card_id)
		var name: String = str(card.get("name", card_id))
		var suffix: String = "+" if upgraded else ""
		lines.append("%02d. %s%s [%d] %s" % [i + 1, name, suffix, int(card.get("cost", 0)), card.get("type", "")])
	return "\n".join(lines)

func _deck_display_card(entry: String) -> Dictionary:
	var upgraded: bool = entry.ends_with("+")
	var card_id: String = entry.substr(0, entry.length() - 1) if upgraded else entry
	var card: Dictionary = _card_by_id(card_id).duplicate(true)
	if card.is_empty():
		return {}
	if upgraded:
		var upgrade: Dictionary = card.get("upgrade", {})
		card["name"] = "%s+" % str(card.get("name", card_id))
		card["cost"] = int(upgrade.get("cost", card.get("cost", 0)))
		card["description"] = str(upgrade.get("description", card.get("description", "")))
	return card

func _potion_summary() -> String:
	if run_potion_ids.is_empty():
		return "无"
	var names: Array[String] = []
	for potion_id in run_potion_ids:
		var potion: Dictionary = _potion_by_id(str(potion_id))
		names.append(str(potion.get("name", potion_id)))
	return ", ".join(names)

func _base_card_id(entry: String) -> String:
	return entry.substr(0, entry.length() - 1) if entry.ends_with("+") else entry

func _chapter_sequence() -> Array:
	var sequence: Array = map_generation_data.get("chapter_sequence", [])
	if sequence.is_empty():
		sequence = ["chapter_one"]
	return sequence

func _first_chapter_id() -> String:
	var sequence: Array = _chapter_sequence()
	return str(sequence[0]) if not sequence.is_empty() else "chapter_one"

func _next_chapter_id() -> String:
	var sequence: Array = _chapter_sequence()
	for i in range(sequence.size()):
		if str(sequence[i]) == current_chapter_id and i + 1 < sequence.size():
			return str(sequence[i + 1])
	return ""

func _chapter_display_name(chapter_id: String) -> String:
	var chapter_config: Dictionary = map_generation_data.get(chapter_id, {})
	return str(chapter_config.get("name", chapter_id))

func _start_next_chapter() -> bool:
	var next_chapter_id: String = _next_chapter_id()
	if next_chapter_id.is_empty():
		return false
	if not completed_chapter_ids.has(current_chapter_id):
		completed_chapter_ids.append(current_chapter_id)
	_record_chapter_completed(current_chapter_id)
	_apply_chapter_transition_recovery()
	current_chapter_id = next_chapter_id
	current_node_index = 0
	current_node_id = ""
	available_node_ids.clear()
	completed_node_ids.clear()
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	reward_generated_for = ""
	shop_generated_for = -1
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	_build_route()
	_start_current_node()
	return true

func _apply_chapter_transition_recovery() -> void:
	run_hp = run_max_hp

func _upgrade_preview_text(card: Dictionary) -> String:
	var upgrade: Dictionary = card.get("upgrade", {})
	var before_cost: int = int(card.get("cost", 0))
	var after_cost: int = int(upgrade.get("cost", before_cost))
	var before_desc: String = str(card.get("description", ""))
	var after_desc: String = str(upgrade.get("description", before_desc))
	return "%s\n费用 %d -> %d\n%s\n=> %s" % [
		card.get("name", "卡牌"),
		before_cost,
		after_cost,
		before_desc,
		after_desc
	]

func _audio_event(event_id: String) -> void:
	if not is_inside_tree():
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_event"):
		audio.play_event(event_id)

func _music_context(context_id: String) -> void:
	last_music_context = context_id
	if not is_inside_tree():
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_music_context"):
		audio.play_music_context(context_id)
		last_music_stream_path = str(audio.get("last_music_stream_path"))
		last_music_stream_loaded = bool(audio.get("last_music_stream_loaded"))
