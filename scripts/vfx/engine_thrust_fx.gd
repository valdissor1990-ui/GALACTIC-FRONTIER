extends Node3D
class_name EngineThrustFx
## Thruster plumes, boost trails, hull heat. Visual only.

@export var ship_path: NodePath
@export var idle_intensity: float = 0.25
@export var cruise_intensity: float = 0.85
@export var boost_intensity: float = 1.8
@export var response: float = 8.0
@export var enable_boost_trails: bool = true
@export var drive_hull_heat: bool = true

var _ship: ShipController
var _particles: Array[GPUParticles3D] = []
var _plume_mats: Array[ShaderMaterial] = []
var _hull_mats: Array[ShaderMaterial] = []
var _trail_particles: Array[GPUParticles3D] = []
var _intensity: float = 0.25
var _boosting: bool = false


func _ready() -> void:
	if ship_path != NodePath(""):
		_ship = get_node_or_null(ship_path) as ShipController
	if _ship == null:
		_ship = get_parent() as ShipController
	for child in get_children():
		if child is GPUParticles3D:
			var gp := child as GPUParticles3D
			if str(gp.name).begins_with("Trail") or gp.get_meta("is_boost_trail", false):
				_trail_particles.append(gp)
				gp.emitting = false
			else:
				_particles.append(gp)
				gp.emitting = true
		elif child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat is ShaderMaterial:
				_plume_mats.append(mat)
	if enable_boost_trails and _trail_particles.is_empty():
		_spawn_default_trails()
	if drive_hull_heat:
		_collect_hull_mats()
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq and gq.has_method("particle_amount_scale"):
		apply_quality(gq)


func apply_quality(gq: Node) -> void:
	if gq == null:
		return
	var scale: float = 1.0
	if gq.has_method("particle_amount_scale"):
		scale = gq.particle_amount_scale()
	for p in _particles:
		p.amount = maxi(8, int(24.0 * scale))
	for t in _trail_particles:
		t.amount = maxi(12, int(48.0 * scale))
		t.visible = scale > 0.4


func _collect_hull_mats() -> void:
	var root := get_parent()
	if root == null:
		return
	var visual := root.get_node_or_null("Visual")
	if visual == null:
		return
	for child in visual.get_children():
		if child is MeshInstance3D:
			var mat := (child as MeshInstance3D).get_active_material(0)
			if mat is ShaderMaterial and (mat as ShaderMaterial).shader:
				var path := str((mat as ShaderMaterial).shader.resource_path)
				if path.find("hull_fresnel") >= 0:
					_hull_mats.append(mat)


func _spawn_default_trails() -> void:
	# Trails aligned with existing plume offsets if present
	offset_list := [Vector3(-0.38, 0, 2.2), Vector3(0.38, 0, 2.2)]
	for i in offset_list.size():
		var gp := GPUParticles3D.new()
		gp.name = "Trail%d" % i
		gp.position = offset_list[i]
		gp.amount = 40
		gp.lifetime = 0.55
		gp.explosiveness = 0.0
		gp.randomness = 0.25
		gp.local_coords = false
		gp.emitting = false
		gp.set_meta("is_boost_trail", true)
		var ppm := ParticleProcessMaterial.new()
		ppm.direction = Vector3(0, 0, 1)
		ppm.spread = 6.0
		ppm.initial_velocity_min = 2.0
		ppm.initial_velocity_max = 8.0
		ppm.gravity = Vector3.ZERO
		ppm.damping_min = 1.0
		ppm.damping_max = 3.0
		ppm.scale_min = 0.06
		ppm.scale_max = 0.18
		ppm.color = Color(0.4, 0.75, 1.0, 0.55)
		gp.process_material = ppm
		var draw := QuadMesh.new()
		draw.size = Vector2(0.2, 0.2)
		var sm := StandardMaterial3D.new()
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = Color(0.45, 0.85, 1.0, 0.7)
		sm.emission_enabled = true
		sm.emission = Color(0.35, 0.75, 1.0)
		sm.emission_energy_multiplier = 1.8
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		draw.material = sm
		gp.draw_pass_1 = draw
		add_child(gp)
		_trail_particles.append(gp)


func _process(delta: float) -> void:
	var target := idle_intensity
	_boosting = false
	if _ship != null:
		var speed := _ship.velocity.length()
		var max_speed := 40.0
		if _ship.flight_config:
			max_speed = maxf(1.0, _ship.flight_config.max_speed)
		var speed_n := clampf(speed / max_speed, 0.0, 1.0)
		target = lerpf(idle_intensity, cruise_intensity, speed_n)
		if Input.is_action_pressed("boost") and _ship.boost_amount > 0.0:
			target = boost_intensity
			_boosting = true
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
	# Boost trails
	for t in _trail_particles:
		t.emitting = _boosting and _intensity > 1.0
		if t.emitting:
			var pm := t.process_material
			if pm is ParticleProcessMaterial:
				(pm as ParticleProcessMaterial).initial_velocity_max = 10.0 + _intensity * 14.0
	# Hull heat (engines / re-entry look)
	var heat := clampf((_intensity - idle_intensity) / (boost_intensity - idle_intensity), 0.0, 1.0)
	heat = heat * heat
	for hm in _hull_mats:
		hm.set_shader_parameter("heat", heat * 0.85)
