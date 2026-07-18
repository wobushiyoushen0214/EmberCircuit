extends SceneTree

const DEFAULT_MEAN_RGB_LIMIT := 0.01
const DEFAULT_CHANGED_PIXEL_LIMIT := 0.02
const PIXEL_CHANGE_EPSILON := 1.0 / 255.0

func _init() -> void:
	_verify.call_deferred()

static func compare_images(actual: Image, golden: Image, regions: Array) -> Dictionary:
	if actual == null or golden == null or actual.get_size() != golden.get_size():
		return {"passed": false, "failed_regions": ["image_size"], "regions": []}
	var region_reports: Array[Dictionary] = []
	var failed_regions: Array[String] = []
	for raw in regions:
		if not raw is Dictionary:
			continue
		var contract: Dictionary = raw
		var region_id := str(contract.get("id", "region_%d" % region_reports.size()))
		var rect := _region_rect(contract.get("rect", []), actual.get_size())
		var pixel_count := maxi(1, rect.size.x * rect.size.y)
		var changed_pixels := 0
		var rgb_difference_sum := 0.0
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var actual_color := actual.get_pixel(x, y)
				var golden_color := golden.get_pixel(x, y)
				var difference := (absf(actual_color.r - golden_color.r) + absf(actual_color.g - golden_color.g) + absf(actual_color.b - golden_color.b)) / 3.0
				rgb_difference_sum += difference
				if difference > PIXEL_CHANGE_EPSILON:
					changed_pixels += 1
		var mean_rgb := rgb_difference_sum / float(pixel_count)
		var changed_ratio := float(changed_pixels) / float(pixel_count)
		var mean_limit := float(contract.get("mean_rgb_limit", DEFAULT_MEAN_RGB_LIMIT))
		var pixel_limit := float(contract.get("changed_pixel_limit", DEFAULT_CHANGED_PIXEL_LIMIT))
		var passed := mean_rgb <= mean_limit and changed_ratio <= pixel_limit
		if not passed:
			failed_regions.append(region_id)
		region_reports.append({
			"id": region_id,
			"passed": passed,
			"mean_rgb_difference": mean_rgb,
			"changed_pixel_ratio": changed_ratio,
			"pixel_count": pixel_count,
			"mean_rgb_limit": mean_limit,
			"changed_pixel_limit": pixel_limit
		})
	return {
		"passed": failed_regions.is_empty(),
		"failed_regions": failed_regions,
		"regions": region_reports
	}

static func _region_rect(raw_rect: Variant, image_size: Vector2i) -> Rect2i:
	if raw_rect is Array and raw_rect.size() >= 4:
		var x := clampi(int(raw_rect[0]), 0, image_size.x)
		var y := clampi(int(raw_rect[1]), 0, image_size.y)
		var width := clampi(int(raw_rect[2]), 0, image_size.x - x)
		var height := clampi(int(raw_rect[3]), 0, image_size.y - y)
		return Rect2i(x, y, width, height)
	return Rect2i(Vector2i.ZERO, image_size)

func _verify() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var actual_dir := str(options.get("actual", "/tmp/embercircuit_pc_gallery"))
	var contract_path := str(options.get("contracts", "res://tests/fixtures/ui_visual_contracts.json"))
	var contract_text := FileAccess.get_file_as_string(contract_path)
	var parsed = JSON.parse_string(contract_text)
	if not parsed is Dictionary:
		push_error("Visual contracts are missing or invalid: %s" % contract_path)
		quit(2)
		return
	var page_reports: Array[Dictionary] = []
	var failed_pages: Array[String] = []
	for raw_page in parsed.get("pages", []):
		if not raw_page is Dictionary:
			continue
		var page: Dictionary = raw_page
		var page_id := str(page.get("id", "page_%d" % page_reports.size()))
		var filename := str(page.get("filename", "%s.png" % page_id))
		var golden_path := str(page.get("golden", "res://tests/golden/ui_720p/%s" % filename))
		var actual_path := actual_dir.path_join(filename)
		var actual := Image.load_from_file(actual_path)
		var golden := Image.load_from_file(golden_path)
		var report := compare_images(actual, golden, page.get("regions", []))
		report["id"] = page_id
		report["actual"] = actual_path
		report["golden"] = golden_path
		if not bool(report.get("passed", false)):
			failed_pages.append(page_id)
		page_reports.append(report)
	var result := {"passed": failed_pages.is_empty(), "failed_pages": failed_pages, "pages": page_reports}
	var output_path := str(options.get("output", "/tmp/embercircuit-ui-visual-report.json"))
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file = null
	print("UI visual report: %s" % output_path)
	quit(0 if bool(result.get("passed", false)) else 1)

func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options := {}
	for argument in arguments:
		var value := str(argument)
		if value.begins_with("--actual="):
			options["actual"] = value.trim_prefix("--actual=")
		elif value.begins_with("--contracts="):
			options["contracts"] = value.trim_prefix("--contracts=")
		elif value.begins_with("--output="):
			options["output"] = value.trim_prefix("--output=")
	return options
