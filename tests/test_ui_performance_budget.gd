extends SceneTree

const ProfileToolScript = preload("res://tools/profile_ui_performance.gd")
const VisualToolScript = preload("res://tools/verify_ui_visual_regression.gd")

func _init() -> void:
	var pass_report: Dictionary = ProfileToolScript.evaluate_snapshot({
		"frame_times_ms": [15.0, 16.0, 16.5, 17.0, 18.0, 19.0, 19.5, 20.0],
		"input_latency_ms": [42.0, 55.0, 68.0],
		"persistent_particles": 30,
		"normal_burst_particles": 18,
		"boss_burst_particles": 30,
		"looping_tweens": 2,
		"node_delta_after_20_switches": 0,
		"route_page_ids": ["map", "event", "shop", "campfire", "reward"],
		"route_switch_rounds": 20
	})
	_check(bool(pass_report.get("passed", false)), "performance budget accepts values on the declared boundary")
	_check(float(pass_report.get("p95_ms", 99.0)) <= 20.0 and float(pass_report.get("one_percent_low_fps", 0.0)) >= 45.0, "performance report exposes frame pacing metrics")
	_check(pass_report.get("route_page_ids", []).size() == 5 and int(pass_report.get("route_switch_rounds", 0)) == 20, "performance report proves all five route pages completed twenty switch rounds")

	var fail_report: Dictionary = ProfileToolScript.evaluate_snapshot({
		"frame_times_ms": [16.0, 18.0, 22.0, 28.0],
		"input_latency_ms": [120.0],
		"persistent_particles": 61,
		"normal_burst_particles": 19,
		"boss_burst_particles": 31,
		"looping_tweens": 3,
		"node_delta_after_20_switches": 2,
		"route_page_ids": ["map", "shop", "reward"],
		"route_switch_rounds": 19
	})
	_check(not bool(fail_report.get("passed", true)), "performance budget rejects frame, input, particle, tween and leak violations")
	var issues: Array = fail_report.get("issues", [])
	for issue_id in ["p95_frame_time", "input_latency", "persistent_particles", "normal_burst_particles", "boss_burst_particles", "looping_tweens", "node_leak", "route_page_coverage", "route_switch_rounds"]:
		_check(issues.has(issue_id), "performance report identifies %s" % issue_id)

	var golden := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	golden.fill(Color(0.1, 0.1, 0.1, 1.0))
	var close_actual := golden.duplicate()
	close_actual.set_pixel(0, 0, Color(0.12, 0.1, 0.1, 1.0))
	var close_report: Dictionary = VisualToolScript.compare_images(close_actual, golden, [{"id": "full", "rect": [0, 0, 10, 10]}])
	_check(bool(close_report.get("passed", false)), "regional visual verifier accepts a bounded one-pixel change")
	var bad_actual := golden.duplicate()
	for x in range(4):
		bad_actual.set_pixel(x, 0, Color(1.0, 1.0, 1.0, 1.0))
	var bad_report: Dictionary = VisualToolScript.compare_images(bad_actual, golden, [{"id": "full", "rect": [0, 0, 10, 10]}])
	_check(not bool(bad_report.get("passed", true)) and bad_report.get("failed_regions", []).has("full"), "regional visual verifier rejects excessive changed pixels")

	print("PASS: ui performance budget")
	quit()

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
