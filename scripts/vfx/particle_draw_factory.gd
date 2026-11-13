extends RefCounted
class_name ParticleDrawFactory
## Builds optimized GPU particle draw passes (soft / spark).
## Avoids duplicating StandardMaterial3D billboards across VFX scripts.

static func soft_quad(size: float = 0.1, tint: Color = Color(0.8, 0.9, 1.0), emissive: float = 1.1) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var shader := load("res://assets/shaders/soft_particle.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("softness", 1.9)
		mat.set_shader_parameter("emissive_boost", emissive)
		mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
		q.material = mat
	return q


static func spark_quad(size: float = 0.12) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var shader := load("res://assets/shaders/thrust_spark_particle.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("core_power", 3.6)
		mat.set_shader_parameter("halo_softness", 2.1)
		mat.set_shader_parameter("emissive_boost", 2.5)
		q.material = mat
	return q


static func apply_budget(gp: GPUParticles3D, base_amount: int, scale: float) -> void:
	if gp == null:
		return
	gp.amount = maxi(4, int(float(base_amount) * scale))
	gp.fixed_fps = 30 if scale < 0.5 else 0
	gp.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	gp.emitting = scale > 0.25
