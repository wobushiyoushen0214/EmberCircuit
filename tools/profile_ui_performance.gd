extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

const P95_LIMIT_MS := 20.0
const ONE_PERCENT_LOW_LIMIT_FPS := 45.0
const INPUT_LATENCY_LIMIT_MS := 100.0
const PERSISTENT_PARTICLE_LIMIT := 60
const NORMAL_BURST_PARTICLE_LIMIT := 18
const BOSS_BURST_PARTICLE_LIMIT := 30
const LOOPING_TWEEN_LIMIT := 2

func _init() -> void:
	_profile.call_deferred()

static func evaluate_snapshot(snapshot: Dictionary) -> Dictionary:
	var frame_times: Array[float] = []
	for raw in snapshot.get("frame_times_ms", []):
		frame_times.append(maxf(0.0, float(raw)))
	frame_times.sort()
	var p95_ms := _percentile(frame_times, 0.95)
	var p99_ms := _percentile(frame_times, 0.99)
	var one_percent_low_fps := 1000.0 / p99_ms if p99_ms > 0.0 else 0.0
	var max_input_latency := 0.0
	for raw in snapshot.get("input_latency_ms", []):
		max_input_latency = maxf(max_input_latency, float(raw))
	var issues: Array[String] = []
	if frame_times.is_empty() or p95_ms > P95_LIMIT_MS:
		issues.append("p95_frame_time")
	if one_percent_low_fps < ONE_PERCENT_LOW_LIMIT_FPS:
		issues.append("one_percent_low")
	if max_input_latency > INPUT_LATENCY_LIMIT_MS:
		issues.append("input_latency")
	if int(snapshot.get("persistent_particles", 0)) > PERSISTENT_PARTICLE_LIMIT:
		issues.append("persistent_particles")
	var normal_burst_particles := int(snapshot.get("normal_burst_particles", snapshot.get("burst_particles", 0)))
	var boss_burst_particles := int(snapshot.get("boss_burst_particles", snapshot.get("burst_particles", 0)))
	if normal_burst_particles > NORMAL_BURST_PARTICLE_LIMIT:
		issues.append("normal_burst_particles")
	if boss_burst_particles > BOSS_BURST_PARTICLE_LIMIT:
		issues.append("boss_burst_particles")
	if int(snapshot.get("looping_tweens", 0)) > LOOPING_TWEEN_LIMIT:
		issues.append("looping_tweens")
	if int(snapshot.get("node_delta_after_20_switches", 0)) != 0:
		issues.append("node_leak")
	return {
		"passed": issues.is_empty(),
		"p95_ms": p95_ms,
		"one_percent_low_fps": one_percent_low_fps,
		"max_input_latency_ms": max_input_latency,
		"issues": issues,
		"sample_count": frame_times.size(),
		"persistent_particles": int(snapshot.get("persistent_particles", 0)),
		"normal_burst_particles": normal_burst_particles,
		"boss_burst_particles": boss_burst_particles,
		"looping_tweens": int(snapshot.get("looping_tweens", 0)),
		"node_delta_after_20_switches": int(snapshot.get("node_delta_after_20_switches", 0))
	}

