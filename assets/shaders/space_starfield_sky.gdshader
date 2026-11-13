shader_type sky;

// Multi-layer procedural starfield — sprint densify mid layer + giants.

uniform vec3 space_color : source_color = vec3(0.002, 0.006, 0.02);
uniform vec3 nebula_a : source_color = vec3(0.05, 0.08, 0.28);
uniform vec3 nebula_b : source_color = vec3(0.18, 0.04, 0.1);
uniform vec3 nebula_c : source_color = vec3(0.03, 0.14, 0.12);
uniform float nebula_strength : hint_range(0.0, 1.5) = 0.55;
uniform float star_density : hint_range(0.5, 5.0) = 2.2;
uniform float star_brightness : hint_range(0.0, 2.5) = 1.25;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.28;
uniform float galactic_strength : hint_range(0.0, 1.0) = 0.35;

float hash13(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

float fbm2(vec3 p) {
	return 0.55 * vnoise(p) + 0.3 * vnoise(p * 2.1 + 3.7) + 0.15 * vnoise(p * 4.3 - 1.9);
}

vec3 star_layer(vec3 dir, float scale, float threshold) {
	vec3 cell = floor(dir * scale);
	vec3 local_pos = fract(dir * scale);
	float seed = hash13(cell);
	if (seed < threshold) {
		return vec3(0.0);
	}
	vec3 center = vec3(
		hash13(cell + vec3(17.1, 3.7, 9.2)),
		hash13(cell + vec3(5.3, 29.1, 1.7)),
		hash13(cell + vec3(11.9, 7.4, 31.3))
	);
	float giant = step(0.9955, seed);
	float radius = mix(0.018, 0.048, hash13(cell + vec3(2.4, 19.7, 4.1)));
	radius = mix(radius, 0.13, giant);
	float d = length(local_pos - center);
	float core = 1.0 - smoothstep(radius * 0.22, radius, d);
	float halo = 1.0 - smoothstep(radius, radius * 3.6, d);
	float inten = (core + halo * 0.16) * mix(0.7, 1.1, seed) * mix(1.0, 2.8, giant);
	float tint_roll = hash13(cell + vec3(8.2, 14.0, 3.3));
	vec3 tint = mix(vec3(0.92, 0.95, 1.0), vec3(1.0, 0.88, 0.72), step(0.8, tint_roll));
	tint = mix(tint, vec3(0.72, 0.84, 1.2), step(0.93, tint_roll));
	tint = mix(tint, vec3(1.15, 0.78, 0.52), giant * step(0.45, tint_roll));
	return tint * inten;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 col = space_color;

	float n1 = fbm2(dir * 2.4 + vec3(0.0, 0.3, 0.0));
	float n2 = fbm2(dir * 3.6 + vec3(4.1, -1.2, 2.0));
	float n3 = fbm2(dir.yzx * 1.8 - 2.5);
	col = mix(col, nebula_a, nebula_strength * smoothstep(0.42, 0.78, n1) * 0.55);
	col = mix(col, nebula_b, nebula_strength * smoothstep(0.48, 0.82, n2) * 0.4);
	col = mix(col, nebula_c, nebula_strength * smoothstep(0.55, 0.88, n3) * 0.28);

	float plane = exp(-pow(dir.y * 2.8, 2.0));
	float plane_noise = fbm2(dir * vec3(6.0, 1.2, 6.0) + 9.0);
	col += vec3(0.06, 0.07, 0.12) * plane * plane_noise * galactic_strength;

	float dust = exp(-abs(dir.y + 0.04) * 3.2) * dust_strength;
	col += vec3(0.08, 0.06, 0.09) * dust * (0.5 + 0.5 * n2);

	// Denser mid layer (lower threshold)
	vec3 s_far = star_layer(dir + vec3(3.1, 1.7, 2.3), 540.0 * star_density, 0.975);
	vec3 s_mid = star_layer(dir + vec3(1.2, -2.4, 0.7), 240.0 * star_density, 0.938);
	vec3 s_near = star_layer(dir, 120.0 * star_density, 0.905);
	col += (s_far * 1.2 + s_mid * 1.05 + s_near * 0.65) * star_brightness;

	col += vec3(0.04, 0.055, 0.09) * exp(-abs(dir.y) * 2.2) * 0.05;
	COLOR = col;
}
