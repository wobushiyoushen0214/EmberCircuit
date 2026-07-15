extends SceneTree

const NumericalTreeAuditorScript = preload("res://scripts/tools/NumericalTreeAuditor.gd")

const REPORT_PATH := "/tmp/embercircuit_numerical_tree_test_report.json"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var auditor = NumericalTreeAuditorScript.new()
	var report: Dictionary = auditor.build_report()
	_check(str(report.get("audit_model", "")) == "static_numerical_tree", "numerical tree auditor reports model")
	var cards: Array = report.get("cards", [])
	var players: Array = report.get("players", [])
	var monsters: Array = report.get("monsters", [])
	_check(cards.size() >= 40, "numerical tree auditor scores the card pool")
	_check(players.size() == 3, "numerical tree auditor scores every playable character")
	_check(monsters.size() >= 12, "numerical tree auditor scores configured encounters")
	var summary: Dictionary = report.get("summary", {})
	_check(int(summary.get("card_count", 0)) == cards.size(), "numerical tree card summary is consistent")
	_check(int(summary.get("player_count", 0)) == players.size(), "numerical tree player summary is consistent")
	_check(int(summary.get("monster_encounter_count", 0)) == monsters.size(), "numerical tree monster summary is consistent")
	var category_fixture := [
		{"type": "block", "target": "self", "amount": 8},
		{"type": "apply_status", "target": "self", "status": "strength", "amount": 1},
		{"type": "create_card", "target": "player", "card_id": "searing_wound", "amount": 1},
	]
	_check(auditor._phase_entry_effect_categories(category_fixture) == ["block", "status_card", "strength"], "phase entry audit distinguishes block, strength, and status-card pressure")
	for monster_value in monsters:
		var monster: Dictionary = monster_value
		if str(monster.get("tier", "")) == "boss":
			_check(int(monster.get("max_phase_entry_effect_categories", -1)) <= int(monster.get("phase_entry_effect_category_limit", 0)), "boss phase entry stays inside the configured pressure-category limit: %s" % str(monster.get("id", "")))
			_check(str(monster.get("phase_transition_mode", "")) == "highest_reached_only", "boss audit declares the runtime multi-threshold transition rule: %s" % str(monster.get("id", "")))
	_check(int(summary.get("player_warning_count", -1)) == 0, "playable characters satisfy the numerical tree")
	_check(report.get("economy", {}).has("expected_final_gold_range"), "numerical tree report includes economy targets")
	_check((report.get("progression", {}).get("trees", []) as Array).size() >= 3, "numerical tree report includes progression trees")
	var ember_strike: Dictionary = _row_by_id(cards, "ember_strike")
	_check(not ember_strike.is_empty(), "numerical tree report includes starter attack")
	_check(float(ember_strike.get("base_score", 0.0)) > 0.0, "numerical tree scores starter attack above zero")
	var pressure_surge: Dictionary = _row_by_id(cards, "pressure_surge")
	_check(is_equal_approx(float(pressure_surge.get("base_score", 0.0)), 12.6), "numerical tree scores unconditional damage plus the weighted momentum bonus")
	_check(not (pressure_surge.get("issues", []) as Array).has("under_budget"), "conditional bonus damage no longer produces a false under-budget advisory")
	var ash_guard: Dictionary = _row_by_id(cards, "ash_guard")
	_check(is_equal_approx(float(ash_guard.get("base_score", 0.0)), 7.04), "numerical tree weights only ash guard's conditional block bonus")
	var ember_exile: Dictionary = _row_by_id(players, "ember_exile")
	_check(int(ember_exile.get("max_hp", 0)) == 70 and int(ember_exile.get("starter_deck_size", 0)) == 10, "default character matches stable starter budget")
	_check(float(ember_exile.get("starter_deck_score", 0.0)) >= 76.0, "default starter deck meets its effect-point floor")
	var error: Error = auditor.save_report(report, REPORT_PATH)
	_check(error == OK and FileAccess.file_exists(REPORT_PATH), "numerical tree auditor saves JSON report")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(REPORT_PATH))
	_check(saved is Dictionary and str(saved.get("audit_model", "")) == "static_numerical_tree", "saved numerical tree report is valid JSON")
	if not _failures.is_empty():
		push_error("Numerical tree auditor test failed with %d issue(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return
	print("Numerical tree auditor smoke test passed.")
	quit(0)

func _row_by_id(rows: Array, row_id: String) -> Dictionary:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == row_id:
			return row
	return {}

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
