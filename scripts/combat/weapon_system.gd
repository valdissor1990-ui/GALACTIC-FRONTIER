extends Node3D
class_name WeaponSystem
## Basic energy weapon with a cooldown; one projectile per firing interval.

@export var projectile_scene: PackedScene
@export var muzzle_path: NodePath = NodePath("Muzzle")
@export_range(0.1, 20.0, 0.1) var shots_per_second: float = 3.0
@export_range(1.0, 2000.0, 1.0) var projectile_speed: float = 180.0
@export_range(0.1, 1000.0, 0.1) var projectile_damage: float = 18.0

var _cooldown: float = 0.0
var _ship: Node3D
var _muzzle: Marker3D


func _ready() -> void:
	_ship = get_parent() as Node3D
	_muzzle = get_node_or_null(muzzle_path) as Marker3D
	if _muzzle == null:
		push_error("WeaponSystem requires a Marker3D muzzle at muzzle_path.")
	if projectile_scene == null:
		push_error("WeaponSystem requires a projectile_scene.")


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if not get_tree().paused and Input.is_action_pressed("fire_primary"):
		fire_primary()


func fire_primary() -> bool:
	if _cooldown > 0.0 or projectile_scene == null or _muzzle == null or _ship == null:
		return false

	var projectile := projectile_scene.instantiate() as CombatProjectile
	if projectile == null:
		push_error("WeaponSystem projectile_scene root must use projectile.gd.")
		return false

	var forward := -_muzzle.global_transform.basis.z
	projectile.configure(forward, _ship, projectile_speed, projectile_damage)
	projectile.global_transform = _muzzle.global_transform
	get_tree().current_scene.add_child(projectile)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call("play_3d", audio_manager.get("weapon_asset_stream") if audio_manager.get("weapon_asset_stream") != null else audio_manager.get("weapon_stream"), _muzzle.global_position, -9.0, 24.0, 420.0)
	_cooldown = 1.0 / maxf(shots_per_second, 0.1)
	return true


func rearm() -> void:
	# Energy weapons have no physical ammunition; carrier service resets the
	# capacitor cycle so the next sortie starts with a ready weapon system.
	_cooldown = 0.0
