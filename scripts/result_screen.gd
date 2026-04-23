extends Control

signal replay_requested
signal theater_requested

const GameState = preload("res://scripts/game_state.gd")
const RibbonBanner = preload("res://scripts/ui/ribbon_banner.gd")
const TheaterModal = preload("res://scripts/ui/theater_modal.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const ButtonFeedback = preload("res://scripts/ui/button_feedback.gd")
const UIFactory = preload("res://scripts/ui_factory.gd")

const ENTRANCE_RITUALS_PATH := "res://data/entrance_rituals.json"
const RESULT_VICTORY_BACKGROUND_PATH := "res://assets/backgrounds/screens/title.png"
const RESULT_DEFEAT_BACKGROUND_PATH := "res://assets/backgrounds/screens/battle.png"

var state: GameState
var result_texture_cache := {}
var ritual_manifest_loaded := false
var ritual_manifest_entries := {}

var background_host: Control
var background_rect: TextureRect
var background_texture: Texture2D
var backdrop_tint: ColorRect
var vignette_rect: ColorRect
var global_spotlight: TextureRect

var outer_margin: MarginContainer
var title_banner: RibbonBanner
var persona_label: Label
var cast_stage: Control
var stage_spotlight: TextureRect
var stage_floor_shadow: TextureRect
var stage_floor_glow: TextureRect
var hero_actor: Control
var ally_actor_nodes := []

var stats_panel: Control
var stats_margin: MarginContainer
var stat_hp_value: Label
var stat_round_value: Label
var stat_ally_value: Label

var button_row: HBoxContainer
var theater_button: Button
var replay_button: Button

var soft_glow_texture: Texture2D
var status_scroll_texture: Texture2D
var progress_card_texture: Texture2D
var hp_heart_texture: Texture2D
var ally_gem_texture: Texture2D

var intro_played := false
var intro_tween: Tween
var float_tweens: Array[Tween] = []
var ambient_particles: GPUParticles2D


func setup(next_state: GameState) -> void:
	state = next_state


func _ready() -> void:
	_load_theme_textures()
	_build_background()
	_build_ui()
	_refresh_content()
	call_deferred("_refresh_background_layout")
	call_deferred("_layout_result_screen")


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	call_deferred("_refresh_background_layout")
	call_deferred("_layout_result_screen")


func _load_theme_textures() -> void:
	soft_glow_texture = _generate_soft_glow_texture()
	background_texture = _load_result_background_texture()
	status_scroll_texture = _load_first_texture(["res://assets/ui/theater/status_scroll.png"])
	progress_card_texture = _load_first_texture(["res://assets/ui/theater/progress_card.png"])
	hp_heart_texture = _load_first_texture(["res://assets/ui/theater/hp_heart.png"])
	ally_gem_texture = _load_first_texture([
		"res://assets/ui/theater/gem_blue.png",
		"res://assets/ui/theater/gem_green.png",
	])


func _load_result_background_texture() -> Texture2D:
	var path := RESULT_VICTORY_BACKGROUND_PATH if state != null and state.victory else RESULT_DEFEAT_BACKGROUND_PATH
	return _load_first_texture([path])


func _build_background() -> void:
	var base := ColorRect.new()
	base.color = Color("090403")
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
	background_rect.texture = background_texture if background_texture != null else soft_glow_texture
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_host.add_child(background_rect)

	backdrop_tint = ColorRect.new()
	backdrop_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_tint.color = Color(0.28, 0.11, 0.06, 0.24) if state.victory else Color(0.08, 0.10, 0.20, 0.44)
	backdrop_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop_tint)

	global_spotlight = TextureRect.new()
	global_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	global_spotlight.texture = soft_glow_texture
	global_spotlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	global_spotlight.stretch_mode = TextureRect.STRETCH_SCALE
	global_spotlight.modulate = Color(1.0, 0.82, 0.48, 0.16) if state.victory else Color(0.75, 0.70, 1.0, 0.10)
	add_child(global_spotlight)

	vignette_rect = ColorRect.new()
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_rect.color = Color(0, 0, 0, 0.18) if state.victory else Color(0, 0, 0, 0.34)
	vignette_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette_rect)


