extends CharacterBody3D
class_name ShipController
## Player ship controller for the Phase 1 flight prototype.
## Movement is manually integrated so the ship remains controllable and tunable.

@export var flight_config: ShipFlightConfig
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12

@onready var camera_rig: CameraRig = $CameraRig
@onready var ship_visual: Node3D = $Visual

var _flight_model: FlightModel = FlightModel.new()
var _angular_velocity: Vector3 = Vector3.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var boost_amount: float = 10.0


func _ready() -> void:
	if flight_config == null:
		push_error("ShipFlightConfig is not assigned to PlayerShip.")
		return

	boost_amount = flight_config.boost_capacity
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += event.relative

	if event.is_action_pressed("toggle_camera"):
		camera_rig.toggle_camera()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if flight_config == null:
		return

	_update_translation(delta)
	_update_rotation(delta)
	move_and_slide()


func _update_translation(delta: float) -> void:
	var strafe: float = Input.get_axis("move_left", "move_right")
	var vertical: float = Input.get_axis("move_down", "move_up")
	var thrust: float = Input.get_axis("move_backward", "move_forward")
	var local_direction := Vector3(strafe, vertical, -thrust)
	var world_direction: Vector3 = global_transform.basis * local_direction

	var boosting: bool = Input.is_action_pressed("boost") and boost_amount > 0.0
	if boosting:
		boost_amount = maxf(0.0, boost_amount - delta)
	else:
		boost_amount = minf(flight_config.boost_capacity, boost_amount + flight_config.boost_recharge_rate * delta)

	var acceleration_multiplier: float = flight_config.boost_acceleration_multiplier if boosting else 1.0
	var speed_multiplier: float = flight_config.boost_speed_multiplier if boosting else 1.0
	var drag_value: float = flight_config.brake_drag if Input.is_action_pressed("brake") else flight_config.drag

	velocity = _flight_model.integrate_velocity(
		velocity,
		world_direction,
		flight_config.acceleration * acceleration_multiplier,
		flight_config.max_speed * speed_multiplier,
		drag_value,
		delta
	)


func _update_rotation(delta: float) -> void:
	var pitch: float = Input.get_axis("pitch_down", "pitch_up")
	var yaw: float = Input.get_axis("yaw_left", "yaw_right")
	var roll: float = Input.get_axis("roll_left", "roll_right")
	var desired_angular_velocity := Vector3(pitch, yaw, roll) * flight_config.rotation_speed

	_angular_velocity = _angular_velocity.move_toward(
		desired_angular_velocity,
		flight_config.rotation_acceleration * delta
	)

	rotate_object_local(Vector3.RIGHT, _angular_velocity.x * delta)
	rotate_object_local(Vector3.UP, _angular_velocity.y * delta)
	rotate_object_local(Vector3.BACK, _angular_velocity.z * delta)

	if _mouse_delta.length_squared() > 0.0:
		var mouse_scale: float = mouse_sensitivity * 0.002
		rotate_object_local(Vector3.UP, -_mouse_delta.x * mouse_scale)
		rotate_object_local(Vector3.RIGHT, -_mouse_delta.y * mouse_scale)
		_mouse_delta = Vector2.ZERO

	# Passive angular damping is the flight stabilizer.
	_angular_velocity = _angular_velocity.move_toward(
		Vector3.ZERO if desired_angular_velocity == Vector3.ZERO else desired_angular_velocity,
		flight_config.rotation_stabilization * delta if desired_angular_velocity == Vector3.ZERO else 0.0
	)


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.02, 0.5)


func is_cockpit_camera_active() -> bool:
	return camera_rig.is_cockpit_active()
