extends Node
class_name Damageable
## Reusable shield/hull component. Attach as a child named "Damageable".

signal shield_changed(current: float, maximum: float)
signal hull_changed(current: float, maximum: float)
signal destroyed

@export_range(1.0, 10000.0, 1.0) var max_hull: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_shield: float = 60.0
@export_range(0.0, 500.0, 0.5) var shield_regen_per_second: float = 8.0
@export_range(0.0, 30.0, 0.1) var shield_regen_delay: float = 3.0

var current_hull: float = 100.0
var current_shield: float = 60.0
var _time_since_damage: float = 0.0
var _is_destroyed: bool = false


func _ready() -> void:
	current_hull = max_hull
	current_shield = max_shield
	shield_changed.emit(current_shield, max_shield)
	hull_changed.emit(current_hull, max_hull)


func _process(delta: float) -> void:
	if _is_destroyed:
		return
	_time_since_damage += delta
	if _time_since_damage < shield_regen_delay or current_shield >= max_shield:
		return
	current_shield = minf(max_shield, current_shield + shield_regen_per_second * delta)
	shield_changed.emit(current_shield, max_shield)


func take_damage(amount: float) -> void:
	if _is_destroyed or amount <= 0.0:
		return

	_time_since_damage = 0.0
	var remaining_damage := amount
	if current_shield > 0.0:
		var absorbed := minf(current_shield, remaining_damage)
		current_shield -= absorbed
		remaining_damage -= absorbed
		shield_changed.emit(current_shield, max_shield)

	if remaining_damage > 0.0:
		current_hull = maxf(0.0, current_hull - remaining_damage)
		hull_changed.emit(current_hull, max_hull)

	if current_hull <= 0.0 and not _is_destroyed:
		_is_destroyed = true
		destroyed.emit()


func is_destroyed() -> bool:
	return _is_destroyed


func get_hull_ratio() -> float:
	return current_hull / maxf(max_hull, 0.001)


func get_shield_ratio() -> float:
	return current_shield / maxf(max_shield, 0.001)
