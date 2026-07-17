extends SceneTree

const PlaytestTelemetryScript = preload("res://scripts/core/PlaytestTelemetry.gd")

var failed: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	var fingerprint: String = PlaytestTelemetryScript.configuration_fingerprint()
	_check(fingerprint.length() == 64, "gameplay configuration fingerprint is SHA-256")

	var store: Dictionary = PlaytestTelemetryScript.start_run(
		PlaytestTelemetryScript.default_store(),
		{
			"run_id": "fixture-run-001",
			"timestamp_utc": "2026-07-15T10:00:00Z",
			"game_version": "0.1.0.1",
			"engine_version": "4.7.stable",
			"config_fingerprint": fingerprint,
			"platform": "TestOS",
			"display_size": [1280, 720],
			"display_scale": 1.25,
			"locale": "zh_CN",
			"character_id": "ember_exile",
			"challenge_level": 2,
			"skill_book_id": "steel_manual",
			"progression_node_ids": ["ember_hp_1"],
			"starting_hp": 66,
			"max_hp": 72,
			"starting_gold": 99,
			"starting_deck_ids": ["ember_strike", "ash_guard+"],
			"starting_relic_ids": ["ember_bottle"],
			"starting_potion_ids": []
		}
	)
	var run: Dictionary = PlaytestTelemetryScript.active_run(store)
	_check(str(run.get("run_id", "")) == "fixture-run-001", "run keeps its anonymous id")
	_check(str(run.get("outcome", "")) == "in_progress", "new run starts in progress")
	_check(is_equal_approx(float(run.get("environment", {}).get("display_scale", 0.0)), 1.25), "run records display scale for UI compatibility analysis")
	_check(str(run.get("environment", {}).get("locale", "")) == "zh_CN", "run records locale without collecting identity")
	_check(not run.has("username") and not run.has("home_path"), "run schema excludes direct identity and home paths")

	_check(PlaytestTelemetryScript.record_node_started(run, {
		"chapter_id": "chapter_one",
		"node_id": "combat_1",
		"node_type": "combat",
		"encounter_id": "intro_patrol",
		"is_battle": true,
		"hp": 66,
		"gold": 99,
		"deck_size": 10
	}), "first node start is recorded")
	_check(not PlaytestTelemetryScript.record_node_started(run, {
		"chapter_id": "chapter_one",
		"node_id": "combat_1",
		"node_type": "combat",
		"encounter_id": "intro_patrol",
		"is_battle": true
	}), "duplicate current node start is ignored")

	PlaytestTelemetryScript.record_card_offers(run, ["ember_strike+", "ash_guard"], "combat_reward")
	PlaytestTelemetryScript.record_card_acquired(run, "ember_strike+", "combat_reward")
	PlaytestTelemetryScript.record_card_played(run, "ember_strike+")
	PlaytestTelemetryScript.record_card_played(run, "ember_strike")
	PlaytestTelemetryScript.record_card_removed(run, "ash_guard+")
	PlaytestTelemetryScript.record_card_upgraded(run, "ember_strike")
	PlaytestTelemetryScript.record_item_acquired(run, "relics", "heavy_gear", "elite_reward")
	PlaytestTelemetryScript.record_item_acquired(run, "potions", "volatile_vial", "combat_reward")
	PlaytestTelemetryScript.record_potion_used(run, "volatile_vial")
	PlaytestTelemetryScript.record_run_loaded(run)
	_check(PlaytestTelemetryScript.record_node_finished(run, {
		"chapter_id": "chapter_one",
		"node_id": "combat_1",
		"result": "won",
		"turns": 4,
		"hp": 51,
		"gold": 116,
		"deck_size": 10,
		"is_battle": true
	}), "combat result is recorded once")
	_check(not PlaytestTelemetryScript.record_node_finished(run, {
		"chapter_id": "chapter_one",
		"node_id": "combat_1",
		"result": "won",
		"turns": 4,
		"is_battle": true
	}), "duplicate combat result is ignored")

	PlaytestTelemetryScript.record_node_started(run, {
		"chapter_id": "chapter_one",
		"node_id": "event_1",
		"node_type": "event",
		"event_id": "broken_reactor",
		"is_battle": false,
		"hp": 51,
		"gold": 116,
		"deck_size": 10
	})
	PlaytestTelemetryScript.record_event_choice(run, "broken_reactor", "tap_pressure_line", "cinder_backwash")
	PlaytestTelemetryScript.record_reward_skipped(run, "card")
	PlaytestTelemetryScript.record_node_finished(run, {
		"chapter_id": "chapter_one",
		"node_id": "event_1",
		"result": "completed",
		"hp": 45,
		"gold": 151,
		"deck_size": 10,
		"is_battle": false
	})

	store["active_run"] = run
	store = PlaytestTelemetryScript.finish_active_run(store, "victory", {
		"timestamp_utc": "2026-07-15T11:00:00Z",
		"chapter_id": "chapter_three",
		"node_id": "chapter_three_boss",
		"encounter_id": "chapter_three_boss",
		"hp": 23,
		"max_hp": 72,
		"gold": 151,
		"deck_ids": ["ember_strike+", "ash_guard"],
		"relic_ids": ["ember_bottle", "heavy_gear"],
		"potion_ids": [],
		"completed_chapter_ids": ["chapter_one", "chapter_two", "chapter_three"],
		"deck_mastery_id": "offense_forging"
	})
	_check(PlaytestTelemetryScript.active_run(store).is_empty(), "finished run leaves no active run")
	_check(store.get("runs", []).size() == 1, "finished run is archived")
	var retried_terminal_store: Dictionary = store.duplicate(true)
	retried_terminal_store["active_run"] = run.duplicate(true)
	retried_terminal_store = PlaytestTelemetryScript.finish_active_run(retried_terminal_store, "victory", {
		"timestamp_utc": "2026-07-15T11:00:01Z",
		"chapter_id": "chapter_three",
		"node_id": "chapter_three_boss"
	})
	_check(retried_terminal_store.get("runs", []).size() == 1 and str((retried_terminal_store.get("runs", [])[0] as Dictionary).get("run_id", "")) == "fixture-run-001", "retrying terminal persistence replaces the same anonymous run instead of duplicating it")
	var stale_restore_store := PlaytestTelemetryScript.set_active_run(store, run.duplicate(true))
	_check(PlaytestTelemetryScript.active_run(stale_restore_store).is_empty() and str((stale_restore_store.get("runs", [])[0] as Dictionary).get("outcome", "")) == "victory", "a stale save cannot reactivate a run whose victory is already archived")
	var conflicting_terminal_store: Dictionary = store.duplicate(true)
	conflicting_terminal_store["active_run"] = run.duplicate(true)
	conflicting_terminal_store = PlaytestTelemetryScript.finish_active_run(conflicting_terminal_store, "defeat", {
		"timestamp_utc": "2026-07-15T11:00:02Z",
		"chapter_id": "chapter_three",
		"node_id": "chapter_three_boss"
	})
	var immutable_terminal: Dictionary = conflicting_terminal_store.get("runs", [])[0]
	_check(conflicting_terminal_store.get("runs", []).size() == 1 and str(immutable_terminal.get("outcome", "")) == "victory" and int(immutable_terminal.get("final", {}).get("hp", 0)) == 23, "an archived victory is immutable when a stale active snapshot later reports another outcome")

	var archived: Dictionary = store.get("runs", [])[0]
	var summary: Dictionary = archived.get("summary", {})
	var cards: Dictionary = archived.get("card_telemetry", {})
	var strike: Dictionary = cards.get("ember_strike", {})
	var guard: Dictionary = cards.get("ash_guard", {})
	_check(str(archived.get("outcome", "")) == "victory", "archived run records victory")
	_check(int(summary.get("nodes_visited", 0)) == 2, "run counts visited nodes")
	_check(int(summary.get("combats_started", 0)) == 1 and int(summary.get("combats_won", 0)) == 1, "run counts combat outcomes")
	_check(int(summary.get("turns", 0)) == 4 and int(summary.get("cards_played", 0)) == 2, "run counts turns and card plays")
	_check(int(summary.get("potions_used", 0)) == 1, "run counts used potions")
	_check(int(summary.get("loads", 0)) == 1, "run records save-load restarts for later filtering")
	_check(str((archived.get("event_choices", [])[0] as Dictionary).get("result_id", "")) == "cinder_backwash", "event telemetry retains deterministic or random result ids")
	_check(int(strike.get("offers", 0)) == 1 and int(strike.get("acquisitions", 0)) == 1, "card offers and acquisitions are counted")
	_check(int(strike.get("plays", 0)) == 2 and int(strike.get("upgrades", 0)) == 1, "upgraded card activity normalizes to its base id")
	_check(int(guard.get("offers", 0)) == 1 and int(guard.get("removals", 0)) == 1, "removed upgraded card normalizes to its base id")
	_check(int(strike.get("acquisition_sources", {}).get("combat_reward", 0)) == 1, "card acquisition source is retained")

	var report: Dictionary = PlaytestTelemetryScript.build_report(store, {
		"generated_at_utc": "2026-07-15T12:00:00Z"
	})
	var report_summary: Dictionary = report.get("summary", {})
	var report_cards: Array = report.get("card_telemetry", [])
	_check(int(report.get("schema_version", 0)) == PlaytestTelemetryScript.SCHEMA_VERSION, "report exposes schema version")
	_check(str(report.get("report_kind", "")) == "human_playtest_local_export", "report identifies human data separately from AI simulation")
	_check(str(report.get("privacy_note", "")).contains("不收集"), "report states its privacy boundary")
	_check(int(report_summary.get("total_runs", 0)) == 1 and int(report_summary.get("victories", 0)) == 1, "report aggregates run outcomes")
	_check(is_equal_approx(float(report_summary.get("win_rate", 0.0)), 1.0), "report computes finished-run win rate")
	_check(is_equal_approx(float(report_summary.get("abandon_rate", -1.0)), 0.0), "report computes abandon rate outside the win-rate denominator")
	_check(is_equal_approx(float(report_summary.get("average_turns", 0.0)), 4.0), "report computes average turns")
	var cells: Array = report.get("by_character_challenge", [])
	_check(cells.size() == 1 and str((cells[0] as Dictionary).get("character_id", "")) == "ember_exile" and int((cells[0] as Dictionary).get("challenge_level", -1)) == 2, "report aggregates the character by challenge analysis cell")
	_check(int((cells[0] as Dictionary).get("finished_runs", 0)) == 1 and is_equal_approx(float((cells[0] as Dictionary).get("abandon_rate", -1.0)), 0.0), "analysis cells expose finished sample size and abandon rate")
	_check(_report_card(report_cards, "ember_strike").get("plays", 0) == 2, "report aggregates card activity")
	_check(report.get("runs", []).size() == 1, "report includes raw anonymized run rows")

	var comparison_store: Dictionary = PlaytestTelemetryScript.start_run(store, {
		"run_id": "fixture-run-002",
		"timestamp_utc": "2026-07-15T13:00:00Z",
		"game_version": "0.1.0.1",
		"engine_version": "4.7.stable",
		"config_fingerprint": fingerprint,
		"character_id": "ember_exile",
		"challenge_level": 2
	})
	var comparison_run: Dictionary = PlaytestTelemetryScript.active_run(comparison_store)
	PlaytestTelemetryScript.record_node_started(comparison_run, {
		"chapter_id": "chapter_one",
		"node_id": "combat_2",
		"node_type": "combat",
		"encounter_id": "polluted_lab",
		"is_battle": true
	})
	PlaytestTelemetryScript.record_node_finished(comparison_run, {
		"chapter_id": "chapter_one",
		"node_id": "combat_2",
		"result": "lost",
		"turns": 3,
		"is_battle": true
	})
	comparison_store["active_run"] = comparison_run
	comparison_store = PlaytestTelemetryScript.finish_active_run(comparison_store, "defeat", {"encounter_id": "polluted_lab"})
	var comparison_report: Dictionary = PlaytestTelemetryScript.build_report(comparison_store)
	var comparison_strike: Dictionary = _report_card(comparison_report.get("card_telemetry", []), "ember_strike")
	_check(bool(comparison_strike.get("acquisition_comparison_available", false)), "card report enables acquisition comparison when both cohorts exist")
	_check(int(comparison_strike.get("finished_runs_acquired", 0)) == 1, "card report exposes the finished acquisition cohort size")
	_check(int(comparison_strike.get("runs_not_acquired", 0)) == 1, "card report counts finished runs without acquisition")
	_check(is_equal_approx(float(comparison_strike.get("win_rate_lift_when_acquired", 0.0)), 1.0), "card report computes acquisition win-rate lift")
	_check(bool(comparison_strike.get("play_comparison_available", false)), "card report enables play comparison when both cohorts exist")
	_check(int(comparison_strike.get("finished_runs_played", 0)) == 1, "card report exposes the finished play cohort size")
	_check(is_equal_approx(float(comparison_strike.get("win_rate_lift_when_played", 0.0)), 1.0), "card report computes play win-rate lift")
	var failure_rows: Array = comparison_report.get("failure_encounters", [])
	_check(failure_rows.size() == 1 and is_equal_approx(float((failure_rows[0] as Dictionary).get("share_of_defeats", 0.0)), 1.0), "failure report exposes encounter concentration directly")

	var bounded_store: Dictionary = PlaytestTelemetryScript.default_store()
	for index in range(110):
		var sample_day: int = 15 + index / 24
		var sample_hour: int = index % 24
		bounded_store = PlaytestTelemetryScript.start_run(bounded_store, {
			"run_id": "bounded-%03d" % index,
			"timestamp_utc": "2026-07-%02dT%02d:00:00Z" % [sample_day, sample_hour],
			"character_id": "ember_exile"
		})
		bounded_store = PlaytestTelemetryScript.finish_active_run(bounded_store, "abandoned", {
			"timestamp_utc": "2026-07-%02dT%02d:30:00Z" % [sample_day, sample_hour]
		})
	_check(bounded_store.get("runs", []).size() == PlaytestTelemetryScript.MAX_RUN_HISTORY, "local playtest history stays bounded")
	_check(str((bounded_store.get("runs", [])[0] as Dictionary).get("run_id", "")) == "bounded-014", "bounded abandoned history retains the newest runs without consuming finished-run capacity")
	var bounded_report: Dictionary = PlaytestTelemetryScript.build_report(bounded_store)
	_check(int(bounded_report.get("summary", {}).get("finished_runs", -1)) == 0, "abandoned runs never enter the win-rate denominator")
	_check(is_equal_approx(float(bounded_report.get("summary", {}).get("win_rate", -1.0)), 0.0), "unfinished-only history has a zero win rate instead of a false loss rate")
	_check(is_equal_approx(float(bounded_report.get("summary", {}).get("abandon_rate", 0.0)), 1.0), "unfinished-only history reports a full abandon rate separately")

	if failed:
		quit(1)
		return
	print("Playtest telemetry contract test passed.")
	quit(0)

func _report_card(rows: Array, card_id: String) -> Dictionary:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == card_id:
			return row
	return {}

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("Test failed: %s" % message)
