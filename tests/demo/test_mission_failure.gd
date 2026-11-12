extends Node

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var demo := DEMO_SCENE.instantiate()
	get_tree().root.add_child(demo)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := demo.get_node("PlayerShip") as ShipController
	var damageable := player.get_node("Damageable") as Damageable
	var director := demo.get_node("DemoMissionDirector")
	damageable.take_damage(100000.0)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(player.is_destroyed(), "player controller must enter destroyed state")
	_check(player.velocity == Vector3.ZERO, "destroyed player velocity must be zero")
	_check(not player.is_physics_processing(), "destroyed player physics must be disabled")
	_check(not player.get_node("WeaponSystem").is_processing(), "destroyed player weapons must be disabled")
	_check(director.stage == 8, "player destruction must fail the mission")
	_check(demo.get_node_or_null("MissionResult") != null, "failure result screen must be shown")
	print("DEMO_MISSION_FAILURE_TEST_PASS")
	get_tree().quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("DEMO_MISSION_FAILURE_TEST_FAIL: " + message)
	get_tree().quit(1)
