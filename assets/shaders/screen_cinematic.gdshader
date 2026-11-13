shader_type canvas_item;

// Single-pass screen post for space scenes.
// Cost target: one screen texture sample + light ALU (no multi-pass blur).

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.55;
uniform float vignette_softness : hint_range(0.2, 2.0) = 0.85;
uniform float chroma_strength : hint_range(0.0, 0.01) = 0.0022;
uniform float contrast : hint_range(0.8, 1.3) = 1.04;
uniform float saturation : hint_range(0.5, 1.5) = 1.06;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - vec2(0.5);
	float dist = length(center);

	// Mild radial chromatic aberration (reads 3 times — keep chroma tiny)
	vec2 offset = normalize(center + vec2(1e-5)) * chroma_strength * dist;
	float r = texture(screen_texture, uv + offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - offset).b;
	vec3 col = vec3(r, g, b);

	// Contrast around mid-grey
	col = (col - 0.5) * contrast + 0.5;

	// Saturation
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation);

	// Vignette
	float vig = 1.0 - smoothstep(vignette_softness * 0.55, vignette_softness, dist * vignette_strength + dist);
	col *= vig;

	COLOR = vec4(col, 1.0);
}
