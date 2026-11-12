extends Control
## Interactive showroom for all seven original ship classes.

const FLIGHT_SCENE := "res://scenes/demo/ten_minute_demo.tscn"
const RUNTIME_GLTF_SCRIPT: Script = preload("res://scripts/visual/runtime_gltf_model.gd")
const SHIPS := [
	{"name": "PLAYER FIGHTER MK.I", "role": "MULTIROLE / PLAYER CRAFT", "path": "res://assets/models/ships/player_fighter.glb", "scale": 0.42, "description": "A compact, agile frontline fighter built for independent patrols and precision engagements.", "specs": "CLASS  LIGHT FIGHTER     DRIVE  TWIN ION"},
	{"name": "RAIDER INTERCEPTOR", "role": "HOSTILE / INTERCEPTOR", "path": "res://assets/models/ships/enemy_fighter.glb", "scale": 0.42, "description": "A fast attack craft with a narrow armored spine, split-delta wings and a triple engine cluster.", "specs": "CLASS  INTERCEPTOR       ROLE  PURSUIT"},
	{"name": "AEGIS HEAVY FIGHTER", "role": "HEAVY / SPACE SUPERIORITY", "path": "res://assets/models/ships/heavy_fighter.glb", "scale": 0.32, "description": "A heavily armored superiority fighter with reinforced wing roots, turret coverage and high-output drives.", "specs": "CLASS  HEAVY FIGHTER     ARMOR  HEAVY"},
	{"name": "BASTION BOMBER", "role": "STRIKE / ORDNANCE", "path": "res://assets/models/ships/bomber.glb", "scale": 0.28, "description": "A broad strike platform carrying internal payload bays and remote defensive turrets.", "specs": "CLASS  BOMBER            PAYLOAD  INTERNAL"},
	{"name": "MULE CARGO HAULER", "role": "CIVILIAN / LOGISTICS", "path": "res://assets/models/ships/cargo_hauler.glb", "scale": 0.28, "description": "A modular industrial hauler with exposed container racks, docking interfaces and multiple drive nacelles.", "specs": "CLASS  HAULER            CARGO  MODULAR"},
	{"name": "VANGUARD FRIGATE", "role": "ESCORT / PATROL", "path": "res://assets/models/ships/frigate.glb", "scale": 0.22, "description": "A long-range escort warship designed to protect convoys and maintain a defensive perimeter.", "specs": "CLASS  FRIGATE           ROLE  ESCORT"},
	{"name": "LEVIATHAN CRUISER", "role": "CAPITAL / COMMAND", "path": "res://assets/models/ships/cruiser.glb", "scale": 0.16, "description": "A capital command vessel with a broad armored hull, layered batteries and long-duration fleet support systems.", "specs": "CLASS  CRUISER           ROLE  CAPITAL"}
]

var _ship_index: int = 0
var _model_mount: Node3D
var _active_model: Node3D
var _name_label: Label
var _role_label: Label
var _description_label: Label
var _specs_label: Label
var _counter_label: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_showroom()
	_show_ship(0)


func _process(delta: float) -> void:
	if is_instance_valid(_model_mount):
		_model_mount.rotate_y(delta * 0.16)


