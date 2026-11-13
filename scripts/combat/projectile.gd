extends Area3D
class_name CombatProjectile
## Energy bolt with a visible luminous core, trail and impact burst.

@export_range(1.0, 2000.0, 1.0) var speed: float = 180.0
@export_range(0.1, 1000.0, 0.1) var damage: float = 18.0
@export_range(0.1, 20.0, 0.1) var lifetime: float = 5.0

var _direction: Vector3 = Vector3.FORWARD
var _source: Node3D
var _remaining_lifetime: float = 5.0
var _impacted: bool = false


func configure(direction: Vector3, source: Node3D, projectile_speed: float, projectile_damage: float) -> void:
	_direction = direction.normalized()
	_source = source
	speed = projectile_speed
	damage = projectile_damage
	_remaining_lifetime = lifetime


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_trail()


func _physics_process(delta: float) -> void:
	var motion := _direction * speed * delta
	if _sweep_for_impact(motion):
		_remaining_lifetime -= delta
		if _remaining_lifetime <= 0.0 and is_inside_tree():
			queue_free()
		return
	global_position += motion
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()


func _sweep_for_impact(motion: Vector3) -> bool:
	if motion.length_squared() <= 0.000001 or not is_inside_tree():
		return false
	var space := get_world_3d().direct_space_state
	var excluded: Array[RID] = []
	if is_instance_valid(_source) and _source is CollisionObject3D:
		excluded.append((_source as CollisionObject3D).get_rid())

	# Nine parallel rays approximate the projectile's 0.12 m spherical radius.
	# This avoids discrete overlap tunnelling without allocating physics bodies.
	var right_raw := _direction.cross(Vector3.UP)
	if right_raw.length_squared() <= 0.0001:
		right_raw = _direction.cross(Vector3.RIGHT)
	var right := right_raw.normalized()
	var up := _direction.cross(right).normalized()
	var radius := 0.12
	var diagonal := radius * 0.70710678
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		right * radius, -right * radius,
		up * radius, -up * radius,
		(right + up) * diagonal, (right - up) * diagonal,
		(-right + up) * diagonal, (-right - up) * diagonal
	]
	var best_distance_squared := INF
	var best_collider: Node3D
	var best_position := global_position
	for offset in offsets:
		var ray := PhysicsRayQueryParameters3D.create(
			global_position + offset,
			global_position + motion + offset,
			collision_mask,
			excluded
		)
		ray.collide_with_areas = false
		ray.collide_with_bodies = true
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			continue
		var collider: Variant = hit.get("collider")
		if not collider is Node3D or _is_source_or_child(collider as Node3D):
			continue
		var hit_position: Vector3 = hit.get("position", global_position + motion)
		var projectile_position := hit_position - offset
		var distance_squared := global_position.distance_squared_to(projectile_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_collider = collider as Node3D
			best_position = projectile_position
	if best_collider == null:
		return false
	global_position = best_position
	_on_body_entered(best_collider)
	return true


func _create_trail() -> void:
	var hostile := is_instance_valid(_source) and _source.is_in_group("hostile_fighters")
	var tint := Color(1.0, 0.16, 0.045) if hostile else Color(0.08, 0.66, 1.0)
	var trail := GPUParticles3D.new()
	trail.name = "EnergyTrail"
	trail.amount = 14
	trail.lifetime = 0.075
	trail.explosiveness = 0.0
	trail.randomness = 0.22
	trail.local_coords = false
	trail.position = Vector3(0.0, 0.0, 0.22)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 8.0
	process.initial_velocity_min = 3.0
	process.initial_velocity_max = 8.0
	process.gravity = Vector3.ZERO
	process.damping_min = 1.0
	process.damping_max = 2.5
	process.scale_min = 0.025
	process.scale_max = 0.055
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 0.95))
	gradient.add_point(0.35, tint)
	gradient.set_color(gradient.get_point_count() - 1, Color(tint.r, tint.g, tint.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	trail.process_material = process
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.08
	particle_mesh.height = 0.16
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	var particle_material := StandardMaterial3D.new()
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_material.albedo_color = tint
	particle_material.emission_enabled = true
	particle_material.emission = tint
	particle_material.emission_energy_multiplier = 3.0
	particle_mesh.material = particle_material
	trail.draw_pass_1 = particle_mesh
	add_child(trail)
	trail.emitting = true


func _on_body_entered(body: Node3D) -> void:
	if _impacted or not is_instance_valid(body) or _is_source_or_child(body):
		return
	_impacted = true

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call("play_3d", audio_manager.get("impact_stream"), global_position, -8.0, 30.0, 520.0)
	var damageable := _find_damageable(body)
	if damageable != null:
		damageable.call("take_damage", damage)
	var tint := Color(1.0, 0.16, 0.045) if (is_instance_valid(_source) and _source.is_in_group("hostile_fighters")) else Color(0.08, 0.66, 1.0)
	CombatEffects.spawn_burst(get_tree().current_scene, global_position, tint, 0.55)
	queue_free()


func _is_source_or_child(node: Node) -> bool:
	if not is_instance_valid(node) or not is_instance_valid(_source):
		return false
	var current: Node = node
	while is_instance_valid(current):
		if current == _source:
			return true
		current = current.get_parent()
	return false


func _find_damageable(node: Node) -> Node:
	if not is_instance_valid(node):
		return null
	var current: Node = node
	while is_instance_valid(current):
		if current.has_method("take_damage"):
			return current
		var component := current.get_node_or_null("Damageable")
		if component != null and component.has_method("take_damage"):
			return component
		current = current.get_parent()
	return null
