extends Node
## Deterministic visual-QA pilot. Uses the real flight controller, weapons and enemy AI.

@onready var world: Node3D = get_parent()
@onready var mission: Node = world.get_node("DemoMissionDirector")
@onready var player: ShipController = world.get_node("PlayerShip") as ShipController
@onready var targeting: TargetingSystem = player.get_node("TargetingSystem") as TargetingSystem
@onready var camera_rig: CameraRig = player.get_node("CameraRig") as CameraRig


func _ready() -> void:
	var player_model := player.find_child("PlayerFighterModel", true, false)
	print("SHOWCASE_PLAYER_MODEL_MESHES=", _count_meshes(player_model))
	print("SHOWCASE_READY")
	call_deferred("_run_showcase")


func _run_showcase() -> void:
	await get_tree().create_timer(0.5).timeout
	await _capture_screenshot("gameplay-01.png")
	var travel_elapsed := 0.0
	while mission.stage == 0 and travel_elapsed < 9.0:
		player.look_at(mission._objective_position, Vector3.UP)
		Input.action_press("move_forward")
		Input.action_press("boost")
		await get_tree().create_timer(0.05).timeout
		travel_elapsed += 0.05
	Input.action_release("boost")
	Input.action_release("move_forward")

	# Guarantee the showcase reaches the real encounter instead of producing
	# eight screenshots of an empty outbound flight when acceleration varies
	# between CI renderers. The mission's own stage transition and encounter
	# spawning still run through DemoMissionDirector.
	if mission.stage == 0:
		player.global_position = mission._objective_position + Vector3(0.0, 0.0, 75.0)
		await get_tree().create_timer(0.2).timeout
	if mission.stage == 1:
		mission._complete_relay_scan()
	await get_tree().create_timer(0.4).timeout
	await _capture_screenshot("gameplay-02.png")

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
		# Bring one hostile into a readable showcase range; normal mission spawn
		# distances and combat behavior remain unchanged outside this QA scene.
		acquired.global_position = player.global_position + (-player.global_basis.z * 34.0) + Vector3.UP * 2.0
		targeting.set_target(acquired)
	print("SHOWCASE_TARGET_ACQUIRED=", acquired != null)
	if acquired != null:
		var enemy_model := acquired.find_child("RaiderInterceptorModel", true, false)
		print("SHOWCASE_ENEMY_MODEL_MESHES=", _count_meshes(enemy_model))
	await _capture_screenshot("gameplay-03.png")
	if acquired == null:
		push_error("SHOWCASE failed: no combat target was acquired")
		return
	await _engage_for(1.5)
	await _capture_screenshot("gameplay-04.png")
	await _engage_for(2.0)

	camera_rig.toggle_camera()
	await get_tree().create_timer(0.8).timeout
	await _capture_screenshot("gameplay-05.png")
	await get_tree().create_timer(1.2).timeout
	camera_rig.toggle_camera()
	await _engage_for(1.0)
	await _capture_screenshot("gameplay-06.png")
	await _engage_for(1.0)
	await _capture_screenshot("gameplay-07.png")

	Input.action_release("fire_primary")
	Input.action_release("move_forward")
	Input.action_release("boost")
	await _capture_screenshot("gameplay-08.png")
	print("SHOWCASE_SEQUENCE_COMPLETE stage=", mission.stage)


func _capture_screenshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(filename)
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("SHOWCASE screenshot failed: %s (error %d)" % [filename, error])
		return
	print("SHOWCASE_SCREENSHOT=", path)


func _count_meshes(root_node: Node) -> int:
	if root_node == null:
		return 0
	var count := 0
	if root_node is MeshInstance3D and (root_node as MeshInstance3D).mesh != null:
		count += 1
	for child in root_node.get_children():
		count += _count_meshes(child)
	return count


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
			# Lock the selected target directly; camera follow interpolation can
			# make cone-based reacquisition miss during automated capture.
			targeting.set_target(best_target)
			Input.action_press("fire_primary")
		else:
			Input.action_release("fire_primary")
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
