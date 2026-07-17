class_name PlaytestTelemetry
extends RefCounted

const PlaytestEvidenceGateScript = preload("res://scripts/core/PlaytestEvidenceGate.gd")

const SCHEMA_VERSION := 2
const MAX_ABANDONED_RUN_HISTORY := PlaytestEvidenceGateScript.MAX_ABANDONED_RUNS_PER_COHORT
# Compatibility alias for existing consumers; retention is now cohort/cell aware.
const MAX_RUN_HISTORY := MAX_ABANDONED_RUN_HISTORY
const TERMINAL_OUTCOMES := ["victory", "defeat", "abandoned"]
const GAMEPLAY_CONFIG_PATHS := [
	"res://data/cards/cards.json",
	"res://data/config/challenges.json",
	"res://data/config/card_balance_budgets.json",
	"res://data/config/chapter_one_route.json",
	"res://data/config/economy.json",
	"res://data/config/level_tree.json",
	"res://data/config/map_generation.json",
	"res://data/config/monster_scaling.json",
	"res://data/config/numerical_tree.json",
	"res://data/config/player.json",
	"res://data/config/progression_systems.json",
	"res://data/encounters/encounters.json",
	"res://data/enemies/enemies.json",
	"res://data/events/events.json",
	"res://data/potions/potions.json",
	"res://data/relics/relics.json",
	"res://data/statuses/statuses.json"
]

const SUMMARY_FIELDS := [
	"nodes_visited",
	"combats_started",
	"combats_won",
	"combats_lost",
	"bosses_defeated",
	"turns",
	"cards_offered",
	"card_offer_batches",
	"cards_acquired",
	"cards_removed",
	"cards_upgraded",
	"cards_played",
	"potions_used",
	"loads"
]

const CARD_COUNT_FIELDS := ["offers", "acquisitions", "removals", "upgrades", "plays"]

static func default_store() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"active_run": {},
		"runs": []
	}

static func configuration_fingerprint(paths: Array = []) -> String:
	var selected_paths: Array = paths.duplicate() if not paths.is_empty() else GAMEPLAY_CONFIG_PATHS.duplicate()
	selected_paths.sort()
	var payload := "ember-circuit-gameplay-config-v%d\n" % SCHEMA_VERSION
	for path_value in selected_paths:
		var path := str(path_value)
		payload += "%s\n" % path
		if FileAccess.file_exists(path):
			payload += FileAccess.get_file_as_string(path)
		payload += "\n"
	return payload.sha256_text()

static func normalize_store(raw_store: Dictionary) -> Dictionary:
	var store: Dictionary = default_store()
	var runs: Array = []
	for run_value in raw_store.get("runs", []):
		if not run_value is Dictionary:
			continue
		var run: Dictionary = _normalized_run(run_value)
		if run.is_empty() or not TERMINAL_OUTCOMES.has(str(run.get("outcome", ""))):
			continue
		runs.append(run)
	store["runs"] = PlaytestEvidenceGateScript.retain_runs(runs)
	var active_value = raw_store.get("active_run", {})
	if active_value is Dictionary:
		var active: Dictionary = _normalized_run(active_value)
		if str(active.get("outcome", "")) == "in_progress":
			store["active_run"] = active
	return store

static func start_run(raw_store: Dictionary, context: Dictionary) -> Dictionary:
	var store: Dictionary = normalize_store(raw_store)
	var previous: Dictionary = active_run(store)
	if not previous.is_empty():
		_finish_run(previous, "abandoned", {
			"timestamp_utc": str(context.get("timestamp_utc", _timestamp_utc())),
			"reason": "new_run_started"
		})
		_append_finished_run(store, previous)
	store["active_run"] = _new_run(context)
	return store

static func active_run(store: Dictionary) -> Dictionary:
	var value = store.get("active_run", {})
	return value if value is Dictionary else {}

