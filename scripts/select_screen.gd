extends Control

signal hero_confirmed(character)

const ShaderEffects = preload("res://scripts/shader_effects.gd")
const GameBalance = preload("res://scripts/game_balance.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const ButtonFeedback = preload("res://scripts/ui/button_feedback.gd")
const AudioToggleBar = preload("res://scripts/ui/audio_toggle_bar.gd")

const THUMBNAIL_BTN_SIZE := Vector2(96, 112)
const CAROUSEL_CONTAINER_HEIGHT := 150.0
const CAROUSEL_BOTTOM_MARGIN := 14.0
const CAROUSEL_ITEM_SPACING := 112.0
const CAROUSEL_VISIBLE_SIDE := 5
const CAROUSEL_ITEM_SCALE := 1.0
const CAROUSEL_SELECTED_SCALE := 1.10
const CAROUSEL_EDGE_ALPHA_STEP := 0.10
const CAROUSEL_TRANSITION := 0.26
const ARROW_BUTTON_SIZE := Vector2(64.0, 108.0)
const ARROW_HORIZONTAL_MARGIN := 48.0
const PROFILE_PANEL_WIDTH := 560.0
const MAIN_CARD_TARGET_HEIGHT := 640.0
const MAIN_CARD_ASPECT := 0.75
const HP_PER_HEART := 8
const SELECT_BACKGROUND_PATH := "res://assets/backgrounds/screens/select.png"

const AMBIENT_PRESETS: Array[Color] = [
	Color(1.00, 0.78, 0.36, 0.14),
	Color(1.00, 0.55, 0.30, 0.14),
	Color(0.90, 0.45, 0.55, 0.14),
	Color(0.50, 0.70, 0.90, 0.14),
	Color(0.50, 0.80, 0.65, 0.14),
	Color(0.85, 0.65, 0.35, 0.14),
	Color(0.70, 0.50, 0.85, 0.14),
	Color(0.85, 0.40, 0.40, 0.14),
]

var characters: Array = []
var selected_index := 0
var card_texture_cache := {}
var portrait_texture_cache := {}

var background_host: Control
var background_rect: TextureRect
var background_texture: Texture2D
var soft_glow_texture: Texture2D
var spotlight_rect: TextureRect
var title_label: Label
var main_card_button: Button
var card_transform: Control
var main_card_image: TextureRect
var main_card_title_overlay: VBoxContainer
var main_card_skill_overlay: VBoxContainer
var profile_panel: PanelContainer
var connector_line: ColorRect
var connector_dot: Panel
var profile_title_label: RichTextLabel
var profile_divider: Control
var profile_skills_label: RichTextLabel
var confirm_button: Button
var confirm_ribbon: RibbonBanner
var thumbnail_carousel: Control
var thumbnail_host: Control
var arrow_left_button: Button
var arrow_right_button: Button
var audio_toggle_bar: AudioToggleBar
var thumbnail_buttons := {}
var thumbnail_tweens := {}
var halo_tweens := {}
var layout_tween: Tween
var is_switching := false

var card_tilt_target: Vector2 = Vector2.ZERO
var card_tilt_current: Vector2 = Vector2.ZERO
var card_float_time: float = 0.0
var card_rim_glow: TextureRect
var card_top_shine: TextureRect
var sheen_rect: TextureRect
var sheen_texture: Texture2D
var settle_tween: Tween
var previous_selected_index: int = -1
var ambient_tween: Tween
var is_card_hovered: bool = false


func setup(next_characters: Array) -> void:
	characters = next_characters


func _ready() -> void:
	_build_background()
	_build_ui()
	_add_audio_toggle_bar()
	call_deferred("_deferred_init")


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	if background_host != null and background_rect != null:
		call_deferred("_refresh_background_layout")
	call_deferred("_refresh_layout")


func _process(delta: float) -> void:
	if card_transform == null or is_switching:
		return

	var mouse_pos := get_global_mouse_position()
	var card_rect := Rect2(main_card_button.global_position, main_card_button.size)
	var card_center := card_rect.get_center()
	var half_size := card_rect.size * 0.5
	var rel := (mouse_pos - card_center) / half_size
	rel.x = clampf(rel.x, -1.0, 1.0)
	rel.y = clampf(rel.y, -1.0, 1.0)

	var lerp_speed := 10.0
	if is_card_hovered:
		card_tilt_target = rel * 0.5
	else:
		card_tilt_target = Vector2(
			sin(card_float_time * 1.4) * 0.5,
			cos(card_float_time * 1.0) * 0.3
		)
	card_tilt_current = card_tilt_current.lerp(card_tilt_target, 1.0 - exp(-delta * lerp_speed))

	var max_rot := 0.06
	var max_offset := 8.0
	card_transform.rotation = card_tilt_current.x * max_rot

	card_float_time += delta
	var breath_scale := 1.0 + sin(card_float_time * 1.96) * 0.0075
	var float_x := sin(card_float_time * 1.3) * 1.5
	var float_y := cos(card_float_time * 0.9) * 2.0

	card_transform.scale = Vector2(breath_scale, breath_scale)
	card_transform.position = Vector2(
		card_tilt_current.x * max_offset + float_x,
		card_tilt_current.y * max_offset * 0.5 + float_y
	)


func _build_background() -> void:
	background_texture = _get_select_background_texture()

	var bg := ColorRect.new()
	bg.color = Color("0a0604")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	background_host.add_child(background_rect)
	call_deferred("_refresh_background_layout")

	soft_glow_texture = _generate_soft_glow_texture()

	spotlight_rect = TextureRect.new()
	spotlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spotlight_rect.texture = soft_glow_texture
	spotlight_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spotlight_rect.stretch_mode = TextureRect.STRETCH_SCALE
	spotlight_rect.modulate = Color(1.0, 0.78, 0.36, 0.12)
	add_child(spotlight_rect)

	var vignette := ColorRect.new()
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0, 0, 0, 0.22)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)


