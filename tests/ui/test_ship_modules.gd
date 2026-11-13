extends SceneTree

const FLIGHT_SCENE: PackedScene = preload("res://scenes/flight/test_flight.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := root.get_node("GameProfile") as PlayerProfile
	var backup := {
		"credits": profile.credits,
		"selected_ship_id": profile.selected_ship_id,
		"unlocked_ship_ids": profile.unlocked_ship_ids.duplicate(),
		"completed_mission_ids": profile.completed_mission_ids.duplicate(),
		"installed_modules": profile.installed_modules.duplicate(true)
	}
	profile.credits = 10000
	profile.selected_ship_id = "player_fighter"
	profile.unlocked_ship_ids.clear()
	profile.unlocked_ship_ids.append("player_fighter")
	profile.unlocked_ship_ids.append("raider_interceptor")
	profile.completed_mission_ids.clear()
	profile.installed_modules.clear()
	profile.call("_save_profile")

	var flight := FLIGHT_SCENE.instantiate()
	root.add_child(flight)
	await process_frame
	var player := flight.get_node("PlayerShip") as ShipController
	var damageable := player.get_node("Damageable") as Damageable
	var weapon := player.get_node("WeaponSystem") as WeaponSystem

	_check(profile.purchase_module("player_fighter", "reinforced_hull"), "reinforced hull module can be purchased")
	_check(profile.purchase_module("player_fighter", "shield_capacitor"), "shield capacitor module can be purchased")
	_check(profile.purchase_module("player_fighter", "weapon_overclock"), "weapon overclock module can be purchased")
	_check(profile.purchase_module("player_fighter", "boost_injector"), "boost injector module can be purchased")
	_check(not profile.purchase_module("player_fighter", "ion_thrusters"), "only one module can occupy the engine slot")
	player.refresh_profile_upgrades()

	_check(is_equal_approx(damageable.max_hull, 118.0), "reinforced hull increases maximum hull by 18 percent")
	_check(is_equal_approx(damageable.max_shield, 73.2), "shield capacitor increases maximum shields by 22 percent")
	_check(is_equal_approx(damageable.shield_regen_per_second, 9.2), "shield capacitor increases shield regeneration")
	_check(is_equal_approx(weapon.shots_per_second, 3.3), "weapon overclock increases fire rate")
	_check(is_equal_approx(weapon.projectile_damage, 20.16), "weapon overclock increases projectile damage")
	_check(is_equal_approx(player.flight_config.boost_capacity, 12.5), "boost injector increases boost capacity")
	_check(is_equal_approx(player.flight_config.boost_recharge_rate, 2.36), "boost injector increases recharge rate")
	_check(profile.get_installed_modules("player_fighter").size() == 4, "installed modules persist on the selected ship")

	profile.credits = 0
	_check(not profile.purchase_module("raider_interceptor", "ion_thrusters"), "module purchase is rejected when credits are insufficient")
	_check(profile.get_module_catalog().size() == 5, "five upgrade modules are available in the catalog")

	profile.credits = int(backup["credits"])
	profile.selected_ship_id = str(backup["selected_ship_id"])
	profile.unlocked_ship_ids.clear()
	for ship_id in backup["unlocked_ship_ids"]:
		profile.unlocked_ship_ids.append(str(ship_id))
	profile.completed_mission_ids.clear()
	for mission_id in backup["completed_mission_ids"]:
		profile.completed_mission_ids.append(str(mission_id))
	profile.installed_modules = backup["installed_modules"].duplicate(true)
	profile.call("_save_profile")
	flight.queue_free()
	await process_frame

	if _failures.is_empty():
		print("SHIP_MODULES_TEST_PASS assertions=13")
		quit(0)
	else:
		for failure in _failures:
			push_error("SHIP_MODULES_TEST_FAIL: " + failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