func _build_ui() -> void:
	outer_margin = MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer_margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 22)
	outer_margin.add_child(root)

	var header_stack := VBoxContainer.new()
	header_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	header_stack.add_theme_constant_override("separation", 8)
	root.add_child(header_stack)

	var title_center := CenterContainer.new()
	title_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_stack.add_child(title_center)

	title_banner = RibbonBanner.new()
	title_banner.fill_color = Color("6b1218")
	title_banner.border_color = Color("c9a04c")
	title_banner.border_width = 2.5
	title_banner.cut_depth = 24.0
	title_banner.title_text = _get_result_label()
	title_banner.title_color = Color("f0d28a")
	title_banner.title_outline = Color(0.10, 0.03, 0.02, 0.94)
	title_banner.title_outline_size = 6
	title_banner.title_font_size = 34
	title_center.add_child(title_banner)

	cast_stage = Control.new()
	cast_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cast_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cast_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cast_stage.custom_minimum_size = Vector2(0, 340)
	root.add_child(cast_stage)

	stage_spotlight = TextureRect.new()
	stage_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_spotlight.texture = soft_glow_texture
	stage_spotlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_spotlight.stretch_mode = TextureRect.STRETCH_SCALE
	stage_spotlight.modulate = Color(1.0, 0.86, 0.55, 0.28) if state.victory else Color(0.80, 0.78, 1.0, 0.16)
	cast_stage.add_child(stage_spotlight)

	stage_floor_shadow = TextureRect.new()
	stage_floor_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_floor_shadow.texture = soft_glow_texture
	stage_floor_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_floor_shadow.stretch_mode = TextureRect.STRETCH_SCALE
	stage_floor_shadow.modulate = Color(0.10, 0.04, 0.02, 0.34) if state.victory else Color(0.04, 0.06, 0.10, 0.38)
	cast_stage.add_child(stage_floor_shadow)

	stage_floor_glow = TextureRect.new()
	stage_floor_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_floor_glow.texture = soft_glow_texture
	stage_floor_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_floor_glow.stretch_mode = TextureRect.STRETCH_SCALE
	stage_floor_glow.modulate = Color(1.0, 0.84, 0.48, 0.22) if state.victory else Color(0.66, 0.76, 1.0, 0.18)
	cast_stage.add_child(stage_floor_glow)

	hero_actor = _build_cast_actor(true)
	cast_stage.add_child(hero_actor)
	_rebuild_ally_actors()

	persona_label = UIFactory.make_label("", 24, Color("f5e2b7"), true)
	persona_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	persona_label.add_theme_constant_override("outline_size", 4)
	persona_label.add_theme_color_override("font_outline_color", Color(0.14, 0.04, 0.02, 0.88))
	persona_label.z_index = 170
	cast_stage.add_child(persona_label)

	var stats_center := CenterContainer.new()
	stats_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_center.custom_minimum_size = Vector2(0, 56)
	root.add_child(stats_center)

	stats_panel = _build_stats_panel()
	stats_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stats_center.add_child(stats_panel)

	var button_center := CenterContainer.new()
	button_center.custom_minimum_size = Vector2(0, 70)
	root.add_child(button_center)

	button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 20)
	button_center.add_child(button_row)

	theater_button = TheaterModal.make_option_button("返回首页", "secondary")
	theater_button.pressed.connect(func() -> void:
		ButtonFeedback.spawn_ripple(self, theater_button.global_position + theater_button.size * 0.5)
		theater_requested.emit()
	)
	button_row.add_child(theater_button)
	ButtonFeedback.add_press_feedback(theater_button)

	replay_button = TheaterModal.make_option_button(_get_replay_label(), "primary")
	replay_button.pressed.connect(func() -> void:
		ButtonFeedback.spawn_ripple(self, replay_button.global_position + replay_button.size * 0.5)
		replay_requested.emit()
	)
	button_row.add_child(replay_button)
	ButtonFeedback.add_press_feedback(replay_button)


