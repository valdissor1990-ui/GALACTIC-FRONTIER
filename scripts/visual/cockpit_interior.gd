extends Node3D
## Procedural fighter cockpit interior, shown only in first-person camera mode.

var _armor: StandardMaterial3D
var _panel: StandardMaterial3D
var _screen: StandardMaterial3D
var _amber: StandardMaterial3D
var _white: StandardMaterial3D
var _canopy_frame: StandardMaterial3D


func _ready() -> void:
	visible = false
	_create_materials()
	_build_dashboard()
	_build_canopy_frame()
	_build_controls()
	_build_holographic_hud()
	_build_instrument_labels()


func _create_materials() -> void:
	_armor = StandardMaterial3D.new()
	_armor.albedo_color = Color(0.018, 0.032, 0.052)
	_armor.metallic = 0.86
	_armor.roughness = 0.31
	_panel = StandardMaterial3D.new()
	_panel.albedo_color = Color(0.055, 0.085, 0.12)
	_panel.metallic = 0.72
	_panel.roughness = 0.38
	_screen = StandardMaterial3D.new()
	_screen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen.albedo_color = Color(0.025, 0.32, 0.48)
	_screen.emission_enabled = true
	_screen.emission = Color(0.015, 0.42, 0.82)
	_screen.emission_energy_multiplier = 1.7
	_amber = StandardMaterial3D.new()
	_amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_amber.albedo_color = Color(0.95, 0.34, 0.055)
	_amber.emission_enabled = true
	_amber.emission = Color(1.0, 0.16, 0.015)
	_amber.emission_energy_multiplier = 1.25
	_white = StandardMaterial3D.new()
	_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_white.albedo_color = Color(0.48, 0.76, 0.9)
	_white.emission_enabled = true
	_white.emission = Color(0.16, 0.48, 0.72)
	_white.emission_energy_multiplier = 0.75
	_canopy_frame = StandardMaterial3D.new()
	_canopy_frame.albedo_color = Color(0.12, 0.19, 0.27)
	_canopy_frame.metallic = 0.72
	_canopy_frame.roughness = 0.28
	_canopy_frame.emission_enabled = true
	_canopy_frame.emission = Color(0.028, 0.065, 0.10)
	_canopy_frame.emission_energy_multiplier = 0.42



func _build_dashboard() -> void:
	# Keep the coaming low and narrow so the pilot retains a clear forward view.
	_box("Instrument fascia", Vector3(0.0, -0.59, -1.88),
		Vector3(1.28, 0.085, 0.34), _armor, Vector3(-8.0, 0.0, 0.0))
	_box("Central display housing", Vector3(0.0, -0.39, -1.74),
		Vector3(0.46, 0.22, 0.075), _panel, Vector3(-8.0, 0.0, 0.0))
	_box("Port display housing", Vector3(-0.43, -0.40, -1.68),
		Vector3(0.31, 0.18, 0.065), _panel, Vector3(-10.0, 0.0, 0.0))
	_box("Starboard display housing", Vector3(0.43, -0.40, -1.68),
		Vector3(0.31, 0.18, 0.065), _panel, Vector3(-10.0, 0.0, 0.0))
	_quad("Primary flight display", Vector3(0.0, -0.39, -1.695),
		Vector2(0.37, 0.16), _screen)
	_quad("Port tactical display", Vector3(-0.43, -0.40, -1.645),
		Vector2(0.245, 0.13), _screen)
	_quad("Starboard systems display", Vector3(0.43, -0.40, -1.645),
		Vector2(0.245, 0.13), _screen)
	_box("Lower console", Vector3(0.0, -0.76, -1.48),
		Vector3(1.02, 0.065, 0.30), _panel, Vector3(-11.0, 0.0, 0.0))
	for side in [-1.0, 1.0]:
		_box("Side instrument console %s" % side,
			Vector3(side * 0.72, -0.45, -1.28),
			Vector3(0.105, 0.30, 0.54), _armor,
			Vector3(-7.0, side * -7.0, 0.0))
		_box("Side console light strip %s" % side,
			Vector3(side * 0.665, -0.31, -1.40),
			Vector3(0.012, 0.20, 0.012), _screen)
		for index in range(3):
			var button_material := _amber if index == 2 else _screen
			_box("Console key %s %s" % [side, index],
				Vector3(side * (0.57 + float(index % 2) * 0.07),
					-0.59, -1.38 + float(index / 2) * 0.10),
				Vector3(0.045, 0.018, 0.045), button_material)