func _build_ui() -> void:
	_build_main_card()
	_build_profile_panel()

	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.flat = true
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.text = ""
	confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	confirm_button.custom_minimum_size = Vector2(240, 60)
	confirm_button.size = confirm_button.custom_minimum_size
	var btn_empty := StyleBoxEmpty.new()
	confirm_button.add_theme_stylebox_override("normal", btn_empty)
	confirm_button.add_theme_stylebox_override("hover", btn_empty)
	confirm_button.add_theme_stylebox_override("pressed", btn_empty)
	confirm_button.add_theme_stylebox_override("focus", btn_empty)
	confirm_button.pressed.connect(func() -> void:
		ButtonFeedback.spawn_ripple(self, confirm_button.global_position + confirm_button.size * 0.5)
		_on_confirm_pressed()
	)
	confirm_button.mouse_entered.connect(_on_confirm_hover_changed.bind(true))
	confirm_button.mouse_exited.connect(_on_confirm_hover_changed.bind(false))
	add_child(confirm_button)
	ButtonFeedback.add_press_feedback(confirm_button)

	confirm_ribbon = RibbonBanner.new()
	confirm_ribbon.name = "ConfirmRibbon"
	confirm_ribbon.fill_color = Color("6b1218")
	confirm_ribbon.border_color = Color("c9a04c")
	confirm_ribbon.border_width = 2.0
	confirm_ribbon.cut_depth = 22.0
	confirm_ribbon.title_text = "登场"
	confirm_ribbon.title_color = Color("f0d28a")
	confirm_ribbon.title_font_size = 28
	confirm_ribbon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_button.add_child(confirm_ribbon)

	_build_thumbnail_carousel()


func _add_audio_toggle_bar() -> void:
	audio_toggle_bar = AudioToggleBar.new()
	audio_toggle_bar.show_sfx_toggle = false
	add_child(audio_toggle_bar)


func _build_main_card() -> void:
	main_card_button = Button.new()
	main_card_button.name = "MainCard"
	main_card_button.flat = true
	main_card_button.focus_mode = Control.FOCUS_NONE
	main_card_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	main_card_button.text = ""
	main_card_button.clip_contents = false
	var empty := StyleBoxEmpty.new()
	main_card_button.add_theme_stylebox_override("normal", empty)
	main_card_button.add_theme_stylebox_override("hover", empty)
	main_card_button.add_theme_stylebox_override("pressed", empty)
	main_card_button.add_theme_stylebox_override("focus", empty)
	main_card_button.pressed.connect(_on_confirm_pressed)
	add_child(main_card_button)

	card_transform = Control.new()
	card_transform.name = "CardTransform"
	card_transform.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_transform.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_card_button.add_child(card_transform)

	main_card_image = TextureRect.new()
	main_card_image.name = "MainCardImage"
	main_card_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_card_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	main_card_image.stretch_mode = TextureRect.STRETCH_SCALE
	main_card_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_transform.add_child(main_card_image)

	main_card_title_overlay = VBoxContainer.new()
	main_card_title_overlay.name = "TitleOverlay"
	main_card_title_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_card_title_overlay.add_theme_constant_override("separation", -2)
	main_card_title_overlay.alignment = BoxContainer.ALIGNMENT_BEGIN
	card_transform.add_child(main_card_title_overlay)

	main_card_skill_overlay = VBoxContainer.new()
	main_card_skill_overlay.name = "SkillOverlay"
	main_card_skill_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_card_skill_overlay.add_theme_constant_override("separation", 4)
	main_card_skill_overlay.alignment = BoxContainer.ALIGNMENT_CENTER
	card_transform.add_child(main_card_skill_overlay)

	main_card_button.mouse_entered.connect(_on_card_mouse_entered)
	main_card_button.mouse_exited.connect(_on_card_mouse_exited)


