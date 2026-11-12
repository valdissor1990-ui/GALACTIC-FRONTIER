extends Node

func _ready() -> void:
	var route_start := Vector3.ZERO
	var route_end := Vector3(0.0, 18.0, -720.0)
	var planet_center := Vector3(-160.0, 26.0, -285.0)
	var planet_radius := 42.0
	var route := route_end - route_start
	var t := clampf((planet_center - route_start).dot(route) / route.length_squared(), 0.0, 1.0)
	var closest := route_start + route * t
	var clearance := closest.distance_to(planet_center) - planet_radius
	if clearance <= 25.0:
		push_error("ROUTE_SAFETY_TEST_FAIL: planet clearance is only %.2f m" % clearance)
		get_tree().quit(1)
		return
	if not InputMap.has_action("scan"):
		push_error("ROUTE_SAFETY_TEST_FAIL: scan input action is missing")
		get_tree().quit(1)
		return
	var has_physical_f := false
	for event in InputMap.action_get_events("scan"):
		if event is InputEventKey and event.physical_keycode == KEY_F:
			has_physical_f = true
	if not has_physical_f:
		push_error("ROUTE_SAFETY_TEST_FAIL: scan action is not bound to physical F")
		get_tree().quit(1)
		return
	print("ROUTE_SAFETY_TEST_PASS planet_clearance_m=", clearance, " physical_scan_key=F")
	get_tree().quit(0)