func _build_stats_panel() -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(520, 56)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.03, 0.015, 0.72)
	bg.border_color = Color(0.72, 0.56, 0.28, 0.35)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 12
	bg.corner_radius_top_right = 12
	bg.corner_radius_bottom_left = 12
	bg.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", bg)

	stats_margin = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 16)
	stats_margin.add_theme_constant_override("margin_top", 8)
	stats_margin.add_theme_constant_override("margin_right", 16)
	stats_margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(stats_margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	stats_margin.add_child(row)

	var hp_item := _make_stat_item(hp_heart_texture, "♥", Color("ff8c98"))
	row.add_child(hp_item[0])
	stat_hp_value = hp_item[1] as Label

	var round_item := _make_stat_item(progress_card_texture, "⚡", Color("f0c977"))
	row.add_child(round_item[0])
	stat_round_value = round_item[1] as Label
	stat_ally_value = null

	return panel


func _make_stat_item(texture: Texture2D, fallback_icon: String, tint: Color) -> Array:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 12)

	if texture != null:
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		icon.modulate = tint
		item.add_child(icon)
	else:
		var icon_label := UIFactory.make_label(fallback_icon, 28, tint, true)
		item.add_child(icon_label)

	var value := UIFactory.make_label("", 28, Color("f6e9c7"), true)
	value.add_theme_constant_override("outline_size", 4)
	value.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.02, 0.88))
	value.custom_minimum_size = Vector2(80, 0)
	value.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.add_child(value)
	return [item, value]


func _build_cast_actor(is_hero: bool) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = false

	var halo := TextureRect.new()
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.texture = soft_glow_texture
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(halo)

	var shadow := TextureRect.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.texture = soft_glow_texture
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.modulate = Color(0.08, 0.02, 0.01, 0.42)
	root.add_child(shadow)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(portrait)

	var label := UIFactory.make_label("", 18 if is_hero else 15, Color("f5e2b7"), true)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("outline_size", 5 if is_hero else 4)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.02, 0.92))
	root.add_child(label)

	root.set_meta("halo", halo)
	root.set_meta("shadow", shadow)
	root.set_meta("portrait", portrait)
	root.set_meta("label", label)
	root.set_meta("is_hero", is_hero)
	return root


func _rebuild_ally_actors() -> void:
	for actor in ally_actor_nodes:
		if actor != null:
			actor.queue_free()
	ally_actor_nodes.clear()


func _refresh_content() -> void:
	if state == null:
		return

	title_banner.title_text = _get_result_label()
	title_banner.fill_color = Color("6b1218") if state.victory else Color("34121d")
	title_banner.border_color = Color("c9a04c") if state.victory else Color("9d6a78")
	title_banner.title_color = Color("f0d28a") if state.victory else Color("f2d1d9")
	title_banner.queue_redraw()

	persona_label.text = _get_persona_text()
	persona_label.modulate = Color.WHITE

	stat_hp_value.text = "%d/%d" % [state.hp, state.displayed_hp_capacity()]
	stat_round_value.text = "%d/%d" % [state.revealed_cards(), state.total_cards()]
	if stat_ally_value != null:
		stat_ally_value.text = state.ally_slot_summary()

	_apply_cast_actor(hero_actor, state.player_character, true)

	_set_button_text(theater_button, "返回首页")
	_set_button_text(replay_button, _get_replay_label())


