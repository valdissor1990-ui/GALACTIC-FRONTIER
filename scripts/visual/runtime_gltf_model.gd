extends Node3D
## Loads a GLB through Godot's runtime GLTFDocument API.
## This avoids relying on editor-generated import cache metadata at runtime.

@export_file("*.glb") var source_path: String
@export var model_scale: Vector3 = Vector3.ONE

static var _packed_scene_cache: Dictionary = {}

func _ready() -> void:
	if source_path.is_empty():
		_show_fallback_visuals()
		push_error("RuntimeGLTFModel: source_path is empty.")
		return
	var packed := _packed_scene_cache.get(source_path) as PackedScene
	if packed == null:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_file(source_path, state)
		if error != OK:
			_show_fallback_visuals()
			push_error("RuntimeGLTFModel: cannot parse %s (error %d)" % [source_path, error])
			return
		var model_root := document.generate_scene(state)
		if model_root == null:
			_show_fallback_visuals()
			push_error("RuntimeGLTFModel: generated scene is null for %s" % source_path)
			return
		var generated := PackedScene.new()
		var pack_error := generated.pack(model_root)
		if pack_error != OK:
			_show_fallback_visuals()
			push_error("RuntimeGLTFModel: cannot pack %s (error %d)" % [source_path, pack_error])
			model_root.free()
			return
		model_root.free()
		_packed_scene_cache[source_path] = generated
		packed = generated
	var instance := packed.instantiate()
	instance.name = "Model"
	instance.scale = model_scale
	add_child(instance)


func _show_fallback_visuals() -> void:
	var visual_root := get_parent()
	if visual_root == null:
		return
	for sibling in visual_root.get_children():
		if sibling == self:
			continue
		_set_fallback_meshes_visible(sibling)


func _set_fallback_meshes_visible(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = true
	for child in node.get_children():
		_set_fallback_meshes_visible(child)
