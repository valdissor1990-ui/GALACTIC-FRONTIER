extends RefCounted
class_name StoryState
## Plain-data story progress. Safe for SaveManager payload under mission_flags / completed_missions.

const FLAG_TRUE := 1
const FLAG_FALSE := 0

var flags: Dictionary = {}
var completed_missions: Array[String] = []
var active_mission_id: String = ""
var relationship: Dictionary = {
	"sera_quinn": 0,
	"jex_morra": 0,
	"kade_vorn": 0,
	"nyra_sol": 0,
	"helene_voss": 0,
	"helix": 0,
	"union": 0,
	"free_colonies": 0,
}


func set_flag(flag_id: String, value: bool = true) -> void:
	flags[flag_id] = FLAG_TRUE if value else FLAG_FALSE


func has_flag(flag_id: String) -> bool:
	return int(flags.get(flag_id, FLAG_FALSE)) == FLAG_TRUE


func clear_flag(flag_id: String) -> void:
	flags[flag_id] = FLAG_FALSE


func complete_mission(mission_id: String) -> void:
	if mission_id not in completed_missions:
		completed_missions.append(mission_id)
	if active_mission_id == mission_id:
		active_mission_id = ""


func is_mission_completed(mission_id: String) -> bool:
	return mission_id in completed_missions


func adjust_relationship(key: String, delta: int) -> void:
	var current: int = int(relationship.get(key, 0))
	relationship[key] = clampi(current + delta, -100, 100)


func get_relationship(key: String) -> int:
	return int(relationship.get(key, 0))


func to_save_dict() -> Dictionary:
	return {
		"mission_flags": flags.duplicate(true),
		"completed_missions": completed_missions.duplicate(),
		"active_mission_id": active_mission_id,
		"relationship": relationship.duplicate(true),
	}


func from_save_dict(data: Dictionary) -> void:
	flags.clear()
	var loaded_flags: Variant = data.get("mission_flags", {})
	if typeof(loaded_flags) == TYPE_DICTIONARY:
		for k in loaded_flags.keys():
			flags[str(k)] = int(loaded_flags[k])
	completed_missions.clear()
	var loaded_completed: Variant = data.get("completed_missions", [])
	if typeof(loaded_completed) == TYPE_ARRAY:
		for item in loaded_completed:
			completed_missions.append(str(item))
	active_mission_id = str(data.get("active_mission_id", ""))
	var loaded_rel: Variant = data.get("relationship", {})
	if typeof(loaded_rel) == TYPE_DICTIONARY:
		for k in loaded_rel.keys():
			relationship[str(k)] = int(loaded_rel[k])
