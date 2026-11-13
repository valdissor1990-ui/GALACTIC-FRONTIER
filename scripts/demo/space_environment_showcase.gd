extends Node3D
## Captures real in-engine space-environment views for visual art-direction review.

const SHOTS: Array[Dictionary] = [
	{"name": "01-nebula-field", "camera": Vector3(0.0, 0.0, 0.0), "target": Vector3(-138.0, 54.0, -465.0), "fov": 60.0},
	{"name": "02-aurelia-planet", "camera": Vector3(-160.0, 26.0, -105.0), "target": Vector3(-160.0, 26.0, -285.0), "fov": 52.0},
	{"name": "03-ringed-gas-giant", "camera": Vector3(670.0, 48.0, -900.0), "target": Vector3(430.0, -92.0, -1320.0), "fov": 55.0},
	{"name": "04-spiral-galaxy", "camera": Vector3(115.0, 168.0, -620.0), "target": Vector3(35.0, 148.0, -920.0), "fov": 54.0},
	{"name": "05-comet-landmark", "camera": Vector3(-430.0, 305.0, -1600.0), "target": Vector3(-520.0, 205.0, -1880.0), "fov": 58.0},
	{"name": "06-derelict-wreck", "camera": Vector3(405.0, -48.0, -500.0), "target": Vector3(285.0, -118.0, -690.0), "fov": 48.0},
	{"name": "07-asteroid-corridor", "camera": Vector3.ZERO, "target": Vector3.ZERO, "fov": 64.0}
]

@onready var _camera: Camera3D = $ShowcaseCamera
@onready var _environment: Node3D = $SpaceEnvironment


func _ready() -> void:
	_camera.current = true
	_camera.make_current()
	_camera.far = 50000.0
	_environment.set("showcase_mode", true)
	call_deferred("_capture_sequence")


