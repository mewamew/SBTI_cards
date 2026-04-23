// ═══════════════════════════════════════════════════════════════
// SBTI 卡牌3D翻转着色器
// ═══════════════════════════════════════════════════════════════
// 视觉效果：
//   - 正反面纹理在翻转中点平滑切换
//   - 透视压缩模拟3D翻转的厚度感
//   - 侧面边缘金色高光模拟卡牌金属边框反光
//   - 配合 Tween 控制 flip_progress，在中点暂停=「命运悬停」
//
// 使用方式：
//   1. 将此着色器材质附加到卡牌的 TextureRect 上
//   2. 设置 front_texture / back_texture
//   3. 用 Tween 驱动 shader_parameter/flip_progress 从 0→1
//   4. 在 flip_progress ≈ 0.5 时暂停 0.05s（命运悬停）
// ═══════════════════════════════════════════════════════════════

shader_type canvas_item;
render_mode blend_mix;

// ── Uniform 参数 ──

// 翻转进度：0.0 = 完全正面，0.5 = 侧面（最薄），1.0 = 完全背面
uniform float flip_progress : hint_range(0.0, 1.0) = 0.0;

// 正面纹理（卡牌角色图）
uniform sampler2D front_texture : source_color, hint_default_white;

// 背面纹理（卡牌背面花纹）
uniform sampler2D back_texture : source_color, hint_default_white;

// 侧面边缘高光颜色
uniform vec4 edge_glow_color : source_color = vec4(0.84, 0.71, 0.43, 1.0);

// 侧面边缘高光宽度
uniform float edge_glow_width : hint_range(0.01, 0.2) = 0.08;

// 翻转透视曲率（越大越像3D透视）
uniform float perspective_curvature : hint_range(0.0, 0.3) = 0.12;

// ── 片段着色器 ──

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	// 将 flip_progress 映射到 -1..1 范围，0.5 为翻转中点
	float flip_angle = flip_progress * 2.0 - 1.0;  // -1(正面) → 0(侧面) → 1(背面)

	// cos 模拟透视缩放：侧面时 X 方向最窄
	float cos_angle = cos(flip_angle * 1.5708);  // PI/2
	float x_scale = abs(cos_angle);

	// 是否在背面
	bool is_back = flip_angle > 0.0;

	// UV 透视变换：模拟3D翻转时的透视畸变
	vec2 flipped_uv = UV;

	// X方向压缩（模拟侧面）
	flipped_uv.x = (UV.x - 0.5) / max(x_scale, 0.02) + 0.5;

	// 透视曲率：边缘比中心稍宽（桶形畸变模拟）
	float center_dist = abs(UV.x - 0.5) * 2.0;
	float curvature = perspective_curvature * (1.0 - x_scale);
	flipped_uv.x += curvature * (UV.x - 0.5) * center_dist;

	// 背面 UV 水平镜像
	if (is_back) {
		flipped_uv.x = 1.0 - flipped_uv.x;
	}

	// 采样对应面的纹理
	vec4 face_color;
	if (is_back) {
		face_color = texture(back_texture, flipped_uv);
	} else {
		face_color = texture(front_texture, flipped_uv);
	}

	// 混合：用基础纹理的alpha做遮罩，保留原始卡牌形状
	vec4 final_color = face_color * vec4(1.0, 1.0, 1.0, base_color.a);

	// ── 侧面边缘高光 ──
	// 在翻转过程中（x_scale < 1），卡牌两侧边缘发出金色光芒
	float edge_intensity = 1.0 - x_scale;  // 侧面时最强
	edge_intensity = pow(edge_intensity, 0.8);  // 让高光分布更自然

	// 计算到最近边缘的距离
	float edge_dist = min(UV.x, 1.0 - UV.x);
	float edge_glow = smoothstep(edge_glow_width, 0.0, edge_dist);

	// 高光仅在翻转过程中出现，静止时消失
	float glow_factor = edge_intensity * edge_glow;

	// 叠加边缘高光
	final_color.rgb += edge_glow_color.rgb * glow_factor * 0.8;
	// 高光也增加一点alpha，让边缘光可见
	final_color.a += glow_factor * 0.3 * base_color.a;

	// ── 翻转中点闪光脉冲 ──
	// 在 flip_progress ≈ 0.5 时，全卡面微微泛白（命运悬停的紧张感）
	float midpoint_proximity = 1.0 - abs(flip_progress - 0.5) * 2.0;
	midpoint_proximity = pow(max(midpoint_proximity, 0.0), 3.0);
	final_color.rgb += vec3(1.0, 0.95, 0.85) * midpoint_proximity * 0.15;
	final_color.a = min(final_color.a, 1.0);

	COLOR = final_color;
}
