extends SceneTree

const ArtAssetAuditorScript = preload("res://scripts/tools/ArtAssetAuditor.gd")

const REQUIRED_BITMAP_SECTIONS := [
	"battle_background_slots",
	"player_stage_slots",
	"enemy_stage_slots",
	"card_art_slots",
	"event_art_slots",
	"room_scene_slots",
	"relic_icon_slots",
	"potion_icon_slots",
	"hud_texture_slots"
]

const EXPANDED_PRODUCTION_RELICS := {
	"ash_rosary": {
		"asset_path": "res://assets/art/generated/relics/relic_ash_rosary_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_ash_rosary.svg"
	},
	"blank_contract": {
		"asset_path": "res://assets/art/generated/relics/relic_blank_contract_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_blank_contract.svg"
	},
	"echo_stone": {
		"asset_path": "res://assets/art/generated/relics/relic_echo_stone_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_echo_stone.svg"
	},
	"heavy_gear": {
		"asset_path": "res://assets/art/generated/relics/relic_heavy_gear_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_heavy_gear.svg"
	},
	"molten_core_ring": {
		"asset_path": "res://assets/art/generated/relics/relic_molten_core_ring_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_molten_core_ring.svg"
	},
	"old_compass": {
		"asset_path": "res://assets/art/generated/relics/relic_old_compass_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_old_compass.svg"
	},
	"shield_break_wedge": {
		"asset_path": "res://assets/art/generated/relics/relic_shield_break_wedge_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_shield_break_wedge.svg"
	},
	"war_drum_fragment": {
		"asset_path": "res://assets/art/generated/relics/relic_war_drum_fragment_v2_pc.png",
		"slot_path": "res://assets/art/relics/relic_war_drum_fragment.svg"
	}
}

var failed := false

func _init() -> void:
	_test_production_preferred_bitmap_is_strict()
	_test_alpha_pixels_and_subject_bounds_are_read()
	_test_legacy_svg_is_advisory()
	_test_production_required_missing_asset_is_hard_failure()
	_test_unknown_production_tier_is_hard_failure()
	_test_real_manifest_contract()
	if failed:
		quit(1)
	else:
		print("Art asset auditor tests passed.")
		quit(0)

func _test_production_preferred_bitmap_is_strict() -> void:
	var valid_fixture := _fixture_manifest(
		"res://assets/art/generated/card_relay_strike_v2_pc.png",
		"production_preferred",
		_card_contract()
	)
	var valid_report: Dictionary = ArtAssetAuditorScript.audit(valid_fixture)
	var valid_item: Dictionary = valid_report.get("items", [])[0]
	_check(valid_item.get("width", 0) == 784 and valid_item.get("height", 0) == 1168, "auditor reads bitmap dimensions")
	_check(valid_item.get("color_mode", "") == "RGB", "auditor reads RGB channel mode")
	_check(not bool(valid_item.get("has_alpha_channel", true)), "RGB bitmap has no alpha channel")
	_check(not bool(valid_item.get("uses_transparency", true)), "RGB bitmap has no transparent pixels")
	_check(valid_item.get("asset_tier", "") == "production_preferred", "bitmap keeps production preferred tier")
	_check(valid_item.get("hard_errors", []).is_empty(), "conforming production preferred bitmap has no hard errors")

	var invalid_fixture := _fixture_manifest(
		"res://assets/art/generated/card_ash_guard_pc.png",
		"production_preferred",
		_card_contract()
	)
	var invalid_item: Dictionary = ArtAssetAuditorScript.audit(invalid_fixture).get("items", [])[0]
	_check(_has_issue_code(invalid_item.get("hard_errors", []), "dimension_mismatch"), "production preferred dimension mismatch is hard")
	_check(_has_issue_code(invalid_item.get("hard_errors", []), "aspect_ratio_mismatch"), "production preferred aspect mismatch is hard")

