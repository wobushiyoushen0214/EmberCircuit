class_name PlaytestEvidenceGate
extends RefCounted

const MAX_FINISHED_RUNS_PER_CELL := 40
const MAX_ABANDONED_RUNS_PER_COHORT := 96
const MAX_EXCLUDED_RUNS_PER_COHORT := 96
const MAX_RETAINED_COHORTS := 4
const DIRECTIONAL_SAMPLE_THRESHOLD := 12
const HARD_GATE_SAMPLE_THRESHOLD := 30
const CARD_SAMPLE_THRESHOLD := 20
const CARD_COUNT_FIELDS := ["offers", "acquisitions", "removals", "upgrades", "plays"]

static func cohort_id(run: Dictionary) -> String:
	var payload := "%d|%s|%s" % [
		max(1, int(run.get("source_schema_version", run.get("schema_version", 1)))),
		str(run.get("game_version", "unknown")),
		str(run.get("config_fingerprint", ""))
	]
	return payload.sha256_text()

static func retain_runs(raw_runs: Array) -> Array:
	var unique_by_id: Dictionary = {}
	var order_by_id: Dictionary = {}
	var sequence := 0
	for run_value in raw_runs:
		if not run_value is Dictionary:
			continue
		var run: Dictionary = (run_value as Dictionary).duplicate(true)
		var run_id := str(run.get("run_id", ""))
		if run_id.is_empty():
			continue
		run["cohort_id"] = cohort_id(run)
		if not unique_by_id.has(run_id):
			unique_by_id[run_id] = run
			order_by_id[run_id] = sequence
		else:
			var existing: Dictionary = unique_by_id.get(run_id, {})
			var existing_is_finished := _run_is_finished(existing)
			var incoming_is_finished := _run_is_finished(run)
			if incoming_is_finished or not existing_is_finished:
				unique_by_id[run_id] = run
		sequence += 1

	var cohorts: Dictionary = {}
	for run_value in unique_by_id.values():
		var run: Dictionary = run_value
		var cohort := str(run.get("cohort_id", ""))
		var bucket: Dictionary = cohorts.get(cohort, {"latest": "", "latest_eligible": "", "runs": []})
		var bucket_runs: Array = bucket.get("runs", [])
		bucket_runs.append(run)
		bucket["runs"] = bucket_runs
		var timestamp := _run_timestamp(run)
		if timestamp > str(bucket.get("latest", "")):
			bucket["latest"] = timestamp
		if _run_is_gate_eligible(run) and timestamp > str(bucket.get("latest_eligible", "")):
			bucket["latest_eligible"] = timestamp
		cohorts[cohort] = bucket

	var cohort_rows: Array = []
	for cohort_value in cohorts.keys():
		cohort_rows.append({
			"cohort_id": str(cohort_value),
			"latest": str(cohorts.get(cohort_value, {}).get("latest", "")),
			"latest_eligible": str(cohorts.get(cohort_value, {}).get("latest_eligible", ""))
		})
	cohort_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_eligible := str(a.get("latest_eligible", ""))
		var b_eligible := str(b.get("latest_eligible", ""))
		if a_eligible != b_eligible:
			if a_eligible.is_empty():
				return false
			if b_eligible.is_empty():
				return true
			return a_eligible > b_eligible
		var a_latest := str(a.get("latest", ""))
		var b_latest := str(b.get("latest", ""))
		return str(a.get("cohort_id", "")) < str(b.get("cohort_id", "")) if a_latest == b_latest else a_latest > b_latest
	)

	var retained: Array = []
	for cohort_index in range(min(MAX_RETAINED_COHORTS, cohort_rows.size())):
		var cohort := str((cohort_rows[cohort_index] as Dictionary).get("cohort_id", ""))
		var bucket_runs: Array = cohorts.get(cohort, {}).get("runs", [])
		var finished_by_cell: Dictionary = {}
		var abandoned: Array = []
		var excluded: Array = []
		for run_value in bucket_runs:
			var run: Dictionary = run_value
			var outcome := str(run.get("outcome", ""))
			if not _run_is_gate_eligible(run):
				excluded.append(run)
			elif outcome == "abandoned":
				abandoned.append(run)
			elif outcome == "victory" or outcome == "defeat":
				var cell := "%s|%d" % [str(run.get("character_id", "")), int(run.get("challenge_level", 0))]
				var cell_runs: Array = finished_by_cell.get(cell, [])
				cell_runs.append(run)
				finished_by_cell[cell] = cell_runs
		for cell_value in finished_by_cell.keys():
			var cell_runs: Array = finished_by_cell.get(cell_value, [])
			_sort_runs(cell_runs)
			var start: int = max(0, cell_runs.size() - MAX_FINISHED_RUNS_PER_CELL)
			retained.append_array(cell_runs.slice(start, cell_runs.size()))
		_sort_runs(abandoned)
		var abandoned_start: int = max(0, abandoned.size() - MAX_ABANDONED_RUNS_PER_COHORT)
		retained.append_array(abandoned.slice(abandoned_start, abandoned.size()))
		_sort_runs(excluded)
		var excluded_start: int = max(0, excluded.size() - MAX_EXCLUDED_RUNS_PER_COHORT)
		retained.append_array(excluded.slice(excluded_start, excluded.size()))

	retained.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(order_by_id.get(str(a.get("run_id", "")), 0)) < int(order_by_id.get(str(b.get("run_id", "")), 0))
	)
	return retained

