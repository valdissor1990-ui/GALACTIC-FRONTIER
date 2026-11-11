extends SceneTree
## Headless deterministic tests for FlightModel.integrate_velocity().
## Run with:
##   godot --headless --path . --script res://tests/flight/test_flight_model.gd
## Exit code 0 = all tests passed. Non-zero = failure.

const EPSILON := 0.0001

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — FlightModel tests ===")
	var model := FlightModel.new()

	_test_acceleration_is_normalized(model)
	_test_max_speed_is_clamped(model)
	_test_exponential_drag_when_no_input(model)
	_test_no_drag_while_accelerating(model)
	_test_zero_delta_is_noop(model)
	_test_zero_direction_uses_drag(model)

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


func _assert_vec_approx(actual: Vector3, expected: Vector3, message: String) -> void:
	var ok: bool = actual.distance_to(expected) <= EPSILON
	_assert_true(ok, "%s (got %s, expected %s)" % [message, actual, expected])


func _test_acceleration_is_normalized(model: FlightModel) -> void:
	print("\n[acceleration direction is normalized]")
	# Non-unit direction must be normalized before applying acceleration.
	var direction := Vector3(3.0, 0.0, 0.0)  # length 3
	var result: Vector3 = model.integrate_velocity(
		Vector3.ZERO, direction, 10.0, 100.0, 0.0, 1.0
	)
	# Expected: normalized(3,0,0) * 10 * 1 = (1,0,0) * 10 = (10,0,0)
	_assert_vec_approx(result, Vector3(10.0, 0.0, 0.0), "non-unit direction produces unit-length acceleration")


func _test_max_speed_is_clamped(model: FlightModel) -> void:
	print("\n[max speed is clamped]")
	var fast := Vector3(0.0, 0.0, -200.0)
	var result: Vector3 = model.integrate_velocity(
		fast, Vector3.ZERO, 0.0, 95.0, 0.0, 0.016
	)
	_assert_approx(result.length(), 95.0, "velocity longer than max_speed is limited")

	# Also clamp after acceleration would exceed max_speed.
	var almost_max := Vector3(0.0, 0.0, -90.0)
	var accelerated: Vector3 = model.integrate_velocity(
		almost_max, Vector3(0.0, 0.0, -1.0), 50.0, 95.0, 0.0, 1.0
	)
	_assert_approx(accelerated.length(), 95.0, "acceleration that would exceed max_speed is clamped")


func _test_exponential_drag_when_no_input(model: FlightModel) -> void:
	print("\n[exponential drag when no acceleration input]")
	var start := Vector3(0.0, 0.0, -50.0)
	var drag := 0.85
	var delta := 1.0
	var result: Vector3 = model.integrate_velocity(
		start, Vector3.ZERO, 0.0, 200.0, drag, delta
	)
	var expected_length: float = 50.0 * exp(-drag * delta)
	_assert_approx(result.length(), expected_length, "drag multiplies velocity by exp(-drag * delta)")
	_assert_true(result.z < 0.0, "drag preserves direction")


func _test_no_drag_while_accelerating(model: FlightModel) -> void:
	print("\n[no drag applied while acceleration input is present]")
	# With a non-zero direction the else-branch (drag) must not run.
	var start := Vector3(0.0, 0.0, -40.0)
	var result: Vector3 = model.integrate_velocity(
		start, Vector3(0.0, 0.0, -1.0), 10.0, 200.0, 100.0, 1.0
	)
	# Expected: start + normalized(dir) * accel * delta = (0,0,-40) + (0,0,-1)*10*1 = (0,0,-50)
	# If drag had been applied it would be much smaller because drag=100.
	_assert_vec_approx(result, Vector3(0.0, 0.0, -50.0), "active acceleration ignores drag")


func _test_zero_delta_is_noop(model: FlightModel) -> void:
	print("\n[delta = 0 leaves velocity unchanged (except max_speed clamp)]")
	var start := Vector3(1.0, 2.0, 3.0)
	var result: Vector3 = model.integrate_velocity(
		start, Vector3(0.0, 0.0, -1.0), 50.0, 100.0, 5.0, 0.0
	)
	_assert_vec_approx(result, start, "zero delta with acceleration does not change velocity")

	var result_drag: Vector3 = model.integrate_velocity(
		start, Vector3.ZERO, 0.0, 100.0, 5.0, 0.0
	)
	_assert_vec_approx(result_drag, start, "zero delta with drag does not change velocity")


func _test_zero_direction_uses_drag(model: FlightModel) -> void:
	print("\n[near-zero direction is treated as no input and uses drag]")
	var start := Vector3(0.0, 0.0, -30.0)
	var tiny := Vector3(0.00001, 0.0, 0.0)  # length_squared << 0.0001 threshold
	var result: Vector3 = model.integrate_velocity(
		start, tiny, 10.0, 200.0, 0.5, 1.0
	)
	var expected_length: float = 30.0 * exp(-0.5 * 1.0)
	_assert_approx(result.length(), expected_length, "direction below threshold triggers drag path")
