extends SceneTree

const RULES: Script = preload("res://scripts/flight/docking_rules.gd")


func _initialize() -> void:
	_check(RULES.can_dock(10.0, 12.0, Vector3.BACK, Vector3.BACK), "aligned slow approach inside the port must dock")
	_check(not RULES.can_dock(19.0, 12.0, Vector3.BACK, Vector3.BACK), "distance outside the collar must be rejected")
	_check(not RULES.can_dock(10.0, 19.0, Vector3.BACK, Vector3.BACK), "speed above the docking limit must be rejected")
	_check(not RULES.can_dock(10.0, 12.0, Vector3.FORWARD, Vector3.BACK), "misaligned approach must be rejected")
	_check(not RULES.can_dock(10.0, 12.0, Vector3.ZERO, Vector3.BACK), "zero forward vector must be rejected")
	print("DOCKING_RULES_TEST_PASS")
	quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("DOCKING_RULES_TEST_FAIL: " + message)
	quit(1)
