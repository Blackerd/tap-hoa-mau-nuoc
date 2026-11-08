shader_type canvas_item;

uniform float reveal_radius : hint_range(0.1, 1.3) = 0.48;
uniform vec2 center_uv = vec2(0.45, 0.52);
uniform vec4 paper_bg : source_color = vec4(0.965, 0.945, 0.906, 1.0);
uniform vec4 pigment_rim : source_color = vec4(0.82, 0.62, 0.38, 0.35);

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float fbm_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 aspect_uv = (UV - center_uv) * vec2(1.55, 1.0);
	float dist = length(aspect_uv);
	float organic = (fbm_noise(UV * 14.0) - 0.5) * 0.09 + (fbm_noise(UV * 37.0) - 0.5) * 0.04;
	float d = dist + organic;

	// Outside reveal_radius: soft cream paper wash so outer area looks like pencil sketch on white paper
	float sketch_mask = smoothstep(reveal_radius - 0.04, reveal_radius + 0.06, d);
	// Watercolor wet-on-wet pigment ring right at the boundary
	float rim_band = 1.0 - smoothstep(0.0, 0.045, abs(d - reveal_radius));

	vec3 col = mix(pigment_rim.rgb, paper_bg.rgb, sketch_mask);
	float alpha = clamp(sketch_mask * 0.72 + rim_band * pigment_rim.a, 0.0, 0.78);
	COLOR = vec4(col, alpha);
}

