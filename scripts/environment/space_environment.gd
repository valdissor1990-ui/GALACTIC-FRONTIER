extends Node3D
## Deterministic, lightweight space backdrop for the first visual flight slice.
## Uses generated geometry and textures only; no network or third-party assets.

@export_range(300, 2400, 100) var star_count: int = 1200
@export_range(40, 220, 10) var asteroid_count: int = 120

var _rng := RandomNumberGenerator.new()
var _starfield: MultiMeshInstance3D


func _ready() -> void:
	_rng.seed = 741_2026
	_build_world_environment()
	_build_starfield()
	_build_planet()
	_build_asteroid_field()


func _process(_delta: float) -> void:
	if not is_instance_valid(_starfield):
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		_starfield.global_position = camera.global_position


func _build_world_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.004, 0.009, 0.028)
	sky_material.sky_horizon_color = Color(0.025, 0.045, 0.09)
	sky_material.ground_bottom_color = Color(0.002, 0.004, 0.012)
	sky_material.ground_horizon_color = Color(0.012, 0.022, 0.05)
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.22, 0.31, 0.52)
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_strength = 0.8
	world.environment = environment
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.name = "StellarKeyLight"
	key_light.rotation_degrees = Vector3(-24.0, 32.0, 0.0)
	key_light.light_color = Color(0.72, 0.82, 1.0)
	key_light.light_energy = 1.35
	key_light.shadow_enabled = true
	add_child(key_light)


func _build_starfield() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.22
	star_mesh.height = 0.44
	star_mesh.radial_segments = 6
	star_mesh.rings = 4

	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color(0.72, 0.84, 1.0)
	star_material.emission_enabled = true
	star_material.emission = Color(0.48, 0.68, 1.0)
	star_material.emission_energy_multiplier = 1.6
	star_mesh.material = star_material

	_starfield = _make_multimesh("Starfield", star_mesh, star_count)
	for index in range(star_count):
		var direction := _random_unit_vector()
		var distance := _rng.randf_range(760.0, 1120.0)
		var size := _rng.randf_range(0.55, 2.1)
		var transform := Transform3D(Basis.from_scale(Vector3.ONE * size), direction * distance)
		_starfield.multimesh.set_instance_transform(index, transform)
	add_child(_starfield)


func _build_planet() -> void:
	var planet := MeshInstance3D.new()
	planet.name = "Aurelia"
	planet.position = Vector3(0.0, 26.0, -285.0)
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
	add_child(planet)

	var atmosphere := MeshInstance3D.new()
	atmosphere.name = "AureliaAtmosphere"
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
	atmosphere_material.albedo_color = Color(0.12, 0.42, 0.95, 0.12)
	atmosphere_material.emission_enabled = true
	atmosphere_material.emission = Color(0.025, 0.12, 0.42)
	atmosphere_material.emission_energy_multiplier = 0.35
	atmosphere_mesh.material = atmosphere_material
	atmosphere.mesh = atmosphere_mesh
	add_child(atmosphere)


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
				color = Color(0.018, 0.075, 0.16).lerp(Color(0.035, 0.19, 0.31), clampf((value + 1.0) / 0.82, 0.0, 1.0))
			elif value < 0.02:
				color = Color(0.035, 0.19, 0.31).lerp(Color(0.18, 0.34, 0.31), (value + 0.18) / 0.20)
			elif value < 0.30:
				color = Color(0.18, 0.34, 0.31).lerp(Color(0.43, 0.38, 0.25), (value - 0.02) / 0.28)
			else:
				color = Color(0.43, 0.38, 0.25).lerp(Color(0.78, 0.79, 0.72), clampf((value - 0.30) / 0.45, 0.0, 1.0))
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _build_asteroid_field() -> void:
	var asteroid_mesh := SphereMesh.new()
	asteroid_mesh.radius = 1.0
	asteroid_mesh.height = 2.0
	asteroid_mesh.radial_segments = 9
	asteroid_mesh.rings = 5
	var asteroid_material := StandardMaterial3D.new()
	asteroid_material.albedo_color = Color(0.19, 0.22, 0.28)
	asteroid_material.metallic = 0.18
	asteroid_material.roughness = 0.96
	asteroid_mesh.material = asteroid_material

	var field := _make_multimesh("AsteroidField", asteroid_mesh, asteroid_count)
	for index in range(asteroid_count):
		var position := Vector3(
			_rng.randf_range(-155.0, 155.0),
			_rng.randf_range(-88.0, 88.0),
			_rng.randf_range(-250.0, 80.0)
		)
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
	add_child(field)


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