func _build_profile_panel() -> void:
	profile_panel = PanelContainer.new()
	profile_panel.name = "ProfilePanel"
	profile_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	profile_panel.add_theme_stylebox_override("panel", _make_profile_panel_style())
	add_child(profile_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile_panel.add_child(vbox)

	profile_title_label = RichTextLabel.new()
	profile_title_label.bbcode_enabled = true
	profile_title_label.fit_content = true
	profile_title_label.scroll_active = false
	profile_title_label.selection_enabled = false
	profile_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_title_label.add_theme_constant_override("outline_size", 6)
	profile_title_label.add_theme_color_override("font_outline_color", Color(0.22, 0.04, 0.04, 0.92))
	vbox.add_child(profile_title_label)

	var title_spacer := Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(title_spacer)

	profile_divider = GoldDivider.new()
	profile_divider.custom_minimum_size = Vector2(0, 4)
	profile_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(profile_divider)

	var divider_spacer := Control.new()
	divider_spacer.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(divider_spacer)

	profile_skills_label = RichTextLabel.new()
	profile_skills_label.bbcode_enabled = true
	profile_skills_label.fit_content = true
	profile_skills_label.scroll_active = false
	profile_skills_label.selection_enabled = false
	profile_skills_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_skills_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_skills_label.add_theme_constant_override("outline_size", 4)
	profile_skills_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.0, 0.85))
	vbox.add_child(profile_skills_label)


func _build_connector() -> void:
	connector_line = ColorRect.new()
	connector_line.name = "ConnectorLine"
	connector_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	connector_line.color = Color("e6c87a")
	connector_line.color.a = 0.55
	add_child(connector_line)

	connector_dot = Panel.new()
	connector_dot.name = "ConnectorDot"
	connector_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = Color("f0d28a")
	dot_style.corner_radius_top_left = 999
	dot_style.corner_radius_top_right = 999
	dot_style.corner_radius_bottom_right = 999
	dot_style.corner_radius_bottom_left = 999
	dot_style.shadow_color = Color(1.0, 0.78, 0.36, 0.55)
	dot_style.shadow_size = 10
	connector_dot.add_theme_stylebox_override("panel", dot_style)
	add_child(connector_dot)


func _build_thumbnail_carousel() -> void:
	thumbnail_carousel = Control.new()
	thumbnail_carousel.name = "ThumbnailCarousel"
	thumbnail_carousel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumbnail_carousel.anchor_left = 0.0
	thumbnail_carousel.anchor_top = 1.0
	thumbnail_carousel.anchor_right = 1.0
	thumbnail_carousel.anchor_bottom = 1.0
	thumbnail_carousel.offset_left = 0.0
	thumbnail_carousel.offset_top = -(CAROUSEL_CONTAINER_HEIGHT + CAROUSEL_BOTTOM_MARGIN)
	thumbnail_carousel.offset_right = 0.0
	thumbnail_carousel.offset_bottom = -CAROUSEL_BOTTOM_MARGIN
	thumbnail_carousel.clip_contents = false
	add_child(thumbnail_carousel)

	thumbnail_host = Control.new()
	thumbnail_host.name = "ThumbnailHost"
	thumbnail_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumbnail_host.anchor_left = 0.5
	thumbnail_host.anchor_top = 1.0
	thumbnail_host.anchor_right = 0.5
	thumbnail_host.anchor_bottom = 1.0
	thumbnail_host.offset_left = 0.0
	thumbnail_host.offset_top = 0.0
	thumbnail_host.offset_right = 0.0
	thumbnail_host.offset_bottom = 0.0
	thumbnail_carousel.add_child(thumbnail_host)

	arrow_left_button = _make_arrow_button("‹", -1)
	thumbnail_carousel.add_child(arrow_left_button)

	arrow_right_button = _make_arrow_button("›", 1)
	thumbnail_carousel.add_child(arrow_right_button)


func _make_arrow_button(arrow_text: String, delta: int) -> Button:
	var btn := Button.new()
	btn.name = "ArrowLeft" if delta < 0 else "ArrowRight"
	btn.text = arrow_text
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = ARROW_BUTTON_SIZE
	btn.size = ARROW_BUTTON_SIZE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 72)
	btn.add_theme_color_override("font_color", Color("f0d28a"))
	btn.add_theme_color_override("font_hover_color", Color("ffe9b8"))
	btn.add_theme_color_override("font_pressed_color", Color("d8b878"))
	btn.add_theme_color_override("font_focus_color", Color("f0d28a"))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0, 0.9))
	btn.add_theme_constant_override("outline_size", 6)
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.modulate = Color(1, 1, 1, 0.88)
	btn.pressed.connect(_move_selection.bind(delta))
	btn.mouse_entered.connect(func() -> void:
		btn.modulate = Color(1, 1, 1, 1.0)
	)
	btn.mouse_exited.connect(func() -> void:
		btn.modulate = Color(1, 1, 1, 0.88)
	)
	return btn


func _populate_thumbnail_carousel() -> void:
	if thumbnail_host == null:
		return
	for child in thumbnail_host.get_children():
		child.queue_free()
	thumbnail_buttons.clear()
	thumbnail_tweens.clear()

	for char_index in range(characters.size()):
		var character: Dictionary = characters[char_index]
		var btn := _make_thumbnail_button(character, char_index)
		btn.anchor_left = 0.0
		btn.anchor_top = 0.0
		btn.anchor_right = 0.0
		btn.anchor_bottom = 0.0
		btn.size = THUMBNAIL_BTN_SIZE
		btn.position = Vector2(-THUMBNAIL_BTN_SIZE.x * 0.5, -THUMBNAIL_BTN_SIZE.y)
		btn.modulate = Color(1, 1, 1, 0)
		thumbnail_host.add_child(btn)
		thumbnail_buttons[char_index] = btn