static func set_active_run(raw_store: Dictionary, raw_run: Dictionary) -> Dictionary:
	var store: Dictionary = normalize_store(raw_store)
	var run: Dictionary = _normalized_run(raw_run)
	if str(run.get("outcome", "")) != "in_progress":
		store["active_run"] = {}
		return store
	var run_id := str(run.get("run_id", ""))
	var retained_runs: Array = []
	var terminal_already_archived := false
	for archived_value in store.get("runs", []):
		var archived: Dictionary = archived_value
		if str(archived.get("run_id", "")) == run_id:
			var archived_outcome := str(archived.get("outcome", ""))
			if ["victory", "defeat"].has(archived_outcome):
				terminal_already_archived = true
			elif archived_outcome == "abandoned":
				continue
		retained_runs.append(archived)
	store["runs"] = retained_runs
	store["active_run"] = {} if terminal_already_archived else run
	return store

static func finish_active_run(raw_store: Dictionary, outcome: String, final_context: Dictionary) -> Dictionary:
	var store: Dictionary = normalize_store(raw_store)
	var run: Dictionary = active_run(store)
	if run.is_empty():
		return store
	_finish_run(run, outcome, final_context)
	_append_finished_run(store, run)
	store["active_run"] = {}
	return store

static func record_node_started(run: Dictionary, context: Dictionary) -> bool:
	if not _run_is_active(run):
		return false
	var chapter_id := str(context.get("chapter_id", ""))
	var node_id := str(context.get("node_id", ""))
	if node_id.is_empty():
		return false
	var route: Array = run.get("route", [])
	if not route.is_empty():
		var previous: Dictionary = route[-1]
		if str(previous.get("chapter_id", "")) == chapter_id and str(previous.get("node_id", "")) == node_id and str(previous.get("result", "")) == "started":
			return false
	var entry := {
		"chapter_id": chapter_id,
		"node_id": node_id,
		"node_type": str(context.get("node_type", "")),
		"encounter_id": str(context.get("encounter_id", "")),
		"event_id": str(context.get("event_id", "")),
		"is_battle": bool(context.get("is_battle", false)),
		"result": "started",
		"turns": 0,
		"hp_before": max(0, int(context.get("hp", 0))),
		"hp_after": max(0, int(context.get("hp", 0))),
		"gold_before": max(0, int(context.get("gold", 0))),
		"gold_after": max(0, int(context.get("gold", 0))),
		"deck_size_before": max(0, int(context.get("deck_size", 0))),
		"deck_size_after": max(0, int(context.get("deck_size", 0)))
	}
	route.append(entry)
	run["route"] = route
	_increment_summary(run, "nodes_visited", 1)
	if bool(entry.get("is_battle", false)):
		_increment_summary(run, "combats_started", 1)
	return true

static func record_node_finished(run: Dictionary, context: Dictionary) -> bool:
	if not _run_is_active(run):
		return false
	var chapter_id := str(context.get("chapter_id", ""))
	var node_id := str(context.get("node_id", ""))
	var route: Array = run.get("route", [])
	for index in range(route.size() - 1, -1, -1):
		var entry: Dictionary = route[index]
		if str(entry.get("chapter_id", "")) != chapter_id or str(entry.get("node_id", "")) != node_id:
			continue
		if str(entry.get("result", "")) != "started":
			return false
		var result := str(context.get("result", "completed"))
		entry["result"] = result
		entry["turns"] = max(0, int(context.get("turns", 0)))
		entry["hp_after"] = max(0, int(context.get("hp", entry.get("hp_after", 0))))
		entry["gold_after"] = max(0, int(context.get("gold", entry.get("gold_after", 0))))
		entry["deck_size_after"] = max(0, int(context.get("deck_size", entry.get("deck_size_after", 0))))
		route[index] = entry
		run["route"] = route
		if bool(entry.get("is_battle", context.get("is_battle", false))):
			_increment_summary(run, "turns", int(entry.get("turns", 0)))
			if result == "won":
				_increment_summary(run, "combats_won", 1)
				if str(entry.get("node_type", "")) == "boss":
					_increment_summary(run, "bosses_defeated", 1)
			elif result == "lost":
				_increment_summary(run, "combats_lost", 1)
				run["failure"] = {
					"chapter_id": chapter_id,
					"node_id": node_id,
					"encounter_id": str(entry.get("encounter_id", "")),
					"turn": int(entry.get("turns", 0))
				}
		return true
	return false

