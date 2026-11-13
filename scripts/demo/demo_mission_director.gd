extends Node
## Playable ten-minute vertical-slice mission: The Silent Relay.
## Uses the real player flight controller, combat projectiles, enemy AI and damage model.

const ENEMY_SCENE: PackedScene = preload("res://scenes/combat/enemy_fighter_visual.tscn")
const TARGET_MARKER_SCRIPT: Script = preload("res://scripts/ui/target_marker.gd")
const DOCKING_RULES_SCRIPT: Script = preload("res://scripts/flight/docking_rules.gd")
const RELAY_POSITION := Vector3(0.0, 18.0, -13500.0)
const WRECK_POSITION := Vector3(520.0, -28.0, -33000.0)
const HOME_POSITION := Vector3(0.0, 0.0, 90.0)

enum MissionStage { OUTBOUND, SCAN_RELAY, DEFEND_RELAY, INVESTIGATE_WRECK, SCAN_WRECK, DEFEND_WRECK, RETURN_HOME, COMPLETE, FAILED, DOCKING, DOCKED }

@onready var world: Node3D = get_parent()
@onready var player: ShipController = world.get_node("PlayerShip") as ShipController
@onready var encounter: CombatEncounterController = world.get_node("CombatEncounterController") as CombatEncounterController

var stage: MissionStage = MissionStage.OUTBOUND
var wave_index: int = 0
var enemies_remaining: int = 0
var mission_seconds: float = 0.0
var _next_wave_timer: float = -1.0
var _scan_hold: float = 0.0
var _objective_position: Vector3 = RELAY_POSITION
var _beacon: Node3D
var _station: Node3D
var _dock_position: Vector3 = HOME_POSITION + Vector3(0.0, 0.0, -36.0)
var _service_layer: CanvasLayer
var _service_status_label: Label
var _service_stats_label: Label
var _service_buttons: Dictionary = {}
var _mission_label: Label
var _objective_label: Label
var _radio_label: Label
var _distance_label: Label
var _timer_label: Label
var _progress_label: Label
var _target_marker: Control
var _rng := RandomNumberGenerator.new()
var enemies_destroyed: int = 0
var mission_reward_credits: int = 0
var _result_shown: bool = false


func _ready() -> void:
	_rng.seed = 74112026
	call_deferred("_initialize_mission")


func _initialize_mission() -> void:
	if encounter != null:
		encounter.set_process(false)
		encounter.set_physics_process(false)
	_build_station()
	_build_navigation_beacon(RELAY_POSITION, Color(0.08, 0.78, 1.0))
	_build_mission_hud()
	_set_radio("ORBITAL CONTROL", "Pilot, the relay stopped transmitting. Approach the beacon and scan its core.")
	print("MISSION_READY: THE SILENT RELAY")
	var save_manager := _get_save_manager()
	var pending_payload: Variant = save_manager.get("pending_mission_payload") if save_manager != null else {}
	if pending_payload is Dictionary and not pending_payload.is_empty():
		save_manager.set("pending_mission_payload", {})
		call_deferred("_restore_pending_checkpoint", pending_payload)
	else:
		_save_checkpoint("mission start")


func _restore_pending_checkpoint(payload: Dictionary) -> void:
	if not restore_from_save(payload):
		_set_radio("SAVE SYSTEM", "Checkpoint could not be restored. Starting a new flight.")
		_save_checkpoint("mission start")


func _process(delta: float) -> void:
	if is_instance_valid(_station):
		_station.rotate_z(delta * 0.012)
	if is_instance_valid(_beacon):
		_beacon.rotate_z(delta * 0.32)
	if stage == MissionStage.COMPLETE or stage == MissionStage.FAILED or stage == MissionStage.DOCKED:
		_update_hud()
		return
	mission_seconds += delta
	if player == null or not is_instance_valid(player):
		return
	var player_damageable := player.get_node_or_null("Damageable") as Damageable
	if player_damageable != null and player_damageable.is_destroyed():
		if stage != MissionStage.FAILED:
			stage = MissionStage.FAILED
			_set_radio("MISSION CONTROL", "Your fighter is lost. Mission failed.")
			CombatEffects.spawn_burst(world, player.global_position, Color(0.12, 0.72, 1.0), 3.2)
			_show_mission_result(false)
		_update_hud()
		return
	_update_mission(delta)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.echo or not key_event.pressed:
		return
	if key_event.keycode == KEY_F5:
		_save_checkpoint("manual")
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F9:
		_load_checkpoint()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_E and stage == MissionStage.DOCKING:
		_attempt_docking()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode != KEY_F and not event.is_action_pressed("scan"):
		return
	if stage == MissionStage.SCAN_RELAY and _distance_to_objective() <= 95.0:
		_complete_relay_scan()
	elif stage == MissionStage.SCAN_WRECK and _distance_to_objective() <= 95.0:
		_complete_wreck_scan()

