extends SceneTree

const ArtAssetAuditorScript = preload("res://scripts/tools/ArtAssetAuditor.gd")

const SECTIONS := [
	"battle_background_slots",
	"event_art_slots",
	"card_art_slots",
	"relic_icon_slots",
	"potion_icon_slots"
]

var failed := false

func _init() -> void:
	_test_in_memory_quality_tiers()
	_test_real_manifest_contract()
	if failed:
		quit(1)
	else:
		print("Art asset auditor tests passed.")
		quit(0)

func _test_in_memory_quality_tiers() -> void:
	var fixture := {
		"battle_background_slots": [{"id": "bitmap", "asset_path": "res://assets/art/generated/chapter_one_battle_v3_pc.png"}],
		"event_art_slots": [{"id": "svg", "asset_path": "res://assets/art/events/event_broken_reactor.svg"}],
		"card_art_slots": [{"id": "missing", "asset_path": "res://assets/art/generated/does_not_exist.png"}],
		"relic_icon_slots": [],
		"potion_icon_slots": []
	}
	var report: Dictionary = ArtAssetAuditorScript.audit(fixture)
	_check(report.get("summary", {}).get("total", -1) == 3, "fixture collects every slot")
	_check(report.get("summary", {}).get("production_candidate", -1) == 1, "generated bitmap is production candidate")
	_check(report.get("summary", {}).get("first_pass", -1) == 1, "loadable SVG is first pass")
	_check(report.get("summary", {}).get("missing", -1) == 1, "missing path is missing")
	var priorities := {}
	for item in report.get("items", []):
		priorities[item.get("quality_tier", "")] = item.get("priority", "")
	_check(priorities.get("production_candidate") == "low", "production candidate priority is low")
	_check(priorities.get("first_pass") == "medium", "first pass priority is medium")
	_check(priorities.get("missing") == "high", "missing priority is high")

func _test_real_manifest_contract() -> void:
	var file := FileAccess.open("res://data/config/art_assets.json", FileAccess.READ)
	_check(file != null, "real art manifest opens")
	if file == null:
		return
	var art_data: Dictionary = JSON.parse_string(file.get_as_text())
	var expected_total := 0
	for section in SECTIONS:
		expected_total += art_data.get(section, []).size()
	var report: Dictionary = ArtAssetAuditorScript.audit(art_data)
	var summary: Dictionary = report.get("summary", {})
	_check(summary.get("total", -1) == expected_total, "real manifest total matches five sections")
	_check(summary.get("production_candidate", 0) + summary.get("first_pass", 0) + summary.get("missing", 0) == expected_total, "quality counts conserve total")
	_check(report.get("items", []).size() == expected_total, "report includes every item")
	for item in report.get("items", []):
		for field in ["section", "id", "asset_path", "quality_tier", "priority"]:
			_check(item.has(field), "item contains %s" % field)
		_check(SECTIONS.has(item.get("section", "")), "item section is audited")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failed = true
		push_error("FAIL: %s" % message)
