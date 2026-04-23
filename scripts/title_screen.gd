extends Control

signal start_requested

const RibbonBanner := preload("res://scripts/ui/ribbon_banner.gd")
const ButtonFeedback := preload("res://scripts/ui/button_feedback.gd")
const AudioToggleBar := preload("res://scripts/ui/audio_toggle_bar.gd")
const UIFactory := preload("res://scripts/ui_factory.gd")
const TITLE_TEXT := "SBTI人物卡牌游戏"
const TITLE_BACKGROUND_PATH := "res://assets/backgrounds/screens/title.png"

var background_host: Control
var background_rect: TextureRect
var background_texture: Texture2D
var soft_glow_texture: Texture2D
var spotlight_rect: TextureRect
var title_stage: Control
var title_letters: Array[Label] = []
var start_button: Button
var start_ribbon: RibbonBanner
var audio_toggle_bar: AudioToggleBar

var ambient_tweens: Array[Tween] = []
var spotlight_base_pos: Vector2
var dust_particles: GPUParticles2D


func _ready() -> void:
	_build_background()
	_build_foreground()
	_add_audio_toggle_bar()
	call_deferred("_layout_title_arc")
	call_deferred("_start_ambient_animations")


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	call_deferred("_refresh_background_layout")
	call_deferred("_layout_title_arc")
	call_deferred("_refresh_spotlight")
	call_deferred("_refresh_start_button_layout")


func _build_background() -> void:
	background_texture = _load_title_background_texture()

	var base := ColorRect.new()
	base.color = Color("0a0604")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)

	background_host = Control.new()
	background_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_host.clip_contents = true
	background_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_host)

	background_rect = TextureRect.new()
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.texture = background_texture
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_rect.modulate = Color(1.10, 1.08, 1.04, 1.0)
	background_host.add_child(background_rect)
	call_deferred("_refresh_background_layout")

	soft_glow_texture = _generate_soft_glow_texture()

	spotlight_rect = TextureRect.new()
	spotlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spotlight_rect.texture = soft_glow_texture
	spotlight_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spotlight_rect.stretch_mode = TextureRect.STRETCH_SCALE
	spotlight_rect.modulate = Color(1.0, 0.82, 0.42, 0.18)
	add_child(spotlight_rect)

	var vignette := ColorRect.new()
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0, 0, 0, 0.14)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)


func _build_foreground() -> void:
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	start_button = _make_start_button()
	start_button.pressed.connect(func() -> void:
		ButtonFeedback.spawn_ripple(self, start_button.global_position + start_button.size * 0.5)
		start_requested.emit()
	)
	start_button.anchor_left = 0.5
	start_button.anchor_right = 0.5
	start_button.anchor_top = 1.0
	start_button.anchor_bottom = 1.0
	overlay.add_child(start_button)
	ButtonFeedback.add_press_feedback(start_button, 0.95)
	call_deferred("_refresh_start_button_layout")


func _add_audio_toggle_bar() -> void:
	audio_toggle_bar = AudioToggleBar.new()
	audio_toggle_bar.show_sfx_toggle = false
	add_child(audio_toggle_bar)


func _build_title_arc() -> void:
	if title_stage == null:
		return
	for child in title_stage.get_children():
		child.queue_free()
	title_letters.clear()

	for index in range(TITLE_TEXT.length()):
		var glyph := TITLE_TEXT.substr(index, 1)
		var font_size := 84 if index < 4 else 54
		var label := UIFactory.make_label(glyph, font_size, _get_title_character_color(index, TITLE_TEXT.length()), true)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_constant_override("outline_size", 6 if index < 4 else 4)
		label.add_theme_color_override("font_outline_color", Color(0.18, 0.04, 0.04, 0.95))
		title_stage.add_child(label)
		title_letters.append(label)


