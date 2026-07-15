extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/tools/BalanceSimulator.gd")

const CAMPAIGN_ITERATIONS := 2
const CAMPAIGN_MAX_TURNS := 45
const CHARACTER_IDS := ["ember_exile", "arc_tinker", "pyre_ascetic"]
const RUN_COUNT_FIELDS := [
	"card_offer_counts_by_id",
	"card_acquisition_counts_by_id",
	"card_removal_counts_by_id",
	"card_upgrade_counts_by_id",
	"card_play_counts_by_id",
]
const TELEMETRY_FIELDS := [
	"id",
	"offers",
	"acquisitions",
	"offered_acquisitions",
	"acquisition_sources",
	"acquisition_rate_per_offer",
	"acquisition_runs",
	"removals",
	"upgrades",
	"runs_played",
	"plays",
	"wins_when_acquired",
	"losses_when_acquired",
	"win_rate_when_acquired",
	"runs_not_acquired",
	"wins_when_not_acquired",
	"losses_when_not_acquired",
	"win_rate_when_not_acquired",
	"acquisition_comparison_available",
	"win_rate_lift_when_acquired",
	"wins_when_played",
	"losses_when_played",
	"win_rate_when_played",
	"runs_not_played",
	"wins_when_not_played",
	"losses_when_not_played",
	"win_rate_when_not_played",
	"play_comparison_available",
	"win_rate_lift_when_played",
]

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulator = BalanceSimulatorScript.new()
	simulator.load_default_data()

	_test_single_combat_play_counts(simulator)
	_test_campaign_run_and_case_telemetry(simulator)
	_test_campaign_options_are_deterministic(simulator)

	if not _failures.is_empty():
		push_error("Card telemetry contract test failed with %d issue(s)." % _failures.size())
		for failure in _failures:
			push_error(" - %s" % failure)
		quit(1)
		return

	print("Balance card telemetry contract test passed.")
	quit(0)

func _test_single_combat_play_counts(simulator) -> void:
	var upgraded_deck: Array = []
	for _index in range(10):
		upgraded_deck.append("ember_strike+")
	var result: Dictionary = simulator._run_single_combat_with_loadout(
		"ember_exile",
		0,
		"intro_patrol",
		25,
		simulator._stable_text_seed("card_telemetry|upgraded_single_combat"),
		upgraded_deck,
		[],
		72,
		[]
	)
	var play_counts := _dictionary_field(result, "card_play_counts_by_id", "single combat")
	_validate_card_count_map(simulator, play_counts, "ember_exile", "single combat plays")
	var total_plays := _sum_count_map(play_counts)
	_check(int(result.get("cards_played", 0)) > 0, "single combat plays at least one card")
	_check(total_plays == int(result.get("cards_played", 0)), "single combat per-card plays sum to cards_played")
	_check(int(play_counts.get("ember_strike", 0)) == total_plays, "upgraded ember_strike plays aggregate under the base card id")
	_check(not play_counts.has("ember_strike+"), "single combat telemetry never emits an upgraded card id")

func _test_campaign_run_and_case_telemetry(simulator) -> void:
	var observed_campaign_acquisitions := 0
	var observed_campaign_plays := 0
	for character_id_value in CHARACTER_IDS:
		var character_id: String = str(character_id_value)
		var runs: Array = []
		for iteration in range(CAMPAIGN_ITERATIONS):
			var seed_value: int = simulator._stable_text_seed("campaign|%d" % iteration)
			var run: Dictionary = simulator._run_campaign_once(character_id, 0, CAMPAIGN_MAX_TURNS, seed_value)
			runs.append(run)
			var run_totals: Dictionary = _validate_campaign_run(simulator, run, character_id, iteration)
			observed_campaign_acquisitions += int(run_totals.get("acquisitions", 0))
			observed_campaign_plays += int(run_totals.get("plays", 0))

		var campaign_case: Dictionary = simulator._aggregate_campaign_case(
			simulator._character_config(character_id),
			simulator._challenge_config(0),
			runs
		)
		_validate_campaign_case(simulator, campaign_case, runs, character_id)

	_check(observed_campaign_plays > 0, "deterministic campaign samples record at least one played card")
	_check(observed_campaign_acquisitions > 0, "deterministic campaign samples record at least one acquired card")

