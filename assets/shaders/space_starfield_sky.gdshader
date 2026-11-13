shader_type sky;

// Procedural deep-space sky for GALACTIC FRONTIER (no external textures).
// Layered stars + soft nebula tint. Cheap enough for Forward+ desktop.

uniform vec3 space_color : source_color = vec3(0.004, 0.01, 0.03);
uniform vec3 nebula_a : source_color = vec3(0.05, 0.08, 0.22);
uniform vec3 nebula_b : source_color = vec3(0.12, 0.03, 0.08);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.35;
uniform float star_density : hint_range(0.5, 4.0) = 1.6;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float stars(vec3 dir, float scale, float threshold) {
	vec3 p = dir * scale;
	vec3 ip = floor(p);
	float h = hash(ip);
	float spark = smoothstep(threshold, 1.0, h);
	// Tiny core brightening
	return spark * spark;
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	// Base void
	vec3 col = space_color;

	// Soft nebula bands (view-dependent, no 3D noise texture required)
	float band = 0.5 + 0.5 * sin(dir.y * 3.1 + dir.x * 1.7);
	float band2 = 0.5 + 0.5 * sin(dir.z * 2.4 - dir.y * 2.0);
	vec3 nebula = mix(nebula_a, nebula_b, band2);
	col = mix(col, nebula, nebula_strength * band * 0.55);

	// Star layers
	float s1 = stars(dir, 120.0 * star_density, 0.92);
	float s2 = stars(dir + vec3(3.1, 1.7, 2.3), 280.0 * star_density, 0.965);
	float s3 = stars(dir + vec3(7.2, 4.4, 0.9), 600.0 * star_density, 0.985);
	float star_light = (s1 * 0.55 + s2 * 0.9 + s3 * 1.4) * star_brightness;
	col += vec3(star_light);

	// Subtle horizon-ish brightening toward ecliptic for readable navigation
	float ecliptic = exp(-abs(dir.y) * 2.5) * 0.04;
	col += vec3(0.05, 0.07, 0.12) * ecliptic;

	COLOR = col;
}
