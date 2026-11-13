extends Node
class_name DynamicResolution
## Softly adjusts GraphicsQuality.dynamic_scale_mul to hold a target FPS.
## Attach under any always-present node (e.g. flight root). Optional.

@export var enabled: bool = true
@export var target_fps: float = 60.0
@export var min_mul: float = 0.65
@export var max_mul: float = 1.0
@export var sample_seconds: float = 0.5
@export var adjust_step: float = 0.03

var _accum_time: float = 0.0
var _frame_count: int = 0


func _process(delta: float) -> void:
	if not enabled:
		return
	var gq := get_node_or_null("/root/GraphicsQuality")
	if gq == null:
		return
	# High preset stays at full internal scale; only Low/Medium adapt
	if gq.current == gq.Preset.HIGH:
		if gq.dynamic_scale_mul != 1.0:
			gq.set_dynamic_scale_mul(1.0)
		return

	_accum_time += delta
	_frame_count += 1
	if _accum_time < sample_seconds:
		return

	var fps := float(_frame_count) / _accum_time
	_accum_time = 0.0
	_frame_count = 0

	var mul: float = gq.dynamic_scale_mul
	if fps < target_fps * 0.9:
		mul = maxf(min_mul, mul - adjust_step)
	elif fps > target_fps * 1.08:
		mul = minf(max_mul, mul + adjust_step)
	else:
		return
	gq.set_dynamic_scale_mul(mul)
