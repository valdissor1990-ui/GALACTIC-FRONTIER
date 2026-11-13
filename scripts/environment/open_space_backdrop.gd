extends Node3D
class_name OpenSpaceBackdrop
## Dense open-space backdrop with procedural planet/rock materials.

@export var asteroid_count: int = 220
@export var belt_radius: float = 140.0
@export var belt_width: float = 55.0
@export var belt_height: float = 18.0
@export var spawn_relay_beacon: bool = true
@export var spawn_lens_mass: bool = true
@export var enable_ssao: bool = false

var _rng := RandomNumberGenerator.new()
var _world_env: WorldEnvironment
var _key_light: DirectionalLight3D
var _sky_mat: ShaderMaterial


func _ready() -> void:
	_rng.randomize()
	var gq := _gq()
	if gq:
		asteroid_count = gq.asteroid_count()
		enable_ssao = gq.ssao_enabled()
	_setup_sky_environment()
	_setup_lights()
	_setup_planets()
	_setup_asteroid_belt()
	_setup_outer_debris()
	if spawn_relay_beacon:
		_setup_relay_beacon()
	if spawn_lens_mass:
		_setup_lens_mass()
	if gq:
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	enable_ssao = gq.ssao_enabled()
	if _sky_mat:
		_sky_mat.set_shader_parameter("star_density", gq.sky_star_density())
		_sky_mat.set_shader_parameter("star_brightness", gq.sky_star_brightness())
		_sky_mat.set_shader_parameter("nebula_strength", gq.sky_nebula_strength())
		_sky_mat.set_shader_parameter("dust_strength", gq.sky_dust_strength())
		_sky_mat.set_shader_parameter("galactic_strength", gq.sky_galactic_strength())
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		env.tonemap_mode = gq.tonemap_mode()
		env.tonemap_exposure = gq.tonemap_exposure()
		env.tonemap_white = gq.tonemap_white()
		if gq.has_method("apply_tonemap_extras"):
			gq.apply_tonemap_extras(env)
		env.adjustment_enabled = gq.adjustment_enabled()
		if env.adjustment_enabled:
			env.adjustment_contrast = gq.adjustment_contrast()
			env.adjustment_saturation = gq.adjustment_saturation()
		env.ssao_enabled = enable_ssao
		env.glow_enabled = gq.glow_enabled()
		env.glow_intensity = gq.glow_intensity()
		env.glow_bloom = gq.glow_bloom()
		env.glow_hdr_threshold = gq.glow_hdr_threshold()
		env.glow_hdr_scale = gq.glow_hdr_scale()
		env.glow_hdr_luminance_cap = gq.glow_hdr_luminance_cap()
		env.glow_strength = gq.glow_strength()
		if gq.has_method("apply_glow_levels"):
			gq.apply_glow_levels(env)
	if _key_light:
		_key_light.shadow_enabled = gq.shadow_enabled()
		_key_light.directional_shadow_max_distance = gq.shadow_max_distance()
		_key_light.directional_shadow_mode = gq.shadow_splits() as DirectionalLight3D.ShadowMode


func _gq() -> Node:
	return get_node_or_null("/root/GraphicsQuality")


func _setup_sky_environment() -> void:
	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ShaderMaterial.new()
	var shader := load("res://assets/shaders/space_starfield_sky.gdshader") as Shader
	var gq := _gq()
	if shader:
		_sky_mat.shader = shader
		_sky_mat.set_shader_parameter("space_color", Color(0.002, 0.006, 0.02))
		_sky_mat.set_shader_parameter("nebula_a", Color(0.05, 0.08, 0.28))
		_sky_mat.set_shader_parameter("nebula_b", Color(0.18, 0.04, 0.1))
		_sky_mat.set_shader_parameter("nebula_c", Color(0.03, 0.14, 0.12))
		if gq:
			_sky_mat.set_shader_parameter("star_density", gq.sky_star_density())
			_sky_mat.set_shader_parameter("star_brightness", gq.sky_star_brightness())
			_sky_mat.set_shader_parameter("nebula_strength", gq.sky_nebula_strength())
			_sky_mat.set_shader_parameter("dust_strength", gq.sky_dust_strength())
			_sky_mat.set_shader_parameter("galactic_strength", gq.sky_galactic_strength())
		else:
			_sky_mat.set_shader_parameter("star_density", 2.2)
			_sky_mat.set_shader_parameter("star_brightness", 1.25)
			_sky_mat.set_shader_parameter("nebula_strength", 0.55)
			_sky_mat.set_shader_parameter("dust_strength", 0.28)
			_sky_mat.set_shader_parameter("galactic_strength", 0.35)
		sky.sky_material = _sky_mat
	else:
		var proc := ProceduralSkyMaterial.new()
		proc.sky_top_color = Color(0.01, 0.02, 0.05)
		proc.sky_horizon_color = Color(0.03, 0.05, 0.1)
		proc.ground_bottom_color = Color(0.01, 0.01, 0.02)
		proc.ground_horizon_color = Color(0.02, 0.03, 0.06)
		proc.sky_energy_multiplier = 0.8
		sky.sky_material = proc
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.28
	env.tonemap_mode = gq.tonemap_mode() if gq else Environment.TONE_MAP_MODE_ACES
	env.tonemap_exposure = gq.tonemap_exposure() if gq else 0.94
	env.tonemap_white = gq.tonemap_white() if gq else 7.5
	if gq and gq.has_method("apply_tonemap_extras"):
		gq.apply_tonemap_extras(env)
	env.glow_enabled = true
	if gq and gq.has_method("apply_glow_levels"):
		gq.apply_glow_levels(env)
	else:
		env.glow_levels[2] = 0.6
		env.glow_levels[3] = 1.0
		env.glow_levels[4] = 0.7
		env.glow_levels[5] = 0.35
	env.glow_intensity = gq.glow_intensity() if gq else 0.55
	env.glow_strength = gq.glow_strength() if gq else 1.05
	env.glow_bloom = gq.glow_bloom() if gq else 0.25
	env.glow_hdr_threshold = gq.glow_hdr_threshold() if gq else 0.8
	env.glow_hdr_scale = gq.glow_hdr_scale() if gq else 2.0
	env.glow_hdr_luminance_cap = gq.glow_hdr_luminance_cap() if gq else 12.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = gq.adjustment_enabled() if gq else true
	if env.adjustment_enabled:
		env.adjustment_contrast = gq.adjustment_contrast() if gq else 1.04
		env.adjustment_saturation = gq.adjustment_saturation() if gq else 1.05
	env.ssr_enabled = false
	env.ssao_enabled = enable_ssao
	if enable_ssao:
		env.ssao_radius = 1.0
		env.ssao_intensity = 1.2
	_world_env.environment = env
	add_child(_world_env)


