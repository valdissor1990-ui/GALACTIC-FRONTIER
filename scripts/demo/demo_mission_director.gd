extends Node
## Playable ten-minute vertical-slice mission: The Silent Relay.
## Uses the real player flight controller, combat projectiles, enemy AI and damage model.

const ENEMY_SCENE: PackedScene = preload("res://scenes/combat/enemy_fighter_visual.tscn")
const RELAY_POSITION := Vector3(0.0, 18.0, -13500.0)
const WRECK_POSITION := Vector3(520.0, -28.0, -33000.0)
const HOME_POSITION := Vector3(0.0, 0.0, 90.0)

enum MissionStage { OUTBOUND, SCAN_RELAY, DEFEND_RELAY, INVESTIGATE_WRECK, SCAN_WRECK, DEFEND_WRECK, RETURN_HOME, COMPLETE, FAILED }

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
var _mission_label: Label
var _objective_label: Label
var _radio_label: Label
var _distance_label: Label
var _timer_label: Label
var _progress_label: Label
var _rng := RandomNumberGenerator.new()


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


func _process(delta: float) -> void:
	if is_instance_valid(_station):
		_station.rotate_z(delta * 0.012)
	if is_instance_valid(_beacon):
		_beacon.rotate_z(delta * 0.32)
	if stage == MissionStage.COMPLETE or stage == MissionStage.FAILED:
		_update_hud()
		return
	mission_seconds += delta
	if player == null or not is_instance_valid(player):
		return
	var player_damageable := player.get_node_or_null("Damageable") as Damageable
	if player_damageable != null and player_damageable.is_destroyed():
		stage = MissionStage.FAILED
		_set_radio("MISSION CONTROL", "Your fighter is lost. Mission failed.")
	_update_mission(delta)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_F:
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
				stage = MissionStage.COMPLETE
				_set_radio("ORBITAL CONTROL", "Docking corridor clear. Data recovered. Mission complete.")
				print("MISSION_COMPLETE seconds=", mission_seconds)


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


func _on_enemy_destroyed(enemy: Node3D) -> void:
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
	elif stage == MissionStage.DEFEND_WRECK and wave_index < 3:
		_next_wave_timer = 18.0
	elif stage == MissionStage.DEFEND_WRECK:
		stage = MissionStage.RETURN_HOME
		_objective_position = HOME_POSITION
		_move_beacon(HOME_POSITION, Color(0.18, 1.0, 0.62))
		_set_radio("ORBITAL CONTROL", "All hostiles eliminated. Return to the carrier for debriefing.")


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
	elif stage == MissionStage.RETURN_HOME or stage == MissionStage.COMPLETE:
		completed_waves = 6
	_progress_label.text = "OPERATION SILENT RELAY   |   %d / %d WAVES   |   WASD / MOUSE  •  LMB FIRE  •  T LOCK  •  F SCAN  •  C CAMERA" % [completed_waves, total_waves]


func _build_mission_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MissionHUD"
	layer.layer = 8
	world.add_child(layer)
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
