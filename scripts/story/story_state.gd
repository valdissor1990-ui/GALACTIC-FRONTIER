extends RefCounted
class_name StoryState
## Plain-data campaign progress. Compatible with SaveManager payloads.

const FLAG_TRUE := 1
const FLAG_FALSE := 0

const DEFAULT_RELATIONSHIPS := {
	"sera_quinn": 0,
	"jex_morra": 0,
	"kade_vorn": 0,
	"nyra_sol": 0,
	"helene_voss": 0,
	"helix": 0,
	"union": 0,
	"free_colonies": 0,
}

var flags: Dictionary = {}
var completed_missions: Array[String] = []
var active_mission_id: String = ""
var relationship: Dictionary = DEFAULT_RELATIONSHIPS.duplicate(true)


func set_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.is_empty():
		return
	flags[flag_id] = FLAG_TRUE if value else FLAG_FALSE


func has_flag(flag_id: String) -> bool:
	return int(flags.get(flag_id, FLAG_FALSE)) == FLAG_TRUE


func clear_flag(flag_id: String) -> void:
	flags[flag_id] = FLAG_FALSE


func complete_mission(mission_id: String) -> bool:
	if mission_id.is_empty() or is_mission_completed(mission_id):
		return false
	completed_missions.append(mission_id)
	if active_mission_id == mission_id:
		active_mission_id = ""
	return true


func is_mission_completed(mission_id: String) -> bool:
	return mission_id in completed_missions


func adjust_relationship(key: String, delta: int) -> void:
	if key.is_empty():
		return
	var current := int(relationship.get(key, 0))
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
	completed_missions.clear()
	active_mission_id = ""
	relationship = DEFAULT_RELATIONSHIPS.duplicate(true)

	var loaded_flags: Variant = data.get("mission_flags", {})
	if loaded_flags is Dictionary:
		for key in loaded_flags:
			flags[str(key)] = int(loaded_flags[key])

	var loaded_completed: Variant = data.get("completed_missions", [])
	if loaded_completed is Array:
		for item in loaded_completed:
			var mission_id := str(item)
			if not mission_id.is_empty() and mission_id not in completed_missions:
				completed_missions.append(mission_id)

	active_mission_id = str(data.get("active_mission_id", ""))
	if active_mission_id in completed_missions:
		active_mission_id = ""

	var loaded_relationships: Variant = data.get("relationship", {})
	if loaded_relationships is Dictionary:
		for key in loaded_relationships:
			relationship[str(key)] = clampi(int(loaded_relationships[key]), -100, 100)
