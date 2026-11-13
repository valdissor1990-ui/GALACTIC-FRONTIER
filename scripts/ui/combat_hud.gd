extends CanvasLayer
## Compact combat telemetry for target lock, shields and hull integrity.

@export var targeting_system_path: NodePath
@export var damageable_path: NodePath

@onready var target_label: Label = $CombatPanel/Margin/VBox/TargetLabel
@onready var target_status_label: Label = $CombatPanel/Margin/VBox/TargetStatusLabel
@onready var shield_label: Label = $CombatPanel/Margin/VBox/ShieldLabel
@onready var hull_label: Label = $CombatPanel/Margin/VBox/HullLabel

var _targeting: TargetingSystem
var _player_damageable: Damageable


func _ready() -> void:
	_targeting = get_node_or_null(targeting_system_path) as TargetingSystem
	_player_damageable = get_node_or_null(damageable_path) as Damageable
	if _targeting == null:
		push_error("CombatHUD could not resolve TargetingSystem.")
	if _player_damageable == null:
		push_error("CombatHUD could not resolve player Damageable component.")


func _process(_delta: float) -> void:
	if _targeting != null:
		var target := _targeting.current_target
		target_label.text = "TARGET  %s" % _targeting.get_target_name()
		if target == null or not is_instance_valid(target):
			target_status_label.text = "STATUS  —"
		else:
			var target_damageable := _find_damageable(target)
			if target_damageable != null:
				target_status_label.text = "SHIELD  %d%%   HULL  %d%%" % [
					roundi(target_damageable.call("get_shield_ratio") * 100.0),
					roundi(target_damageable.call("get_hull_ratio") * 100.0)
				]
			else:
				target_status_label.text = "STATUS  LOCKED"

	if _player_damageable != null:
		shield_label.text = "SHIELDS  %03.0f%%" % (_player_damageable.get_shield_ratio() * 100.0)
		hull_label.text = "HULL  %03.0f%%" % (_player_damageable.get_hull_ratio() * 100.0)


func _find_damageable(target: Node) -> Node:
	var component := target.get_node_or_null("Damageable")
	if component != null and component.has_method("get_hull_ratio") and component.has_method("get_shield_ratio"):
		return component
	if target.has_method("get_hull_ratio") and target.has_method("get_shield_ratio"):
		return target
	return null
