extends Node3D
## Deterministic, lightweight space backdrop for the first visual flight slice.
## Uses deterministic procedural layers plus curated NASA and CC0 environment assets.

@export_range(300, 4000, 100) var star_count: int = 3800
@export_range(40, 220, 10) var asteroid_count: int = 160
@export var showcase_mode: bool = false

var _rng := RandomNumberGenerator.new()
var _starfield: MultiMeshInstance3D
var _star_clusters: MultiMeshInstance3D
var _system_id: String = "aurelia"
var _theme: Dictionary = {}
var _planet_visual: MeshInstance3D
var _planet_atmosphere: MeshInstance3D
var _planet_clouds: MeshInstance3D
var _companion_planet: MeshInstance3D
var _companion_rings: MeshInstance3D
var _companion_moon: MeshInstance3D
var _cosmic_dust: MultiMeshInstance3D
var _distant_galaxy: MeshInstance3D
var _stellar_primary: MeshInstance3D
var _stellar_corona: MeshInstance3D
var _stellar_key_light: DirectionalLight3D
var _comet_root: Node3D
var _derelict_root: Node3D
var _orbital_station_root: Node3D
var _traffic_roots: Array[Node3D] = []
var _dust_count: int = 2400
var _applied_quality_preset: int = -1


func _ready() -> void:
	_rng.seed = 741_2026
	var quality := get_node_or_null("/root/GraphicsQuality")
	if quality != null:
		star_count = roundi(3800.0 * float(quality.sky_star_density()) / 2.35)
		asteroid_count = quality.asteroid_count()
		_dust_count = maxi(roundi(2400.0 * float(quality.particle_amount_scale())), 500)
	_load_system_theme()
	_build_world_environment()
	_build_stellar_primary()
	_build_starfield()
	_build_star_clusters()
	_build_nebulae()
	_build_distant_galaxy()
	_build_planet()
	_build_companion_worlds()
	_build_asteroid_field()
	_build_cosmic_dust()
	_build_comet_landmark()
	_build_derelict_landmark()
	_build_orbital_station_landmark()
	_build_distant_traffic()
	_build_gravity_lens_landmark()
	if quality != null:
		apply_quality(quality, false)


func _build_gravity_lens_landmark() -> void:
	var lens := Node3D.new()
	lens.name = "GravitationalLensMass"
	lens.set_script(load("res://scripts/environment/gravity_lens_mass.gd"))
	lens.set("lens_strength", 1.2)
	lens.set("lens_radius", 0.28)
	lens.set("show_debug_core", true)
	lens.position = Vector3(-240.0, 72.0, -430.0)
	add_child(lens)


func apply_quality(quality: Node, rebuild_fields: bool = true) -> void:
	if quality == null:
		return
	var preset_id := int(quality.current)
	var preset_changed := preset_id != _applied_quality_preset
	var desired_stars := roundi(3800.0 * float(quality.sky_star_density()) / 2.35)
	if rebuild_fields and desired_stars != star_count:
		star_count = desired_stars
		if is_instance_valid(_starfield):
			remove_child(_starfield)
			_starfield.queue_free()
		_build_starfield()

	var desired_asteroids: int = quality.asteroid_count()
	if rebuild_fields and desired_asteroids != asteroid_count:
		asteroid_count = desired_asteroids
		for node_name in ["AsteroidField", "KenneyMeteorVariants"]:
			var old_field := get_node_or_null(node_name)
			if old_field != null:
				remove_child(old_field)
				old_field.queue_free()
		for child in get_children():
			if child.name.begins_with("AsteroidCollision_"):
				remove_child(child)
				child.queue_free()
		_build_asteroid_field()

	var desired_dust := maxi(roundi(2400.0 * float(quality.particle_amount_scale())), 500)
	if rebuild_fields and desired_dust != _dust_count:
		_dust_count = desired_dust
		if is_instance_valid(_cosmic_dust):
			remove_child(_cosmic_dust)
			_cosmic_dust.queue_free()
		_build_cosmic_dust()

	if preset_changed and rebuild_fields:
		for node_name in ["PrimaryNebula", "SecondaryNebula", "TertiaryNebula", "FarNebula", "DistantSpiralGalaxy"]:
			var old_visual := get_node_or_null(NodePath(node_name))
			if old_visual != null:
				remove_child(old_visual)
				old_visual.queue_free()
		_build_nebulae()
		_build_distant_galaxy()
	_apply_planet_quality(quality.planet_segments() * 2)
	_applied_quality_preset = preset_id

	var world_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_node != null and world_node.environment != null:
		var environment := world_node.environment
		environment.tonemap_mode = quality.tonemap_mode()
		environment.tonemap_exposure = quality.tonemap_exposure()
		environment.tonemap_white = quality.tonemap_white()
		environment.glow_enabled = quality.glow_enabled()
		environment.glow_intensity = quality.glow_intensity()
		environment.glow_bloom = quality.glow_bloom()
		environment.glow_hdr_threshold = quality.glow_hdr_threshold()
		environment.glow_hdr_scale = quality.glow_hdr_scale()
		environment.glow_hdr_luminance_cap = quality.glow_hdr_luminance_cap()
		environment.glow_strength = quality.glow_strength()
		environment.ssao_enabled = quality.ssao_enabled()
		environment.adjustment_enabled = quality.adjustment_enabled()
		if environment.adjustment_enabled:
			environment.adjustment_contrast = quality.adjustment_contrast()
			environment.adjustment_saturation = quality.adjustment_saturation()
		quality.apply_tonemap_extras(environment)

	if is_instance_valid(_stellar_key_light):
		_stellar_key_light.shadow_enabled = quality.shadow_enabled()
		_stellar_key_light.directional_shadow_max_distance = quality.shadow_max_distance()
		_stellar_key_light.directional_shadow_mode = quality.shadow_splits() as DirectionalLight3D.ShadowMode


func _apply_planet_quality(segments: int) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.mesh is SphereMesh:
			var sphere := child.mesh as SphereMesh
			sphere.radial_segments = maxi(segments, 24)
			sphere.rings = maxi(segments / 2, 12)


func _process(delta: float) -> void:
	if not is_instance_valid(_starfield):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if showcase_mode:
		_update_showcase_landmarks()
		return

	# Keep the distant sky landmarks around the active ship. The mission spans
	# tens of kilometres; static backdrop geometry would otherwise be left
	# behind at the starting carrier and leave later combat shots almost black.
	_starfield.global_position = camera.global_position
	if is_instance_valid(_star_clusters):
		_star_clusters.global_position = camera.global_position
	var camera_transform := camera.global_transform
	if is_instance_valid(_stellar_key_light):
		var incoming_light := camera.global_basis * Vector3(620.0, -285.0, 3200.0).normalized()
		_stellar_key_light.global_basis = Basis.looking_at(incoming_light, camera.global_basis.y)
	var star_transform := camera_transform * Transform3D(Basis.IDENTITY, Vector3(-620.0, 285.0, -3200.0))
	if is_instance_valid(_stellar_primary):
		_stellar_primary.global_transform = star_transform
		_stellar_primary.rotate_y(delta * 0.0018)
	if is_instance_valid(_stellar_corona):
		_stellar_corona.global_transform = star_transform
	var primary_nebula := get_node_or_null("PrimaryNebula") as Node3D
	if primary_nebula != null:
		primary_nebula.global_transform = camera_transform * Transform3D(Basis.IDENTITY, Vector3(-138.0, 54.0, -465.0))
	var secondary_nebula := get_node_or_null("SecondaryNebula") as Node3D
	if secondary_nebula != null:
		secondary_nebula.global_transform = camera_transform * Transform3D(Basis.IDENTITY, Vector3(158.0, -42.0, -520.0))
	var tertiary_nebula := get_node_or_null("TertiaryNebula") as Node3D
	if tertiary_nebula != null:
		tertiary_nebula.global_transform = camera_transform * Transform3D(Basis(Vector3.FORWARD, deg_to_rad(18.0)), Vector3(-265.0, -112.0, -760.0))
	var far_nebula := get_node_or_null("FarNebula") as Node3D
	if far_nebula != null:
		far_nebula.global_transform = camera_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(24.0)), Vector3(285.0, 185.0, -1120.0))
	if is_instance_valid(_distant_galaxy):
		_distant_galaxy.global_transform = camera_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-18.0)), Vector3(35.0, 148.0, -920.0))

	# Aurelia is a distant sky landmark, not a nearby world object. Keep its
	# visual shell camera-relative; its physical collision proxy remains fixed
	# so long-range mission shots retain a readable planetary horizon.
	var planet_position := camera.global_position + camera.global_basis * Vector3(-160.0, 26.0, -285.0)
	if is_instance_valid(_planet_visual):
		_planet_visual.global_position = planet_position
	if is_instance_valid(_planet_atmosphere):
		_planet_atmosphere.global_position = planet_position
	if is_instance_valid(_planet_clouds):
		_planet_clouds.global_position = planet_position
		_planet_clouds.rotate_y(delta * 0.0038)
	if is_instance_valid(_companion_planet):
		_companion_planet.global_position = camera.global_position + camera.global_basis * Vector3(430.0, -92.0, -1320.0)
		_companion_planet.rotate_y(delta * 0.003)
	if is_instance_valid(_companion_rings):
		var ring_position := camera.global_position + camera.global_basis * Vector3(430.0, -92.0, -1320.0)
		var ring_basis := camera.global_basis * Basis(Vector3.RIGHT, deg_to_rad(32.0))
		_companion_rings.global_transform = Transform3D(ring_basis.scaled(Vector3.ONE * 100.0), ring_position)
	if is_instance_valid(_companion_moon):
		_companion_moon.global_position = camera.global_position + camera.global_basis * Vector3(620.0, -12.0, -1430.0)
		_companion_moon.rotate_y(delta * 0.012)
	if is_instance_valid(_comet_root):
		var comet_transform := camera_transform * Transform3D(Basis(Vector3(0.2, 0.8, 0.1).normalized(), delta * 0.012), Vector3(-520.0, 205.0, -1880.0))
		_comet_root.global_transform = comet_transform
	if is_instance_valid(_derelict_root):
		var derelict_transform := camera_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-24.0)), Vector3(285.0, -118.0, -690.0))
		_derelict_root.global_transform = derelict_transform
	if is_instance_valid(_orbital_station_root):
		_orbital_station_root.global_transform = camera_transform * Transform3D(Basis(Vector3(0.18, 0.92, -0.12).normalized(), deg_to_rad(8.0)), Vector3(-560.0, 185.0, -2140.0))
	var traffic_offsets: Array[Vector3] = [Vector3(310.0, 82.0, -760.0), Vector3(-420.0, -165.0, -1120.0), Vector3(165.0, 245.0, -1480.0)]
	var traffic_rotations: Array[float] = [12.0, -36.0, 74.0]
	for index in range(mini(_traffic_roots.size(), traffic_offsets.size())):
		_traffic_roots[index].global_transform = camera_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(traffic_rotations[index])), traffic_offsets[index])


