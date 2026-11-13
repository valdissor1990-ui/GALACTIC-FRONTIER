extends SceneTree
## Verifies persistent hangar selection drives the actual player GLB in flight.
## Run: godot --headless --path . --script res://tests/ui/test_player_ship_selection.gd -- --test-mode

const HANGAR_SCENE := "res://scenes/ui/fleet_hangar.tscn"
const FLIGHT_SCENE := "res://scenes/flight/visual_flight.tscn"
const PROFILE_TEST_DIRECTORY := "user://test_player_ship_selection"

var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager := root.get_node_or_null("GameSave")
	var profile := root.get_node_or_null("GameProfile")
	_check(save_manager != null, "GameSave autoload is available")
	_check(profile != null, "GameProfile autoload is available")
	if save_manager == null or profile == null:
		quit(1)
		return

	save_manager.set("save_directory", PROFILE_TEST_DIRECTORY)
	save_manager.call("delete_slot", "pilot_profile")
	profile.set("selected_ship_id", "player_fighter")
	profile.set("credits", 2500)
	profile.set("unlocked_ship_ids", ["player_fighter"])
	profile.set("completed_mission_ids", [])
	_check(bool(profile.call("_save_profile")), "starter pilot profile is initialized with 2500 credits")
	_check(int(profile.call("get_credits")) == 2500, "starting credit balance is available")

	var hangar := (load(HANGAR_SCENE) as PackedScene).instantiate()
	root.add_child(hangar)
	await process_frame
	await process_frame
	await process_frame
	var select_button := hangar.get_node_or_null("HangarOverlay/SelectShipButton") as Button
	_check(select_button != null, "hangar exposes a Select for Next Flight button")
	_check(select_button != null and not select_button.disabled, "starter fighter is selectable")
	hangar.call("show_next_ship")
	await process_frame
	await process_frame
	hangar.call("_select_current_ship")
	_check(str(profile.call("get_selected_ship_id")) == "raider_interceptor", "buying the interceptor also selects it")
	_check(int(profile.call("get_credits")) == 0, "interceptor purchase deducts its 2500-credit price")
	var mission_reward := int(profile.call("complete_mission", "silent_relay", 5000))
	_check(mission_reward == 5000 and int(profile.call("get_credits")) == 5000, "mission completion grants 5000 credits")
	_check(int(profile.call("complete_mission", "silent_relay", 5000)) == 0, "mission reward cannot be claimed twice")
	hangar.call("show_next_ship")
	await process_frame
	await process_frame
	hangar.call("_select_current_ship")
	_check(str(profile.call("get_selected_ship_id")) == "aegis_heavy_fighter", "purchased heavy fighter becomes the active ship")
	_check(int(profile.call("get_credits")) == 0, "heavy fighter purchase deducts its 5000-credit price")
	hangar.call("show_next_ship")
	await process_frame
	await process_frame
	var locked_bomber_button := hangar.get_node_or_null("HangarOverlay/SelectShipButton") as Button
	_check(locked_bomber_button != null and locked_bomber_button.disabled, "bomber purchase is disabled without sufficient credits")

	hangar.queue_free()
	await process_frame
	var flight := (load(FLIGHT_SCENE) as PackedScene).instantiate()
	root.add_child(flight)
	for _frame in range(5):
		await process_frame
	var model_loader := flight.get_node_or_null("PlayerShip/Visual/PlayerFighterModel")
	_check(model_loader != null, "player ship model loader exists in the flight scene")
	if model_loader != null:
		_check(str(model_loader.get("source_path")) == "res://assets/models/ships/heavy_fighter.glb", "flight scene uses the selected heavy fighter GLB")
		var model := model_loader.get_node_or_null("Model")
		_check(model != null and _count_meshes(model) > 0, "selected heavy fighter model is rendered in flight")

	var player_ship := flight.get_node_or_null("PlayerShip") as ShipController
	_check(player_ship != null and is_equal_approx(player_ship.flight_config.max_speed, 80.0), "heavy fighter loads its slower flight profile")
	if player_ship != null:
		var damageable := player_ship.get_node("Damageable") as Damageable
		var weapon := player_ship.get_node("WeaponSystem") as WeaponSystem
		_check(is_equal_approx(damageable.max_hull, 165.0), "heavy fighter receives its higher hull rating")
		_check(is_equal_approx(damageable.max_shield, 125.0), "heavy fighter receives its stronger shields")
		_check(is_equal_approx(weapon.projectile_damage, 25.0), "heavy fighter receives its heavier weapon damage")
		_check(is_equal_approx(weapon.shots_per_second, 2.8), "heavy fighter receives its slower weapon cadence")

	flight.queue_free()
	await process_frame
	profile.set("selected_ship_id", "player_fighter")
	profile.set("credits", 2500)
	profile.set("unlocked_ship_ids", ["player_fighter"])
	profile.set("completed_mission_ids", [])
	profile.call("_save_profile")
	save_manager.call("delete_slot", "pilot_profile")
	save_manager.set("save_directory", "user://saves")
	if _failed == 0:
		print("PLAYER_SHIP_SELECTION_PASS")
		quit(0)
	else:
		print("PLAYER_SHIP_SELECTION_FAIL assertions=", _failed)
		quit(1)


func _count_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("PLAYER_SHIP_SELECTION_FAIL: " + message)
