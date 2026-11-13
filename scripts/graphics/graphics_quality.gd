extends Node
## GraphicsQuality — presets shaped like SC axes (view distance, gas, fog)
## without claiming feature parity with CIG's renderer.
## Autoload: GraphicsQuality
##
## Tonemap: Low Filmic | Medium ACES | High AgX

enum Preset { LOW = 0, MEDIUM = 1, HIGH = 2 }

signal quality_changed(preset: Preset)

var current: Preset = Preset.MEDIUM
var dynamic_scale_mul: float = 1.0

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
	set_preset(((int(current) + 1) % 3) as Preset)


func apply_preset(preset: Preset) -> void:
	current = preset
	match preset:
		Preset.LOW:
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		Preset.MEDIUM:
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		Preset.HIGH:
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
	_apply_viewport_scale()
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


func get_tonemap_name() -> String:
	match tonemap_mode():
		Environment.TONE_MAPPER_FILMIC:
			return "Filmic"
		Environment.TONE_MAPPER_ACES:
			return "ACES"
		Environment.TONE_MAPPER_AGX:
			return "AgX"
		_:
			return "Other"


# --- FSR --------------------------------------------------------------------

func base_scale_3d() -> float:
	match current:
		Preset.LOW:
			return 0.59
		Preset.MEDIUM:
			return 0.77
		Preset.HIGH:
			return 1.0
	return 0.77


func scaling_3d_mode() -> int:
	match current:
		Preset.LOW:
			return 0
		_:
			return 1


func fsr_sharpness() -> float:
	match current:
		Preset.LOW:
			return 0.35
		Preset.MEDIUM:
			return 0.2
		Preset.HIGH:
			return 0.15
	return 0.2


func effective_scale_3d() -> float:
	return clampf(base_scale_3d() * dynamic_scale_mul, 0.4, 1.25)


func set_dynamic_scale_mul(mul: float) -> void:
	dynamic_scale_mul = clampf(mul, 0.5, 1.15)
	_apply_viewport_scale()


func _apply_viewport_scale() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	vp.scaling_3d_scale = effective_scale_3d()
	vp.scaling_3d_mode = scaling_3d_mode() as Viewport.Scaling3DMode
	if "fsr_sharpness" in vp:
		vp.fsr_sharpness = fsr_sharpness()


# --- Tonemap ----------------------------------------------------------------

func tonemap_mode() -> int:
	match current:
		Preset.LOW:
			return Environment.TONE_MAPPER_FILMIC
		Preset.MEDIUM:
			return Environment.TONE_MAPPER_ACES
		Preset.HIGH:
			return Environment.TONE_MAPPER_AGX
	return Environment.TONE_MAPPER_ACES


func tonemap_exposure() -> float:
	match current:
		Preset.LOW:
			return 0.90
		Preset.MEDIUM:
			return 0.94
		Preset.HIGH:
			return 1.05
	return 0.94


func tonemap_white() -> float:
	match current:
		Preset.LOW:
			return 6.0
		Preset.MEDIUM:
			return 7.5
		Preset.HIGH:
			return 16.29
	return 7.5


func agx_white() -> float:
	return 16.29


func agx_contrast() -> float:
	return 1.05


func apply_tonemap_extras(env: Environment) -> void:
	if env == null:
		return
	if tonemap_mode() != Environment.TONE_MAPPER_AGX:
		return
	if "tonemap_agx_white" in env:
		env.tonemap_agx_white = agx_white()
	elif "agx_white" in env:
		env.set("agx_white", agx_white())
	if "tonemap_agx_contrast" in env:
		env.tonemap_agx_contrast = agx_contrast()
	elif "agx_contrast" in env:
		env.set("agx_contrast", agx_contrast())


func adjustment_enabled() -> bool:
	return current != Preset.LOW


func adjustment_contrast() -> float:
	match current:
		Preset.HIGH:
			return 1.06
		_:
			return 1.04


func adjustment_saturation() -> float:
	match current:
		Preset.HIGH:
			return 1.08
		_:
			return 1.05


# --- SC-inspired axes -------------------------------------------------------
# Object View Distance: multiplier on visibility_range_end for clutter fields.
func object_view_distance_mul() -> float:
	match current:
		Preset.LOW:
			return 0.55
		Preset.MEDIUM:
			return 1.0
		Preset.HIGH:
			return 1.35
	return 1.0


# Gas cloud (local volumetric near giant / anomaly)
func gas_cloud_enabled() -> bool:
	return current != Preset.LOW


func gas_cloud_density() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 0.012
		Preset.HIGH:
			return 0.022
	return 0.012


func gas_cloud_size() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 90.0
		Preset.HIGH:
			return 120.0
	return 90.0


# Depth cue fog (very light — space must stay black)
func depth_fog_enabled() -> bool:
	return current == Preset.HIGH


func depth_fog_density() -> float:
	match current:
		Preset.HIGH:
			return 0.00018
		_:
			return 0.0


# --- Sky detail -------------------------------------------------------------

func sky_star_density() -> float:
	match current:
		Preset.LOW:
			return 1.4
		Preset.MEDIUM:
			return 2.2
		Preset.HIGH:
			return 3.0
	return 2.2


