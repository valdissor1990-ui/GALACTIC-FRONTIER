extends Node
class_name PlayerProfile
## Persistent pilot progression: selected craft, credits and mission rewards.

const PROFILE_SLOT := "pilot_profile"
const STARTING_CREDITS := 2500
const MODULE_CATALOG := {
	"reinforced_hull": {
		"name": "Reinforced Hull", "slot": "HULL", "price": 1800,
		"description": "+18% maximum hull", "stats": {"hull_multiplier": 1.18}
	},
	"shield_capacitor": {
		"name": "Shield Capacitor", "slot": "SHIELD", "price": 1600,
		"description": "+22% shields, +15% shield regeneration",
		"stats": {"shield_multiplier": 1.22, "shield_regen_multiplier": 1.15}
	},
	"weapon_overclock": {
		"name": "Weapon Overclock", "slot": "WEAPON", "price": 2200,
		"description": "+10% fire rate, +12% projectile damage",
		"stats": {"shots_per_second_multiplier": 1.10, "projectile_damage_multiplier": 1.12}
	},
	"boost_injector": {
		"name": "Boost Injector", "slot": "ENGINE", "price": 1700,
		"description": "+25% boost reserve, +18% boost recharge",
		"stats": {"boost_capacity_multiplier": 1.25, "boost_recharge_multiplier": 1.18}
	},
	"ion_thrusters": {
		"name": "Ion Thrusters", "slot": "ENGINE", "price": 2500,
		"description": "+8% top speed, +12% acceleration",
		"stats": {"max_speed_multiplier": 1.08, "acceleration_multiplier": 1.12}
	}
}
const FLYABLE_SHIPS := {
	"player_fighter": {
		"path": "res://assets/models/ships/player_fighter.glb",
		"scale": 0.30,
		"price": 0,
		"flight_config": "res://resources/ships/player_ship.tres",
		"stats": {"hull": 100.0, "shield": 60.0, "shield_regen": 8.0, "shots_per_second": 3.0, "projectile_speed": 180.0, "projectile_damage": 18.0}
	},
	"raider_interceptor": {
		"path": "res://assets/models/ships/enemy_fighter.glb",
		"scale": 0.30,
		"price": 2500,
		"flight_config": "res://resources/ships/raider_interceptor.tres",
		"stats": {"hull": 85.0, "shield": 45.0, "shield_regen": 7.0, "shots_per_second": 3.8, "projectile_speed": 210.0, "projectile_damage": 16.0}
	},
	"aegis_heavy_fighter": {
		"path": "res://assets/models/ships/heavy_fighter.glb",
		"scale": 0.28,
		"price": 5000,
		"flight_config": "res://resources/ships/aegis_heavy_fighter.tres",
		"stats": {"hull": 165.0, "shield": 125.0, "shield_regen": 9.0, "shots_per_second": 2.8, "projectile_speed": 170.0, "projectile_damage": 25.0}
	},
	"bastion_bomber": {
		"path": "res://assets/models/ships/bomber.glb",
		"scale": 0.26,
		"price": 7500,
		"flight_config": "res://resources/ships/bastion_bomber.tres",
		"stats": {"hull": 200.0, "shield": 85.0, "shield_regen": 5.0, "shots_per_second": 1.8, "projectile_speed": 160.0, "projectile_damage": 42.0}
	}
}

var selected_ship_id: String = "player_fighter"
var credits: int = STARTING_CREDITS
var unlocked_ship_ids: Array[String] = ["player_fighter"]
var completed_mission_ids: Array[String] = []
var installed_modules: Dictionary = {}


func _ready() -> void:
	_load_profile()


func _load_profile() -> void:
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		return
	var result: Dictionary = save_manager.call("load_slot", PROFILE_SLOT)
	if not result.get("ok", false):
		_save_profile()
		return
	var payload: Variant = result.get("payload", {})
	if not payload is Dictionary:
		_save_profile()
		return

	credits = maxi(0, int(payload.get("credits", STARTING_CREDITS)))
	unlocked_ship_ids.clear()
	var saved_unlocked: Variant = payload.get("unlocked_ship_ids", ["player_fighter"])
	if saved_unlocked is Array:
		for value in saved_unlocked:
			var ship_id := str(value)
			if FLYABLE_SHIPS.has(ship_id) and not unlocked_ship_ids.has(ship_id):
				unlocked_ship_ids.append(ship_id)
	if not unlocked_ship_ids.has("player_fighter"):
		unlocked_ship_ids.push_front("player_fighter")

	completed_mission_ids.clear()
	var saved_modules: Variant = payload.get("installed_modules", {})
	installed_modules.clear()
	if saved_modules is Dictionary:
		for ship_key in saved_modules.keys():
			var ship_id := str(ship_key)
			if not FLYABLE_SHIPS.has(ship_id) or not (saved_modules[ship_key] is Array):
				continue
			var accepted: Array[String] = []
			var occupied_slots: Array[String] = []
			for module_value in saved_modules[ship_key]:
				var module_id := str(module_value)
				if not MODULE_CATALOG.has(module_id) or accepted.has(module_id):
					continue
				var module_slot := str(MODULE_CATALOG[module_id].slot)
				if occupied_slots.has(module_slot):
					continue
				accepted.append(module_id)
				occupied_slots.append(module_slot)
			installed_modules[ship_id] = accepted
	var saved_missions: Variant = payload.get("completed_mission_ids", [])
	if saved_missions is Array:
		for value in saved_missions:
			var mission_id := str(value)
			if not mission_id.is_empty() and not completed_mission_ids.has(mission_id):
				completed_mission_ids.append(mission_id)

	var saved_id := str(payload.get("selected_ship_id", "player_fighter"))
	selected_ship_id = saved_id if unlocked_ship_ids.has(saved_id) else "player_fighter"