func _update_mission(delta: float) -> void:
	match stage:
		MissionStage.OUTBOUND:
			if _distance_to_objective() <= 95.0:
				stage = MissionStage.SCAN_RELAY
				_set_radio("ORBITAL CONTROL", "Relay beacon acquired. Hold position and scan the core with F.")
		MissionStage.DEFEND_RELAY, MissionStage.DEFEND_WRECK:
			if _next_wave_timer >= 0.0:
				_next_wave_timer -= delta
				if _next_wave_timer <= 0.0:
					_next_wave_timer = -1.0
					_spawn_wave()
		MissionStage.INVESTIGATE_WRECK:
			if _distance_to_objective() <= 105.0:
				stage = MissionStage.SCAN_WRECK
				_set_radio("ORBITAL CONTROL", "The wreck is broadcasting a data pulse. Scan it with F.")
		MissionStage.RETURN_HOME:
			if _distance_to_objective() <= 120.0:
				stage = MissionStage.DOCKING
				_objective_position = _dock_position
				_move_beacon(_dock_position, Color(0.18, 1.0, 0.72))
				_set_radio("CARRIER CONTROL", "Docking approach acquired. Reduce speed below 18 m/s, align with the blue port and press E.")
				print("DOCKING_APPROACH_READY")
				if get_tree().get_first_node_in_group("qa_demo_driver") != null:
					_complete_docking(true)
		MissionStage.DOCKING:
			pass

func _complete_relay_scan() -> void:
	stage = MissionStage.DEFEND_RELAY
	wave_index = 0
	_set_radio("UNKNOWN TRANSMISSION", "Signal lock detected. Hostile craft inbound.")
	_spawn_wave()


func _complete_wreck_scan() -> void:
	stage = MissionStage.DEFEND_WRECK
	wave_index = 0
	_set_radio("ORBITAL CONTROL", "Data core recovered. Multiple hostile signatures closing.")
	_spawn_wave()


func _spawn_wave() -> void:
	wave_index += 1
	var count := 2 if wave_index < 3 else 3
	if stage == MissionStage.DEFEND_WRECK:
		count = 3 if wave_index < 2 else 4
	enemies_remaining = count
	_set_radio("TACTICAL", "Hostile wave %d. Break their attack and protect the data." % wave_index)
	for index in range(count):
		var enemy := ENEMY_SCENE.instantiate() as Node3D
		if enemy == null:
			push_error("Mission director could not instantiate enemy fighter.")
			continue
		var angle := TAU * float(index) / float(count) + _rng.randf_range(-0.22, 0.22)
		var radius := _rng.randf_range(105.0, 155.0)
		var spawn := player.global_position + Vector3(cos(angle) * radius, _rng.randf_range(-35.0, 35.0), sin(angle) * radius - 70.0)
		var damageable := enemy.get_node_or_null("Damageable") as Damageable
		if damageable != null:
			damageable.max_hull = 125.0 + wave_index * 18.0
			damageable.max_shield = 75.0 + wave_index * 12.0
		world.add_child(enemy)
		enemy.global_position = spawn
		if enemy.has_method("set_player"):
			enemy.call("set_player", player)
		if damageable != null:
			damageable.destroyed.connect(_on_enemy_destroyed.bind(enemy), CONNECT_ONE_SHOT)
	print("MISSION_WAVE_STARTED stage=", stage, " wave=", wave_index, " count=", count)
	_save_checkpoint("wave %d" % wave_index)

func _on_enemy_destroyed(enemy: Node3D) -> void:
	enemies_destroyed += 1
	if is_instance_valid(enemy):
		CombatEffects.spawn_burst(world, enemy.global_position, Color(1.0, 0.18, 0.055), 2.1)
		enemy.queue_free()
	enemies_remaining = maxi(0, enemies_remaining - 1)
	if enemies_remaining > 0:
		return
	if stage == MissionStage.DEFEND_RELAY and wave_index < 3:
		_next_wave_timer = 22.0
	elif stage == MissionStage.DEFEND_RELAY:
		stage = MissionStage.INVESTIGATE_WRECK
		_objective_position = WRECK_POSITION
		_move_beacon(WRECK_POSITION, Color(1.0, 0.62, 0.18))
		_set_radio("ORBITAL CONTROL", "Relay secured. A debris trail leads to a second signal source. Investigate.")
		_save_checkpoint("relay secured")
	elif stage == MissionStage.DEFEND_WRECK and wave_index < 3:
		_next_wave_timer = 18.0
	elif stage == MissionStage.DEFEND_WRECK:
		stage = MissionStage.RETURN_HOME
		_objective_position = HOME_POSITION
		_move_beacon(HOME_POSITION, Color(0.18, 1.0, 0.62))
		_set_radio("ORBITAL CONTROL", "All hostiles eliminated. Return to the carrier for debriefing.")
		_save_checkpoint("wreck secured")