func _setup_lights() -> void:
	_key_light = DirectionalLight3D.new()
	_key_light.name = "StarKeyLight"
	_key_light.rotation_degrees = Vector3(-24, 40, 0)
	_key_light.light_color = Color(1.0, 0.96, 0.88)
	_key_light.light_energy = 1.55
	var gq := _gq()
	if gq:
		_key_light.shadow_enabled = gq.shadow_enabled()
		_key_light.directional_shadow_max_distance = gq.shadow_max_distance()
		_key_light.directional_shadow_mode = gq.shadow_splits() as DirectionalLight3D.ShadowMode
	else:
		_key_light.shadow_enabled = true
		_key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		_key_light.directional_shadow_max_distance = 280.0
	add_child(_key_light)
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(15, -120, 0)
	fill.light_color = Color(0.45, 0.55, 0.85)
	fill.light_energy = 0.28
	fill.shadow_enabled = false
	add_child(fill)


func _setup_planets() -> void:
	var segs := 40
	var gq := _gq()
	if gq:
		segs = gq.planet_segments()
	var giant_pos := Vector3(-90, 40, -260)
	_add_gas_giant("GasGiant", giant_pos, 48.0, segs)
	_add_ice_ring("GasGiantRing", giant_pos, 58.0, 78.0, Color(0.55, 0.6, 0.72, 0.35))
	_add_rocky_planet(
		"RockyWorld", Vector3(120, -30, -200), 18.0, segs,
		Color(0.18, 0.12, 0.09), Color(0.35, 0.24, 0.16), Color(0.55, 0.5, 0.45),
		0.2, Color(0.4, 0.55, 0.85)
	)
	_add_rocky_planet(
		"IceWorld", Vector3(-40, -55, -380), 12.0, maxi(segs - 8, 16),
		Color(0.25, 0.3, 0.35), Color(0.45, 0.52, 0.58), Color(0.75, 0.82, 0.9),
		0.7, Color(0.55, 0.7, 0.95)
	)


func _add_gas_giant(planet_name: String, pos: Vector3, radius: float, segments: int) -> void:
	var mi := MeshInstance3D.new()
	mi.name = planet_name
	mi.position = pos
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(segments / 2, 8)
	mi.mesh = mesh
	var mat := ShaderMaterial.new()
	var shader := load("res://assets/shaders/planet_gas.gdshader") as Shader
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("band_color_a", Color(0.12, 0.22, 0.38))
		mat.set_shader_parameter("band_color_b", Color(0.22, 0.35, 0.48))
		mat.set_shader_parameter("band_color_c", Color(0.4, 0.3, 0.2))
		mat.set_shader_parameter("storm_color", Color(0.55, 0.32, 0.18))
		mat.set_shader_parameter("band_scale", 11.0)
		mat.set_shader_parameter("storm_amount", 0.4)
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.15, 0.28, 0.42)
		mat = fallback
	mi.set_surface_override_material(0, mat)
	mi.visibility_range_end = 2500.0
	add_child(mi)
	_add_atmosphere(planet_name + "Atmo", pos, radius * 1.045, Color(0.35, 0.55, 1.0), 1.2, segments)


