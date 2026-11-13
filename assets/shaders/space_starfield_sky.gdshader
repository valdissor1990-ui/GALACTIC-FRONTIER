shader_type sky;

// Procedural deep-space sky — layered stars, nebula, soft dust band.

uniform vec3 space_color : source_color = vec3(0.003, 0.008, 0.025);
uniform vec3 nebula_a : source_color = vec3(0.06, 0.09, 0.24);
uniform vec3 nebula_b : source_color = vec3(0.14, 0.04, 0.09);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.4;
uniform float star_density : hint_range(0.5, 4.0) = 1.75;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.15;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.2;

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
	// Rare brighter cores
	float giant = smoothstep(0.995, 1.0, h);
	return spark * spark + giant * 2.5;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 col = space_color;

	float band = 0.5 + 0.5 * sin(dir.y * 3.1 + dir.x * 1.7);
	float band2 = 0.5 + 0.5 * sin(dir.z * 2.4 - dir.y * 2.0);
	vec3 nebula = mix(nebula_a, nebula_b, band2);
	col = mix(col, nebula, nebula_strength * band * 0.55);

	// Galactic dust plane
	float dust = exp(-abs(dir.y + 0.05) * 3.5) * dust_strength;
	col += vec3(0.07, 0.06, 0.09) * dust;

	float s1 = stars(dir, 120.0 * star_density, 0.915);
	float s2 = stars(dir + vec3(3.1, 1.7, 2.3), 280.0 * star_density, 0.96);
	float s3 = stars(dir + vec3(7.2, 4.4, 0.9), 620.0 * star_density, 0.984);
	float star_light = (s1 * 0.5 + s2 * 0.95 + s3 * 1.5) * star_brightness;
	col += vec3(star_light);

	float ecliptic = exp(-abs(dir.y) * 2.5) * 0.045;
	col += vec3(0.05, 0.07, 0.12) * ecliptic;

	COLOR = col;
}
