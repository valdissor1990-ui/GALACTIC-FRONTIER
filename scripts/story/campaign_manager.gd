extends Node
class_name CampaignManager
## Runtime bridge between gameplay events, M01-M05 objectives and persistent story state.

signal mission_started(mission_id: String)
signal objective_progress_changed(mission_id: String, objective_id: String, progress: int, required: int)
signal objective_completed(mission_id: String, objective_id: String)
signal mission_completed(mission_id: String)
signal campaign_state_changed

const SAVE_SLOT := "story_campaign"

var story_state: StoryState = StoryState.new()
var objective_progress: Dictionary = {}
var persistence_enabled: bool = true


func _ready() -> void:
	if persistence_enabled:
		load_campaign()


func start_mission(mission_id: String) -> Dictionary:
	if not story_state.active_mission_id.is_empty():
		if story_state.active_mission_id == mission_id:
			return {"ok": true, "resumed": true, "mission_id": mission_id, "objectives": get_objectives()}
		return _failure("Finish or abandon the active mission before starting another one.")
	if not MissionCatalog.can_start(mission_id, story_state):
		return _failure("Mission is locked, unknown, or already completed: %s" % mission_id)
	var definition := MissionCatalog.get_mission(mission_id)
	if definition.is_empty():
		return _failure("Unknown mission: %s" % mission_id)
	story_state.active_mission_id = mission_id
	objective_progress = {}
	for objective in definition.get("objectives", []):
		var objective_id := str(objective.get("id", ""))
		objective_progress[objective_id] = 0 if int(objective.get("count", 1)) > 1 else false
	_persist()
	mission_started.emit(mission_id)
	campaign_state_changed.emit()
	return {"ok": true, "mission_id": mission_id, "objectives": get_objectives()}


func complete_objective(objective_id: String, choice_id: String = "") -> Dictionary:
	var mission_id := story_state.active_mission_id
	if mission_id.is_empty():
		return _failure("There is no active mission.")
	var definition := MissionCatalog.get_mission(mission_id)
	var objective: Dictionary = {}
	for candidate in definition.get("objectives", []):
		if str(candidate.get("id", "")) == objective_id:
			objective = candidate
			break
	if objective.is_empty():
		return _failure("Objective does not belong to active mission: %s" % objective_id)
	var required_count := maxi(1, int(objective.get("count", 1)))
	var current_progress := int(objective_progress.get(objective_id, 0)) if required_count > 1 else (1 if bool(objective_progress.get(objective_id, false)) else 0)
	if current_progress >= required_count:
		return {"ok": true, "duplicate": true, "mission_completed": false, "progress": current_progress, "required": required_count}
	if str(objective.get("type", "")) == "choice":
		var choices: Dictionary = definition.get("choices", {})
		if choice_id.is_empty() or not choices.has(choice_id):
			return _failure("A valid choice_id is required for this objective.")
	current_progress += 1
	objective_progress[objective_id] = current_progress if required_count > 1 else true
	if str(objective.get("type", "")) == "choice":
		objective_progress[objective_id + "::choice"] = choice_id
	var objective_done := current_progress >= required_count
	objective_progress_changed.emit(mission_id, objective_id, current_progress, required_count)
	if objective_done:
		objective_completed.emit(mission_id, objective_id)
	var mission_done := objective_done and _all_required_objectives_complete(definition)
	if mission_done:
		var selected_choice := ""
		for candidate in definition.get("objectives", []):
			if str(candidate.get("type", "")) == "choice":
				selected_choice = str(objective_progress.get(str(candidate.get("id", "")) + "::choice", ""))
				break
		MissionCatalog.apply_completion(mission_id, story_state, selected_choice)
		objective_progress.clear()
		mission_completed.emit(mission_id)
	_persist()
	campaign_state_changed.emit()
	return {"ok": true, "mission_completed": mission_done, "objective_completed": objective_done, "progress": current_progress, "required": required_count, "mission_id": mission_id, "objective_id": objective_id}