func _apply_cast_actor(actor: Control, character: Dictionary, is_hero: bool) -> void:
	if actor == null:
		return

	var halo := actor.get_meta("halo") as TextureRect
	var shadow := actor.get_meta("shadow") as TextureRect
	var portrait := actor.get_meta("portrait") as TextureRect
	var label := actor.get_meta("label") as Label

	var entry := _get_ritual_entry(character)
	var base_color := _color_from_entry(entry, "halo_color", _get_default_actor_color(is_hero))
	var accent_color := _color_from_entry(entry, "halo_accent", base_color.lightened(0.32))
	var halo_texture_path := str(entry.get("halo_texture", ""))

	if halo != null:
		halo.texture = _load_texture_from_disk(halo_texture_path) if not halo_texture_path.is_empty() else soft_glow_texture
		if halo.texture == null:
			halo.texture = soft_glow_texture
		var halo_alpha := 0.86 if is_hero and state.victory else (0.70 if is_hero else 0.52)
		if not state.victory:
			halo_alpha *= 0.80
		halo.modulate = Color(base_color.r, base_color.g, base_color.b, halo_alpha)

	if shadow != null:
		shadow.modulate = Color(0.08, 0.02, 0.01, 0.34) if state.victory else Color(0.02, 0.04, 0.10, 0.44)

	if portrait != null:
		portrait.texture = _get_stage_pose_texture(character)
		portrait.modulate = Color.WHITE

	if label != null:
		label.text = _get_actor_label_text(character, is_hero)
		label.add_theme_color_override("font_color", accent_color.lerp(Color("f6e2b9"), 0.34))
		label.visible = not is_hero


func _layout_result_screen() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var margin_x := int(clampf(size.x * 0.045, 28.0, 72.0))
	var margin_top := int(clampf(size.y * 0.040, 20.0, 44.0))
	var margin_bottom := int(clampf(size.y * 0.032, 16.0, 36.0))
	outer_margin.add_theme_constant_override("margin_left", margin_x)
	outer_margin.add_theme_constant_override("margin_right", margin_x)
	outer_margin.add_theme_constant_override("margin_top", margin_top)
	outer_margin.add_theme_constant_override("margin_bottom", margin_bottom)

	var banner_width := clampf(size.x * 0.42, 420.0, 660.0)
	var banner_height := clampf(size.y * 0.090, 64.0, 92.0)
	title_banner.custom_minimum_size = Vector2(banner_width, banner_height)
	title_banner.size = title_banner.custom_minimum_size
	title_banner.title_font_size = int(clampf(size.y * 0.040, 28.0, 40.0))
	title_banner.cut_depth = clampf(banner_width * 0.050, 20.0, 30.0)
	title_banner.queue_redraw()

	theater_button.custom_minimum_size = Vector2(clampf(size.x * 0.18, 220.0, 280.0), 54.0)
	replay_button.custom_minimum_size = Vector2(clampf(size.x * 0.22, 250.0, 320.0), 56.0)
	button_row.add_theme_constant_override("separation", int(clampf(size.x * 0.018, 16.0, 28.0)))

	_refresh_background_layout()
	_layout_cast_stage()

	if not intro_played:
		intro_played = true
		_play_result_animation()


func _refresh_background_layout() -> void:
	if background_host == null or background_rect == null:
		return
	var host_size := background_host.size
	if host_size.x <= 0.0 or host_size.y <= 0.0:
		return

	var texture := background_rect.texture
	if texture != null:
		var texture_size := texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			var scale := maxf(host_size.x / texture_size.x, host_size.y / texture_size.y)
			var scaled_size := texture_size * scale
			background_rect.size = scaled_size
			background_rect.position = (host_size - scaled_size) * 0.5
		else:
			background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if global_spotlight != null:
		global_spotlight.size = Vector2(host_size.x * 0.88, host_size.y * 0.88)
		global_spotlight.position = Vector2(
			(host_size.x - global_spotlight.size.x) * 0.5,
			host_size.y * -0.06
		)