func _capture_sequence() -> void:
	var output_directory := "user://screenshots"
	var absolute_directory := ProjectSettings.globalize_path(output_directory)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("SPACE_SHOWCASE_DIRECTORY_FAILED: %s" % error_string(directory_error))
		get_tree().quit(1)
		return

	# Aim the camera at the first shot before placing the marker, and explicitly
	# include all 3D render layers so the diagnostic tests the actual viewport.
	var first_shot: Dictionary = SHOTS[0]
	_camera.global_position = first_shot["camera"]
	_camera.look_at(first_shot["target"], Vector3.UP)
	_camera.cull_mask = 0xFFFFFFFF
	_camera.force_update_transform()
	_environment.visible = true
	var diagnostic_sphere := MeshInstance3D.new()
	diagnostic_sphere.name = "ShowcaseCameraDiagnostic"
	var diagnostic_mesh := SphereMesh.new()
	diagnostic_mesh.radius = 12.0
	diagnostic_mesh.height = 24.0
	var diagnostic_material := StandardMaterial3D.new()
	diagnostic_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	diagnostic_material.albedo_color = Color(1.0, 0.04, 0.02)
	diagnostic_material.emission_enabled = true
	diagnostic_material.emission = Color(1.0, 0.04, 0.02)
	diagnostic_material.emission_energy_multiplier = 1.5
	diagnostic_mesh.material = diagnostic_material
	diagnostic_sphere.mesh = diagnostic_mesh
	diagnostic_sphere.layers = 1
	var marker_position := _camera.global_position + (-_camera.global_basis.z * 80.0)
	diagnostic_sphere.position = marker_position
	add_child(diagnostic_sphere)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var diagnostic_image := get_viewport().get_texture().get_image()
	var diagnostic_error := diagnostic_image.save_png(output_directory + "/space-camera-diagnostic.png")
	var viewport_environment := get_viewport().world_3d.environment
	print("SPACE_SHOWCASE_CAMERA_ACTIVE=", get_viewport().get_camera_3d() == _camera,
		" cull_mask=", _camera.cull_mask,
		" diagnostic_save=", diagnostic_error,
		" environment_visible=", _environment.visible,
		" environment_position=", _environment.global_position,
		" viewport_background_mode=", viewport_environment.background_mode if viewport_environment != null else -1,
		" viewport_background_color=", viewport_environment.background_color if viewport_environment != null else Color.BLACK,
		" children=", _environment.get_child_count())
	var visible_mesh_children := 0
	var has_world_environment := false
	var world_environment_names: Array[String] = []
	var environment_background_mode := -1
	for child in _environment.get_children():
		if child is MeshInstance3D and child.name != "ShowcaseCameraDiagnostic" and child.mesh != null and child.visible:
			visible_mesh_children += 1
		if child is WorldEnvironment:
			has_world_environment = true
			world_environment_names.append(child.name)
			if child.environment != null:
				environment_background_mode = child.environment.background_mode
	print("SPACE_SHOWCASE_VISIBLE_MESH_CHILDREN=", visible_mesh_children,
		" camera_position=", _camera.global_position,
		" camera_forward=", -_camera.global_basis.z,
		" world_environment=", has_world_environment,
		" world_environment_names=", world_environment_names,
		" background_mode=", environment_background_mode)
	diagnostic_sphere.queue_free()
	await get_tree().process_frame

	for shot in SHOTS:
		_camera.fov = float(shot.get("fov", 60.0))
		var camera_position: Vector3 = shot["camera"]
		var target_position: Vector3 = shot["target"]
		if str(shot["name"]) == "07-asteroid-corridor":
			var asteroid_field := _environment.get_node_or_null("AsteroidField") as MultiMeshInstance3D
			print("SPACE_SHOWCASE_ASTEROID_FIELD_VALID=", asteroid_field != null)
			if asteroid_field != null and asteroid_field.multimesh != null and asteroid_field.multimesh.instance_count > 0:
				var asteroid_positions: Array[Vector3] = []
				for index in range(asteroid_field.multimesh.instance_count):
					var instance_transform := asteroid_field.multimesh.get_instance_transform(index)
					asteroid_positions.append(asteroid_field.to_global(instance_transform.origin))
				var densest_center := asteroid_positions[0]
				var densest_neighbors := 0
				for candidate in asteroid_positions:
					var neighbor_count := 0
					for other in asteroid_positions:
						if candidate.distance_to(other) < 680.0:
							neighbor_count += 1
					if neighbor_count > densest_neighbors:
						densest_neighbors = neighbor_count
						densest_center = candidate
				target_position = densest_center
				camera_position = target_position + Vector3(90.0, 60.0, 260.0)
				print("SPACE_SHOWCASE_ASTEROID_FIELD_COUNT=", asteroid_positions.size())
				print("SPACE_SHOWCASE_ASTEROID_FOCUS=", target_position)
			else:
				target_position = Vector3(-250.0, 220.0, -13500.0)
				camera_position = target_position + Vector3(250.0, 180.0, 720.0)
				print("SPACE_SHOWCASE_ASTEROID_FIELD_MISSING_FALLBACK=", target_position)
		_camera.global_position = camera_position
		_camera.look_at(target_position, Vector3.UP)
		print("SPACE_SHOWCASE_CAMERA=", shot["name"], " pos=", camera_position, " target=", target_position)
		await get_tree().process_frame
		await get_tree().create_timer(1.15).timeout
		var screenshot := get_viewport().get_texture().get_image()
		var file_path := output_directory + "/space-" + str(shot["name"]) + ".png"
		var save_error := screenshot.save_png(file_path)
		if save_error != OK:
			push_error("SPACE_SHOWCASE_SAVE_FAILED path=%s error=%s" % [file_path, error_string(save_error)])
			get_tree().quit(1)
			return
		print("SPACE_SHOWCASE_SCREENSHOT=%s" % file_path)

	print("SPACE_SHOWCASE_COMPLETE count=%d" % SHOTS.size())
	get_tree().quit(0)
