extends SceneTree
## Exercises actual result-screen navigation across scene reloads.

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var err := change_scene_to_packed(DEMO_SCENE)
	_check(err == OK, "initial mission scene must load")
	await process_frame
	await process_frame
	var demo := current_scene
	var player := demo.get_node("PlayerShip") as ShipController
	(player.get_node("Damageable") as Damageable).take_damage(100000.0)
	await process_frame
	await process_frame
	var result := demo.get_node_or_null("MissionResult")
	_check(result != null, "failure must create a result screen")
	var retry_button := result.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/RetryButton") as Button
	_check(retry_button != null, "retry button must be addressable")
	retry_button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	var retried := current_scene
	_check(retried != null and retried.name == "TenMinuteDemo", "retry must reload the mission scene")
	_check(retried.get_node_or_null("MissionResult") == null, "retry must not retain the previous result screen")
	var retried_player := retried.get_node("PlayerShip") as ShipController
	(retried_player.get_node("Damageable") as Damageable).take_damage(100000.0)
	await process_frame
	await process_frame
	var second_result := retried.get_node_or_null("MissionResult")
	_check(second_result != null, "second failure must show a fresh result screen")
	var menu_button := second_result.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/MenuButton") as Button
	_check(menu_button != null, "main menu button must be addressable")
	menu_button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.name == "MainMenu", "main menu action must load the menu scene")
	print("MISSION_RETRY_MENU_TEST_PASS")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MISSION_RETRY_MENU_TEST_FAIL: " + message)
	quit(1)
