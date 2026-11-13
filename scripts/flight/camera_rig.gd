extends Node3D
class_name CameraRig
## Camera switching never changes the ship's transform or velocity.

@onready var chase_camera: Camera3D = $ChaseCamera
@onready var cockpit_camera: Camera3D = $CockpitCamera
@onready var ship_visual: Node3D = get_parent().get_node_or_null("Visual") as Node3D
@onready var cockpit_interior: Node3D = get_parent().get_node_or_null("CockpitInterior") as Node3D

var _cockpit_active: bool = false


func _ready() -> void:
	if ship_visual == null:
		push_warning(
			"CameraRig expected a Node3D named 'Visual' under its parent ship. "
			+ "The camera can still switch, but the placeholder hull cannot be hidden."
		)
	if cockpit_interior != null:
		cockpit_interior.visible = false
	_apply_camera_mode()


func toggle_camera() -> void:
	_cockpit_active = not _cockpit_active
	_apply_camera_mode()


func is_cockpit_active() -> bool:
	return _cockpit_active


func _apply_camera_mode() -> void:
	chase_camera.current = not _cockpit_active
	cockpit_camera.current = _cockpit_active

	if ship_visual != null:
		ship_visual.visible = not _cockpit_active
	if cockpit_interior != null:
		cockpit_interior.visible = _cockpit_active
