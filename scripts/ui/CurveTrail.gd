extends Control

var curve_points := PackedVector2Array()
var glow_color := Color(1, 1, 1, 0.18)
var core_color := Color(1, 1, 1, 0.84)
var glow_width: float = 8.0
var core_width: float = 2.6

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_curve(points: PackedVector2Array, color: Color, valid: bool = true, wide: bool = false) -> void:
	curve_points = points
	glow_width = 9.0 if wide else 7.0
	core_width = 2.8 if wide else 2.2
	glow_color = Color(color.r, color.g, color.b, 0.20 if valid else 0.12)
	core_color = Color(color.r, color.g, color.b, 0.92 if valid else 0.56)
	queue_redraw()

func _draw() -> void:
	if curve_points.size() < 2:
		return
	# Godot 4.7's Metal path can flash the full canvas when antialiasing a
	# rapidly-created polyline. The layered widths already provide soft edges.
	draw_polyline(curve_points, glow_color, glow_width, false)
	draw_polyline(curve_points, core_color, core_width, false)
