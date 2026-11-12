extends Node
## Verifies the real planet mesh clears the relay route and F is bound to scan.

const ENVIRONMENT_SCENE: PackedScene = preload("res://scenes/environment/space_environment.tscn")
const ROUTE_START := Vector3.ZERO
const ROUTE_END := Vector3(0.0, 18.0, -720.0)
const REQUIRED_CLEARANCE := 25.0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var environment := ENVIRONMENT_SCENE.instantiate()
	add_child(environment)
	await get_tree().process_frame
	var planet := environment.get_node_or_null("Aurelia") as MeshInstance3D
	if planet == null or not (planet.mesh is SphereMesh):
		_fail("real Aurelia planet mesh was not found in the environment scene")
		return
	var sphere := planet.mesh as SphereMesh
	var planet_center := planet.global_position
	var planet_radius := sphere.radius * maxf(maxf(planet.global_basis.get_scale().x, planet.global_basis.get_scale().y), planet.global_basis.get_scale().z)
	var clearance := _route_clearance(planet_center, planet_radius)
	if clearance <= REQUIRED_CLEARANCE:
		_fail("actual planet clearance is only %.2f m" % clearance)
		return
	planet.global_position = ROUTE_START.lerp(ROUTE_END, 0.5)
	var blocked_clearance := _route_clearance(planet.global_position, planet_radius)
	if blocked_clearance > REQUIRED_CLEARANCE:
		_fail("negative control failed: moving Aurelia onto route still passed")
		return
	if not InputMap.has_action("scan"):
		_fail("scan input action is missing")
		return
	var has_physical_f := false
	for event in InputMap.action_get_events("scan"):
		if event is InputEventKey and event.physical_keycode == KEY_F:
			has_physical_f = true
	if not has_physical_f:
		_fail("scan action is not bound to physical F")
		return
	print("ROUTE_SAFETY_TEST_PASS actual_clearance_m=", clearance, " blocked_control_m=", blocked_clearance, " physical_scan_key=F")
	get_tree().quit(0)

func _route_clearance(center: Vector3, radius: float) -> float:
	var route := ROUTE_END - ROUTE_START
	var t := clampf((center - ROUTE_START).dot(route) / route.length_squared(), 0.0, 1.0)
	var closest := ROUTE_START + route * t
	return closest.distance_to(center) - radius

func _fail(message: String) -> void:
	push_error("ROUTE_SAFETY_TEST_FAIL: " + message)
	get_tree().quit(1)
