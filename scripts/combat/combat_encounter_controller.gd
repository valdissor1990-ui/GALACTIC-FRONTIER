extends Node
class_name CombatEncounterController
## Spawns a single enemy fighter, waits for its destruction, then respawns after a delay.

@export var enemy_scene: PackedScene
@export var auto_start: bool = true
@export var player_path: NodePath
@export var spawn_position: Vector3 = Vector3(0.0, 0.0, -80.0)
@export_range(0.5, 60.0, 0.5) var respawn_delay: float = 4.0

var _player: Node3D
var _current_enemy: Node3D
var _respawn_timer: float = -1.0
var _encounter_active: bool = false


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	if enemy_scene == null:
		push_error("CombatEncounterController requires enemy_scene.")
		return
	if _player == null:
		push_error("CombatEncounterController could not resolve player_path.")
		return
	if auto_start:
		call_deferred("start_encounter")


func _process(delta: float) -> void:
	if _respawn_timer < 0.0:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_respawn_timer = -1.0
		_spawn_enemy()


func start_encounter() -> void:
	if _encounter_active:
		return
	_encounter_active = true
	_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_scene == null or _player == null:
		return
	if is_instance_valid(_current_enemy):
		return

	var enemy := enemy_scene.instantiate() as Node3D
	if enemy == null:
		push_error("CombatEncounterController: enemy_scene root must be Node3D.")
		return

	get_parent().add_child(enemy)
	enemy.global_position = spawn_position
	if enemy.has_method("set_player"):
		enemy.call("set_player", _player)

	var damageable := enemy.get_node_or_null("Damageable")
	if damageable != null and damageable.has_signal("destroyed"):
		damageable.connect("destroyed", _on_enemy_destroyed)

	_current_enemy = enemy


func _on_enemy_destroyed() -> void:
	# Allow the destroyed node to finish its frame, then free and schedule respawn.
	if is_instance_valid(_current_enemy):
		_current_enemy.queue_free()
	_current_enemy = null
	_respawn_timer = respawn_delay


func has_active_enemy() -> bool:
	return is_instance_valid(_current_enemy)


func get_respawn_timer() -> float:
	return _respawn_timer
