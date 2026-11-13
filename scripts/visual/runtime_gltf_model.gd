extends Node3D
## Loads a GLB through Godot's runtime GLTFDocument API.
## This avoids relying on editor-generated import cache metadata at runtime.

@export_file("*.glb") var source_path: String
@export var model_scale: Vector3 = Vector3.ONE

static var _packed_scene_cache: Dictionary = {}
static var _surface_albedo_noise: NoiseTexture2D
static var _surface_normal_noise: NoiseTexture2D


static func apply_surface_finish(root: Node) -> int:
	# GLB only carries standard PBR maps; add a lightweight Godot-side detail
	# layer after import so procedural Blender materials also read correctly
	# in the actual game, not just in the Blender preview renders.
	if _surface_albedo_noise == null or _surface_normal_noise == null:
		_create_surface_noise()
	return _apply_surface_finish_recursive(root)


static func _create_surface_noise() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 20261113
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.085

	var subtle_ramp := Gradient.new()
	subtle_ramp.set_color(0, Color(0.88, 0.88, 0.88, 1.0))
	subtle_ramp.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = subtle_ramp

	_surface_albedo_noise = NoiseTexture2D.new()
	_surface_albedo_noise.noise = noise
	_surface_albedo_noise.color_ramp = ramp_texture
	_surface_albedo_noise.width = 256
	_surface_albedo_noise.height = 256
	_surface_albedo_noise.seamless = true
	_surface_albedo_noise.generate_mipmaps = true

	var normal_noise := NoiseTexture2D.new()
	normal_noise.noise = noise
	normal_noise.width = 256
	normal_noise.height = 256
	normal_noise.seamless = true
	normal_noise.generate_mipmaps = true
	normal_noise.as_normal_map = true
	normal_noise.bump_strength = 0.28
	_surface_normal_noise = normal_noise


static func _apply_surface_finish_recursive(node: Node) -> int:
	var updated := 0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			mesh_instance.material_override = _finished_material(mesh_instance.material_override as StandardMaterial3D)
			updated += 1
		if mesh_instance.mesh != null:
			for surface in range(mesh_instance.mesh.get_surface_count()):
				var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
				if source == null:
					continue
				mesh_instance.set_surface_override_material(surface, _finished_material(source))
				updated += 1
	for child in node.get_children():
		updated += _apply_surface_finish_recursive(child)
	return updated


static func _finished_material(source: StandardMaterial3D) -> StandardMaterial3D:
	var material := source.duplicate(true) as StandardMaterial3D
	material.detail_enabled = true
	material.detail_albedo = _surface_albedo_noise
	material.detail_blend_mode = BaseMaterial3D.DETAIL_BLEND_MODE_MUL
	material.detail_uv = BaseMaterial3D.DETAIL_UV_1
	material.detail_normal = _surface_normal_noise
	material.roughness = clampf(material.roughness, 0.24, 0.88)
	return material

func _ready() -> void:
	_apply_player_profile_selection()
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
	var detailed_surfaces := apply_surface_finish(instance)
	print("SHIP_SURFACE_FINISH: %s — %d material surfaces" % [source_path.get_file(), detailed_surfaces])
	add_child(instance)


func _apply_player_profile_selection() -> void:
	var visual_root := get_parent()
	if visual_root == null or visual_root.name != "Visual":
		return
	var ship_root := visual_root.get_parent()
	if ship_root == null or ship_root.name != "PlayerShip":
		return
	var profile := get_node_or_null("/root/GameProfile")
	if profile == null:
		return
	source_path = str(profile.call("get_selected_ship_model_path"))
	model_scale = Vector3.ONE * float(profile.call("get_selected_ship_scale"))


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
