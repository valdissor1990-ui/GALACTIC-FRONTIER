extends SceneTree
## Captures the actual primitive-based flight test scene, not the separate mission showcase.

const SCENE_PATH := "res://scenes/flight/test_flight.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("TEST_FLIGHT_VISUAL_QA: cannot load " + SCENE_PATH)
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await create_timer(0.8).timeout
	var output_dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(output_dir)

	await _capture(scene, "test-flight-chase.png")
	var camera_rig := scene.get_node("PlayerShip/CameraRig") as CameraRig
	camera_rig.toggle_camera()
	await create_timer(0.5).timeout
	await _capture(scene, "test-flight-cockpit.png")
	camera_rig.toggle_camera()
	await create_timer(0.5).timeout

	var encounter := scene.get_node("CombatEncounterController") as CombatEncounterController
	if not encounter.has_active_enemy():
		push_error("TEST_FLIGHT_VISUAL_QA: combat encounter did not spawn its enemy")
		quit(1)
		return
	var enemy := encounter.get("_current_enemy") as Node3D
	var player := scene.get_node("PlayerShip") as ShipController
	var targeting := player.get_node("TargetingSystem") as TargetingSystem
	if enemy != null:
		enemy.global_position = player.global_position + Vector3(0.0, 0.5, -32.0)
		enemy.look_at(player.global_position, Vector3.UP)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		targeting.set_target(enemy)
	await create_timer(0.35).timeout
	Input.action_press("fire_primary")
	await create_timer(0.2).timeout
	Input.action_release("fire_primary")
	await _capture(scene, "test-flight-combat.png")
	print("TEST_FLIGHT_VISUAL_QA_COMPLETE cameras=2 combat_enemy=true resolution=", get_root().size)
	quit(0)


func _capture(_scene: Node, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://screenshots").path_join(filename)
	var error := image.save_png(path)
	if error != OK:
		push_error("TEST_FLIGHT_VISUAL_QA: screenshot save failed: %s error=%d" % [filename, error])
		quit(1)
		return
	print("TEST_FLIGHT_SCREENSHOT=", path)
