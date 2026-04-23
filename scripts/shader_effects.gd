extends RefCounted
class_name ShaderEffects

## SBTI 卡牌着色器效果工具类
## 提供所有着色器材质的创建、参数控制、动画驱动的统一接口
##
## 使用方式：
##   var mat := ShaderEffects.create_card_flip_material(front_tex, back_tex)
##   node.material = mat
##   ShaderEffects.animate_flip(mat, 0.0, 1.0, 0.5)

# ──────────────────────────────────────────
# 着色器路径常量
# ──────────────────────────────────────────

const PATH_CARD_FLIP := "res://shaders/card_flip.gdshader"
const PATH_FATE_REVEAL := "res://shaders/fate_reveal.gdshader"
const PATH_CARD_HIGHLIGHT := "res://shaders/card_highlight.gdshader"
const PATH_CARD_DISSOLVE := "res://shaders/card_dissolve.gdshader"
const PATH_VIGNETTE := "res://shaders/vignette_atmosphere.gdshader"
const PATH_TABLE_ATMOSPHERE := "res://shaders/table_atmosphere.gdshader"
const PATH_STAGE_LIGHT_SHAFTS := "res://shaders/stage_light_shafts.gdshader"

# ──────────────────────────────────────────
# 材质缓存（避免重复加载着色器资源）
# ──────────────────────────────────────────

static var _shader_cache: Dictionary = {}

static func _get_shader(path: String) -> Shader:
	if not _shader_cache.has(path):
		var shader: Shader = load(path) as Shader
		_shader_cache[path] = shader
	return _shader_cache[path] as Shader


# ══════════════════════════════════════════
# 一、卡牌3D翻转 (card_flip)
# ══════════════════════════════════════════

## 创建翻牌着色器材质
## front_texture: 卡牌正面纹理
## back_texture: 卡牌背面纹理（传null则用默认白色）
static func create_card_flip_material(front_texture: Texture2D = null, back_texture: Texture2D = null) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_CARD_FLIP)
	if front_texture != null:
		mat.set_shader_parameter("front_texture", front_texture)
	if back_texture != null:
		mat.set_shader_parameter("back_texture", back_texture)
	mat.set_shader_parameter("flip_progress", 0.0)
	mat.set_shader_parameter("edge_glow_color", Color(0.84, 0.71, 0.43, 1.0))
	mat.set_shader_parameter("edge_glow_width", 0.08)
	mat.set_shader_parameter("perspective_curvature", 0.12)
	return mat


## 驱动翻牌动画（需在Node上下文中调用，使用该Node的create_tween）
## node: 用于创建Tween的节点
## material: 翻牌着色器材质
## from: 起始进度 (0.0=正面, 1.0=背面)
## to: 目标进度
## midpoint_pause: 翻转中点(0.5)暂停时长(秒)，0=不暂停
## 返回: Tween对象
static func animate_flip(node: Node, material: ShaderMaterial, from: float, to: float, midpoint_pause: float = 0.05) -> Tween:
	if node == null or material == null:
		return null

	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)

	if midpoint_pause > 0.0 and ((from < 0.5 and to > 0.5) or (from > 0.5 and to < 0.5)):
		# 分两段：前半 + 暂停 + 后半
		# 前半：from → 0.5
		var first_duration: float = 0.12
		var second_duration: float = 0.15

		tween.tween_method(func(val: float) -> void:
			material.set_shader_parameter("flip_progress", val)
		, from, 0.5, first_duration).set_ease(Tween.EASE_IN)

		tween.tween_interval(midpoint_pause)  # 命运悬停

		tween.tween_method(func(val: float) -> void:
			material.set_shader_parameter("flip_progress", val)
		, 0.5, to, second_duration).set_ease(Tween.EASE_OUT)
	else:
		var duration: float = 0.25
		tween.tween_method(func(val: float) -> void:
			material.set_shader_parameter("flip_progress", val)
		, from, to, duration)

	return tween


