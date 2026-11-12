extends Control

const FLIGHT_SCENE := "res://scenes/demo/ten_minute_demo.tscn"
const BACKDROP_SCRIPT := preload("res://scripts/ui/menu_backdrop.gd")

var _update_button: Button
var _update_status: Label
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
	if saved_game.ok:
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
	if not saved.ok:
		push_error("Could not load the local mission checkpoint: %s" % saved.get("error", "unknown"))
		return
	var error := get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		push_error("Could not load Silent Relay mission: %s" % error)
		return
	_restore_saved_mission.call_deferred(saved.payload)


func _restore_saved_mission(payload: Dictionary) -> void:
	await get_tree().process_frame
	var current := get_tree().current_scene
	if current == null:
		push_error("Continue failed: mission scene is not active.")
		return
	var director := current.get_node_or_null("DemoMissionDirector")
	if director == null or not director.has_method("restore_from_save"):
		push_error("Continue failed: mission director is unavailable.")
		return
	if not director.call("restore_from_save", payload):
		push_error("Continue failed: checkpoint data was rejected.")


func _open_hangar() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/fleet_hangar.tscn")
	if error != OK:
		push_error("Could not open fleet hangar: %s" % error)