func _layout_title_arc() -> void:
	if title_stage == null or title_letters.is_empty():
		return

	var stage_size := title_stage.size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		stage_size = title_stage.custom_minimum_size

	var center := Vector2(stage_size.x * 0.5, stage_size.y * 3.55)
	var radius := stage_size.x * 0.80
	var start_angle := deg_to_rad(-116.0)
	var end_angle := deg_to_rad(-64.0)

	for index in range(title_letters.size()):
		var label := title_letters[index]
		if label == null:
			continue
		var t := 0.5 if title_letters.size() == 1 else float(index) / float(title_letters.size() - 1)
		var angle := lerpf(start_angle, end_angle, t)
		var label_size := label.get_combined_minimum_size()
		var position_on_arc := center + Vector2(cos(angle), sin(angle)) * radius
		label.position = position_on_arc - label_size * 0.5
		label.rotation = (angle + PI * 0.5) * 0.35


func _get_title_character_color(index: int, total: int) -> Color:
	var t := 0.5 if total <= 1 else float(index) / float(total - 1)
	if t <= 0.5:
		return Color("f5e3b8").lerp(Color("f0d28a"), t / 0.5)
	return Color("f0d28a").lerp(Color("d8a94c"), (t - 0.5) / 0.5)


func _make_start_button() -> Button:
	var button := Button.new()
	button.name = "StartButton"
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(320, 78)
	button.size = button.custom_minimum_size
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.mouse_entered.connect(_on_start_hover_changed.bind(true))
	button.mouse_exited.connect(_on_start_hover_changed.bind(false))

	start_ribbon = RibbonBanner.new()
	start_ribbon.name = "StartRibbon"
	start_ribbon.fill_color = Color("6b1218")
	start_ribbon.border_color = Color("c9a04c")
	start_ribbon.border_width = 2.5
	start_ribbon.cut_depth = 26.0
	start_ribbon.title_text = "进入游戏"
	start_ribbon.title_color = Color("f0d28a")
	start_ribbon.title_font_size = 32
	start_ribbon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(start_ribbon)
	return button


func _on_start_hover_changed(is_hover: bool) -> void:
	if start_ribbon == null:
		return
	start_ribbon.fill_color = Color("8a1a1f") if is_hover else Color("6b1218")
	start_ribbon.title_color = Color("ffe9b8") if is_hover else Color("f0d28a")
	start_ribbon.queue_redraw()


func _refresh_background_layout() -> void:
	if background_host == null or background_rect == null or background_texture == null:
		return
	var host_size := background_host.size
	if host_size.x <= 0.0 or host_size.y <= 0.0:
		return
	var texture_size := background_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale_factor := maxf(host_size.x / texture_size.x, host_size.y / texture_size.y)
	var draw_size := texture_size * scale_factor
	background_rect.size = draw_size
	background_rect.position = (host_size - draw_size) * 0.5


func _refresh_spotlight() -> void:
	if spotlight_rect == null:
		return
	var screen := size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return
	var sw := screen.x * 0.85
	var sh := screen.y * 1.10
	spotlight_base_pos = Vector2((screen.x - sw) * 0.5, -screen.y * 0.18)
	spotlight_rect.position = spotlight_base_pos
	spotlight_rect.size = Vector2(sw, sh)


func _refresh_start_button_layout() -> void:
	if start_button == null:
		return
	var screen := size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return
	var button_width := clampf(screen.x * 0.24, 280.0, 380.0)
	var button_height := clampf(screen.y * 0.085, 68.0, 84.0)
	var bottom_margin := clampf(screen.y * 0.090, 52.0, 84.0)
	start_button.custom_minimum_size = Vector2(button_width, button_height)
	start_button.size = start_button.custom_minimum_size
	start_button.offset_left = -button_width * 0.5
	start_button.offset_right = button_width * 0.5
	start_button.offset_top = -button_height - bottom_margin
	start_button.offset_bottom = -bottom_margin
	start_button.pivot_offset = start_button.custom_minimum_size * 0.5
	if start_ribbon != null:
		start_ribbon.title_font_size = int(clampf(button_height * 0.40, 24.0, 34.0))
		start_ribbon.queue_redraw()


func _start_ambient_animations() -> void:
	_kill_ambient_tweens()
	_start_title_breath()
	_start_spotlight_sway()
	_start_background_pulse()
	_start_dust_particles()


func _kill_ambient_tweens() -> void:
	for tween in ambient_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	ambient_tweens.clear()