static func build_report(raw_runs: Array, context: Dictionary = {}) -> Dictionary:
	var cohort_groups := _cohort_groups(raw_runs)
	var cohorts: Array = []
	for group_value in cohort_groups:
		var group: Dictionary = group_value
		cohorts.append(_aggregate_cohort(group.get("runs", []), context))
	var primary_cohort: Dictionary = {}
	for cohort_value in cohorts:
		var cohort: Dictionary = cohort_value
		if _cohort_has_eligible_finished_run(cohort):
			primary_cohort = cohort
			break
	if primary_cohort.is_empty() and not cohorts.is_empty():
		primary_cohort = cohorts[0]
	var report := _empty_report(context)
	if not primary_cohort.is_empty():
		report = primary_cohort.duplicate(true)
	report["schema_version"] = 2
	report["report_kind"] = "human_playtest_local_export"
	report["generated_at_utc"] = str(context.get("generated_at_utc", _timestamp_utc()))
	report["privacy_note"] = "本报告不收集用户名、主目录、设备序列号或网络标识；不会自动联网发送。"
	report["primary_cohort_id"] = str(primary_cohort.get("cohort_id", ""))
	report["cohorts"] = cohorts
	report["cohort_count"] = cohorts.size()
	return report

static func merge_reports(reports: Array, context: Dictionary = {}) -> Dictionary:
	var runs_by_id: Dictionary = {}
	var canonical_by_id: Dictionary = {}
	for report_value in reports:
		if not report_value is Dictionary:
			return {"ok": false, "error_code": "malformed_report"}
		var report: Dictionary = report_value
		var report_runs: Array = []
		var cohorts_value: Variant = report.get("cohorts", [])
		if not cohorts_value is Array:
			return {"ok": false, "error_code": "malformed_report"}
		var cohorts: Array = cohorts_value
		if cohorts.is_empty():
			var runs_value: Variant = report.get("runs", [])
			if not runs_value is Array:
				return {"ok": false, "error_code": "malformed_report"}
			report_runs = runs_value
		else:
			for cohort_value in cohorts:
				if not cohort_value is Dictionary:
					return {"ok": false, "error_code": "malformed_report"}
				var cohort_runs: Variant = (cohort_value as Dictionary).get("runs", [])
				if not cohort_runs is Array:
					return {"ok": false, "error_code": "malformed_report"}
				report_runs.append_array(cohort_runs)
		for run_value in report_runs:
			if not run_value is Dictionary:
				return {"ok": false, "error_code": "malformed_run"}
			var run: Dictionary = (run_value as Dictionary).duplicate(true)
			var run_id := str(run.get("run_id", ""))
			if run_id.is_empty():
				return {"ok": false, "error_code": "run_id_missing"}
			if not _run_has_valid_aggregate_fields(run):
				return {"ok": false, "error_code": "malformed_run", "run_id": run_id}
			var canonical := JSON.stringify(run)
			if canonical_by_id.has(run_id) and str(canonical_by_id.get(run_id, "")) != canonical:
				return {"ok": false, "error_code": "duplicate_run_conflict", "run_id": run_id}
			canonical_by_id[run_id] = canonical
			runs_by_id[run_id] = run
	var merged_runs: Array = runs_by_id.values()
	_sort_runs(merged_runs)
	var merged_context := _merged_report_context(reports, context)
	return {"ok": true, "report": build_report(merged_runs, merged_context)}

