class_name ArtAssetAuditor
extends RefCounted

const LEGACY_AUDITED_SECTIONS := [
	"battle_background_slots",
	"event_art_slots",
	"card_art_slots",
	"relic_icon_slots",
	"potion_icon_slots"
]
const BITMAP_EXTENSIONS := ["png", "webp", "jpg", "jpeg"]
const STRICT_TIERS := ["production_required", "production_preferred"]
const VALID_TIERS := ["production_required", "production_preferred", "legacy_fallback"]

static func audit(art_data: Dictionary) -> Dictionary:
	var asset_contract: Dictionary = art_data.get("asset_contract", {})
	var section_defaults: Dictionary = asset_contract.get("section_defaults", {}).duplicate(true)
	var contracts: Dictionary = asset_contract.get("contracts", {}).duplicate(true)
	if section_defaults.is_empty():
		section_defaults = _legacy_section_defaults()
		contracts["legacy_uncontracted"] = _legacy_contract()

	var items: Array = []
	var summary := {
		"total": 0,
		"production_candidate": 0,
		"first_pass": 0,
		"missing": 0,
		"production_required": 0,
		"production_preferred": 0,
		"legacy_fallback": 0,
		"compliant": 0,
		"advisory": 0,
		"hard_failures": 0,
		"hard_errors": 0,
		"advisories": 0,
		"manual_reviews": 0
	}

	for section_value in section_defaults.keys():
		var section := str(section_value)
		var section_rule: Dictionary = section_defaults.get(section, {})
		for slot_value in art_data.get(section, []):
			if not slot_value is Dictionary:
				continue
			var item := _audit_slot(section, slot_value, section_rule, contracts)
			items.append(item)
			_accumulate_summary(summary, item)

	return {
		"contract_schema_version": int(asset_contract.get("schema_version", 0)),
		"pc_baseline": asset_contract.get("pc_baseline", {}),
		"summary": summary,
		"items": items
	}

static func _audit_slot(section: String, slot: Dictionary, section_rule: Dictionary, contracts: Dictionary) -> Dictionary:
	var asset_path := str(slot.get("asset_path", ""))
	var extension := asset_path.get_extension().to_lower()
	var configured_tier := str(slot.get("production_tier", section_rule.get("production_tier", "legacy_fallback")))
	var asset_tier := _resolve_asset_tier(extension, configured_tier, section_rule)
	var contract_id := str(slot.get("contract_id", section_rule.get("contract_id", "")))
	var contract: Dictionary = contracts.get(contract_id, {})
	var item := {
		"section": section,
		"id": str(slot.get("id", "")),
		"asset_path": asset_path,
		"contract_id": contract_id,
		"configured_tier": configured_tier,
		"asset_tier": asset_tier,
		"quality_tier": _quality_tier(asset_path),
		"status": "pass",
		"priority": "low",
		"extension": extension,
		"width": 0,
		"height": 0,
		"aspect_ratio": 0.0,
		"color_mode": "",
		"has_alpha_channel": false,
		"uses_transparency": false,
		"alpha_mode": "none",
		"subject_bounds": {},
		"hard_errors": [],
		"advisories": []
	}

	if not configured_tier in VALID_TIERS:
		_add_hard_error(item, "production_tier_invalid", "Unknown production tier: %s" % configured_tier)
		return _finalize_item(item)
	if contract.is_empty():
		_add_hard_error(item, "contract_missing", "Contract '%s' is not defined." % contract_id)
		return _finalize_item(item)
	if not _asset_exists(asset_path):
		_add_hard_error(item, "asset_missing", "Asset does not exist: %s" % asset_path)
		return _finalize_item(item)

	if extension == "svg":
		if asset_tier == "legacy_fallback":
			_add_advisory(item, "legacy_fallback", "Loadable SVG remains available but needs a production bitmap replacement.")
		else:
			_add_hard_error(item, "production_bitmap_required", "Tier %s requires a production bitmap, not SVG." % asset_tier)
		return _finalize_item(item)

	if not extension in BITMAP_EXTENSIONS:
		_add_hard_error(item, "unsupported_extension", "Unsupported asset extension: %s" % extension)
		return _finalize_item(item)

	var image := Image.new()
	var load_error := _load_source_image(image, asset_path, extension)
	if load_error != OK:
		_add_hard_error(item, "bitmap_unreadable", "Bitmap cannot be decoded: %s" % asset_path)
		return _finalize_item(item)

	_read_image_metadata(item, image)
	if asset_tier in STRICT_TIERS:
		_validate_strict_bitmap(item, contract)
	else:
		_add_advisory(item, "legacy_fallback", "Legacy bitmap is readable but is not accepted as a production asset.")
	if asset_tier != "legacy_fallback":
		_validate_composition(item, contract)
	return _finalize_item(item)

