// ═══════════════════════════════════════════════════════════════
// SBTI 卡牌选中高亮着色器
// ═══════════════════════════════════════════════════════════════
// 视觉效果：
//   - 沿卡牌边缘绘制流动光晕
//   - 光晕沿边缘循环移动（TIME驱动角度偏移）
//   - 选中态：光晕强、宽、快
//   - 悬停态：光晕柔、窄、慢
//
// 使用方式：
//   1. 不要直接附加到使用 StyleBoxFlat 的 Button 上；
//      Control 节点上的 TEXTURE 往往是白色占位，会把卡面整体冲白。
//   2. 如需使用，优先挂到独立的边缘高光覆盖层上
//   2. 设置 highlight_intensity: 0=关, 0.5=悬停, 1.0=选中
//   3. 选中态时提高 flow_speed 让光晕流动更快
// ═══════════════════════════════════════════════════════════════

shader_type canvas_item;
render_mode blend_mix;

// ── Uniform 参数 ──

// 光晕颜色
uniform vec4 highlight_color : source_color = vec4(0.97, 0.87, 0.58, 1.0);

// 光晕强度：0 = 不可见，0.5 = 悬停，1.0 = 选中
uniform float highlight_intensity : hint_range(0.0, 1.0) = 0.0;

// 流动速度
uniform float flow_speed : hint_range(0.0, 3.0) = 1.0;

// 光晕宽度（占UV的比例）
uniform float highlight_width : hint_range(0.01, 0.15) = 0.06;

// 内发光柔和度
uniform float glow_softness : hint_range(0.1, 1.0) = 0.5;

// ── 片段着色器 ──

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	// 计算到四条边缘的最小距离（归一化到0~1）
	float dist_left = UV.x;
	float dist_right = 1.0 - UV.x;
	float dist_top = UV.y;
	float dist_bottom = 1.0 - UV.y;
	float edge_dist = min(min(dist_left, dist_right), min(dist_top, dist_bottom));

	// ── 流动光晕 ──
	// 计算当前像素在边缘上的角度位置
	vec2 center = vec2(0.5, 0.5);
	vec2 delta = UV - center;
	float angle = atan(delta.y, delta.x);  // -PI ~ PI

	// 流动因子：角度随时间偏移，产生沿边缘移动的效果
	float flow = sin(angle * 2.0 + TIME * flow_speed * 3.0) * 0.5 + 0.5;
	float flow2 = sin(angle * 3.0 - TIME * flow_speed * 2.0) * 0.5 + 0.5;

	// 双层光晕叠加，产生更丰富的流动感
	float wave = mix(flow, flow2, 0.4);

	// ── 边缘光晕计算 ──
	// 基础光晕：靠近边缘的区域
	float edge_glow = smoothstep(highlight_width, 0.0, edge_dist);

	// 柔和内发光：向内扩散的弱光
	float inner_glow = smoothstep(highlight_width * 3.0, 0.0, edge_dist) * glow_softness * 0.3;

	// 流动光晕：只在边缘附近，且随流动因子变化
	float flowing_glow = edge_glow * (0.5 + wave * 0.5);

	// 合并所有光晕
	float total_glow = flowing_glow + inner_glow;

	// ── 角落高亮加强 ──
	// 四个角落处光晕稍强，模拟金属卡角反光
	float corner_factor = 1.0;
	float corner_dist = length(vec2(
		min(dist_left, dist_right) / 0.5,
		min(dist_top, dist_bottom) / 0.5
	));
	if (corner_dist < 0.3) {
		corner_factor = 1.0 + (0.3 - corner_dist) * 2.0;
	}
	total_glow *= corner_factor;

	// ── 应用到最终颜色 ──
	vec3 glow_rgb = highlight_color.rgb * total_glow * highlight_intensity;

	// 叠加模式：光晕添加到原始颜色上
	vec3 final_rgb = base_color.rgb + glow_rgb;

	// 光晕也微弱影响alpha
	float glow_alpha = total_glow * highlight_intensity * 0.3;

	COLOR = vec4(final_rgb, base_color.a + glow_alpha * base_color.a);
}
