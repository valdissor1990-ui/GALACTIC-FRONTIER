shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Lightweight "2020s" ship hull: base color, metallic roughness, rim light.
// Works without external textures; optional albedo texture slot.

uniform vec4 albedo_color : source_color = vec4(0.14, 0.20, 0.28, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.78;
uniform float roughness : hint_range(0.0, 1.0) = 0.34;
uniform vec4 rim_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.85;
uniform float panel_scale : hint_range(1.0, 40.0) = 12.0;
uniform float panel_contrast : hint_range(0.0, 1.0) = 0.22;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	// Procedural micro-panels (UV based) for close-up detail without textures
	vec2 grid = floor(UV * panel_scale);
	float h = hash21(grid);
	float panel = mix(1.0 - panel_contrast, 1.0, smoothstep(0.35, 0.65, h));

	vec3 base = albedo_color.rgb * panel;
	ALBEDO = base;
	METALLIC = metallic;
	ROUGHNESS = clamp(roughness + (1.0 - panel) * 0.15, 0.05, 1.0);

	// View-based rim for silhouette readability in dark space
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength;
}