static func record_card_offers(run: Dictionary, card_ids: Array, source: String) -> void:
	if not _run_is_active(run) or card_ids.is_empty():
		return
	for card_id_value in card_ids:
		var card_id := base_card_id(str(card_id_value))
		if card_id.is_empty():
			continue
		var row := _card_row(run, card_id)
		row["offers"] = int(row.get("offers", 0)) + 1
		var offer_sources: Dictionary = row.get("offer_sources", {})
		_increment_count_map(offer_sources, source, 1)
		row["offer_sources"] = offer_sources
		_set_card_row(run, card_id, row)
		_increment_summary(run, "cards_offered", 1)
	_increment_summary(run, "card_offer_batches", 1)

static func record_card_acquired(run: Dictionary, card_id_value: String, source: String) -> void:
	var card_id := base_card_id(card_id_value)
	if not _run_is_active(run) or card_id.is_empty():
		return
	var row := _card_row(run, card_id)
	row["acquisitions"] = int(row.get("acquisitions", 0)) + 1
	var sources: Dictionary = row.get("acquisition_sources", {})
	_increment_count_map(sources, source, 1)
	row["acquisition_sources"] = sources
	_set_card_row(run, card_id, row)
	_increment_summary(run, "cards_acquired", 1)

static func record_card_removed(run: Dictionary, card_id_value: String) -> void:
	_record_card_count(run, card_id_value, "removals", "cards_removed")

static func record_card_upgraded(run: Dictionary, card_id_value: String) -> void:
	_record_card_count(run, card_id_value, "upgrades", "cards_upgraded")

static func record_card_played(run: Dictionary, card_id_value: String) -> void:
	_record_card_count(run, card_id_value, "plays", "cards_played")

static func record_item_acquired(run: Dictionary, category: String, item_id_value: String, source: String) -> void:
	if not _run_is_active(run) or not ["relics", "potions"].has(category):
		return
	var item_id := item_id_value.strip_edges()
	if item_id.is_empty():
		return
	var acquisitions: Dictionary = run.get("item_acquisitions", {})
	var category_rows: Dictionary = acquisitions.get(category, {})
	var row: Dictionary = category_rows.get(item_id, {"count": 0, "sources": {}})
	row["count"] = int(row.get("count", 0)) + 1
	var sources: Dictionary = row.get("sources", {})
	_increment_count_map(sources, source, 1)
	row["sources"] = sources
	category_rows[item_id] = row
	acquisitions[category] = category_rows
	run["item_acquisitions"] = acquisitions

static func record_potion_used(run: Dictionary, potion_id_value: String) -> void:
	if not _run_is_active(run):
		return
	var potion_id := potion_id_value.strip_edges()
	if potion_id.is_empty():
		return
	var uses: Dictionary = run.get("potion_uses", {})
	_increment_count_map(uses, potion_id, 1)
	run["potion_uses"] = uses
	_increment_summary(run, "potions_used", 1)

static func record_event_choice(run: Dictionary, event_id_value: String, choice_id_value: String, result_id_value: String = "") -> void:
	if not _run_is_active(run):
		return
	var event_id := event_id_value.strip_edges()
	var choice_id := choice_id_value.strip_edges()
	if event_id.is_empty() or choice_id.is_empty():
		return
	var choices: Array = run.get("event_choices", [])
	choices.append({
		"chapter_id": _current_route_chapter(run),
		"node_id": _current_route_node(run),
		"event_id": event_id,
		"choice_id": choice_id,
		"result_id": result_id_value.strip_edges()
	})
	run["event_choices"] = choices

static func record_reward_skipped(run: Dictionary, reward_type: String) -> void:
	if not _run_is_active(run):
		return
	var reward_id := reward_type.strip_edges()
	if reward_id.is_empty():
		return
	var skips: Dictionary = run.get("reward_skips", {})
	_increment_count_map(skips, reward_id, 1)
	run["reward_skips"] = skips

