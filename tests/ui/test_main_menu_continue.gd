extends SceneTree
## End-to-end test: main menu Continue -> scene change -> checkpoint restoration.
## Run: godot --headless --path . --script res://tests/ui/test_main_menu_continue.gd -- --test-mode

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MISSION_SCENE := "res://scenes/demo/ten_minute_demo.tscn"
const TEST_SAVE_DIRECTORY := "user://test_main_menu_continue"

var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager := root.get_node_or_null("GameSave")
	_check(save_manager != null, "persistent GameSave autoload is available")
	if save_manager == null:
		quit(1)
		return

	save_manager.set("save_directory", TEST_SAVE_DIRECTORY)
	save_manager.call("delete_slot", "silent_relay")
	var payload := {
		"mission_id": "silent_relay",
		"stage": 4,
		"wave_index": 0,
		"mission_seconds": 123.5,
		"enemies_destroyed": 5,
		"player_position": [20.0, 40.0, -500.0],
		"player_rotation": [0.1, 0.2, 0.3],
		"player_velocity": [4.0, 5.0, 6.0],
		"player_hull": 72.0,
		"player_shield": 28.0
	}
	var save_result: Dictionary = save_manager.call("save_slot", "silent_relay", payload)
	_check(save_result.ok, "valid Silent Relay checkpoint is written")

	var scene_error := change_scene_to_file(MENU_SCENE)
	_check(scene_error == OK, "main menu scene can be opened")
	await process_frame
	await process_frame
	var menu := current_scene
	_check(menu != null and menu.scene_file_path == MENU_SCENE, "main menu becomes active")
	if menu == null:
		_finish(save_manager)
		return

	var continue_button := menu.get_node_or_null("MainMenuLayout/ContinueButton") as Button
	_check(continue_button != null, "Continue button is shown for a valid checkpoint")
	if continue_button == null:
		_finish(save_manager)
		return

	menu.call("_continue_game")
	for _frame in range(8):
		await process_frame

	var mission := current_scene
	_check(mission != null and mission.scene_file_path == MISSION_SCENE, "Continue opens the Silent Relay mission")
	if mission == null:
		_finish(save_manager)
		return
	var director := mission.get_node_or_null("DemoMissionDirector")
	var player := mission.get_node_or_null("PlayerShip") as ShipController
	_check(director != null, "mission director is initialized")
	_check(player != null, "player ship is initialized")
	if director != null and player != null:
		print("DEBUG_RESTORED timer=", director.get("mission_seconds"), " position=", player.global_position, " velocity=", player.velocity, " hull=", player.get_node("Damageable").current_hull, " shield=", player.get_node("Damageable").current_shield)
		_check(int(director.get("stage")) == 4, "saved mission stage is restored")
		_check(is_equal_approx(float(director.get("mission_seconds")), 123.5), "saved mission timer is restored")
		_check(int(director.get("enemies_destroyed")) == 5, "saved combat progress is restored")
		_check(player.global_position.is_equal_approx(Vector3(20.0, 40.0, -500.0)), "saved player position is restored")
		_check(player.global_rotation.is_equal_approx(Vector3(0.1, 0.2, 0.3)), "saved player rotation is restored")
		_check(player.velocity.is_equal_approx(Vector3(4.0, 5.0, 6.0)), "saved flight velocity is restored")
	_check(save_manager.get("pending_mission_payload").is_empty(), "one-shot checkpoint handoff is cleared")

	_finish(save_manager)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("MAIN_MENU_CONTINUE_FAIL: " + message)


func _finish(save_manager: Node) -> void:
	save_manager.call("delete_slot", "silent_relay")
	save_manager.set("save_directory", "user://saves")
	if _failed == 0:
		print("MAIN_MENU_CONTINUE_PASS")
		quit(0)
	else:
		print("MAIN_MENU_CONTINUE_FAIL assertions=", _failed)
		quit(1)