func _update_showcase_landmarks() -> void:
	# Fixed world-space placement is used only by the screenshot showcase.
	# Normal gameplay remains camera-relative so the long mission route keeps
	# its sky landmarks in view without adding world-scale streaming complexity.
	if is_instance_valid(_starfield):
		_starfield.global_position = Vector3.ZERO
	if is_instance_valid(_star_clusters):
		_star_clusters.global_position = Vector3.ZERO
	if is_instance_valid(_stellar_primary):
		_stellar_primary.global_transform = Transform3D(Basis.IDENTITY, Vector3(-620.0, 285.0, -3200.0))
	if is_instance_valid(_stellar_corona):
		_stellar_corona.global_transform = Transform3D(Basis.IDENTITY, Vector3(-620.0, 285.0, -3200.0))
	if is_instance_valid(_stellar_key_light):
		var incoming_light := Vector3(620.0, -285.0, 3200.0).normalized()
		_stellar_key_light.global_basis = Basis.looking_at(incoming_light, Vector3.UP)
	var primary_nebula := get_node_or_null("PrimaryNebula") as Node3D
	if primary_nebula != null:
		primary_nebula.global_transform = Transform3D(Basis.IDENTITY, Vector3(-138.0, 54.0, -465.0))
	var secondary_nebula := get_node_or_null("SecondaryNebula") as Node3D
	if secondary_nebula != null:
		secondary_nebula.global_transform = Transform3D(Basis.IDENTITY, Vector3(158.0, -42.0, -520.0))
	var tertiary_nebula := get_node_or_null("TertiaryNebula") as Node3D
	if tertiary_nebula != null:
		tertiary_nebula.global_transform = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(18.0)), Vector3(-265.0, -112.0, -760.0))
	var far_nebula := get_node_or_null("FarNebula") as Node3D
	if far_nebula != null:
		far_nebula.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(24.0)), Vector3(285.0, 185.0, -1120.0))
	if is_instance_valid(_distant_galaxy):
		_distant_galaxy.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-18.0)), Vector3(35.0, 148.0, -920.0))
	if is_instance_valid(_planet_visual):
		_planet_visual.global_position = Vector3(-160.0, 26.0, -285.0)
	if is_instance_valid(_planet_atmosphere):
		_planet_atmosphere.global_position = Vector3(-160.0, 26.0, -285.0)
	if is_instance_valid(_planet_clouds):
		_planet_clouds.global_position = Vector3(-160.0, 26.0, -285.0)
	if is_instance_valid(_companion_planet):
		_companion_planet.global_position = Vector3(430.0, -92.0, -1320.0)
	if is_instance_valid(_companion_rings):
		var ring_basis := Basis(Vector3.RIGHT, deg_to_rad(68.0)).scaled(Vector3.ONE * 100.0)
		_companion_rings.global_transform = Transform3D(ring_basis, Vector3(430.0, -92.0, -1320.0))
	if is_instance_valid(_companion_moon):
		_companion_moon.global_position = Vector3(620.0, -12.0, -1430.0)
	if is_instance_valid(_comet_root):
		_comet_root.global_transform = Transform3D(Basis(Vector3(0.2, 0.8, 0.1).normalized(), 0.0), Vector3(-520.0, 205.0, -1880.0))
	if is_instance_valid(_derelict_root):
		_derelict_root.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-24.0)), Vector3(285.0, -118.0, -690.0))
	if is_instance_valid(_orbital_station_root):
		_orbital_station_root.global_transform = Transform3D(Basis(Vector3(0.18, 0.92, -0.12).normalized(), deg_to_rad(8.0)), Vector3(-560.0, 185.0, -2140.0))
	var traffic_offsets: Array[Vector3] = [Vector3(310.0, 82.0, -760.0), Vector3(-420.0, -165.0, -1120.0), Vector3(165.0, 245.0, -1480.0)]
	var traffic_rotations: Array[float] = [12.0, -36.0, 74.0]
	for index in range(mini(_traffic_roots.size(), traffic_offsets.size())):
		_traffic_roots[index].global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(traffic_rotations[index])), traffic_offsets[index])



func _load_system_theme() -> void:
	var profile := get_node_or_null("/root/GameProfile")
	var system: Dictionary = profile.call("get_active_system") if profile != null else {"id": "aurelia", "asteroid_density": 120}
	_system_id = str(system.get("id", "aurelia"))
	asteroid_count = int(system.get("asteroid_density", 120))
	match _system_id:
		"vesper":
			_theme = {
				"sky_top": Color(0.020, 0.008, 0.003), "sky_horizon": Color(0.12, 0.045, 0.020),
				"ambient": Color(0.42, 0.24, 0.12), "key_light": Color(1.0, 0.72, 0.42),
				"fill_light": Color(0.72, 0.28, 0.10), "nebula_a": Color(1.0, 0.38, 0.08, 0.18),
				"nebula_b": Color(0.72, 0.14, 0.04, 0.14), "atmosphere": Color(0.95, 0.36, 0.10, 0.14),
				"water_dark": Color(0.05, 0.03, 0.02), "water_light": Color(0.18, 0.08, 0.04),
				"land_low": Color(0.34, 0.18, 0.08), "land_high": Color(0.58, 0.30, 0.12),
				"snow": Color(0.82, 0.62, 0.38), "star": Color(1.0, 0.76, 0.52), "asteroid_tint": Color(0.48, 0.31, 0.22), "gas_dark": Color(0.18, 0.07, 0.035), "gas_light": Color(0.48, 0.20, 0.09), "gas_highlight": Color(0.75, 0.46, 0.24), "ring_tint": Color(0.90, 0.52, 0.24)
			}
		"kestrel":
			_theme = {
				"sky_top": Color(0.005, 0.012, 0.035), "sky_horizon": Color(0.025, 0.09, 0.15),
				"ambient": Color(0.20, 0.38, 0.56), "key_light": Color(0.62, 0.85, 1.0),
				"fill_light": Color(0.12, 0.46, 0.78), "nebula_a": Color(0.10, 0.72, 0.95, 0.16),
				"nebula_b": Color(0.42, 0.28, 0.95, 0.12), "atmosphere": Color(0.12, 0.62, 1.0, 0.16),
				"water_dark": Color(0.015, 0.08, 0.18), "water_light": Color(0.05, 0.22, 0.42),
				"land_low": Color(0.22, 0.36, 0.52), "land_high": Color(0.44, 0.55, 0.65),
				"snow": Color(0.86, 0.92, 1.0), "star": Color(0.70, 0.88, 1.0), "asteroid_tint": Color(0.34, 0.48, 0.62), "gas_dark": Color(0.055, 0.12, 0.20), "gas_light": Color(0.20, 0.38, 0.52), "gas_highlight": Color(0.58, 0.76, 0.90), "ring_tint": Color(0.48, 0.75, 0.95)
			}
		_:
			_system_id = "aurelia"
			_theme = {
				"sky_top": Color(0.004, 0.009, 0.028), "sky_horizon": Color(0.025, 0.045, 0.09),
				"ambient": Color(0.22, 0.31, 0.52), "key_light": Color(0.72, 0.82, 1.0),
				"fill_light": Color(0.20, 0.38, 0.72), "nebula_a": Color(0.16, 0.40, 1.0, 0.16),
				"nebula_b": Color(0.52, 0.20, 0.94, 0.12), "atmosphere": Color(0.12, 0.42, 0.95, 0.12),
				"water_dark": Color(0.018, 0.075, 0.16), "water_light": Color(0.035, 0.19, 0.31),
				"land_low": Color(0.18, 0.34, 0.31), "land_high": Color(0.43, 0.38, 0.25),
				"snow": Color(0.78, 0.79, 0.72), "star": Color(0.72, 0.84, 1.0), "asteroid_tint": Color(0.48, 0.52, 0.56), "gas_dark": Color(0.19, 0.105, 0.075), "gas_light": Color(0.58, 0.39, 0.27), "gas_highlight": Color(0.76, 0.62, 0.46), "ring_tint": Color(0.68, 0.54, 0.38)
			}


