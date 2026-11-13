shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform vec4 plume_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 4.0) = 1.0;
uniform float core_boost : hint_range(0.0, 2.0) = 0.8;

void fragment() {
	vec2 uv = UV;
	float axis = 1.0 - clamp(abs(uv.y - 0.5) * 2.0, 0.0, 1.0);
	float radial = 1.0 - clamp(length(uv - vec2(0.5)) * 2.0, 0.0, 1.0);
	float mask = pow(max(axis * radial, 0.0), 1.35);
	// Temporal flicker + hot core
	float flick = 0.85 + 0.15 * sin(TIME * 28.0 + uv.y * 12.0);
	float core = pow(radial, 3.5) * axis * core_boost;
	vec3 hot = mix(plume_color.rgb, vec3(0.85, 0.95, 1.0), core);
	vec3 col = hot * (intensity * flick + core * 1.4);
	ALBEDO = col;
	EMISSION = col;
	ALPHA = mask * clamp(intensity * 0.9 + core * 0.35, 0.0, 1.0);
}
