extends Control

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const MapViewScript = preload("res://scripts/map/MapView.gd")
const CurveTrailScript = preload("res://scripts/ui/CurveTrail.gd")
const ForgeMotionScript = preload("res://scripts/ui/ForgeMotion.gd")
const AppShellScript = preload("res://scripts/ui/AppShell.gd")
const WelcomePageScript = preload("res://scripts/ui/pages/WelcomePage.gd")
const CharacterSelectPageScript = preload("res://scripts/ui/pages/CharacterSelectPage.gd")
const SettingsPageScript = preload("res://scripts/ui/pages/SettingsPage.gd")
const CompendiumPageScript = preload("res://scripts/ui/pages/CompendiumPage.gd")
const OutcomePageScript = preload("res://scripts/ui/pages/OutcomePage.gd")
const MapPageScript = preload("res://scripts/ui/pages/MapPage.gd")
const EventPageScript = preload("res://scripts/ui/pages/EventPage.gd")
const CampfirePageScript = preload("res://scripts/ui/pages/CampfirePage.gd")
const ShopExperienceScript = preload("res://scripts/ui/pages/ShopExperience.gd")
const RewardPageScript = preload("res://scripts/ui/pages/RewardPage.gd")

const ENEMY_ART_PATHS := {
	"placeholder_soot_raider": "res://assets/art/generated/enemy_soot_raider_pc.png",
	"placeholder_ash_hound": "res://assets/art/generated/enemy_ash_hound_v3_pc.png",
	"placeholder_plague_alchemist": "res://assets/art/generated/enemy_plague_alchemist_v2_pc.png",
	"placeholder_bomb_mite": "res://assets/art/generated/enemy_bomb_mite_v2_pc.png",
	"placeholder_iron_shell_guard": "res://assets/art/generated/enemy_iron_shell_guard_pc.png",
	"placeholder_thorn_shield": "res://assets/art/generated/enemy_thorn_shield_pc.png",
	"placeholder_twinblade_executor": "res://assets/art/generated/enemy_twinblade_executor_v2_pc.png",
	"placeholder_forge_bishop": "res://assets/art/generated/enemy_forge_bishop_v2_pc.png",
	"placeholder_storm_archon": "res://assets/art/generated/enemy_storm_archon_v2_pc.png",
	"placeholder_nexus_heart": "res://assets/art/generated/enemy_nexus_heart_v2_pc.png"
}
const CARD_FRAME_PATHS := {
	"attack": "res://assets/art/card_attack_frame.svg",
	"skill": "res://assets/art/card_skill_frame.svg",
	"power": "res://assets/art/card_power_frame.svg"
}
const PC_CARD_MATERIAL_FRAME_PATHS := {
	"attack": "res://assets/art/generated/ui/card_frames/card_frame_attack_v2_pc.png",
	"skill": "res://assets/art/generated/ui/card_frames/card_frame_skill_v2_pc.png",
	"power": "res://assets/art/generated/ui/card_frames/card_frame_power_v5_pc.png"
}
const POTION_ART_PATH := "res://assets/art/potion_placeholder.svg"
const RELIC_ART_PATH := "res://assets/art/relic_placeholder.svg"
const EVENT_ART_PATH := "res://assets/art/event_default.svg"
const UI_BACKDROP_PATH := "res://assets/art/generated/ui_backdrop_pc.png"
const UI_MENU_BACKDROP_PATH := "res://assets/art/generated/ui/menu_backdrop_v3_pc.png"
const UI_RESOURCE_CHIP_PATH := "res://assets/art/generated/ui/ui_resource_chip_pc.png"
const UI_HAND_TRAY_PATH := "res://assets/art/generated/ui/ui_hand_tray_pc.png"
const UI_ENEMY_PLATE_PATH := "res://assets/art/generated/ui/ui_enemy_plate_pc.png"
const UI_END_TURN_BUTTON_PATH := "res://assets/art/generated/ui/ui_end_turn_button_pc.png"
const UI_FEEDBACK_TOAST_PATH := "res://assets/art/generated/ui/ui_feedback_toast_pc.png"
const HUD_ICON_PATHS := {
	"回合": "res://assets/art/generated/ui/icons/hud_turn.svg",
	"生命": "res://assets/art/generated/ui/icons/hud_hp.svg",
	"护甲": "res://assets/art/generated/ui/icons/hud_block.svg",
	"能量": "res://assets/art/generated/ui/icons/hud_energy.svg",
	"势能": "res://assets/art/generated/ui/icons/hud_momentum.svg",
	"金币": "res://assets/art/generated/ui/icons/hud_gold.svg",
	"抽牌": "res://assets/art/generated/ui/icons/hud_draw.svg",
	"弃牌": "res://assets/art/generated/ui/icons/hud_discard.svg",
	"消耗": "res://assets/art/generated/ui/icons/hud_exhaust.svg"
}
const INTENT_ICON_PATHS := {
	"attack": "res://assets/art/generated/ui/icons/intent_attack.svg",
	"attack_debuff": "res://assets/art/generated/ui/icons/intent_attack.svg",
	"attack_block": "res://assets/art/generated/ui/icons/intent_attack.svg",
	"attack_buff": "res://assets/art/generated/ui/icons/intent_attack.svg",
	"attack_status_card": "res://assets/art/generated/ui/icons/intent_attack.svg",
	"block": "res://assets/art/generated/ui/icons/hud_block.svg",
	"block_buff": "res://assets/art/generated/ui/icons/hud_block.svg",
	"buff": "res://assets/art/generated/ui/icons/intent_buff.svg",
	"debuff": "res://assets/art/generated/ui/icons/intent_debuff.svg",
	"status_card": "res://assets/art/generated/ui/icons/intent_debuff.svg"
}
const UI_DECK_ICON_PATH := "res://assets/art/generated/ui/icons/hud_draw.svg"
const UI_SETTINGS_ICON_PATH := "res://assets/art/generated/ui/icons/control_settings.svg"
const UI_NEW_RUN_ICON_PATH := "res://assets/art/generated/ui/icons/control_new_run.svg"
const UI_LOAD_RUN_ICON_PATH := "res://assets/art/generated/ui/icons/control_load_run.svg"
const UI_SAVE_RUN_ICON_PATH := "res://assets/art/generated/ui/icons/control_save_run.svg"
const UI_EXPORT_REPORT_ICON_PATH := "res://assets/art/generated/ui/icons/control_export_report.svg"
const UI_RETRY_RUN_ICON_PATH := "res://assets/art/generated/ui/icons/control_retry.svg"
const UI_PROFILE_ICON_PATH := "res://assets/art/generated/ui/icons/control_profile.svg"
const UI_COMPENDIUM_ICON_PATH := "res://assets/art/generated/ui/icons/control_compendium.svg"
const UI_TUTORIAL_ICON_PATH := "res://assets/art/generated/ui/icons/control_tutorial.svg"
const UI_SKIP_REWARD_ICON_PATH := "res://assets/art/generated/ui/icons/control_skip_reward.svg"
const UI_CONTINUE_ROUTE_ICON_PATH := "res://assets/art/generated/ui/icons/control_continue_route.svg"
const UI_FONT_PATH := "res://assets/fonts/NotoSansSC-Variable.ttf"
const PLAYTEST_BUILD_LABEL := "0.1.0-alpha.9-preview"
const PLAYER_ART_PATHS := {
	"ember_exile": "res://assets/art/generated/player_ember_exile_pc.png",
	"arc_tinker": "res://assets/art/generated/player_arc_tinker_pc.png",
	"pyre_ascetic": "res://assets/art/generated/player_pyre_ascetic_pc.png"
}
const PLAYER_STAGE_ART_PATHS := {
	"ember_exile": "res://assets/art/generated/player_ember_exile_stage_pc.png",
	"arc_tinker": "res://assets/art/generated/player_arc_tinker_stage_pc.png",
	"pyre_ascetic": "res://assets/art/generated/player_pyre_ascetic_stage_pc.png"
}
const ROOT_MARGIN_LEFT := 14.0
const ROOT_MARGIN_RIGHT := 14.0
const ROOT_MARGIN_TOP := 10.0
const ROOT_MARGIN_BOTTOM := 10.0
const SCROLLBAR_WIDTH_RESERVE := 24.0
const MIN_SAFE_CONTENT_WIDTH := 220.0
const PC_HAND_CARD_WIDTH := 136.0
const PC_HAND_LEFT_DOCK_WIDTH := 82.0
const PC_HAND_RIGHT_DOCK_WIDTH := 112.0
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
var profile_character_id: String = "ember_exile"
var welcome_open: bool = true
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
var progression_data: Dictionary = {}
var monster_scaling_data: Dictionary = {}
var level_tree_data: Dictionary = {}
var raw_svg_texture_cache: Dictionary = {}
var menu_backdrop_tween: Tween
var screen_shake_tween: Tween
var feedback_label_tween: Tween
var cinematic_tween: Tween
var boss_phase_banner_tween: Tween
var stage_forecast_refresh_pending: bool = false

var run_deck_ids: Array = []
var run_relic_ids: Array = []
var run_potion_ids: Array = []
var run_hp: int = 0
var run_max_hp: int = 0
var run_gold: int = 0
var run_shop_remove_count: int = 0
var run_character_config: Dictionary = {}
var run_progression_node_ids: Array = []
var run_completed: bool = false
var current_chapter_id: String = "chapter_one"
var completed_chapter_ids: Array = []
var selected_challenge_level: int = 0
var current_challenge_level: int = 0
var run_skill_book_id: String = "steel_manual"
var run_deck_mastery_id: String = ""
var settings_open: bool = false
var tutorial_open: bool = false
var profile_open: bool = false
var compendium_open: bool = false
var pile_view_open: bool = false
var pile_view_kind: String = ""
var selected_compendium_tab: String = "cards"
var selected_compendium_filter: String = "all"
var selected_compendium_sort: String = "name"
var selected_compendium_search: String = ""
var compendium_reveal_all_details: bool = false
var user_settings: Dictionary = {}
var player_profile: Dictionary = {}
var playtest_store: Dictionary = {}
var playtest_config_fingerprint: String = ""

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
var shop_relic_options: Array = []
var shop_potion_options: Array = []
var treasure_reward_gold: int = 0
var combat_reward_gold: int = 0
var reward_generated_for: String = ""
var restoring_combat_reward_state: bool = false
var shop_generated_for: int = -1
var shop_remove_selection_open: bool = false
var campfire_upgrade_selection_open: bool = false
var card_reward_done: bool = false
var relic_reward_done: bool = true
var potion_reward_done: bool = true
var deck_view_open: bool = false
var deck_view_filter: String = "all"
var deck_view_sort: String = "type"

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
var battle_forecast_layer: Control
var battle_foreground_layer: Control
var player_stage_art: TextureRect
var player_stage_plate: PanelContainer
var player_stage_hp_fill: ColorRect
var player_stage_hp_label: Label
var player_stage_block_icon: TextureRect
var player_stage_block_label: Label
var hand_frame: PanelContainer
var hand_dock_row: HBoxContainer
var hand_left_hud: VBoxContainer
var hand_right_hud: VBoxContainer
var hand_energy_panel: PanelContainer
var hand_energy_value_label: Label
var hand_draw_button: Button
var hand_discard_button: Button
var hand_exhaust_button: Button
var hand_scroll: ScrollContainer
var combat_hud_row: HBoxContainer
var feedback_label: Label
var feedback_overlay: Control
var card_detail_preview: Button
var pile_overlay: Control
var pile_panel: PanelContainer
var pile_title_label: Label
var pile_summary_label: Label
var pile_tab_row: HBoxContainer
var pile_cards_scroll: ScrollContainer
var pile_cards_flow: HFlowContainer
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
var app_shell
var log_label: RichTextLabel
var controls_scroll: ScrollContainer
var controls_row: HBoxContainer
var controls_spacer: Control
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
var last_hit_stop_request_count: int = 0
var last_hit_stop_scope: String = ""
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
var last_boss_phase_badge_count: int = 0
var last_boss_phase_badge_texts: Array[String] = []
var last_boss_phase_threshold_marker_count: int = 0
var last_boss_phase_banner_visible: bool = false
var last_boss_phase_banner_title: String = ""
var last_boss_phase_banner_note: String = ""
var last_boss_phase_banner_effect: String = ""
var last_boss_phase_banner_intent: String = ""
var last_card_preview_index: int = -1
var last_card_preview_card_id: String = ""
var last_card_preview_target_id: String = ""
var last_card_target_line_count: int = 0
var last_card_play_animation_count: int = 0
var last_card_play_card_id: String = ""
var last_card_play_target_id: String = ""
var last_card_play_trajectory_points: Array[Vector2] = []
var last_card_trail_segment_count: int = 0
var last_card_flight_uses_card_art: bool = false
var last_card_effect_profile: String = ""
var last_card_particle_count: int = 0
var last_card_audio_event: String = ""
var last_card_vfx_asset_path: String = ""
var last_card_vfx_asset_loaded: bool = false
var last_player_action_animation_count: int = 0
var last_player_action_animation_type: String = ""
var last_player_reaction_animation_count: int = 0
var last_enemy_reaction_animation_count: int = 0
var last_enemy_action_animation_count: int = 0
var last_enemy_action_ids: Array[String] = []
var combat_presentation_busy: bool = false
var combat_presentation_ticket: int = 0
var combat_presentation_sequence: Array[String] = []
var combat_presentation_instant_override: bool = false
var last_player_stage_plate_visible: bool = false
var last_player_stage_hp_text: String = ""
var last_player_stage_block_text: String = ""
var last_hand_card_art_path: String = ""
var last_hand_card_art_loaded: bool = false
var last_hand_card_layout_count: int = 0
var last_hand_card_art_node_count: int = 0
var last_hand_card_material_frame_count: int = 0
var last_hand_dock_control_count: int = 0
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
var last_shop_relic_layout_count: int = 0
var last_shop_relic_icon_node_count: int = 0
var last_shop_remove_candidate_count: int = 0
var last_shop_remove_card_layout_count: int = 0
var last_shop_remove_card_art_node_count: int = 0
var last_campfire_card_layout_count: int = 0
var last_campfire_card_art_node_count: int = 0
var last_campfire_art_path: String = ""
var last_campfire_art_loaded: bool = false
var last_campfire_action_count: int = 0
var last_campfire_upgrade_candidate_count: int = 0
var last_campfire_reveal_animation_count: int = 0
var last_deck_view_card_layout_count: int = 0
var last_deck_view_card_art_node_count: int = 0
var last_deck_view_visible_card_count: int = 0
var last_deck_view_filter_button_count: int = 0
var last_deck_view_sort_option_count: int = 0
var last_deck_view_toolbar_visible: bool = false
var last_deck_view_cost_curve_text: String = ""
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
var last_combat_gold_reward: int = 0
var last_reward_gold_panel_count: int = 0
var last_reward_action_button_count: int = 0
var last_reward_action_icon_node_count: int = 0
var last_mastery_reward_option_count: int = 0
var last_mastery_reward_pending: bool = false
var last_treasure_gold_reward: int = 0
var last_treasure_relic_layout_count: int = 0
var last_treasure_relic_icon_node_count: int = 0
var last_event_choice_blocked_reason: String = ""
var last_event_choice_layout_count: int = 0
var last_event_result_id: String = ""
var last_event_result_label: String = ""
var last_event_art_path: String = ""
var last_event_art_loaded: bool = false
var last_event_panel_title: String = ""
var last_event_panel_body: String = ""
var last_event_panel_choice_count: int = 0
var last_event_reveal_animation_count: int = 0
var last_run_completion_title: String = ""
var last_run_completion_summary: String = ""
var last_run_unlocks: Array[String] = []
var last_run_completion_panel_visible: bool = false
var last_run_completion_art_path: String = ""
var last_run_completion_art_loaded: bool = false
var last_run_completion_stat_chip_count: int = 0
var last_run_completion_unlock_chip_count: int = 0
var last_run_completion_action_count: int = 0
var last_run_completion_export_button_visible: bool = false
var last_defeat_panel_visible: bool = false
var last_defeat_art_path: String = ""
var last_defeat_art_loaded: bool = false
var last_defeat_scene_enemy_count: int = 0
var last_defeat_stat_chip_count: int = 0
var last_defeat_action_count: int = 0
var last_defeat_forge_marks_earned: int = 0
var last_defeat_summary: String = ""
var last_defeat_reveal_animation_count: int = 0
var last_character_selection_title: String = ""
var last_character_selection_ids: Array[String] = []
var last_character_selection_confirm_visible: bool = false
var last_character_selection_selected_id: String = ""
var last_welcome_action_count: int = 0
var last_welcome_continue_available: bool = false
var last_character_button_icon_count: int = 0
var last_campfire_button_style_count: int = 0
var last_shop_button_style_count: int = 0
var last_event_choice_style_count: int = 0
var last_reward_button_style_count: int = 0
var last_combat_hud_text: String = ""
var last_combat_hud_block_count: int = 0
var last_combat_hud_icon_node_count: int = 0
var last_pile_view_visible: bool = false
var last_pile_view_kind: String = ""
var last_pile_view_card_count: int = 0
var last_pile_view_art_node_count: int = 0
var last_pile_view_tab_count: int = 0
var last_stage_forecast_marker_count: int = 0
var last_stage_forecast_beam_count: int = 0
var last_stage_forecast_icon_count: int = 0
var last_stage_foreground_layer_count: int = 0
var last_feedback_label_suppressed_for_stage: bool = false
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
var last_enemy_stage_info_count: int = 0
var last_enemy_stage_info_texts: Array[String] = []
var last_card_detail_preview_visible: bool = false
var last_card_detail_preview_card_id: String = ""
var last_card_detail_preview_description: String = ""
var last_combat_hotkey_action: String = ""
var last_combat_hotkey_count: int = 0
var last_combat_hotkey_index: int = -1
var last_map_preview_node_id: String = ""
var last_map_preview_text: String = ""
var last_map_preview_risk_level: String = ""
var last_map_preview_reward_summary: String = ""
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
var last_settings_reduced_motion: bool = false
var last_settings_flash_intensity: float = 1.0
var last_settings_particle_density: float = 1.0
var last_settings_save_ok: bool = false
var last_profile_panel_visible: bool = false
var last_profile_button_count: int = 0
var last_profile_summary: String = ""
var last_profile_unlocked_count: int = 0
var last_profile_total_count: int = 0
var last_profile_last_unlock_text: String = ""
var last_profile_forge_marks: int = 0
var last_profile_upgrade_node_count: int = 0
var last_profile_skill_book_count: int = 0
var last_profile_save_ok: bool = false
var last_run_save_cleanup_ok: bool = true
var last_terminal_run_id: String = ""
var last_terminal_persistence_error: String = ""
var last_profile_character_selector_count: int = 0
var last_profile_export_button_visible: bool = false
var last_playtest_export_ok: bool = false
var last_playtest_export_path: String = ""
var last_playtest_export_run_count: int = 0
var last_playtest_export_summary: String = ""
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
var card_drag_candidate_index: int = -1
var card_drag_active: bool = false
var card_drag_index: int = -1
var card_drag_target_index: int = -1
var card_drag_start_mouse: Vector2 = Vector2.ZERO
var card_drag_pointer: Vector2 = Vector2.ZERO
var card_drag_ghost: Button
var card_drag_curve: Control
var card_drag_target_ring: PanelContainer
var card_drag_source_button: Button
var card_drag_suppress_click_index: int = -1
var last_card_drag_started_count: int = 0
var last_card_drag_played_count: int = 0
var last_card_drag_cancelled_count: int = 0
var last_card_drag_valid: bool = false
var last_card_drag_target_id: String = ""
var last_card_drag_ghost_uses_art: bool = false
var last_card_drag_curve_point_count: int = 0
var hit_stop_ticket: int = 0
var hit_stop_active: bool = false
var hit_stop_restore_process_mode: int = Node.PROCESS_MODE_INHERIT
var hit_stop_deadline_msec: int = 0
var refresh_call_count: int = 0
var layout_refresh_pending: bool = false
var last_music_context: String = ""
var last_music_stream_path: String = ""
var last_music_stream_loaded: bool = false

func _ready() -> void:
	_load_user_settings()
	_load_player_profile()
	_load_playtest_store()
	_apply_ui_font_theme()
	_build_layout()
	_apply_runtime_settings()
	_load_all_data()
	selected_character_id = _valid_character_id(selected_character_id)
	_open_welcome(false)

func _apply_ui_font_theme() -> void:
	if not ResourceLoader.exists(UI_FONT_PATH):
		return
	var ui_font = load(UI_FONT_PATH)
	if not ui_font is Font:
		return
	var ui_theme := Theme.new()
	ui_theme.default_font = ui_font
	ui_theme.default_font_size = 14
	theme = ui_theme

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_layout_widths()
		if is_node_ready() and not layout_refresh_pending:
			layout_refresh_pending = true
			call_deferred("_refresh_after_resize")

func _exit_tree() -> void:
	combat_presentation_ticket += 1
	combat_presentation_busy = false
	_restore_battle_stage_processing()

func _refresh_after_resize() -> void:
	layout_refresh_pending = false
	if not is_inside_tree() or page_scroll == null:
		return
	if card_drag_active or card_drag_candidate_index >= 0:
		_cancel_card_drag()
	_refresh()

func _input(event: InputEvent) -> void:
	if _handle_card_drag_input(event):
		get_viewport().set_input_as_handled()
		return
	if _handle_combat_hotkey(event):
		get_viewport().set_input_as_handled()

func _handle_card_drag_input(event: InputEvent) -> bool:
	if not _is_pc_layout() or combat == null:
		return false
	if event is InputEventMouseMotion and card_drag_candidate_index >= 0:
		var motion := event as InputEventMouseMotion
		card_drag_pointer = motion.position
		if not card_drag_active and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and card_drag_start_mouse.distance_to(card_drag_pointer) >= 10.0:
			_begin_card_drag(card_drag_candidate_index, card_drag_pointer)
		if card_drag_active:
			_update_card_drag(card_drag_pointer)
			return true
		return false
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT and mouse_button.pressed and card_drag_active:
			_cancel_card_drag()
			return true
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed and card_drag_candidate_index >= 0:
			if card_drag_active:
				card_drag_pointer = mouse_button.position
				_update_card_drag(card_drag_pointer)
				_finish_card_drag(last_card_drag_valid)
				return true
			else:
				card_drag_candidate_index = -1
	return false

func _unhandled_input(event: InputEvent) -> void:
	if card_drag_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_cancel_card_drag()
		get_viewport().set_input_as_handled()
		return
	if pile_view_open and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_pile_view()
		get_viewport().set_input_as_handled()
		return
	if _handle_combat_hotkey(event):
		get_viewport().set_input_as_handled()

func _handle_combat_hotkey(event: InputEvent) -> bool:
	if not _combat_hotkeys_allowed() or not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return false
	match key_event.keycode:
		KEY_SPACE:
			last_combat_hotkey_action = "end_turn"
			last_combat_hotkey_index = -1
			last_combat_hotkey_count += 1
			_on_end_turn_pressed()
			return true
		KEY_TAB:
			var next_index: int = _next_living_enemy_index()
			if next_index < 0:
				return false
			last_combat_hotkey_action = "cycle_target"
			last_combat_hotkey_index = next_index
			last_combat_hotkey_count += 1
			_on_enemy_pressed(next_index)
			return true
		KEY_1, KEY_2, KEY_3, KEY_KP_1, KEY_KP_2, KEY_KP_3:
			var potion_index: int = _potion_index_for_key(key_event.keycode)
			if potion_index < 0 or potion_index >= run_potion_ids.size():
				return false
			last_combat_hotkey_action = "use_potion"
			last_combat_hotkey_index = potion_index
			last_combat_hotkey_count += 1
			_on_potion_pressed(potion_index)
			return true
	return false

func _potion_index_for_key(keycode: Key) -> int:
	match keycode:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
	return -1

func _combat_hotkeys_allowed() -> bool:
	if combat_presentation_busy or not _is_pc_layout() or combat == null or combat.phase != "player" or card_drag_active:
		return false
	if pile_view_open or deck_view_open or settings_open or profile_open or compendium_open or tutorial_open:
		return false
	if welcome_open or character_select_open or run_completed:
		return false
	if is_inside_tree():
		var focus_owner: Control = get_viewport().gui_get_focus_owner()
		if focus_owner is LineEdit or focus_owner is TextEdit:
			return false
	return true

func _next_living_enemy_index() -> int:
	if combat == null or combat.enemies.is_empty():
		return -1
	for offset in range(1, combat.enemies.size() + 1):
		var candidate: int = (selected_enemy_index + offset) % combat.enemies.size()
		if int(combat.enemies[candidate].get("hp", 0)) > 0:
			return candidate
	return -1

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
	page_scroll.set("vertical_scroll_mode", 0 if _is_pc_layout() else 1)
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
	battle_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	battle_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	battle_background.modulate = Color(1, 1, 1, 0.86)
	enemy_stage_stack.add_child(battle_background)

	battle_stage_scrim = ColorRect.new()
	battle_stage_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_stage_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_stage_scrim.color = Color(0.02, 0.025, 0.03, 0.18)
	enemy_stage_stack.add_child(battle_stage_scrim)

	battle_forecast_layer = Control.new()
	battle_forecast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_forecast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_forecast_layer.clip_contents = true
	enemy_stage_stack.add_child(battle_forecast_layer)

	player_stage_art = TextureRect.new()
	player_stage_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_stage_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_stage_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_stage_art.modulate = Color(1.0, 1.0, 1.0, 0.92)
	enemy_stage_stack.add_child(player_stage_art)

	player_stage_plate = PanelContainer.new()
	player_stage_plate.name = "PlayerStagePlate"
	player_stage_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_stage_plate.custom_minimum_size = Vector2(238, 30)
	player_stage_plate.add_theme_stylebox_override("panel", _player_stage_plate_style())
	enemy_stage_stack.add_child(player_stage_plate)

	var player_plate_margin := MarginContainer.new()
	player_plate_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_plate_margin.add_theme_constant_override("margin_left", 6)
	player_plate_margin.add_theme_constant_override("margin_right", 6)
	player_plate_margin.add_theme_constant_override("margin_top", 4)
	player_plate_margin.add_theme_constant_override("margin_bottom", 4)
	player_stage_plate.add_child(player_plate_margin)

	var player_plate_row := HBoxContainer.new()
	player_plate_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_plate_row.add_theme_constant_override("separation", 5)
	player_plate_margin.add_child(player_plate_row)

	var hp_icon := TextureRect.new()
	hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_icon.custom_minimum_size = Vector2(20, 20)
	hp_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hp_icon.texture = _load_texture(_hud_icon_path("生命"))
	hp_icon.modulate = Color(1.0, 0.54, 0.38, 1.0)
	player_plate_row.add_child(hp_icon)

	var player_hp_bar := Control.new()
	player_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_hp_bar.custom_minimum_size = Vector2(138, 18)
	player_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_hp_bar.clip_contents = true
	player_plate_row.add_child(player_hp_bar)

	var player_hp_bg := ColorRect.new()
	player_hp_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	player_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_hp_bg.color = Color(0.040, 0.028, 0.026, 0.96)
	player_hp_bar.add_child(player_hp_bg)

	player_stage_hp_fill = ColorRect.new()
	player_stage_hp_fill.anchor_left = 0.0
	player_stage_hp_fill.anchor_top = 0.0
	player_stage_hp_fill.anchor_right = 1.0
	player_stage_hp_fill.anchor_bottom = 1.0
	player_stage_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_stage_hp_fill.color = Color(0.78, 0.12, 0.075, 0.96)
	player_hp_bar.add_child(player_stage_hp_fill)

	player_stage_hp_label = Label.new()
	player_stage_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	player_stage_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_stage_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_stage_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_stage_hp_label.add_theme_font_size_override("font_size", 11)
	player_stage_hp_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.80))
	player_stage_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	player_stage_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	player_stage_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	player_hp_bar.add_child(player_stage_hp_label)

	player_stage_block_icon = TextureRect.new()
	player_stage_block_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_stage_block_icon.custom_minimum_size = Vector2(20, 20)
	player_stage_block_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	player_stage_block_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_stage_block_icon.texture = _load_texture(_hud_icon_path("护甲"))
	player_stage_block_icon.modulate = Color(0.48, 0.90, 1.0, 0.96)
	player_plate_row.add_child(player_stage_block_icon)

	player_stage_block_label = Label.new()
	player_stage_block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_stage_block_label.custom_minimum_size = Vector2(24, 0)
	player_stage_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_stage_block_label.add_theme_font_size_override("font_size", 12)
	player_stage_block_label.add_theme_color_override("font_color", Color(0.76, 0.94, 1.0))
	player_plate_row.add_child(player_stage_block_label)

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

	battle_foreground_layer = Control.new()
	battle_foreground_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_foreground_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_foreground_layer.clip_contents = true
	enemy_stage_stack.add_child(battle_foreground_layer)
	_rebuild_stage_foreground_layer()

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

	_add_generated_texture_background(hand_frame, UI_HAND_TRAY_PATH, 0.42)

	hand_dock_row = HBoxContainer.new()
	hand_dock_row.name = "HandDockRow"
	hand_dock_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_dock_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_dock_row.add_theme_constant_override("separation", 8)
	hand_frame.add_child(hand_dock_row)

	hand_left_hud = VBoxContainer.new()
	hand_left_hud.name = "HandLeftHud"
	hand_left_hud.custom_minimum_size = Vector2(72, 0)
	hand_left_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_left_hud.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_left_hud.add_theme_constant_override("separation", 8)
	hand_dock_row.add_child(hand_left_hud)

	hand_energy_panel = _create_hand_energy_panel()
	hand_left_hud.add_child(hand_energy_panel)
	hand_draw_button = _create_hand_pile_button("draw", "抽牌堆", HUD_ICON_PATHS.get("抽牌", ""))
	hand_left_hud.add_child(hand_draw_button)

	hand_scroll = ScrollContainer.new()
	hand_scroll.custom_minimum_size = Vector2(0, 140)
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_scroll.clip_contents = true
	hand_scroll.set("horizontal_scroll_mode", 1)
	hand_scroll.set("vertical_scroll_mode", 0)
	hand_dock_row.add_child(hand_scroll)

	hand_row = HBoxContainer.new()
	hand_row.custom_minimum_size = Vector2(0, 140)
	hand_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hand_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", 6)
	hand_row.sort_children.connect(_apply_hand_card_transforms, CONNECT_DEFERRED)
	hand_scroll.add_child(hand_row)

	hand_right_hud = VBoxContainer.new()
	hand_right_hud.name = "HandRightHud"
	hand_right_hud.custom_minimum_size = Vector2(72, 0)
	hand_right_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_right_hud.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_right_hud.add_theme_constant_override("separation", 8)
	hand_dock_row.add_child(hand_right_hud)

	hand_discard_button = _create_hand_pile_button("discard", "弃牌堆", HUD_ICON_PATHS.get("弃牌", ""))
	hand_right_hud.add_child(hand_discard_button)
	hand_exhaust_button = _create_hand_pile_button("exhaust", "消耗堆", HUD_ICON_PATHS.get("消耗", ""))
	hand_right_hud.add_child(hand_exhaust_button)

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

	app_shell = AppShellScript.new()
	app_shell.name = "MenuAppShell"
	app_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app_shell.z_index = 8
	app_shell.visible = false
	add_child(app_shell)

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

	controls_spacer = Control.new()
	controls_spacer.visible = false
	controls_spacer.custom_minimum_size = Vector2(0, 1)
	controls_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_row.add_child(controls_spacer)

	feedback_overlay = Control.new()
	feedback_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_overlay.z_index = 20
	add_child(feedback_overlay)
	_build_card_detail_preview()

	_build_pile_overlay()
	_build_cinematic_overlay()

func _sync_layout_widths() -> void:
	if page_scroll != null:
		page_scroll.set("vertical_scroll_mode", 0 if _is_pc_layout() else 1)
	var content_width: float = _scroll_content_width()
	var page_width: float = content_width + _root_horizontal_margin()
	if page_margin != null:
		page_margin.custom_minimum_size = Vector2(max(MIN_SAFE_CONTENT_WIDTH, page_width), 0)
	if root_box != null:
		root_box.custom_minimum_size = Vector2(content_width, 0)
		root_box.size = Vector2(content_width, root_box.size.y)
	_sync_pile_overlay_layout()

func _build_card_detail_preview() -> void:
	card_detail_preview = Button.new()
	card_detail_preview.name = "CardDetailPreview"
	card_detail_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_detail_preview.focus_mode = Control.FOCUS_NONE
	card_detail_preview.custom_minimum_size = Vector2(220, 320)
	card_detail_preview.size = card_detail_preview.custom_minimum_size
	card_detail_preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card_detail_preview.position = Vector2(22, 70)
	card_detail_preview.z_index = 130
	card_detail_preview.visible = false
	feedback_overlay.add_child(card_detail_preview)

func _build_pile_overlay() -> void:
	pile_overlay = Control.new()
	pile_overlay.name = "PileOverlay"
	pile_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pile_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pile_overlay.visible = false
	pile_overlay.z_index = 25
	add_child(pile_overlay)

	var dismiss := Button.new()
	dismiss.name = "PileDismissArea"
	dismiss.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss.text = ""
	dismiss.focus_mode = Control.FOCUS_NONE
	dismiss.add_theme_stylebox_override("normal", _pile_dismiss_style(false))
	dismiss.add_theme_stylebox_override("hover", _pile_dismiss_style(false))
	dismiss.add_theme_stylebox_override("pressed", _pile_dismiss_style(true))
	dismiss.pressed.connect(_on_close_pile_view_pressed)
	pile_overlay.add_child(dismiss)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile_overlay.add_child(center)

	pile_panel = PanelContainer.new()
	pile_panel.name = "PilePanel"
	pile_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pile_panel.clip_contents = true
	pile_panel.add_theme_stylebox_override("panel", _pile_panel_style())
	center.add_child(pile_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	pile_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 42)
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", -2)
	header.add_child(title_box)

	pile_title_label = Label.new()
	pile_title_label.text = "牌堆"
	pile_title_label.add_theme_font_size_override("font_size", 22)
	pile_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	title_box.add_child(pile_title_label)

	pile_summary_label = Label.new()
	pile_summary_label.text = ""
	pile_summary_label.clip_text = true
	pile_summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pile_summary_label.add_theme_font_size_override("font_size", 11)
	pile_summary_label.add_theme_color_override("font_color", Color(0.70, 0.76, 0.74))
	title_box.add_child(pile_summary_label)

	var close_button := Button.new()
	close_button.name = "PileCloseButton"
	close_button.custom_minimum_size = Vector2(38, 38)
	close_button.text = "×"
	close_button.tooltip_text = "关闭牌堆"
	close_button.add_theme_font_size_override("font_size", 22)
	_apply_button_skin(close_button, "neutral")
	close_button.pressed.connect(_on_close_pile_view_pressed)
	header.add_child(close_button)

	pile_tab_row = HBoxContainer.new()
	pile_tab_row.custom_minimum_size = Vector2(0, 38)
	pile_tab_row.add_theme_constant_override("separation", 8)
	box.add_child(pile_tab_row)

	pile_cards_scroll = ScrollContainer.new()
	pile_cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pile_cards_scroll.clip_contents = true
	pile_cards_scroll.set("horizontal_scroll_mode", 0)
	pile_cards_scroll.set("vertical_scroll_mode", 1)
	box.add_child(pile_cards_scroll)

	pile_cards_flow = HFlowContainer.new()
	pile_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_cards_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pile_cards_flow.add_theme_constant_override("h_separation", 10)
	pile_cards_flow.add_theme_constant_override("v_separation", 10)
	pile_cards_scroll.add_child(pile_cards_flow)
	_sync_pile_overlay_layout()

func _sync_pile_overlay_layout() -> void:
	if pile_panel == null or pile_cards_flow == null:
		return
	var viewport_size: Vector2 = _layout_viewport_size()
	var panel_width: float = clamp(viewport_size.x - 96.0, 760.0, 1180.0)
	var panel_height: float = clamp(viewport_size.y - 80.0, 500.0, 720.0)
	if _is_pc_layout():
		var card_size: Vector2 = _pile_card_size()
		var content_width: float = max(220.0, panel_width - 44.0)
		var columns: int = max(1, int(floor((content_width + 10.0) / (card_size.x + 10.0))))
		var card_count: int = _pile_cards(pile_view_kind).size() if combat != null and pile_view_open else 0
		var rows: int = max(1, int(ceil(float(max(1, card_count)) / float(columns))))
		var cards_height: float = float(rows) * card_size.y + float(max(0, rows - 1)) * 10.0
		panel_height = clamp(142.0 + cards_height, 382.0, viewport_size.y - 80.0)
	if not _is_pc_layout():
		panel_width = max(260.0, viewport_size.x - 24.0)
		panel_height = max(360.0, viewport_size.y - 24.0)
	pile_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	pile_cards_flow.custom_minimum_size = Vector2(max(220.0, panel_width - 44.0), 0)

func _pile_dismiss_style(pressed: bool) -> StyleBoxFlat:
	var alpha: float = 0.78 if pressed else 0.70
	var style := _button_style(Color(0.005, 0.007, 0.010, alpha), Color(0, 0, 0, 0), 0, 0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _pile_panel_style() -> StyleBoxFlat:
	var style := _button_style(Color(0.035, 0.042, 0.046, 0.98), Color(0.72, 0.54, 0.30, 0.92), 2, 8)
	style.shadow_color = Color(0, 0, 0, 0.76)
	style.shadow_size = 14
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

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
	if playtest_store.is_empty():
		_load_playtest_store()
	_finish_active_playtest_run("abandoned", "new_run_started")

	if not character_id.is_empty():
		selected_character_id = character_id
	selected_character_id = _valid_character_id(selected_character_id)
	selected_challenge_level = _valid_challenge_level(selected_challenge_level)
	current_challenge_level = selected_challenge_level
	run_skill_book_id = _equipped_skill_book_for_character(selected_character_id)
	run_deck_mastery_id = ""
	run_progression_node_ids = _purchased_upgrade_node_ids_for_character(selected_character_id)
	run_character_config = _effective_character_config(selected_character_id)
	_close_pile_view(false)
	welcome_open = false
	character_select_open = false
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	var player_config: Dictionary = run_character_config
	run_deck_ids = _starter_deck_for_character(player_config)
	run_relic_ids = _starter_relics_for_character(player_config)
	run_potion_ids = player_config.get("starting_potions", []).duplicate(true)
	run_max_hp = int(player_config.get("max_hp", 72))
	run_hp = int(player_config.get("starting_hp", run_max_hp))
	run_hp = max(1, run_hp - _challenge_player_starting_hp_loss(current_challenge_level))
	run_gold = int(player_config.get("starting_gold", 0))
	run_shop_remove_count = 0
	run_completed = false
	last_run_save_cleanup_ok = true
	last_terminal_run_id = ""
	last_terminal_persistence_error = ""
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
	shop_relic_options.clear()
	shop_potion_options.clear()
	treasure_reward_gold = 0
	combat_reward_gold = 0
	reward_generated_for = ""
	shop_generated_for = -1
	shop_remove_selection_open = false
	campfire_upgrade_selection_open = false
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	_start_playtest_run()
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
	_close_pile_view(false)
	welcome_open = false
	character_select_open = true
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	run_character_config.clear()
	run_progression_node_ids.clear()
	combat = null
	run_completed = false
	current_node_id = ""
	available_node_ids.clear()
	if play_audio:
		_audio_event("ui_click")
	_refresh()

func _open_welcome(play_audio: bool = true) -> void:
	if player_data.is_empty():
		_load_all_data()
	welcome_open = true
	character_select_open = false
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	run_character_config.clear()
	combat = null
	if play_audio:
		_audio_event("ui_click")
	_refresh()

func _on_new_run_pressed() -> void:
	if is_inside_tree():
		_open_character_select.call_deferred()
	else:
		_open_character_select()

func _on_welcome_pressed() -> void:
	_open_welcome()

func _on_character_selected(character_id: String) -> void:
	_start_new_run(character_id)

func _on_character_preview_selected(character_id: String) -> void:
	selected_character_id = _valid_character_id(character_id)
	last_character_selection_selected_id = selected_character_id
	_audio_event("ui_click")

func _on_character_confirm_pressed() -> void:
	_start_new_run(selected_character_id)

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
	progression_data = DataLoaderScript.load_json("res://data/config/progression_systems.json")
	monster_scaling_data = DataLoaderScript.load_json("res://data/config/monster_scaling.json")
	level_tree_data = DataLoaderScript.load_json("res://data/config/level_tree.json")
	playtest_config_fingerprint = PlaytestTelemetryScript.configuration_fingerprint()

func _load_user_settings() -> void:
	user_settings = SaveManagerScript.load_settings()
	_apply_runtime_settings()

func _load_player_profile() -> void:
	player_profile = SaveManagerScript.load_profile()

func _load_playtest_store() -> void:
	playtest_store = SaveManagerScript.load_playtest_store()

func _save_player_profile() -> bool:
	player_profile = SaveManagerScript.normalized_profile(player_profile)
	last_profile_save_ok = SaveManagerScript.save_profile(player_profile)
	return last_profile_save_ok

func _playtest_active_run() -> Dictionary:
	return PlaytestTelemetryScript.active_run(playtest_store)

func _active_playtest_run_id() -> String:
	return str(_playtest_active_run().get("run_id", ""))

func _start_playtest_run(forced_run_id: String = "") -> void:
	if not _playtest_active_run().is_empty():
		playtest_store = PlaytestTelemetryScript.finish_active_run(playtest_store, "abandoned", _playtest_final_snapshot("new_run_started"))
	playtest_store = PlaytestTelemetryScript.start_run(playtest_store, {
		"run_id": forced_run_id,
		"game_version": PLAYTEST_BUILD_LABEL,
		"engine_version": str(Engine.get_version_info().get("string", "unknown")),
		"config_fingerprint": playtest_config_fingerprint,
		"platform": OS.get_name(),
		"display_size": [int(_layout_viewport_size().x), int(_layout_viewport_size().y)],
		"display_scale": DisplayServer.screen_get_scale() if DisplayServer.get_name() != "headless" else 1.0,
		"locale": TranslationServer.get_locale(),
		"character_id": selected_character_id,
		"challenge_level": current_challenge_level,
		"skill_book_id": run_skill_book_id,
		"progression_node_ids": run_progression_node_ids.duplicate(true),
		"starting_hp": run_hp,
		"max_hp": run_max_hp,
		"starting_gold": run_gold,
		"starting_deck_ids": run_deck_ids.duplicate(true),
		"starting_relic_ids": run_relic_ids.duplicate(true),
		"starting_potion_ids": run_potion_ids.duplicate(true)
	})
	_checkpoint_playtest_store()

func _archive_playtest_run_replaced_by(raw_run: Variant) -> void:
	var incoming: Dictionary = raw_run if raw_run is Dictionary else {}
	var current := _playtest_active_run()
	if not current.is_empty() and (incoming.is_empty() or str(current.get("run_id", "")) != str(incoming.get("run_id", ""))):
		playtest_store = PlaytestTelemetryScript.finish_active_run(playtest_store, "abandoned", _playtest_final_snapshot("different_save_loaded"))
		_checkpoint_playtest_store()

func _restore_playtest_run(raw_run: Variant, fallback_run_id: String = "") -> void:
	var incoming: Dictionary = (raw_run as Dictionary).duplicate(true) if raw_run is Dictionary else {}
	if not fallback_run_id.is_empty():
		last_terminal_run_id = fallback_run_id
	if not incoming.is_empty() and str(incoming.get("run_id", "")).is_empty() and not fallback_run_id.is_empty():
		incoming["run_id"] = fallback_run_id
	if not incoming.is_empty():
		playtest_store = PlaytestTelemetryScript.set_active_run(playtest_store, incoming)
	else:
		playtest_store["active_run"] = {}
	if _playtest_active_run().is_empty() and not run_completed and _archived_playtest_run_outcome(fallback_run_id).is_empty():
		_start_playtest_run(fallback_run_id)
	var restored := _playtest_active_run()
	if not restored.is_empty():
		PlaytestTelemetryScript.record_run_loaded(restored)
		playtest_store["active_run"] = restored
	_checkpoint_playtest_store()

func _checkpoint_playtest_store() -> bool:
	return SaveManagerScript.save_playtest_store(playtest_store)

func _record_playtest_node_started() -> void:
	var run := _playtest_active_run()
	if run.is_empty() or current_node_id.is_empty():
		return
	var node: Dictionary = _current_node()
	var node_type := str(node.get("type", ""))
	var hp := run_hp
	if combat != null:
		hp = int(combat.player.get("hp", run_hp))
	if PlaytestTelemetryScript.record_node_started(run, {
		"chapter_id": current_chapter_id,
		"node_id": current_node_id,
		"node_type": node_type,
		"encounter_id": str(node.get("encounter_id", "")),
		"event_id": str(node.get("event_id", "")),
		"is_battle": _is_battle_node(node_type),
		"hp": hp,
		"gold": run_gold,
		"deck_size": run_deck_ids.size()
	}):
		playtest_store["active_run"] = run
		_checkpoint_playtest_store()

func _record_playtest_combat_terminal() -> void:
	if combat == null or not ["won", "lost"].has(str(combat.phase)):
		return
	var run := _playtest_active_run().duplicate(true)
	if run.is_empty():
		return
	var node: Dictionary = _current_node()
	var result := "won" if combat.phase == "won" else "lost"
	var changed := PlaytestTelemetryScript.record_node_finished(run, {
		"chapter_id": current_chapter_id,
		"node_id": current_node_id,
		"result": result,
		"turns": int(combat.turn),
		"hp": max(0, int(combat.player.get("hp", run_hp))),
		"gold": run_gold,
		"deck_size": run_deck_ids.size(),
		"is_battle": true
	})
	if combat.phase == "lost":
		var run_id := str(run.get("run_id", ""))
		last_terminal_run_id = run_id
		var candidate_store: Dictionary = playtest_store.duplicate(true)
		candidate_store["active_run"] = run
		candidate_store = PlaytestTelemetryScript.finish_active_run(candidate_store, "defeat", _playtest_final_snapshot("combat_defeat"))
		if not SaveManagerScript.save_playtest_store(candidate_store):
			last_run_save_cleanup_ok = false
			last_terminal_persistence_error = "试玩记录保存失败；可恢复存档仍保留。"
			return
		playtest_store = candidate_store
		last_terminal_run_id = run_id
		last_run_save_cleanup_ok = SaveManagerScript.delete_run_for_run_id(run_id)
		last_terminal_persistence_error = "" if last_run_save_cleanup_ok else "试玩记录已保存，但本局存档清理失败。"
	elif changed:
		playtest_store["active_run"] = run
		_checkpoint_playtest_store()

func _record_playtest_noncombat_terminal() -> void:
	if combat != null or current_node_id.is_empty():
		return
	var run := _playtest_active_run()
	if run.is_empty():
		return
	if PlaytestTelemetryScript.record_node_finished(run, {
		"chapter_id": current_chapter_id,
		"node_id": current_node_id,
		"result": "completed",
		"hp": run_hp,
		"gold": run_gold,
		"deck_size": run_deck_ids.size(),
		"is_battle": false
	}):
		playtest_store["active_run"] = run
		_checkpoint_playtest_store()

func _finish_active_playtest_run(outcome: String, reason: String = "", expected_run_id: String = "") -> bool:
	var active := _playtest_active_run()
	if active.is_empty():
		if expected_run_id.is_empty():
			return true
		var archived_matches := _archived_playtest_run_matches(expected_run_id, outcome)
		if not archived_matches:
			last_terminal_persistence_error = "未找到本局的终局试玩记录；可恢复存档仍保留。"
		return archived_matches
	var run_id := str(active.get("run_id", ""))
	if not expected_run_id.is_empty() and run_id != expected_run_id:
		last_terminal_persistence_error = "终局试玩记录与跑团存档身份不一致；可恢复存档仍保留。"
		return false
	var candidate_store := PlaytestTelemetryScript.finish_active_run(playtest_store, outcome, _playtest_final_snapshot(reason))
	if not SaveManagerScript.save_playtest_store(candidate_store):
		last_terminal_persistence_error = "试玩记录保存失败；可恢复存档仍保留。"
		return false
	playtest_store = candidate_store
	last_terminal_run_id = run_id
	last_terminal_persistence_error = ""
	return true

func _archived_playtest_run_matches(run_id: String, outcome: String) -> bool:
	return _archived_playtest_run_outcome(run_id) == outcome

func _archived_playtest_run_outcome(run_id: String) -> String:
	if run_id.is_empty():
		return ""
	for archived_value in playtest_store.get("runs", []):
		var archived: Dictionary = archived_value
		if str(archived.get("run_id", "")) == run_id:
			var archived_outcome := str(archived.get("outcome", ""))
			if ["victory", "defeat"].has(archived_outcome):
				return archived_outcome
	return ""

func _finalize_terminal_run_storage(outcome: String, reason: String, run_id: String) -> bool:
	if run_id.is_empty():
		last_terminal_persistence_error = "终局存档缺少跑团身份；可恢复存档仍保留。"
		return false
	if not _finish_active_playtest_run(outcome, reason, run_id):
		return false
	last_run_save_cleanup_ok = SaveManagerScript.delete_run_for_run_id(run_id)
	last_terminal_persistence_error = "" if last_run_save_cleanup_ok else "结算已保存，但本局存档清理失败；请重试。"
	return last_run_save_cleanup_ok

func _playtest_final_snapshot(reason: String = "") -> Dictionary:
	var hp := run_hp
	if combat != null:
		hp = max(0, int(combat.player.get("hp", run_hp)))
	var node: Dictionary = _current_node() if not current_node_id.is_empty() else {}
	return {
		"reason": reason,
		"chapter_id": current_chapter_id,
		"node_id": current_node_id,
		"encounter_id": str(node.get("encounter_id", "")),
		"turn": int(combat.turn) if combat != null else 0,
		"hp": hp,
		"max_hp": run_max_hp,
		"gold": run_gold,
		"deck_ids": run_deck_ids.duplicate(true),
		"relic_ids": run_relic_ids.duplicate(true),
		"potion_ids": run_potion_ids.duplicate(true),
		"completed_chapter_ids": completed_chapter_ids.duplicate(true),
		"deck_mastery_id": run_deck_mastery_id
	}

func _record_playtest_card_offers(items: Array, source: String) -> void:
	var ids: Array = []
	for item_value in items:
		if item_value is Dictionary:
			var item_id := str((item_value as Dictionary).get("id", ""))
			if not item_id.is_empty():
				ids.append(item_id)
	var run := _playtest_active_run()
	if not run.is_empty():
		PlaytestTelemetryScript.record_card_offers(run, ids, source)
		playtest_store["active_run"] = run
		_checkpoint_playtest_store()

func _record_playtest_card_acquired(card_id: String, source: String) -> void:
	var run := _playtest_active_run()
	if run.is_empty():
		return
	PlaytestTelemetryScript.record_card_acquired(run, card_id, source)
	playtest_store["active_run"] = run
	_checkpoint_playtest_store()

func _record_playtest_item_acquired(category: String, item_id: String, source: String) -> void:
	var run := _playtest_active_run()
	if run.is_empty():
		return
	PlaytestTelemetryScript.record_item_acquired(run, category, item_id, source)
	playtest_store["active_run"] = run
	_checkpoint_playtest_store()

func _on_export_playtest_report_pressed() -> void:
	_checkpoint_playtest_store()
	var report: Dictionary = PlaytestTelemetryScript.build_report(playtest_store, _playtest_report_context())
	last_playtest_export_ok = SaveManagerScript.export_playtest_report(report)
	last_playtest_export_path = SaveManagerScript.playtest_export_absolute_path()
	last_playtest_export_run_count = int(report.get("summary", {}).get("total_runs", 0))
	var summary: Dictionary = report.get("summary", {})
	var coverage: Dictionary = report.get("coverage", {})
	last_playtest_export_summary = "试玩 %d 局 · 胜 %d / 败 %d / 弃 %d | 方向 %d/%d | 硬门 %d/%d | 尚缺 %d 完成局" % [
		last_playtest_export_run_count,
		int(summary.get("victories", 0)),
		int(summary.get("defeats", 0)),
		int(summary.get("abandoned", 0)),
		int(coverage.get("directional_ready_cells", 0)),
		int(coverage.get("total_cells", 0)),
		int(coverage.get("hard_gate_ready_cells", 0)),
		int(coverage.get("total_cells", 0)),
		int(coverage.get("missing_finished_for_hard_gate", 0))
	]
	if last_playtest_export_ok and DisplayServer.get_name() != "headless":
		DisplayServer.clipboard_set(last_playtest_export_path)
	_audio_event("save" if last_playtest_export_ok else "error")
	if feedback_label != null:
		feedback_label.text = "试玩报告已导出，文件路径已复制。" if last_playtest_export_ok else "试玩报告导出失败。"
		feedback_label.visible = true
	if status_label != null:
		status_label.text = "%s | 路径已复制" % last_playtest_export_summary if last_playtest_export_ok else "试玩报告导出失败。"
		status_label.tooltip_text = last_playtest_export_path if last_playtest_export_ok else status_label.text
	var outcome_page := app_shell.active_page as Control if app_shell != null else null
	if outcome_page != null:
		var outcome_export_button := outcome_page.find_child("DefeatExportButton", true, false) as Button
		if outcome_export_button == null:
			outcome_export_button = outcome_page.find_child("OutcomeExportButton", true, false) as Button
		if outcome_export_button != null:
			outcome_export_button.text = "报告已导出" if last_playtest_export_ok else "导出失败"
			outcome_export_button.tooltip_text = last_playtest_export_path if last_playtest_export_ok else "试玩报告导出失败，请检查本机存储权限。"

func _playtest_report_context() -> Dictionary:
	var character_ids: Array = []
	for character_value in player_data.get("characters", []):
		var character_id := str((character_value as Dictionary).get("id", ""))
		if not character_id.is_empty() and not character_ids.has(character_id):
			character_ids.append(character_id)
	var challenge_levels: Array = []
	for level_value in challenge_data.get("levels", []):
		var level := int((level_value as Dictionary).get("level", 0))
		if not challenge_levels.has(level):
			challenge_levels.append(level)
	return {
		"expected_character_ids": character_ids,
		"expected_challenge_levels": challenge_levels
	}

func _on_retry_terminal_persistence_pressed() -> void:
	if combat != null and combat.phase == "lost" and not _playtest_active_run().is_empty():
		_record_playtest_combat_terminal()
	elif not last_terminal_run_id.is_empty() and _archived_playtest_run_matches(last_terminal_run_id, "defeat"):
		last_run_save_cleanup_ok = SaveManagerScript.delete_run_for_run_id(last_terminal_run_id)
		last_terminal_persistence_error = "" if last_run_save_cleanup_ok else "试玩记录已保存，但本局存档清理失败。"
	else:
		last_run_save_cleanup_ok = false
		last_terminal_persistence_error = "未找到本局的战败试玩记录；可恢复存档仍保留。"
	_audio_event("save" if last_terminal_persistence_error.is_empty() else "error")
	_refresh()

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
	var motion_policy: Dictionary = ForgeMotionScript.resolve_policy(user_settings)
	last_settings_reduced_motion = bool(motion_policy.get("reduced_motion", false))
	last_settings_flash_intensity = float(motion_policy.get("flash_intensity", 1.0))
	last_settings_particle_density = float(motion_policy.get("particle_density", 1.0))
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
	if not run_character_config.is_empty():
		return run_character_config
	return _effective_character_config(selected_character_id)

func _effective_character_config(character_id: String) -> Dictionary:
	var config: Dictionary = _character_config(character_id).duplicate(true)
	if config.is_empty():
		config = player_data.get("player", {}).duplicate(true)
	for effect_value in _character_upgrade_effects(character_id):
		var effect: Dictionary = effect_value
		match str(effect.get("type", "")):
			"max_hp_bonus":
				var hp_bonus: int = int(effect.get("amount", 0))
				config["max_hp"] = int(config.get("max_hp", 0)) + hp_bonus
				config["starting_hp"] = int(config.get("starting_hp", config.get("max_hp", 0))) + hp_bonus
			"starting_gold_bonus":
				config["starting_gold"] = int(config.get("starting_gold", 0)) + int(effect.get("amount", 0))
			"starting_momentum_bonus":
				config["starting_momentum"] = int(config.get("starting_momentum", 0)) + int(effect.get("amount", 0))
			"potion_slot_bonus":
				var cap: int = int(effect.get("cap", 99))
				config["potion_slots"] = min(cap, int(config.get("potion_slots", 0)) + int(effect.get("amount", 0)))
	return config

func _player_data_for_current_character() -> Dictionary:
	var normalized_data: Dictionary = player_data.duplicate(true)
	normalized_data["selected_character_id"] = selected_character_id
	normalized_data["player"] = _current_player_config().duplicate(true)
	normalized_data["runtime_player_config"] = _current_player_config().duplicate(true)
	normalized_data["run_modifier_sources"] = _run_modifier_sources()
	normalized_data["challenge_level"] = current_challenge_level
	normalized_data["challenge_modifiers"] = _challenge_modifiers(current_challenge_level)
	return normalized_data

func _character_tree_for_id(character_id: String) -> Dictionary:
	for tree_value in progression_data.get("character_trees", []):
		var tree: Dictionary = tree_value
		if str(tree.get("character_id", "")) == character_id:
			return tree
	return {}

func _upgrade_node_by_id(node_id: String) -> Dictionary:
	for tree_value in progression_data.get("character_trees", []):
		var tree: Dictionary = tree_value
		for node_value in tree.get("nodes", []):
			var node: Dictionary = node_value
			if str(node.get("id", "")) == node_id:
				return node
	return {}

func _upgrade_node_for_character(node_id: String, character_id: String) -> Dictionary:
	for node_value in _character_tree_for_id(character_id).get("nodes", []):
		var node: Dictionary = node_value
		if str(node.get("id", "")) == node_id:
			return node
	return {}

func _purchased_upgrade_node_ids() -> Array:
	return player_profile.get("purchased_upgrade_node_ids", [])

func _purchased_upgrade_node_ids_for_character(character_id: String) -> Array:
	var result: Array = []
	for node_id_value in _purchased_upgrade_node_ids():
		var node_id: String = str(node_id_value)
		if not _upgrade_node_for_character(node_id, character_id).is_empty():
			result.append(node_id)
	return result

func _character_upgrade_effects(character_id: String) -> Array:
	var effects: Array = []
	var purchased: Array = _purchased_upgrade_node_ids()
	var tree: Dictionary = _character_tree_for_id(character_id)
	for node_value in tree.get("nodes", []):
		var node: Dictionary = node_value
		if not purchased.has(str(node.get("id", ""))):
			continue
		for effect_value in node.get("effects", []):
			var effect: Dictionary = effect_value
			effects.append(effect.duplicate(true))
	return effects

func _progression_currency_amount() -> int:
	return max(0, int(player_profile.get("forge_marks", 0)))

func _skill_book_by_id(book_id: String) -> Dictionary:
	for book_value in progression_data.get("skill_books", []):
		var book: Dictionary = book_value
		if str(book.get("id", "")) == book_id:
			return book
	return {}

func _skill_book_unlocked(book: Dictionary) -> bool:
	var unlock: Dictionary = book.get("unlock", {})
	match str(unlock.get("type", "default")):
		"default":
			return true
		"chapter_completed":
			return player_profile.get("completed_chapters", []).has(str(unlock.get("chapter_id", "")))
	return false

func _default_skill_book_id() -> String:
	for book_value in progression_data.get("skill_books", []):
		var book: Dictionary = book_value
		if _skill_book_unlocked(book):
			return str(book.get("id", "steel_manual"))
	return "steel_manual"

func _equipped_skill_book_for_character(character_id: String) -> String:
	var equipped_by_character: Dictionary = player_profile.get("equipped_skill_book_by_character", {})
	var requested_id: String = str(equipped_by_character.get(character_id, ""))
	var requested_book: Dictionary = _skill_book_by_id(requested_id)
	if not requested_book.is_empty() and _skill_book_unlocked(requested_book):
		return requested_id
	return _default_skill_book_id()

func _run_modifier_sources() -> Array:
	var sources: Array = []
	for node_id_value in run_progression_node_ids:
		var node_id: String = str(node_id_value)
		var node: Dictionary = _upgrade_node_for_character(node_id, selected_character_id)
		if node.is_empty():
			continue
		var combat_start_effects: Array = []
		for effect_value in node.get("effects", []):
			var effect: Dictionary = effect_value
			if str(effect.get("type", "")) == "combat_start_block":
				combat_start_effects.append({"trigger": "combat_start", "type": "gain_block", "amount": int(effect.get("amount", 0))})
		if not combat_start_effects.is_empty():
			sources.append({"id": "upgrade_%s" % node_id, "name": "升级：%s" % str(node.get("name", node_id)), "effects": combat_start_effects})
	var skill_book: Dictionary = _skill_book_by_id(run_skill_book_id)
	if not skill_book.is_empty() and _skill_book_unlocked(skill_book):
		sources.append({"id": "skill_book_%s" % run_skill_book_id, "name": "技能书：%s" % str(skill_book.get("name", run_skill_book_id)), "effects": skill_book.get("effects", []).duplicate(true)})
	var mastery: Dictionary = _deck_mastery_by_id(run_deck_mastery_id)
	if not mastery.is_empty():
		sources.append({"id": "deck_mastery_%s" % run_deck_mastery_id, "name": "卡组专精：%s" % str(mastery.get("name", run_deck_mastery_id)), "effects": mastery.get("effects", []).duplicate(true)})
	return sources

func _deck_mastery_by_id(mastery_id: String) -> Dictionary:
	for mastery_value in progression_data.get("deck_masteries", []):
		var mastery: Dictionary = mastery_value
		if str(mastery.get("id", "")) == mastery_id:
			return mastery
	return {}

func _eligible_deck_masteries() -> Array:
	var eligible: Array = []
	for mastery_value in progression_data.get("deck_masteries", []):
		var mastery: Dictionary = mastery_value
		if _deck_mastery_requirements_met(mastery.get("requirements", {})):
			eligible.append(mastery)
	return eligible

func _deck_mastery_requirements_met(requirements: Dictionary) -> bool:
	if requirements.has("min_type_count"):
		var summary: Dictionary = _deck_summary()
		for card_type_value in requirements.get("min_type_count", {}).keys():
			var card_type: String = str(card_type_value)
			if int(summary.get(card_type, 0)) < int(requirements.get("min_type_count", {}).get(card_type_value, 0)):
				return false
		return true
	if requirements.has("min_zero_cost_cards"):
		return _deck_zero_cost_count() >= int(requirements.get("min_zero_cost_cards", 0))
	if requirements.has("min_burn_creator_cards"):
		return _deck_burn_creator_count() >= int(requirements.get("min_burn_creator_cards", 0))
	return false

func _deck_zero_cost_count() -> int:
	var count: int = 0
	for entry_value in run_deck_ids:
		var card: Dictionary = _deck_display_card(str(entry_value))
		if not card.is_empty() and int(card.get("cost", -1)) == 0:
			count += 1
	return count

func _deck_burn_creator_count() -> int:
	var count: int = 0
	for entry_value in run_deck_ids:
		var entry: String = str(entry_value)
		var card: Dictionary = _card_by_id(_base_card_id(entry))
		var effects: Array = card.get("upgrade", {}).get("effects", []) if entry.ends_with("+") else card.get("effects", [])
		for effect_value in effects:
			var effect: Dictionary = effect_value
			if str(effect.get("type", "")) == "create_card" and str(effect.get("card_id", "")) == "searing_wound":
				count += 1
				break
	return count

func _mastery_reward_is_available() -> bool:
	if combat == null or combat.phase != "won" or not run_deck_mastery_id.is_empty():
		return false
	if str(_current_node().get("type", "")) != "elite":
		return false
	return not _eligible_deck_masteries().is_empty()

func _mastery_requirement_text(mastery: Dictionary) -> String:
	var requirements: Dictionary = mastery.get("requirements", {})
	if requirements.has("min_type_count"):
		var labels := {"attack": "攻击牌", "skill": "技能牌", "power": "能力牌"}
		for card_type_value in requirements.get("min_type_count", {}).keys():
			return "%s至少 %d 张" % [str(labels.get(str(card_type_value), str(card_type_value))), int(requirements.get("min_type_count", {}).get(card_type_value, 0))]
	if requirements.has("min_zero_cost_cards"):
		return "0 费牌至少 %d 张" % int(requirements.get("min_zero_cost_cards", 0))
	if requirements.has("min_burn_creator_cards"):
		return "灼伤生成牌至少 %d 张" % int(requirements.get("min_burn_creator_cards", 0))
	return "构筑条件已满足"

func _mastery_icon_path(mastery_id: String) -> String:
	match mastery_id:
		"offense_forging":
			return str(INTENT_ICON_PATHS.get("attack", UI_DECK_ICON_PATH))
		"bastion_forging":
			return _hud_icon_path("护甲")
		"overload_forging":
			return _hud_icon_path("势能")
		"burn_forging":
			return str(INTENT_ICON_PATHS.get("debuff", UI_DECK_ICON_PATH))
	return UI_DECK_ICON_PATH

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

func _character_stage_art_path(character_id: String = "") -> String:
	var lookup_id: String = selected_character_id if character_id.is_empty() else character_id
	var fallback: String = str(PLAYER_STAGE_ART_PATHS.get(lookup_id, _character_art_path(lookup_id)))
	return _asset_path_from_slot("player_stage_slots", lookup_id, fallback)

func _character_selection_tooltip_text(character: Dictionary) -> String:
	return "%s\n\n%s\n\n起始牌组：%s" % [
		str(character.get("name", character.get("id", "角色"))),
		str(character.get("balance_note", "")),
		_card_names(character.get("starter_deck_ids", []))
	]

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
	var boss_hp_percent: int = int(round(float(modifiers.get("boss_hp_multiplier", 1.0)) * 100.0))
	var enemy_damage_percent: int = int(round(float(modifiers.get("enemy_damage_multiplier", 1.0)) * 100.0))
	var hp_loss: int = int(modifiers.get("player_starting_hp_loss", 0))
	return "敌血 %d%% | 首领额外 %d%% | 敌伤 %d%% | 开局 -%dHP" % [enemy_hp_percent, boss_hp_percent, enemy_damage_percent, hp_loss]

func _challenge_log_text(level: int, unlocked_max: int, short_name: String) -> String:
	var modifiers: Dictionary = _challenge_modifiers(level)
	var enemy_hp_percent: int = int(round(float(modifiers.get("enemy_hp_multiplier", 1.0)) * 100.0))
	var boss_hp_percent: int = int(round(float(modifiers.get("boss_hp_multiplier", 1.0)) * 100.0))
	var enemy_damage_percent: int = int(round(float(modifiers.get("enemy_damage_multiplier", 1.0)) * 100.0))
	var hp_loss: int = int(modifiers.get("player_starting_hp_loss", 0))
	if _scroll_content_width() < 420.0:
		return "挑战 %d/%d %s | 敌血%d%% 首领%d%% 敌伤%d%% -%dHP" % [
			level,
			unlocked_max,
			short_name,
			enemy_hp_percent,
			boss_hp_percent,
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
	if relic_belt_row != null and relic_belt_row.get_parent() != character_panel:
		var relic_parent := relic_belt_row.get_parent()
		if relic_parent != null:
			relic_parent.remove_child(relic_belt_row)
		character_panel.add_child(relic_belt_row)
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
	config["level_tree_constraints"] = level_tree_data.get("chapters", {}).get(chapter_id, {}).duplicate(true)
	config["route_constraints"] = level_tree_data.get("route_constraints", {}).duplicate(true)
	var filtered_event_pool: Array = []
	var guaranteed_event_ids: Array = []
	for event_id_value in config.get("event_pool", []):
		var event_id: String = str(event_id_value)
		var event: Dictionary = _event_by_id(event_id)
		if event.is_empty() or _event_available_for_current_character(event):
			filtered_event_pool.append(event_id)
			if bool(event.get("guaranteed_when_available", false)):
				guaranteed_event_ids.append(event_id)
	config["event_pool"] = filtered_event_pool
	config["guaranteed_event_ids"] = guaranteed_event_ids
	return config

func _event_available_for_current_character(event: Dictionary) -> bool:
	var character_ids: Array = event.get("character_ids", [])
	if not character_ids.is_empty() and not character_ids.has(selected_character_id):
		return false
	var pool_tags: Array = event.get("pool_tags", [])
	if not pool_tags.is_empty():
		var character_tags: Array = _current_player_config().get("reward_pool_tags", ["shared", selected_character_id])
		var tag_matched: bool = false
		for tag in pool_tags:
			if character_tags.has(str(tag)):
				tag_matched = true
				break
		if not tag_matched:
			return false
	for condition in event.get("availability_conditions", []):
		var condition_dict: Dictionary = condition
		if not _event_condition_blocked_reason(condition_dict).is_empty():
			return false
	return true

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
	treasure_reward_gold = 0
	combat_reward_gold = 0
	shop_relic_options.clear()
	reward_generated_for = ""
	shop_remove_selection_open = false
	campfire_upgrade_selection_open = false
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
		combat.changed.connect(_on_combat_changed)
	else:
		if node_type == "event":
			var event_id: String = str(node.get("event_id", ""))
			if _record_discovered_content("events", event_id):
				_save_player_profile()
		combat = null
	if not restoring_combat_reward_state:
		_record_playtest_node_started()
	_refresh()

func _refresh() -> void:
	refresh_call_count += 1
	if status_label != null:
		status_label.visible = true
	_refresh_screen_backdrop()
	var terminal_outcome_open: bool = not deck_view_open and not profile_open and not tutorial_open and (run_completed or (combat != null and combat.phase == "lost"))
	var pc_run_page_shell_active: bool = false
	if _is_pc_layout():
		pc_run_page_shell_active = current_node_id.is_empty() and not available_node_ids.is_empty()
		if not pc_run_page_shell_active and not current_node_id.is_empty():
			pc_run_page_shell_active = ["event", "campfire", "shop", "treasure"].has(str(_current_node().get("type", "")))
			if combat != null and combat.phase == "won":
				pc_run_page_shell_active = true
	var menu_shell_active: bool = settings_open or compendium_open or terminal_outcome_open or pc_run_page_shell_active or ((welcome_open or character_select_open) and not profile_open and not tutorial_open)
	_set_menu_shell_active(menu_shell_active)
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
	if welcome_open:
		_music_context("menu")
		_set_run_controls_enabled(false)
		_refresh_welcome()
		return
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
	elif node_type == "treasure":
		_music_context("reward")
		_refresh_treasure(node)
		_apply_tutorial_hint("treasure")
	else:
		_refresh_unknown_node(node)
		_apply_tutorial_hint("")

func _set_menu_shell_active(active: bool) -> void:
	if page_scroll != null:
		page_scroll.visible = not active
	if app_shell == null:
		return
	app_shell.visible = active
	app_shell.configure_effect_policy(user_settings)
	if not active and app_shell.active_page != null:
		app_shell.clear_page()

func _refresh_screen_backdrop() -> void:
	if screen_background_art == null:
		return
	var menu_page: bool = (welcome_open or character_select_open) and not settings_open and not profile_open and not tutorial_open and not compendium_open
	var path: String = UI_MENU_BACKDROP_PATH if menu_page else UI_BACKDROP_PATH
	screen_background_art.texture = _load_texture(path)
	screen_background_art.visible = screen_background_art.texture != null
	screen_background_art.modulate = Color(1, 1, 1, 0.86 if menu_page else 0.46)
	last_ui_backdrop_loaded = screen_background_art.visible
	_update_menu_backdrop_motion(menu_page)
	if title_label != null:
		title_label.text = "余烬回路" if menu_page else "EmberCircuit / 余烬回路"
		title_label.custom_minimum_size.y = 46.0 if menu_page else 24.0
		title_label.add_theme_font_size_override("font_size", 36 if menu_page else 20)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62) if menu_page else Color(0.96, 0.92, 0.84))
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 3)
	if status_label != null and menu_page and _is_pc_layout():
		status_label.visible = false

func _update_menu_backdrop_motion(menu_page: bool) -> void:
	var continuous_motion_allowed := ForgeMotionScript.allows_continuous_motion(bool(user_settings.get("reduced_motion", false)))
	if not menu_page or not continuous_motion_allowed:
		if menu_backdrop_tween != null and menu_backdrop_tween.is_valid():
			menu_backdrop_tween.kill()
		menu_backdrop_tween = null
		screen_background_art.scale = Vector2.ONE
		return
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	if menu_backdrop_tween != null and menu_backdrop_tween.is_valid():
		return
	screen_background_art.pivot_offset = _layout_viewport_size() * 0.5
	screen_background_art.scale = Vector2(1.018, 1.018)
	menu_backdrop_tween = create_tween().set_loops()
	menu_backdrop_tween.tween_property(screen_background_art, "scale", Vector2(1.048, 1.048), 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	menu_backdrop_tween.tween_property(screen_background_art, "scale", Vector2(1.018, 1.018), 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_run_controls_enabled(active_run: bool) -> void:
	if restart_button != null:
		restart_button.disabled = false
	if save_button != null:
		save_button.disabled = not active_run or _run_save_blocked()
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

func _run_save_blocked() -> bool:
	return run_completed or (combat != null and str(combat.phase) == "lost")

func _set_page_regions(character_visible: bool, hud_visible: bool, map_visible: bool, potions_visible: bool, enemies_visible: bool, log_visible: bool, hand_visible: bool, rewards_visible: bool) -> void:
	if title_label != null:
		title_label.visible = true
	if run_label != null:
		run_label.visible = true
	if status_label != null:
		status_label.visible = true
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
		reward_scroll.set("vertical_scroll_mode", 0 if _is_pc_layout() and (welcome_open or character_select_open) else 1)
	if reward_row != null:
		reward_row.visible = rewards_visible
	if controls_scroll != null:
		controls_scroll.visible = true
	if controls_row != null:
		controls_row.visible = true
	_apply_controls_layout_constraints(hud_visible and hand_visible and not rewards_visible)

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
	var reward_height: float = clamp(_layout_viewport_size().y - 330.0, 390.0, 560.0) if _is_pc_layout() else clamp(round(322.0 * scale_y), 232.0, 322.0)
	_set_content_heights(log_height, reward_height)
	_record_scroll_region_metrics()

func _apply_map_layout_constraints() -> void:
	var scale_y: float = _page_layout_scale()
	var map_height: float = clamp(_layout_viewport_size().y - 82.0, 560.0, 760.0) if _is_pc_layout() else clamp(round(316.0 * scale_y), 244.0, 330.0)
	if map_scroll != null:
		map_scroll.custom_minimum_size = Vector2(0, map_height)
		map_scroll.set("horizontal_scroll_mode", 0 if _is_pc_layout() else 1)
		map_scroll.scroll_horizontal = 0
	if map_view != null:
		var map_width: float = _map_view_required_width()
		map_view.custom_minimum_size = Vector2(map_width, map_height)
		map_view.size = Vector2(map_width, map_height)
	var log_height: float = 0.0 if _is_pc_layout() else clamp(round(92.0 * scale_y), 76.0, 104.0)
	_set_content_heights(log_height, 0.0)
	_record_scroll_region_metrics()

func _apply_pc_map_chrome() -> void:
	if not _is_pc_layout():
		return
	title_label.visible = false
	run_label.visible = false
	status_label.visible = false
	character_frame.visible = false
	character_panel.visible = false
	log_label.visible = false
	for button_value in [restart_button, load_button, compendium_button, tutorial_button]:
		var button := button_value as Button
		if button != null:
			button.visible = false
	for button_value in [save_button, deck_button, profile_button, settings_button]:
		var button := button_value as Button
		if button != null:
			button.visible = true
	if controls_spacer != null:
		controls_spacer.visible = true
	if controls_row != null:
		controls_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls_row.custom_minimum_size = Vector2(_scroll_content_width(), 36.0)

func _apply_pc_story_room_chrome() -> void:
	if not _is_pc_layout():
		return
	title_label.visible = false
	run_label.visible = false
	status_label.visible = false
	log_label.visible = false
	var reward_height: float = clamp(_layout_viewport_size().y - 154.0, 520.0, 760.0)
	_set_content_heights(0.0, reward_height)
	if reward_scroll != null:
		reward_scroll.set("vertical_scroll_mode", 0)
		reward_scroll.scroll_vertical = 0
	for button_value in [restart_button, load_button, compendium_button, tutorial_button]:
		var button := button_value as Button
		if button != null:
			button.visible = false
	for button_value in [save_button, deck_button, profile_button, settings_button]:
		var button := button_value as Button
		if button != null:
			button.visible = true
	if controls_spacer != null:
		controls_spacer.visible = true
	if controls_row != null:
		controls_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls_row.custom_minimum_size = Vector2(_scroll_content_width(), 36.0)

func _apply_reward_page_layout_constraints(log_height: float = 170.0, reward_height: float = 190.0) -> void:
	var scale_y: float = _page_layout_scale()
	var target_log_height: float = round(log_height * scale_y)
	var target_reward_height: float = round(reward_height * scale_y)
	if _is_pc_layout():
		target_log_height = clamp(target_log_height, 56.0, 76.0)
		target_reward_height = clamp(max(target_reward_height, 390.0), 340.0, 430.0)
	_set_content_heights(target_log_height, target_reward_height)
	_record_scroll_region_metrics()

func _apply_pc_combat_chrome(reward_visible: bool) -> void:
	if _is_pc_layout() and combat != null and combat.phase == "lost":
		_apply_pc_defeat_chrome()
		return
	if _is_pc_layout() and reward_visible:
		if title_label != null:
			title_label.visible = true
			title_label.text = "战斗奖励"
			title_label.custom_minimum_size.y = 42.0
			title_label.add_theme_font_size_override("font_size", 26)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
		for control_value in [run_label, status_label, character_frame, character_panel, log_label]:
			var control := control_value as Control
			if control != null:
				control.visible = false
		if controls_scroll != null:
			controls_scroll.visible = false
		if controls_row != null:
			controls_row.visible = false
		if reward_scroll != null:
			reward_scroll.visible = app_shell == null or app_shell.active_page_id != "reward"
			reward_scroll.set("vertical_scroll_mode", 0)
		return
	var immersive_combat: bool = _is_pc_layout() and not reward_visible
	if title_label != null:
		title_label.visible = not immersive_combat
	if run_label != null:
		run_label.visible = not immersive_combat
	if status_label != null:
		status_label.visible = not immersive_combat
	if character_frame != null:
		character_frame.visible = not immersive_combat
	if character_panel != null:
		character_panel.visible = not immersive_combat
	if relic_belt_row != null:
		relic_belt_row.visible = immersive_combat or not run_relic_ids.is_empty()
	if log_label != null and immersive_combat:
		log_label.visible = false

func _apply_pc_defeat_chrome() -> void:
	_apply_pc_defeat_layout_constraints()
	for control_value in [title_label, run_label, status_label, character_frame, character_panel, log_label, feedback_label]:
		var control := control_value as Control
		if control != null:
			control.visible = false
	if controls_scroll != null:
		controls_scroll.visible = false
	if reward_scroll != null:
		reward_scroll.visible = true
		reward_scroll.set("vertical_scroll_mode", 0)
		reward_scroll.scroll_vertical = 0
	if page_scroll != null:
		page_scroll.set("vertical_scroll_mode", 0)
		page_scroll.scroll_vertical = 0

func _apply_pc_defeat_layout_constraints() -> void:
	if not _is_pc_layout():
		return
	var reward_height: float = max(620.0, _layout_viewport_size().y - _root_vertical_margin())
	_set_content_heights(0.0, reward_height)

func _place_potion_row_for_combat(use_hud_belt: bool, row_size: Vector2) -> void:
	if potion_row == null or battle_mid_row == null or enemy_stage_stack == null:
		return
	var desired_parent: Node = combat_hud_row if use_hud_belt and combat_hud_row != null else battle_mid_row
	if potion_row.get_parent() != desired_parent:
		var old_parent := potion_row.get_parent()
		if old_parent != null:
			old_parent.remove_child(potion_row)
		desired_parent.add_child(potion_row)
	potion_row.custom_minimum_size = row_size
	potion_row.size = row_size
	potion_row.size_flags_horizontal = Control.SIZE_SHRINK_END if use_hud_belt else Control.SIZE_SHRINK_BEGIN
	potion_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	potion_row.z_index = 0
	if use_hud_belt:
		potion_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
		potion_row.offset_left = 0.0
		potion_row.offset_top = 0.0
		potion_row.offset_right = 0.0
		potion_row.offset_bottom = 0.0
		if combat_hud_row != null and potion_row.get_parent() == combat_hud_row:
			combat_hud_row.move_child(potion_row, combat_hud_row.get_child_count() - 1)
	else:
		potion_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
		potion_row.offset_left = 0.0
		potion_row.offset_top = 0.0
		potion_row.offset_right = 0.0
		potion_row.offset_bottom = 0.0

func _place_feedback_label_for_combat(overlay_on_stage: bool, label_size: Vector2) -> void:
	if feedback_label == null or battle_board_box == null or enemy_stage_stack == null:
		return
	var desired_parent: Node = enemy_stage_stack if overlay_on_stage else battle_board_box
	if feedback_label.get_parent() != desired_parent:
		var old_parent := feedback_label.get_parent()
		if old_parent != null:
			old_parent.remove_child(feedback_label)
		desired_parent.add_child(feedback_label)
	if overlay_on_stage:
		feedback_label.z_index = 9
		feedback_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		feedback_label.anchor_left = 0.5
		feedback_label.anchor_right = 0.5
		feedback_label.offset_left = -label_size.x * 0.5
		feedback_label.offset_top = 10.0
		feedback_label.offset_right = label_size.x * 0.5
		feedback_label.offset_bottom = 10.0 + label_size.y
		feedback_label.size = label_size
	else:
		feedback_label.z_index = 0
		feedback_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		feedback_label.offset_left = 0.0
		feedback_label.offset_top = 0.0
		feedback_label.offset_right = 0.0
		feedback_label.offset_bottom = 0.0
		if battle_mid_row != null and feedback_label.get_parent() == battle_board_box:
			battle_board_box.move_child(feedback_label, max(0, battle_mid_row.get_index()))

func _apply_controls_layout_constraints(combat_primary: bool = false) -> void:
	var pc_combat: bool = _is_pc_layout() and combat_primary
	var pc_character_menu: bool = _is_pc_character_menu_controls()
	var pc_wide_controls: bool = pc_combat or pc_character_menu
	_place_end_turn_button(pc_combat)
	if controls_scroll != null:
		controls_scroll.custom_minimum_size = Vector2(0, 36.0 if pc_wide_controls else 34.0)
		controls_scroll.set("horizontal_scroll_mode", 0 if pc_wide_controls else 1)
		controls_scroll.scroll_horizontal = 0
	if controls_row != null:
		controls_row.add_theme_constant_override("separation", 10 if pc_character_menu else (8 if pc_combat else 8))
		controls_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL if pc_wide_controls else Control.SIZE_SHRINK_BEGIN
		controls_row.custom_minimum_size = Vector2(_scroll_content_width() if pc_wide_controls else 0.0, 36.0 if pc_wide_controls else 34.0)
	if controls_spacer != null:
		controls_spacer.visible = pc_wide_controls
		controls_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls_spacer.custom_minimum_size = Vector2(0, 1)
	if controls_row != null and end_turn_button != null and end_turn_button.get_parent() == controls_row:
		controls_row.move_child(end_turn_button, controls_row.get_child_count() - 1 if pc_combat else 0)
	if controls_row != null and controls_spacer != null and controls_spacer.get_parent() == controls_row:
		if pc_combat:
			controls_row.move_child(controls_spacer, max(0, controls_row.get_child_count() - 2))
		elif pc_character_menu:
			var split_button: Button = profile_button if welcome_open else load_button
			if split_button != null and split_button.get_parent() == controls_row:
				controls_row.move_child(controls_spacer, max(0, split_button.get_index()))

	var utility_buttons: Array = [restart_button, save_button, load_button, deck_button, profile_button, compendium_button, tutorial_button, settings_button]
	for button_value in utility_buttons:
		var button := button_value as Button
		if button == null:
			continue
		button.visible = _control_button_visible_for_layout(button, pc_combat, pc_character_menu)
		button.text = _control_button_label(button, pc_combat)
		if pc_combat:
			button.custom_minimum_size = Vector2(_combat_utility_button_width(button), 30)
			_apply_compact_control_button_skin(button, _control_button_skin(button), true)
			_apply_pc_combat_utility_button_content(button)
		elif pc_character_menu:
			button.custom_minimum_size = Vector2(_pc_menu_control_button_width(button), 36)
			_apply_pc_menu_control_button_skin(button)
			_apply_pc_menu_control_button_content(button)
		else:
			_remove_compact_button_content(button)
			button.custom_minimum_size = Vector2(_default_control_button_width(button), 30.0)
			_apply_button_skin(button, _control_button_skin(button))
	if end_turn_button != null:
		if pc_combat:
			end_turn_button.visible = true
			end_turn_button.custom_minimum_size = Vector2(104, 52)
			_apply_primary_control_button_skin(end_turn_button)
		else:
			end_turn_button.visible = not pc_character_menu and not _is_pc_layout()
			_remove_generated_button_skin_children(end_turn_button)
			end_turn_button.text = "结束回合"
			end_turn_button.custom_minimum_size = Vector2(96, 30)
			_apply_button_skin(end_turn_button, "primary")

func _place_end_turn_button(pc_combat: bool) -> void:
	if end_turn_button == null or controls_row == null:
		return
	var desired_parent: Node = hand_right_hud if pc_combat and hand_right_hud != null else controls_row
	if end_turn_button.get_parent() != desired_parent:
		var old_parent := end_turn_button.get_parent()
		if old_parent != null:
			old_parent.remove_child(end_turn_button)
		desired_parent.add_child(end_turn_button)
	if pc_combat and desired_parent == hand_right_hud:
		hand_right_hud.move_child(end_turn_button, 0)
	elif desired_parent == controls_row:
		controls_row.move_child(end_turn_button, 0)

func _is_pc_character_menu_controls() -> bool:
	return _is_pc_layout() and (welcome_open or character_select_open) and not settings_open and not profile_open and not tutorial_open and not compendium_open

func _control_button_visible_for_layout(button: Button, pc_combat: bool, pc_character_menu: bool) -> bool:
	if pc_combat:
		return button == deck_button or button == settings_button
	if pc_character_menu:
		if welcome_open:
			return button == profile_button or button == compendium_button or button == settings_button
		return button == restart_button or button == load_button or button == profile_button or button == compendium_button or button == tutorial_button or button == settings_button
	return true

func _control_button_skin(button: Button) -> String:
	if button == profile_button:
		return "relic"
	if button == compendium_button:
		return "event"
	return "neutral"

func _default_control_button_width(button: Button) -> float:
	if button == profile_button or button == compendium_button or button == settings_button:
		return 72.0
	return 88.0

func _control_button_label(button: Button, pc_combat: bool = false) -> String:
	if button == restart_button:
		return "新跑团"
	if button == save_button:
		return "保存跑团"
	if button == load_button:
		return "读取跑团"
	if button == deck_button:
		return "牌组" if pc_combat else "查看牌组"
	if button == profile_button:
		return "档案"
	if button == compendium_button:
		return "图鉴"
	if button == tutorial_button:
		return "完成引导" if last_tutorial_visible and not last_tutorial_step_id.is_empty() else "引导"
	if button == settings_button:
		return "设置"
	return button.text

func _combat_utility_button_width(button: Button) -> float:
	if button == profile_button or button == compendium_button or button == settings_button:
		return 62.0
	if button == tutorial_button:
		return 70.0
	return 76.0

func _pc_menu_control_button_width(button: Button) -> float:
	if button == restart_button or button == load_button:
		return 118.0
	if button == tutorial_button:
		return 112.0 if button.text.length() >= 4 else 94.0
	return 90.0

func _apply_compact_control_button_skin(button: Button, skin: String, subdued: bool) -> void:
	_configure_button_bounds(button)
	var palette: Dictionary = _button_skin_palette(skin)
	var bg: Color = palette.get("bg", Color(0.16, 0.17, 0.18))
	var border: Color = palette.get("border", Color(0.46, 0.50, 0.52))
	if subdued:
		bg = bg.darkened(0.18)
		border = border.darkened(0.18)
	var normal := _button_style(bg, border, 1, 6)
	var hover := _button_style(bg.lightened(0.10), border.lightened(0.14), 1, 6)
	var pressed := _button_style(bg.darkened(0.10), border.lightened(0.06), 1, 6)
	for style in [normal, hover, pressed]:
		style.content_margin_left = 7
		style.content_margin_right = 7
		style.content_margin_top = 3
		style.content_margin_bottom = 3
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.10, 0.11, 0.12), Color(0.28, 0.30, 0.32), 1, 6))
	button.add_theme_color_override("font_color", Color(0.82, 0.84, 0.82))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.50, 0.50))
	button.add_theme_font_size_override("font_size", 12)

func _apply_pc_menu_control_button_skin(button: Button) -> void:
	_configure_button_bounds(button)
	var active_main: bool = button == restart_button
	var bg := Color(0.105, 0.115, 0.12, 0.88)
	var border := Color(0.48, 0.54, 0.56, 0.78)
	if active_main:
		bg = Color(0.18, 0.145, 0.085, 0.92)
		border = Color(0.92, 0.66, 0.34, 0.90)
	var normal := _button_style(bg, border, 1 if not active_main else 2, 7)
	var hover := _button_style(bg.lightened(0.09), border.lightened(0.14), 1 if not active_main else 2, 7)
	var pressed := _button_style(bg.darkened(0.12), border.lightened(0.04), 1 if not active_main else 2, 7)
	var disabled := _button_style(Color(0.08, 0.085, 0.09, 0.62), Color(0.24, 0.26, 0.27, 0.58), 1, 7)
	for style in [normal, hover, pressed, disabled]:
		style.content_margin_left = 9
		style.content_margin_right = 9
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		style.shadow_color = Color(0, 0, 0, 0.34)
		style.shadow_size = 2
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.90, 0.91, 0.86))
	button.add_theme_color_override("font_disabled_color", Color(0.50, 0.52, 0.50))
	button.add_theme_font_size_override("font_size", 13)

func _apply_pc_menu_control_button_content(button: Button) -> void:
	if button == null:
		return
	var label_text: String = button.text
	var icon_path: String = _pc_menu_control_icon_path(button)
	_remove_compact_button_content(button)
	_remove_generated_button_skin_children(button)
	if icon_path.is_empty():
		return
	button.text = ""
	var root := CenterContainer.new()
	root.name = "CompactButtonContent"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	root.add_child(row)

	var icon := TextureRect.new()
	icon.name = "MenuButtonIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(17, 17)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(icon_path)
	icon.modulate = Color(0.96, 0.98, 0.90, 0.94)
	row.add_child(icon)

	var label := Label.new()
	label.name = "MenuButtonLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.90, 0.91, 0.86))
	row.add_child(label)

func _apply_pc_combat_utility_button_content(button: Button) -> void:
	if button == null:
		return
	var label_text: String = button.text
	var icon_path: String = _pc_combat_utility_icon_path(button)
	_remove_compact_button_content(button)
	if icon_path.is_empty():
		return
	button.text = ""
	var root := CenterContainer.new()
	root.name = "CompactButtonContent"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	root.add_child(row)

	var icon := TextureRect.new()
	icon.name = "CompactButtonIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(icon_path)
	icon.modulate = Color(0.96, 0.98, 0.90, 0.92)
	row.add_child(icon)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.84))
	row.add_child(label)

func _remove_compact_button_content(button: Button) -> void:
	if button == null:
		return
	var child := button.get_node_or_null("CompactButtonContent")
	if child != null:
		button.remove_child(child)
		child.free()

func _pc_combat_utility_icon_path(button: Button) -> String:
	if button == deck_button:
		return UI_DECK_ICON_PATH
	if button == settings_button:
		return UI_SETTINGS_ICON_PATH
	return ""

func _pc_menu_control_icon_path(button: Button) -> String:
	if button == restart_button:
		return UI_NEW_RUN_ICON_PATH
	if button == load_button:
		return UI_LOAD_RUN_ICON_PATH
	if button == profile_button:
		return UI_PROFILE_ICON_PATH
	if button == compendium_button:
		return UI_COMPENDIUM_ICON_PATH
	if button == tutorial_button:
		return UI_TUTORIAL_ICON_PATH
	if button == settings_button:
		return UI_SETTINGS_ICON_PATH
	return ""

func _apply_primary_control_button_skin(button: Button) -> void:
	_configure_button_bounds(button)
	if _is_pc_layout():
		var normal := _button_style(Color(0.15, 0.30, 0.16, 0.96), Color(0.86, 0.96, 0.56), 2, 9)
		var hover := _button_style(Color(0.20, 0.39, 0.20, 0.98), Color(1.0, 0.98, 0.66), 2, 9)
		var pressed := _button_style(Color(0.10, 0.22, 0.12, 0.98), Color(0.78, 0.86, 0.48), 2, 9)
		for style in [normal, hover, pressed]:
			style.content_margin_left = 18
			style.content_margin_right = 18
			style.content_margin_top = 7
			style.content_margin_bottom = 7
			style.shadow_color = Color(0, 0, 0, 0.48)
			style.shadow_size = 5
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.08, 0.10, 0.08, 0.78), Color(0.30, 0.34, 0.24), 1, 9))
		button.add_theme_color_override("font_color", Color(0.98, 1.00, 0.80))
		button.add_theme_color_override("font_disabled_color", Color(0.48, 0.52, 0.42))
		button.add_theme_font_size_override("font_size", 17)
		_apply_generated_button_texture_label(button, _hud_texture_path("end_turn_button", UI_END_TURN_BUTTON_PATH), "结束回合")
		return
	_remove_generated_button_skin_children(button)
	button.text = "结束回合"
	var normal := _button_style(Color(0.16, 0.28, 0.20), Color(0.78, 0.94, 0.62), 2, 7)
	var hover := _button_style(Color(0.19, 0.34, 0.24), Color(0.92, 1.00, 0.74), 2, 7)
	var pressed := _button_style(Color(0.12, 0.22, 0.16), Color(0.82, 0.94, 0.62), 2, 7)
	for style in [normal, hover, pressed]:
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 5
		style.content_margin_bottom = 5
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.10, 0.12, 0.11), Color(0.30, 0.36, 0.32), 1, 7))
	button.add_theme_color_override("font_color", Color(0.96, 1.00, 0.88))
	button.add_theme_color_override("font_disabled_color", Color(0.54, 0.58, 0.54))
	button.add_theme_font_size_override("font_size", 16)

func _apply_combat_layout_constraints(reward_visible: bool) -> void:
	var scale_y: float = _combat_layout_scale()
	var target_hand_frame_height := 252.0 if _is_pc_layout() else 150.0
	var hand_frame_height: float = clamp(round(target_hand_frame_height * scale_y), 124.0, 220.0 if _is_pc_layout() else 150.0)
	var combat_root_gap: float = float(root_box.get_theme_constant("separation")) if root_box != null else 5.0
	if character_frame != null:
		if _is_pc_layout() and not reward_visible:
			character_frame.visible = false
		else:
			character_frame.visible = true
		var character_frame_height := 52.0 if _is_pc_layout() else 58.0
		character_frame.custom_minimum_size = Vector2(0, clamp(round(character_frame_height * scale_y), 42.0, character_frame_height))
	if character_panel != null:
		character_panel.visible = character_frame == null or character_frame.visible
	if character_panel != null:
		var character_panel_height := 44.0 if _is_pc_layout() else 50.0
		character_panel.custom_minimum_size = Vector2(0, clamp(round(character_panel_height * scale_y), 38.0, character_panel_height))
	if player_portrait != null:
		var portrait_target := 42.0 if _is_pc_layout() else 48.0
		var portrait_size: float = clamp(round(portrait_target * scale_y), 34.0, portrait_target)
		player_portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)

	if battle_board_panel != null:
		var battle_board_height := 495.0 if _is_pc_layout() else 244.0
		battle_board_height = clamp(round(battle_board_height * scale_y), 176.0, 500.0 if _is_pc_layout() else 244.0)
		if _is_pc_layout() and not reward_visible:
			battle_board_height = max(360.0, _layout_viewport_size().y - _root_vertical_margin() - hand_frame_height - 36.0 - combat_root_gap * 2.0)
		battle_board_panel.custom_minimum_size = Vector2(0, battle_board_height)
	if battle_board_box != null:
		battle_board_box.add_theme_constant_override("separation", max(2, int(round((4.0 if _is_pc_layout() else 5.0) * scale_y))))
	if combat_hud_row != null:
		combat_hud_row.custom_minimum_size = Vector2(0, clamp(round((36.0 if _is_pc_layout() else 38.0) * scale_y), 34.0 if _is_pc_layout() else 24.0, 38.0 if _is_pc_layout() else 38.0))
		combat_hud_row.add_theme_constant_override("separation", 6)
	if feedback_label != null:
		var feedback_overlay: bool = _is_pc_layout() and not reward_visible
		var feedback_height: float = clamp(round((22.0 if _is_pc_layout() else 28.0) * scale_y), 18.0, 24.0 if _is_pc_layout() else 28.0)
		_place_feedback_label_for_combat(feedback_overlay, Vector2(340.0, feedback_height))
		feedback_label.custom_minimum_size = Vector2(340.0 if feedback_overlay else 0.0, feedback_height)
		feedback_label.add_theme_font_size_override("font_size", max(11, int(round((12.0 if _is_pc_layout() else 14.0) * scale_y))))
	if battle_mid_row != null:
		var battle_mid_height := 420.0 if _is_pc_layout() else 150.0
		battle_mid_height = clamp(round(battle_mid_height * scale_y), 108.0, 430.0 if _is_pc_layout() else 150.0)
		if _is_pc_layout() and not reward_visible:
			battle_mid_height = max(108.0, battle_board_panel.custom_minimum_size.y - combat_hud_row.custom_minimum_size.y - 18.0)
		battle_mid_row.custom_minimum_size = Vector2(0, battle_mid_height)
	if enemy_stage_panel != null:
		var enemy_stage_height := 416.0 if _is_pc_layout() else 148.0
		enemy_stage_height = clamp(round(enemy_stage_height * scale_y), 106.0, 426.0 if _is_pc_layout() else 148.0)
		if _is_pc_layout() and not reward_visible:
			enemy_stage_height = max(106.0, battle_mid_row.custom_minimum_size.y - 4.0)
		enemy_stage_panel.custom_minimum_size = Vector2(0, enemy_stage_height)
	if enemy_stage_stack != null:
		var enemy_stack_height := 404.0 if _is_pc_layout() else 136.0
		enemy_stack_height = clamp(round(enemy_stack_height * scale_y), 98.0, 414.0 if _is_pc_layout() else 136.0)
		if _is_pc_layout() and not reward_visible:
			enemy_stack_height = max(98.0, enemy_stage_panel.custom_minimum_size.y - 12.0)
		enemy_stage_stack.custom_minimum_size = Vector2(0, enemy_stack_height)
	if player_stage_art != null:
		player_stage_art.texture = _load_texture(_character_stage_art_path())
		player_stage_art.visible = _is_pc_layout() and player_stage_art.texture != null and not reward_visible
		if _is_pc_layout():
			player_stage_art.anchor_left = 0.0
			player_stage_art.anchor_top = 0.0
			player_stage_art.anchor_right = 0.0
			player_stage_art.anchor_bottom = 1.0
			player_stage_art.offset_left = 26.0
			player_stage_art.offset_top = 20.0
			player_stage_art.offset_right = 356.0
			player_stage_art.offset_bottom = -2.0
	if player_stage_plate != null:
		player_stage_plate.visible = _is_pc_layout() and not reward_visible
		player_stage_plate.z_index = 6
		player_stage_plate.anchor_left = 0.0
		player_stage_plate.anchor_top = 1.0
		player_stage_plate.anchor_right = 0.0
		player_stage_plate.anchor_bottom = 1.0
		player_stage_plate.offset_left = 72.0
		player_stage_plate.offset_top = -43.0
		player_stage_plate.offset_right = 310.0
		player_stage_plate.offset_bottom = -13.0
	if enemy_row != null:
		var enemy_row_height := 398.0 if _is_pc_layout() else 136.0
		enemy_row_height = clamp(round(enemy_row_height * scale_y), 98.0, 408.0 if _is_pc_layout() else 136.0)
		if _is_pc_layout() and not reward_visible:
			enemy_row_height = max(98.0, enemy_stage_stack.custom_minimum_size.y - 6.0)
		enemy_row.custom_minimum_size = Vector2(0, enemy_row_height)
		if _is_pc_layout():
			enemy_row.offset_left = 366.0
			enemy_row.offset_top = 18.0
			enemy_row.offset_right = -24.0
			enemy_row.offset_bottom = -14.0
		else:
			enemy_row.offset_left = 12.0
			enemy_row.offset_top = 8.0
			enemy_row.offset_right = -12.0
			enemy_row.offset_bottom = -8.0
		enemy_row.add_theme_constant_override("separation", _enemy_panel_gap())
	if potion_row != null:
		var potion_row_height: float = clamp(round((32.0 if _is_pc_layout() else 52.0) * scale_y), 30.0 if _is_pc_layout() else 38.0, 34.0 if _is_pc_layout() else 52.0)
		var potion_row_size := Vector2(_potion_row_width(), potion_row_height)
		_place_potion_row_for_combat(_is_pc_layout() and not reward_visible, potion_row_size)
		potion_row.add_theme_constant_override("separation", _potion_slot_gap())

	var log_height: float = clamp(round((98.0 if reward_visible else (34.0 if _is_pc_layout() else 58.0)) * scale_y), 28.0 if (_is_pc_layout() and not reward_visible) else (40.0 if not reward_visible else 70.0), 98.0 if reward_visible else (38.0 if _is_pc_layout() else 58.0))
	var reward_height: float = 0.0
	if reward_visible:
		reward_height = clamp(round((480.0 if _is_pc_layout() else 190.0) * scale_y), 390.0 if _is_pc_layout() else 112.0, 500.0 if _is_pc_layout() else 190.0)
	var hand_scroll_height: float = clamp(hand_frame_height - 12.0, 114.0, 208.0 if _is_pc_layout() else 140.0)
	if hand_frame != null:
		hand_frame.add_theme_stylebox_override("panel", _hand_frame_style())
		_add_generated_texture_background(hand_frame, _hud_texture_path("hand_tray", UI_HAND_TRAY_PATH), 0.42)
		hand_frame.custom_minimum_size = Vector2(0, hand_frame_height)
		hand_frame.clip_contents = not _is_pc_layout()
	if hand_dock_row != null:
		hand_dock_row.custom_minimum_size = Vector2(0, hand_scroll_height)
		hand_dock_row.add_theme_constant_override("separation", 8 if _is_pc_layout() else 0)
	if hand_left_hud != null:
		hand_left_hud.custom_minimum_size = Vector2(PC_HAND_LEFT_DOCK_WIDTH if _is_pc_layout() else 0.0, hand_scroll_height)
	if hand_right_hud != null:
		hand_right_hud.custom_minimum_size = Vector2(PC_HAND_RIGHT_DOCK_WIDTH if _is_pc_layout() else 0.0, hand_scroll_height)
	if hand_scroll != null:
		hand_scroll.custom_minimum_size = Vector2(0, hand_scroll_height)
		hand_scroll.clip_contents = not _is_pc_layout()
		hand_scroll.set("horizontal_scroll_mode", 3 if _is_pc_layout() else 1)
	if hand_row != null:
		var hand_width: float = _hand_required_width()
		var hand_height: float = hand_scroll_height
		var hand_row_width: float = max(_hand_scroll_content_width(), hand_width) if _is_pc_layout() else hand_width
		hand_row.custom_minimum_size = Vector2(hand_row_width, hand_height)
		hand_row.size = Vector2(hand_row_width, hand_height)
		hand_row.add_theme_constant_override("separation", _hand_card_gap())
	_set_content_heights(log_height, reward_height)
	_apply_pc_combat_chrome(reward_visible)
	_record_scroll_region_metrics()

func _combat_layout_scale() -> float:
	var available_height: float = _layout_viewport_size().y - _root_vertical_margin()
	return clamp(available_height / 860.0, 0.70, 1.08 if _is_pc_layout() else 1.0)

func _page_layout_scale() -> float:
	var available_height: float = _layout_viewport_size().y - _root_vertical_margin()
	return clamp(available_height / 840.0, 0.68, 1.08 if _is_pc_layout() else 1.0)

func _is_pc_layout() -> bool:
	var viewport_size: Vector2 = _layout_viewport_size()
	return viewport_size.x >= 1180.0 and viewport_size.y >= 720.0

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
	var scrollbar_reserve := 0.0 if _is_pc_layout() else SCROLLBAR_WIDTH_RESERVE
	return max(MIN_SAFE_CONTENT_WIDTH, _layout_viewport_size().x - _root_horizontal_margin() - scrollbar_reserve)

func _bounded_width(preferred_width: float, minimum_width: float, maximum_width: float) -> float:
	var available_width: float = _scroll_content_width()
	var safe_minimum: float = min(minimum_width, available_width)
	var safe_maximum: float = min(maximum_width, available_width)
	return clamp(preferred_width, safe_minimum, max(safe_minimum, safe_maximum))

func _map_view_required_width() -> float:
	if _is_pc_layout():
		return _scroll_content_width()
	var layer_count: int = 1
	if not map_graph.is_empty():
		layer_count = max(1, map_graph.get("layers", []).size())
	var minimum_layer_width := 150.0
	var required_width: float = 88.0 + float(layer_count) * minimum_layer_width
	return max(_scroll_content_width(), required_width)

func _large_card_button_size() -> Vector2:
	var scale_y: float = _page_layout_scale()
	if _is_pc_layout():
		return Vector2(clamp(round(184.0 * scale_y), 168.0, 196.0), clamp(round(238.0 * scale_y), 214.0, 254.0))
	return Vector2(clamp(round(158.0 * scale_y), 132.0, 158.0), clamp(round(184.0 * scale_y), 154.0, 184.0))

func _large_item_button_size() -> Vector2:
	var scale_y: float = _page_layout_scale()
	if _is_pc_layout():
		return Vector2(clamp(round(164.0 * scale_y), 144.0, 176.0), clamp(round(142.0 * scale_y), 122.0, 154.0))
	return Vector2(clamp(round(150.0 * scale_y), 128.0, 150.0), clamp(round(118.0 * scale_y), 96.0, 118.0))

func _mastery_reward_button_size() -> Vector2:
	if _is_pc_layout():
		return Vector2(clamp(_scroll_content_width() * 0.245, 244.0, 292.0), 154.0)
	return Vector2(clamp(_scroll_content_width() * 0.46, 150.0, 220.0), 132.0)

func _small_action_button_size() -> Vector2:
	var scale_y: float = _page_layout_scale()
	if _is_pc_layout():
		return Vector2(142, clamp(round(104.0 * scale_y), 88.0, 112.0))
	return Vector2(120, clamp(round(96.0 * scale_y), 78.0, 96.0))

func _reward_action_button_size(compact: bool = false) -> Vector2:
	var scale_y: float = _page_layout_scale()
	if compact and _is_pc_layout():
		return Vector2(clamp(round(150.0 * scale_y), 132.0, 164.0), clamp(round(68.0 * scale_y), 60.0, 72.0))
	if _is_pc_layout():
		return Vector2(clamp(round(150.0 * scale_y), 132.0, 164.0), clamp(round(142.0 * scale_y), 122.0, 154.0))
	return Vector2(clamp(round(132.0 * scale_y), 116.0, 138.0), clamp(round(118.0 * scale_y), 96.0, 124.0))

func _event_story_panel_size() -> Vector2:
	if _is_pc_layout():
		var pc_width: float = _bounded_width(_scroll_content_width() * 0.48, 600.0, 820.0)
		var pc_height: float = clamp(_layout_viewport_size().y - 392.0, 320.0, 470.0)
		return Vector2(pc_width, pc_height)
	var width: float = _bounded_width(_scroll_content_width(), 286.0, 520.0)
	var height: float = clamp(round(138.0 * _page_layout_scale()), 118.0, 138.0)
	return Vector2(width, height)

func _event_story_art_size(panel_width: float) -> Vector2:
	if _is_pc_layout():
		var art_width: float = clamp(panel_width * 0.42, 290.0, 380.0)
		var art_height: float = clamp(_event_story_panel_size().y - 20.0, 300.0, 450.0)
		return Vector2(art_width, art_height)
	var art_width: float = 130.0
	if panel_width < 340.0:
		art_width = 88.0
	elif panel_width < 440.0:
		art_width = 104.0
	var art_height: float = clamp(round(120.0 * _page_layout_scale()), 96.0, 120.0)
	return Vector2(art_width, art_height)

func _event_choice_button_size(choice_count: int) -> Vector2:
	var scale_y: float = _page_layout_scale()
	if _is_pc_layout():
		var count: int = max(1, choice_count)
		var story_width: float = _event_story_panel_size().x
		var available_width: float = max(0.0, _scroll_content_width() - story_width - float(count) * 6.0)
		var width: float = clamp(floor(available_width / float(count)), 176.0, 204.0)
		# Keep the event row inside the 720p combat shell; the story panel already
		# carries the visual weight, so choices should remain readable without
		# forcing the reward viewport below the fixed control strip.
		return Vector2(width, clamp(_event_story_panel_size().y * 0.66, 210.0, 280.0))
	return Vector2(196, clamp(round(122.0 * scale_y), 108.0, 126.0))

func _cinematic_panel_size() -> Vector2:
	var viewport_size: Vector2 = _layout_viewport_size()
	var width: float = clamp(viewport_size.x - _root_horizontal_margin() * 2.0, MIN_SAFE_CONTENT_WIDTH, min(620.0, viewport_size.x))
	return Vector2(width, clamp(round(164.0 * _page_layout_scale()), 132.0, 164.0))

func _root_vertical_margin() -> float:
	return ROOT_MARGIN_TOP + ROOT_MARGIN_BOTTOM

func _root_horizontal_margin() -> float:
	return ROOT_MARGIN_LEFT + ROOT_MARGIN_RIGHT

func _hand_card_gap() -> int:
	return 10 if _is_pc_layout() else 6

func _hand_card_size() -> Vector2:
	var target_height := 224.0 if _is_pc_layout() else 136.0
	var height: float = clamp(round(target_height * _combat_layout_scale()), 172.0 if _is_pc_layout() else 112.0, 192.0 if _is_pc_layout() else 140.0)
	if _is_pc_layout():
		return Vector2(PC_HAND_CARD_WIDTH, height)
	var card_count := 5
	if combat != null:
		card_count = max(1, combat.hand.size())
	var available_width: float = _hand_scroll_content_width()
	var width: float = floor((available_width - float(card_count - 1) * float(_hand_card_gap())) / float(card_count))
	width = clamp(width, 88.0, 136.0)
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
	last_hand_scroll_width = _hand_scroll_content_width()
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
	return 28 if _is_pc_layout() else 8

func _enemy_panel_width() -> float:
	var enemy_count := 1
	if combat != null:
		enemy_count = max(1, combat.enemies.size())
	var content_width: float = _scroll_content_width()
	var available_width: float = content_width - _potion_row_width() - 20.0
	if _is_pc_layout():
		available_width = max(260.0, content_width - 366.0 - 24.0)
	var width: float = floor((available_width - float(enemy_count - 1) * float(_enemy_panel_gap())) / float(enemy_count))
	var minimum_width := 72.0
	if content_width < 360.0:
		minimum_width = 36.0
	elif content_width < 460.0:
		minimum_width = 44.0
	elif _is_pc_layout():
		minimum_width = 210.0
	return clamp(width, minimum_width, 340.0 if _is_pc_layout() else 198.0)

func _enemy_panel_height() -> float:
	return clamp(round((342.0 if _is_pc_layout() else 132.0) * _combat_layout_scale()), 96.0, 368.0 if _is_pc_layout() else 136.0)

func _enemy_art_height() -> float:
	return clamp(round((226.0 if _is_pc_layout() else 58.0) * _combat_layout_scale()), 38.0, 246.0 if _is_pc_layout() else 62.0)

func _enemy_badge_height() -> float:
	return clamp(round((28.0 if _is_pc_layout() else 22.0) * _combat_layout_scale()), 18.0, 30.0 if _is_pc_layout() else 24.0)

func _enemy_button_height() -> float:
	return clamp(round((50.0 if _is_pc_layout() else 42.0) * _combat_layout_scale()), 32.0, 54.0 if _is_pc_layout() else 46.0)

func _pc_enemy_info_width(panel_width: float) -> float:
	return clamp(round(panel_width * 0.78), 174.0, 258.0)

func _potion_slot_gap() -> int:
	return 6

func _potion_slot_button_size() -> Vector2:
	if _is_pc_layout():
		return Vector2(48.0, 36.0)
	var scale_y: float = _combat_layout_scale()
	var slots := 2
	if player_data != null and not player_data.is_empty():
		slots = max(1, _max_potion_slots())
	var available_width: float = _scroll_content_width()
	var target_minimum := 170.0 if _is_pc_layout() else 210.0
	var slot_minimum := 48.0
	if available_width < 420.0:
		target_minimum = 96.0
		slot_minimum = 28.0
	var max_row_width := 238.0 if _is_pc_layout() else 344.0
	var target_row_width: float = clamp(available_width * (0.22 if _is_pc_layout() else (0.38 if slots >= 3 else 0.34)), target_minimum, min(max_row_width, available_width))
	if available_width < 420.0:
		target_row_width = clamp(available_width * (0.30 if slots >= 3 else 0.26), target_minimum, min(132.0, available_width))
	var label_width := 44.0
	if available_width < 420.0:
		label_width = 30.0
	var slot_width: float = floor((target_row_width - label_width - float(slots) * float(_potion_slot_gap())) / float(slots))
	return Vector2(clamp(slot_width, slot_minimum, 76.0 if _is_pc_layout() else 96.0), clamp(round(48.0 * scale_y), 34.0, 50.0))

func _potion_row_width() -> float:
	var slots := 2
	if player_data != null and not player_data.is_empty():
		slots = max(1, _max_potion_slots())
	if _is_pc_layout():
		return float(slots) * _potion_slot_button_size().x + float(max(0, slots - 1)) * float(_potion_slot_gap())
	var label_width := 44.0
	if _scroll_content_width() < 420.0:
		label_width = 30.0
	return label_width + float(slots) * _potion_slot_button_size().x + float(max(0, slots)) * float(_potion_slot_gap())

func _hud_block_width() -> float:
	var entries := 5 if _is_pc_layout() else 7
	var gap := 6.0
	var available_width: float = _scroll_content_width()
	if _is_pc_layout():
		available_width = max(360.0, available_width - _potion_row_width() - 18.0)
	var width: float = floor((available_width - float(entries - 1) * gap) / float(entries))
	var minimum_width := 64.0 if available_width >= 420.0 else 38.0
	return clamp(width, minimum_width, 112.0 if _is_pc_layout() else 98.0)

func _hand_scroll_content_width() -> float:
	var width: float = _scroll_content_width()
	if _is_pc_layout():
		width -= PC_HAND_LEFT_DOCK_WIDTH + PC_HAND_RIGHT_DOCK_WIDTH + 16.0
	return max(MIN_SAFE_CONTENT_WIDTH, width)

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

func _refresh_welcome() -> void:
	last_welcome_action_count = 0
	last_welcome_continue_available = not SaveManagerScript.load_run().is_empty()
	run_label.text = "牌组构筑 Roguelike"
	status_label.text = "穿过三章失控回路，在敌人的行动意图中构筑自己的战斗协议。"
	_set_page_regions(false, false, false, false, false, true, false, true)
	if reward_scroll != null:
		reward_scroll.set("vertical_scroll_mode", 0 if _is_pc_layout() else 1)
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	_set_content_heights(74.0, 360.0 if _is_pc_layout() else 300.0)
	log_label.text = "余烬回路已失去控制。选择一名回路行者，沿分叉路线战斗、改造牌组并关闭核心。"
	log_label.tooltip_text = "当前版本包含三名角色、三章路线、普通/精英/Boss 战斗、事件、商店、篝火、宝箱与局外成长。"

	var welcome_page = WelcomePageScript.new()
	welcome_page.configure({
		"title": "余烬回路",
		"eyebrow": "EMBER CIRCUIT",
		"subtitle": "穿过三章失控回路，在行动意图中重写战斗协议。",
		"continue_available": last_welcome_continue_available,
		"available_width": _layout_viewport_size().x,
		"reduced_motion": bool(user_settings.get("reduced_motion", false))
	})
	welcome_page.new_run_requested.connect(_on_new_run_pressed)
	welcome_page.continue_requested.connect(_on_load_pressed)
	welcome_page.archive_requested.connect(_on_compendium_pressed)
	welcome_page.profile_requested.connect(_on_profile_pressed)
	welcome_page.settings_requested.connect(_on_settings_pressed)
	app_shell.mount_page(welcome_page, "welcome")
	last_welcome_action_count = 5
	_record_layout_metrics()

func _refresh_character_select() -> void:
	last_character_selection_title = "选择角色"
	last_character_selection_ids.clear()
	last_character_button_icon_count = 0
	last_challenge_button_count = 0
	last_character_selection_confirm_visible = false
	last_character_selection_selected_id = selected_character_id
	selected_challenge_level = _valid_challenge_level(selected_challenge_level)
	last_challenge_level = selected_challenge_level
	last_challenge_unlocked_max = _max_unlocked_challenge_level()
	last_challenge_modifier_summary = _challenge_modifier_summary(selected_challenge_level)
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		last_character_selection_ids.append(str(character_dict.get("id", "")))

	run_label.text = "新跑团 | %s" % last_character_selection_title
	status_label.text = "选择本次跑团的角色和挑战等级。不同角色拥有独立初始牌组、起始遗物、生命、势能和药水槽。"
	_set_page_regions(false, false, false, false, false, true, false, true)
	if reward_scroll != null:
		reward_scroll.set("vertical_scroll_mode", 0 if _is_pc_layout() else 1)
	if _is_pc_layout():
		title_label.visible = false
		status_label.visible = false
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
	log_label.text = _challenge_log_text(selected_challenge_level, last_challenge_unlocked_max, str(challenge_config.get("short_name", "普通")))
	log_label.tooltip_text = "%s\n\n%s" % [challenge_summary, _character_selection_roster_text()]
	var character_models: Array = []
	for character in player_data.get("characters", []):
		var character_dict: Dictionary = character
		var character_id := str(character_dict.get("id", ""))
		if character_id.is_empty():
			continue
		var texture: Texture2D = _load_texture(_character_art_path(character_id))
		if texture != null:
			last_character_button_icon_count += 1
		character_models.append({
			"id": character_id,
			"name": str(character_dict.get("name", character_id)),
			"archetype": str(character_dict.get("archetype_note", "")),
			"max_hp": int(character_dict.get("max_hp", 0)),
			"max_energy": int(character_dict.get("max_energy", 0)),
			"starting_momentum": int(character_dict.get("starting_momentum", 0)),
			"momentum_max": int(character_dict.get("momentum_max", 0)),
			"starting_gold": int(character_dict.get("starting_gold", 0)),
			"potion_slots": int(character_dict.get("potion_slots", 0)),
			"accent_color": _character_accent_color(character_id),
			"relic_names": _relic_names(character_dict.get("starter_relic_ids", [])),
			"deck_count": character_dict.get("starter_deck_ids", []).size(),
			"deck_summary": _card_names(character_dict.get("starter_deck_ids", [])),
			"tooltip": _character_selection_tooltip_text(character_dict),
			"texture": texture
		})
	var challenge_models: Array = []
	for challenge_value in challenge_data.get("levels", []):
		var challenge: Dictionary = challenge_value
		var level := int(challenge.get("level", 0))
		challenge_models.append({
			"level": level,
			"short_name": str(challenge.get("short_name", "挑战 %d" % level)),
			"description": str(challenge.get("description", "")),
			"modifier_summary": _challenge_modifier_summary(level),
			"tooltip": _challenge_tooltip_text(level)
		})
	var character_page = CharacterSelectPageScript.new()
	character_page.configure({
		"selected_character_id": selected_character_id,
		"selected_challenge_level": selected_challenge_level,
		"unlocked_challenge_max": last_challenge_unlocked_max,
		"characters": character_models,
		"challenges": challenge_models,
		"compact": _layout_viewport_size().x < 900.0,
		"available_width": _layout_viewport_size().x,
		"available_height": _layout_viewport_size().y,
		"reduced_motion": bool(user_settings.get("reduced_motion", false))
	})
	character_page.character_preview_requested.connect(_on_character_preview_selected)
	character_page.challenge_delta_requested.connect(_on_character_challenge_level_requested)
	character_page.confirm_requested.connect(func(_id: String, _level: int) -> void: _on_character_confirm_pressed())
	character_page.back_requested.connect(_on_welcome_pressed)
	app_shell.mount_page(character_page, "character_select")
	last_challenge_button_count = character_page.challenge_buttons.size()
	last_character_selection_confirm_visible = character_page.confirm_button != null
	last_character_selection_selected_id = selected_character_id
	_record_layout_metrics()

func _on_character_challenge_level_requested(level: int) -> void:
	selected_challenge_level = _valid_challenge_level(level)
	_audio_event("ui_click")
	_refresh()

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
	_apply_reward_page_layout_constraints(72.0, 430.0)
	if _is_pc_layout():
		_set_content_heights(56.0, 410.0)
	last_run_completion_title = _run_completion_title()
	last_run_unlocks = _run_completion_unlocks()
	last_run_completion_summary = _run_completion_summary()
	last_run_completion_panel_visible = false
	last_run_completion_art_path = ""
	last_run_completion_art_loaded = false
	last_run_completion_stat_chip_count = 0
	last_run_completion_unlock_chip_count = 0
	last_run_completion_action_count = 0
	last_run_completion_export_button_visible = false
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
	log_label.text = _run_completion_logline()
	end_turn_button.disabled = true
	last_run_completion_panel_visible = true
	last_run_completion_art_path = _battle_background_path(current_chapter_id)
	last_run_completion_art_loaded = _asset_loaded(last_run_completion_art_path)
	last_run_completion_stat_chip_count = 6
	last_run_completion_unlock_chip_count = max(1, last_run_unlocks.size())
	last_run_completion_action_count = 4
	last_run_completion_export_button_visible = true
	_mount_outcome_pages(_victory_outcome_page_model())
	_record_layout_metrics()

func _victory_outcome_page_model() -> Dictionary:
	return {
		"mode": "victory",
		"title": last_run_completion_title,
		"subtitle": _run_completion_epilogue(),
		"chapter_id": current_chapter_id,
		"character_id": selected_character_id,
		"art_path": last_run_completion_art_path,
		"stats": {
			"hp": run_hp,
			"max_hp": run_max_hp,
			"gold": run_gold,
			"deck_size": run_deck_ids.size(),
			"relic_count": run_relic_ids.size(),
			"potion_count": run_potion_ids.size()
		},
		"stat_entries": [
			["生命", "%d/%d" % [run_hp, run_max_hp]],
			["金币", "%d" % run_gold],
			["牌组", "%d 张" % run_deck_ids.size()],
			["章节", "%d/3" % completed_chapter_ids.size()],
			["遗物", "%d" % run_relic_ids.size()],
			["药水", "%d" % run_potion_ids.size()]
		],
		"unlocks": last_run_unlocks.duplicate(),
		"persistence_error": ""
	}

func _mount_outcome_pages(base_model: Dictionary) -> void:
	var visible_model := base_model.duplicate(true)
	visible_model["available_width"] = _layout_viewport_size().x
	visible_model["available_height"] = _layout_viewport_size().y
	var visible_page = _new_outcome_page(visible_model)
	app_shell.mount_page(visible_page, "outcome")

func _new_outcome_page(model: Dictionary):
	var page = OutcomePageScript.new()
	page.configure(model)
	page.continue_requested.connect(_on_new_run_pressed)
	page.retry_requested.connect(_on_retry_terminal_persistence_pressed)
	page.new_run_requested.connect(_on_new_run_pressed)
	page.deck_requested.connect(_on_deck_view_pressed)
	page.export_requested.connect(_on_export_playtest_report_pressed)
	page.profile_requested.connect(_on_profile_pressed)
	return page

func _run_completion_logline() -> String:
	return "%s\n完成章节：%s | 最终资源：生命 %d/%d，金币 %d，遗物 %d，药水 %d" % [
		_run_completion_epilogue(),
		" -> ".join(_completed_chapter_display_names()),
		run_hp,
		run_max_hp,
		run_gold,
		run_relic_ids.size(),
		run_potion_ids.size()
	]

func _completed_chapter_display_names() -> Array[String]:
	var chapter_names: Array[String] = []
	for chapter_id in completed_chapter_ids:
		chapter_names.append(_chapter_display_name(str(chapter_id)))
	return chapter_names

func _run_completion_summary() -> String:
	var summary: Dictionary = _deck_summary()
	var chapter_names: Array[String] = _completed_chapter_display_names()
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

func _defeat_outcome_data() -> Dictionary:
	var node: Dictionary = _current_node()
	var encounter_id: String = str(node.get("encounter_id", ""))
	var encounter: Dictionary = _encounter_by_id(encounter_id)
	var route_total: int = map_graph.get("layers", []).size()
	if route_total <= 0:
		route_total = route_nodes.size()
	route_total = max(1, route_total)
	var route_step: int = int(node.get("layer", current_node_index)) + 1
	var boss_count: int = _defeat_completed_boss_count()
	var boss_reward: int = int(progression_data.get("currency", {}).get("boss_reward", 2))
	return {
		"chapter_id": current_chapter_id,
		"chapter_name": _chapter_display_name(current_chapter_id),
		"node_name": str(node.get("name", "战斗节点")),
		"encounter_id": encounter_id,
		"encounter_name": str(encounter.get("name", node.get("name", "未知遭遇"))),
		"turn": int(combat.turn) if combat != null else 0,
		"route_step": clamp(route_step, 1, route_total),
		"route_total": route_total,
		"challenge_level": current_challenge_level,
		"gold": run_gold,
		"deck_size": run_deck_ids.size(),
		"relic_count": run_relic_ids.size(),
		"potion_count": run_potion_ids.size(),
		"bosses_defeated": boss_count,
		"forge_marks_earned": boss_count * boss_reward,
		"forge_marks_total": _progression_currency_amount(),
		"surviving_enemies": _defeat_surviving_enemies().size()
	}

func _defeat_completed_boss_count() -> int:
	var chapter_sequence: Array = map_generation_data.get("chapter_sequence", [])
	var seen: Dictionary = {}
	for chapter_id_value in completed_chapter_ids:
		var chapter_id: String = str(chapter_id_value)
		if chapter_sequence.has(chapter_id):
			seen[chapter_id] = true
	return seen.size()

func _defeat_surviving_enemies() -> Array[Dictionary]:
	var survivors: Array[Dictionary] = []
	if combat == null:
		return survivors
	for enemy_value in combat.enemies:
		var enemy: Dictionary = enemy_value
		if int(enemy.get("hp", 0)) > 0:
			survivors.append(enemy)
	return survivors

func _refresh_map_choices() -> void:
	var use_map_page := _is_pc_layout()
	_set_page_regions(true, false, not use_map_page, false, false, true, false, false)
	_apply_map_layout_constraints()
	_apply_pc_map_chrome()
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
	if not use_map_page:
		map_view.set_map_state(_map_graph_for_view(), available_node_ids, completed_node_ids, current_node_id)
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	var preview_node_id := _default_map_preview_node_id()
	if use_map_page:
		_mount_map_page(preview_node_id)
	_update_map_preview(preview_node_id)
	end_turn_button.disabled = true
	_record_layout_metrics()

func _map_page_model(preview_node_id: String) -> Dictionary:
	var preview_node: Dictionary = _node_by_id(preview_node_id)
	var successor_ids: Array[String] = _successor_node_ids(preview_node_id)
	var successor_names: Array[String] = []
	for successor_id in successor_ids:
		var successor: Dictionary = _node_by_id(successor_id)
		successor_names.append(
			successor_id if successor.is_empty() else "%s [%s]" % [
				successor.get("name", successor_id),
				_node_type_display_name(str(successor.get("type", "")))
			]
		)
	return {
		"graph": _map_graph_for_view(),
		"available_node_ids": available_node_ids.duplicate(),
		"completed_node_ids": completed_node_ids.duplicate(true),
		"current_node_id": current_node_id,
		"preview_successor_ids": successor_ids,
		"preview_title": "暂无可预览节点" if preview_node.is_empty() else "%s [%s]" % [preview_node.get("name", preview_node_id), _node_type_display_name(str(preview_node.get("type", "")))],
		"preview_risk": "未知" if preview_node.is_empty() else _node_risk_summary(preview_node),
		"preview_reward": "待确认" if preview_node.is_empty() else _node_reward_summary(preview_node),
		"preview_description": "暂无节点说明。" if preview_node.is_empty() else _node_detail_text(preview_node),
		"preview_successors": successor_names,
		"risk_summary": "未知" if preview_node.is_empty() else _node_risk_summary(preview_node),
		"available_width": _layout_viewport_size().x,
		"available_height": _layout_viewport_size().y
	}

func _mount_map_page(preview_node_id: String) -> void:
	var page = MapPageScript.new()
	page.configure(_map_page_model(preview_node_id))
	page.node_selected.connect(_on_map_node_pressed)
	page.node_previewed.connect(_on_map_node_previewed)
	var legacy_map_view := map_view
	if legacy_map_view != null and legacy_map_view.get_parent() == map_scroll:
		map_scroll.remove_child(legacy_map_view)
		legacy_map_view.queue_free()
	map_view = page.map_view
	app_shell.mount_page(page, "map")

func _refresh_deck_view() -> void:
	_set_page_regions(true, false, false, false, false, true, false, true)
	_apply_deck_view_layout_constraints()
	last_deck_view_card_layout_count = 0
	last_deck_view_card_art_node_count = 0
	last_deck_view_visible_card_count = 0
	last_deck_view_filter_button_count = 0
	last_deck_view_sort_option_count = 0
	last_deck_view_toolbar_visible = false
	run_label.text = "%s · %s · 挑战 %d · 当前牌组 %d 张 · 生命 %d/%d · 金币 %d" % [
		_character_display_name(),
		_chapter_display_name(current_chapter_id),
		current_challenge_level,
		run_deck_ids.size(),
		run_hp,
		run_max_hp,
		run_gold
	]
	status_label.text = "当前牌组"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true

	var summary: Dictionary = _deck_summary()
	last_deck_view_cost_curve_text = _deck_cost_curve_text()
	log_label.text = "构成  攻击 %d  ·  技能 %d  ·  能力 %d  ·  状态/诅咒 %d  ·  升级牌 +%d\n%s" % [
		int(summary.get("attack", 0)),
		int(summary.get("skill", 0)),
		int(summary.get("power", 0)),
		int(summary.get("other", 0)),
		int(summary.get("upgraded", 0)),
		last_deck_view_cost_curve_text
	]

	_add_deck_view_toolbar()
	var visible_cards: Array[Dictionary] = _deck_view_cards()
	last_deck_view_visible_card_count = visible_cards.size()
	for card in visible_cards:
		var card_button := Button.new()
		card_button.custom_minimum_size = _large_card_button_size()
		card_button.text = ""
		card_button.focus_mode = Control.FOCUS_NONE
		card_button.tooltip_text = "%s [%d]\n%s\n%s" % [
			card.get("name", "卡牌"),
			int(card.get("cost", 0)),
			_card_type_display_name(str(card.get("type", ""))),
			card.get("description", "")
		]
		var art_path: String = _card_art_path(card)
		var card_texture: Texture2D = _load_texture(art_path)
		_apply_card_button_skin(card_button, str(card.get("type", "")))
		_add_structured_card_layout(card_button, card, card_texture, "deck_view")
		reward_row.add_child(card_button)
	if visible_cards.is_empty():
		_add_deck_view_empty_state()
	_record_layout_metrics()

func _apply_deck_view_layout_constraints() -> void:
	if not _is_pc_layout():
		_apply_reward_page_layout_constraints(112.0, 250.0)
		return
	if title_label != null:
		title_label.visible = false
	if status_label != null:
		status_label.visible = false
	if character_frame != null:
		character_frame.visible = false
	if character_panel != null:
		character_panel.visible = false
	if controls_scroll != null:
		controls_scroll.visible = false
	var deck_height: float = clamp(_layout_viewport_size().y - 165.0, 500.0, 660.0)
	_set_content_heights(64.0, deck_height)
	_record_scroll_region_metrics()

func _add_deck_view_toolbar() -> void:
	var toolbar := HBoxContainer.new()
	toolbar.name = "DeckToolbar"
	toolbar.custom_minimum_size = Vector2(_scroll_content_width(), 44)
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_theme_constant_override("separation", 7)
	reward_row.add_child(toolbar)
	last_deck_view_toolbar_visible = true

	var filter_specs := [
		["all", "全部"],
		["attack", "攻击"],
		["skill", "技能"],
		["power", "能力"],
		["other", "状态"],
		["upgraded", "已升级"]
	]
	for spec_value in filter_specs:
		var spec: Array = spec_value
		var filter_id: String = str(spec[0])
		var button := Button.new()
		button.name = "DeckFilter_%s" % filter_id
		button.custom_minimum_size = Vector2(66 if filter_id != "upgraded" else 80, 34)
		button.text = str(spec[1])
		button.tooltip_text = "筛选%s牌" % str(spec[1])
		_apply_button_skin(button, "primary" if deck_view_filter == filter_id else "neutral")
		button.pressed.connect(_on_deck_view_filter_pressed.bind(filter_id))
		toolbar.add_child(button)
		last_deck_view_filter_button_count += 1

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	var sort_menu := OptionButton.new()
	sort_menu.name = "DeckSortMenu"
	sort_menu.custom_minimum_size = Vector2(128, 34)
	sort_menu.tooltip_text = "调整牌组排列顺序"
	var sort_specs := [["type", "按类型"], ["cost", "按费用"], ["name", "按名称"], ["upgrade", "升级优先"]]
	var selected_sort_index := 0
	for i in range(sort_specs.size()):
		var sort_spec: Array = sort_specs[i]
		sort_menu.add_item(str(sort_spec[1]))
		sort_menu.set_item_metadata(i, str(sort_spec[0]))
		if str(sort_spec[0]) == deck_view_sort:
			selected_sort_index = i
	sort_menu.select(selected_sort_index)
	_apply_button_skin(sort_menu, "neutral")
	sort_menu.item_selected.connect(_on_deck_view_sort_selected.bind(sort_menu))
	toolbar.add_child(sort_menu)
	last_deck_view_sort_option_count = sort_specs.size()

	var close_button := Button.new()
	close_button.name = "DeckCloseButton"
	close_button.custom_minimum_size = Vector2(104, 34)
	close_button.text = "返回游戏"
	_apply_button_skin(close_button, "event")
	close_button.pressed.connect(_on_close_deck_view_pressed)
	toolbar.add_child(close_button)

func _deck_view_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for entry_value in run_deck_ids:
		var entry: String = str(entry_value)
		var card: Dictionary = _deck_display_card(entry)
		if card.is_empty():
			continue
		card["_deck_entry"] = entry
		card["_deck_upgraded"] = entry.ends_with("+")
		if not _deck_view_card_matches_filter(card):
			continue
		cards.append(card)
	cards.sort_custom(Callable(self, "_deck_view_card_less"))
	return cards

func _deck_view_card_matches_filter(card: Dictionary) -> bool:
	var card_type: String = str(card.get("type", "other"))
	match deck_view_filter:
		"attack", "skill", "power":
			return card_type == deck_view_filter
		"other":
			return not ["attack", "skill", "power"].has(card_type)
		"upgraded":
			return bool(card.get("_deck_upgraded", false))
	return true

func _deck_view_card_less(a: Dictionary, b: Dictionary) -> bool:
	return _deck_view_sort_key(a) < _deck_view_sort_key(b)

func _deck_view_sort_key(card: Dictionary) -> String:
	var card_type: String = str(card.get("type", "other"))
	var type_order := {"attack": 0, "skill": 1, "power": 2}
	var type_index: int = int(type_order.get(card_type, 3))
	var cost: int = int(card.get("cost", 0))
	var name: String = str(card.get("name", ""))
	var upgraded: int = 0 if bool(card.get("_deck_upgraded", false)) else 1
	match deck_view_sort:
		"cost":
			return "%03d|%02d|%s" % [cost, type_index, name]
		"name":
			return "%s|%02d|%03d" % [name, type_index, cost]
		"upgrade":
			return "%d|%02d|%03d|%s" % [upgraded, type_index, cost, name]
	return "%02d|%03d|%s" % [type_index, cost, name]

func _deck_cost_curve_text() -> String:
	var curve := [0, 0, 0, 0]
	var total_cost := 0
	for entry_value in run_deck_ids:
		var card: Dictionary = _deck_display_card(str(entry_value))
		if card.is_empty():
			continue
		var cost: int = max(0, int(card.get("cost", 0)))
		total_cost += cost
		curve[min(cost, 3)] = int(curve[min(cost, 3)]) + 1
	var average: float = float(total_cost) / float(max(1, run_deck_ids.size()))
	return "费用曲线  0费 %d  ·  1费 %d  ·  2费 %d  ·  3费以上 %d  ·  平均 %.1f" % [curve[0], curve[1], curve[2], curve[3], average]

func _add_deck_view_empty_state() -> void:
	var empty := Label.new()
	empty.name = "DeckFilterEmptyState"
	empty.custom_minimum_size = Vector2(_scroll_content_width(), 150)
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.text = "当前筛选没有卡牌"
	empty.add_theme_font_size_override("font_size", 18)
	empty.add_theme_color_override("font_color", Color(0.66, 0.70, 0.68))
	reward_row.add_child(empty)

func _on_deck_view_filter_pressed(filter_id: String) -> void:
	deck_view_filter = filter_id if ["all", "attack", "skill", "power", "other", "upgraded"].has(filter_id) else "all"
	_audio_event("ui_click")
	_refresh_deck_view()

func _on_deck_view_sort_selected(index: int, sort_menu: OptionButton) -> void:
	if sort_menu == null or index < 0 or index >= sort_menu.item_count:
		return
	deck_view_sort = str(sort_menu.get_item_metadata(index))
	_audio_event("ui_click")
	_refresh_deck_view()

func _refresh_settings_view() -> void:
	last_settings_panel_visible = true
	last_settings_button_count = 13
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
	var settings_page = SettingsPageScript.new()
	settings_page.configure({
		"settings": user_settings.duplicate(true),
		"source_page": _settings_source_page_id(),
		"available_width": _layout_viewport_size().x,
		"available_height": _layout_viewport_size().y
	})
	settings_page.setting_changed.connect(_on_settings_page_setting_changed)
	settings_page.reset_requested.connect(_on_settings_reset_pressed)
	settings_page.tutorial_reset_requested.connect(_on_settings_reset_tutorial_pressed)
	settings_page.close_requested.connect(_on_close_settings_pressed)
	app_shell.mount_page(settings_page, "settings")
	_apply_tutorial_hint("settings")
	_record_layout_metrics()

func _settings_source_page_id() -> String:
	if welcome_open:
		return "welcome"
	if character_select_open:
		return "character_select"
	if run_completed:
		return "outcome"
	return "run"

func _on_settings_page_setting_changed(setting_id: String, value: Variant) -> void:
	if not SaveManagerScript.default_settings().has(setting_id):
		return
	user_settings[setting_id] = value
	_save_user_settings()
	_audio_event("ui_click")
	_refresh()

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
	last_profile_export_button_visible = false
	last_profile_button_count = 0
	last_profile_character_selector_count = 0
	last_profile_forge_marks = _progression_currency_amount()
	last_profile_upgrade_node_count = _purchased_upgrade_node_ids().size()
	last_profile_skill_book_count = _unlocked_skill_book_count()
	_refresh_achievement_unlocks("profile_view")
	_set_page_regions(false, false, false, false, false, true, false, true)
	_apply_reward_page_layout_constraints(148.0, 224.0)
	run_label.text = "局外档案 | 炉印 %d | 成就 %d/%d" % [last_profile_forge_marks, last_profile_unlocked_count, last_profile_total_count]
	status_label.text = "使用炉印购买角色升级，并为当前选中角色装备技能书。局外成长仅在下一次新跑团生效。"
	status_label.tooltip_text = status_label.text
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true
	log_label.text = _profile_summary_text()

	var profile_root := VBoxContainer.new()
	profile_root.custom_minimum_size = Vector2(_scroll_content_width(), 0)
	profile_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_root.add_theme_constant_override("separation", 10)
	reward_row.add_child(profile_root)

	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size = Vector2(_scroll_content_width(), 52)
	toolbar.add_theme_constant_override("separation", 6)
	profile_root.add_child(toolbar)
	_add_profile_button("返回档案", "primary", Callable(self, "_on_close_profile_pressed"), toolbar)
	_add_profile_button("导出报告", "event", Callable(self, "_on_export_playtest_report_pressed"), toolbar, UI_EXPORT_REPORT_ICON_PATH, "导出本机匿名逐局数据，文件路径会复制到剪贴板。")
	last_profile_export_button_visible = true
	for character_value in player_data.get("characters", []):
		var character: Dictionary = character_value
		var character_id: String = str(character.get("id", ""))
		if character_id.is_empty():
			continue
		var character_button := Button.new()
		character_button.custom_minimum_size = Vector2(_profile_character_button_width(), 48)
		character_button.text = str(character.get("name", character_id))
		character_button.icon = _load_texture(_character_art_path(character_id))
		character_button.expand_icon = true
		character_button.tooltip_text = "查看 %s 的角色升级树和技能书配置。" % str(character.get("name", character_id))
		_apply_button_skin(character_button, "relic" if profile_character_id == character_id else "neutral")
		character_button.disabled = profile_character_id == character_id
		character_button.pressed.connect(_on_profile_character_pressed.bind(character_id))
		toolbar.add_child(character_button)
		last_profile_button_count += 1
		last_profile_character_selector_count += 1

	_add_profile_progression_entries(profile_root)
	_add_profile_section_header(profile_root, "成就档案", "%d/%d 已解锁" % [last_profile_unlocked_count, last_profile_total_count], UI_PROFILE_ICON_PATH, "success")
	var achievement_flow := HFlowContainer.new()
	achievement_flow.custom_minimum_size = Vector2(_scroll_content_width(), 0)
	achievement_flow.add_theme_constant_override("h_separation", 6)
	achievement_flow.add_theme_constant_override("v_separation", 6)
	profile_root.add_child(achievement_flow)
	for achievement in achievement_data.get("achievements", []):
		var achievement_dict: Dictionary = achievement
		var achievement_id: String = str(achievement_dict.get("id", ""))
		if achievement_id.is_empty():
			continue
		var unlocked: bool = _profile_unlocked_achievements().has(achievement_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(_profile_achievement_card_width(), 88)
		button.text = ""
		button.tooltip_text = "%s\n%s\n%s" % [
			str(achievement_dict.get("name", achievement_id)),
			str(achievement_dict.get("description", "")),
			str(achievement_dict.get("design_note", ""))
		]
		_apply_button_skin(button, "success" if unlocked else "neutral")
		button.disabled = true
		_add_profile_option_layout(button, str(achievement_dict.get("name", achievement_id)), "已解锁" if unlocked else "未解锁", str(achievement_dict.get("description", "")), UI_PROFILE_ICON_PATH, "success" if unlocked else "neutral")
		achievement_flow.add_child(button)
		last_profile_button_count += 1
	_record_layout_metrics()

func _add_profile_button(text: String, skin: String, pressed_callable: Callable, parent: Container = null, icon_path: String = UI_CONTINUE_ROUTE_ICON_PATH, tooltip: String = "") -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(132, 48)
	button.text = text
	button.icon = _load_texture(icon_path)
	button.expand_icon = true
	button.tooltip_text = tooltip if not tooltip.is_empty() else text
	_apply_button_skin(button, skin)
	button.pressed.connect(pressed_callable)
	(parent if parent != null else reward_row).add_child(button)
	last_profile_button_count += 1

func _profile_achievement_card_width() -> float:
	var available: float = _scroll_content_width()
	var columns: int = 3 if available >= 840.0 else (2 if available >= 520.0 else 1)
	return floor((available - 6.0 * float(columns - 1)) / float(columns))

func _profile_character_button_width() -> float:
	return clamp(floor((_scroll_content_width() - 150.0) / 3.0), 176.0, 248.0)

func _profile_progression_card_width(columns: int) -> float:
	return floor((_scroll_content_width() - 6.0 * float(columns - 1)) / float(columns))

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
	last_profile_summary = "档案统计 | 炉印 %d | 角色升级 %d/9 | 技能书 %d/%d | 当前装备：%s\n跑团开始 %d | 完整通关 %d | 击败 Boss %d | 商店删卡 %d | 最高金币 %d | 最大牌组 %d\n挑战完成 %d | 最高解锁 %d | 完成章节：%s\n角色通关：%s | 最近解锁：%s" % [
		_progression_currency_amount(),
		_purchased_upgrade_node_ids().size(),
		_unlocked_skill_book_count(),
		progression_data.get("skill_books", []).size(),
		str(_skill_book_by_id(_equipped_skill_book_for_character(profile_character_id)).get("name", "钢铁手册")),
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

func _add_profile_progression_entries(parent: VBoxContainer) -> void:
	var tree: Dictionary = _character_tree_for_id(profile_character_id)
	_add_profile_section_header(parent, str(tree.get("name", "角色升级树")), "炉印 %d | 购买后下次跑团生效" % _progression_currency_amount(), UI_PROFILE_ICON_PATH, "relic")
	var tree_flow := HFlowContainer.new()
	tree_flow.custom_minimum_size = Vector2(_scroll_content_width(), 0)
	tree_flow.add_theme_constant_override("h_separation", 6)
	tree_flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(tree_flow)
	for node_value in tree.get("nodes", []):
		var node: Dictionary = node_value
		var node_id: String = str(node.get("id", ""))
		if node_id.is_empty():
			continue
		var owned: bool = _purchased_upgrade_node_ids().has(node_id)
		var blocked_reason: String = _upgrade_node_blocked_reason(node)
		var state_text: String = "已购买" if owned else ("成本 %d 炉印" % int(node.get("cost", 0)) if blocked_reason.is_empty() else blocked_reason)
		var skin: String = "success" if owned else ("relic" if blocked_reason.is_empty() else "neutral")
		var button := Button.new()
		button.custom_minimum_size = Vector2(_profile_progression_card_width(3), 94)
		button.text = ""
		button.tooltip_text = "%s\n%s\n%s\n%s" % [str(tree.get("name", "角色升级")), str(node.get("description", "")), str(node.get("design_note", "")), state_text]
		_apply_button_skin(button, skin)
		button.disabled = owned or not blocked_reason.is_empty()
		button.pressed.connect(_on_upgrade_node_pressed.bind(node_id))
		_add_profile_option_layout(button, str(node.get("name", node_id)), state_text, str(node.get("description", "")), _upgrade_node_icon_path(node), skin)
		tree_flow.add_child(button)
		last_profile_button_count += 1

	_add_profile_section_header(parent, "技能书", "装备给 %s | 每局限 1 本" % _character_display_name(profile_character_id), UI_COMPENDIUM_ICON_PATH, "event")
	var book_flow := HFlowContainer.new()
	book_flow.custom_minimum_size = Vector2(_scroll_content_width(), 0)
	book_flow.add_theme_constant_override("h_separation", 6)
	book_flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(book_flow)
	for book_value in progression_data.get("skill_books", []):
		var book: Dictionary = book_value
		var book_id: String = str(book.get("id", ""))
		var unlocked: bool = _skill_book_unlocked(book)
		var equipped: bool = _equipped_skill_book_for_character(profile_character_id) == book_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(_profile_progression_card_width(4), 94)
		button.text = ""
		button.tooltip_text = "%s\n%s\n%s" % [str(book.get("description", "")), str(book.get("design_note", "")), str(book.get("balance_note", ""))]
		var skin: String = "success" if equipped else ("event" if unlocked else "neutral")
		_apply_button_skin(button, skin)
		button.disabled = not unlocked or equipped
		button.pressed.connect(_on_skill_book_equipped.bind(book_id))
		_add_profile_option_layout(button, str(book.get("name", book_id)), "已装备" if equipped else ("可装备" if unlocked else "未解锁"), str(book.get("description", "")), _skill_book_icon_path(book_id), skin)
		book_flow.add_child(button)
		last_profile_button_count += 1

func _add_profile_section_header(parent: VBoxContainer, title_text: String, detail_text: String, icon_path: String, skin: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(_scroll_content_width(), 28)
	row.add_theme_constant_override("separation", 7)
	parent.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.texture = _load_texture(icon_path)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", _icon_item_accent_color(skin))
	row.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var detail := Label.new()
	detail.text = detail_text
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", Color(0.76, 0.80, 0.78))
	row.add_child(detail)

func _add_profile_option_layout(button: Button, title_text: String, state_text: String, description_text: String, icon_path: String, skin: String) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 9
	margin.offset_top = 8
	margin.offset_right = -9
	margin.offset_bottom = -8
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)
	row.add_child(_icon_item_frame(_load_texture(icon_path), skin, Vector2(42, 42)))
	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 1)
	row.add_child(text_box)
	var title := _icon_item_label(title_text, 13, Color(0.96, 0.96, 0.90), HORIZONTAL_ALIGNMENT_LEFT)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_box.add_child(title)
	var state := _icon_item_label(state_text, 11, _icon_item_accent_color(skin), HORIZONTAL_ALIGNMENT_LEFT)
	state.clip_text = true
	state.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_box.add_child(state)
	var description := _icon_item_label(description_text, 10, Color(0.78, 0.82, 0.80), HORIZONTAL_ALIGNMENT_LEFT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_box.add_child(description)

func _upgrade_node_icon_path(node: Dictionary) -> String:
	var effects: Array = node.get("effects", [])
	var effect_type: String = str((effects[0] as Dictionary).get("type", "")) if not effects.is_empty() else ""
	match effect_type:
		"max_hp_bonus":
			return _hud_icon_path("生命")
		"starting_gold_bonus":
			return _hud_icon_path("金币")
		"starting_momentum_bonus":
			return _hud_icon_path("势能")
		"potion_slot_bonus":
			return _potion_fallback_icon_path()
		"combat_start_block":
			return _hud_icon_path("护甲")
	return UI_PROFILE_ICON_PATH

func _skill_book_icon_path(book_id: String) -> String:
	match book_id:
		"steel_manual":
			return _hud_icon_path("护甲")
		"swift_current_notes":
			return _hud_icon_path("抽牌")
		"furnace_edict":
			return _hud_icon_path("能量")
		"ember_ritual":
			return str(INTENT_ICON_PATHS.get("debuff", UI_COMPENDIUM_ICON_PATH))
	return UI_COMPENDIUM_ICON_PATH

func _on_profile_character_pressed(character_id: String) -> void:
	if _character_config(character_id).is_empty():
		_audio_event("error")
		return
	profile_character_id = character_id
	_audio_event("ui_click")
	_refresh()

func _upgrade_node_blocked_reason(node: Dictionary) -> String:
	var node_id: String = str(node.get("id", ""))
	if _purchased_upgrade_node_ids().has(node_id):
		return "已购"
	for prerequisite_value in node.get("prerequisites", []):
		if not _purchased_upgrade_node_ids().has(str(prerequisite_value)):
			var prerequisite: Dictionary = _upgrade_node_by_id(str(prerequisite_value))
			return "需要 %s" % str(prerequisite.get("name", prerequisite_value))
	if _progression_currency_amount() < int(node.get("cost", 0)):
		return "炉印不足"
	return ""

func _on_upgrade_node_pressed(node_id: String) -> void:
	var node: Dictionary = _upgrade_node_by_id(node_id)
	if node.is_empty() or not _upgrade_node_blocked_reason(node).is_empty():
		_audio_event("error")
		return
	var purchased: Array = _purchased_upgrade_node_ids()
	purchased.append(node_id)
	player_profile["purchased_upgrade_node_ids"] = purchased
	player_profile["forge_marks"] = _progression_currency_amount() - int(node.get("cost", 0))
	_save_player_profile()
	_audio_event("reward")
	_refresh()

func _on_skill_book_equipped(book_id: String) -> void:
	var book: Dictionary = _skill_book_by_id(book_id)
	if book.is_empty() or not _skill_book_unlocked(book):
		_audio_event("error")
		return
	var equipped_by_character: Dictionary = player_profile.get("equipped_skill_book_by_character", {}).duplicate(true)
	var target_character_id: String = profile_character_id if profile_open else selected_character_id
	equipped_by_character[target_character_id] = book_id
	player_profile["equipped_skill_book_by_character"] = equipped_by_character
	_save_player_profile()
	_audio_event("ui_click")
	_refresh()

func _unlocked_skill_book_count() -> int:
	var count := 0
	for book_value in progression_data.get("skill_books", []):
		var book: Dictionary = book_value
		if _skill_book_unlocked(book):
			count += 1
	return count

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
	last_compendium_tab_button_count = COMPENDIUM_TAB_ORDER.size() + 2
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
	last_compendium_filter_button_count = _compendium_filter_options(selected_compendium_tab).size()
	last_compendium_sort_button_count = _compendium_sort_options(selected_compendium_tab).size()
	last_compendium_search_control_count = 2
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
	_compendium_card_width()
	var compendium_page = CompendiumPageScript.new()
	compendium_page.configure({
		"selected_tab": selected_compendium_tab,
		"selected_filter": selected_compendium_filter,
		"selected_sort": selected_compendium_sort,
		"query": selected_compendium_search,
		"categories": COMPENDIUM_TAB_ORDER.duplicate(),
		"filters": _compendium_filter_options(selected_compendium_tab),
		"sorts": _compendium_sort_options(selected_compendium_tab),
		"items": _compendium_page_item_models(),
		"available_width": _layout_viewport_size().x,
		"available_height": _layout_viewport_size().y
	})
	compendium_page.tab_selected.connect(_on_compendium_tab_pressed)
	compendium_page.filter_selected.connect(_on_compendium_filter_pressed)
	compendium_page.sort_selected.connect(_on_compendium_sort_pressed)
	compendium_page.query_changed.connect(_on_compendium_search_changed)
	compendium_page.clear_query_requested.connect(_on_compendium_search_clear_pressed)
	compendium_page.close_requested.connect(_on_close_compendium_pressed)
	app_shell.mount_page(compendium_page, "compendium")
	_record_layout_metrics()

func _compendium_page_item_models() -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var item_index := 0
	for item_value in _filtered_sorted_compendium_items(selected_compendium_tab):
		var item: Dictionary = item_value
		var model := _compendium_page_item_model(item, item_index)
		models.append(model)
		last_compendium_item_count += 1
		last_compendium_item_titles.append(str(model.get("title", "")))
		last_compendium_item_subtitles.append(str(model.get("subtitle", "")))
		last_compendium_item_bodies.append(str(model.get("body", "")))
		last_compendium_item_tooltips.append(str(model.get("tooltip", "")))
		if not bool(model.get("discovered", false)):
			last_compendium_locked_item_count += 1
		item_index += 1
	return models

func _compendium_page_item_model(item: Dictionary, item_index: int) -> Dictionary:
	if not _compendium_item_revealed(selected_compendium_tab, item):
		return {
			"id": "locked_%d" % item_index,
			"kind": _compendium_page_kind(selected_compendium_tab),
			"discovered": false,
			"title": _compendium_locked_title(selected_compendium_tab),
			"subtitle": _compendium_locked_subtitle(selected_compendium_tab),
			"body": _compendium_locked_body(selected_compendium_tab),
			"tooltip": _compendium_locked_tooltip(selected_compendium_tab)
		}
	var model := {
		"id": str(item.get("id", "item_%d" % item_index)),
		"kind": _compendium_page_kind(selected_compendium_tab),
		"discovered": true
	}
	match selected_compendium_tab:
		"cards":
			model["title"] = "%s [%d]" % [str(item.get("name", "卡牌")), int(item.get("cost", 0))]
			model["subtitle"] = "%s · %s · %s · %s" % [_compendium_discovery_text("cards", item), _card_type_display_name(str(item.get("type", ""))), _rarity_display_name(str(item.get("rarity", ""))), _target_display_name(str(item.get("target", "")))]
			model["body"] = str(item.get("description", ""))
			model["tooltip"] = "%s\n%s" % [model["title"], model["body"]]
		"relics":
			model["title"] = str(item.get("name", "遗物"))
			model["subtitle"] = "%s · %s · %s" % [_compendium_discovery_text("relics", item), _rarity_display_name(str(item.get("rarity", ""))), _character_scope_text(item)]
			model["body"] = str(item.get("description", ""))
			model["tooltip"] = "%s\n%s" % [model["title"], model["body"]]
		"potions":
			model["title"] = str(item.get("name", "药水"))
			model["subtitle"] = "%s · %s · %s" % [_compendium_discovery_text("potions", item), _rarity_display_name(str(item.get("rarity", ""))), _target_display_name(str(item.get("target", "")))]
			model["body"] = str(item.get("description", ""))
			model["tooltip"] = "%s\n%s" % [model["title"], model["body"]]
		"enemies":
			model["title"] = str(item.get("name", "敌人"))
			model["subtitle"] = "%s · %s · %d HP · %d 行动" % [_compendium_discovery_text("enemies", item), _enemy_tier_display_name(str(item.get("tier", "normal"))), int(item.get("max_hp", 0)), item.get("actions", []).size()]
			model["body"] = _enemy_actions_summary(item)
			model["tooltip"] = "%s\n%s" % [model["title"], model["body"]]
		"events":
			model["title"] = str(item.get("name", "事件"))
			model["subtitle"] = "%s · %s · %d 选择" % [_compendium_discovery_text("events", item), _character_scope_text(item), item.get("choices", []).size()]
			model["body"] = str(item.get("body", ""))
			model["tooltip"] = "%s\n%s" % [model["title"], model["body"]]
		"challenges":
			var level := int(item.get("level", 0))
			model["title"] = str(item.get("name", "挑战"))
			model["subtitle"] = "%s · 等级 %d · %s" % [_compendium_discovery_text("challenges", item), level, str(item.get("short_name", ""))]
			model["body"] = _challenge_modifier_summary(level)
			model["tooltip"] = "%s\n%s" % [model["title"], model["body"]]
	return model

func _compendium_page_kind(tab_id: String) -> String:
	match tab_id:
		"relics", "potions":
			return "relic"
		"events", "challenges":
			return "event"
		_:
			return "card"

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
			_refresh_pc_menu_button_content(tutorial_button)
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
		_refresh_pc_menu_button_content(tutorial_button)

func _refresh_pc_menu_button_content(button: Button) -> void:
	if button == null or not _is_pc_character_menu_controls():
		return
	button.custom_minimum_size = Vector2(_pc_menu_control_button_width(button), 36)
	_apply_pc_menu_control_button_skin(button)
	_apply_pc_menu_control_button_content(button)

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
		"treasure":
			return {
				"title": "宝箱",
				"short": "无战斗获得一次构筑强化",
				"body": "宝箱会提供金币和一件遗物选择。优先选择能强化当前核心出牌节奏的遗物；金币可以为后续商店保留空间。"
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

func _record_boss_defeated(chapter_id: String) -> bool:
	var active_run_id: String = _active_playtest_run_id()
	var run_id: String = active_run_id if not active_run_id.is_empty() else last_terminal_run_id
	if run_id.is_empty() or chapter_id.is_empty():
		return false
	var receipt_id := "boss:%s:%s" % [run_id, chapter_id]
	if player_profile.get("reward_receipt_ids", []).has(receipt_id):
		return true
	if active_run_id.is_empty():
		return false
	var previous_profile: Dictionary = player_profile.duplicate(true)
	_increment_profile_stat("bosses_defeated", 1)
	_add_forge_marks(int(progression_data.get("currency", {}).get("boss_reward", 2)))
	_set_profile_stat_max("best_gold", run_gold)
	_set_profile_stat_max("highest_deck_size", run_deck_ids.size())
	_profile_append_unique("reward_receipt_ids", receipt_id)
	_refresh_achievement_unlocks("boss_defeated")
	if not _save_player_profile():
		player_profile = previous_profile
		return false
	return true

func _record_chapter_completed(chapter_id: String) -> bool:
	if player_profile.get("completed_chapters", []).has(chapter_id):
		return true
	var previous_profile: Dictionary = player_profile.duplicate(true)
	_profile_append_unique("completed_chapters", chapter_id)
	_refresh_achievement_unlocks("chapter_completed")
	if not _save_player_profile():
		player_profile = previous_profile
		return false
	return true

func _record_run_completed() -> bool:
	var active_run_id := _active_playtest_run_id()
	var run_id: String = active_run_id if not active_run_id.is_empty() else last_terminal_run_id
	if run_id.is_empty():
		return false
	var receipt_id := "completion:%s" % run_id
	if player_profile.get("reward_receipt_ids", []).has(receipt_id):
		return true
	if active_run_id.is_empty():
		return false
	var previous_profile: Dictionary = player_profile.duplicate(true)
	_increment_profile_stat("runs_completed", 1)
	_add_forge_marks(int(progression_data.get("currency", {}).get("full_run_bonus", 3)))
	_set_profile_stat_max("best_gold", run_gold)
	_set_profile_stat_max("highest_deck_size", run_deck_ids.size())
	_set_profile_stat_max("best_challenge_level_completed", current_challenge_level)
	_profile_append_unique("character_completions", selected_character_id)
	for chapter_id in completed_chapter_ids:
		_profile_append_unique("completed_chapters", str(chapter_id))
	_set_profile_stat_max("max_challenge_level_unlocked", _max_unlocked_challenge_level())
	_profile_append_unique("reward_receipt_ids", receipt_id)
	_refresh_achievement_unlocks("run_completed")
	if not _save_player_profile():
		player_profile = previous_profile
		return false
	return true

func _terminal_settlement_run_id() -> String:
	var active_run_id := _active_playtest_run_id()
	if not active_run_id.is_empty():
		return active_run_id
	return last_terminal_run_id

func _add_forge_marks(amount: int) -> void:
	if amount <= 0:
		return
	player_profile["forge_marks"] = _progression_currency_amount() + amount

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
	if combat.phase == "lost" and not deck_view_open and not profile_open and not settings_open and not compendium_open:
		_set_menu_shell_active(true)
	if combat.phase == "won" and _is_pc_layout() and not deck_view_open and not profile_open and not settings_open and not compendium_open:
		_set_menu_shell_active(true)
	_record_playtest_combat_terminal()
	if save_button != null:
		save_button.disabled = _run_save_blocked()
	var reward_visible: bool = combat.phase == "won" or combat.phase == "lost"
	if reward_visible:
		_close_pile_view(false)
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
	var legacy_reward_visible: bool = reward_visible and not (_is_pc_layout() and combat.phase == "won")
	_set_page_regions(true, board_visible, false, board_visible, board_visible, true, hand_visible, legacy_reward_visible)
	_apply_combat_layout_constraints(reward_visible)
	status_label.text = "回合 %d | 阶段：%s | 资源见 HUD，下方显示对手行动。" % [
		combat.turn,
		combat.phase
	]
	if status_label != null:
		status_label.visible = not (_is_pc_layout() and not reward_visible)
	_refresh_battle_background()
	_refresh_combat_hud()
	_refresh_potions()
	_refresh_enemies()
	_refresh_hand()
	_refresh_rewards()
	_refresh_log()
	_refresh_feedback()
	_apply_pc_combat_chrome(reward_visible)
	_record_combat_layout_metrics(reward_visible)
	end_turn_button.disabled = combat_presentation_busy or combat.phase != "player"

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
	var preserved_potion_row := potion_row if potion_row != null and potion_row.get_parent() == combat_hud_row else null
	if preserved_potion_row != null:
		combat_hud_row.remove_child(preserved_potion_row)
	var preserved_relic_belt := relic_belt_row if _is_pc_layout() and relic_belt_row != null else null
	if preserved_relic_belt != null and preserved_relic_belt.get_parent() != null:
		preserved_relic_belt.get_parent().remove_child(preserved_relic_belt)
	_clear_container(combat_hud_row)
	last_combat_hud_block_count = 0
	last_combat_hud_icon_node_count = 0
	var hp: int = int(combat.player.get("hp", 0))
	var max_hp: int = int(combat.player.get("max_hp", 0))
	var block: int = int(combat.player.get("block", 0))
	var energy: int = int(combat.player.get("energy", 0))
	var max_energy: int = int(combat.player.get("max_energy", 0))
	var momentum: int = int(combat.player.get("momentum", 0))
	var momentum_max: int = int(combat.player.get("momentum_max", 0))
	var entries: Array[Dictionary] = []
	if _is_pc_layout():
		entries.append_array([
			{"label": "生命", "value": "%d/%d" % [hp, max_hp], "skin": "danger"},
			{"label": "护甲", "value": "%d" % block, "skin": "primary"},
			{"label": "金币", "value": "%d" % run_gold, "skin": "relic"},
			{"label": "回合", "value": "%d · %s" % [combat.turn, _combat_phase_short_name()], "skin": "event"},
			{"label": "势能", "value": "%d/%d" % [momentum, momentum_max], "skin": "potion"}
		])
	else:
		entries.append_array([
			{"label": "生命", "value": "%d/%d" % [hp, max_hp], "skin": "danger"},
			{"label": "护甲", "value": "%d" % block, "skin": "primary"},
			{"label": "能量", "value": "%d/%d" % [energy, max_energy], "skin": "relic"},
			{"label": "势能", "value": "%d/%d" % [momentum, momentum_max], "skin": "potion"},
			{"label": "抽牌", "value": "%d" % combat.draw_pile.size(), "skin": "neutral"},
			{"label": "弃牌", "value": "%d" % combat.discard_pile.size(), "skin": "neutral"},
			{"label": "消耗", "value": "%d" % combat.exhaust_pile.size(), "skin": "event"}
		])
	var text_parts: Array[String] = []
	for entry in entries:
		var entry_dict: Dictionary = entry
		var label: String = str(entry_dict.get("label", ""))
		var value: String = str(entry_dict.get("value", ""))
		_add_hud_block(label, value, str(entry_dict.get("skin", "neutral")))
		text_parts.append("%s %s" % [label, value])
	if preserved_relic_belt != null:
		preserved_relic_belt.custom_minimum_size.y = 38
		preserved_relic_belt.visible = not run_relic_ids.is_empty()
		combat_hud_row.add_child(preserved_relic_belt)
	if preserved_potion_row != null:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(8, 1)
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		combat_hud_row.add_child(spacer)
		combat_hud_row.add_child(preserved_potion_row)
	last_combat_hud_text = " | ".join(text_parts)
	_refresh_player_stage_plate()
	_refresh_pc_hand_dock_hud()

func _refresh_player_stage_plate() -> void:
	last_player_stage_plate_visible = false
	last_player_stage_hp_text = ""
	last_player_stage_block_text = ""
	if player_stage_plate == null or combat == null:
		return
	var hp: int = int(combat.player.get("hp", 0))
	var max_hp: int = max(1, int(combat.player.get("max_hp", 1)))
	var block: int = int(combat.player.get("block", 0))
	var hp_ratio: float = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	if player_stage_hp_fill != null:
		player_stage_hp_fill.anchor_right = hp_ratio
		player_stage_hp_fill.color = Color(0.82, 0.18, 0.09, 0.96) if hp_ratio > 0.32 else Color(0.92, 0.07, 0.045, 0.98)
	last_player_stage_hp_text = "%d/%d" % [hp, max_hp]
	last_player_stage_block_text = str(block)
	if player_stage_hp_label != null:
		player_stage_hp_label.text = last_player_stage_hp_text
	if player_stage_block_label != null:
		player_stage_block_label.text = last_player_stage_block_text
	if player_stage_block_icon != null:
		player_stage_block_icon.modulate = Color(0.48, 0.90, 1.0, 0.96 if block > 0 else 0.34)
	player_stage_plate.tooltip_text = "生命 %s | 护甲 %d%s" % [
		last_player_stage_hp_text,
		block,
		_status_text(combat.player.get("statuses", {}))
	]
	last_player_stage_plate_visible = player_stage_plate.visible

func _create_hand_energy_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "HandEnergyPanel"
	panel.custom_minimum_size = Vector2(64, 74)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.tooltip_text = "当前能量 / 最大能量"
	panel.add_theme_stylebox_override("panel", _hand_dock_panel_style("relic", true))

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	center.add_child(box)

	var icon := TextureRect.new()
	icon.name = "HandEnergyIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(_hud_icon_path("能量"))
	icon.modulate = Color(1.0, 0.88, 0.42, 0.98)
	box.add_child(icon)

	hand_energy_value_label = Label.new()
	hand_energy_value_label.name = "HandEnergyValue"
	hand_energy_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_energy_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_energy_value_label.add_theme_font_size_override("font_size", 18)
	hand_energy_value_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
	box.add_child(hand_energy_value_label)
	return panel

func _create_hand_pile_button(kind: String, title: String, icon_path: String) -> Button:
	var button := Button.new()
	button.name = "HandPileButton_%s" % kind
	button.custom_minimum_size = Vector2(64, 56)
	button.text = ""
	button.clip_contents = true
	button.tooltip_text = "%s\n点击查看" % title
	button.add_theme_stylebox_override("normal", _hand_dock_button_style(false, false))
	button.add_theme_stylebox_override("hover", _hand_dock_button_style(true, false))
	button.add_theme_stylebox_override("pressed", _hand_dock_button_style(true, true))
	button.pressed.connect(_open_pile_view.bind(kind))

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	center.add_child(row)

	var icon := TextureRect.new()
	icon.name = "HandPileIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(icon_path)
	icon.modulate = Color(0.88, 0.92, 0.86, 0.96)
	row.add_child(icon)

	var count := Label.new()
	count.name = "HandPileCount"
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.text = "0"
	count.add_theme_font_size_override("font_size", 17)
	count.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	row.add_child(count)
	return button

func _refresh_pc_hand_dock_hud() -> void:
	var visible: bool = _is_pc_layout() and combat != null and combat.phase != "won" and combat.phase != "lost"
	if hand_left_hud != null:
		hand_left_hud.visible = visible
	if hand_right_hud != null:
		hand_right_hud.visible = visible
	last_hand_dock_control_count = 0
	if not visible:
		return
	if hand_energy_value_label != null:
		hand_energy_value_label.text = "%d/%d" % [int(combat.player.get("energy", 0)), int(combat.player.get("max_energy", 0))]
		last_hand_dock_control_count += 1
	_update_hand_pile_button(hand_draw_button, combat.draw_pile.size(), "抽牌堆")
	_update_hand_pile_button(hand_discard_button, combat.discard_pile.size(), "弃牌堆")
	_update_hand_pile_button(hand_exhaust_button, combat.exhaust_pile.size(), "消耗堆")

func _update_hand_pile_button(button: Button, count: int, title: String) -> void:
	if button == null:
		return
	var count_label := button.find_child("HandPileCount", true, false) as Label
	if count_label != null:
		count_label.text = str(count)
	button.tooltip_text = "%s：%d 张\n点击查看" % [title, count]
	last_hand_dock_control_count += 1

func _hand_dock_panel_style(skin: String, emphasized: bool = false) -> StyleBoxFlat:
	var palette: Dictionary = _button_skin_palette(skin)
	var bg: Color = palette.get("bg", Color(0.12, 0.13, 0.14)).darkened(0.22)
	var border: Color = palette.get("border", Color(0.64, 0.66, 0.62))
	var style := _button_style(Color(bg.r, bg.g, bg.b, 0.90), Color(border.r, border.g, border.b, 0.92), 2 if emphasized else 1, 8)
	style.shadow_color = Color(0, 0, 0, 0.54)
	style.shadow_size = 4
	return style

func _hand_dock_button_style(hovered: bool, pressed: bool) -> StyleBoxFlat:
	var bg := Color(0.055, 0.066, 0.070, 0.90)
	var border := Color(0.42, 0.50, 0.48, 0.84)
	if hovered:
		bg = Color(0.085, 0.10, 0.10, 0.96)
		border = Color(0.74, 0.82, 0.68, 0.96)
	if pressed:
		bg = bg.darkened(0.12)
	var style := _button_style(bg, border, 1, 8)
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 3
	return style

func _add_hud_block(label_text: String, value_text: String, skin: String) -> void:
	if _is_pc_layout():
		_add_pc_hud_block(label_text, value_text, skin)
		return
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_hud_block_width(), clamp(round((30.0 if _is_pc_layout() else 34.0) * _combat_layout_scale()), 28.0 if _is_pc_layout() else 22.0, 32.0 if _is_pc_layout() else 34.0))
	var palette: Dictionary = _button_skin_palette(skin)
	var panel_style := _button_style(
		palette.get("bg", Color(0.16, 0.17, 0.18)),
		palette.get("border", Color(0.46, 0.50, 0.52)),
		2,
		6
	)
	if _is_pc_layout():
		panel_style.content_margin_left = 6
		panel_style.content_margin_right = 6
		panel_style.content_margin_top = 2
		panel_style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", panel_style)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1 if _is_pc_layout() else 2)
	panel.add_child(box)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9 if _is_pc_layout() else 10)
	label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.74))
	box.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 12 if _is_pc_layout() else 14)
	value.add_theme_color_override("font_color", Color(0.96, 0.96, 0.90))
	box.add_child(value)
	combat_hud_row.add_child(panel)
	last_combat_hud_block_count += 1

func _add_pc_hud_block(label_text: String, value_text: String, skin: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_hud_block_width(), 34)
	panel.clip_contents = true
	panel.tooltip_text = _hud_block_tooltip(label_text, value_text)
	panel.add_theme_stylebox_override("panel", _pc_hud_panel_style(skin))
	combat_hud_row.add_child(panel)
	_add_generated_texture_background(panel, _hud_texture_path("resource_chip", UI_RESOURCE_CHIP_PATH), 0.20)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(24, 24)
	badge.add_theme_stylebox_override("panel", _pc_hud_badge_style(skin))
	row.add_child(badge)

	var icon := TextureRect.new()
	icon.name = "HudIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(_hud_icon_path(label_text))
	icon.modulate = Color(1.0, 0.96, 0.78, 0.96)
	badge.add_child(icon)
	if icon.texture != null:
		last_combat_hud_icon_node_count += 1

	var value := Label.new()
	value.name = "HudValue"
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", Color(0.98, 0.96, 0.86))
	row.add_child(value)

	if _hud_block_opens_pile(label_text):
		var hit_area := Button.new()
		hit_area.name = "PileHudHitArea_%s" % label_text
		hit_area.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit_area.text = ""
		hit_area.tooltip_text = _hud_block_tooltip(label_text, value_text)
		hit_area.focus_mode = Control.FOCUS_ALL
		hit_area.add_theme_stylebox_override("normal", _hud_hit_area_style(false, false))
		hit_area.add_theme_stylebox_override("hover", _hud_hit_area_style(true, false))
		hit_area.add_theme_stylebox_override("pressed", _hud_hit_area_style(true, true))
		hit_area.pressed.connect(_on_pile_hud_pressed.bind(label_text))
		panel.add_child(hit_area)
	last_combat_hud_block_count += 1

func _hud_icon_path(label_text: String) -> String:
	return str(HUD_ICON_PATHS.get(label_text, ""))

func _combat_phase_short_name() -> String:
	if combat == null:
		return ""
	match str(combat.phase):
		"player":
			return "玩家"
		"enemy":
			return "敌方"
		"won":
			return "胜利"
		"lost":
			return "战败"
	return str(combat.phase)

func _hud_block_opens_pile(label_text: String) -> bool:
	return ["抽牌", "弃牌", "消耗"].has(label_text)

func _hud_block_tooltip(label_text: String, value_text: String) -> String:
	if _hud_block_opens_pile(label_text):
		return "%s堆：%s 张\n点击查看牌堆内容" % [label_text, value_text]
	if label_text == "回合":
		return "当前回合与行动阶段"
	return "%s：%s" % [label_text, value_text]

func _hud_hit_area_style(hovered: bool, pressed: bool) -> StyleBoxFlat:
	var bg := Color(1.0, 0.78, 0.38, 0.0)
	var border := Color(1.0, 0.76, 0.32, 0.0)
	if hovered:
		bg.a = 0.07 if not pressed else 0.12
		border.a = 0.58 if not pressed else 0.78
	var style := _button_style(bg, border, 1, 8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _on_pile_hud_pressed(label_text: String) -> void:
	match label_text:
		"抽牌":
			_open_pile_view("draw")
		"弃牌":
			_open_pile_view("discard")
		"消耗":
			_open_pile_view("exhaust")

func _open_pile_view(kind: String) -> void:
	if combat == null or combat.phase == "won" or combat.phase == "lost":
		return
	pile_view_kind = _valid_pile_view_kind(kind)
	pile_view_open = true
	_refresh_pile_view()
	_audio_event("ui_click")

func _close_pile_view(play_audio: bool = true) -> void:
	pile_view_open = false
	pile_view_kind = ""
	last_pile_view_visible = false
	if pile_overlay != null:
		pile_overlay.visible = false
	if play_audio:
		_audio_event("ui_click")

func _on_close_pile_view_pressed() -> void:
	_close_pile_view()

func _valid_pile_view_kind(kind: String) -> String:
	if ["draw", "discard", "exhaust"].has(kind):
		return kind
	return "draw"

func _refresh_pile_view() -> void:
	if pile_overlay == null or pile_cards_flow == null or pile_tab_row == null:
		return
	if combat == null or not pile_view_open:
		_close_pile_view(false)
		return
	_sync_pile_overlay_layout()
	pile_view_kind = _valid_pile_view_kind(pile_view_kind)
	var cards: Array = _pile_cards_for_view(pile_view_kind)
	pile_overlay.visible = true
	last_pile_view_visible = true
	last_pile_view_kind = pile_view_kind
	last_pile_view_card_count = cards.size()
	last_pile_view_art_node_count = 0
	last_pile_view_tab_count = 0
	if pile_title_label != null:
		pile_title_label.text = "%s · %d 张" % [_pile_view_title(pile_view_kind), cards.size()]
	if pile_summary_label != null:
		pile_summary_label.text = _pile_view_summary(pile_view_kind, cards.size())
	_clear_container(pile_tab_row)
	for tab_kind in ["draw", "discard", "exhaust"]:
		_add_pile_tab_button(str(tab_kind))
	_clear_container(pile_cards_flow)
	if cards.is_empty():
		var empty_panel := PanelContainer.new()
		empty_panel.custom_minimum_size = Vector2(max(420.0, pile_panel.custom_minimum_size.x - 46.0), 130.0)
		empty_panel.add_theme_stylebox_override("panel", _button_style(Color(0.045, 0.052, 0.055, 0.82), Color(0.30, 0.36, 0.36, 0.70), 1, 7))
		pile_cards_flow.add_child(empty_panel)
		var empty_label := Label.new()
		empty_label.text = "%s当前为空" % _pile_view_title(pile_view_kind)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.66))
		empty_panel.add_child(empty_label)
		return
	for card_value in cards:
		var card: Dictionary = card_value
		var button := Button.new()
		button.custom_minimum_size = _pile_card_size()
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "%s [%d]\n%s\n%s" % [
			card.get("name", "卡牌"),
			int(card.get("cost", 0)),
			_card_type_display_name(str(card.get("type", ""))),
			card.get("description", "")
		]
		_apply_card_button_skin(button, str(card.get("type", "")))
		var art_path: String = _card_art_path(card)
		var art_texture: Texture2D = _load_texture(art_path)
		_add_structured_card_layout(button, card, art_texture, "pile_view")
		if art_texture != null:
			last_pile_view_art_node_count += 1
		pile_cards_flow.add_child(button)

func _add_pile_tab_button(kind: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(164, 36)
	button.text = "%s  %d" % [_pile_view_title(kind), _pile_cards(kind).size()]
	button.icon = _load_texture(_pile_view_icon_path(kind))
	button.expand_icon = true
	button.tooltip_text = "查看%s" % _pile_view_title(kind)
	button.disabled = kind == pile_view_kind
	_apply_button_skin(button, "primary" if kind == pile_view_kind else "neutral")
	button.pressed.connect(_open_pile_view.bind(kind))
	pile_tab_row.add_child(button)
	last_pile_view_tab_count += 1

func _pile_cards(kind: String) -> Array:
	if combat == null:
		return []
	match _valid_pile_view_kind(kind):
		"discard":
			return combat.discard_pile
		"exhaust":
			return combat.exhaust_pile
	return combat.draw_pile

func _pile_cards_for_view(kind: String) -> Array:
	var cards: Array = _pile_cards(kind).duplicate(true)
	cards.sort_custom(_sort_cards_by_display_name)
	return cards

func _sort_cards_by_display_name(a: Variant, b: Variant) -> bool:
	var card_a: Dictionary = a
	var card_b: Dictionary = b
	var name_a: String = str(card_a.get("name", card_a.get("id", "")))
	var name_b: String = str(card_b.get("name", card_b.get("id", "")))
	if name_a == name_b:
		return str(card_a.get("id", "")) < str(card_b.get("id", ""))
	return name_a < name_b

func _pile_view_title(kind: String) -> String:
	match _valid_pile_view_kind(kind):
		"discard":
			return "弃牌堆"
		"exhaust":
			return "消耗堆"
	return "抽牌堆"

func _pile_view_summary(kind: String, count: int) -> String:
	match _valid_pile_view_kind(kind):
		"draw":
			return "共 %d 张。抽牌顺序已随机化，此处按名称展示，不泄露下一张牌。" % count
		"discard":
			return "共 %d 张。抽牌堆耗尽时，这些牌会重新洗入抽牌堆。" % count
		"exhaust":
			return "共 %d 张。本场战斗中通常不会再次进入牌组循环。" % count
	return ""

func _pile_view_icon_path(kind: String) -> String:
	match _valid_pile_view_kind(kind):
		"discard":
			return _hud_icon_path("弃牌")
		"exhaust":
			return _hud_icon_path("消耗")
	return _hud_icon_path("抽牌")

func _pile_card_size() -> Vector2:
	if _is_pc_layout():
		return Vector2(166, 224)
	return Vector2(132, 184)

func _refresh_campfire(node: Dictionary) -> void:
	last_campfire_button_style_count = 0
	last_campfire_card_layout_count = 0
	last_campfire_card_art_node_count = 0
	last_campfire_art_path = ""
	last_campfire_art_loaded = false
	last_campfire_action_count = 0
	last_campfire_upgrade_candidate_count = 0
	last_campfire_reveal_animation_count = 0
	var use_campfire_page := _is_pc_layout()
	_set_page_regions(true, false, false, false, false, true, false, not use_campfire_page)
	_apply_reward_page_layout_constraints(156.0, 204.0)
	_apply_pc_story_room_chrome()
	status_label.text = "篝火：选择恢复生命或升级一张牌。升级后的牌会在名称后显示 +。"
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true
	if use_campfire_page:
		_mount_campfire_page(_campfire_page_model(node))
		_record_layout_metrics()
		return

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

func _campfire_page_model(node: Dictionary) -> Dictionary:
	last_campfire_art_path = _room_scene_art_path("campfire")
	last_campfire_art_loaded = _asset_loaded(last_campfire_art_path)
	var public_candidates: Array = []
	for candidate in _campfire_upgrade_candidates():
		var card: Dictionary = candidate.get("card", {})
		public_candidates.append({
			"deck_index": int(candidate.get("deck_index", -1)),
			"id": str(candidate.get("entry_id", "")),
			"name": str(card.get("name", candidate.get("entry_id", "卡牌"))),
			"description": _upgrade_preview_text(card),
			"art_path": _card_art_path(card)
		})
	var mode := "forge" if campfire_upgrade_selection_open else "arrival"
	last_campfire_action_count = 2 if mode == "arrival" else 1
	last_campfire_upgrade_candidate_count = public_candidates.size()
	last_campfire_card_layout_count = public_candidates.size() if mode == "forge" else 0
	last_campfire_card_art_node_count = last_campfire_card_layout_count
	last_campfire_button_style_count = last_campfire_action_count + last_campfire_card_layout_count
	last_campfire_reveal_animation_count = 1 + (last_campfire_action_count if mode == "arrival" else public_candidates.size())
	return {
		"mode": mode,
		"node": {"id": str(node.get("id", "")), "name": str(node.get("name", "废墟锻炉"))},
		"art_path": last_campfire_art_path,
		"hp": run_hp,
		"max_hp": run_max_hp,
		"heal_percent": _campfire_heal_percent(),
		"upgrade_candidates": public_candidates
	}

func _mount_campfire_page(model: Dictionary) -> void:
	var page = CampfirePageScript.new()
	page.configure(model)
	page.rest_requested.connect(_on_campfire_heal_pressed)
	page.forge_requested.connect(_on_campfire_forge_pressed)
	page.upgrade_card_requested.connect(_on_campfire_page_upgrade_requested)
	page.forge_back_requested.connect(_on_campfire_forge_back_pressed)
	page.leave.connect(_advance_to_next_node)
	app_shell.mount_page(page, "campfire")

func _on_campfire_page_upgrade_requested(deck_index: int) -> void:
	for candidate in _campfire_upgrade_candidates():
		if int(candidate.get("deck_index", -1)) == deck_index:
			_on_upgrade_card_pressed(deck_index)
			return
	push_warning("CampfirePage: invalid upgrade deck index %d" % deck_index)

func _campfire_upgrade_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for deck_index in range(run_deck_ids.size()):
		var entry_id: String = str(run_deck_ids[deck_index])
		if entry_id.ends_with("+"):
			continue
		var card: Dictionary = _card_by_id(entry_id)
		if card.is_empty() or not card.has("upgrade"):
			continue
		candidates.append({
			"deck_index": deck_index,
			"entry_id": entry_id,
			"card": card
		})
	return candidates

func _refresh_shop(node: Dictionary) -> void:
	last_shop_button_style_count = 0
	last_shop_card_layout_count = 0
	last_shop_card_art_node_count = 0
	last_shop_relic_layout_count = 0
	last_shop_relic_icon_node_count = 0
	last_shop_remove_candidate_count = 0
	last_shop_remove_card_layout_count = 0
	last_shop_remove_card_art_node_count = 0
	last_shop_potion_layout_count = 0
	last_shop_potion_icon_node_count = 0
	var use_shop_page := _is_pc_layout()
	_set_page_regions(true, false, false, false, false, true, false, not use_shop_page)
	_apply_reward_page_layout_constraints(150.0, 204.0)
	if shop_generated_for != current_node_index:
		shop_card_options = _generate_card_rewards(3, "shop_card")
		shop_relic_options = _generate_relic_rewards(2, "shop_relic")
		shop_potion_options = _generate_potion_rewards(2, "shop_potion")
		_record_playtest_card_offers(shop_card_options, "shop")
		var discovery_changed: bool = _record_discovered_item_array("cards", shop_card_options)
		discovery_changed = _record_discovered_item_array("relics", shop_relic_options) or discovery_changed
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
	end_turn_button.disabled = true

	if shop_remove_selection_open:
		if use_shop_page:
			_mount_shop_page(_shop_page_model("remove"))
		else:
			_refresh_shop_remove_selection()
		_record_layout_metrics()
		return
	if use_shop_page:
		_mount_shop_page(_shop_page_model("store"))
		_record_layout_metrics()
		return

	log_label.text = "商店库存：卡牌 %d | 遗物 %d | 药水 %d\n当前金币：%d | 删卡价格：%d | 本局已删：%d" % [
		shop_card_options.size(),
		shop_relic_options.size(),
		shop_potion_options.size(),
		run_gold,
		_remove_card_price(),
		run_shop_remove_count
	]

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

	for relic in shop_relic_options:
		var relic_dict: Dictionary = relic
		var relic_price: int = _relic_price(relic_dict)
		var relic_button := Button.new()
		relic_button.custom_minimum_size = _large_item_button_size()
		relic_button.text = ""
		relic_button.tooltip_text = "遗物 %s\n%d 金币\n%s" % [relic_dict.get("name", "遗物"), relic_price, relic_dict.get("description", "")]
		last_relic_icon_path = _relic_icon_path(relic_dict)
		last_relic_icon_loaded = _asset_loaded(last_relic_icon_path)
		var relic_texture: Texture2D = _load_texture(last_relic_icon_path)
		_apply_button_skin(relic_button, "relic", "shop")
		_add_icon_item_layout(
			relic_button,
			str(relic_dict.get("name", "遗物")),
			"%d 金币" % relic_price,
			str(relic_dict.get("description", "")),
			relic_texture,
			"relic",
			"shop_relic",
			false
		)
		relic_button.disabled = run_gold < relic_price or run_relic_ids.has(str(relic_dict.get("id", "")))
		relic_button.pressed.connect(_on_shop_buy_relic_pressed.bind(str(relic_dict.get("id", "")), relic_price))
		reward_row.add_child(relic_button)

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
	remove_button.text = "删卡\n%d 金币\n本局已删 %d 次\n选择一张牌" % [remove_price, run_shop_remove_count]
	_apply_button_skin(remove_button, "danger", "shop")
	remove_button.disabled = run_gold < remove_price or _shop_removable_card_indices().is_empty()
	remove_button.pressed.connect(_on_shop_remove_card_pressed)
	reward_row.add_child(remove_button)

	var leave_button := Button.new()
	leave_button.custom_minimum_size = Vector2(120, 104)
	leave_button.text = "离开商店"
	_apply_button_skin(leave_button, "neutral", "shop")
	leave_button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(leave_button)
	_record_layout_metrics()

func _shop_page_model(mode: String) -> Dictionary:
	var cards: Array = []
	for card_value in shop_card_options:
		var card: Dictionary = card_value
		var price := _card_price(card)
		cards.append({
			"id": str(card.get("id", "")),
			"name": str(card.get("name", "卡牌")),
			"price": price,
			"description": str(card.get("description", "")),
			"art_path": _card_art_path(card),
			"disabled_reason": "金币不足" if run_gold < price else ""
		})
	var relics: Array = []
	for relic_value in shop_relic_options:
		var relic: Dictionary = relic_value
		var price := _relic_price(relic)
		relics.append({
			"id": str(relic.get("id", "")),
			"name": str(relic.get("name", "遗物")),
			"price": price,
			"description": str(relic.get("description", "")),
			"art_path": _relic_icon_path(relic),
			"disabled_reason": "已拥有" if run_relic_ids.has(str(relic.get("id", ""))) else ("金币不足" if run_gold < price else "")
		})
	var potions: Array = []
	for potion_value in shop_potion_options:
		var potion: Dictionary = potion_value
		var price := _potion_price(potion)
		var disabled_reason := "药水槽已满" if not _has_empty_potion_slot() else ("金币不足" if run_gold < price else "")
		potions.append({
			"id": str(potion.get("id", "")),
			"name": str(potion.get("name", "药水")),
			"price": price,
			"description": str(potion.get("description", "")),
			"art_path": _potion_icon_path(potion),
			"slots_available": _has_empty_potion_slot(),
			"disabled_reason": disabled_reason
		})
	var remove_candidates: Array = []
	for deck_index in _shop_removable_card_indices():
		var entry := str(run_deck_ids[deck_index])
		var card := _deck_display_card(entry)
		remove_candidates.append({
			"deck_index": deck_index,
			"id": entry,
			"name": str(card.get("name", entry)),
			"description": str(card.get("description", "")),
			"art_path": _card_art_path(card)
		})
	var remove_reason := ""
	if run_gold < _remove_card_price():
		remove_reason = "金币不足"
	elif remove_candidates.is_empty():
		remove_reason = "没有可删卡牌"
	last_shop_card_layout_count = cards.size()
	last_shop_card_art_node_count = cards.size()
	last_shop_relic_layout_count = relics.size()
	last_shop_relic_icon_node_count = relics.size()
	last_shop_potion_layout_count = potions.size()
	last_shop_potion_icon_node_count = potions.size()
	last_shop_remove_candidate_count = remove_candidates.size()
	last_shop_remove_card_layout_count = remove_candidates.size()
	last_shop_remove_card_art_node_count = remove_candidates.size()
	last_shop_button_style_count = cards.size() + relics.size() + potions.size() + 2
	return {
		"mode": mode,
		"gold": run_gold,
		"remove_price": _remove_card_price(),
		"remove_disabled_reason": remove_reason,
		"cards": cards,
		"relics": relics,
		"potions": potions,
		"remove_candidates": remove_candidates
	}

func _mount_shop_page(model: Dictionary) -> void:
	var page = ShopExperienceScript.new()
	page.configure(model)
	page.buy_card.connect(_on_shop_page_buy_card)
	page.buy_relic.connect(_on_shop_page_buy_relic)
	page.buy_potion.connect(_on_shop_page_buy_potion)
	page.open_remove.connect(_on_shop_remove_card_pressed)
	page.remove_card.connect(_on_shop_page_remove_card_selected)
	page.cancel_remove.connect(_on_shop_remove_cancel_pressed)
	page.leave.connect(_advance_to_next_node)
	app_shell.mount_page(page, "shop")

func _shop_option_by_id(options: Array, item_id: String) -> Dictionary:
	for option_value in options:
		var option: Dictionary = option_value
		if str(option.get("id", "")) == item_id:
			return option
	return {}

func _on_shop_page_buy_card(item_id: String) -> void:
	var option := _shop_option_by_id(shop_card_options, item_id)
	if option.is_empty():
		push_warning("ShopExperience: unknown card id '%s'" % item_id)
		return
	_on_shop_buy_card_pressed(item_id, _card_price(option))

func _on_shop_page_buy_relic(item_id: String) -> void:
	var option := _shop_option_by_id(shop_relic_options, item_id)
	if option.is_empty():
		push_warning("ShopExperience: unknown relic id '%s'" % item_id)
		return
	_on_shop_buy_relic_pressed(item_id, _relic_price(option))

func _on_shop_page_buy_potion(item_id: String) -> void:
	var option := _shop_option_by_id(shop_potion_options, item_id)
	if option.is_empty():
		push_warning("ShopExperience: unknown potion id '%s'" % item_id)
		return
	_on_shop_buy_potion_pressed(item_id, _potion_price(option))

func _on_shop_page_remove_card_selected(deck_index: int) -> void:
	if not _shop_removable_card_indices().has(deck_index):
		push_warning("ShopExperience: invalid remove deck index %d" % deck_index)
		return
	_on_shop_remove_card_selected(deck_index)

func _refresh_shop_remove_selection() -> void:
	var remove_price: int = _remove_card_price()
	status_label.text = "商店删卡：选择一张要移除的牌。删卡会立刻扣除 %d 金币，并使本局下次删卡更贵。" % remove_price
	log_label.text = "当前金币：%d | 删卡价格：%d | 本局已删：%d\n选择具体卡牌后不可撤销。" % [
		run_gold,
		remove_price,
		run_shop_remove_count
	]

	var header := Label.new()
	header.text = "选择要移除的牌："
	header.custom_minimum_size = Vector2(150, 0)
	reward_row.add_child(header)

	var candidate_indices: Array[int] = _shop_removable_card_indices()
	last_shop_remove_candidate_count = candidate_indices.size()
	for deck_index in candidate_indices:
		var entry: String = str(run_deck_ids[deck_index])
		var card_dict: Dictionary = _deck_display_card(entry)
		if card_dict.is_empty():
			continue
		var button := Button.new()
		button.custom_minimum_size = _large_card_button_size()
		button.text = ""
		button.tooltip_text = "移除第 %d 张：%s\n花费 %d 金币\n%s" % [
			deck_index + 1,
			card_dict.get("name", "卡牌"),
			remove_price,
			card_dict.get("description", "")
		]
		last_reward_card_art_path = _card_art_path(card_dict)
		last_reward_card_art_loaded = _asset_loaded(last_reward_card_art_path)
		var card_texture: Texture2D = _load_texture(last_reward_card_art_path)
		_apply_card_button_skin(button, str(card_dict.get("type", "")), "shop_remove")
		_add_structured_card_layout(button, card_dict, card_texture, "shop_remove")
		button.disabled = run_gold < remove_price
		button.pressed.connect(_on_shop_remove_card_selected.bind(deck_index))
		reward_row.add_child(button)

	if candidate_indices.is_empty():
		var empty_label := Label.new()
		empty_label.text = "当前牌组没有可移除的牌。"
		empty_label.custom_minimum_size = Vector2(200, 0)
		reward_row.add_child(empty_label)

	var cancel_button := Button.new()
	cancel_button.custom_minimum_size = _small_action_button_size()
	cancel_button.text = "返回商店"
	_apply_button_skin(cancel_button, "neutral", "shop")
	cancel_button.pressed.connect(_on_shop_remove_cancel_pressed)
	reward_row.add_child(cancel_button)

func _refresh_event(node: Dictionary) -> void:
	last_event_choice_style_count = 0
	last_event_choice_layout_count = 0
	last_event_art_path = ""
	last_event_art_loaded = false
	last_event_panel_title = ""
	last_event_panel_body = ""
	last_event_panel_choice_count = 0
	last_event_reveal_animation_count = 0
	var use_event_page := _is_pc_layout()
	_set_page_regions(true, false, false, false, false, true, false, not use_event_page)
	_apply_reward_page_layout_constraints(132.0, 204.0)
	_apply_pc_story_room_chrome()
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

	var event_choices: Array = event.get("choices", [])
	if use_event_page:
		_mount_event_page(_event_page_model(event, node, event_choices))
		_record_layout_metrics()
		return

	_add_event_story_panel(event, node)
	for choice in event_choices:
		var choice_dict: Dictionary = choice
		var button := Button.new()
		button.custom_minimum_size = _event_choice_button_size(event_choices.size())
		var blocked_reason: String = _event_choice_blocked_reason(choice_dict)
		button.text = ""
		button.tooltip_text = _event_choice_button_text(choice_dict, blocked_reason)
		_apply_button_skin(button, "event", "event")
		button.disabled = not blocked_reason.is_empty()
		_add_event_choice_layout(button, choice_dict, blocked_reason, last_event_panel_choice_count)
		button.pressed.connect(_on_event_choice_pressed.bind(choice_dict))
		reward_row.add_child(button)
		last_event_panel_choice_count += 1

	if event_choices.is_empty():
		var continue_button := Button.new()
		continue_button.custom_minimum_size = Vector2(120, 104)
		continue_button.text = "继续"
		_apply_button_skin(continue_button, "primary", "event")
		continue_button.pressed.connect(_advance_to_next_node)
		reward_row.add_child(continue_button)
	_record_layout_metrics()

func _event_page_model(event: Dictionary, node: Dictionary, event_choices: Array) -> Dictionary:
	last_event_panel_title = str(event.get("name", node.get("name", "事件")))
	last_event_panel_body = str(event.get("body", "你遇到了一个未知事件。"))
	last_event_art_path = _event_art_path(event)
	last_event_art_loaded = _asset_loaded(last_event_art_path)
	var public_choices: Array = []
	for choice_value in event_choices:
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		var blocked_reason := _event_choice_blocked_reason(choice)
		public_choices.append({
			"id": str(choice.get("id", "")),
			"label": str(choice.get("label", "回应")),
			"description": str(choice.get("description", "")),
			"blocked_reason": blocked_reason,
			"disabled": not blocked_reason.is_empty()
		})
	last_event_panel_choice_count = public_choices.size()
	last_event_choice_style_count = public_choices.size()
	last_event_choice_layout_count = public_choices.size()
	last_event_reveal_animation_count = 1 + public_choices.size()
	return {
		"event": {
			"id": str(event.get("id", "")),
			"name": last_event_panel_title,
			"body": last_event_panel_body,
			"art_path": last_event_art_path
		},
		"node": {"id": str(node.get("id", "")), "name": str(node.get("name", "事件"))},
		"choices": public_choices
	}

func _mount_event_page(model: Dictionary) -> void:
	var page = EventPageScript.new()
	page.configure(model)
	page.choice_selected.connect(_on_event_page_choice_selected)
	page.continue_requested.connect(_advance_to_next_node)
	app_shell.mount_page(page, "event")

func _on_event_page_choice_selected(choice_id: String) -> void:
	var event: Dictionary = _event_by_id(str(_current_node().get("event_id", "")))
	for choice_value in event.get("choices", []):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		if str(choice.get("id", "")) == choice_id:
			_on_event_choice_pressed(choice)
			return
	push_warning("EventPage: unknown choice id '%s'" % choice_id)

func _add_event_choice_layout(button: Button, choice: Dictionary, blocked_reason: String, choice_index: int = -1) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 12
	margin.offset_top = 10
	margin.offset_right = -12
	margin.offset_bottom = -10
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(choice.get("label", "选择"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.97, 0.92, 0.82))
	box.add_child(title)

	var description := Label.new()
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.text = str(choice.get("description", ""))
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	description.add_theme_font_size_override("font_size", 11)
	description.add_theme_color_override("font_color", Color(0.86, 0.86, 0.82))
	box.add_child(description)

	var footer_text := ""
	var footer_color := Color(0.66, 0.82, 0.80)
	if not blocked_reason.is_empty():
		footer_text = "条件不足：%s" % blocked_reason
		footer_color = Color(0.95, 0.56, 0.48)
	elif choice.has("random_results"):
		footer_text = "结果随机"
	if not footer_text.is_empty():
		var footer := Label.new()
		footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer.text = footer_text
		footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		footer.add_theme_font_size_override("font_size", 10)
		footer.add_theme_color_override("font_color", footer_color)
		box.add_child(footer)
	last_event_choice_layout_count += 1

func _refresh_treasure(node: Dictionary) -> void:
	last_treasure_gold_reward = 0
	last_treasure_relic_layout_count = 0
	last_treasure_relic_icon_node_count = 0
	var use_reward_page: bool = _is_pc_layout()
	_set_page_regions(true, false, false, false, false, true, false, not use_reward_page)
	_apply_reward_page_layout_constraints(132.0, 204.0)
	var reward_key: String = "treasure:%s" % str(node.get("id", current_node_index))
	if reward_generated_for != reward_key:
		treasure_reward_gold = _treasure_gold_amount(str(node.get("id", "")))
		last_treasure_gold_reward = treasure_reward_gold
		relic_reward_options = _generate_relic_rewards(_treasure_relic_choice_count(), "treasure_relic")
		relic_reward_done = relic_reward_options.is_empty()
		card_reward_done = true
		potion_reward_done = true
		if _record_discovered_item_array("relics", relic_reward_options):
			_save_player_profile()
		reward_generated_for = reward_key
	else:
		last_treasure_gold_reward = treasure_reward_gold

	status_label.text = "宝箱：选择 1 件遗物，并在离开时获得 %d 金币。" % treasure_reward_gold
	feedback_label.visible = false
	_hide_cinematic_prompt()
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = "宝箱奖励：金币 %d；遗物 %d 选 1。\n选择遗物或领取金币后返回地图路线。" % [
		treasure_reward_gold,
		relic_reward_options.size()
	]
	end_turn_button.disabled = true
	if use_reward_page:
		_mount_reward_page(_treasure_reward_page_model())
		_record_layout_metrics()
		return

	_add_treasure_summary_panel(node)

	if not relic_reward_options.is_empty():
		for relic in relic_reward_options:
			var relic_dict: Dictionary = relic
			var relic_button := Button.new()
			relic_button.custom_minimum_size = _large_item_button_size()
			relic_button.text = ""
			relic_button.tooltip_text = "选择遗物：%s\n%s\n同时获得 %d 金币。" % [
				relic_dict.get("name", "遗物"),
				relic_dict.get("description", ""),
				treasure_reward_gold
			]
			last_relic_icon_path = _relic_icon_path(relic_dict)
			last_relic_icon_loaded = _asset_loaded(last_relic_icon_path)
			var relic_texture: Texture2D = _load_texture(last_relic_icon_path)
			_apply_button_skin(relic_button, "relic", "reward")
			_add_icon_item_layout(
				relic_button,
				str(relic_dict.get("name", "遗物")),
				"遗物 + %d 金币" % treasure_reward_gold,
				str(relic_dict.get("description", "")),
				relic_texture,
				"relic",
				"treasure_relic",
				false
			)
			relic_button.pressed.connect(_on_treasure_relic_pressed.bind(str(relic_dict.get("id", ""))))
			reward_row.add_child(relic_button)
	else:
		var empty_label := Label.new()
		empty_label.text = "本局可获得的遗物已耗尽，领取金币后继续。"
		empty_label.custom_minimum_size = Vector2(220, 0)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_row.add_child(empty_label)

	var continue_button := Button.new()
	continue_button.custom_minimum_size = _small_action_button_size()
	continue_button.text = "领取金币"
	_apply_button_skin(continue_button, "primary", "reward")
	continue_button.pressed.connect(_on_treasure_continue_pressed)
	reward_row.add_child(continue_button)
	_record_layout_metrics()

func _add_treasure_summary_panel(node: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(186, 154) if _is_pc_layout() else Vector2(160, 130)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _button_style(Color(0.14, 0.105, 0.07), Color(0.98, 0.78, 0.29), 2, 6))
	reward_row.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var title := Label.new()
	title.text = str(node.get("name", "宝箱"))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.91, 0.58))
	box.add_child(title)

	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(0, 66)
	icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(icon_center)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(58, 58)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture("res://assets/art/map_node_treasure.svg")
	icon_center.add_child(icon)

	var body := Label.new()
	body.text = "金币 +%d\n选择一件遗物带走" % treasure_reward_gold
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	box.add_child(body)

func _add_event_story_panel(event: Dictionary, node: Dictionary) -> void:
	var panel := PanelContainer.new()
	var panel_size: Vector2 = _event_story_panel_size()
	panel.custom_minimum_size = panel_size
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _event_story_panel_style())
	reward_row.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.clip_contents = true
	panel.add_child(row)

	var art_size: Vector2 = _event_story_art_size(panel_size.x)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = art_size
	art_frame.clip_contents = true
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
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.texture = _load_texture(last_event_art_path)
	art_frame.add_child(art)

	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(max(160.0, panel_size.x - art_size.x - 38.0), 0)
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
	body.custom_minimum_size = Vector2(0, max(74.0, panel_size.y - 48.0))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.clip_text = true
	body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	if _is_pc_layout():
		potion_row.alignment = BoxContainer.ALIGNMENT_END
		var pc_max_slots: int = _max_potion_slots()
		for i in range(pc_max_slots):
			var button := Button.new()
			button.custom_minimum_size = _potion_slot_button_size()
			_configure_button_bounds(button)
			button.clip_contents = true
			if i < run_potion_ids.size():
				var potion: Dictionary = _potion_by_id(str(run_potion_ids[i]))
				last_potion_icon_path = _potion_icon_path(potion)
				last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
				var potion_texture: Texture2D = _load_texture(last_potion_icon_path)
				button.text = ""
				button.tooltip_text = "%s\n%s" % [potion.get("name", run_potion_ids[i]), potion.get("description", "")]
				_apply_pc_potion_slot_skin(button, true)
				_add_pc_potion_slot_layout(button, potion_texture, true, i)
				button.disabled = combat_presentation_busy or combat == null or combat.phase != "player"
				button.pressed.connect(_on_potion_pressed.bind(i))
			else:
				last_potion_icon_path = _potion_fallback_icon_path()
				last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
				var empty_texture: Texture2D = _load_texture(last_potion_icon_path)
				button.text = ""
				button.tooltip_text = "空药水槽"
				_apply_pc_potion_slot_skin(button, false)
				_add_pc_potion_slot_layout(button, empty_texture, false, i)
				button.disabled = true
			potion_row.add_child(button)
		return

	potion_row.alignment = BoxContainer.ALIGNMENT_CENTER
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
			button.disabled = combat_presentation_busy or combat == null or combat.phase != "player"
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

func _apply_pc_potion_slot_skin(button: Button, occupied: bool) -> void:
	var normal := _pc_potion_slot_style(occupied, false)
	var hover := _pc_potion_slot_style(occupied, true)
	var pressed := _pc_potion_slot_style(occupied, false)
	pressed.bg_color = pressed.bg_color.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", _pc_potion_slot_style(occupied, false, true))

func _add_pc_potion_slot_layout(button: Button, icon_texture: Texture2D, occupied: bool, slot_index: int) -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 4
	root.offset_top = 3
	root.offset_right = -4
	root.offset_bottom = -3
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	if occupied and icon_texture != null:
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(27, 27)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = icon_texture
		center.add_child(icon)
	else:
		var socket := PanelContainer.new()
		socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		socket.custom_minimum_size = Vector2(26, 22)
		socket.add_theme_stylebox_override("panel", _pc_potion_empty_socket_style())
		center.add_child(socket)
		if icon_texture != null:
			var empty_icon := TextureRect.new()
			empty_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty_icon.custom_minimum_size = Vector2(18, 18)
			empty_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			empty_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			empty_icon.texture = icon_texture
			empty_icon.modulate = Color(0.62, 0.76, 0.74, 0.36)
			socket.add_child(empty_icon)

	var shortcut := Label.new()
	shortcut.name = "PotionShortcutLabel"
	shortcut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shortcut.text = str(slot_index + 1)
	shortcut.position = Vector2(2, 0)
	shortcut.add_theme_font_size_override("font_size", 9)
	shortcut.add_theme_color_override("font_color", Color(0.94, 0.88, 0.68, 0.88 if occupied else 0.42))
	button.add_child(shortcut)
	_record_icon_item_layout("potion_slot", icon_texture != null)

func _refresh_enemies() -> void:
	_clear_container(enemy_row)
	enemy_visuals_by_id.clear()
	last_boss_phase_badge_count = 0
	last_boss_phase_badge_texts.clear()
	last_boss_phase_threshold_marker_count = 0
	last_enemy_intent_badge_count = 0
	last_enemy_intent_badge_texts.clear()
	last_enemy_intent_badge_types.clear()
	last_enemy_stage_info_count = 0
	last_enemy_stage_info_texts.clear()
	last_stage_forecast_marker_count = 0
	last_stage_forecast_beam_count = 0
	last_stage_forecast_icon_count = 0
	for i in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[i]
		var enemy_id: String = str(enemy.get("id", ""))
		var panel_width: float = _enemy_panel_width()
		var panel_height: float = _enemy_panel_height()
		if _is_pc_layout():
			var pc_panel := Control.new()
			pc_panel.custom_minimum_size = Vector2(panel_width, panel_height)
			pc_panel.size = Vector2(panel_width, panel_height)
			pc_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			enemy_row.add_child(pc_panel)
			var pc_visual_entry: Dictionary = _add_pc_enemy_stage_layout(pc_panel, enemy, i, panel_width, panel_height)
			enemy_visuals_by_id["%s:%d" % [enemy_id, i]] = pc_visual_entry
			if not enemy_visuals_by_id.has(enemy_id):
				enemy_visuals_by_id[enemy_id] = pc_visual_entry
			continue

		var panel := VBoxContainer.new()
		panel.custom_minimum_size = Vector2(panel_width, panel_height)
		panel.add_theme_constant_override("separation", 4)
		if _is_pc_layout():
			panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		enemy_row.add_child(panel)

		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(panel_width, _enemy_art_height())
		art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = _enemy_texture(enemy)
		panel.add_child(art)

		var enemy_info_width: float = _pc_enemy_info_width(panel_width) if _is_pc_layout() else panel_width
		var intent_badge := _enemy_intent_badge(enemy, enemy_info_width)
		if _is_pc_layout():
			intent_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.add_child(intent_badge)

		var button := Button.new()
		button.custom_minimum_size = Vector2(enemy_info_width, _enemy_button_height())
		if _is_pc_layout():
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.disabled = int(enemy.get("hp", 0)) <= 0
		button.tooltip_text = _enemy_tooltip_text(enemy)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.clip_contents = true
		if _is_pc_layout():
			button.text = ""
			button.add_theme_stylebox_override("normal", _pc_enemy_plate_style(enemy, i == selected_enemy_index, false))
			button.add_theme_stylebox_override("hover", _pc_enemy_plate_style(enemy, true, false))
			button.add_theme_stylebox_override("pressed", _pc_enemy_plate_style(enemy, true, true))
			button.add_theme_stylebox_override("disabled", _pc_enemy_plate_style(enemy, false, false, true))
			_add_generated_texture_background(button, UI_ENEMY_PLATE_PATH, 0.18)
			_add_pc_enemy_plate_layout(button, enemy, i == selected_enemy_index)
		else:
			button.text = _enemy_button_text(enemy, i == selected_enemy_index)
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
	_queue_stage_forecast_refresh()

func _add_pc_enemy_stage_layout(panel: Control, enemy: Dictionary, enemy_index: int, panel_width: float, panel_height: float) -> Dictionary:
	var selected: bool = enemy_index == selected_enemy_index
	var hit_area := Button.new()
	hit_area.name = "EnemyHitArea"
	hit_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit_area.text = ""
	hit_area.tooltip_text = _enemy_tooltip_text(enemy)
	hit_area.disabled = int(enemy.get("hp", 0)) <= 0
	hit_area.focus_mode = Control.FOCUS_ALL
	hit_area.clip_contents = false
	hit_area.add_theme_stylebox_override("normal", _pc_enemy_stage_hit_style(enemy, selected, false))
	hit_area.add_theme_stylebox_override("hover", _pc_enemy_stage_hit_style(enemy, true, false))
	hit_area.add_theme_stylebox_override("pressed", _pc_enemy_stage_hit_style(enemy, true, true))
	hit_area.add_theme_stylebox_override("disabled", _pc_enemy_stage_hit_style(enemy, false, false, true))
	hit_area.pressed.connect(_on_enemy_pressed.bind(enemy_index))
	panel.add_child(hit_area)

	var hp_plate_height := 28.0
	var hp_plate_width: float = clamp(round(panel_width * 0.50), 126.0, 170.0)
	var hp_plate_y: float = panel_height - hp_plate_height - 8.0
	var art_y := 38.0
	if panel_height >= 330.0:
		art_y = 44.0
	var art_height: float = clamp(_enemy_art_height() + 18.0, 150.0, min(268.0, max(150.0, hp_plate_y - art_y + 18.0)))

	var foot_shadow := PanelContainer.new()
	foot_shadow.name = "EnemyFootShadow"
	foot_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot_shadow.custom_minimum_size = Vector2(clamp(panel_width * 0.58, 118.0, 204.0), 18.0)
	foot_shadow.size = foot_shadow.custom_minimum_size
	foot_shadow.position = Vector2((panel_width - foot_shadow.size.x) * 0.5, hp_plate_y - 15.0)
	foot_shadow.add_theme_stylebox_override("panel", _pc_enemy_foot_shadow_style(enemy, selected))
	panel.add_child(foot_shadow)

	var art := TextureRect.new()
	art.name = "EnemyStageArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(panel_width, art_height)
	art.size = art.custom_minimum_size
	art.position = Vector2(0.0, art_y)
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _enemy_texture(enemy)
	art.set_meta("enemy_index", enemy_index)
	var art_scale: float = _pc_enemy_stage_art_scale(enemy)
	if art_scale > 1.0:
		art.scale = Vector2(art_scale, art_scale)
		art.position = Vector2(
			(panel_width - panel_width * art_scale) * 0.5,
			art_y - (art_height * art_scale - art_height) * 0.44
		)
	panel.add_child(art)
	_start_enemy_idle_motion(art, enemy_index)

	var intent_width: float = clamp(round(panel_width * 0.32), 76.0, 98.0)
	var intent_badge := _enemy_intent_badge(enemy, intent_width)
	intent_badge.name = "EnemyStageIntentBadge"
	intent_badge.size = intent_badge.custom_minimum_size
	intent_badge.position = Vector2((panel_width - intent_badge.size.x) * 0.5, 2.0)
	panel.add_child(intent_badge)
	_add_pc_boss_phase_badge(panel, enemy, panel_width)

	var hp_plate := PanelContainer.new()
	hp_plate.name = "EnemyHpPlate"
	hp_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_plate.custom_minimum_size = Vector2(hp_plate_width, hp_plate_height)
	hp_plate.size = hp_plate.custom_minimum_size
	hp_plate.position = Vector2((panel_width - hp_plate_width) * 0.5, hp_plate_y)
	hp_plate.add_theme_stylebox_override("panel", _pc_enemy_health_plate_style(enemy, selected))
	panel.add_child(hp_plate)
	_add_pc_enemy_health_plate_layout(hp_plate, enemy, selected)

	var info_width: float = clamp(round(panel_width * 0.72), 158.0, 232.0)
	var info_strip := PanelContainer.new()
	info_strip.name = "EnemyInfoStrip"
	info_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_strip.custom_minimum_size = Vector2(info_width, 26.0)
	info_strip.size = info_strip.custom_minimum_size
	info_strip.position = Vector2((panel_width - info_width) * 0.5, hp_plate_y - 30.0)
	info_strip.add_theme_stylebox_override("panel", _button_style(Color(0.035, 0.038, 0.040, 0.88), Color(0.54, 0.48, 0.38, 0.76), 1, 5))
	panel.add_child(info_strip)
	_add_pc_enemy_info_strip_layout(info_strip, enemy, selected)

	return {
		"panel": panel,
		"art": art,
		"intent_badge": intent_badge,
		"button": hit_area
	}

func _add_pc_boss_phase_badge(panel: Control, enemy: Dictionary, panel_width: float) -> void:
	var data: Dictionary = enemy.get("data", {})
	var phases: Array = data.get("phases", [])
	if str(data.get("tier", "")) != "boss" or phases.is_empty():
		return
	var phase_index: int = int(enemy.get("phase_index", -1))
	var phase_ordinal: int = clampi(phase_index + 2, 1, phases.size() + 1)
	var badge_text := "阶段 %d/%d" % [phase_ordinal, phases.size() + 1]
	var profile_index: int = clampi(phase_index, 0, phases.size() - 1)
	var profile: Dictionary = _boss_phase_profile(str(enemy.get("id", "")), profile_index)
	var accent: Color = _vfx_profile_color(profile) if not profile.is_empty() else Color(1.0, 0.72, 0.30, 1.0)

	var badge := PanelContainer.new()
	badge.name = "BossPhaseBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(88, 24)
	badge.size = badge.custom_minimum_size
	badge.position = Vector2(max(4.0, panel_width - badge.size.x - 4.0), 4.0)
	badge.z_index = 8
	var style := _button_style(Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.94), Color(accent.r, accent.g, accent.b, 0.90), 1, 5)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	style.shadow_size = 4
	badge.add_theme_stylebox_override("panel", style)
	panel.add_child(badge)

	var label := Label.new()
	label.name = "BossPhaseBadgeLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = badge_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", accent.lightened(0.26))
	badge.add_child(label)
	last_boss_phase_badge_count += 1
	last_boss_phase_badge_texts.append(badge_text)

func _add_pc_enemy_info_strip_layout(info_strip: PanelContainer, enemy: Dictionary, selected: bool) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	info_strip.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)

	var name_label := Label.new()
	name_label.name = "EnemyNameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = "%s%s" % ["> " if selected else "", str(enemy.get("name", "敌人"))]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.76))
	row.add_child(name_label)

	var block: int = int(enemy.get("block", 0))
	var status_text: String = _status_text(enemy.get("statuses", {}))
	var state_label := Label.new()
	state_label.name = "EnemyStateLabel"
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_label.text = "盾%d · %s" % [block, status_text]
	state_label.custom_minimum_size = Vector2(74, 0)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state_label.clip_text = true
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_label.add_theme_font_size_override("font_size", 10)
	state_label.add_theme_color_override("font_color", Color(0.68, 0.86, 0.88) if block > 0 else Color(0.68, 0.70, 0.68))
	row.add_child(state_label)

	var telemetry_text := "%s | 护甲 %d | %s" % [str(enemy.get("name", "敌人")), block, status_text]
	last_enemy_stage_info_count += 1
	last_enemy_stage_info_texts.append(telemetry_text)

func _pc_enemy_stage_art_scale(enemy: Dictionary) -> float:
	var sprite_key: String = str(enemy.get("data", {}).get("sprite_key", ""))
	match sprite_key:
		"placeholder_ash_hound":
			return 1.16
		"placeholder_plague_alchemist":
			return 1.30
		"placeholder_bomb_mite":
			return 1.24
		"placeholder_twinblade_executor":
			return 1.55
		"placeholder_forge_bishop":
			return 1.28
		"placeholder_storm_archon":
			return 1.12
		"placeholder_nexus_heart":
			return 1.18
	return 1.0

func _start_enemy_idle_motion(art: TextureRect, enemy_index: int) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var active_tween: Tween
	if art.has_meta("idle_motion_tween"):
		active_tween = art.get_meta("idle_motion_tween") as Tween
	if active_tween != null and active_tween.is_valid():
		return
	var base_y: float = art.position.y
	var amplitude: float = 2.5 + float(enemy_index % 2)
	var duration: float = 1.65 + float(enemy_index) * 0.14
	var tween := create_tween().bind_node(art).set_loops()
	art.set_meta("idle_motion_tween", tween)
	tween.tween_property(art, "position:y", base_y - amplitude, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(art, "position:y", base_y + amplitude * 0.35, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _rebuild_stage_foreground_layer() -> void:
	if battle_foreground_layer == null:
		return
	_clear_container(battle_foreground_layer)
	last_stage_foreground_layer_count = 0
	_add_stage_foreground_rect(0.0, 0.0, 1.0, 0.0, 0.0, 2.0, Color(1.0, 0.52, 0.24, 0.34))
	_add_stage_foreground_rect(0.0, 1.0, 1.0, 1.0, 0.0, -58.0, Color(0.0, 0.0, 0.0, 0.20))
	_add_stage_foreground_rect(0.0, 1.0, 1.0, 1.0, 0.0, -28.0, Color(0.0, 0.0, 0.0, 0.26))
	_add_stage_foreground_rect(0.0, 0.0, 0.0, 1.0, 0.0, 0.0, Color(0.0, 0.0, 0.0, 0.16), Vector2(70, 0))
	_add_stage_foreground_rect(1.0, 0.0, 1.0, 1.0, -70.0, 0.0, Color(0.0, 0.0, 0.0, 0.13), Vector2(70, 0))

func _add_stage_foreground_rect(anchor_left: float, anchor_top: float, anchor_right: float, anchor_bottom: float, offset_x: float, offset_y: float, color: Color, fixed_size: Vector2 = Vector2.ZERO) -> void:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = color
	rect.anchor_left = anchor_left
	rect.anchor_top = anchor_top
	rect.anchor_right = anchor_right
	rect.anchor_bottom = anchor_bottom
	rect.offset_left = offset_x
	rect.offset_top = offset_y
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	if fixed_size.x > 0.0:
		rect.offset_right = offset_x + fixed_size.x
	if fixed_size.y > 0.0:
		rect.offset_bottom = offset_y + fixed_size.y
	battle_foreground_layer.add_child(rect)
	last_stage_foreground_layer_count += 1

func _queue_stage_forecast_refresh() -> void:
	if battle_forecast_layer == null:
		return
	if not _is_pc_layout() or combat == null or combat.phase == "won" or combat.phase == "lost":
		_clear_container(battle_forecast_layer)
		last_stage_forecast_marker_count = 0
		last_stage_forecast_beam_count = 0
		last_stage_forecast_icon_count = 0
		return
	for enemy in combat.enemies:
		var enemy_dict: Dictionary = enemy
		if int(enemy_dict.get("hp", 0)) <= 0:
			continue
		last_stage_forecast_marker_count += 1
		var intent: Dictionary = enemy_dict.get("current_action", {}).get("intent", {})
		if _intent_projects_to_player(str(intent.get("type", ""))):
			last_stage_forecast_beam_count += 1
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		if not stage_forecast_refresh_pending:
			stage_forecast_refresh_pending = true
			call_deferred("_refresh_stage_forecast_layer")

func _refresh_stage_forecast_layer() -> void:
	stage_forecast_refresh_pending = false
	if battle_forecast_layer == null or not is_instance_valid(battle_forecast_layer) or not is_inside_tree():
		return
	_clear_container(battle_forecast_layer)
	last_stage_forecast_marker_count = 0
	last_stage_forecast_beam_count = 0
	last_stage_forecast_icon_count = 0
	if not _is_pc_layout() or combat == null or combat.phase == "won" or combat.phase == "lost":
		return
	var player_control: Control = _player_combat_target_control()
	if player_control != null and is_instance_valid(player_control):
		var player_rect: Rect2 = _control_rect_in_layer(player_control, battle_forecast_layer)
		var player_floor: Vector2 = Vector2(player_rect.position.x + player_rect.size.x * 0.50, player_rect.end.y - 18.0)
		_add_stage_floor_marker(player_floor, Vector2(clamp(player_rect.size.x * 0.55, 148.0, 236.0), 30.0), "player", false)
	for i in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[i]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var visual: Dictionary = _enemy_visual_for_index(i)
		var art_value: Variant = visual.get("art", null)
		if not is_instance_valid(art_value):
			continue
		var art: Control = art_value as Control
		if art == null:
			continue
		var intent: Dictionary = enemy.get("current_action", {}).get("intent", {})
		var intent_type: String = str(intent.get("type", "none"))
		var enemy_rect: Rect2 = _control_rect_in_layer(art, battle_forecast_layer)
		var enemy_floor: Vector2 = Vector2(enemy_rect.position.x + enemy_rect.size.x * 0.5, enemy_rect.end.y - 10.0)
		var selected: bool = i == selected_enemy_index
		_add_stage_floor_marker(enemy_floor, Vector2(clamp(enemy_rect.size.x * 0.64, 120.0, 210.0), 26.0), intent_type, selected)
		_add_stage_intent_marker(Vector2(enemy_rect.position.x + enemy_rect.size.x * 0.50, enemy_rect.position.y + 22.0), intent_type, intent)
		if selected:
			_add_stage_selection_reticle(enemy_rect, intent_type)
		if _intent_projects_to_player(intent_type) and player_control != null:
			var enemy_center: Vector2 = Vector2(enemy_rect.position.x + enemy_rect.size.x * 0.5, enemy_rect.position.y + enemy_rect.size.y * 0.48)
			var player_center: Vector2 = _control_center_in_layer(player_control, battle_forecast_layer) + Vector2(58.0, 4.0)
			_add_stage_beam(enemy_center, player_center, intent_type)

func _intent_projects_to_player(intent_type: String) -> bool:
	return ["attack", "attack_debuff", "attack_block", "attack_buff", "attack_status_card", "debuff", "status_card"].has(intent_type)

func _add_stage_floor_marker(center: Vector2, size: Vector2, intent_type: String, selected: bool) -> void:
	if battle_forecast_layer == null:
		return
	var marker := PanelContainer.new()
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.custom_minimum_size = size
	marker.size = size
	marker.position = center - size * 0.5
	marker.add_theme_stylebox_override("panel", _stage_floor_marker_style(intent_type, selected))
	battle_forecast_layer.add_child(marker)
	last_stage_forecast_marker_count += 1

func _add_stage_intent_marker(center: Vector2, intent_type: String, intent: Dictionary) -> void:
	if battle_forecast_layer == null:
		return
	var marker := PanelContainer.new()
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.custom_minimum_size = Vector2(42, 42)
	marker.size = marker.custom_minimum_size
	marker.position = center - marker.size * 0.5
	marker.add_theme_stylebox_override("panel", _stage_intent_marker_style(intent_type))
	marker.tooltip_text = _intent_text(intent)
	battle_forecast_layer.add_child(marker)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(_intent_icon_path(intent_type))
	icon.modulate = _intent_badge_font_color(intent_type)
	marker.add_child(icon)
	if icon.texture != null:
		last_stage_forecast_icon_count += 1

func _add_stage_selection_reticle(enemy_rect: Rect2, intent_type: String) -> void:
	if battle_forecast_layer == null:
		return
	var size: Vector2 = Vector2(clamp(enemy_rect.size.x * 0.74, 122.0, 230.0), clamp(enemy_rect.size.y * 0.76, 142.0, 224.0))
	var reticle := Control.new()
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.custom_minimum_size = size
	reticle.size = size
	reticle.position = Vector2(enemy_rect.position.x + enemy_rect.size.x * 0.5, enemy_rect.position.y + enemy_rect.size.y * 0.50) - size * 0.5
	battle_forecast_layer.add_child(reticle)
	var color: Color = _stage_forecast_color(intent_type)
	var line_length: float = clamp(min(size.x, size.y) * 0.15, 18.0, 28.0)
	var thickness := 2.0
	var lines: Array[Rect2] = [
		Rect2(Vector2(0, 0), Vector2(line_length, thickness)),
		Rect2(Vector2(0, 0), Vector2(thickness, line_length)),
		Rect2(Vector2(size.x - line_length, 0), Vector2(line_length, thickness)),
		Rect2(Vector2(size.x - thickness, 0), Vector2(thickness, line_length)),
		Rect2(Vector2(0, size.y - thickness), Vector2(line_length, thickness)),
		Rect2(Vector2(0, size.y - line_length), Vector2(thickness, line_length)),
		Rect2(Vector2(size.x - line_length, size.y - thickness), Vector2(line_length, thickness)),
		Rect2(Vector2(size.x - thickness, size.y - line_length), Vector2(thickness, line_length))
	]
	for line_rect in lines:
		var line := ColorRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position = line_rect.position
		line.size = line_rect.size
		line.color = Color(color.r, color.g, color.b, 0.82)
		reticle.add_child(line)

func _add_stage_beam(start: Vector2, end: Vector2, intent_type: String) -> void:
	if battle_forecast_layer == null:
		return
	var delta: Vector2 = end - start
	var length: float = max(delta.length(), 1.0)
	for pass_index in range(2):
		var beam := ColorRect.new()
		beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		beam.color = _stage_forecast_color(intent_type)
		beam.size = Vector2(length, 12.0 if pass_index == 0 else 4.0)
		beam.pivot_offset = Vector2(0, beam.size.y * 0.5)
		beam.position = start - Vector2(0, beam.size.y * 0.5)
		beam.rotation = delta.angle()
		beam.modulate = Color(1, 1, 1, 0.18 if pass_index == 0 else 0.50)
		battle_forecast_layer.add_child(beam)
	last_stage_forecast_beam_count += 1

func _stage_floor_marker_style(intent_type: String, selected: bool) -> StyleBoxFlat:
	var color: Color = _stage_forecast_color(intent_type)
	var bg_alpha: float = 0.16 if intent_type == "player" else 0.20
	var border_alpha: float = 0.56 if selected else 0.36
	var style: StyleBoxFlat = _button_style(Color(color.r, color.g, color.b, bg_alpha), Color(color.r, color.g, color.b, border_alpha), 2 if selected else 1, 18)
	style.shadow_color = Color(color.r, color.g, color.b, 0.28 if selected else 0.12)
	style.shadow_size = 5 if selected else 2
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _stage_intent_marker_style(intent_type: String) -> StyleBoxFlat:
	var color: Color = _stage_forecast_color(intent_type)
	var style: StyleBoxFlat = _button_style(Color(0.015, 0.017, 0.020, 0.62), Color(color.r, color.g, color.b, 0.68), 1, 21)
	style.shadow_color = Color(color.r, color.g, color.b, 0.26)
	style.shadow_size = 4
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _stage_selection_reticle_style(intent_type: String) -> StyleBoxFlat:
	var color: Color = _stage_forecast_color(intent_type)
	var style: StyleBoxFlat = _button_style(Color(color.r, color.g, color.b, 0.035), Color(color.r, color.g, color.b, 0.62), 2, 10)
	style.shadow_color = Color(color.r, color.g, color.b, 0.18)
	style.shadow_size = 4
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _stage_forecast_color(intent_type: String) -> Color:
	match intent_type:
		"attack", "attack_debuff", "attack_block", "attack_buff", "attack_status_card":
			return Color(1.0, 0.30, 0.18, 1.0)
		"block", "block_buff":
			return Color(0.42, 0.90, 0.72, 1.0)
		"debuff", "status_card":
			return Color(0.82, 0.52, 1.0, 1.0)
		"buff":
			return Color(1.0, 0.74, 0.30, 1.0)
		"player":
			return Color(0.36, 0.88, 1.0, 1.0)
	return Color(0.76, 0.82, 0.86, 1.0)

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

func _add_pc_enemy_plate_layout(button: Button, enemy: Dictionary, selected: bool) -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 8
	root.offset_top = 5
	root.offset_right = -8
	root.offset_bottom = -5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	root.add_child(box)

	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 6)
	box.add_child(top_row)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = "%s%s" % ["> " if selected else "", str(enemy.get("name", "敌人"))]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.84))
	top_row.add_child(name_label)

	var hp_text := "%d/%d" % [int(enemy.get("hp", 0)), int(enemy.get("max_hp", 0))]
	var hp_label := Label.new()
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_label.text = hp_text
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label.custom_minimum_size = Vector2(58, 0)
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.72))
	top_row.add_child(hp_label)

	var hp_bar := Control.new()
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.custom_minimum_size = Vector2(0, 7)
	hp_bar.clip_contents = true
	box.add_child(hp_bar)

	var bar_bg := ColorRect.new()
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.color = Color(0.045, 0.035, 0.035, 0.92)
	hp_bar.add_child(bar_bg)

	var max_hp: int = max(1, int(enemy.get("max_hp", 1)))
	var hp_ratio: float = clamp(float(int(enemy.get("hp", 0))) / float(max_hp), 0.0, 1.0)
	var bar_fill := ColorRect.new()
	bar_fill.anchor_left = 0.0
	bar_fill.anchor_top = 0.0
	bar_fill.anchor_right = hp_ratio
	bar_fill.anchor_bottom = 1.0
	bar_fill.offset_left = 0.0
	bar_fill.offset_top = 0.0
	bar_fill.offset_right = 0.0
	bar_fill.offset_bottom = 0.0
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_fill.color = Color(0.78, 0.16, 0.12, 0.94)
	hp_bar.add_child(bar_fill)

	var status_line := Label.new()
	status_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_line.text = "护甲 %d%s" % [int(enemy.get("block", 0)), _pc_enemy_status_suffix(enemy)]
	status_line.clip_text = true
	status_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_line.add_theme_font_size_override("font_size", 10)
	status_line.add_theme_color_override("font_color", Color(0.72, 0.76, 0.72))
	box.add_child(status_line)

func _add_pc_enemy_health_plate_layout(hp_plate: PanelContainer, enemy: Dictionary, selected: bool) -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("margin_left", 5)
	root.add_theme_constant_override("margin_right", 5)
	root.add_theme_constant_override("margin_top", 4)
	root.add_theme_constant_override("margin_bottom", 4)
	hp_plate.add_child(root)

	var hp_bar := Control.new()
	hp_bar.name = "EnemyHpBar"
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.custom_minimum_size = Vector2(0, 14)
	hp_bar.clip_contents = true
	root.add_child(hp_bar)

	var bar_bg := ColorRect.new()
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.color = Color(0.045, 0.030, 0.026, 0.96)
	hp_bar.add_child(bar_bg)

	var max_hp: int = max(1, int(enemy.get("max_hp", 1)))
	var hp_ratio: float = clamp(float(int(enemy.get("hp", 0))) / float(max_hp), 0.0, 1.0)
	var bar_fill := ColorRect.new()
	bar_fill.anchor_left = 0.0
	bar_fill.anchor_top = 0.0
	bar_fill.anchor_right = hp_ratio
	bar_fill.anchor_bottom = 1.0
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_fill.color = Color(0.72, 0.045, 0.035, 0.96)
	hp_bar.add_child(bar_fill)

	var bar_glint := ColorRect.new()
	bar_glint.anchor_left = 0.0
	bar_glint.anchor_top = 0.0
	bar_glint.anchor_right = hp_ratio
	bar_glint.anchor_bottom = 0.0
	bar_glint.offset_bottom = 2.0
	bar_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_glint.color = Color(1.0, 0.42, 0.30, 0.42)
	hp_bar.add_child(bar_glint)

	var enemy_data: Dictionary = enemy.get("data", {})
	var phases: Array = enemy_data.get("phases", []) if str(enemy_data.get("tier", "")) == "boss" else []
	for phase_marker_index in range(phases.size()):
		var phase_data: Dictionary = phases[phase_marker_index]
		var threshold_ratio: float = _boss_phase_threshold_ratio(enemy, phase_data)
		if threshold_ratio < 0.0:
			continue
		var marker := ColorRect.new()
		marker.name = "BossPhaseThreshold_%d" % phase_marker_index
		marker.anchor_left = threshold_ratio
		marker.anchor_top = 0.0
		marker.anchor_right = threshold_ratio
		marker.anchor_bottom = 1.0
		marker.offset_left = -1.0
		marker.offset_right = 1.0
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.color = Color(1.0, 0.82, 0.42, 0.94)
		marker.z_index = 2
		hp_bar.add_child(marker)
		last_boss_phase_threshold_marker_count += 1

	var hp_label := Label.new()
	hp_label.name = "EnemyHpValue"
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_label.text = "%d/%d" % [int(enemy.get("hp", 0)), int(enemy.get("max_hp", 0))]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.clip_text = true
	hp_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.76))
	hp_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	hp_label.add_theme_constant_override("shadow_offset_x", 1)
	hp_label.add_theme_constant_override("shadow_offset_y", 1)
	hp_label.z_index = 3
	hp_bar.add_child(hp_label)

func _boss_phase_threshold_ratio(enemy: Dictionary, phase_data: Dictionary) -> float:
	if phase_data.has("hp_percent_below"):
		return clamp(float(phase_data.get("hp_percent_below", 0)) / 100.0, 0.0, 1.0)
	if phase_data.has("hp_below"):
		var max_hp: int = max(1, int(enemy.get("max_hp", 1)))
		return clamp(float(int(phase_data.get("hp_below", 0))) / float(max_hp), 0.0, 1.0)
	return -1.0

func _pc_enemy_status_suffix(enemy: Dictionary) -> String:
	var status_text: String = _status_text(enemy.get("statuses", {}))
	if status_text.is_empty():
		return ""
	return "  %s" % status_text

func _enemy_tooltip_text(enemy: Dictionary) -> String:
	var data: Dictionary = enemy.get("data", {})
	var lines: Array[String] = [str(enemy.get("name", "敌人"))]
	var phases: Array = data.get("phases", [])
	if str(data.get("tier", "")) == "boss" and not phases.is_empty():
		var phase_index: int = int(enemy.get("phase_index", -1))
		var phase_ordinal: int = clampi(phase_index + 2, 1, phases.size() + 1)
		var phase_name: String = str(enemy.get("phase_name", "初始阶段"))
		if phase_name.is_empty():
			phase_name = "初始阶段"
		lines.append("当前阶段：%s（%d/%d）" % [phase_name, phase_ordinal, phases.size() + 1])
		var next_phase_index: int = phase_index + 1
		if next_phase_index >= 0 and next_phase_index < phases.size():
			var next_phase: Dictionary = phases[next_phase_index]
			var threshold_text := "%d%%" % int(next_phase.get("hp_percent_below", 0))
			if next_phase.has("hp_below"):
				threshold_text = "%d HP" % int(next_phase.get("hp_below", 0))
			lines.append("下一阶段：%s（生命 <= %s）" % [str(next_phase.get("name", "阶段变更")), threshold_text])
			var phase_note: String = str(next_phase.get("phase_note", ""))
			if not phase_note.is_empty():
				lines.append(phase_note)
		else:
			lines.append("下一阶段：无（最终阶段）")
	lines.append("类型：%s" % str(data.get("tier", "normal")))
	var intent_note: String = str(data.get("intent_note", ""))
	if not intent_note.is_empty():
		lines.append(intent_note)
	return "\n".join(lines)

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
		"attack_block":
			return "攻击 %d x%d，并获得 %d 护甲" % [int(intent.get("amount", 0)), int(intent.get("hits", 1)), int(intent.get("block", 0))]
		"attack_buff":
			return "攻击 %d x%d，并强化 %s x%d" % [int(intent.get("amount", 0)), int(intent.get("hits", 1)), intent.get("status", ""), int(intent.get("status_amount", 1))]
		"attack_status_card":
			var status_id: String = str(intent.get("status", ""))
			if not status_id.is_empty():
				return "攻击 %d x%d，并施加 %s x%d，并加入 %d 张 %s" % [int(intent.get("amount", 0)), int(intent.get("hits", 1)), status_id, int(intent.get("status_amount", 1)), int(intent.get("card_amount", 1)), intent.get("card_id", "")]
			return "攻击 %d x%d，并加入 %d 张 %s" % [int(intent.get("amount", 0)), int(intent.get("hits", 1)), int(intent.get("card_amount", 1)), intent.get("card_id", "")]
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
	if _is_pc_layout():
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 7)
		margin.add_theme_constant_override("margin_right", 7)
		margin.add_theme_constant_override("margin_top", 3)
		margin.add_theme_constant_override("margin_bottom", 3)
		badge.add_child(margin)

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 4)
		margin.add_child(row)

		var icon := TextureRect.new()
		icon.name = "IntentIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _load_texture(_intent_icon_path(intent_type))
		icon.modulate = _intent_badge_font_color(intent_type)
		row.add_child(icon)
		if icon.texture != null:
			last_stage_forecast_icon_count += 1

		var label := Label.new()
		label.name = "IntentLabel"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = _intent_compact_text(intent)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", _intent_badge_font_color(intent_type))
		row.add_child(label)
	else:
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

func _intent_icon_path(intent_type: String) -> String:
	return str(INTENT_ICON_PATHS.get(intent_type, "res://assets/art/generated/ui/icons/intent_buff.svg"))

func _intent_compact_text(intent: Dictionary) -> String:
	var intent_type: String = str(intent.get("type", "none"))
	match intent_type:
		"attack":
			return "%d x%d" % [int(intent.get("amount", 0)), int(intent.get("hits", 1))]
		"attack_debuff":
			return "%d+" % int(intent.get("amount", 0))
		"attack_block":
			return "%d+盾%d" % [int(intent.get("amount", 0)) * int(intent.get("hits", 1)), int(intent.get("block", 0))]
		"attack_buff":
			return "%d+强%d" % [int(intent.get("amount", 0)) * int(intent.get("hits", 1)), int(intent.get("status_amount", 1))]
		"attack_status_card":
			var status_id: String = str(intent.get("status", ""))
			if not status_id.is_empty():
				return "%d+%s%d+伤%d" % [int(intent.get("amount", 0)) * int(intent.get("hits", 1)), _intent_status_compact_label(status_id), int(intent.get("status_amount", 1)), int(intent.get("card_amount", 1))]
			return "%d+伤%d" % [int(intent.get("amount", 0)) * int(intent.get("hits", 1)), int(intent.get("card_amount", 1))]
		"block":
			return "+%d" % int(intent.get("amount", 0))
		"block_buff":
			return "+%d" % int(intent.get("amount", 0))
		"debuff":
			return "x%d" % int(intent.get("amount", 0))
		"status_card":
			return "+"
		"buff":
			return "x%d" % int(intent.get("amount", 0))
	return _intent_text(intent)

func _intent_status_compact_label(status_id: String) -> String:
	match status_id:
		"vulnerable":
			return "易"
		"weak":
			return "弱"
		"frail":
			return "脆"
		"strength":
			return "强"
	return "状"

func _intent_badge_label(intent: Dictionary) -> String:
	var intent_type: String = str(intent.get("type", "none"))
	var category := "意图"
	match intent_type:
		"attack":
			category = "攻击"
		"attack_debuff":
			category = "攻击/减益"
		"attack_block":
			category = "攻击/护甲"
		"attack_buff":
			category = "攻击/强化"
		"attack_status_card":
			category = "攻击/干扰"
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
		"attack_debuff", "attack_block", "attack_buff", "attack_status_card":
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
	_hide_card_detail_preview()
	_clear_container(hand_row)
	hand_buttons_by_index.clear()
	last_hand_card_layout_count = 0
	last_hand_card_art_node_count = 0
	last_hand_card_material_frame_count = 0
	last_hand_card_cost_texts.clear()
	last_hand_card_type_texts.clear()
	last_hand_card_name_texts.clear()
	last_hand_card_rarity_texts.clear()
	if combat.phase == "won" or combat.phase == "lost":
		return

	for i in range(combat.hand.size()):
		var card: Dictionary = combat.hand[i]
		var button := Button.new()
		button.set_meta("hand_index", i)
		button.custom_minimum_size = _hand_card_size()
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.text = ""
		# The hand is a quick-scanning surface. Full rules text lives in the
		# dedicated hover preview so the native tooltip cannot duplicate it.
		button.tooltip_text = "" if _is_pc_layout() else "%s [%d]\n%s\n%s" % [
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
		button.disabled = combat_presentation_busy or not combat.can_play_card(i)
		_add_structured_card_layout(button, card, card_texture, "hand")
		button.mouse_entered.connect(_on_card_previewed.bind(i))
		button.mouse_entered.connect(_on_hand_card_hovered.bind(i, true))
		button.mouse_exited.connect(_hide_card_detail_preview.bind(i))
		button.mouse_exited.connect(_on_hand_card_hovered.bind(i, false))
		button.focus_entered.connect(_on_card_previewed.bind(i))
		button.focus_entered.connect(_on_hand_card_hovered.bind(i, true))
		button.focus_exited.connect(_hide_card_detail_preview.bind(i))
		button.focus_exited.connect(_on_hand_card_hovered.bind(i, false))
		button.gui_input.connect(_on_hand_card_gui_input.bind(i))
		button.pressed.connect(_on_card_button_pressed.bind(i))
		hand_row.add_child(button)
		hand_buttons_by_index[i] = button
	hand_row.queue_sort()

func _add_structured_card_layout(button: Button, card: Dictionary, card_texture: Texture2D, telemetry_bucket: String) -> void:
	var card_type: String = str(card.get("type", ""))
	var card_name: String = str(card.get("name", "卡牌"))
	var cost_text: String = str(int(card.get("cost", 0)))
	var type_text: String = _card_type_display_name(card_type)
	var rarity_text: String = _rarity_display_name(str(card.get("rarity", "common")))
	var visible_type_text: String = type_text
	if not rarity_text.is_empty():
		visible_type_text = "%s · %s" % [type_text, rarity_text]
	var use_pc_full_art: bool = _is_pc_layout() and (telemetry_bucket == "hand" or button.custom_minimum_size.y >= 200.0)
	if use_pc_full_art:
		_add_pc_hand_card_layout(button, card, card_texture, card_type, card_name, cost_text, visible_type_text, telemetry_bucket)
		_record_structured_card_layout(telemetry_bucket, card_texture != null, cost_text, type_text, card_name, rarity_text)
		return
	var compact: bool = (telemetry_bucket == "hand" and not _is_pc_layout()) or button.custom_minimum_size.y < 178.0
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
	if _is_pc_layout() and not compact:
		var card_height: float = button.custom_minimum_size.y
		top_height = 28.0
		cost_size = Vector2(32, 28)
		name_font_size = 14
		cost_font_size = 17
		art_height = clamp(round(card_height * 0.30), 64.0, 82.0)
		type_font_size = 11
		desc_height = clamp(round(card_height * 0.31), 66.0, 88.0)
		desc_font_size = 11
		child_gap = 5
	var framed_content_padding := 12.0

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
	art_frame.clip_contents = true
	art_frame.add_theme_stylebox_override("panel", _hand_card_art_frame_style(card_type))
	box.add_child(art_frame)

	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(0, max(0.0, art_height - framed_content_padding))
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	desc.custom_minimum_size = Vector2(0, max(0.0, desc_height - framed_content_padding))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.add_theme_font_size_override("font_size", desc_font_size)
	desc.add_theme_color_override("font_color", Color(0.88, 0.90, 0.88))
	desc_panel.add_child(desc)

	_record_structured_card_layout(telemetry_bucket, card_texture != null, cost_text, type_text, card_name, rarity_text)

func _add_pc_hand_card_layout(button: Button, card: Dictionary, card_texture: Texture2D, card_type: String, card_name: String, cost_text: String, visible_type_text: String, telemetry_bucket: String) -> void:
	button.clip_contents = true
	var detail_preview: bool = telemetry_bucket == "detail_preview"
	var hand_card: bool = telemetry_bucket == "hand"
	var show_description: bool = true
	var material_frame_texture: Texture2D = _load_texture(_pc_card_material_frame_path(card_type))
	var has_material_frame: bool = material_frame_texture != null
	var card_height: float = button.custom_minimum_size.y
	var top_height: float = clamp(round(card_height * 0.18), 30.0, 38.0)
	var desc_height: float = clamp(round(card_height * 0.27), 46.0, 54.0) if hand_card else (110.0 if detail_preview else clamp(round(card_height * 0.40), 72.0, 86.0))
	var type_height: float = 18.0 if hand_card else 20.0

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 1 if has_material_frame else 3
	root.offset_top = 1 if has_material_frame else 3
	root.offset_right = -1 if has_material_frame else -3
	root.offset_bottom = -1 if has_material_frame else -3
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.clip_contents = true
	root.add_child(stack)

	var art := TextureRect.new()
	art.name = "FullCardArt"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = card_texture
	stack.add_child(art)

	var left_rail := ColorRect.new()
	left_rail.name = "CardLeftRail"
	left_rail.anchor_left = 0.0
	left_rail.anchor_top = 0.0
	left_rail.anchor_right = 0.0
	left_rail.anchor_bottom = 1.0
	left_rail.offset_left = 0.0
	left_rail.offset_right = 7.0
	left_rail.color = _pc_card_rail_color(card_type, true)
	left_rail.visible = not has_material_frame
	left_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(left_rail)

	var right_rail := ColorRect.new()
	right_rail.name = "CardRightRail"
	right_rail.anchor_left = 1.0
	right_rail.anchor_top = 0.0
	right_rail.anchor_right = 1.0
	right_rail.anchor_bottom = 1.0
	right_rail.offset_left = -6.0
	right_rail.offset_right = 0.0
	right_rail.color = Color(0.0, 0.0, 0.0, 0.40)
	right_rail.visible = not has_material_frame
	right_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(right_rail)

	var top_highlight := ColorRect.new()
	top_highlight.name = "CardTopHighlight"
	top_highlight.anchor_left = 0.0
	top_highlight.anchor_top = 0.0
	top_highlight.anchor_right = 1.0
	top_highlight.anchor_bottom = 0.0
	top_highlight.offset_top = 0.0
	top_highlight.offset_bottom = 2.0
	top_highlight.color = Color(1.0, 0.92, 0.70, 0.34)
	top_highlight.visible = not has_material_frame
	top_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(top_highlight)

	var diagonal_glaze := ColorRect.new()
	diagonal_glaze.name = "CardDiagonalGlaze"
	diagonal_glaze.anchor_left = 0.0
	diagonal_glaze.anchor_top = 0.0
	diagonal_glaze.anchor_right = 0.0
	diagonal_glaze.anchor_bottom = 0.0
	diagonal_glaze.offset_left = 18.0
	diagonal_glaze.offset_top = -22.0
	diagonal_glaze.offset_right = 82.0
	diagonal_glaze.offset_bottom = 120.0
	diagonal_glaze.rotation = -0.18
	diagonal_glaze.color = Color(1.0, 0.96, 0.80, 0.055)
	diagonal_glaze.visible = not has_material_frame
	diagonal_glaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(diagonal_glaze)

	var top_scrim := ColorRect.new()
	top_scrim.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_scrim.anchor_right = 1.0
	top_scrim.offset_right = 0.0
	top_scrim.offset_bottom = top_height + 10.0
	top_scrim.color = Color(0.02, 0.015, 0.014, 0.58)
	top_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(top_scrim)

	var bottom_scrim := ColorRect.new()
	bottom_scrim.anchor_left = 0.0
	bottom_scrim.anchor_top = 1.0
	bottom_scrim.anchor_right = 1.0
	bottom_scrim.anchor_bottom = 1.0
	bottom_scrim.offset_top = -desc_height - type_height - (10.0 if hand_card else 16.0)
	bottom_scrim.offset_bottom = 0.0
	bottom_scrim.color = Color(0.015, 0.014, 0.016, 0.68)
	bottom_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bottom_scrim)

	if has_material_frame:
		var material_frame := TextureRect.new()
		material_frame.name = "CardMaterialFrame"
		material_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		material_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		material_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		material_frame.stretch_mode = TextureRect.STRETCH_SCALE
		material_frame.texture = material_frame_texture
		material_frame.modulate = Color(1.0, 1.0, 1.0, 0.96)
		stack.add_child(material_frame)
		if telemetry_bucket == "hand":
			last_hand_card_material_frame_count += 1

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = not has_material_frame
	frame.add_theme_stylebox_override("panel", _pc_hand_card_frame_style(card_type))
	stack.add_child(frame)

	var title_panel := PanelContainer.new()
	title_panel.anchor_left = 0.0
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 1.0
	title_panel.anchor_bottom = 0.0
	title_panel.offset_left = 42.0 if has_material_frame else 26.0
	title_panel.offset_top = 4.0
	title_panel.offset_right = -8.0
	title_panel.offset_bottom = top_height
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_theme_stylebox_override("panel", _pc_hand_card_title_style(card_type))
	stack.add_child(title_panel)

	var title_margin := MarginContainer.new()
	title_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_margin.add_theme_constant_override("margin_left", 12)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_panel.add_child(title_margin)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = card_name
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	title_margin.add_child(name_label)

	var cost_panel := PanelContainer.new()
	cost_panel.anchor_left = 0.0
	cost_panel.anchor_top = 0.0
	cost_panel.anchor_right = 0.0
	cost_panel.anchor_bottom = 0.0
	cost_panel.offset_left = 4.0
	cost_panel.offset_top = 2.0
	cost_panel.offset_right = 36.0
	cost_panel.offset_bottom = 34.0
	cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_panel.add_theme_stylebox_override("panel", _hand_card_cost_style(card_type))
	stack.add_child(cost_panel)

	var cost_label := Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = cost_text
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 17)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78))
	cost_panel.add_child(cost_label)

	var rarity_gem := PanelContainer.new()
	rarity_gem.name = "CardRarityGem"
	rarity_gem.anchor_left = 1.0
	rarity_gem.anchor_top = 0.0
	rarity_gem.anchor_right = 1.0
	rarity_gem.anchor_bottom = 0.0
	rarity_gem.offset_left = -26.0
	rarity_gem.offset_top = 8.0
	rarity_gem.offset_right = -10.0
	rarity_gem.offset_bottom = 24.0
	rarity_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_gem.add_theme_stylebox_override("panel", _pc_card_rarity_gem_style(str(card.get("rarity", "common"))))
	stack.add_child(rarity_gem)

	var type_panel := PanelContainer.new()
	type_panel.name = "CardTypePanel"
	type_panel.anchor_left = 0.08
	type_panel.anchor_top = 1.0
	type_panel.anchor_right = 0.92
	type_panel.anchor_bottom = 1.0
	type_panel.offset_top = -desc_height - type_height - (6.0 if hand_card else 4.0)
	type_panel.offset_bottom = -desc_height - (6.0 if hand_card else 4.0)
	type_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_panel.add_theme_stylebox_override("panel", _pc_hand_card_type_style(card_type))
	stack.add_child(type_panel)

	var type_label := Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.text = visible_type_text
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.clip_text = true
	type_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", _hand_card_type_color(card_type))
	type_panel.add_child(type_label)

	if show_description:
		var desc_panel := PanelContainer.new()
		desc_panel.name = "CardDescriptionPanel"
		desc_panel.anchor_left = 0.0
		desc_panel.anchor_top = 1.0
		desc_panel.anchor_right = 1.0
		desc_panel.anchor_bottom = 1.0
		desc_panel.offset_left = 8.0
		desc_panel.offset_top = -desc_height
		desc_panel.offset_right = -8.0
		desc_panel.offset_bottom = -8.0
		desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_panel.add_theme_stylebox_override("panel", _pc_hand_card_description_style(card_type))
		stack.add_child(desc_panel)

		var desc_margin := MarginContainer.new()
		desc_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_margin.add_theme_constant_override("margin_left", 7)
		desc_margin.add_theme_constant_override("margin_right", 7)
		desc_margin.add_theme_constant_override("margin_top", 4)
		desc_margin.add_theme_constant_override("margin_bottom", 4)
		desc_panel.add_child(desc_margin)

		var desc := Label.new()
		desc.name = "CardDescriptionText"
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc.text = str(card.get("description", ""))
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc.clip_text = not detail_preview
		desc.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING if detail_preview else TextServer.OVERRUN_TRIM_ELLIPSIS
		desc.add_theme_font_size_override("font_size", 11 if detail_preview else (9 if hand_card else 10))
		if card_height <= 200.0 and not hand_card:
			desc.add_theme_font_size_override("font_size", 9)
		if hand_card:
			desc.max_lines_visible = 3
		desc.add_theme_color_override("font_color", Color(0.94, 0.90, 0.78))
		desc_margin.add_child(desc)

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
		"shop_remove":
			last_shop_remove_card_layout_count += 1
			if art_loaded:
				last_shop_remove_card_art_node_count += 1
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

func _add_reward_action_button(title: String, subtitle: String, description: String, icon_path: String, skin: String, disabled: bool, callback: Callable, compact: bool = false) -> Button:
	var button := Button.new()
	button.custom_minimum_size = _reward_action_button_size(compact)
	button.text = ""
	button.tooltip_text = "%s\n%s\n%s" % [title, subtitle, description]
	button.disabled = disabled
	_apply_button_skin(button, skin, "reward")
	_add_icon_item_layout(
		button,
		title,
		subtitle,
		description,
		_load_texture(icon_path),
		skin,
		"reward_action",
		compact
	)
	if callback.is_valid():
		button.pressed.connect(callback)
	return button

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

func _add_generated_texture_background(parent: Control, texture_path: String, alpha: float = 1.0) -> TextureRect:
	if parent == null:
		return null
	var existing := parent.get_node_or_null("GeneratedTextureBackground") as TextureRect
	if existing != null:
		existing.texture = _load_texture(texture_path)
		existing.modulate = Color(1, 1, 1, alpha)
		return existing
	var texture := TextureRect.new()
	texture.name = "GeneratedTextureBackground"
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.texture = _load_texture(texture_path)
	texture.modulate = Color(1, 1, 1, alpha)
	parent.add_child(texture)
	parent.move_child(texture, 0)
	return texture

func _remove_generated_button_skin_children(button: Button) -> void:
	if button == null:
		return
	for child in button.get_children():
		if child.name == "GeneratedTextureBackground" or child.name == "GeneratedButtonLabelRoot":
			button.remove_child(child)
			child.free()

func _apply_generated_button_texture_label(button: Button, texture_path: String, label_text: String) -> void:
	if button == null:
		return
	_remove_generated_button_skin_children(button)
	button.text = ""
	button.clip_contents = true
	_add_generated_texture_background(button, texture_path, 0.96)
	var center := CenterContainer.new()
	center.name = "GeneratedButtonLabelRoot"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14 if button.custom_minimum_size.x < 120.0 else 19)
	label.add_theme_color_override("font_color", Color(0.98, 1.0, 0.78))
	center.add_child(label)

func _hud_badge_text(label_text: String) -> String:
	match label_text:
		"生命":
			return "心"
		"护甲":
			return "盾"
		"能量":
			return "能"
		"势能":
			return "势"
		"抽牌":
			return "抽"
		"弃牌":
			return "弃"
		"消耗":
			return "耗"
		_:
			return label_text.substr(0, 1)

func _pc_hud_panel_style(skin: String) -> StyleBoxFlat:
	var palette: Dictionary = _button_skin_palette(skin)
	var bg: Color = palette.get("bg", Color(0.16, 0.17, 0.18)).darkened(0.28)
	var border: Color = palette.get("border", Color(0.46, 0.50, 0.52)).darkened(0.04)
	var style := _button_style(Color(bg.r, bg.g, bg.b, 0.76), Color(border.r, border.g, border.b, 0.82), 1, 8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 3
	return style

func _pc_hud_badge_style(skin: String) -> StyleBoxFlat:
	var palette: Dictionary = _button_skin_palette(skin)
	var border: Color = palette.get("border", Color(0.46, 0.50, 0.52))
	var bg: Color = border.darkened(0.34)
	var style := _button_style(Color(bg.r, bg.g, bg.b, 0.92), Color(border.r, border.g, border.b, 0.96), 1, 12)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_size = 1
	return style

func _pc_potion_slot_style(occupied: bool, highlighted: bool, disabled: bool = false) -> StyleBoxFlat:
	var bg := Color(0.050, 0.064, 0.070, 0.82)
	var border := Color(0.35, 0.45, 0.45, 0.76)
	if occupied:
		bg = Color(0.075, 0.18, 0.18, 0.94)
		border = Color(0.48, 0.92, 0.88, 0.96)
	if highlighted:
		bg = bg.lightened(0.10)
		border = border.lightened(0.16)
	if disabled and not occupied:
		bg = Color(0.030, 0.038, 0.042, 0.64)
		border = Color(0.32, 0.38, 0.38, 0.58)
	var style := _button_style(bg, border, 1, 11)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.shadow_color = Color(0, 0, 0, 0.50)
	style.shadow_size = 3
	return style

func _pc_potion_empty_socket_style() -> StyleBoxFlat:
	var style := _button_style(Color(0.012, 0.018, 0.020, 0.44), Color(0.38, 0.56, 0.53, 0.40), 1, 8)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 1
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

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
		"shop_relic":
			last_shop_relic_layout_count += 1
			if icon_loaded:
				last_shop_relic_icon_node_count += 1
		"reward_potion":
			last_reward_potion_layout_count += 1
			if icon_loaded:
				last_reward_potion_icon_node_count += 1
		"reward_relic":
			last_reward_relic_layout_count += 1
			if icon_loaded:
				last_reward_relic_icon_node_count += 1
		"treasure_relic":
			last_treasure_relic_layout_count += 1
			if icon_loaded:
				last_treasure_relic_icon_node_count += 1
		"reward_action":
			last_reward_action_button_count += 1
			if icon_loaded:
				last_reward_action_icon_node_count += 1

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
	last_feedback_label_suppressed_for_stage = false
	if _stage_feedback_replaces_label(event_type):
		feedback_label.visible = false
		last_feedback_label_suppressed_for_stage = true
		return
	feedback_label.text = message
	feedback_label.visible = true
	var feedback_height: float = round((36.0 if _is_strong_feedback(event_type) else 28.0) * _combat_layout_scale())
	feedback_label.custom_minimum_size = Vector2(340.0 if _is_pc_layout() else 0.0, feedback_height)
	feedback_label.add_theme_font_size_override("font_size", _feedback_font_size(event_type))
	feedback_label.add_theme_stylebox_override("normal", _feedback_style(str(event.get("severity", "info"))))
	feedback_label.modulate = Color(1, 1, 1, 1)
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		if feedback_label_tween != null and feedback_label_tween.is_valid():
			feedback_label_tween.kill()
		feedback_label_tween = create_tween()
		feedback_label.scale = Vector2(1.10, 1.10) if _is_strong_feedback(event_type) else Vector2(1.04, 1.04)
		feedback_label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.12)
		feedback_label_tween.parallel().tween_property(feedback_label, "modulate", Color(1, 1, 1, 0.88), 0.36)

func _apply_feedback_effects(events: Array, primary_event: Dictionary) -> void:
	last_flash_target_id = ""
	last_feedback_visual_type = str(primary_event.get("type", ""))
	last_feedback_audio_event = _feedback_audio_event_for_event(primary_event)
	last_hit_stop_duration = 0.0
	last_hit_stop_request_count = 0
	last_hit_stop_scope = ""
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

	var batch_hit_stop_duration := 0.0
	for event in events:
		var event_dict: Dictionary = event
		var event_type: String = str(event_dict.get("type", ""))
		match str(event_dict.get("type", "")):
			"enemy_hit", "enemy_block_absorb", "enemy_defeated":
				var target_id: String = str(event_dict.get("target_id", ""))
				if not target_id.is_empty():
					last_flash_target_id = target_id
					_flash_enemy_target(target_id, str(event_dict.get("severity", "hit")))
			"phase":
				last_flash_target_id = str(event_dict.get("target_id", ""))
			"player_hit":
				last_flash_target_id = "player"
				_flash_player_target(true)
			"block", "block_absorb", "heal":
				last_flash_target_id = "player"
				_flash_player_target(false)
			"won", "lost":
				last_flash_target_id = str(event_dict.get("target_id", ""))

		if _feedback_spawns_float(event_type):
			_spawn_floating_feedback(event_dict)
		if _feedback_spawns_impact(event_type):
			_spawn_impact_effect(event_dict)
		var stop_duration: float = _feedback_hit_stop_duration(event_dict)
		batch_hit_stop_duration = max(batch_hit_stop_duration, stop_duration)
		var shake_intensity: float = _feedback_shake_intensity(event_dict)
		if shake_intensity > 0.0:
			_request_screen_shake(shake_intensity, _feedback_shake_duration(event_dict))
		if _is_cinematic_feedback(event_type):
			_show_cinematic_prompt(event_dict)
		if event_type == "phase":
			_play_phase_character_animation(str(event_dict.get("target_id", "")), int(event_dict.get("amount", 0)))
	if batch_hit_stop_duration > 0.0:
		_request_hit_stop(batch_hit_stop_duration)

func _feedback_audio_event_for_event(event: Dictionary) -> String:
	var event_type: String = str(event.get("type", ""))
	if event_type == "phase":
		var profile: Dictionary = _boss_phase_profile(str(event.get("target_id", "")), int(event.get("amount", 0)))
		var configured: String = str(profile.get("audio_event", ""))
		if not configured.is_empty():
			return configured
	return _feedback_audio_event(event_type)

func _feedback_audio_event(event_type: String) -> String:
	match event_type:
		"enemy_hit", "enemy_defeated", "player_hit":
			return "hit"
		"block", "block_absorb", "enemy_block_absorb":
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
	if event_type == "phase":
		if cinematic_tween != null and cinematic_tween.is_valid():
			cinematic_tween.kill()
		_hide_cinematic_prompt()
		_show_boss_phase_banner(event)
		return
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
	if cinematic_tween != null and cinematic_tween.is_valid():
		cinematic_tween.kill()
	cinematic_tween = create_tween()
	cinematic_tween.tween_property(cinematic_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cinematic_tween.tween_interval(_cinematic_hold_duration(event_type))
	cinematic_tween.tween_property(cinematic_overlay, "modulate", Color(1, 1, 1, 0), 0.18)
	cinematic_tween.tween_callback(Callable(self, "_hide_cinematic_prompt"))

func _show_boss_phase_banner(event: Dictionary) -> void:
	last_boss_phase_banner_visible = false
	last_boss_phase_banner_title = ""
	last_boss_phase_banner_note = ""
	last_boss_phase_banner_effect = ""
	last_boss_phase_banner_intent = ""
	if enemy_stage_stack == null:
		return
	if boss_phase_banner_tween != null and boss_phase_banner_tween.is_valid():
		boss_phase_banner_tween.kill()
	var existing := enemy_stage_stack.get_node_or_null("BossPhaseBanner")
	if existing != null:
		enemy_stage_stack.remove_child(existing)
		existing.queue_free()

	var target_id: String = str(event.get("target_id", ""))
	var enemy: Dictionary = {}
	if combat != null:
		for candidate in combat.enemies:
			var candidate_dict: Dictionary = candidate
			if str(candidate_dict.get("id", "")) == target_id:
				enemy = candidate_dict
				break
	var enemy_data: Dictionary = enemy.get("data", {})
	var phases: Array = enemy_data.get("phases", [])
	var transition_index: int = int(event.get("amount", enemy.get("phase_index", 0)))
	var phase_data: Dictionary = {}
	var runtime_phase_data: Variant = enemy.get("phase_data", {})
	if runtime_phase_data is Dictionary:
		phase_data = runtime_phase_data
	if phase_data.is_empty() and transition_index >= 0 and transition_index < phases.size():
		var configured_phase: Variant = phases[transition_index]
		if configured_phase is Dictionary:
			phase_data = configured_phase
	var phase_count: int = max(2, phases.size() + 1)
	var phase_ordinal: int = clampi(transition_index + 2, 1, phase_count)
	var boss_name: String = str(enemy.get("name", target_id))
	if boss_name.is_empty():
		boss_name = "Boss"
	var phase_name: String = str(phase_data.get("name", enemy.get("phase_name", "")))
	if phase_name.is_empty():
		phase_name = str(event.get("message", "阶段变更"))
	var phase_note: String = str(phase_data.get("phase_note", event.get("message", "战斗形态发生改变。")))
	var effect_summary: String = _boss_phase_effect_summary(phase_data.get("on_enter_effects", []))
	var action: Dictionary = enemy.get("current_action", {})
	if action.is_empty():
		var phase_actions: Array = phase_data.get("actions", [])
		if not phase_actions.is_empty() and phase_actions[0] is Dictionary:
			action = phase_actions[0]
	var intent_summary: String = _intent_text(action.get("intent", {}))
	if intent_summary.is_empty() or intent_summary == "none":
		intent_summary = "意图正在重组"
	var profile: Dictionary = _boss_phase_profile(target_id, transition_index)
	var accent: Color = _vfx_profile_color(profile) if not profile.is_empty() else Color(1.0, 0.72, 0.30, 1.0)

	last_boss_phase_banner_visible = true
	last_boss_phase_banner_title = "%s · 阶段 %d/%d · %s" % [boss_name, phase_ordinal, phase_count, phase_name]
	last_boss_phase_banner_note = phase_note
	last_boss_phase_banner_effect = effect_summary
	last_boss_phase_banner_intent = intent_summary

	var stage_width: float = max(enemy_stage_stack.size.x, enemy_stage_panel.size.x if enemy_stage_panel != null else 0.0)
	if stage_width <= 64.0:
		stage_width = max(320.0, _scroll_content_width() - _potion_row_width() - 24.0)
	var banner_width: float = clamp(min(620.0, stage_width - 32.0), 288.0, 620.0)
	var banner_height := 116.0
	var banner := PanelContainer.new()
	banner.name = "BossPhaseBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.process_mode = Node.PROCESS_MODE_ALWAYS
	banner.anchor_left = 0.5
	banner.anchor_top = 0.0
	banner.anchor_right = 0.5
	banner.anchor_bottom = 0.0
	banner.offset_left = -banner_width * 0.5
	banner.offset_top = 38.0
	banner.offset_right = banner_width * 0.5
	banner.offset_bottom = 38.0 + banner_height
	banner.custom_minimum_size = Vector2(banner_width, banner_height)
	banner.clip_contents = true
	banner.z_index = 24
	var banner_style := _button_style(Color(0.025, 0.028, 0.034, 0.96), Color(accent.r, accent.g, accent.b, 0.96), 2, 6)
	banner_style.content_margin_left = 10
	banner_style.content_margin_right = 12
	banner_style.content_margin_top = 8
	banner_style.content_margin_bottom = 8
	banner_style.shadow_color = Color(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, 0.72)
	banner_style.shadow_size = 8
	banner.add_theme_stylebox_override("panel", banner_style)
	enemy_stage_stack.add_child(banner)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	banner.add_child(row)

	var portrait := TextureRect.new()
	portrait.name = "BossPhaseBannerPortrait"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(82, 94)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = _enemy_texture(enemy) if not enemy.is_empty() else null
	portrait.modulate = Color(1.0, 1.0, 1.0, 0.96)
	row.add_child(portrait)

	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)
	_add_boss_phase_banner_label(copy, "BossPhaseBannerTitle", last_boss_phase_banner_title, 17, accent.lightened(0.24))
	_add_boss_phase_banner_label(copy, "BossPhaseBannerNote", phase_note, 11, Color(0.84, 0.84, 0.80))
	_add_boss_phase_banner_label(copy, "BossPhaseBannerEffect", "阶段效果 · %s" % effect_summary, 12, Color(1.0, 0.84, 0.50))
	_add_boss_phase_banner_label(copy, "BossPhaseBannerIntent", "下一意图 · %s" % intent_summary, 13, Color(0.74, 0.94, 1.0))

	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	banner.pivot_offset = Vector2(banner_width * 0.5, banner_height * 0.5)
	banner.scale = Vector2(0.96, 0.96)
	banner.modulate = Color(1, 1, 1, 0)
	boss_phase_banner_tween = create_tween().bind_node(banner).set_ignore_time_scale(true)
	boss_phase_banner_tween.tween_property(banner, "modulate", Color.WHITE, 0.18)
	boss_phase_banner_tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	boss_phase_banner_tween.tween_interval(0.95)
	boss_phase_banner_tween.tween_property(banner, "modulate", Color(1, 1, 1, 0), 0.20)
	boss_phase_banner_tween.tween_callback(Callable(self, "_hide_boss_phase_banner").bind(banner))

func _add_boss_phase_banner_label(parent: VBoxContainer, node_name: String, text_value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)

func _boss_phase_effect_summary(effects: Array) -> String:
	var parts: Array[String] = []
	for effect in effects:
		var effect_dict: Dictionary = effect
		var amount: int = int(effect_dict.get("amount", 0))
		match str(effect_dict.get("type", "")):
			"block":
				parts.append("获得 %d 点护甲" % amount)
			"apply_status":
				parts.append("获得 %d 层%s" % [amount, _status_display_name(str(effect_dict.get("status", "状态")))])
			"create_card":
				var card_id: String = str(effect_dict.get("card_id", ""))
				var card_name: String = str(_card_by_id(card_id).get("name", card_id))
				var destination: String = "弃牌堆" if str(effect_dict.get("destination", "discard")) == "discard" else "牌堆"
				parts.append("向%s加入 %d 张%s" % [destination, amount, card_name])
			"heal":
				parts.append("恢复 %d 点生命" % amount)
			_:
				parts.append(str(effect_dict.get("type", "阶段强化")))
	if parts.is_empty():
		return "战斗形态重构"
	return "，".join(parts)

func _hide_boss_phase_banner(banner: Control) -> void:
	if not is_instance_valid(banner):
		return
	if banner.get_parent() == enemy_stage_stack:
		enemy_stage_stack.remove_child(banner)
	last_boss_phase_banner_visible = false
	banner.queue_free()

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
	if severity != "phase":
		_play_enemy_reaction(target_id, severity)
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
	elif severity == "block":
		flash_color = Color(0.48, 0.88, 1.0, 1.0)
	flash_color.a = float(ForgeMotionScript.resolve_policy(user_settings).get("flash_intensity", 1.0))
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
		_play_player_reaction(null, danger)
		return
	var flash_color := Color(1.0, 0.36, 0.30, 1.0) if danger else Color(0.48, 0.78, 1.0, 1.0)
	flash_color.a = float(ForgeMotionScript.resolve_policy(user_settings).get("flash_intensity", 1.0))
	var target: Control = _player_combat_target_control()
	if target == null:
		return
	var tween := create_tween()
	target.modulate = flash_color
	tween.tween_property(target, "modulate", Color.WHITE, 0.20)
	_play_player_reaction(target, danger)

func _play_enemy_reaction(target_id: String, severity: String) -> void:
	last_enemy_reaction_animation_count += 1
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var visual: Dictionary = enemy_visuals_by_id.get(target_id, {})
	if visual.is_empty():
		return
	var art := visual.get("art") as Control
	if art == null or not is_instance_valid(art):
		return
	var motion: Dictionary = _begin_stage_actor_motion(art)
	var base_position: Vector2 = motion.get("position", art.position)
	var base_scale: Vector2 = motion.get("scale", art.scale)
	var base_rotation: float = float(motion.get("rotation", art.rotation))
	art.pivot_offset = art.size * 0.5
	var tween := create_tween().bind_node(art)
	art.set_meta("stage_motion_tween", tween)
	if severity == "success":
		art.position = base_position + Vector2(15.0, -2.0)
		art.rotation = base_rotation + 0.045
		tween.tween_property(art, "position", base_position + Vector2(-12.0, 4.0), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale * 0.94, 0.075)
		tween.tween_property(art, "position", base_position, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale, 0.18)
		tween.parallel().tween_property(art, "rotation", base_rotation, 0.18)
	elif severity == "block":
		tween.tween_property(art, "scale", base_scale * 1.028, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(art, "scale", base_scale, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		art.position = base_position + Vector2(13.0, 0.0)
		art.rotation = base_rotation + 0.028
		tween.tween_property(art, "position", base_position + Vector2(-8.0, 1.0), 0.065).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale * 0.97, 0.065)
		tween.tween_property(art, "position", base_position, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale, 0.14)
		tween.parallel().tween_property(art, "rotation", base_rotation, 0.14)
	tween.tween_callback(Callable(self, "_finish_stage_actor_motion").bind(art, true))

func _play_player_reaction(target: Control, danger: bool) -> void:
	last_player_reaction_animation_count += 1
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or target == null or not is_instance_valid(target):
		return
	var motion: Dictionary = _begin_stage_actor_motion(target)
	var base_position: Vector2 = motion.get("position", target.position)
	var base_scale: Vector2 = motion.get("scale", target.scale)
	var base_rotation: float = float(motion.get("rotation", target.rotation))
	target.pivot_offset = target.size * 0.5
	var tween := create_tween().bind_node(target)
	target.set_meta("stage_motion_tween", tween)
	if danger:
		target.position = base_position + Vector2(-14.0, 2.0)
		target.rotation = base_rotation - 0.022
		tween.tween_property(target, "position", base_position + Vector2(7.0, 0.0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(target, "scale", base_scale * 0.975, 0.07)
		tween.tween_property(target, "position", base_position, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(target, "scale", base_scale, 0.15)
		tween.parallel().tween_property(target, "rotation", base_rotation, 0.15)
	else:
		tween.tween_property(target, "scale", base_scale * 1.045, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(target, "scale", base_scale, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_finish_stage_actor_motion").bind(target, false))

func _begin_stage_actor_motion(target: Control) -> Dictionary:
	if target == null or not is_instance_valid(target):
		return {}
	if target.has_meta("stage_motion_tween"):
		var active_tween := target.get_meta("stage_motion_tween") as Tween
		if active_tween != null and active_tween.is_valid():
			active_tween.kill()
	if target.has_meta("stage_motion_base_position"):
		target.position = target.get_meta("stage_motion_base_position")
		target.scale = target.get_meta("stage_motion_base_scale")
		target.rotation = float(target.get_meta("stage_motion_base_rotation"))
		target.remove_meta("stage_motion_base_position")
		target.remove_meta("stage_motion_base_scale")
		target.remove_meta("stage_motion_base_rotation")
	target.remove_meta("stage_motion_tween")
	if target.has_meta("idle_motion_tween"):
		var idle_tween := target.get_meta("idle_motion_tween") as Tween
		if idle_tween != null and idle_tween.is_valid():
			idle_tween.kill()
		target.remove_meta("idle_motion_tween")
	var motion := {
		"position": target.position,
		"scale": target.scale,
		"rotation": target.rotation
	}
	target.set_meta("stage_motion_base_position", target.position)
	target.set_meta("stage_motion_base_scale", target.scale)
	target.set_meta("stage_motion_base_rotation", target.rotation)
	return motion

func _finish_stage_actor_motion(target: Control, restart_idle: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_meta("stage_motion_base_position"):
		target.position = target.get_meta("stage_motion_base_position")
		target.scale = target.get_meta("stage_motion_base_scale")
		target.rotation = float(target.get_meta("stage_motion_base_rotation"))
		target.remove_meta("stage_motion_base_position")
		target.remove_meta("stage_motion_base_scale")
		target.remove_meta("stage_motion_base_rotation")
	target.remove_meta("stage_motion_tween")
	if restart_idle and target is TextureRect and target.has_meta("enemy_index"):
		_start_enemy_idle_motion(target as TextureRect, int(target.get_meta("enemy_index")))

func _feedback_spawns_float(event_type: String) -> bool:
	return ["enemy_hit", "player_hit", "block", "block_absorb", "enemy_block_absorb", "heal", "enemy_defeated", "phase", "won", "lost"].has(event_type)

func _feedback_spawns_impact(event_type: String) -> bool:
	return ["enemy_hit", "player_hit", "block", "block_absorb", "enemy_block_absorb", "heal", "enemy_defeated", "phase"].has(event_type)

func _stage_feedback_replaces_label(event_type: String) -> bool:
	return _is_pc_layout() and (event_type == "phase" or not _is_strong_feedback(event_type))

func _apply_hand_card_transforms() -> void:
	if hand_row == null:
		return
	var card_count: int = hand_row.get_child_count()
	for i in range(card_count):
		var button := hand_row.get_child(i) as Button
		if button == null:
			continue
		button.pivot_offset = button.custom_minimum_size * 0.5
		button.scale = Vector2.ONE
		button.z_index = i
		button.remove_meta("hand_hover_base_position")
		if _is_pc_layout():
			var center: float = float(max(1, card_count - 1)) * 0.5
			var distance_from_center: float = abs(float(i) - center)
			var base_position: Vector2 = button.position
			if button.has_meta("hand_layout_base_position"):
				base_position = button.get_meta("hand_layout_base_position")
				var previous_rest: Vector2 = button.get_meta("hand_rest_position", base_position)
				if button.position.distance_to(previous_rest) > 0.5:
					base_position = button.position
			else:
				button.set_meta("hand_layout_base_position", base_position)
			button.set_meta("hand_layout_base_position", base_position)
			var rest_position: Vector2 = base_position + Vector2(0, 0.5 + distance_from_center)
			button.set_meta("hand_rest_position", rest_position)
			button.position = rest_position
			button.rotation_degrees = _hand_card_base_rotation(i, card_count)
		else:
			button.remove_meta("hand_layout_base_position")
			button.remove_meta("hand_rest_position")
			button.rotation_degrees = 0.0

func _hand_card_base_rotation(index: int, card_count: int = -1) -> float:
	if not _is_pc_layout():
		return 0.0
	if card_count < 0:
		card_count = combat.hand.size() if combat != null else 0
	if card_count <= 1:
		return 0.0
	var center: float = float(card_count - 1) * 0.5
	return clamp((float(index) - center) * 1.6, -3.2, 3.2)

func _on_hand_card_hovered(index: int, hovered: bool) -> void:
	if not _is_pc_layout() or hand_row == null or not hand_buttons_by_index.has(index):
		return
	var button := hand_buttons_by_index.get(index) as Button
	if button == null:
		return
	button.pivot_offset = button.size * 0.5 if button.size.x > 0.0 and button.size.y > 0.0 else button.custom_minimum_size * 0.5
	var card_count: int = hand_row.get_child_count()
	var base_rotation: float = _hand_card_base_rotation(index, card_count)
	var rest_position: Vector2 = button.get_meta("hand_rest_position", button.position)
	var active_tween: Tween
	if button.has_meta("hand_hover_tween"):
		active_tween = button.get_meta("hand_hover_tween") as Tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	if hovered:
		button.set_meta("hand_hover_base_position", rest_position)
		button.z_index = 80
		var enter_tween := create_tween()
		button.set_meta("hand_hover_tween", enter_tween)
		enter_tween.tween_property(button, "scale", Vector2(1.045, 1.045), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		enter_tween.parallel().tween_property(button, "rotation_degrees", 0.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		enter_tween.parallel().tween_property(button, "position", rest_position + Vector2(0, -24), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		var base_position: Vector2 = button.get_meta("hand_hover_base_position", rest_position)
		button.z_index = index
		var exit_tween := create_tween()
		button.set_meta("hand_hover_tween", exit_tween)
		exit_tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		exit_tween.parallel().tween_property(button, "rotation_degrees", base_rotation, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		exit_tween.parallel().tween_property(button, "position", base_position, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		button.remove_meta("hand_hover_base_position")

func _on_hand_card_gui_input(event: InputEvent, index: int) -> void:
	if combat_presentation_busy or not _is_pc_layout() or combat == null or combat.phase != "player":
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed and not mouse_button.double_click and combat.can_play_card(index):
			card_drag_candidate_index = index
			card_drag_index = index
			card_drag_start_mouse = mouse_button.global_position
			if card_drag_start_mouse == Vector2.ZERO:
				card_drag_start_mouse = get_viewport().get_mouse_position()
			card_drag_pointer = card_drag_start_mouse
			card_drag_source_button = hand_buttons_by_index.get(index, null) as Button

func _on_card_button_pressed(index: int) -> void:
	card_drag_candidate_index = -1
	card_drag_index = -1
	if card_drag_suppress_click_index == index:
		card_drag_suppress_click_index = -1
		return
	_on_card_pressed(index)

func _begin_card_drag(index: int, pointer: Vector2) -> void:
	if combat_presentation_busy or combat == null or combat.phase != "player" or index < 0 or index >= combat.hand.size() or not combat.can_play_card(index):
		return
	card_drag_active = true
	card_drag_candidate_index = index
	card_drag_index = index
	card_drag_target_index = -1
	card_drag_pointer = pointer
	last_card_drag_started_count += 1
	last_card_drag_valid = false
	last_card_drag_target_id = ""
	last_card_drag_curve_point_count = 0
	card_drag_source_button = hand_buttons_by_index.get(index, null) as Button
	var card: Dictionary = combat.hand[index]
	last_card_drag_ghost_uses_art = _asset_loaded(_card_art_path(card))
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null:
		return
	if card_drag_source_button != null:
		card_drag_source_button.modulate = Color(1, 1, 1, 0.28)
	var card_texture: Texture2D = _load_texture(_card_art_path(card))
	last_card_drag_ghost_uses_art = card_texture != null
	card_drag_ghost = Button.new()
	card_drag_ghost.name = "CardDragGhost"
	card_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_drag_ghost.focus_mode = Control.FOCUS_NONE
	card_drag_ghost.custom_minimum_size = Vector2(132, 202)
	card_drag_ghost.size = card_drag_ghost.custom_minimum_size
	card_drag_ghost.pivot_offset = card_drag_ghost.size * 0.5
	card_drag_ghost.add_theme_stylebox_override("normal", _card_button_style(str(card.get("type", "")), true, false))
	_add_structured_card_layout(card_drag_ghost, card, card_texture, "drag")
	card_drag_ghost.scale = Vector2(1.04, 1.04)
	card_drag_ghost.z_index = 110
	feedback_overlay.add_child(card_drag_ghost)

	card_drag_curve = CurveTrailScript.new()
	card_drag_curve.z_index = 103
	feedback_overlay.add_child(card_drag_curve)

	card_drag_target_ring = PanelContainer.new()
	card_drag_target_ring.name = "CardDragTargetRing"
	card_drag_target_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_drag_target_ring.custom_minimum_size = Vector2(60, 60)
	card_drag_target_ring.size = card_drag_target_ring.custom_minimum_size
	card_drag_target_ring.z_index = 104
	feedback_overlay.add_child(card_drag_target_ring)
	_update_card_drag(pointer)

func _update_card_drag(pointer: Vector2) -> void:
	if not card_drag_active or combat == null or card_drag_index < 0 or card_drag_index >= combat.hand.size():
		return
	card_drag_pointer = pointer
	var card: Dictionary = combat.hand[card_drag_index]
	if card_drag_ghost != null and is_instance_valid(card_drag_ghost):
		var ghost_center: Vector2 = pointer + Vector2(0, -78.0)
		card_drag_ghost.position = _clamp_feedback_overlay_position(ghost_center - card_drag_ghost.size * 0.5, card_drag_ghost.size)
	var target_index: int = _card_drag_target_index_at(pointer)
	var over_stage: bool = _card_drag_pointer_over_stage(pointer)
	last_card_drag_valid = _card_drag_accepts_target(card, target_index, over_stage)
	card_drag_target_index = target_index if _card_targets_enemy(card) else -1
	if last_card_drag_valid:
		last_card_drag_target_id = _card_visual_target_id(card, target_index)
		if _card_targets_enemy(card) and target_index >= 0 and target_index != selected_enemy_index:
			selected_enemy_index = target_index
			_queue_stage_forecast_refresh()
	else:
		last_card_drag_target_id = ""
	var start: Vector2 = pointer + Vector2(0, -24.0)
	if card_drag_ghost != null and is_instance_valid(card_drag_ghost):
		start = card_drag_ghost.position + Vector2(card_drag_ghost.size.x * 0.5, card_drag_ghost.size.y * 0.38)
	var end: Vector2 = pointer
	if last_card_drag_valid:
		end = _card_target_position(last_card_drag_target_id, target_index)
	var mid: Vector2 = (start + end) * 0.5 + Vector2(0, -58.0)
	var curve_points := PackedVector2Array()
	var point_count := 24
	for point_index in range(point_count + 1):
		var point_t: float = float(point_index) / float(point_count)
		curve_points.append(_quadratic_bezier(start, mid, end, point_t))
	last_card_drag_curve_point_count = curve_points.size()
	var color: Color = _card_visual_color(str(card.get("type", ""))) if last_card_drag_valid else Color(0.92, 0.30, 0.24, 1.0)
	if card_drag_curve != null and is_instance_valid(card_drag_curve):
		card_drag_curve.set_curve(curve_points, color, last_card_drag_valid, true)
	if card_drag_target_ring != null and is_instance_valid(card_drag_target_ring):
		card_drag_target_ring.visible = over_stage or target_index >= 0
		card_drag_target_ring.position = end - card_drag_target_ring.size * 0.5
		card_drag_target_ring.add_theme_stylebox_override("panel", _card_drag_target_style(color, last_card_drag_valid))

func _card_drag_target_index_at(pointer: Vector2) -> int:
	if combat == null or not _card_drag_pointer_over_stage(pointer):
		return -1
	var nearest_index := -1
	var nearest_distance := INF
	for enemy_index in range(combat.enemies.size()):
		if int(combat.enemies[enemy_index].get("hp", 0)) <= 0:
			continue
		var control := _enemy_combat_target_control(str(combat.enemies[enemy_index].get("id", "")), enemy_index)
		if control == null or not is_instance_valid(control):
			continue
		var rect: Rect2 = control.get_global_rect().grow(18.0)
		if rect.has_point(pointer):
			return enemy_index
		var distance: float = (rect.position + rect.size * 0.5).distance_to(pointer)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = enemy_index
	return nearest_index if nearest_distance <= 170.0 else -1

func _card_drag_pointer_over_stage(pointer: Vector2) -> bool:
	if enemy_stage_panel == null or not is_instance_valid(enemy_stage_panel) or not enemy_stage_panel.visible:
		return false
	return enemy_stage_panel.get_global_rect().grow(8.0).has_point(pointer)

func _card_drag_accepts_target(card: Dictionary, target_index: int, over_stage: bool) -> bool:
	if combat == null or card_drag_index < 0 or card_drag_index >= combat.hand.size() or not combat.can_play_card(card_drag_index):
		return false
	if _card_targets_all_enemies(card):
		return over_stage and not combat.get_alive_enemies().is_empty()
	if _card_targets_enemy(card):
		return target_index >= 0 and target_index < combat.enemies.size() and int(combat.enemies[target_index].get("hp", 0)) > 0
	return over_stage

func _finish_card_drag(play_card: bool) -> void:
	if not card_drag_active:
		return
	var index: int = card_drag_index
	var target_index: int = card_drag_target_index
	var source_button := card_drag_source_button
	var ghost := card_drag_ghost
	card_drag_active = false
	card_drag_candidate_index = -1
	card_drag_index = -1
	card_drag_target_index = -1
	card_drag_source_button = null
	card_drag_ghost = null
	_clear_card_drag_target_visuals()
	if play_card and last_card_drag_valid:
		last_card_drag_played_count += 1
		if source_button != null and is_instance_valid(source_button):
			source_button.modulate = Color.WHITE
		if ghost != null and is_instance_valid(ghost):
			ghost.queue_free()
		if target_index >= 0:
			selected_enemy_index = target_index
		card_drag_suppress_click_index = index
		_on_card_pressed(index)
		call_deferred("_clear_card_drag_click_suppression", index)
		return
	last_card_drag_cancelled_count += 1
	if ghost != null and is_instance_valid(ghost):
		var return_center: Vector2 = _card_source_position(index)
		var tween := create_tween().bind_node(ghost)
		tween.tween_property(ghost, "position", return_center - ghost.size * 0.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ghost, "scale", Vector2(0.86, 0.86), 0.16)
		tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0.12), 0.16)
		tween.tween_callback(Callable(self, "_complete_card_drag_cancel").bind(ghost, source_button))
	elif source_button != null and is_instance_valid(source_button):
		source_button.modulate = Color.WHITE

func _cancel_card_drag() -> void:
	if card_drag_active:
		last_card_drag_valid = false
		last_card_drag_target_id = ""
		_finish_card_drag(false)
	else:
		card_drag_candidate_index = -1
		card_drag_index = -1

func _clear_card_drag_target_visuals() -> void:
	for visual in [card_drag_curve, card_drag_target_ring]:
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
	card_drag_curve = null
	card_drag_target_ring = null

func _complete_card_drag_cancel(ghost: Control, source_button: Button) -> void:
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	if source_button != null and is_instance_valid(source_button):
		source_button.modulate = Color.WHITE

func _clear_card_drag_click_suppression(index: int) -> void:
	if card_drag_suppress_click_index == index:
		card_drag_suppress_click_index = -1

func _on_card_previewed(index: int) -> void:
	if combat == null or combat.phase != "player" or index < 0 or index >= combat.hand.size():
		return
	var target_index: int = _normalize_selected_enemy()
	var card: Dictionary = combat.hand[index]
	_show_card_detail_preview(card, index)
	var payload: Dictionary = _build_card_visual_payload(index, card, target_index)
	last_card_preview_index = index
	last_card_preview_card_id = str(card.get("id", ""))
	last_card_preview_target_id = str(payload.get("target_id", ""))
	if combat.can_play_card(index):
		_request_card_target_line(payload, false)

func _show_card_detail_preview(card: Dictionary, index: int) -> void:
	if not _is_pc_layout() or card_detail_preview == null:
		return
	_clear_container(card_detail_preview)
	var card_type: String = str(card.get("type", "skill"))
	card_detail_preview.add_theme_stylebox_override("normal", _card_button_style(card_type, true, false))
	card_detail_preview.add_theme_stylebox_override("hover", _card_button_style(card_type, true, false))
	card_detail_preview.tooltip_text = ""
	_add_structured_card_layout(card_detail_preview, card, _load_texture(_card_art_path(card)), "detail_preview")
	var preview_position := Vector2(22, 70)
	if hand_frame != null and is_inside_tree():
		var hand_rect: Rect2 = hand_frame.get_global_rect()
		var overlay_transform: Transform2D = feedback_overlay.get_global_transform_with_canvas()
		var preview_global_center_x: float = hand_rect.get_center().x
		var source_button := hand_buttons_by_index.get(index, null) as Button
		if source_button != null and is_instance_valid(source_button):
			preview_global_center_x = source_button.get_global_rect().get_center().x
		var stage_top: float = enemy_stage_panel.get_global_rect().position.y + 6.0 if enemy_stage_panel != null else 62.0
		preview_position = overlay_transform.affine_inverse() * Vector2(
			preview_global_center_x - card_detail_preview.size.x * 0.5,
			max(stage_top, hand_rect.position.y - card_detail_preview.size.y - 8.0)
		)
	card_detail_preview.position = _clamp_feedback_overlay_position(preview_position, card_detail_preview.size)
	card_detail_preview.visible = true
	card_detail_preview.set_meta("hand_index", index)
	last_card_detail_preview_visible = true
	last_card_detail_preview_card_id = str(card.get("id", ""))
	last_card_detail_preview_description = str(card.get("description", ""))

func _hide_card_detail_preview(index: int = -1) -> void:
	if card_detail_preview == null:
		return
	if index >= 0 and card_detail_preview.has_meta("hand_index") and int(card_detail_preview.get_meta("hand_index")) != index:
		return
	card_detail_preview.visible = false
	card_detail_preview.remove_meta("hand_index")
	last_card_detail_preview_visible = false

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
		"card_art_path": _card_art_path(card),
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
		return _control_center(_player_combat_target_control())
	if target_id == "all_enemies":
		return _alive_enemy_group_center()
	var control := _enemy_combat_target_control(target_id, target_index)
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
			var control := visual.get("art") as Control
			if control == null:
				control = visual.get("button") as Control
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
	last_card_trail_segment_count = 24 if persistent else 16
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or feedback_overlay == null:
		return
	var points: Array = payload.get("points", [])
	if points.size() < 3:
		return
	var color: Color = _card_visual_color(str(payload.get("card_type", "")))
	var duration: float = 0.34 if persistent else 0.20
	var curve_points := PackedVector2Array()
	for segment_index in range(last_card_trail_segment_count + 1):
		var point_t: float = float(segment_index) / float(last_card_trail_segment_count)
		curve_points.append(_quadratic_bezier(points[0], points[1], points[2], point_t))
	var curve := CurveTrailScript.new()
	curve.z_index = 3
	feedback_overlay.add_child(curve)
	curve.set_curve(curve_points, color, true, persistent)
	var tween := create_tween().bind_node(curve)
	tween.tween_property(curve, "modulate", Color(1, 1, 1, 0), duration)
	tween.tween_callback(Callable(curve, "queue_free"))
	if persistent:
		_spawn_card_pulse(points[2], 42.0, color, 0.28)

func _request_card_play_visual(payload: Dictionary) -> void:
	var points: Array = payload.get("points", [])
	var profile: String = _card_effect_profile(str(payload.get("card_type", "")))
	last_card_play_animation_count += 1
	last_card_play_card_id = str(payload.get("card_id", ""))
	last_card_play_target_id = str(payload.get("target_id", ""))
	last_card_effect_profile = profile
	last_card_particle_count = _card_particle_count(profile)
	last_card_audio_event = _card_audio_event(profile)
	last_card_flight_uses_card_art = _asset_loaded(str(payload.get("card_art_path", "")))
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
	ghost.custom_minimum_size = Vector2(86, 124) if _is_pc_layout() else Vector2(118, 72)
	ghost.size = ghost.custom_minimum_size
	ghost.pivot_offset = ghost.custom_minimum_size * 0.5
	ghost.clip_contents = true
	ghost.add_theme_stylebox_override("panel", _card_flight_style(str(payload.get("card_type", ""))))
	var stack := Control.new()
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.clip_contents = true
	ghost.add_child(stack)

	var card_art_path: String = str(payload.get("card_art_path", ""))
	var card_texture := _load_texture(card_art_path)
	if card_texture != null:
		var art := TextureRect.new()
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture = card_texture
		stack.add_child(art)
		var scrim := ColorRect.new()
		scrim.anchor_left = 0.0
		scrim.anchor_top = 1.0
		scrim.anchor_right = 1.0
		scrim.anchor_bottom = 1.0
		scrim.offset_top = -30.0
		scrim.color = Color(0.02, 0.016, 0.014, 0.64)
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(scrim)
	else:
		var fill := ColorRect.new()
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.color = Color(0.08, 0.075, 0.07, 0.92)
		stack.add_child(fill)
	var material_frame_texture: Texture2D = _load_texture(_pc_card_material_frame_path(str(payload.get("card_type", ""))))
	if material_frame_texture != null:
		var material_frame := TextureRect.new()
		material_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		material_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		material_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		material_frame.stretch_mode = TextureRect.STRETCH_SCALE
		material_frame.texture = material_frame_texture
		material_frame.modulate = Color(1.0, 1.0, 1.0, 0.94)
		stack.add_child(material_frame)

	var label := Label.new()
	label.anchor_left = 0.0
	label.anchor_top = 1.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 6.0
	label.offset_top = -29.0
	label.offset_right = -6.0
	label.offset_bottom = -4.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = str(payload.get("card_name", "卡牌"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 10 if _is_pc_layout() else 14)
	label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.78))
	stack.add_child(label)
	feedback_overlay.add_child(ghost)
	ghost.position = (points[0] as Vector2) - ghost.custom_minimum_size * 0.5
	ghost.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.tween_method(Callable(self, "_update_card_flight_position").bind(ghost, points, ghost.custom_minimum_size), 0.0, 1.0, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.46, 0.46), 0.27)
	tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0.16), 0.27)
	tween.tween_callback(Callable(self, "_spawn_card_resolution_effect").bind(payload))
	tween.tween_callback(Callable(ghost, "queue_free"))

func _play_player_card_action(payload: Dictionary) -> void:
	var card_type: String = str(payload.get("card_type", "default"))
	last_player_action_animation_count += 1
	last_player_action_animation_type = card_type
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var target: Control = _player_combat_target_control()
	if target == null or not is_instance_valid(target):
		return
	var motion: Dictionary = _begin_stage_actor_motion(target)
	var base_position: Vector2 = motion.get("position", target.position)
	var base_scale: Vector2 = motion.get("scale", target.scale)
	var base_rotation: float = float(motion.get("rotation", target.rotation))
	target.pivot_offset = target.size * 0.5
	var tween := create_tween().bind_node(target)
	target.set_meta("stage_motion_tween", tween)
	match card_type:
		"attack":
			tween.tween_property(target, "position", base_position + Vector2(34.0, -3.0), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target, "scale", base_scale * 1.055, 0.09)
			tween.parallel().tween_property(target, "rotation", base_rotation + 0.025, 0.09)
			tween.tween_property(target, "position", base_position, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target, "scale", base_scale, 0.16)
			tween.parallel().tween_property(target, "rotation", base_rotation, 0.16)
		"power":
			tween.tween_property(target, "scale", base_scale * 0.97, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(target, "scale", base_scale * 1.075, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target, "rotation", base_rotation - 0.018, 0.16)
			tween.tween_property(target, "scale", base_scale, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target, "rotation", base_rotation, 0.18)
		_:
			tween.tween_property(target, "position", base_position + Vector2(8.0, -6.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target, "scale", base_scale * 1.035, 0.10)
			tween.tween_property(target, "position", base_position, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(target, "scale", base_scale, 0.16)
	tween.tween_callback(Callable(self, "_finish_stage_actor_motion").bind(target, false))

func _capture_enemy_action_visuals() -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	if combat == null:
		return payloads
	for enemy_index in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[enemy_index]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var action: Dictionary = enemy.get("current_action", {})
		var intent: Dictionary = action.get("intent", {})
		payloads.append({
			"enemy_id": str(enemy.get("id", "")),
			"enemy_index": enemy_index,
			"intent_type": str(intent.get("type", "none"))
		})
	return payloads

func _play_enemy_action_visuals(payloads: Array[Dictionary]) -> void:
	last_enemy_action_animation_count = payloads.size()
	last_enemy_action_ids.clear()
	for payload in payloads:
		var enemy_id: String = str(payload.get("enemy_id", ""))
		if not enemy_id.is_empty():
			last_enemy_action_ids.append(enemy_id)
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	for payload_index in range(payloads.size()):
		var payload: Dictionary = payloads[payload_index]
		var enemy_id: String = str(payload.get("enemy_id", ""))
		var enemy_index: int = int(payload.get("enemy_index", -1))
		var visual: Dictionary = _enemy_visual_for_index(enemy_index)
		if visual.is_empty():
			visual = enemy_visuals_by_id.get(enemy_id, {})
		var art := visual.get("art") as Control
		if art == null or not is_instance_valid(art):
			continue
		_play_enemy_stage_action(art, str(payload.get("intent_type", "none")), float(payload_index) * 0.055)

func _play_enemy_stage_action(art: Control, intent_type: String, delay: float) -> void:
	var motion: Dictionary = _begin_stage_actor_motion(art)
	var base_position: Vector2 = motion.get("position", art.position)
	var base_scale: Vector2 = motion.get("scale", art.scale)
	var base_rotation: float = float(motion.get("rotation", art.rotation))
	art.pivot_offset = art.size * 0.5
	var tween := create_tween().bind_node(art)
	art.set_meta("stage_motion_tween", tween)
	if delay > 0.0:
		tween.tween_interval(delay)
	if _intent_projects_to_player(intent_type):
		tween.tween_property(art, "position", base_position + Vector2(-30.0, -2.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale * 1.045, 0.10)
		tween.parallel().tween_property(art, "rotation", base_rotation - 0.022, 0.10)
		tween.tween_property(art, "position", base_position, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale, 0.17)
		tween.parallel().tween_property(art, "rotation", base_rotation, 0.17)
	else:
		tween.tween_property(art, "position", base_position + Vector2(0.0, -7.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale * 1.035, 0.12)
		tween.tween_property(art, "position", base_position, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(art, "scale", base_scale, 0.18)
	tween.tween_callback(Callable(self, "_finish_stage_actor_motion").bind(art, true))

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
	var density: float = float(ForgeMotionScript.resolve_policy(user_settings).get("particle_density", 1.0))
	if density <= 0.0:
		return 0
	var profile_data: Dictionary = _vfx_profile(profile)
	var configured_count: int = int(profile_data.get("particle_count", 0))
	if configured_count > 0:
		return int(round(float(configured_count) * density))
	match profile:
		"attack_slash":
			return int(round(7.0 * density))
		"skill_guard":
			return int(round(8.0 * density))
		"power_pulse":
			return int(round(10.0 * density))
		_:
			return int(round(4.0 * density))

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
	if float(ForgeMotionScript.resolve_policy(user_settings).get("particle_density", 1.0)) <= 0.0:
		return
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

func _card_drag_target_style(color: Color, valid: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.08 if valid else 0.035)
	style.border_color = Color(color.r, color.g, color.b, 0.94 if valid else 0.54)
	style.set_border_width_all(3 if valid else 2)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(color.r, color.g, color.b, 0.28 if valid else 0.12)
	style.shadow_size = 7 if valid else 3
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
	var rays: int = _impact_ray_count(event)
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
	if str(event.get("type", "")) == "phase":
		var boss_profile: Dictionary = _boss_phase_profile(str(event.get("target_id", "")), int(event.get("amount", 0)))
		if not boss_profile.is_empty():
			return _vfx_profile_color(boss_profile)
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

func _impact_ray_count(event: Dictionary) -> int:
	var event_type: String = str(event.get("type", ""))
	var profile_data: Dictionary = _vfx_profile(_feedback_vfx_profile(event_type))
	if event_type == "phase":
		var boss_profile: Dictionary = _boss_phase_profile(str(event.get("target_id", "")), int(event.get("amount", 0)))
		if not boss_profile.is_empty():
			return int(boss_profile.get("ray_count", profile_data.get("ray_count", 12)))
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

func _play_phase_character_animation(target_id: String, phase_index: int = 0) -> void:
	last_phase_animation_target_id = target_id
	if target_id.is_empty() or DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var visual: Dictionary = enemy_visuals_by_id.get(target_id, {})
	if visual.is_empty():
		return
	var art := visual.get("art") as Control
	var button := visual.get("button") as Control
	var boss_profile: Dictionary = _boss_phase_profile(target_id, phase_index)
	var phase_color: Color = _vfx_profile_color(boss_profile) if not boss_profile.is_empty() else Color(0.92, 0.58, 1.0, 1.0)
	var phase_scale: float = float(boss_profile.get("scale", 1.16)) if not boss_profile.is_empty() else 1.16
	var phase_duration: float = float(boss_profile.get("duration", 0.32)) if not boss_profile.is_empty() else 0.32
	if art != null:
		art.pivot_offset = art.size * 0.5
		var base_art_scale: Vector2 = art.scale
		var art_tween := create_tween().bind_node(art).set_ignore_time_scale(true)
		art.scale = base_art_scale * phase_scale
		art.modulate = phase_color
		art_tween.tween_property(art, "scale", base_art_scale, phase_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		art_tween.parallel().tween_property(art, "modulate", Color.WHITE, phase_duration)
	if button != null:
		button.pivot_offset = button.size * 0.5
		var base_button_scale: Vector2 = button.scale
		var button_tween := create_tween().bind_node(button).set_ignore_time_scale(true)
		button.scale = base_button_scale * 1.08
		button_tween.tween_property(button, "scale", base_button_scale, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _boss_phase_profile(target_id: String, phase_index: int) -> Dictionary:
	var profiles: Dictionary = vfx_data.get("boss_phase_profiles", {})
	var enemy_profile: Variant = profiles.get(target_id, {})
	if enemy_profile is Array:
		var entries: Array = enemy_profile
		if phase_index >= 0 and phase_index < entries.size() and entries[phase_index] is Dictionary:
			return entries[phase_index]
	if enemy_profile is Dictionary:
		var profile_dict: Dictionary = enemy_profile
		var phases: Array = profile_dict.get("phases", [])
		if phase_index >= 0 and phase_index < phases.size() and phases[phase_index] is Dictionary:
			return phases[phase_index]
	return {}

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
		"block_absorb", "enemy_block_absorb":
			return "格挡 %d" % amount
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
		"block":
			return Color(0.48, 0.90, 1.0)
		"success":
			return Color(0.48, 1.0, 0.58)
		"phase":
			return Color(0.95, 0.62, 1.0)
		_:
			return Color(0.70, 0.88, 1.0)

func _feedback_target_position(event: Dictionary) -> Vector2:
	var target_id: String = str(event.get("target_id", ""))
	if target_id == "player":
		return _control_center(_player_combat_target_control())
	var control := _enemy_combat_target_control(target_id, -1)
	if control != null:
		return _control_center(control)
	if feedback_label != null:
		return _control_center(feedback_label)
	return Vector2.ZERO

func _player_combat_target_control() -> Control:
	if _is_pc_layout() and player_stage_art != null and player_stage_art.visible:
		return player_stage_art
	if character_panel != null and character_panel.visible:
		return character_panel
	if player_portrait != null and player_portrait.visible:
		return player_portrait
	return status_label

func _enemy_combat_target_control(target_id: String, target_index: int = -1) -> Control:
	var visual: Dictionary = {}
	if target_index >= 0:
		visual = _enemy_visual_for_index(target_index)
	if visual.is_empty():
		visual = enemy_visuals_by_id.get(target_id, {})
	if visual.is_empty():
		return null
	var art_value: Variant = visual.get("art", null)
	var art: Control = null
	if is_instance_valid(art_value):
		art = art_value as Control
	if art != null and art.visible:
		return art
	var button_value: Variant = visual.get("button", null)
	if is_instance_valid(button_value):
		return button_value as Control
	return null

func _control_rect_in_layer(control: Control, layer: Control) -> Rect2:
	if control == null or layer == null or not is_instance_valid(control) or not is_instance_valid(layer):
		return Rect2()
	var rect: Rect2 = control.get_global_rect()
	var layer_transform: Transform2D = layer.get_global_transform_with_canvas()
	var local_position: Vector2 = layer_transform.affine_inverse() * rect.position
	var local_end: Vector2 = layer_transform.affine_inverse() * rect.end
	return Rect2(local_position, local_end - local_position)

func _control_center_in_layer(control: Control, layer: Control) -> Vector2:
	var rect := _control_rect_in_layer(control, layer)
	return rect.position + rect.size * 0.5

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
	var safe_top := 8.0
	if feedback_overlay == null:
		return safe_top
	var overlay_transform: Transform2D = feedback_overlay.get_global_transform_with_canvas()
	if status_label == null or not status_label.visible:
		if combat_hud_row != null and combat_hud_row.visible:
			var hud_rect: Rect2 = combat_hud_row.get_global_rect()
			var hud_bottom: Vector2 = overlay_transform.affine_inverse() * Vector2(hud_rect.position.x, hud_rect.end.y)
			return max(safe_top, hud_bottom.y + 6.0)
		return safe_top
	var rect: Rect2 = status_label.get_global_rect()
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
			return clamp(0.024 + float(int(event.get("amount", 0))) * 0.0010, 0.028, 0.060)
		"block_absorb", "enemy_block_absorb":
			return clamp(0.012 + float(int(event.get("amount", 0))) * 0.0005, 0.014, 0.026)
		"enemy_defeated":
			return 0.070
		"phase":
			var phase_profile: Dictionary = _boss_phase_profile(str(event.get("target_id", "")), int(event.get("amount", 0)))
			return float(phase_profile.get("hit_stop", 0.085))
		"won", "lost":
			return 0.095
		_:
			return 0.0

func _feedback_shake_intensity(event: Dictionary) -> float:
	match str(event.get("type", "")):
		"enemy_hit":
			return clamp(2.0 + float(int(event.get("amount", 0))) * 0.16, 2.0, 7.0)
		"player_hit":
			return clamp(4.0 + float(int(event.get("amount", 0))) * 0.22, 4.0, 11.0)
		"block_absorb", "enemy_block_absorb":
			return clamp(0.8 + float(int(event.get("amount", 0))) * 0.06, 0.8, 2.4)
		"enemy_defeated":
			return 7.0
		"phase":
			var phase_profile: Dictionary = _boss_phase_profile(str(event.get("target_id", "")), int(event.get("amount", 0)))
			return float(phase_profile.get("shake", 10.0))
		"won", "lost":
			return 12.0
		_:
			return 0.0

func _feedback_shake_duration(event: Dictionary) -> float:
	return 0.30 if _is_strong_feedback(str(event.get("type", ""))) else 0.18

func _request_hit_stop(duration: float) -> void:
	if not _setting_enabled("hit_stop_enabled", true):
		return
	last_hit_stop_request_count += 1
	last_hit_stop_duration = max(last_hit_stop_duration, duration)
	last_hit_stop_scope = "battle_stage"
	if not is_inside_tree():
		return
	if enemy_stage_stack == null or not is_instance_valid(enemy_stage_stack):
		return
	var requested_deadline: int = Time.get_ticks_msec() + int(ceil(max(0.0, duration) * 1000.0))
	hit_stop_deadline_msec = max(hit_stop_deadline_msec, requested_deadline)
	if not hit_stop_active:
		hit_stop_restore_process_mode = enemy_stage_stack.process_mode
		hit_stop_active = true
		hit_stop_ticket += 1
		enemy_stage_stack.process_mode = Node.PROCESS_MODE_DISABLED
		_play_hit_stop(hit_stop_ticket)

func _play_hit_stop(ticket: int) -> void:
	while hit_stop_active and ticket == hit_stop_ticket:
		var remaining_msec: int = hit_stop_deadline_msec - Time.get_ticks_msec()
		if remaining_msec <= 0:
			break
		await get_tree().create_timer(float(remaining_msec) / 1000.0, true, false, true).timeout
	if ticket == hit_stop_ticket:
		_restore_battle_stage_processing()

func _restore_battle_stage_processing() -> void:
	if hit_stop_active and enemy_stage_stack != null and is_instance_valid(enemy_stage_stack):
		enemy_stage_stack.process_mode = hit_stop_restore_process_mode as Node.ProcessMode
	hit_stop_active = false
	hit_stop_deadline_msec = 0
	hit_stop_ticket += 1

func _request_screen_shake(intensity: float, duration: float) -> void:
	if not _setting_enabled("screen_shake_enabled", true):
		return
	if not bool(ForgeMotionScript.resolve_policy(user_settings).get("allows_translation", true)):
		return
	last_screen_shake_intensity = max(last_screen_shake_intensity, intensity)
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or root_box == null:
		return
	var base_position: Vector2 = root_box.position
	if root_box.has_meta("screen_shake_origin"):
		base_position = root_box.get_meta("screen_shake_origin") as Vector2
	if screen_shake_tween != null and screen_shake_tween.is_valid():
		screen_shake_tween.kill()
		root_box.position = base_position
	root_box.set_meta("screen_shake_origin", base_position)
	var step: float = duration / 4.0
	screen_shake_tween = create_tween()
	screen_shake_tween.tween_property(root_box, "position", base_position + Vector2(intensity, -intensity * 0.45), step)
	screen_shake_tween.tween_property(root_box, "position", base_position + Vector2(-intensity * 0.80, intensity * 0.55), step)
	screen_shake_tween.tween_property(root_box, "position", base_position + Vector2(intensity * 0.35, intensity * 0.35), step)
	screen_shake_tween.tween_property(root_box, "position", base_position, step)
	screen_shake_tween.tween_callback(Callable(root_box, "remove_meta").bind("screen_shake_origin"))

func _primary_feedback_event(events: Array) -> Dictionary:
	var priority := {
		"lost": 100,
		"won": 95,
		"phase": 90,
		"enemy_defeated": 80,
		"player_hit": 70,
		"block_absorb": 65,
		"enemy_hit": 60,
		"enemy_block_absorb": 58,
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
	last_reward_gold_panel_count = 0
	last_reward_action_button_count = 0
	last_reward_action_icon_node_count = 0
	last_mastery_reward_option_count = 0
	last_mastery_reward_pending = false
	last_defeat_panel_visible = false
	last_defeat_art_path = ""
	last_defeat_art_loaded = false
	last_defeat_scene_enemy_count = 0
	last_defeat_stat_chip_count = 0
	last_defeat_action_count = 0
	last_defeat_forge_marks_earned = 0
	last_defeat_summary = ""
	last_defeat_reveal_animation_count = 0
	_clear_container(reward_row)
	if combat.phase == "lost":
		if _is_pc_layout():
			_apply_pc_defeat_layout_constraints()
			_mount_defeat_outcome_page()
			return
		var lost_label := Label.new()
		lost_label.text = "战败。点击“重开跑团”重新开始。"
		lost_label.add_theme_font_size_override("font_size", 18)
		reward_row.add_child(lost_label)
		var export_button := Button.new()
		export_button.custom_minimum_size = Vector2(176, 42)
		export_button.text = "导出试玩报告"
		export_button.icon = _load_texture(UI_EXPORT_REPORT_ICON_PATH)
		export_button.expand_icon = true
		export_button.tooltip_text = "导出本机匿名逐局数据，文件路径会复制到剪贴板。"
		_apply_button_skin(export_button, "event", "reward")
		export_button.pressed.connect(_on_export_playtest_report_pressed)
		reward_row.add_child(export_button)
		return
	if combat.phase != "won":
		return

	var node: Dictionary = _current_node()
	var encounter_id: String = str(node.get("encounter_id", ""))
	var reward_key: String = _combat_reward_key(node, encounter_id)
	if reward_generated_for != reward_key:
		var encounter: Dictionary = _encounter_by_id(encounter_id)
		combat_reward_gold = _grant_encounter_gold(encounter_id, reward_key)
		var card_reward_count: int = max(0, int(encounter.get("card_reward_count", 3)))
		reward_options = _generate_card_rewards(card_reward_count) if card_reward_count > 0 else []
		if bool(encounter.get("relic_reward", false)):
			relic_reward_options = _generate_relic_rewards(3)
			relic_reward_done = relic_reward_options.is_empty()
		else:
			relic_reward_options.clear()
			relic_reward_done = true
		if card_reward_count > 0 and _has_empty_potion_slot() and _should_offer_potion_reward(reward_key):
			potion_reward_options = _generate_potion_rewards(_potion_reward_count())
			potion_reward_done = potion_reward_options.is_empty()
		else:
			potion_reward_options.clear()
			potion_reward_done = true
		_record_playtest_card_offers(reward_options, "combat_reward")
		var discovery_changed: bool = _record_discovered_item_array("cards", reward_options)
		discovery_changed = _record_discovered_item_array("relics", relic_reward_options) or discovery_changed
		discovery_changed = _record_discovered_item_array("potions", potion_reward_options) or discovery_changed
		if discovery_changed:
			_save_player_profile()
		card_reward_done = reward_options.is_empty()
		reward_generated_for = reward_key
	last_combat_gold_reward = combat_reward_gold
	if _is_pc_layout():
		reward_scroll.visible = false
		reward_row.visible = false
		_mount_reward_page(_combat_reward_page_model())
		_record_layout_metrics()
		return

	var action_column: VBoxContainer = null
	var action_target: Container = action_column if action_column != null else reward_row

	if not _is_pc_layout():
		var label := Label.new()
		label.text = "战斗胜利，领取奖励："
		label.custom_minimum_size = Vector2(180, 0)
		reward_row.add_child(label)

	if combat_reward_gold > 0:
		_add_combat_gold_reward_panel(combat_reward_gold)

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

		action_target.add_child(_add_reward_action_button(
			"跳过卡牌",
			"保持牌组精简",
			"不拿本次卡牌奖励。",
			UI_SKIP_REWARD_ICON_PATH,
			"neutral",
			false,
			Callable(self, "_on_skip_card_reward_pressed"),
			action_column != null
		))
	elif not _is_pc_layout():
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
	elif not relic_reward_options.is_empty() and not _is_pc_layout():
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

		action_target.add_child(_add_reward_action_button(
			"跳过药水",
			"保留药水槽",
			"不拿本次药水奖励。",
			UI_SKIP_REWARD_ICON_PATH,
			"neutral",
			false,
			Callable(self, "_on_skip_potion_reward_pressed"),
			action_column != null
		))
	elif not potion_reward_options.is_empty() and not _is_pc_layout():
		var potion_done_label := Label.new()
		potion_done_label.text = "药水奖励已处理。"
		potion_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(potion_done_label)

	var standard_rewards_done: bool = card_reward_done and relic_reward_done and potion_reward_done
	var mastery_options: Array = _eligible_deck_masteries() if standard_rewards_done and _mastery_reward_is_available() else []
	last_mastery_reward_pending = not mastery_options.is_empty()
	if last_mastery_reward_pending:
		_add_mastery_reward_summary_panel(mastery_options.size())
		for mastery_value in mastery_options:
			var mastery: Dictionary = mastery_value
			var mastery_id: String = str(mastery.get("id", ""))
			var mastery_button := Button.new()
			mastery_button.custom_minimum_size = _mastery_reward_button_size()
			mastery_button.text = ""
			mastery_button.tooltip_text = "%s\n%s\n条件：%s" % [
				str(mastery.get("name", mastery_id)),
				str(mastery.get("description", "")),
				_mastery_requirement_text(mastery)
			]
			_apply_button_skin(mastery_button, "relic", "reward")
			_add_icon_item_layout(
				mastery_button,
				str(mastery.get("name", mastery_id)),
				"卡组锻造专精",
				str(mastery.get("description", "")),
				_load_texture(_mastery_icon_path(mastery_id)),
				"relic",
				"mastery_reward",
				false
			)
			mastery_button.pressed.connect(_on_deck_mastery_pressed.bind(mastery_id))
			reward_row.add_child(mastery_button)
			last_mastery_reward_option_count += 1

	var can_continue: bool = standard_rewards_done and not last_mastery_reward_pending
	action_target.add_child(_add_reward_action_button(
		"保存进度",
		"可从奖励页继续",
		"保存当前奖励选项和已处理状态。",
		UI_SAVE_RUN_ICON_PATH,
		"event",
		false,
		Callable(self, "_on_save_pressed"),
		action_column != null
	))
	action_target.add_child(_add_reward_action_button(
		"继续路线",
		"进入下个节点" if can_continue else ("选择一项卡组专精" if last_mastery_reward_pending else "等待奖励处理"),
		"完成所有奖励和卡组专精选择后继续推进路线。",
		UI_CONTINUE_ROUTE_ICON_PATH,
		"primary",
		not can_continue,
		Callable(self, "_advance_to_next_node"),
		action_column != null
	))
	if action_column != null:
		reward_row.add_child(action_column)

func _reward_item_models(items: Array, kind: String) -> Array:
	var models: Array = []
	for item_value in items:
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		var art_path := ""
		if kind == "card":
			art_path = _card_art_path(item)
		elif kind == "relic":
			art_path = _relic_icon_path(item)
		elif kind == "potion":
			art_path = _potion_icon_path(item)
		elif kind == "mastery":
			art_path = _mastery_icon_path(str(item.get("id", "")))
		var model := {
			"id": str(item.get("id", "")),
			"name": str(item.get("name", item.get("id", "奖励"))),
			"description": str(item.get("description", "")),
			"art_path": art_path
		}
		if kind == "card":
			model["cost"] = int(item.get("cost", 0))
			model["type"] = str(item.get("type", ""))
			model["rarity"] = str(item.get("rarity", "common"))
		models.append(model)
	return models

func _combat_reward_page_model() -> Dictionary:
	var standard_done := card_reward_done and relic_reward_done and potion_reward_done
	var mastery_options: Array = _eligible_deck_masteries() if standard_done and _mastery_reward_is_available() else []
	var can_continue := standard_done and mastery_options.is_empty()
	last_reward_card_layout_count = reward_options.size()
	last_reward_card_art_node_count = reward_options.size()
	last_reward_potion_layout_count = potion_reward_options.size()
	last_reward_potion_icon_node_count = potion_reward_options.size()
	last_reward_relic_layout_count = relic_reward_options.size()
	last_reward_relic_icon_node_count = relic_reward_options.size()
	last_reward_gold_panel_count = 1 if combat_reward_gold > 0 else 0
	last_mastery_reward_option_count = mastery_options.size()
	last_mastery_reward_pending = not mastery_options.is_empty()
	last_reward_action_button_count = (0 if card_reward_done else 1) + (0 if potion_reward_done else 1) + 2
	last_reward_action_icon_node_count = last_reward_action_button_count
	last_reward_button_style_count = last_reward_card_layout_count + last_reward_relic_layout_count + last_reward_potion_layout_count + last_reward_action_button_count
	if not reward_options.is_empty():
		last_reward_card_art_path = _card_art_path(reward_options[0])
		last_reward_card_art_loaded = _asset_loaded(last_reward_card_art_path)
	if not relic_reward_options.is_empty():
		last_relic_icon_path = _relic_icon_path(relic_reward_options[0])
		last_relic_icon_loaded = _asset_loaded(last_relic_icon_path)
	if not potion_reward_options.is_empty():
		last_potion_icon_path = _potion_icon_path(potion_reward_options[0])
		last_potion_icon_loaded = _asset_loaded(last_potion_icon_path)
	return {
		"mode": "combat",
		"gold": combat_reward_gold,
		"cards": _reward_item_models(reward_options, "card"),
		"relics": _reward_item_models(relic_reward_options, "relic"),
		"potions": _reward_item_models(potion_reward_options, "potion"),
		"card_done": card_reward_done,
		"relic_done": relic_reward_done,
		"potion_done": potion_reward_done,
		"masteries": _reward_item_models(mastery_options, "mastery"),
		"can_continue": can_continue,
		"continue_reason": "选择一项卡组专精" if not mastery_options.is_empty() else ("等待奖励处理" if not standard_done else "进入下个节点")
	}

func _treasure_reward_page_model() -> Dictionary:
	last_treasure_relic_layout_count = relic_reward_options.size()
	last_treasure_relic_icon_node_count = relic_reward_options.size()
	last_reward_card_layout_count = 0
	last_reward_card_art_node_count = 0
	last_reward_potion_layout_count = 0
	last_reward_potion_icon_node_count = 0
	last_reward_relic_layout_count = relic_reward_options.size()
	last_reward_relic_icon_node_count = relic_reward_options.size()
	last_reward_gold_panel_count = 1 if treasure_reward_gold > 0 else 0
	last_reward_action_button_count = 1
	last_reward_action_icon_node_count = 1
	last_reward_button_style_count = relic_reward_options.size() + 1
	if not relic_reward_options.is_empty():
		last_relic_icon_path = _relic_icon_path(relic_reward_options[0])
		last_relic_icon_loaded = _asset_loaded(last_relic_icon_path)
	return {
		"mode": "treasure",
		"gold": treasure_reward_gold,
		"cards": [],
		"relics": _reward_item_models(relic_reward_options, "relic"),
		"potions": [],
		"relic_done": relic_reward_done,
		"can_continue": true,
		"continue_reason": "领取金币并继续"
	}

func _reward_option_by_id(options: Array, item_id: String) -> Dictionary:
	for option_value in options:
		var option: Dictionary = option_value
		if str(option.get("id", "")) == item_id:
			return option
	return {}

func _warn_rejected_reward_action(action: String, item_id: String = "") -> void:
	var suffix := "" if item_id.is_empty() else " id '%s'" % item_id
	push_warning("RewardPage: rejected %s%s" % [action, suffix])

func _on_reward_page_claim_card(item_id: String) -> void:
	if combat == null or combat.phase != "won" or card_reward_done or _reward_option_by_id(reward_options, item_id).is_empty():
		_warn_rejected_reward_action("card", item_id)
		return
	_on_reward_card_pressed(item_id)

func _on_reward_page_claim_relic(item_id: String) -> void:
	if combat == null or combat.phase != "won" or relic_reward_done or run_relic_ids.has(item_id) or _reward_option_by_id(relic_reward_options, item_id).is_empty():
		_warn_rejected_reward_action("relic", item_id)
		return
	_on_reward_relic_pressed(item_id)

func _on_reward_page_claim_potion(item_id: String) -> void:
	if combat == null or combat.phase != "won" or potion_reward_done or not _has_empty_potion_slot() or _reward_option_by_id(potion_reward_options, item_id).is_empty():
		_warn_rejected_reward_action("potion", item_id)
		return
	_on_reward_potion_pressed(item_id)

func _on_reward_page_claim_mastery(mastery_id: String) -> void:
	var standard_done := card_reward_done and relic_reward_done and potion_reward_done
	if combat == null or combat.phase != "won" or not standard_done or not run_deck_mastery_id.is_empty() or _reward_option_by_id(_eligible_deck_masteries(), mastery_id).is_empty():
		_warn_rejected_reward_action("mastery", mastery_id)
		return
	_on_deck_mastery_pressed(mastery_id)

func _combat_reward_can_continue() -> bool:
	if combat == null or combat.phase != "won" or not (card_reward_done and relic_reward_done and potion_reward_done):
		return false
	return not (_mastery_reward_is_available() and not _eligible_deck_masteries().is_empty())

func _on_reward_page_continue_requested() -> void:
	if not _combat_reward_can_continue():
		_warn_rejected_reward_action("continue")
		return
	_advance_to_next_node()

func _on_reward_page_treasure_relic(item_id: String) -> void:
	if current_node_id.is_empty() or str(_current_node().get("type", "")) != "treasure" or relic_reward_done or run_relic_ids.has(item_id) or _reward_option_by_id(relic_reward_options, item_id).is_empty():
		_warn_rejected_reward_action("treasure relic", item_id)
		return
	_on_treasure_relic_pressed(item_id)

func _on_reward_page_treasure_continue() -> void:
	if current_node_id.is_empty() or str(_current_node().get("type", "")) != "treasure":
		_warn_rejected_reward_action("treasure continue")
		return
	_on_treasure_continue_pressed()

func _mount_reward_page(model: Dictionary) -> void:
	var page = RewardPageScript.new()
	page.configure(model)
	var is_combat_reward := str(model.get("mode", "")) == "combat"
	page.claim_card.connect(_on_reward_page_claim_card)
	page.claim_relic.connect(_on_reward_page_claim_relic if is_combat_reward else _on_reward_page_treasure_relic)
	page.claim_potion.connect(_on_reward_page_claim_potion)
	page.skip_card_requested.connect(_on_skip_card_reward_pressed)
	page.skip_potion_requested.connect(_on_skip_potion_reward_pressed)
	page.save_requested.connect(_on_save_pressed)
	page.claim_mastery.connect(_on_reward_page_claim_mastery)
	if is_combat_reward:
		page.continue_requested.connect(_on_reward_page_continue_requested)
	else:
		page.continue_requested.connect(_on_reward_page_treasure_continue)
	app_shell.mount_page(page, "reward")

func _mount_defeat_outcome_page() -> void:
	var outcome: Dictionary = _defeat_outcome_data()
	last_defeat_forge_marks_earned = int(outcome.get("forge_marks_earned", 0))
	last_defeat_summary = "%s / %s / 回合 %d | 路线 %d/%d | 金币 %d | 牌组 %d | 遗物 %d | 挑战 %d | 炉印 +%d（总计 %d）" % [
		str(outcome.get("chapter_name", "未知章节")),
		str(outcome.get("encounter_name", "未知遭遇")),
		int(outcome.get("turn", 0)),
		int(outcome.get("route_step", 0)),
		int(outcome.get("route_total", 0)),
		int(outcome.get("gold", 0)),
		int(outcome.get("deck_size", 0)),
		int(outcome.get("relic_count", 0)),
		int(outcome.get("challenge_level", 0)),
		last_defeat_forge_marks_earned,
		int(outcome.get("forge_marks_total", 0))
	]
	last_defeat_panel_visible = true
	last_defeat_art_path = _battle_background_path(current_chapter_id)
	last_defeat_art_loaded = _asset_loaded(last_defeat_art_path)
	var survivors := _defeat_surviving_enemies()
	last_defeat_scene_enemy_count = min(3, survivors.size())
	last_defeat_stat_chip_count = 6
	last_defeat_action_count = 4 + (1 if not last_terminal_persistence_error.is_empty() else 0)
	last_defeat_reveal_animation_count = 1 + last_defeat_action_count
	var model := {
		"mode": "defeat",
		"title": "%s止步于%s" % [_character_display_name(), str(outcome.get("chapter_name", "未知章节"))],
		"subtitle": last_terminal_persistence_error if not last_terminal_persistence_error.is_empty() else "本次跑团已归档。已击败 Boss 的炉印和永久进度会保留。",
		"chapter_id": current_chapter_id,
		"character_id": selected_character_id,
		"art_path": last_defeat_art_path,
		"player_art_path": _character_stage_art_path(),
		"surviving_enemies": survivors,
		"stats": {
			"hp": 0,
			"max_hp": run_max_hp,
			"gold": int(outcome.get("gold", 0)),
			"deck_size": int(outcome.get("deck_size", 0)),
			"relic_count": int(outcome.get("relic_count", 0)),
			"potion_count": int(outcome.get("potion_count", 0))
		},
		"stat_entries": [
			["回合", "%d" % int(outcome.get("turn", 0))],
			["路线", "%d/%d" % [int(outcome.get("route_step", 0)), int(outcome.get("route_total", 0))]],
			["金币", "%d" % int(outcome.get("gold", 0))],
			["牌组", "%d 张" % int(outcome.get("deck_size", 0))],
			["遗物", "%d" % int(outcome.get("relic_count", 0))],
			["挑战", "%d" % int(outcome.get("challenge_level", 0))]
		],
		"unlocks": ["炉印 +%d（总计 %d）" % [last_defeat_forge_marks_earned, int(outcome.get("forge_marks_total", 0))]],
		"persistence_error": last_terminal_persistence_error
	}
	_mount_outcome_pages(model)

func _add_mastery_reward_summary_panel(eligible_count: int) -> void:
	var summary: Dictionary = _deck_summary()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(270, 154)
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _button_style(Color(0.16, 0.13, 0.08), Color(0.92, 0.64, 0.28), 2, 6))
	reward_row.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 7)
	box.add_child(title_row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.texture = _load_texture(UI_DECK_ICON_PATH)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_row.add_child(icon)
	var title := Label.new()
	title.text = "卡组锻造"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58))
	title_row.add_child(title)
	var stats := Label.new()
	stats.text = "攻击 %d  ·  技能 %d  ·  能力 %d\n0 费 %d  ·  灼伤源 %d" % [
		int(summary.get("attack", 0)),
		int(summary.get("skill", 0)),
		int(summary.get("power", 0)),
		_deck_zero_cost_count(),
		_deck_burn_creator_count()
	]
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.88, 0.86, 0.78))
	box.add_child(stats)
	var footer := Label.new()
	footer.text = "%d 项学派满足当前构筑" % eligible_count
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", Color(0.96, 0.68, 0.32))
	box.add_child(footer)

func _combat_reward_key(node: Dictionary, encounter_id: String) -> String:
	var node_id: String = str(node.get("id", ""))
	if node_id.is_empty():
		node_id = "index_%d" % current_node_index
	return "%s:%s" % [node_id, encounter_id]

func _add_combat_gold_reward_panel(amount: int) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = _large_item_button_size()
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _button_style(Color(0.18, 0.125, 0.045), Color(0.96, 0.70, 0.22), 2, 6))
	reward_row.add_child(panel)
	last_reward_gold_panel_count += 1

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var title := Label.new()
	title.text = "战利品"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50))
	box.add_child(title)

	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(0, 48)
	box.add_child(icon_center)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(_hud_icon_path("金币"))
	icon_center.add_child(icon)

	var amount_label := Label.new()
	amount_label.text = "+%d 金币" % amount
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 15)
	amount_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72))
	box.add_child(amount_label)

	var note := Label.new()
	note.text = "已加入钱袋"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.84, 0.76, 0.58))
	box.add_child(note)

func _on_enemy_pressed(index: int) -> void:
	selected_enemy_index = index
	_refresh()

func _on_combat_changed() -> void:
	selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_card_pressed(index: int) -> void:
	if combat_presentation_busy or combat == null or combat.phase != "player":
		return
	var target_index: int = _normalize_selected_enemy()
	if index < 0 or index >= combat.hand.size() or not combat.can_play_card(index):
		return
	var card: Dictionary = combat.hand[index]
	var payload: Dictionary = _build_card_visual_payload(index, card, target_index)
	_run_card_presentation(index, target_index, str(card.get("id", "")), payload)

func _on_end_turn_pressed() -> void:
	if combat_presentation_busy or combat == null or combat.phase != "player":
		return
	var action_payloads: Array[Dictionary] = combat.prepare_enemy_turn()
	_run_enemy_turn_presentation(action_payloads)

func _run_card_presentation(index: int, target_index: int, card_id: String, payload: Dictionary) -> void:
	var ticket := _begin_combat_presentation("card:lock")
	combat_presentation_sequence.append("card:windup")
	_request_card_play_visual(payload)
	_play_player_card_action(payload)
	if not _combat_presentation_is_instant():
		await get_tree().create_timer(0.20).timeout
	if not _combat_presentation_ticket_valid(ticket):
		return
	combat_presentation_sequence.append("card:impact")
	var active_run := _playtest_active_run()
	if not active_run.is_empty():
		PlaytestTelemetryScript.record_card_played(active_run, card_id)
		playtest_store["active_run"] = active_run
	var played: bool = combat.play_card(index, target_index)
	combat_presentation_sequence.append("card:resolved" if played else "card:rejected")
	if not _combat_presentation_is_instant():
		await get_tree().create_timer(0.16).timeout
	_end_combat_presentation(ticket, "card:unlock")

func _run_enemy_turn_presentation(action_payloads: Array[Dictionary]) -> void:
	var ticket := _begin_combat_presentation("enemy:lock")
	combat_presentation_sequence.append("enemy:windup")
	_audio_event("turn_end")
	_play_enemy_action_visuals(action_payloads)
	if not _combat_presentation_is_instant():
		await get_tree().create_timer(0.14).timeout
	if not _combat_presentation_ticket_valid(ticket):
		return
	combat_presentation_sequence.append("enemy:impact")
	combat.resolve_prepared_enemy_turn()
	combat_presentation_sequence.append("enemy:resolved")
	_checkpoint_playtest_store()
	if not _combat_presentation_is_instant():
		await get_tree().create_timer(0.20).timeout
	_end_combat_presentation(ticket, "enemy:unlock")

func _begin_combat_presentation(checkpoint: String) -> int:
	_cancel_card_drag()
	combat_presentation_ticket += 1
	combat_presentation_busy = true
	combat_presentation_sequence.clear()
	combat_presentation_sequence.append(checkpoint)
	_apply_combat_presentation_input_state()
	return combat_presentation_ticket

func _end_combat_presentation(ticket: int, checkpoint: String) -> void:
	if not _combat_presentation_ticket_valid(ticket):
		return
	combat_presentation_sequence.append(checkpoint)
	combat_presentation_busy = false
	_apply_combat_presentation_input_state()

func _combat_presentation_ticket_valid(ticket: int) -> bool:
	return combat_presentation_busy and ticket == combat_presentation_ticket and combat != null

func _combat_presentation_is_instant() -> bool:
	return combat_presentation_instant_override or DisplayServer.get_name() == "headless" or not is_inside_tree()

func _apply_combat_presentation_input_state() -> void:
	if end_turn_button != null:
		end_turn_button.disabled = combat_presentation_busy or combat == null or combat.phase != "player"
	for button_value in hand_buttons_by_index.values():
		var button := button_value as Button
		if button != null:
			var hand_index: int = int(button.get_meta("hand_index", -1))
			button.disabled = combat_presentation_busy or combat == null or not combat.can_play_card(hand_index)
	if potion_row != null:
		for child in potion_row.get_children():
			if child is Button:
				(child as Button).disabled = combat_presentation_busy or combat == null or combat.phase != "player"

func _on_potion_pressed(slot_index: int) -> void:
	if combat_presentation_busy or combat == null or slot_index < 0 or slot_index >= run_potion_ids.size():
		return
	var potion: Dictionary = _potion_by_id(str(run_potion_ids[slot_index]))
	if potion.is_empty():
		_audio_event("error")
		return
	var changed_callable := Callable(self, "_on_combat_changed")
	var changed_was_connected: bool = combat.changed.is_connected(changed_callable)
	if changed_was_connected:
		combat.changed.disconnect(changed_callable)
	var potion_used: bool = combat.use_potion(potion, selected_enemy_index)
	if potion_used:
		run_potion_ids.remove_at(slot_index)
		var active_run := _playtest_active_run()
		if not active_run.is_empty():
			PlaytestTelemetryScript.record_potion_used(active_run, str(potion.get("id", "")))
			playtest_store["active_run"] = active_run
		_audio_event("potion")
	if changed_was_connected:
		combat.changed.connect(changed_callable)
	_on_combat_changed()

func _on_reward_card_pressed(card_id: String) -> void:
	if card_id.is_empty():
		return
	run_deck_ids.append(card_id)
	_record_playtest_card_acquired(card_id, "combat_reward")
	if _record_discovered_content("cards", card_id):
		_save_player_profile()
	_audio_event("reward")
	var card: Dictionary = _card_by_id(card_id)
	combat.log_entries.append("奖励选择：%s 加入牌组。" % card.get("name", card_id))
	card_reward_done = true
	_refresh()

func _on_skip_card_reward_pressed() -> void:
	combat.log_entries.append("跳过卡牌奖励。")
	var active_run := _playtest_active_run()
	if not active_run.is_empty():
		PlaytestTelemetryScript.record_reward_skipped(active_run, "card")
		playtest_store["active_run"] = active_run
		_checkpoint_playtest_store()
	_audio_event("ui_click")
	card_reward_done = true
	_refresh()

func _on_reward_relic_pressed(relic_id: String) -> void:
	if relic_id.is_empty():
		return
	run_relic_ids.append(relic_id)
	_record_playtest_item_acquired("relics", relic_id, "combat_reward")
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
	_record_playtest_item_acquired("potions", potion_id, "combat_reward")
	if _record_discovered_content("potions", potion_id):
		_save_player_profile()
	_audio_event("reward")
	var potion: Dictionary = _potion_by_id(potion_id)
	combat.log_entries.append("药水获得：%s。" % potion.get("name", potion_id))
	potion_reward_done = true
	_refresh()

func _on_skip_potion_reward_pressed() -> void:
	combat.log_entries.append("跳过药水奖励。")
	var active_run := _playtest_active_run()
	if not active_run.is_empty():
		PlaytestTelemetryScript.record_reward_skipped(active_run, "potion")
		playtest_store["active_run"] = active_run
		_checkpoint_playtest_store()
	_audio_event("ui_click")
	potion_reward_done = true
	_refresh()

func _on_deck_mastery_pressed(mastery_id: String) -> void:
	if not run_deck_mastery_id.is_empty():
		return
	var mastery: Dictionary = _deck_mastery_by_id(mastery_id)
	if mastery.is_empty() or not _deck_mastery_requirements_met(mastery.get("requirements", {})):
		_audio_event("error")
		return
	run_deck_mastery_id = mastery_id
	var active_run := _playtest_active_run()
	if not active_run.is_empty():
		PlaytestTelemetryScript.record_mastery_selected(active_run, mastery_id)
		playtest_store["active_run"] = active_run
		_checkpoint_playtest_store()
	_audio_event("reward")
	if combat != null:
		combat.log_entries.append("卡组专精：%s。下一场战斗起生效。" % str(mastery.get("name", mastery_id)))
	_refresh()

func _on_treasure_relic_pressed(relic_id: String) -> void:
	if relic_id.is_empty():
		_audio_event("error")
		return
	_claim_treasure_reward(relic_id)

func _on_treasure_continue_pressed() -> void:
	_claim_treasure_reward("")

func _claim_treasure_reward(relic_id: String) -> void:
	var gold_reward: int = treasure_reward_gold
	if gold_reward <= 0:
		gold_reward = _treasure_gold_amount(str(_current_node().get("id", "")))
	run_gold += gold_reward
	last_treasure_gold_reward = gold_reward
	treasure_reward_gold = 0
	if not relic_id.is_empty() and not run_relic_ids.has(relic_id):
		run_relic_ids.append(relic_id)
		_record_playtest_item_acquired("relics", relic_id, "treasure")
		if _record_discovered_content("relics", relic_id):
			_save_player_profile()
	relic_reward_done = true
	_audio_event("reward")
	_advance_to_next_node()

func _on_campfire_heal_pressed() -> void:
	var heal_percent: int = _campfire_heal_percent()
	var heal: int = max(1, int(ceil(float(run_max_hp) * float(heal_percent) / 100.0)))
	run_hp = min(run_max_hp, run_hp + heal)
	_audio_event("campfire")
	_advance_to_next_node()

func _on_campfire_forge_pressed() -> void:
	campfire_upgrade_selection_open = true
	_audio_event("ui_click")
	_refresh()

func _on_campfire_forge_back_pressed() -> void:
	campfire_upgrade_selection_open = false
	_audio_event("ui_click")
	_refresh()

func _on_upgrade_card_pressed(deck_index: int) -> void:
	if deck_index < 0 or deck_index >= run_deck_ids.size():
		return
	var entry: String = str(run_deck_ids[deck_index])
	if not entry.ends_with("+"):
		run_deck_ids[deck_index] = "%s+" % entry
		var active_run := _playtest_active_run()
		if not active_run.is_empty():
			PlaytestTelemetryScript.record_card_upgraded(active_run, entry)
			playtest_store["active_run"] = active_run
	_audio_event("campfire")
	_advance_to_next_node()

func _on_shop_buy_card_pressed(card_id: String, price: int) -> void:
	if card_id.is_empty() or run_gold < price:
		_audio_event("error")
		return
	run_gold -= price
	run_deck_ids.append(card_id)
	_record_playtest_card_acquired(card_id, "shop")
	if _record_discovered_content("cards", card_id):
		_save_player_profile()
	_audio_event("shop")
	for i in range(shop_card_options.size()):
		var card: Dictionary = shop_card_options[i]
		if str(card.get("id", "")) == card_id:
			shop_card_options.remove_at(i)
			break
	_refresh()

func _on_shop_buy_relic_pressed(relic_id: String, price: int) -> void:
	if relic_id.is_empty() or run_gold < price or run_relic_ids.has(relic_id):
		_audio_event("error")
		return
	run_gold -= price
	run_relic_ids.append(relic_id)
	_record_playtest_item_acquired("relics", relic_id, "shop")
	if _record_discovered_content("relics", relic_id):
		_save_player_profile()
	_audio_event("shop")
	for i in range(shop_relic_options.size()):
		var relic: Dictionary = shop_relic_options[i]
		if str(relic.get("id", "")) == relic_id:
			shop_relic_options.remove_at(i)
			break
	_refresh()

func _on_shop_buy_potion_pressed(potion_id: String, price: int) -> void:
	if potion_id.is_empty() or run_gold < price or not _has_empty_potion_slot():
		_audio_event("error")
		return
	run_gold -= price
	run_potion_ids.append(potion_id)
	_record_playtest_item_acquired("potions", potion_id, "shop")
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
	if run_gold < remove_price or _shop_removable_card_indices().is_empty():
		_audio_event("error")
		return
	shop_remove_selection_open = true
	_audio_event("ui_click")
	_refresh()

func _on_shop_remove_card_selected(deck_index: int) -> void:
	var remove_price: int = _remove_card_price()
	if run_gold < remove_price or not _shop_removable_card_indices().has(deck_index):
		_audio_event("error")
		_refresh()
		return
	run_gold -= remove_price
	var removed_entry: String = str(run_deck_ids[deck_index])
	var removed_card: Dictionary = _deck_display_card(removed_entry)
	run_deck_ids.remove_at(deck_index)
	var active_run := _playtest_active_run()
	if not active_run.is_empty():
		PlaytestTelemetryScript.record_card_removed(active_run, removed_entry)
		playtest_store["active_run"] = active_run
		_checkpoint_playtest_store()
	run_shop_remove_count += 1
	shop_remove_selection_open = false
	_record_card_removed()
	_audio_event("shop")
	status_label.text = "已移除：%s。" % removed_card.get("name", removed_entry)
	_refresh()

func _on_shop_remove_cancel_pressed() -> void:
	shop_remove_selection_open = false
	_audio_event("ui_click")
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
		var successor_ids: Array[String] = _successor_node_ids(node_id)
		var node: Dictionary = _node_by_id(node_id)
		if map_view.has_method("set_preview_details"):
			var successor_names: Array[String] = []
			for successor_id in successor_ids:
				var successor: Dictionary = _node_by_id(successor_id)
				if successor.is_empty():
					successor_names.append(successor_id)
				else:
					successor_names.append("%s [%s]" % [
						successor.get("name", successor_id),
						_node_type_display_name(str(successor.get("type", "")))
					])
			if node.is_empty():
				map_view.set_preview_details("暂无可预览节点", "未知", "待确认", "暂无节点说明。", successor_names)
			else:
				map_view.set_preview_details(
					"%s [%s]" % [node.get("name", node_id), _node_type_display_name(str(node.get("type", "")))],
					_node_risk_summary(node),
					_node_reward_summary(node),
					_node_detail_text(node),
					successor_names
				)
		map_view.set_preview_node(node_id, successor_ids)

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
	profile_character_id = _valid_character_id(selected_character_id)
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
	if welcome_open or character_select_open or run_deck_ids.is_empty() or _run_save_blocked():
		_audio_event("error")
		return
	_checkpoint_playtest_store()
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
	var state_run_id := str(state.get("run_id", ""))
	var archived_outcome := _archived_playtest_run_outcome(state_run_id)
	if not archived_outcome.is_empty():
		last_terminal_run_id = state_run_id
		last_run_save_cleanup_ok = SaveManagerScript.delete_run_for_run_id(state_run_id)
		last_terminal_persistence_error = "" if last_run_save_cleanup_ok else "终局记录已归档，但陈旧跑团存档清理失败；请再次读取重试。"
		_audio_event("save" if last_run_save_cleanup_ok else "error")
		_refresh()
		if status_label != null:
			status_label.text = "该跑团已结束，已清理陈旧存档。" if last_run_save_cleanup_ok else last_terminal_persistence_error
			status_label.visible = true
		return
	_archive_playtest_run_replaced_by(state.get("playtest_active_run", {}))
	_load_all_data()
	selected_character_id = _valid_character_id(str(state.get("selected_character_id", _default_character_id())))
	welcome_open = false
	character_select_open = false
	deck_view_open = false
	settings_open = false
	tutorial_open = false
	profile_open = false
	compendium_open = false
	_audio_event("save")
	_cancel_card_drag()
	combat_presentation_ticket += 1
	combat_presentation_busy = false
	_restore_battle_stage_processing()
	combat = null
	var saved_combat_reward_state: Dictionary = {}
	var raw_combat_reward_state: Variant = state.get("combat_reward_state", {})
	if raw_combat_reward_state is Dictionary:
		saved_combat_reward_state = (raw_combat_reward_state as Dictionary).duplicate(true)
	run_deck_ids = state.get("run_deck_ids", []).duplicate(true)
	run_relic_ids = state.get("run_relic_ids", []).duplicate(true)
	run_potion_ids = state.get("run_potion_ids", []).duplicate(true)
	run_hp = int(state.get("run_hp", 1))
	run_max_hp = int(state.get("run_max_hp", 72))
	run_gold = int(state.get("run_gold", 0))
	run_shop_remove_count = int(state.get("run_shop_remove_count", 0))
	run_progression_node_ids = state.get("run_progression_node_ids", []).duplicate(true)
	run_character_config = state.get("run_character_config", {}).duplicate(true)
	if run_character_config.is_empty():
		run_character_config = _character_config(selected_character_id).duplicate(true)
		run_character_config["max_hp"] = run_max_hp
		run_character_config["starting_hp"] = run_max_hp
	run_skill_book_id = str(state.get("run_skill_book_id", _equipped_skill_book_for_character(selected_character_id)))
	if _skill_book_by_id(run_skill_book_id).is_empty() or not _skill_book_unlocked(_skill_book_by_id(run_skill_book_id)):
		run_skill_book_id = _equipped_skill_book_for_character(selected_character_id)
	run_deck_mastery_id = str(state.get("run_deck_mastery_id", ""))
	if not run_deck_mastery_id.is_empty() and _deck_mastery_by_id(run_deck_mastery_id).is_empty():
		run_deck_mastery_id = ""
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
	shop_relic_options.clear()
	shop_potion_options.clear()
	treasure_reward_gold = 0
	reward_generated_for = ""
	shop_generated_for = -1
	shop_remove_selection_open = false
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
	_restore_playtest_run(state.get("playtest_active_run", {}), str(state.get("run_id", "")))
	var can_restore_combat_reward: bool = _combat_reward_state_matches_current_node(saved_combat_reward_state)
	if not saved_combat_reward_state.is_empty() and not can_restore_combat_reward:
		_rollback_invalid_combat_reward_gold(saved_combat_reward_state)
	var migrated_state: Dictionary = _create_save_state()
	if can_restore_combat_reward:
		migrated_state["combat_reward_state"] = saved_combat_reward_state.duplicate(true)
	if not SaveManagerScript.save_run(migrated_state):
		last_terminal_persistence_error = "迁移后的跑团存档写回失败；本次读取仍可继续。"
	restoring_combat_reward_state = can_restore_combat_reward
	_start_current_node()
	if can_restore_combat_reward and _restore_combat_reward_state(saved_combat_reward_state):
		_refresh()
	restoring_combat_reward_state = false

func _on_event_choice_pressed(choice: Dictionary) -> void:
	var blocked_reason: String = _event_choice_blocked_reason(choice)
	last_event_choice_blocked_reason = blocked_reason
	if not blocked_reason.is_empty():
		_audio_event("error")
		_refresh()
		return
	last_event_choice_blocked_reason = ""
	var current_event_id: String = str(_current_node().get("event_id", ""))
	var resolved_effects: Array = _resolve_event_choice_effects(choice, current_event_id)
	var active_run := _playtest_active_run()
	if not active_run.is_empty():
		PlaytestTelemetryScript.record_event_choice(active_run, current_event_id, str(choice.get("id", "")), last_event_result_id)
		playtest_store["active_run"] = active_run
	for effect in resolved_effects:
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
		_record_playtest_combat_terminal()
	else:
		_record_playtest_noncombat_terminal()
	if combat != null:
		if combat.phase == "won":
			run_hp = int(combat.player.get("hp", run_hp))
			if completed_node_type == "boss" and not _record_boss_defeated(completed_chapter_id):
				_show_terminal_persistence_error()
				return
		elif combat.phase == "lost":
			return
	var successor_ids: Array[String] = _map_relic_augmented_node_ids(current_node_id, _next_node_ids(current_node_id))
	if successor_ids.is_empty():
		if not _next_chapter_id().is_empty():
			if not _start_next_chapter():
				_show_terminal_persistence_error()
			return
		var appended_final_chapter := false
		if not completed_chapter_ids.has(current_chapter_id):
			completed_chapter_ids.append(current_chapter_id)
			appended_final_chapter = true
		run_completed = true
		var terminal_run_id := _terminal_settlement_run_id()
		if not _record_run_completed():
			run_completed = false
			if appended_final_chapter:
				completed_chapter_ids.erase(current_chapter_id)
			_show_terminal_persistence_error()
			return
		if not _finalize_terminal_run_storage("victory", "campaign_completed", terminal_run_id):
			_show_terminal_persistence_error()
			return
		if not current_node_id.is_empty():
			completed_node_ids[current_node_id] = true
		available_node_ids.clear()
		current_node_id = ""
		combat = null
		_audio_event("ui_click")
		_refresh()
		return
	if not current_node_id.is_empty():
		completed_node_ids[current_node_id] = true
	available_node_ids = successor_ids
	current_node_id = ""
	combat = null
	_audio_event("ui_click")
	_refresh()

func _show_terminal_persistence_error() -> void:
	_audio_event("error")
	var message := last_terminal_persistence_error
	if message.is_empty():
		message = "局外进度保存失败；未删除可恢复存档。"
	if combat != null:
		combat.log_entries.append("%s 当前结算尚未关闭，请重试。" % message)
	if status_label != null:
		status_label.text = "%s 请检查本机存储权限后重试。" % message
		status_label.visible = true

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
	var fallback: String = str(ENEMY_ART_PATHS.get(sprite_key, ""))
	if fallback.is_empty() and sprite_key.begins_with("placeholder_"):
		fallback = "res://assets/art/enemy_%s.svg" % sprite_key.trim_prefix("placeholder_")
		if not _asset_loaded(fallback):
			fallback = ""
	if fallback.is_empty():
		fallback = "res://assets/art/enemy_forge_bishop.svg" if str(data.get("tier", "")) == "boss" else "res://assets/art/enemy_soot_raider.svg"
	var path: String = _asset_path_from_slot("enemy_stage_slots", sprite_key, fallback)
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

func _hud_texture_path(slot_id: String, fallback_path: String) -> String:
	return _asset_path_from_slot("hud_texture_slots", slot_id, fallback_path)

func _asset_loaded(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		return true
	return (path.ends_with(".svg") or _is_raster_texture_path(path)) and FileAccess.file_exists(path)

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

func _pc_card_material_frame_path(card_type: String) -> String:
	return str(PC_CARD_MATERIAL_FRAME_PATHS.get(card_type, ""))

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

func _room_scene_art_path(room_id: String, fallback_path: String = "") -> String:
	return _asset_path_from_slot("room_scene_slots", room_id, fallback_path)

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
	if _is_raster_texture_path(path) and FileAccess.file_exists(path):
		if raw_svg_texture_cache.has(path):
			return raw_svg_texture_cache.get(path)
		var image := Image.new()
		var error: Error = image.load(path)
		if error != OK or image.get_width() <= 0 or image.get_height() <= 0:
			return null
		var image_texture := ImageTexture.create_from_image(image)
		raw_svg_texture_cache[path] = image_texture
		return image_texture
	return null

func _is_raster_texture_path(path: String) -> bool:
	return path.ends_with(".png") or path.ends_with(".jpg") or path.ends_with(".jpeg") or path.ends_with(".webp")

func _player_panel_style() -> StyleBoxFlat:
	return _button_style(Color(0.12, 0.16, 0.16, 0.94), Color(0.46, 0.72, 0.66), 2, 8)

func _player_stage_plate_style() -> StyleBoxFlat:
	var style := _button_style(Color(0.035, 0.050, 0.052, 0.94), Color(0.34, 0.78, 0.78, 0.92), 2, 7)
	style.shadow_color = Color(0, 0, 0, 0.72)
	style.shadow_size = 5
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _battle_board_style() -> StyleBoxFlat:
	return _button_style(Color(0.085, 0.095, 0.10, 0.96), Color(0.40, 0.44, 0.48), 2, 8)

func _enemy_stage_style() -> StyleBoxFlat:
	return _button_style(Color(0.095, 0.09, 0.085, 0.92), Color(0.72, 0.48, 0.30), 2, 8)

func _hand_frame_style() -> StyleBoxFlat:
	if _is_pc_layout():
		var style := _button_style(Color(0.045, 0.050, 0.060, 0.58), Color(0.36, 0.46, 0.66, 0.50), 1, 8)
		style.shadow_color = Color(0, 0, 0, 0.48)
		style.shadow_size = 5
		return style
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
	if _is_pc_layout():
		var style := _button_style(Color(bg.r, bg.g, bg.b, 0.92), border.lightened(0.05), 2, 8)
		style.shadow_color = Color(0, 0, 0, 0.60)
		style.shadow_size = 8
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		return style
	return _button_style(bg, border, 2, 5)

func _hand_card_cost_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var style := _button_style(
		colors.get("border", Color(0.58, 0.60, 0.64)).darkened(0.28),
		colors.get("border", Color(0.58, 0.60, 0.64)).lightened(0.10),
		2,
		16 if _is_pc_layout() else 8
	)
	if _is_pc_layout():
		style.shadow_color = Color(0, 0, 0, 0.52)
		style.shadow_size = 4
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	return style

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

func _pc_hand_card_frame_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var style := _button_style(
		Color(0.03, 0.024, 0.020, 0.10),
		colors.get("border", Color(0.58, 0.60, 0.64)).lightened(0.12),
		2,
		8
	)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 7
	return style

func _pc_hand_card_title_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var style := _button_style(
		colors.get("bg", Color(0.18, 0.19, 0.22)).darkened(0.12),
		colors.get("border", Color(0.58, 0.60, 0.64)).lightened(0.02),
		1,
		5
	)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_size = 2
	return style

func _pc_hand_card_type_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var style := _button_style(
		Color(0.03, 0.028, 0.026, 0.78),
		colors.get("border", Color(0.58, 0.60, 0.64)).darkened(0.06),
		1,
		5
	)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	style.shadow_size = 1
	return style

func _pc_hand_card_description_style(card_type: String) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var style := _button_style(
		Color(0.08, 0.07, 0.055, 0.88),
		colors.get("border", Color(0.58, 0.60, 0.64)).darkened(0.18),
		1,
		5
	)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_size = 2
	return style

func _pc_card_rail_color(card_type: String, primary: bool) -> Color:
	var colors: Dictionary = _card_colors(card_type)
	var border: Color = colors.get("border", Color(0.58, 0.60, 0.64))
	if primary:
		return Color(border.r, border.g, border.b, 0.50)
	return Color(border.darkened(0.36).r, border.darkened(0.36).g, border.darkened(0.36).b, 0.42)

func _pc_card_rarity_gem_style(rarity: String) -> StyleBoxFlat:
	var color := _rarity_gem_color(rarity)
	var style := _button_style(Color(color.r, color.g, color.b, 0.84), Color(1.0, 0.96, 0.78, 0.90), 1, 8)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 3
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _rarity_gem_color(rarity: String) -> Color:
	match rarity:
		"uncommon":
			return Color(0.44, 0.88, 0.62, 1.0)
		"rare":
			return Color(0.74, 0.52, 1.0, 1.0)
		"starter":
			return Color(0.88, 0.78, 0.52, 1.0)
		_:
			return Color(0.78, 0.84, 0.88, 1.0)

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

func _pc_enemy_plate_style(enemy: Dictionary, selected: bool, pressed: bool, disabled: bool = false) -> StyleBoxFlat:
	var data: Dictionary = enemy.get("data", {})
	var tier: String = str(data.get("tier", "normal"))
	var bg := Color(0.10, 0.105, 0.11, 0.78)
	var border := Color(0.45, 0.48, 0.50, 0.80)
	if tier == "elite":
		bg = Color(0.16, 0.12, 0.08, 0.82)
		border = Color(0.88, 0.58, 0.28, 0.92)
	elif tier == "boss":
		bg = Color(0.17, 0.075, 0.075, 0.84)
		border = Color(0.96, 0.34, 0.28, 0.96)
	if selected:
		bg = bg.lightened(0.08)
		border = border.lightened(0.16)
	if pressed:
		bg = bg.darkened(0.10)
	if disabled:
		bg = Color(0.06, 0.06, 0.065, 0.58)
		border = Color(0.24, 0.24, 0.25, 0.62)
	var style := _button_style(bg, border, 1, 7)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.44)
	style.shadow_size = 3
	return style

func _pc_enemy_stage_hit_style(enemy: Dictionary, selected: bool, pressed: bool, disabled: bool = false) -> StyleBoxFlat:
	var bg := Color(0.0, 0.0, 0.0, 0.0)
	if pressed:
		bg = Color(1.0, 0.55, 0.24, 0.035)
	if disabled:
		bg = Color(0.0, 0.0, 0.0, 0.08)
	var style := _button_style(bg, Color(0.0, 0.0, 0.0, 0.0), 0, 10)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_size = 0
	return style

func _pc_enemy_health_plate_style(enemy: Dictionary, selected: bool) -> StyleBoxFlat:
	var data: Dictionary = enemy.get("data", {})
	var tier: String = str(data.get("tier", "normal"))
	var border := Color(0.42, 0.46, 0.46, 0.68)
	if tier == "elite":
		border = Color(0.88, 0.58, 0.28, 0.72)
	elif tier == "boss":
		border = Color(0.96, 0.34, 0.28, 0.78)
	if selected:
		border = border.lightened(0.18)
	var style := _button_style(Color(0.018, 0.016, 0.015, 0.72), border, 1, 5)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 4
	return style

func _pc_enemy_foot_shadow_style(enemy: Dictionary, selected: bool) -> StyleBoxFlat:
	var color := Color(0.0, 0.0, 0.0, 0.38)
	var border := Color(0.0, 0.0, 0.0, 0.0)
	if selected:
		border = Color(0.66, 0.92, 0.82, 0.30)
	var style := _button_style(color, border, 1 if selected else 0, 12)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 5
	return style

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
	if _is_pc_layout():
		match severity:
			"danger":
				return _button_style(Color(0.22, 0.055, 0.045, 0.82), Color(0.95, 0.35, 0.28, 0.82), 1, 8)
			"hit":
				return _button_style(Color(0.18, 0.10, 0.045, 0.82), Color(0.95, 0.55, 0.24, 0.82), 1, 8)
			"block":
				return _button_style(Color(0.045, 0.12, 0.17, 0.82), Color(0.42, 0.84, 1.0, 0.84), 1, 8)
			"success":
				return _button_style(Color(0.06, 0.16, 0.09, 0.80), Color(0.36, 0.86, 0.48, 0.80), 1, 8)
			"phase":
				return _button_style(Color(0.17, 0.06, 0.20, 0.84), Color(0.82, 0.46, 0.96, 0.84), 1, 8)
			_:
				return _button_style(Color(0.08, 0.085, 0.09, 0.74), Color(0.50, 0.54, 0.58, 0.72), 1, 8)
	match severity:
		"danger":
			return _button_style(Color(0.28, 0.09, 0.08), Color(0.95, 0.35, 0.28), 2, 6)
		"hit":
			return _button_style(Color(0.25, 0.14, 0.08), Color(0.95, 0.55, 0.24), 2, 6)
		"block":
			return _button_style(Color(0.07, 0.16, 0.22), Color(0.42, 0.84, 1.0), 2, 6)
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
	if _is_pc_layout():
		return 15 if _is_strong_feedback(event_type) else 12
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
		"shop_relic":
			return config.get("shop_relic_rarity_weights", config.get("relic_rarity_weights", {}))
		"relic_reward", "treasure_relic":
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

func _grant_encounter_gold(encounter_id: String, reward_key: String) -> int:
	var gold_reward: int = _encounter_gold_reward(encounter_id, reward_key)
	if gold_reward <= 0:
		return 0
	run_gold += gold_reward
	combat.log_entries.append("获得金币：%d。" % gold_reward)
	return gold_reward

func _encounter_gold_reward(encounter_id: String, reward_key: String) -> int:
	var encounter: Dictionary = _encounter_by_id(encounter_id)
	if encounter.is_empty() or _encounter_skips_economy_rewards(encounter):
		return 0
	var gold_config: Dictionary = economy_data.get("combat_gold_rewards", {})
	var by_tier: Dictionary = gold_config.get("by_tier", {})
	var tier: String = str(encounter.get("tier", "normal"))
	if by_tier.has(tier):
		var tier_range: Dictionary = by_tier.get(tier, {})
		var min_gold: int = int(tier_range.get("min", encounter.get("gold_reward", 0)))
		var max_gold: int = int(tier_range.get("max", min_gold))
		if max_gold < min_gold:
			max_gold = min_gold
		var span: int = max_gold - min_gold + 1
		var chapter_bonus: int = int(gold_config.get("chapter_bonus", {}).get(current_chapter_id, 0))
		return max(0, min_gold + _deterministic_index("combat_gold|%s|%s|%s|%s|%d" % [
			selected_character_id,
			current_chapter_id,
			reward_key,
			tier,
			current_challenge_level
		], span) + chapter_bonus)
	return max(0, int(encounter.get("gold_reward", 0)))

func _encounter_skips_economy_rewards(encounter: Dictionary) -> bool:
	return int(encounter.get("card_reward_count", 3)) <= 0 and not bool(encounter.get("relic_reward", false)) and int(encounter.get("gold_reward", 0)) <= 0

func _card_price(card: Dictionary) -> int:
	var rarity: String = str(card.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("card_prices", {})
	return int(prices.get(rarity, prices.get("common", 50)))

func _potion_price(potion: Dictionary) -> int:
	var rarity: String = str(potion.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("potion_prices", {})
	return int(prices.get(rarity, prices.get("common", 35)))

func _relic_price(relic: Dictionary) -> int:
	var rarity: String = str(relic.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("relic_prices", {})
	return int(prices.get(rarity, prices.get("common", 120)))

func _remove_card_price() -> int:
	var shop_config: Dictionary = economy_data.get("shop", {})
	var base_price: int = int(shop_config.get("remove_card_price", 50))
	var increase: int = int(shop_config.get("remove_card_price_increase", 25))
	return base_price + max(0, run_shop_remove_count) * max(0, increase)

func _treasure_gold_amount(node_id: String) -> int:
	var treasure_config: Dictionary = economy_data.get("treasure", {})
	var min_gold: int = int(treasure_config.get("gold_min", 18))
	var max_gold: int = int(treasure_config.get("gold_max", 35))
	if max_gold < min_gold:
		max_gold = min_gold
	var span: int = max_gold - min_gold + 1
	return min_gold + _deterministic_index("treasure_gold|%s|%s|%s|%d" % [
		selected_character_id,
		current_chapter_id,
		node_id,
		current_challenge_level
	], span)

func _treasure_relic_choice_count() -> int:
	return max(1, int(economy_data.get("treasure", {}).get("relic_choices", 3)))

func _campfire_heal_percent() -> int:
	return int(economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 30))

func _potion_reward_count() -> int:
	return int(economy_data.get("potion_reward", {}).get("combat_drop_count", 1))

func _should_offer_potion_reward(reward_key: String) -> bool:
	var potion_config: Dictionary = economy_data.get("potion_reward", {})
	var chance_percent: int = clampi(int(potion_config.get("drop_chance_percent", 100)), 0, 100)
	if chance_percent <= 0:
		return false
	if chance_percent >= 100:
		return true
	return _deterministic_index("potion_drop|%s|%s|%d" % [
		selected_character_id,
		reward_key,
		current_challenge_level
	], 100) < chance_percent

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
		"event_completed":
			var event_id: String = str(condition.get("event_id", ""))
			if not bool(completed_event_ids.get(event_id, false)):
				return "需要完成前置事件"
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
		"lose_gold":
			run_gold = max(0, run_gold - int(effect.get("amount", 0)))
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
				_record_playtest_card_acquired(card_id, "event:%s" % str(_current_node().get("event_id", "unknown")))
				if _record_discovered_content("cards", card_id):
					_save_player_profile()
		"gain_relic":
			var relic_id: String = str(effect.get("relic_id", ""))
			if not relic_id.is_empty() and not run_relic_ids.has(relic_id):
				run_relic_ids.append(relic_id)
				_record_playtest_item_acquired("relics", relic_id, "event:%s" % str(_current_node().get("event_id", "unknown")))
				if _record_discovered_content("relics", relic_id):
					_save_player_profile()
		"gain_potion":
			var potion_id: String = str(effect.get("potion_id", ""))
			if not potion_id.is_empty() and _has_empty_potion_slot():
				run_potion_ids.append(potion_id)
				_record_playtest_item_acquired("potions", potion_id, "event:%s" % str(_current_node().get("event_id", "unknown")))
				if _record_discovered_content("potions", potion_id):
					_save_player_profile()
		"remove_first_non_starter_card":
			var remove_index: int = _find_removable_card_index()
			if remove_index >= 0:
				var removed_entry := str(run_deck_ids[remove_index])
				run_deck_ids.remove_at(remove_index)
				var active_run := _playtest_active_run()
				if not active_run.is_empty():
					PlaytestTelemetryScript.record_card_removed(active_run, removed_entry)
					playtest_store["active_run"] = active_run
		"complete_event":
			var event_id: String = str(effect.get("event_id", ""))
			if not event_id.is_empty():
				completed_event_ids[event_id] = true
		_:
			pass

func _find_removable_card_index() -> int:
	for i in range(run_deck_ids.size()):
		var card: Dictionary = _card_by_id(_base_card_id(str(run_deck_ids[i])))
		if not card.is_empty() and str(card.get("rarity", "")) != "starter":
			return i
	return -1

func _shop_removable_card_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		if not _deck_display_card(entry).is_empty():
			result.append(i)
	return result

func _current_node() -> Dictionary:
	if not current_node_id.is_empty():
		return _node_by_id(current_node_id)
	if current_node_index >= 0 and current_node_index < route_nodes.size():
		return route_nodes[current_node_index]
	return {}

func _is_battle_node(node_type: String) -> bool:
	return node_type == "combat" or node_type == "elite" or node_type == "boss"

func _route_preview() -> String:
	var total_nodes: int = _route_total_node_count()
	var current_node: Dictionary = _current_node()
	var current_text: String = "未选择"
	if not current_node.is_empty():
		current_text = "%s [%s]" % [
			current_node.get("name", "节点"),
			_node_type_display_name(str(current_node.get("type", "")))
		]
	var next_parts: Array[String] = _route_next_preview_parts()
	var next_text: String = "本章终点"
	if not next_parts.is_empty():
		next_text = "、".join(next_parts)
	return "路线概览：已清理 %d/%d | 当前：%s\n下一步：%s" % [
		min(completed_node_ids.size(), total_nodes),
		total_nodes,
		current_text,
		next_text
	]

func _route_total_node_count() -> int:
	var total := 0
	for layer in map_graph.get("layers", []):
		var layer_nodes: Array = layer
		total += layer_nodes.size()
	if total > 0:
		return total
	return route_nodes.size()

func _route_next_preview_parts() -> Array[String]:
	var node_ids: Array[String] = []
	if not current_node_id.is_empty():
		node_ids = _successor_node_ids(current_node_id)
	if node_ids.is_empty():
		for node_id in available_node_ids:
			var node_id_string: String = str(node_id)
			if not node_id_string.is_empty() and not node_ids.has(node_id_string):
				node_ids.append(node_id_string)

	var parts: Array[String] = []
	var max_count := 4 if _is_pc_layout() else 3
	for i in range(min(max_count, node_ids.size())):
		var node_id: String = str(node_ids[i])
		var node: Dictionary = _node_by_id(node_id)
		if node.is_empty():
			continue
		parts.append("%s [%s]" % [
			node.get("name", node_id),
			_node_type_display_name(str(node.get("type", "")))
		])
	if node_ids.size() > max_count:
		parts.append("另有 %d 个选择" % (node_ids.size() - max_count))
	return parts

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
		available_names.append("%s [%s]" % [
			node.get("name", node_id),
			_node_type_display_name(str(node.get("type", "")))
		])
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
		last_map_preview_risk_level = ""
		last_map_preview_reward_summary = ""
		return "节点详情：暂无可预览节点。"
	var next_ids: Array[String] = _successor_node_ids(node_id)
	var next_parts: Array[String] = []
	for next_id in next_ids:
		var next_node: Dictionary = _node_by_id(next_id)
		next_parts.append("%s [%s]" % [next_node.get("name", next_id), _node_type_display_name(str(next_node.get("type", "")))])
	if next_parts.is_empty():
		next_parts.append("终点或当前路线末端")
	var risk_summary: String = _node_risk_summary(node)
	var reward_summary: String = _node_reward_summary(node)
	last_map_preview_risk_level = _node_risk_level(node)
	last_map_preview_reward_summary = reward_summary
	return "节点详情\n%s [%s]\n%s\n风险：%s\n收益：%s\n后续可达：%s" % [
		node.get("name", node_id),
		_node_type_display_name(str(node.get("type", ""))),
		_node_detail_text(node),
		risk_summary,
		reward_summary,
		", ".join(next_parts)
	]

func _node_risk_level(node: Dictionary) -> String:
	var node_type: String = str(node.get("type", ""))
	if node_type == "boss":
		return "极高"
	if node_type == "elite":
		return "高"
	if node_type == "combat":
		var encounter: Dictionary = _encounter_by_id(str(node.get("encounter_id", "")))
		var enemy_count: int = encounter.get("enemy_ids", []).size()
		if current_chapter_id == "chapter_three" or enemy_count >= 2:
			return "中"
		return "低"
	if node_type == "event":
		return "未知"
	if node_type == "shop" or node_type == "campfire" or node_type == "treasure":
		return "低"
	return "未知"

func _node_risk_summary(node: Dictionary) -> String:
	var node_type: String = str(node.get("type", ""))
	var level: String = _node_risk_level(node)
	if _is_battle_node(node_type):
		var encounter: Dictionary = _encounter_by_id(str(node.get("encounter_id", "")))
		var enemy_count: int = encounter.get("enemy_ids", []).size()
		var tier: String = str(encounter.get("tier", node_type))
		var pressure: String = "敌人 %d 个" % enemy_count
		if tier == "elite":
			pressure = "精英战，敌方数值和行动压力更高"
		elif tier == "boss":
			pressure = "Boss 战，击败后推进章节或结局"
		return "%s - %s" % [level, pressure]
	if node_type == "event":
		return "%s - 结果依赖选项，可能用生命换资源" % level
	if node_type == "shop":
		return "%s - 无战斗，但会消耗金币" % level
	if node_type == "campfire":
		return "%s - 安全休整节点" % level
	if node_type == "treasure":
		return "%s - 低风险构筑强化" % level
	return "%s - 规则未明" % level

func _node_reward_summary(node: Dictionary) -> String:
	var node_type: String = str(node.get("type", ""))
	if _is_battle_node(node_type):
		var encounter_id: String = str(node.get("encounter_id", ""))
		var encounter: Dictionary = _encounter_by_id(encounter_id)
		if _encounter_skips_economy_rewards(encounter):
			return "最终战结算，无战后选牌奖励"
		var reward_key: String = _combat_reward_key(node, encounter_id)
		var gold_reward: int = _encounter_gold_reward(encounter_id, reward_key)
		var parts: Array[String] = []
		if gold_reward > 0:
			parts.append("%d 金币" % gold_reward)
		var card_count: int = int(encounter.get("card_reward_count", 3))
		if card_count > 0:
			parts.append("%d 选 1 卡牌" % card_count)
		if bool(encounter.get("relic_reward", false)):
			parts.append("遗物选择")
		if parts.is_empty():
			parts.append("无额外奖励")
		return "、".join(parts)
	if node_type == "event":
		return "事件选项可能提供金币、删卡、遗物、药水或卡牌"
	if node_type == "shop":
		return "购买卡牌/遗物/药水，删卡 %d 金币" % _remove_card_price()
	if node_type == "campfire":
		return "恢复 %d%% 最大生命或升级 1 张牌" % _campfire_heal_percent()
	if node_type == "treasure":
		return "%d-%d 金币，%d 件遗物中选 1" % [
			int(economy_data.get("treasure", {}).get("gold_min", 18)),
			int(economy_data.get("treasure", {}).get("gold_max", 35)),
			_treasure_relic_choice_count()
		]
	return "无明确奖励"

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
		"treasure":
			return "宝箱"
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
	if node_type == "treasure":
		return "获得 %d-%d 金币，并从 %d 件遗物中选择 1 件。" % [
			int(economy_data.get("treasure", {}).get("gold_min", 18)),
			int(economy_data.get("treasure", {}).get("gold_max", 35)),
			_treasure_relic_choice_count()
		]
	return ""

func _clear_container(container: Node) -> void:
	if container == null:
		return
	if container == reward_row and app_shell != null and app_shell.active_page != null and app_shell.active_page.get_parent() == reward_row:
		app_shell.clear_page()
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _create_save_state() -> Dictionary:
	var hp_to_save: int = run_hp
	if combat != null:
		hp_to_save = int(combat.player.get("hp", run_hp))
	return {
		"version": SaveManagerScript.RUN_SAVE_VERSION,
		"run_id": _terminal_settlement_run_id(),
		"selected_character_id": selected_character_id,
		"run_deck_ids": run_deck_ids.duplicate(true),
		"run_relic_ids": run_relic_ids.duplicate(true),
		"run_potion_ids": run_potion_ids.duplicate(true),
		"run_hp": hp_to_save,
		"run_max_hp": run_max_hp,
		"run_gold": run_gold,
		"run_shop_remove_count": run_shop_remove_count,
		"run_progression_node_ids": run_progression_node_ids.duplicate(true),
		"run_character_config": run_character_config.duplicate(true),
		"run_skill_book_id": run_skill_book_id,
		"run_deck_mastery_id": run_deck_mastery_id,
		"current_challenge_level": current_challenge_level,
		"current_chapter_id": current_chapter_id,
		"completed_chapter_ids": completed_chapter_ids.duplicate(true),
		"current_node_index": current_node_index,
		"current_node_id": current_node_id,
		"available_node_ids": available_node_ids.duplicate(true),
		"completed_node_ids": completed_node_ids.duplicate(true),
		"completed_event_ids": completed_event_ids.duplicate(true),
		"map_graph": map_graph.duplicate(true),
		"run_completed": run_completed,
		"combat_reward_state": _combat_reward_state_for_save(),
		"playtest_active_run": _playtest_active_run().duplicate(true)
	}

func _combat_reward_state_for_save() -> Dictionary:
	if combat == null or combat.phase != "won" or reward_generated_for.is_empty():
		return {}
	var node: Dictionary = _current_node()
	var run_id: String = _terminal_settlement_run_id()
	var node_id: String = str(node.get("id", ""))
	var encounter_id: String = str(node.get("encounter_id", ""))
	var gold_before_reward: int = run_gold - combat_reward_gold
	if run_id.is_empty() or node_id.is_empty() or encounter_id.is_empty() or gold_before_reward < 0:
		return {}
	return {
		"schema_version": 1,
		"active": true,
		"run_id": run_id,
		"chapter_id": current_chapter_id,
		"node_id": node_id,
		"encounter_id": encounter_id,
		"reward_generated_for": reward_generated_for,
		"run_gold_before_reward": gold_before_reward,
		"combat_reward_gold": combat_reward_gold,
		"card_ids": _item_ids(reward_options),
		"relic_ids": _item_ids(relic_reward_options),
		"potion_ids": _item_ids(potion_reward_options),
		"card_reward_done": card_reward_done,
		"relic_reward_done": relic_reward_done,
		"potion_reward_done": potion_reward_done
	}

func _item_ids(items: Array) -> Array[String]:
	var ids: Array[String] = []
	for item_value in items:
		var item: Dictionary = item_value
		var item_id: String = str(item.get("id", ""))
		if not item_id.is_empty():
			ids.append(item_id)
	return ids

func _restore_combat_reward_state(raw_state: Variant) -> bool:
	if combat == null or not _combat_reward_state_matches_current_node(raw_state):
		return false
	var state: Dictionary = raw_state
	reward_generated_for = str(state.get("reward_generated_for", ""))
	combat_reward_gold = max(0, int(state.get("combat_reward_gold", 0)))
	last_combat_gold_reward = combat_reward_gold
	reward_options = _items_by_ids(state.get("card_ids", []), Callable(self, "_card_by_id"))
	relic_reward_options = _items_by_ids(state.get("relic_ids", []), Callable(self, "_relic_by_id"))
	potion_reward_options = _items_by_ids(state.get("potion_ids", []), Callable(self, "_potion_by_id"))
	card_reward_done = bool(state.get("card_reward_done", false)) or reward_options.is_empty()
	relic_reward_done = bool(state.get("relic_reward_done", false)) or relic_reward_options.is_empty()
	potion_reward_done = bool(state.get("potion_reward_done", false)) or potion_reward_options.is_empty()
	combat.phase = "won"
	return true

func _combat_reward_state_matches_current_node(raw_state: Variant) -> bool:
	if not raw_state is Dictionary or run_completed:
		return false
	var state: Dictionary = raw_state
	if not _is_nonnegative_json_integer(state.get("schema_version", null)) or int(state.get("schema_version", 0)) != 1:
		return false
	if typeof(state.get("active", null)) != TYPE_BOOL or not bool(state.get("active", false)):
		return false
	for field_name in ["run_id", "chapter_id", "node_id", "encounter_id", "reward_generated_for"]:
		if typeof(state.get(field_name, null)) != TYPE_STRING or str(state.get(field_name, "")).is_empty():
			return false
	for field_name in ["run_gold_before_reward", "combat_reward_gold"]:
		if not _is_nonnegative_json_integer(state.get(field_name, null)):
			return false
	for field_name in ["card_reward_done", "relic_reward_done", "potion_reward_done"]:
		if typeof(state.get(field_name, null)) != TYPE_BOOL:
			return false
	if not _reward_item_ids_are_valid(state.get("card_ids", null), Callable(self, "_card_by_id")):
		return false
	if not _reward_item_ids_are_valid(state.get("relic_ids", null), Callable(self, "_relic_by_id")):
		return false
	if not _reward_item_ids_are_valid(state.get("potion_ids", null), Callable(self, "_potion_by_id")):
		return false
	if not bool(state.get("card_reward_done", false)) and (state.get("card_ids", []) as Array).is_empty():
		return false
	if not bool(state.get("relic_reward_done", false)) and (state.get("relic_ids", []) as Array).is_empty():
		return false
	if not bool(state.get("potion_reward_done", false)) and (state.get("potion_ids", []) as Array).is_empty():
		return false
	if int(state.get("run_gold_before_reward", 0)) + int(state.get("combat_reward_gold", 0)) != run_gold:
		return false
	var saved_reward_key: String = str(state.get("reward_generated_for", ""))
	var node: Dictionary = _current_node()
	if node.is_empty() or not _is_battle_node(str(node.get("type", ""))):
		return false
	var encounter_id: String = str(node.get("encounter_id", ""))
	if encounter_id.is_empty():
		return false
	return str(state.get("run_id", "")) == _terminal_settlement_run_id() \
		and str(state.get("chapter_id", "")) == current_chapter_id \
		and str(state.get("node_id", "")) == str(node.get("id", "")) \
		and str(state.get("encounter_id", "")) == encounter_id \
		and saved_reward_key == _combat_reward_key(node, encounter_id)

func _reward_item_ids_are_valid(raw_ids: Variant, lookup: Callable) -> bool:
	if not raw_ids is Array:
		return false
	var seen_ids: Dictionary = {}
	for item_id_value in raw_ids:
		if typeof(item_id_value) != TYPE_STRING:
			return false
		var item_id: String = str(item_id_value)
		if item_id.is_empty() or seen_ids.has(item_id) or (lookup.call(item_id) as Dictionary).is_empty():
			return false
		seen_ids[item_id] = true
	return true

func _rollback_invalid_combat_reward_gold(raw_state: Variant) -> void:
	if not raw_state is Dictionary:
		return
	var state: Dictionary = raw_state
	if not _is_nonnegative_json_integer(state.get("run_gold_before_reward", null)) or not _is_nonnegative_json_integer(state.get("combat_reward_gold", null)):
		return
	var gold_before_reward: int = int(state.get("run_gold_before_reward", -1))
	var reward_gold: int = int(state.get("combat_reward_gold", -1))
	if gold_before_reward >= 0 and reward_gold >= 0 and gold_before_reward + reward_gold == run_gold:
		run_gold = gold_before_reward

func _is_nonnegative_json_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return number >= 0.0 and number == floor(number)

func _items_by_ids(raw_ids: Variant, lookup: Callable) -> Array:
	var items: Array = []
	if not raw_ids is Array:
		return items
	for item_id_value in raw_ids:
		var item: Dictionary = lookup.call(str(item_id_value))
		if not item.is_empty():
			items.append(item.duplicate(true))
	return items

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
	var appended_chapter := false
	if not completed_chapter_ids.has(current_chapter_id):
		completed_chapter_ids.append(current_chapter_id)
		appended_chapter = true
	if not _record_chapter_completed(current_chapter_id):
		if appended_chapter:
			completed_chapter_ids.erase(current_chapter_id)
		return false
	_apply_chapter_transition_recovery()
	current_chapter_id = next_chapter_id
	current_node_index = 0
	current_node_id = ""
	available_node_ids.clear()
	completed_node_ids.clear()
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	treasure_reward_gold = 0
	combat_reward_gold = 0
	shop_relic_options.clear()
	reward_generated_for = ""
	shop_generated_for = -1
	shop_remove_selection_open = false
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	_build_route()
	_audio_event("ui_click")
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