func _build_world_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.002, 0.004, 0.012)
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = _theme.get("sky_top", Color(0.004, 0.009, 0.028))
	sky_material.sky_horizon_color = _theme.get("sky_horizon", Color(0.025, 0.045, 0.09))
	sky_material.ground_bottom_color = sky_material.sky_top_color
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _theme.get("ambient", Color(0.22, 0.31, 0.52))
	environment.ambient_light_energy = 0.88
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.68
	environment.glow_strength = 0.86
	environment.ssao_enabled = true
	environment.ssao_radius = 1.35
	environment.ssao_intensity = 0.62
	environment.ssil_enabled = false
	environment.ssil_radius = 5.0
	environment.ssil_intensity = 0.65
	environment.sdfgi_enabled = false
	environment.sdfgi_cascades = 4
	environment.sdfgi_min_cell_size = 0.2
	world.environment = environment
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.name = "StellarKeyLight"
	key_light.rotation_degrees = Vector3(-24.0, 32.0, 0.0)
	key_light.light_color = _theme.get("key_light", Color(0.72, 0.82, 1.0))
	key_light.light_energy = 1.82
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 260.0
	_stellar_key_light = key_light
	add_child(key_light)

	# Low-energy blue fill preserves hull readability on the shadow side while
	# keeping the scene recognizably lit by a single stellar key source.
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "NebulaFillLight"
	fill_light.rotation_degrees = Vector3(-12.0, -148.0, 0.0)
	fill_light.light_color = _theme.get("fill_light", Color(0.20, 0.38, 0.72))
	fill_light.light_energy = 0.48
	fill_light.shadow_enabled = false
	add_child(fill_light)


func _build_stellar_primary() -> void:
	# A visible system star anchors the sky and gives the flight scene a strong
	# light source landmark, with a turbulent plasma surface and soft corona.
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 1.0
	star_mesh.height = 2.0
	star_mesh.radial_segments = 96
	star_mesh.rings = 64
	var star_shader := Shader.new()
	star_shader.code = """
shader_type spatial;
render_mode unshaded;
uniform vec4 star_low : source_color = vec4(0.72, 0.12, 0.025, 1.0);
uniform vec4 star_high : source_color = vec4(1.0, 0.78, 0.28, 1.0);
void fragment() {
	vec2 p = UV * vec2(58.0, 30.0);
	float convection = sin(p.x * 0.72 + sin(p.y * 0.83 + TIME * 0.11) * 2.8 + TIME * 0.16)
		* cos(p.y * 0.91 - TIME * 0.08);
	float granulation = sin(UV.x * 173.0 + sin(UV.y * 91.0 + TIME * 0.07) * 3.0)
		* sin(UV.y * 137.0 - TIME * 0.09) * 0.18;
	float plasma = clamp(0.52 + convection * 0.30 + granulation, 0.0, 1.0);
	vec3 color = mix(star_low.rgb, star_high.rgb, smoothstep(0.12, 0.88, plasma));
	ALBEDO = color;
	EMISSION = color * (1.8 + plasma * 2.2);
}
"""
	var star_material := ShaderMaterial.new()
	star_material.shader = star_shader
	var hot_color: Color = _theme.get("key_light", Color(0.72, 0.82, 1.0))
	var cool_color := hot_color.lerp(Color(0.82, 0.12, 0.025), 0.42)
	star_material.set_shader_parameter("star_low", cool_color)
	star_material.set_shader_parameter("star_high", hot_color.lerp(Color.WHITE, 0.38))
	star_mesh.material = star_material
	_stellar_primary = MeshInstance3D.new()
	_stellar_primary.name = "StellarPrimary"
	_stellar_primary.mesh = star_mesh
	_stellar_primary.scale = Vector3.ONE * 72.0
	add_child(_stellar_primary)

	var corona_mesh := SphereMesh.new()
	corona_mesh.radius = 1.0
	corona_mesh.height = 2.0
	corona_mesh.radial_segments = 64
	corona_mesh.rings = 32
	var corona_shader := Shader.new()
	corona_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 corona_tint : source_color = vec4(1.0, 0.52, 0.18, 0.30);
void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, 2.35);
	float waves = 0.86 + 0.14 * sin(UV.x * 34.0 + TIME * 0.12 + sin(UV.y * 18.0));
	ALBEDO = corona_tint.rgb;
	EMISSION = corona_tint.rgb * (0.28 + rim * 1.7) * waves;
	ALPHA = rim * corona_tint.a;
}
"""
	var corona_material := ShaderMaterial.new()
	corona_material.shader = corona_shader
	corona_material.set_shader_parameter("corona_tint", Color(hot_color.r, hot_color.g, hot_color.b, 0.30))
	corona_mesh.material = corona_material
	_stellar_corona = MeshInstance3D.new()
	_stellar_corona.name = "StellarCorona"
	_stellar_corona.mesh = corona_mesh
	_stellar_corona.scale = Vector3.ONE * 92.0
	add_child(_stellar_corona)


func _build_starfield() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.38
	star_mesh.height = 0.76
	star_mesh.radial_segments = 6
	star_mesh.rings = 4

	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = _theme.get("star", Color(0.72, 0.84, 1.0))
	star_material.emission_enabled = true
	star_material.emission = _theme.get("star", Color(0.56, 0.76, 1.0))
	var quality := get_node_or_null("/root/GraphicsQuality")
	var star_brightness := float(quality.sky_star_brightness()) / 1.3 if quality != null else 1.0
	star_material.emission_energy_multiplier = 2.25 * star_brightness
	star_mesh.material = star_material

	_starfield = _make_multimesh("Starfield", star_mesh, star_count)
	for index in range(star_count):
		var direction := _random_unit_vector()
		var distance := _rng.randf_range(520.0, 980.0)
		var size := _rng.randf_range(1.15, 3.4)
		var transform := Transform3D(Basis.from_scale(Vector3.ONE * size), direction * distance)
		_starfield.multimesh.set_instance_transform(index, transform)
	add_child(_starfield)


func _build_nebulae() -> void:
	_add_nebula(
		"PrimaryNebula",
		Vector3(-138.0, 54.0, -465.0),
		Vector2(310.0, 178.0),
		_theme.get("nebula_a", Color(0.16, 0.40, 1.0, 0.38)),
		1138
	)
	_add_nebula(
		"SecondaryNebula",
		Vector3(158.0, -42.0, -520.0),
		Vector2(270.0, 152.0),
		_theme.get("nebula_b", Color(0.52, 0.20, 0.94, 0.32)),
		8821
	)
	_add_nebula("TertiaryNebula", Vector3(-265.0, -112.0, -760.0), Vector2(360.0, 220.0), _theme.get("nebula_b", Color(0.52, 0.20, 0.94, 0.32)) * Color(1.0, 1.0, 1.0, 0.62), 29117)
	_add_nebula("FarNebula", Vector3(285.0, 185.0, -1120.0), Vector2(430.0, 270.0), _theme.get("nebula_a", Color(0.16, 0.40, 1.0, 0.38)) * Color(1.0, 1.0, 1.0, 0.44), 77291)


func _add_nebula(node_name: String, position: Vector3, dimensions: Vector2, tint: Color, seed_value: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 6
	noise.fractal_lacunarity = 2.1
	noise.fractal_gain = 0.52
	noise.frequency = 0.72

	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.width = 768
	noise_texture.height = 768
	noise_texture.seamless = true
	noise_texture.generate_mipmaps = true

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform sampler2D nebula_noise : repeat_enable, filter_linear_mipmap;
uniform vec4 nebula_tint : source_color = vec4(0.2, 0.4, 1.0, 0.2);

void fragment() {
	vec2 drift = vec2(TIME * 0.0015, -TIME * 0.0007);
	vec2 uv_a = UV * vec2(2.3, 1.8) + drift;
	vec2 uv_b = UV * vec2(4.1, 3.2) - drift * 0.7 + vec2(0.23, 0.41);
	float broad = texture(nebula_noise, uv_a).r;
	float detail = texture(nebula_noise, uv_b).r;
	float micro = texture(nebula_noise, UV * vec2(8.2, 6.5) + drift * 1.7 + vec2(0.17, 0.63)).r;
	float cloud = broad * 0.60 + detail * 0.27 + micro * 0.13;
	float ridges = 1.0 - abs(cloud * 2.0 - 1.0);
	float filaments = smoothstep(0.34, 0.72, cloud) * (0.78 + ridges * 0.34);
	float wisps = smoothstep(0.49, 0.82, detail) * 0.22 + smoothstep(0.72, 0.91, micro) * 0.12;
	vec2 centered = UV * 2.0 - 1.0;
	float edge_fade = 1.0 - smoothstep(0.42, 1.0, length(centered));
	float alpha = clamp((filaments + wisps) * nebula_tint.a * edge_fade, 0.0, 0.36);
	ALBEDO = nebula_tint.rgb;
	EMISSION = nebula_tint.rgb * (0.45 + filaments * 1.8);
	ALPHA = alpha;
}
"""
	var quality := get_node_or_null("/root/GraphicsQuality")
	if quality != null:
		tint.a *= float(quality.sky_nebula_strength()) / 0.58
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("nebula_noise", noise_texture)
	material.set_shader_parameter("nebula_tint", tint)

	var quad := QuadMesh.new()
	quad.size = dimensions
	quad.material = material

	var cloud := MeshInstance3D.new()
	cloud.name = node_name
	cloud.mesh = quad
	cloud.position = position
	cloud.rotation_degrees = Vector3(8.0, 0.0, -4.0)
	add_child(cloud)


