shader_type canvas_item;

uniform vec4 haze_tint : source_color = vec4(0.92, 0.76, 0.48, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.16, 0.06, 0.04, 1.0);
uniform float haze_strength : hint_range(0.0, 0.4) = 0.10;
uniform float glow_strength : hint_range(0.0, 0.4) = 0.13;
uniform float vignette_strength : hint_range(0.0, 0.5) = 0.16;
uniform float grain_strength : hint_range(0.0, 0.12) = 0.035;
uniform float motion_speed : hint_range(0.0, 1.0) = 0.14;

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
	float amplitude = 0.55;
	for (int i = 0; i < 4; i++) {
		value += noise(p) * amplitude;
		p = p * 2.03 + vec2(17.2, 9.4);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 uv = UV;
	vec2 centered = uv - 0.5;
	float radial = 1.0 - clamp(length(vec2(centered.x * 1.08, centered.y * 1.34)) * 1.26, 0.0, 1.0);

	float haze = fbm(uv * 3.6 + vec2(TIME * motion_speed, -TIME * motion_speed * 0.58));
	haze += fbm(uv * 7.8 - vec2(TIME * motion_speed * 0.48, TIME * motion_speed * 0.21)) * 0.42;
	haze = clamp(haze * 0.72, 0.0, 1.0);

	float warm_breath = 0.92 + sin(TIME * 0.48 + uv.x * 4.2 + uv.y * 3.3) * 0.08;
	float center_glow = pow(radial, 2.4) * glow_strength * warm_breath;
	float sweep = sin((uv.x * 6.8 + uv.y * 5.1) - TIME * 0.26) * 0.5 + 0.5;
	sweep = smoothstep(0.58, 0.98, sweep) * radial;
	float ember = pow(max(1.0 - length(vec2((uv.x - 0.5) * 1.12, (uv.y - 0.58) * 1.95)), 0.0), 3.4);

	float vignette = smoothstep(0.22, 0.94, length(vec2(centered.x * 1.02, centered.y * 1.30)));
	float grain = noise(uv * 22.0 + vec2(TIME * 0.02, -TIME * 0.015)) - 0.5;

	vec3 color = base.rgb;
	color += haze_tint.rgb * ((haze * haze_strength) * (0.28 + radial * 0.72));
	color += haze_tint.rgb * (center_glow * 0.95);
	color += vec3(0.95, 0.86, 0.72) * (sweep * 0.055);
	color += vec3(0.92, 0.62, 0.26) * (ember * glow_strength * 0.52);
	color = mix(color, color * shadow_tint.rgb, vignette * vignette_strength);
	color += vec3(grain) * grain_strength * (0.18 + radial * 0.82);

	COLOR = vec4(clamp(color, 0.0, 1.0), base.a);
}