## 立即设置翻牌进度（无动画）
static func set_flip_progress(material: ShaderMaterial, progress: float) -> void:
	if material != null:
		material.set_shader_parameter("flip_progress", progress)


## 设置翻牌正反面纹理
static func set_flip_textures(material: ShaderMaterial, front_texture: Texture2D, back_texture: Texture2D = null) -> void:
	if material == null:
		return
	material.set_shader_parameter("front_texture", front_texture)
	if back_texture != null:
		material.set_shader_parameter("back_texture", back_texture)


# ══════════════════════════════════════════
# 二、命运揭晓光效 (fate_reveal)
# ══════════════════════════════════════════

## 创建命运揭晓光效着色器材质
static func create_fate_reveal_material(is_ally: bool = true) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_FATE_REVEAL)
	mat.set_shader_parameter("glow_color", Color(0.29, 0.62, 1.0) if is_ally else Color(1.0, 0.23, 0.23))
	mat.set_shader_parameter("glow_intensity", 0.0)
	mat.set_shader_parameter("glow_radius", 0.5)
	mat.set_shader_parameter("is_ally", 1.0 if is_ally else 0.0)
	mat.set_shader_parameter("noise_speed", 0.3)
	mat.set_shader_parameter("scan_line_count", 8.0)
	return mat


## 播放命运揭晓光效动画
## node: 用于创建Tween的节点
## overlay: 带有 fate_reveal 材质的控件节点（ColorRect / TextureRect 均可）
## fate: "ally" 或 "enemy"
## 返回: Tween对象
static func animate_fate_reveal(node: Node, overlay: Control, fate: String) -> Tween:
	if node == null or overlay == null:
		return null

	var mat: ShaderMaterial = overlay.material as ShaderMaterial
	if mat == null:
		return null

	var overlay_id := overlay.get_instance_id()
	var is_ally_result: bool = fate == "ally"
	mat.set_shader_parameter("is_ally", 1.0 if is_ally_result else 0.0)
	mat.set_shader_parameter("glow_color", Color(0.29, 0.62, 1.0) if is_ally_result else Color(1.0, 0.23, 0.23))
	mat.set_shader_parameter("glow_intensity", 0.0)

	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 5

	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_SINE)

	if is_ally_result:
		# 伙伴：缓慢升起 → 长时间保持 → 缓慢消退
		tween.tween_method(func(val: float) -> void:
			var o := instance_from_id(overlay_id) as Control
			if o == null or not is_instance_valid(o) or o.material == null:
				return
			o.material.set_shader_parameter("glow_intensity", val)
		, 0.0, 1.0, 0.15).set_ease(Tween.EASE_OUT)

		tween.tween_method(func(val: float) -> void:
			var o := instance_from_id(overlay_id) as Control
			if o == null or not is_instance_valid(o) or o.material == null:
				return
			o.material.set_shader_parameter("glow_radius", val)
		, 0.3, 0.8, 0.5).set_ease(Tween.EASE_OUT)

		tween.tween_interval(0.3)

		tween.tween_method(func(val: float) -> void:
			var o := instance_from_id(overlay_id) as Control
			if o == null or not is_instance_valid(o) or o.material == null:
				return
			o.material.set_shader_parameter("glow_intensity", val)
		, 1.0, 0.0, 0.6).set_ease(Tween.EASE_IN)
	else:
		# 敌人：快速闪击 → 短暂保持 → 快速消退
		tween.tween_method(func(val: float) -> void:
			var o := instance_from_id(overlay_id) as Control
			if o == null or not is_instance_valid(o) or o.material == null:
				return
			o.material.set_shader_parameter("glow_intensity", val)
		, 0.0, 1.0, 0.06).set_ease(Tween.EASE_OUT)

		tween.tween_method(func(val: float) -> void:
			var o := instance_from_id(overlay_id) as Control
			if o == null or not is_instance_valid(o) or o.material == null:
				return
			o.material.set_shader_parameter("glow_radius", val)
		, 0.8, 0.3, 0.2).set_ease(Tween.EASE_IN)

		tween.tween_interval(0.15)

		tween.tween_method(func(val: float) -> void:
			var o := instance_from_id(overlay_id) as Control
			if o == null or not is_instance_valid(o) or o.material == null:
				return
			o.material.set_shader_parameter("glow_intensity", val)
		, 1.0, 0.0, 0.35).set_ease(Tween.EASE_IN)

	# 消失后隐藏
	tween.tween_callback(func() -> void:
		var o := instance_from_id(overlay_id) as Control
		if o == null or not is_instance_valid(o):
			return
		o.visible = false
	)

	return tween