func _validate_campaign_run(simulator, run: Dictionary, character_id: String, iteration: int) -> Dictionary:
	var context := "%s campaign run %d" % [character_id, iteration]
	var maps: Dictionary = {}
	for field_name_value in RUN_COUNT_FIELDS:
		var field_name: String = str(field_name_value)
		var count_map := _dictionary_field(run, field_name, context)
		maps[field_name] = count_map
		_validate_card_count_map(simulator, count_map, character_id, "%s %s" % [context, field_name])

	var acquisition_sources := _dictionary_field(run, "card_acquisition_sources_by_id", context)
	_validate_acquisition_sources(simulator, acquisition_sources, maps.get("card_acquisition_counts_by_id", {}), character_id, context)

	var acquisitions: Dictionary = maps.get("card_acquisition_counts_by_id", {})
	var removals: Dictionary = maps.get("card_removal_counts_by_id", {})
	var upgrades: Dictionary = maps.get("card_upgrade_counts_by_id", {})
	var plays: Dictionary = maps.get("card_play_counts_by_id", {})
	var acquisition_total := _sum_count_map(acquisitions)
	var removal_total := _sum_count_map(removals)
	var upgrade_total := _sum_count_map(upgrades)
	var play_total := _sum_count_map(plays)
	_check(acquisition_total == int(run.get("cards_added", 0)), "%s acquisitions sum to cards_added" % context)
	_check(removal_total == int(run.get("cards_removed", 0)), "%s removals sum to cards_removed" % context)
	_check(upgrade_total == int(run.get("cards_upgraded", 0)), "%s upgrades sum to cards_upgraded" % context)
	_check(play_total == int(run.get("cards_played", 0)), "%s plays sum to cards_played" % context)
	_check(play_total > 0, "%s records positive per-card play counts" % context)
	return {"acquisitions": acquisition_total, "plays": play_total}

func _validate_acquisition_sources(
	simulator,
	sources_by_id: Dictionary,
	acquisitions_by_id: Dictionary,
	character_id: String,
	context: String
) -> void:
	var card_ids := _union_keys(sources_by_id, acquisitions_by_id)
	for card_id_value in card_ids:
		var card_id: String = str(card_id_value)
		_check(_is_card_accessible(simulator, card_id, character_id), "%s acquisition source card %s is accessible" % [context, card_id])
		var source_value = sources_by_id.get(card_id, {})
		_check(source_value is Dictionary, "%s acquisition sources for %s are a dictionary" % [context, card_id])
		var source_counts: Dictionary = source_value if source_value is Dictionary else {}
		for source_name_value in source_counts.keys():
			var source_name: String = str(source_name_value)
			_check(not source_name.is_empty(), "%s acquisition source name for %s is non-empty" % [context, card_id])
			_check(int(source_counts.get(source_name_value, -1)) >= 0, "%s acquisition source %s:%s is non-negative" % [context, card_id, source_name])
		_check(
			_sum_count_map(source_counts) == int(acquisitions_by_id.get(card_id, 0)),
			"%s acquisition sources for %s sum to acquisitions" % [context, card_id]
		)

