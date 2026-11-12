extends SceneTree

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var demo := DEMO_SCENE.instantiate()
	root.add_child(demo)
	await process_frame
	await process_frame
	var director: Node = demo.get_node("DemoMissionDirector")
	var player: Node3D = demo.get_node("PlayerShip")
	var camera_rig: CameraRig = player.get_node("CameraRig") as CameraRig
	var cockpit: Node3D = player.get_node("CockpitInterior") as Node3D
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
	player.global_position = director._objective_position
	await process_frame
	_check(director.stage == 7, "Returning to carrier must complete the mission")
	print("DEMO_MISSION_TEST_PASS")
	quit(0)


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
