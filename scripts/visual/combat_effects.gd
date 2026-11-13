extends RefCounted
class_name CombatEffects
## Small, fully procedural combat impact and destruction effects.

static func spawn_burst(host: Node, world_position: Vector3, tint: Color, effect_scale: float = 1.0) -> void:
	if host == null or not is_instance_valid(host):
		return
	var root := Node3D.new()
	root.name = "CombatBurst"
	host.add_child(root)
	root.global_position = world_position

	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.42 * effect_scale
	flash_mesh.height = 0.84 * effect_scale
	flash_mesh.radial_segments = 16
	flash_mesh.rings = 8
	var flash_material := StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_material.albedo_color = Color(tint.r, tint.g, tint.b, 0.72)
	flash_material.emission_enabled = true
	flash_material.emission = tint
	flash_material.emission_energy_multiplier = 4.5
	flash.mesh = flash_mesh
	flash.material_override = flash_material
	root.add_child(flash)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.32 * effect_scale
	ring_mesh.outer_radius = 0.43 * effect_scale
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.albedo_color = Color(tint.r, tint.g, tint.b, 0.65)
	ring_material.emission_enabled = true
	ring_material.emission = tint
	ring_material.emission_energy_multiplier = 2.4
	ring.mesh = ring_mesh
	ring.material_override = ring_material
	ring.scale = Vector3.ONE * 0.15
	root.add_child(ring)

	var particles := GPUParticles3D.new()
	particles.amount = 42 if effect_scale < 1.0 else 88
	particles.lifetime = 0.72
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 1.0
	particles.local_coords = true
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 5.0 * effect_scale
	process.initial_velocity_max = 17.0 * effect_scale
	process.gravity = Vector3.ZERO
	process.damping_min = 0.5
	process.damping_max = 2.2
	process.scale_min = 0.055 * effect_scale
	process.scale_max = 0.15 * effect_scale
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.94, 0.78, 1.0))
	gradient.add_point(0.28, tint)
	gradient.add_point(0.72, Color(tint.r * 0.55, tint.g * 0.42, tint.b * 0.34, 0.55))
	gradient.set_color(gradient.get_point_count() - 1, Color(tint.r, tint.g, tint.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	particles.process_material = process
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.11 * effect_scale
	particle_mesh.height = 0.22 * effect_scale
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	var particle_material := StandardMaterial3D.new()
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_material.albedo_color = tint
	particle_material.emission_enabled = true
	particle_material.emission = tint
	particle_material.emission_energy_multiplier = 3.2
	particle_mesh.material = particle_material
	particles.draw_pass_1 = particle_mesh
	root.add_child(particles)
	particles.emitting = true

	var tween := root.create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 1.8, 0.20)
	tween.parallel().tween_property(flash_material, "albedo_color", Color(tint.r, tint.g, tint.b, 0.0), 0.20)
	tween.parallel().tween_property(ring, "scale", Vector3.ONE * 3.6, 0.52)
	tween.parallel().tween_property(ring_material, "albedo_color", Color(tint.r, tint.g, tint.b, 0.0), 0.52)

	var cleanup := Timer.new()
	cleanup.one_shot = true
	cleanup.wait_time = 1.15
	cleanup.timeout.connect(root.queue_free)
	root.add_child(cleanup)
	cleanup.start()
