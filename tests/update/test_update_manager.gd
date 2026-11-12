extends SceneTree
## Offline regression tests for updater version comparison and local version source.

const UPDATER_SCRIPT := preload("res://scripts/update/update_manager.gd")
var _passed := 0
var _failed := 0


func _initialize() -> void:
	var updater := UPDATER_SCRIPT.new()
	root.add_child(updater)
	_check(updater.current_version() == "0.1.0", "version comes from project configuration")
	_check(updater._is_newer("0.1.1", "0.1.0"), "patch update is detected")
	_check(updater._is_newer("0.2.0", "0.1.9"), "minor update is detected")
	_check(updater._is_newer("1.0.0", "0.9.9"), "major update is detected")
	_check(not updater._is_newer("0.1.0", "0.1.0"), "same version is not an update")
	_check(not updater._is_newer("0.1.0", "0.1.1"), "older release is not an update")
	_check(not updater._is_newer("0.2.3", "0.2.10"), "numeric components are compared numerically")
	if _failed == 0:
		print("UPDATE_MANAGER_TEST_PASS assertions=", _passed)
		quit(0)
	else:
		push_error("UPDATE_MANAGER_TEST_FAIL assertions_failed=%d" % _failed)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("  FAIL " + message)