func _make_thumbnail_button(character: Dictionary, char_index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = THUMBNAIL_BTN_SIZE
	btn.size = THUMBNAIL_BTN_SIZE
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""
	btn.clip_contents = false
	btn.tooltip_text = "%s · %s" % [character.get("code", ""), character.get("name", "")]
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_meta("char_index", char_index)
	btn.pivot_offset = Vector2(THUMBNAIL_BTN_SIZE.x * 0.5, THUMBNAIL_BTN_SIZE.y)
	var thumb_empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", thumb_empty)
	btn.add_theme_stylebox_override("hover", thumb_empty)
	btn.add_theme_stylebox_override("pressed", thumb_empty)
	btn.add_theme_stylebox_override("focus", thumb_empty)
	btn.pressed.connect(func() -> void:
		_on_thumbnail_pressed(char_index)
	)

	var glow := TextureRect.new()
	glow.name = "SelectionGlow"
	glow.texture = soft_glow_texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.modulate = Color(1.0, 0.82, 0.42, 0.0)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = -48.0
	glow.offset_top = -48.0
	glow.offset_right = 48.0
	glow.offset_bottom = 48.0
	btn.add_child(glow)

	var halo := TextureRect.new()
	halo.name = "Halo"
	halo.texture = soft_glow_texture
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.modulate = Color(1.0, 0.78, 0.36, 0.0)
	halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	halo.offset_left = -16.0
	halo.offset_top = 44.0
	halo.offset_right = 16.0
	halo.offset_bottom = 8.0
	btn.add_child(halo)

	var image := TextureRect.new()
	image.name = "Portrait"
	image.texture = _get_portrait_texture(character)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 4.0
	image.offset_top = 0.0
	image.offset_right = -4.0
	image.offset_bottom = -22.0
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(image)

	var code_label := UIFactory.make_label(str(character.get("code", "")), 13, Color("d8b878"), false)
	code_label.name = "CodeLabel"
	code_label.anchor_left = 0.0
	code_label.anchor_top = 1.0
	code_label.anchor_right = 1.0
	code_label.anchor_bottom = 1.0
	code_label.offset_left = 0.0
	code_label.offset_top = -20.0
	code_label.offset_right = 0.0
	code_label.offset_bottom = -2.0
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_label.add_theme_constant_override("outline_size", 3)
	code_label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0, 0.85))
	btn.add_child(code_label)

	btn.mouse_entered.connect(func() -> void:
		if char_index != selected_index:
			_play_sfx("card_hover")
		if char_index == selected_index:
			return
		var portrait := btn.get_node_or_null("Portrait") as TextureRect
		if portrait == null:
			return
		var t := create_tween().set_parallel(true)
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(portrait, "scale", Vector2(1.08, 1.08), 0.12)
		t.tween_property(portrait, "position:y", -3, 0.12)
	)

	btn.mouse_exited.connect(func() -> void:
		if char_index == selected_index:
			return
		var portrait := btn.get_node_or_null("Portrait") as TextureRect
		if portrait == null:
			return
		var t := create_tween().set_parallel(true)
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(portrait, "scale", Vector2.ONE, 0.18)
		t.tween_property(portrait, "position:y", 0, 0.18)
	)

	return btn


func _on_thumbnail_pressed(char_index: int) -> void:
	if char_index == selected_index or is_switching:
		return
	_play_sfx("card_select")
	selected_index = char_index
	_refresh_selected()


func _signed_offset(char_index: int) -> int:
	var n := characters.size()
	if n == 0:
		return 0
	var diff := char_index - selected_index
	var half := int(floor(float(n) / 2.0))
	if diff > half:
		diff -= n
	elif diff < -half:
		diff += n
	return diff


func _carousel_slot_x(display_offset: int) -> float:
	return float(display_offset) * CAROUSEL_ITEM_SPACING


