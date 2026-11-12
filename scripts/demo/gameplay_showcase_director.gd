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
		# Bring the first hostile into a cinematic but still playable engagement range
		# so the automated QA captures can verify silhouettes and weapon effects.
		var engagement_direction := -player.global_transform.basis.z
		acquired.global_position = player.global_position + engagement_direction * 38.0 + player.global_transform.basis.x * 7.0
		acquired.look_at(player.global_position, Vector3.UP)
		targeting.set_target(acquired)
	print("SHOWCASE_TARGET_ACQUIRED=", acquired != null)
	if acquired == null:
		push_error("SHOWCASE failed: no combat target was acquired")
		return
	await _engage_for(4.0)
	Input.action_release("fire_primary")

	camera_rig.toggle_camera()
	await get_tree().create_timer(4.5).timeout
	camera_rig.toggle_camera()
	await _engage_for(2.0)

	Input.action_release("fire_primary")
	Input.action_release("move_forward")
	Input.action_release("boost")
	print("SHOWCASE_SEQUENCE_COMPLETE stage=", mission.stage)


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