func _test_alpha_pixels_and_subject_bounds_are_read() -> void:
	var fixture := _fixture_manifest(
		"res://assets/art/generated/potions/potion_volatile_vial_v2_pc.png",
		"production_required",
		_potion_contract()
	)
	var item: Dictionary = ArtAssetAuditorScript.audit(fixture).get("items", [])[0]
	_check(item.get("color_mode", "") == "RGBA", "auditor reads RGBA channel mode")
	_check(bool(item.get("has_alpha_channel", false)), "RGBA bitmap reports alpha channel")
	_check(bool(item.get("uses_transparency", false)), "auditor detects actual transparent pixels")
	_check(item.get("alpha_mode", "") in ["bit", "blend"], "auditor reports detected alpha mode")
	var subject_bounds: Dictionary = item.get("subject_bounds", {})
	_check(not subject_bounds.is_empty(), "transparent bitmap exposes alpha subject bounds")
	_check(float(subject_bounds.get("width_ratio", 0.0)) > 0.0, "subject bounds include normalized width")
	_check(float(subject_bounds.get("height_ratio", 0.0)) > 0.0, "subject bounds include normalized height")

func _test_legacy_svg_is_advisory() -> void:
	var fixture := _fixture_manifest(
		"res://assets/art/cards/card_violent_discharge.svg",
		"production_preferred",
		_card_contract(),
		true
	)
	var report: Dictionary = ArtAssetAuditorScript.audit(fixture)
	var item: Dictionary = report.get("items", [])[0]
	_check(item.get("asset_tier", "") == "legacy_fallback", "allowed SVG resolves to legacy fallback")
	_check(item.get("hard_errors", []).is_empty(), "loadable legacy SVG does not hard fail")
	_check(_has_issue_code(item.get("advisories", []), "legacy_fallback"), "legacy SVG emits replacement advisory")
	_check(report.get("summary", {}).get("legacy_fallback", 0) == 1, "summary counts legacy fallback")

func _test_production_required_missing_asset_is_hard_failure() -> void:
	var fixture := _fixture_manifest(
		"res://assets/art/generated/does_not_exist.png",
		"production_required",
		_card_contract()
	)
	var report: Dictionary = ArtAssetAuditorScript.audit(fixture)
	var item: Dictionary = report.get("items", [])[0]
	_check(_has_issue_code(item.get("hard_errors", []), "asset_missing"), "missing production required bitmap is hard")
	_check(report.get("summary", {}).get("hard_failures", 0) == 1, "summary counts hard-failed item")

func _test_unknown_production_tier_is_hard_failure() -> void:
	var fixture := _fixture_manifest(
		"res://assets/art/generated/card_relay_strike_v2_pc.png",
		"production_prefered",
		_card_contract()
	)
	var report: Dictionary = ArtAssetAuditorScript.audit(fixture)
	var item: Dictionary = report.get("items", [])[0]
	_check(item.get("asset_tier", "") == "invalid", "unknown production tier is not silently downgraded")
	_check(_has_issue_code(item.get("hard_errors", []), "production_tier_invalid"), "unknown production tier is a hard error")
	_check(report.get("summary", {}).get("hard_failures", 0) == 1, "summary blocks an unknown production tier")

