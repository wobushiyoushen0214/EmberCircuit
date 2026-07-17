extends RefCounted

const TOKEN_PATH := "res://data/config/ui_theme_tokens.json"

var _tokens: Dictionary = {}

func _init() -> void:
	_tokens = _load_tokens()

func schema_version() -> int:
	return int(_tokens.get("schema_version", 1))

func color(token_id: String, fallback_id: String = "bg_ink") -> Color:
	var colors: Dictionary = _tokens.get("colors", {})
	var value = colors.get(token_id, colors.get(fallback_id, "#0b0908"))
	return Color(str(value))

func spacing(token_id: String, fallback: float = 0.0) -> float:
	return float(_tokens.get("spacing", {}).get(token_id, fallback))

func font_size(token_id: String, fallback: int = 16) -> int:
	return int(_tokens.get("font_sizes", {}).get(token_id, fallback))

func radius(token_id: String, fallback: int = 6) -> int:
	return int(_tokens.get("radii", {}).get(token_id, fallback))

func metric(token_id: String, fallback: float = 0.0) -> float:
	return float(_tokens.get("metrics", {}).get(token_id, fallback))

func panel_style(variant: String = "iron") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color("panel_wood" if variant == "wood" else "panel_iron")
	style.border_color = color("border_subtle", "brass")
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius("panel")
	style.corner_radius_top_right = radius("panel")
	style.corner_radius_bottom_left = radius("panel")
	style.corner_radius_bottom_right = radius("panel")
	style.content_margin_left = spacing("panel_gap")
	style.content_margin_right = spacing("panel_gap")
	style.content_margin_top = spacing("panel_gap")
	style.content_margin_bottom = spacing("panel_gap")
	return style

func button_style(variant: String = "neutral", interaction: String = "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _button_surface(variant, interaction)
	style.border_color = _button_border(variant, interaction)
	if variant == "utility":
		style.set_border_width_all(0)
		style.border_width_bottom = 1
	else:
		style.set_border_width_all(1)
	var card_radius := radius("card")
	var command_radius: int = min(card_radius, 3)
	style.corner_radius_top_left = command_radius
	style.corner_radius_top_right = command_radius
	style.corner_radius_bottom_left = command_radius
	style.corner_radius_bottom_right = command_radius
	style.content_margin_left = spacing("panel_gap")
	style.content_margin_right = spacing("panel_gap")
	style.content_margin_top = spacing("card_gap")
	style.content_margin_bottom = spacing("card_gap")
	if variant == "primary":
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
		style.shadow_size = 7 if interaction == "hover" else 4
		style.shadow_offset = Vector2(0.0, 3.0)
	return style

func focus_style(radius_token: String = "card") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color("focus_ring", "brass_bright")
	style.set_border_width_all(max(2, int(spacing("focus_width", 2.0))))
	var focus_radius := radius(radius_token)
	style.corner_radius_top_left = focus_radius
	style.corner_radius_top_right = focus_radius
	style.corner_radius_bottom_left = focus_radius
	style.corner_radius_bottom_right = focus_radius
	style.expand_margin_left = 2.0
	style.expand_margin_right = 2.0
	style.expand_margin_top = 2.0
	style.expand_margin_bottom = 2.0
	return style

func menu_command_style(variant: String, interaction: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var is_disabled := interaction == "disabled"
	if variant == "utility":
		style.bg_color = color("menu_utility_pressed" if interaction == "pressed" else ("menu_utility_hover" if interaction == "hover" else "transparent"), "utility_surface")
	elif variant == "secondary":
		style.bg_color = color("menu_secondary_disabled" if is_disabled else ("menu_secondary_pressed" if interaction == "pressed" else ("menu_secondary_hover" if interaction == "hover" else "menu_secondary_surface")))
	else:
		style.bg_color = color("menu_command_disabled" if is_disabled else ("menu_command_surface_pressed" if interaction == "pressed" else ("menu_command_surface_hover" if interaction == "hover" else "menu_command_surface")))
	style.corner_radius_top_left = radius("command")
	style.corner_radius_top_right = radius("command")
	style.corner_radius_bottom_left = radius("command")
	style.corner_radius_bottom_right = radius("command")
	if variant == "primary" and not is_disabled:
		style.border_color = color("menu_command_border_pressed" if interaction == "pressed" else ("menu_command_border_hover" if interaction == "hover" else "menu_command_border"))
		style.set_border_width_all(1)
		style.border_width_bottom = 1 if interaction == "pressed" else 2
		style.shadow_color = color("menu_command_shadow")
		style.shadow_size = int(metric("menu_command_shadow_pressed" if interaction == "pressed" else ("menu_command_shadow_hover" if interaction == "hover" else "menu_command_shadow_normal"), 6.0))
		style.shadow_offset = Vector2(0.0, metric("menu_command_shadow_offset_pressed" if interaction == "pressed" else "menu_command_shadow_offset", 4.0))
	else:
		style.set_border_width_all(0)
	return style

func menu_command_focus_style(_variant: String = "primary") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color("focus_ring", "brass_bright")
	style.border_width_left = max(2, int(spacing("focus_width", 2.0)))
	style.expand_margin_left = 4.0
	return style

func _button_surface(variant: String, interaction: String) -> Color:
	if interaction == "disabled":
		return color("panel_iron")
	if variant == "primary":
		if interaction == "hover":
			return color("primary_surface_hover", "primary_surface")
		if interaction == "pressed":
			return color("primary_surface_pressed", "primary_surface")
		return color("primary_surface")
	if variant == "utility" and interaction == "normal":
		return Color(0.0, 0.0, 0.0, 0.0)
	if interaction == "hover":
		return color("panel_iron_hover", "panel_iron")
	if interaction == "pressed":
		return color("bg_furnace", "panel_iron")
	return color("utility_surface" if variant == "utility" else "secondary_surface", "panel_iron")

func _button_border(variant: String, interaction: String) -> Color:
	if interaction == "disabled":
		return color("text_disabled")
	if interaction == "hover":
		return color("brass_bright")
	if interaction == "pressed":
		return color("ember", "brass")
	if variant == "primary":
		return color("border_strong", "brass")
	return color("border_subtle", "brass")

func _load_tokens() -> Dictionary:
	if not FileAccess.file_exists(TOKEN_PATH):
		return {}
	var file := FileAccess.open(TOKEN_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
