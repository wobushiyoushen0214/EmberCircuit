extends Control

signal setting_changed(setting_id: String, value: Variant)
signal reset_requested
signal tutorial_reset_requested
signal close_requested

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")

var _theme := ForgeThemeScript.new()
var _content: VBoxContainer
var _group_grid: GridContainer
var _reset_confirm: HBoxContainer
var source_page: String = ""

func _init() -> void:
	name = "SettingsPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()

func configure(model: Dictionary) -> void:
	source_page = str(model.get("source_page", ""))
	var settings: Dictionary = model.get("settings", {})
	var available_width := maxf(960.0, float(model.get("available_width", 1280.0)))
	var available_height := maxf(640.0, float(model.get("available_height", 720.0)))
	custom_minimum_size = Vector2(available_width, available_height)
	_clear_content()
	_build_header()
	_group_grid = GridContainer.new()
	_group_grid.name = "SettingsDesktopGrid"
	_group_grid.columns = 2
	_group_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_group_grid.add_theme_constant_override("h_separation", 12)
	_group_grid.add_theme_constant_override("v_separation", 12)
	_content.add_child(_group_grid)
	var audio_group := _new_group("SettingsAudioGroup", "音频")
	_add_toggle(audio_group, "SettingsAudioEnabled", "启用音效", "audio_enabled", bool(settings.get("audio_enabled", true)))
	_add_slider(audio_group, "SettingsMasterVolume", "主音量", "master_volume", float(settings.get("master_volume", 1.0)), 0.1)
	_add_toggle(audio_group, "SettingsMusicEnabled", "启用音乐", "music_enabled", bool(settings.get("music_enabled", true)))
	_add_slider(audio_group, "SettingsMusicVolume", "音乐音量", "music_volume", float(settings.get("music_volume", 0.65)), 0.1)

	var feedback_group := _new_group("SettingsFeedbackGroup", "战斗反馈")
	_add_toggle(feedback_group, "SettingsScreenShake", "震屏", "screen_shake_enabled", bool(settings.get("screen_shake_enabled", true)))
	_add_toggle(feedback_group, "SettingsHitStop", "受击顿帧", "hit_stop_enabled", bool(settings.get("hit_stop_enabled", true)))
	_add_toggle(feedback_group, "SettingsFloatingText", "漂浮战斗文字", "floating_text_enabled", bool(settings.get("floating_text_enabled", true)))

	var accessibility_group := _new_group("SettingsAccessibilityGroup", "可访问性")
	_add_toggle(accessibility_group, "SettingsReducedMotion", "降低动态效果", "reduced_motion", bool(settings.get("reduced_motion", false)))
	_add_slider(accessibility_group, "SettingsFlashIntensity", "闪光强度", "flash_intensity", float(settings.get("flash_intensity", 1.0)), 0.25)
	_add_slider(accessibility_group, "SettingsParticleDensity", "粒子密度", "particle_density", float(settings.get("particle_density", 1.0)), 0.25)

	var tutorial_group := _new_group("SettingsTutorialGroup", "引导")
	_add_toggle(tutorial_group, "SettingsTutorialEnabled", "启用新手引导", "tutorial_enabled", bool(settings.get("tutorial_enabled", true)))
	var tutorial_reset := _new_button("SettingsTutorialReset", "重置引导进度", "secondary")
	tutorial_reset.pressed.connect(func() -> void: tutorial_reset_requested.emit())
	tutorial_group.add_child(tutorial_reset)

	var footer := HBoxContainer.new()
	footer.name = "SettingsFooter"
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)
	_content.add_child(footer)
	var reset := _new_button("SettingsResetButton", "恢复默认", "secondary")
	reset.pressed.connect(_show_reset_confirm)
	footer.add_child(reset)
	var close := _new_button("SettingsCloseButton", "返回", "primary")
	close.pressed.connect(func() -> void: close_requested.emit())
	footer.add_child(close)

	_reset_confirm = HBoxContainer.new()
	_reset_confirm.name = "SettingsResetConfirm"
	_reset_confirm.visible = false
	_reset_confirm.alignment = BoxContainer.ALIGNMENT_END
	_reset_confirm.add_theme_constant_override("separation", 8)
	_content.add_child(_reset_confirm)
	var confirm := _new_button("SettingsResetConfirmButton", "确认恢复默认", "primary")
	confirm.pressed.connect(_confirm_reset)
	_reset_confirm.add_child(confirm)
	var cancel := _new_button("SettingsResetCancelButton", "取消", "utility")
	cancel.pressed.connect(func() -> void: _reset_confirm.hide())
	_reset_confirm.add_child(cancel)

