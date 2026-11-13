shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Fully procedural gas-giant albedo — no external textures.

uniform vec3 band_color_a : source_color = vec3(0.12, 0.22, 0.38);
uniform vec3 band_color_b : source_color = vec3(0.22, 0.35, 0.48);
uniform vec3 band_color_c : source_color = vec3(0.35, 0.28, 0.22);
uniform vec3 storm_color : source_color = vec3(0.55, 0.32, 0.18);
uniform float band_scale : hint_range(2.0, 24.0) = 10.0;
uniform float band_warp : hint_range(0.0, 2.0) = 0.65;
uniform float storm_amount : hint_range(0.0, 1.0) = 0.35;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.88;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.12;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.05 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	// Spherical-ish UV from normals (stable, no seam fighting on simple spheres)
	vec3 n = normalize(NORMAL);
	float lat = n.y;
	float lon = atan(n.z, n.x);

	float warp = fbm(vec2(lon * 1.5, lat * 3.0) * 1.2) * band_warp;
	float bands = sin((lat * band_scale + warp) * 3.14159);
	bands = bands * 0.5 + 0.5;
	float detail = fbm(vec2(lon * 4.0, lat * 8.0));
	bands = mix(bands, detail, 0.35);

	vec3 col = mix(band_color_a, band_color_b, bands);
	col = mix(col, band_color_c, smoothstep(0.55, 0.9, detail) * 0.45);

	// Storm ovals
	float storm = fbm(vec2(lon * 2.5 + 3.0, lat * 5.0 - 1.0));
	storm = smoothstep(0.62, 0.78, storm) * storm_amount;
	col = mix(col, storm_color, storm);

	// Pole darkening
	float poles = smoothstep(0.55, 0.95, abs(lat));
	col *= 1.0 - poles * 0.25;

	ALBEDO = col;
	ROUGHNESS = roughness_val;
	METALLIC = 0.05;
	EMISSION = col * emission_strength * (0.4 + storm * 0.8);
}
