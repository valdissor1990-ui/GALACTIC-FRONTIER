shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform float core_power : hint_range(1.0, 8.0) = 3.5;
uniform float halo_softness : hint_range(0.5, 4.0) = 2.2;
uniform float emissive_boost : hint_range(0.5, 6.0) = 2.4;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float core = exp(-d * d * core_power * 2.5);
	float halo = exp(-d * d * halo_softness);
	vec3 hot = mix(COLOR.rgb, vec3(1.0, 0.95, 0.9), core);
	ALBEDO = hot;
	EMISSION = hot * (core * 2.0 + halo) * emissive_boost;
	ALPHA = clamp(halo * COLOR.a, 0.0, 1.0);
}
