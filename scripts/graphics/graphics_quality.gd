extends Node
## Global graphics quality presets for GALACTIC FRONTIER.
## Autoload name: GraphicsQuality
##
## Applies Environment, shadows, screen post, particle density, asteroid counts.
## Persists choice in user://graphics.cfg

enum Preset { LOW = 0, MEDIUM = 1, HIGH = 2 }

signal quality_changed(preset: Preset)

var current: Preset = Preset.MEDIUM

const CONFIG_PATH := "user://graphics.cfg"
const CONFIG_SECTION := "graphics"
const CONFIG_KEY := "preset"


func _ready() -> void:
	_load()
	apply_preset(current)


func set_preset(preset: Preset) -> void:
	current = preset
	apply_preset(current)
	_save()
	quality_changed.emit(current)


func cycle_preset() -> void:
	var next: Preset = ((int(current) + 1) % 3) as Preset
	set_preset(next)


func apply_preset(preset: Preset) -> void:
	current = preset
	match preset:
		Preset.LOW:
			_apply_low()
		Preset.MEDIUM:
			_apply_medium()
		Preset.HIGH:
			_apply_high()
	_apply_to_scene_tree()


func get_preset_name() -> String:
	match current:
		Preset.LOW:
			return "Low"
		Preset.MEDIUM:
			return "Medium"
		Preset.HIGH:
			return "High"
	return "Medium"


# --- Profile tables ---------------------------------------------------------

func shadow_enabled() -> bool:
	return current != Preset.LOW


func shadow_max_distance() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 160.0
		Preset.HIGH:
			return 280.0
	return 160.0


func shadow_splits() -> int:
	# DirectionalLight3D: 0=1 split, 1=2 splits, 2=4 splits
	match current:
		Preset.LOW:
			return 0
		Preset.MEDIUM:
			return 0
		Preset.HIGH:
			return 1
	return 0


func ssao_enabled() -> bool:
	return current == Preset.HIGH


func glow_intensity() -> float:
	match current:
		Preset.LOW:
			return 0.28
		Preset.MEDIUM:
			return 0.45
		Preset.HIGH:
			return 0.55
	return 0.45


func screen_post_enabled() -> bool:
	return current != Preset.LOW


func chroma_strength() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 0.0012
		Preset.HIGH:
			return 0.0020
	return 0.0012


func vignette_strength() -> float:
	match current:
		Preset.LOW:
			return 0.25
		Preset.MEDIUM:
			return 0.45
		Preset.HIGH:
			return 0.55
	return 0.45


func asteroid_count() -> int:
	match current:
		Preset.LOW:
			return 80
		Preset.MEDIUM:
			return 160
		Preset.HIGH:
			return 240
	return 160


func particle_amount_scale() -> float:
	match current:
		Preset.LOW:
			return 0.35
		Preset.MEDIUM:
			return 0.7
		Preset.HIGH:
			return 1.0
	return 0.7


func planet_segments() -> int:
	match current:
		Preset.LOW:
			return 24
		Preset.MEDIUM:
			return 40
		Preset.HIGH:
			return 48
	return 40


# --- Project / RenderingServer ---------------------------------------------

func _apply_low() -> void:
	# Smaller shadow atlas; soft shadows off conceptually via distance 0
	RenderingServer.directional_shadow_atlas_set_size(1024, true)


func _apply_medium() -> void:
	RenderingServer.directional_shadow_atlas_set_size(2048, true)


func _apply_high() -> void:
	RenderingServer.directional_shadow_atlas_set_size(4096, true)


func _apply_to_scene_tree() -> void:
	var root := get_tree().root
	if root == null:
		return
	_walk_apply(root)


func _walk_apply(node: Node) -> void:
	if node is OpenSpaceBackdrop:
		(node as OpenSpaceBackdrop).apply_quality(self)
	elif node is ScreenPostFx:
		(node as ScreenPostFx).apply_quality(self)
	elif node is EngineThrustFx:
		(node as EngineThrustFx).apply_quality(self)
	elif node is DirectionalLight3D:
		_apply_to_directional(node as DirectionalLight3D)
	for child in node.get_children():
		_walk_apply(child)


func _apply_to_directional(light: DirectionalLight3D) -> void:
	# Only touch key star lights (shadow-capable); leave fill alone if already no shadow
	if light.name == "FillLight":
		return
	light.shadow_enabled = shadow_enabled()
	light.directional_shadow_max_distance = shadow_max_distance()
	light.directional_shadow_mode = shadow_splits() as DirectionalLight3D.ShadowMode


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	cfg.set_value(CONFIG_SECTION, CONFIG_KEY, int(current))
	cfg.save(CONFIG_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		current = Preset.MEDIUM
		return
	var v: int = int(cfg.get_value(CONFIG_SECTION, CONFIG_KEY, int(Preset.MEDIUM)))
	current = clampi(v, 0, 2) as Preset