# ══════════════════════════════════════════
# 三、卡牌选中高亮 (card_highlight)
# ══════════════════════════════════════════

## 创建卡牌高亮着色器材质
static func create_card_highlight_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_CARD_HIGHLIGHT)
	mat.set_shader_parameter("highlight_color", Color(0.97, 0.87, 0.58, 1.0))
	mat.set_shader_parameter("highlight_intensity", 0.0)
	mat.set_shader_parameter("flow_speed", 1.0)
	mat.set_shader_parameter("highlight_width", 0.06)
	mat.set_shader_parameter("glow_softness", 0.5)
	return mat


## 设置高亮强度（0=关, 0.5=悬停, 1.0=选中）
static func set_highlight_intensity(material: ShaderMaterial, intensity: float) -> void:
	if material != null:
		material.set_shader_parameter("highlight_intensity", intensity)


## 设置高亮流动速度
static func set_highlight_flow_speed(material: ShaderMaterial, speed: float) -> void:
	if material != null:
		material.set_shader_parameter("flow_speed", speed)


## 悬停高亮动画
static func animate_hover_highlight(node: Node, material: ShaderMaterial, enter: bool) -> Tween:
	if node == null or material == null:
		return null
	var target: float = 0.5 if enter else 0.0
	var speed: float = 1.5 if enter else 1.0
	var current_intensity: float = float(material.get_shader_parameter("highlight_intensity"))
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("highlight_intensity", val)
	, current_intensity, target, 0.12)
	# 同时调整流动速度
	var current_speed: float = material.get_shader_parameter("flow_speed")
	tween.parallel().tween_method(func(val: float) -> void:
		material.set_shader_parameter("flow_speed", val)
	, current_speed, speed, 0.12)
	return tween


## 选中高亮动画
static func animate_select_highlight(node: Node, material: ShaderMaterial, selected: bool) -> Tween:
	if node == null or material == null:
		return null
	var target: float = 1.0 if selected else 0.0
	var speed: float = 2.5 if selected else 1.0
	var width: float = 0.08 if selected else 0.06
	var current_intensity: float = float(material.get_shader_parameter("highlight_intensity"))
	var current_speed: float = float(material.get_shader_parameter("flow_speed"))
	var current_width: float = float(material.get_shader_parameter("highlight_width"))
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("highlight_intensity", val)
	, current_intensity, target, 0.15)
	tween.parallel().tween_method(func(val: float) -> void:
		material.set_shader_parameter("flow_speed", val)
	, current_speed, speed, 0.15)
	tween.parallel().tween_method(func(val: float) -> void:
		material.set_shader_parameter("highlight_width", val)
	, current_width, width, 0.15)
	return tween


# ══════════════════════════════════════════
# 四、卡牌溶解消逝 (card_dissolve)
# ══════════════════════════════════════════

## 创建溶解着色器材质
static func create_card_dissolve_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_CARD_DISSOLVE)
	mat.set_shader_parameter("dissolve_amount", 0.0)
	mat.set_shader_parameter("edge_color", Color(0.84, 0.71, 0.43, 1.0))
	mat.set_shader_parameter("edge_width", 0.05)
	mat.set_shader_parameter("noise_scale", 5.0)
	mat.set_shader_parameter("dissolve_direction_bias", 0.0)
	return mat