func _layout_cast_stage() -> void:
	if cast_stage == null:
		return
	var stage_size := cast_stage.size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return

	if stage_spotlight != null:
		stage_spotlight.size = Vector2(stage_size.x * 0.74, stage_size.y * 1.06)
		stage_spotlight.position = Vector2(
			(stage_size.x - stage_spotlight.size.x) * 0.5,
			-stage_size.y * 0.14
		)

	var ground_line := stage_size.y * 0.79
	if stage_floor_shadow != null:
		stage_floor_shadow.size = Vector2(
			clampf(stage_size.x * 0.36, 260.0, 460.0),
			clampf(stage_size.y * 0.10, 38.0, 72.0)
		)
		stage_floor_shadow.position = Vector2(
			(stage_size.x - stage_floor_shadow.size.x) * 0.5,
			ground_line - stage_floor_shadow.size.y * 0.08
		)

	if stage_floor_glow != null:
		stage_floor_glow.size = Vector2(
			clampf(stage_size.x * 0.44, 360.0, 620.0),
			clampf(stage_size.y * 0.18, 86.0, 128.0)
		)
		stage_floor_glow.position = Vector2(
			(stage_size.x - stage_floor_glow.size.x) * 0.5,
			ground_line - stage_floor_glow.size.y * 0.44
		)

	var hero_size := Vector2(
		clampf(stage_size.x * 0.26, 200.0, 300.0),
		clampf(stage_size.y * 0.58, 180.0, 300.0)
	)
	var hero_focus_x := stage_size.x * 0.5 - clampf(stage_size.x * 0.026, 26.0, 46.0)
	_layout_cast_actor(hero_actor, hero_size, true)

	# Position hero so feet are near ground_line
	hero_actor.position = Vector2(
		hero_focus_x - hero_size.x * 0.5,
		ground_line - hero_size.y * 1.02
	)
	hero_actor.z_index = 160

	# Position persona_label directly above hero_actor
	if persona_label != null:
		var name_font_size := int(clampf(stage_size.y * 0.075, 22.0, 36.0))
		persona_label.add_theme_font_size_override("font_size", name_font_size)
		var label_width := clampf(stage_size.x * 0.62, 280.0, 520.0)
		var label_height := name_font_size + 12.0
		persona_label.size = Vector2(label_width, label_height)
		persona_label.position = Vector2(
			hero_focus_x - label_width * 0.5,
			hero_actor.position.y - label_height - 14.0
		)
		persona_label.pivot_offset = Vector2(label_width * 0.5, label_height * 0.5)


func _layout_cast_actor(actor: Control, actor_size: Vector2, is_hero: bool) -> void:
	if actor == null:
		return
	actor.size = actor_size
	actor.pivot_offset = Vector2(actor_size.x * 0.5, actor_size.y * (0.92 if is_hero else 0.78))

	var halo := actor.get_meta("halo") as TextureRect
	var shadow := actor.get_meta("shadow") as TextureRect
	var portrait := actor.get_meta("portrait") as TextureRect
	var label := actor.get_meta("label") as Label

	var label_height := 0.0 if is_hero else actor_size.y * 0.19
	var portrait_area_height := actor_size.y - label_height

	if halo != null:
		halo.size = Vector2(actor_size.x * (1.34 if is_hero else 1.28), portrait_area_height * (1.16 if is_hero else 1.08))
		halo.position = Vector2(
			(actor_size.x - halo.size.x) * 0.5,
			portrait_area_height * (-0.09 if is_hero else -0.02)
		)

	if shadow != null:
		shadow.size = Vector2(actor_size.x * (0.54 if is_hero else 0.64), actor_size.y * (0.10 if is_hero else 0.14))
		shadow.position = Vector2(
			(actor_size.x - shadow.size.x) * 0.5,
			portrait_area_height - shadow.size.y * (0.14 if is_hero else 0.44)
		)

	if portrait != null:
		portrait.size = Vector2(
			actor_size.x * (0.96 if is_hero else 0.90),
			portrait_area_height * (1.02 if is_hero else 0.94)
		)
		portrait.position = Vector2(
			(actor_size.x - portrait.size.x) * 0.5,
			portrait_area_height * (0.01 if is_hero else 0.02)
		)

	if label != null:
		label.position = Vector2(0.0, actor_size.y - label_height)
		label.size = Vector2(actor_size.x, label_height)
		label.visible = not is_hero
		label.add_theme_font_size_override("font_size", int(clampf(actor_size.x * (0.105 if is_hero else 0.095), 15.0, 30.0)))


