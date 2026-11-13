shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 nebula_color : source_color = vec4(0.25, 0.2, 0.55, 0.14);
uniform float softness : hint_range(0.5, 4.0) = 2.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float mask = exp(-d * d * softness);
	// Mild structured noise so cards don't look identical
	float n = fract(sin(dot(UV * 8.0, vec2(12.9898, 78.233))) * 43758.5453);
	mask *= 0.75 + 0.25 * n;
	ALBEDO = nebula_color.rgb;
	ALPHA = clamp(mask * nebula_color.a * 2.5, 0.0, 1.0);
	EMISSION = nebula_color.rgb * mask * 0.6;
}
