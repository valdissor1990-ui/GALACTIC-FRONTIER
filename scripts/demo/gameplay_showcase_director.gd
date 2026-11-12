extends Node3D
## Deterministic 10-second gameplay demonstration controller.
## Drives the real flight, camera, targeting and weapon systems; it does not fake combat.

@onready var player: ShipController = $Flight/PlayerShip
@onready var targeting: TargetingSystem = $Flight/PlayerShip/TargetingSystem
@onready var camera_rig: CameraRig = $Flight/PlayerShip/CameraRig
@onready var encounter: CombatEncounterController = $Flight/CombatEncounterController


func _ready() -> void:
	print("SHOWCASE_READY")
	call_deferred("_run_showcase")


func _run_showcase() -> void:
	# Give the encounter controller one frame to spawn its real enemy fighter.
	await get_tree().create_timer(0.35).timeout

	# Open with forward thrust and boost toward the hostile contact.
	Input.action_press("move_forward")
	Input.action_press("boost")
	await get_tree().create_timer(0.75).timeout

	var acquired := targeting.acquire_target()
	print("SHOWCASE_TARGET_ACQUIRED=", acquired != null)
	Input.action_press("fire_primary")

	# Sustained energy-weapon exchange while the enemy AI approaches and strafes.
	await get_tree().create_timer(2.25).timeout
	Input.action_release("boost")
	Input.action_release("move_forward")

	# Short evasive yaw maneuver.
	Input.action_press("yaw_right")
	await get_tree().create_timer(0.55).timeout
	Input.action_release("yaw_right")
	await get_tree().create_timer(0.25).timeout

	# Switch to cockpit view, then return to external chase camera.
	camera_rig.toggle_camera()
	await get_tree().create_timer(1.65).timeout
	camera_rig.toggle_camera()

	# Finish with a brief pitch correction and continued weapon fire.
	Input.action_press("pitch_up")
	await get_tree().create_timer(0.45).timeout
	Input.action_release("pitch_up")
	await get_tree().create_timer(1.0).timeout

	Input.action_release("fire_primary")
	Input.action_release("boost")
	Input.action_release("move_forward")
	print("SHOWCASE_SEQUENCE_COMPLETE active_enemy=", encounter.has_active_enemy())
