extends Node3D
class_name EngineThrustFx
## Visual-only thruster intensity. Does not affect flight physics.

@export var ship_path: NodePath
@export var idle_intensity: float = 0.25
@export var cruise_intensity: float = 0.85
@export var boost_intensity: float = 1.8
@export var response: float = 8.0

var _ship: ShipController
var _particles: Array[GPUParticles3D] = []
var _plume_mats: Array[ShaderMaterial] = []
var _intensity: float = 0.25
var _particle_scale: float = 1.0
var _base_amounts: Array[int] = []


func _ready() -> void:
	if ship_path != NodePath(""):
		_ship = get_node_or_null(ship_path) as ShipController
	if _ship == null:
		_ship = get_parent() as ShipController
	for child in get_children():
		if child is GPUParticles3D:
			var p := child as GPUParticles3D
			_particles.append(p)
			_base_amounts.append(p.amount)
			p.emitting = true
		elif child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat is ShaderMaterial:
				_plume_mats.append(mat)
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq:
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	_particle_scale = gq.particle_amount_scale()
	for i in _particles.size():
		var base_amt := _base_amounts[i] if i < _base_amounts.size() else _particles[i].amount
		_particles[i].amount = maxi(4, int(float(base_amt) * _particle_scale))


func _process(delta: float) -> void:
	var target := idle_intensity
	if _ship != null:
		var speed := _ship.velocity.length()
		var max_speed := 40.0
		if _ship.flight_config:
			max_speed = maxf(1.0, _ship.flight_config.max_speed)
		var speed_n := clampf(speed / max_speed, 0.0, 1.0)
		target = lerpf(idle_intensity, cruise_intensity, speed_n)
		if Input.is_action_pressed("boost") and _ship.boost_amount > 0.0:
			target = boost_intensity
		elif Input.is_action_pressed("brake"):
			target = idle_intensity * 0.5
	_intensity = lerpf(_intensity, target, 1.0 - exp(-response * delta))
	for p in _particles:
		p.amount_ratio = clampf(_intensity / boost_intensity, 0.15, 1.0)
		var mat := p.process_material
		if mat is ParticleProcessMaterial:
			(mat as ParticleProcessMaterial).initial_velocity_max = 6.0 + _intensity * 10.0
	for m in _plume_mats:
		m.set_shader_parameter("intensity", _intensity)
