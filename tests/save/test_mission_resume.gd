extends SceneTree
## Integration test for mission checkpoint persistence and resume.

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")
var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GameSave.save_directory = "user://test_mission_resume"
	var error := change_scene_to_packed(DEMO_SCENE)
	_check(error == OK, "demo scene must load")
	await process_frame
	await process_frame
	var demo := current_scene
	var director := demo.get_node("DemoMissionDirector")
	var player := demo.get_node("PlayerShip") as ShipController
	var damageable := player.get_node("Damageable") as Damageable
	director.stage = 6
	director.wave_index = 3
	director.mission_seconds = 123.5
	director.enemies_destroyed = 8
	player.global_position = Vector3(20.0, 40.0, 60.0)
	player.global_rotation = Vector3(0.1, 0.2, 0.3)
	player.velocity = Vector3(4.0, 5.0, 6.0)
	damageable.current_hull = 72.0
	damageable.current_shield = 28.0
	_check(director._save_checkpoint("integration test"), "checkpoint must be written")
	var loaded := GameSave.load_slot("silent_relay")
	_check(loaded.ok, "checkpoint must load from disk")
	player.global_position = Vector3.ZERO
	player.global_rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	damageable.current_hull = 10.0
	damageable.current_shield = 0.0
	director.stage = 0
	director.wave_index = 0
	director.mission_seconds = 0.0
	director.enemies_destroyed = 0
	_check(director.restore_from_save(loaded.payload), "mission director must accept the saved checkpoint")
	_check(director.stage == 6, "mission stage must be restored")
	_check(director.wave_index == 3, "wave progress must be restored")
	_check(is_equal_approx(director.mission_seconds, 123.5), "mission timer must be restored")
	_check(director.enemies_destroyed == 8, "kill count must be restored")
	_check(player.global_position.is_equal_approx(Vector3(20.0, 40.0, 60.0)), "player position must be restored")
	_check(player.global_rotation.is_equal_approx(Vector3(0.1, 0.2, 0.3)), "player rotation must be restored")
	_check(player.velocity.is_equal_approx(Vector3(4.0, 5.0, 6.0)), "player velocity must be restored")
	_check(is_equal_approx(damageable.current_hull, 72.0), "hull must be restored")
	_check(is_equal_approx(damageable.current_shield, 28.0), "shield must be restored")
	GameSave.delete_slot("silent_relay")
	if _failed == 0:
		print("MISSION_RESUME_TEST_PASS")
		quit(0)
	else:
		print("MISSION_RESUME_TEST_FAIL: ", _failed, " assertions")
		quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("MISSION_RESUME_TEST_FAIL: " + message)
