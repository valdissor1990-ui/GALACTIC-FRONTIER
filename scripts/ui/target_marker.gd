extends Control
## Screen-space objective marker: brackets the objective or points toward it.

var target: Node3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_target(value: Node3D) -> void:
	target = value
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(target):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var center := size * 0.5
	var world_position := target.global_position
	var behind := camera.is_position_behind(world_position)
	var screen_position := camera.unproject_position(world_position)
	var visible_rect := Rect2(Vector2.ZERO, size).grow(-42.0)
	if not behind and visible_rect.has_point(screen_position):
		var p := screen_position
		var color := Color(0.18, 0.86, 1.0, 0.95)
		var corner := 12.0
		draw_line(p + Vector2(-corner, -corner), p + Vector2(-corner, -4), color, 2.0)
		draw_line(p + Vector2(-corner, -corner), p + Vector2(-4, -corner), color, 2.0)
		draw_line(p + Vector2(corner, -corner), p + Vector2(corner, -4), color, 2.0)
		draw_line(p + Vector2(corner, -corner), p + Vector2(4, -corner), color, 2.0)
		draw_line(p + Vector2(-corner, corner), p + Vector2(-corner, 4), color, 2.0)
		draw_line(p + Vector2(-corner, corner), p + Vector2(-4, corner), color, 2.0)
		draw_line(p + Vector2(corner, corner), p + Vector2(corner, 4), color, 2.0)
		draw_line(p + Vector2(corner, corner), p + Vector2(4, corner), color, 2.0)
		draw_circle(p, 2.5, color)
		_draw_objective_label(p + Vector2(16, -12), color)
		return
	var direction := screen_position - center
	if behind:
		direction = -direction
	if direction.length_squared() < 0.001:
		direction = Vector2.UP
	direction = direction.normalized()
	var half := size * 0.5 - Vector2(58, 58)
	var scale_x := half.x / maxf(absf(direction.x), 0.001)
	var scale_y := half.y / maxf(absf(direction.y), 0.001)
	var edge_position := center + direction * minf(scale_x, scale_y)
	var side := Vector2(-direction.y, direction.x)
	var tip := edge_position + direction * 15.0
	var base := edge_position - direction * 10.0
	draw_colored_polygon(PackedVector2Array([tip, base + side * 9.0, base - side * 9.0]), Color(0.18, 0.86, 1.0, 0.98))
	_draw_objective_label(edge_position + Vector2(16, 4), Color(0.62, 0.88, 1.0))

func _draw_objective_label(anchor: Vector2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 12
	var text_width := font.get_string_size("OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline_y := clampf(anchor.y, 14.0, size.y - 8.0)
	if anchor.x + text_width > size.x - 8.0:
		var right_x := clampf(anchor.x - 16.0, text_width + 8.0, size.x - 8.0)
		draw_string(font, Vector2(right_x, baseline_y), "OBJECTIVE", HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, color)
	else:
		var left_x := clampf(anchor.x, 8.0, size.x - text_width - 8.0)
		draw_string(font, Vector2(left_x, baseline_y), "OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
