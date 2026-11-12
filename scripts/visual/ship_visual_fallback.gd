extends Node3D
class_name ShipVisualFallback
## Restores a readable procedural ship silhouette when an imported GLB is unavailable.
## If the GLB is healthy, the imported model is shown and primitive fallback meshes are hidden.

enum Profile { PLAYER_FIGHTER, RAIDER_INTERCEPTOR }

@export var imported_model_name: StringName = &""
@export var fallback_mesh_names: Array[StringName] = []
@export var profile: Profile = Profile.PLAYER_FIGHTER

var _hull_material: StandardMaterial3D
var _accent_material: StandardMaterial3D
var _glass_material: StandardMaterial3D
var _glow_material: StandardMaterial3D


func _ready() -> void:
	var imported_model := get_node_or_null(NodePath(String(imported_model_name)))
	var use_imported := imported_model != null and _contains_mesh(imported_model)
	for node_name in fallback_mesh_names:
		var fallback := get_node_or_null(NodePath(String(node_name))) as GeometryInstance3D
		if fallback != null:
			fallback.visible = not use_imported
	if not use_imported:
		_build_procedural_details()


func _contains_mesh(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _contains_mesh(child):
			return true
	return false


func _build_procedural_details() -> void:
	var raider := profile == Profile.RAIDER_INTERCEPTOR
	var hull_color := Color(0.22, 0.30, 0.40) if not raider else Color(0.30, 0.12, 0.105)
	var accent_color := Color(0.10, 0.70, 0.88) if not raider else Color(0.96, 0.29, 0.10)
	var glow_color := Color(0.04, 0.48, 1.0) if not raider else Color(1.0, 0.16, 0.035)

	_hull_material = _make_material(hull_color, 0.78, 0.3)
	_accent_material = _make_material(accent_color, 0.58, 0.26, accent_color * 0.38, 1.1)
	_glass_material = _make_material(Color(0.018, 0.075, 0.12, 0.92), 0.82, 0.12)
	_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_material = _make_material(glow_color, 0.25, 0.24, glow_color, 3.2)

	# Layered armor, dorsal spine and a glazed cockpit turn the primitive blockout
	# into a deliberate, readable fighter silhouette without external assets.
	_add_box("Fallback_DorsalSpine", Vector3(0.42, 0.18, 1.55), Vector3(0, 0.27, 0.12), _hull_material)
	_add_box("Fallback_CockpitFrame", Vector3(0.58, 0.12, 0.78), Vector3(0, 0.31, -0.72), _accent_material)
	_add_sphere("Fallback_Canopy", Vector3(0, 0.37, -0.72), Vector3(0.26, 0.15, 0.42), _glass_material)

	for side in [-1.0, 1.0]:
		_add_box("Fallback_WingArmor_%s" % str(side), Vector3(0.78, 0.16, 0.64), Vector3(side * 1.05, -0.015, 0.1), _hull_material, Vector3(0, 0, side * -7.0))
		_add_box("Fallback_WingStripe_%s" % str(side), Vector3(0.48, 0.035, 0.11), Vector3(side * 1.0, 0.09, -0.08), _accent_material)
		_add_box("Fallback_EnginePylon_%s" % str(side), Vector3(0.20, 0.22, 0.48), Vector3(side * 0.38, -0.02, 1.55), _hull_material)
		_add_engine("Fallback_EngineNozzle_%s" % str(side), Vector3(side * 0.38, 0.0, 1.98), raider)
		_add_box("Fallback_WeaponPod_%s" % str(side), Vector3(0.12, 0.12, 0.88), Vector3(side * 1.24, -0.03, -0.42), _accent_material)

	_add_box("Fallback_NoseKeel", Vector3(0.16, 0.12, 1.12), Vector3(0, -0.19, -1.82), _hull_material)
	_add_box("Fallback_DorsalAntenna", Vector3(0.055, 0.32, 0.08), Vector3(0, 0.49, 0.46), _accent_material)


func _make_material(color: Color, metal: float, rough: float, emission_color: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = rough
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = energy
	return material


func _add_box(node_name: String, dimensions: Vector3, position: Vector3, material: Material, rotation_degrees: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	add_child(instance)


func _add_sphere(node_name: String, position: Vector3, dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 24
	mesh.rings = 12
	instance.mesh = mesh
	instance.scale = dimensions
	instance.position = position
	instance.material_override = material
	add_child(instance)


func _add_engine(node_name: String, position: Vector3, raider: bool) -> void:
	var nozzle := MeshInstance3D.new()
	nozzle.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.19
	cylinder.bottom_radius = 0.25
	cylinder.height = 0.34
	cylinder.radial_segments = 20
	nozzle.mesh = cylinder
	nozzle.rotation_degrees.x = 90.0
	nozzle.position = position
	nozzle.material_override = _hull_material
	add_child(nozzle)

	var core := MeshInstance3D.new()
	core.name = node_name + "_Glow"
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	sphere.radial_segments = 16
	sphere.rings = 8
	core.mesh = sphere
	core.scale = Vector3(1.0, 1.0, 0.45)
	core.position = position + Vector3(0, 0, 0.18)
	core.material_override = _glow_material
	add_child(core)
