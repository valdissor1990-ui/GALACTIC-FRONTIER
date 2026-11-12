extends Control

const FLIGHT_SCENE := "res://scenes/demo/ten_minute_demo.tscn"
const BACKDROP_SCRIPT := preload("res://scripts/ui/menu_backdrop.gd")

var _update_button: Button
var _update_status: Label
var _rollback_button: Button
var _update_ready := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_menu()
	var updater := get_node_or_null("/root/UpdateManager")
	if updater != null:
		updater.status_changed.connect(_on_update_status)
		updater.update_available.connect(_on_update_available)
		updater.check_for_updates()


func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = Color("#040914")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var backdrop := Control.new()
	backdrop.name = "MenuBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_script(BACKDROP_SCRIPT)
	add_child(backdrop)
	var layout := VBoxContainer.new()
	layout.name = "MainMenuLayout"
	layout.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	layout.position = Vector2(90, -210)
	layout.custom_minimum_size = Vector2(520, 450)
	layout.add_theme_constant_override("separation", 14)
	add_child(layout)
	var eyebrow := Label.new()
	eyebrow.text = "FRONTIER COMMAND  /  SINGLE-PILOT ACCESS"
	eyebrow.add_theme_color_override("font_color", Color("#55c7e6"))
	layout.add_child(eyebrow)
	var title := Label.new()
	title.text = "GALACTIC\nFRONTIER"
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color("#e8f4fb"))
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "THE SILENT RELAY"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#43c2e1"))
	layout.add_child(subtitle)
	var intro := Label.new()
	intro.text = "A remote relay has gone dark.\nYour flight begins at the edge of known space."
	intro.add_theme_color_override("font_color", Color("#9eb8c8"))
	layout.add_child(intro)
	var start := Button.new()
	start.text = "  NEW FLIGHT"
	start.custom_minimum_size = Vector2(390, 54)
	start.pressed.connect(_start_game)
	layout.add_child(start)
	var hangar := Button.new()
	hangar.name = "FleetHangarButton"
	hangar.text = "  FLEET HANGAR"
	hangar.custom_minimum_size = Vector2(390, 48)
	hangar.pressed.connect(_open_hangar)
	layout.add_child(hangar)
	var save_manager := get_node_or_null("/root/GameSave")
	var saved_game: Dictionary = save_manager.call("load_slot", "silent_relay") if save_manager != null else {"ok": false}
	if _is_valid_checkpoint(saved_game):
		var continue_button := Button.new()
		continue_button.text = "  CONTINUE FLIGHT"
		continue_button.custom_minimum_size = Vector2(390, 48)
		continue_button.pressed.connect(_continue_game)
		layout.add_child(continue_button)
	_update_button = Button.new()
	_update_button.name = "CheckUpdatesButton"
	_update_button.text = "  CHECK FOR UPDATES"
	_update_button.custom_minimum_size = Vector2(390, 42)
	_update_button.pressed.connect(_on_update_button_pressed)
	layout.add_child(_update_button)
	_update_status = Label.new()
	_update_status.name = "UpdateStatus"
	_update_status.text = "Версия " + str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	_update_status.add_theme_font_size_override("font_size", 11)
	_update_status.add_theme_color_override("font_color", Color("#7294a8"))
	_update_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_status.custom_minimum_size = Vector2(390, 24)
	layout.add_child(_update_status)
	var updater := get_node_or_null("/root/UpdateManager")
	if updater != null and updater.has_method("has_rollback_backup") and updater.has_rollback_backup():
		_rollback_button = Button.new()
		_rollback_button.name = "RollbackUpdateButton"
		_rollback_button.text = "  ROLL BACK LAST VERSION"
		_rollback_button.custom_minimum_size = Vector2(390, 40)
		_rollback_button.pressed.connect(_confirm_rollback)
		layout.add_child(_rollback_button)
	var controls := Label.new()
	controls.text = "WASD / MOUSE — FLIGHT     LMB — FIRE     T — LOCK\nF — SCAN     C — CAMERA     SHIFT — BOOST     F5 — SAVE     F9 — LOAD"
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color("#7294a8"))
	layout.add_child(controls)
	var quit := Button.new()
	quit.text = "EXIT"
	quit.custom_minimum_size = Vector2(390, 42)
	quit.pressed.connect(func() -> void: get_tree().quit())
	layout.add_child(quit)


func _confirm_rollback() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Restore previous version?"
	dialog.dialog_text = "The current game files will be replaced with the previous version. Your save files will remain unchanged."
	add_child(dialog)
	dialog.confirmed.connect(_perform_rollback)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered()


func _perform_rollback() -> void:
	var updater := get_node_or_null("/root/UpdateManager")
	if updater != null:
		updater.rollback_last_update()


func _on_update_button_pressed() -> void:
	var updater := get_node_or_null("/root/UpdateManager")
	if updater == null:
		_on_update_status("Проверка обновлений недоступна.")
	elif _update_ready:
		updater.download_and_install_update()
	else:
		updater.check_for_updates()


func _on_update_status(message: String) -> void:
	if is_instance_valid(_update_status):
		_update_status.text = message


func _on_update_available(version: String, _notes: String) -> void:
	_update_ready = true
	if is_instance_valid(_update_button):
		_update_button.text = "  DOWNLOAD UPDATE " + version


func _start_game() -> void:
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager != null:
		save_manager.set("pending_mission_payload", {})
		save_manager.call("delete_slot", "silent_relay")
	var error := get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		push_error("Could not load Silent Relay mission: %s" % error)


func _continue_game() -> void:
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager == null:
		push_error("Continue is unavailable: local save manager is missing.")
		return
	var saved: Dictionary = save_manager.call("load_slot", "silent_relay")
	if not _is_valid_checkpoint(saved):
		push_error("Could not load a valid Silent Relay checkpoint.")
		return
	# The autoload survives the scene change; the mission director consumes this
	# payload only after its player, HUD and navigation beacon are initialized.
	save_manager.set("pending_mission_payload", saved.payload)
	var error := get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		save_manager.set("pending_mission_payload", {})
		push_error("Could not load Silent Relay mission: %s" % error)


func _is_valid_checkpoint(saved: Dictionary) -> bool:
	if not bool(saved.get("ok", false)):
		return false
	var payload: Variant = saved.get("payload", {})
	if not payload is Dictionary or str(payload.get("mission_id", "")) != "silent_relay":
		return false
	var stage := int(payload.get("stage", -1))
	return stage >= 0 and stage <= 6


func _open_hangar() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/fleet_hangar.tscn")
	if error != OK:
		push_error("Could not open fleet hangar: %s" % error)
