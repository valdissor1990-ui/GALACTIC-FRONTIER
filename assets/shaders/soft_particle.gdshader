shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

// Soft circular particle for dust / trails / sparks.
// COLOR comes from ParticleProcessMaterial (vertex color).

uniform float softness : hint_range(0.5, 4.0) = 1.8;
uniform float emissive_boost : hint_range(0.0, 4.0) = 1.2;
uniform vec3 tint : source_color = vec3(1.0);

void vertex() {
	// Billboard toward camera (Y-axis free)
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
	float mask = exp(-d * d * softness);
	vec3 col = COLOR.rgb * tint;
	ALBEDO = col;
	EMISSION = col * emissive_boost;
	ALPHA = mask * COLOR.a;
}
