shader_type canvas_item;
render_mode blend_add;

uniform vec4 beam_color : source_color = vec4(1.0, 0.82, 0.58, 1.0);
uniform float beam_alpha : hint_range(0.0, 0.4) = 0.10;
uniform float focus_strength : hint_range(0.0, 0.3) = 0.07;
uniform float shimmer_strength : hint_range(0.0, 0.5) = 0.16;
uniform float drift_speed : hint_range(0.0, 1.0) = 0.10;
uniform float pulse_boost : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += noise(p) * amplitude;
		p = p * 2.01 + vec2(19.3, 11.7);
		amplitude *= 0.5;
	}
	return value;
}

float beam_mask(vec2 uv, vec2 origin, vec2 direction, float width, float softness) {
	vec2 dir = normalize(direction);
	vec2 normal = vec2(-dir.y, dir.x);
	vec2 rel = uv - origin;
	float along = dot(rel, dir);
	float across = abs(dot(rel, normal));
	float core = 1.0 - smoothstep(width, width + softness, across);
	float head = smoothstep(-0.03, 0.10, along);
	float tail = 1.0 - smoothstep(0.18, 1.08, along);
	return core * head * tail;
}

void fragment() {
	vec2 uv = UV;
	float flow = TIME * drift_speed;
	float field = fbm(vec2(uv.x * 4.5 - flow * 0.35, uv.y * 2.4 + flow * 0.18));
	float flicker = 0.92 + sin(TIME * 0.62) * 0.05 + (field - 0.5) * shimmer_strength * 0.30;
	float pulse = 1.0 + pulse_boost * 1.7;

	float left_beam = beam_mask(
		uv + vec2(field * 0.012, 0.0),
		vec2(0.15, -0.08),
		vec2(0.22, 1.0),
		0.14 + field * 0.028,
		0.22
	);
	float right_beam = beam_mask(
		uv + vec2(-field * 0.014, 0.0),
		vec2(0.83, -0.06),
		vec2(-0.20, 1.0),
		0.16 + field * 0.032,
		0.24
	);
	float center_beam = beam_mask(
		uv,
		vec2(0.50, -0.14),
		vec2(0.04, 1.0),
		0.12,
		0.30
	) * 0.92;

	float floor_focus = pow(max(1.0 - length(vec2((uv.x - 0.5) * 1.15, (uv.y - 0.46) * 1.75)), 0.0), 3.2);
	float beam_mix = left_beam * 0.95 + right_beam * 0.78 + center_beam;
	float alpha = beam_mix * beam_alpha * flicker * pulse * 1.32;
	alpha += floor_focus * focus_strength * (1.05 + pulse_boost * 1.10);
	float edge_fade_x = smoothstep(0.0, 0.12, uv.x) * smoothstep(0.0, 0.12, 1.0 - uv.x);
	float edge_fade_y = smoothstep(0.0, 0.16, uv.y) * smoothstep(0.0, 0.18, 1.0 - uv.y);
	float center_falloff = smoothstep(1.12, 0.10, uv.y);
	alpha *= edge_fade_x * edge_fade_y * center_falloff;

	vec3 color = beam_color.rgb * alpha;
	COLOR = vec4(color, alpha);
}
