// ═══════════════════════════════════════════════════════════════
// SBTI 命运揭晓光效着色器
// ═══════════════════════════════════════════════════════════════
// 视觉效果：
//   伙伴模式 — 暖金色中心脉冲 + 向外扩散光波 + 微弱噪点闪烁
//   敌人模式 — 冷红色边缘收缩 + 中心闪光爆发 + 扫描线闪烁
//
// 使用方式：
//   1. 创建一个 ColorRect 作为翻牌卡的子节点，z_index 高于内容
//   2. 附加此着色器材质
//   3. 用 Tween 驱动 glow_intensity 从 0→1→0
//   4. 设置 is_ally 和 glow_color
// ═══════════════════════════════════════════════════════════════

shader_type canvas_item;
render_mode blend_add;

// ── Uniform 参数 ──

// 光效颜色：伙伴 #4a9eff / 敌人 #ff3a3a
uniform vec4 glow_color : source_color = vec4(0.29, 0.62, 1.0, 1.0);

// 光效总强度：0 = 不可见，1 = 最强
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;

// 光环扩散半径（0.5 = 中心到边缘的一半）
uniform float glow_radius : hint_range(0.1, 1.0) = 0.5;

// 伙伴模式(1.0) / 敌人模式(0.0)
uniform float is_ally : hint_range(0.0, 1.0) = 1.0;

// 噪点动画速度
uniform float noise_speed : hint_range(0.0, 2.0) = 0.3;

// 扫描线数量（敌人模式）
uniform float scan_line_count : hint_range(0.0, 20.0) = 8.0;

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
	vec2 center = vec2(0.5, 0.5);
	vec2 delta = UV - center;
	float dist = length(delta);
	float angle = atan(delta.y, delta.x);
	float source_alpha = texture(TEXTURE, UV).a;

	vec4 result = vec4(0.0);

	if (is_ally > 0.5) {
		// ── 伙伴模式：暖金色中心脉冲 + 向外扩散光波 ──

		// 中心脉冲：从中心向外的径向渐变
		float pulse = smoothstep(glow_radius, 0.0, dist);
		pulse = pow(pulse, 1.5);  // 让中心更集中

		// 扩散光波：2层同心圆波纹
		float wave1 = smoothstep(0.02, 0.0, abs(dist - glow_radius * 0.4));
		float wave2 = smoothstep(0.02, 0.0, abs(dist - glow_radius * 0.7));
		float waves = (wave1 + wave2 * 0.6);

		// 噪点闪烁：给光效增加微弱的有机感
		float n = noise(UV * 6.0 + vec2(TIME * noise_speed * 0.7, TIME * noise_speed * 0.4));
		float flicker = 0.85 + n * 0.15;

		// 组合
		float ally_intensity = (pulse * 0.7 + waves * 0.5) * flicker;
		result = glow_color * ally_intensity;

	} else {
		// ── 敌人模式：冷红色边缘收缩 + 中心闪光 + 扫描线 ──

		// 边缘收缩光：从边缘向中心的径向渐变（反转方向）
		float edge_glow = smoothstep(0.0, glow_radius, dist);
		edge_glow = pow(edge_glow, 1.2);

		// 中心闪光爆发
		float center_flash = smoothstep(glow_radius * 0.3, 0.0, dist);
		center_flash = pow(center_flash, 2.0);

		// 扫描线：水平条纹闪烁
		float scan = sin(UV.y * scan_line_count * 3.14159 + TIME * 8.0);
		scan = smoothstep(0.3, 0.8, scan) * 0.3;

		// 闪电效果：基于角度的随机亮线
		float lightning_noise = noise(vec2(angle * 3.0, TIME * 3.0));
		float lightning = smoothstep(0.75, 0.95, lightning_noise);
		lightning *= smoothstep(glow_radius * 0.2, glow_radius * 0.8, dist);

		// 组合
		float enemy_intensity = (edge_glow * 0.5 + center_flash * 0.8 + scan + lightning * 0.6);
		result = glow_color * enemy_intensity;
	}

	// 全局强度控制
	result *= glow_intensity * source_alpha;

	// 边缘淡出：避免光效硬切到透明
	float fade = smoothstep(1.0, 0.4, dist);
	result.a *= fade;

	COLOR = result;
}
