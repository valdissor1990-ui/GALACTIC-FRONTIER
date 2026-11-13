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
	var previous_value: Variant = objective_progress.get(objective_id, 0 if required_count > 1 else false)
	var current_progress := int(previous_value) if required_count > 1 else (1 if bool(previous_value) else 0)
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
	var mission_done := objective_done and _all_required_objectives_complete(definition)

	if mission_done:
		var selected_choice := ""
		for candidate in definition.get("objectives", []):
			if str(candidate.get("type", "")) == "choice":
				selected_choice = str(objective_progress.get(str(candidate.get("id", "")) + "::choice", ""))
				break
		if not MissionCatalog.apply_completion(mission_id, story_state, selected_choice):
			objective_progress[objective_id] = previous_value
			return _failure("Mission completion was rejected by the campaign state.")

	if mission_done:
		objective_progress.clear()
		mission_completed.emit(mission_id)
	objective_progress_changed.emit(mission_id, objective_id, current_progress, required_count)
	if objective_done:
		objective_completed.emit(mission_id, objective_id)
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
		if _is_objective_complete(objective_id, objective):
			continue

		# One world event advances one matching objective. This prevents a single
		# generic "talk" or "scan" event from satisfying multiple story beats.
		matched.append(objective_id)
		for event_index in range(amount):
			var result := complete_objective(objective_id, choice_id)
			results.append(result)
			if not result.get("ok", false) or result.get("objective_completed", false):
				break
		break

	return {
		"ok": true,
		"matched_objectives": matched,
		"results": results,
		"mission_completed": story_state.active_mission_id.is_empty(),
	}


func _is_objective_complete(objective_id: String, objective: Dictionary) -> bool:
	var required_count := maxi(1, int(objective.get("count", 1)))
	var value: Variant = objective_progress.get(objective_id, 0 if required_count > 1 else false)
	var progress := int(value) if required_count > 1 else (1 if bool(value) else 0)
	return progress >= required_count


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

	objective_progress.clear()
	var saved_progress: Variant = payload.get("objective_progress", {})
	if saved_progress is Dictionary:
		for key in saved_progress.keys():
			objective_progress[str(key)] = saved_progress[key]

	var active_id := story_state.active_mission_id
	if active_id.is_empty():
		objective_progress.clear()
	else:
		var definition := MissionCatalog.get_mission(active_id)
		if definition.is_empty() or not MissionCatalog.can_start(active_id, story_state):
			story_state.active_mission_id = ""
			objective_progress.clear()
		else:
			var objective_definitions: Dictionary = {}
			for objective in definition.get("objectives", []):
				objective_definitions[str(objective.get("id", ""))] = objective

			for key_variant in objective_progress.keys():
				var key := str(key_variant)
				if key.ends_with("::choice"):
					var choice_objective_id := key.substr(0, key.length() - 8)
					var choice_objective: Dictionary = objective_definitions.get(choice_objective_id, {})
					var choices: Dictionary = definition.get("choices", {})
					var saved_choice := str(objective_progress[key])
					if str(choice_objective.get("type", "")) != "choice" or not choices.has(saved_choice):
						objective_progress.erase(key)
					continue

				if not objective_definitions.has(key):
					objective_progress.erase(key)
					continue
				var objective: Dictionary = objective_definitions[key]
				var required_count := maxi(1, int(objective.get("count", 1)))
				var saved_value: Variant = objective_progress[key]
				if required_count > 1:
					if typeof(saved_value) != TYPE_INT and typeof(saved_value) != TYPE_FLOAT:
						objective_progress[key] = 0
					else:
						objective_progress[key] = clampi(int(saved_value), 0, required_count)
				else:
					objective_progress[key] = bool(saved_value)

			for objective_id in objective_definitions.keys():
				if not objective_progress.has(objective_id):
					var objective: Dictionary = objective_definitions[objective_id]
					objective_progress[objective_id] = 0 if int(objective.get("count", 1)) > 1 else false

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