func _build_distant_galaxy() -> void:
	# A procedural spiral galaxy adds a recognisable deep-space landmark behind the local nebula layers.
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 galaxy_tint : source_color = vec4(0.62, 0.68, 0.82, 0.34);
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise21(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(2.0, 1.35);
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float spiral_phase = angle * 2.0 + radius * 13.5;
	float arm_a = pow(max(cos(spiral_phase), 0.0), 7.0);
	float arm_b = pow(max(cos(spiral_phase + 3.14159), 0.0), 7.0);
	float spiral_arms = (arm_a + arm_b) * exp(-radius * 1.55);
	float disk = exp(-pow(abs(p.y) * 3.8, 1.35)) * exp(-radius * 1.35);
	float clouds = noise21(UV * vec2(32.0, 18.0)) * 0.52
		+ noise21(UV * vec2(78.0, 43.0)) * 0.30
		+ noise21(UV * vec2(154.0, 86.0)) * 0.18;
	float dust_lane = smoothstep(0.42, 0.72, clouds) * 0.34;
	float core = exp(-radius * 8.0) * 0.82;
	float edge = 1.0 - smoothstep(0.62, 1.0, radius);
	float arm_detail = spiral_arms * (0.34 + clouds * 0.66) * (1.0 - dust_lane * 0.72);
	float intensity = max(0.0, disk * (0.12 + clouds * 0.30) + arm_detail * 0.88 + core) * edge;
	ALBEDO = galaxy_tint.rgb;
	EMISSION = galaxy_tint.rgb * (0.06 + intensity * 1.15);
	ALPHA = clamp(intensity * galaxy_tint.a, 0.0, 0.28);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var tint: Color = _theme.get("star", Color(0.72, 0.84, 1.0))
	var quality := get_node_or_null("/root/GraphicsQuality")
	var galaxy_strength := float(quality.sky_galactic_strength()) / 0.42 if quality != null else 1.0
	material.set_shader_parameter("galaxy_tint", Color(tint.r * 0.86, tint.g * 0.88, tint.b * 0.96, 0.34 * galaxy_strength))
	var quad := QuadMesh.new()
	quad.size = Vector2(340.0, 188.0)
	quad.material = material
	_distant_galaxy = MeshInstance3D.new()
	_distant_galaxy.name = "DistantSpiralGalaxy"
	_distant_galaxy.mesh = quad
	add_child(_distant_galaxy)

func _build_star_clusters() -> void:
	# Camera-relative clusters add foreground depth; per-instance color and phase
	# keep spectral types distinct while the shader adds restrained scintillation.
	const CLUSTER_COUNT := 6
	const STARS_PER_CLUSTER := 92
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.52
	star_mesh.height = 1.04
	star_mesh.radial_segments = 6
	star_mesh.rings = 4
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded;
varying vec4 star_custom;
void vertex() {
	star_custom = INSTANCE_CUSTOM;
}
void fragment() {
	vec4 tint = star_custom;
	float pulse = 0.82 + 0.18 * sin(TIME * 1.4 + tint.a * 6.28318);
	ALBEDO = tint.rgb * pulse;
	EMISSION = tint.rgb * (1.1 + pulse * 2.4);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	star_mesh.material = material
	var cluster_multimesh := MultiMesh.new()
	cluster_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	cluster_multimesh.use_custom_data = true
	cluster_multimesh.mesh = star_mesh
	cluster_multimesh.instance_count = CLUSTER_COUNT * STARS_PER_CLUSTER
	_star_clusters = MultiMeshInstance3D.new()
	_star_clusters.name = "ChromaticStarClusters"
	_star_clusters.multimesh = cluster_multimesh
	var cluster_directions: Array[Vector3] = [Vector3(-0.72, 0.28, -0.63), Vector3(0.56, 0.48, -0.67), Vector3(-0.12, -0.62, -0.77), Vector3(0.82, -0.18, -0.54), Vector3(-0.88, -0.22, -0.41), Vector3(0.18, 0.82, -0.54)]
	var palettes: Array[Color] = [Color(0.58, 0.76, 1.0), Color(1.0, 0.76, 0.52), Color(0.72, 0.62, 1.0), Color(0.56, 0.94, 0.88), Color(1.0, 0.88, 0.72), Color(0.72, 0.82, 1.0)]
	for cluster_index in range(CLUSTER_COUNT):
		var center := cluster_directions[cluster_index].normalized() * _rng.randf_range(700.0, 1040.0)
		var palette: Color = palettes[cluster_index]
		for star_index in range(STARS_PER_CLUSTER):
			var index := cluster_index * STARS_PER_CLUSTER + star_index
			var position := center + Vector3(_rng.randfn(0.0, 42.0), _rng.randfn(0.0, 42.0), _rng.randfn(0.0, 42.0))
			var size := _rng.randf_range(0.8, 2.6)
			var basis := Basis.from_euler(Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3.ONE * size)
			_star_clusters.multimesh.set_instance_transform(index, Transform3D(basis, position))
			var brightness := _rng.randf_range(0.35, 1.0)
			_star_clusters.multimesh.set_instance_custom_data(index, Color(palette.r * brightness, palette.g * brightness, palette.b * brightness, _rng.randf_range(0.0, 1.0)))
	add_child(_star_clusters)

func _build_planet() -> void:
	var planet := MeshInstance3D.new()
	planet.name = "Aurelia" if _system_id == "aurelia" else "Planet_%s" % _system_id
	planet.position = Vector3(-160.0, 26.0, -285.0)
	planet.scale = Vector3.ONE * 42.0

	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 128
	sphere.rings = 64

	var planet_material := StandardMaterial3D.new()
	planet_material.albedo_texture = _create_planet_texture()
	planet_material.roughness = 0.94
	planet_material.metallic = 0.025
	planet_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sphere.material = planet_material
	planet.mesh = sphere
	_planet_visual = planet
	add_child(planet)
	_build_planet_collision(planet.position)

	var atmosphere := MeshInstance3D.new()
	atmosphere.name = "AureliaAtmosphere" if _system_id == "aurelia" else "PlanetAtmosphere_%s" % _system_id
	atmosphere.position = planet.position
	atmosphere.scale = Vector3.ONE * 43.2
	var atmosphere_mesh := SphereMesh.new()
	atmosphere_mesh.radius = 1.0
	atmosphere_mesh.height = 2.0
	atmosphere_mesh.radial_segments = 96
	atmosphere_mesh.rings = 48
	var atmosphere_material := StandardMaterial3D.new()
	atmosphere_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	atmosphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	atmosphere_material.albedo_color = _theme.get("atmosphere", Color(0.12, 0.42, 0.95, 0.12))
	atmosphere_material.emission_enabled = true
	atmosphere_material.emission = Color(0.025, 0.12, 0.42)
	atmosphere_material.emission_energy_multiplier = 0.35
	atmosphere_mesh.material = atmosphere_material
	atmosphere.mesh = atmosphere_mesh
	_planet_atmosphere = atmosphere
	add_child(atmosphere)

	# A separate, slowly rotating cloud shell gives the nearby world real depth.
	var cloud_shell := MeshInstance3D.new()
	cloud_shell.name = "AureliaCloudLayer" if _system_id == "aurelia" else "PlanetCloudLayer_%s" % _system_id
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 2.0
	cloud_mesh.radial_segments = 96
	cloud_mesh.rings = 48
	var cloud_shader := Shader.new()
	cloud_shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 cloud_tint : source_color = vec4(0.78, 0.86, 1.0, 0.30);
uniform float cloud_coverage = 0.56;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise21(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += noise21(p) * amplitude;
		p = p * 2.03 + vec2(13.7, 7.1);
		amplitude *= 0.5;
	}
	return value;
}
void fragment() {
	vec2 p = UV * vec2(12.0, 6.0);
	p.x += TIME * 0.006;
	float broad = fbm(p);
	float detail = fbm(p * 2.1 + vec2(4.2, 8.7));
	float clouds = broad * 0.72 + detail * 0.28;
	float coverage = smoothstep(cloud_coverage, cloud_coverage + 0.19, clouds);
	float wisps = smoothstep(0.68, 0.86, detail) * 0.16;
	float density = clamp(coverage * 0.82 + wisps, 0.0, 0.72);
	ALBEDO = cloud_tint.rgb;
	EMISSION = cloud_tint.rgb * 0.08;
	ALPHA = density * cloud_tint.a;
}
"""
	var cloud_material := ShaderMaterial.new()
	cloud_material.shader = cloud_shader
	cloud_material.set_shader_parameter("cloud_tint", Color(0.76, 0.84, 1.0, 0.34))
	cloud_material.set_shader_parameter("cloud_coverage", 0.53)
	cloud_mesh.material = cloud_material
	cloud_shell.mesh = cloud_mesh
	cloud_shell.scale = Vector3.ONE * 43.65
	_planet_clouds = cloud_shell
	add_child(cloud_shell)




func _build_companion_worlds() -> void:
	# A second, ringed gas giant and its moon provide a strong distant landmark.
	# They are camera-relative sky bodies, not nearby collision geometry.
	var giant := MeshInstance3D.new()
	giant.name = "NacreonGasGiant"
	var giant_mesh := SphereMesh.new()
	giant_mesh.radius = 1.0
	giant_mesh.height = 2.0
	giant_mesh.radial_segments = 96
	giant_mesh.rings = 48
	var giant_shader := Shader.new()
	giant_shader.code = """
shader_type spatial;
render_mode unshaded;

uniform vec4 band_dark = vec4(0.19, 0.105, 0.075, 1.0);
uniform vec4 band_light = vec4(0.58, 0.39, 0.27, 1.0);
uniform vec4 band_highlight = vec4(0.76, 0.62, 0.46, 1.0);

void fragment() {
	float latitude = UV.y;
	float warp = sin(UV.x * 18.0 + sin(latitude * 21.0) * 1.8) * 0.012;
	float broad_bands = sin((latitude + warp) * 92.0);
	float fine_bands = sin((latitude + warp * 2.0) * 238.0) * 0.12;
	float cloud = smoothstep(-0.25, 0.72, broad_bands + fine_bands);
	vec3 band_color = mix(band_dark.rgb, band_light.rgb, cloud);
	float storm_distance = length(vec2((UV.x - 0.63) * 1.8, UV.y - 0.43));
	float storm_edge = 1.0 - smoothstep(0.025, 0.105, storm_distance);
	float storm_swirl = sin(atan(UV.y - 0.43, (UV.x - 0.63) * 1.8) * 7.0 + storm_distance * 210.0);
	vec3 storm_color = mix(band_highlight.rgb, band_dark.rgb, smoothstep(-0.4, 0.65, storm_swirl));
	band_color = mix(band_color, storm_color, storm_edge * 0.82);
	ALBEDO = mix(band_color, band_highlight.rgb, smoothstep(0.68, 0.96, broad_bands) * 0.28);
	EMISSION = band_color * 0.24;
	ROUGHNESS = 0.91;
	METALLIC = 0.0;
}
"""
	var giant_material: Material = ShaderMaterial.new()
	var fallback_giant_material := giant_material as ShaderMaterial
	fallback_giant_material.shader = giant_shader
	fallback_giant_material.set_shader_parameter("band_dark", _theme.get("gas_dark", Color(0.19, 0.105, 0.075)))
	fallback_giant_material.set_shader_parameter("band_light", _theme.get("gas_light", Color(0.58, 0.39, 0.27)))
	fallback_giant_material.set_shader_parameter("band_highlight", _theme.get("gas_highlight", Color(0.76, 0.62, 0.46)))
	# Prefer the authored 2K Jupiter map (CC BY 4.0) for natural atmospheric
	# banding and storm detail; keep the procedural shader as an offline fallback.
	var gas_giant_texture: Texture2D
	var gas_giant_image := Image.load_from_file("res://assets/textures/space/jupiter_2k.jpg")
	if gas_giant_image != null and not gas_giant_image.is_empty():
		gas_giant_texture = ImageTexture.create_from_image(gas_giant_image)
	if gas_giant_texture != null:
		var textured_giant := StandardMaterial3D.new()
		textured_giant.albedo_texture = gas_giant_texture
		textured_giant.roughness = 0.94
		textured_giant.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		giant_material = textured_giant
	giant_mesh.material = giant_material
	giant.mesh = giant_mesh
	giant.scale = Vector3.ONE * 82.0
	_companion_planet = giant
	add_child(giant)

	var ring := MeshInstance3D.new()
	ring.name = "NacreonRings"
	var ring_mesh := QuadMesh.new()
	ring_mesh.size = Vector2(3.6, 3.6)
	var ring_shader := Shader.new()
	ring_shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;
uniform vec4 ring_tint : source_color = vec4(0.68, 0.54, 0.38, 1.0);
void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float radius = length(centered);
	if (radius < 0.48 || radius > 0.985) {
		discard;
	}
	float radial = (radius - 0.48) / 0.505;
	float broad = sin(radial * 54.0 + sin(radial * 11.0) * 0.55);
	float fine = sin(radial * 214.0 + sin(radial * 37.0)) * 0.12;
	float bands = smoothstep(-0.18, 0.38, broad + fine);
	float variation = 0.88 + 0.12 * sin(radial * 17.0);
	vec3 color = ring_tint.rgb * variation * mix(0.68, 1.12, bands);
	float edge_fade = 1.0 - smoothstep(0.94, 0.99, radius);
	ALBEDO = color;
	EMISSION = color * 0.035;
	ALPHA = mix(0.045, 0.30, bands) * edge_fade;
}
"""
	var ring_material := ShaderMaterial.new()
	ring_material.shader = ring_shader
	var ring_tint: Color = _theme.get("ring_tint", Color(0.68, 0.54, 0.38))
	ring_material.set_shader_parameter("ring_tint", ring_tint)
	ring_mesh.material = ring_material
	ring.mesh = ring_mesh
	ring.scale = Vector3.ONE * 100.0
	_companion_rings = ring
	add_child(ring)
	# Subtle, translucent sub-bands add scale and particulate variation without
	# turning the gas giant into a wireframe icon.
	_add_ring_detail(ring, "NacreonInnerRing", 0.50, 0.57, 0.045)
	_add_ring_detail(ring, "NacreonOuterRing", 0.83, 0.91, 0.035)
	_add_ring_detail(ring, "NacreonDustBand", 0.64, 0.79, 0.018)

	var moon := MeshInstance3D.new()
	moon.name = "NacreonMoon"
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 1.0
	moon_mesh.height = 2.0
	moon_mesh.radial_segments = 32
	moon_mesh.rings = 16
	var moon_shader := Shader.new()
	moon_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 moon_tint : source_color = vec4(0.66, 0.70, 0.76, 1.0);
float hash22(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash22(i), hash22(i + vec2(1.0, 0.0)), f.x),
		mix(hash22(i + vec2(0.0, 1.0)), hash22(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 grid = UV * vec2(34.0, 17.0);
	vec2 cell = floor(grid);
	vec2 local = fract(grid);
	float seed = hash22(cell);
	vec2 crater_center = vec2(0.5) + vec2(hash22(cell + 3.1), hash22(cell + 7.7)) * 0.30 - 0.15;
	float crater_radius = mix(0.16, 0.43, hash22(cell + 11.3));
	float distance_to_crater = length((local - crater_center) * vec2(1.0, 0.82));
	float crater = 1.0 - smoothstep(crater_radius * 0.66, crater_radius, distance_to_crater);
	float rim = smoothstep(crater_radius * 0.82, crater_radius * 0.96, distance_to_crater)
		* (1.0 - smoothstep(crater_radius * 0.98, crater_radius * 1.18, distance_to_crater));
	float terrain = value_noise(UV * vec2(82.0, 41.0));
	float albedo = 0.66 + terrain * 0.18 - crater * 0.28 + rim * 0.18;
	ALBEDO = moon_tint.rgb * albedo;
	ROUGHNESS = 0.98;
	METALLIC = 0.0;
}
"""
	var moon_material := ShaderMaterial.new()
	moon_material.shader = moon_shader
	moon_material.set_shader_parameter("moon_tint", _theme.get("snow", Color(0.66, 0.70, 0.76)))
	moon_mesh.material = moon_material
	moon.mesh = moon_mesh
	moon.scale = Vector3.ONE * 18.0
	_companion_moon = moon
	add_child(moon)

func _create_planet_texture() -> Texture2D:
	const WIDTH := 1024
	const HEIGHT := 512
	var noise := FastNoiseLite.new()
	noise.seed = 19073
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 6
	noise.fractal_lacunarity = 2.05
	noise.fractal_gain = 0.48
	noise.frequency = 1.32

	var water_dark: Color = _theme.get("water_dark", Color(0.018, 0.075, 0.16))
	var water_light: Color = _theme.get("water_light", Color(0.035, 0.19, 0.31))
	var land_low: Color = _theme.get("land_low", Color(0.18, 0.34, 0.31))
	var land_high: Color = _theme.get("land_high", Color(0.43, 0.38, 0.25))
	var snow: Color = _theme.get("snow", Color(0.78, 0.79, 0.72))
	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = 48291
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = 4
	detail_noise.frequency = 5.8
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	for y in range(HEIGHT):
		var latitude := (float(y) / float(HEIGHT - 1) - 0.5) * PI
		for x in range(WIDTH):
			var longitude := (float(x) / float(WIDTH - 1) - 0.5) * TAU
			var direction := Vector3(
				cos(latitude) * cos(longitude),
				sin(latitude),
				cos(latitude) * sin(longitude)
			)
			var value := noise.get_noise_3d(direction.x * 2.8, direction.y * 2.8, direction.z * 2.8)
			var surface_detail := detail_noise.get_noise_3d(direction.x * 5.8, direction.y * 5.8, direction.z * 5.8)
			value += surface_detail * 0.075
			var color: Color
			if value < -0.18:
				color = water_dark.lerp(water_light, clampf((value + 1.0) / 0.82, 0.0, 1.0))
			elif value < 0.02:
				color = water_light.lerp(land_low, (value + 0.18) / 0.20)
			elif value < 0.30:
				color = land_low.lerp(land_high, (value - 0.02) / 0.28)
			else:
				color = land_high.lerp(snow, clampf((value - 0.30) / 0.45, 0.0, 1.0))
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _load_glb_mesh(source_path: String) -> Mesh:
	if not FileAccess.file_exists(source_path):
		push_warning("GLB asset is missing: %s" % source_path)
		return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(source_path, state)
	if error != OK:
		push_warning("GLB asset could not be parsed: %s (error %d)" % [source_path, error])
		return null
	var instance := document.generate_scene(state)
	if instance == null:
		push_warning("GLB asset generated an empty scene: %s" % source_path)
		return null
	var mesh := _find_first_mesh(instance)
	instance.free()
	if mesh == null:
		push_warning("GLB asset contains no MeshInstance3D: %s" % source_path)
		return null
	return mesh.duplicate(true) as Mesh


func _load_nasa_asteroid_mesh() -> Mesh:
	return _load_glb_mesh("res://assets/models/environment/1999_rq36_asteroid.glb")


func _find_first_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			return mesh_instance.mesh
	for child in node.get_children():
		var found := _find_first_mesh(child)
		if found != null:
			return found
	return null


func _build_asteroid_field() -> void:
	# Use NASA's authored asteroid geometry and embedded materials for the
	# actual debris field; retain a procedural mesh only as a safe fallback.
	var asteroid_mesh: Mesh = _load_nasa_asteroid_mesh()
	var using_nasa_asset := asteroid_mesh != null
	if asteroid_mesh == null:
		# Keep the procedural fallback available on platforms where the imported
		# NASA GLB is unavailable; normal project builds use the real scanned mesh.
		var fallback_mesh := SphereMesh.new()
		fallback_mesh.radius = 1.0
		fallback_mesh.height = 2.0
		fallback_mesh.radial_segments = 20
		fallback_mesh.rings = 12
		asteroid_mesh = fallback_mesh
	var asteroid_shader := Shader.new()
	asteroid_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying float rock_variation;
varying vec4 asteroid_custom;
uniform vec4 rock_tint = vec4(0.48, 0.52, 0.56, 1.0);

void vertex() {
	asteroid_custom = INSTANCE_CUSTOM;
	vec3 p = VERTEX;
	float seed = asteroid_custom.a * 6.28318;
	float broad = sin(p.x * 4.7 + p.y * 2.1 + seed) * cos(p.z * 3.8 - p.x * 1.9 + seed * 0.7);
	float fracture = sin(p.y * 9.3 + p.z * 6.1 + seed * 1.8) * cos(p.x * 8.2 + p.z * 4.4 - seed);
	float chips = sin(p.x * 15.0 + p.y * 11.0 + seed * 2.4) * sin(p.z * 13.0 - p.y * 7.0 + seed);
	float displacement = broad * 0.105 + fracture * 0.042 + chips * 0.014;
	VERTEX += NORMAL * displacement;
	rock_variation = broad * 0.5 + fracture * 0.22 + chips * 0.12;
}

void fragment() {
	float strata = sin(VERTEX.x * 8.0 + VERTEX.y * 5.0 + VERTEX.z * 7.0) * 0.035;
	float value = clamp(0.42 + rock_variation * 0.30 + strata, 0.24, 0.78);
	vec3 mineral_tint = mix(vec3(0.72), vec3(1.18), asteroid_custom.rgb);
	ALBEDO = rock_tint.rgb * value * mineral_tint;
	EMISSION = rock_tint.rgb * value * mineral_tint * 0.14;
	METALLIC = 0.08 + asteroid_custom.g * 0.16;
	ROUGHNESS = 0.94;
}
"""
	var asteroid_material := ShaderMaterial.new()
	asteroid_material.shader = asteroid_shader
	asteroid_material.set_shader_parameter("rock_tint", _theme.get("asteroid_tint", Color(0.48, 0.52, 0.56)))
	# Keep the NASA GLB's authored PBR materials and embedded texture maps.
	# Only the low-detail fallback receives the procedural shader.
	if not using_nasa_asset:
		for surface_index in range(asteroid_mesh.get_surface_count()):
			asteroid_mesh.surface_set_material(surface_index, asteroid_material)

	const RELAY_CLUSTER_COUNT := 28
	var total_asteroid_count := asteroid_count + RELAY_CLUSTER_COUNT
	var asteroid_multimesh := MultiMesh.new()
	asteroid_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	asteroid_multimesh.use_custom_data = true
	asteroid_multimesh.mesh = asteroid_mesh
	asteroid_multimesh.instance_count = total_asteroid_count
	var field := MultiMeshInstance3D.new()
	field.name = "AsteroidField"
	field.multimesh = asteroid_multimesh
	# The mesh instances span a 33 km route; without an explicit world AABB,
	# Godot culls the MultiMesh using only the unit-sphere source mesh bounds.
	field.custom_aabb = AABB(Vector3(-1500.0, -1500.0, -35000.0), Vector3(3000.0, 3000.0, 36000.0))
	for index in range(total_asteroid_count):
		var position: Vector3
		if index < asteroid_count:
			position = _random_asteroid_position()
		else:
			# A denser, navigable debris belt around the relay gives the player
			# a memorable asteroid encounter instead of a few isolated rocks.
			var cluster_angle := _rng.randf_range(0.0, TAU)
			var cluster_radius := _rng.randf_range(120.0, 180.0)
			position = Vector3(
				-250.0 + cos(cluster_angle) * cluster_radius,
				220.0 + sin(cluster_angle) * cluster_radius,
				-13500.0 + _rng.randf_range(-100.0, 100.0)
			)
			# The route returns through this sector; keep every new rock outside
			# both outbound and return corridors, not just the straight relay leg.
			for attempt in range(24):
				var route_distance := _distance_to_route(position)
				if route_distance >= 120.0 and route_distance <= 700.0:
					break
				cluster_angle = _rng.randf_range(0.0, TAU)
				cluster_radius = _rng.randf_range(120.0, 180.0)
				position = Vector3(
					-250.0 + cos(cluster_angle) * cluster_radius,
					220.0 + sin(cluster_angle) * cluster_radius,
					-13500.0 + _rng.randf_range(-100.0, 100.0)
				)
		var size := _rng.randf_range(0.8, 3.8)
		if index >= asteroid_count:
			# Larger relay-sector boulders create a readable close-range field
			# while remaining outside the marked flight corridor.
			size = _rng.randf_range(8.0, 22.0)
		var rotation := Vector3(
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(0.0, TAU)
		)
		var basis := Basis.from_euler(rotation).scaled(Vector3(
			size * _rng.randf_range(0.72, 1.3),
			size * _rng.randf_range(0.65, 1.15),
			size * _rng.randf_range(0.72, 1.25)
		))
		field.multimesh.set_instance_transform(index, Transform3D(basis, position))
		field.multimesh.set_instance_custom_data(index, Color(_rng.randf_range(0.0, 1.0), _rng.randf_range(0.0, 1.0), _rng.randf_range(0.0, 1.0), _rng.randf()))
		_add_asteroid_collision(index, position, size)
	add_child(field)
	_build_asteroid_variants()


func _build_asteroid_variants() -> void:
	# A second silhouette from the CC0 Kenney kit breaks up repetition in the
	# NASA asteroid field without adding hundreds of draw calls.
	var meteor_mesh := _load_glb_mesh("res://assets/models/environment/kenney_meteor_detailed.glb")
	if meteor_mesh == null:
		push_warning("Optional Kenney meteor variant unavailable")
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = meteor_mesh
	multi.instance_count = 18
	var field := MultiMeshInstance3D.new()
	field.name = "KenneyMeteorVariants"
	field.multimesh = multi
	field.custom_aabb = AABB(Vector3(-1500.0, -1500.0, -35000.0), Vector3(3000.0, 3000.0, 36000.0))
	for index in range(multi.instance_count):
		var position := _random_asteroid_position()
		var size := _rng.randf_range(3.0, 9.0)
		var rotation := Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU))
		var basis := Basis.from_euler(rotation).scaled(Vector3(size * 0.9, size * 0.72, size * 1.12))
		multi.set_instance_transform(index, Transform3D(basis, position))
		_add_asteroid_collision(asteroid_count + 100 + index, position, size)
	add_child(field)


