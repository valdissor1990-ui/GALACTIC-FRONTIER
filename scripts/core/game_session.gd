extends Node
## Owns the top-level menu-to-mission flow.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const BOOTSTRAP_SCENE := "res://scenes/bootstrap/main.tscn"

func _ready() -> void:
	call_deferred("_open_menu")

func _open_menu() -> void:
	if OS.get_cmdline_user_args().has("--test-mode"):
		print("GAME_SESSION: menu autoload suppressed for isolated test run")
		return
	var active_scene := get_tree().current_scene
	if active_scene != null and active_scene.scene_file_path != BOOTSTRAP_SCENE:
		print("GAME_SESSION: keeping explicitly requested scene ", active_scene.scene_file_path)
		return
	var error := get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("GALACTIC FRONTIER: could not open main menu. Error code: %s" % error)
		get_tree().quit(1)
