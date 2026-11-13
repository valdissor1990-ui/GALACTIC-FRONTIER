shader_type sky;

uniform vec3 space_tint : source_color = vec3(0.002, 0.005, 0.014);
uniform float star_density = 190.0;
uniform float star_threshold = 0.985;

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
	float radius = mix(0.10, 0.22, hash_cell(cell + vec3(19.1, 7.7, 3.2)));
	float distance_to_center = length(local_position);
	float star_shape = 1.0 - smoothstep(radius * 0.22, radius, distance_to_center);
	float star = step(star_threshold, seed) * star_shape;
	float brightness = mix(0.32, 1.35, hash_cell(cell + vec3(2.2, 13.4, 8.8)));
	COLOR = space_tint + vec3(0.62, 0.76, 1.0) * star * brightness;
}
