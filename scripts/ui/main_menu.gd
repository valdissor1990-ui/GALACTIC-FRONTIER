extends Control

const FLIGHT_SCENE := "res://scenes/demo/ten_minute_demo.tscn"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_menu()

func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = Color("#040914")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var stars := Control.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.draw.connect(func() -> void:
		for i in range(180):
			var x := fposmod(float(i * 73 + 19), 997.0) / 997.0 * size.x
			var y := fposmod(float(i * 127 + 41), 991.0) / 991.0 * size.y
			draw_circle(Vector2(x, y), 0.8 + float(i % 3) * 0.35, Color(0.55, 0.78, 0.95, 0.5))
	)
	add_child(stars)
	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	layout.position = Vector2(90, -190)
	layout.custom_minimum_size = Vector2(520, 390)
	layout.add_theme_constant_override("separation", 16)
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
	var controls := Label.new()
	controls.text = "WASD / MOUSE — FLIGHT     LMB — FIRE     T — LOCK\nF — SCAN     C — CAMERA     SHIFT — BOOST     ESC — PAUSE"
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color("#7294a8"))
	layout.add_child(controls)
	var quit := Button.new()
	quit.text = "EXIT"
	quit.custom_minimum_size = Vector2(390, 42)
	quit.pressed.connect(func() -> void: get_tree().quit())
	layout.add_child(quit)

func _start_game() -> void:
	var error := get_tree().change_scene_to_file(FLIGHT_SCENE)
	if error != OK:
		push_error("Could not load Silent Relay mission: %s" % error)
