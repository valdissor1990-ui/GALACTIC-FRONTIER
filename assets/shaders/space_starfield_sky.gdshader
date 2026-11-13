shader_type sky;

// Optimized procedural sky: 2 star layers + nebula (was 3 full hash layers).
// Sky runs on a low-res cubemap; still keep ALU modest.

uniform vec3 space_color : source_color = vec3(0.003, 0.008, 0.025);
uniform vec3 nebula_a : source_color = vec3(0.06, 0.09, 0.24);
uniform vec3 nebula_b : source_color = vec3(0.14, 0.04, 0.09);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.4;
uniform float star_density : hint_range(0.5, 4.0) = 1.75;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.15;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.2;

float hash13(vec3 p) {
	// Single multiply hash — cheaper than multi-step fract chain
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float star_layer(vec3 dir, float scale, float threshold) {
	vec3 ip = floor(dir * scale);
	float h = hash13(ip);
	float spark = max(h - threshold, 0.0) / max(1.0 - threshold, 1e-4);
	spark *= spark;
	// Giant without second smoothstep
	float giant = step(0.997, h) * 2.2;
	return spark + giant;
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

	// Two layers instead of three — similar density, less ALU
	float s_near = star_layer(dir, 140.0 * star_density, 0.93);
	float s_far = star_layer(dir + vec3(3.1, 1.7, 2.3), 420.0 * star_density, 0.975);
	col += vec3((s_near * 0.7 + s_far * 1.35) * star_brightness);

	col += vec3(0.05, 0.07, 0.12) * exp(-abs(ny) * 2.5) * 0.045;
	COLOR = col;
}
