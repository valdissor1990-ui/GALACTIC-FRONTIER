shader_type sky;

uniform vec3 space_tint : source_color = vec3(0.002, 0.005, 0.014);
uniform float star_density = 245.0;
uniform float star_threshold = 0.994;

float hash_cell(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 direction = normalize(EYEDIR);
	vec3 grid = direction * star_density;
	vec3 cell = floor(grid);
	vec3 local_position = fract(grid) - vec3(0.5);
	float seed = hash_cell(cell);
	float radius = mix(0.018, 0.052, hash_cell(cell + vec3(19.1, 7.7, 3.2)));
	float distance_to_center = length(local_position);
	float star_shape = 1.0 - smoothstep(radius * 0.22, radius, distance_to_center);
	float star = step(star_threshold, seed) * star_shape;
	float brightness = mix(0.32, 1.35, hash_cell(cell + vec3(2.2, 13.4, 8.8)));
	float galactic_band = pow(max(0.0, 1.0 - abs(direction.y + 0.12)), 9.0);
	vec3 faint_nebula = vec3(0.004, 0.009, 0.022) * galactic_band;
	COLOR = space_tint + faint_nebula + vec3(0.58, 0.74, 0.98) * star * brightness;
}
