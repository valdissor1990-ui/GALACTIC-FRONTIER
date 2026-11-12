extends SceneTree
## Validates all seven GLB files through Godot's runtime glTF parser.
## ResourceLoader import metadata is not required; GLTFDocument reads the binary GLB directly.

const SHIPS := [
	"res://assets/models/ships/player_fighter.glb",
	"res://assets/models/ships/enemy_fighter.glb",
	"res://assets/models/ships/heavy_fighter.glb",
	"res://assets/models/ships/bomber.glb",
	"res://assets/models/ships/cargo_hauler.glb",
	"res://assets/models/ships/frigate.glb",
	"res://assets/models/ships/cruiser.glb"
]

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in SHIPS:
		_validate_glb(path)
	if _failed == 0:
		print("SHIP_ASSET_VALIDATION_PASS: %d/7 runtime GLB scenes" % _passed)
		quit(0)
	else:
		print("SHIP_ASSET_VALIDATION_FAIL: %d passed, %d failed" % [_passed, _failed])
		quit(1)


func _validate_glb(path: String) -> void:
	if not FileAccess.file_exists(path):
		_fail(path, "file is missing")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 4096:
		_fail(path, "file is unreadable or implausibly small")
		return
	var magic := file.get_buffer(4)
	file.close()
	if magic != PackedByteArray([103, 108, 84, 70]):
		_fail(path, "GLB header is not glTF")
		return

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state)
	if error != OK:
		_fail(path, "GLTFDocument.append_from_file returned %d" % error)
		return
	var scene := document.generate_scene(state)
	if scene == null:
		_fail(path, "GLTFDocument.generate_scene returned null")
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(scene, meshes)
	if meshes.is_empty():
		_fail(path, "runtime GLB scene contains no MeshInstance3D")
		scene.free()
		return
	var valid_surfaces := 0
	for instance in meshes:
		if instance.mesh != null and instance.mesh.get_surface_count() > 0:
			valid_surfaces += instance.mesh.get_surface_count()
	if valid_surfaces == 0:
		_fail(path, "runtime GLB scene contains no renderable mesh surfaces")
		scene.free()
		return

	_passed += 1
	print("  PASS  %s — %d mesh nodes, %d surfaces" % [path.get_file(), meshes.size(), valid_surfaces])
	scene.free()


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)


func _fail(path: String, reason: String) -> void:
	_failed += 1
	push_error("SHIP_ASSET_LOAD_FAILED: %s — %s" % [path, reason])
