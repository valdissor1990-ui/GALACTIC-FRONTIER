extends Node
class_name PlayerProfile
## Persistent pilot progression: selected craft, credits and mission rewards.

const PROFILE_SLOT := "pilot_profile"
const STARTING_CREDITS := 2500
const FLYABLE_SHIPS := {
	"player_fighter": {
		"path": "res://assets/models/ships/player_fighter.glb",
		"scale": 0.30,
		"price": 0
	},
	"raider_interceptor": {
		"path": "res://assets/models/ships/enemy_fighter.glb",
		"scale": 0.30,
		"price": 2500
	},
	"aegis_heavy_fighter": {
		"path": "res://assets/models/ships/heavy_fighter.glb",
		"scale": 0.28,
		"price": 5000
	},
	"bastion_bomber": {
		"path": "res://assets/models/ships/bomber.glb",
		"scale": 0.26,
		"price": 7500
	}
}

var selected_ship_id: String = "player_fighter"
var credits: int = STARTING_CREDITS
var unlocked_ship_ids: Array[String] = ["player_fighter"]
var completed_mission_ids: Array[String] = []


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


func _save_profile() -> bool:
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		return false
	var result: Dictionary = save_manager.call("save_slot", PROFILE_SLOT, {
		"profile_version": 2,
		"selected_ship_id": selected_ship_id,
		"credits": credits,
		"unlocked_ship_ids": unlocked_ship_ids,
		"completed_mission_ids": completed_mission_ids
	})
	if not result.get("ok", false):
		push_error("Pilot profile save failed: " + str(result.get("error", "unknown")))
		return false
	return true
