extends Control
## Native Godot front end for the offline single-player campaign.

const FLIGHT_SCENE := "res://scenes/demo/ten_minute_demo.tscn"

var _continue_button: Button
var _controls_panel: PanelContainer
var _star_points: Array[Vector3] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_menu()
	_refresh_continue_state()
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#040914"))
	for point in _star_points:
		draw_circle(Vector2(point.x * size.x, point.y * size.y), point.z, Color(0.52, 0.76, 0.92, 0.28 + point.z * 0.16))

	var planet_center := Vector2(size.x * 0.79, size.y * 0.48)
	var planet_radius := minf(size.y * 0.34, size.x * 0.22)
	draw_circle(planet_center + Vector2(0, planet_radius * 0.08), planet_radius * 1.08, Color(0.035, 0.20, 0.31, 0.18))
	draw_circle(planet_center, planet_radius, Color("#0b2940"))
	draw_arc(planet_center, planet_radius, -PI * 0.92, PI * 0.92, 96, Color("#1c7394"), 2.0, true)
	draw_arc(planet_center, planet_radius * 0.88, -PI * 0.84, PI * 0.84, 96, Color(0.08, 0.34, 0.48, 0.72), 1.0, true)
	draw_arc(planet_center + Vector2(0, planet_radius * 0.03), planet_radius * 1.32, -0.18, PI + 0.18, 96, Color(0.08, 0.50, 0.70, 0.42), 1.2, true)
	draw_arc(planet_center + Vector2(0, planet_radius * 0.03), planet_radius * 1.44, PI + 0.20, TAU - 0.20, 96, Color(0.08, 0.50, 0.70, 0.22), 1.0, true)
	draw_line(Vector2(size.x * 0.05, size.y * 0.83), Vector2(size.x * 0.95, size.y * 0.83), Color(0.12, 0.37, 0.48, 0.35), 1.0)
	draw_line(Vector2(size.x * 0.05, size.y * 0.835), Vector2(size.x * 0.24, size.y * 0.835), Color("#26b6d8"), 2.0)


