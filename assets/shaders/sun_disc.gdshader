shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec3 disc_color : source_color = vec3(1.0, 0.82, 0.58);
uniform float disc_energy : hint_range(0.5, 4.0) = 1.8;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float radius = length(centered);
	float disc = 1.0 - smoothstep(0.88, 1.0, radius);
	float limb = 1.0 - smoothstep(0.58, 0.94, radius);
	vec3 warm_core = mix(disc_color, vec3(1.0, 0.96, 0.86), limb * 0.72);
	ALBEDO = warm_core;
	EMISSION = warm_core * disc_energy;
	ALPHA = disc;
}
