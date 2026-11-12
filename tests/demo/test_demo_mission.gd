extends Node

const DEMO_SCENE: PackedScene = preload("res://scenes/demo/ten_minute_demo.tscn")
var _finished := false


func _ready() -> void:
	call_deferred("_watchdog")
	call_deferred("_run_test")


func _watchdog() -> void:
	await get_tree().create_timer(120.0).timeout
	if not _finished:
		push_error("DEMO_MISSION_TEST_TIMEOUT: progression did not finish within 120 seconds")
		get_tree().quit(1)


func _run_test() -> void:
	var demo := DEMO_SCENE.instantiate()
	get_tree().root.add_child(demo)
	await get_tree().process_frame
	await get_tree().process_frame
	var director: Node = demo.get_node("DemoMissionDirector")
	var player: Node3D = demo.get_node("PlayerShip")
	var camera_rig: CameraRig = player.get_node("CameraRig") as CameraRig
	var cockpit: Node3D = player.get_node("CockpitInterior") as Node3D
	_check(cockpit != null and not cockpit.visible, "Cockpit interior must start hidden in chase-camera mode")
	camera_rig.toggle_camera()
	_check(cockpit.visible and not player.get_node("Visual").visible, "Cockpit mode must show the cockpit and hide the exterior ship")
	camera_rig.toggle_camera()
	_check(not cockpit.visible and player.get_node("Visual").visible, "Chase mode must restore the exterior ship")
	print("DEMO_TEST_CHECKPOINT stage=", director.stage, " phase=initialization")
	_check(director.stage == 0, "Mission must start at outbound navigation")
	_check(get_tree().get_nodes_in_group("combat_targets").is_empty(), "Demo must not start the legacy automatic encounter")

	player.global_position = Vector3(0.0, 18.0, -720.0)
	await get_tree().process_frame
	_check(director.stage == 1, "Entering relay range must activate the scan objective")
	director._complete_relay_scan()
	_check(director.stage == 2, "Relay scan must start the first defense sequence")
	await _clear_three_waves(director)
	print("DEMO_TEST_CHECKPOINT stage=", director.stage, " phase=relay-defense")

	_check(director.stage == 3, "Three relay waves must unlock wreck investigation")
	player.global_position = Vector3(210.0, -28.0, -1420.0)
	await get_tree().process_frame
	_check(director.stage == 4, "Entering wreck range must activate the data scan")
	director._complete_wreck_scan()
	_check(director.stage == 5, "Wreck scan must start the second defense sequence")
	await _clear_three_waves(director)
	print("DEMO_TEST_CHECKPOINT stage=", director.stage, " phase=wreck-defense")

	_check(director.stage == 6, "Six waves must unlock return to carrier")
	player.global_position = Vector3(0.0, 0.0, 90.0)
	await get_tree().process_frame
	_check(director.stage == 7, "Returning to carrier must complete the mission")
	_finished = true
	print("DEMO_MISSION_TEST_PASS")
	get_tree().quit(0)


func _clear_three_waves(director: Node) -> void:
	for wave in range(3):
		var enemies := get_tree().get_nodes_in_group("combat_targets")
		_check(not enemies.is_empty(), "Each defense wave must spawn hostile fighters")
		for enemy in enemies:
			var damageable := enemy.get_node_or_null("Damageable")
			_check(damageable != null, "Every hostile must have a Damageable component")
			damageable.take_damage(100000.0)
		await get_tree().process_frame
		if wave < 2:
			director._next_wave_timer = 0.0
			await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_finished = true
	push_error("DEMO_MISSION_TEST_FAIL: " + message)
	get_tree().quit(1)