func sky_star_brightness() -> float:
	match current:
		Preset.LOW:
			return 1.05
		Preset.MEDIUM:
			return 1.25
		Preset.HIGH:
			return 1.4
	return 1.25


func sky_nebula_strength() -> float:
	match current:
		Preset.LOW:
			return 0.35
		Preset.MEDIUM:
			return 0.55
		Preset.HIGH:
			return 0.75
	return 0.55


func sky_dust_strength() -> float:
	match current:
		Preset.LOW:
			return 0.15
		Preset.MEDIUM:
			return 0.28
		Preset.HIGH:
			return 0.4
	return 0.28


func sky_galactic_strength() -> float:
	match current:
		Preset.LOW:
			return 0.18
		Preset.MEDIUM:
			return 0.35
		Preset.HIGH:
			return 0.5
	return 0.35


# --- Gravitational lens -----------------------------------------------------

func lens_enabled() -> bool:
	return current != Preset.LOW


func lens_strength() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 0.85
		Preset.HIGH:
			return 1.15
	return 0.85


func lens_chroma() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 0.003
		Preset.HIGH:
			return 0.0055
	return 0.003


func lens_ring_boost() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 0.75
		Preset.HIGH:
			return 1.1
	return 0.75


# --- Sun --------------------------------------------------------------------

func sun_disc_energy() -> float:
	return 1.8


func sun_flare_enabled() -> bool:
	return current != Preset.LOW


func sun_flare_strength() -> float:
	match current:
		Preset.LOW:
			return 0.0
		Preset.MEDIUM:
			return 0.16
		Preset.HIGH:
			return 0.25
	return 0.16


# --- HDR glow ---------------------------------------------------------------

func glow_enabled() -> bool:
	return true


func glow_intensity() -> float:
	match current:
		Preset.LOW:
			return 0.28
		Preset.MEDIUM:
			return 0.5
		Preset.HIGH:
			return 0.62
	return 0.5


func glow_bloom() -> float:
	match current:
		Preset.LOW:
			return 0.10
		Preset.MEDIUM:
			return 0.22
		Preset.HIGH:
			return 0.32
	return 0.22


func glow_hdr_threshold() -> float:
	match current:
		Preset.LOW:
			return 1.0
		Preset.MEDIUM:
			return 0.85
		Preset.HIGH:
			return 0.72
	return 0.85


func glow_hdr_scale() -> float:
	match current:
		Preset.LOW:
			return 1.5
		Preset.MEDIUM:
			return 2.0
		Preset.HIGH:
			return 2.4
	return 2.0


func glow_hdr_luminance_cap() -> float:
	match current:
		Preset.LOW:
			return 6.0
		Preset.MEDIUM:
			return 12.0
		Preset.HIGH:
			return 16.0
	return 12.0


func glow_strength() -> float:
	match current:
		Preset.LOW:
			return 0.9
		Preset.MEDIUM:
			return 1.05
		Preset.HIGH:
			return 1.12
	return 1.05


func apply_glow_levels(env: Environment) -> void:
	if env == null:
		return
	match current:
		Preset.LOW:
			env.set_glow_level(1, 0.0)
			env.set_glow_level(2, 0.7)
			env.set_glow_level(3, 0.9)
			env.set_glow_level(4, 0.35)
			env.set_glow_level(5, 0.0)
			env.set_glow_level(6, 0.0)
		Preset.MEDIUM:
			env.set_glow_level(1, 0.0)
			env.set_glow_level(2, 0.6)
			env.set_glow_level(3, 1.0)
			env.set_glow_level(4, 0.7)
			env.set_glow_level(5, 0.35)
			env.set_glow_level(6, 0.0)
		Preset.HIGH:
			env.set_glow_level(1, 0.0)
			env.set_glow_level(2, 0.6)
			env.set_glow_level(3, 1.0)
			env.set_glow_level(4, 0.7)
			env.set_glow_level(5, 0.35)
			env.set_glow_level(6, 0.15)


# --- World density ----------------------------------------------------------

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
	match current:
		Preset.HIGH:
			return 1
		_:
			return 0


func ssao_enabled() -> bool:
	return current == Preset.HIGH


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
			return 120
		Preset.MEDIUM:
			return 280
		Preset.HIGH:
			return 420
	return 280


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
			return 28
		Preset.MEDIUM:
			return 48
		Preset.HIGH:
			return 64
	return 48


func _apply_to_scene_tree() -> void:
	var root := get_tree().root
	if root == null:
		return
	_walk_apply(root)


func _walk_apply(node: Node) -> void:
	if node.has_method("apply_quality"):
		node.call("apply_quality", self)
	elif node is DirectionalLight3D:
		var light := node as DirectionalLight3D
		if light.name != "FillLight":
			light.shadow_enabled = shadow_enabled()
			light.directional_shadow_max_distance = shadow_max_distance()
			light.directional_shadow_mode = shadow_splits() as DirectionalLight3D.ShadowMode
	for child in node.get_children():
		_walk_apply(child)


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
	current = clampi(int(cfg.get_value(CONFIG_SECTION, CONFIG_KEY, int(Preset.MEDIUM))), 0, 2) as Preset
