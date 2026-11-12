extends Node
class_name PlayerProfile
## Persistent pilot preferences shared by the hangar and the flight scene.

const PROFILE_SLOT := "pilot_profile"
const FLYABLE_SHIPS := {
	"player_fighter": {
		"path": "res://assets/models/ships/player_fighter.glb",
		"scale": 0.30
	},
	"raider_interceptor": {
		"path": "res://assets/models/ships/enemy_fighter.glb",
		"scale": 0.30
	},
	"aegis_heavy_fighter": {
		"path": "res://assets/models/ships/heavy_fighter.glb",
		"scale": 0.28
	},
	"bastion_bomber": {
		"path": "res://assets/models/ships/bomber.glb",
		"scale": 0.26
	}
}

var selected_ship_id: String = "player_fighter"


func _ready() -> void:
	_load_profile()


func _load_profile() -> void:
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		return
	var result: Dictionary = save_manager.call("load_slot", PROFILE_SLOT)
	if result.get("ok", false):
		var payload: Variant = result.get("payload", {})
		if payload is Dictionary:
			var saved_id := str(payload.get("selected_ship_id", "player_fighter"))
			if FLYABLE_SHIPS.has(saved_id):
				selected_ship_id = saved_id
				return
	_save_profile()


func select_ship(ship_id: String) -> bool:
	if not FLYABLE_SHIPS.has(ship_id):
		return false
	selected_ship_id = ship_id
	return _save_profile()


func is_flyable(ship_id: String) -> bool:
	return FLYABLE_SHIPS.has(ship_id)


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
		"profile_version": 1,
		"selected_ship_id": selected_ship_id
	})
	if not result.get("ok", false):
		push_error("Pilot profile save failed: " + str(result.get("error", "unknown")))
		return false
	return true