func _build_shell() -> void:
	var scrim := ColorRect.new()
	scrim.name = "SettingsScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = _theme.color("menu_scrim", "bg_ink")
	add_child(scrim)
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.set("horizontal_scroll_mode", 0)
	scroll.set("vertical_scroll_mode", 1)
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)
	_content = VBoxContainer.new()
	_content.name = "SettingsContent"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	margin.add_child(_content)

func _build_header() -> void:
	var header := VBoxContainer.new()
	header.name = "SettingsPageHeader"
	header.add_theme_constant_override("separation", 2)
	_content.add_child(header)
	var eyebrow := Label.new()
	eyebrow.text = "SYSTEM / ACCESSIBILITY"
	eyebrow.add_theme_font_size_override("font_size", _theme.font_size("caption"))
	eyebrow.add_theme_color_override("font_color", _theme.color("brass_bright"))
	header.add_child(eyebrow)
	var title := Label.new()
	title.name = "SettingsPageTitle"
	title.text = "系统设置"
	title.add_theme_font_size_override("font_size", _theme.font_size("heading_lg"))
	title.add_theme_color_override("font_color", _theme.color("text_primary"))
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "音频、战斗反馈和动态效果会即时保存，不写入跑团存档。"
	subtitle.add_theme_color_override("font_color", _theme.color("text_muted"))
	header.add_child(subtitle)

func _new_group(node_name: String, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = Vector2(560, 178)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _theme.panel_style("iron"))
	_group_grid.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", _theme.font_size("heading_sm"))
	label.add_theme_color_override("font_color", _theme.color("text_primary"))
	box.add_child(label)
	return box

func _add_toggle(parent: Container, node_name: String, label: String, setting_id: String, value: bool) -> void:
	var toggle := CheckButton.new()
	toggle.name = node_name
	toggle.text = label
	toggle.button_pressed = value
	toggle.custom_minimum_size = Vector2(260, 44)
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	toggle.toggled.connect(func(enabled: bool) -> void: setting_changed.emit(setting_id, enabled))
	parent.add_child(toggle)

func _add_slider(parent: Container, node_name: String, label: String, setting_id: String, value: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var caption := Label.new()
	caption.text = label
	caption.custom_minimum_size = Vector2(150, 44)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", _theme.color("text_muted"))
	row.add_child(caption)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = step
	slider.value = clampf(value, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(260, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	slider.value_changed.connect(func(next_value: float) -> void: setting_changed.emit(setting_id, next_value))
	row.add_child(slider)

func _new_button(node_name: String, label: String, variant: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(156, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _theme.button_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _theme.button_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _theme.button_style(variant, "pressed"))
	button.add_theme_stylebox_override("focus", _theme.focus_style("card"))
	return button

func _show_reset_confirm() -> void:
	_reset_confirm.show()
	var confirm := _reset_confirm.find_child("SettingsResetConfirmButton", true, false) as Button
	if confirm != null:
		confirm.grab_focus()

func _confirm_reset() -> void:
	_reset_confirm.hide()
	reset_requested.emit()

func _clear_content() -> void:
	for child in _content.get_children():
		child.queue_free()
