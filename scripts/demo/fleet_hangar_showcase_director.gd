extends Node3D
## Full HD in-engine lineup for visual QA of all seven original ship classes.

const RUNTIME_GLTF_SCRIPT: Script = preload("res://scripts/visual/runtime_gltf_model.gd")

const SHIPS: Array[Dictionary] = [
	{"path": "res://assets/models/ships/player_fighter.glb", "name": "PLAYER FIGHTER", "role": "MULTIROLE / RECON", "scale": 0.40, "position": Vector3(-12.0, 0.0, 0.0)},
	{"path": "res://assets/models/ships/enemy_fighter.glb", "name": "RAIDER INTERCEPTOR", "role": "LIGHT ATTACK", "scale": 0.38, "position": Vector3(-4.0, 0.0, 0.0)},
	{"path": "res://assets/models/ships/heavy_fighter.glb", "name": "AEGIS HEAVY FIGHTER", "role": "HEAVY ASSAULT", "scale": 0.34, "position": Vector3(4.0, 0.0, 0.0)},
	{"path": "res://assets/models/ships/bomber.glb", "name": "BASTION BOMBER", "role": "TORPEDO / STRIKE", "scale": 0.32, "position": Vector3(12.0, 0.0, 0.0)},
	{"path": "res://assets/models/ships/cargo_hauler.glb", "name": "MULE HAULER", "role": "LOGISTICS", "scale": 0.27, "position": Vector3(-8.0, 0.0, 9.0)},
	{"path": "res://assets/models/ships/frigate.glb", "name": "VANGUARD FRIGATE", "role": "ESCORT / PATROL", "scale": 0.19, "position": Vector3(0.0, 0.0, 9.0)},
	{"path": "res://assets/models/ships/cruiser.glb", "name": "LEVIATHAN CRUISER", "role": "CAPITAL SHIP", "scale": 0.14, "position": Vector3(8.0, 0.0, 9.0)}
]


func _ready() -> void:
	_build_environment()
	_build_stage()
	var loaded_count := 0
	for ship_data in SHIPS:
		if _spawn_ship(ship_data):
			loaded_count += 1
	_build_overlay()
	print("FLEET_HANGAR_SHIPS_LOADED=", loaded_count)
	if loaded_count != SHIPS.size():
		push_error("Fleet hangar expected %d ships, loaded %d" % [SHIPS.size(), loaded_count])
		return
	call_deferred("_capture_after_render")


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.012, 0.026)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.34, 0.43, 0.58)
	environment.ambient_light_energy = 0.85
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	key.light_color = Color(0.78, 0.88, 1.0)
	key.light_energy = 1.75
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18.0, 148.0, 0.0)
	fill.light_color = Color(0.20, 0.46, 0.82)
	fill.light_energy = 0.58
	add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.name = "HangarWarmRim"
	rim.rotation_degrees = Vector3(-8.0, 72.0, 0.0)
	rim.light_color = Color(1.0, 0.48, 0.22)
	rim.light_energy = 0.42
	rim.shadow_enabled = false
	add_child(rim)


func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(48.0, 36.0)
	floor.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.018, 0.028, 0.048)
	floor_material.metallic = 0.55
	floor_material.roughness = 0.34
	floor.material_override = floor_material
	floor.position = Vector3(0.0, -0.72, 4.5)
	add_child(floor)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 9.0, -20.0)
	camera.fov = 50.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.4, 4.5), Vector3.UP)


func _spawn_ship(data: Dictionary) -> bool:
	var path: String = data["path"]
	# Use the same runtime GLTFDocument path as the flight scene. This avoids
	# depending on editor-generated .import cache entries for direct GLB loads.
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var parse_error := document.append_from_file(path, state)
	if parse_error != OK:
		push_error("Fleet hangar cannot parse %s (error %d)" % [path, parse_error])
		return false
	var ship := document.generate_scene(state) as Node3D
	if ship == null:
		push_error("Fleet hangar generated a null scene for %s" % path)
		return false

	var detailed_surfaces: int = int(RUNTIME_GLTF_SCRIPT.apply_surface_finish(ship))
	if detailed_surfaces <= 0:
		push_error("Fleet hangar surface finish did not find PBR materials in %s" % path)
		ship.free()
		return false
	var position: Vector3 = data["position"]
	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 2.65
	pedestal_mesh.bottom_radius = 2.85
	pedestal_mesh.height = 0.42
	pedestal_mesh.radial_segments = 48
	pedestal.mesh = pedestal_mesh
	var pedestal_material := StandardMaterial3D.new()
	pedestal_material.albedo_color = Color(0.045, 0.075, 0.12)
	pedestal_material.metallic = 0.82
	pedestal_material.roughness = 0.26
	pedestal.material_override = pedestal_material
	pedestal.position = position + Vector3(0.0, -0.48, 0.0)
	add_child(pedestal)

	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 2.88
	ring_mesh.bottom_radius = 2.88
	ring_mesh.height = 0.055
	ring_mesh.radial_segments = 48
	ring.mesh = ring_mesh
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = Color(0.02, 0.30, 0.52)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.02, 0.34, 0.68)
	ring_material.emission_energy_multiplier = 2.0
	ring.material_override = ring_material
	ring.position = position + Vector3(0.0, -0.22, 0.0)
	add_child(ring)

	ship.name = String(data["name"]).replace(" ", "")
	ship.scale = Vector3.ONE * float(data["scale"])
	ship.position = position + Vector3(0.0, 0.12, 0.0)
	add_child(ship)

	var label := Label3D.new()
	label.text = String(data["name"]) + "\n" + String(data["role"])
	label.font_size = 72
	label.outline_size = 12
	label.modulate = Color(0.78, 0.91, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position + Vector3(0.0, 4.55, 0.0)
	add_child(label)

	var light := OmniLight3D.new()
	light.position = position + Vector3(0.0, 5.0, 0.0)
	light.light_color = Color(0.28, 0.55, 0.92)
	light.light_energy = 1.10
	light.omni_range = 15.0
	add_child(light)

	var warm_fill := OmniLight3D.new()
	warm_fill.position = position + Vector3(4.0, 1.8, 1.5)
	warm_fill.light_color = Color(1.0, 0.42, 0.20)
	warm_fill.light_energy = 0.48
	warm_fill.omni_range = 10.0
	add_child(warm_fill)
	return true


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "GALACTIC FRONTIER   /   ORIGINAL FLEET"
	title.position = Vector2(44.0, 34.0)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.74, 0.88, 1.0))
	layer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SEVEN SHIP CLASSES  •  FULL HD SHOWROOM"
	subtitle.position = Vector2(46.0, 78.0)
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.35, 0.68, 0.88))
	layer.add_child(subtitle)


func _capture_after_render() -> void:
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("fleet-hangar.png")
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Fleet hangar screenshot failed: %d" % error)
		return
	print("FLEET_HANGAR_CAPTURE=", path)
	print("FLEET_HANGAR_COMPLETE")
	get_tree().quit()
