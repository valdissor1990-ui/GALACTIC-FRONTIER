extends Node3D
## Captures real in-engine space-environment views for visual art-direction review.

const SHOTS: Array[Dictionary] = [
	{"name": "01-nebula-field", "camera": Vector3(0.0, 0.0, 0.0), "target": Vector3(-138.0, 54.0, -465.0)},
	{"name": "02-aurelia-planet", "camera": Vector3(-160.0, 26.0, -105.0), "target": Vector3(-160.0, 26.0, -285.0)},
	{"name": "03-ringed-gas-giant", "camera": Vector3(430.0, -12.0, -900.0), "target": Vector3(430.0, -92.0, -1320.0)},
	{"name": "04-spiral-galaxy", "camera": Vector3(35.0, 148.0, -300.0), "target": Vector3(35.0, 148.0, -920.0)},
	{"name": "05-comet-landmark", "camera": Vector3(-520.0, 205.0, -1600.0), "target": Vector3(-520.0, 205.0, -1880.0)},
	{"name": "06-derelict-wreck", "camera": Vector3(285.0, -70.0, -570.0), "target": Vector3(285.0, -118.0, -690.0)},
	{"name": "07-asteroid-corridor", "camera": Vector3(0.0, 18.0, -13000.0), "target": Vector3(0.0, 18.0, -14000.0)}
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
		_camera.global_position = shot["camera"]
		_camera.look_at(shot["target"], Vector3.UP)
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