static func _run_has_valid_aggregate_fields(run: Dictionary) -> bool:
	if not ["victory", "defeat", "abandoned"].has(str(run.get("outcome", ""))):
		return false
	for field in ["summary", "final", "card_telemetry", "failure"]:
		if run.has(field) and not run.get(field) is Dictionary:
			return false
	if run.has("route") and not run.get("route") is Array:
		return false
	var final_state: Dictionary = run.get("final", {})
	if final_state.has("completed_chapter_ids") and not final_state.get("completed_chapter_ids") is Array:
		return false
	var card_telemetry: Dictionary = run.get("card_telemetry", {})
	for card_value in card_telemetry.values():
		if not card_value is Dictionary:
			return false
	return true

static func _merged_report_context(reports: Array, context: Dictionary) -> Dictionary:
	var merged_context := context.duplicate(true)
	var character_ids: Array = merged_context.get("expected_character_ids", []).duplicate()
	var challenge_levels: Array = merged_context.get("expected_challenge_levels", []).duplicate()
	if not character_ids.is_empty() and not challenge_levels.is_empty():
		return merged_context
	for report_value in reports:
		if not report_value is Dictionary:
			continue
		var report: Dictionary = report_value
		var cohorts: Array = report.get("cohorts", [])
		if cohorts.is_empty():
			_append_coverage_axes(report.get("coverage", {}), character_ids, challenge_levels)
		else:
			for cohort_value in cohorts:
				if cohort_value is Dictionary:
					_append_coverage_axes((cohort_value as Dictionary).get("coverage", {}), character_ids, challenge_levels)
	character_ids.sort()
	challenge_levels.sort()
	merged_context["expected_character_ids"] = character_ids
	merged_context["expected_challenge_levels"] = challenge_levels
	return merged_context

static func _append_coverage_axes(coverage_value: Variant, character_ids: Array, challenge_levels: Array) -> void:
	if not coverage_value is Dictionary:
		return
	for cell_value in (coverage_value as Dictionary).get("cells", []):
		if not cell_value is Dictionary:
			continue
		var cell: Dictionary = cell_value
		var character_id := str(cell.get("character_id", ""))
		var challenge_level := int(cell.get("challenge_level", 0))
		if not character_id.is_empty() and not character_ids.has(character_id):
			character_ids.append(character_id)
		if not challenge_levels.has(challenge_level):
			challenge_levels.append(challenge_level)

static func _cohort_has_eligible_finished_run(cohort: Dictionary) -> bool:
	for run_value in cohort.get("runs", []):
		if run_value is Dictionary and bool((run_value as Dictionary).get("gate_eligible", false)) and _run_is_finished(run_value):
			return true
	return false

static func _cohort_groups(raw_runs: Array) -> Array:
	var groups: Dictionary = {}
	for run_value in raw_runs:
		if not run_value is Dictionary:
			continue
		var run: Dictionary = run_value
		var cohort := cohort_id(run)
		var group: Dictionary = groups.get(cohort, {"cohort_id": cohort, "latest": "", "latest_eligible": "", "runs": []})
		var runs: Array = group.get("runs", [])
		runs.append(run)
		group["runs"] = runs
		var timestamp := _run_timestamp(run)
		if timestamp > str(group.get("latest", "")):
			group["latest"] = timestamp
		if _run_is_gate_eligible(run) and _run_is_finished(run) and timestamp > str(group.get("latest_eligible", "")):
			group["latest_eligible"] = timestamp
		groups[cohort] = group
	var rows: Array = groups.values()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_eligible := str(a.get("latest_eligible", ""))
		var b_eligible := str(b.get("latest_eligible", ""))
		if a_eligible != b_eligible:
			if a_eligible.is_empty():
				return false
			if b_eligible.is_empty():
				return true
			return a_eligible > b_eligible
		var a_latest := str(a.get("latest", ""))
		var b_latest := str(b.get("latest", ""))
		return str(a.get("cohort_id", "")) < str(b.get("cohort_id", "")) if a_latest == b_latest else a_latest > b_latest
	)
	return rows

