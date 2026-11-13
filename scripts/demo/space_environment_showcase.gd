extends Node3D
## Captures real in-engine space-environment views for visual art-direction review.

const SHOTS: Array[Dictionary] = [
	{"name": "01-nebula-field", "camera": Vector3(0.0, 0.0, 0.0), "target": Vector3(-138.0, 54.0, -465.0), "fov": 60.0},
	{"name": "02-aurelia-planet", "camera": Vector3(-160.0, 26.0, -105.0), "target": Vector3(-160.0, 26.0, -285.0), "fov": 52.0},
	{"name": "03-ringed-gas-giant", "camera": Vector3(430.0, -52.0, -1060.0), "target": Vector3(430.0, -92.0, -1320.0), "fov": 42.0},
	{"name": "04-spiral-galaxy", "camera": Vector3(35.0, 148.0, -300.0), "target": Vector3(35.0, 148.0, -920.0), "fov": 58.0},
	{"name": "05-comet-landmark", "camera": Vector3(-520.0, 225.0, -1770.0), "target": Vector3(-520.0, 205.0, -1880.0), "fov": 38.0},
	{"name": "06-derelict-wreck", "camera": Vector3(285.0, -88.0, -610.0), "target": Vector3(285.0, -118.0, -690.0), "fov": 42.0},
	{"name": "07-asteroid-corridor", "camera": Vector3.ZERO, "target": Vector3.ZERO, "fov": 38.0}
]

@onready var _camera: Camera3D = $ShowcaseCamera
@onready var _environment: Node3D = $SpaceEnvironment


func _ready() -> void:
	_camera.current = true
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

	for shot in SHOTS:
		_camera.fov = float(shot.get("fov", 60.0))
		var camera_position: Vector3 = shot["camera"]
		var target_position: Vector3 = shot["target"]
		if str(shot["name"]) == "07-asteroid-corridor":
			var asteroid_field := _environment.get_node_or_null("AsteroidField") as MultiMeshInstance3D
			if asteroid_field != null and asteroid_field.multimesh != null and asteroid_field.multimesh.instance_count > 0:
				var largest_index := 0
				var largest_scale := 0.0
				for index in range(asteroid_field.multimesh.instance_count):
					var instance_transform := asteroid_field.multimesh.get_instance_transform(index)
					var instance_scale := instance_transform.basis.get_scale().length()
					if instance_scale > largest_scale:
						largest_scale = instance_scale
						largest_index = index
				target_position = asteroid_field.to_global(asteroid_field.multimesh.get_instance_transform(largest_index).origin)
				camera_position = target_position + Vector3(0.0, 0.0, maxf(14.0, largest_scale * 5.5))
		_camera.global_position = camera_position
		_camera.look_at(target_position, Vector3.UP)
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
