extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := root.get_node("GameProfile") as PlayerProfile
	var backup := _backup_profile(profile)
	profile.credits = 10000
	profile.completed_mission_ids.clear()
	profile.active_contract_id = "silent_relay"
	profile.call("_save_profile")

	_check(profile.is_contract_unlocked("silent_relay"), "starter contract must always be available")
	_check(not profile.is_contract_unlocked("vesper_salvage"), "Vesper contract must remain locked before the starter contract")
	_check(not profile.accept_contract("vesper_salvage"), "locked contracts cannot be accepted")
	_check(profile.complete_mission("silent_relay", 5000) == 5000, "starter contract pays its configured reward")
	_check(profile.is_contract_unlocked("vesper_salvage"), "Vesper contract unlocks after Silent Relay")
	_check(not profile.is_contract_unlocked("kestrel_patrol"), "Kestrel remains locked until Vesper is complete")
	_check(profile.accept_contract("vesper_salvage"), "unlocked Vesper contract can be accepted")
	_check(str(profile.get_active_system().get("id", "")) == "vesper", "Vesper contract selects the Vesper star system")
	_check(profile.complete_mission("vesper_salvage", 6500) == 6500, "Vesper contract pays its configured reward")
	_check(profile.is_contract_unlocked("kestrel_patrol"), "Kestrel unlocks after Vesper Salvage")
	_check(profile.accept_contract("kestrel_patrol"), "unlocked Kestrel contract can be accepted")
	_check(str(profile.get_active_contract().get("id", "")) == "kestrel_patrol", "active contract persists as Kestrel Patrol")
	_check(str(profile.get_active_system().get("id", "")) == "kestrel", "Kestrel contract selects the Kestrel system")

	_check(profile.set_story_flag("m01_done", true), "canonical M01 completion flag is accepted")
	_check(profile.has_story_flag("m01_done"), "story flag is visible immediately")
	_check(not profile.set_story_flag("unknown_flag", true), "unknown story flags are rejected")
	profile.call("_load_profile")
	_check(profile.has_story_flag("m01_done"), "story flags persist through profile reload")
	_check(not profile.has_story_flag("vesper_access"), "unset story flags remain false after reload")

	var board: Control = load("res://scenes/ui/contract_board.tscn").instantiate() as Control
	root.add_child(board)
	await process_frame
	var cards := board.get("_cards") as HBoxContainer
	_check(cards != null and cards.get_child_count() == 3, "contract board renders all three system contracts")
	board.queue_free()
	await process_frame

	_restore_profile(profile, backup)
	if _failures.is_empty():
		print("CONTRACT_PROGRESSION_TEST_PASS assertions=19")
		quit(0)
	else:
		for failure in _failures:
			push_error("CONTRACT_PROGRESSION_TEST_FAIL: " + failure)
		quit(1)


func _backup_profile(profile: PlayerProfile) -> Dictionary:
	return {
		"credits": profile.credits,
		"selected_ship_id": profile.selected_ship_id,
		"unlocked_ship_ids": profile.unlocked_ship_ids.duplicate(),
		"completed_mission_ids": profile.completed_mission_ids.duplicate(),
		"installed_modules": profile.installed_modules.duplicate(true),
		"active_contract_id": profile.active_contract_id,
		"story_flags": profile.story_flags.duplicate(true)
	}


func _restore_profile(profile: PlayerProfile, backup: Dictionary) -> void:
	profile.credits = int(backup["credits"])
	profile.selected_ship_id = str(backup["selected_ship_id"])
	profile.unlocked_ship_ids.clear()
	for ship_id in backup["unlocked_ship_ids"]:
		profile.unlocked_ship_ids.append(str(ship_id))
	profile.completed_mission_ids.clear()
	for mission_id in backup["completed_mission_ids"]:
		profile.completed_mission_ids.append(str(mission_id))
	profile.installed_modules = backup["installed_modules"].duplicate(true)
	profile.active_contract_id = str(backup["active_contract_id"])
	profile.story_flags = backup["story_flags"].duplicate(true)
	profile.call("_save_profile")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
