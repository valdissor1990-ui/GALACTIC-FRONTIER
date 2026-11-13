extends Node3D
class_name ShipVisualBuilder
## Runtime-built low-poly ship silhouettes. Geometry is authored in local X/Z;
## forward is -Z, matching the flight controller and weapon muzzle.

@export_enum("player", "enemy") var craft_type: String = "player"

var _hull_material: ShaderMaterial
var _accent_material: StandardMaterial3D
var _glass_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	if craft_type == "enemy":
		_build_enemy()
	else:
		_build_player()


func _create_materials() -> void:
	_hull_material = ShaderMaterial.new()
	_hull_material.shader = load("res://assets/shaders/hull_fresnel.gdshader")
	if craft_type == "enemy":
		_hull_material.set_shader_parameter("albedo_color", Color(0.22, 0.075, 0.085, 1.0))
		_hull_material.set_shader_parameter("rim_color", Color(0.95, 0.18, 0.12, 1.0))
		_hull_material.set_shader_parameter("rim_strength", 0.48)
		_hull_material.set_shader_parameter("panel_scale", 16.0)
	else:
		_hull_material.set_shader_parameter("albedo_color", Color(0.22, 0.32, 0.40, 1.0))
		_hull_material.set_shader_parameter("rim_color", Color(0.22, 0.68, 0.92, 1.0))
		_hull_material.set_shader_parameter("rim_strength", 0.58)
		_hull_material.set_shader_parameter("panel_scale", 18.0)

	_accent_material = StandardMaterial3D.new()
	_accent_material.metallic = 0.72
	_accent_material.roughness = 0.28
	_accent_material.albedo_color = Color(0.08, 0.16, 0.22) if craft_type == "player" else Color(0.18, 0.055, 0.06)
	_glass_material = StandardMaterial3D.new()
	_glass_material.albedo_color = Color(0.025, 0.12, 0.18) if craft_type == "player" else Color(0.12, 0.035, 0.04)
	_glass_material.metallic = 0.45
	_glass_material.roughness = 0.12
	_glass_material.emission_enabled = true
	_glass_material.emission = Color(0.015, 0.10, 0.16) if craft_type == "player" else Color(0.18, 0.025, 0.02)
	_glass_material.emission_energy_multiplier = 0.35


func _build_player() -> void:
	_add_extruded("SweptDeltaWing", PackedVector2Array([
		Vector2(0.0, -2.9), Vector2(0.52, -2.35), Vector2(0.72, -1.25),
		Vector2(3.55, 0.72), Vector2(4.0, 1.38), Vector2(1.05, 0.92),
		Vector2(0.88, 2.12), Vector2(0.42, 2.65), Vector2(0.0, 2.42),
		Vector2(-0.42, 2.65), Vector2(-0.88, 2.12), Vector2(-1.05, 0.92),
		Vector2(-4.0, 1.38), Vector2(-3.55, 0.72), Vector2(-0.72, -1.25),
	]), 0.22, _hull_material)
	_add_extruded("ArmouredSpine", PackedVector2Array([
		Vector2(0.0, -3.35), Vector2(0.48, -2.45), Vector2(0.43, 1.85),
		Vector2(0.18, 2.72), Vector2(0.0, 2.88), Vector2(-0.18, 2.72),
		Vector2(-0.43, 1.85), Vector2(-0.48, -2.45),
	]), 0.42, _hull_material, 0.16)
	_add_cockpit(Vector3(0.0, 0.34, -0.72), Vector3(0.43, 0.19, 0.82))
	_add_engine_pod(-1.12, 1.62, false)
	_add_engine_pod(1.12, 1.62, false)
	_add_nav_light(-3.48, Color(0.95, 0.28, 0.12))
	_add_nav_light(3.48, Color(0.12, 0.62, 1.0))


func _build_enemy() -> void:
	_add_extruded("StrikeWing", PackedVector2Array([
		Vector2(0.0, -2.85), Vector2(0.42, -2.12), Vector2(0.78, -0.88),
		Vector2(2.55, 0.32), Vector2(3.15, 1.15), Vector2(0.88, 0.82),
		Vector2(0.58, 1.92), Vector2(0.0, 2.5), Vector2(-0.58, 1.92),
		Vector2(-0.88, 0.82), Vector2(-3.15, 1.15), Vector2(-2.55, 0.32),
		Vector2(-0.78, -0.88), Vector2(-0.42, -2.12),
	]), 0.20, _hull_material)
	_add_extruded("AttackSpine", PackedVector2Array([
		Vector2(0.0, -3.1), Vector2(0.36, -2.15), Vector2(0.31, 1.8),
		Vector2(0.0, 2.55), Vector2(-0.31, 1.8), Vector2(-0.36, -2.15),
	]), 0.36, _hull_material, 0.14)
	_add_cockpit(Vector3(0.0, 0.28, -0.82), Vector3(0.32, 0.15, 0.65))
	_add_engine_pod(-0.82, 1.58, true)
	_add_engine_pod(0.82, 1.58, true)
	_add_nav_light(-2.7, Color(1.0, 0.18, 0.08))
	_add_nav_light(2.7, Color(1.0, 0.18, 0.08))