func _validate_campaign_case(simulator, campaign_case: Dictionary, runs: Array, character_id: String) -> void:
	var context := "%s campaign case" % character_id
	var telemetry_value = campaign_case.get("card_telemetry", null)
	_check(telemetry_value is Array, "%s exposes card_telemetry as an array" % context)
	var telemetry: Array = telemetry_value if telemetry_value is Array else []
	var win_indices_value = campaign_case.get("win_iteration_indices", null)
	_check(win_indices_value is Array, "%s exposes win_iteration_indices as an array" % context)
	var win_indices: Array = win_indices_value if win_indices_value is Array else []
	_check(win_indices.size() == int(campaign_case.get("wins", -1)), "%s win indices conserve aggregate wins" % context)
	var previous_win_index := -1
	for index_value in win_indices:
		var win_index := int(index_value)
		_check(win_index >= 0 and win_index < runs.size(), "%s win index stays inside the iteration range" % context)
		_check(win_index > previous_win_index, "%s win indices are unique and sorted" % context)
		if win_index >= 0 and win_index < runs.size():
			_check(bool((runs[win_index] as Dictionary).get("won", false)), "%s win index points to a winning run" % context)
		previous_win_index = win_index
	var expected := _aggregate_expected_telemetry(runs)
	var expected_counts: Dictionary = expected.get("counts", {})
	var expected_acquisition_runs: Dictionary = expected.get("acquisition_runs", {})
	var expected_runs_played: Dictionary = expected.get("runs_played", {})
	var expected_wins_acquired: Dictionary = expected.get("wins_acquired", {})
	var expected_losses_acquired: Dictionary = expected.get("losses_acquired", {})
	var expected_wins_played: Dictionary = expected.get("wins_played", {})
	var expected_losses_played: Dictionary = expected.get("losses_played", {})
	var row_by_id: Dictionary = {}
	var ids: Array[String] = []
	var total_offers := 0
	var total_acquisitions := 0
	var total_removals := 0
	var total_upgrades := 0
	var total_plays := 0

	for row_value in telemetry:
		_check(row_value is Dictionary, "%s telemetry rows are dictionaries" % context)
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		for field_name_value in TELEMETRY_FIELDS:
			var field_name: String = str(field_name_value)
			_check(row.has(field_name), "%s telemetry row contains %s" % [context, field_name])
		var card_id: String = str(row.get("id", ""))
		_check(not card_id.is_empty(), "%s telemetry id is non-empty" % context)
		_check(not row_by_id.has(card_id), "%s telemetry id %s is unique" % [context, card_id])
		_check(not card_id.ends_with("+"), "%s telemetry id %s is a base card id" % [context, card_id])
		_check(_is_card_accessible(simulator, card_id, character_id), "%s telemetry card %s is shared or character-accessible" % [context, card_id])
		row_by_id[card_id] = row
		ids.append(card_id)

		var offers := int(row.get("offers", -1))
		var acquisitions := int(row.get("acquisitions", -1))
		var offered_acquisitions := int(row.get("offered_acquisitions", -1))
		var removals := int(row.get("removals", -1))
		var upgrades := int(row.get("upgrades", -1))
		var acquisition_runs := int(row.get("acquisition_runs", -1))
		var runs_played := int(row.get("runs_played", -1))
		var plays := int(row.get("plays", -1))
		var wins_when_acquired := int(row.get("wins_when_acquired", -1))
		var losses_when_acquired := int(row.get("losses_when_acquired", -1))
		var wins_when_played := int(row.get("wins_when_played", -1))
		var losses_when_played := int(row.get("losses_when_played", -1))
		for count_value in [offers, acquisitions, offered_acquisitions, removals, upgrades, acquisition_runs, runs_played, plays, wins_when_acquired, losses_when_acquired, wins_when_played, losses_when_played]:
			_check(int(count_value) >= 0, "%s telemetry counts for %s are non-negative" % [context, card_id])
		var sources_value = row.get("acquisition_sources", null)
		_check(sources_value is Dictionary, "%s telemetry acquisition_sources for %s is a dictionary" % [context, card_id])
		var sources: Dictionary = sources_value if sources_value is Dictionary else {}
		_check(_sum_count_map(sources) == acquisitions, "%s telemetry sources for %s sum to acquisitions" % [context, card_id])
		var expected_offered_acquisitions := int(sources.get("combat_reward", 0)) + int(sources.get("shop", 0))
		_check(offered_acquisitions == expected_offered_acquisitions, "%s offered acquisitions for %s only include reward and shop choices" % [context, card_id])
		_check(offered_acquisitions <= offers, "%s offered acquisitions for %s do not exceed offers" % [context, card_id])
		_check(_rate_matches(row.get("acquisition_rate_per_offer", -1.0), offered_acquisitions, offers), "%s acquisition rate for %s matches offered acquisitions" % [context, card_id])

		_check(acquisition_runs <= runs.size(), "%s acquisition_runs for %s do not exceed runs" % [context, card_id])
		_check(runs_played <= runs.size(), "%s runs_played for %s do not exceed runs" % [context, card_id])
		_check(wins_when_acquired + losses_when_acquired == acquisition_runs, "%s acquired outcomes for %s conserve acquisition_runs" % [context, card_id])
		_check(wins_when_played + losses_when_played == runs_played, "%s played outcomes for %s conserve runs_played" % [context, card_id])
		_check(_rate_matches(row.get("win_rate_when_acquired", -1.0), wins_when_acquired, acquisition_runs), "%s acquired win rate for %s matches outcomes" % [context, card_id])
		_check(_rate_matches(row.get("win_rate_when_played", -1.0), wins_when_played, runs_played), "%s played win rate for %s matches outcomes" % [context, card_id])

		total_offers += max(0, offers)
		total_acquisitions += max(0, acquisitions)
		total_removals += max(0, removals)
		total_upgrades += max(0, upgrades)
		total_plays += max(0, plays)

	var sorted_ids: Array[String] = ids.duplicate()
	sorted_ids.sort()
	_check(ids == sorted_ids, "%s telemetry rows are stably sorted by id" % context)
	_check(total_offers == _sum_count_map(expected_counts.get("offers", {})), "%s telemetry offers conserve run totals" % context)
	_check(total_acquisitions == _sum_count_map(expected_counts.get("acquisitions", {})), "%s telemetry acquisitions conserve run totals" % context)
	_check(total_removals == _sum_count_map(expected_counts.get("removals", {})), "%s telemetry removals conserve run totals" % context)
	_check(total_upgrades == _sum_count_map(expected_counts.get("upgrades", {})), "%s telemetry upgrades conserve run totals" % context)
	_check(total_plays == _sum_count_map(expected_counts.get("plays", {})), "%s telemetry plays conserve run totals" % context)

	var observed_ids := _union_keys(expected_counts.get("offers", {}), expected_counts.get("acquisitions", {}))
	observed_ids = _union_key_array(observed_ids, (expected_counts.get("removals", {}) as Dictionary).keys())
	observed_ids = _union_key_array(observed_ids, (expected_counts.get("upgrades", {}) as Dictionary).keys())
	observed_ids = _union_key_array(observed_ids, (expected_counts.get("plays", {}) as Dictionary).keys())
	for card_id_value in observed_ids:
		var card_id: String = str(card_id_value)
		_check(row_by_id.has(card_id), "%s telemetry includes observed card %s" % [context, card_id])
		if not row_by_id.has(card_id):
			continue
		var row: Dictionary = row_by_id[card_id]
		_check(int(row.get("offers", -1)) == int((expected_counts.get("offers", {}) as Dictionary).get(card_id, 0)), "%s offers match runs for %s" % [context, card_id])
		_check(int(row.get("acquisitions", -1)) == int((expected_counts.get("acquisitions", {}) as Dictionary).get(card_id, 0)), "%s acquisitions match runs for %s" % [context, card_id])
		_check(int(row.get("removals", -1)) == int((expected_counts.get("removals", {}) as Dictionary).get(card_id, 0)), "%s removals match runs for %s" % [context, card_id])
		_check(int(row.get("upgrades", -1)) == int((expected_counts.get("upgrades", {}) as Dictionary).get(card_id, 0)), "%s upgrades match runs for %s" % [context, card_id])
		_check(int(row.get("plays", -1)) == int((expected_counts.get("plays", {}) as Dictionary).get(card_id, 0)), "%s plays match runs for %s" % [context, card_id])
		_check(int(row.get("acquisition_runs", -1)) == int(expected_acquisition_runs.get(card_id, 0)), "%s acquisition_runs match runs for %s" % [context, card_id])
		_check(int(row.get("runs_played", -1)) == int(expected_runs_played.get(card_id, 0)), "%s runs_played match runs for %s" % [context, card_id])
		_check(int(row.get("wins_when_acquired", -1)) == int(expected_wins_acquired.get(card_id, 0)), "%s wins_when_acquired match runs for %s" % [context, card_id])
		_check(int(row.get("losses_when_acquired", -1)) == int(expected_losses_acquired.get(card_id, 0)), "%s losses_when_acquired match runs for %s" % [context, card_id])
		_check(int(row.get("wins_when_played", -1)) == int(expected_wins_played.get(card_id, 0)), "%s wins_when_played match runs for %s" % [context, card_id])
		_check(int(row.get("losses_when_played", -1)) == int(expected_losses_played.get(card_id, 0)), "%s losses_when_played match runs for %s" % [context, card_id])