func _get_ally_angles(count: int) -> Array[float]:
	match count:
		1:
			return [270.0]
		2:
			return [228.0, 312.0]
		3:
			return [216.0, 270.0, 324.0]
		4:
			return [206.0, 248.0, 292.0, 334.0]
		_:
			var angles: Array[float] = []
			var start_angle := 206.0
			var end_angle := 334.0
			for index in range(count):
				var t := 0.5 if count == 1 else float(index) / float(maxi(count - 1, 1))
				angles.append(lerpf(start_angle, end_angle, t))
			return angles


func _play_result_animation() -> void:
	var audio := GameAudio.get_shared(self)
	if audio != null:
		audio.play_persistent("victory" if state != null and state.victory else "defeat")

	var nodes := [title_banner, persona_label, stats_panel, theater_button, replay_button, hero_actor]
	for actor in ally_actor_nodes:
		nodes.append(actor)

	for node in nodes:
		if node is Control:
			var control := node as Control
			control.modulate = Color(1, 1, 1, 0)
			control.scale = Vector2.ONE * 0.96

	intro_tween = create_tween()
	intro_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for index in range(nodes.size()):
		var node = nodes[index]
		if node is Control:
			var control := node as Control
			var delay := float(index) * 0.05
			intro_tween.parallel().tween_property(control, "modulate", Color.WHITE, 0.30).set_delay(delay)
			intro_tween.parallel().tween_property(control, "scale", Vector2.ONE, 0.34).set_delay(delay)

	# Start ambient animations after intro
	intro_tween.finished.connect(func() -> void:
		if not is_instance_valid(self) or is_queued_for_deletion():
			return
		_start_actor_float()
		_animate_stat_numbers()
		_start_ambient_particles()
	)


func _start_actor_float() -> void:
	_kill_float_tweens()
	var is_win := state.victory
	var float_duration := 2.2 if is_win else 3.8
	var float_amount := 4.0 if is_win else 8.0

	var actors := [hero_actor]
	for actor in ally_actor_nodes:
		actors.append(actor)

	for actor in actors:
		if actor == null:
			continue
		var tween := create_tween()
		tween.set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		if is_win:
			# Victory: light, quick float
			tween.tween_property(actor, "position:y", actor.position.y - float_amount, float_duration * 0.5)
			tween.tween_property(actor, "position:y", actor.position.y + float_amount, float_duration * 0.5)
		else:
			# Defeat: heavy, slow float with slight rotation
			tween.tween_property(actor, "position:y", actor.position.y - float_amount * 0.5, float_duration * 0.5)
			tween.parallel().tween_property(actor, "rotation", deg_to_rad(1.5), float_duration * 0.5)
			tween.tween_property(actor, "position:y", actor.position.y + float_amount * 0.5, float_duration * 0.5)
			tween.parallel().tween_property(actor, "rotation", deg_to_rad(-1.5), float_duration * 0.5)
		float_tweens.append(tween)


func _kill_float_tweens() -> void:
	for tween in float_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	float_tweens.clear()


func _animate_stat_numbers() -> void:
	if state == null:
		return
	var target_hp := state.hp
	var target_max_hp := state.displayed_hp_capacity()
	var target_round := state.revealed_cards()
	var target_total_cards := state.total_cards()

	if stat_hp_value != null:
		var hp_tween := create_tween()
		hp_tween.set_trans(Tween.TRANS_CUBIC)
		hp_tween.set_ease(Tween.EASE_OUT)
		hp_tween.tween_method(
			func(v: float) -> void:
				stat_hp_value.text = "%d/%d" % [int(v), target_max_hp],
			0.0,
			float(target_hp),
			0.7
		)

	if stat_round_value != null:
		var round_tween := create_tween()
		round_tween.set_trans(Tween.TRANS_CUBIC)
		round_tween.set_ease(Tween.EASE_OUT)
		round_tween.tween_method(
			func(v: float) -> void:
				stat_round_value.text = "%d/%d" % [int(v), target_total_cards],
			0.0,
			float(target_round),
			0.7
		)

	if stat_ally_value != null:
		var target_ally := state.occupied_slots()
		var ally_tween := create_tween()
		ally_tween.set_trans(Tween.TRANS_CUBIC)
		ally_tween.set_ease(Tween.EASE_OUT)
		ally_tween.tween_method(
			func(v: float) -> void:
				stat_ally_value.text = state.ally_slot_summary(int(v)),
			0.0,
			float(target_ally),
			0.7
		)


