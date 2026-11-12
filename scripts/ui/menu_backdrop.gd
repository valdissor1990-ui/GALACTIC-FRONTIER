extends Control
## Decorative starfield and distant planet for the main menu.

func _draw() -> void:
	for i in range(180):
		var x := fposmod(float(i * 73 + 19), 997.0) / 997.0 * size.x
		var y := fposmod(float(i * 127 + 41), 991.0) / 991.0 * size.y
		draw_circle(Vector2(x, y), 0.8 + float(i % 3) * 0.35, Color(0.55, 0.78, 0.95, 0.5))
	var planet_center := Vector2(size.x * 0.82, size.y * 0.53)
	var radius := minf(size.y * 0.31, size.x * 0.19)
	draw_circle(planet_center, radius, Color("#0b2940"))
	draw_arc(planet_center, radius, -PI * 0.92, PI * 0.92, 96, Color("#1c7394"), 2.0, true)
	draw_arc(planet_center, radius * 1.34, -0.15, PI + 0.15, 96, Color(0.08, 0.50, 0.70, 0.42), 1.2, true)
