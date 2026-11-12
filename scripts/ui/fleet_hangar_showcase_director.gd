extends Node
## Captures each ship in the real interactive hangar for visual regression review.

@onready var hangar: Control = get_node("FleetHangar")

func _ready() -> void:
	call_deferred("_capture_fleet")

func _capture_fleet() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var directory := ProjectSettings.globalize_path("user://screenshots")
	var make_error := DirAccess.make_dir_recursive_absolute(directory)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		push_error("Could not create fleet screenshot directory: " + str(make_error))
		get_tree().quit(1)
		return
	for index in range(hangar.get_ship_count()):
		await get_tree().create_timer(0.55).timeout
		await RenderingServer.frame_post_draw
		var mesh_count: int = hangar.get_visible_model_mesh_count()
		if mesh_count <= 0:
			push_error("Fleet hangar screenshot %d has no visible ship meshes" % (index + 1))
			get_tree().quit(1)
			return
		var image := get_viewport().get_texture().get_image()
		var path := directory.path_join("fleet-hangar-%02d.png" % (index + 1))
		var save_error := image.save_png(path)
		if save_error != OK:
			push_error("Could not save fleet hangar screenshot: " + path)
			get_tree().quit(1)
			return
		print("FLEET_HANGAR_CAPTURE=", path, " mesh_count=", mesh_count)
		hangar.show_next_ship()
		await get_tree().process_frame
	print("FLEET_HANGAR_SHOWCASE_COMPLETE ships=", hangar.get_ship_count())
	get_tree().quit(0)
