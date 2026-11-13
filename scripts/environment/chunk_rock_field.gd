extends MultiMeshInstance3D
class_name ChunkRockField
## Angular rock shards for near belt — contrasts with sphere shells.

@export var count: int = 80
@export var radius: float = 130.0
@export var width: float = 40.0
@export var height: float = 14.0
@export var albedo: Color = Color(0.26, 0.22, 0.18)
@export var scale_min: float = 0.5
@export var scale_max: float = 2.2
@export var vis_end: float = 150.0


func _ready() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("asteroid_count"):
		count = maxi(24, gq.asteroid_count() / 4)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 0.85, 1.0)
	var shader := load("res://assets/shaders/rock_surface.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("base_color", albedo)
		mat.set_shader_parameter("dark_color", albedo.darkened(0.5))
		mat.set_shader_parameter("highlight_color", albedo.lightened(0.3))
		mat.set_shader_parameter("noise_scale", 5.5)
		mat.set_shader_parameter("crater_amount", 0.55)
		box.material = mat
	mm.mesh = box
	for i in count:
		var angle := rng.randf() * TAU
		var r := radius + rng.randf_range(-width, width)
		var y := rng.randf_range(-height, height)
		var pos := Vector3(cos(angle) * r, y, sin(angle) * r)
		var s := rng.randf_range(scale_min, scale_max)
		var basis := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		basis = basis.scaled(Vector3(s * rng.randf_range(0.6, 1.3), s * rng.randf_range(0.4, 1.1), s * rng.randf_range(0.7, 1.4)))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	multimesh = mm
	visibility_range_end = vis_end
	visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if gq and gq.has_method("object_view_distance_mul"):
		visibility_range_end = vis_end * gq.object_view_distance_mul()


func apply_quality(gq: Node) -> void:
	if gq and gq.has_method("object_view_distance_mul"):
		visibility_range_end = vis_end * gq.object_view_distance_mul()
