shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Optimized hull: panels + rim + hit flash. Avoids extra smoothsteps.

uniform vec4 albedo_color : source_color = vec4(0.14, 0.20, 0.28, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.78;
uniform float roughness : hint_range(0.0, 1.0) = 0.34;
uniform vec4 rim_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.85;
uniform float panel_scale : hint_range(1.0, 40.0) = 12.0;
uniform float panel_contrast : hint_range(0.0, 1.0) = 0.22;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 0.45, 0.15, 1.0);
uniform float heat : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Cheap grid panels via fract (no hash21)
	vec2 g = fract(UV * panel_scale);
	float edge = step(0.92, max(g.x, g.y));
	float panel = 1.0 - edge * panel_contrast;

	vec3 base = mix(albedo_color.rgb * panel, hit_color.rgb, hit_flash * 0.75);
	ALBEDO = base;
	METALLIC = metallic * (1.0 - hit_flash * 0.25);
	ROUGHNESS = clamp(roughness + edge * 0.12 + hit_flash * 0.2, 0.05, 1.0);

	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, rim_power);
	vec3 em = rim_color.rgb * fresnel * rim_strength;
	em += hit_color.rgb * hit_flash * (0.6 + fresnel);
	em += vec3(1.0, 0.35, 0.08) * heat * fresnel * 0.8;
	EMISSION = em;
}