func select_ship(ship_id: String) -> bool:
	if not FLYABLE_SHIPS.has(ship_id) or not unlocked_ship_ids.has(ship_id):
		return false
	selected_ship_id = ship_id
	return _save_profile()


func purchase_ship(ship_id: String) -> bool:
	if not FLYABLE_SHIPS.has(ship_id):
		return false
	if unlocked_ship_ids.has(ship_id):
		return select_ship(ship_id)
	var price := get_ship_price(ship_id)
	if credits < price:
		return false
	credits -= price
	unlocked_ship_ids.append(ship_id)
	selected_ship_id = ship_id
	return _save_profile()


func spend_credits(amount: int) -> bool:
	var cost := maxi(0, amount)
	if credits < cost:
		return false
	if cost == 0:
		return true
	credits -= cost
	if not _save_profile():
		credits += cost
		return false
	return true


func purchase_module(ship_id: String, module_id: String) -> bool:
	if not FLYABLE_SHIPS.has(ship_id) or not unlocked_ship_ids.has(ship_id):
		return false
	if not MODULE_CATALOG.has(module_id) or not is_module_slot_available(ship_id, module_id):
		return false
	var price := int(MODULE_CATALOG[module_id].price)
	if credits < price:
		return false
	var installed := get_installed_modules(ship_id)
	installed.append(module_id)
	installed_modules[ship_id] = installed
	credits -= price
	if not _save_profile():
		credits += price
		installed.erase(module_id)
		if installed.is_empty():
			installed_modules.erase(ship_id)
		else:
			installed_modules[ship_id] = installed
		return false
	return true


func get_module_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for module_id in MODULE_CATALOG.keys():
		var entry: Dictionary = MODULE_CATALOG[module_id].duplicate(true)
		entry["id"] = str(module_id)
		result.append(entry)
	return result


func get_installed_modules(ship_id: String) -> Array[String]:
	var result: Array[String] = []
	var raw: Variant = installed_modules.get(ship_id, [])
	if raw is Array:
		for module_id in raw:
			result.append(str(module_id))
	return result


func is_module_slot_available(ship_id: String, module_id: String) -> bool:
	if not FLYABLE_SHIPS.has(ship_id) or not MODULE_CATALOG.has(module_id):
		return false
	var candidate_slot := str(MODULE_CATALOG[module_id].slot)
	for installed_id in get_installed_modules(ship_id):
		if not MODULE_CATALOG.has(installed_id):
			continue
		if str(MODULE_CATALOG[installed_id].slot) == candidate_slot:
			return false
	return true


func complete_mission(mission_id: String, reward_credits: int) -> int:
	if mission_id.is_empty() or completed_mission_ids.has(mission_id):
		return 0
	var reward := maxi(0, reward_credits)
	completed_mission_ids.append(mission_id)
	credits += reward
	if not _save_profile():
		completed_mission_ids.erase(mission_id)
		credits -= reward
		return 0
	return reward


func is_flyable(ship_id: String) -> bool:
	return FLYABLE_SHIPS.has(ship_id)


func is_ship_unlocked(ship_id: String) -> bool:
	return unlocked_ship_ids.has(ship_id)


func get_ship_price(ship_id: String) -> int:
	if not FLYABLE_SHIPS.has(ship_id):
		return -1
	return int(FLYABLE_SHIPS[ship_id].get("price", 0))


func get_credits() -> int:
	return credits


func get_selected_ship_id() -> String:
	return selected_ship_id


func get_selected_ship_model_path() -> String:
	return str(FLYABLE_SHIPS[selected_ship_id].path)


func get_selected_ship_scale() -> float:
	return float(FLYABLE_SHIPS[selected_ship_id].scale)


func get_selected_ship_flight_config_path() -> String:
	return str(FLYABLE_SHIPS[selected_ship_id].flight_config)


func get_selected_ship_stats() -> Dictionary:
	var stats: Variant = FLYABLE_SHIPS[selected_ship_id].get("stats", {})
	var result: Dictionary = stats.duplicate(true) if stats is Dictionary else {}
	for multiplier_key in [
		"hull_multiplier", "shield_multiplier", "shield_regen_multiplier",
		"shots_per_second_multiplier", "projectile_speed_multiplier",
		"projectile_damage_multiplier", "max_speed_multiplier",
		"acceleration_multiplier", "boost_capacity_multiplier",
		"boost_recharge_multiplier"
	]:
		result[multiplier_key] = 1.0
	for module_id in get_installed_modules(selected_ship_id):
		if not MODULE_CATALOG.has(module_id):
			continue
		var module_stats: Dictionary = MODULE_CATALOG[module_id].get("stats", {})
		for stat_key in module_stats.keys():
			result[stat_key] = float(result.get(stat_key, 1.0)) * float(module_stats[stat_key])
	return result


func _save_profile() -> bool:
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		return false
	var result: Dictionary = save_manager.call("save_slot", PROFILE_SLOT, {
		"profile_version": 3,
		"selected_ship_id": selected_ship_id,
		"credits": credits,
		"unlocked_ship_ids": unlocked_ship_ids,
		"completed_mission_ids": completed_mission_ids,
		"installed_modules": installed_modules
	})
	if not result.get("ok", false):
		push_error("Pilot profile save failed: " + str(result.get("error", "unknown")))
		return false
	return true
