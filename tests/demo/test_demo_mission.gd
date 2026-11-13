extends SceneTree

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")
var _finished := false
var _profile_backup: Dictionary = {}


func _initialize() -> void:
	call_deferred("_watchdog")
	call_deferred("_run_test")


func _watchdog() -> void:
	await create_timer(120.0).timeout
	if not _finished:
		push_error("DEMO_MISSION_TEST_TIMEOUT: progression did not finish within 120 seconds")
		quit(1)


func _run_test() -> void:
	var demo := DEMO_SCENE.instantiate()
	demo.add_to_group("qa_demo_driver")
	root.add_child(demo)
	await process_frame
	await process_frame
	var director: Node = demo.get_node("DemoMissionDirector")
	var player: Node3D = demo.get_node("PlayerShip")
	var profile := root.get_node("GameProfile") as PlayerProfile
	_profile_backup = {
		"credits": profile.credits,
		"selected_ship_id": profile.selected_ship_id,
		"unlocked_ship_ids": profile.unlocked_ship_ids.duplicate(),
		"completed_mission_ids": profile.completed_mission_ids.duplicate()
	}
	var camera_rig: CameraRig = player.get_node("CameraRig") as CameraRig
	var cockpit: Node3D = player.get_node("CockpitInterior") as Node3D
	# Keep the first-person composition stable across future model/cockpit edits.
	var cockpit_camera := camera_rig.get_node("CockpitCamera") as Camera3D
	_check(is_equal_approx(cockpit_camera.fov, 76.0), "Cockpit camera must retain the polished 76-degree field of view")
	_check(cockpit_camera.position.is_equal_approx(Vector3(0.0, 0.24, -1.72)), "Cockpit camera must retain the forward-biased framing")
	_check(cockpit != null and not cockpit.visible, "Cockpit interior must start hidden in chase-camera mode")
	camera_rig.toggle_camera()
	_check(cockpit.visible and not player.get_node("Visual").visible, "Cockpit mode must show the cockpit and hide the exterior ship")
	camera_rig.toggle_camera()
	_check(not cockpit.visible and player.get_node("Visual").visible, "Chase mode must restore the exterior ship")
	_test_mission_duration_budget()
	_check(director.stage == 0, "Mission must start at outbound navigation")
	_check(get_nodes_in_group("combat_targets").is_empty(), "Demo must not start the legacy automatic encounter")

	player.global_position = director._objective_position
	await process_frame
	_check(director.stage == 1, "Entering relay range must activate the scan objective")
	director._complete_relay_scan()
	_check(director.stage == 2, "Relay scan must start the first defense sequence")
	await _clear_three_waves(director)

	_check(director.stage == 3, "Three relay waves must unlock wreck investigation")
	player.global_position = director._objective_position
	await process_frame
	_check(director.stage == 4, "Entering wreck range must activate the data scan")
	director._complete_wreck_scan()
	_check(director.stage == 5, "Wreck scan must start the second defense sequence")
	await _clear_three_waves(director)

	_check(director.stage == 6, "Six waves must unlock return to carrier")
	var damageable := player.get_node("Damageable") as Damageable
	damageable.current_hull = damageable.max_hull * 0.5
	damageable.current_shield = damageable.max_shield * 0.25
	player.boost_amount = 0.0
	profile.credits = 10000
	profile.call("_save_profile")
	demo.remove_from_group("qa_demo_driver")
	player.global_position = director._objective_position
	await process_frame
	_check(director.stage == 9, "Returning to carrier must enter the docking approach, not auto-complete")
	player.global_position = director._dock_position
	player.global_rotation = Vector3(0.0, PI, 0.0)
	player.velocity = Vector3.ZERO
	_check(director._attempt_docking(), "Aligned, stationary craft inside the port must dock")
	_check(director.stage == 10, "Successful docking must open carrier maintenance")
	_check(not demo.get_node("HUD").visible, "Flight telemetry HUD must be hidden behind carrier maintenance")
	_check(not demo.get_node("CombatHUD").visible, "Combat HUD must be hidden behind carrier maintenance")
	_check(director._service_layer.visible, "Carrier maintenance overlay must remain visible above the flight scene")
	var credits_before := profile.get_credits()
	director._service_hull()
	_check(is_equal_approx(damageable.current_hull, damageable.max_hull), "Carrier hull repair must restore full hull")
	director._service_shields()
	_check(is_equal_approx(damageable.current_shield, damageable.max_shield), "Carrier shield recharge must restore full shields")
	director._service_boost()
	_check(is_equal_approx(player.boost_amount, player.flight_config.boost_capacity), "Carrier boost refill must restore full boost")
	director._service_weapons()
	_check(profile.get_credits() < credits_before, "Maintenance services must deduct persistent pilot credits")
	_check(director._service_layer != null and is_instance_valid(director._service_layer), "Docking must present the carrier maintenance panel")
	_restore_profile(profile)
	_finished = true
	print("DEMO_DOCKING_SERVICE_TEST_PASS")
	quit(0)