func _start_ambient_particles() -> void:
	if ambient_particles != null:
		ambient_particles.queue_free()
	ambient_particles = GPUParticles2D.new()
	ambient_particles.name = "AmbientParticles"
	ambient_particles.amount = 32
	ambient_particles.lifetime = 10.0
	ambient_particles.preprocess = 10.0
	ambient_particles.explosiveness = 0.0
	ambient_particles.randomness = 1.0
	ambient_particles.position = Vector2(size.x * 0.5, size.y * 0.5)
	ambient_particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(size.x * 0.5, size.y * 0.35, 0)
	material.particle_flag_disable_z = true
	material.direction = Vector3(0, -1, 0)
	material.spread = 20.0
	material.gravity = Vector3(0, -6, 0)
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 5.0
	material.angular_velocity_min = -8.0
	material.angular_velocity_max = 8.0
	material.scale_min = 0.2
	material.scale_max = 0.6
	if state.victory:
		material.color = Color(1.0, 0.92, 0.65, 0.14)
	else:
		material.color = Color(0.65, 0.72, 0.95, 0.10)

	var curve := CurveTexture.new()
	var curve_data := Curve.new()
	curve_data.add_point(Vector2(0, 0))
	curve_data.add_point(Vector2(0.2, 1))
	curve_data.add_point(Vector2(0.8, 1))
	curve_data.add_point(Vector2(1, 0))
	curve.curve = curve_data
	material.alpha_curve = curve

	ambient_particles.process_material = material
	ambient_particles.texture = soft_glow_texture
	ambient_particles.z_index = 2
	add_child(ambient_particles)


func _exit_tree() -> void:
	_kill_float_tweens()
	if intro_tween != null and intro_tween.is_valid():
		intro_tween.kill()
		intro_tween = null


func _make_scroll_panel(scroll_texture: Texture2D, min_size: Vector2) -> Control:
	var panel: Control
	if scroll_texture != null:
		var nine := NinePatchRect.new()
		nine.texture = scroll_texture
		nine.patch_margin_left = 240
		nine.patch_margin_right = 240
		nine.patch_margin_top = 50
		nine.patch_margin_bottom = 50
		nine.mouse_filter = Control.MOUSE_FILTER_PASS
		panel = nine
	else:
		panel = UIFactory.make_glass_panel(Color("c89968"), 28, 0.32, 0.55)
	panel.custom_minimum_size = min_size
	return panel


func _set_button_text(button: Button, text: String) -> void:
	if button == null:
		return
	button.text = text
	for child in button.get_children():
		if child is Label:
			(child as Label).text = text


func _get_stage_pose_texture(character: Dictionary) -> Texture2D:
	var code := str(character.get("code", ""))
	if code.is_empty():
		return null
	var cache_key := "%s::stage" % code
	if result_texture_cache.has(cache_key):
		return result_texture_cache[cache_key]

	var entry := _get_ritual_entry(character)
	var candidates: Array[String] = []
	candidates.append("res://assets/portraits/cutout/ally/%s.png" % code)
	if entry.has("stage_pose"):
		candidates.append(str(entry.get("stage_pose", "")))
	candidates.append("res://assets/entrance_rituals/stage_poses/%s.png" % code)
	candidates.append("res://assets/portraits/subject/ally/%s.png" % code)

	var texture := _load_first_texture(candidates)
	if texture != null:
		texture = _trim_texture_to_used_rect(texture, 10)
		result_texture_cache[cache_key] = texture
		return texture
	return null