func _test_real_manifest_contract() -> void:
	var file := FileAccess.open("res://data/config/art_assets.json", FileAccess.READ)
	_check(file != null, "real art manifest opens")
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	_check(parsed is Dictionary, "real art manifest is valid JSON")
	if not parsed is Dictionary:
		return
	var art_data: Dictionary = parsed
	var asset_contract: Dictionary = art_data.get("asset_contract", {})
	_check(int(asset_contract.get("schema_version", 0)) >= 1, "manifest has versioned asset contract")
	var baseline: Dictionary = asset_contract.get("pc_baseline", {})
	_check(baseline.get("width", 0) == 1280 and baseline.get("height", 0) == 720, "contract records PC baseline")
	var section_defaults: Dictionary = asset_contract.get("section_defaults", {})
	var contracts: Dictionary = asset_contract.get("contracts", {})
	for section in REQUIRED_BITMAP_SECTIONS:
		_check(section_defaults.has(section), "contract covers required section: %s" % section)
		_check(not art_data.get(section, []).is_empty(), "manifest has slots for required section: %s" % section)
	var contracts_complete := true
	for contract_id_value in contracts.keys():
		var contract_id: String = str(contract_id_value)
		var contract: Dictionary = contracts.get(contract_id, {})
		for field in ["allowed_extensions", "expected_dimensions", "expected_aspect_ratio", "color_mode", "alpha_requirement", "safe_area", "subject_occupancy"]:
			contracts_complete = contracts_complete and contract.has(field)
	_check(contracts_complete, "every asset contract contains dimensions, ratio, channels, alpha, safe area, and occupancy")
	_check(_all_slots_resolve_contracts(art_data, section_defaults, contracts), "every contracted slot resolves a contract")
	_check(_player_stage_coverage_complete(art_data), "player stage slots cover every configured character")
	_check(_enemy_stage_coverage_complete(art_data), "enemy stage slots cover every configured sprite key")
	for hud_id in ["battle_stage_frame", "hand_tray", "resource_chip", "enemy_plate", "end_turn_button", "feedback_toast"]:
		_check(not _find_slot(art_data.get("hud_texture_slots", []), hud_id).is_empty(), "HUD contract contains %s" % hud_id)

	var expected_total := 0
	for section_value in section_defaults.keys():
		expected_total += art_data.get(str(section_value), []).size()
	var report: Dictionary = ArtAssetAuditorScript.audit(art_data)
	var summary: Dictionary = report.get("summary", {})
	_check(summary.get("total", -1) == expected_total, "real manifest total matches contracted sections")
	_check(report.get("items", []).size() == expected_total, "report includes every contracted item")
	_check(int(summary.get("production_required", 0)) > 0, "manifest has production required assets")
	_check(int(summary.get("production_preferred", 0)) > 0, "manifest has production preferred assets")
	_check(int(summary.get("legacy_fallback", 0)) > 0, "manifest retains legacy fallbacks")
	_check(int(summary.get("hard_failures", -1)) == 0, "real manifest has zero hard-failed assets")
	_check(int(summary.get("hard_errors", -1)) == 0, "real manifest has zero hard errors")
	var item_shape_valid := true
	var item_sections_valid := true
	for item_value in report.get("items", []):
		var item: Dictionary = item_value
		for field in ["section", "id", "asset_path", "contract_id", "asset_tier", "quality_tier", "status", "hard_errors", "advisories"]:
			item_shape_valid = item_shape_valid and item.has(field)
		item_sections_valid = item_sections_valid and section_defaults.has(item.get("section", ""))
	_check(item_shape_valid, "every audited item has the report contract")
	_check(item_sections_valid, "every audited item belongs to a contracted section")

	var known_card := _find_item(report.get("items", []), "card_art_slots", "relay_strike")
	_check(known_card.get("width", 0) == 784 and known_card.get("height", 0) == 1168, "real card dimensions are audited")
	_check(known_card.get("color_mode", "") == "RGB", "real card channel mode is audited")
	var known_potion := _find_item(report.get("items", []), "potion_icon_slots", "volatile_vial")
	_check(known_potion.get("color_mode", "") == "RGBA" and bool(known_potion.get("uses_transparency", false)), "real potion alpha is audited")
	var expanded_relic_paths := {}
	var expanded_relic_hashes := {}
	for relic_id_value in EXPANDED_PRODUCTION_RELICS.keys():
		var relic_id: String = str(relic_id_value)
		var expected: Dictionary = EXPANDED_PRODUCTION_RELICS.get(relic_id, {})
		var relic_slot := _find_slot(art_data.get("relic_icon_slots", []), relic_id)
		var relic_item := _find_item(report.get("items", []), "relic_icon_slots", relic_id)
		var asset_path: String = str(relic_slot.get("asset_path", ""))
		var subject_bounds: Dictionary = relic_item.get("subject_bounds", {})
		var subject_area_ratio := float(subject_bounds.get("area_ratio", 0.0))
		_check(asset_path == expected.get("asset_path", ""), "expanded relic keeps its exact production path: %s" % relic_id)
		_check(relic_slot.get("slot_path", "") == expected.get("slot_path", ""), "expanded relic keeps its stable SVG slot: %s" % relic_id)
		_check(relic_item.get("width", 0) == 512 and relic_item.get("height", 0) == 512, "expanded relic is exactly 512x512: %s" % relic_id)
		_check(relic_item.get("color_mode", "") == "RGBA" and bool(relic_item.get("has_alpha_channel", false)) and bool(relic_item.get("uses_transparency", false)), "expanded relic has RGBA transparency: %s" % relic_id)
		_check(relic_item.get("asset_tier", "") == "production_preferred", "expanded relic uses the production bitmap contract: %s" % relic_id)
		_check(subject_area_ratio >= 0.30 and subject_area_ratio <= 0.82, "expanded relic subject occupancy matches the batch design: %s" % relic_id)
		_check(not expanded_relic_paths.has(asset_path), "expanded relic uses a unique production path: %s" % relic_id)
		expanded_relic_paths[asset_path] = relic_id
		var asset_hash := FileAccess.get_md5(asset_path)
		_check(not asset_hash.is_empty(), "expanded relic file is hashable: %s" % relic_id)
		_check(not expanded_relic_hashes.has(asset_hash), "expanded relic has independent image content: %s" % relic_id)
		expanded_relic_hashes[asset_hash] = relic_id
	_check(expanded_relic_paths.size() == EXPANDED_PRODUCTION_RELICS.size(), "all expanded relic production paths are unique")
	_check(expanded_relic_hashes.size() == EXPANDED_PRODUCTION_RELICS.size(), "all expanded relic images have unique content")
	var production_relic_count := 0
	for report_item_value in report.get("items", []):
		var report_item: Dictionary = report_item_value
		if report_item.get("section", "") == "relic_icon_slots" and report_item.get("asset_tier", "") == "production_preferred":
			production_relic_count += 1
	_check(production_relic_count >= 13, "real manifest contains the expanded production relic batch")
	var known_event := _find_item(report.get("items", []), "event_art_slots", "broken_reactor")
	_check(known_event.get("width", 0) == 1536 and known_event.get("height", 0) == 1024, "real event illustration dimensions are audited")
	_check(known_event.get("color_mode", "") == "RGB" and known_event.get("asset_tier", "") == "production_preferred", "real event illustration uses the production RGB contract")
	var known_room := _find_item(report.get("items", []), "room_scene_slots", "campfire")
	_check(known_room.get("width", 0) == 1536 and known_room.get("height", 0) == 1024, "real campfire room dimensions are audited")
	_check(known_room.get("color_mode", "") == "RGB" and known_room.get("asset_tier", "") == "production_preferred", "real campfire room uses the production RGB contract")
	_check(known_room.get("contract_id", "") == "room_illustration", "real campfire room is bound to the room illustration contract")
	var room_defaults: Dictionary = section_defaults.get("room_scene_slots", {})
	_check(room_defaults.get("contract_id", "") == "room_illustration" and not bool(room_defaults.get("legacy_fallback_allowed", true)), "campfire room section forbids legacy fallback")
	var legacy_card := _find_item(report.get("items", []), "card_art_slots", "violent_discharge")
	_check(legacy_card.get("asset_tier", "") == "legacy_fallback", "real SVG card remains a legacy fallback")
	_check(legacy_card.get("hard_errors", []).is_empty(), "real SVG card does not hard fail")

