shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.22, 0.2, 0.18);
uniform vec3 dark_color : source_color = vec3(0.1, 0.09, 0.08);
uniform vec3 highlight_color : source_color = vec3(0.32, 0.3, 0.26);
uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
uniform float roughness_val : hint_range(0.5, 1.0) = 0.94;
uniform float crater_amount : hint_range(0.0, 1.0) = 0.45;

float hash13(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1, 0, 0));
	float n010 = hash13(i + vec3(0, 1, 0));
	float n110 = hash13(i + vec3(1, 1, 0));
	float n001 = hash13(i + vec3(0, 0, 1));
	float n101 = hash13(i + vec3(1, 0, 1));
	float n011 = hash13(i + vec3(0, 1, 1));
	float n111 = hash13(i + vec3(1, 1, 1));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

float fbm3(vec3 p) {
	return 0.5 * vnoise(p) + 0.3 * vnoise(p * 2.17) + 0.2 * vnoise(p * 4.41);
}

void fragment() {
	vec3 p = NORMAL * noise_scale;
	float n = fbm3(p);
	float detail = fbm3(p * 3.1 + 2.7);
	// Soft crater pits
	float pits = smoothstep(0.72, 0.95, vnoise(p * 1.4 + 5.0));
	pits *= crater_amount;
	vec3 col = mix(dark_color, base_color, n);
	col = mix(col, highlight_color, smoothstep(0.62, 0.92, detail) * 0.45);
	col = mix(col, dark_color * 0.55, pits);
	ALBEDO = col;
	ROUGHNESS = clamp(roughness_val - detail * 0.08 + pits * 0.12, 0.5, 1.0);
	METALLIC = 0.05 + smoothstep(0.8, 1.0, detail) * 0.06;
}