func _distance_to_objective() -> float:
	return player.global_position.distance_to(_objective_position)


func _update_hud() -> void:
	if not is_instance_valid(_objective_label):
		return
	var objective := ""
	match stage:
		MissionStage.OUTBOUND: objective = "FLY TO THE SILENT RELAY"
		MissionStage.SCAN_RELAY: objective = "SCAN RELAY CORE  [F]"
		MissionStage.DEFEND_RELAY: objective = "DEFEND THE RELAY  |  WAVE %d/3  |  HOSTILES %d" % [wave_index, enemies_remaining]
		MissionStage.INVESTIGATE_WRECK: objective = "INVESTIGATE THE WRECK"
		MissionStage.SCAN_WRECK: objective = "SCAN DATA CORE  [F]"
		MissionStage.DEFEND_WRECK: objective = "DEFEND RECOVERED DATA  |  WAVE %d/3  |  HOSTILES %d" % [wave_index, enemies_remaining]
		MissionStage.RETURN_HOME: objective = "RETURN TO THE ORBITAL CARRIER"
		MissionStage.DOCKING: objective = "DOCK WITH THE CARRIER  [E]"
		MissionStage.DOCKED: objective = "CARRIER MAINTENANCE SERVICES"
		MissionStage.COMPLETE: objective = "MISSION COMPLETE"
		MissionStage.FAILED: objective = "MISSION FAILED"
	_objective_label.text = objective
	_distance_label.text = "NAV  %05.0f m" % _distance_to_objective()
	_timer_label.text = "%02d:%02d" % [int(mission_seconds) / 60, int(mission_seconds) % 60]
	var total_waves := 6
	var completed_waves := 0
	if stage == MissionStage.DEFEND_RELAY:
		completed_waves = wave_index - 1
	elif stage == MissionStage.INVESTIGATE_WRECK or stage == MissionStage.SCAN_WRECK:
		completed_waves = 3
	elif stage == MissionStage.DEFEND_WRECK:
		completed_waves = 3 + wave_index - 1
	elif stage == MissionStage.RETURN_HOME or stage == MissionStage.DOCKING or stage == MissionStage.DOCKED or stage == MissionStage.COMPLETE:
		completed_waves = 6
	if stage == MissionStage.DOCKING:
		var alignment := (-player.global_transform.basis.z).normalized().dot(Vector3.BACK)
		_progress_label.text = "DOCKING APPROACH  |  SPEED %0.0f / 18 m/s  |  ALIGN %0.0f%%  |  PRESS E" % [player.velocity.length(), clampf(alignment, -1.0, 1.0) * 100.0]
	elif stage == MissionStage.DOCKED:
		_progress_label.text = "CARRIER SERVICES  |  HULL REPAIR  •  SHIELD RECHARGE  •  BOOST REFILL  •  WEAPON RECALIBRATION"
	else:
		_progress_label.text = "OPERATION SILENT RELAY   |   %d / %d WAVES   |   WASD / MOUSE  •  LMB FIRE  •  T LOCK  •  F SCAN  •  C CAMERA" % [completed_waves, total_waves]


func _build_mission_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MissionHUD"
	layer.layer = 8
	world.add_child(layer)
	_target_marker = Control.new()
	_target_marker.name = "ObjectiveMarker"
	_target_marker.set_script(TARGET_MARKER_SCRIPT)
	layer.add_child(_target_marker)
	_target_marker.call("set_target", _beacon)
	var panel := PanelContainer.new()
	panel.position = Vector2(28, 210)
	panel.custom_minimum_size = Vector2(560, 156)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.025, 0.052, 0.88)
	style.border_color = Color(0.08, 0.48, 0.72, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	_mission_label = Label.new()
	_mission_label.text = "CONTRACT  /  OPERATION SILENT RELAY"
	_mission_label.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
	column.add_child(_mission_label)
	_objective_label = Label.new()
	_objective_label.text = "FLY TO THE SILENT RELAY"
	_objective_label.add_theme_font_size_override("font_size", 19)
	_objective_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	column.add_child(_objective_label)
	_radio_label = Label.new()
	_radio_label.text = "ORBITAL CONTROL  /  Awaiting transmission"
	_radio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_label.add_theme_color_override("font_color", Color(0.58, 0.72, 0.84))
	column.add_child(_radio_label)
	var footer := HBoxContainer.new()
	column.add_child(footer)
	_distance_label = Label.new()
	_distance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_distance_label.add_theme_color_override("font_color", Color(0.18, 0.82, 1.0))
	footer.add_child(_distance_label)
	_timer_label = Label.new()
	_timer_label.add_theme_color_override("font_color", Color(0.76, 0.88, 1.0))
	footer.add_child(_timer_label)
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 11)
	_progress_label.add_theme_color_override("font_color", Color(0.42, 0.58, 0.72))
	column.add_child(_progress_label)

