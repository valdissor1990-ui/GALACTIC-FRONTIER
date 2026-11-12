extends Node
## Minimal bootstrap. The flight scene is the only game scene in Phase 1.

const FLIGHT_SCENE: String = "res://scenes/flight/visual_flight.tscn"


func _ready() -> void:
	call_deferred("_open_flight_scene")


func _open_flight_scene() -> void:
	var error: Error = get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		push_error("GALACTIC FRONTIER: could not open flight scene. Error code: %s" % error)
