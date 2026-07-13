extends SceneTree

const ArtAssetAuditorScript = preload("res://scripts/tools/ArtAssetAuditor.gd")
const MANIFEST_PATH := "res://data/config/art_assets.json"

func _init() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取美术资源清单：%s" % MANIFEST_PATH)
		quit(1)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("美术资源清单不是有效 JSON 对象：%s" % MANIFEST_PATH)
		quit(1)
		return
	print(JSON.stringify(ArtAssetAuditorScript.audit(parsed), "  "))
	quit(0)
