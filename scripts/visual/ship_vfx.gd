extends Node3D
## Lightweight GPU exhaust plumes for the player fighter.
## All meshes/materials are generated locally; no external assets required.

@export var engine_spacing: float = 0.20
@export var exhaust_offset: float = 1.43
@export_range(20, 240, 10) var particle_count: int = 100


func _ready() -> void:
	_create_engine_plume(-engine_spacing)
	_create_engine_plume(engine_spacing)


func _create_engine_plume(x_offset: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "IonExhaust_%s" % ("L" if x_offset < 0.0 else "R")
	particles.position = Vector3(x_offset, 0.0, exhaust_offset)
	particles.amount = particle_count
	particles.lifetime = 0.52
	particles.explosiveness = 0.0
	particles.randomness = 0.28
	particles.local_coords = true

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 7.0
	process.initial_velocity_min = 7.0
	process.initial_velocity_max = 17.0
	process.gravity = Vector3.ZERO
	process.damping_min = 1.0
	process.damping_max = 3.5
	process.scale_min = 0.08
	process.scale_max = 0.24
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.07
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.55, 0.94, 1.0, 0.95))
	gradient.add_point(0.32, Color(0.08, 0.48, 1.0, 0.78))
	gradient.add_point(0.72, Color(0.025, 0.16, 0.75, 0.34))
	gradient.set_color(gradient.get_point_count() - 1, Color(0.01, 0.04, 0.20, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	particles.process_material = process

	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.12
	particle_mesh.height = 0.24
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.10, 0.48, 1.0, 0.82)
	material.emission_enabled = true
	material.emission = Color(0.025, 0.32, 1.0)
	material.emission_energy_multiplier = 4.0
	particle_mesh.material = material
	particles.draw_pass_1 = particle_mesh
	add_child(particles)
	particles.emitting = true
