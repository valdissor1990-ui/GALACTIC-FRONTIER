shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 low_color : source_color = vec3(0.18, 0.12, 0.09);
uniform vec3 mid_color : source_color = vec3(0.35, 0.24, 0.16);
uniform vec3 high_color : source_color = vec3(0.55, 0.5, 0.45);
uniform vec3 ice_color : source_color = vec3(0.7, 0.78, 0.85);
uniform float ice_caps : hint_range(0.0, 1.0) = 0.35;
uniform float crater_amount : hint_range(0.0, 1.0) = 0.4;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.92;
uniform float emission_strength : hint_range(0.0, 0.5) = 0.05;

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
		p = p * 2.1 + 11.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float lat = n.y;
	// Triplanar-ish from normal directions
	vec2 uv_xy = n.xy * 3.0;
	vec2 uv_yz = n.yz * 3.0;
	float h = fbm(uv_xy * 2.0) * 0.6 + fbm(uv_yz * 2.5 + 4.0) * 0.4;

	vec3 col = mix(low_color, mid_color, smoothstep(0.3, 0.55, h));
	col = mix(col, high_color, smoothstep(0.6, 0.85, h));

	// Crater-like dark spots
	float cr = fbm(n.xz * 8.0 + 2.0);
	cr = smoothstep(0.7, 0.85, cr) * crater_amount;
	col *= 1.0 - cr * 0.35;

	// Polar ice
	float ice = smoothstep(1.0 - ice_caps, 1.0, abs(lat));
	col = mix(col, ice_color, ice);

	ALBEDO = col;
	ROUGHNESS = mix(roughness_base, 0.55, ice);
	METALLIC = 0.02;
	EMISSION = col * emission_strength;
}
