extends Node
## Bootstraps the playable Silent Relay vertical-slice mission.

const FLIGHT_SCENE: String = "res://scenes/demo/ten_minute_demo.tscn"


func _ready() -> void:
	call_deferred("_open_flight_scene")


func _open_flight_scene() -> void:
	var error: Error = get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		push_error("GALACTIC FRONTIER: could not open flight scene. Error code: %s" % error)
