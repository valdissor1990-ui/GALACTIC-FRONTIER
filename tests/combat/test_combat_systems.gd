extends SceneTree
## Headless tests for the first combat systems.
## Run:
##   godot --headless --path . --script res://tests/combat/test_combat_systems.gd

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — Combat system tests ===")
	_test_shield_absorbs_damage_before_hull()
	_test_hull_takes_overflow_damage()
	_test_shields_regenerate_after_delay()
	_test_destroyed_combatant_stops_regenerating()
	_test_targeting_selects_forward_target()
	_test_targeting_ignores_out_of_cone_target()
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
	_assert_true(absf(actual - expected) <= 0.001, "%s (got %.3f, expected %.3f)" % [message, actual, expected])


func _make_damageable() -> Damageable:
	var component := Damageable.new()
	component.max_hull = 100.0
	component.max_shield = 50.0
	component.shield_regen_per_second = 10.0
	component.shield_regen_delay = 2.0
	root.add_child(component)
	return component


func _test_shield_absorbs_damage_before_hull() -> void:
	print("\n[shield absorbs damage before hull]")
	var component := _make_damageable()
	component.take_damage(20.0)
	_assert_approx(component.current_shield, 30.0, "shield reduced by incoming damage")
	_assert_approx(component.current_hull, 100.0, "hull remains untouched while shield holds")
	component.queue_free()


func _test_hull_takes_overflow_damage() -> void:
	print("\n[damage overflow reaches hull]")
	var component := _make_damageable()
	component.take_damage(65.0)
	_assert_approx(component.current_shield, 0.0, "shield depleted")
	_assert_approx(component.current_hull, 85.0, "overflow damage reduces hull")
	component.queue_free()


func _test_shields_regenerate_after_delay() -> void:
	print("\n[shield regeneration delay]")
	var component := _make_damageable()
	component.take_damage(30.0)
	component._process(1.0)
	_assert_approx(component.current_shield, 20.0, "shield does not regenerate before delay")
	component._process(2.0)
	_assert_approx(component.current_shield, 40.0, "shield regenerates after delay")
	component.queue_free()


func _test_destroyed_combatant_stops_regenerating() -> void:
	print("\n[destroyed combatant]")
	var component := _make_damageable()
	component.take_damage(200.0)
	_assert_true(component.is_destroyed(), "lethal damage marks component destroyed")
	_assert_approx(component.current_hull, 0.0, "hull cannot fall below zero")
	component._process(10.0)
	_assert_approx(component.current_shield, 0.0, "destroyed component does not regenerate")
	component.queue_free()


func _make_targeting_scene() -> Dictionary:
	var ship := Node3D.new()
	ship.name = "PlayerShip"
	var targeting := TargetingSystem.new()
	targeting.name = "TargetingSystem"
	ship.add_child(targeting)
	root.add_child(ship)

	var camera := Camera3D.new()
	camera.name = "TestCamera"
	root.add_child(camera)
	camera.current = true

	var target := Node3D.new()
	target.name = "ForwardTarget"
	target.position = Vector3(0.0, 0.0, -100.0)
	target.add_to_group("combat_targets")
	root.add_child(target)

	return {"ship": ship, "targeting": targeting, "camera": camera, "target": target}


func _test_targeting_selects_forward_target() -> void:
	print("\n[targeting selects forward target]")
	var scene := _make_targeting_scene()
	var targeting: TargetingSystem = scene["targeting"]
	var target: Node3D = scene["target"]
	var selected := targeting.acquire_target()
	_assert_true(selected == target, "target in camera forward cone is selected")
	scene["ship"].queue_free()
	scene["camera"].queue_free()
	target.queue_free()


func _test_targeting_ignores_out_of_cone_target() -> void:
	print("\n[targeting ignores target outside cone]")
	var scene := _make_targeting_scene()
	var targeting: TargetingSystem = scene["targeting"]
	var target: Node3D = scene["target"]
	target.position = Vector3(100.0, 0.0, -20.0)
	var selected := targeting.acquire_target()
	_assert_true(selected == null, "target outside acquisition cone is rejected")
	scene["ship"].queue_free()
	scene["camera"].queue_free()
	target.queue_free()
