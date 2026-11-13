shader_type canvas_item;

// Approximate gravitational lensing for space scenes.
// Distorts SCREEN_UV toward projected mass centers; optional Einstein-ring boost
// and chromatic fringe. Up to 2 masses (GPU-friendly).

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform vec2 mass0_uv = vec2(0.5, 0.5);
uniform float mass0_strength : hint_range(0.0, 1.0) = 0.0;
uniform float mass0_radius : hint_range(0.02, 0.8) = 0.22;

uniform vec2 mass1_uv = vec2(0.5, 0.5);
uniform float mass1_strength : hint_range(0.0, 1.0) = 0.0;
uniform float mass1_radius : hint_range(0.02, 0.8) = 0.18;

uniform float ring_boost : hint_range(0.0, 2.0) = 0.85;
uniform float chroma : hint_range(0.0, 0.02) = 0.004;
uniform float overall : hint_range(0.0, 1.5) = 1.0;

vec2 lens_offset(vec2 uv, vec2 mass_uv, float strength, float radius) {
	if (strength < 0.001) {
		return vec2(0.0);
	}
	vec2 d = uv - mass_uv;
	// Aspect-correct-ish using uniform circle in UV (good enough for game feel)
	float dist = length(d) + 1e-5;
	float fall = 1.0 - smoothstep(radius * 0.15, radius, dist);
	// 1/r style deflection, soft-clamped
	float deflect = (strength * overall) * fall / (dist * 8.0 + 0.35);
	// Einstein-ring emphasis near characteristic radius
	float ring = exp(-pow((dist - radius * 0.45) * 6.0, 2.0)) * ring_boost * strength;
	deflect += ring * 0.04;
	// Pull toward mass (light bent around)
	return normalize(d) * (-deflect);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = lens_offset(uv, mass0_uv, mass0_strength, mass0_radius);
	off += lens_offset(uv, mass1_uv, mass1_strength, mass1_radius);

	vec2 sample_uv = clamp(uv + off, vec2(0.001), vec2(0.999));

	// Mild spectral split along deflection direction
	vec2 dir = normalize(off + vec2(1e-5));
	vec2 c_off = dir * chroma * length(off) * 40.0;
	float r = texture(screen_texture, clamp(sample_uv + c_off, vec2(0.001), vec2(0.999))).r;
	float g = texture(screen_texture, sample_uv).g;
	float b = texture(screen_texture, clamp(sample_uv - c_off, vec2(0.001), vec2(0.999))).b;

	COLOR = vec4(r, g, b, 1.0);
}
