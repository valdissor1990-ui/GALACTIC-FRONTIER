extends SceneTree
## Headless tests for local save slot validation, integrity and recovery.
## Run:
##   godot --headless --path . --script res://tests/save/test_save_manager.gd

var _passed: int = 0
var _failed: int = 0
var _manager: SaveManager
const TEST_DIRECTORY := "user://test_saves"


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — Save manager tests ===")
	_manager = SaveManager.new()
	_manager.save_directory = TEST_DIRECTORY
	root.add_child(_manager)
	_clean_test_directory()
	_test_round_trip()
	_test_rejects_invalid_slot()
	_test_rejects_non_finite_payload()
	_test_lists_only_valid_slots()
	_test_recovers_from_corrupt_primary()
	_test_delete_removes_slot_and_backup()
	_clean_test_directory()
	print("")
	if _failed == 0:
		print("RESULT: PASS  (%d assertions)" % _passed)
		quit(0)
	else:
		print("RESULT: FAIL  (%d passed, %d failed)" % [_passed, _failed])
		quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % message)
	else:
		_failed += 1
		print("  FAIL  %s" % message)


func _clean_test_directory() -> void:
	var directory := DirAccess.open(TEST_DIRECTORY)
	if directory == null:
		return
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY.path_join(filename)))
		filename = directory.get_next()
	directory.list_dir_end()


func _test_round_trip() -> void:
	print("\n[save/load round trip]")
	var payload := {
		"player": {"position": [12.5, -4.0, 88.25], "hull": 82.0, "shield": 40.0},
		"credits": 12500,
		"completed_missions": ["silent_relay_intro"]
	}
	var saved := _manager.save_slot("slot_1", payload)
	var loaded := _manager.load_slot("slot_1")
	_assert_true(saved.ok, "valid payload saves")
	_assert_true(loaded.ok, "saved slot loads" + ("" if loaded.ok else ": " + str(loaded.get("error", "unknown"))))
	if loaded.ok:
		var json_normalized: Dictionary = JSON.parse_string(JSON.stringify(payload))
		_assert_true(loaded.payload == json_normalized, "loaded payload matches JSON-normalized original data")
	if loaded.ok:
		_assert_true(not loaded.recovered_from_backup, "normal load does not use backup")


func _test_rejects_invalid_slot() -> void:
	print("\n[slot id validation]")
	var result := _manager.save_slot("../outside", {"credits": 1})
	_assert_true(not result.ok, "path traversal slot id is rejected")


func _test_rejects_non_finite_payload() -> void:
	print("\n[payload validation]")
	var result := _manager.save_slot("invalid", {"credits": INF})
	_assert_true(not result.ok, "non-finite numbers are rejected")


func _test_lists_only_valid_slots() -> void:
	print("\n[slot listing]")
	_manager.save_slot("slot_2", {"credits": 50})
	var slots := _manager.list_slots()
	_assert_true(slots.size() == 2, "only valid JSON save slots are listed")


func _test_recovers_from_corrupt_primary() -> void:
	print("\n[backup recovery]")
	_manager.save_slot("recovery", {"credits": 100})
	_manager.save_slot("recovery", {"credits": 250})
	var file := FileAccess.open(TEST_DIRECTORY.path_join("recovery.json"), FileAccess.WRITE)
	file.store_string("{ broken json")
	file.close()
	var loaded := _manager.load_slot("recovery")
	_assert_true(loaded.ok, "corrupt primary falls back to backup")
	if loaded.ok:
		_assert_true(loaded.recovered_from_backup, "load reports backup recovery")
		_assert_true(int(loaded.payload.credits) == 100, "backup contains previous committed save")


func _test_delete_removes_slot_and_backup() -> void:
	print("\n[slot deletion]")
	var result := _manager.delete_slot("recovery")
	_assert_true(result.ok, "slot and backup are deleted")
	_assert_true(not FileAccess.file_exists(TEST_DIRECTORY.path_join("recovery.json")), "primary file is removed")
	_assert_true(not FileAccess.file_exists(TEST_DIRECTORY.path_join("recovery.json.bak")), "backup file is removed")