func _add_extruded(
	mesh_name: String, points: PackedVector2Array, thickness: float,
	material: Material, height_offset: float = 0.0
) -> void:
	if points.size() < 3:
		return
	var min_x := points[0].x
	var max_x := points[0].x
	var min_z := points[0].y
	var max_z := points[0].y
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.y)
		max_z = maxf(max_z, point.y)

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := thickness * 0.5
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())

	# Top and bottom caps; duplicate vertices keep face normals crisp.
	for i in points.size():
		var next := (i + 1) % points.size()
		_add_triangle(tool, Vector3(0.0, half, 0.0), _point3(points[i], half), _point3(points[next], half), center, points[i], points[next], min_x, max_x, min_z, max_z)
		_add_triangle(tool, Vector3(0.0, -half, 0.0), _point3(points[next], -half), _point3(points[i], -half), center, points[next], points[i], min_x, max_x, min_z, max_z)

	# Side wall around the complete silhouette.
	for i in points.size():
		var next := (i + 1) % points.size()
		var a := _point3(points[i], -half)
		var b := _point3(points[next], -half)
		var c := _point3(points[next], half)
		var d := _point3(points[i], half)
		tool.set_uv(_uv(points[i], min_x, max_x, min_z, max_z)); tool.add_vertex(a)
		tool.set_uv(_uv(points[next], min_x, max_x, min_z, max_z)); tool.add_vertex(b)
		tool.set_uv(_uv(points[next], min_x, max_x, min_z, max_z)); tool.add_vertex(c)
		tool.set_uv(_uv(points[i], min_x, max_x, min_z, max_z)); tool.add_vertex(a)
		tool.set_uv(_uv(points[next], min_x, max_x, min_z, max_z)); tool.add_vertex(c)
		tool.set_uv(_uv(points[i], min_x, max_x, min_z, max_z)); tool.add_vertex(d)

	tool.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.position.y = height_offset
	instance.mesh = tool.commit()
	instance.material_override = material
	add_child(instance)


func _add_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	tool.set_uv(_uv(ua, min_x, max_x, min_z, max_z)); tool.add_vertex(a)
	tool.set_uv(_uv(ub, min_x, max_x, min_z, max_z)); tool.add_vertex(b)
	tool.set_uv(_uv(uc, min_x, max_x, min_z, max_z)); tool.add_vertex(c)


func _point3(point: Vector2, y: float) -> Vector3:
	return Vector3(point.x, y, point.y)


func _uv(point: Vector2, min_x: float, max_x: float, min_z: float, max_z: float) -> Vector2:
	return Vector2(inverse_lerp(min_x, max_x, point.x), inverse_lerp(min_z, max_z, point.y))


func _add_cockpit(position: Vector3, size: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	var instance := MeshInstance3D.new()
	instance.name = "CockpitCanopy"
	instance.mesh = mesh
	instance.position = position
	instance.scale = size
	instance.material_override = _glass_material
	add_child(instance)


func _add_engine_pod(x: float, z: float, enemy: bool) -> void:
	var pod := MeshInstance3D.new()
	pod.name = "EngineNacelle"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.30 if not enemy else 0.24
	mesh.bottom_radius = 0.36 if not enemy else 0.28
	mesh.height = 1.25
	mesh.radial_segments = 12
	pod.mesh = mesh
	pod.position = Vector3(x, -0.04, z)
	pod.rotation_degrees.x = 90.0
	pod.material_override = _accent_material
	add_child(pod)

	var nozzle := MeshInstance3D.new()
	nozzle.name = "EngineNozzle"
	var nozzle_mesh := CylinderMesh.new()
	nozzle_mesh.top_radius = 0.20
	nozzle_mesh.bottom_radius = 0.26
	nozzle_mesh.height = 0.22
	nozzle_mesh.radial_segments = 12
	nozzle.mesh = nozzle_mesh
	nozzle.position = Vector3(x, -0.04, z + 0.68)
	nozzle.rotation_degrees.x = 90.0
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.08, 0.48, 0.72) if not enemy else Color(0.82, 0.12, 0.06)
	glow.emission_enabled = true
	glow.emission = glow.albedo_color
	glow.emission_energy_multiplier = 1.6
	nozzle.material_override = glow
	add_child(nozzle)


func _add_nav_light(x: float, color: Color) -> void:
	var light := MeshInstance3D.new()
	light.name = "NavigationLight"
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.18
	mesh.radial_segments = 8
	mesh.rings = 4
	light.mesh = mesh
	light.position = Vector3(x, 0.12, 0.9)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	light.material_override = material
	add_child(light)
