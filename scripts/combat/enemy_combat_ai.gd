extends CharacterBody3D
class_name EnemyCombatAI
## Pursuit / strafe / retreat AI with predictive projectile interception.

enum State { APPROACH, STRAFE, RETREAT, DISABLED }

@export var max_speed: float = 70.0
@export var acceleration: float = 28.0
@export var turn_rate: float = 2.2
@export var approach_distance: float = 45.0
@export var strafe_distance: float = 28.0
@export var retreat_hull_ratio: float = 0.25
@export var fire_range: float = 90.0
@export var fire_angle_degrees: float = 18.0
@export var shots_per_second: float = 1.6
@export var projectile_speed: float = 160.0
@export var projectile_damage: float = 12.0
@export_range(0.0, 1.0, 0.05) var vertical_evasion_strength: float = 0.28
@export var projectile_scene: PackedScene

var player: Node3D
var state: State = State.APPROACH

var _damageable: Damageable
var _muzzle: Marker3D
var _cooldown: float = 0.0
var _strafe_sign: float = 1.0
var _strafe_timer: float = 0.0
var _evasion_phase: float = 0.0


func _ready() -> void:
	add_to_group("combat_targets")
	add_to_group("hostile_fighters")
	_damageable = get_node_or_null("Damageable") as Damageable
	_muzzle = get_node_or_null("Muzzle") as Marker3D
	if _damageable != null:
		_damageable.destroyed.connect(_on_destroyed)
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0
	_strafe_timer = randf_range(0.6, 1.8)
	_evasion_phase = randf_range(0.0, TAU)


func set_player(target: Node3D) -> void:
	player = target


func _physics_process(delta: float) -> void:
	if state == State.DISABLED:
		velocity = Vector3.ZERO
		return
	if player == null or not is_instance_valid(player):
		return

	_cooldown = maxf(0.0, _cooldown - delta)
	_evasion_phase = fposmod(_evasion_phase + delta * 2.1, TAU)
	_update_state()
	_steer_and_move(delta)
	_try_fire()
	move_and_slide()


func _update_state() -> void:
	if _damageable != null and _damageable.is_destroyed():
		state = State.DISABLED
		return

	var distance := global_position.distance_to(player.global_position)
	var hull_ratio := 1.0
	if _damageable != null:
		hull_ratio = _damageable.get_hull_ratio()

	if hull_ratio <= retreat_hull_ratio or distance < strafe_distance * 0.45:
		state = State.RETREAT
	elif distance > approach_distance:
		state = State.APPROACH
	else:
		state = State.STRAFE


func _steer_and_move(delta: float) -> void:
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var direct_direction := to_player.normalized()
	var desired_dir := Vector3.ZERO
	var facing_dir := direct_direction

	match state:
		State.APPROACH:
			desired_dir = direct_direction
			facing_dir = _get_lead_direction(global_position)
		State.STRAFE:
			_strafe_timer -= delta
			if _strafe_timer <= 0.0:
				_strafe_sign *= -1.0
				_strafe_timer = randf_range(1.2, 2.4)
			var side := global_transform.basis.x * _strafe_sign
			var hold := direct_direction * clampf((distance - strafe_distance) * 0.15, -1.0, 1.0)
			var vertical := Vector3.UP * sin(_evasion_phase) * vertical_evasion_strength
			desired_dir = (side + hold + vertical).normalized()
			facing_dir = _get_lead_direction(global_position)
		State.RETREAT:
			desired_dir = -direct_direction
			facing_dir = direct_direction
		_:
			desired_dir = Vector3.ZERO

	if facing_dir.length_squared() > 0.0001:
		var up_axis := Vector3.UP
		if absf(facing_dir.dot(up_axis)) > 0.96:
			up_axis = Vector3.FORWARD
		var target_basis := Basis.looking_at(facing_dir, up_axis)
		global_transform.basis = global_transform.basis.slerp(target_basis, clampf(turn_rate * delta, 0.0, 1.0)).orthonormalized()

	if desired_dir.length_squared() > 0.0001:
		velocity = velocity.move_toward(desired_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)


func _try_fire() -> void:
	if state == State.DISABLED or state == State.RETREAT:
		return
	if _cooldown > 0.0 or projectile_scene == null or _muzzle == null or player == null:
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > fire_range:
		return

	var aim_direction := _get_lead_direction(_muzzle.global_position)
	if aim_direction.length_squared() < 0.000001:
		return
	var forward := -global_transform.basis.z
	if rad_to_deg(forward.angle_to(aim_direction)) > fire_angle_degrees:
		return

	var projectile := projectile_scene.instantiate() as CombatProjectile
	if projectile == null:
		return
	projectile.configure(aim_direction, self, projectile_speed, projectile_damage)
	projectile.global_transform = _muzzle.global_transform
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(projectile)
	AudioManager.play_3d(AudioManager.weapon_stream, _muzzle.global_position, -11.0, 24.0, 420.0)
	_cooldown = 1.0 / maxf(shots_per_second, 0.1)


func _get_player_velocity() -> Vector3:
	if player is CharacterBody3D:
		return (player as CharacterBody3D).velocity
	return Vector3.ZERO


func _get_lead_direction(origin: Vector3) -> Vector3:
	if player == null or not is_instance_valid(player):
		return -global_transform.basis.z
	return calculate_intercept_direction(
		origin,
		player.global_position,
		_get_player_velocity(),
		projectile_speed
	)


static func calculate_intercept_time(relative_position: Vector3, target_velocity: Vector3, speed: float) -> float:
	if speed <= 0.001:
		return 0.0
	var a := target_velocity.dot(target_velocity) - speed * speed
	var b := 2.0 * relative_position.dot(target_velocity)
	var c := relative_position.dot(relative_position)
	var fallback_time := sqrt(c) / speed

	if absf(a) < 0.0001:
		if absf(b) < 0.0001:
			return fallback_time
		var linear_time := -c / b
		return linear_time if linear_time > 0.0 else fallback_time

	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return fallback_time
	var root := sqrt(discriminant)
	var first := (-b - root) / (2.0 * a)
	var second := (-b + root) / (2.0 * a)
	var best := INF
	if first > 0.0:
		best = first
	if second > 0.0:
		best = minf(best, second)
	return best if is_finite(best) else fallback_time


static func calculate_intercept_direction(origin: Vector3, target_position: Vector3, target_velocity: Vector3, speed: float) -> Vector3:
	var relative_position := target_position - origin
	if relative_position.length_squared() <= 0.000001:
		return Vector3.ZERO
	var intercept_time := calculate_intercept_time(relative_position, target_velocity, speed)
	return (relative_position + target_velocity * intercept_time).normalized()


func _on_destroyed() -> void:
	state = State.DISABLED
	velocity = Vector3.ZERO
	set_physics_process(false)