static func record_mastery_selected(run: Dictionary, mastery_id: String) -> void:
	if _run_is_active(run):
		run["deck_mastery_id"] = mastery_id.strip_edges()

static func record_run_loaded(run: Dictionary) -> void:
	if _run_is_active(run):
		_increment_summary(run, "loads", 1)

static func build_report(raw_store: Dictionary, context: Dictionary = {}) -> Dictionary:
	var store := normalize_store(raw_store)
	var report := PlaytestEvidenceGateScript.build_report(store.get("runs", []), context)
	report["active_run"] = active_run(store).duplicate(true)
	report["summary"]["active_run_present"] = not active_run(store).is_empty()
	return report

static func base_card_id(card_id_value: String) -> String:
	var card_id := card_id_value.strip_edges()
	return card_id.substr(0, card_id.length() - 1) if card_id.ends_with("+") else card_id

static func _new_run(context: Dictionary) -> Dictionary:
	var timestamp := str(context.get("timestamp_utc", _timestamp_utc()))
	var run_id := str(context.get("run_id", ""))
	if run_id.is_empty():
		run_id = ("%s|%d|%d" % [timestamp, Time.get_ticks_usec(), randi()]).sha256_text().substr(0, 20)
	var sample_kind := str(context.get("sample_kind", "human"))
	var run := {
		"schema_version": SCHEMA_VERSION,
		"source_schema_version": SCHEMA_VERSION,
		"run_id": run_id,
		"started_at_utc": timestamp,
		"finished_at_utc": "",
		"outcome": "in_progress",
		"game_version": str(context.get("game_version", "unknown")),
		"engine_version": str(context.get("engine_version", "unknown")),
		"config_fingerprint": str(context.get("config_fingerprint", "")),
		"sample_kind": sample_kind,
		"gate_eligible": sample_kind == "human",
		"environment": {
			"platform": str(context.get("platform", "unknown")),
			"display_size": _normalized_int_pair(context.get("display_size", [])),
			"display_scale": max(0.1, float(context.get("display_scale", 1.0))),
			"locale": str(context.get("locale", "unknown"))
		},
		"character_id": str(context.get("character_id", "")),
		"challenge_level": max(0, int(context.get("challenge_level", 0))),
		"skill_book_id": str(context.get("skill_book_id", "")),
		"progression_node_ids": _string_array(context.get("progression_node_ids", [])),
		"starting": {
			"hp": max(0, int(context.get("starting_hp", 0))),
			"max_hp": max(0, int(context.get("max_hp", 0))),
			"gold": max(0, int(context.get("starting_gold", 0))),
			"deck_ids": _string_array(context.get("starting_deck_ids", [])),
			"relic_ids": _string_array(context.get("starting_relic_ids", [])),
			"potion_ids": _string_array(context.get("starting_potion_ids", []))
		},
		"final": {},
		"summary": _default_summary(),
		"route": [],
		"card_telemetry": {},
		"item_acquisitions": {"relics": {}, "potions": {}},
		"potion_uses": {},
		"event_choices": [],
		"reward_skips": {},
		"deck_mastery_id": "",
		"failure": {}
	}
	run["cohort_id"] = PlaytestEvidenceGateScript.cohort_id(run)
	return run