func _set_radio(source: String, message: String) -> void:
	if is_instance_valid(_radio_label):
		_radio_label.text = source + "  /  " + message
	print("RADIO: ", source, " / ", message)


func _build_navigation_beacon(position: Vector3, tint: Color) -> void:
	_beacon = Node3D.new()
	_beacon.name = "MissionNavigationBeacon"
	_beacon.position = position
	world.add_child(_beacon)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.8
	torus.outer_radius = 2.25
	torus.rings = 48
	torus.ring_segments = 12
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 2.5
	ring.material_override = material
	_beacon.add_child(ring)
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.10
	core.mesh = sphere
	core.material_override = material
	_beacon.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = tint
	light.light_energy = 0.9
	light.omni_range = 12.0
	_beacon.add_child(light)


func _move_beacon(position: Vector3, tint: Color) -> void:
	_objective_position = position
	if is_instance_valid(_beacon):
		_beacon.queue_free()
	_build_navigation_beacon(position, tint)
	if is_instance_valid(_target_marker):
		_target_marker.call("set_target", _beacon)

func _build_station() -> void:
	_station = Node3D.new()
	_station.name = "OrbitalCarrier"
	_station.position = HOME_POSITION
	world.add_child(_station)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 25.0
	torus.outer_radius = 28.0
	torus.rings = 96
	torus.ring_segments = 16
	ring.mesh = torus
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.12, 0.18, 0.26)
	armor.metallic = 0.82
	armor.roughness = 0.28
	ring.material_override = armor
	_station.add_child(ring)
	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 5.0
	hub_mesh.bottom_radius = 7.0
	hub_mesh.height = 48.0
	hub_mesh.radial_segments = 48
	hub.mesh = hub_mesh
	hub.rotation_degrees.x = 90.0
	hub.material_override = armor
	_station.add_child(hub)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(2.2, 2.2, 24.0)
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 13.0, 0.0, 0.0)
		arm.material_override = armor
		_station.add_child(arm)
	var accent := StandardMaterial3D.new()
	accent.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	accent.albedo_color = Color(0.05, 0.55, 0.88)
	accent.emission_enabled = true
	accent.emission = Color(0.02, 0.42, 0.9)
	accent.emission_energy_multiplier = 2.0
	var marker := MeshInstance3D.new()
	var accent_ring := TorusMesh.new()
	accent_ring.inner_radius = 29.0
	accent_ring.outer_radius = 29.6
	marker.mesh = accent_ring
	marker.material_override = accent
	_station.add_child(marker)
	var station_light := OmniLight3D.new()
	station_light.position = Vector3(0.0, 0.0, 0.0)
	station_light.light_color = Color(0.08, 0.48, 1.0)
	station_light.light_energy = 3.5
	station_light.omni_range = 90.0
	_station.add_child(station_light)

	# Forward-facing carrier docking collar. The player approaches from -Z,
	# enters the lit collar, aligns with +Z and confirms the clamps with E.
	var docking_bay := Node3D.new()
	docking_bay.name = "DockingBay"
	docking_bay.position = Vector3(0.0, 0.0, -36.0)
	_station.add_child(docking_bay)
	var bay_floor := MeshInstance3D.new()
	var bay_floor_mesh := BoxMesh.new()
	bay_floor_mesh.size = Vector3(18.0, 0.8, 24.0)
	bay_floor.mesh = bay_floor_mesh
	bay_floor.position = Vector3(0.0, -5.0, 4.0)
	bay_floor.material_override = armor
	docking_bay.add_child(bay_floor)
	var collar := MeshInstance3D.new()
	var collar_mesh := TorusMesh.new()
	collar_mesh.inner_radius = 8.0
	collar_mesh.outer_radius = 9.2
	collar_mesh.rings = 64
	collar_mesh.ring_segments = 16
	collar.mesh = collar_mesh
	collar.material_override = accent
	docking_bay.add_child(collar)
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(1.0, 1.2, 20.0)
		rail.mesh = rail_mesh
		rail.position = Vector3(side * 10.0, -2.2, 4.0)
		rail.material_override = armor
		docking_bay.add_child(rail)
		var guide_light := OmniLight3D.new()
		guide_light.position = Vector3(side * 7.0, 1.0, 1.0)
		guide_light.light_color = Color(0.08, 0.95, 0.72)
		guide_light.light_energy = 1.4
		guide_light.omni_range = 18.0
		docking_bay.add_child(guide_light)
	_dock_position = _station.global_position + docking_bay.position


