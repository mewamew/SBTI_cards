shader_type canvas_item;

uniform float edge_fade : hint_range(0.05, 0.35) = 0.18;
uniform float bottom_fade : hint_range(0.02, 0.35) = 0.08;
uniform float center_boost : hint_range(0.0, 1.0) = 0.28;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float left = smoothstep(0.0, edge_fade, UV.x);
	float right = 1.0 - smoothstep(1.0 - edge_fade, 1.0, UV.x);
	float top = smoothstep(0.0, edge_fade * 0.95, UV.y);
	float bottom = 1.0 - smoothstep(1.0 - bottom_fade, 1.0, UV.y);
	float rect_mask = min(min(left, right), min(top, bottom));

	vec2 center_uv = (UV - vec2(0.5, 0.48)) / vec2(0.50, 0.56);
	float radial = 1.0 - smoothstep(0.72, 1.0, length(center_uv));
	float final_alpha = tex.a * clamp(max(rect_mask, radial * center_boost), 0.0, 1.0);

	COLOR = vec4(tex.rgb, final_alpha);
}
