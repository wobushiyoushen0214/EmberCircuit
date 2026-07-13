class_name ArtAssetAuditor
extends RefCounted

const AUDITED_SECTIONS := [
	"battle_background_slots",
	"event_art_slots",
	"card_art_slots",
	"relic_icon_slots",
	"potion_icon_slots"
]

static func audit(art_data: Dictionary) -> Dictionary:
	var items: Array = []
	var summary := {
		"total": 0,
		"production_candidate": 0,
		"first_pass": 0,
		"missing": 0
	}
	for section in AUDITED_SECTIONS:
		for slot_value in art_data.get(section, []):
			var slot: Dictionary = slot_value
			var asset_path := str(slot.get("asset_path", ""))
			var quality_tier := _quality_tier(asset_path)
			items.append({
				"section": section,
				"id": str(slot.get("id", "")),
				"asset_path": asset_path,
				"quality_tier": quality_tier,
				"priority": _priority(quality_tier)
			})
			summary[quality_tier] = int(summary[quality_tier]) + 1
			summary.total = int(summary.total) + 1
	return {"summary": summary, "items": items}

static func _quality_tier(asset_path: String) -> String:
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return "missing"
	var extension := asset_path.get_extension().to_lower()
	if asset_path.begins_with("res://assets/art/generated/") and extension in ["png", "webp", "jpg", "jpeg"]:
		return "production_candidate"
	if extension == "svg":
		return "first_pass"
	return "first_pass"

static func _priority(quality_tier: String) -> String:
	match quality_tier:
		"missing":
			return "high"
		"first_pass":
			return "medium"
		_:
			return "low"