static func _normalized_run(raw_run: Dictionary) -> Dictionary:
	if raw_run.is_empty() or str(raw_run.get("run_id", "")).is_empty():
		return {}
	var source_schema_version: int = max(1, int(raw_run.get("source_schema_version", raw_run.get("schema_version", 1))))
	var sample_kind := str(raw_run.get("sample_kind", ""))
	if sample_kind.is_empty():
		sample_kind = "legacy_unapproved" if source_schema_version < SCHEMA_VERSION else "human"
	var gate_eligible := bool(raw_run.get("gate_eligible", sample_kind == "human")) and sample_kind == "human"
	var starting: Dictionary = raw_run.get("starting", {})
	var final_state: Dictionary = raw_run.get("final", {})
	var summary: Dictionary = _default_summary()
	var raw_summary: Dictionary = raw_run.get("summary", {})
	for field in SUMMARY_FIELDS:
		summary[str(field)] = max(0, int(raw_summary.get(field, 0)))
	var route: Array = []
	for entry_value in raw_run.get("route", []):
		if entry_value is Dictionary:
			route.append(_normalized_route_entry(entry_value))
	var cards: Dictionary = {}
	var raw_cards: Dictionary = raw_run.get("card_telemetry", {})
	for card_id_value in raw_cards.keys():
		var card_id := base_card_id(str(card_id_value))
		if not card_id.is_empty() and raw_cards.get(card_id_value) is Dictionary:
			cards[card_id] = _normalized_card_row(raw_cards.get(card_id_value, {}))
	var choices: Array = []
	for choice_value in raw_run.get("event_choices", []):
		if choice_value is Dictionary:
			choices.append({
				"chapter_id": str(choice_value.get("chapter_id", "")),
				"node_id": str(choice_value.get("node_id", "")),
				"event_id": str(choice_value.get("event_id", "")),
				"choice_id": str(choice_value.get("choice_id", "")),
				"result_id": str(choice_value.get("result_id", ""))
			})
	var raw_items: Dictionary = raw_run.get("item_acquisitions", {})
	var normalized := {
		"schema_version": SCHEMA_VERSION,
		"source_schema_version": source_schema_version,
		"run_id": str(raw_run.get("run_id", "")),
		"started_at_utc": str(raw_run.get("started_at_utc", "")),
		"finished_at_utc": str(raw_run.get("finished_at_utc", "")),
		"outcome": str(raw_run.get("outcome", "in_progress")),
		"game_version": str(raw_run.get("game_version", "unknown")),
		"engine_version": str(raw_run.get("engine_version", "unknown")),
		"config_fingerprint": str(raw_run.get("config_fingerprint", "")),
		"sample_kind": sample_kind,
		"gate_eligible": gate_eligible,
		"environment": {
			"platform": str(raw_run.get("environment", {}).get("platform", "unknown")),
			"display_size": _normalized_int_pair(raw_run.get("environment", {}).get("display_size", [])),
			"display_scale": max(0.1, float(raw_run.get("environment", {}).get("display_scale", 1.0))),
			"locale": str(raw_run.get("environment", {}).get("locale", "unknown"))
		},
		"character_id": str(raw_run.get("character_id", "")),
		"challenge_level": max(0, int(raw_run.get("challenge_level", 0))),
		"skill_book_id": str(raw_run.get("skill_book_id", "")),
		"progression_node_ids": _string_array(raw_run.get("progression_node_ids", [])),
		"starting": {
			"hp": max(0, int(starting.get("hp", 0))),
			"max_hp": max(0, int(starting.get("max_hp", 0))),
			"gold": max(0, int(starting.get("gold", 0))),
			"deck_ids": _string_array(starting.get("deck_ids", [])),
			"relic_ids": _string_array(starting.get("relic_ids", [])),
			"potion_ids": _string_array(starting.get("potion_ids", []))
		},
		"final": _normalized_final_state(final_state),
		"summary": summary,
		"route": route,
		"card_telemetry": cards,
		"item_acquisitions": {
			"relics": _normalized_item_rows(raw_items.get("relics", {})),
			"potions": _normalized_item_rows(raw_items.get("potions", {}))
		},
		"potion_uses": _normalized_count_map(raw_run.get("potion_uses", {})),
		"event_choices": choices,
		"reward_skips": _normalized_count_map(raw_run.get("reward_skips", {})),
		"deck_mastery_id": str(raw_run.get("deck_mastery_id", "")),
		"failure": _normalized_failure(raw_run.get("failure", {}))
	}
	normalized["cohort_id"] = PlaytestEvidenceGateScript.cohort_id(normalized)
	return normalized

