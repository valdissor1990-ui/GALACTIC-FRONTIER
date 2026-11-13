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
	_canopy_frame.albedo_color = Color(0.075, 0.12, 0.18)
	_canopy_frame.metallic = 0.58
	_canopy_frame.roughness = 0.36
	_canopy_frame.emission_enabled = true
	_canopy_frame.emission = Color(0.018, 0.045, 0.075)
	_canopy_frame.emission_energy_multiplier = 0.55


func _build_dashboard() -> void:
	_box("Instrument fascia", Vector3(0.0, -0.46, -1.96), Vector3(1.50, 0.12, 0.48), _armor, Vector3(-9.0, 0.0, 0.0))
	_box("Central display housing", Vector3(0.0, -0.25, -1.80), Vector3(0.56, 0.30, 0.10), _panel, Vector3(-8.0, 0.0, 0.0))
	_box("Port display housing", Vector3(-0.53, -0.25, -1.72), Vector3(0.38, 0.25, 0.08), _panel, Vector3(-10.0, 0.0, 0.0))
	_box("Starboard display housing", Vector3(0.53, -0.25, -1.72), Vector3(0.38, 0.25, 0.08), _panel, Vector3(-10.0, 0.0, 0.0))
	_quad("Primary flight display", Vector3(0.0, -0.25, -1.68), Vector2(0.46, 0.22), _screen)
	_quad("Port tactical display", Vector3(-0.53, -0.25, -1.62), Vector2(0.31, 0.18), _screen)
	_quad("Starboard systems display", Vector3(0.53, -0.25, -1.62), Vector2(0.31, 0.18), _screen)
	_box("Lower console", Vector3(0.0, -0.66, -1.52), Vector3(1.18, 0.08, 0.42), _panel, Vector3(-12.0, 0.0, 0.0))
	for side in [-1.0, 1.0]:
		_box("Side instrument console %s" % side, Vector3(side * 0.79, -0.30, -1.34), Vector3(0.15, 0.42, 0.72), _armor, Vector3(-8.0, side * -8.0, 0.0))
		_box("Side console light strip %s" % side, Vector3(side * 0.70, -0.13, -1.46), Vector3(0.018, 0.28, 0.018), _screen)
		for index in range(4):
			var button_material := _amber if index == 3 else _screen
			_box("Console key %s %s" % [side, index], Vector3(side * (0.60 + (index % 2) * 0.09), -0.50, -1.43 + float(index / 2) * 0.11), Vector3(0.065, 0.025, 0.065), button_material)


func _build_canopy_frame() -> void:
	# The pilot camera sits behind the instrument fascia. Keep the canopy
	# rails outside the central sightline and use thin forward pillars to frame
	# the view without blocking the dashboard or the flight path.
	for side in [-1.0, 1.0]:
		_box("Forward canopy pillar %s" % side, Vector3(side * 0.96, 0.25, -2.62), Vector3(0.038, 0.76, 0.05), _canopy_frame, Vector3(-13.0, side * -7.0, 0.0))
		_box("Side canopy rail %s" % side, Vector3(side * 1.55, 0.32, -0.55), Vector3(0.035, 0.07, 3.85), _canopy_frame, Vector3(0.0, 0.0, side * 3.0))
		_box("Upper canopy brace %s" % side, Vector3(side * 0.46, 0.74, -2.28), Vector3(0.035, 0.035, 0.58), _canopy_frame, Vector3(-8.0, side * 12.0, 0.0))
	_box("Canopy cross member", Vector3(0.0, 0.80, -2.55), Vector3(1.36, 0.035, 0.05), _canopy_frame)
	_box("Rear canopy arch", Vector3(0.0, 0.46, 0.42), Vector3(1.72, 0.12, 0.10), _panel)


func _build_controls() -> void:
	for side in [-1.0, 1.0]:
		var stick := MeshInstance3D.new()
		var stick_mesh := CylinderMesh.new()
		stick_mesh.top_radius = 0.025
		stick_mesh.bottom_radius = 0.045
		stick_mesh.height = 0.32
		stick.mesh = stick_mesh
		stick.position = Vector3(side * 0.44, -0.42, -1.16)
		stick.material_override = _armor
		add_child(stick)
		_box("Flight control grip %s" % side, Vector3(side * 0.44, -0.28, -1.16), Vector3(0.14, 0.11, 0.13), _panel)
	for index in range(8):
		var x := -0.52 + float(index) * 0.15
		_box("Lower console key %d" % index, Vector3(x, -0.56, -1.43), Vector3(0.075, 0.025, 0.075), _amber if index in [1, 6] else _screen)


func _build_holographic_hud() -> void:
	var reticle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.13
	ring.outer_radius = 0.145
	ring.rings = 36
	ring.ring_segments = 8
	reticle.mesh = ring
	reticle.position = Vector3(0.0, 0.10, -3.1)
	reticle.material_override = _white
	add_child(reticle)
	_box("HUD horizontal line", Vector3(0.0, 0.10, -3.1), Vector3(0.72, 0.008, 0.008), _white)
	_box("HUD vertical line", Vector3(0.0, 0.10, -3.1), Vector3(0.008, 0.48, 0.008), _white)
	var target_label := Label3D.new()
	target_label.text = "TARGET  /  NAV  /  SYSTEMS"
	target_label.position = Vector3(-0.44, 0.34, -3.05)
	target_label.font_size = 18
	target_label.pixel_size = 0.0018
	target_label.modulate = Color(0.28, 0.78, 1.0)
	target_label.outline_size = 0
	add_child(target_label)
	var speed_label := Label3D.new()
	speed_label.text = "FLIGHT SYSTEMS   000 m/s"
	speed_label.position = Vector3(0.18, -0.12, -3.05)
	speed_label.font_size = 24
	speed_label.pixel_size = 0.0024
	speed_label.modulate = Color(0.28, 0.78, 1.0)
	add_child(speed_label)


func _build_instrument_labels() -> void:
	_add_label("SHIELD  100%", Vector3(-0.72, -0.32, -1.58), 20, Color(0.28, 0.78, 1.0))
	_add_label("HULL  100%", Vector3(0.40, -0.32, -1.58), 20, Color(1.0, 0.48, 0.18))
	_add_label("REACTOR", Vector3(-0.73, -0.54, -0.86), 16, Color(0.58, 0.78, 0.9))
	_add_label("THRUST", Vector3(0.43, -0.54, -0.86), 16, Color(0.58, 0.78, 0.9))


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