func _build_menu() -> void:
	_star_points.clear()
	for index in range(190):
		var x := fposmod(float(index * 73 + 19), 997.0) / 997.0
		var y := fposmod(float(index * 127 + 41), 991.0) / 991.0
		var radius := 0.7 + float(index % 4) * 0.28
		_star_points.append(Vector3(x, y, radius))

	var margins := MarginContainer.new()
	margins.name = "SafeMargins"
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 76)
	margins.add_theme_constant_override("margin_top", 54)
	margins.add_theme_constant_override("margin_right", 76)
	margins.add_theme_constant_override("margin_bottom", 34)
	add_child(margins)

	var layout := VBoxContainer.new()
	layout.name = "MenuLayout"
	layout.add_theme_constant_override("separation", 0)
	margins.add_child(layout)

	var top_line := Label.new()
	top_line.text = "FRONTIER COMMAND  /  SINGLE-PILOT ACCESS"
	top_line.add_theme_color_override("font_color", Color("#55c7e6"))
	top_line.add_theme_font_size_override("font_size", 12)
	layout.add_child(top_line)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 64
	layout.add_child(spacer_top)

	var title := Label.new()
	title.text = "GALACTIC\nFRONTIER"
	title.add_theme_color_override("font_color", Color("#e8f4fb"))
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_shadow_color", Color(0.03, 0.32, 0.46, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "THE SILENT RELAY"
	subtitle.add_theme_color_override("font_color", Color("#43c2e1"))
	subtitle.add_theme_font_size_override("font_size", 16)
	layout.add_child(subtitle)

	var intro := Label.new()
	intro.text = "A remote relay has gone dark.\nYour flight begins at the edge of known space."
	intro.add_theme_color_override("font_color", Color("#9eb8c8"))
	intro.add_theme_font_size_override("font_size", 14)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(450, 54)
	layout.add_child(intro)

	var spacer_mid := Control.new()
	spacer_mid.custom_minimum_size.y = 30
	layout.add_child(spacer_mid)

	var buttons := VBoxContainer.new()
	buttons.name = "MenuButtons"
	buttons.add_theme_constant_override("separation", 10)
	buttons.custom_minimum_size.x = 430
	layout.add_child(buttons)

	var new_game := _make_menu_button("01   /   NEW FLIGHT")
	new_game.name = "NewGameButton"
	new_game.pressed.connect(_start_new_game)
	buttons.add_child(new_game)

	_continue_button = _make_menu_button("02   /   CONTINUE FLIGHT")
	_continue_button.name = "ContinueButton"
	_continue_button.pressed.connect(_continue_game)
	buttons.add_child(_continue_button)

	var controls := _make_menu_button("03   /   FLIGHT CONTROLS")
	controls.name = "ControlsButton"
	controls.pressed.connect(_toggle_controls)
	buttons.add_child(controls)

	var exit_button := _make_menu_button("04   /   EXIT")
	exit_button.name = "ExitButton"
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	buttons.add_child(exit_button)

	_controls_panel = PanelContainer.new()
	_controls_panel.name = "ControlsPanel"
	_controls_panel.visible = false
	_controls_panel.custom_minimum_size = Vector2(430, 0)
	_controls_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.075, 0.11, 0.96), Color("#2a8099")))
	layout.add_child(_controls_panel)

	var controls_text := Label.new()
	controls_text.text = "FLIGHT CONTROLS\n\nW / S     THRUST / REVERSE\nA / D     STRAFE\nSPACE / Z     VERTICAL MOVEMENT\nQ / E     YAW       I / K     PITCH\nJ / L     ROLL       SHIFT     BOOST\nX     BRAKE       MOUSE     AIM\nLMB     FIRE       T / Y     TARGET LOCK / CLEAR\nF     SCAN       C     CAMERA\nF5 / F9     QUICK SAVE / LOAD"
	controls_text.add_theme_color_override("font_color", Color("#c5dce7"))
	controls_text.add_theme_font_size_override("font_size", 12)
	controls_text.add_theme_constant_override("line_spacing", 5)
	controls_text.custom_minimum_size = Vector2(390, 245)
	_controls_panel.add_child(controls_text)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(footer_spacer)

	var footer := Label.new()
	footer.text = "OFFLINE SINGLE PLAYER     •     NO ACCOUNTS / NO TELEMETRY     •     GODOT 4.7.2"
	footer.add_theme_color_override("font_color", Color("#55788a"))
	footer.add_theme_font_size_override("font_size", 10)
	layout.add_child(footer)

	var planet_caption := Label.new()
	planet_caption.text = "SOL FRONTIER  /  RELAY SECTOR 07"
	planet_caption.position = Vector2(size.x * 0.66, size.y * 0.82)
	planet_caption.add_theme_color_override("font_color", Color("#64a9bf"))
	planet_caption.add_theme_font_size_override("font_size", 11)
	add_child(planet_caption)


func _make_menu_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(430, 52)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#d9edf5"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("#506a79"))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.075, 0.11, 0.86), Color("#20546a")))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.035, 0.14, 0.19, 0.96), Color("#3bc0df")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.06, 0.19, 0.24, 0.98), Color("#56d4ed")))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.018, 0.045, 0.065, 0.8), Color("#253b48")))
	return button


func _panel_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.border_width_left = 2
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 18
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _refresh_continue_state() -> void:
	if _continue_button == null:
		return
	var saved := SaveSlots.load_slot("quick")
	var payload: Variant = saved.get("payload", {})
	_continue_button.disabled = not saved.ok or not payload is Dictionary or payload.get("game_id", "") != "galactic_frontier_silent_relay"


func _start_new_game() -> void:
	SaveSlots.pending_quick_load = false
	_open_flight_scene()


func _continue_game() -> void:
	var saved := SaveSlots.load_slot("quick")
	var payload: Variant = saved.get("payload", {})
	if not saved.ok or not payload is Dictionary or payload.get("game_id", "") != "galactic_frontier_silent_relay":
		_refresh_continue_state()
		return
	SaveSlots.pending_quick_load = true
	_open_flight_scene()


func _open_flight_scene() -> void:
	var error := get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		push_error("Could not load Silent Relay mission. Error code: %s" % error)


func _toggle_controls() -> void:
	_controls_panel.visible = not _controls_panel.visible


