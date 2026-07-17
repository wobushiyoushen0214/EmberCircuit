extends SceneTree

const ForgeThemeScript = preload("res://scripts/ui/ForgeTheme.gd")
const ForgeMotionScript = preload("res://scripts/ui/ForgeMotion.gd")
const AppShellScript = preload("res://scripts/ui/AppShell.gd")
const ForgePanelScript = preload("res://scripts/ui/components/ForgePanel.gd")
const ActionCardScript = preload("res://scripts/ui/components/ActionCard.gd")
const ResourceChipScript = preload("res://scripts/ui/components/ResourceChip.gd")
const PageHeaderScript = preload("res://scripts/ui/components/PageHeader.gd")

var failed := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var theme = ForgeThemeScript.new()
	if not _check(theme.schema_version() == 1, "theme token schema is version 1"):
		return
	if not _check(theme.color("bg_ink") == Color("0b0908"), "theme exposes dark forge background"):
		return
	if not _check(theme.color("missing_token") == theme.color("bg_ink"), "unknown token falls back to bg_ink"):
		return
	if not _check(_contrast_ratio(theme.color("text_primary"), theme.color("primary_surface")) >= 4.5, "primary command text meets WCAG AA contrast"):
		return
	if not _check(_contrast_ratio(theme.color("text_muted"), theme.color("panel_iron")) >= 4.5, "muted body text remains readable on iron panels"):
		return
	if not _check(theme.font_size("heading_lg") >= 24, "heading token is readable"):
		return
	if not _check(theme.spacing("panel_gap") >= 8, "spacing token is deterministic"):
		return
	var style := theme.panel_style("iron")
	if not _check(style is StyleBoxFlat and style.border_width_left == 1, "iron panel style has brass border"):
		return
	var motion = ForgeMotionScript.new()
	if not _check(motion.duration("page_enter") >= 220.0 and motion.duration("page_enter") <= 320.0, "page motion duration is bounded"):
		return
	if not _check(motion.duration("missing") == motion.duration("micro"), "unknown motion falls back to micro"):
		return
	var durations: Dictionary = motion._profiles.get("durations_ms", {})
	durations["press_in"] = 10
	durations["outcome"] = 900
	if not _check(motion.duration("press_in") == 80.0 and motion.duration("outcome") == 320.0, "motion durations clamp to the shared 80-320 millisecond contract"):
		return
	if not _check(ForgeMotionScript.allows_continuous_motion(false) and not ForgeMotionScript.allows_continuous_motion(true), "reduced motion disables continuous looping effects"):
		return
	var probe := Control.new()
	probe.custom_minimum_size = Vector2(80, 50)
	motion.press_scale(probe, true, true)
	if not _check(probe.scale == Vector2.ONE, "reduced motion keeps press layout stable"):
		return
	var shell = AppShellScript.new()
	root.add_child(shell)
	if not _check(shell.page_host != null and shell.mount_page(null, "empty") == false, "shell exposes page host and rejects null page"):
		return
	if not _check(is_equal_approx(shell.page_host.anchor_right, 1.0) and is_equal_approx(shell.page_host.anchor_bottom, 1.0), "shell owns a full-screen internal page host"):
		return
	shell.reduced_motion = true
	var mounted_page := Control.new()
	mounted_page.modulate.a = 0.25
	if not _check(shell.mount_page(mounted_page, "motion_probe") and is_equal_approx(mounted_page.modulate.a, 1.0), "shell routes page entry through reduced-motion policy"):
		return
	var signal_page := Button.new()
	var replacement_page := Control.new()
	shell.mount_page(signal_page, "signal_page")
	signal_page.pressed.connect(func() -> void: shell.mount_page(replacement_page, "replacement_page"))
	signal_page.pressed.emit()
	if not _check(shell.active_page == replacement_page and signal_page.is_queued_for_deletion(), "shell defers page destruction while an outgoing control is emitting"):
		return
	await process_frame
	var panel = ForgePanelScript.new()
	panel.variant = "iron"
	if not _check(panel.custom_minimum_size.x >= 44.0 and panel.custom_minimum_size.y >= 44.0, "forge panel keeps interactive minimum area"):
		return
	var card = ActionCardScript.new()
	card.configure({"title": "开始新跑团", "variant": "primary"})
	if not _check(card.title_label.text == "开始新跑团" and card.custom_minimum_size.x >= 44.0 and card.custom_minimum_size.y >= 44.0, "action card configures title and hit area"):
		return
	var focus_style := card.get_theme_stylebox("focus") as StyleBoxFlat
	if not _check(focus_style != null and focus_style.border_width_left >= 2, "action card exposes a two-pixel focus ring"):
		return
	var chip = ResourceChipScript.new()
	chip.configure("金币", 55)
	if not _check(chip.value_label.text == "55" and chip.name == "ResourceChip", "resource chip exposes semantic value"):
		return
	var header = PageHeaderScript.new()
	header.configure("选择角色", "锻炉中的三条回路")
	if not _check(header.title_label.text == "选择角色" and header.subtitle_label.text == "锻炉中的三条回路", "page header configures title and subtitle"):
		return
	probe.free()
	root.remove_child(shell)
	shell.free()
	panel.free()
	card.free()
	chip.free()
	header.free()
	print("PASS: forge ui foundation")
	quit()

func _contrast_ratio(foreground: Color, background: Color) -> float:
	var lighter: float = max(_relative_luminance(foreground), _relative_luminance(background))
	var darker: float = min(_relative_luminance(foreground), _relative_luminance(background))
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	var channels := [color.r, color.g, color.b]
	var linear: Array[float] = []
	for channel in channels:
		var value: float = float(channel)
		linear.append(value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4))
	return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	failed = true
	printerr("FAIL: %s" % message)
	quit(1)
	return false
