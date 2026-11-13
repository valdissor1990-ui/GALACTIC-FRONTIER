shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// 2020s-style ship hull without external textures.
// Panels + Fresnel rim + optional hit flash driven from GDScript.

uniform vec4 albedo_color : source_color = vec4(0.14, 0.20, 0.28, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.78;
uniform float roughness : hint_range(0.0, 1.0) = 0.34;
uniform vec4 rim_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.85;
uniform float panel_scale : hint_range(1.0, 40.0) = 12.0;
uniform float panel_contrast : hint_range(0.0, 1.0) = 0.22;
// 0 = calm, 1 = full damage flash
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 0.45, 0.15, 1.0);
// Subtle moving heat on engines / stressed metal
uniform float heat : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 grid = floor(UV * panel_scale);
	float h = hash21(grid);
	float panel = mix(1.0 - panel_contrast, 1.0, smoothstep(0.35, 0.65, h));

	// Fine rivet-line break (cheap)
	float line = step(0.96, fract(UV.x * panel_scale * 0.5))
		+ step(0.96, fract(UV.y * panel_scale * 0.5));
	line = clamp(line, 0.0, 1.0);
	panel *= (1.0 - line * 0.12);

	vec3 base = albedo_color.rgb * panel;
	base = mix(base, hit_color.rgb, hit_flash * 0.75);

	ALBEDO = base;
	METALLIC = metallic * (1.0 - hit_flash * 0.25);
	ROUGHNESS = clamp(roughness + (1.0 - panel) * 0.15 + hit_flash * 0.2, 0.05, 1.0);

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	vec3 rim = rim_color.rgb * fresnel * rim_strength;
	vec3 flash = hit_color.rgb * hit_flash * (0.6 + fresnel);
	vec3 heat_em = vec3(1.0, 0.35, 0.08) * heat * fresnel * 0.8;
	EMISSION = rim + flash + heat_em;
}
