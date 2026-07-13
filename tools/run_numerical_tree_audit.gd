extends SceneTree

const NumericalTreeAuditorScript = preload("res://scripts/tools/NumericalTreeAuditor.gd")

const DEFAULT_OUTPUT_PATH := "/tmp/embercircuit_numerical_tree_audit.json"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var output_path: String = _parse_output_path()
	var auditor = NumericalTreeAuditorScript.new()
	var report: Dictionary = auditor.build_report()
	var error: Error = auditor.save_report(report, output_path)
	if error != OK:
		push_error("Failed to save numerical tree audit: %s" % output_path)
		quit(1)
		return

	var summary: Dictionary = report.get("summary", {})
	print("Saved numerical tree audit: %s" % output_path)
	print("Cards: %d | Advisories: %d | Card warnings: %d | Players: %d/%d warnings | Encounters: %d | Encounter warnings: %d | Economy warnings: %d | Progression warnings: %d | Total hard warnings: %d" % [
		int(summary.get("card_count", 0)),
		int(summary.get("card_advisory_count", 0)),
		int(summary.get("card_warning_count", 0)),
		int(summary.get("player_warning_count", 0)),
		int(summary.get("player_count", 0)),
		int(summary.get("monster_encounter_count", 0)),
		int(summary.get("monster_warning_count", 0)),
		int(summary.get("economy_warning_count", 0)),
		int(summary.get("progression_warning_count", 0)),
		int(summary.get("total_warning_count", 0))
	])
	quit(0)

func _parse_output_path() -> String:
	for argument in OS.get_cmdline_user_args():
		var arg: String = str(argument)
		if arg.begins_with("--output="):
			return arg.get_slice("=", 1)
	return DEFAULT_OUTPUT_PATH
