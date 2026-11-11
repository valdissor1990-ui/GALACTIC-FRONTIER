extends Node3D
class_name CameraRig
## Camera switching never changes the ship's transform or velocity.

@onready var chase_camera: Camera3D = $ChaseCamera
@onready var cockpit_camera: Camera3D = $CockpitCamera
@onready var ship_visual: Node3D = $"../Visual"

var _cockpit_active: bool = false


func _ready() -> void:
	_apply_camera_mode()


func toggle_camera() -> void:
	_cockpit_active = not _cockpit_active
	_apply_camera_mode()


func is_cockpit_active() -> bool:
	return _cockpit_active


func _apply_camera_mode() -> void:
	if not is_node_ready():
		return

	chase_camera.current = not _cockpit_active
	cockpit_camera.current = _cockpit_active
	# Hide the placeholder hull from inside the cockpit camera.
	ship_visual.visible = not _cockpit_active
