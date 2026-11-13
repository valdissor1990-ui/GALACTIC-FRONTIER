extends SceneTree
## Loads every original GLB through the hangar UI and checks cyclic selection.

const HANGAR_SCENE: PackedScene = preload("res://scenes/ui/fleet_hangar.tscn")
const EXPECTED_NAMES := [
	"PLAYER FIGHTER MK.I",
	"RAIDER INTERCEPTOR",
	"AEGIS HEAVY FIGHTER",
	"BASTION BOMBER",
	"MULE CARGO HAULER",
	"VANGUARD FRIGATE",
	"LEVIATHAN CRUISER"
]

var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hangar := HANGAR_SCENE.instantiate()
	root.add_child(hangar)
	await process_frame
	await process_frame
	_check(hangar.get_ship_count() == EXPECTED_NAMES.size(), "hangar exposes all seven ship classes")
	for index in range(EXPECTED_NAMES.size()):
		_check(hangar.get_current_ship_name() == EXPECTED_NAMES[index], "ship selector order at index %d" % index)
		_check(hangar.get_visible_model_mesh_count() > 0, "GLB model has visible meshes: " + EXPECTED_NAMES[index])
		hangar.show_next_ship()
		await process_frame
		await process_frame
	_check(hangar.get_current_ship_name() == EXPECTED_NAMES[0], "next navigation wraps to the first ship")
	hangar.show_previous_ship()
	await process_frame
	await process_frame
	_check(hangar.get_current_ship_name() == EXPECTED_NAMES[6], "previous navigation wraps to the final ship")
	if _failed == 0:
		print("FLEET_HANGAR_TEST_PASS: 7/7 GLB models rendered; cyclic navigation passed")
		quit(0)
	else:
		print("FLEET_HANGAR_TEST_FAIL: ", _failed, " assertions failed")
		quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("FLEET_HANGAR_TEST_FAIL: " + message)
