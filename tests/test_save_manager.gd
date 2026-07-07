extends SceneTree

const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")

func _init() -> void:
	var state := {
		"version": 1,
		"run_deck_ids": ["ember_strike", "ash_guard+"],
		"run_relic_ids": ["ember_bottle"],
		"run_potion_ids": ["volatile_vial"],
		"run_hp": 42,
		"run_max_hp": 72,
		"run_gold": 123,
		"current_node_index": 3,
		"run_completed": false
	}

	_check(SaveManagerScript.save_run(state), "save_run returns true")
	var loaded: Dictionary = SaveManagerScript.load_run()
	_check(int(loaded.get("run_hp", 0)) == 42, "load_run restores HP")
	_check(int(loaded.get("run_gold", 0)) == 123, "load_run restores gold")
	_check(loaded.get("run_deck_ids", []).size() == 2, "load_run restores deck")
	_check(str(loaded.get("run_deck_ids", [])[1]) == "ash_guard+", "load_run keeps upgraded card marker")
	_check(str(loaded.get("run_potion_ids", [])[0]) == "volatile_vial", "load_run restores potions")

	print("Save manager smoke test passed.")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("Test failed: %s" % message)
		quit(1)
