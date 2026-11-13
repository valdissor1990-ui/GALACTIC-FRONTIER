shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// SC-inspired detail textures in-shader: panels, rivets, wear, window strips.
// No external bitmaps required.

uniform vec4 albedo_color : source_color = vec4(0.14, 0.20, 0.28, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.78;
uniform float roughness : hint_range(0.0, 1.0) = 0.34;
uniform vec4 rim_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.85;
uniform float panel_scale : hint_range(1.0, 40.0) = 12.0;
uniform float panel_contrast : hint_range(0.0, 1.0) = 0.22;
uniform float wear_amount : hint_range(0.0, 1.0) = 0.35;
uniform float rivet_amount : hint_range(0.0, 1.0) = 0.55;
uniform float window_emissive : hint_range(0.0, 2.0) = 0.85;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 0.45, 0.15, 1.0);
uniform float heat : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * panel_scale;
	vec2 cell = floor(uv);
	vec2 g = fract(uv);

	// Panel seams
	float edge = step(0.92, max(g.x, g.y));
	float panel = 1.0 - edge * panel_contrast;

	// Micro rivets along panel borders
	float rivet_line = max(
		smoothstep(0.04, 0.0, abs(g.x - 0.5)) * step(0.88, g.y),
		smoothstep(0.04, 0.0, abs(g.y - 0.5)) * step(0.88, g.x)
	);
	float rivet = rivet_line * rivet_amount * step(0.35, hash21(cell + 3.1));

	// Wear / soot noise per panel
	float wear = hash21(cell * 1.7) * wear_amount;
	wear *= smoothstep(0.15, 0.85, g.x * g.y);

	// Window strips (emissive "detail texture" layer)
	float win = step(0.42, g.y) * step(g.y, 0.58) * step(0.18, g.x) * step(g.x, 0.82);
	win *= step(0.55, hash21(cell + 9.2));

	vec3 base = albedo_color.rgb * panel;
	base = mix(base, base * 0.55, wear);
	base = mix(base, base * 1.15, rivet * 0.6);
	base = mix(base, hit_color.rgb, hit_flash * 0.75);

	ALBEDO = base;
	METALLIC = metallic * (1.0 - hit_flash * 0.25) * (1.0 - win * 0.8);
	ROUGHNESS = clamp(roughness + edge * 0.12 + wear * 0.25 + hit_flash * 0.2 - rivet * 0.08, 0.05, 1.0);

	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, rim_power);
	vec3 em = rim_color.rgb * fresnel * rim_strength;
	em += hit_color.rgb * hit_flash * (0.6 + fresnel);
	em += vec3(1.0, 0.35, 0.08) * heat * fresnel * 0.8;
	// Cockpit / running-light windows
	em += vec3(0.35, 0.85, 1.15) * win * window_emissive;
	EMISSION = em;
}
