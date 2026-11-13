extends GPUParticles3D
class_name LocalSpaceDust
## Micro dust with soft_particle draw shader. Visual only.

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
	fixed_fps = 0
	emitting = true
	visibility_aabb = AABB(Vector3(-36, -36, -36), Vector3(72, 72, 72))
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = 28.0
	ppm.direction = Vector3(0, 0, 1)
	ppm.spread = 180.0
	ppm.initial_velocity_min = 0.05
	ppm.initial_velocity_max = 0.35
	ppm.gravity = Vector3.ZERO
	ppm.scale_min = 0.5
	ppm.scale_max = 1.4
	ppm.color = Color(0.75, 0.82, 0.95, 0.28)
	process_material = ppm
	draw_pass_1 = ParticleDrawFactory.soft_quad(0.09, Color(0.8, 0.88, 1.0), 0.9)
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("particle_amount_scale"):
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	var s: float = gq.particle_amount_scale()
	ParticleDrawFactory.apply_budget(self, base_amount, s)


func _process(_delta: float) -> void:
	if _track == null or not is_instance_valid(_track):
		if track_path != NodePath(""):
			_track = get_node_or_null(track_path) as Node3D
		if _track == null:
			return
	global_position = _track.global_position
