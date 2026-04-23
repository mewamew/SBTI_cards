// ═══════════════════════════════════════════════════════════════
// SBTI 全局暗角/氛围着色器
// ═══════════════════════════════════════════════════════════════
// 视觉效果：
//   - 暗角效果（画面边缘变暗，聚焦中央）
//   - 微弱噪点纹理叠加（打破纯色死板）
//   - 暖冷偏移：翻牌前冷调，翻出伙伴后暖调脉冲
//   - 呼吸式暗角强度微变（氛围感）
//
// 使用方式：
//   1. 在场景最底层创建全屏 ColorRect
//   2. 附加此着色器材质
//   3. 常驻运行，通过 warmth 参数响应游戏事件
// ═══════════════════════════════════════════════════════════════

shader_type canvas_item;
render_mode blend_mix;

// ── Uniform 参数 ──

// 暗角强度：0 = 无暗角，1 = 极强暗角
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;

// 暖冷偏移：-1 = 冷调（蓝偏），0 = 中性，1 = 暖调（橙偏）
uniform float warmth : hint_range(-1.0, 1.0) = 0.0;

// 噪点透明度
uniform float noise_opacity : hint_range(0.0, 0.1) = 0.03;

// 噪点缩放
uniform float noise_scale : hint_range(1.0, 50.0) = 15.0;

// 暗角椭圆度（1.0 = 圆形，<1 = 横椭圆，>1 = 竖椭圆）
uniform float vignette_aspect : hint_range(0.5, 2.0) = 1.4;

// 暗角柔和度
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.35;

// ── 简易伪随机函数 ──

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

// ── 片段着色器 ──

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	// ── 暗角计算 ──
	vec2 center = vec2(0.5, 0.5);
	vec2 delta = UV - center;

	// 考虑椭圆度的距离计算
	delta.x *= vignette_aspect;
	float dist = length(delta);

	// 平滑暗角：中心完全透明，边缘变暗
	float vignette = smoothstep(0.5, 0.5 - vignette_softness, dist);
	vignette *= vignette_intensity;

	// 微弱呼吸效果：暗角强度随时间轻微波动
	float breath = sin(TIME * 0.5) * 0.03 + 1.0;
	vignette *= breath;

	// ── 暖冷色调偏移 ──
	vec3 tint = vec3(0.0);
	if (warmth > 0.0) {
		// 暖调：橙黄色偏移
		tint = vec3(0.15, 0.08, 0.0) * warmth;
	} else {
		// 冷调：蓝青色偏移
		tint = vec3(0.0, 0.03, 0.12) * abs(warmth);
	}

	// 暖冷偏移强度：越靠近边缘越明显
	float tint_factor = vignette * 0.5 + dist * 0.3;

	// ── 噪点纹理叠加 ──
	float n = noise(UV * noise_scale + vec2(TIME * 0.1, TIME * 0.07));
	// 时间变化的噪点偏移
	float n2 = noise(UV * noise_scale * 0.7 - vec2(TIME * 0.05, TIME * 0.12));
	float grain = mix(n, n2, 0.5);

	// 噪点只在暗角区域明显
	float grain_visibility = noise_opacity * (0.3 + vignette * 0.7);

	// ── 组合最终颜色 ──
	vec3 final_rgb = base_color.rgb;

	// 应用暗角（变暗）
	final_rgb *= (1.0 - vignette);

	// 应用暖冷色调
	final_rgb += tint * tint_factor;

	// 应用噪点
	final_rgb += vec3(grain - 0.5) * grain_visibility;

	// 边缘额外加深：纯黑渐变
	float edge_darken = smoothstep(0.48, 0.5, dist) * vignette_intensity * 0.3;
	final_rgb *= (1.0 - edge_darken);

	COLOR = vec4(clamp(final_rgb, 0.0, 1.0), base_color.a);
}
