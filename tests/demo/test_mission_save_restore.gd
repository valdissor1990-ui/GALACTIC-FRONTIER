extends SceneTree
## End-to-end quick-save test against the actual Silent Relay scene.
## Run:
##   godot --headless --path . --script res://tests/demo/test_mission_save_restore.gd

var _passed: int = 0
var _failed: int = 0
var _mission: Node


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — Mission quick-save tests ===")
	call_deferred("_run_tests")


func _run_tests() -> void:
	SaveSlots.save_directory = "user://test_mission_saves"
	_clean_test_directory()
	var packed := load("res://scenes/demo/ten_minute_demo.tscn") as PackedScene
	_assert_true(packed != null, "demo mission scene loads")
	if packed == null:
		_finish()
		return
	_mission = packed.instantiate()
	root.add_child(_mission)
	await process_frame
	await process_frame

	var director := _mission.get_node_or_null("DemoMissionDirector")
	var player := _mission.get_node_or_null("PlayerShip") as ShipController
	_assert_true(director != null, "mission director is present")
	_assert_true(player != null, "player ship is present")
	if director == null or player == null:
		_finish()
		return

	player.global_position = Vector3(14.5, 22.0, -31.25)
	player.global_rotation = Vector3(0.1, 0.2, -0.05)
	player.velocity = Vector3(12.0, -3.0, 7.5)
	player.boost_amount = 4.25
	director.set("mission_seconds", 123.5)
	director.set("stage", 0)

	var save_key := InputEventKey.new()
	save_key.keycode = KEY_F5
	save_key.pressed = true
	director.call("_unhandled_input", save_key)
	var saved := SaveSlots.load_slot("quick")
	_assert_true(saved.ok, "F5 creates a valid quick save")

	player.global_position = Vector3(-500.0, 100.0, 900.0)
	player.velocity = Vector3.ZERO
	player.boost_amount = 0.0
	director.set("mission_seconds", 999.0)
	director.set("stage", 6)

	var load_key := InputEventKey.new()
	load_key.keycode = KEY_F9
	load_key.pressed = true
	director.call("_unhandled_input", load_key)

	_assert_true(player.global_position.is_equal_approx(Vector3(14.5, 22.0, -31.25)), "F9 restores player position")
	_assert_true(player.velocity.is_equal_approx(Vector3(12.0, -3.0, 7.5)), "F9 restores flight velocity")
	_assert_true(is_equal_approx(player.boost_amount, 4.25), "F9 restores boost reserve")
	_assert_true(is_equal_approx(float(director.get("mission_seconds")), 123.5), "F9 restores mission timer")
	_assert_true(int(director.get("stage")) == 0, "F9 restores mission stage")

	_finish()


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % message)
	else:
		_failed += 1
		print("  FAIL  %s" % message)


func _clean_test_directory() -> void:
	var directory := DirAccess.open(SaveSlots.save_directory)
	if directory == null:
		return
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSlots.save_directory.path_join(filename)))
		filename = directory.get_next()
	directory.list_dir_end()


func _finish() -> void:
	if is_instance_valid(_mission):
		_mission.queue_free()
	_clean_test_directory()
	print("")
	if _failed == 0:
		print("RESULT: PASS (%d assertions)" % _passed)
		quit(0)
	else:
		print("RESULT: FAIL (%d passed, %d failed)" % [_passed, _failed])
		quit(1)