func _add_ring_detail(parent: MeshInstance3D, node_name: String, inner_radius: float, outer_radius: float, alpha: float) -> void:
	var band := MeshInstance3D.new()
	band.name = node_name
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 112
	mesh.ring_segments = 10
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tint: Color = _theme.get("ring_tint", Color(0.68, 0.54, 0.38))
	material.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	material.emission_enabled = true
	material.emission = tint * 0.12
	material.emission_energy_multiplier = 0.12
	mesh.material = material
	band.mesh = mesh
	band.rotation_degrees.x = 90.0
	parent.add_child(band)


func _build_cosmic_dust() -> void:
	# Layered, chromatic dust motes trace the long flight corridor. A single
	# custom-data MultiMesh keeps this visual detail out of the physics scene.
	var dust_count := _dust_count
	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.22
	dust_mesh.height = 0.44
	dust_mesh.radial_segments = 5
	dust_mesh.rings = 3
	var dust_shader := Shader.new()
	dust_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
varying vec4 dust_custom;
void vertex() {
	dust_custom = INSTANCE_CUSTOM;
}
void fragment() {
	float shimmer = 0.82 + 0.18 * sin(TIME * 0.65 + dust_custom.a * 6.28318);
	ALBEDO = dust_custom.rgb * shimmer;
	EMISSION = dust_custom.rgb * (0.22 + shimmer * 0.72);
	ALPHA = clamp(dust_custom.a * 0.30, 0.035, 0.24);
}
"""
	var dust_material := ShaderMaterial.new()
	dust_material.shader = dust_shader
	dust_mesh.material = dust_material
	var dust_multimesh := MultiMesh.new()
	dust_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	dust_multimesh.use_custom_data = true
	dust_multimesh.mesh = dust_mesh
	dust_multimesh.instance_count = dust_count
	_cosmic_dust = MultiMeshInstance3D.new()
	_cosmic_dust.name = "InterplanetaryDust"
	_cosmic_dust.multimesh = dust_multimesh
	_cosmic_dust.custom_aabb = AABB(Vector3(-4000.0, -4000.0, -36000.0), Vector3(8000.0, 8000.0, 37000.0))
	var quality := get_node_or_null("/root/GraphicsQuality")
	var dust_strength := float(quality.sky_dust_strength()) / 0.3 if quality != null else 1.0
	var dust_palettes: Array[Color] = [
		Color(0.28, 0.48, 0.82), Color(0.46, 0.62, 0.92),
		Color(0.72, 0.48, 0.34), Color(0.42, 0.72, 0.72),
		Color(0.72, 0.66, 0.52)
	]
	var route_points: Array[Vector3] = [Vector3(0.0, 0.0, 90.0), Vector3(0.0, 18.0, -13500.0), Vector3(520.0, -28.0, -33000.0), Vector3(0.0, 0.0, 90.0)]
	for index in range(dust_count):
		var segment := _rng.randi_range(0, route_points.size() - 2)
		var start := route_points[segment]
		var end := route_points[segment + 1]
		var forward := (end - start).normalized()
		var center := start.lerp(end, _rng.randf_range(0.02, 0.98))
		var axis := Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.92 else Vector3.RIGHT
		var side := forward.cross(axis).normalized()
		var vertical := forward.cross(side).normalized()
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(850.0, 2800.0)
		var position := center + side * cos(angle) * radius + vertical * sin(angle) * radius
		var size := _rng.randf_range(0.35, 1.65)
		# Flattened, irregular flakes catch light differently from spherical stars.
		var basis := Basis.from_euler(Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU))).scaled(Vector3(
			size * _rng.randf_range(0.55, 1.25),
			size * _rng.randf_range(0.35, 0.75),
			size * _rng.randf_range(1.4, 3.2)
		))
		_cosmic_dust.multimesh.set_instance_transform(index, Transform3D(basis, position))
		var tint: Color = dust_palettes[_rng.randi_range(0, dust_palettes.size() - 1)]
		var brightness := _rng.randf_range(0.32, 0.82) * dust_strength
		_cosmic_dust.multimesh.set_instance_custom_data(index, Color(tint.r * brightness, tint.g * brightness, tint.b * brightness, _rng.randf()))
	add_child(_cosmic_dust)


func _random_asteroid_position() -> Vector3:
	var route_points: Array[Vector3] = [
		Vector3(0.0, 0.0, 90.0),
		Vector3(0.0, 18.0, -13500.0),
		Vector3(520.0, -28.0, -33000.0),
		Vector3(0.0, 0.0, 90.0)
	]
	for attempt in range(160):
		var segment_index := _rng.randi_range(0, route_points.size() - 2)
		var start := route_points[segment_index]
		var end := route_points[segment_index + 1]
		var forward := (end - start).normalized()
		var center := start.lerp(end, _rng.randf_range(0.08, 0.92))
		var reference_axis := Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.92 else Vector3.RIGHT
		var side := forward.cross(reference_axis).normalized()
		var vertical := forward.cross(side).normalized()
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(110.0, 720.0)
		var offset := side * cos(angle) * radius + vertical * sin(angle) * radius
		var candidate := center + offset + forward * _rng.randf_range(-90.0, 90.0)
		# Keep the actual navigation corridor clear while populating the full
		# 33 km flight route instead of leaving every asteroid at the carrier.
		var route_distance := _distance_to_route(candidate)
		if route_distance >= 82.0 and route_distance <= 760.0:
			return candidate
	return Vector3(220.0, 160.0, -16500.0)


func _distance_to_route(point: Vector3) -> float:
	var route_points: Array[Vector3] = [
		Vector3(0.0, 18.0, 0.0),
		Vector3(0.0, 18.0, -13500.0),
		Vector3(520.0, -28.0, -33000.0),
		Vector3(0.0, 0.0, 90.0)
	]
	var minimum_distance := INF
	for index in range(route_points.size() - 1):
		var start := route_points[index]
		var end := route_points[index + 1]
		var route := end - start
		var t := clampf((point - start).dot(route) / route.length_squared(), 0.0, 1.0)
		minimum_distance = minf(minimum_distance, point.distance_to(start + route * t))
	return minimum_distance


func _add_asteroid_collision(index: int, position: Vector3, size: float) -> void:
	var body := StaticBody3D.new()
	body.name = "AsteroidCollision_%03d" % index
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("space_obstacles")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = size * 0.9
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _build_planet_collision(position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "AureliaCollision"
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("space_obstacles")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 42.0
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _make_multimesh(node_name: String, mesh: Mesh, count: int) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	return instance


func _random_unit_vector() -> Vector3:
	var vector := Vector3(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0)
	)
	if vector.length_squared() < 0.0001:
		return Vector3.UP
	return vector.normalized()


func _build_comet_landmark() -> void:
	# A camera-relative comet provides a readable moving celestial landmark.
	# Its tail is a single transparent quad; it adds no physics bodies.
	_comet_root = Node3D.new()
	_comet_root.name = "CometLandmark"
	add_child(_comet_root)

	var nucleus := MeshInstance3D.new()
	nucleus.name = "CometNucleus"
	var nucleus_mesh := SphereMesh.new()
	nucleus_mesh.radius = 1.0
	nucleus_mesh.height = 2.0
	nucleus_mesh.radial_segments = 24
	nucleus_mesh.rings = 16
	var nucleus_material := StandardMaterial3D.new()
	nucleus_material.albedo_color = Color(0.40, 0.34, 0.27)
	nucleus_material.roughness = 0.98
	nucleus_material.metallic = 0.04
	nucleus_material.emission_enabled = true
	nucleus_material.emission = Color(0.18, 0.12, 0.07)
	nucleus_material.emission_energy_multiplier = 0.18
	nucleus_mesh.material = nucleus_material
	nucleus.mesh = nucleus_mesh
	nucleus.scale = Vector3(24.0, 17.0, 22.0)
	_comet_root.add_child(nucleus)

	var coma := MeshInstance3D.new()
	coma.name = "CometComa"
	var coma_mesh := SphereMesh.new()
	coma_mesh.radius = 1.0
	coma_mesh.height = 2.0
	coma_mesh.radial_segments = 32
	coma_mesh.rings = 20
	var coma_shader := Shader.new()
	coma_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 coma_tint : source_color = vec4(0.42, 0.76, 1.0, 0.28);
void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, 1.45);
	float turbulence = 0.82 + 0.18 * sin(UV.x * 52.0 + TIME * 0.7) * sin(UV.y * 39.0 - TIME * 0.4);
	ALBEDO = coma_tint.rgb;
	EMISSION = coma_tint.rgb * (0.28 + rim * 1.45) * turbulence;
	ALPHA = (0.07 + rim * 0.24) * coma_tint.a * turbulence;
}
"""
	var coma_material := ShaderMaterial.new()
	coma_material.shader = coma_shader
	coma_material.set_shader_parameter("coma_tint", Color(0.42, 0.76, 1.0, 0.28))
	coma_mesh.material = coma_material
	coma.mesh = coma_mesh
	coma.scale = Vector3(54.0, 42.0, 48.0)
	_comet_root.add_child(coma)

	var tail := MeshInstance3D.new()
	tail.name = "CometIonTail"
	var tail_mesh := QuadMesh.new()
	tail_mesh.size = Vector2(54.0, 310.0)
	var tail_shader := Shader.new()
	tail_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 tail_tint : source_color = vec4(0.46, 0.68, 0.88, 0.075);
