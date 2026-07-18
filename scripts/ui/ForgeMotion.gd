extends RefCounted

const PROFILE_PATH := "res://data/config/ui_motion_profiles.json"
const PAGE_TWEEN_META := &"_forge_page_tween"
const PRESS_TWEEN_META := &"_forge_press_tween"
var _profiles: Dictionary = {}

func _init() -> void:
	_profiles = _load_profiles()

func schema_version() -> int:
	return int(_profiles.get("schema_version", 1))

func duration(profile_id: String, fallback_id: String = "micro") -> float:
	var durations: Dictionary = _profiles.get("durations_ms", {})
	return clampf(float(durations.get(profile_id, durations.get(fallback_id, 100.0))), 80.0, 320.0)

func scale(profile_id: String, fallback: float = 1.0) -> float:
	return float(_profiles.get("scales", {}).get(profile_id, fallback))

static func allows_continuous_motion(reduced_motion: bool) -> bool:
	return not reduced_motion

static func resolve_policy(settings: Dictionary) -> Dictionary:
	var reduced_motion := bool(settings.get("reduced_motion", false))
	var flash_intensity := snappedf(clampf(float(settings.get("flash_intensity", 1.0)), 0.0, 1.0), 0.25)
	var particle_density := snappedf(clampf(float(settings.get("particle_density", 1.0)), 0.0, 1.0), 0.25)
	return {
		"reduced_motion": reduced_motion,
		"flash_intensity": flash_intensity,
		"particle_density": 0.0 if reduced_motion else particle_density,
		"allows_translation": not reduced_motion,
		"allows_scale": not reduced_motion,
		"allows_opacity": true,
		"allows_continuous_motion": not reduced_motion
	}

func page_enter(control: Control, reduced_motion: bool = false) -> void:
	if control == null or not is_instance_valid(control):
		return
	_kill_tween(control, PAGE_TWEEN_META)
	if reduced_motion:
		control.modulate.a = 1.0
		return
	control.modulate.a = 0.0
	if control.is_inside_tree():
		var tween := control.create_tween()
		control.set_meta(PAGE_TWEEN_META, tween)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(control, "modulate:a", 1.0, duration("page_enter") / 1000.0)
	else:
		control.modulate.a = 1.0

func press_scale(control: Control, is_pressed: bool, reduced_motion: bool = false, scale_id: String = "press") -> void:
	if control == null or not is_instance_valid(control):
		return
	_kill_tween(control, PRESS_TWEEN_META)
	var pressed_scale_value := clampf(scale(scale_id, 0.98), 0.9, 1.0)
	var target := Vector2.ONE if (reduced_motion or not is_pressed) else Vector2(pressed_scale_value, pressed_scale_value)
	control.pivot_offset = control.size * 0.5
	if control.is_inside_tree() and not reduced_motion:
		var tween := control.create_tween()
		control.set_meta(PRESS_TWEEN_META, tween)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var profile_id := "press_in" if is_pressed else "press_out"
		tween.tween_property(control, "scale", target, duration(profile_id) / 1000.0)
	else:
		control.scale = target

func _kill_tween(control: Control, meta_key: StringName) -> void:
	if not control.has_meta(meta_key):
		return
	var previous = control.get_meta(meta_key)
	if previous is Tween and previous.is_valid():
		previous.kill()
	control.remove_meta(meta_key)

func _load_profiles() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