func _aggregate_expected_telemetry(runs: Array) -> Dictionary:
	var counts := {"offers": {}, "acquisitions": {}, "removals": {}, "upgrades": {}, "plays": {}}
	var acquisition_runs: Dictionary = {}
	var runs_played: Dictionary = {}
	var wins_acquired: Dictionary = {}
	var losses_acquired: Dictionary = {}
	var wins_played: Dictionary = {}
	var losses_played: Dictionary = {}
	for run_value in runs:
		var run: Dictionary = run_value
		var won := bool(run.get("won", false))
		var offers := _variant_dictionary(run.get("card_offer_counts_by_id", {}))
		var acquisitions := _variant_dictionary(run.get("card_acquisition_counts_by_id", {}))
		var removals := _variant_dictionary(run.get("card_removal_counts_by_id", {}))
		var upgrades := _variant_dictionary(run.get("card_upgrade_counts_by_id", {}))
		var plays := _variant_dictionary(run.get("card_play_counts_by_id", {}))
		_merge_count_map(counts["offers"], offers)
		_merge_count_map(counts["acquisitions"], acquisitions)
		_merge_count_map(counts["removals"], removals)
		_merge_count_map(counts["upgrades"], upgrades)
		_merge_count_map(counts["plays"], plays)
		for card_id_value in acquisitions.keys():
			var card_id: String = str(card_id_value)
			if int(acquisitions.get(card_id_value, 0)) <= 0:
				continue
			_increment(acquisition_runs, card_id)
			_increment(wins_acquired if won else losses_acquired, card_id)
		for card_id_value in plays.keys():
			var card_id: String = str(card_id_value)
			if int(plays.get(card_id_value, 0)) <= 0:
				continue
			_increment(runs_played, card_id)
			_increment(wins_played if won else losses_played, card_id)
	return {
		"counts": counts,
		"acquisition_runs": acquisition_runs,
		"runs_played": runs_played,
		"wins_acquired": wins_acquired,
		"losses_acquired": losses_acquired,
		"wins_played": wins_played,
		"losses_played": losses_played,
	}

