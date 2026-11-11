extends CanvasLayer
## Minimal telemetry HUD and pause handling for Phase 1.

@export var ship_path: NodePath

@onready var speed_label: Label = $Telemetry/Panel/Margin/VBox/SpeedLabel
@onready var mode_label: Label = $Telemetry/Panel/Margin/VBox/ModeLabel
@onready var boost_label: Label = $Telemetry/Panel/Margin/VBox/BoostLabel
@onready var sensitivity_label: Label = $Telemetry/Panel/Margin/VBox/SensitivityLabel
@onready var pause_panel: Control = $PausePanel

var _ship: ShipController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ship = get_node_or_null(ship_path) as ShipController
	if _ship == null:
		push_error("HUD could not find the PlayerShip node.")
	pause_panel.visible = false


func _process(_delta: float) -> void:
	if _ship == null:
		return

	speed_label.text = "SPEED  %06.1f m/s" % _ship.velocity.length()
	mode_label.text = "CAMERA  %s" % ("COCKPIT" if _ship.is_cockpit_camera_active() else "CHASE")

	if _ship.flight_config == null:
		boost_label.text = "BOOST  --"
	else:
		var capacity: float = maxf(_ship.flight_config.boost_capacity, 0.001)
		boost_label.text = "BOOST  %03.0f%%" % (100.0 * _ship.boost_amount / capacity)

	sensitivity_label.text = "MOUSE  %0.2f   ([ / ] to adjust)" % _ship.mouse_sensitivity


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused and event.is_action_pressed("sensitivity_down") and _ship != null:
		_ship.set_mouse_sensitivity(_ship.mouse_sensitivity - 0.01)
	elif not get_tree().paused and event.is_action_pressed("sensitivity_up") and _ship != null:
		_ship.set_mouse_sensitivity(_ship.mouse_sensitivity + 0.01)


func _toggle_pause() -> void:
	var should_pause: bool = not get_tree().paused
	get_tree().paused = should_pause
	pause_panel.visible = should_pause
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if should_pause else Input.MOUSE_MODE_CAPTURED
