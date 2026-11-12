extends SceneTree
## Deterministic tests for the core flight velocity integrator.

var _passed := 0
var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model := FlightModel.new()
	var accelerated := model.integrate_velocity(Vector3.ZERO, Vector3(0.0, 0.0, -4.0), 20.0, 200.0, 0.85, 0.5)
	_check(absf(accelerated.length() - 10.0) < 0.001, "acceleration uses normalized input direction and delta time")
	_check(accelerated.z < 0.0, "forward input accelerates along the requested direction")

	var dragged := model.integrate_velocity(Vector3(100.0, 0.0, 0.0), Vector3.ZERO, 20.0, 200.0, 0.85, 1.0)
	_check(absf(dragged.x - 100.0 * exp(-0.85)) < 0.001, "drag decays velocity exponentially when there is no input")

	var capped := model.integrate_velocity(Vector3(90.0, 0.0, 0.0), Vector3.RIGHT, 100.0, 95.0, 0.85, 1.0)
	_check(absf(capped.length() - 95.0) < 0.001, "velocity never exceeds configured maximum speed")

	var unchanged := model.integrate_velocity(Vector3(12.0, 3.0, -4.0), Vector3.RIGHT, 50.0, 200.0, 0.85, 0.0)
	_check(unchanged.distance_to(Vector3(12.0, 3.0, -4.0)) < 0.001, "zero delta does not change velocity")

	if _failed == 0:
		print("FLIGHT_MODEL_TEST_PASS: %d assertions" % _passed)
		quit(0)
	else:
		push_error("FLIGHT_MODEL_TEST_FAIL: %d passed, %d failed" % [_passed, _failed])
		quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + message)
	else:
		_failed += 1
		push_error("  FAIL  " + message)