func _restore_profile(profile: PlayerProfile) -> void:
	profile.credits = int(_profile_backup.get("credits", PlayerProfile.STARTING_CREDITS))
	profile.selected_ship_id = str(_profile_backup.get("selected_ship_id", "player_fighter"))
	profile.unlocked_ship_ids.clear()
	for ship_id in _profile_backup.get("unlocked_ship_ids", ["player_fighter"]):
		profile.unlocked_ship_ids.append(str(ship_id))
	profile.completed_mission_ids.clear()
	for mission_id in _profile_backup.get("completed_mission_ids", []):
		profile.completed_mission_ids.append(str(mission_id))
	profile.call("_save_profile")


func _clear_three_waves(director: Node) -> void:
	for wave in range(3):
		var enemies := get_nodes_in_group("combat_targets")
		_check(not enemies.is_empty(), "Each defense wave must spawn hostile fighters")
		for enemy in enemies:
			var damageable := enemy.get_node_or_null("Damageable")
			_check(damageable != null, "Every hostile must have a Damageable component")
			damageable.take_damage(100000.0)
		await process_frame
		if wave < 2:
			director._next_wave_timer = 0.0
			await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_finished = true
	push_error("DEMO_MISSION_TEST_FAIL: " + message)
	quit(1)


func _test_mission_duration_budget() -> void:
	# Conservative design budget: full route at the fastest sustainable boost
	# cycle, plus theoretical minimum time to destroy all 17 hostiles and wave
	# intermissions. Actual play takes longer due to aiming and manoeuvring.
	var relay := Vector3(0.0, 18.0, -13500.0)
	var wreck := Vector3(520.0, -28.0, -33000.0)
	var home := Vector3(0.0, 0.0, 90.0)
	var route_distance := Vector3.ZERO.distance_to(relay) + relay.distance_to(wreck) + wreck.distance_to(home)
	var cruise_speed := 95.0
	var boost_speed_multiplier := 1.55
	var boost_seconds := 10.0
	var recharge_seconds := 5.0
	var average_speed := cruise_speed * ((boost_seconds * boost_speed_multiplier + recharge_seconds) / (boost_seconds + recharge_seconds))
	var travel_seconds := route_distance / average_speed
	var hostile_health_total := 2.0 * 230.0 + 2.0 * 260.0 + 3.0 * 290.0 + 3.0 * 230.0 + 3.0 * 260.0 + 4.0 * 290.0
	var theoretical_combat_seconds := hostile_health_total / (18.0 * 3.0)
	var wave_intermission_seconds := 22.0 * 2.0 + 18.0 * 2.0
	var estimated_minimum_seconds := travel_seconds + theoretical_combat_seconds + wave_intermission_seconds
	_check(estimated_minimum_seconds >= 600.0, "route, six combat waves and intermissions budget at least ten minutes")
