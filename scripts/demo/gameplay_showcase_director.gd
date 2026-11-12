extends Node
## Deterministic visual-QA pilot. Uses the real flight controller, weapons and enemy AI.

@onready var world: Node3D = get_parent()
@onready var mission: Node = world.get_node("DemoMissionDirector")
@onready var player: ShipController = world.get_node("PlayerShip") as ShipController
@onready var targeting: TargetingSystem = player.get_node("TargetingSystem") as TargetingSystem
@onready var camera_rig: CameraRig = player.get_node("CameraRig") as CameraRig


func _ready() -> void:
	print("SHOWCASE_READY")
	call_deferred("_run_showcase")


func _run_showcase() -> void:
	await get_tree().create_timer(0.5).timeout
	var player_model := player.get_node_or_null("Visual/PlayerFighterModel")
	var player_mesh_count := _count_visible_meshes(player_model)
	print("SHOWCASE_PLAYER_MODEL_MESHES=", player_mesh_count)
	if player_mesh_count == 0:
		push_error("SHOWCASE failed: player GLB has no visible mesh instances")
		get_tree().quit(1)
		return
	await _capture_screenshot("01-flight-start.png")

	var travel_elapsed := 0.0
	while mission.stage == 0 and travel_elapsed < 9.0:
		player.look_at(mission._objective_position, Vector3.UP)
		Input.action_press("move_forward")
		Input.action_press("boost")
		await get_tree().create_timer(0.05).timeout
		travel_elapsed += 0.05
	Input.action_release("boost")
	Input.action_release("move_forward")
	await get_tree().create_timer(0.4).timeout
	await _capture_screenshot("02-relay-approach.png")
	if mission.stage == 0:
		player.global_position = mission._objective_position + Vector3(0.0, 0.0, 75.0)
		await get_tree().create_timer(0.2).timeout
	if mission.stage == 1:
		mission._complete_relay_scan()
	await get_tree().create_timer(0.4).timeout
	var enemy_mesh_count := 0
	for candidate in get_tree().get_nodes_in_group("combat_targets"):
		if candidate is Node3D:
			enemy_mesh_count += _count_visible_meshes(candidate.get_node_or_null("Visual/RaiderInterceptorModel"))
	print("SHOWCASE_ENEMY_MODEL_MESHES=", enemy_mesh_count)
	if enemy_mesh_count == 0:
		push_error("SHOWCASE failed: enemy GLB has no visible mesh instances")
		get_tree().quit(1)
		return
	await _capture_screenshot("03-hostiles-arrive.png")

	var acquired: Node3D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("combat_targets"):
		if not (candidate is Node3D):
			continue
		var target := candidate as Node3D
		if not is_instance_valid(target) or not target.is_inside_tree():
			continue
		var distance := player.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			acquired = target
	if acquired != null:
		targeting.set_target(acquired)
	print("SHOWCASE_TARGET_ACQUIRED=", acquired != null)
	if acquired == null:
		push_error("SHOWCASE failed: no combat target was acquired")
		get_tree().quit(1)
		return
	await _engage_for(4.0)
	await _capture_screenshot("04-combat-targeting.png")

	camera_rig.toggle_camera()
	await get_tree().create_timer(2.0).timeout
	await _capture_screenshot("05-cockpit-view.png")
	camera_rig.toggle_camera()
	await _engage_for(2.0)
	await _capture_screenshot("06-chase-combat.png")

	Input.action_release("fire_primary")
	Input.action_release("move_forward")
	Input.action_release("boost")
	await get_tree().process_frame
	await _capture_screenshot("07-mission-hud.png")
	await get_tree().create_timer(0.25).timeout
	await _capture_screenshot("08-final-frame.png")
	print("SHOWCASE_SEQUENCE_COMPLETE stage=", mission.stage)
	get_tree().quit(0)


func _capture_screenshot(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("user://screenshots")
	var make_dir_error := DirAccess.make_dir_recursive_absolute(directory)
	if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
		push_error("Could not create screenshot directory: " + str(make_dir_error))
		return
	var image := get_viewport().get_texture().get_image()
	var output_path := directory.path_join(file_name)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("Could not save screenshot %s: %s" % [file_name, save_error])
		return
	print("SHOWCASE_SCREENSHOT=", output_path)


func _engage_for(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var best_target: Node3D
		var best_distance := INF
		for candidate in get_tree().get_nodes_in_group("combat_targets"):
			if not (candidate is Node3D):
				continue
			var target := candidate as Node3D
			if not is_instance_valid(target) or not target.is_inside_tree():
				continue
			var distance := player.global_position.distance_to(target.global_position)
			if distance < best_distance:
				best_distance = distance
				best_target = target
		if best_target != null:
			player.look_at(best_target.global_position, Vector3.UP)
			targeting.set_target(best_target)
			Input.action_press("fire_primary")
		else:
			Input.action_release("fire_primary")
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05


func _count_visible_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is MeshInstance3D and (node as MeshInstance3D).visible and (node as MeshInstance3D).mesh != null:
		count += 1
	for child in node.get_children():
		count += _count_visible_meshes(child)
	return count
