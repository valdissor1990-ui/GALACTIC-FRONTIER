extends Node
## Headless UI tests for the campaign front end.
## Run:
##   godot --headless --path . res://tests/ui/main_menu_test_runner.tscn

var _passed: int = 0
var _failed: int = 0
var _menu: Control


func _ready() -> void:
	print("=== GALACTIC FRONTIER — Main menu tests ===")
	call_deferred("_run_tests")


func _run_tests() -> void:
	SaveSlots.save_directory = "user://test_menu_saves"
	SaveSlots.delete_slot("quick")
	var packed := load("res://scenes/ui/main_menu.tscn") as PackedScene
	_assert_true(packed != null, "main menu scene loads")
	if packed == null:
		_finish()
		return
	_menu = packed.instantiate() as Control
	get_tree().root.add_child(_menu)
	await get_tree().process_frame

	var continue_button := _menu.get_node_or_null("SafeMargins/MenuLayout/MenuButtons/ContinueButton") as Button
	var controls_button := _menu.get_node_or_null("SafeMargins/MenuLayout/MenuButtons/ControlsButton") as Button
	var controls_panel := _menu.get_node_or_null("SafeMargins/MenuLayout/ControlsPanel") as PanelContainer
	_assert_true(continue_button != null, "Continue button is present")
	_assert_true(controls_button != null, "Controls button is present")
	_assert_true(controls_panel != null, "Controls panel is present")
	if continue_button == null or controls_button == null or controls_panel == null:
		_finish()
		return

	_assert_true(continue_button.disabled, "Continue is disabled without a valid quick save")
	var saved := SaveSlots.save_slot("quick", {"game_id": "menu_test", "credits": 100})
	_menu.call("_refresh_continue_state")
	_assert_true(saved.ok and not continue_button.disabled, "Continue enables when a valid quick save exists")

	controls_button.pressed.emit()
	_assert_true(controls_panel.visible, "Controls button opens the controls panel")
	controls_button.pressed.emit()
	_assert_true(not controls_panel.visible, "Controls button closes the controls panel")

	_finish()


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % message)
	else:
		_failed += 1
		print("  FAIL  %s" % message)


func _finish() -> void:
	SaveSlots.delete_slot("quick")
	if is_instance_valid(_menu):
		_menu.queue_free()
	print("")
	if _failed == 0:
		print("RESULT: PASS (%d assertions)" % _passed)
		get_tree().quit(0)
	else:
		print("RESULT: FAIL (%d passed, %d failed)" % [_passed, _failed])
		get_tree().quit(1)