## 播放溶解动画
## node: 用于创建Tween的节点
## material: 溶解着色器材质
## duration: 溶解时长
## on_complete: 完成回调（通常用于 queue_free）
## 返回: Tween对象
static func animate_dissolve(node: Node, material: ShaderMaterial, duration: float = 0.6, on_complete: Callable = Callable()) -> Tween:
	if node == null or material == null:
		return null

	material.set_shader_parameter("dissolve_amount", 0.0)
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("dissolve_amount", val)
	, 0.0, 1.0, duration)

	if on_complete.is_valid():
		tween.tween_callback(on_complete)

	return tween


## 设置溶解边缘颜色（可改为红色模拟燃烧等）
static func set_dissolve_edge_color(material: ShaderMaterial, color: Color) -> void:
	if material != null:
		material.set_shader_parameter("edge_color", color)


# ══════════════════════════════════════════
# 五、全局暗角/氛围 (vignette_atmosphere)
# ══════════════════════════════════════════

## 创建暗角氛围着色器材质
static func create_vignette_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_VIGNETTE)
	mat.set_shader_parameter("vignette_intensity", 0.4)
	mat.set_shader_parameter("warmth", 0.0)
	mat.set_shader_parameter("noise_opacity", 0.03)
	mat.set_shader_parameter("noise_scale", 15.0)
	mat.set_shader_parameter("vignette_aspect", 1.4)
	mat.set_shader_parameter("vignette_softness", 0.35)
	return mat


## 创建赌桌动态氛围材质
static func create_table_atmosphere_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_TABLE_ATMOSPHERE)
	mat.set_shader_parameter("haze_tint", Color(0.92, 0.76, 0.48, 1.0))
	mat.set_shader_parameter("shadow_tint", Color(0.16, 0.06, 0.04, 1.0))
	mat.set_shader_parameter("haze_strength", 0.20)
	mat.set_shader_parameter("glow_strength", 0.24)
	mat.set_shader_parameter("vignette_strength", 0.22)
	mat.set_shader_parameter("grain_strength", 0.050)
	mat.set_shader_parameter("motion_speed", 0.18)
	return mat


## 创建舞台光束材质
static func create_stage_light_shafts_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _get_shader(PATH_STAGE_LIGHT_SHAFTS)
	mat.set_shader_parameter("beam_color", Color(1.0, 0.82, 0.58, 1.0))
	mat.set_shader_parameter("beam_alpha", 0.34)
	mat.set_shader_parameter("focus_strength", 0.26)
	mat.set_shader_parameter("shimmer_strength", 0.30)
	mat.set_shader_parameter("drift_speed", 0.16)
	mat.set_shader_parameter("pulse_boost", 0.0)
	return mat


## 设置暖冷偏移
## warmth: -1(冷/紧张) ~ 0(中性) ~ 1(暖/安全)
static func set_warmth(material: ShaderMaterial, warmth: float) -> void:
	if material != null:
		material.set_shader_parameter("warmth", clampf(warmth, -1.0, 1.0))


## 播放暖调脉冲动画（翻出伙伴时调用）
static func animate_warmth_pulse(node: Node, material: ShaderMaterial) -> Tween:
	if node == null or material == null:
		return null
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("warmth", val)
	, 0.0, 0.8, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("warmth", val)
	, 0.8, 0.0, 1.0).set_ease(Tween.EASE_IN)
	return tween


## 播放冷调脉冲动画（翻出敌人时调用）
static func animate_cold_pulse(node: Node, material: ShaderMaterial) -> Tween:
	if node == null or material == null:
		return null
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("warmth", val)
	, 0.0, -0.7, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("warmth", val)
	, -0.7, 0.0, 0.8).set_ease(Tween.EASE_IN)
	return tween


## 播放紧张氛围渐变（翻牌前调用，缓慢偏冷）
static func animate_tension_build(node: Node, material: ShaderMaterial) -> Tween:
	if node == null or material == null:
		return null
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_method(func(val: float) -> void:
		material.set_shader_parameter("warmth", val)
	, 0.0, -0.3, 0.3)
	return tween


## 重置氛围到中性
static func reset_atmosphere(material: ShaderMaterial) -> void:
	if material != null:
		material.set_shader_parameter("warmth", 0.0)
