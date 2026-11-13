extends Node3D
class_name ParallaxNebulaLayer
## Soft world-space nebula cards for parallax between ship and sky.
## Quality-aware; disabled on Low.

@export var card_count: int = 5
@export var radius: float = 420.0
@export var card_size: float = 180.0

var _cards: Array[MeshInstance3D] = []


func _ready() -> void:
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("gas_cloud_enabled") and not gq.gas_cloud_enabled():
		visible = false
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var shader := load("res://assets/shaders/nebula_billboard.gdshader") as Shader
	for i in card_count:
		var mi := MeshInstance3D.new()
		mi.name = "NebulaCard%d" % i
		var quad := QuadMesh.new()
		var s := card_size * rng.randf_range(0.7, 1.4)
		quad.size = Vector2(s, s * rng.randf_range(0.55, 0.9))
		mi.mesh = quad
		var angle := rng.randf() * TAU
		var elev := rng.randf_range(-0.35, 0.45)
		var r := radius * rng.randf_range(0.65, 1.15)
		mi.position = Vector3(cos(angle) * r, elev * r, sin(angle) * r)
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.render_priority = -8
			var tint := Color(
				rng.randf_range(0.15, 0.45),
				rng.randf_range(0.1, 0.35),
				rng.randf_range(0.35, 0.7),
				rng.randf_range(0.08, 0.18)
			)
			mat.set_shader_parameter("nebula_color", tint)
			mat.set_shader_parameter("softness", rng.randf_range(1.6, 2.8))
			mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 2800.0
		add_child(mi)
		_cards.append(mi)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for mi in _cards:
		if mi:
			mi.look_at(cam.global_position, Vector3.UP)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	if gq.has_method("gas_cloud_enabled"):
		visible = gq.gas_cloud_enabled()