func _refresh_carousel(animate: bool = true) -> void:
	if characters.is_empty():
		return
	for char_index_variant in thumbnail_buttons:
		var char_index := int(char_index_variant)
		var btn: Button = thumbnail_buttons[char_index] as Button
		if btn == null:
			continue
		var offset := _signed_offset(char_index)
		var abs_off := absi(offset)
		var is_visible := abs_off <= CAROUSEL_VISIBLE_SIDE
		var display_offset: int
		if is_visible:
			display_offset = offset
		elif offset > 0:
			display_offset = CAROUSEL_VISIBLE_SIDE + 1
		else:
			display_offset = -(CAROUSEL_VISIBLE_SIDE + 1)
		var is_selected := char_index == selected_index
		var edge_distance := maxi(0, abs_off - (CAROUSEL_VISIBLE_SIDE - 2))
		var alpha := maxf(0.0, 1.0 - float(edge_distance) * CAROUSEL_EDGE_ALPHA_STEP) if is_visible else 0.0
		var tint: Color
		if is_selected:
			tint = Color(1.0, 1.0, 1.0, alpha)
		else:
			tint = Color(0.82, 0.76, 0.66, alpha * 0.92)

		var scale_val := CAROUSEL_SELECTED_SCALE if is_selected else CAROUSEL_ITEM_SCALE
		var target_pos := Vector2(_carousel_slot_x(display_offset) - THUMBNAIL_BTN_SIZE.x * 0.5, -THUMBNAIL_BTN_SIZE.y)
		var target_scale := Vector2(scale_val, scale_val)

		btn.z_index = 100 if is_selected else (CAROUSEL_VISIBLE_SIDE + 1 - abs_off)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE

		var existing = thumbnail_tweens.get(char_index)
		if existing is Tween and existing.is_valid():
			existing.kill()

		var glow := btn.get_node_or_null("SelectionGlow") as TextureRect
		var halo := btn.get_node_or_null("Halo") as TextureRect
		var target_glow := Color(1.0, 0.82, 0.42, 0.85) if is_selected else Color(1.0, 0.82, 0.42, 0.0)
		var target_halo := Color(1.0, 0.78, 0.36, 0.95) if is_selected else Color(1.0, 0.78, 0.36, 0.0)

		if animate:
			var delay := float(absi(offset)) * 0.022
			var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "position", target_pos, CAROUSEL_TRANSITION).set_delay(delay)
			tween.tween_property(btn, "scale", target_scale, CAROUSEL_TRANSITION).set_delay(delay)
			tween.tween_property(btn, "modulate", tint, CAROUSEL_TRANSITION).set_delay(delay)
			if glow != null:
				tween.tween_property(glow, "modulate", target_glow, CAROUSEL_TRANSITION).set_delay(delay)
			if halo != null:
				tween.tween_property(halo, "modulate", target_halo, CAROUSEL_TRANSITION).set_delay(delay)
			thumbnail_tweens[char_index] = tween
		else:
			btn.position = target_pos
			btn.scale = target_scale
			btn.modulate = tint
			if glow != null:
				glow.modulate = target_glow
			if halo != null:
				halo.modulate = target_halo

		var existing_halo = halo_tweens.get(char_index)
		if existing_halo is Tween and existing_halo.is_valid():
			existing_halo.kill()
			halo_tweens.erase(char_index)
		if is_selected and glow != null:
			var pulse := create_tween()
			pulse.set_loops()
			pulse.set_trans(Tween.TRANS_SINE)
			pulse.set_ease(Tween.EASE_IN_OUT)
			pulse.tween_property(glow, "modulate", Color(1.0, 0.82, 0.42, 0.95), 0.9)
			pulse.parallel().tween_property(glow, "scale", Vector2(1.06, 1.06), 0.9)
			pulse.tween_property(glow, "modulate", Color(1.0, 0.82, 0.42, 0.65), 0.9)
			pulse.parallel().tween_property(glow, "scale", Vector2(0.97, 0.97), 0.9)
			halo_tweens[char_index] = pulse

		var code_label := btn.get_node_or_null("CodeLabel") as Label
		if code_label != null:
			code_label.add_theme_color_override("font_color", Color("f5e3b8") if is_selected else Color("b69670"))


func _make_profile_panel_style() -> StyleBox:
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 8
	style.content_margin_top = 12
	style.content_margin_right = 8
	style.content_margin_bottom = 12
	return style


func _deferred_init() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_populate_thumbnail_carousel()
	_refresh_selected(false)


func _refresh_selected(animate: bool = true) -> void:
	if characters.is_empty():
		return
	if confirm_ribbon != null:
		confirm_ribbon.title_text = "登场"
		confirm_ribbon.queue_redraw()
	_refresh_layout()
	_apply_selected_character(animate)
	_refresh_carousel(animate)
	previous_selected_index = selected_index


