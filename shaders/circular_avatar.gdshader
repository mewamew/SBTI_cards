shader_type canvas_item;

uniform float border_width : hint_range(0.0, 0.5) = 0.05;
uniform vec4 border_color : source_color = vec4(0.8, 0.7, 0.5, 1.0);
uniform float smoothing : hint_range(0.001, 0.1) = 0.02;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);

	float circle_mask = 1.0 - smoothstep(0.5 - smoothing, 0.5, dist);
	float border_mask = smoothstep(0.5 - border_width - smoothing, 0.5 - border_width, dist);
	border_mask *= 1.0 - smoothstep(0.5 - smoothing, 0.5, dist);

	vec4 tex = texture(TEXTURE, UV);
	vec3 final_color = mix(tex.rgb, border_color.rgb, border_mask);
	COLOR = vec4(final_color, tex.a * circle_mask);
}
