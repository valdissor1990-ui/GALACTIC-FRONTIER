extends Node3D
## Deterministic, lightweight space backdrop for the first visual flight slice.
## Uses generated geometry and textures only; no network or third-party assets.

@export_range(300, 4000, 100) var star_count: int = 3200
@export_range(40, 220, 10) var asteroid_count: int = 120

var _rng := RandomNumberGenerator.new()
var _starfield: MultiMeshInstance3D
var _system_id: String = "aurelia"
var _theme: Dictionary = {}
var _planet_visual: MeshInstance3D
var _planet_atmosphere: MeshInstance3D
var _companion_planet: MeshInstance3D
var _companion_rings: MeshInstance3D
var _companion_moon: MeshInstance3D
var _cosmic_dust: MultiMeshInstance3D


func _ready() -> void:
	_rng.seed = 741_2026
	_load_system_theme()
	_build_world_environment()
	_build_starfield()
	_build_nebulae()
	_build_planet()
	_build_companion_worlds()
	_build_asteroid_field()
	_build_cosmic_dust()


func _process(delta: float) -> void:
	if not is_instance_valid(_starfield):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	# Keep the distant sky landmarks around the active ship. The mission spans
	# tens of kilometres; static backdrop geometry would otherwise be left
	# behind at the starting carrier and leave later combat shots almost black.
	_starfield.global_position = camera.global_position
	var camera_transform := camera.global_transform
	var primary_nebula := get_node_or_null("PrimaryNebula") as Node3D
	if primary_nebula != null:
		primary_nebula.global_transform = camera_transform * Transform3D(Basis.IDENTITY, Vector3(-138.0, 54.0, -465.0))
	var secondary_nebula := get_node_or_null("SecondaryNebula") as Node3D
	if secondary_nebula != null:
		secondary_nebula.global_transform = camera_transform * Transform3D(Basis.IDENTITY, Vector3(158.0, -42.0, -520.0))

	# Aurelia is a distant sky landmark, not a nearby world object. Keep its
	# visual shell camera-relative; its physical collision proxy remains fixed
	# so long-range mission shots retain a readable planetary horizon.
	var planet_position := camera.global_position + camera.global_basis * Vector3(-160.0, 26.0, -285.0)
	if is_instance_valid(_planet_visual):
		_planet_visual.global_position = planet_position
	if is_instance_valid(_planet_atmosphere):
		_planet_atmosphere.global_position = planet_position
	if is_instance_valid(_companion_planet):
		_companion_planet.global_position = camera.global_position + camera.global_basis * Vector3(430.0, -92.0, -1320.0)
		_companion_planet.rotate_y(delta * 0.003)
	if is_instance_valid(_companion_rings):
		var ring_position := camera.global_position + camera.global_basis * Vector3(430.0, -92.0, -1320.0)
		var ring_basis := camera.global_basis * Basis(Vector3.RIGHT, deg_to_rad(68.0))
		_companion_rings.global_transform = Transform3D(ring_basis.scaled(Vector3.ONE * 100.0), ring_position)
	if is_instance_valid(_companion_moon):
		_companion_moon.global_position = camera.global_position + camera.global_basis * Vector3(620.0, -12.0, -1430.0)
		_companion_moon.rotate_y(delta * 0.012)



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
				"fill_light": Color(0.72, 0.28, 0.10), "nebula_a": Color(1.0, 0.38, 0.08, 0.42),
				"nebula_b": Color(0.72, 0.14, 0.04, 0.34), "atmosphere": Color(0.95, 0.36, 0.10, 0.14),
				"water_dark": Color(0.05, 0.03, 0.02), "water_light": Color(0.18, 0.08, 0.04),
				"land_low": Color(0.34, 0.18, 0.08), "land_high": Color(0.58, 0.30, 0.12),
				"snow": Color(0.82, 0.62, 0.38), "star": Color(1.0, 0.76, 0.52), "asteroid_tint": Color(0.48, 0.31, 0.22), "gas_dark": Color(0.18, 0.07, 0.035), "gas_light": Color(0.48, 0.20, 0.09), "gas_highlight": Color(0.75, 0.46, 0.24), "ring_tint": Color(0.90, 0.52, 0.24)
			}
		"kestrel":
			_theme = {
				"sky_top": Color(0.005, 0.012, 0.035), "sky_horizon": Color(0.025, 0.09, 0.15),
				"ambient": Color(0.20, 0.38, 0.56), "key_light": Color(0.62, 0.85, 1.0),
				"fill_light": Color(0.12, 0.46, 0.78), "nebula_a": Color(0.10, 0.72, 0.95, 0.36),
				"nebula_b": Color(0.42, 0.28, 0.95, 0.30), "atmosphere": Color(0.12, 0.62, 1.0, 0.16),
				"water_dark": Color(0.015, 0.08, 0.18), "water_light": Color(0.05, 0.22, 0.42),
				"land_low": Color(0.22, 0.36, 0.52), "land_high": Color(0.44, 0.55, 0.65),
				"snow": Color(0.86, 0.92, 1.0), "star": Color(0.70, 0.88, 1.0), "asteroid_tint": Color(0.34, 0.48, 0.62), "gas_dark": Color(0.055, 0.12, 0.20), "gas_light": Color(0.20, 0.38, 0.52), "gas_highlight": Color(0.58, 0.76, 0.90), "ring_tint": Color(0.48, 0.75, 0.95)
			}
		_:
			_system_id = "aurelia"
			_theme = {
				"sky_top": Color(0.004, 0.009, 0.028), "sky_horizon": Color(0.025, 0.045, 0.09),
				"ambient": Color(0.22, 0.31, 0.52), "key_light": Color(0.72, 0.82, 1.0),
				"fill_light": Color(0.20, 0.38, 0.72), "nebula_a": Color(0.16, 0.40, 1.0, 0.38),
				"nebula_b": Color(0.52, 0.20, 0.94, 0.32), "atmosphere": Color(0.12, 0.42, 0.95, 0.12),
				"water_dark": Color(0.018, 0.075, 0.16), "water_light": Color(0.035, 0.19, 0.31),
				"land_low": Color(0.18, 0.34, 0.31), "land_high": Color(0.43, 0.38, 0.25),
				"snow": Color(0.78, 0.79, 0.72), "star": Color(0.72, 0.84, 1.0), "asteroid_tint": Color(0.48, 0.52, 0.56), "gas_dark": Color(0.19, 0.105, 0.075), "gas_light": Color(0.58, 0.39, 0.27), "gas_highlight": Color(0.76, 0.62, 0.46), "ring_tint": Color(0.68, 0.54, 0.38)
			}


