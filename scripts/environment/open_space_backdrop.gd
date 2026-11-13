extends Node3D
class_name OpenSpaceBackdrop
## Open-space visual stack with quality-aware bloom / shadows.

@export var asteroid_count: int = 220
@export var belt_radius: float = 140.0
@export var belt_width: float = 55.0
@export var belt_height: float = 18.0
@export var spawn_relay_beacon: bool = true
@export var enable_ssao: bool = false

var _rng := RandomNumberGenerator.new()
var _world_env: WorldEnvironment
var _key_light: DirectionalLight3D


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
	if spawn_relay_beacon:
		_setup_relay_beacon()
	if gq:
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	enable_ssao = gq.ssao_enabled()
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		env.ssao_enabled = enable_ssao
		env.glow_enabled = gq.glow_enabled()
		env.glow_intensity = gq.glow_intensity()
		env.glow_bloom = gq.glow_bloom()
		env.glow_hdr_threshold = gq.glow_hdr_threshold()
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
	var sky_mat := ShaderMaterial.new()
	var shader := load("res://assets/shaders/space_starfield_sky.gdshader") as Shader
	if shader:
		sky_mat.shader = shader
		sky_mat.set_shader_parameter("space_color", Color(0.004, 0.01, 0.03))
		sky_mat.set_shader_parameter("nebula_strength", 0.4)
		sky_mat.set_shader_parameter("star_density", 1.75)
		sky_mat.set_shader_parameter("star_brightness", 1.12)
		sky_mat.set_shader_parameter("dust_strength", 0.2)
		sky.sky_material = sky_mat
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
	env.ambient_light_energy = 0.26
	env.tonemap_mode = Environment.TONE_MAP_MODE_ACES
	env.tonemap_exposure = 0.95
	env.tonemap_white = 6.5

	# Bloom / glow — HDR spill for engines, bolts, relay
	var gq := _gq()
	env.glow_enabled = true
	env.glow_levels[1] = 0.0
	env.glow_levels[2] = 0.6
	env.glow_levels[3] = 1.0
	env.glow_levels[4] = 0.7
	env.glow_levels[5] = 0.35
	env.glow_levels[6] = 0.15
	env.glow_intensity = gq.glow_intensity() if gq else 0.55
	env.glow_strength = 1.05
	env.glow_bloom = gq.glow_bloom() if gq else 0.25
	env.glow_hdr_threshold = gq.glow_hdr_threshold() if gq else 0.8
	env.glow_hdr_scale = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.06
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
	fill.light_energy = 0.25
	fill.shadow_enabled = false
	add_child(fill)


func _setup_planets() -> void:
	var segs := 40
	var gq := _gq()
	if gq:
		segs = gq.planet_segments()
	_add_planet("GasGiant", Vector3(-90, 40, -260), 48.0, Color(0.15, 0.28, 0.42), Color(0.05, 0.12, 0.2), 0.15, 0.85, segs)
	_add_planet("RockyWorld", Vector3(120, -30, -200), 18.0, Color(0.35, 0.22, 0.16), Color(0.08, 0.05, 0.04), 0.05, 0.92, segs)


func _add_planet(
	planet_name: String, pos: Vector3, radius: float,
	albedo: Color, emission: Color, metallic: float, roughness: float,
	segments: int = 40
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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 0.35
	mi.set_surface_override_material(0, mat)
	mi.visibility_range_end = 2000.0
	add_child(mi)


func _setup_asteroid_belt() -> void:
	var multi := MultiMeshInstance3D.new()
	multi.name = "AsteroidBelt"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = asteroid_count
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 8
	rock.rings = 5
	mm.mesh = rock
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.2, 0.18)
	mat.roughness = 0.95
	mat.metallic = 0.08
	rock.material = mat
	for i in asteroid_count:
		var angle := _rng.randf() * TAU
		var r := belt_radius + _rng.randf_range(-belt_width, belt_width)
		var y := _rng.randf_range(-belt_height, belt_height)
		var pos := Vector3(cos(angle) * r, y, sin(angle) * r)
		var s := _rng.randf_range(0.6, 3.2)
		var basis := Basis.from_euler(Vector3(
			_rng.randf() * TAU,
			_rng.randf() * TAU,
			_rng.randf() * TAU
		)).scaled(Vector3(s, s * _rng.randf_range(0.6, 1.2), s))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	multi.multimesh = mm
	multi.visibility_range_end = 900.0
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
