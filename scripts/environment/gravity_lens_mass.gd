extends Node3D
class_name GravityLensMass
## Marks this Node3D as a gravitational-lens source for GravitationalLensFx.

@export var lens_strength: float = 1.0
@export var lens_radius: float = 0.22
@export var show_debug_core: bool = true


func _ready() -> void:
	add_to_group("gravity_lens_mass")
	set_meta("lens_mass", true)
	set_meta("lens_strength", lens_strength)
	set_meta("lens_radius", lens_radius)
	if show_debug_core:
		_spawn_core()


func _spawn_core() -> void:
	# Compact dark core so the player has a spatial anchor for the lens
	var mi := MeshInstance3D.new()
	mi.name = "LensCore"
	var mesh := SphereMesh.new()
	mesh.radius = 2.4
	mesh.height = 4.8
	mesh.radial_segments = 16
	mesh.rings = 8
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.02, 0.02, 0.03)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.05, 0.25)
	mat.emission_energy_multiplier = 0.6
	mi.set_surface_override_material(0, mat)
	add_child(mi)

	var halo := MeshInstance3D.new()
	halo.name = "PhotonSphereHint"
	var torus := TorusMesh.new()
	torus.inner_radius = 3.2
	torus.outer_radius = 4.6
	torus.rings = 24
	torus.ring_segments = 8
	halo.mesh = torus
	halo.rotation_degrees = Vector3(80, 20, 0)
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.albedo_color = Color(0.4, 0.55, 1.0, 0.35)
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	hmat.emission_enabled = true
	hmat.emission = Color(0.3, 0.45, 1.0)
	hmat.emission_energy_multiplier = 1.2
	halo.set_surface_override_material(0, hmat)
	add_child(halo)
