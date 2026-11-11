extends SceneTree
## Headless tests for the enemy fighter and the complete repeatable encounter loop.
## Run:
##   godot --headless --path . --script res://tests/combat/test_enemy_combat_ai.gd

const STATE_APPROACH := 0
const STATE_STRAFE := 1
const STATE_RETREAT := 2
const STATE_DISABLED := 3

var _failed := 0
var _passed := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== GALACTIC FRONTIER — Enemy combat and encounter tests ===")
	_test_state_by_distance()
	_test_retreat_on_low_hull()
	_test_disabled_after_destruction()
	_test_no_fire_when_disabled()
	await _test_real_encounter_spawn_fire_and_respawn()
	print("")
	if _failed == 0:
		print("RESULT: PASS (%d assertions)" % _passed)
		quit(0)
	else:
		print("RESULT: FAIL (%d passed, %d failed)" % [_passed, _failed])
		quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % message)
	else:
		_failed += 1
		push_error("  FAIL  %s" % message)


func _make_enemy() -> CharacterBody3D:
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
	return enemy


func _make_player_at(position: Vector3) -> Node3D:
	var player := Node3D.new()
	player.name = "TestPlayer"
	root.add_child(player)
	player.global_position = position
	return player


func _test_state_by_distance() -> void:
	print("\n[state selection by distance]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -120))
	enemy.call("set_player", player)
	enemy.global_position = Vector3.ZERO
	enemy.call("_update_state")
	_assert_true(int(enemy.get("state")) == STATE_APPROACH, "far target selects APPROACH")
	player.global_position = Vector3(0, 0, -30)
	enemy.call("_update_state")
	_assert_true(int(enemy.get("state")) == STATE_STRAFE, "mid-range target selects STRAFE")
	player.global_position = Vector3(0, 0, -5)
	enemy.call("_update_state")
	_assert_true(int(enemy.get("state")) == STATE_RETREAT, "very close target selects RETREAT")
	enemy.queue_free()
	player.queue_free()


func _test_retreat_on_low_hull() -> void:
	print("\n[retreat when hull is critical]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -40))
	enemy.call("set_player", player)
	var damageable: Node = enemy.get_node("Damageable")
	damageable.set("current_hull", float(damageable.get("max_hull")) * 0.1)
	enemy.call("_update_state")
	_assert_true(int(enemy.get("state")) == STATE_RETREAT, "low hull selects RETREAT")
	enemy.queue_free()
	player.queue_free()


func _test_disabled_after_destruction() -> void:
	print("\n[disabled after destruction]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -40))
	enemy.call("set_player", player)
	var damageable: Node = enemy.get_node("Damageable")
	damageable.call("take_damage", float(damageable.get("max_shield")) + float(damageable.get("max_hull")) + 10.0)
	enemy.call("_update_state")
	_assert_true(int(enemy.get("state")) == STATE_DISABLED, "destroyed enemy selects DISABLED")
	_assert_true(bool(damageable.call("is_destroyed")), "Damageable reports destroyed")
	_assert_true(not enemy.is_physics_processing(), "destroyed enemy stops physics processing")
	enemy.queue_free()
	player.queue_free()


func _test_no_fire_when_disabled() -> void:
	print("\n[disabled enemy cannot fire]")
	var enemy := _make_enemy()
	var player := _make_player_at(Vector3(0, 0, -20))
	enemy.call("set_player", player)
	enemy.set("state", STATE_DISABLED)
	enemy.set("_cooldown", 0.0)
	var before := root.get_child_count()
	enemy.call("_try_fire")
	_assert_true(root.get_child_count() == before, "DISABLED state does not create a projectile")
	enemy.queue_free()
	player.queue_free()


func _test_real_encounter_spawn_fire_and_respawn() -> void:
	print("\n[real encounter spawn, fire and respawn]")
	var player := _make_player_at(Vector3(0, 0, -100))
	var controller := Node.new()
	controller.set_script(load("res://scripts/combat/combat_encounter_controller.gd"))
	controller.set("enemy_scene", load("res://scenes/combat/enemy_fighter.tscn"))
	controller.set("player_path", NodePath("../TestPlayer"))
	controller.set("spawn_position", Vector3(0, 0, -80))
	controller.set("respawn_delay", 0.2)
	root.add_child(controller)

	# _ready() schedules the first encounter spawn for the next idle cycle.
	await process_frame
	await process_frame
	var active_enemy: bool = bool(controller.call("has_active_enemy"))
	_assert_true(active_enemy, "controller creates the first enemy")
	if not active_enemy:
		controller.queue_free()
		player.queue_free()
		return

	var enemy := controller.get("_current_enemy") as Node3D
	_assert_true(enemy != null and enemy.has_method("set_player"), "spawned enemy exposes set_player")
	if enemy == null:
		controller.queue_free()
		player.queue_free()
		return

	# The enemy's -Z nose faces the player at z=-100, so this also exercises
	# the shared projectile scene and muzzle path without waiting for AI steering.
	enemy.set("_cooldown", 0.0)
	enemy.set("state", STATE_APPROACH)
	enemy.call("_try_fire")
	var projectile_found := false
	var projectile_script: Script = load("res://scripts/combat/projectile.gd")
	for child in root.find_children("*", "Area3D", true, false):
		if child.get_script() == projectile_script:
			projectile_found = true
			child.queue_free()
	if not projectile_found:
		print("DEBUG enemy position=%s player=%s ai_player=%s muzzle=%s projectile_scene=%s cooldown=%s current_scene=%s parent=%s" % [
			enemy.global_position, player.global_position, enemy.get("player"), enemy.get("_muzzle"),
			enemy.get("projectile_scene"), enemy.get("_cooldown"), current_scene, enemy.get_parent()
		])
	_assert_true(projectile_found, "enemy fires a shared CombatProjectile from its muzzle")

	var damageable: Node = enemy.get_node("Damageable")
	damageable.call("take_damage", float(damageable.get("max_shield")) + float(damageable.get("max_hull")) + 1.0)
	_assert_true(not bool(controller.call("has_active_enemy")), "destroyed enemy is removed from active encounter")
	_assert_true(float(controller.call("get_respawn_timer")) > 0.0, "destruction starts respawn countdown")

	controller.set_process(true)
	await create_timer(0.8).timeout
	await process_frame
	if not bool(controller.call("has_active_enemy")):
		print("DEBUG respawn timer=%s current_enemy=%s processing=%s player=%s enemy_scene=%s active=%s" % [
			controller.call("get_respawn_timer"),
			controller.get("_current_enemy"),
			controller.is_processing(),
			controller.get("_player"),
			controller.get("enemy_scene"),
			controller.get("_encounter_active")
		])
	_assert_true(bool(controller.call("has_active_enemy")), "controller respawns an enemy after the delay")

	controller.queue_free()
	player.queue_free()