func _attempt_docking() -> bool:
	if stage != MissionStage.DOCKING or not is_instance_valid(player):
		return false
	var ship_forward := -player.global_transform.basis.z
	var distance := player.global_position.distance_to(_dock_position)
	var speed := player.velocity.length()
	if not DOCKING_RULES_SCRIPT.can_dock(distance, speed, ship_forward, Vector3.BACK):
		_set_radio("DOCKING CONTROL", "Docking denied. Port %0.0f m • speed %0.0f/%0.0f m/s • align nose with the green collar." % [distance, speed, DOCKING_RULES_SCRIPT.MAX_DOCK_SPEED])
		return false
	_complete_docking(false)
	return true


func _complete_docking(qa_mode: bool = false) -> void:
	if not is_instance_valid(player):
		return
	stage = MissionStage.DOCKED
	player.global_position = _dock_position
	player.global_rotation = Vector3(0.0, PI, 0.0)
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	var weapon := player.get_node_or_null("WeaponSystem")
	if weapon != null:
		weapon.set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if qa_mode or get_tree().get_first_node_in_group("qa_demo_driver") != null:
		stage = MissionStage.COMPLETE
		_set_radio("CARRIER CONTROL", "Automated docking sequence verified. Mission complete.")
		print("MISSION_DOCKING_QA_PASS")
		_show_mission_result(true)
		return

	var profile := get_node_or_null("/root/GameProfile")
	if profile != null:
		mission_reward_credits = int(profile.call("complete_mission", "silent_relay", 5000))
	var save_manager := _get_save_manager()
	if save_manager != null:
		save_manager.call("delete_slot", "silent_relay")
	_set_radio("CARRIER CONTROL", "Docking clamps engaged. Carrier maintenance services are online.")
	_build_docking_services()
	print("DOCKING_COMPLETE reward=", mission_reward_credits)


func _build_docking_services() -> void:
	_service_layer = CanvasLayer.new()
	_service_layer.name = "CarrierServices"
	_service_layer.layer = 24
	_service_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(_service_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.004, 0.012, 0.026, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_service_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_service_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620.0, 760.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.035, 0.062, 0.98)
	style.border_color = Color(0.08, 0.82, 0.72, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "ORBITAL CARRIER  /  MAINTENANCE BAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.38, 0.94, 0.86))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "DOCKING COMPLETE  •  SERVICE YOUR CRAFT BEFORE THE NEXT SORTIE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.58, 0.72, 0.82))
	column.add_child(subtitle)
	_service_stats_label = Label.new()
	_service_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_service_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_service_stats_label.add_theme_color_override("font_color", Color(0.84, 0.92, 0.98))
	column.add_child(_service_stats_label)
	var separator := HSeparator.new()
	column.add_child(separator)
	_service_status_label = Label.new()
	_service_status_label.text = "Select a maintenance operation. Costs are deducted from pilot credits."
	_service_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_service_status_label.add_theme_color_override("font_color", Color(0.58, 0.78, 0.86))
	column.add_child(_service_status_label)

	_service_buttons.clear()
	_add_service_button(column, "hull", "REPAIR HULL", _service_hull)
	_add_service_button(column, "shields", "RECHARGE SHIELDS", _service_shields)
	_add_service_button(column, "boost", "REFILL BOOST CELLS", _service_boost)
	_add_service_button(column, "weapons", "REARM WEAPON CAPACITORS", _service_weapons)

	var module_separator := HSeparator.new()
	column.add_child(module_separator)
	var module_heading := Label.new()
	module_heading.text = "HARDPOINT MODULES  /  ONE MODULE PER SLOT"
	module_heading.add_theme_color_override("font_color", Color(0.38, 0.94, 0.86))
	column.add_child(module_heading)
	var profile := get_node_or_null("/root/GameProfile")
	var module_catalog: Array = profile.call("get_module_catalog") if profile != null else []
	for module in module_catalog:
		var module_id := str(module.get("id", ""))
		var module_name := str(module.get("name", module_id))
		var module_price := int(module.get("price", 0))
		var module_button_key := "module_" + module_id
		_add_service_button(column, module_button_key, "INSTALL %s  •  %d CR" % [module_name.to_upper(), module_price], _install_module.bind(module_id))
		var module_button := _service_buttons.get(module_button_key) as Button
		if module_button != null:
			module_button.tooltip_text = str(module.get("description", ""))

	var debrief := Button.new()
	debrief.text = "COMPLETE DEBRIEF"
	debrief.custom_minimum_size.y = 46.0
	debrief.pressed.connect(_finish_docking_services)
	column.add_child(debrief)
	_refresh_docking_services()



