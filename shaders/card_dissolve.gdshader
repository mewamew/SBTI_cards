// ═══════════════════════════════════════════════════════════════
// SBTI 卡牌溶解消逝着色器
// ═══════════════════════════════════════════════════════════════
// 视觉效果：
//   - 噪点纹理驱动的溶解遮罩
//   - 溶解前沿金色发光边缘（与翻牌着色器风格统一）
//   - 从底部向上溶解，像被命运之火吞噬
//   - 溶解完成后卡牌消逝
//
// 使用方式：
//   1. 附加此着色器材质到即将消失的卡牌节点上
//   2. 用 Tween 驱动 dissolve_amount 从 0→1
//   3. 完成后 queue_free 该节点
// ═══════════════════════════════════════════════════════════════

shader_type canvas_item;
render_mode blend_mix;

// ── Uniform 参数 ──

// 溶解进度：0.0 = 完整，1.0 = 完全消逝
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;

// 溶解边缘发光颜色
uniform vec4 edge_color : source_color = vec4(0.84, 0.71, 0.43, 1.0);

// 发光边缘宽度
uniform float edge_width : hint_range(0.01, 0.2) = 0.05;

// 噪点缩放（控制溶解颗粒大小）
uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;

// 溶解方向偏移：0 = 从底部向上，0.5 = 中心向四周，1 = 从顶部向下
uniform float dissolve_direction_bias : hint_range(0.0, 1.0) = 0.0;

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

// 分形布朗运动（FBM）— 更细腻的噪点
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// ── 片段着色器 ──

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	// 生成噪点值
	float n = fbm(UV * noise_scale);

	// 溶解方向偏移：让底部先溶解
	float direction = mix(UV.y, 0.5, dissolve_direction_bias);
	// 将噪点与方向偏移混合，底部值更低 → 先被溶解
	float noise_value = n * 0.7 + direction * 0.3;

	// 溶解阈值
	float threshold = dissolve_amount;

	// 溶解边缘检测
	float edge_dist = noise_value - threshold;
	float is_edge = smoothstep(edge_width, 0.0, edge_dist) * smoothstep(-edge_width * 0.5, 0.0, edge_dist);

	// 已溶解区域
	float is_dissolved = step(noise_value, threshold);

	// ── 发光边缘 ──
	// 溶解前沿的发光效果
	float edge_glow = smoothstep(edge_width * 2.0, 0.0, abs(edge_dist));
	edge_glow *= (1.0 - is_dissolved);  // 已溶解区域不发光

	// 边缘颜色：从边缘色到白色的热力渐变
	vec3 hot_edge = mix(edge_color.rgb, vec3(1.0, 0.95, 0.8), edge_glow * 0.5);

	// ── 组合最终颜色 ──
	vec3 final_rgb = mix(base_color.rgb, hot_edge, is_edge * 1.5 + edge_glow * 0.4);

	// alpha：溶解区域完全透明
	float final_alpha = base_color.a * (1.0 - is_dissolved);

	// 边缘发光微弱增加alpha
	final_alpha += edge_glow * 0.3 * base_color.a;

	// 完全溶解时提前消逝（避免最后几个像素残留）
	if (dissolve_amount > 0.95) {
		final_alpha *= (1.0 - dissolve_amount) * 20.0;
	}

	COLOR = vec4(final_rgb, clamp(final_alpha, 0.0, 1.0));
}
