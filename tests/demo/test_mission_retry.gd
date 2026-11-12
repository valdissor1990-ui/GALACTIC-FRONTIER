extends Node
## Exercises actual result-screen navigation across scene reloads.

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var err := get_tree().change_scene_to_packed(DEMO_SCENE)
	_check(err == OK, "initial mission scene must load")
	await get_tree().process_frame
	await get_tree().process_frame
	var demo := get_tree().current_scene
	var player := demo.get_node("PlayerShip") as ShipController
	(player.get_node("Damageable") as Damageable).take_damage(100000.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var result := demo.get_node_or_null("MissionResult")
	_check(result != null, "failure must create a result screen")
	var retry_button := result.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/RetryButton") as Button
	_check(retry_button != null, "retry button must be addressable")
	retry_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var retried := get_tree().current_scene
	_check(retried != null and retried.name == "TenMinuteDemo", "retry must reload the mission scene")
	_check(retried.get_node_or_null("MissionResult") == null, "retry must not retain the previous result screen")
	var retried_player := retried.get_node("PlayerShip") as ShipController
	(retried_player.get_node("Damageable") as Damageable).take_damage(100000.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var second_result := retried.get_node_or_null("MissionResult")
	_check(second_result != null, "second failure must show a fresh result screen")
	var menu_button := second_result.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/MenuButton") as Button
	_check(menu_button != null, "main menu button must be addressable")
	menu_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_check(get_tree().current_scene != null and get_tree().current_scene.name == "MainMenu", "main menu action must load the menu scene")
	print("MISSION_RETRY_MENU_TEST_PASS")
	get_tree().quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MISSION_RETRY_MENU_TEST_FAIL: " + message)
	get_tree().quit(1)