void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	float along = UV.y;
	float width = 1.0 - smoothstep(0.08, 0.96, across);
	float fade = pow(1.0 - along, 1.7) * smoothstep(0.0, 0.10, along);
	float stream = 0.78 + 0.22 * sin(UV.x * 34.0 + UV.y * 11.0 - TIME * 0.5);
	float alpha = width * fade * stream * tail_tint.a;
	ALBEDO = tail_tint.rgb;
	EMISSION = tail_tint.rgb * (0.4 + stream * 1.1);
	ALPHA = alpha;
}
"""
	var tail_material := ShaderMaterial.new()
	tail_material.shader = tail_shader
	tail_material.set_shader_parameter("tail_tint", Color(0.46, 0.68, 0.88, 0.075))
	tail_mesh.material = tail_material
	tail.mesh = tail_mesh
	tail.position = Vector3(0.0, 155.0, 2.0)
	tail.rotation_degrees = Vector3(0.0, 0.0, 12.0)
	_comet_root.add_child(tail)


func _build_orbital_station_landmark() -> void:
	# NASA's detailed ISS model adds a recognizable human-made landmark to the
	# deep-space route. It is visual-only and follows the camera like other sky
	# landmarks, so it never changes flight physics or mission collision.
	var station_scene := load("res://assets/models/environment/nasa_iss_station.glb") as PackedScene
	if station_scene == null:
		push_warning("NASA ISS model unavailable; skipping orbital station landmark")
		return
	_orbital_station_root = Node3D.new()
	_orbital_station_root.name = "OrbitalStationLandmark"
	var station := station_scene.instantiate()
	station.name = "NASA_ISS_Visual"
	station.scale = Vector3.ONE * 0.62
	station.rotation_degrees = Vector3(18.0, -24.0, 11.0)
	_orbital_station_root.add_child(station)
	add_child(_orbital_station_root)


func _build_distant_traffic() -> void:
	# Kenney CC0 ships are intentionally used as distant civilian traffic,
	# not as replacements for the game's hero fighters. Their silhouettes add
	# scale and life to the system while remaining small in the Full HD frame.
	var traffic_specs: Array[Dictionary] = [
		{"path": "res://assets/models/environment/kenney_craft_cargo_a.glb", "name": "CivilianCargoA", "scale": 8.0},
		{"path": "res://assets/models/environment/kenney_craft_miner.glb", "name": "CivilianMiner", "scale": 7.0},
		{"path": "res://assets/models/environment/kenney_craft_racer.glb", "name": "CivilianCourier", "scale": 7.5}
	]
	for spec in traffic_specs:
		var packed_scene := load(str(spec.path)) as PackedScene
		if packed_scene == null:
			push_warning("Optional Kenney traffic model unavailable: %s" % spec.path)
			continue
		var root := Node3D.new()
		root.name = str(spec.name)
		var ship := packed_scene.instantiate()
		ship.scale = Vector3.ONE * float(spec.scale)
		root.add_child(ship)
		add_child(root)
		_traffic_roots.append(root)


func _build_derelict_landmark() -> void:
	# A low-poly abandoned courier hull, broken antennae and debris cloud.
	# All pieces are visual-only and share a camera-relative parent.
	_derelict_root = Node3D.new()
	_derelict_root.name = "DerelictWreckLandmark"
	add_child(_derelict_root)

	var hull_material := StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.25, 0.32, 0.40)
	hull_material.metallic = 0.58
	hull_material.roughness = 0.72
	var exposed_material := StandardMaterial3D.new()
	exposed_material.albedo_color = Color(0.42, 0.24, 0.12)
	exposed_material.metallic = 0.48
	exposed_material.roughness = 0.88
	var window_material := StandardMaterial3D.new()
	window_material.albedo_color = Color(0.10, 0.42, 0.58)
	window_material.emission_enabled = true
	window_material.emission = Color(0.08, 0.48, 0.82)
	window_material.emission_energy_multiplier = 0.8

	_add_wreck_box("WreckMainHull", Vector3(0.0, 0.0, 0.0), Vector3(12.0, 5.0, 34.0), hull_material)
	_add_wreck_box("WreckForwardSpine", Vector3(0.0, 0.0, -25.0), Vector3(5.0, 3.0, 22.0), exposed_material)
	_add_wreck_box("WreckPortWing", Vector3(-20.0, -0.8, 2.0), Vector3(29.0, 1.8, 8.0), hull_material)
	_add_wreck_box("WreckStarboardWing", Vector3(19.0, -1.0, 7.0), Vector3(23.0, 1.5, 7.0), exposed_material)
	_add_wreck_box("WreckBrokenPanel", Vector3(-31.0, 1.0, 9.0), Vector3(10.0, 1.0, 13.0), exposed_material)
	_add_wreck_box("WreckBridgeGlass", Vector3(0.0, 3.0, -8.0), Vector3(6.0, 1.2, 8.0), window_material)
	var turret_scene := load("res://assets/models/environment/kenney_turret_double.glb") as PackedScene
	if turret_scene != null:
		var turret := turret_scene.instantiate()
		turret.name = "KenneyDerelictTurret"
		turret.position = Vector3(0.0, 5.0, -18.0)
		turret.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		turret.scale = Vector3.ONE * 2.2
		_derelict_root.add_child(turret)

	var antenna := MeshInstance3D.new()
	antenna.name = "WreckAntenna"
	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.16
	antenna_mesh.bottom_radius = 0.28
	antenna_mesh.height = 18.0
	antenna_mesh.radial_segments = 8
	antenna_mesh.material = exposed_material
	antenna.mesh = antenna_mesh
	antenna.position = Vector3(4.0, 10.0, 12.0)
	antenna.rotation_degrees = Vector3(0.0, 0.0, 18.0)
	_derelict_root.add_child(antenna)

	var beacon := MeshInstance3D.new()
	beacon.name = "WreckEmergencyBeacon"
	var beacon_mesh := SphereMesh.new()
	beacon_mesh.radius = 1.0
	beacon_mesh.height = 2.0
	beacon_mesh.radial_segments = 12
	beacon_mesh.rings = 8
	var beacon_material := StandardMaterial3D.new()
	beacon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beacon_material.albedo_color = Color(1.0, 0.22, 0.08)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.08, 0.025)
	beacon_material.emission_energy_multiplier = 1.6
	beacon_mesh.material = beacon_material
	beacon.mesh = beacon_mesh
	beacon.scale = Vector3.ONE * 1.4
	beacon.position = Vector3(0.0, 7.0, -2.0)
	_derelict_root.add_child(beacon)

	var debris_mesh := SphereMesh.new()
	debris_mesh.radius = 0.7
	debris_mesh.height = 1.4
	debris_mesh.radial_segments = 6
	debris_mesh.rings = 4
	debris_mesh.material = exposed_material
	var debris_multi := MultiMesh.new()
	debris_multi.transform_format = MultiMesh.TRANSFORM_3D
	debris_multi.mesh = debris_mesh
	debris_multi.instance_count = 96
	var debris := MultiMeshInstance3D.new()
	debris.name = "WreckDebrisCloud"
	debris.multimesh = debris_multi
	for index in range(debris_multi.instance_count):
		var direction := _random_unit_vector()
		var radius := _rng.randf_range(24.0, 82.0)
		var position := direction * radius
		var size := _rng.randf_range(0.45, 3.2)
		var basis := Basis.from_euler(Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU))).scaled(Vector3(size, size * _rng.randf_range(0.35, 1.0), size * _rng.randf_range(0.55, 1.4)))
		debris.multimesh.set_instance_transform(index, Transform3D(basis, position))
	_derelict_root.add_child(debris)


func _add_wreck_box(node_name: String, position: Vector3, dimensions: Vector3, material: Material) -> void:
	var piece := MeshInstance3D.new()
	piece.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	piece.mesh = mesh
	piece.position = position
	_derelict_root.add_child(piece)
