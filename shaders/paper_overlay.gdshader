shader_type canvas_item;

uniform float paper_grain_strength : hint_range(0.0, 0.15) = 0.045;
uniform float vignette_strength : hint_range(0.0, 0.5) = 0.18;
uniform vec4 paper_tint : source_color = vec4(0.965, 0.945, 0.906, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	// Cold-press watercolor paper grain
	float n1 = noise(uv * 320.0);
	float n2 = noise(uv * 95.0);
	float grain = (n1 * 0.65 + n2 * 0.35) - 0.5;

	// Soft deckled paper margin vignette at screen edges
	vec2 d = abs(uv - vec2(0.5)) * 2.0;
	float edge_dist = max(d.x, d.y);
	float edge_wobble = noise(uv * 28.0) * 0.06;
	float border_fade = smoothstep(0.84, 1.02, edge_dist + edge_wobble);

	vec3 border_color = paper_tint.rgb * 0.94;
	float alpha = clamp(abs(grain) * paper_grain_strength * 2.2 + border_fade * vignette_strength, 0.0, 0.35);
	vec3 final_rgb = mix(vec3(0.52, 0.43, 0.34), border_color, border_fade);

	COLOR = vec4(final_rgb, alpha);
}

