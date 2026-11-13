extends SceneTree
## Headless tests for CameraRig camera switching behaviour.
## Run:
##   godot --headless --path . --script res://tests/flight/test_camera_rig.gd
## Exit code 0 = all assertions passed.

const EPSILON := 0.0001

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== GALACTIC FRONTIER — CameraRig tests ===")

	_test_initial_mode_is_chase()
	await process_frame
	_test_toggle_chase_to_cockpit()
	await process_frame
	_test_toggle_cockpit_to_chase()
	await process_frame
	_test_toggle_does_not_change_ship_transform()
	await process_frame
	_test_toggle_does_not_change_ship_velocity()
	await process_frame
	_test_missing_visual_does_not_crash()
	await process_frame
	_test_cameras_still_switch_without_visual()
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


func _make_ship_with_cameras(include_visual: bool = true) -> CharacterBody3D:
	var ship := CharacterBody3D.new()
	ship.name = "PlayerShip"
	ship.velocity = Vector3(1.5, -0.25, 3.0)
	ship.position = Vector3(10.0, 4.0, -7.0)
	ship.rotation = Vector3(0.1, 0.2, 0.3)

	if include_visual:
		var visual := Node3D.new()
		visual.name = "Visual"
		ship.add_child(visual)

	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(load("res://scripts/flight/camera_rig.gd"))

	var chase := Camera3D.new()
	chase.name = "ChaseCamera"
	chase.current = true
	rig.add_child(chase)

	var cockpit := Camera3D.new()
	cockpit.name = "CockpitCamera"
	rig.add_child(cockpit)

	ship.add_child(rig)
	# Adding to the tree triggers @onready assignment and _ready() once.
	root.add_child(ship)
	return ship


func _get_rig(ship: Node) -> CameraRig:
	return ship.get_node("CameraRig") as CameraRig


func _test_initial_mode_is_chase() -> void:
	print("\n[initial mode is chase]")
	var ship := _make_ship_with_cameras(true)
	var rig := _get_rig(ship)
	_assert_true(not rig.is_cockpit_active(), "starts in chase mode")
	_assert_true(rig.get_node("ChaseCamera").current, "chase camera is current")
	_assert_true(not rig.get_node("CockpitCamera").current, "cockpit camera is not current")
	ship.queue_free()


func _test_toggle_chase_to_cockpit() -> void:
	print("\n[toggle chase -> cockpit]")
	var ship := _make_ship_with_cameras(true)
	var rig := _get_rig(ship)
	rig.toggle_camera()
	_assert_true(rig.is_cockpit_active(), "cockpit becomes active")
	_assert_true(rig.get_node("CockpitCamera").current, "cockpit camera is current")
	_assert_true(not rig.get_node("ChaseCamera").current, "chase camera is not current")
	var visual: Node3D = ship.get_node_or_null("Visual") as Node3D
	if visual:
		_assert_true(not visual.visible, "visual hidden in cockpit")
	ship.queue_free()


func _test_toggle_cockpit_to_chase() -> void:
	print("\n[toggle cockpit -> chase]")
	var ship := _make_ship_with_cameras(true)
	var rig := _get_rig(ship)
	rig.toggle_camera()  # to cockpit
	rig.toggle_camera()  # back to chase
	_assert_true(not rig.is_cockpit_active(), "chase becomes active again")
	_assert_true(rig.get_node("ChaseCamera").current, "chase camera is current again")
	var visual: Node3D = ship.get_node_or_null("Visual") as Node3D
	if visual:
		_assert_true(visual.visible, "visual visible again in chase")
	ship.queue_free()


func _test_toggle_does_not_change_ship_transform() -> void:
	print("\n[toggle does not change ship transform]")
	var ship := _make_ship_with_cameras(true)
	var before_pos := ship.global_position
	var before_rot := ship.global_rotation
	var rig := _get_rig(ship)
	rig.toggle_camera()
	rig.toggle_camera()
	_assert_true(before_pos.distance_to(ship.global_position) <= EPSILON, "position unchanged")
	_assert_true(before_rot.distance_to(ship.global_rotation) <= EPSILON, "rotation unchanged")
	ship.queue_free()


func _test_toggle_does_not_change_ship_velocity() -> void:
	print("\n[toggle does not change ship velocity]")
	var ship := _make_ship_with_cameras(true)
	var before_vel := ship.velocity
	var rig := _get_rig(ship)
	rig.toggle_camera()
	_assert_true(before_vel.distance_to(ship.velocity) <= EPSILON, "velocity unchanged after toggle")
	ship.queue_free()


func _test_missing_visual_does_not_crash() -> void:
	print("\n[missing Visual does not crash]")
	# CameraRig.push_error is expected; we only require that execution continues.
	var ship := _make_ship_with_cameras(false)
	var rig := _get_rig(ship)
	_assert_true(rig != null, "rig created without Visual")
	_assert_true(not rig.is_cockpit_active(), "starts in chase without Visual")
	ship.queue_free()


func _test_cameras_still_switch_without_visual() -> void:
	print("\n[cameras still switch without Visual]")
	var ship := _make_ship_with_cameras(false)
	var rig := _get_rig(ship)
	rig.toggle_camera()
	_assert_true(rig.is_cockpit_active(), "cockpit active without Visual")
	_assert_true(rig.get_node("CockpitCamera").current, "cockpit camera current without Visual")
	rig.toggle_camera()
	_assert_true(not rig.is_cockpit_active(), "chase active again without Visual")
	ship.queue_free()
