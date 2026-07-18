extends SceneTree

const ForgeMotionScript = preload("res://scripts/ui/ForgeMotion.gd")
const AppShellScript = preload("res://scripts/ui/AppShell.gd")
const OutcomePageScript = preload("res://scripts/ui/pages/OutcomePage.gd")
const SettingsPageScript = preload("res://scripts/ui/pages/SettingsPage.gd")
const CompendiumPageScript = preload("res://scripts/ui/pages/CompendiumPage.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var standard: Dictionary = ForgeMotionScript.resolve_policy({
		"reduced_motion": false,
		"flash_intensity": 0.75,
		"particle_density": 0.5
	})
	if not _check(not bool(standard.get("reduced_motion", true)) and bool(standard.get("allows_translation", false)) and bool(standard.get("allows_scale", false)), "standard motion allows short translation and scale"):
		return
	if not _check(is_equal_approx(float(standard.get("flash_intensity", 0.0)), 0.75) and is_equal_approx(float(standard.get("particle_density", 0.0)), 0.5), "standard motion preserves normalized effect intensity"):
		return

	var reduced: Dictionary = ForgeMotionScript.resolve_policy({
		"reduced_motion": true,
		"flash_intensity": 1.0,
		"particle_density": 1.0
	})
	if not _check(bool(reduced.get("reduced_motion", false)) and not bool(reduced.get("allows_translation", true)) and not bool(reduced.get("allows_scale", true)), "reduced motion removes translation and scale"):
		return
	if not _check(bool(reduced.get("allows_opacity", false)) and is_equal_approx(float(reduced.get("particle_density", 1.0)), 0.0), "reduced motion preserves opacity confirmation and disables particles"):
		return
	var shell = AppShellScript.new()
	shell.configure_effect_policy({"reduced_motion": true, "flash_intensity": 0.5, "particle_density": 1.0})
	var shell_page := Control.new()
	shell.mount_page(shell_page, "policy_fixture")
	if not _check(shell.reduced_motion and is_equal_approx(shell.flash_intensity, 0.5) and is_equal_approx(shell.particle_density, 0.0), "app shell resolves the global effect policy"):
		return
	if not _check(shell_page.has_meta("forge_motion_policy") and not bool((shell_page.get_meta("forge_motion_policy") as Dictionary).get("allows_scale", true)), "mounted pages receive the resolved effect policy"):
		return
	shell.free()

	var outcome = OutcomePageScript.new()
	outcome.configure({"mode": "victory", "stats": {}})
	root.add_child(outcome)
	var settings = SettingsPageScript.new()
	settings.configure({"settings": {}})
	root.add_child(settings)
	var compendium = CompendiumPageScript.new()
	compendium.configure({"items": [], "categories": ["cards", "relics", "potions", "enemies", "events", "challenges"]})
	root.add_child(compendium)
	await process_frame
	for page in [outcome, settings, compendium]:
		if not _check(_interactive_minimums_are_valid(page), "%s keeps 44px interactive minimum" % page.name):
			return
	print("PASS: ui accessibility motion")
	quit()

func _interactive_minimums_are_valid(node: Node) -> bool:
	if node is BaseButton or node is LineEdit or node is Slider:
		var control := node as Control
		if control.custom_minimum_size.x < 44.0 or control.custom_minimum_size.y < 44.0:
			return false
	for child in node.get_children():
		if not _interactive_minimums_are_valid(child):
			return false
	return true

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: %s" % message)
	quit(1)
	return false