func _build_world_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = _theme.get("sky_top", Color(0.004, 0.009, 0.028))
	sky_material.sky_horizon_color = _theme.get("sky_horizon", Color(0.025, 0.045, 0.09))
	sky_material.ground_bottom_color = Color(0.002, 0.004, 0.012)
	sky_material.ground_horizon_color = Color(0.012, 0.022, 0.05)
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _theme.get("ambient", Color(0.22, 0.31, 0.52))
	environment.ambient_light_energy = 0.78
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_strength = 0.8
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
	key_light.light_energy = 1.65
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 260.0
	add_child(key_light)

	# Low-energy blue fill preserves hull readability on the shadow side while
	# keeping the scene recognizably lit by a single stellar key source.
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "NebulaFillLight"
	fill_light.rotation_degrees = Vector3(-12.0, -148.0, 0.0)
	fill_light.light_color = _theme.get("fill_light", Color(0.20, 0.38, 0.72))
	fill_light.light_energy = 0.34
	fill_light.shadow_enabled = false
	add_child(fill_light)


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
	star_material.emission_energy_multiplier = 2.25
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
	noise_texture.width = 512
	noise_texture.height = 512
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
	float cloud = broad * 0.72 + detail * 0.28;
	float filaments = smoothstep(0.36, 0.74, cloud);
	float wisps = smoothstep(0.49, 0.82, detail) * 0.22;
	vec2 centered = UV * 2.0 - 1.0;
	float edge_fade = 1.0 - smoothstep(0.42, 1.0, length(centered));
	float alpha = clamp((filaments + wisps) * nebula_tint.a * edge_fade, 0.0, 0.36);
	ALBEDO = nebula_tint.rgb;
	EMISSION = nebula_tint.rgb * (0.45 + filaments * 1.8);
	ALPHA = alpha;
}
"""
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
render_mode diffuse_burley, specular_schlick_ggx;

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
	ALBEDO = mix(band_color, band_highlight.rgb, smoothstep(0.68, 0.96, broad_bands) * 0.28);
	ROUGHNESS = 0.91;
	METALLIC = 0.0;
}
"""
	var giant_material := ShaderMaterial.new()
	giant_material.shader = giant_shader
	giant_material.set_shader_parameter("band_dark", _theme.get("gas_dark", Color(0.19, 0.105, 0.075)))
	giant_material.set_shader_parameter("band_light", _theme.get("gas_light", Color(0.58, 0.39, 0.27)))
	giant_material.set_shader_parameter("band_highlight", _theme.get("gas_highlight", Color(0.76, 0.62, 0.46)))
	giant_mesh.material = giant_material
	giant.mesh = giant_mesh
	giant.scale = Vector3.ONE * 82.0
	_companion_planet = giant
	add_child(giant)

	var ring := MeshInstance3D.new()
	ring.name = "NacreonRings"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.24
	ring_mesh.outer_radius = 1.86
	ring_mesh.rings = 96
	ring_mesh.ring_segments = 12
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ring_tint: Color = _theme.get("ring_tint", Color(0.68, 0.54, 0.38))
	ring_material.albedo_color = Color(ring_tint.r, ring_tint.g, ring_tint.b, 0.58)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.12, 0.075, 0.035)
	ring_material.emission_energy_multiplier = 0.18
	ring_material.roughness = 0.88
	ring_mesh.material = ring_material
	ring.mesh = ring_mesh
	ring.scale = Vector3.ONE * 100.0
	_companion_rings = ring
	add_child(ring)
	_add_ring_detail(ring, "NacreonInnerRing", 1.06, 1.17, 0.30)
	_add_ring_detail(ring, "NacreonOuterRing", 1.92, 2.12, 0.22)
	_add_ring_detail(ring, "NacreonDustBand", 2.18, 2.25, 0.10)

	var moon := MeshInstance3D.new()
	moon.name = "NacreonMoon"
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 1.0
	moon_mesh.height = 2.0
	moon_mesh.radial_segments = 32
	moon_mesh.rings = 16
	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_color = _theme.get("snow", Color(0.34, 0.39, 0.46))
	moon_material.roughness = 0.96
	moon_mesh.material = moon_material
	moon.mesh = moon_mesh
	moon.scale = Vector3.ONE * 18.0
	_companion_moon = moon
	add_child(moon)

