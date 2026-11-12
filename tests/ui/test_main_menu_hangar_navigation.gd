extends SceneTree
## Verifies the main-menu button opens the real fleet hangar scene.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const HANGAR_SCENE := "res://scenes/ui/fleet_hangar.tscn"
var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var error := change_scene_to_file(MENU_SCENE)
	_check(error == OK, "main menu scene loads")
	await process_frame
	await process_frame
	var menu := current_scene
	_check(menu != null, "main menu becomes current scene")
	if menu == null:
		quit(1)
		return
	var button := menu.get_node_or_null("MainMenuLayout/FleetHangarButton") as Button
	_check(button != null, "fleet hangar button is present in main menu")
	if button == null:
		quit(1)
		return
	button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == HANGAR_SCENE, "fleet hangar button opens the real hangar scene")
	if _failed == 0:
		print("MAIN_MENU_HANGAR_NAVIGATION_PASS")
		quit(0)
	else:
		print("MAIN_MENU_HANGAR_NAVIGATION_FAIL assertions=", _failed)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("MAIN_MENU_HANGAR_NAVIGATION_FAIL: " + message)
