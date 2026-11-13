extends Node3D
class_name SectorDetailStreamer
## Lightweight stand-in for SC object-container streaming.
## Activates registered POI roots when the tracked node is inside radius.
## Does not stream disk assets — toggles already-built Node3D children.

@export var track_path: NodePath
@export var check_interval: float = 0.35

var _track: Node3D
var _entries: Array[Dictionary] = []
var _timer: float = 0.0


func _ready() -> void:
	if track_path != NodePath(""):
		_track = get_node_or_null(track_path) as Node3D
	call_deferred("_collect_marked")


func register_poi(node: Node3D, radius: float = 180.0, hysteresis: float = 30.0) -> void:
	if node == null:
		return
	_entries.append({
		"node": node,
		"radius": radius,
		"hysteresis": hysteresis,
		"active": node.visible,
	})


func _collect_marked() -> void:
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	_walk(root)
	_update_streaming(true)


func _walk(n: Node) -> void:
	if n is Node3D and n.has_meta("sector_poi"):
		var r := 180.0
		if n.has_meta("sector_radius"):
			r = float(n.get_meta("sector_radius"))
		register_poi(n as Node3D, r)
	for c in n.get_children():
		_walk(c)


func _process(delta: float) -> void:
	_timer += delta
	if _timer < check_interval:
		return
	_timer = 0.0
	if _track == null or not is_instance_valid(_track):
		if track_path != NodePath(""):
			_track = get_node_or_null(track_path) as Node3D
		if _track == null:
			var cam := get_viewport().get_camera_3d()
			if cam:
				_track = cam
	_update_streaming(false)


func _update_streaming(force: bool) -> void:
	if _track == null:
		return
	var origin := _track.global_position
	for e in _entries:
		var node: Node3D = e["node"]
		if node == null or not is_instance_valid(node):
			continue
		var dist := origin.distance_to(node.global_position)
		var r: float = e["radius"]
		var h: float = e["hysteresis"]
		var want := dist < r if not e["active"] else dist < r + h
		if force or want != e["active"]:
			e["active"] = want
			node.visible = want
			node.set_process(want)
			node.set_physics_process(want)