static func _percentile(sorted_values: Array[float], ratio: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index: int = clampi(int(ceil(float(sorted_values.size()) * clampf(ratio, 0.0, 1.0))) - 1, 0, sorted_values.size() - 1)
	return sorted_values[index]

func _profile() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := maxi(1, int(options.get("width", 1280)))
	var height := maxi(1, int(options.get("height", 720)))
	var warmup := maxi(0, int(options.get("warmup", 120)))
	var frame_count := maxi(1, int(options.get("frames", 600)))
	SaveManagerScript.set_storage_namespace("ui_performance_profile")
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.save_profile(SaveManagerScript.default_profile())
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = scene.instantiate()
	main.debug_viewport_size_override = Vector2(width, height)
	viewport.add_child(main)
	await process_frame
	await process_frame
	var baseline_node_count := _node_count(main)
	var input_latency: Array[float] = []
	var input_started := Time.get_ticks_usec()
	main._on_settings_pressed()
	await process_frame
	input_latency.append(float(Time.get_ticks_usec() - input_started) / 1000.0)
	main._on_close_settings_pressed()
	await process_frame
	await process_frame
	for _switch_index in range(20):
		main._on_settings_pressed()
		await process_frame
		main._on_close_settings_pressed()
		await process_frame
		main._on_compendium_pressed()
		await process_frame
		main._on_close_compendium_pressed()
		await process_frame
	await process_frame
	await process_frame
	var node_delta_after_switches := _node_count(main) - baseline_node_count
	main._on_character_selected("arc_tinker")
	await process_frame
	await process_frame
	await create_timer(0.4).timeout
	for _index in range(warmup):
		await process_frame
	var frame_times: Array[float] = []
	var previous_tick := Time.get_ticks_usec()
	for _index in range(frame_count):
		await process_frame
		var current_tick := Time.get_ticks_usec()
		frame_times.append(float(current_tick - previous_tick) / 1000.0)
		previous_tick = current_tick
	var burst_budgets := _configured_burst_budgets(main.vfx_data)
	var snapshot := {
		"frame_times_ms": frame_times,
		"input_latency_ms": input_latency,
		"persistent_particles": _particle_count(main),
		"normal_burst_particles": int(burst_budgets.get("normal", 0)),
		"boss_burst_particles": int(burst_budgets.get("boss", 0)),
		"looping_tweens": _active_tween_count(),
		"node_delta_after_20_switches": node_delta_after_switches
	}
	var report := evaluate_snapshot(snapshot)
	report["platform"] = OS.get_name()
	report["display_server"] = DisplayServer.get_name()
	report["renderer"] = RenderingServer.get_video_adapter_name()
	report["viewport"] = [width, height]
	report["warmup_frames"] = warmup
	report["page_switch_rounds"] = 20
	report["scene_sampled"] = "res://scenes/main/Main.tscn"
	var output_path := str(options.get("output", "/tmp/embercircuit-ui-performance.json"))
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write UI performance report: %s" % output_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file = null
	viewport.remove_child(main)
	main.queue_free()
	root.remove_child(viewport)
	viewport.queue_free()
	await process_frame
	SaveManagerScript.cleanup_storage_namespace()
	SaveManagerScript.clear_storage_namespace()
	print("UI performance report: %s" % output_path)
	quit(0 if bool(report.get("passed", false)) else 1)

func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options := {}
	for argument in arguments:
		var value := str(argument)
		if value.begins_with("--warmup="):
			options["warmup"] = value.trim_prefix("--warmup=").to_int()
		elif value.begins_with("--frames="):
			options["frames"] = value.trim_prefix("--frames=").to_int()
		elif value.begins_with("--width="):
			options["width"] = value.trim_prefix("--width=").to_int()
		elif value.begins_with("--height="):
			options["height"] = value.trim_prefix("--height=").to_int()
		elif value.begins_with("--output="):
			options["output"] = value.trim_prefix("--output=")
	return options

func _particle_count(node: Node) -> int:
	var count := 1 if node is GPUParticles2D or node is CPUParticles2D else 0
	for child in node.get_children():
		count += _particle_count(child)
	return count

func _node_count(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _node_count(child)
	return count

func _active_tween_count() -> int:
	var count := 0
	for tween in get_processed_tweens():
		if tween != null and tween.is_valid():
			count += 1
	return count

func _configured_burst_budgets(vfx_data: Dictionary) -> Dictionary:
	var normal_max := 0
	var boss_max := 0
	for profile_value in vfx_data.get("profiles", []):
		var profile: Dictionary = profile_value
		var particle_count := int(profile.get("particle_count", 0))
		if str(profile.get("id", "")) == "impact_phase":
			boss_max = max(boss_max, particle_count)
		else:
			normal_max = max(normal_max, particle_count)
	for boss_value in vfx_data.get("boss_phase_profiles", {}).values():
		var boss: Dictionary = boss_value
		for phase_value in boss.get("phases", []):
			var phase: Dictionary = phase_value
			boss_max = max(boss_max, int(phase.get("ray_count", 0)))
	return {"normal": normal_max, "boss": boss_max}