func _start_title_breath() -> void:
	if title_letters.is_empty():
		return
	for i in range(title_letters.size()):
		var letter := title_letters[i]
		if letter == null:
			continue
		var tween := create_tween()
		tween.set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		var delay := float(i) / title_letters.size() * 2.0
		if delay > 0:
			tween.tween_interval(delay)
		tween.tween_property(letter, "scale", Vector2(1.035, 1.035), 1.6)
		tween.parallel().tween_property(letter, "modulate", Color(1.08, 1.02, 0.92, 1.0), 1.6)
		tween.tween_property(letter, "scale", Vector2(1.0, 1.0), 1.6)
		tween.parallel().tween_property(letter, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.6)
		ambient_tweens.append(tween)


func _start_spotlight_sway() -> void:
	if spotlight_rect == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var sway := size.x * 0.06
	tween.tween_property(spotlight_rect, "position:x", spotlight_base_pos.x + sway, 5.0)
	tween.tween_property(spotlight_rect, "position:x", spotlight_base_pos.x - sway, 5.0)
	ambient_tweens.append(tween)


func _start_background_pulse() -> void:
	if background_rect == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background_rect, "modulate", Color(1.14, 1.11, 1.06, 1.0), 5.0)
	tween.tween_property(background_rect, "modulate", Color(1.06, 1.04, 1.00, 1.0), 5.0)
	ambient_tweens.append(tween)


func _start_dust_particles() -> void:
	if dust_particles != null:
		dust_particles.queue_free()
	dust_particles = GPUParticles2D.new()
	dust_particles.name = "DustParticles"
	dust_particles.amount = 48
	dust_particles.lifetime = 8.0
	dust_particles.preprocess = 8.0
	dust_particles.explosiveness = 0.0
	dust_particles.randomness = 1.0
	dust_particles.position = Vector2(size.x * 0.5, size.y * 0.5)
	dust_particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(size.x * 0.6, size.y * 0.4, 0)
	material.particle_flag_disable_z = true
	material.direction = Vector3(0, -1, 0)
	material.spread = 15.0
	material.gravity = Vector3(0, -8, 0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 8.0
	material.angular_velocity_min = -10.0
	material.angular_velocity_max = 10.0
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.color = Color(1.0, 0.92, 0.72, 0.18)

	var curve := CurveTexture.new()
	var curve_data := Curve.new()
	curve_data.add_point(Vector2(0, 0))
	curve_data.add_point(Vector2(0.2, 1))
	curve_data.add_point(Vector2(0.8, 1))
	curve_data.add_point(Vector2(1, 0))
	curve.curve = curve_data
	material.alpha_curve = curve

	dust_particles.process_material = material

	var particle_texture := _generate_soft_glow_texture()
	dust_particles.texture = particle_texture
	dust_particles.z_index = 5
	add_child(dust_particles)


func _exit_tree() -> void:
	_kill_ambient_tweens()
	if dust_particles != null and is_instance_valid(dust_particles):
		dust_particles.queue_free()
		dust_particles = null


func _load_image_from_disk(res_path: String) -> Image:
	if res_path.is_empty():
		return null
	var global_path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(global_path):
		return null
	var image := Image.load_from_file(global_path)
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return null
	return image


func _load_texture_from_disk(res_path: String) -> Texture2D:
	var image := _load_image_from_disk(res_path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func _load_title_background_texture() -> Texture2D:
	var disk_texture := _load_texture_from_disk(TITLE_BACKGROUND_PATH)
	if disk_texture != null:
		return disk_texture
	if ResourceLoader.exists(TITLE_BACKGROUND_PATH):
		return load(TITLE_BACKGROUND_PATH) as Texture2D
	push_error("Missing title background: %s" % TITLE_BACKGROUND_PATH)
	return null


func _generate_soft_glow_texture() -> Texture2D:
	var size_px := 256
	var image := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var center := Vector2(size_px * 0.5, size_px * 0.5)
	var radius := size_px * 0.46
	for y in range(size_px):
		for x in range(size_px):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := pow(clampf(1.0 - dist / radius, 0.0, 1.0), 3.6) * 0.48
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