func _fixture_manifest(asset_path: String, production_tier: String, contract: Dictionary, legacy_fallback_allowed: bool = false) -> Dictionary:
	return {
		"asset_contract": {
			"schema_version": 1,
			"pc_baseline": {"width": 1280, "height": 720},
			"section_defaults": {
				"card_art_slots": {
					"contract_id": "fixture",
					"production_tier": production_tier,
					"legacy_fallback_allowed": legacy_fallback_allowed
				}
			},
			"contracts": {"fixture": contract}
		},
		"card_art_slots": [{"id": "fixture", "asset_path": asset_path}]
	}

func _card_contract() -> Dictionary:
	return {
		"allowed_extensions": ["png", "webp"],
		"expected_dimensions": {"mode": "exact", "width": 784, "height": 1168},
		"expected_aspect_ratio": {"mode": "exact", "value": 0.671233, "tolerance": 0.001},
		"color_mode": "RGB",
		"alpha_requirement": "forbidden",
		"safe_area": {"check": "manual", "normalized_rect": [0.08, 0.08, 0.84, 0.84], "enforcement": "advisory"},
		"subject_occupancy": {"check": "manual", "metric": "visual_subject_area_ratio", "min": 0.30, "max": 0.78, "enforcement": "advisory"}
	}

func _potion_contract() -> Dictionary:
	return {
		"allowed_extensions": ["png", "webp"],
		"expected_dimensions": {"mode": "minimum", "width": 1024, "height": 1024},
		"expected_aspect_ratio": {"mode": "exact", "value": 1.0, "tolerance": 0.001},
		"color_mode": "RGBA",
		"alpha_requirement": "required",
		"safe_area": {"check": "alpha_bounds", "normalized_rect": [0.02, 0.02, 0.96, 0.96], "enforcement": "advisory"},
		"subject_occupancy": {"check": "alpha_bounds", "metric": "alpha_bbox_area_ratio", "min": 0.30, "max": 0.82, "enforcement": "advisory"}
	}