func _create_planet_texture() -> Texture2D:
	const WIDTH := 768
	const HEIGHT := 384
	var noise := FastNoiseLite.new()
	noise.seed = 19073
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 6
	noise.fractal_lacunarity = 2.05
	noise.fractal_gain = 0.48
	noise.frequency = 1.15

	var water_dark: Color = _theme.get("water_dark", Color(0.018, 0.075, 0.16))
	var water_light: Color = _theme.get("water_light", Color(0.035, 0.19, 0.31))
	var land_low: Color = _theme.get("land_low", Color(0.18, 0.34, 0.31))
	var land_high: Color = _theme.get("land_high", Color(0.43, 0.38, 0.25))
	var snow: Color = _theme.get("snow", Color(0.78, 0.79, 0.72))
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


func _build_asteroid_field() -> void:
	# A denser base sphere plus deterministic vertex displacement avoids the
	# smooth blue-marble look of the first capture and gives each instance a
	# fractured, rocky silhouette without spawning hundreds of separate nodes.
	var asteroid_mesh := SphereMesh.new()
	asteroid_mesh.radius = 1.0
	asteroid_mesh.height = 2.0
	asteroid_mesh.radial_segments = 20
	asteroid_mesh.rings = 12
	var asteroid_shader := Shader.new()
	asteroid_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying float rock_variation;
uniform vec4 rock_tint = vec4(0.48, 0.52, 0.56, 1.0);

void vertex() {
	vec3 p = VERTEX;
	float broad = sin(p.x * 4.7 + p.y * 2.1) * cos(p.z * 3.8 - p.x * 1.9);
	float fracture = sin(p.y * 9.3 + p.z * 6.1) * cos(p.x * 8.2 + p.z * 4.4);
	float chips = sin(p.x * 15.0 + p.y * 11.0) * sin(p.z * 13.0 - p.y * 7.0);
	float displacement = broad * 0.105 + fracture * 0.042 + chips * 0.014;
	VERTEX += NORMAL * displacement;
	rock_variation = broad * 0.5 + fracture * 0.22 + chips * 0.12;
}

void fragment() {
	float strata = sin(VERTEX.x * 8.0 + VERTEX.y * 5.0 + VERTEX.z * 7.0) * 0.035;
	float value = clamp(0.30 + rock_variation * 0.24 + strata, 0.12, 0.48);
	ALBEDO = rock_tint.rgb * value;
	METALLIC = 0.12;
	ROUGHNESS = 0.94;
}
"""
	var asteroid_material := ShaderMaterial.new()
	asteroid_material.shader = asteroid_shader
	asteroid_material.set_shader_parameter("rock_tint", _theme.get("asteroid_tint", Color(0.48, 0.52, 0.56)))
	asteroid_mesh.material = asteroid_material

	var field := _make_multimesh("AsteroidField", asteroid_mesh, asteroid_count)
	for index in range(asteroid_count):
		var position := _random_asteroid_position()
		var size := _rng.randf_range(0.8, 3.8)
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
		_add_asteroid_collision(index, position, size)
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
	parent.add_child(band)


func _build_cosmic_dust() -> void:
	# One batched visual layer adds depth without hundreds of physics bodies.
	const DUST_COUNT := 1400
	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.22
	dust_mesh.height = 0.44
	dust_mesh.radial_segments = 5
	dust_mesh.rings = 3
	var dust_material := StandardMaterial3D.new()
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.albedo_color = Color(0.34, 0.48, 0.72, 0.42)
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.emission_enabled = true
	dust_material.emission = Color(0.12, 0.22, 0.42)
	dust_material.emission_energy_multiplier = 0.42
	dust_mesh.material = dust_material
	_cosmic_dust = _make_multimesh("InterplanetaryDust", dust_mesh, DUST_COUNT)
	var route_points: Array[Vector3] = [Vector3(0.0, 0.0, 90.0), Vector3(0.0, 18.0, -13500.0), Vector3(520.0, -28.0, -33000.0), Vector3(0.0, 0.0, 90.0)]
	for index in range(DUST_COUNT):
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
		var basis := Basis.from_euler(Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU))).scaled(Vector3.ONE * size)
		_cosmic_dust.multimesh.set_instance_transform(index, Transform3D(basis, position))
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
