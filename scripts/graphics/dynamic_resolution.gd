extends Node
class_name DynamicResolution
## Frame-time governor. Adjusts only internal 3D scale, never UI resolution.

@export var enabled: bool = true
@export_range(30.0, 144.0, 1.0) var target_fps: float = 60.0
@export_range(0.5, 1.0, 0.01) var min_mul: float = 0.65
@export_range(0.75, 1.0, 0.01) var max_mul: float = 1.0
@export_range(0.25, 2.0, 0.05) var sample_seconds: float = 0.5
@export_range(0.005, 0.05, 0.005) var adjust_step: float = 0.02
@export_range(0.0, 0.5, 0.01) var cooldown_seconds: float = 0.75

var _elapsed := 0.0
var _frames := 0
var _cooldown := 0.0


func _process(delta: float) -> void:
	var quality := get_node_or_null("/root/GraphicsQuality")
	if quality == null:
		return
	if not enabled or quality.current == quality.Preset.HIGH:
		_reset_scale(quality)
		return

	_elapsed += delta
	_frames += 1
	_cooldown = maxf(0.0, _cooldown - delta)
	if _elapsed < sample_seconds:
		return

	var fps := float(_frames) / maxf(_elapsed, 0.001)
	_elapsed = 0.0
	_frames = 0
	if _cooldown > 0.0:
		return

	var scale_mul: float = quality.dynamic_scale_mul
	if fps < target_fps * 0.92:
		scale_mul = maxf(min_mul, scale_mul - adjust_step)
	elif fps > target_fps * 1.08:
		scale_mul = minf(max_mul, scale_mul + adjust_step)
	else:
		return

	if not is_equal_approx(scale_mul, quality.dynamic_scale_mul):
		quality.set_dynamic_scale_mul(scale_mul)
		_cooldown = cooldown_seconds


func _reset_scale(quality: Node) -> void:
	_elapsed = 0.0
	_frames = 0
	if quality.dynamic_scale_mul != 1.0:
		quality.set_dynamic_scale_mul(1.0)
