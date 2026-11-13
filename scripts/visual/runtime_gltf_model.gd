extends Node3D
## Loads a GLB through Godot's runtime GLTFDocument API.
## This avoids relying on editor-generated import cache metadata at runtime.

@export_file("*.glb") var source_path: String
@export var model_scale: Vector3 = Vector3.ONE

static var _packed_scene_cache: Dictionary = {}
static var _surface_albedo_noise: NoiseTexture2D
static var _surface_roughness_noise: NoiseTexture2D


static func apply_surface_finish(root: Node) -> int:
	# GLB only carries standard PBR maps; add a lightweight Godot-side detail
	# layer after import so procedural Blender materials also read correctly
	# in the actual game, not just in the Blender preview renders.
	if _surface_albedo_noise == null or _surface_roughness_noise == null:
		_create_surface_noise()
	return _apply_surface_finish_recursive(root)


static func _create_surface_noise() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 20261113
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.085

	var albedo_ramp := Gradient.new()
	albedo_ramp.set_color(0, Color(0.88, 0.88, 0.88, 1.0))
	albedo_ramp.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
	_surface_albedo_noise = NoiseTexture2D.new()
	_surface_albedo_noise.noise = noise
	_surface_albedo_noise.color_ramp = albedo_ramp
	_surface_albedo_noise.width = 256
	_surface_albedo_noise.height = 256
	_surface_albedo_noise.seamless = true
	_surface_albedo_noise.generate_mipmaps = true

	var roughness_ramp := Gradient.new()
	roughness_ramp.set_color(0, Color(0.72, 0.72, 0.72, 1.0))
	roughness_ramp.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
	_surface_roughness_noise = NoiseTexture2D.new()
	_surface_roughness_noise.noise = noise
	_surface_roughness_noise.color_ramp = roughness_ramp
	_surface_roughness_noise.width = 256
	_surface_roughness_noise.height = 256
	_surface_roughness_noise.seamless = true
	_surface_roughness_noise.generate_mipmaps = true


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
	# Preserve canopy transparency and unshaded emissive elements; the detail
	# layer is intended for opaque painted hulls, armor and structural parts.
	if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return material
	material.detail_enabled = true
	material.detail_albedo = _surface_albedo_noise
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
	# The original hand-built hull meshes predate UV authoring. Triplanar
	# projection keeps the new detail visible on those meshes immediately,
	# while the new UV maps provide a clean path for future baked textures.
	if material.albedo_texture == null:
		material.uv1_triplanar = true
		material.uv1_triplanar_sharpness = 4.0
		material.uv1_scale = Vector3(2.0, 2.0, 2.0)
	if material.roughness_texture == null:
		material.roughness_texture = _surface_roughness_noise
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	# The fleet uses painted aerospace armor, not mirror-finished bare metal.
	# A restrained metalness ceiling keeps the hull readable without relying on
	# an expensive reflection probe in the large open-space scene.
	material.metallic = minf(material.metallic, 0.62)
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
	var detailed_surfaces: int = 0
	# Godot's dummy renderer used by headless smoke tests cannot render detail
	# textures. Keep those tests quiet; the dedicated GLB test still exercises
	# the finish on detached scenes, and real desktop builds apply it normally.
	if DisplayServer.get_name() != "headless":
		detailed_surfaces = apply_surface_finish(instance)
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