func _test_campaign_options_are_deterministic(simulator) -> void:
	var options := {
		"iterations": 2,
		"max_turns": CAMPAIGN_MAX_TURNS,
		"character_ids": ["ember_exile"],
		"challenge_levels": [0],
	}
	var first_report: Dictionary = simulator.run_campaign_suite(options)
	var second_report: Dictionary = simulator.run_campaign_suite(options)
	_check(JSON.stringify(first_report) == JSON.stringify(second_report), "campaign telemetry JSON is completely deterministic for identical options")
	var cases: Array = first_report.get("cases", [])
	_check(cases.size() == 1, "determinism sample produces one campaign case")
	if not cases.is_empty() and cases[0] is Dictionary:
		var telemetry = (cases[0] as Dictionary).get("card_telemetry", null)
		_check(telemetry is Array and not (telemetry as Array).is_empty(), "campaign report exposes non-empty card telemetry")

func _dictionary_field(owner: Dictionary, field_name: String, context: String) -> Dictionary:
	var value = owner.get(field_name, null)
	_check(value is Dictionary, "%s exposes %s as a dictionary" % [context, field_name])
	return value if value is Dictionary else {}

func _variant_dictionary(value) -> Dictionary:
	return value if value is Dictionary else {}

func _validate_card_count_map(simulator, count_map: Dictionary, character_id: String, context: String) -> void:
	for card_id_value in count_map.keys():
		var card_id: String = str(card_id_value)
		_check(not card_id.is_empty(), "%s has no empty card id" % context)
		_check(not card_id.ends_with("+"), "%s aggregates upgraded id %s into its base id" % [context, card_id])
		_check(int(count_map.get(card_id_value, -1)) >= 0, "%s count for %s is non-negative" % [context, card_id])
		_check(_is_card_accessible(simulator, card_id, character_id), "%s card %s is shared or character-accessible" % [context, card_id])

func _is_card_accessible(simulator, card_id: String, character_id: String) -> bool:
	for card_value in simulator.card_data.get("cards", []):
		var card: Dictionary = card_value
		if str(card.get("id", "")) != card_id:
			continue
		var character_ids: Array = card.get("character_ids", [])
		return character_ids.is_empty() or character_ids.has(character_id)
	return false

func _sum_count_map(count_map: Dictionary) -> int:
	var total := 0
	for value in count_map.values():
		total += int(value)
	return total

func _merge_count_map(target: Dictionary, source: Dictionary) -> void:
	for key_value in source.keys():
		var key: String = str(key_value)
		target[key] = int(target.get(key, 0)) + int(source.get(key_value, 0))

func _increment(counts: Dictionary, key: String) -> void:
	counts[key] = int(counts.get(key, 0)) + 1

func _union_keys(first: Dictionary, second: Dictionary) -> Array:
	return _union_key_array(first.keys(), second.keys())

func _union_key_array(first: Array, second: Array) -> Array:
	var seen: Dictionary = {}
	for key_value in first:
		seen[str(key_value)] = true
	for key_value in second:
		seen[str(key_value)] = true
	var keys: Array = seen.keys()
	keys.sort()
	return keys

func _rate_matches(value, wins: int, total: int) -> bool:
	var rate := float(value)
	if rate < 0.0 or rate > 1.0:
		return false
	var expected := 0.0 if total <= 0 else float(wins) / float(total)
	return absf(rate - expected) <= 0.00051

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	if not _failures.has(message):
		_failures.append(message)
