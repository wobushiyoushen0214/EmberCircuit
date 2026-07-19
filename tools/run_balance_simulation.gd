extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")

const DEFAULT_OUTPUT_PATH := "/tmp/embercircuit_balance_report.json"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var options: Dictionary = parse_options_for_args(OS.get_cmdline_user_args())
	var output_path: String = str(options.get("output_path", DEFAULT_OUTPUT_PATH))
	var mode: String = str(options.get("mode", "single"))
	options.erase("output_path")
	options.erase("mode")

	var simulator = BalanceSimulatorScript.new()
	var report: Dictionary = simulator.run_campaign_suite(options) if mode == "campaign" else simulator.run_suite(options)
	var error: Error = simulator.save_report(report, output_path)
	if error != OK:
		push_error("Failed to save balance report: %s" % output_path)
		quit(1)
		return

	var summary: Dictionary = report.get("summary", {})
	print("Saved balance report: %s" % output_path)
	if mode == "campaign":
		print("Mode: campaign | Cases: %d | Iterations: %d | Avg win rate: %.3f | Avg chapters: %.3f | Flagged: %d" % [
			int(report.get("case_count", 0)),
			int(report.get("iterations_per_case", 0)),
			float(summary.get("average_campaign_win_rate", 0.0)),
			float(summary.get("average_chapters_completed", 0.0)),
			int(summary.get("flagged_case_count", 0))
		])
	else:
		print("Mode: single | Cases: %d | Iterations: %d | Avg win rate: %.3f | Flagged: %d" % [
			int(report.get("case_count", 0)),
			int(report.get("iterations_per_case", 0)),
			float(summary.get("average_case_win_rate", 0.0)),
			int(summary.get("flagged_case_count", 0))
		])
	quit(0)

static func parse_options_for_args(arguments: Array) -> Dictionary:
	var options := {
		"iterations": BalanceSimulatorScript.DEFAULT_ITERATIONS,
		"max_turns": BalanceSimulatorScript.DEFAULT_MAX_TURNS,
		"output_path": DEFAULT_OUTPUT_PATH,
		"mode": "single"
	}
	for argument in arguments:
		var arg: String = str(argument)
		if arg.begins_with("--mode="):
			options["mode"] = arg.get_slice("=", 1)
		elif arg.begins_with("--strategy-profile="):
			options["strategy_profile"] = arg.get_slice("=", 1)
		elif arg.begins_with("--iterations="):
			options["iterations"] = max(1, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--max-turns="):
			options["max_turns"] = max(1, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--output="):
			options["output_path"] = arg.get_slice("=", 1)
		elif arg.begins_with("--characters="):
			options["character_ids"] = _split_csv(arg.get_slice("=", 1))
		elif arg.begins_with("--challenges="):
			options["challenge_levels"] = _split_int_csv(arg.get_slice("=", 1))
		elif arg.begins_with("--encounters="):
			options["encounter_ids"] = _split_csv(arg.get_slice("=", 1))
	return options

static func _split_csv(value: String) -> Array:
	var result: Array = []
	for part in value.split(",", false):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result

static func _split_int_csv(value: String) -> Array:
	var result: Array = []
	for part in value.split(",", false):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			result.append(int(trimmed))
	return result
