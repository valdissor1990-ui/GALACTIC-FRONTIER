extends CharacterBody3D
class_name EnemyCombatAI
## Simple combat AI for the Phase 2 enemy fighter.
## States: APPROACH, STRAFE, RETREAT, DISABLED.

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
@export var projectile_scene: PackedScene

var player: Node3D
var state: State = State.APPROACH

var _damageable: Damageable
var _muzzle: Marker3D
var _cooldown: float = 0.0
var _strafe_sign: float = 1.0
var _strafe_timer: float = 0.0


func _ready() -> void:
	add_to_group("combat_targets")
	_damageable = get_node_or_null("Damageable") as Damageable
	_muzzle = get_node_or_null("Muzzle") as Marker3D
	if _damageable != null:
		_damageable.destroyed.connect(_on_destroyed)
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0


func set_player(target: Node3D) -> void:
	player = target


func _physics_process(delta: float) -> void:
	if state == State.DISABLED:
		velocity = Vector3.ZERO
		return
	if player == null or not is_instance_valid(player):
		return

	_cooldown = maxf(0.0, _cooldown - delta)
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
	var desired_dir := Vector3.ZERO

	match state:
		State.APPROACH:
			desired_dir = to_player.normalized()
		State.STRAFE:
			_strafe_timer -= delta
			if _strafe_timer <= 0.0:
				_strafe_sign *= -1.0
				_strafe_timer = randf_range(1.2, 2.4)
			var side := global_transform.basis.x * _strafe_sign
			var hold := to_player.normalized() * clampf((distance - strafe_distance) * 0.15, -1.0, 1.0)
			desired_dir = (side + hold).normalized()
		State.RETREAT:
			desired_dir = -to_player.normalized()
		_:
			desired_dir = Vector3.ZERO

	if desired_dir.length_squared() > 0.0001:
		var target_basis := Basis.looking_at(desired_dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, clampf(turn_rate * delta, 0.0, 1.0)).orthonormalized()
		velocity = velocity.move_toward(desired_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)


func _try_fire() -> void:
	if state == State.DISABLED or state == State.RETREAT:
		return
	if _cooldown > 0.0 or projectile_scene == null or _muzzle == null or player == null:
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance > fire_range:
		return

	var forward := -global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > fire_angle_degrees:
		return

	var projectile := projectile_scene.instantiate() as CombatProjectile
	if projectile == null:
		return
	projectile.configure(forward, self, projectile_speed, projectile_damage)
	projectile.global_transform = _muzzle.global_transform
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(projectile)
	_cooldown = 1.0 / maxf(shots_per_second, 0.1)


func _on_destroyed() -> void:
	state = State.DISABLED
	velocity = Vector3.ZERO
	set_physics_process(false)
