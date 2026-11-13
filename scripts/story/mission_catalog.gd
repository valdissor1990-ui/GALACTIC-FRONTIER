extends RefCounted
class_name MissionCatalog
## Static definitions and guarded completion for campaign missions M01–M05.

const MISSION_ORDER: Array[String] = ["m01", "m02", "m03", "m04", "m05"]


static func all_missions() -> Dictionary:
	return {"m01": _m01(), "m02": _m02(), "m03": _m03(), "m04": _m04(), "m05": _m05()}


static func get_mission(mission_id: String) -> Dictionary:
	return all_missions().get(mission_id, {})


static func can_start(mission_id: String, state: StoryState) -> bool:
	if state == null or state.is_mission_completed(mission_id):
		return false
	var definition := get_mission(mission_id)
	if definition.is_empty():
		return false
	for flag_id in definition.get("requires_flags", []):
		if not state.has_flag(str(flag_id)):
			return false
	for required_mission in definition.get("requires_missions", []):
		if not state.is_mission_completed(str(required_mission)):
			return false
	return true


static func apply_completion(mission_id: String, state: StoryState, choice_id: String = "") -> bool:
	if state == null or not can_start(mission_id, state):
		return false
	var definition := get_mission(mission_id)
	var choices: Dictionary = definition.get("choices", {})
	if not choices.is_empty() and (choice_id.is_empty() or not choices.has(choice_id)):
		return false
	if choices.is_empty() and not choice_id.is_empty():
		return false

	if not state.complete_mission(mission_id):
		return false

	for flag_id in definition.get("set_flags_on_success", []):
		state.set_flag(str(flag_id))

	if not choices.is_empty():
		# Choice flags are mutually exclusive, even if state came from an older save.
		for candidate in choices.values():
			for flag_id in candidate.get("set_flags", []):
				state.clear_flag(str(flag_id))
		var choice: Dictionary = choices[choice_id]
		for flag_id in choice.get("set_flags", []):
			state.set_flag(str(flag_id))
		for key in choice.get("relationship", {}):
			state.adjust_relationship(str(key), int(choice["relationship"][key]))

	for key in definition.get("relationship_on_success", {}):
		state.adjust_relationship(str(key), int(definition["relationship_on_success"][key]))
	return true


static func _m01() -> Dictionary:
	return {
		"id": "m01", "title_ru": "Старт из Порт-Солейс", "title_en": "Port Solace Launch",
		"region": "aurelia_reach", "requires_flags": [], "requires_missions": [],
		"set_flags_on_success": ["m01_done", "board_tier_0"],
		"relationship_on_success": {"sera_quinn": 5},
		"objectives": [
			{"id": "talk_quinn", "type": "talk", "optional": false},
			{"id": "undock", "type": "undock", "optional": false},
			{"id": "goto_buoy", "type": "goto", "target": "aurelia_a3", "optional": false},
			{"id": "scan_buoy", "type": "scan", "target": "aurelia_a3", "optional": false},
			{"id": "return_dock", "type": "dock", "target": "port_solace", "optional": false}
		], "next_mission": "m02"
	}


static func _m02() -> Dictionary:
	return {
		"id": "m02", "title_ru": "Вкус Пояса", "title_en": "Belt Taste",
		"region": "vesper_belt", "requires_missions": ["m01"],
		"set_flags_on_success": ["vesper_access", "m02_done"],
		"relationship_on_success": {"jex_morra": 5},
		"objectives": [
			{"id": "goto_vb01", "type": "goto", "target": "vb_01", "optional": false},
			{"id": "scan_debris", "type": "scan", "count": 3, "optional": false},
			{"id": "optional_hostiles", "type": "destroy", "optional": true},
			{"id": "deliver_jex", "type": "deliver", "target": "jex_drop", "optional": false}
		], "next_mission": "m03"
	}


static func _m03() -> Dictionary:
	return {
		"id": "m03", "title_ru": "Имя на бирке", "title_en": "Name on a Tag",
		"region": "aurelia_reach", "requires_missions": ["m02"],
		"set_flags_on_success": ["m03_done"],
		"choices": {
			"share_helix": {"set_flags": ["shared_helix"], "relationship": {"helene_voss": 10, "helix": 10, "free_colonies": -5, "nyra_sol": -2}},
			"share_union": {"set_flags": ["shared_union"], "relationship": {"kade_vorn": 5, "union": 10, "helix": -5, "nyra_sol": 0}},
			"keep_private": {"set_flags": ["kept_private"], "relationship": {"nyra_sol": 10, "helix": -3, "union": -3}}
		},
		"objectives": [
			{"id": "talk_quinn_tag", "type": "talk", "optional": false},
			{"id": "talk_nyra", "type": "talk", "optional": false},
			{"id": "choose_share", "type": "choice", "optional": false}
		], "next_mission": "m04"
	}


static func _m04() -> Dictionary:
	return {
		"id": "m04", "title_ru": "Эскорт Кестрела", "title_en": "Kestrel Escort",
		"region": "kestrel_expanse", "requires_missions": ["m03"],
		"set_flags_on_success": ["kestrel_access", "m04_done"],
		"relationship_on_success": {"kade_vorn": 8, "union": 5},
		"objectives": [
			{"id": "goto_convoy", "type": "goto", "target": "kestrel_gather", "optional": false},
			{"id": "protect_freighter", "type": "protect", "target": "freighter_1", "optional": false},
			{"id": "survive_interdiction", "type": "survive_or_destroy", "optional": false},
			{"id": "handoff", "type": "goto", "target": "kestrel_handoff", "optional": false}
		], "next_mission": "m05"
	}


static func _m05() -> Dictionary:
	return {
		"id": "m05", "title_ru": "Статика на Реле", "title_en": "Static on the Relay",
		"region": "silent_relay", "requires_missions": ["m04"],
		"set_flags_on_success": ["relay_contact_1", "m05_done", "act1_complete"],
		"relationship_on_success": {"nyra_sol": 5},
		"objectives": [
			{"id": "goto_relay_edge", "type": "goto", "target": "silent_relay_outer", "optional": false},
			{"id": "scan_pulse", "type": "scan", "target": "relay_pulse", "optional": false},
			{"id": "survive_timer", "type": "survive_timer", "seconds": 20, "optional": false},
			{"id": "escape_safe", "type": "goto", "target": "safe_nav", "optional": false}
		], "next_mission": ""
	}