static func _aggregate_cohort(runs: Array, context: Dictionary) -> Dictionary:
	var evidence_runs: Array = []
	for run_value in runs:
		if run_value is Dictionary and _run_is_gate_eligible(run_value):
			evidence_runs.append(run_value)
	var victories := 0
	var defeats := 0
	var abandoned := 0
	var total_turns := 0
	var total_chapters := 0
	var total_loads := 0
	var by_character: Dictionary = {}
	var by_challenge: Dictionary = {}
	var by_character_challenge: Dictionary = {}
	var card_aggregates: Dictionary = {}
	var failure_counts: Dictionary = {}
	var first_run: Dictionary = runs[0] if not runs.is_empty() else {}
	for run_value in evidence_runs:
		var run: Dictionary = run_value
		var outcome := str(run.get("outcome", ""))
		if outcome == "victory":
			victories += 1
		elif outcome == "defeat":
			defeats += 1
		elif outcome == "abandoned":
			abandoned += 1
		var summary: Dictionary = run.get("summary", {})
		total_loads += int(summary.get("loads", 0))
		if outcome == "victory" or outcome == "defeat":
			total_turns += int(summary.get("turns", 0))
		total_chapters += (run.get("final", {}).get("completed_chapter_ids", []) as Array).size()
		_aggregate_dimension(by_character, str(run.get("character_id", "unknown")), outcome)
		_aggregate_dimension(by_challenge, str(int(run.get("challenge_level", 0))), outcome)
		_aggregate_dimension(by_character_challenge, "%s|%d" % [str(run.get("character_id", "unknown")), int(run.get("challenge_level", 0))], outcome)
		var failure: Dictionary = run.get("failure", {})
		var failure_id := str(failure.get("encounter_id", ""))
		if outcome == "defeat" and not failure_id.is_empty():
			_increment_count_map(failure_counts, failure_id, 1)
		_aggregate_cards(card_aggregates, run)
	var finished_runs := victories + defeats
	var card_rows := _card_rows(card_aggregates, finished_runs, victories, defeats)
	var failure_rows := _failure_rows(failure_counts, defeats)
	return {
		"cohort_id": cohort_id(first_run) if not first_run.is_empty() else "",
		"game_version": str(first_run.get("game_version", "unknown")),
		"config_fingerprint": str(first_run.get("config_fingerprint", "")),
		"telemetry_schema_version": int(first_run.get("source_schema_version", first_run.get("schema_version", 1))),
		"latest_run_finished_at_utc": _latest_run_timestamp(evidence_runs),
		"summary": {
			"total_runs": evidence_runs.size(),
			"finished_runs": finished_runs,
			"victories": victories,
			"defeats": defeats,
			"abandoned": abandoned,
			"win_rate": float(victories) / float(finished_runs) if finished_runs > 0 else 0.0,
			"abandon_rate": float(abandoned) / float(evidence_runs.size()) if not evidence_runs.is_empty() else 0.0,
			"average_turns": float(total_turns) / float(finished_runs) if finished_runs > 0 else 0.0,
			"average_chapters_completed": float(total_chapters) / float(evidence_runs.size()) if not evidence_runs.is_empty() else 0.0,
			"loads": total_loads,
			"active_run_present": false
		},
		"by_character": _dimension_rows(by_character, "character_id"),
		"by_challenge": _dimension_rows(by_challenge, "challenge_level"),
		"by_character_challenge": _character_challenge_rows(by_character_challenge),
		"card_telemetry": card_rows,
		"failure_encounters": failure_rows,
		"coverage": _coverage(evidence_runs, context),
		"excluded_run_count": runs.size() - evidence_runs.size(),
		"active_run": {},
		"runs": evidence_runs.duplicate(true)
	}

