extends GPUParticles3D
class_name LocalSpaceDust
## Micro dust / grit around the ship for speed parallax. Visual only.

@export var track_path: NodePath
@export var base_amount: int = 64

var _track: Node3D


func _ready() -> void:
	if track_path != NodePath(""):
		_track = get_node_or_null(track_path) as Node3D
	amount = base_amount
	lifetime = 2.2
	explosiveness = 0.0
	randomness = 0.8
	local_coords = false
	emitting = true
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = 28.0
	ppm.direction = Vector3(0, 0, 1)
	ppm.spread = 180.0
	ppm.initial_velocity_min = 0.05
	ppm.initial_velocity_max = 0.4
	ppm.gravity = Vector3.ZERO
	ppm.scale_min = 0.02
	ppm.scale_max = 0.06
	ppm.color = Color(0.75, 0.8, 0.9, 0.35)
	process_material = ppm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var sm := StandardMaterial3D.new()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.vertex_color_use_as_albedo = true
	sm.albedo_color = Color(0.85, 0.9, 1.0, 0.4)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.no_depth_test = false
	quad.material = sm
	draw_pass_1 = quad
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("particle_amount_scale"):
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	var s: float = gq.particle_amount_scale()
	amount = maxi(12, int(float(base_amount) * s))
	emitting = s > 0.3


func _process(_delta: float) -> void:
	if _track == null or not is_instance_valid(_track):
		if track_path != NodePath(""):
			_track = get_node_or_null(track_path) as Node3D
		if _track == null:
			return
	global_position = _track.global_position