static func _normalized_route_entry(raw: Dictionary) -> Dictionary:
	return {
		"chapter_id": str(raw.get("chapter_id", "")),
		"node_id": str(raw.get("node_id", "")),
		"node_type": str(raw.get("node_type", "")),
		"encounter_id": str(raw.get("encounter_id", "")),
		"event_id": str(raw.get("event_id", "")),
		"is_battle": bool(raw.get("is_battle", false)),
		"result": str(raw.get("result", "started")),
		"turns": max(0, int(raw.get("turns", 0))),
		"hp_before": max(0, int(raw.get("hp_before", 0))),
		"hp_after": max(0, int(raw.get("hp_after", 0))),
		"gold_before": max(0, int(raw.get("gold_before", 0))),
		"gold_after": max(0, int(raw.get("gold_after", 0))),
		"deck_size_before": max(0, int(raw.get("deck_size_before", 0))),
		"deck_size_after": max(0, int(raw.get("deck_size_after", 0)))
	}

static func _normalized_card_row(raw: Dictionary) -> Dictionary:
	var row := _default_card_row()
	for field in CARD_COUNT_FIELDS:
		row[str(field)] = max(0, int(raw.get(field, 0)))
	row["offer_sources"] = _normalized_count_map(raw.get("offer_sources", {}))
	row["acquisition_sources"] = _normalized_count_map(raw.get("acquisition_sources", {}))
	return row