static func _coverage(runs: Array, context: Dictionary) -> Dictionary:
	var character_ids: Array = context.get("expected_character_ids", []).duplicate()
	var challenge_levels: Array = context.get("expected_challenge_levels", []).duplicate()
	if character_ids.is_empty() or challenge_levels.is_empty():
		for run_value in runs:
			var run: Dictionary = run_value
			var character_id := str(run.get("character_id", ""))
			var challenge_level := int(run.get("challenge_level", 0))
			if not character_id.is_empty() and not character_ids.has(character_id):
				character_ids.append(character_id)
			if not challenge_levels.has(challenge_level):
				challenge_levels.append(challenge_level)
	character_ids.sort()
	challenge_levels.sort()
	var counts: Dictionary = {}
	for run_value in runs:
		var run: Dictionary = run_value
		if not _run_is_gate_eligible(run) or not ["victory", "defeat"].has(str(run.get("outcome", ""))):
			continue
		var key := "%s|%d" % [str(run.get("character_id", "")), int(run.get("challenge_level", 0))]
		counts[key] = int(counts.get(key, 0)) + 1
	var cells: Array = []
	var directional_ready := 0
	var hard_gate_ready := 0
	var missing_directional := 0
	var missing_hard := 0
	for character_id_value in character_ids:
		for challenge_level_value in challenge_levels:
			var character_id := str(character_id_value)
			var challenge_level := int(challenge_level_value)
			var key := "%s|%d" % [character_id, challenge_level]
			var finished := int(counts.get(key, 0))
			var status := "insufficient"
			if finished >= HARD_GATE_SAMPLE_THRESHOLD:
				status = "hard_gate_ready"
				hard_gate_ready += 1
				directional_ready += 1
			elif finished >= DIRECTIONAL_SAMPLE_THRESHOLD:
				status = "directional_ready"
				directional_ready += 1
			missing_directional += max(0, DIRECTIONAL_SAMPLE_THRESHOLD - finished)
			missing_hard += max(0, HARD_GATE_SAMPLE_THRESHOLD - finished)
			cells.append({
				"character_id": character_id,
				"challenge_level": challenge_level,
				"finished_runs": finished,
				"status": status,
				"missing_for_directional": max(0, DIRECTIONAL_SAMPLE_THRESHOLD - finished),
				"missing_for_hard_gate": max(0, HARD_GATE_SAMPLE_THRESHOLD - finished)
			})
	return {
		"cells": cells,
		"total_cells": cells.size(),
		"directional_ready_cells": directional_ready,
		"hard_gate_ready_cells": hard_gate_ready,
		"missing_finished_for_directional": missing_directional,
		"missing_finished_for_hard_gate": missing_hard,
		"directional_threshold": DIRECTIONAL_SAMPLE_THRESHOLD,
		"hard_gate_threshold": HARD_GATE_SAMPLE_THRESHOLD,
		"card_threshold": CARD_SAMPLE_THRESHOLD
	}

static func _empty_report(context: Dictionary) -> Dictionary:
	return {
		"summary": {"total_runs": 0, "finished_runs": 0, "victories": 0, "defeats": 0, "abandoned": 0, "win_rate": 0.0, "abandon_rate": 0.0, "average_turns": 0.0, "average_chapters_completed": 0.0, "loads": 0, "active_run_present": false},
		"by_character": [], "by_challenge": [], "by_character_challenge": [], "card_telemetry": [], "failure_encounters": [],
		"coverage": _coverage([], context), "active_run": {}, "runs": []
	}

static func _aggregate_dimension(target: Dictionary, id_value: String, outcome: String) -> void:
	var id := id_value if not id_value.is_empty() else "unknown"
	var row: Dictionary = target.get(id, {"runs": 0, "victories": 0, "defeats": 0, "abandoned": 0})
	row["runs"] = int(row.get("runs", 0)) + 1
	if outcome == "victory":
		row["victories"] = int(row.get("victories", 0)) + 1
	elif outcome == "defeat":
		row["defeats"] = int(row.get("defeats", 0)) + 1
	elif outcome == "abandoned":
		row["abandoned"] = int(row.get("abandoned", 0)) + 1
	target[id] = row

static func _dimension_rows(source: Dictionary, id_field: String) -> Array:
	var ids: Array = source.keys()
	ids.sort()
	var rows: Array = []
	for id_value in ids:
		var row: Dictionary = source.get(id_value, {}).duplicate(true)
		row[id_field] = int(id_value) if id_field == "challenge_level" else str(id_value)
		var finished := int(row.get("victories", 0)) + int(row.get("defeats", 0))
		row["finished_runs"] = finished
		row["win_rate"] = float(row.get("victories", 0)) / float(finished) if finished > 0 else 0.0
		row["abandon_rate"] = float(row.get("abandoned", 0)) / float(row.get("runs", 0)) if int(row.get("runs", 0)) > 0 else 0.0
		rows.append(row)
	return rows