func _find_item(items: Array, section: String, item_id: String) -> Dictionary:
	for item_value in items:
		var item: Dictionary = item_value
		if item.get("section", "") == section and item.get("id", "") == item_id:
			return item
	return {}

func _find_slot(slots: Array, slot_id: String) -> Dictionary:
	for slot_value in slots:
		var slot: Dictionary = slot_value
		if slot.get("id", "") == slot_id:
			return slot
	return {}

func _all_slots_resolve_contracts(art_data: Dictionary, section_defaults: Dictionary, contracts: Dictionary) -> bool:
	for section_value in section_defaults.keys():
		var section := str(section_value)
		var default_contract_id := str(section_defaults.get(section, {}).get("contract_id", ""))
		for slot_value in art_data.get(section, []):
			var slot: Dictionary = slot_value
			var contract_id := str(slot.get("contract_id", default_contract_id))
			if not contracts.has(contract_id):
				return false
	return true

func _player_stage_coverage_complete(art_data: Dictionary) -> bool:
	var player_data := _load_json("res://data/config/player.json")
	for character_value in player_data.get("characters", []):
		var character: Dictionary = character_value
		if _find_slot(art_data.get("player_stage_slots", []), str(character.get("id", ""))).is_empty():
			return false
	return true

func _enemy_stage_coverage_complete(art_data: Dictionary) -> bool:
	var enemy_data := _load_json("res://data/enemies/enemies.json")
	for enemy_value in enemy_data.get("enemies", []):
		var enemy: Dictionary = enemy_value
		if _find_slot(art_data.get("enemy_stage_slots", []), str(enemy.get("sprite_key", ""))).is_empty():
			return false
	return true

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _has_issue_code(issues: Array, code: String) -> bool:
	for issue_value in issues:
		var issue: Dictionary = issue_value
		if issue.get("code", "") == code:
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failed = true
		push_error("FAIL: %s" % message)
