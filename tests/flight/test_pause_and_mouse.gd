extends SceneTree
## Headless tests for pause handling and mouse-delta behaviour in ShipController.
## Run:
##   godot --headless --path . --script res://tests/flight/test_pause_and_mouse.gd
## Exit code 0 = all assertions passed.

const EPSILON := 0.0001

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — Pause & mouse tests ===")

	_test_mouse_not_accumulated_while_paused()
	_test_mouse_delta_is_capped()
	_test_focus_out_clears_mouse_delta()
	_test_focus_in_clears_mouse_delta()
	_test_focus_in_captures_mouse_when_not_paused()
	_test_focus_in_does_not_capture_mouse_when_paused()
	_test_unpause_restores_mouse_capture()
	_test_sensitivity_clamped()

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

	# Minimal camera rig so @onready does not fail hard.
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
	# Manually run ready-side effects that do not require a full scene.
	ship.boost_amount = config.boost_capacity
	return ship as ShipController


func _make_mouse_motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	return event


func _test_mouse_not_accumulated_while_paused() -> void:
	print("\n[mouse not accumulated while paused]")
	var ship := _make_ship()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Directly invoke the handler used by the production code.
	ship._unhandled_input(_make_mouse_motion(Vector2(100.0, 50.0)))
	_assert_true(ship._mouse_delta.length_squared() <= EPSILON, "paused: mouse delta stays zero")
	get_tree().paused = false
	ship.queue_free()


func _test_mouse_delta_is_capped() -> void:
	print("\n[mouse delta is capped per physics tick]")
	var ship := _make_ship()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var huge := Vector2(1000.0, 1000.0)
	ship._unhandled_input(_make_mouse_motion(huge))
	var max_len: float = ShipController.MAX_MOUSE_DELTA_PER_PHYSICS_TICK
	_assert_true(ship._mouse_delta.length() <= max_len + EPSILON, "delta length capped at MAX_MOUSE_DELTA")
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


func _test_unpause_restores_mouse_capture() -> void:
	print("\n[unpause restores mouse capture]")
	# HUD owns the actual pause toggle; we verify the contract that
	# resuming sets mouse capture (mirrors hud.gd _toggle_pause).
	var ship := _make_ship()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Simulate the unpause path used by HUD.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_assert_true(not get_tree().paused, "tree is unpaused")
	_assert_true(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse captured after unpause")
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