static func _normalized_item_rows(raw_value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw_value is Dictionary:
		return result
	var raw: Dictionary = raw_value
	for item_id_value in raw.keys():
		if not raw.get(item_id_value) is Dictionary:
			continue
		var item_id := str(item_id_value)
		var row: Dictionary = raw.get(item_id_value, {})
		result[item_id] = {
			"count": max(0, int(row.get("count", 0))),
			"sources": _normalized_count_map(row.get("sources", {}))
		}
	return result

static func _normalized_final_state(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return {}
	return {
		"chapter_id": str(raw.get("chapter_id", "")),
		"node_id": str(raw.get("node_id", "")),
		"encounter_id": str(raw.get("encounter_id", "")),
		"reason": str(raw.get("reason", "")),
		"hp": max(0, int(raw.get("hp", 0))),
		"max_hp": max(0, int(raw.get("max_hp", 0))),
		"gold": max(0, int(raw.get("gold", 0))),
		"deck_ids": _string_array(raw.get("deck_ids", [])),
		"relic_ids": _string_array(raw.get("relic_ids", [])),
		"potion_ids": _string_array(raw.get("potion_ids", [])),
		"completed_chapter_ids": _string_array(raw.get("completed_chapter_ids", [])),
		"deck_mastery_id": str(raw.get("deck_mastery_id", ""))
	}

static func _normalized_failure(raw_value: Variant) -> Dictionary:
	if not raw_value is Dictionary or (raw_value as Dictionary).is_empty():
		return {}
	var raw: Dictionary = raw_value
	return {
		"chapter_id": str(raw.get("chapter_id", "")),
		"node_id": str(raw.get("node_id", "")),
		"encounter_id": str(raw.get("encounter_id", "")),
		"turn": max(0, int(raw.get("turn", 0)))
	}

static func _finish_run(run: Dictionary, outcome: String, final_context: Dictionary) -> void:
	if not _run_is_active(run):
		return
	run["outcome"] = outcome if TERMINAL_OUTCOMES.has(outcome) else "abandoned"
	run["finished_at_utc"] = str(final_context.get("timestamp_utc", _timestamp_utc()))
	run["final"] = _normalized_final_state(final_context)
	if str(run.get("outcome", "")) == "defeat" and run.get("failure", {}).is_empty():
		run["failure"] = {
			"chapter_id": str(final_context.get("chapter_id", "")),
			"node_id": str(final_context.get("node_id", "")),
			"encounter_id": str(final_context.get("encounter_id", "")),
			"turn": max(0, int(final_context.get("turn", 0)))
		}

static func _append_finished_run(store: Dictionary, run: Dictionary) -> void:
	var finished_run := _normalized_run(run)
	var finished_run_id := str(finished_run.get("run_id", ""))
	var runs: Array = []
	var retained_terminal: Dictionary = {}
	for existing_value in store.get("runs", []):
		var existing: Dictionary = existing_value
		if not finished_run_id.is_empty() and str(existing.get("run_id", "")) == finished_run_id:
			if retained_terminal.is_empty() and ["victory", "defeat"].has(str(existing.get("outcome", ""))):
				retained_terminal = existing
			continue
		runs.append(existing)
	runs.append(retained_terminal if not retained_terminal.is_empty() else finished_run)
	store["runs"] = PlaytestEvidenceGateScript.retain_runs(runs)

static func _run_is_active(run: Dictionary) -> bool:
	return not run.is_empty() and str(run.get("outcome", "")) == "in_progress"

static func _default_summary() -> Dictionary:
	var summary: Dictionary = {}
	for field in SUMMARY_FIELDS:
		summary[str(field)] = 0
	return summary

static func _default_card_row() -> Dictionary:
	return {
		"offers": 0,
		"acquisitions": 0,
		"removals": 0,
		"upgrades": 0,
		"plays": 0,
		"offer_sources": {},
		"acquisition_sources": {}
	}

static func _card_row(run: Dictionary, card_id: String) -> Dictionary:
	var cards: Dictionary = run.get("card_telemetry", {})
	var value = cards.get(card_id, {})
	return _normalized_card_row(value) if value is Dictionary and not (value as Dictionary).is_empty() else _default_card_row()

static func _set_card_row(run: Dictionary, card_id: String, row: Dictionary) -> void:
	var cards: Dictionary = run.get("card_telemetry", {})
	cards[card_id] = row
	run["card_telemetry"] = cards

static func _record_card_count(run: Dictionary, card_id_value: String, card_field: String, summary_field: String) -> void:
	var card_id := base_card_id(card_id_value)
	if not _run_is_active(run) or card_id.is_empty():
		return
	var row := _card_row(run, card_id)
	row[card_field] = int(row.get(card_field, 0)) + 1
	_set_card_row(run, card_id, row)
	_increment_summary(run, summary_field, 1)

static func _increment_summary(run: Dictionary, field: String, amount: int) -> void:
	var summary: Dictionary = run.get("summary", _default_summary())
	summary[field] = max(0, int(summary.get(field, 0)) + amount)
	run["summary"] = summary

static func _increment_count_map(counts: Dictionary, id_value: String, amount: int) -> void:
	var id := id_value.strip_edges()
	if id.is_empty():
		id = "unknown"
	counts[id] = max(0, int(counts.get(id, 0)) + amount)

static func _normalized_count_map(raw_value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw_value is Dictionary:
		return result
	var raw: Dictionary = raw_value
	for key_value in raw.keys():
		var key := str(key_value).strip_edges()
		if not key.is_empty():
			result[key] = max(0, int(raw.get(key_value, 0)))
	return result

static func _string_array(raw_value: Variant) -> Array:
	var result: Array = []
	if not raw_value is Array:
		return result
	for value in raw_value:
		var text := str(value).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result

static func _normalized_int_pair(raw_value: Variant) -> Array:
	if not raw_value is Array or (raw_value as Array).size() < 2:
		return [0, 0]
	var raw: Array = raw_value
	return [max(0, int(raw[0])), max(0, int(raw[1]))]

static func _current_route_chapter(run: Dictionary) -> String:
	var route: Array = run.get("route", [])
	return str((route[-1] as Dictionary).get("chapter_id", "")) if not route.is_empty() else ""

static func _current_route_node(run: Dictionary) -> String:
	var route: Array = run.get("route", [])
	return str((route[-1] as Dictionary).get("node_id", "")) if not route.is_empty() else ""

static func _timestamp_utc() -> String:
	var timestamp := Time.get_datetime_string_from_system(true, true)
	return timestamp if timestamp.ends_with("Z") else "%sZ" % timestamp
