extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := root.get_node("GameProfile") as PlayerProfile
	var backup := {
		"credits": profile.credits,
		"selected_ship_id": profile.selected_ship_id,
		"unlocked_ship_ids": profile.unlocked_ship_ids.duplicate(),
		"completed_mission_ids": profile.completed_mission_ids.duplicate(),
		"installed_modules": profile.installed_modules.duplicate(true),
		"active_contract_id": profile.active_contract_id
	}
	profile.completed_mission_ids.clear()
	profile.completed_mission_ids.append("silent_relay")
	profile.active_contract_id = "vesper_salvage"
	profile.call("_save_profile")
	var save_manager := root.get_node("GameSave")
	var checkpoint_backup: Dictionary = save_manager.call("load_slot", "silent_relay")
	var pending_payload_backup: Variant = save_manager.get("pending_mission_payload")
	save_manager.set("pending_mission_payload", {})

	var demo: Node3D = load("res://scenes/demo/ten_minute_demo.tscn").instantiate() as Node3D
	demo.add_to_group("qa_demo_driver")
	root.add_child(demo)
	await process_frame
	await process_frame
	var director := demo.get_node("DemoMissionDirector")
	var environment := demo.get_node("SpaceEnvironment")
	var player := demo.get_node("PlayerShip") as ShipController
	_check(int(director.get("_waves_per_encounter")) == 4, "Vesper contract configures four waves per encounter")
	_check(is_equal_approx(float(director.get("_enemy_health_multiplier")), 1.10), "Vesper contract applies veteran enemy durability")
	_check(int(director.get("_mission_reward")) == 6500, "Vesper contract reward is applied to the mission")
	_check(str(director.get("_system_name")) == "Vesper Belt", "mission director uses the Vesper system name")
	_check(str(environment.get("_system_id")) == "vesper", "space environment selects Vesper's visual theme")
	_check(int(environment.get("asteroid_count")) == 190, "Vesper system uses its denser asteroid field")
	director.call("_begin_contract_epilogue")
	_check(int(director.get("stage")) == 11, "Vesper contract adds a dedicated salvage recovery stage")
	_check((director.get("_salvage_pods") as Array).size() == 3, "Vesper contract creates three recoverable cargo pods")
	for _index in range(3):
		player.global_position = director.get("_objective_position")
		director.call("_recover_salvage")
	_check(int(director.get("stage")) == 6, "recovering all Vesper pods unlocks carrier return")

	profile.complete_mission("vesper_salvage", 6500)
	_check(profile.accept_contract("kestrel_patrol"), "Kestrel contract unlocks after Vesper completion")
	director.call("_load_active_contract")
	director.call("_build_contract_objectives")
	environment.call("_load_system_theme")
	_check(int(director.get("_waves_per_encounter")) == 5, "Kestrel contract configures five waves per encounter")
	_check(is_equal_approx(float(director.get("_enemy_health_multiplier")), 1.25), "Kestrel contract applies elite enemy durability")
	_check(int(director.get("_mission_reward")) == 8000, "Kestrel contract applies its higher reward")
	_check(str(director.get("_system_name")) == "Kestrel Expanse", "mission director switches to Kestrel")
	_check(str(environment.get("_system_id")) == "kestrel", "space environment switches to Kestrel visual theme")
	_check(int(environment.get("asteroid_count")) == 80, "Kestrel system uses its sparse debris field")
	director.call("_begin_contract_epilogue")
	_check(int(director.get("stage")) == 12, "Kestrel contract adds a dedicated patrol sweep stage")
	_check((director.get("_patrol_positions") as Array).size() == 3, "Kestrel contract defines three patrol waypoints")
	for _index in range(3):
		player.global_position = director.get("_objective_position")
		director.call("_advance_patrol_waypoint")
	_check(int(director.get("stage")) == 6, "visiting all Kestrel patrol waypoints unlocks carrier return")

	demo.queue_free()
	await process_frame
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
	profile.call("_save_profile")
	if bool(checkpoint_backup.get("ok", false)):
		save_manager.call("save_slot", "silent_relay", checkpoint_backup.get("payload", {}))
	else:
		save_manager.call("delete_slot", "silent_relay")
	save_manager.set("pending_mission_payload", pending_payload_backup)

	if _failures.is_empty():
		print("CONTRACT_VARIANTS_TEST_PASS assertions=19")
		quit(0)
	else:
		for failure in _failures:
			push_error("CONTRACT_VARIANTS_TEST_FAIL: " + failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
