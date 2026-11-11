extends SceneTree
## Headless tests for EnemyCombatAI state selection and encounter respawn gating.
## Run:
##   godot --headless --path . --script res://tests/combat/test_enemy_combat_ai.gd
## Exit code 0 = all assertions passed.

const EPSILON := 0.0001

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — Enemy combat AI tests ===")

	_test_state_by_distance()
	_test_retreat_on_low_hull()
	_test_disabled_on_destroyed()
	_test_no_fire_when_disabled()
	_test_encounter_does_not_double_spawn()

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


func _make_enemy() -> EnemyCombatAI:
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/combat/enemy_combat_ai.gd"))
	var damageable := Node.new()
	damageable.name = "Damageable"
	damageable.set_script(load("res://scripts/combat/damageable.gd"))
	enemy.add_child(damageable)
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	enemy.add_child(muzzle)
	root.add_child(enemy)
	return enemy as EnemyCombatAI


func _make_player_at(pos: Vector3) -> Node3D:
	var player := Node3D.new()
	player.name = "Player"
	root.add_child(player)
	player.global_position = pos
	return player


func _test_state_by_distance() -> void:
	print("\n[state selection by distance]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -120))
	enemy.set_player(player)
	enemy.global_position = Vector3.ZERO
	enemy._update_state()
	_assert_true(enemy.state == EnemyCombatAI.State.APPROACH, "far target -> APPROACH")

	player.global_position = Vector3(0, 0, -30)
	enemy._update_state()
	_assert_true(enemy.state == EnemyCombatAI.State.STRAFE, "mid range -> STRAFE")

	player.global_position = Vector3(0, 0, -5)
	enemy._update_state()
	_assert_true(enemy.state == EnemyCombatAI.State.RETREAT, "very close -> RETREAT")

	enemy.queue_free()
	player.queue_free()


func _test_retreat_on_low_hull() -> void:
	print("\n[retreat when hull is critical]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -40))
	enemy.set_player(player)
	var dmg := enemy.get_node("Damageable") as Damageable
	dmg.current_hull = dmg.max_hull * 0.1
	enemy._update_state()
	_assert_true(enemy.state == EnemyCombatAI.State.RETREAT, "low hull -> RETREAT")
	enemy.queue_free()
	player.queue_free()


func _test_disabled_on_destroyed() -> void:
	print("\n[disabled after destruction]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -40))
	enemy.set_player(player)
	var dmg := enemy.get_node("Damageable") as Damageable
	dmg.take_damage(dmg.max_shield + dmg.max_hull + 10.0)
	enemy._update_state()
	_assert_true(enemy.state == EnemyCombatAI.State.DISABLED, "destroyed -> DISABLED")
	_assert_true(dmg.is_destroyed(), "damageable reports destroyed")
	enemy.queue_free()
	player.queue_free()


func _test_no_fire_when_disabled() -> void:
	print("\n[no fire when disabled]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -20))
	enemy.set_player(player)
	enemy.state = EnemyCombatAI.State.DISABLED
	enemy._cooldown = 0.0
	var before_children := root.get_child_count()
	enemy._try_fire()
	_assert_true(root.get_child_count() == before_children, "disabled enemy does not spawn projectiles")
	enemy.queue_free()
	player.queue_free()


func _test_encounter_does_not_double_spawn() -> void:
	print("\n[encounter controller does not double-spawn]")
	var player := _make_player_at(Vector3.ZERO)
	var controller := Node.new()
	controller.set_script(load("res://scripts/combat/combat_encounter_controller.gd"))
	# Use a minimal PackedScene substitute: spawn logic checks is_instance_valid.
	# We verify the guard when _current_enemy is already set.
	root.add_child(controller)
	var ctrl := controller as CombatEncounterController
	ctrl._player = player
	var dummy := Node3D.new()
	root.add_child(dummy)
	ctrl._current_enemy = dummy
	ctrl._spawn_enemy()  # should early-return because current enemy is valid
	_assert_true(ctrl._current_enemy == dummy, "active enemy blocks second spawn")
	controller.queue_free()
	player.queue_free()
	dummy.queue_free()
