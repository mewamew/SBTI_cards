extends GPUParticles2D


const DEFAULT_STAGE_SIZE := Vector2(1200.0, 640.0)

var _configured_stage_size := DEFAULT_STAGE_SIZE
var _emission_box_scale := Vector2(0.30, 0.22)


func _ready() -> void:
	if process_material == null:
		process_material = _build_process_material()
	if texture == null:
		texture = _build_fallback_texture()
	_apply_profile({})
	set_stage_size(_configured_stage_size)
	emitting = true


func configure(glow_texture: Texture2D, stage_size: Vector2, profile: Dictionary = {}) -> void:
	if glow_texture != null:
		texture = glow_texture
	elif texture == null:
		texture = _build_fallback_texture()
	if process_material == null:
		process_material = _build_process_material()
	_apply_profile(profile)
	set_stage_size(stage_size)
	restart()
	emitting = true


func set_stage_size(stage_size: Vector2) -> void:
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		stage_size = DEFAULT_STAGE_SIZE
	_configured_stage_size = stage_size
	position = stage_size * 0.5
	visibility_rect = Rect2(-stage_size * 0.64, stage_size * 1.28)
	var material := process_material as ParticleProcessMaterial
	if material != null:
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		material.emission_box_extents = Vector3(
			stage_size.x * _emission_box_scale.x,
			stage_size.y * _emission_box_scale.y,
			1.0
		)


func _apply_profile(profile: Dictionary) -> void:
	amount = int(profile.get("amount", 84))
	lifetime = float(profile.get("lifetime", 9.0))
	one_shot = false
	explosiveness = 0.0
	randomness = float(profile.get("randomness", 0.72))
	preprocess = float(profile.get("preprocess", lifetime))
	fixed_fps = int(profile.get("fixed_fps", 30))
	speed_scale = float(profile.get("speed_scale", 1.0))
	local_coords = false
	z_index = int(profile.get("z_index", 0))
	self_modulate = profile.get("self_modulate", Color(1.0, 0.96, 0.88, 0.92))
	_emission_box_scale = profile.get("emission_scale", Vector2(0.30, 0.22))

	var material := process_material as ParticleProcessMaterial
	if material == null:
		return
	material.direction = profile.get("direction", Vector3(0.0, -1.0, 0.0))
	material.spread = float(profile.get("spread", 34.0))
	material.initial_velocity_min = float(profile.get("velocity_min", 5.0))
	material.initial_velocity_max = float(profile.get("velocity_max", 14.0))
	material.gravity = profile.get("gravity", Vector3(0.0, -0.8, 0.0))
	material.linear_accel_min = float(profile.get("linear_accel_min", -0.8))
	material.linear_accel_max = float(profile.get("linear_accel_max", 1.2))
	material.radial_accel_min = float(profile.get("radial_accel_min", -1.8))
	material.radial_accel_max = float(profile.get("radial_accel_max", 1.8))
	material.tangential_accel_min = float(profile.get("tangential_accel_min", -4.0))
	material.tangential_accel_max = float(profile.get("tangential_accel_max", 4.0))
	material.damping_min = float(profile.get("damping_min", 0.2))
	material.damping_max = float(profile.get("damping_max", 0.7))
	material.scale_min = float(profile.get("scale_min", 0.035))
	material.scale_max = float(profile.get("scale_max", 0.12))
	material.hue_variation_min = float(profile.get("hue_variation_min", -0.015))
	material.hue_variation_max = float(profile.get("hue_variation_max", 0.02))
	material.color_ramp = _build_color_ramp(profile)


func _build_process_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 34.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 14.0
	material.gravity = Vector3(0.0, -0.8, 0.0)
	material.linear_accel_min = -0.8
	material.linear_accel_max = 1.2
	material.radial_accel_min = -1.8
	material.radial_accel_max = 1.8
	material.tangential_accel_min = -4.0
	material.tangential_accel_max = 4.0
	material.damping_min = 0.2
	material.damping_max = 0.7
	material.scale_min = 0.035
	material.scale_max = 0.12
	material.hue_variation_min = -0.015
	material.hue_variation_max = 0.02
	material.color_ramp = _build_color_ramp({})
	return material


func _build_color_ramp(profile: Dictionary) -> GradientTexture1D:
	var inner: Color = profile.get("inner_color", Color(1.0, 0.86, 0.60, 0.10))
	var mid: Color = profile.get("mid_color", Color(0.99, 0.82, 0.56, 0.26))
	var outer: Color = profile.get("outer_color", Color(0.94, 0.73, 0.44, 0.42))
	var fade: Color = profile.get("fade_color", Color(0.88, 0.60, 0.34, 0.0))
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.88, 0.62, 0.0))
	gradient.add_point(0.12, inner)
	gradient.add_point(0.40, mid)
	gradient.add_point(0.72, outer)
	gradient.add_point(1.0, fade)
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	ramp.width = 96
	return ramp


func _build_fallback_texture() -> Texture2D:
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.46
	for y in range(size):
		for x in range(size):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := pow(clampf(1.0 - dist / radius, 0.0, 1.0), 3.2) * 0.42
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
