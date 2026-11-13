extends Node
## Deterministic visual-QA pilot. Drives the real mission state machine and combat actors.

@onready var world: Node3D = get_parent()
@onready var mission: Node = world.get_node("DemoMissionDirector")
@onready var player: ShipController = world.get_node("PlayerShip") as ShipController
@onready var targeting: TargetingSystem = player.get_node("TargetingSystem") as TargetingSystem
@onready var camera_rig: CameraRig = player.get_node("CameraRig") as CameraRig

const STAGE_OUTBOUND := 0
const STAGE_SCAN_RELAY := 1
const STAGE_DEFEND_RELAY := 2
const STAGE_INVESTIGATE_WRECK := 3
const STAGE_SCAN_WRECK := 4
const STAGE_DEFEND_WRECK := 5
const STAGE_RETURN_HOME := 6
const STAGE_COMPLETE := 7


func _ready() -> void:
	add_to_group("qa_demo_driver")
	print("SHOWCASE_PLAYER_MODEL_MESHES=", _count_meshes(player))
	print("SHOWCASE_READY")
	call_deferred("_run_showcase")


func _run_showcase() -> void:
	await get_tree().create_timer(0.5).timeout
	var original_chase_fov := camera_rig.chase_camera.fov
	var original_chase_position := camera_rig.chase_camera.position
	var original_chase_rotation := camera_rig.chase_camera.rotation_degrees
	camera_rig.chase_camera.position = Vector3(0.0, 3.0, 9.5)
	camera_rig.chase_camera.rotation_degrees = Vector3(-17.0, 0.0, 0.0)
	camera_rig.chase_camera.fov = 58.0
	await _capture_screenshot("gameplay-01.png")

	# Move into the relay scan radius. The actual mission director performs
	# the OUTBOUND -> SCAN_RELAY transition on its normal process tick.
	await _move_to_objective(75.0)
	if int(mission.stage) != STAGE_SCAN_RELAY:
		push_error("SHOWCASE failed: relay approach did not enter scan stage; stage=%s" % mission.stage)
		return
	print("SHOWCASE_PHASE=RELAY_APPROACH")
	await _capture_screenshot("gameplay-02.png")
	mission._complete_relay_scan()
	await get_tree().create_timer(0.25).timeout

	var relay_target := _place_nearest_target_for_camera()
	print("SHOWCASE_TARGET_ACQUIRED=", relay_target != null)
	if relay_target == null:
		push_error("SHOWCASE failed: relay defense did not spawn a combat target")
		return
	print("SHOWCASE_ENEMY_MODEL_MESHES=", _count_meshes(relay_target))
	print("SHOWCASE_PHASE=RELAY_COMBAT")
	await _capture_screenshot("gameplay-03.png")
	await _engage_for(1.0)
	await _capture_screenshot("gameplay-04.png")
	camera_rig.toggle_camera()
	await get_tree().create_timer(0.35).timeout
	await _capture_screenshot("gameplay-05.png")
	camera_rig.toggle_camera()

	# Resolve the three relay waves through the real Damageable.destroyed
	# signal path, accelerating only the inter-wave wait for this QA scene.
	var relay_waves_cleared: bool = await _clear_defense_waves(STAGE_DEFEND_RELAY)
	if not relay_waves_cleared:
		return
	if int(mission.stage) != STAGE_INVESTIGATE_WRECK:
		push_error("SHOWCASE failed: relay defense did not advance to wreck; stage=%s" % mission.stage)
		return

	await _move_to_objective(80.0)
	if int(mission.stage) != STAGE_SCAN_WRECK:
		push_error("SHOWCASE failed: wreck approach did not enter scan stage; stage=%s" % mission.stage)
		return
	print("SHOWCASE_PHASE=WRECK_INVESTIGATION")
	await _capture_screenshot("gameplay-06.png")
	mission._complete_wreck_scan()
	await get_tree().create_timer(0.25).timeout
	var wreck_target := _place_nearest_target_for_camera()
	if wreck_target == null:
		push_error("SHOWCASE failed: wreck defense did not spawn a combat target")
		return
	print("SHOWCASE_PHASE=WRECK_COMBAT")
	await _engage_for(1.0)
	await _capture_screenshot("gameplay-07.png")

	var wreck_waves_cleared: bool = await _clear_defense_waves(STAGE_DEFEND_WRECK)
	if not wreck_waves_cleared:
		return
	if int(mission.stage) != STAGE_RETURN_HOME:
		push_error("SHOWCASE failed: wreck defense did not advance to return; stage=%s" % mission.stage)
		return

	await _move_to_objective(80.0)
	if int(mission.stage) != STAGE_COMPLETE:
		push_error("SHOWCASE failed: return did not complete mission; stage=%s" % mission.stage)
		return
	print("SHOWCASE_PHASE=MISSION_COMPLETE")
	Input.action_release("fire_primary")
	Input.action_release("move_forward")
	Input.action_release("boost")
	camera_rig.chase_camera.fov = original_chase_fov
	camera_rig.chase_camera.position = original_chase_position
	camera_rig.chase_camera.rotation_degrees = original_chase_rotation
	await get_tree().create_timer(0.25).timeout
	await _capture_screenshot("gameplay-08.png")

	# Capture the actual carrier maintenance UI as a separate visual QA frame.
	# This is a presentation-only snapshot; pilot credits are restored immediately.
	var profile := get_node_or_null("/root/GameProfile")
	if profile != null:
		var original_credits := int(profile.call("get_credits"))
		profile.set("credits", maxi(original_credits, 10000))
		var damageable := player.get_node_or_null("Damageable") as Damageable
		if damageable != null:
			damageable.current_hull = damageable.max_hull * 0.62
			damageable.current_shield = damageable.max_shield * 0.35
		player.boost_amount = player.flight_config.boost_capacity * 0.2
		mission._build_docking_services()
		await get_tree().create_timer(0.25).timeout
		await _capture_screenshot("carrier-services.png")
		if is_instance_valid(mission._service_layer):
			mission._service_layer.queue_free()
		profile.set("credits", original_credits)
		var original_completed: Array[String] = profile.completed_mission_ids.duplicate()
		var original_active_contract: String = profile.active_contract_id
		profile.completed_mission_ids.clear()
		profile.completed_mission_ids.append("silent_relay")
		profile.completed_mission_ids.append("vesper_salvage")
		profile.active_contract_id = "kestrel_patrol"
		profile.call("_save_profile")
		var contract_board: Control = load("res://scenes/ui/contract_board.tscn").instantiate() as Control
		get_tree().root.add_child(contract_board)
		await get_tree().process_frame
		await get_tree().create_timer(0.25).timeout
		await _capture_screenshot("contract-board.png")
		contract_board.queue_free()
		await get_tree().process_frame
		profile.completed_mission_ids.clear()
		for mission_id in original_completed:
			profile.completed_mission_ids.append(str(mission_id))
		profile.active_contract_id = original_active_contract
		profile.call("_save_profile")
	print("SHOWCASE_SEQUENCE_COMPLETE stage=", mission.stage)


