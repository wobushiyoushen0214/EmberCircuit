extends SceneTree

const PlaytestEvidenceGateScript = preload("res://scripts/core/PlaytestEvidenceGate.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var output_path := ""
	var input_paths: Array[String] = []
	var index := 0
	while index < args.size():
		var argument := str(args[index])
		if argument == "--out" and index + 1 < args.size():
			output_path = str(args[index + 1])
			index += 2
			continue
		input_paths.append(argument)
		index += 1
	if output_path.is_empty() or input_paths.is_empty():
		push_error("Usage: --script res://tools/merge_playtest_reports.gd -- --out <output.json> <report1.json> [report2.json ...]")
		quit(2)
		return
	var reports: Array = []
	for path in input_paths:
		if not FileAccess.file_exists(path):
			push_error("Playtest report does not exist: %s" % path)
			quit(2)
			return
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			push_error("Playtest report is not a JSON object: %s" % path)
			quit(2)
			return
		reports.append(parsed)
	var result: Dictionary = PlaytestEvidenceGateScript.merge_reports(reports)
	if not bool(result.get("ok", false)):
		push_error("Cannot merge playtest reports: %s (%s)" % [str(result.get("error_code", "unknown")), str(result.get("run_id", ""))])
		quit(1)
		return
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write merged playtest report: %s" % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(result.get("report", {}), "\t"))
	file.flush()
	if file.get_error() != OK:
		push_error("Cannot flush merged playtest report: %s" % output_path)
		quit(1)
		return
	print("Merged %d report(s) into %s" % [reports.size(), output_path])
	quit(0)
