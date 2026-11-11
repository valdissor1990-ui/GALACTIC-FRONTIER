extends Node3D
class_name TargetingSystem
## Acquires the best combat target near the active camera's forward direction.

signal target_changed(target: Node3D)

@export_range(10.0, 10000.0, 10.0) var maximum_range: float = 1800.0
@export_range(1.0, 45.0, 0.5) var acquisition_cone_degrees: float = 12.0

var current_target: Node3D
var _ship: Node3D


func _ready() -> void:
	_ship = get_parent() as Node3D


func _process(_delta: float) -> void:
	if current_target != null:
		if not is_instance_valid(current_target) or not current_target.is_inside_tree():
			set_target(null)
		elif _ship != null and _ship.global_position.distance_to(current_target.global_position) > maximum_range:
			set_target(null)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("target_lock"):
		acquire_target()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("target_clear"):
		set_target(null)
		get_viewport().set_input_as_handled()


func acquire_target() -> Node3D:
	var camera := get_viewport().get_camera_3d()
	if camera == null or _ship == null:
		set_target(null)
		return null

	var forward := -camera.global_transform.basis.z.normalized()
	var minimum_dot := cos(deg_to_rad(acquisition_cone_degrees))
	var best_score := INF
	var best_target: Node3D

	for candidate in get_tree().get_nodes_in_group("combat_targets"):
		if not candidate is Node3D:
			continue
		var target := candidate as Node3D
		if target == _ship or not target.is_inside_tree():
			continue
		var offset := target.global_position - camera.global_position
		var distance := offset.length()
		if distance <= 0.01 or distance > maximum_range:
			continue
		var alignment := forward.dot(offset / distance)
		if alignment < minimum_dot:
			continue

		# Favor targets close to the reticle, with a small preference for nearer ones.
		var score := (1.0 - alignment) + (distance / maximum_range) * 0.08
		if score < best_score:
			best_score = score
			best_target = target

	set_target(best_target)
	return current_target


func set_target(target: Node3D) -> void:
	if current_target == target:
		return
	current_target = target
	target_changed.emit(current_target)


func get_target_name() -> String:
	if current_target == null or not is_instance_valid(current_target):
		return "NO TARGET"
	return current_target.name