static func _character_challenge_rows(source: Dictionary) -> Array:
	var keys: Array = source.keys()
	keys.sort()
	var rows: Array = []
	for key_value in keys:
		var key := str(key_value)
		var row: Dictionary = source.get(key_value, {}).duplicate(true)
		row["character_id"] = key.get_slice("|", 0)
		row["challenge_level"] = int(key.get_slice("|", 1))
		var finished := int(row.get("victories", 0)) + int(row.get("defeats", 0))
		row["finished_runs"] = finished
		row["win_rate"] = float(row.get("victories", 0)) / float(finished) if finished > 0 else 0.0
		row["abandon_rate"] = float(row.get("abandoned", 0)) / float(row.get("runs", 0)) if int(row.get("runs", 0)) > 0 else 0.0
		rows.append(row)
	return rows

static func _aggregate_cards(target: Dictionary, run: Dictionary) -> void:
	var won := str(run.get("outcome", "")) == "victory"
	var lost := str(run.get("outcome", "")) == "defeat"
	var cards: Dictionary = run.get("card_telemetry", {})
	for card_id_value in cards.keys():
		var card_id := str(card_id_value)
		var source: Dictionary = cards.get(card_id_value, {})
		var row: Dictionary = target.get(card_id, {"id": card_id, "offers": 0, "acquisitions": 0, "removals": 0, "upgrades": 0, "plays": 0, "offer_sources": {}, "acquisition_sources": {}, "runs_acquired": 0, "wins_when_acquired": 0, "losses_when_acquired": 0, "runs_played": 0, "wins_when_played": 0, "losses_when_played": 0})
		for field in CARD_COUNT_FIELDS:
			row[str(field)] = int(row.get(field, 0)) + int(source.get(field, 0))
		_merge_count_map(row.get("offer_sources", {}), source.get("offer_sources", {}))
		_merge_count_map(row.get("acquisition_sources", {}), source.get("acquisition_sources", {}))
		if int(source.get("acquisitions", 0)) > 0:
			row["runs_acquired"] = int(row.get("runs_acquired", 0)) + 1
			if won:
				row["wins_when_acquired"] = int(row.get("wins_when_acquired", 0)) + 1
			elif lost:
				row["losses_when_acquired"] = int(row.get("losses_when_acquired", 0)) + 1
		if int(source.get("plays", 0)) > 0:
			row["runs_played"] = int(row.get("runs_played", 0)) + 1
			if won:
				row["wins_when_played"] = int(row.get("wins_when_played", 0)) + 1
			elif lost:
				row["losses_when_played"] = int(row.get("losses_when_played", 0)) + 1
		target[card_id] = row

static func _card_rows(aggregates: Dictionary, finished_runs: int, victories: int, defeats: int) -> Array:
	var rows: Array = []
	for card_id_value in aggregates.keys():
		var row: Dictionary = aggregates.get(card_id_value, {})
		_finalize_card_aggregate(row, finished_runs, victories, defeats)
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_plays := int(a.get("plays", 0))
		var b_plays := int(b.get("plays", 0))
		return str(a.get("id", "")) < str(b.get("id", "")) if a_plays == b_plays else a_plays > b_plays
	)
	return rows

