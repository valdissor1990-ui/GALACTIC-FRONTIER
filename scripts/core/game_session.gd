extends Node
## Opens the original single-player front end. The menu owns New Game / Continue.

const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	call_deferred("_open_main_menu")


func _open_main_menu() -> void:
	var error: Error = get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("GALACTIC FRONTIER: could not open main menu. Error code: %s" % error)
