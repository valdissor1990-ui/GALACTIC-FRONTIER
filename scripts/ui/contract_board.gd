extends Control
## Data-driven star map and contract selection screen.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MISSION_SCENE := "res://scenes/demo/ten_minute_demo.tscn"

var _profile: PlayerProfile
var _cards: HBoxContainer
var _status_label: Label


func _ready() -> void:
	_profile = get_node_or_null("/root/GameProfile") as PlayerProfile
	_build_ui()
	_refresh_contracts()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.004, 0.012, 0.028)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 38)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title_column := VBoxContainer.new()
	header.add_child(title_column)
	var title := Label.new()
	title.text = "GALACTIC FRONTIER  /  STAR MAP"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.48, 0.91, 1.0))
	title_column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "CONTRACT NETWORK  •  SELECT A SYSTEM AND DEPLOYMENT"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.52, 0.68, 0.78))
	title_column.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var back := Button.new()
	back.text = "BACK TO MAIN MENU"
	back.custom_minimum_size = Vector2(220, 48)
	back.pressed.connect(_back_to_menu)
	header.add_child(back)

	var system_strip := HBoxContainer.new()
	system_strip.add_theme_constant_override("separation", 12)
	column.add_child(system_strip)
	if _profile != null:
		for system in _profile.get_system_catalog():
			var system_panel := PanelContainer.new()
			system_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var system_style := StyleBoxFlat.new()
			system_style.bg_color = Color(0.02, 0.055, 0.085, 0.9)
			system_style.border_color = Color(0.10, 0.38, 0.52, 0.8)
			system_style.set_border_width_all(1)
			system_style.set_corner_radius_all(6)
			system_style.content_margin_left = 14
			system_style.content_margin_right = 14
			system_style.content_margin_top = 10
			system_style.content_margin_bottom = 10
			system_panel.add_theme_stylebox_override("panel", system_style)
			system_strip.add_child(system_panel)
			var system_column := VBoxContainer.new()
			system_column.add_theme_constant_override("separation", 4)
			system_panel.add_child(system_column)
			var system_name := Label.new()
			system_name.text = str(system.get("name", "Unknown System")).to_upper()
			system_name.add_theme_font_size_override("font_size", 15)
			system_name.add_theme_color_override("font_color", Color(0.42, 0.88, 0.92))
			system_column.add_child(system_name)
			var system_description := Label.new()
			system_description.text = str(system.get("description", ""))
			system_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			system_description.add_theme_font_size_override("font_size", 11)
			system_description.add_theme_color_override("font_color", Color(0.62, 0.74, 0.82))
			system_column.add_child(system_description)

	var section_title := Label.new()
	section_title.text = "AVAILABLE CONTRACTS"
	section_title.add_theme_font_size_override("font_size", 18)
	section_title.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	column.add_child(section_title)

	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 16)
	column.add_child(_cards)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.62, 0.85, 0.90))
	column.add_child(_status_label)


func _refresh_contracts() -> void:
	if _profile == null or _cards == null:
		return
	for child in _cards.get_children():
		child.queue_free()
	for contract in _profile.get_contract_catalog():
		_cards.add_child(_build_contract_card(contract))


func _build_contract_card(contract: Dictionary) -> Control:
	var contract_id := str(contract.get("id", ""))
	var unlocked := bool(contract.get("unlocked", false))
	var completed := bool(contract.get("completed", false))
	var active := bool(contract.get("active", false))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.045, 0.072, 0.97) if unlocked else Color(0.012, 0.025, 0.04, 0.96)
	style.border_color = Color(0.10, 0.82, 0.72, 0.95) if active else Color(0.12, 0.32, 0.45, 0.75)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var status := Label.new()
	status.text = "ACTIVE DEPLOYMENT" if active else ("COMPLETED" if completed else ("AVAILABLE" if unlocked else "LOCKED"))
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_color_override("font_color", Color(0.35, 0.94, 0.78) if unlocked else Color(0.55, 0.62, 0.68))
	content.add_child(status)

	var title := Label.new()
	title.text = str(contract.get("name", contract_id))
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0) if unlocked else Color(0.56, 0.64, 0.70))
	content.add_child(title)

	var system := Label.new()
	system.text = str(contract.get("system_name", "Unknown System")).to_upper()
	system.add_theme_font_size_override("font_size", 13)
	system.add_theme_color_override("font_color", Color(0.38, 0.82, 0.94))
	content.add_child(system)

	var description := Label.new()
	description.text = str(contract.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_color_override("font_color", Color(0.68, 0.78, 0.86))
	content.add_child(description)

	var details := Label.new()
	details.text = "THREAT: %s\nCOMBAT WAVES: %d + %d\nCONTRACT PAYOUT: %s CR" % [
		str(contract.get("difficulty", "UNKNOWN")),
		int(contract.get("waves_per_encounter", 3)),
		int(contract.get("waves_per_encounter", 3)),
		String.num_int64(int(contract.get("reward", 0)))
	]
	details.add_theme_font_size_override("font_size", 13)
	details.add_theme_color_override("font_color", Color(0.78, 0.88, 0.94))
	content.add_child(details)

	var button := Button.new()
	button.custom_minimum_size.y = 48
	if not unlocked:
		var required_id := str(contract.get("unlock_after", ""))
		var required_contract := _profile.get_contract(required_id)
		button.text = "COMPLETE %s FIRST" % str(required_contract.get("name", required_id)).to_upper()
		button.disabled = true
	else:
		button.text = "REPLAY CONTRACT" if completed else ("LAUNCH ACTIVE" if active else "ACCEPT & LAUNCH")
		button.pressed.connect(_accept_and_launch.bind(contract_id))
	content.add_child(button)
	return card


func _accept_and_launch(contract_id: String) -> void:
	if _profile == null or not _profile.accept_contract(contract_id):
		_status_label.text = "CONTRACT ACCEPTANCE FAILED — check progression and pilot profile."
		return
	var save_manager := get_node_or_null("/root/GameSave")
	if save_manager != null:
		save_manager.call("delete_slot", "silent_relay")
		save_manager.set("pending_mission_payload", {})
	_status_label.text = "CONTRACT ACCEPTED — launching %s." % str(_profile.get_contract(contract_id).get("name", contract_id))
	var error := get_tree().change_scene_to_file(MISSION_SCENE)
	if error != OK:
		_status_label.text = "LAUNCH FAILED — mission scene could not be loaded."


func _back_to_menu() -> void:
	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_error("Could not return to the main menu: %s" % error)