func _add_rocky_planet(
	planet_name: String, pos: Vector3, radius: float, segments: int,
	low_c: Color, mid_c: Color, high_c: Color,
	ice_caps: float, atmo_color: Color
) -> void:
	var mi := MeshInstance3D.new()
	mi.name = planet_name
	mi.position = pos
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(segments / 2, 8)
	mi.mesh = mesh
	var mat := ShaderMaterial.new()
	var shader := load("res://assets/shaders/planet_rocky.gdshader") as Shader
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("low_color", low_c)
		mat.set_shader_parameter("mid_color", mid_c)
		mat.set_shader_parameter("high_color", high_c)
		mat.set_shader_parameter("ice_caps", ice_caps)
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = mid_c
		mat = fallback
	mi.set_surface_override_material(0, mat)
	mi.visibility_range_end = 2500.0
	add_child(mi)
	_add_atmosphere(planet_name + "Atmo", pos, radius * 1.06, atmo_color, 0.9, segments)


func _add_atmosphere(
	atmo_name: String, pos: Vector3, radius: float,
	color: Color, intensity: float, segments: int
) -> void:
	var mi := MeshInstance3D.new()
	mi.name = atmo_name
	mi.position = pos
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = maxi(segments / 2, 16)
	mesh.rings = maxi(segments / 4, 8)
	mi.mesh = mesh
	var mat := ShaderMaterial.new()
	var shader := load("res://assets/shaders/planet_atmosphere.gdshader") as Shader
	if shader == null:
		return
	mat.shader = shader
	mat.set_shader_parameter("atmosphere_color", color)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("falloff", 3.6)
	mat.set_shader_parameter("density", 0.9)
	mi.set_surface_override_material(0, mat)
	mi.visibility_range_end = 2500.0
	add_child(mi)


func _setup_lens_mass() -> void:
	var script := load("res://scripts/environment/gravity_lens_mass.gd") as Script
	if script == null:
		return
	var mass := Node3D.new()
	mass.set_script(script)
	mass.name = "GravityAnomaly"
	mass.position = Vector3(-55, 25, -200)
	if "lens_strength" in mass:
		mass.set("lens_strength", 1.15)
	if "lens_radius" in mass:
		mass.set("lens_radius", 0.24)
	add_child(mass)


func _add_ice_ring(ring_name: String, center: Vector3, inner_r: float, outer_r: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = ring_name
	mi.position = center
	mi.rotation_degrees = Vector3(72.0, 18.0, 0.0)
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_r
	mesh.outer_radius = outer_r
	mesh.rings = 48
	mesh.ring_segments = 12
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b) * 0.35
	mat.emission_energy_multiplier = 0.25
	mi.set_surface_override_material(0, mat)
	mi.visibility_range_end = 2200.0
	add_child(mi)


func _setup_asteroid_belt() -> void:
	_spawn_rock_field("AsteroidBelt", asteroid_count, belt_radius, belt_width, belt_height, Color(0.22, 0.2, 0.18), 0.6, 3.4, 900.0)
	var inner_n := maxi(asteroid_count / 4, 20)
	_spawn_rock_field("InnerCluster", inner_n, 55.0, 22.0, 10.0, Color(0.28, 0.24, 0.2), 0.4, 2.0, 400.0)


func _setup_outer_debris() -> void:
	var n := maxi(asteroid_count / 3, 24)
	_spawn_rock_field("OuterDebris", n, 280.0, 90.0, 40.0, Color(0.16, 0.17, 0.2), 0.8, 4.5, 1400.0)


func _spawn_rock_field(
	field_name: String, count: int, radius: float, width: float, height: float,
	albedo: Color, scale_min: float, scale_max: float, vis_end: float
) -> void:
	var multi := MultiMeshInstance3D.new()
	multi.name = field_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 7
	rock.rings = 4
	mm.mesh = rock
	var mat := ShaderMaterial.new()
	var shader := load("res://assets/shaders/rock_surface.gdshader") as Shader
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("base_color", albedo)
		mat.set_shader_parameter("dark_color", albedo.darkened(0.45))
		mat.set_shader_parameter("highlight_color", albedo.lightened(0.25))
		mat.set_shader_parameter("noise_scale", 6.5)
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = albedo
		fallback.roughness = 0.95
		mat = fallback
	rock.material = mat
	for i in count:
		var angle := _rng.randf() * TAU
		var r := radius + _rng.randf_range(-width, width)
		var y := _rng.randf_range(-height, height)
		var pos := Vector3(cos(angle) * r, y, sin(angle) * r)
		var s := _rng.randf_range(scale_min, scale_max)
		var basis := Basis.from_euler(Vector3(
			_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU
		)).scaled(Vector3(s, s * _rng.randf_range(0.55, 1.25), s * _rng.randf_range(0.7, 1.15)))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	multi.multimesh = mm
	multi.visibility_range_end = vis_end
	add_child(multi)


func _setup_relay_beacon() -> void:
	var packed := load("res://scenes/environment/silent_relay_beacon.tscn") as PackedScene
	if packed == null:
		return
	var beacon := packed.instantiate() as Node3D
	beacon.name = "SilentRelayBeacon"
	beacon.position = Vector3(40, 12, -95)
	beacon.scale = Vector3(1.4, 1.4, 1.4)
	add_child(beacon)