func _apply_selected_character(animated: bool = false) -> void:
	var character: Dictionary = characters[selected_index]
	var ambient_color := _get_character_ambient_color(character)

	if animated and ambient_tween != null and ambient_tween.is_valid():
		ambient_tween.kill()
	if animated:
		ambient_tween = create_tween()
		ambient_tween.set_trans(Tween.TRANS_CUBIC)
		ambient_tween.set_ease(Tween.EASE_IN_OUT)
		ambient_tween.tween_property(spotlight_rect, "modulate", ambient_color, 0.5)
	else:
		spotlight_rect.modulate = ambient_color

	if animated and card_transform != null and main_card_image.texture != null and main_card_image.modulate.a > 0.0:
		is_switching = true
		_stop_card_breath()

		var out := create_tween().set_parallel(true)
		out.set_trans(Tween.TRANS_CUBIC)
		out.set_ease(Tween.EASE_IN)
		out.tween_property(card_transform, "position:x", -100, 0.15)
		out.parallel().tween_property(card_transform, "position:y", 20, 0.15)
		out.parallel().tween_property(card_transform, "rotation", deg_to_rad(-12), 0.15)
		out.parallel().tween_property(card_transform, "scale", Vector2(0.88, 0.88), 0.15)
		out.parallel().tween_property(card_transform, "modulate:a", 0.0, 0.13)
		out.parallel().tween_property(profile_panel, "modulate:a", 0.0, 0.10)
		await out.finished

		main_card_image.texture = _get_card_texture(character)
		_update_main_card_title_overlay(character)
		_update_main_card_skill_overlay(character)
		_update_profile_panel(character)

		card_transform.position = Vector2(100, -15)
		card_transform.rotation = deg_to_rad(12)
		card_transform.scale = Vector2(0.88, 0.88)
		card_transform.modulate.a = 0.0
		main_card_title_overlay.modulate.a = 0.0
		main_card_skill_overlay.modulate.a = 0.0
		profile_panel.modulate.a = 0.0
		profile_title_label.visible_ratio = 0.0
		profile_skills_label.visible_ratio = 0.0

		var inn := create_tween().set_parallel(true)
		inn.set_trans(Tween.TRANS_CUBIC)
		inn.set_ease(Tween.EASE_OUT)
		inn.tween_property(card_transform, "position", Vector2.ZERO, 0.20)
		inn.parallel().tween_property(card_transform, "rotation", 0.0, 0.20)
		inn.parallel().tween_property(card_transform, "scale", Vector2(1.04, 1.04), 0.18)
		inn.parallel().tween_property(card_transform, "modulate:a", 1.0, 0.20)
		inn.parallel().tween_property(profile_panel, "modulate:a", 1.0, 0.18)
		inn.parallel().tween_property(main_card_title_overlay, "modulate:a", 1.0, 0.14).set_delay(0.08)
		inn.parallel().tween_property(main_card_skill_overlay, "modulate:a", 1.0, 0.16).set_delay(0.12)
		await inn.finished

		var settle := create_tween()
		settle.set_trans(Tween.TRANS_BACK)
		settle.set_ease(Tween.EASE_OUT)
		settle.tween_property(card_transform, "scale", Vector2.ONE, 0.16)
		await settle.finished

		var type_tween := create_tween().set_parallel(true)
		type_tween.set_trans(Tween.TRANS_LINEAR)
		type_tween.tween_property(profile_title_label, "visible_ratio", 1.0, 0.6).set_delay(0.05)
		type_tween.tween_property(profile_skills_label, "visible_ratio", 1.0, 1.0).set_delay(0.25)

		_start_card_breath()

		is_switching = false
	else:
		main_card_image.texture = _get_card_texture(character)
		_update_main_card_title_overlay(character)
		_update_main_card_skill_overlay(character)
		_update_profile_panel(character)
		if card_transform != null:
			card_transform.position = Vector2.ZERO
			card_transform.rotation = 0.0
			card_transform.scale = Vector2.ONE
			card_transform.modulate.a = 1.0
		profile_panel.modulate.a = 1.0
		if main_card_title_overlay != null:
			main_card_title_overlay.modulate.a = 1.0
		if main_card_skill_overlay != null:
			main_card_skill_overlay.modulate.a = 1.0
		spotlight_rect.modulate = ambient_color
		profile_title_label.visible_ratio = 1.0
		profile_skills_label.visible_ratio = 1.0
		_start_card_breath()


func _update_main_card_title_overlay(_character: Dictionary) -> void:
	for child in main_card_title_overlay.get_children():
		child.queue_free()


