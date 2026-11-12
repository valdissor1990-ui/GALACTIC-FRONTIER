extends Node
## Owns the top-level menu-to-mission flow.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

func _ready() -> void:
	call_deferred("_open_menu")

func _open_menu() -> void:
	var error := get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("GALACTIC FRONTIER: could not open main menu. Error code: %s" % error)
		get_tree().quit(1)
