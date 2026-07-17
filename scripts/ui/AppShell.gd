extends Control

signal page_changed(page_id: String)
signal back_requested(page_id: String)

const ForgeMotionScript = preload("res://scripts/ui/ForgeMotion.gd")

var page_host: Control
var active_page: Control
var active_page_id: String = ""
var context_title: String = ""
var context_subtitle: String = ""
var reduced_motion: bool = false

var _owns_page_host: bool = true
var _motion := ForgeMotionScript.new()

func _init() -> void:
	name = "AppShell"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host = Control.new()
	page_host.name = "PageHost"
	page_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(page_host)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and not _owns_page_host:
		_release_active_page()

func mount_page(page: Control, page_id: String) -> bool:
	if page == null or not is_instance_valid(page) or page_host == null or not is_instance_valid(page_host):
		return false
	if page == active_page:
		active_page_id = page_id
		_motion.page_enter(page, reduced_motion)
		page_changed.emit(page_id)
		return true
	if page.get_parent() != null:
		return false
	clear_page()
	active_page = page
	active_page_id = page_id
	page_host.add_child(page)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _owns_page_host:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_motion.page_enter(page, reduced_motion)
	page_changed.emit(page_id)
	return true

func clear_page() -> void:
	_release_active_page()

func _release_active_page() -> void:
	var page := active_page
	active_page = null
	active_page_id = ""
	if page == null or not is_instance_valid(page):
		return
	var parent := page.get_parent()
	if parent != null:
		parent.remove_child(page)
	if is_inside_tree():
		page.queue_free()
	else:
		page.free()

func set_page_host(host: Control) -> void:
	if host == null or host == page_host:
		return
	clear_page()
	if _owns_page_host and page_host != null and is_instance_valid(page_host) and page_host.get_parent() == self:
		remove_child(page_host)
		page_host.free()
	page_host = host
	_owns_page_host = false
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_context(title: String, subtitle: String = "") -> void:
	context_title = title
	context_subtitle = subtitle

func request_back() -> void:
	if not active_page_id.is_empty():
		back_requested.emit(active_page_id)
