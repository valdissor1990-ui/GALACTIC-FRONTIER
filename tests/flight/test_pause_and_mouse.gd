extends SceneTree
## Headless tests for pause handling and mouse-delta behaviour.
## Run:
##   godot --headless --path . --script res://tests/flight/test_pause_and_mouse.gd
## Exit code 0 = all assertions passed.

const EPSILON := 0.0001

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== GALACTIC FRONTIER — Pause & mouse tests ===")

	_test_mouse_not_accumulated_while_paused()
	await process_frame
	_test_mouse_delta_is_capped_single_event()
	await process_frame
	_test_mouse_delta_capped_across_multiple_events()
	await process_frame
	_test_focus_out_clears_mouse_delta()
	await process_frame
	_test_focus_in_clears_mouse_delta()
	await process_frame
	_test_focus_in_captures_mouse_when_not_paused()
	await process_frame
	_test_focus_in_does_not_capture_mouse_when_paused()
	await process_frame
	_test_hud_toggle_pause_cycle()
	await process_frame
	_test_sensitivity_clamped()
	await process_frame

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


func _assert_approx(actual: float, expected: float, message: String) -> void:
	_assert_true(absf(actual - expected) <= EPSILON, "%s (got %s, expected %s)" % [message, actual, expected])


func _make_ship() -> ShipController:
	var ship := CharacterBody3D.new()
	ship.set_script(load("res://scripts/flight/ship_controller.gd"))
	var config := ShipFlightConfig.new()
	ship.flight_config = config

	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(load("res://scripts/flight/camera_rig.gd"))
	var chase := Camera3D.new()
	chase.name = "ChaseCamera"
	rig.add_child(chase)
	var cockpit := Camera3D.new()
	cockpit.name = "CockpitCamera"
	rig.add_child(cockpit)
	ship.add_child(rig)

	root.add_child(ship)
	ship.boost_amount = config.boost_capacity
	return ship as ShipController


func _make_hud(ship: ShipController) -> CanvasLayer:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scripts/ui/hud.gd"))
	hud.ship_path = ship.get_path()

	# Minimal node tree required by hud.gd @onready paths.
	var telemetry := Control.new()
	telemetry.name = "Telemetry"
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var margin := MarginContainer.new()
	margin.name = "Margin"
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	for label_name in ["SpeedLabel", "ModeLabel", "BoostLabel", "SensitivityLabel"]:
		var lbl := Label.new()
		lbl.name = label_name
		vbox.add_child(lbl)
	margin.add_child(vbox)
	panel.add_child(margin)
	telemetry.add_child(panel)
	hud.add_child(telemetry)

	var pause_panel := PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.visible = false
	hud.add_child(pause_panel)

	root.add_child(hud)
	return hud


func _make_mouse_motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	return event


func _test_mouse_not_accumulated_while_paused() -> void:
	print("\n[mouse not accumulated while paused]")
	var ship := _make_ship()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ship._unhandled_input(_make_mouse_motion(Vector2(100.0, 50.0)))
	_assert_true(ship._mouse_delta.length_squared() <= EPSILON, "paused: mouse delta stays zero")
	get_tree().paused = false
	ship.queue_free()


func _test_mouse_delta_is_capped_single_event() -> void:
	print("\n[mouse delta capped on single large event]")
	var ship := _make_ship()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ship._unhandled_input(_make_mouse_motion(Vector2(1000.0, 1000.0)))
	var max_len: float = ShipController.MAX_MOUSE_DELTA_PER_PHYSICS_TICK
	_assert_true(ship._mouse_delta.length() <= max_len + EPSILON, "single event delta length capped")
	ship.queue_free()


func _test_mouse_delta_capped_across_multiple_events() -> void:
	print("\n[mouse delta capped across multiple sequential events]")
	var ship := _make_ship()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var max_len: float = ShipController.MAX_MOUSE_DELTA_PER_PHYSICS_TICK
	# Several medium moves that would exceed the cap if unbounded.
	for i in range(5):
		ship._unhandled_input(_make_mouse_motion(Vector2(100.0, 80.0)))
	_assert_true(ship._mouse_delta.length() <= max_len + EPSILON, "accumulated sequential delta stays within cap")
	ship.queue_free()


func _test_focus_out_clears_mouse_delta() -> void:
	print("\n[focus out clears mouse delta]")
	var ship := _make_ship()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ship._mouse_delta = Vector2(40.0, -20.0)
	ship._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_assert_true(ship._mouse_delta.length_squared() <= EPSILON, "focus out zeroes delta")
	_assert_true(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "focus out releases mouse")
	ship.queue_free()


func _test_focus_in_clears_mouse_delta() -> void:
	print("\n[focus in clears mouse delta]")
	var ship := _make_ship()
	get_tree().paused = false
	ship._mouse_delta = Vector2(15.0, 15.0)
	ship._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_assert_true(ship._mouse_delta.length_squared() <= EPSILON, "focus in zeroes old delta")
	ship.queue_free()


func _test_focus_in_captures_mouse_when_not_paused() -> void:
	print("\n[focus in captures mouse when not paused]")
	var ship := _make_ship()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ship._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_assert_true(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "focus in captures mouse when not paused")
	ship.queue_free()


func _test_focus_in_does_not_capture_mouse_when_paused() -> void:
	print("\n[focus in does not capture mouse when paused]")
	var ship := _make_ship()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ship._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_assert_true(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "focus in while paused leaves mouse visible")
	get_tree().paused = false
	ship.queue_free()


func _test_hud_toggle_pause_cycle() -> void:
	print("\n[HUD _toggle_pause full cycle]")
	var ship := _make_ship()
	var hud := _make_hud(ship)
	var pause_panel: Control = hud.get_node("PausePanel") as Control

	# Start unpaused.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_panel.visible = false

	# Pause via real production method.
	hud._toggle_pause()
	_assert_true(get_tree().paused, "pause enabled")
	_assert_true(pause_panel.visible, "PausePanel visible while paused")
	_assert_true(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "mouse released while paused")

	# Resume via real production method.
	hud._toggle_pause()
	_assert_true(not get_tree().paused, "pause disabled")
	_assert_true(not pause_panel.visible, "PausePanel hidden after resume")
	_assert_true(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse captured after resume")

	hud.queue_free()
	ship.queue_free()


func _test_sensitivity_clamped() -> void:
	print("\n[sensitivity stays within allowed range]")
	var ship := _make_ship()
	ship.set_mouse_sensitivity(0.001)
	_assert_true(ship.mouse_sensitivity >= 0.02 - EPSILON, "sensitivity lower bound")
	ship.set_mouse_sensitivity(5.0)
	_assert_true(ship.mouse_sensitivity <= 0.5 + EPSILON, "sensitivity upper bound")
	ship.set_mouse_sensitivity(0.25)
	_assert_approx(ship.mouse_sensitivity, 0.25, "sensitivity accepts valid mid value")
	ship.queue_free()