func _get_ritual_entry(character: Dictionary) -> Dictionary:
	_load_ritual_manifest()
	var code := str(character.get("code", ""))
	if code.is_empty():
		return {}
	if ritual_manifest_entries.has(code):
		return (ritual_manifest_entries[code] as Dictionary).duplicate(true)
	return {}


func _load_ritual_manifest() -> void:
	if ritual_manifest_loaded:
		return
	ritual_manifest_loaded = true
	ritual_manifest_entries.clear()

	var global_path := ProjectSettings.globalize_path(ENTRANCE_RITUALS_PATH)
	if not FileAccess.file_exists(global_path):
		return

	var file := FileAccess.open(global_path, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var entries = (parsed as Dictionary).get("entries", [])
	if not (entries is Array):
		return

	for entry in entries:
		if not (entry is Dictionary):
			continue
		var dict := entry as Dictionary
		var code := str(dict.get("code", ""))
		if code.is_empty():
			continue
		ritual_manifest_entries[code] = dict.duplicate(true)


func _color_from_entry(entry: Dictionary, key: String, fallback: Color) -> Color:
	if entry.is_empty():
		return fallback
	var value := str(entry.get(key, ""))
	if value.is_empty():
		return fallback
	return Color(value)


func _get_default_actor_color(is_hero: bool) -> Color:
	if is_hero:
		return Color("f1bf5e") if state.victory else Color("98a9e6")
	return Color("d2a35e") if state.victory else Color("b7a9db")


func _get_actor_label_text(character: Dictionary, is_hero: bool) -> String:
	var code := str(character.get("code", ""))
	var name := str(character.get("name", ""))
	if not is_hero:
		return code
	if not code.is_empty():
		return code
	return name


func _load_first_texture(candidates: Array[String]) -> Texture2D:
	for candidate in candidates:
		if candidate.is_empty():
			continue
		var disk_texture := _load_texture_from_disk(candidate)
		if disk_texture != null:
			return disk_texture
		if ResourceLoader.exists(candidate):
			var resource := load(candidate)
			if resource is Texture2D:
				return resource as Texture2D
	return null


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


func _trim_texture_to_used_rect(texture: Texture2D, padding: int = 0) -> Texture2D:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return texture
	if image.get_width() <= 0 or image.get_height() <= 0:
		return texture
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return texture
	if used_rect.position == Vector2i.ZERO and used_rect.size == image.get_size():
		return texture

	used_rect.position.x = maxi(0, used_rect.position.x - padding)
	used_rect.position.y = maxi(0, used_rect.position.y - padding)
	used_rect.size.x = mini(image.get_width() - used_rect.position.x, used_rect.size.x + padding * 2)
	used_rect.size.y = mini(image.get_height() - used_rect.position.y, used_rect.size.y + padding * 2)

	var trimmed := Image.create(used_rect.size.x, used_rect.size.y, false, Image.FORMAT_RGBA8)
	trimmed.blit_rect(image, used_rect, Vector2i.ZERO)
	return ImageTexture.create_from_image(trimmed)


func _generate_soft_glow_texture() -> Texture2D:
	var size_px := 256
	var image := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size_px * 0.5, size_px * 0.5)
	var radius := size_px * 0.46
	for y in range(size_px):
		for x in range(size_px):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := pow(clampf(1.0 - dist / radius, 0.0, 1.0), 3.6) * 0.48
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


func _get_persona_text() -> String:
	var code := str(state.player_character.get("code", ""))
	var name := str(state.player_character.get("name", ""))
	if not code.is_empty() and not name.is_empty():
		return "%s-%s" % [code, name]
	if not name.is_empty():
		return name
	return code


func _get_result_label() -> String:
	return "存活成功" if state.victory else "存活失败"


func _get_replay_label() -> String:
	return "下一局" if state.victory else "再试一次"