func _move_to_objective(distance: float) -> void:
	player.global_position = mission._objective_position + Vector3(0.0, 0.0, distance)
	player.look_at(mission._objective_position, Vector3.UP)
	await get_tree().create_timer(0.2).timeout


func _place_nearest_target_for_camera() -> Node3D:
	var nearest: Node3D
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
			nearest = target
	if nearest != null:
		nearest.global_position = player.global_position + (-player.global_basis.z * 16.0) + Vector3.UP * 3.0
		camera_rig.chase_camera.fov = 54.0
		targeting.set_target(nearest)
	return nearest


func _clear_defense_waves(expected_stage: int) -> bool:
	var waves_resolved := 0
	while int(mission.stage) == expected_stage and waves_resolved < 3:
		var targets := get_tree().get_nodes_in_group("combat_targets")
		if targets.is_empty():
			await get_tree().create_timer(0.1).timeout
			targets = get_tree().get_nodes_in_group("combat_targets")
		if targets.is_empty():
			push_error("SHOWCASE failed: no targets during defense wave %d" % (waves_resolved + 1))
			return false
		for candidate in targets:
			if not (candidate is Node3D):
				continue
			var damageable := candidate.get_node_or_null("Damageable") as Damageable
			if damageable != null and not damageable.is_destroyed():
				damageable.take_damage(1000000.0)
		await get_tree().create_timer(0.2).timeout
		waves_resolved += 1
		if int(mission.stage) == expected_stage and mission._next_wave_timer >= 0.0:
			mission._next_wave_timer = 0.01
			await get_tree().create_timer(0.2).timeout
	if int(mission.stage) != expected_stage:
		print("SHOWCASE_WAVES_RESOLVED=", waves_resolved, " next_stage=", mission.stage)
		return true
	push_error("SHOWCASE failed: defense stage did not finish after %d waves" % waves_resolved)
	return false


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
			targeting.set_target(best_target)
			Input.action_press("fire_primary")
		else:
			Input.action_release("fire_primary")
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