static func _finalize_card_aggregate(row: Dictionary, finished_runs: int, victories: int, defeats: int) -> void:
	var offers := int(row.get("offers", 0))
	var acquisitions := int(row.get("acquisitions", 0))
	var acquired_finished := int(row.get("wins_when_acquired", 0)) + int(row.get("losses_when_acquired", 0))
	var played_finished := int(row.get("wins_when_played", 0)) + int(row.get("losses_when_played", 0))
	var not_acquired_finished: int = max(0, finished_runs - acquired_finished)
	var not_played_finished: int = max(0, finished_runs - played_finished)
	var wins_not_acquired: int = max(0, victories - int(row.get("wins_when_acquired", 0)))
	var wins_not_played: int = max(0, victories - int(row.get("wins_when_played", 0)))
	row["acquisition_rate_per_offer"] = float(acquisitions) / float(offers) if offers > 0 else 0.0
	row["finished_runs_acquired"] = acquired_finished
	row["win_rate_when_acquired"] = float(row.get("wins_when_acquired", 0)) / float(acquired_finished) if acquired_finished > 0 else 0.0
	row["finished_runs_played"] = played_finished
	row["win_rate_when_played"] = float(row.get("wins_when_played", 0)) / float(played_finished) if played_finished > 0 else 0.0
	row["runs_not_acquired"] = not_acquired_finished
	row["wins_when_not_acquired"] = wins_not_acquired
	row["losses_when_not_acquired"] = max(0, defeats - int(row.get("losses_when_acquired", 0)))
	row["win_rate_when_not_acquired"] = float(wins_not_acquired) / float(not_acquired_finished) if not_acquired_finished > 0 else 0.0
	row["acquisition_comparison_available"] = acquired_finished > 0 and not_acquired_finished > 0
	row["acquisition_sample_ready"] = acquired_finished >= CARD_SAMPLE_THRESHOLD and not_acquired_finished >= CARD_SAMPLE_THRESHOLD
	row["win_rate_lift_when_acquired"] = float(row.get("win_rate_when_acquired", 0.0)) - float(row.get("win_rate_when_not_acquired", 0.0)) if bool(row.get("acquisition_comparison_available", false)) else 0.0
	row["runs_not_played"] = not_played_finished
	row["wins_when_not_played"] = wins_not_played
	row["losses_when_not_played"] = max(0, defeats - int(row.get("losses_when_played", 0)))
	row["win_rate_when_not_played"] = float(wins_not_played) / float(not_played_finished) if not_played_finished > 0 else 0.0
	row["play_comparison_available"] = played_finished > 0 and not_played_finished > 0
	row["play_sample_ready"] = played_finished >= CARD_SAMPLE_THRESHOLD and not_played_finished >= CARD_SAMPLE_THRESHOLD
	row["win_rate_lift_when_played"] = float(row.get("win_rate_when_played", 0.0)) - float(row.get("win_rate_when_not_played", 0.0)) if bool(row.get("play_comparison_available", false)) else 0.0
	row["comparison_sample_threshold"] = CARD_SAMPLE_THRESHOLD

static func _failure_rows(counts: Dictionary, defeats: int) -> Array:
	var rows: Array = []
	for encounter_id_value in counts.keys():
		var count := int(counts.get(encounter_id_value, 0))
		rows.append({"encounter_id": str(encounter_id_value), "defeats": count, "share_of_defeats": float(count) / float(defeats) if defeats > 0 else 0.0})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_count := int(a.get("defeats", 0))
		var b_count := int(b.get("defeats", 0))
		return str(a.get("encounter_id", "")) < str(b.get("encounter_id", "")) if a_count == b_count else a_count > b_count
	)
	return rows

static func _merge_count_map(target_value: Variant, source_value: Variant) -> void:
	if not target_value is Dictionary or not source_value is Dictionary:
		return
	for key_value in (source_value as Dictionary).keys():
		_increment_count_map(target_value as Dictionary, str(key_value), int((source_value as Dictionary).get(key_value, 0)))

static func _increment_count_map(counts: Dictionary, id_value: String, amount: int) -> void:
	var id := id_value.strip_edges()
	if id.is_empty():
		id = "unknown"
	counts[id] = max(0, int(counts.get(id, 0)) + amount)

static func _latest_run_timestamp(runs: Array) -> String:
	var latest := ""
	for run_value in runs:
		var timestamp := _run_timestamp(run_value)
		if timestamp > latest:
			latest = timestamp
	return latest

static func _timestamp_utc() -> String:
	var timestamp := Time.get_datetime_string_from_system(true, true)
	return timestamp if timestamp.ends_with("Z") else "%sZ" % timestamp

static func _sort_runs(runs: Array) -> void:
	runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [_run_timestamp(a), str(a.get("run_id", ""))]
		var b_key := "%s|%s" % [_run_timestamp(b), str(b.get("run_id", ""))]
		return a_key < b_key
	)

static func _run_timestamp(run: Dictionary) -> String:
	var finished := str(run.get("finished_at_utc", ""))
	return finished if not finished.is_empty() else str(run.get("started_at_utc", ""))

static func _run_is_finished(run: Dictionary) -> bool:
	return ["victory", "defeat"].has(str(run.get("outcome", "")))

static func _run_is_gate_eligible(run: Dictionary) -> bool:
	return bool(run.get("gate_eligible", false)) and str(run.get("sample_kind", "")) == "human"
