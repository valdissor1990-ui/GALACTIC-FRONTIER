shader_type sky;

// Compact point stars: each occupied cell contains one small radial star.
uniform vec3 space_color : source_color = vec3(0.003, 0.008, 0.025);
uniform vec3 nebula_a : source_color = vec3(0.06, 0.09, 0.24);
uniform vec3 nebula_b : source_color = vec3(0.14, 0.04, 0.09);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.4;
uniform float star_density : hint_range(0.5, 4.0) = 1.75;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.15;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.2;

float hash13(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float star_layer(vec3 dir, float scale, float threshold) {
	vec3 cell = floor(dir * scale);
	vec3 local_pos = fract(dir * scale);
	float seed = hash13(cell);
	if (seed < threshold) {
		return 0.0;
	}
	vec3 center = vec3(
		hash13(cell + vec3(17.1, 3.7, 9.2)),
		hash13(cell + vec3(5.3, 29.1, 1.7)),
		hash13(cell + vec3(11.9, 7.4, 31.3))
	);
	float giant = step(0.997, seed);
	float radius = mix(0.025, 0.055, hash13(cell + vec3(2.4, 19.7, 4.1)));
	radius = mix(radius, 0.12, giant);
	float d = length(local_pos - center);
	float core = 1.0 - smoothstep(radius * 0.28, radius, d);
	float halo = 1.0 - smoothstep(radius, radius * 2.8, d);
	return (core + halo * 0.12) * mix(0.7, 1.0, seed) * mix(1.0, 2.2, giant);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 col = space_color;
	float ny = dir.y;
	float band = 0.5 + 0.5 * sin(ny * 3.1 + dir.x * 1.7);
	float band2 = 0.5 + 0.5 * sin(dir.z * 2.4 - ny * 2.0);
	col = mix(col, mix(nebula_a, nebula_b, band2), nebula_strength * band * 0.55);
	float dust = exp(-abs(ny + 0.05) * 3.5) * dust_strength;
	col += vec3(0.07, 0.06, 0.09) * dust;
	float s_near = star_layer(dir, 140.0 * star_density, 0.93);
	float s_far = star_layer(dir + vec3(3.1, 1.7, 2.3), 420.0 * star_density, 0.975);
	col += vec3((s_near * 0.7 + s_far * 1.35) * star_brightness);
	col += vec3(0.05, 0.07, 0.12) * exp(-abs(ny) * 2.5) * 0.045;
	COLOR = col;
}