func _update_main_card_skill_overlay(character: Dictionary) -> void:
	for child in main_card_skill_overlay.get_children():
		child.queue_free()
	var skills: Dictionary = character.get("skills", {})
	var quote: String = str(character.get("quote", ""))

	if not quote.is_empty():
		var quote_label := RichTextLabel.new()
		quote_label.bbcode_enabled = true
		quote_label.fit_content = true
		quote_label.scroll_active = false
		quote_label.selection_enabled = false
		quote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quote_label.text = "[center][font_size=15][color=#6a4a24][i]「%s」[/i][/color][/font_size][/center]" % quote
		main_card_skill_overlay.add_child(quote_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	main_card_skill_overlay.add_child(spacer)

	var rows := [
		{"label": "主角", "skill": skills.get("hero", {}), "label_color": "#8a3810", "dot_color": "#c97a2a"},
		{"label": "伙伴", "skill": skills.get("ally", {}), "label_color": "#1a3560", "dot_color": "#3a6db0"},
		{"label": "敌人", "skill": skills.get("enemy", {}), "label_color": "#7a1a14", "dot_color": "#a8362c"},
	]
	for row in rows:
		var skill: Dictionary = row.get("skill", {})
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.selection_enabled = false
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text = "[center][font_size=21][color=%s]◆[/color]  [color=%s]%s[/color]    [color=#2a1810]%s[/color][/font_size][/center]" % [
			row["dot_color"],
			row["label_color"],
			row["label"],
			skill.get("name", "")
		]
		main_card_skill_overlay.add_child(line)


func _update_profile_panel(character: Dictionary) -> void:
	var code := str(character.get("code", ""))
	var name_text := str(character.get("name", ""))
	var hp := int(character.get("hp", 0))
	var charm_pct := int(round(float(character.get("charm", 0.5)) * 100.0))
	var hearts := maxi(1, int(ceil(float(hp) / float(HP_PER_HEART))))
	var hearts_str := "❤".repeat(hearts)

	var title_line: String
	if name_text.is_empty():
		title_line = "[font_size=48][color=#f0d28a]%s[/color][/font_size]" % code
	else:
		title_line = "[font_size=48][color=#f0d28a]%s[/color][/font_size]  [font_size=22][color=#a8884a]· %s[/color][/font_size]" % [code, name_text]
	var stats_line := "[font_size=26][color=#d83030]%s[/color]    [color=#5a8eb0]✦ %d[/color][/font_size]" % [hearts_str, charm_pct]
	profile_title_label.text = "%s\n%s" % [title_line, stats_line]

	var skills: Dictionary = character.get("skills", {})
	var sections := PackedStringArray()
	sections.append(_format_profile_skill_section("主角", skills.get("hero", {})))
	sections.append(_format_profile_skill_section("伙伴", skills.get("ally", {})))
	sections.append(_format_profile_skill_section("敌人", skills.get("enemy", {})))
	profile_skills_label.text = "\n\n\n".join(sections)

	profile_title_label.visible_ratio = 0.0
	profile_skills_label.visible_ratio = 0.0


func _format_profile_skill_section(label: String, skill: Dictionary) -> String:
	return (
		"[font_size=20][color=#a8884a]%s · %s[/color][/font_size]\n"
		+ "[font_size=29][color=#ece0c4]%s[/color][/font_size]"
	) % [
		label,
		skill.get("name", ""),
		skill.get("description", "")
	]


func _refresh_layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var available_height := size.y - 50.0 - (CAROUSEL_CONTAINER_HEIGHT + CAROUSEL_BOTTOM_MARGIN) - 24.0
	var card_height := minf(MAIN_CARD_TARGET_HEIGHT, available_height)
	if card_height < 320.0:
		card_height = 320.0
	var card_width := card_height * MAIN_CARD_ASPECT
	var card_center_y := 50.0 + available_height * 0.5
	var card_center_x := size.x * 0.30
	var card_left := card_center_x - card_width * 0.5
	var card_top := card_center_y - card_height * 0.5

	main_card_button.size = Vector2(card_width, card_height)
	main_card_button.position = Vector2(card_left, card_top)
	main_card_button.pivot_offset = main_card_button.size * 0.5

	if card_transform != null:
		card_transform.pivot_offset = card_transform.size * 0.5

	var title_left := card_width * 0.08
	var title_top := card_height * 0.04
	var title_bottom := card_height * 0.20
	main_card_title_overlay.position = Vector2(title_left, title_top)
	main_card_title_overlay.size = Vector2(card_width - title_left * 2.0, title_bottom - title_top)

	var overlay_left := card_width * 0.08
	var overlay_top := card_height * 0.58
	var overlay_bottom := card_height * 0.86
	main_card_skill_overlay.position = Vector2(overlay_left, overlay_top)
	main_card_skill_overlay.size = Vector2(card_width - overlay_left * 2.0, overlay_bottom - overlay_top)

	if spotlight_rect != null:
		var sw := card_width * 3.4
		var sh := card_height * 2.6
		spotlight_rect.position = Vector2(card_center_x - sw * 0.5, card_top - sh * 0.28)
		spotlight_rect.size = Vector2(sw, sh)

	var profile_left := clampf(maxf(card_left + card_width + 40.0, size.x * 0.46), 0.0, size.x - PROFILE_PANEL_WIDTH - 64.0)
	var profile_top := card_top - 60.0
	var profile_height := card_height + 12.0
	profile_panel.position = Vector2(profile_left, profile_top)
	profile_panel.size = Vector2(PROFILE_PANEL_WIDTH, profile_height)

	if connector_line != null and connector_dot != null:
		var card_right := card_left + card_width
		var conn_y := card_center_y - 1.5
		connector_line.position = Vector2(card_right, conn_y)
		connector_line.size = Vector2(maxf(0.0, profile_left - card_right), 3.0)
		var dot_size := 14.0
		var dot_x := card_right + (profile_left - card_right) * 0.5 - dot_size * 0.5
		var dot_y := card_center_y - dot_size * 0.5
		connector_dot.position = Vector2(dot_x, dot_y)
		connector_dot.size = Vector2(dot_size, dot_size)


	var btn_x := profile_left + (PROFILE_PANEL_WIDTH - confirm_button.size.x) * 0.5
	var btn_y := profile_top + profile_height + 16.0
	var max_btn_y := size.y - confirm_button.size.y - (CAROUSEL_CONTAINER_HEIGHT + CAROUSEL_BOTTOM_MARGIN + 14.0)
	btn_y = minf(btn_y, max_btn_y)
	confirm_button.position = Vector2(btn_x, btn_y)

	if thumbnail_carousel != null:
		var arrow_top := thumbnail_carousel.size.y - THUMBNAIL_BTN_SIZE.y * 0.5 - ARROW_BUTTON_SIZE.y * 0.5
		if arrow_left_button != null:
			arrow_left_button.size = ARROW_BUTTON_SIZE
			arrow_left_button.position = Vector2(ARROW_HORIZONTAL_MARGIN, arrow_top)
		if arrow_right_button != null:
			arrow_right_button.size = ARROW_BUTTON_SIZE
			arrow_right_button.position = Vector2(
				thumbnail_carousel.size.x - ARROW_HORIZONTAL_MARGIN - ARROW_BUTTON_SIZE.x,
				arrow_top
			)


func _on_confirm_hover_changed(is_hover: bool) -> void:
	if confirm_ribbon == null:
		return
	confirm_ribbon.fill_color = Color("8a1a1f") if is_hover else Color("6b1218")
	confirm_ribbon.title_color = Color("ffe9b8") if is_hover else Color("f0d28a")
	confirm_ribbon.queue_redraw()


func _on_confirm_pressed() -> void:
	if characters.is_empty():
		return
	hero_confirmed.emit(characters[selected_index].duplicate(true))


func _move_selection(delta: int) -> void:
	if characters.is_empty() or is_switching:
		return
	_play_sfx("card_select")
	selected_index = posmod(selected_index + delta, characters.size())
	_refresh_selected()


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


func _load_image_from_disk(res_path: String) -> Image:
	if res_path.is_empty():
		return null
	var candidate_paths: Array[String] = []
	var global_path := ProjectSettings.globalize_path(res_path)
	if global_path != res_path:
		candidate_paths.append(global_path)
	elif not res_path.begins_with("res://"):
		candidate_paths.append(res_path)
	for candidate_path in candidate_paths:
		if not FileAccess.file_exists(candidate_path):
			continue
		var image := Image.load_from_file(candidate_path)
		if image == null:
			continue
		if image.get_width() <= 0 or image.get_height() <= 0:
			continue
		return image
	return null


func _load_texture_from_disk(res_path: String) -> Texture2D:
	var image := _load_image_from_disk(res_path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func _get_select_background_texture() -> Texture2D:
	var disk_texture := _load_texture_from_disk(SELECT_BACKGROUND_PATH)
	if disk_texture != null:
		return disk_texture
	if ResourceLoader.exists(SELECT_BACKGROUND_PATH):
		return load(SELECT_BACKGROUND_PATH) as Texture2D
	push_error("Missing select background: %s" % SELECT_BACKGROUND_PATH)
	return null


func _get_card_texture(character: Dictionary) -> Texture2D:
	var code := str(character.get("code", ""))
	if card_texture_cache.has(code):
		return card_texture_cache[code]
	var image_path := str(character.get("image_path", ""))
	var texture := _load_texture_from_disk(image_path)
	if texture == null and ResourceLoader.exists(image_path):
		texture = load(image_path) as Texture2D
	card_texture_cache[code] = texture
	return texture


func _get_portrait_texture(character: Dictionary) -> Texture2D:
	var code := str(character.get("code", ""))
	if portrait_texture_cache.has(code):
		return portrait_texture_cache[code]
	var candidates := [
		"res://assets/portraits/cutout/ally/%s.png" % code,
		"res://assets/portraits/subject/ally/%s.png" % code,
		str(character.get("image_path", "")),
	]
	for path in candidates:
		if path.is_empty():
			continue
		var texture := _load_texture_from_disk(path)
		if texture == null and ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		if texture != null:
			portrait_texture_cache[code] = texture
			return texture
	portrait_texture_cache[code] = null
	return null


func _generate_soft_glow_texture() -> Texture2D:
	if soft_glow_texture != null:
		return soft_glow_texture
	var size_px := 256
	var image := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var center := Vector2(size_px * 0.5, size_px * 0.5)
	var radius := size_px * 0.46
	for y in range(size_px):
		for x in range(size_px):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := pow(clampf(1.0 - dist / radius, 0.0, 1.0), 3.6) * 0.48
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	soft_glow_texture = ImageTexture.create_from_image(image)
	return soft_glow_texture


func _start_card_breath() -> void:
	pass


func _stop_card_breath() -> void:
	pass


func _on_card_mouse_entered() -> void:
	is_card_hovered = true
	_play_sfx("card_hover")


func _on_card_mouse_exited() -> void:
	is_card_hovered = false


func _play_sfx(key: String) -> void:
	var audio := GameAudio.get_shared(self)
	if audio != null:
		audio.play_sfx(key)


func _get_character_ambient_color(character: Dictionary) -> Color:
	var code := str(character.get("code", ""))
	if code.is_empty():
		return AMBIENT_PRESETS[0]
	var hash_val := code.hash()
	var idx := absi(hash_val) % AMBIENT_PRESETS.size()
	return AMBIENT_PRESETS[idx]


func _unhandled_input(event: InputEvent) -> void:
	if characters.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				_move_selection(-1)
			KEY_RIGHT, KEY_D:
				_move_selection(1)
			KEY_ENTER, KEY_KP_ENTER:
				_on_confirm_pressed()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_move_selection(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_move_selection(1)


class GoldDivider extends Control:
	var color_strong: Color = Color("c9a04c")
	var color_fade: Color = Color(0.79, 0.63, 0.30, 0.0)
	var line_height: float = 1.6

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0.0 or h <= 0.0:
			return
		var y := (h - line_height) * 0.5
		var pts := PackedVector2Array([
			Vector2(0, y),
			Vector2(w, y),
			Vector2(w, y + line_height),
			Vector2(0, y + line_height),
		])
		var cols := PackedColorArray([
			color_strong,
			color_fade,
			color_fade,
			color_strong,
		])
		draw_polygon(pts, cols)
