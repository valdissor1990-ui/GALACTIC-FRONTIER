shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform vec4 plume_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 4.0) = 1.0;
uniform float core_boost : hint_range(0.0, 2.0) = 0.8;

void fragment() {
	// Soft axial falloff along local Z (mesh should be a stretched sphere/cone)
	float axis = 1.0 - clamp(abs(UV.y - 0.5) * 2.0, 0.0, 1.0);
	float radial = 1.0 - clamp(length(UV - vec2(0.5, 0.5)) * 2.0, 0.0, 1.0);
	float mask = pow(axis * radial, 1.4);
	vec3 col = plume_color.rgb * (intensity + core_boost * mask);
	ALBEDO = col;
	EMISSION = col;
	ALPHA = mask * clamp(intensity, 0.0, 1.0);
}