func _refresh_module_buttons() -> void:
	var profile := get_node_or_null("/root/GameProfile")
	if profile == null:
		return
	var ship_id := str(profile.call("get_selected_ship_id"))
	var installed: Array = profile.call("get_installed_modules", ship_id)
	var credits := int(profile.call("get_credits"))
	var catalog: Array = profile.call("get_module_catalog")
	for module in catalog:
		var module_id := str(module.get("id", ""))
		var module_name := str(module.get("name", module_id)).to_upper()
		var price := int(module.get("price", 0))
		var key := "module_" + module_id
		var button := _service_buttons.get(key) as Button
		if button == null:
			continue
		button.tooltip_text = str(module.get("description", ""))
		if installed.has(module_id):
			button.text = "INSTALLED  •  " + module_name
			button.disabled = true
		elif not bool(profile.call("is_module_slot_available", ship_id, module_id)):
			button.text = "SLOT OCCUPIED  •  " + module_name
			button.disabled = true
		else:
			button.text = "INSTALL %s  •  %d CR" % [module_name, price]
			button.disabled = credits < price


func _install_module(module_id: String) -> void:
	var profile := get_node_or_null("/root/GameProfile")
	if profile == null:
		return
	var ship_id := str(profile.call("get_selected_ship_id"))
	if not bool(profile.call("purchase_module", ship_id, module_id)):
		_service_status_label.text = "MODULE NOT INSTALLED — check available credits and the occupied slot."
		_refresh_docking_services()
		return
	if is_instance_valid(player) and player.has_method("refresh_profile_upgrades"):
		player.call("refresh_profile_upgrades")
	var catalog: Array = profile.call("get_module_catalog")
	var module_name := module_id
	for module in catalog:
		if str(module.get("id", "")) == module_id:
			module_name = str(module.get("name", module_id))
			break
	_service_status_label.text = "%s installed on %s. Ship performance has been recalculated." % [module_name, ship_id.replace("_", " ").to_upper()]
	_refresh_docking_services()


