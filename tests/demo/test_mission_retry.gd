extends SceneTree
## Exercises actual result-screen navigation across scene reloads.
## This SceneTree harness survives change_scene_to_file() calls.

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")
var _finished := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	call_deferred("_watchdog")
	var err := change_scene_to_packed(DEMO_SCENE)
	if not _check(err == OK, "initial mission scene must load"):
		return
	await process_frame
	await process_frame
	var demo := current_scene
	var player := demo.get_node("PlayerShip") as ShipController
	(player.get_node("Damageable") as Damageable).take_damage(100000.0)
	await process_frame
	await process_frame
	var result := demo.get_node_or_null("MissionResult")
	if not _check(result != null, "failure must create a result screen"):
		return
	var retry_button := _find_named(result, "RetryButton") as Button
	if not _check(retry_button != null, "retry button must be present in the result screen"):
		_dump_tree(result)
		return
	retry_button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	var retried := current_scene
	if not _check(retried != null and retried.name == "TenMinuteDemo", "retry must reload the mission scene"):
		return
	if not _check(retried.get_node_or_null("MissionResult") == null, "retry must not retain the previous result screen"):
		return
	var retried_player := retried.get_node("PlayerShip") as ShipController
	(retried_player.get_node("Damageable") as Damageable).take_damage(100000.0)
	await process_frame
	await process_frame
	var second_result := retried.get_node_or_null("MissionResult")
	if not _check(second_result != null, "second failure must show a fresh result screen"):
		return
	var menu_button := _find_named(second_result, "MenuButton") as Button
	if not _check(menu_button != null, "main-menu button must be present in the result screen"):
		_dump_tree(second_result)
		return
	menu_button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	if not _check(current_scene != null and current_scene.name == "MainMenu", "main menu action must load the menu scene"):
		return
	_finished = true
	print("MISSION_RETRY_MENU_TEST_PASS")
	quit(0)

func _find_named(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child in node.get_children():
		var found := _find_named(child, wanted)
		if found != null:
			return found
	return null

func _dump_tree(node: Node, indent := "") -> void:
	print("RETRY_TEST_TREE ", indent, node.name, " [", node.get_class(), "]")
	for child in node.get_children():
		_dump_tree(child, indent + "  ")

func _watchdog() -> void:
	await create_timer(120.0).timeout
	if not _finished:
		push_error("MISSION_RETRY_MENU_TEST_TIMEOUT")
		quit(1)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_finished = true
	push_error("MISSION_RETRY_MENU_TEST_FAIL: " + message)
	quit(1)
	return false