func _build_showroom() -> void:
	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "ShowroomViewport"
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.name = "Showroom3D"
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	var world := Node3D.new()
	world.name = "HangarWorld"
	viewport.add_child(world)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.012, 0.027)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.40, 0.50, 0.72)
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.42
	environment_node.environment = environment
	world.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-28.0, 34.0, 0.0)
	key_light.light_color = Color(0.72, 0.84, 1.0)
	key_light.light_energy = 2.0
	key_light.shadow_enabled = true
	world.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(6.0, 3.0, 7.0)
	fill_light.light_color = Color(0.12, 0.55, 1.0)
	fill_light.light_energy = 3.2
	fill_light.omni_range = 28.0
	world.add_child(fill_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-7.0, 2.0, -5.0)
	rim_light.light_color = Color(0.48, 0.24, 1.0)
	rim_light.light_energy = 2.6
	rim_light.omni_range = 24.0
	world.add_child(rim_light)

	var platform := MeshInstance3D.new()
	platform.name = "DisplayPlinth"
	platform.position.y = -2.8
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 4.2
	cylinder.bottom_radius = 4.6
	cylinder.height = 0.34
	cylinder.radial_segments = 96
	platform.mesh = cylinder
	var platform_material := StandardMaterial3D.new()
	platform_material.albedo_color = Color(0.075, 0.11, 0.17)
	platform_material.metallic = 0.48
	platform_material.roughness = 0.48
	platform.material_override = platform_material
	world.add_child(platform)

	var platform_ring := MeshInstance3D.new()
	platform_ring.position.y = -2.59
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 4.28
	ring_mesh.outer_radius = 4.36
	ring_mesh.rings = 96
	ring_mesh.ring_segments = 12
	platform_ring.mesh = ring_mesh
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = Color(0.04, 0.62, 0.95)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.02, 0.35, 0.8)
	ring_material.emission_energy_multiplier = 1.6
	platform_ring.material_override = ring_material
	world.add_child(platform_ring)

	_model_mount = Node3D.new()
	_model_mount.name = "ShipDisplayMount"
	_model_mount.position.y = -2.0
	world.add_child(_model_mount)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.6, 12.5)
	camera.fov = 40.0
	camera.current = true
	world.add_child(camera)
	camera.look_at(Vector3(0.0, -1.0, 0.0), Vector3.UP)

	var overlay := Control.new()
	overlay.name = "HangarOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(overlay)

	var header := Label.new()
	header.position = Vector2(38, 28)
	header.text = "FRONTIER COMMAND  /  SHIP REGISTRY"
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color(0.30, 0.82, 1.0))
	overlay.add_child(header)

	var panel := PanelContainer.new()
	panel.position = Vector2(38, 78)
	panel.custom_minimum_size = Vector2(430, 260)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.008, 0.020, 0.042, 0.88)
	panel_style.border_color = Color(0.08, 0.48, 0.72, 0.82)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 22
	panel_style.content_margin_right = 22
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 27)
	_name_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	column.add_child(_name_label)

	_role_label = Label.new()
	_role_label.add_theme_font_size_override("font_size", 13)
	_role_label.add_theme_color_override("font_color", Color(0.22, 0.78, 1.0))
	column.add_child(_role_label)

	var separator := HSeparator.new()
	column.add_child(separator)

	_description_label = Label.new()
	_description_label.custom_minimum_size = Vector2(380, 76)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 15)
	_description_label.add_theme_color_override("font_color", Color(0.68, 0.79, 0.88))
	column.add_child(_description_label)

	_specs_label = Label.new()
	_specs_label.add_theme_font_size_override("font_size", 12)
	_specs_label.add_theme_color_override("font_color", Color(0.35, 0.65, 0.82))
	column.add_child(_specs_label)

	_counter_label = Label.new()
	_counter_label.position = Vector2(40, 660)
	_counter_label.add_theme_font_size_override("font_size", 13)
	_counter_label.add_theme_color_override("font_color", Color(0.42, 0.72, 0.9))
	overlay.add_child(_counter_label)

	var previous := Button.new()
	previous.text = "  PREVIOUS SHIP"
	previous.position = Vector2(40, 590)
	previous.custom_minimum_size = Vector2(190, 48)
	previous.pressed.connect(show_previous_ship)
	overlay.add_child(previous)

	var next := Button.new()
	next.text = "NEXT SHIP  "
	next.position = Vector2(245, 590)
	next.custom_minimum_size = Vector2(190, 48)
	next.pressed.connect(show_next_ship)
	overlay.add_child(next)

	var back := Button.new()
	back.text = "RETURN TO COMMAND"
	back.position = Vector2(1010, 28)
	back.custom_minimum_size = Vector2(230, 44)
	back.pressed.connect(_return_to_menu)
	overlay.add_child(back)

	var hint := Label.new()
	hint.position = Vector2(800, 665)
	hint.size = Vector2(430, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.text = "A / D OR ARROW KEYS  —  SELECT SHIP"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.35, 0.58, 0.72))
	overlay.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A or event.keycode == KEY_LEFT:
			show_previous_ship()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			show_next_ship()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_return_to_menu()
			get_viewport().set_input_as_handled()


func show_next_ship() -> void:
	_show_ship((_ship_index + 1) % SHIPS.size())


func show_previous_ship() -> void:
	_show_ship((_ship_index - 1 + SHIPS.size()) % SHIPS.size())


func _show_ship(index: int) -> void:
	_ship_index = clampi(index, 0, SHIPS.size() - 1)
	if is_instance_valid(_active_model):
		_active_model.queue_free()
	_active_model = Node3D.new()
	_active_model.name = "ActiveShipModel"
	_active_model.set_script(RUNTIME_GLTF_SCRIPT)
	_active_model.set("source_path", SHIPS[_ship_index].path)
	_active_model.set("model_scale", Vector3.ONE * float(SHIPS[_ship_index].scale))
	_active_model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_model_mount.add_child(_active_model)
	_name_label.text = SHIPS[_ship_index].name
	_role_label.text = SHIPS[_ship_index].role
	_description_label.text = SHIPS[_ship_index].description
	_specs_label.text = SHIPS[_ship_index].specs
	_counter_label.text = "HULL REGISTRY  /  %02d OF %02d" % [_ship_index + 1, SHIPS.size()]


func get_ship_count() -> int:
	return SHIPS.size()


func get_current_ship_name() -> String:
	return str(SHIPS[_ship_index].name)


func get_visible_model_mesh_count() -> int:
	return _count_meshes(_active_model)


func _count_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and (node as MeshInstance3D).visible else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count


func _return_to_menu() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	if error != OK:
		push_error("Could not return to main menu: %s" % error)