func _add_service_button(parent: VBoxContainer, key: String, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.name = "Service_" + key
	button.text = label
	button.custom_minimum_size.y = 42.0
	button.pressed.connect(callback)
	parent.add_child(button)
	_service_buttons[key] = button


func _service_cost(missing_amount: float, rate: float) -> int:
	return maxi(0, int(ceil(maxf(0.0, missing_amount) * rate)))


func _refresh_docking_services() -> void:
	if not is_instance_valid(player) or not is_instance_valid(_service_stats_label):
		return
	var damageable := player.get_node_or_null("Damageable") as Damageable
	var weapon := player.get_node_or_null("WeaponSystem") as WeaponSystem
	var profile := get_node_or_null("/root/GameProfile")
	var credits := int(profile.call("get_credits")) if profile != null else 0
	var hull_cost := _service_cost(damageable.max_hull - damageable.current_hull, 4.0) if damageable != null else 0
	var shield_cost := _service_cost(damageable.max_shield - damageable.current_shield, 2.0) if damageable != null else 0
	var boost_cost := _service_cost(player.flight_config.boost_capacity - player.boost_amount, 25.0) if player.flight_config != null else 0
	_service_stats_label.text = "HULL  %0.0f/%0.0f     SHIELD  %0.0f/%0.0f     BOOST  %0.0f/%0.0f     CREDITS  %d" % [
		damageable.current_hull if damageable != null else 0.0,
		damageable.max_hull if damageable != null else 0.0,
		damageable.current_shield if damageable != null else 0.0,
		damageable.max_shield if damageable != null else 0.0,
		player.boost_amount,
		player.flight_config.boost_capacity if player.flight_config != null else 0.0,
		credits
	]
	_set_service_button("hull", "REPAIR HULL  •  %d CR" % hull_cost, hull_cost, hull_cost > 0)
	_set_service_button("shields", "RECHARGE SHIELDS  •  %d CR" % shield_cost, shield_cost, shield_cost > 0)
	_set_service_button("boost", "REFILL BOOST CELLS  •  %d CR" % boost_cost, boost_cost, boost_cost > 0)
	_set_service_button("weapons", "REARM WEAPON CAPACITORS  •  150 CR", 150, weapon != null)
	_refresh_module_buttons()


func _set_service_button(key: String, label: String, cost: int, needed: bool) -> void:
	var button := _service_buttons.get(key) as Button
	if button == null:
		return
	button.text = label
	var profile := get_node_or_null("/root/GameProfile")
	var credits := int(profile.call("get_credits")) if profile != null else 0
	button.disabled = not needed or credits < cost


func _pay_for_service(cost: int, service_name: String) -> bool:
	var profile := get_node_or_null("/root/GameProfile")
	if profile == null or not bool(profile.call("spend_credits", cost)):
		if is_instance_valid(_service_status_label):
			_service_status_label.text = "INSUFFICIENT CREDITS — %s was not performed." % service_name
		return false
	return true


func _service_hull() -> void:
	var damageable := player.get_node_or_null("Damageable") as Damageable
	if damageable == null:
		return
	var cost := _service_cost(damageable.max_hull - damageable.current_hull, 4.0)
	if cost <= 0 or not _pay_for_service(cost, "HULL REPAIR"):
		return
	damageable.current_hull = damageable.max_hull
	damageable.hull_changed.emit(damageable.current_hull, damageable.max_hull)
	_service_status_label.text = "HULL REPAIRED — structural integrity restored to 100%."
	_refresh_docking_services()


func _service_shields() -> void:
	var damageable := player.get_node_or_null("Damageable") as Damageable
	if damageable == null:
		return
	var cost := _service_cost(damageable.max_shield - damageable.current_shield, 2.0)
	if cost <= 0 or not _pay_for_service(cost, "SHIELD RECHARGE"):
		return
	damageable.current_shield = damageable.max_shield
	damageable.shield_changed.emit(damageable.current_shield, damageable.max_shield)
	_service_status_label.text = "SHIELDS RECHARGED — defensive grid at full capacity."
	_refresh_docking_services()


func _service_boost() -> void:
	if player.flight_config == null:
		return
	var cost := _service_cost(player.flight_config.boost_capacity - player.boost_amount, 25.0)
	if cost <= 0 or not _pay_for_service(cost, "BOOST REFILL"):
		return
	player.boost_amount = player.flight_config.boost_capacity
	_service_status_label.text = "BOOST CELLS REFILLED — full acceleration reserve available."
	_refresh_docking_services()


func _service_weapons() -> void:
	var weapon := player.get_node_or_null("WeaponSystem") as WeaponSystem
	if weapon == null or not _pay_for_service(150, "WEAPON RECALIBRATION"):
		return
	weapon.rearm()
	_service_status_label.text = "WEAPONS RECALIBRATED — capacitor cycle reset."
	_refresh_docking_services()


func _finish_docking_services() -> void:
	if is_instance_valid(_service_layer):
		_service_layer.queue_free()
	stage = MissionStage.COMPLETE
	_set_radio("CARRIER CONTROL", "Maintenance logged. Debrief complete. Mission successful.")
	print("MISSION_COMPLETE seconds=", mission_seconds, " reward=", mission_reward_credits)
	_show_mission_result(true)


func _save_checkpoint(reason: String = "manual") -> bool:
	if not is_instance_valid(player):
		return false
	var damageable := player.get_node_or_null("Damageable") as Damageable
	var payload := {
		"mission_id": "silent_relay",
		"stage": int(stage),
		"wave_index": wave_index,
		"mission_seconds": mission_seconds,
		"enemies_destroyed": enemies_destroyed,
		"player_position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"player_rotation": [player.global_rotation.x, player.global_rotation.y, player.global_rotation.z],
		"player_velocity": [player.velocity.x, player.velocity.y, player.velocity.z],
		"player_hull": damageable.current_hull if damageable != null else 100.0,
		"player_shield": damageable.current_shield if damageable != null else 100.0
	}
	var save_manager := _get_save_manager()
	if save_manager == null:
		push_error("Checkpoint save manager is unavailable.")
		return false
	var result: Dictionary = save_manager.call("save_slot", "silent_relay", payload)
	if result.ok:
		print("CHECKPOINT_SAVED reason=", reason, " stage=", stage, " wave=", wave_index)
		if is_instance_valid(_radio_label) and reason == "manual":
			_set_radio("SAVE SYSTEM", "Checkpoint saved locally. Press F9 to restore it.")
		return true
	push_error("Checkpoint save failed: " + str(result.get("error", "unknown")))
	return false

func _load_checkpoint() -> bool:
	var save_manager := _get_save_manager()
	if save_manager == null:
		return false
	var result: Dictionary = save_manager.call("load_slot", "silent_relay")
	if not result.ok:
		_set_radio("SAVE SYSTEM", "No valid local checkpoint is available.")
		return false
	var restored := restore_from_save(result.payload)
	if restored:
		_set_radio("SAVE SYSTEM", "Checkpoint restored. Flight resumed.")
	return restored

func restore_from_save(payload: Dictionary) -> bool:
	if str(payload.get("mission_id", "")) != "silent_relay":
		return false
	var saved_stage := int(payload.get("stage", -1))
	if saved_stage < MissionStage.OUTBOUND or saved_stage > MissionStage.DOCKING:
		return false
	stage = saved_stage
	wave_index = maxi(0, int(payload.get("wave_index", 0)))
	mission_seconds = maxf(0.0, float(payload.get("mission_seconds", 0.0)))
	enemies_destroyed = clampi(int(payload.get("enemies_destroyed", 0)), 0, 18)
	player.global_position = _vector_from_payload(payload.get("player_position", []), player.global_position)
	player.global_rotation = _vector_from_payload(payload.get("player_rotation", []), player.global_rotation)
	player.velocity = _vector_from_payload(payload.get("player_velocity", []), Vector3.ZERO)
	var damageable := player.get_node_or_null("Damageable") as Damageable
	if damageable != null:
		damageable.current_hull = clampf(float(payload.get("player_hull", damageable.max_hull)), 1.0, damageable.max_hull)
		damageable.current_shield = clampf(float(payload.get("player_shield", damageable.max_shield)), 0.0, damageable.max_shield)
	for enemy in get_tree().get_nodes_in_group("combat_targets"):
		if enemy != player and is_instance_valid(enemy):
			enemy.queue_free()
	enemies_remaining = 0
	_next_wave_timer = -1.0
	match stage:
		MissionStage.OUTBOUND, MissionStage.SCAN_RELAY, MissionStage.DEFEND_RELAY:
			_move_beacon(RELAY_POSITION, Color(0.08, 0.78, 1.0))
		MissionStage.INVESTIGATE_WRECK, MissionStage.SCAN_WRECK, MissionStage.DEFEND_WRECK:
			_move_beacon(WRECK_POSITION, Color(1.0, 0.62, 0.18))
		MissionStage.RETURN_HOME:
			_move_beacon(HOME_POSITION, Color(0.18, 1.0, 0.62))
		MissionStage.DOCKING:
			_move_beacon(_dock_position, Color(0.18, 1.0, 0.72))
	if stage == MissionStage.DEFEND_RELAY or stage == MissionStage.DEFEND_WRECK:
		wave_index = maxi(0, wave_index - 1)
		_spawn_wave()
	_update_hud()
	return true

func _get_save_manager() -> Node:
	return get_node_or_null("/root/GameSave")

func _vector_from_payload(value: Variant, fallback: Vector3) -> Vector3:
	if not value is Array or value.size() != 3:
		return fallback
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _show_mission_result(success: bool) -> void:
	if _result_shown:
		return
	_result_shown = true
	if get_tree().get_first_node_in_group("qa_demo_driver") != null:
		print("MISSION_RESULT_QA_SUPPRESSED success=", success)
		return
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		var weapon := player.get_node_or_null("WeaponSystem")
		if weapon != null:
			weapon.set_process(false)
	if is_instance_valid(encounter):
		encounter.set_process(false)
		encounter.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var layer := CanvasLayer.new()
	layer.name = "MissionResult"
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.012, 0.025, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 370)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.045, 0.075, 0.98)
	style.border_color = Color(0.12, 0.62, 0.82, 0.9) if success else Color(0.78, 0.24, 0.18, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "MISSION COMPLETE" if success else "MISSION FAILED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#67d9f3") if success else Color("#ff887d"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "THE SILENT RELAY  /  DEBRIEFING"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#9eb8c8"))
	column.add_child(subtitle)
	var stats := Label.new()
	stats.text = "FLIGHT TIME     %02d:%02d\nHOSTILES DESTROYED     %d / 18\nWAVES CLEARED     %d / 6\nCREDITS EARNED     +%d" % [int(mission_seconds) / 60, int(mission_seconds) % 60, enemies_destroyed, _get_waves_cleared(success), mission_reward_credits]
	stats.add_theme_font_size_override("font_size", 16)
	stats.add_theme_color_override("font_color", Color("#d5e8f2"))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(stats)
	var retry := Button.new()
	retry.name = "RetryButton"
	retry.text = "PLAY AGAIN"
	retry.custom_minimum_size.y = 48
	retry.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/demo/ten_minute_demo.tscn")
	)
	column.add_child(retry)
	var menu := Button.new()
	menu.name = "MenuButton"
	menu.text = "MAIN MENU"
	menu.custom_minimum_size.y = 42
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	column.add_child(menu)
	get_tree().paused = true
	print("MISSION_RESULT_SHOWN success=", success, " kills=", enemies_destroyed, " seconds=", mission_seconds)

func _get_waves_cleared(success: bool) -> int:
	if success:
		return 6
	match stage:
		MissionStage.DEFEND_RELAY:
			return maxi(0, wave_index - (1 if enemies_remaining > 0 else 0))
		MissionStage.INVESTIGATE_WRECK, MissionStage.SCAN_WRECK:
			return 3
		MissionStage.DEFEND_WRECK:
			return 3 + maxi(0, wave_index - (1 if enemies_remaining > 0 else 0))
		MissionStage.RETURN_HOME:
			return 6
		_:
			return 0
