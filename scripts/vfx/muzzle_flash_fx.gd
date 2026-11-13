extends Node3D
class_name MuzzleFlashFx
## One-shot muzzle flash. Call play_flash() from weapon fire.

@export var base_amount: int = 18
@export var lifetime: float = 0.12

var _gp: GPUParticles3D
var _cooldown: float = 0.0


func _ready() -> void:
	_gp = GPUParticles3D.new()
	_gp.name = "FlashParticles"
	_gp.amount = base_amount
	_gp.lifetime = lifetime
	_gp.one_shot = true
	_gp.explosiveness = 1.0
	_gp.randomness = 0.4
	_gp.emitting = false
	_gp.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 6))
	var ppm := ParticleProcessMaterial.new()
	ppm.direction = Vector3(0, 0, -1)
	ppm.spread = 28.0
	ppm.initial_velocity_min = 4.0
	ppm.initial_velocity_max = 14.0
	ppm.gravity = Vector3.ZERO
	ppm.damping_min = 8.0
	ppm.damping_max = 16.0
	ppm.scale_min = 0.7
	ppm.scale_max = 1.6
	ppm.color = Color(0.7, 0.9, 1.0, 0.9)
	_gp.process_material = ppm
	_gp.draw_pass_1 = ParticleDrawFactory.spark_quad(0.14)
	add_child(_gp)
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("particle_amount_scale"):
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null or _gp == null:
		return
	ParticleDrawFactory.apply_budget(_gp, base_amount, gq.particle_amount_scale())


func play_flash() -> void:
	if _gp == null:
		return
	if _cooldown > 0.0:
		return
	_gp.restart()
	_gp.emitting = true
	_cooldown = lifetime * 0.85


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
