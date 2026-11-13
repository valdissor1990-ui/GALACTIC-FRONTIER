shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform vec4 pulse_color : source_color = vec4(0.45, 0.85, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.1, 4.0) = 1.1;
uniform float pulse_width : hint_range(0.02, 0.4) = 0.08;
uniform float base_glow : hint_range(0.0, 2.0) = 0.35;

void fragment() {
	float t = TIME * pulse_speed;
	// Expanding ring in UV space
	float d = distance(UV, vec2(0.5, 0.5));
	float wave = fract(t * 0.25);
	float ring = 1.0 - smoothstep(0.0, pulse_width, abs(d - wave));
	float core = exp(-d * 4.0) * base_glow;
	float a = clamp(ring + core, 0.0, 1.0);
	vec3 col = pulse_color.rgb * (1.0 + ring * 1.5);
	ALBEDO = col;
	EMISSION = col;
	ALPHA = a;
}