## Translate world/gameplay events into catalog objective progress.
## Supported events: talk, undock, reach_target, scan, dock, destroy,
## deliver, protect, survive, timer_elapsed.
func report_gameplay_event(event_type: String, target_id: String = "", amount: int = 1, choice_id: String = "") -> Dictionary:
	if story_state.active_mission_id.is_empty():
		return _failure("There is no active mission.")
	if amount <= 0:
		return _failure("Event amount must be greater than zero.")
	var normalized_event := event_type.strip_edges().to_lower()
	var accepted_types: Dictionary = {
		"talk": ["talk"],
		"choice": ["choice"],
		"undock": ["undock"],
		"reach_target": ["goto"],
		"goto": ["goto"],
		"scan": ["scan"],
		"dock": ["dock"],
		"destroy": ["destroy", "survive_or_destroy"],
		"deliver": ["deliver"],
		"protect": ["protect"],
		"survive": ["survive", "survive_or_destroy"],
		"timer_elapsed": ["survive_timer", "survive_or_destroy"],
	}
	if not accepted_types.has(normalized_event):
		return _failure("Unsupported gameplay event: %s" % normalized_event)
	var definition := MissionCatalog.get_mission(story_state.active_mission_id)
	var matched: Array[String] = []
	var results: Array[Dictionary] = []
	for objective in definition.get("objectives", []):
		var objective_id := str(objective.get("id", ""))
		var objective_type := str(objective.get("type", ""))
		if objective_type not in accepted_types[normalized_event]:
			continue
		var expected_target := str(objective.get("target", ""))
		if not expected_target.is_empty() and expected_target != target_id:
			continue
		matched.append(objective_id)
		for event_index in range(amount):
			var result := complete_objective(objective_id, choice_id)
			results.append(result)
			if not result.get("ok", false) or result.get("objective_completed", false):
				break
	return {
		"ok": true,
		"matched_objectives": matched,
		"results": results,
		"mission_completed": story_state.active_mission_id.is_empty(),
	}


func get_objectives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mission_id := story_state.active_mission_id
	if mission_id.is_empty():
		return result
	var definition := MissionCatalog.get_mission(mission_id)
	for objective in definition.get("objectives", []):
		var item: Dictionary = objective.duplicate(true)
		var objective_id := str(item.get("id", ""))
		var required_count := maxi(1, int(item.get("count", 1)))
		var current_progress := int(objective_progress.get(objective_id, 0)) if required_count > 1 else (1 if bool(objective_progress.get(objective_id, false)) else 0)
		item["progress"] = current_progress
		item["required_count"] = required_count
		item["completed"] = current_progress >= required_count
		result.append(item)
	return result


func get_active_mission() -> Dictionary:
	if story_state.active_mission_id.is_empty():
		return {}
	return MissionCatalog.get_mission(story_state.active_mission_id)


func get_campaign_snapshot() -> Dictionary:
	return {
		"active_mission_id": story_state.active_mission_id,
		"completed_missions": story_state.completed_missions.duplicate(),
		"flags": story_state.flags.duplicate(true),
		"relationships": story_state.relationship.duplicate(true),
		"objectives": get_objectives(),
	}


func save_campaign() -> Dictionary:
	if not persistence_enabled:
		return {"ok": true, "skipped": true}
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		return _failure("GameSave autoload is unavailable.")
	var payload := {
		"story_state": story_state.to_save_dict(),
		"objective_progress": objective_progress.duplicate(true),
	}
	var result: Dictionary = save_manager.call("save_slot", SAVE_SLOT, payload)
	if not result.get("ok", false):
		return _failure(str(result.get("error", "Could not save campaign.")))
	return {"ok": true, "slot_id": SAVE_SLOT}


func load_campaign() -> Dictionary:
	if not persistence_enabled:
		return {"ok": true, "skipped": true}
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		return _failure("GameSave autoload is unavailable.")
	var result: Dictionary = save_manager.call("load_slot", SAVE_SLOT)
	if not result.get("ok", false):
		return {"ok": true, "new_campaign": true}
	var payload: Dictionary = result.get("payload", {})
	var saved_state: Variant = payload.get("story_state", {})
	if saved_state is Dictionary:
		story_state.from_save_dict(saved_state)
	var saved_progress: Variant = payload.get("objective_progress", {})
	objective_progress.clear()
	if saved_progress is Dictionary:
		for key in saved_progress.keys():
			objective_progress[str(key)] = saved_progress[key]
	# Discard stale or malformed objective progress rather than blocking a mission.
	if not story_state.active_mission_id.is_empty():
		var definition := MissionCatalog.get_mission(story_state.active_mission_id)
		if definition.is_empty():
			story_state.active_mission_id = ""
			objective_progress.clear()
		else:
			var valid_ids: Array[String] = []
			for objective in definition.get("objectives", []):
				valid_ids.append(str(objective.get("id", "")))
			for key in objective_progress.keys():
				if str(key).ends_with("::choice"):
					continue
				if str(key) not in valid_ids:
					objective_progress.erase(key)
	campaign_state_changed.emit()
	return {"ok": true, "loaded": true}


func _all_required_objectives_complete(definition: Dictionary) -> bool:
	for objective in definition.get("objectives", []):
		if bool(objective.get("optional", false)):
			continue
		var objective_id := str(objective.get("id", ""))
		var required_count := maxi(1, int(objective.get("count", 1)))
		var current_progress := int(objective_progress.get(objective_id, 0)) if required_count > 1 else (1 if bool(objective_progress.get(objective_id, false)) else 0)
		if current_progress < required_count:
			return false
	return true


func _persist() -> void:
	if persistence_enabled:
		var result := save_campaign()
		if not result.get("ok", false):
			push_error("Campaign persistence failed: " + str(result.get("error", "unknown")))


func _failure(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}
