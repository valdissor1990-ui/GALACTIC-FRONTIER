extends CanvasLayer
class_name ScreenPostFx
## Fullscreen single-pass post (vignette + soft chroma).
## Disable on low-end via enabled export or quality preset later.

@export var enabled_fx: bool = true
@export_range(0.0, 1.5, 0.01) var vignette_strength: float = 0.5
@export_range(0.0, 0.01, 0.0001) var chroma_strength: float = 0.002
@export_range(0.8, 1.3, 0.01) var contrast: float = 1.04
@export_range(0.5, 1.5, 0.01) var saturation: float = 1.05

var _rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.name = "PostRect"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	var shader := load("res://assets/shaders/screen_cinematic.gdshader") as Shader
	if shader:
		_mat.shader = shader
		_apply_params()
		_rect.material = _mat
	add_child(_rect)
	_rect.visible = enabled_fx


func _apply_params() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("vignette_strength", vignette_strength)
	_mat.set_shader_parameter("chroma_strength", chroma_strength)
	_mat.set_shader_parameter("contrast", contrast)
	_mat.set_shader_parameter("saturation", saturation)


func set_fx_enabled(value: bool) -> void:
	enabled_fx = value
	if _rect:
		_rect.visible = value
