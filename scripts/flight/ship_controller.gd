extends CharacterBody3D
class_name ShipController
## Player ship controller for the Phase 1 flight prototype.
## Keyboard rotation has angular inertia; mouse look is an immediate view adjustment.

const MAX_MOUSE_DELTA_PER_PHYSICS_TICK: float = 250.0

@export var flight_config: ShipFlightConfig
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12

@onready var camera_rig: CameraRig = $CameraRig

var _flight_model: FlightModel = FlightModel.new()
var _angular_velocity: Vector3 = Vector3.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var boost_amount: float = 10.0
var _is_destroyed: bool = false


func _ready() -> void:
	_apply_profile_configuration()
	if flight_config == null:
		push_error("ShipFlightConfig is not assigned to PlayerShip.")
		return

	boost_amount = flight_config.boost_capacity
	var damageable := get_node_or_null("Damageable") as Damageable
	if damageable != null:
		damageable.destroyed.connect(_on_destroyed, CONNECT_ONE_SHOT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_profile_configuration() -> void:
	var profile := get_node_or_null("/root/GameProfile")
	if profile == null:
		return

	var config_path := str(profile.call("get_selected_ship_flight_config_path"))
	if not config_path.is_empty():
		var selected_config := load(config_path) as ShipFlightConfig
		if selected_config != null:
			flight_config = selected_config
		else:
			push_error("Selected ship flight config could not be loaded: " + config_path)

	var ship_stats: Dictionary = profile.call("get_selected_ship_stats")
	var damageable := get_node_or_null("Damageable") as Damageable
	if damageable != null and not ship_stats.is_empty():
		damageable.max_hull = float(ship_stats.get("hull", damageable.max_hull))
		damageable.max_shield = float(ship_stats.get("shield", damageable.max_shield))
		damageable.shield_regen_per_second = float(ship_stats.get("shield_regen", damageable.shield_regen_per_second))
		damageable.current_hull = damageable.max_hull
		damageable.current_shield = damageable.max_shield
		damageable.hull_changed.emit(damageable.current_hull, damageable.max_hull)
		damageable.shield_changed.emit(damageable.current_shield, damageable.max_shield)

	var weapon := get_node_or_null("WeaponSystem") as WeaponSystem
	if weapon != null and not ship_stats.is_empty():
		weapon.shots_per_second = float(ship_stats.get("shots_per_second", weapon.shots_per_second))
		weapon.projectile_speed = float(ship_stats.get("projectile_speed", weapon.projectile_speed))
		weapon.projectile_damage = float(ship_stats.get("projectile_damage", weapon.projectile_damage))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_mouse_delta = Vector2.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and not get_tree().paused:
		_mouse_delta = Vector2.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _is_destroyed:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Bound accumulated input so a delayed physics tick cannot cause a large snap.
		_mouse_delta = (_mouse_delta + event.relative).limit_length(
			MAX_MOUSE_DELTA_PER_PHYSICS_TICK
		)

	if event.is_action_pressed("toggle_camera"):
		camera_rig.toggle_camera()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _is_destroyed:
		velocity = Vector3.ZERO
		return
	if flight_config == null:
		_mouse_delta = Vector2.ZERO
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
		boost_amount = minf(
			flight_config.boost_capacity,
			boost_amount + flight_config.boost_recharge_rate * delta
		)

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

	# Keyboard rotation is rate-based and accelerates/decelerates smoothly.
	rotate_object_local(Vector3.RIGHT, _angular_velocity.x * delta)
	rotate_object_local(Vector3.UP, _angular_velocity.y * delta)
	rotate_object_local(Vector3.BACK, _angular_velocity.z * delta)

	# Mouse look is intentionally immediate (not added to keyboard angular inertia).
	# The accumulated pixel delta is bounded and consumed exactly once per physics tick.
	if _mouse_delta.length_squared() > 0.0:
		var mouse_scale: float = mouse_sensitivity * 0.002
		rotate_object_local(Vector3.UP, -_mouse_delta.x * mouse_scale)
		rotate_object_local(Vector3.RIGHT, -_mouse_delta.y * mouse_scale)
		_mouse_delta = Vector2.ZERO

	# Release damping applies after keyboard rotation input is released.
	if desired_angular_velocity == Vector3.ZERO:
		_angular_velocity = _angular_velocity.move_toward(
			Vector3.ZERO,
			flight_config.rotation_stabilization * delta
		)


func _on_destroyed() -> void:
	_is_destroyed = true
	velocity = Vector3.ZERO
	_angular_velocity = Vector3.ZERO
	_mouse_delta = Vector2.ZERO
	set_physics_process(false)
	set_process_unhandled_input(false)
	var weapon := get_node_or_null("WeaponSystem")
	if weapon != null:
		weapon.set_process(false)
		weapon.set_physics_process(false)
	print("PLAYER_SHIP_DESTROYED: flight controls and weapons disabled")


func is_destroyed() -> bool:
	return _is_destroyed


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.02, 0.5)


func is_cockpit_camera_active() -> bool:
	return camera_rig.is_cockpit_active()