func _build_canopy_frame() -> void:
	# Thin metallic rails sit at the canopy perimeter, never across the reticle.
	for side in [-1.0, 1.0]:
		_box("Forward canopy pillar %s" % side,
			Vector3(side * 0.86, 0.31, -2.45),
			Vector3(0.022, 0.48, 0.032), _canopy_frame,
			Vector3(-11.0, side * -6.0, 0.0))
		_box("Side canopy rail %s" % side,
			Vector3(side * 1.30, 0.36, -0.38),
			Vector3(0.022, 0.045, 2.85), _canopy_frame,
			Vector3(0.0, 0.0, side * 2.0))
		_box("Upper canopy brace %s" % side,
			Vector3(side * 0.39, 0.98, -2.32),
			Vector3(0.022, 0.022, 0.38), _canopy_frame,
			Vector3(-6.0, side * 9.0, 0.0))
	_box("Canopy cross member", Vector3(0.0, 1.02, -2.42),
		Vector3(0.94, 0.022, 0.028), _canopy_frame)
	_box("Rear canopy arch", Vector3(0.0, 0.54, 0.48),
		Vector3(1.42, 0.075, 0.075), _panel)



func _build_controls() -> void:
	# A conventional central flight stick and a separate port throttle.
	var stick := MeshInstance3D.new()
	var stick_mesh := CylinderMesh.new()
	stick_mesh.top_radius = 0.018
	stick_mesh.bottom_radius = 0.035
	stick_mesh.height = 0.25
	stick.mesh = stick_mesh
	stick.position = Vector3(0.28, -0.51, -1.12)
	stick.material_override = _armor
	add_child(stick)
	_box("Flight control grip", Vector3(0.28, -0.39, -1.12),
		Vector3(0.105, 0.075, 0.095), _panel)
	var throttle := MeshInstance3D.new()
	var throttle_mesh := CylinderMesh.new()
	throttle_mesh.top_radius = 0.022
	throttle_mesh.bottom_radius = 0.032
	throttle_mesh.height = 0.22
	throttle.mesh = throttle_mesh
	throttle.position = Vector3(-0.48, -0.51, -1.22)
	throttle.rotation_degrees = Vector3(0.0, 0.0, -12.0)
	throttle.material_override = _armor
	add_child(throttle)
	_box("Throttle grip", Vector3(-0.48, -0.39, -1.22),
		Vector3(0.09, 0.075, 0.12), _panel)
	for index in range(6):
		var x := -0.42 + float(index) * 0.15
		_box("Lower console key %d" % index,
			Vector3(x, -0.67, -1.39),
			Vector3(0.052, 0.018, 0.052),
			_amber if index in [1, 4] else _screen)



func _build_holographic_hud() -> void:
	var reticle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.115
	ring.outer_radius = 0.126
	ring.rings = 36
	ring.ring_segments = 8
	reticle.mesh = ring
	reticle.position = Vector3(0.0, 0.16, -3.1)
	reticle.material_override = _white
	add_child(reticle)
	_box("HUD horizontal line", Vector3(0.0, 0.16, -3.1),
		Vector3(0.58, 0.006, 0.006), _white)
	_box("HUD vertical line", Vector3(0.0, 0.16, -3.1),
		Vector3(0.006, 0.38, 0.006), _white)
	var target_label := Label3D.new()
	target_label.text = "TARGET / NAV / SYSTEMS"
	target_label.position = Vector3(-0.36, 0.38, -3.05)
	target_label.font_size = 14
	target_label.pixel_size = 0.0016
	target_label.modulate = Color(0.28, 0.78, 1.0)
	target_label.outline_size = 1
	add_child(target_label)
	var speed_label := Label3D.new()
	speed_label.text = "FLIGHT SYSTEMS   000 m/s"
	speed_label.position = Vector3(-0.26, -0.10, -3.05)
	speed_label.font_size = 17
	speed_label.pixel_size = 0.0017
	speed_label.modulate = Color(0.28, 0.78, 1.0)
	speed_label.outline_size = 1
	add_child(speed_label)



func _build_instrument_labels() -> void:
	_add_label("SHIELD 100%", Vector3(-0.61, -0.43, -1.56), 15, Color(0.28, 0.78, 1.0))
	_add_label("HULL 100%", Vector3(0.30, -0.43, -1.56), 15, Color(1.0, 0.48, 0.18))
	_add_label("REACTOR", Vector3(-0.58, -0.63, -0.91), 12, Color(0.58, 0.78, 0.9))
	_add_label("THRUST", Vector3(0.34, -0.63, -0.91), 12, Color(0.58, 0.78, 0.9))


func _add_label(value: String, at: Vector3, size: int, tint: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = size
	label.pixel_size = 0.0025
	label.modulate = tint
	label.outline_size = 0
	add_child(label)


func _box(node_name: String, at: Vector3, dimensions: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = at
	instance.rotation_degrees = rotation
	instance.material_override = material
	add_child(instance)


func _quad(node_name: String, at: Vector3, dimensions: Vector2, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := QuadMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	add_child(instance)
