shader_type spatial;
render_mode blend_add, depth_draw_never, cull_front, unshaded, shadows_disabled;

// Inverted-sphere atmosphere rim. Place on a slightly larger sphere than the planet.

uniform vec3 atmosphere_color : source_color = vec3(0.35, 0.55, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.1;
uniform float falloff : hint_range(0.5, 8.0) = 3.5;
uniform float density : hint_range(0.1, 2.0) = 0.85;

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), falloff);
	float a = fres * intensity * density;
	ALBEDO = atmosphere_color;
	ALPHA = clamp(a, 0.0, 1.0);
	EMISSION = atmosphere_color * a;
}
