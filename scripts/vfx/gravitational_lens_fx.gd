extends Node
class_name GravitationalLensFx
## Full-screen gravitational lens driven by GravityLensMass markers in the scene.
##
## Add as child of the flight scene (or any Node3D root). Builds a CanvasLayer
## ColorRect that samples the screen and warps UVs toward projected masses.

@export var max_masses: int = 2
@export var auto_find_masses: bool = true
@export var camera_path: NodePath
@export var strength_multiplier: float = 1.0
@export var min_effect_distance: float = 40.0
@export var max_effect_distance: float = 900.0

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _camera: Camera3D
var _masses: Array[Node3D] = []


func _ready() -> void:
	_build_overlay()
	_resolve_camera()
	if auto_find_masses:
		call_deferred("_collect_masses")
	var gq := _gq()
	if gq:
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if _mat == null or gq == null:
		return
	var enabled: bool = true
	if gq.has_method("lens_enabled"):
		enabled = gq.lens_enabled()
	if _layer:
		_layer.visible = enabled
	if not enabled:
		return
	var overall := 1.0
	if gq.has_method("lens_strength"):
		overall = gq.lens_strength()
	_mat.set_shader_parameter("overall", overall * strength_multiplier)
	var chroma := 0.004
	if gq.has_method("lens_chroma"):
		chroma = gq.lens_chroma()
	_mat.set_shader_parameter("chroma", chroma)
	var ring := 0.85
	if gq.has_method("lens_ring_boost"):
		ring = gq.lens_ring_boost()
	_mat.set_shader_parameter("ring_boost", ring)


func register_mass(mass: Node3D) -> void:
	if mass and mass not in _masses:
		_masses.append(mass)


func _gq() -> Node:
	return get_node_or_null("/root/GraphicsQuality")


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "GravitationalLensLayer"
	_layer.layer = 80
	add_child(_layer)

	# Ensure we sample the 3D buffer behind this canvas item
	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	_layer.add_child(bbc)

	_rect = ColorRect.new()
	_rect.name = "LensRect"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	var shader := load("res://assets/shaders/gravitational_lens.gdshader") as Shader
	if shader:
		_mat.shader = shader
	_rect.material = _mat
	_layer.add_child(_rect)

	# Clear masses until process fills them
	_mat.set_shader_parameter("mass0_strength", 0.0)
	_mat.set_shader_parameter("mass1_strength", 0.0)


func _resolve_camera() -> void:
	if camera_path != NodePath(""):
		_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		_camera = get_viewport().get_camera_3d()


func _collect_masses() -> void:
	_masses.clear()
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	_walk_masses(root)


func _walk_masses(node: Node) -> void:
	if node is Node3D and node.is_in_group("gravity_lens_mass"):
		_masses.append(node as Node3D)
	elif node is Node3D and node.has_meta("lens_mass"):
		_masses.append(node as Node3D)
	for c in node.get_children():
		_walk_masses(c)


func _process(_delta: float) -> void:
	if _mat == null:
		return
	if _layer and not _layer.visible:
		return
	if _camera == null or not is_instance_valid(_camera):
		_resolve_camera()
	if _camera == null:
		return
	if auto_find_masses and _masses.is_empty():
		_collect_masses()

	var scored: Array = []
	for m in _masses:
		if m == null or not is_instance_valid(m):
			continue
		var dist := _camera.global_position.distance_to(m.global_position)
		if dist > max_effect_distance or dist < 1.0:
			continue
		var behind := _camera.is_position_behind(m.global_position)
		if behind:
			continue
		var mass_factor := 1.0
		if m.has_meta("lens_strength"):
			mass_factor = float(m.get_meta("lens_strength"))
		elif "lens_strength" in m:
			mass_factor = float(m.get("lens_strength"))
		var t := 1.0 - clampf((dist - min_effect_distance) / maxf(max_effect_distance - min_effect_distance, 1.0), 0.0, 1.0)
		var strength := mass_factor * t * t
		if strength < 0.02:
			continue
		var screen := _camera.unproject_position(m.global_position)
		var vp_size := get_viewport().get_visible_rect().size
		if vp_size.x < 1.0 or vp_size.y < 1.0:
			continue
		var uv := Vector2(screen.x / vp_size.x, screen.y / vp_size.y)
		var rad := 0.2
		if m.has_meta("lens_radius"):
			rad = float(m.get_meta("lens_radius"))
		# Apparent size grows when closer
		rad *= clampf(180.0 / dist, 0.55, 2.2)
		scored.append({"uv": uv, "strength": strength, "radius": rad})

	scored.sort_custom(func(a, b): return a["strength"] > b["strength"])

	for i in 2:
		var prefix := "mass%d_" % i
		if i < scored.size() and i < max_masses:
			_mat.set_shader_parameter(prefix + "uv", scored[i]["uv"])
			_mat.set_shader_parameter(prefix + "strength", scored[i]["strength"])
			_mat.set_shader_parameter(prefix + "radius", scored[i]["radius"])
		else:
			_mat.set_shader_parameter(prefix + "strength", 0.0)