static func _load_source_image(image: Image, asset_path: String, extension: String) -> Error:
	var bytes := FileAccess.get_file_as_bytes(asset_path)
	if bytes.is_empty():
		return ERR_FILE_CANT_READ
	match extension:
		"png":
			return image.load_png_from_buffer(bytes)
		"webp":
			return image.load_webp_from_buffer(bytes)
		"jpg", "jpeg":
			return image.load_jpg_from_buffer(bytes)
	return ERR_FILE_UNRECOGNIZED

static func _read_image_metadata(item: Dictionary, image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var image_format := image.get_format()
	var alpha_mode_value := image.detect_alpha()
	var has_alpha_channel := _format_has_alpha(image_format)
	var uses_transparency := alpha_mode_value != Image.ALPHA_NONE
	item["width"] = width
	item["height"] = height
	item["aspect_ratio"] = float(width) / float(height) if height > 0 else 0.0
	item["color_mode"] = _color_mode(image_format)
	item["has_alpha_channel"] = has_alpha_channel
	item["uses_transparency"] = uses_transparency
	item["alpha_mode"] = _alpha_mode_name(alpha_mode_value)
	if has_alpha_channel and uses_transparency and width > 0 and height > 0:
		var used_rect := image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			item["subject_bounds"] = {
				"x": used_rect.position.x,
				"y": used_rect.position.y,
				"width": used_rect.size.x,
				"height": used_rect.size.y,
				"x_ratio": float(used_rect.position.x) / float(width),
				"y_ratio": float(used_rect.position.y) / float(height),
				"width_ratio": float(used_rect.size.x) / float(width),
				"height_ratio": float(used_rect.size.y) / float(height),
				"area_ratio": float(used_rect.size.x * used_rect.size.y) / float(width * height)
			}

static func _validate_strict_bitmap(item: Dictionary, contract: Dictionary) -> void:
	var extension := str(item.get("extension", ""))
	var allowed_extensions: Array = contract.get("allowed_extensions", [])
	if not allowed_extensions.has(extension):
		_add_hard_error(item, "extension_mismatch", "Extension %s is not allowed by the contract." % extension)

	var dimensions: Dictionary = contract.get("expected_dimensions", {})
	var dimension_mode := str(dimensions.get("mode", "any"))
	var expected_width := int(dimensions.get("width", 0))
	var expected_height := int(dimensions.get("height", 0))
	var actual_width := int(item.get("width", 0))
	var actual_height := int(item.get("height", 0))
	var dimensions_match := true
	match dimension_mode:
		"exact":
			dimensions_match = actual_width == expected_width and actual_height == expected_height
		"minimum":
			dimensions_match = actual_width >= expected_width and actual_height >= expected_height
		"maximum":
			dimensions_match = actual_width <= expected_width and actual_height <= expected_height
	if not dimensions_match:
		_add_hard_error(item, "dimension_mismatch", "Dimensions %dx%d do not satisfy %s %dx%d." % [actual_width, actual_height, dimension_mode, expected_width, expected_height])

	var aspect_contract: Dictionary = contract.get("expected_aspect_ratio", {})
	var aspect_mode := str(aspect_contract.get("mode", "any"))
	var actual_aspect := float(item.get("aspect_ratio", 0.0))
	var aspect_matches := true
	match aspect_mode:
		"exact":
			var target := float(aspect_contract.get("value", 0.0))
			var tolerance := maxf(0.0, float(aspect_contract.get("tolerance", 0.0)))
			aspect_matches = absf(actual_aspect - target) <= tolerance
		"range":
			aspect_matches = actual_aspect >= float(aspect_contract.get("min", 0.0)) and actual_aspect <= float(aspect_contract.get("max", INF))
	if not aspect_matches:
		_add_hard_error(item, "aspect_ratio_mismatch", "Aspect ratio %.6f does not satisfy the contract." % actual_aspect)

	var expected_color_mode := str(contract.get("color_mode", "RGB_OR_RGBA"))
	var actual_color_mode := str(item.get("color_mode", ""))
	var color_matches := actual_color_mode == expected_color_mode
	if expected_color_mode == "RGB_OR_RGBA":
		color_matches = actual_color_mode in ["RGB", "RGBA"]
	if not color_matches:
		_add_hard_error(item, "color_mode_mismatch", "Color mode %s does not match expected %s." % [actual_color_mode, expected_color_mode])

	match str(contract.get("alpha_requirement", "optional")):
		"required":
			if not bool(item.get("has_alpha_channel", false)) or not bool(item.get("uses_transparency", false)):
				_add_hard_error(item, "alpha_missing", "Contract requires an alpha channel with transparent pixels.")
		"forbidden":
			if bool(item.get("has_alpha_channel", false)):
				_add_hard_error(item, "alpha_forbidden", "Contract requires an RGB bitmap without an alpha channel.")

static func _validate_composition(item: Dictionary, contract: Dictionary) -> void:
	var safe_area: Dictionary = contract.get("safe_area", {})
	match str(safe_area.get("check", "manual")):
		"manual":
			_add_advisory(item, "manual_safe_area_review", str(safe_area.get("note", "Safe area needs manual review.")))
		"alpha_bounds":
			_validate_alpha_safe_area(item, safe_area)

	var occupancy: Dictionary = contract.get("subject_occupancy", {})
	match str(occupancy.get("check", "manual")):
		"manual":
			_add_advisory(item, "manual_subject_occupancy_review", str(occupancy.get("note", "Subject occupancy needs manual review.")))
		"alpha_bounds":
			_validate_alpha_occupancy(item, occupancy)

static func _validate_alpha_safe_area(item: Dictionary, safe_area: Dictionary) -> void:
	var subject_bounds: Dictionary = item.get("subject_bounds", {})
	if subject_bounds.is_empty():
		_add_configured_issue(item, safe_area, "subject_bounds_unavailable", "Alpha subject bounds are unavailable for safe-area validation.")
		return
	var normalized_rect: Array = safe_area.get("normalized_rect", [])
	if normalized_rect.size() != 4:
		_add_hard_error(item, "safe_area_contract_invalid", "Safe area normalized_rect must contain four values.")
		return
	var safe_left := float(normalized_rect[0])
	var safe_top := float(normalized_rect[1])
	var safe_right := safe_left + float(normalized_rect[2])
	var safe_bottom := safe_top + float(normalized_rect[3])
	var subject_left := float(subject_bounds.get("x_ratio", 0.0))
	var subject_top := float(subject_bounds.get("y_ratio", 0.0))
	var subject_right := subject_left + float(subject_bounds.get("width_ratio", 0.0))
	var subject_bottom := subject_top + float(subject_bounds.get("height_ratio", 0.0))
	if subject_left < safe_left or subject_top < safe_top or subject_right > safe_right or subject_bottom > safe_bottom:
		_add_configured_issue(item, safe_area, "safe_area_violation", "Alpha subject bounds extend outside the normalized safe area.")

static func _validate_alpha_occupancy(item: Dictionary, occupancy: Dictionary) -> void:
	var subject_bounds: Dictionary = item.get("subject_bounds", {})
	if subject_bounds.is_empty():
		_add_configured_issue(item, occupancy, "subject_bounds_unavailable", "Alpha subject bounds are unavailable for occupancy validation.")
		return
	var value := float(subject_bounds.get("area_ratio", 0.0))
	var minimum := float(occupancy.get("min", 0.0))
	var maximum := float(occupancy.get("max", 1.0))
	if value < minimum or value > maximum:
		_add_configured_issue(item, occupancy, "subject_occupancy_violation", "Alpha bounding-box occupancy %.4f is outside %.4f..%.4f." % [value, minimum, maximum])

static func _resolve_asset_tier(extension: String, configured_tier: String, section_rule: Dictionary) -> String:
	if extension == "svg" and configured_tier == "production_preferred" and bool(section_rule.get("legacy_fallback_allowed", false)):
		return "legacy_fallback"
	return configured_tier if configured_tier in VALID_TIERS else "invalid"

static func _quality_tier(asset_path: String) -> String:
	if not _asset_exists(asset_path):
		return "missing"
	var extension := asset_path.get_extension().to_lower()
	if extension in BITMAP_EXTENSIONS:
		return "production_candidate"
	return "first_pass"

static func _asset_exists(asset_path: String) -> bool:
	if asset_path.is_empty():
		return false
	return ResourceLoader.exists(asset_path) or FileAccess.file_exists(asset_path)

static func _color_mode(image_format: Image.Format) -> String:
	match image_format:
		Image.FORMAT_RGB8:
			return "RGB"
		Image.FORMAT_RGBA8:
			return "RGBA"
		Image.FORMAT_L8:
			return "L"
		Image.FORMAT_LA8:
			return "LA"
	return "OTHER"

static func _format_has_alpha(image_format: Image.Format) -> bool:
	return image_format in [Image.FORMAT_RGBA8, Image.FORMAT_LA8]

static func _alpha_mode_name(alpha_mode_value: Image.AlphaMode) -> String:
	match alpha_mode_value:
		Image.ALPHA_BIT:
			return "bit"
		Image.ALPHA_BLEND:
			return "blend"
	return "none"

static func _add_configured_issue(item: Dictionary, rule: Dictionary, code: String, message: String) -> void:
	if str(rule.get("enforcement", "advisory")) == "hard":
		_add_hard_error(item, code, message)
	else:
		_add_advisory(item, code, message)

static func _add_hard_error(item: Dictionary, code: String, message: String) -> void:
	var issues: Array = item.get("hard_errors", [])
	issues.append({"code": code, "message": message})

static func _add_advisory(item: Dictionary, code: String, message: String) -> void:
	var issues: Array = item.get("advisories", [])
	issues.append({"code": code, "message": message})

static func _finalize_item(item: Dictionary) -> Dictionary:
	if not item.get("hard_errors", []).is_empty():
		item["status"] = "failed"
		item["priority"] = "high"
	elif not item.get("advisories", []).is_empty():
		item["status"] = "advisory"
		item["priority"] = "medium"
	else:
		item["status"] = "pass"
		item["priority"] = "low"
	return item

static func _accumulate_summary(summary: Dictionary, item: Dictionary) -> void:
	summary["total"] = int(summary.get("total", 0)) + 1
	var quality_tier := str(item.get("quality_tier", "missing"))
	summary[quality_tier] = int(summary.get(quality_tier, 0)) + 1
	var asset_tier := str(item.get("asset_tier", "legacy_fallback"))
	summary[asset_tier] = int(summary.get(asset_tier, 0)) + 1
	var status := str(item.get("status", "failed"))
	match status:
		"failed":
			summary["hard_failures"] = int(summary.get("hard_failures", 0)) + 1
		"advisory":
			summary["advisory"] = int(summary.get("advisory", 0)) + 1
		_:
			summary["compliant"] = int(summary.get("compliant", 0)) + 1
	var hard_errors: Array = item.get("hard_errors", [])
	var advisories: Array = item.get("advisories", [])
	summary["hard_errors"] = int(summary.get("hard_errors", 0)) + hard_errors.size()
	summary["advisories"] = int(summary.get("advisories", 0)) + advisories.size()
	for advisory_value in advisories:
		var advisory: Dictionary = advisory_value
		if str(advisory.get("code", "")).begins_with("manual_"):
			summary["manual_reviews"] = int(summary.get("manual_reviews", 0)) + 1

static func _legacy_section_defaults() -> Dictionary:
	var defaults := {}
	for section in LEGACY_AUDITED_SECTIONS:
		defaults[section] = {
			"contract_id": "legacy_uncontracted",
			"production_tier": "legacy_fallback",
			"legacy_fallback_allowed": true
		}
	return defaults

static func _legacy_contract() -> Dictionary:
	return {
		"allowed_extensions": ["svg", "png", "webp", "jpg", "jpeg"],
		"expected_dimensions": {"mode": "any", "width": 0, "height": 0},
		"expected_aspect_ratio": {"mode": "any", "value": 0.0, "tolerance": 0.0},
		"color_mode": "RGB_OR_RGBA",
		"alpha_requirement": "optional",
		"safe_area": {"check": "manual", "normalized_rect": [0.0, 0.0, 1.0, 1.0], "enforcement": "advisory"},
		"subject_occupancy": {"check": "manual", "metric": "visual_subject_area_ratio", "min": 0.0, "max": 1.0, "enforcement": "advisory"}
	}
