shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec3 flare_color : source_color = vec3(1.0, 0.58, 0.28);
uniform float flare_strength : hint_range(0.0, 0.5) = 0.16;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float broad_halo = exp(-radius * radius * 4.2);
	float inner_halo = exp(-radius * radius * 20.0);
	float horizontal_streak = exp(-abs(p.y) * 34.0) * exp(-abs(p.x) * 2.8);
	float vertical_streak = exp(-abs(p.x) * 42.0) * exp(-abs(p.y) * 2.2);
	float intensity = broad_halo * 0.22 + inner_halo * 0.20
		+ (horizontal_streak + vertical_streak) * 0.035;
	float mask = clamp(intensity, 0.0, 0.5);
	ALBEDO = vec3(0.0);
	EMISSION = flare_color * mask * flare_strength;
	ALPHA = mask;
}
