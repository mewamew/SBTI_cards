extends Control

signal battle_finished
signal exit_to_select_requested
signal modal_choice_resolved(value)

const ShaderEffects = preload("res://scripts/shader_effects.gd")
const GameBalance = preload("res://scripts/game_balance.gd")
const CharactersData = preload("res://data/characters.gd")
const BattleScreenAssets = preload("res://scripts/battle_screen_assets.gd")
const BattleScreenCards = preload("res://scripts/battle_screen_cards.gd")
const BattleScreenFx = preload("res://scripts/battle_screen_fx.gd")
const BattleScreenStage = preload("res://scripts/battle_screen_stage.gd")
const BattleScreenText = preload("res://scripts/battle_screen_text.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const TheaterModal = preload("res://scripts/ui/theater_modal.gd")
const AudioToggleBar = preload("res://scripts/ui/audio_toggle_bar.gd")
const AmbientDustScene = preload("res://scenes/fx/ambient_dust.tscn")
const ENTRANCE_RITUALS_PATH := "res://data/entrance_rituals.json"
const BATTLE_BACKGROUND_PATH := "res://assets/backgrounds/screens/battle.png"

const TABLE_INNER_ELLIPSE_UV_CENTER := Vector2(0.501174, 0.387330)
const TABLE_INNER_ELLIPSE_UV_RADIUS := Vector2(0.189649, 0.175540)
const HP_PER_HEART := 8
const AMBIENT_DUST_BACKGROUND_PROFILE := {
	"amount": 112,
	"lifetime": 13.0,
	"preprocess": 13.0,
	"randomness": 0.78,
	"velocity_min": 3.8,
	"velocity_max": 10.8,
	"spread": 30.0,
	"scale_min": 0.028,
	"scale_max": 0.095,
	"damping_min": 0.28,
	"damping_max": 0.90,
	"linear_accel_min": -0.45,
	"linear_accel_max": 0.65,
	"radial_accel_min": -1.0,
	"radial_accel_max": 1.0,
	"tangential_accel_min": -2.4,
	"tangential_accel_max": 2.4,
	"gravity": Vector3(0.0, -0.45, 0.0),
	"self_modulate": Color(1.0, 0.95, 0.86, 0.58),
	"emission_scale": Vector2(0.44, 0.30),
	"inner_color": Color(1.0, 0.92, 0.78, 0.0),
	"mid_color": Color(1.0, 0.84, 0.62, 0.14),
	"outer_color": Color(0.96, 0.73, 0.44, 0.32),
	"fade_color": Color(0.90, 0.62, 0.34, 0.0),
}
const AMBIENT_DUST_FOREGROUND_PROFILE := {
	"amount": 32,
	"lifetime": 15.5,
	"preprocess": 15.5,
	"randomness": 0.86,
	"velocity_min": 1.8,
	"velocity_max": 6.2,
	"spread": 42.0,
	"scale_min": 0.11,
	"scale_max": 0.25,
	"damping_min": 0.08,
	"damping_max": 0.24,
	"linear_accel_min": -0.16,
	"linear_accel_max": 0.22,
	"radial_accel_min": -0.55,
	"radial_accel_max": 0.55,
	"tangential_accel_min": -1.2,
	"tangential_accel_max": 1.2,
	"gravity": Vector3(0.0, -0.18, 0.0),
	"self_modulate": Color(1.0, 0.90, 0.74, 0.28),
	"emission_scale": Vector2(0.48, 0.34),
	"z_index": 58,
	"inner_color": Color(1.0, 0.94, 0.82, 0.0),
	"mid_color": Color(1.0, 0.86, 0.66, 0.10),
	"outer_color": Color(0.98, 0.78, 0.52, 0.18),
	"fade_color": Color(0.92, 0.68, 0.38, 0.0),
}
const AMBIENT_DUST_SPOTLIGHT_PROFILE := {
	"amount": 88,
	"lifetime": 10.5,
	"preprocess": 10.5,
	"randomness": 0.82,
	"velocity_min": 4.2,
	"velocity_max": 11.4,
	"spread": 18.0,
	"scale_min": 0.050,
	"scale_max": 0.145,
	"damping_min": 0.16,
	"damping_max": 0.54,
	"linear_accel_min": -0.18,
	"linear_accel_max": 0.20,
	"radial_accel_min": -0.40,
	"radial_accel_max": 0.40,
	"tangential_accel_min": -0.75,
	"tangential_accel_max": 0.75,
	"gravity": Vector3(0.0, -0.24, 0.0),
	"self_modulate": Color(1.0, 0.93, 0.78, 0.74),
	"emission_scale": Vector2(0.14, 0.20),
	"z_index": 15,
	"inner_color": Color(1.0, 0.96, 0.84, 0.0),
	"mid_color": Color(1.0, 0.92, 0.72, 0.18),
	"outer_color": Color(0.98, 0.82, 0.56, 0.42),
	"fade_color": Color(0.94, 0.70, 0.40, 0.0),
}

const SEAT_CONFIG := {
	"player": {
		"angle_deg": 90.0,
		"size_ratio": 0.18,
		"tone": Color("7ab7ff"),
		"z_bias": 10,
	},
	"enemy": {
		"angle_deg": 325.0,
		"size_ratio": 0.17,
		"tone": Color("b693ff"),
		"z_bias": 8,
	},
	"ally_1": {
		"angle_deg": 210.0,
		"size_ratio": 0.17,
		"tone": Color("ffae78"),
		"z_bias": 4,
	},
	"ally_2": {
		"angle_deg": 150.0,
		"size_ratio": 0.17,
		"tone": Color("9dd7ff"),
		"z_bias": 2,
	},
	"ally_3": {
		"angle_deg": 268.0,
		"size_ratio": 0.17,
		"tone": Color("ffd8e7"),
		"z_bias": 3,
	},
	"ally_4": {
		"angle_deg": 30.0,
		"size_ratio": 0.17,
		"tone": Color("ffe6a6"),
		"z_bias": 4,
	},
	"ally_5": {
		"angle_deg": 0.0,
		"size_ratio": 0.17,
		"tone": Color("c7f0b3"),
		"z_bias": 4,
	},
	"ally_6": {
		"angle_deg": 330.0,
		"size_ratio": 0.17,
		"tone": Color("d8c8ff"),
		"z_bias": 4,
	},
}

const EXTRA_RENDERED_ALLY_SEATS := 2
const FLOATING_BANNER_GROUP_DISTANCE_X := 360.0
const FLOATING_BANNER_GROUP_DISTANCE_Y := 220.0

var state: GameState
var asset_helper := BattleScreenAssets.new()
var card_helper := BattleScreenCards.new()
var fx_helper := BattleScreenFx.new()
var stage_helper := BattleScreenStage.new()
var visible_deck_indices: Array = []
var selected_deck_index := -1
var busy := false
var deck_card_nodes := {}

var hero_label: Label
var hero_skill_label: Label
var hero_charges_label: Label
var life_icons_label: Label
var energy_icons_label: Label
var life_icons_container: HBoxContainer
var energy_icons_container: HBoxContainer
var hp_heart_texture: Texture2D
var energy_bolt_texture: Texture2D
var progress_card_texture: Texture2D
var status_scroll_texture: Texture2D
var info_scroll_top_texture: Texture2D
var info_scroll_mid_texture: Texture2D
var info_scroll_bot_texture: Texture2D
var info_scroll_full_texture: Texture2D
var ribbon_button_texture: Texture2D
var seat_card_frame_texture: Texture2D
var seat_small_card_template_texture: Texture2D
var gem_textures: Dictionary = {}
var round_label: Label
var pressure_label: Label
var hp_bar: ProgressBar
var hp_value_label: Label
var timer_label: Label
var ally_box: VBoxContainer
var reveal_name_label: Label
var reveal_texture: TextureRect
var reveal_texture_host: CenterContainer
var reveal_preview_card: Control
var fate_label: Label
var reveal_card_panel: PanelContainer
var info_box: RichTextLabel
var info_avatar: Control
var info_content_root: VBoxContainer
var info_title_label: Label
var info_quote_label: Label
var info_hint_label: Label
var info_ally_name_label: Label
var info_ally_desc_label: Label
var info_enemy_name_label: Label
var info_enemy_desc_label: Label
var log_box: RichTextLabel
var log_backdrop: ColorRect
var log_panel: Control
var toast_label: Label
var floating_banner_group_serial := 0
var floating_banner_groups: Dictionary = {}
var floating_banner_entries: Dictionary = {}
var damage_overlay: ColorRect
var _last_hp: int = -1
var deck_count_label: Label
var deck_hint_label: Label
var deck_grid: Control
var secondary_button: Button
var modal_backdrop: ColorRect
var modal_panel: Control
var modal_root: VBoxContainer
var modal_title: Label
var modal_body_center: CenterContainer
var modal_body: RichTextLabel
var modal_detail_panel: PanelContainer
var modal_detail_text: RichTextLabel
var modal_flex_spacer: Control
var modal_buttons_center: CenterContainer
var modal_recruit_detail_root: VBoxContainer
var modal_recruit_badge_label: Label
var modal_recruit_name_label: Label
var modal_recruit_status_label: Label
var modal_recruit_skill_name_label: Label
var modal_recruit_skill_desc_label: Label
var modal_recruit_warning_label: Label
var modal_replace_root: VBoxContainer
var modal_replace_subtitle_label: Label
var modal_replace_compare_row: HBoxContainer
var modal_replace_new_panel: PanelContainer
var modal_replace_new_text: RichTextLabel
var modal_replace_current_panel: PanelContainer
var modal_replace_current_text: RichTextLabel
var modal_replace_candidates_grid: GridContainer
var modal_replace_action_row: HBoxContainer
var modal_replace_confirm_button: Button
var modal_replace_cancel_button: Button
var modal_replace_new_ally: Dictionary = {}
var modal_replace_selected_ally: Dictionary = {}
var modal_replace_choices: Array = []
var modal_active_layout := ""
var modal_buttons: VBoxContainer
var modal_tooltip_panel: PanelContainer
var modal_tooltip_text: RichTextLabel
var peeked_cards := {}
var forced_next_fate_serial := 0
var deck_fan_tween: Tween
var deck_card_size := Vector2(104.0, 156.0)
var deck_display_limit := 7
var deck_fan_max_span := 1440.0
var deck_row_center_bias := 0.0
var ally_tooltip_panel: PanelContainer
var ally_tooltip_text: RichTextLabel
var reveal_result_locked := false
var reveal_locked_character: Dictionary = {}
var reveal_locked_text := ""
var reveal_locked_fate := ""
var reveal_locked_glow: ColorRect
var reveal_base_panel_style: StyleBoxFlat

# ── 着色器相关 ──
var vignette_overlay: ColorRect
var vignette_material: ShaderMaterial
var fate_reveal_overlay: ColorRect
var fate_reveal_material: ShaderMaterial
var table_surface_host: Control
var table_surface_rect: TextureRect
var table_surface_material: ShaderMaterial
var stage_atmosphere_host: Control
var audio_toggle_bar: AudioToggleBar
var stage_light_overlay: ColorRect
var stage_light_material: ShaderMaterial
var stage_light_tween: Tween
var stage_volume_glow: TextureRect
var stage_floor_haze: TextureRect
var table_surface_texture: Texture2D
var play_zone_texture: Texture2D
var pedestal_body_texture: Texture2D
var seat_card_pedestal_texture: Texture2D
var seat_card_border_texture: Texture2D
var enemy_card_back_texture: Texture2D
var card_shadow_texture: Texture2D
var avatar_ring_texture: Texture2D
var avatar_glow_texture: Texture2D
var ambient_dust_back_texture: Texture2D
var ambient_dust_front_texture: Texture2D
var soft_glow_texture: Texture2D
var spotlight_burst: TextureRect
var spotlight_tween: Tween
var ambient_dust_particles: GPUParticles2D
var ambient_dust_foreground_particles: GPUParticles2D
var ambient_dust_spotlight_particles: GPUParticles2D
var seat_entry_ally_burst_material: ParticleProcessMaterial
var seat_entry_enemy_burst_material: ParticleProcessMaterial
var attack_trail_enemy_material: ParticleProcessMaterial
var attack_trail_block_material: ParticleProcessMaterial
var attack_impact_enemy_material: ParticleProcessMaterial
var attack_impact_block_material: ParticleProcessMaterial
var arena_stage: Control
var seat_layer: Control
var projectile_layer: Control
var floating_effect_layer: Control
var seat_nodes := {}
var active_enemy_character: Dictionary = {}
var active_reveal_card: Control
var hero_spotlight_root: Control
var hero_spotlight_shadow: TextureRect
var hero_spotlight_halo: TextureRect
var hero_spotlight_pose: TextureRect
var hero_spotlight_quote_backdrop: PanelContainer
var hero_spotlight_quote_label: RichTextLabel
var hero_spotlight_tween: Tween
var hero_spotlight_quote_tween: Tween
var hero_spotlight_entry_played := false
var hero_spotlight_target_body_alpha := 0.0
var hero_spotlight_target_halo_alpha := 0.0
var info_drawer_host: Control
var info_drawer_panel: Control
var info_drawer_toggle: Button
var info_drawer_open := true
var info_drawer_tween: Tween
var ally_uid_counter := 0
var detail_layout_serial := 0
var _default_time_scale := 1.0
var _impact_hitstop_tween: Tween
var _screen_shake_tween: Tween
var _stage_atmosphere_phase := 0.0

const REVEAL_SUSPENSE_BASE_DURATIONS := [0.10, 0.14, 0.20, 0.30, 0.45, 0.65]
const DECK_CARD_MOTION_DURATION := 0.20
const DECK_CARD_MODULATE_DURATION := 0.18
const DECK_CARD_HOVER_DISTANCE := 24.0
const DECK_CARD_HOVER_SCALE := 1.10
const DECK_CARD_HOVER_SELECTED_SCALE := 1.08
const DECK_CARD_BLINK_SPEED_MIN := 0.92
const DECK_CARD_BLINK_SPEED_MAX := 1.28


func setup(next_state: GameState) -> void:
	state = next_state


func _ready() -> void:
	_default_time_scale = maxf(Engine.time_scale, 0.01)
	card_helper.set_asset_helper(asset_helper)
	fx_helper.setup(self)
	stage_helper.set_asset_helper(asset_helper)
	if state.deck.is_empty():
		state.deck = DeckManager.build_deck(state.player_character)

	_build_ui()
	_add_audio_toggle_bar()
	_update_ui()
	_append_log("主角 %s 出战，当前牌池共 %d 张。" % [state.player_character["code"], state.deck.size()])
	if not state.player_character.is_empty():
		busy = true
		call_deferred("_play_hero_spotlight_opening")


func _exit_tree() -> void:
	_reset_time_scale()


func _play_sfx(key: String) -> void:
	var audio := GameAudio.get_shared(self)
	if audio != null:
		audio.play_sfx(key)


func _add_audio_toggle_bar() -> void:
	audio_toggle_bar = AudioToggleBar.new()
	audio_toggle_bar.show_sfx_toggle = true
	add_child(audio_toggle_bar)


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	if table_surface_rect != null:
		call_deferred("_refresh_table_surface_layout")
	if seat_layer != null:
		call_deferred("_refresh_seat_layout")
	if hero_spotlight_root != null:
		call_deferred("_refresh_hero_spotlight_layout")
	if ambient_dust_particles != null or ambient_dust_foreground_particles != null or ambient_dust_spotlight_particles != null:
		call_deferred("_refresh_ambient_dust_layout")
	if stage_volume_glow != null or stage_floor_haze != null:
		call_deferred("_refresh_stage_atmosphere_layout")
	if log_backdrop != null and log_backdrop.visible:
		call_deferred("_refresh_log_modal_layout")
	if modal_backdrop != null and modal_backdrop.visible:
		if modal_active_layout == "replace":
			call_deferred("_refresh_replace_modal_layout")
		else:
			var option_count := modal_buttons.get_child_count() if modal_buttons != null else 0
			var detail_visible := modal_detail_panel != null and modal_detail_panel.visible
			call_deferred("_refresh_modal_layout", detail_visible, option_count)
	if info_drawer_panel != null:
		call_deferred("_refresh_info_drawer_bounds")
		call_deferred("_refresh_info_drawer", false)
	if floating_effect_layer != null:
		call_deferred("_refresh_floating_banner_layouts")
	call_deferred("_refresh_card_detail_panel_position", false)


func _process(delta: float) -> void:
	_process_stage_atmosphere(delta)
	_process_breath(delta)
	_process_deck_card_blink(delta)
	_enforce_card_detail_panel_layout()


func _reset_time_scale() -> void:
	if _impact_hitstop_tween != null and _impact_hitstop_tween.is_valid():
		_impact_hitstop_tween.kill()
	_impact_hitstop_tween = null
	Engine.time_scale = maxf(_default_time_scale, 0.01)
	if _screen_shake_tween != null and _screen_shake_tween.is_valid():
		_screen_shake_tween.kill()
	_screen_shake_tween = null
	position = Vector2.ZERO


func _set_engine_time_scale(value: float) -> void:
	Engine.time_scale = maxf(value, 0.01)


func _trigger_hitstop(duration: float = 0.036, slow_factor: float = 0.08, recover_duration: float = 0.10) -> void:
	if not is_inside_tree():
		return
	var restore_scale := maxf(_default_time_scale, 0.01)
	var slowed_scale := maxf(restore_scale * clampf(slow_factor, 0.01, 1.0), 0.01)
	if _impact_hitstop_tween != null and _impact_hitstop_tween.is_valid():
		_impact_hitstop_tween.kill()
	_set_engine_time_scale(slowed_scale)
	var tween := create_tween()
	_impact_hitstop_tween = tween
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration)
	tween.tween_method(_set_engine_time_scale, slowed_scale, restore_scale, recover_duration)
	tween.finished.connect(_on_hitstop_tween_finished.bind(tween.get_instance_id(), restore_scale))


func _play_screen_shake(strength: float = 12.0, settle_time: float = 0.12, steps: int = 4, vertical_ratio: float = 0.72) -> void:
	if _screen_shake_tween != null and _screen_shake_tween.is_valid():
		_screen_shake_tween.kill()
	position = Vector2.ZERO
	var tween := create_tween()
	_screen_shake_tween = tween
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for step_index in range(maxi(steps, 1)):
		var decay := 1.0 - float(step_index) / float(maxi(steps, 1))
		var offset := Vector2(
			randf_range(-strength, strength) * decay,
			randf_range(-strength * vertical_ratio, strength * vertical_ratio) * decay
		)
		tween.tween_property(self, "position", offset, 0.024)
	tween.tween_property(self, "position", Vector2.ZERO, settle_time)
	tween.finished.connect(_on_screen_shake_tween_finished.bind(tween.get_instance_id()))


func _process_breath(delta: float) -> void:
	for deck_index in deck_card_nodes:
		var button: Button = deck_card_nodes[deck_index] as Button
		if button == null or not button.visible:
			continue
		var base_x: float = _get_object_meta_value(button, "base_x", button.position.x)
		var base_y: float = _get_object_meta_value(button, "base_y", button.position.y)
		if base_y == 0.0 and base_x == 0.0:
			continue
		# 悬停和交互补间期间不做呼吸偏移，避免与 motion tween 抢写 transform。
		if _get_object_meta_value(button, "hovering", false) or _has_active_deck_card_motion(button):
			continue
		var phase: float = _get_object_meta_value(button, "breath_phase", 0.0)
		var speed: float = _get_object_meta_value(button, "breath_speed", 0.5)
		phase += speed * delta * TAU
		button.set_meta("breath_phase", phase)
		var breath_offset := _get_deck_card_breath_offset(button, int(deck_index))
		button.position = Vector2(base_x, base_y + breath_offset)


func _process_deck_card_blink(delta: float) -> void:
	for deck_index_variant in deck_card_nodes:
		var deck_index: int = int(deck_index_variant)
		var button: Button = deck_card_nodes[deck_index] as Button
		if button == null or not button.visible:
			continue
		_update_deck_card_blink(button, deck_index, delta)


func _update_deck_card_blink(button: Button, deck_index: int, delta: float) -> void:
	if button == null:
		return
	var blink_halo: TextureRect = _get_object_meta_value(button, "blink_halo") as TextureRect
	var blink_major: TextureRect = _get_object_meta_value(button, "blink_major") as TextureRect
	var blink_minor: TextureRect = _get_object_meta_value(button, "blink_minor") as TextureRect
	if blink_halo == null and blink_major == null and blink_minor == null:
		return

	var phase: float = _get_object_meta_value(button, "blink_phase", randf() * TAU)
	var speed: float = _get_object_meta_value(button, "blink_speed", 1.0)
	phase += delta * speed * TAU
	button.set_meta("blink_phase", phase)

	var hovered: bool = bool(_get_object_meta_value(button, "hovering", false))
	var selected: bool = deck_index == selected_deck_index
	var emphasis := 1.0
	if selected:
		emphasis += 0.36
	if hovered:
		emphasis += 0.22

	var card: Dictionary = {}
	var peek_data: Dictionary = {}
	if deck_index >= 0 and deck_index < state.deck.size():
		card = state.deck[deck_index]
		peek_data = _get_peek_data(deck_index)

	var accent := card_helper.get_card_glass_accent(card.get("character", {}), peek_data).lightened(0.28)
	var warm_spark := Color(1.0, 0.97, 0.88, 1.0).lerp(accent.lightened(0.38), 0.30)
	var cool_spark := Color(1.0, 0.95, 0.84, 1.0).lerp(accent, 0.46)
	var base_glow := 0.024
	if selected:
		base_glow += 0.038
	if hovered:
		base_glow += 0.026
	var ambient := base_glow + maxf(0.0, sin(phase * 0.34 + float(deck_index) * 0.31)) * 0.024
	var blink_a := pow(maxf(0.0, sin(phase * 0.82 + 0.38)), 14.0)
	var blink_b := pow(maxf(0.0, sin(phase * 1.10 + 2.26)), 18.0)
	var halo_alpha := clampf(ambient + (blink_a * 0.14 + blink_b * 0.10) * emphasis, 0.0, 0.34)
	var major_alpha := clampf(ambient * 0.28 + blink_a * 0.46 * emphasis, 0.0, 0.66)
	var minor_alpha := clampf(ambient * 0.18 + blink_b * 0.36 * emphasis, 0.0, 0.52)

	if blink_halo != null:
		blink_halo.modulate = Color(accent.r, accent.g, accent.b, halo_alpha)
		blink_halo.scale = Vector2.ONE * (1.0 + halo_alpha * 0.42)

	if blink_major != null:
		var major_base_pos: Vector2 = _get_object_meta_value(button, "blink_major_base_pos", blink_major.position)
		blink_major.position = major_base_pos + Vector2(sin(phase * 0.94) * 1.8, cos(phase * 0.72) * 1.2)
		blink_major.modulate = Color(warm_spark.r, warm_spark.g, warm_spark.b, major_alpha)
		blink_major.scale = Vector2.ONE * (0.84 + major_alpha * 0.54)

	if blink_minor != null:
		var minor_base_pos: Vector2 = _get_object_meta_value(button, "blink_minor_base_pos", blink_minor.position)
		blink_minor.position = minor_base_pos + Vector2(cos(phase * 0.88) * 1.6, sin(phase * 1.08) * 1.0)
		blink_minor.modulate = Color(cool_spark.r, cool_spark.g, cool_spark.b, minor_alpha)
		blink_minor.scale = Vector2.ONE * (0.78 + minor_alpha * 0.48)


func _get_valid_meta_value(name: StringName) -> Variant:
	if not has_meta(name):
		return null
	var value: Variant = get_meta(name)
	if value == null:
		return null
	if value is Object and not is_instance_valid(value):
		remove_meta(name)
		return null
	return value


func _get_object_meta_value(target: Object, name: StringName, fallback: Variant = null) -> Variant:
	if target == null or not is_instance_valid(target) or not target.has_meta(name):
		return fallback
	var value: Variant = target.get_meta(name)
	if value == null:
		return fallback
	if value is Object and not is_instance_valid(value):
		target.remove_meta(name)
		return fallback
	return value


func _canvas_item_global_to_local(target: CanvasItem, global_point: Vector2) -> Vector2:
	if target == null or not is_instance_valid(target):
		return global_point
	return target.get_global_transform().affine_inverse() * global_point


func _make_additive_canvas_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


func _get_stage_atmosphere_rect() -> Rect2:
	if arena_stage == null or stage_atmosphere_host == null:
		return Rect2()
	var global_rect := arena_stage.get_global_rect()
	var top_left := _canvas_item_global_to_local(stage_atmosphere_host, global_rect.position)
	var bottom_right := _canvas_item_global_to_local(stage_atmosphere_host, global_rect.position + global_rect.size)
	return Rect2(top_left, bottom_right - top_left)


func _process_stage_atmosphere(delta: float) -> void:
	_stage_atmosphere_phase += delta
	var pulse_boost := 0.0
	if stage_light_material != null:
		pulse_boost = float(stage_light_material.get_shader_parameter("pulse_boost"))
	if stage_volume_glow != null:
		var glow_alpha := 0.30 + sin(_stage_atmosphere_phase * 0.52) * 0.05 + pulse_boost * 0.08
		stage_volume_glow.modulate.a = clampf(glow_alpha, 0.24, 0.52)
		var glow_scale := 1.00 + sin(_stage_atmosphere_phase * 0.33) * 0.035
		stage_volume_glow.scale = Vector2.ONE * glow_scale
	if stage_floor_haze != null:
		var haze_alpha := 0.19 + sin(_stage_atmosphere_phase * 0.68 + 0.9) * 0.03 + pulse_boost * 0.08
		stage_floor_haze.modulate.a = clampf(haze_alpha, 0.14, 0.34)
		stage_floor_haze.scale = Vector2(1.0 + sin(_stage_atmosphere_phase * 0.26) * 0.028, 1.0 + sin(_stage_atmosphere_phase * 0.34) * 0.018)


func _build_ui() -> void:
	table_surface_texture = _get_table_background_texture()
	play_zone_texture = _generate_play_zone_texture()
	pedestal_body_texture = _generate_pedestal_body_texture()
	seat_card_pedestal_texture = _generate_seat_card_pedestal_texture()
	seat_card_border_texture = _generate_seat_card_border_texture()
	enemy_card_back_texture = _load_texture_from_disk("res://assets/cards/templates/card_back.png")
	if enemy_card_back_texture == null and ResourceLoader.exists("res://assets/cards/templates/card_back.png"):
		enemy_card_back_texture = load("res://assets/cards/templates/card_back.png") as Texture2D
	hp_heart_texture = _load_ui_theater("hp_heart.png")
	energy_bolt_texture = _load_ui_theater("energy_bolt.png")
	progress_card_texture = _load_ui_theater("progress_card.png")
	status_scroll_texture = _load_ui_theater("status_scroll.png")
	info_scroll_top_texture = _load_ui_theater("info_scroll_top.png")
	info_scroll_mid_texture = _load_ui_theater("info_scroll_mid.png")
	info_scroll_bot_texture = _load_ui_theater("info_scroll_bot.png")
	info_scroll_full_texture = _load_ui_theater("info_scroll_full.png")
	ribbon_button_texture = _load_ui_theater("ribbon_button_red.png")
	seat_card_frame_texture = _load_ui_theater("seat_card_frame.png")
	seat_small_card_template_texture = _load_texture_from_disk("res://assets/cards/templates/small_card_alpha.png")
	if seat_small_card_template_texture == null:
		seat_small_card_template_texture = _load_texture_from_disk("res://assets/cards/templates/small_card.png")
	if seat_small_card_template_texture == null and ResourceLoader.exists("res://assets/cards/templates/small_card_alpha.png"):
		seat_small_card_template_texture = load("res://assets/cards/templates/small_card_alpha.png") as Texture2D
	if seat_small_card_template_texture == null and ResourceLoader.exists("res://assets/cards/templates/small_card.png"):
		seat_small_card_template_texture = load("res://assets/cards/templates/small_card.png") as Texture2D
	for color_name in ["red", "blue", "green", "purple"]:
		gem_textures[color_name] = _load_ui_theater("gem_%s.png" % color_name)
	card_shadow_texture = _generate_card_shadow_texture()
	avatar_ring_texture = _generate_avatar_ring_texture()
	avatar_glow_texture = _generate_avatar_glow_texture()
	soft_glow_texture = _generate_soft_glow_texture()
	ambient_dust_back_texture = _load_texture_from_disk("res://assets/fx/particle_dust_mote.png")
	if ambient_dust_back_texture == null and ResourceLoader.exists("res://assets/fx/particle_dust_mote.png"):
		ambient_dust_back_texture = load("res://assets/fx/particle_dust_mote.png") as Texture2D
	ambient_dust_front_texture = _load_texture_from_disk("res://assets/fx/particle_soft_glow.png")
	if ambient_dust_front_texture == null and ResourceLoader.exists("res://assets/fx/particle_soft_glow.png"):
		ambient_dust_front_texture = load("res://assets/fx/particle_soft_glow.png") as Texture2D
	if ambient_dust_back_texture == null:
		ambient_dust_back_texture = soft_glow_texture
	if ambient_dust_front_texture == null:
		ambient_dust_front_texture = soft_glow_texture

	var bg := ColorRect.new()
	bg.color = Color("1a0e08")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glaze := ColorRect.new()
	glaze.color = Color(0, 0, 0, 0.18)
	glaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glaze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(glaze)

	vignette_overlay = ColorRect.new()
	vignette_overlay.color = Color(0, 0, 0, 0)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_material = ShaderEffects.create_vignette_material()
	vignette_overlay.material = vignette_material
	add_child(vignette_overlay)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var shell := Control.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(shell)

	table_surface_host = Control.new()
	table_surface_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_surface_host.clip_contents = true
	table_surface_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(table_surface_host)

	table_surface_rect = TextureRect.new()
	table_surface_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_surface_rect.texture = table_surface_texture
	table_surface_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table_surface_rect.stretch_mode = TextureRect.STRETCH_SCALE
	table_surface_material = ShaderEffects.create_table_atmosphere_material()
	table_surface_rect.material = table_surface_material
	table_surface_host.add_child(table_surface_rect)
	call_deferred("_refresh_table_surface_layout")

	var warm_glow := TextureRect.new()
	warm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warm_glow.texture = soft_glow_texture
	warm_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	warm_glow.stretch_mode = TextureRect.STRETCH_SCALE
	warm_glow.position = Vector2(-120, 52)
	warm_glow.size = Vector2(520, 520)
	warm_glow.modulate = Color(0.95, 0.65, 0.20, 0.16)
	shell.add_child(warm_glow)

	var cool_glow := TextureRect.new()
	cool_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cool_glow.texture = soft_glow_texture
	cool_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cool_glow.stretch_mode = TextureRect.STRETCH_SCALE
	cool_glow.position = Vector2(1020, 10)
	cool_glow.size = Vector2(460, 460)
	cool_glow.modulate = Color(0.55, 0.10, 0.12, 0.10)
	shell.add_child(cool_glow)

	stage_atmosphere_host = Control.new()
	stage_atmosphere_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_atmosphere_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(stage_atmosphere_host)

	# 无边框 - 赌桌本身就是边框

	var content_margin := MarginContainer.new()
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(content_margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	content_margin.add_child(root)

	var status_shell := _make_scroll_panel(status_scroll_texture, Vector2(720, 132))
	status_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(status_shell)

	var status_bar := VBoxContainer.new()
	status_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	status_bar.add_theme_constant_override("separation", 6)
	status_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_bar.offset_left = 140.0
	status_bar.offset_right = -140.0
	status_bar.offset_top = 20.0
	status_bar.offset_bottom = -20.0
	status_shell.add_child(status_bar)

	hero_label = Label.new()
	hero_label.visible = false
	hero_skill_label = Label.new()
	hero_skill_label.visible = false
	hero_charges_label = Label.new()
	hero_charges_label.visible = false

	life_icons_container = HBoxContainer.new()
	life_icons_container.add_theme_constant_override("separation", 1)
	life_icons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	life_icons_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	status_bar.add_child(life_icons_container)

	energy_icons_container = HBoxContainer.new()
	energy_icons_container.add_theme_constant_override("separation", 2)
	energy_icons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_icons_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	status_bar.add_child(energy_icons_container)

	life_icons_label = Label.new()
	life_icons_label.visible = false
	energy_icons_label = Label.new()
	energy_icons_label.visible = false

	var top_metrics_shell := _make_scroll_panel(status_scroll_texture, Vector2(420, 132))
	top_metrics_shell.anchor_left = 1.0
	top_metrics_shell.anchor_right = 1.0
	top_metrics_shell.offset_left = -502.0
	top_metrics_shell.offset_top = 8.0
	top_metrics_shell.offset_right = -82.0
	top_metrics_shell.offset_bottom = 140.0
	shell.add_child(top_metrics_shell)

	var top_metrics_row := HBoxContainer.new()
	top_metrics_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_metrics_row.add_theme_constant_override("separation", 22)
	top_metrics_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_metrics_row.offset_left = 90.0
	top_metrics_row.offset_right = -90.0
	top_metrics_row.offset_top = 28.0
	top_metrics_row.offset_bottom = -28.0
	top_metrics_shell.add_child(top_metrics_row)

	pressure_label = UIFactory.make_label("+ 0", 22, Color("c8e0a0"), true)
	top_metrics_row.add_child(pressure_label)

	hp_bar = ProgressBar.new()
	hp_bar.visible = false
	hp_bar.custom_minimum_size = Vector2(0, 0)
	hp_value_label = Label.new()
	hp_value_label.visible = false

	var round_icon := TextureRect.new()
	round_icon.texture = progress_card_texture
	round_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	round_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	round_icon.custom_minimum_size = Vector2(34, 44)
	round_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_metrics_row.add_child(round_icon)
	round_label = UIFactory.make_label("0/15", 22, Color("f5e8d0"), true)
	top_metrics_row.add_child(round_label)
	timer_label = UIFactory.make_label("×1.00", 22, Color("ffaf6e"), true)
	top_metrics_row.add_child(timer_label)

	var menu_button := _make_fab_button("☰", Color(1, 1, 1, 0.70), Color("62718e"), Color("d8e3ff"), 18)
	menu_button.custom_minimum_size = Vector2(52, 52)
	menu_button.anchor_left = 1.0
	menu_button.anchor_right = 1.0
	menu_button.offset_left = -58.0
	menu_button.offset_top = 17.0
	menu_button.offset_right = -6.0
	menu_button.offset_bottom = 69.0
	menu_button.tooltip_text = "战报"
	menu_button.pressed.connect(_show_log_modal)
	shell.add_child(menu_button)

	var exit_button := _make_fab_button("←", Color(1, 1, 1, 0.70), Color("8a4a3a"), Color("e9c8a0"), 22)
	exit_button.custom_minimum_size = Vector2(52, 52)
	exit_button.anchor_left = 1.0
	exit_button.anchor_right = 1.0
	exit_button.offset_left = -118.0
	exit_button.offset_top = 17.0
	exit_button.offset_right = -66.0
	exit_button.offset_bottom = 69.0
	exit_button.tooltip_text = "返回人格选择"
	exit_button.pressed.connect(_request_exit_to_select)
	shell.add_child(exit_button)
	info_drawer_toggle = null

	ally_box = null

	# arena区域 - 无边框，融入背景
	arena_stage = Control.new()
	arena_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_stage.size_flags_stretch_ratio = 2.6
	root.add_child(arena_stage)

	var center_stage := Control.new()
	center_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_stage.add_child(center_stage)

	ambient_dust_particles = AmbientDustScene.instantiate() as GPUParticles2D
	if ambient_dust_particles != null:
		ambient_dust_particles.name = "AmbientDustBack"
		center_stage.add_child(ambient_dust_particles)

	stage_volume_glow = TextureRect.new()
	stage_volume_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_volume_glow.texture = soft_glow_texture
	stage_volume_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_volume_glow.stretch_mode = TextureRect.STRETCH_SCALE
	stage_volume_glow.material = _make_additive_canvas_material()
	stage_volume_glow.modulate = Color(1.0, 0.74, 0.34, 0.24)
	stage_volume_glow.z_index = 1
	stage_atmosphere_host.add_child(stage_volume_glow)

	stage_light_overlay = ColorRect.new()
	stage_light_overlay.color = Color(1, 1, 1, 1)
	stage_light_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_light_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_light_material = ShaderEffects.create_stage_light_shafts_material()
	stage_light_overlay.material = stage_light_material
	stage_light_overlay.z_index = 3
	stage_atmosphere_host.add_child(stage_light_overlay)

	seat_layer = Control.new()
	seat_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seat_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_stage.add_child(seat_layer)

	stage_floor_haze = TextureRect.new()
	stage_floor_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_floor_haze.texture = soft_glow_texture
	stage_floor_haze.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_floor_haze.stretch_mode = TextureRect.STRETCH_SCALE
	stage_floor_haze.material = _make_additive_canvas_material()
	stage_floor_haze.modulate = Color(1.0, 0.78, 0.46, 0.22)
	stage_floor_haze.z_index = 2
	stage_atmosphere_host.add_child(stage_floor_haze)

	ambient_dust_spotlight_particles = AmbientDustScene.instantiate() as GPUParticles2D
	if ambient_dust_spotlight_particles != null:
		ambient_dust_spotlight_particles.name = "AmbientDustSpotlight"
		stage_atmosphere_host.add_child(ambient_dust_spotlight_particles)

	spotlight_burst = TextureRect.new()
	spotlight_burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spotlight_burst.texture = soft_glow_texture
	spotlight_burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spotlight_burst.stretch_mode = TextureRect.STRETCH_SCALE
	spotlight_burst.size = Vector2(820, 820)
	spotlight_burst.modulate = Color(1.0, 0.85, 0.55, 0.0)
	spotlight_burst.z_index = 18
	seat_layer.add_child(spotlight_burst)

	hero_spotlight_root = Control.new()
	hero_spotlight_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_spotlight_root.visible = false
	hero_spotlight_root.z_index = 8
	seat_layer.add_child(hero_spotlight_root)

	hero_spotlight_shadow = TextureRect.new()
	hero_spotlight_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_spotlight_shadow.texture = soft_glow_texture
	hero_spotlight_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_spotlight_shadow.stretch_mode = TextureRect.STRETCH_SCALE
	hero_spotlight_shadow.modulate = Color(0.22, 0.12, 0.08, 0.0)
	hero_spotlight_root.add_child(hero_spotlight_shadow)

	hero_spotlight_halo = TextureRect.new()
	hero_spotlight_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_spotlight_halo.texture = soft_glow_texture
	hero_spotlight_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_spotlight_halo.stretch_mode = TextureRect.STRETCH_SCALE
	hero_spotlight_halo.modulate = Color(1.0, 0.85, 0.55, 0.0)
	hero_spotlight_root.add_child(hero_spotlight_halo)

	hero_spotlight_pose = TextureRect.new()
	hero_spotlight_pose.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_spotlight_pose.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_spotlight_pose.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_spotlight_pose.modulate = Color(1, 1, 1, 0.0)
	hero_spotlight_root.add_child(hero_spotlight_pose)

	hero_spotlight_quote_backdrop = PanelContainer.new()
	hero_spotlight_quote_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_spotlight_quote_backdrop.clip_contents = true
	hero_spotlight_quote_backdrop.visible = false
	hero_spotlight_quote_backdrop.z_index = 9
	var hero_quote_style := StyleBoxFlat.new()
	hero_quote_style.bg_color = Color(0.12, 0.05, 0.03, 0.0)
	hero_quote_style.corner_radius_top_left = 18
	hero_quote_style.corner_radius_top_right = 18
	hero_quote_style.corner_radius_bottom_left = 18
	hero_quote_style.corner_radius_bottom_right = 18
	hero_quote_style.border_width_left = 1
	hero_quote_style.border_width_top = 1
	hero_quote_style.border_width_right = 1
	hero_quote_style.border_width_bottom = 1
	hero_quote_style.border_color = Color(1.0, 0.92, 0.75, 0.0)
	hero_quote_style.content_margin_left = 18
	hero_quote_style.content_margin_top = 10
	hero_quote_style.content_margin_right = 18
	hero_quote_style.content_margin_bottom = 12
	hero_spotlight_quote_backdrop.add_theme_stylebox_override("panel", hero_quote_style)
	seat_layer.add_child(hero_spotlight_quote_backdrop)

	hero_spotlight_quote_label = RichTextLabel.new()
	hero_spotlight_quote_label.bbcode_enabled = true
	hero_spotlight_quote_label.fit_content = false
	hero_spotlight_quote_label.scroll_active = false
	hero_spotlight_quote_label.selection_enabled = false
	hero_spotlight_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_spotlight_quote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_spotlight_quote_label.visible_ratio = 1.0
	hero_spotlight_quote_label.modulate = Color(1, 1, 1, 0.0)
	hero_spotlight_quote_backdrop.add_child(hero_spotlight_quote_label)

	var center_pool := TextureRect.new()
	center_pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_pool.texture = play_zone_texture
	center_pool.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	center_pool.stretch_mode = TextureRect.STRETCH_SCALE
	center_pool.size = Vector2(420, 180)
	center_pool.modulate = Color(1, 1, 1, 0.18)
	seat_layer.add_child(center_pool)
	seat_layer.set_meta("center_pool", center_pool)

	reveal_card_panel = PanelContainer.new()
	var reveal_panel_style := StyleBoxFlat.new()
	reveal_panel_style.bg_color = Color(0, 0, 0, 0)
	reveal_panel_style.border_color = Color(1, 1, 1, 0)
	reveal_panel_style.corner_radius_top_left = 28
	reveal_panel_style.corner_radius_top_right = 28
	reveal_panel_style.corner_radius_bottom_left = 28
	reveal_panel_style.corner_radius_bottom_right = 28
	reveal_panel_style.content_margin_left = 0
	reveal_panel_style.content_margin_top = 0
	reveal_panel_style.content_margin_right = 0
	reveal_panel_style.content_margin_bottom = 0
	reveal_card_panel.add_theme_stylebox_override("panel", reveal_panel_style)
	reveal_card_panel.custom_minimum_size = Vector2(260, 360)
	reveal_card_panel.visible = false
	reveal_card_panel.z_index = 30
	seat_layer.add_child(reveal_card_panel)
	var reveal_style = reveal_card_panel.get_theme_stylebox("panel")
	if reveal_style is StyleBoxFlat:
		reveal_base_panel_style = (reveal_style as StyleBoxFlat).duplicate()
	reveal_card_panel.resized.connect(_on_reveal_card_panel_resized)

	var front_root := VBoxContainer.new()
	front_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	front_root.alignment = BoxContainer.ALIGNMENT_CENTER
	front_root.add_theme_constant_override("separation", 8)
	reveal_card_panel.add_child(front_root)
	reveal_name_label = UIFactory.make_label("?", 20, Color("f5e9c8"), true)
	reveal_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_name_label.visible = false
	reveal_name_label.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.03, 0.72))
	reveal_name_label.add_theme_constant_override("outline_size", 2)
	front_root.add_child(reveal_name_label)
	reveal_texture_host = CenterContainer.new()
	reveal_texture_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reveal_texture_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	front_root.add_child(reveal_texture_host)
	reveal_texture = TextureRect.new()
	reveal_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reveal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reveal_texture.custom_minimum_size = Vector2(144, 206)
	reveal_texture.visible = false
	reveal_texture_host.add_child(reveal_texture)
	reveal_texture.resized.connect(_on_reveal_texture_resized)

	fate_reveal_overlay = null
	fate_reveal_material = null

	fate_label = UIFactory.make_label("◌", 12, Color("8a7b57"), true)
	fate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	front_root.add_child(fate_label)
	call_deferred("_refresh_reveal_texture_layout")

	_build_seat_system()

	projectile_layer = Control.new()
	projectile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	projectile_layer.z_index = 50
	center_stage.add_child(projectile_layer)

	floating_effect_layer = Control.new()
	floating_effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floating_effect_layer.z_index = 60
	center_stage.add_child(floating_effect_layer)

	ambient_dust_foreground_particles = AmbientDustScene.instantiate() as GPUParticles2D
	if ambient_dust_foreground_particles != null:
		ambient_dust_foreground_particles.name = "AmbientDustFront"
		center_stage.add_child(ambient_dust_foreground_particles)

	call_deferred("_refresh_ambient_dust_layout")
	call_deferred("_refresh_stage_atmosphere_layout")
	call_deferred("_refresh_seat_layout")

	info_drawer_host = Control.new()
	info_drawer_host.anchor_left = 1.0
	info_drawer_host.anchor_right = 1.0
	info_drawer_host.anchor_top = 0.0
	info_drawer_host.anchor_bottom = 0.0
	info_drawer_host.offset_left = -402.0
	info_drawer_host.offset_top = 60.0
	info_drawer_host.offset_right = -14.0
	info_drawer_host.offset_bottom = 620.0
	info_drawer_host.clip_contents = true
	info_drawer_host.z_index = 90
	center_stage.add_child(info_drawer_host)

	info_drawer_panel = Control.new()
	info_drawer_panel.custom_minimum_size = Vector2(360, 300)
	info_drawer_panel.size = Vector2(360, 540)
	info_drawer_panel.position = Vector2(10, 0)
	info_drawer_panel.anchor_top = 0.0
	info_drawer_panel.anchor_bottom = 1.0
	info_drawer_panel.offset_top = 0.0
	info_drawer_panel.offset_bottom = 0.0
	info_drawer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	info_drawer_host.add_child(info_drawer_panel)
	call_deferred("_refresh_info_drawer_bounds")

	if info_scroll_full_texture != null:
		var scroll_bg := NinePatchRect.new()
		scroll_bg.texture = info_scroll_full_texture
		scroll_bg.patch_margin_left = 28
		scroll_bg.patch_margin_right = 28
		scroll_bg.patch_margin_top = 90
		scroll_bg.patch_margin_bottom = 90
		scroll_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_drawer_panel.add_child(scroll_bg)
	else:
		var fallback_bg := UIFactory.make_glass_panel(Color("c89968"), 28, 0.94, 0.78)
		fallback_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_drawer_panel.add_child(fallback_bg)
		var fb_style := fallback_bg.get_theme_stylebox("panel")
		if fb_style is StyleBoxFlat:
			var fb_flat := fb_style as StyleBoxFlat
			fb_flat.bg_color = Color(0.20, 0.06, 0.08, 0.95)

	var info_margin := MarginContainer.new()
	info_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_margin.add_theme_constant_override("margin_left", 68)
	info_margin.add_theme_constant_override("margin_top", 88)
	info_margin.add_theme_constant_override("margin_right", 68)
	info_margin.add_theme_constant_override("margin_bottom", 88)
	info_drawer_panel.add_child(info_margin)

	var info_scroll := ScrollContainer.new()
	info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.follow_focus = false
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	info_margin.add_child(info_scroll)

	info_content_root = VBoxContainer.new()
	info_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_content_root.add_theme_constant_override("separation", 12)
	info_scroll.add_child(info_content_root)

	var info_header := HBoxContainer.new()
	info_header.add_theme_constant_override("separation", 10)
	info_content_root.add_child(info_header)

	info_avatar = stage_helper.build_avatar_node(52, false, avatar_glow_texture, avatar_ring_texture)
	info_header.add_child(info_avatar)

	var info_title_box := VBoxContainer.new()
	info_title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_title_box.add_theme_constant_override("separation", 2)
	info_header.add_child(info_title_box)

	info_title_label = UIFactory.make_label("", 18, Color("f5e9c8"), true)
	info_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_title_box.add_child(info_title_label)

	info_hint_label = UIFactory.make_label("", 13, Color("9fc7ff"), true)
	info_hint_label.visible = false
	info_title_box.add_child(info_hint_label)

	info_quote_label = UIFactory.make_label("", 15, Color("e8d8b0"), true)
	info_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_content_root.add_child(info_quote_label)

	var info_divider_top := HSeparator.new()
	info_divider_top.add_theme_stylebox_override("separator", _make_line_style(Color("c89968"), 1))
	info_content_root.add_child(info_divider_top)

	info_ally_name_label = UIFactory.make_label("", 16, Color("a9cbff"), true)
	info_content_root.add_child(info_ally_name_label)

	info_ally_desc_label = UIFactory.make_label("", 16, Color("e6d6ad"))
	info_ally_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_content_root.add_child(info_ally_desc_label)

	var info_divider_bottom := HSeparator.new()
	info_divider_bottom.add_theme_stylebox_override("separator", _make_line_style(Color("c89968"), 1))
	info_content_root.add_child(info_divider_bottom)

	info_enemy_name_label = UIFactory.make_label("", 16, Color("ffb097"), true)
	info_content_root.add_child(info_enemy_name_label)

	info_enemy_desc_label = UIFactory.make_label("", 16, Color("e6d6ad"))
	info_enemy_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_content_root.add_child(info_enemy_desc_label)

	info_box = null

	# ── 卡牌详情浮动面板 ── 选中卡牌时从右侧弹出，跟随卡牌位置
	var card_detail_panel := PanelContainer.new()
	card_detail_panel.z_index = 150
	card_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_detail_panel.top_level = true
	card_detail_panel.visible = false
	card_detail_panel.custom_minimum_size = Vector2(230, 200)
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(1, 1, 1, 0.86)
	detail_style.corner_radius_top_left = 12
	detail_style.corner_radius_top_right = 12
	detail_style.corner_radius_bottom_left = 12
	detail_style.corner_radius_bottom_right = 12
	detail_style.border_width_left = 1
	detail_style.border_width_top = 1
	detail_style.border_width_right = 1
	detail_style.border_width_bottom = 1
	detail_style.border_color = Color("d9e5ff")
	detail_style.shadow_color = Color(0.24, 0.31, 0.44, 0.12)
	detail_style.shadow_size = 18
	detail_style.shadow_offset = Vector2(0, 8)
	detail_style.content_margin_left = 14
	detail_style.content_margin_top = 12
	detail_style.content_margin_right = 14
	detail_style.content_margin_bottom = 12
	card_detail_panel.add_theme_stylebox_override("panel", detail_style)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_theme_constant_override("separation", 4)
	card_detail_panel.add_child(detail_vbox)

	var detail_header := HBoxContainer.new()
	detail_header.add_theme_constant_override("separation", 6)
	detail_vbox.add_child(detail_header)

	var detail_avatar := stage_helper.build_avatar_node(40, false, avatar_glow_texture, avatar_ring_texture)
	detail_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_header.add_child(detail_avatar)

	var detail_title_box := VBoxContainer.new()
	detail_title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_title_box.add_theme_constant_override("separation", 2)
	detail_header.add_child(detail_title_box)

	var detail_name_row := HBoxContainer.new()
	detail_name_row.add_theme_constant_override("separation", 6)
	detail_title_box.add_child(detail_name_row)

	var detail_code := UIFactory.make_label("", 20, Color("d0a24e"), true)
	detail_name_row.add_child(detail_code)

	var detail_sep := UIFactory.make_label("·", 18, Color("8e95a6"), true)
	detail_name_row.add_child(detail_sep)

	var detail_name := UIFactory.make_label("", 18, Color("27303d"), true)
	detail_name_row.add_child(detail_name)

	var detail_fate := UIFactory.make_label("", 16, Color("d0a24e"), true)
	detail_vbox.add_child(detail_fate)

	var detail_quote := UIFactory.make_label("", 11, Color("596274"))
	detail_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(detail_quote)

	var detail_divider1 := HSeparator.new()
	detail_divider1.add_theme_stylebox_override("separator", _make_line_style(Color("d9e5ff"), 1))
	detail_vbox.add_child(detail_divider1)

	var detail_ally_label := UIFactory.make_label("", 13, Color("5f8dbb"), true)
	detail_vbox.add_child(detail_ally_label)

	var detail_ally_desc := UIFactory.make_label("", 11, Color("4f5b71"))
	detail_ally_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(detail_ally_desc)

	var detail_divider2 := HSeparator.new()
	detail_divider2.add_theme_stylebox_override("separator", _make_line_style(Color("d9e5ff"), 1))
	detail_vbox.add_child(detail_divider2)

	var detail_enemy_label := UIFactory.make_label("", 13, Color("c5846b"), true)
	detail_vbox.add_child(detail_enemy_label)

	var detail_enemy_desc := UIFactory.make_label("", 11, Color("4f5b71"))
	detail_enemy_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(detail_enemy_desc)

	set_meta("card_detail_panel", card_detail_panel)
	set_meta("card_detail_style", detail_style)
	set_meta("detail_vbox", detail_vbox)
	set_meta("detail_avatar", detail_avatar)
	set_meta("detail_code", detail_code)
	set_meta("detail_name", detail_name)
	set_meta("detail_fate", detail_fate)
	set_meta("detail_quote", detail_quote)
	set_meta("detail_ally_label", detail_ally_label)
	set_meta("detail_ally_desc", detail_ally_desc)
	set_meta("detail_enemy_label", detail_enemy_label)
	set_meta("detail_enemy_desc", detail_enemy_desc)

	var deck_shell := Control.new()
	deck_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_shell.size_flags_stretch_ratio = 1.9
	root.add_child(deck_shell)

	var deck_margin := MarginContainer.new()
	deck_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_margin.add_theme_constant_override("margin_left", 10)
	deck_margin.add_theme_constant_override("margin_top", 10)
	deck_margin.add_theme_constant_override("margin_right", 10)
	deck_margin.add_theme_constant_override("margin_bottom", 12)
	deck_shell.add_child(deck_margin)

	var deck_root := VBoxContainer.new()
	deck_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_root.add_theme_constant_override("separation", 2)
	deck_margin.add_child(deck_root)

	var deck_header := HBoxContainer.new()
	deck_header.custom_minimum_size = Vector2(0, 18)
	deck_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_root.add_child(deck_header)
	deck_count_label = UIFactory.make_label("", 12, Color("7b879b"), true)
	deck_count_label.visible = false
	deck_header.add_child(deck_count_label)

	var deck_stage := Control.new()
	deck_stage.custom_minimum_size = Vector2(0, 268)
	deck_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_stage.clip_contents = false
	deck_root.add_child(deck_stage)

	deck_grid = Control.new()
	deck_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	deck_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_grid.offset_left = 8.0
	deck_grid.offset_right = -8.0
	deck_grid.offset_top = 4.0
	deck_grid.offset_bottom = -8.0
	deck_grid.clip_contents = false
	deck_stage.add_child(deck_grid)
	deck_stage.add_child(card_detail_panel)
	deck_grid.resized.connect(_on_deck_area_resized)

	secondary_button = _make_fab_button("↩", Color(1, 1, 1, 0.80), Color("72809c"), Color("dce6ff"), 22)
	secondary_button.custom_minimum_size = Vector2(72, 72)
	secondary_button.anchor_left = 1.0
	secondary_button.anchor_top = 1.0
	secondary_button.anchor_right = 1.0
	secondary_button.anchor_bottom = 1.0
	secondary_button.offset_left = -86.0
	secondary_button.offset_top = -86.0
	secondary_button.offset_right = -10.0
	secondary_button.offset_bottom = -10.0
	secondary_button.z_index = 22
	secondary_button.tooltip_text = "放回并结束回合"
	secondary_button.visible = false
	secondary_button.pressed.connect(_on_secondary_pressed)
	deck_stage.add_child(secondary_button)

	log_box = UIFactory.make_rich_text()
	log_box.bbcode_enabled = true
	log_box.scroll_active = true
	log_box.selection_enabled = true
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_modal_nodes := TheaterModal.build_log_modal(self, log_box)
	log_backdrop = log_modal_nodes["backdrop"] as ColorRect
	log_panel = log_modal_nodes["panel"] as Control
	var log_close_button := log_modal_nodes["close_button"] as Button

	log_close_button.pressed.connect(_hide_log_modal)
	log_backdrop.gui_input.connect(_on_log_backdrop_gui_input)

	ally_tooltip_panel = PanelContainer.new()
	ally_tooltip_panel.visible = false
	ally_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ally_tooltip_panel.top_level = true
	ally_tooltip_panel.custom_minimum_size = Vector2(332, 196)
	ally_tooltip_panel.z_index = 155
	add_child(ally_tooltip_panel)
	var ally_tooltip_style := StyleBoxFlat.new()
	ally_tooltip_style.bg_color = Color(0.20, 0.06, 0.05, 0.96)
	ally_tooltip_style.border_color = Color("d1a85a")
	ally_tooltip_style.border_width_left = 2
	ally_tooltip_style.border_width_top = 2
	ally_tooltip_style.border_width_right = 2
	ally_tooltip_style.border_width_bottom = 2
	ally_tooltip_style.corner_radius_top_left = 18
	ally_tooltip_style.corner_radius_top_right = 18
	ally_tooltip_style.corner_radius_bottom_left = 18
	ally_tooltip_style.corner_radius_bottom_right = 18
	ally_tooltip_style.shadow_color = Color(0, 0, 0, 0.26)
	ally_tooltip_style.shadow_size = 18
	ally_tooltip_style.shadow_offset = Vector2(0, 8)
	ally_tooltip_style.content_margin_left = 22
	ally_tooltip_style.content_margin_top = 18
	ally_tooltip_style.content_margin_right = 22
	ally_tooltip_style.content_margin_bottom = 18
	ally_tooltip_panel.add_theme_stylebox_override("panel", ally_tooltip_style)

	ally_tooltip_text = UIFactory.make_rich_text()
	ally_tooltip_text.fit_content = true
	ally_tooltip_text.scroll_active = false
	ally_tooltip_text.selection_enabled = false
	ally_tooltip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ally_tooltip_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ally_tooltip_text.custom_minimum_size = Vector2(288, 0)
	ally_tooltip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ally_tooltip_text.add_theme_color_override("default_color", Color("f1ddc3"))
	ally_tooltip_text.add_theme_font_size_override("normal_font_size", 15)
	ally_tooltip_panel.add_child(ally_tooltip_text)

	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(1, 0, 0, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.z_index = 100
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(damage_overlay)

	var msg_bar := HBoxContainer.new()
	msg_bar.custom_minimum_size = Vector2(0, 24)
	msg_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	msg_bar.visible = false
	root.add_child(msg_bar)
	toast_label = UIFactory.make_label("", 12, Color("334052"))
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	toast_label.clip_text = true
	msg_bar.add_child(toast_label)

	_build_modal()
	call_deferred("_refresh_info_drawer", false)


func _build_modal() -> void:
	var modal_nodes := TheaterModal.build_choice_modal(self)
	modal_backdrop = modal_nodes["backdrop"] as ColorRect
	modal_panel = modal_nodes["panel"] as Control
	modal_root = modal_nodes["modal_root"] as VBoxContainer
	modal_title = modal_nodes["title"] as Label
	modal_body_center = modal_nodes["body_center"] as CenterContainer
	modal_body = modal_nodes["body"] as RichTextLabel
	modal_detail_panel = modal_nodes["detail_panel"] as PanelContainer
	modal_detail_text = modal_nodes["detail_text"] as RichTextLabel
	modal_flex_spacer = modal_nodes["flex_spacer"] as Control
	modal_buttons_center = modal_nodes["buttons_center"] as CenterContainer
	modal_buttons = modal_nodes["buttons"] as VBoxContainer
	modal_tooltip_panel = modal_nodes["tooltip_panel"] as PanelContainer
	modal_tooltip_text = modal_nodes["tooltip_text"] as RichTextLabel
	_build_modal_recruit_detail_ui()
	_build_modal_replace_ui()


func _build_modal_recruit_detail_ui() -> void:
	if modal_detail_panel == null:
		return

	modal_recruit_detail_root = VBoxContainer.new()
	modal_recruit_detail_root.visible = false
	modal_recruit_detail_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_recruit_detail_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_recruit_detail_root.add_theme_constant_override("separation", 8)
	modal_detail_panel.add_child(modal_recruit_detail_root)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 14)
	modal_recruit_detail_root.add_child(top_row)

	var badge_panel := PanelContainer.new()
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.34, 0.15, 0.10, 0.96)
	badge_style.border_color = Color("d1a85a")
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 10
	badge_style.corner_radius_top_right = 10
	badge_style.corner_radius_bottom_left = 10
	badge_style.corner_radius_bottom_right = 10
	badge_style.content_margin_left = 10
	badge_style.content_margin_top = 5
	badge_style.content_margin_right = 10
	badge_style.content_margin_bottom = 5
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	top_row.add_child(badge_panel)

	modal_recruit_badge_label = UIFactory.make_label("新入队伙伴", 14, Color("f6d58e"), true)
	badge_panel.add_child(modal_recruit_badge_label)

	modal_recruit_name_label = UIFactory.make_label("", 24, Color("fff4d8"), true)
	modal_recruit_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_recruit_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_recruit_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	top_row.add_child(modal_recruit_name_label)

	modal_recruit_status_label = UIFactory.make_label("", 14, Color("f4e2ba"), true)
	modal_recruit_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	modal_recruit_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(modal_recruit_status_label)

	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", 12)
	modal_recruit_detail_root.add_child(bottom_row)

	modal_recruit_skill_name_label = UIFactory.make_label("", 15, Color("9fd4ff"), true)
	modal_recruit_skill_name_label.custom_minimum_size = Vector2(210, 0)
	bottom_row.add_child(modal_recruit_skill_name_label)

	modal_recruit_skill_desc_label = UIFactory.make_label("", 14, Color("f6ebcf"))
	modal_recruit_skill_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_recruit_skill_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_row.add_child(modal_recruit_skill_desc_label)

	modal_recruit_warning_label = UIFactory.make_label("", 14, Color("ff9b84"), true)
	modal_recruit_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_recruit_warning_label.visible = false
	modal_recruit_detail_root.add_child(modal_recruit_warning_label)


func _make_modal_wine_panel(fill_color: Color = Color(0.24, 0.08, 0.06, 0.96), border_color: Color = Color("d1a85a"), radius: int = 18) -> PanelContainer:
	var panel := UIFactory.make_panel(fill_color, border_color, radius, 2)
	var style := panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		flat.bg_color = fill_color
		flat.border_color = border_color
		flat.shadow_color = Color(0, 0, 0, 0.20)
		flat.shadow_size = 14
		flat.shadow_offset = Vector2(0, 6)
		flat.content_margin_left = 18
		flat.content_margin_top = 16
		flat.content_margin_right = 18
		flat.content_margin_bottom = 16
	return panel


func _make_modal_section_text(font_size: int = 15, color: Color = Color("f6ebcf")) -> RichTextLabel:
	var text := UIFactory.make_rich_text()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.selection_enabled = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_color_override("default_color", color)
	text.add_theme_font_size_override("normal_font_size", font_size)
	return text


func _build_modal_replace_ui() -> void:
	if modal_root == null:
		return

	modal_replace_root = VBoxContainer.new()
	modal_replace_root.visible = false
	modal_replace_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_replace_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_replace_root.add_theme_constant_override("separation", 14)
	modal_root.add_child(modal_replace_root)
	if modal_flex_spacer != null:
		modal_root.move_child(modal_replace_root, modal_flex_spacer.get_index())

	modal_replace_subtitle_label = UIFactory.make_label("", 16, Color("664223"), true)
	modal_replace_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_replace_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_replace_root.add_child(modal_replace_subtitle_label)

	modal_replace_compare_row = HBoxContainer.new()
	modal_replace_compare_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_replace_compare_row.add_theme_constant_override("separation", 14)
	modal_replace_root.add_child(modal_replace_compare_row)

	modal_replace_new_panel = _make_modal_wine_panel(Color(0.28, 0.10, 0.08, 0.96), Color("d7ae67"), 18)
	modal_replace_new_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_replace_compare_row.add_child(modal_replace_new_panel)

	modal_replace_new_text = _make_modal_section_text(15, Color("f6ebcf"))
	modal_replace_new_panel.add_child(modal_replace_new_text)

	modal_replace_current_panel = _make_modal_wine_panel(Color(0.22, 0.07, 0.05, 0.96), Color("c98d6a"), 18)
	modal_replace_current_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_replace_compare_row.add_child(modal_replace_current_panel)

	modal_replace_current_text = _make_modal_section_text(15, Color("f6ebcf"))
	modal_replace_current_panel.add_child(modal_replace_current_text)

	var replace_choices_label := UIFactory.make_label("选择离队对象", 15, Color("6a4726"), true)
	replace_choices_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_replace_root.add_child(replace_choices_label)

	modal_replace_candidates_grid = GridContainer.new()
	modal_replace_candidates_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_replace_candidates_grid.add_theme_constant_override("h_separation", 12)
	modal_replace_candidates_grid.add_theme_constant_override("v_separation", 12)
	modal_replace_root.add_child(modal_replace_candidates_grid)

	modal_replace_action_row = HBoxContainer.new()
	modal_replace_action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_replace_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_replace_action_row.add_theme_constant_override("separation", 14)
	modal_replace_root.add_child(modal_replace_action_row)

	modal_replace_confirm_button = TheaterModal.make_option_button("确认替换", "primary")
	modal_replace_confirm_button.pressed.connect(_on_modal_replace_confirm_pressed)
	modal_replace_action_row.add_child(modal_replace_confirm_button)

	modal_replace_cancel_button = TheaterModal.make_option_button("放弃入队", "secondary")
	modal_replace_cancel_button.pressed.connect(_on_modal_replace_cancel_pressed)
	modal_replace_action_row.add_child(modal_replace_cancel_button)


func _on_flip_pressed() -> void:
	_resolve_selected_card()


func _show_log_modal() -> void:
	if log_backdrop != null:
		log_backdrop.modulate = Color(1, 1, 1, 0)
		log_backdrop.visible = true
		_refresh_log_modal_layout()
		await get_tree().process_frame
		_refresh_log_modal_layout()
		log_backdrop.modulate = Color.WHITE


func _hide_log_modal() -> void:
	if log_backdrop != null:
		log_backdrop.visible = false


func _request_exit_to_select() -> void:
	var confirmed := await _confirm_choice(
		"返回人格选择？",
		"当前战斗进度将丢失，确定要返回人格选择页面吗？",
		"返回选人",
		"继续战斗"
	)
	if confirmed:
		exit_to_select_requested.emit()


func _on_deck_card_pressed(deck_index: int) -> void:
	if deck_index < 0 or deck_index >= state.deck.size():
		return
	if state.deck[deck_index]["revealed"]:
		return
	if selected_deck_index == deck_index and not reveal_result_locked and not busy and state.phase == "battle_idle":
		_on_flip_pressed()
		return
	_play_sfx("card_select")
	selected_deck_index = deck_index
	var card: Dictionary = state.deck[selected_deck_index]
	_unlock_reveal_preview()
	_update_card_info(card["character"], selected_deck_index)
	_refresh_action_buttons()
	_update_deck_card_selection()
	var selected_button: Button = deck_card_nodes.get(selected_deck_index) as Button
	if selected_button != null:
		_play_deck_card_focus_burst(selected_button, false)


func _on_secondary_pressed() -> void:
	if busy or selected_deck_index < 0 or state.phase != "battle_idle":
		return
	var peek_data: Dictionary = _get_peek_data(selected_deck_index)
	if peek_data.get("mode", "") != "think":
		return

	busy = true
	_begin_turn(false)
	_append_log("三思之后，你将 %s 放回牌池并结束本回合。" % state.deck[selected_deck_index]["character"]["code"])
	await _finish_turn(false)


func _refresh_table_surface_layout() -> void:
	if table_surface_host == null or table_surface_rect == null or table_surface_texture == null:
		return

	var host_size := table_surface_host.size
	if host_size.x <= 0.0 or host_size.y <= 0.0:
		return

	var texture_size := table_surface_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale_factor := maxf(host_size.x / texture_size.x, host_size.y / texture_size.y)
	var draw_size := texture_size * scale_factor
	table_surface_rect.size = draw_size
	table_surface_rect.position = (host_size - draw_size) * 0.5


func _update_ui() -> void:
	_update_header()
	_update_allies_view()
	_update_deck_view()
	if selected_deck_index >= 0 and selected_deck_index < state.deck.size() and not state.deck[selected_deck_index]["revealed"]:
		var selected_card: Dictionary = state.deck[selected_deck_index]
		if not reveal_result_locked:
			_update_card_info(selected_card["character"], selected_deck_index)
	else:
		selected_deck_index = -1
		if not reveal_result_locked:
			_update_card_info({})
		if not reveal_result_locked and reveal_preview_card == null:
			_update_reveal_preview({}, "")
	_refresh_action_buttons()


func _update_header() -> void:
	hero_label.text = "%s · %s" % [state.player_character.get("code", "未知"), state.player_character.get("name", "")]
	var hero_charges := _get_hero_charges_count()
	hero_charges_label.text = "✦ %d" % hero_charges if hero_charges > 0 else ""
	hero_charges_label.visible = hero_charges > 0
	hero_charges_label.tooltip_text = _get_hero_charges_text()

	var new_hp := state.hp
	if _last_hp >= 0 and new_hp < _last_hp:
		_play_damage_feedback()
	hp_bar.max_value = maxf(float(state.max_hp), 1.0)
	hp_bar.value = float(new_hp)
	hp_value_label.text = "%d/%d" % [new_hp, state.max_hp]
	_sync_hp_icon_row(life_icons_container, hp_heart_texture, new_hp, state.max_hp, 34)
	if life_icons_container != null:
		life_icons_container.tooltip_text = "生命 %d/%d" % [new_hp, state.max_hp]

	var energy_visible := clampi(hero_charges, 0, 6)
	_sync_icon_row(energy_icons_container, energy_bolt_texture, energy_visible, 32)
	if energy_icons_container != null:
		energy_icons_container.tooltip_text = _get_hero_charges_text()

	round_label.text = "%d/%d" % [state.revealed_cards(), state.total_cards()]
	var pressure := state.pressure_multiplier()
	var total_enemy_multiplier := pressure * state.ally_loss_multiplier()
	pressure_label.text = "+ %d" % state.usable_ally_slots()
	pressure_label.modulate = Color("7f8c4a")
	pressure_label.tooltip_text = "当前可用伙伴槽位 %d，敌伤总倍率 ×%.2f。" % [state.usable_ally_slots(), total_enemy_multiplier]
	timer_label.text = "×%.2f" % pressure
	timer_label.tooltip_text = "当前回合压力倍率 ×%.2f。" % pressure

	_update_hp_bar_style(new_hp, state.max_hp)
	_last_hp = new_hp


func _build_meter_text(filled: int, total: int, filled_symbol: String, empty_symbol: String) -> String:
	var pieces: PackedStringArray = []
	for i in range(maxi(total, 0)):
		pieces.append(filled_symbol if i < filled else empty_symbol)
	return " ".join(pieces)


func _refresh_header_if_ready() -> void:
	if not is_inside_tree():
		return
	if hero_label == null or hero_charges_label == null:
		return
	if life_icons_container == null or energy_icons_container == null:
		return
	if round_label == null or pressure_label == null or timer_label == null:
		return
	_update_header()


func _play_damage_feedback() -> void:
	# HP条闪红
	if hp_bar != null:
		var flash := create_tween()
		flash.tween_property(hp_bar, "modulate", Color(1.5, 0.5, 0.5), 0.08)
		flash.tween_property(hp_bar, "modulate", Color.WHITE, 0.3)

	# 屏幕红闪
	if damage_overlay != null:
		damage_overlay.color = Color(1, 0, 0, 0.0)
		var tween := create_tween()
		tween.tween_property(damage_overlay, "color:a", 0.18, 0.06)
		tween.tween_property(damage_overlay, "color:a", 0.0, 0.35)


# ── P2-3: HP条渐变色 + 低血量危险脉冲 ──
var _hp_danger_tween: Tween

func _update_hp_bar_style(hp: int, max_hp: int) -> void:
	if hp_bar == null:
		return
	var ratio := float(hp) / maxf(float(max_hp), 1.0)
	var fill_style := hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style == null:
		return

	# 渐变色：>60% 绿 → 30~60% 黄 → <30% 红
	if ratio > 0.60:
		var t := (ratio - 0.60) / 0.40
		fill_style.bg_color = Color("5ce08a").lerp(Color("3cc06a"), t)
	elif ratio > 0.30:
		var t := (ratio - 0.30) / 0.30
		fill_style.bg_color = Color("f0c977").lerp(Color("5ce08a"), t)
	else:
		var t := ratio / 0.30
		fill_style.bg_color = Color("ff5b5b").lerp(Color("f0c977"), t)

	hp_bar.add_theme_stylebox_override("fill", fill_style)  # 触发重绘

	# 低血量危险脉冲（<30%）
	if ratio < 0.30:
		_start_hp_danger_pulse()
	else:
		_stop_hp_danger_pulse()


func _start_hp_danger_pulse() -> void:
	if _hp_danger_tween != null and _hp_danger_tween.is_valid():
		return  # 已在脉冲
	if hp_bar == null:
		return
	_hp_danger_tween = create_tween()
	_hp_danger_tween.set_loops()
	_hp_danger_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hp_danger_tween.tween_property(hp_bar, "modulate", Color(1.4, 0.6, 0.6), 0.40)
	_hp_danger_tween.tween_property(hp_bar, "modulate", Color(1.0, 0.85, 0.85), 0.40)


func _stop_hp_danger_pulse() -> void:
	if _hp_danger_tween != null and _hp_danger_tween.is_valid():
		_hp_danger_tween.kill()
		_hp_danger_tween = null
	if hp_bar != null:
		hp_bar.modulate = Color.WHITE


func _get_pressure_color(multiplier: float) -> Color:
	if multiplier >= 1.45:
		return Color("ff6b57")
	if multiplier >= 1.30:
		return Color("f59e0b")
	if multiplier >= 1.18:
		return Color("f6d365")
	return Color("86efac")


func _get_hero_charges_count() -> int:
	var hero: String = state.player_character.get("code", "")
	match hero:
		"CTRL": return state.peek_charges
		"THIN-K": return state.think_charges
		"OH-NO": return state.skip_charges
		"ZZZZ": return state.skip_charges
		"WOC!": return state.reroll_charges
		"FAKE": return state.fate_reverse_charges
		"DEAD": return 1 if not state.undying else 0
		"BOSS": return state.max_ally_slots
		"POOR": return state.max_ally_slots
		_: return 0


func _get_hero_charges_text() -> String:
	var hero: String = state.player_character.get("code", "")
	match hero:
		"CTRL":
			return "窥视次数: %d" % state.peek_charges
		"THIN-K":
			return "三思次数: %d" % state.think_charges
		"OH-NO":
			return "回避次数: %d" % state.skip_charges
		"ZZZZ":
			return "补觉次数: %d" % state.skip_charges
		"WOC!":
			return "重来次数: %d" % state.reroll_charges
		"FAKE":
			return "变脸次数: %d" % state.fate_reverse_charges
		"DEAD":
			return "不死: %s" % ("已触发" if state.undying else "未触发")
		"BOSS":
			return "伙伴槽位: %d" % state.max_ally_slots
		"POOR":
			return "伙伴槽位: %d (精通)" % state.max_ally_slots
		_:
			return state.player_character.get("skills", {}).get("hero", {}).get("description", "")


func _update_allies_view() -> void:
	_hide_ally_tooltip()
	_sync_player_seat()
	_sync_ally_seats()
	_sync_enemy_seat()


func _get_all_seat_ids() -> Array:
	var seat_ids: Array = ["enemy", "player"]
	seat_ids.append_array(_get_all_ally_seat_ids())
	return seat_ids


func _get_all_ally_seat_ids() -> Array:
	var seat_ids: Array = []
	var total_count := _get_base_visible_ally_seat_count() + EXTRA_RENDERED_ALLY_SEATS
	for index in range(total_count):
		seat_ids.append("ally_%d" % (index + 1))
	return seat_ids


func _get_base_visible_ally_seat_count() -> int:
	return GameState.MAX_ALLIES


func _get_slotless_ally_count() -> int:
	if state == null:
		return 0
	var count := 0
	for ally in state.allies:
		if not state.ally_uses_slot(ally):
			count += 1
	return count


func _get_standard_visible_ally_seat_count() -> int:
	var base_count := _get_base_visible_ally_seat_count()
	if state == null:
		return base_count
	return clampi(maxi(base_count, int(state.max_ally_slots)), base_count, _get_all_ally_seat_ids().size())


func _get_visible_ally_seat_assignments() -> Dictionary:
	var assignments := {}
	if state == null:
		return assignments

	var visible_seat_ids := _get_visible_ally_seat_ids()
	var standard_seat_count := mini(_get_standard_visible_ally_seat_count(), visible_seat_ids.size())
	var slotted_index := 0
	for ally in state.allies:
		if not state.ally_uses_slot(ally):
			continue
		if slotted_index < standard_seat_count:
			assignments[visible_seat_ids[slotted_index]] = ally
		slotted_index += 1

	var slotless_index := 0
	for ally in state.allies:
		if state.ally_uses_slot(ally):
			continue
		var seat_index := standard_seat_count + slotless_index
		if seat_index < visible_seat_ids.size():
			assignments[visible_seat_ids[seat_index]] = ally
		slotless_index += 1

	return assignments


func _get_visible_ally_seat_count() -> int:
	var standard_count := _get_standard_visible_ally_seat_count()
	return clampi(standard_count + _get_slotless_ally_count(), standard_count, _get_all_ally_seat_ids().size())


func _get_visible_ally_seat_ids() -> Array:
	var visible_seat_ids: Array = []
	var all_ally_seat_ids := _get_all_ally_seat_ids()
	var visible_count := mini(_get_visible_ally_seat_count(), all_ally_seat_ids.size())
	for index in range(visible_count):
		visible_seat_ids.append(all_ally_seat_ids[index])
	return visible_seat_ids


func _seat_uses_small_card_template(seat_id: String) -> bool:
	return seat_id.begins_with("ally_")


func _set_seat_border_tone(seat: Control, tone: Color, border_alpha: float = 0.52) -> void:
	if seat == null:
		return
	var has_character := bool(seat.get_meta("has_character", false))
	var seat_id := str(seat.get_meta("seat_id", ""))
	var use_small_card_template := _seat_uses_small_card_template(seat_id) and seat_small_card_template_texture != null
	var background: TextureRect = seat.get_meta("background") as TextureRect
	if background != null:
		if use_small_card_template:
			background.modulate = Color.WHITE
		else:
			var pedestal_tone := tone.darkened(0.18 if has_character else 0.12)
			background.modulate = Color(pedestal_tone.r, pedestal_tone.g, pedestal_tone.b, 0.98 if has_character else 0.94)
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	if border_ring != null:
		border_ring.modulate = Color(tone.r, tone.g, tone.b, border_alpha)
	var placeholder: Label = seat.get_meta("placeholder") as Label
	if placeholder != null:
		if use_small_card_template:
			placeholder.add_theme_color_override("font_color", Color("815633"))
			placeholder.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.03, 0.34))
		else:
			placeholder.add_theme_color_override("font_color", Color(tone.r, tone.g, tone.b, 0.48))
	var avatar: TextureRect = seat.get_meta("avatar") as TextureRect
	if avatar != null and avatar.material is ShaderMaterial and not use_small_card_template:
		(avatar.material as ShaderMaterial).set_shader_parameter("border_color", tone)


func _get_seat_tone(seat_id: String) -> Color:
	var config: Dictionary = SEAT_CONFIG.get(seat_id, {})
	return config.get("tone", Color("8fa49d"))


func _get_seat_placeholder_symbol(seat_id: String) -> String:
	if seat_id == "enemy":
		return "?"
	if seat_id == "player":
		return ""
	return "+"


func _build_seat_system() -> void:
	seat_nodes.clear()
	for seat_id in _get_all_seat_ids():
		var seat := _create_seat_node(seat_id)
		seat_layer.add_child(seat)
		seat_nodes[seat_id] = seat


func _create_seat_node(seat_id: String) -> Control:
	var config: Dictionary = SEAT_CONFIG.get(seat_id, {})
	var tone: Color = config.get("tone", Color("8fa49d"))
	var seat := Control.new()
	seat.name = "Seat_" + seat_id
	seat.custom_minimum_size = Vector2.ZERO
	seat.size = Vector2.ZERO
	seat.pivot_offset = seat.size * 0.5
	seat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seat.clip_contents = false
	seat.set_meta("seat_id", seat_id)
	seat.set_meta("has_character", false)
	seat.set_meta("uid", -1)
	seat.set_meta("ally_data", {})
	seat.set_meta("uses_small_card_template", _seat_uses_small_card_template(seat_id))

	var background := TextureRect.new()
	background.name = "Pedestal"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = seat_small_card_template_texture if _seat_uses_small_card_template(seat_id) and seat_small_card_template_texture != null else (seat_card_frame_texture if seat_card_frame_texture != null else seat_card_pedestal_texture)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.modulate = Color.WHITE
	background.z_index = -2
	seat.add_child(background)

	var avatar_container := Control.new()
	avatar_container.name = "AvatarContainer"
	avatar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_container.clip_contents = true
	avatar_container.mouse_entered.connect(_on_seat_avatar_mouse_enter.bind(seat_id, avatar_container.get_instance_id()))
	avatar_container.mouse_exited.connect(_hide_ally_tooltip)
	seat.add_child(avatar_container)

	var avatar := TextureRect.new()
	avatar.name = "Avatar"
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.visible = false
	avatar_container.add_child(avatar)

	var seat_name_label := UIFactory.make_label("", 13, Color("4c280f"), true)
	seat_name_label.name = "SeatName"
	seat_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seat_name_label.anchor_left = 0.12
	seat_name_label.anchor_right = 0.88
	seat_name_label.anchor_top = 1.0
	seat_name_label.anchor_bottom = 1.0
	seat_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seat_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seat_name_label.visible = false
	seat_name_label.z_index = 2
	avatar_container.add_child(seat_name_label)

	var placeholder := Label.new()
	placeholder.name = "Placeholder"
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.text = _get_seat_placeholder_symbol(seat_id)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 38)
	placeholder.add_theme_color_override("font_color", Color("d8a878"))
	placeholder.add_theme_color_override("font_outline_color", Color(0.20, 0.10, 0.04, 0.8))
	placeholder.add_theme_constant_override("outline_size", 4)
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seat.add_child(placeholder)

	var border_ring := TextureRect.new()
	border_ring.name = "BorderRing"
	border_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_ring.texture = seat_card_border_texture
	border_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	border_ring.stretch_mode = TextureRect.STRETCH_SCALE
	border_ring.modulate = Color(tone.r, tone.g, tone.b, 0.85)
	border_ring.z_index = 1
	border_ring.visible = seat_card_frame_texture == null
	seat.add_child(border_ring)

	var status_icon := Control.new()
	status_icon.name = "StatusIcon"
	status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_icon.z_index = 2
	status_icon.visible = false
	seat.add_child(status_icon)

	var hit_flash := ColorRect.new()
	hit_flash.name = "HitFlash"
	hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_flash.color = Color(1.0, 0.20, 0.15, 0.0)
	hit_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit_flash.visible = false
	hit_flash.z_index = 3
	seat.add_child(hit_flash)

	seat.set_meta("background", background)
	seat.set_meta("avatar_container", avatar_container)
	seat.set_meta("avatar", avatar)
	seat.set_meta("seat_name_label", seat_name_label)
	seat.set_meta("border_ring", border_ring)
	seat.set_meta("status_icon", status_icon)
	seat.set_meta("placeholder", placeholder)
	seat.set_meta("hit_flash", hit_flash)
	return seat


func _get_table_inner_ellipse_rect() -> Rect2:
	if seat_layer == null:
		return Rect2()
	var stage_size := seat_layer.size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return Rect2()
	var ellipse_center := Vector2(stage_size.x * 0.50, stage_size.y * 0.46)
	var ellipse_radius := Vector2(stage_size.x * 0.26, stage_size.y * 0.16)
	return Rect2(ellipse_center - ellipse_radius, ellipse_radius * 2.0)


func _get_seat_orbit_center(screen_size: Vector2) -> Vector2:
	var layout_rect := _get_seat_layout_rect(screen_size)
	return layout_rect.position + Vector2(layout_rect.size.x * 0.50, layout_rect.size.y * 0.52)


func _get_seat_orbit_radius(screen_size: Vector2) -> Vector2:
	var layout_rect := _get_seat_layout_rect(screen_size)
	return Vector2(
		clampf(layout_rect.size.x * 0.39, 248.0, 372.0),
		clampf(layout_rect.size.y * 0.26, 86.0, 132.0)
	)


func _get_seat_layout_rect(screen_size: Vector2) -> Rect2:
	var left := 62.0
	var top := 56.0
	var right := screen_size.x - 64.0
	var bottom := screen_size.y - 198.0
	if info_drawer_host != null:
		var drawer_rect := info_drawer_host.get_rect()
		if drawer_rect.size.x > 0.0:
			right = minf(right, drawer_rect.position.x - 42.0)
	return Rect2(
		Vector2(left, top),
		Vector2(maxf(360.0, right - left), maxf(260.0, bottom - top))
	)


func _get_seat_center_position(seat_id: String, seat_size: float, screen_size: Vector2, inner_ellipse_rect: Rect2) -> Vector2:
	var config: Dictionary = SEAT_CONFIG.get(seat_id, {})
	var orbit_center: Vector2 = _get_seat_orbit_center(screen_size)
	var orbit_radius: Vector2 = _get_seat_orbit_radius(screen_size)
	var angle_deg: float = float(config.get("angle_deg", 0.0))
	var angle_rad: float = deg_to_rad(angle_deg)
	return orbit_center + Vector2(cos(angle_rad) * orbit_radius.x, sin(angle_rad) * orbit_radius.y)


func _refresh_stage_atmosphere_layout() -> void:
	var stage_rect := _get_stage_atmosphere_rect()
	var stage_size := stage_rect.size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		if seat_layer != null:
			stage_size = seat_layer.size
			stage_rect = Rect2(Vector2.ZERO, stage_size)
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return

	var stage_center := stage_rect.position + Vector2(stage_size.x * 0.5, stage_size.y * 0.46)
	if stage_volume_glow != null:
		stage_volume_glow.size = Vector2(
			clampf(stage_size.x * 0.58, 660.0, 1080.0),
			clampf(stage_size.y * 0.88, 460.0, 860.0)
		)
		stage_volume_glow.position = stage_center - stage_volume_glow.size * 0.5 + Vector2(0.0, -stage_size.y * 0.04)
		stage_volume_glow.pivot_offset = stage_volume_glow.size * 0.5
	if stage_floor_haze != null:
		stage_floor_haze.size = Vector2(
			clampf(stage_size.x * 0.96, 860.0, 1440.0),
			clampf(stage_size.y * 0.62, 320.0, 620.0)
		)
		stage_floor_haze.position = Vector2(
			stage_rect.position.x + (stage_size.x - stage_floor_haze.size.x) * 0.5,
			stage_rect.position.y + stage_size.y * 0.36
		)
		stage_floor_haze.pivot_offset = stage_floor_haze.size * 0.5


func _refresh_ambient_dust_node(
	particles: GPUParticles2D,
	stage_size: Vector2,
	profile: Dictionary,
	particle_texture: Texture2D,
	position_override: Variant = null
) -> void:
	if particles == null:
		return
	var target_position := stage_size * 0.5
	if position_override is Vector2:
		target_position = position_override
	if particles.has_method("configure"):
		particles.call("configure", particle_texture, stage_size, profile)
		particles.position = target_position
		return
	particles.texture = particle_texture
	particles.position = target_position
	particles.visibility_rect = Rect2(-stage_size * 0.64, stage_size * 1.28)


func _refresh_ambient_dust_layout() -> void:
	if ambient_dust_particles == null and ambient_dust_foreground_particles == null and ambient_dust_spotlight_particles == null:
		return
	var stage_size := arena_stage.size if arena_stage != null else Vector2.ZERO
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		stage_size = seat_layer.size if seat_layer != null else Vector2.ZERO
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return
	_refresh_ambient_dust_node(ambient_dust_particles, stage_size, AMBIENT_DUST_BACKGROUND_PROFILE, ambient_dust_back_texture)
	_refresh_ambient_dust_node(ambient_dust_foreground_particles, stage_size, AMBIENT_DUST_FOREGROUND_PROFILE, ambient_dust_front_texture)
	var stage_rect := _get_stage_atmosphere_rect()
	var spotlight_stage_size := stage_rect.size if stage_rect.size.x > 0.0 and stage_rect.size.y > 0.0 else stage_size
	var spotlight_position := stage_rect.position + Vector2(spotlight_stage_size.x * 0.5, spotlight_stage_size.y * 0.36)
	if stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		spotlight_position = Vector2(stage_size.x * 0.5, stage_size.y * 0.36)
	_refresh_ambient_dust_node(
		ambient_dust_spotlight_particles,
		spotlight_stage_size,
		AMBIENT_DUST_SPOTLIGHT_PROFILE,
		ambient_dust_back_texture,
		spotlight_position
	)


func _refresh_seat_layout() -> void:
	if seat_layer == null:
		return
	var screen_size := seat_layer.size
	if screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return

	var visible_ally_seats := _get_visible_ally_seat_ids()
	var ally_count := visible_ally_seats.size()

	var ally_card_height := clampf(screen_size.y * 0.24, 176.0, 236.0)
	var ally_card_width := ally_card_height * 0.75
	var ally_gap := clampf(ally_card_width * 0.14, 16.0, 34.0)

	var enemy_card_height := clampf(screen_size.y * 0.42, 280.0, 400.0)
	var enemy_card_width := enemy_card_height * 0.75

	var ally_row_total_w := ally_card_width * float(ally_count) + ally_gap * float(maxi(ally_count - 1, 0))
	var ally_row_left := (screen_size.x - ally_row_total_w) * 0.5
	var ally_row_top := screen_size.y * 0.10

	var enemy_pos := Vector2(
		(screen_size.x - enemy_card_width) * 0.5,
		ally_row_top + ally_card_height + clampf(screen_size.y * 0.04, 24.0, 60.0)
	)

	for seat_id in _get_all_seat_ids():
		var seat: Control = seat_nodes.get(seat_id) as Control
		if seat == null:
			continue

		if seat_id == "player":
			seat.visible = false
			continue

		var is_enemy: bool = seat_id == "enemy"
		var enemy_has_character: bool = is_enemy and bool(seat.get_meta("has_character", false))
		var is_visible: bool = enemy_has_character or visible_ally_seats.has(seat_id)
		seat.visible = is_visible
		if not is_visible:
			continue

		var card_w: float = enemy_card_width if is_enemy else ally_card_width
		var card_h: float = enemy_card_height if is_enemy else ally_card_height
		var target_pos: Vector2
		if is_enemy:
			target_pos = enemy_pos
		else:
			var idx := visible_ally_seats.find(seat_id)
			if idx < 0:
				idx = 0
			target_pos = Vector2(
				ally_row_left + float(idx) * (ally_card_width + ally_gap),
				ally_row_top
			)

		seat.custom_minimum_size = Vector2(card_w, card_h)
		seat.size = seat.custom_minimum_size
		seat.pivot_offset = seat.size * 0.5
		seat.position = target_pos
		seat.z_index = 30 if is_enemy else 20

		var enemy_face_down: bool = is_enemy and not bool(seat.get_meta("has_character", false))
		var use_small_card_template := _seat_uses_small_card_template(seat_id) and seat_small_card_template_texture != null

		var use_tarot_frame: bool = not use_small_card_template and seat_card_frame_texture != null and not enemy_face_down

		var background: TextureRect = seat.get_meta("background") as TextureRect
		if background != null:
			background.size = Vector2(card_w, card_h)
			background.position = Vector2.ZERO
			if enemy_face_down and enemy_card_back_texture != null:
				background.texture = enemy_card_back_texture
				background.modulate = Color(1, 1, 1, 1)
			elif use_small_card_template:
				background.texture = seat_small_card_template_texture
				background.modulate = Color.WHITE
			elif use_tarot_frame:
				background.texture = seat_card_frame_texture
				background.modulate = Color.WHITE
			else:
				background.texture = seat_card_pedestal_texture
				background.modulate = Color(0.96, 0.92, 0.78, 0.92)

		var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
		if border_ring != null:
			border_ring.visible = not use_tarot_frame and not use_small_card_template
			border_ring.size = Vector2(card_w, card_h)
			border_ring.position = Vector2.ZERO
			if enemy_face_down:
				border_ring.modulate = Color(0.95, 0.55, 0.20, 0.95)

		var placeholder_visible: bool = not enemy_face_down and not bool(seat.get_meta("has_character", false))
		var placeholder_node: Label = seat.get_meta("placeholder") as Label
		if placeholder_node != null:
			placeholder_node.visible = placeholder_visible

		var portrait_size: Vector2
		var portrait_pos: Vector2
		if use_small_card_template:
			portrait_size = Vector2(card_w, card_h)
			portrait_pos = Vector2.ZERO
		else:
			var portrait_margin: float = card_w * (0.16 if use_tarot_frame else 0.08)
			portrait_size = Vector2(
				card_w - portrait_margin * 2.0,
				card_h - portrait_margin * 2.0
			)
			portrait_pos = Vector2(portrait_margin, portrait_margin)

		var avatar_container: Control = seat.get_meta("avatar_container") as Control
		if avatar_container != null:
			avatar_container.position = portrait_pos
			avatar_container.size = portrait_size
			avatar_container.pivot_offset = avatar_container.size * 0.5
			avatar_container.set_meta("target_pos", portrait_pos)
		var seat_name_label: Label = seat.get_meta("seat_name_label") as Label
		if seat_name_label != null:
			if use_small_card_template:
				seat_name_label.offset_top = -card_h * 0.27
				seat_name_label.offset_bottom = -card_h * 0.13
				seat_name_label.add_theme_font_size_override("font_size", maxi(12, int(card_h * 0.072)))
			else:
				seat_name_label.visible = false

		var placeholder: Label = seat.get_meta("placeholder") as Label
		if placeholder != null:
			if use_small_card_template:
				placeholder.position = Vector2.ZERO
				placeholder.size = Vector2(card_w, card_h)
				placeholder.add_theme_font_size_override("font_size", maxi(26, int(card_w * 0.26)))
			else:
				placeholder.position = portrait_pos
				placeholder.size = portrait_size
				placeholder.add_theme_font_size_override("font_size", maxi(28, int(portrait_size.x * 0.30)))

		_layout_seat_status_icons(seat)

	var center_pool: TextureRect = seat_layer.get_meta("center_pool") as TextureRect
	if center_pool != null:
		center_pool.visible = false

	if reveal_card_panel != null:
		_align_reveal_card_panel_to_viewport_center()


func _layout_seat_status_icons(seat: Control) -> void:
	if seat == null:
		return
	var status_icon: Control = seat.get_meta("status_icon") as Control
	var avatar_container: Control = seat.get_meta("avatar_container") as Control
	if status_icon == null or avatar_container == null:
		return
	var avatar_rect := Rect2(avatar_container.position, avatar_container.size)
	var badge_size := maxf(12.0, avatar_rect.size.x * 0.22)
	for child_variant in status_icon.get_children():
		var child: Control = child_variant as Control
		if child == null:
			continue
		var role := str(child.get_meta("badge_role", ""))
		match role:
			"lock":
				child.size = Vector2.ONE * badge_size * 0.70
				child.position = avatar_rect.position + Vector2(avatar_rect.size.x - child.size.x * 0.85, badge_size * 0.06)
			"spy":
				child.size = Vector2.ONE * badge_size * 0.74
				child.position = avatar_rect.position + Vector2(badge_size * 0.08, avatar_rect.size.y - child.size.y * 1.10)
			"block":
				child.size = Vector2.ONE * badge_size
				child.position = avatar_rect.position + avatar_rect.size - child.size - Vector2(badge_size * 0.06, badge_size * 0.06)
				var block_label: Label = child.get_meta("badge_label") as Label
				if block_label != null:
					block_label.add_theme_font_size_override("font_size", maxi(9, int(child.size.x * 0.42)))
			"sleep":
				child.size = Vector2.ONE * badge_size * 0.54
				child.position = avatar_rect.position + Vector2(avatar_rect.size.x * 0.5 - child.size.x * 0.5, avatar_rect.size.y - child.size.y * 0.85)
			_:
				child.size = Vector2.ONE * badge_size


func _build_seat_status_badge(role: String, color: Color, label_text: String = "") -> PanelContainer:
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_meta("badge_role", role)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 2
	match role:
		"spy":
			style.corner_radius_top_left = 3
			style.corner_radius_top_right = 0
			style.corner_radius_bottom_right = 3
			style.corner_radius_bottom_left = 0
		_:
			style.corner_radius_top_left = 999
			style.corner_radius_top_right = 999
			style.corner_radius_bottom_left = 999
			style.corner_radius_bottom_right = 999
	badge.add_theme_stylebox_override("panel", style)
	if not label_text.is_empty():
		var label := UIFactory.make_label(label_text, 9, Color.WHITE, true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.add_child(label)
		badge.set_meta("badge_label", label)
	return badge


func _sync_player_seat() -> void:
	var seat: Control = seat_nodes.get("player") as Control
	if seat == null:
		return
	seat.set_meta("uid", -1)
	seat.set_meta("ally_data", {})
	_sync_seat_avatar("player", state.player_character)
	_set_seat_placeholder(seat, _get_seat_placeholder_symbol("player"), state.player_character.is_empty())
	_sync_seat_status_icons("player")
	_configure_seat_interaction("player")
	_set_seat_border_tone(seat, _get_seat_tone("player"), 0.52)


func _sync_ally_seats() -> void:
	var visible_seat_ids := _get_visible_ally_seat_ids()
	var all_ally_seat_ids := _get_all_ally_seat_ids()
	var seat_assignments := _get_visible_ally_seat_assignments()

	for seat_id in all_ally_seat_ids:
		var seat: Control = seat_nodes.get(seat_id) as Control
		if seat == null:
			continue
		var seat_index := visible_seat_ids.find(seat_id)
		var seat_tone := _get_seat_tone(seat_id)
		if seat_index < 0:
			_sync_seat_avatar(seat_id, {})
			_sync_seat_status_icons(seat_id)
			_configure_seat_interaction(seat_id)
			_set_seat_border_tone(seat, seat_tone, 0.52)
			_set_seat_placeholder(seat, _get_seat_placeholder_symbol(seat_id), true)
			continue
		if seat_assignments.has(seat_id):
			var ally: Dictionary = seat_assignments[seat_id]
			seat_tone = BattleScreenText.get_ally_avatar_tone(ally)
			_sync_seat_avatar(seat_id, ally["character"])
			_sync_seat_status_icons(seat_id, ally)
			_configure_seat_interaction(seat_id, ally)
			_set_seat_placeholder(seat, _get_seat_placeholder_symbol(seat_id), false)
			var avatar_container: Control = seat.get_meta("avatar_container") as Control
			if avatar_container != null:
				avatar_container.modulate = Color(1, 1, 1, 0.68) if int(ally["sleeping"]) > 0 else Color.WHITE
		else:
			var placeholder_symbol := _get_seat_placeholder_symbol(seat_id)
			_sync_seat_avatar(seat_id, {})
			_sync_seat_status_icons(seat_id)
			_configure_seat_interaction(seat_id)
			_set_seat_placeholder(seat, placeholder_symbol, true)
		_set_seat_border_tone(seat, seat_tone, 0.52)


func _sync_enemy_seat() -> void:
	var seat: Control = seat_nodes.get("enemy") as Control
	if seat == null:
		return
	_sync_seat_avatar("enemy", {})
	_sync_seat_status_icons("enemy")
	_configure_seat_interaction("enemy")
	_set_seat_border_tone(seat, _get_seat_tone("enemy"), 0.52)
	_set_seat_placeholder(seat, _get_seat_placeholder_symbol("enemy"), true)


func _set_seat_placeholder(seat: Control, symbol: String, visible: bool) -> void:
	var placeholder: Label = seat.get_meta("placeholder") as Label
	if placeholder == null:
		return
	placeholder.visible = visible
	placeholder.text = symbol


func _configure_seat_interaction(seat_id: String, ally: Dictionary = {}) -> void:
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return
	var avatar_container: Control = seat.get_meta("avatar_container") as Control
	if avatar_container == null:
		return
	seat.set_meta("uid", int(ally.get("uid", -1)) if not ally.is_empty() else -1)
	seat.set_meta("ally_data", ally.duplicate(true) if not ally.is_empty() else {})
	var enable_hover := false
	if seat_id == "player":
		enable_hover = not state.player_character.is_empty()
	elif not ally.is_empty():
		enable_hover = true
	if enable_hover:
		avatar_container.mouse_filter = Control.MOUSE_FILTER_STOP
		avatar_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		avatar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_container.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _sync_seat_avatar(seat_id: String, character: Dictionary) -> void:
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return
	var avatar_container: Control = seat.get_meta("avatar_container") as Control
	var avatar: TextureRect = seat.get_meta("avatar") as TextureRect
	var seat_name_label: Label = seat.get_meta("seat_name_label") as Label
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	var hit_flash: ColorRect = seat.get_meta("hit_flash") as ColorRect
	var seat_use_small_card := _seat_uses_small_card_template(seat_id)
	if avatar_container != null:
		var target_pos: Vector2 = avatar_container.get_meta("target_pos", avatar_container.position)
		avatar_container.position = target_pos
		avatar_container.scale = Vector2.ONE
		avatar_container.modulate = Color.WHITE
		avatar_container.visible = not character.is_empty()
		avatar_container.rotation_degrees = 0.0
	if avatar != null:
		if not character.is_empty():
			avatar.texture = _get_small_hand_card_texture(character) if seat_use_small_card else _get_character_avatar_texture(character)
			if avatar.texture == null and seat_use_small_card:
				avatar.texture = _get_hand_card_art_texture(character)
			avatar.stretch_mode = TextureRect.STRETCH_SCALE if seat_use_small_card else TextureRect.STRETCH_KEEP_ASPECT_COVERED
			avatar.modulate = Color(1, 1, 1, 0.98)
		else:
			avatar.texture = null
		avatar.visible = not character.is_empty()
	if seat_name_label != null:
		seat_name_label.text = str(character.get("code", "")) if seat_use_small_card and not character.is_empty() else ""
		seat_name_label.visible = seat_use_small_card and not character.is_empty()
	if border_ring != null:
		border_ring.visible = not character.is_empty() and not seat_use_small_card
	seat.set_meta("has_character", not character.is_empty())
	if hit_flash != null:
		hit_flash.visible = false
		hit_flash.color.a = 0.0


func _sync_seat_status_icons(seat_id: String, ally: Dictionary = {}) -> void:
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return
	var status_icon: Control = seat.get_meta("status_icon") as Control
	if status_icon == null:
		return
	_clear_children(status_icon)
	if _seat_uses_small_card_template(seat_id):
		status_icon.visible = false
		return
	if ally.is_empty():
		status_icon.visible = false
		_layout_seat_status_icons(seat)
		return
	status_icon.visible = true
	if ally.get("locked", false):
		status_icon.add_child(_build_seat_status_badge("lock", Color("f0c977")))
	if ally.get("is_spy", false):
		status_icon.add_child(_build_seat_status_badge("spy", Color("ff5b5b")))
	if int(ally.get("blocks", 0)) > 0:
		status_icon.add_child(_build_seat_status_badge("block", Color("3a8ecc"), str(int(ally.get("blocks", 0)))))
	if int(ally.get("sleeping", 0)) > 0:
		status_icon.add_child(_build_seat_status_badge("sleep", Color("8d96a6")))
	_layout_seat_status_icons(seat)


func _get_seat_id_for_ally(ally: Dictionary) -> String:
	var ally_uid := int(ally.get("uid", -1))
	var seat_assignments := _get_visible_ally_seat_assignments()
	for seat_id in seat_assignments.keys():
		var current: Dictionary = seat_assignments[seat_id]
		if int(current.get("uid", -2)) == ally_uid:
			return str(seat_id)
	var visible_seat_ids := _get_visible_ally_seat_ids()
	return str(visible_seat_ids[0]) if not visible_seat_ids.is_empty() else "ally_1"


func _get_seat_actor_node(seat_id: String, ally_uid: int = -1) -> Control:
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return null
	if not bool(seat.get_meta("has_character", false)):
		return null
	if ally_uid >= 0 and int(seat.get_meta("uid", -999)) != ally_uid:
		return null
	return seat.get_meta("avatar_container") as Control


func _build_ally_mini_card(parent: VBoxContainer, ally: Dictionary) -> void:
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(72, 72)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	var hover_style := style.duplicate()
	card.add_theme_stylebox_override("normal", style)
	card.add_theme_stylebox_override("hover", hover_style)
	card.add_theme_stylebox_override("pressed", hover_style)
	parent.add_child(card)

	var avatar := stage_helper.build_avatar_node(50, false, avatar_glow_texture, avatar_ring_texture)
	avatar.position = Vector2(3, 2)
	card.add_child(avatar)
	stage_helper.set_avatar_node(
		avatar,
		ally["character"],
		BattleScreenText.get_ally_avatar_tone(ally),
		_get_character_avatar_texture(ally["character"])
	)

	if ally["locked"]:
		var lock_badge := UIFactory.make_label("🔒", 12, Color("f0c977"), true)
		lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_badge.position = Vector2(48, 2)
		card.add_child(lock_badge)

	if ally["is_spy"]:
		var spy_badge := UIFactory.make_label("⚠", 12, Color("ff6a6a"), true)
		spy_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spy_badge.position = Vector2(8, 50)
		card.add_child(spy_badge)

	if int(ally["blocks"]) > 0:
		var block_badge := UIFactory.make_label("🛡", 12, Color("86c5ff"), true)
		block_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block_badge.position = Vector2(48, 48)
		card.add_child(block_badge)

	if int(ally["sleeping"]) > 0:
		var sleep_badge := UIFactory.make_label("💤", 12, Color("b8c5d8"), true)
		sleep_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sleep_badge.position = Vector2(26, 50)
		card.add_child(sleep_badge)

	if int(ally["sleeping"]) > 0:
		card.modulate = Color(1, 1, 1, 0.6)

	card.mouse_entered.connect(_on_ally_mini_card_mouse_enter.bind(int(ally.get("uid", -1)), card.get_instance_id()))
	card.mouse_exited.connect(_hide_ally_tooltip)


func _build_ally_slot_placeholder(parent: VBoxContainer, type: String) -> void:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(72, 72)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(slot)

	var avatar := stage_helper.build_avatar_node(50, false, avatar_glow_texture, avatar_ring_texture)
	avatar.position = Vector2(3, 2)
	slot.add_child(avatar)
	if type == "sealed":
		stage_helper.set_avatar_node(avatar, {}, Color("c56b5d"), null, "", "⛓")
		slot.modulate = Color(1, 1, 1, 0.85)
	else:
		stage_helper.set_avatar_node(avatar, {}, Color("5b6a60"), null, "", "")
		slot.modulate = Color(1, 1, 1, 0.35)


func _update_deck_view() -> void:
	if deck_grid == null or deck_count_label == null or secondary_button == null:
		return
	visible_deck_indices.clear()
	_clear_children(deck_grid)
	deck_card_nodes.clear()
	var remaining_indices: Array = []
	for i in range(state.deck.size()):
		var card: Dictionary = state.deck[i]
		if card["revealed"]:
			continue
		remaining_indices.append(i)

	deck_count_label.text = "◈ %d/%d" % [remaining_indices.size(), state.deck.size()]
	if remaining_indices.is_empty():
		secondary_button.visible = false
		return

	if selected_deck_index == -1 or state.deck[selected_deck_index]["revealed"]:
		selected_deck_index = _get_default_deck_index_from_pool(remaining_indices)

	deck_card_size = _get_deck_card_size_for_count(remaining_indices.size())
	visible_deck_indices = remaining_indices.duplicate()
	for deck_index_variant in visible_deck_indices:
		var deck_index: int = int(deck_index_variant)
		var visible_card: Dictionary = state.deck[deck_index]
		var card_button := _build_deck_card(visible_card, deck_index)
		deck_card_nodes[deck_index] = card_button
		deck_grid.add_child(card_button)

	var card: Dictionary = state.deck[selected_deck_index]
	if not reveal_result_locked:
		_update_card_info(card["character"], selected_deck_index)
	_layout_deck_fan(false)
	call_deferred("_deferred_layout_deck_fan")
	_refresh_action_buttons()


func _get_default_selected_deck_index() -> int:
	return _get_default_deck_index_from_pool(visible_deck_indices)


func _get_default_deck_index_from_pool(pool: Array) -> int:
	if pool.is_empty():
		return -1
	if selected_deck_index >= 0:
		var nearest := int(pool[0])
		var nearest_distance := absi(nearest - selected_deck_index)
		for deck_index_variant in pool:
			var deck_index: int = int(deck_index_variant)
			var distance := absi(deck_index - selected_deck_index)
			if distance < nearest_distance:
				nearest = deck_index
				nearest_distance = distance
		return nearest
	return int(pool[pool.size() / 2])


func _get_displayed_deck_indices(pool: Array) -> Array:
	return pool.duplicate()


func _get_deck_card_size_for_count(card_count: int) -> Vector2:
	var width_basis := deck_grid.size.x
	if width_basis <= 0.0:
		width_basis = size.x - 160.0 if size.x > 0.0 else get_viewport_rect().size.x - 160.0
	var usable_width: float = minf(maxf(720.0, width_basis - 12.0), deck_fan_max_span)
	if card_count <= 0:
		return Vector2(104.0, 156.0)

	var stride_ratio: float = _get_deck_card_stride_ratio(card_count)
	var target_height: float = clampf(get_viewport_rect().size.y * 0.20, 148.0, 176.0)
	var target_width: float = roundf(target_height * 0.667)
	var span_units: float = 1.0 + stride_ratio * float(maxi(0, card_count - 1))
	var max_width_for_span: float = usable_width / maxf(span_units, 1.0)
	var card_width: float = minf(target_width, max_width_for_span)
	card_width = clampf(card_width, 84.0, 118.0)
	var card_height: float = roundf(card_width / 0.667)
	return Vector2(card_width, clampf(card_height, 130.0, 176.0))


func _get_deck_card_gap_for_count(card_count: int) -> float:
	if card_count >= 15:
		return 0.0
	if card_count >= 11:
		return 4.0
	if card_count >= 7:
		return 10.0
	return 16.0


func _get_deck_card_stride_ratio(card_count: int) -> float:
	if card_count >= 15:
		return 0.66
	if card_count >= 11:
		return 0.70
	if card_count >= 8:
		return 0.76
	return 0.84

func _update_card_info(character: Dictionary, deck_index: int = -1) -> void:
	# ── 更新右侧情报卡 ──
	if character.is_empty():
		if info_avatar != null:
			stage_helper.set_avatar_node(info_avatar, {}, Color("b8d4ff"), null, "", "")
		if info_title_label != null:
			info_title_label.text = ""
		if info_quote_label != null:
			info_quote_label.text = ""
		if info_hint_label != null:
			info_hint_label.text = ""
			info_hint_label.visible = false
		if info_ally_name_label != null:
			info_ally_name_label.text = ""
		if info_ally_desc_label != null:
			info_ally_desc_label.text = ""
		if info_enemy_name_label != null:
			info_enemy_name_label.text = ""
		if info_enemy_desc_label != null:
			info_enemy_desc_label.text = ""
		if info_box != null:
			info_box.text = ""
	else:
		var skills: Dictionary = character["skills"]
		if info_avatar != null:
			stage_helper.set_avatar_node(info_avatar, character, _get_rarity_border_color(character), _get_character_avatar_texture(character))
		if info_title_label != null:
			info_title_label.text = "%s - %s" % [character["code"], character["name"]]
		if info_quote_label != null:
			info_quote_label.text = str(character["quote"])
		var hint_text := ""
		var peek_data: Dictionary = _get_peek_data(deck_index)
		if not peek_data.is_empty():
			var peek_text := "伙伴" if peek_data.get("fate", "") == "ally" else "敌人"
			var peek_label := "窥视结果" if peek_data.get("mode", "") == "peek" else "三思结果"
			hint_text = "%s · %s" % [peek_label, peek_text]
		if info_hint_label != null:
			info_hint_label.text = hint_text
			info_hint_label.visible = not hint_text.is_empty()
		if info_ally_name_label != null:
			info_ally_name_label.text = "队友技能：%s" % skills["ally"]["name"]
		if info_ally_desc_label != null:
			info_ally_desc_label.text = str(skills["ally"]["description"])
		if info_enemy_name_label != null:
			info_enemy_name_label.text = "敌人技能：%s" % skills["enemy"]["name"]
		if info_enemy_desc_label != null:
			info_enemy_desc_label.text = str(skills["enemy"]["description"])
		if info_box != null:
			info_box.text = ""
			info_box.append_text("[center][font_size=20][color=#2f3744]%s · %s[/color][/font_size]\n" % [character["code"], character["name"]])
			info_box.append_text("[color=#6b7487]%s[/color][/center]\n\n" % character["quote"])
			if not hint_text.is_empty():
				var peek_color := "#4a9eff" if hint_text.contains("伙伴") else "#ff6a6a"
				info_box.append_text("[center][color=%s]%s[/color][/center]\n\n" % [peek_color, hint_text])
			info_box.append_text("[color=#5f8dbb]队友技能：%s[/color]\n[color=#3e485a]%s[/color]\n\n" % [skills["ally"]["name"], skills["ally"]["description"]])
			info_box.append_text("[color=#c37f6d]敌人技能：%s[/color]\n[color=#3e485a]%s[/color]" % [skills["enemy"]["name"], skills["enemy"]["description"]])
			info_box.scroll_to_line(0)
	call_deferred("_refresh_info_drawer_bounds")

	# ── 更新浮动详情面板 ──
	var detail_panel: PanelContainer = _get_valid_meta_value("card_detail_panel") as PanelContainer
	var detail_vbox: VBoxContainer = _get_valid_meta_value("detail_vbox") as VBoxContainer
	var detail_avatar: Control = _get_valid_meta_value("detail_avatar") as Control
	var detail_code: Label = _get_valid_meta_value("detail_code") as Label
	var detail_name: Label = _get_valid_meta_value("detail_name") as Label
	var detail_fate: Label = _get_valid_meta_value("detail_fate") as Label
	var detail_quote: Label = _get_valid_meta_value("detail_quote") as Label
	var detail_ally_label: Label = _get_valid_meta_value("detail_ally_label") as Label
	var detail_ally_desc: Label = _get_valid_meta_value("detail_ally_desc") as Label
	var detail_enemy_label: Label = _get_valid_meta_value("detail_enemy_label") as Label
	var detail_enemy_desc: Label = _get_valid_meta_value("detail_enemy_desc") as Label
	var detail_style: StyleBoxFlat = _get_valid_meta_value("card_detail_style") as StyleBoxFlat

	if character.is_empty() or detail_panel == null:
		if detail_panel != null:
			detail_panel.visible = false
		return

	detail_panel.visible = false
	return

	# 填充信息
	if detail_avatar != null:
		stage_helper.set_avatar_node(detail_avatar, character, Color("cfab69"), _get_character_avatar_texture(character))
	if detail_code != null:
		detail_code.text = str(character.get("code", ""))
	if detail_name != null:
		detail_name.text = str(character.get("name", ""))
	if detail_quote != null:
		detail_quote.text = str(character.get("quote", ""))
	var skills2: Dictionary = character.get("skills", {})
	if detail_ally_label != null:
		var ally_name := str(skills2.get("ally", {}).get("name", ""))
		detail_ally_label.text = "队友技能：%s" % ally_name if not ally_name.is_empty() else ""
	if detail_ally_desc != null:
		detail_ally_desc.text = str(skills2.get("ally", {}).get("description", ""))
	if detail_enemy_label != null:
		var enemy_name := str(skills2.get("enemy", {}).get("name", ""))
		detail_enemy_label.text = "敌人技能：%s" % enemy_name if not enemy_name.is_empty() else ""
	if detail_enemy_desc != null:
		detail_enemy_desc.text = str(skills2.get("enemy", {}).get("description", ""))

	# 命运状态
	if detail_fate != null:
		if reveal_result_locked:
			detail_fate.text = "✦ 伙伴" if reveal_locked_fate == "ally" else "✦ 敌人"
			detail_fate.add_theme_color_override("font_color", Color("4a9eff") if reveal_locked_fate == "ally" else Color("ff6458"))
		else:
			var peek_data: Dictionary = _get_peek_data(deck_index)
			if not peek_data.is_empty():
				var fate_text := "伙伴" if peek_data.get("fate", "") == "ally" else "敌人"
				var mode_text := "窥视" if peek_data.get("mode", "") == "peek" else "三思"
				detail_fate.text = "%s · %s" % [mode_text, fate_text]
				detail_fate.add_theme_color_override("font_color", Color("4a9eff") if peek_data.get("fate", "") == "ally" else Color("ff6a6a"))
			else:
				detail_fate.text = ""
				detail_fate.add_theme_color_override("font_color", Color("d7b56d"))

	# 面板边框颜色
	if detail_style != null:
		if reveal_result_locked:
			detail_style.border_color = Color("4a9eff") if reveal_locked_fate == "ally" else Color("ff6458")
		else:
			detail_style.border_color = Color("cfab69")

	# ── 定位面板 ── 贴近中央翻牌位，保持和交互焦点一致
	if not character.is_empty() and detail_panel != null:
		var was_visible := detail_panel.visible
		var panel_width := clampf(size.x * 0.18, 286.0, 330.0)
		var content_height := 0.0
		if detail_vbox != null:
			detail_vbox.update_minimum_size()
			content_height = detail_vbox.get_combined_minimum_size().y
		var panel_height := clampf(
			content_height + detail_style.content_margin_top + detail_style.content_margin_bottom,
			244.0,
			320.0
		)
		detail_panel.custom_minimum_size = Vector2(panel_width, panel_height)
		detail_panel.size = Vector2(panel_width, panel_height)
		detail_panel.visible = true
		_refresh_card_detail_panel_position(not was_visible)
	else:
		if detail_panel != null:
			detail_panel.visible = false


func _refresh_card_detail_panel_position(animate: bool = false) -> void:
	var detail_panel: PanelContainer = _get_valid_meta_value("card_detail_panel") as PanelContainer
	if detail_panel == null or not detail_panel.visible:
		return

	var panel_size := detail_panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		detail_panel.reset_size()
		panel_size = detail_panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = detail_panel.custom_minimum_size

	var anchor_rect: Rect2 = Rect2()
	if reveal_card_panel != null:
		anchor_rect = reveal_card_panel.get_global_rect()
	if anchor_rect.size.x <= 0.0 or anchor_rect.size.y <= 0.0:
		var fallback_size := Vector2(228.0, 306.0)
		anchor_rect = Rect2((size - fallback_size) * 0.5, fallback_size)

	var viewport_size := get_viewport_rect().size
	var side_gap := clampf(size.x * 0.015, 22.0, 30.0)
	var edge_margin := clampf(size.x * 0.012, 16.0, 24.0)
	var right_aligned_x: float = viewport_size.x - panel_size.x - edge_margin
	var min_safe_x: float = anchor_rect.position.x + anchor_rect.size.x + side_gap
	var target_x: float = right_aligned_x
	if target_x < min_safe_x:
		target_x = anchor_rect.position.x - panel_size.x - side_gap
	var target_y: float = anchor_rect.position.y + (anchor_rect.size.y - panel_size.y) * 0.5
	target_x = clampf(target_x, edge_margin, viewport_size.x - panel_size.x - edge_margin)
	target_y = clampf(target_y, 88.0, viewport_size.y - panel_size.y - 20.0)
	var target_pos := Vector2(target_x, target_y)
	detail_layout_serial += 1
	var layout_serial := detail_layout_serial

	if animate:
		var start_offset := 20.0 if target_pos.x >= anchor_rect.position.x else -20.0
		detail_panel.global_position = target_pos + Vector2(start_offset, 0.0)
		detail_panel.modulate = Color(1, 1, 1, 0.0)
		var show_tween := create_tween()
		show_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		show_tween.tween_property(detail_panel, "global_position", target_pos, 0.22)
		show_tween.parallel().tween_property(detail_panel, "modulate", Color.WHITE, 0.18)
		_stabilize_card_detail_panel_rect(layout_serial, target_pos, panel_size)
		return

	detail_panel.size = panel_size
	detail_panel.global_position = target_pos
	_stabilize_card_detail_panel_rect(layout_serial, target_pos, panel_size)


func _stabilize_card_detail_panel_rect(layout_serial: int, target_pos: Vector2, panel_size: Vector2) -> void:
	await get_tree().process_frame
	if layout_serial != detail_layout_serial:
		return
	var detail_panel: PanelContainer = _get_valid_meta_value("card_detail_panel") as PanelContainer
	if detail_panel == null or not detail_panel.visible:
		return
	detail_panel.size = panel_size
	detail_panel.global_position = target_pos
	await get_tree().process_frame
	if layout_serial != detail_layout_serial:
		return
	detail_panel = _get_valid_meta_value("card_detail_panel") as PanelContainer
	if detail_panel == null or not detail_panel.visible:
		return
	detail_panel.size = panel_size
	detail_panel.global_position = target_pos


func _enforce_card_detail_panel_layout() -> void:
	var detail_panel: PanelContainer = _get_valid_meta_value("card_detail_panel") as PanelContainer
	if detail_panel == null or not detail_panel.visible:
		return
	var target_size := detail_panel.custom_minimum_size
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return
	if absf(detail_panel.size.x - target_size.x) <= 1.0 and absf(detail_panel.size.y - target_size.y) <= 1.0:
		return
	detail_panel.size = target_size
	_refresh_card_detail_panel_position(false)


func _show_profile_tooltip(text: String, source_card: Control) -> void:
	if ally_tooltip_panel == null or ally_tooltip_text == null:
		return
	if text.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	var bounds_left := 18.0
	var bounds_top := 18.0
	var bounds_right := viewport_size.x - 18.0
	var bounds_bottom := viewport_size.y - 18.0
	if info_drawer_host != null and info_drawer_host.visible:
		var drawer_rect := info_drawer_host.get_global_rect()
		if drawer_rect.size.x > 0.0:
			bounds_right = minf(bounds_right, drawer_rect.position.x - 14.0)
	var max_bounds := Rect2(
		Vector2(bounds_left, bounds_top),
		Vector2(maxf(220.0, bounds_right - bounds_left), maxf(180.0, bounds_bottom - bounds_top))
	)
	var tooltip_width := clampf(max_bounds.size.x * 0.30, 304.0, 368.0)
	tooltip_width = minf(tooltip_width, max_bounds.size.x)
	ally_tooltip_panel.custom_minimum_size = Vector2(tooltip_width, 196.0)
	ally_tooltip_text.custom_minimum_size = Vector2(maxf(168.0, tooltip_width - 44.0), 0.0)
	ally_tooltip_text.text = ""
	ally_tooltip_text.append_text(text)
	ally_tooltip_text.scroll_to_line(0)
	ally_tooltip_text.reset_size()
	ally_tooltip_panel.reset_size()
	var tooltip_size := ally_tooltip_panel.get_combined_minimum_size()
	tooltip_size.x = minf(max_bounds.size.x, maxf(tooltip_size.x, tooltip_width))
	tooltip_size.y = minf(max_bounds.size.y, maxf(tooltip_size.y, 196.0))
	ally_tooltip_panel.size = tooltip_size

	var source_rect := source_card.get_global_rect()
	var source_center := source_rect.get_center()
	var gap := 18.0
	var target_x := source_center.x - tooltip_size.x * 0.5
	var target_y := source_rect.position.y + source_rect.size.y + gap
	var prefer_vertical := source_center.y <= max_bounds.position.y + max_bounds.size.y * 0.38
	if prefer_vertical:
		if target_y + tooltip_size.y > max_bounds.position.y + max_bounds.size.y:
			target_y = source_rect.position.y - tooltip_size.y - gap
	else:
		target_x = source_rect.position.x + source_rect.size.x + gap
		target_y = source_rect.position.y + (source_rect.size.y - tooltip_size.y) * 0.5
		if target_x + tooltip_size.x > max_bounds.position.x + max_bounds.size.x or source_center.x > max_bounds.position.x + max_bounds.size.x * 0.58:
			target_x = source_rect.position.x - tooltip_size.x - gap
	target_x = clampf(target_x, max_bounds.position.x, max_bounds.position.x + max_bounds.size.x - tooltip_size.x)
	target_y = clampf(target_y, max_bounds.position.y, max_bounds.position.y + max_bounds.size.y - tooltip_size.y)

	ally_tooltip_panel.position = Vector2(target_x, target_y)
	ally_tooltip_panel.visible = true


func _show_ally_tooltip(ally: Dictionary, source_card: Control) -> void:
	_show_profile_tooltip(BattleScreenText.build_ally_tooltip_text(ally), source_card)


func _show_hero_tooltip(source_card: Control) -> void:
	_show_profile_tooltip(BattleScreenText.build_hero_tooltip_text(state.player_character, _get_hero_charges_text()), source_card)


func _hide_ally_tooltip() -> void:
	if ally_tooltip_panel != null:
		ally_tooltip_panel.visible = false


func _toggle_info_drawer() -> void:
	info_drawer_open = not info_drawer_open
	_refresh_info_drawer(true)


func _refresh_info_drawer_bounds() -> void:
	if info_drawer_host == null:
		return
	var parent_ctrl := info_drawer_host.get_parent() as Control
	if parent_ctrl == null:
		return
	var viewport_h := get_viewport_rect().size.y
	if viewport_h <= 0.0:
		return
	const TOP_MARGIN := 60.0
	const VIEWPORT_BOTTOM_SAFE := 56.0
	const MAX_HEIGHT := 720.0
	const MIN_HEIGHT := 360.0
	const HAND_SAFE_GAP := 18.0
	const CONTENT_MARGIN_TOP := 88.0
	const CONTENT_MARGIN_BOTTOM := 88.0
	const CHROME_SLACK := 12.0
	var parent_top := parent_ctrl.get_global_rect().position.y
	var bottom_limit := viewport_h - VIEWPORT_BOTTOM_SAFE
	var cards_top := _get_deck_cards_top_global_y()
	if cards_top != INF:
		bottom_limit = minf(bottom_limit, cards_top - HAND_SAFE_GAP)
	var avail := maxf(bottom_limit - parent_top - TOP_MARGIN, 0.0)
	var max_limit := minf(MAX_HEIGHT, avail)
	if max_limit <= 0.0:
		return
	var target_h := max_limit
	if info_content_root != null:
		info_content_root.reset_size()
		info_content_root.update_minimum_size()
		var content_h := info_content_root.get_combined_minimum_size().y
		target_h = content_h + CONTENT_MARGIN_TOP + CONTENT_MARGIN_BOTTOM + CHROME_SLACK
	var min_limit := minf(MIN_HEIGHT, max_limit)
	target_h = clampf(target_h, min_limit, max_limit)
	info_drawer_host.offset_top = TOP_MARGIN
	info_drawer_host.offset_bottom = TOP_MARGIN + target_h


func _refresh_info_drawer(animate: bool = true) -> void:
	if info_drawer_panel == null:
		return
	var target_x := 18.0 if info_drawer_open else 336.0
	if info_drawer_tween != null:
		info_drawer_tween.kill()
	if animate:
		info_drawer_tween = create_tween()
		info_drawer_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		info_drawer_tween.tween_property(info_drawer_panel, "position:x", target_x, 0.24)
	else:
		info_drawer_panel.position.x = target_x
	if info_drawer_toggle != null:
		info_drawer_toggle.text = "✕" if info_drawer_open else "ℹ"
		info_drawer_toggle.tooltip_text = "收起" if info_drawer_open else "情报"


func _get_hero_spotlight_center() -> Vector2:
	if seat_layer == null:
		return Vector2.ZERO
	return _to_layer_local_point(seat_layer, _get_viewport_world_center())


func _refresh_hero_spotlight_layout() -> void:
	stage_helper.refresh_hero_spotlight_layout(
		hero_spotlight_root,
		seat_layer,
		hero_spotlight_shadow,
		hero_spotlight_halo,
		hero_spotlight_pose,
		hero_spotlight_quote_backdrop,
		hero_spotlight_quote_label,
		_get_hero_spotlight_center()
	)


func _apply_hero_spotlight_character(character: Dictionary) -> Dictionary:
	return stage_helper.apply_hero_spotlight_character(
		character,
		ENTRANCE_RITUALS_PATH,
		hero_spotlight_pose,
		hero_spotlight_halo,
		hero_spotlight_shadow,
		hero_spotlight_quote_backdrop,
		hero_spotlight_quote_label,
		soft_glow_texture,
		hero_spotlight_target_body_alpha,
		hero_spotlight_target_halo_alpha
	)


func _set_hero_spotlight_presence(body_alpha: float, halo_alpha: float, duration: float = 0.24, immediate: bool = false) -> void:
	hero_spotlight_target_body_alpha = body_alpha
	hero_spotlight_target_halo_alpha = halo_alpha
	if hero_spotlight_root == null:
		return
	if hero_spotlight_tween != null and hero_spotlight_tween.is_valid():
		hero_spotlight_tween.kill()

	if immediate:
		hero_spotlight_root.modulate.a = body_alpha
		if hero_spotlight_pose != null:
			hero_spotlight_pose.modulate.a = body_alpha
		if hero_spotlight_halo != null:
			hero_spotlight_halo.modulate.a = halo_alpha
		if hero_spotlight_shadow != null:
			hero_spotlight_shadow.modulate.a = body_alpha * 0.46
		return

	hero_spotlight_tween = create_tween()
	hero_spotlight_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hero_spotlight_tween.set_parallel(true)
	hero_spotlight_tween.tween_property(hero_spotlight_root, "modulate:a", body_alpha, duration)
	if hero_spotlight_pose != null:
		hero_spotlight_tween.tween_property(hero_spotlight_pose, "modulate:a", body_alpha, duration)
	if hero_spotlight_halo != null:
		hero_spotlight_tween.tween_property(hero_spotlight_halo, "modulate:a", halo_alpha, duration)
	if hero_spotlight_shadow != null:
		hero_spotlight_tween.tween_property(hero_spotlight_shadow, "modulate:a", body_alpha * 0.46, duration)


func _show_hero_spotlight_quote(visible: bool, duration: float = 0.22) -> void:
	if hero_spotlight_quote_backdrop == null or hero_spotlight_quote_label == null:
		return
	if hero_spotlight_quote_tween != null and hero_spotlight_quote_tween.is_valid():
		hero_spotlight_quote_tween.kill()

	hero_spotlight_quote_backdrop.visible = true
	hero_spotlight_quote_tween = create_tween()
	hero_spotlight_quote_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hero_spotlight_quote_tween.set_parallel(true)
	if visible:
		hero_spotlight_quote_label.visible_ratio = 1.0
		hero_spotlight_quote_label.modulate.a = 0.0
		hero_spotlight_quote_backdrop.modulate.a = 0.0
		hero_spotlight_quote_tween.tween_property(hero_spotlight_quote_backdrop, "modulate:a", 1.0, duration)
		hero_spotlight_quote_tween.tween_property(hero_spotlight_quote_label, "modulate:a", 1.0, duration)
	else:
		hero_spotlight_quote_tween.tween_property(hero_spotlight_quote_backdrop, "modulate:a", 0.0, duration)
		hero_spotlight_quote_tween.tween_property(hero_spotlight_quote_label, "modulate:a", 0.0, duration * 0.92)
		hero_spotlight_quote_tween.tween_callback(_hide_hero_spotlight_quote_backdrop)


func _play_hero_spotlight_opening() -> void:
	if hero_spotlight_entry_played:
		busy = false
		return
	hero_spotlight_entry_played = true
	if state.player_character.is_empty() or hero_spotlight_root == null:
		busy = false
		return

	await get_tree().process_frame
	await get_tree().process_frame
	_refresh_hero_spotlight_layout()

	var entry := _apply_hero_spotlight_character(state.player_character)
	if hero_spotlight_pose == null or hero_spotlight_pose.texture == null:
		busy = false
		return

	hero_spotlight_root.visible = true
	hero_spotlight_root.scale = Vector2(0.72, 0.78)
	hero_spotlight_root.position += Vector2(0.0, 72.0)
	hero_spotlight_root.modulate = Color(1.0, 0.98, 0.95, 0.0)
	hero_spotlight_pose.modulate = Color(1.0, 0.98, 0.95, 0.0)
	if hero_spotlight_halo != null:
		hero_spotlight_halo.scale = Vector2.ONE * 0.82
		hero_spotlight_halo.modulate.a = 0.0
	if hero_spotlight_shadow != null:
		hero_spotlight_shadow.modulate.a = 0.0

	var halo_color := stage_helper.color_from_manifest(entry.get("halo_color", ""), Color("f0c977"))
	var intro_start := hero_spotlight_root.position
	_play_spotlight_focus(halo_color, 0.68, 0.22, 0.42, 0.0)

	var intro := create_tween()
	intro.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.set_parallel(true)
	intro.tween_property(hero_spotlight_root, "position", intro_start - Vector2(0.0, 72.0), 0.56)
	intro.tween_property(hero_spotlight_root, "scale", Vector2.ONE, 0.56)
	intro.tween_property(hero_spotlight_root, "modulate:a", 1.0, 0.30)
	intro.tween_property(hero_spotlight_pose, "modulate:a", 1.0, 0.30)
	if hero_spotlight_halo != null:
		intro.tween_property(hero_spotlight_halo, "scale", Vector2.ONE, 0.60)
		intro.tween_property(hero_spotlight_halo, "modulate:a", 0.94, 0.28)
	if hero_spotlight_shadow != null:
		intro.tween_property(hero_spotlight_shadow, "modulate:a", 0.42, 0.34)
	await intro.finished

	_show_hero_spotlight_quote(true, 0.24)
	var pulse := create_tween()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.set_parallel(true)
	pulse.tween_property(hero_spotlight_root, "scale", Vector2(1.04, 1.02), 0.18)
	if hero_spotlight_halo != null:
		pulse.tween_property(hero_spotlight_halo, "modulate:a", 1.0, 0.18)
	await pulse.finished

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.set_parallel(true)
	settle.tween_property(hero_spotlight_root, "scale", Vector2.ONE, 0.18)
	await settle.finished

	await get_tree().create_timer(1.05).timeout
	_show_hero_spotlight_quote(false, 0.24)
	_set_hero_spotlight_presence(0.92, 0.72, 0.28)
	_append_log("主角 %s 在聚光灯下登场。" % str(state.player_character.get("code", "")))
	busy = false


func _make_replace_candidate_button(ally: Dictionary) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 82)
	button.clip_contents = true

	var title := UIFactory.make_label("%s · %s" % [ally["character"].get("code", ""), ally["character"].get("name", "")], 18, Color("f9ecd2"), true)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	var subtitle := UIFactory.make_label(BattleScreenText.build_replace_candidate_brief_text(ally), 13, Color("d7c1a1"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 16)
	content.add_theme_constant_override("margin_top", 12)
	content.add_theme_constant_override("margin_right", 16)
	content.add_theme_constant_override("margin_bottom", 12)
	button.add_child(content)

	var content_box := VBoxContainer.new()
	content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_theme_constant_override("separation", 4)
	content.add_child(content_box)
	content_box.add_child(title)
	content_box.add_child(subtitle)

	button.set_meta("ally_uid", int(ally.get("uid", -1)))
	button.set_meta("title_label", title)
	button.set_meta("subtitle_label", subtitle)
	button.set_meta("hovered", false)
	button.set_meta("selected", false)
	var button_id := button.get_instance_id()
	button.mouse_entered.connect(_on_replace_candidate_hover_changed.bind(button_id, true))
	button.mouse_exited.connect(_on_replace_candidate_hover_changed.bind(button_id, false))
	button.pressed.connect(_on_replace_candidate_pressed.bind(int(ally.get("uid", -1))))
	_refresh_replace_candidate_button_visual(button)
	return button


func _refresh_replace_candidate_button_visual(button: Button) -> void:
	if button == null:
		return
	var selected := bool(button.get_meta("selected", false))
	var hovered := bool(button.get_meta("hovered", false))
	var bg_color := Color(0.24, 0.08, 0.06, 0.94)
	var border_color := Color("9d7444")
	if hovered:
		bg_color = Color(0.29, 0.11, 0.08, 0.96)
		border_color = Color("bf9455")
	if selected:
		bg_color = Color(0.38, 0.14, 0.10, 0.98)
		border_color = Color("f0c977")

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_color = border_color
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.shadow_color = Color(0, 0, 0, 0.18)
	normal.shadow_size = 12
	normal.shadow_offset = Vector2(0, 5)
	var hover := normal.duplicate()
	hover.bg_color = bg_color.lightened(0.06)
	var pressed := normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.06)
	pressed.shadow_size = 6
	pressed.shadow_offset = Vector2(0, 2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)

	var title := button.get_meta("title_label", null) as Label
	if title != null:
		title.add_theme_color_override("font_color", Color("fff6e3") if selected else Color("f8ebd1") if hovered else Color("f2dfc4"))
	var subtitle := button.get_meta("subtitle_label", null) as Label
	if subtitle != null:
		subtitle.add_theme_color_override("font_color", Color("f3e1bd") if selected else Color("dcc5a3") if hovered else Color("cdb392"))


func _on_replace_candidate_hover_changed(button_id: int, hovered: bool) -> void:
	var button := instance_from_id(button_id) as Button
	if button == null or not is_instance_valid(button):
		return
	button.set_meta("hovered", hovered)
	_refresh_replace_candidate_button_visual(button)


func _on_replace_candidate_pressed(ally_uid: int) -> void:
	var ally := _get_ally_by_uid(ally_uid)
	if ally.is_empty():
		return
	_play_sfx("card_select")
	_set_replace_modal_selected_ally(ally)


func _on_hitstop_tween_finished(tween_id: int, restore_scale: float) -> void:
	if _impact_hitstop_tween == null or not _impact_hitstop_tween.is_valid():
		return
	if _impact_hitstop_tween.get_instance_id() != tween_id:
		return
	_impact_hitstop_tween = null
	Engine.time_scale = restore_scale


func _on_screen_shake_tween_finished(tween_id: int) -> void:
	if _screen_shake_tween == null or not _screen_shake_tween.is_valid():
		return
	if _screen_shake_tween.get_instance_id() != tween_id:
		return
	_screen_shake_tween = null
	position = Vector2.ZERO


func _on_log_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_log_modal()


func _on_modal_replace_confirm_pressed() -> void:
	if modal_replace_selected_ally.is_empty():
		return
	_hide_modal_option_tooltip()
	modal_backdrop.visible = false
	modal_choice_resolved.emit(modal_replace_selected_ally)


func _on_modal_replace_cancel_pressed() -> void:
	_hide_modal_option_tooltip()
	modal_backdrop.visible = false
	modal_choice_resolved.emit(null)


func _on_modal_option_button_mouse_enter(button_id: int, hover_text: String) -> void:
	var button := instance_from_id(button_id) as Control
	if button == null or not is_instance_valid(button):
		return
	_show_modal_option_tooltip(hover_text, button)


func _on_modal_option_inline_hover(hover_text: String, option_count: int, detail_layout: String) -> void:
	_set_modal_detail_text_and_refresh(hover_text, option_count, detail_layout)


func _on_modal_option_pressed(value) -> void:
	_hide_modal_option_tooltip()
	_hide_modal_recruit_detail()
	_set_modal_detail_text("")
	modal_backdrop.visible = false
	modal_choice_resolved.emit(value)


func _on_deck_card_hover_changed(button_id: int, deck_index: int, hovering: bool) -> void:
	var button := instance_from_id(button_id) as Button
	if button == null or not is_instance_valid(button):
		return
	if hovering:
		_play_sfx("card_hover")
	button.set_meta("hovering", hovering)
	_refresh_deck_card_state(button, deck_index, true)


func _on_deck_card_motion_finished(button_id: int, tween_id: int, deck_index: int) -> void:
	var button := instance_from_id(button_id) as Button
	if button == null or not is_instance_valid(button):
		return
	var current_tween: Variant = _get_object_meta_value(button, "motion_tween", null)
	if not (current_tween is Tween):
		return
	var tween := current_tween as Tween
	if tween == null or not tween.is_valid() or tween.get_instance_id() != tween_id:
		return
	button.remove_meta("motion_tween")
	var settled_target := _build_deck_card_motion_target(button, deck_index)
	button.z_index = _get_deck_card_target_z_index(button, deck_index)
	button.position = settled_target["position"]
	button.scale = settled_target["scale"]
	button.rotation_degrees = settled_target["rotation"]
	button.modulate = settled_target["modulate"]


func _on_seat_avatar_mouse_enter(seat_id: String, avatar_container_id: int) -> void:
	var avatar_container := instance_from_id(avatar_container_id) as Control
	if avatar_container == null or not is_instance_valid(avatar_container):
		return
	if seat_id == "player":
		if not state.player_character.is_empty():
			_show_hero_tooltip(avatar_container)
		return
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return
	var ally: Dictionary = seat.get_meta("ally_data", {})
	if not ally.is_empty():
		_show_ally_tooltip(ally, avatar_container)


func _on_ally_mini_card_mouse_enter(ally_uid: int, card_id: int) -> void:
	var card := instance_from_id(card_id) as Control
	if card == null or not is_instance_valid(card):
		return
	var ally := _get_ally_by_uid(ally_uid)
	if ally.is_empty():
		return
	_show_ally_tooltip(ally, card)


func _on_reveal_card_panel_resized() -> void:
	if reveal_card_panel == null:
		return
	reveal_card_panel.pivot_offset = reveal_card_panel.size / 2.0
	_refresh_reveal_texture_layout()


func _on_reveal_texture_resized() -> void:
	if reveal_texture == null:
		return
	reveal_texture.pivot_offset = reveal_texture.size / 2.0


func _hide_hero_spotlight_quote_backdrop() -> void:
	if hero_spotlight_quote_backdrop != null:
		hero_spotlight_quote_backdrop.visible = false


func _set_stage_light_pulse_boost(val: float) -> void:
	if stage_light_material != null:
		stage_light_material.set_shader_parameter("pulse_boost", val)


func _set_spotlight_focus_progress(progress: float, start_color: Color, target_color: Color, target_alpha: float) -> void:
	if spotlight_burst == null:
		return
	spotlight_burst.modulate = start_color.lerp(Color(target_color.r, target_color.g, target_color.b, target_alpha), progress)


func _queue_free_instance(instance_id: int) -> void:
	fx_helper._queue_free_instance(instance_id)


func _get_floating_banner_layer_size() -> Vector2:
	if floating_effect_layer != null and floating_effect_layer.size.x > 0.0 and floating_effect_layer.size.y > 0.0:
		return floating_effect_layer.size
	return get_viewport_rect().size


func _get_floating_banner_size(banner: Control) -> Vector2:
	if banner == null or not is_instance_valid(banner):
		return Vector2.ZERO
	var banner_size := banner.size
	if banner_size.x <= 0.0 or banner_size.y <= 0.0:
		banner.reset_size()
		banner_size = banner.size
	if banner_size.x <= 0.0 or banner_size.y <= 0.0:
		banner_size = banner.custom_minimum_size
	return banner_size


func _resolve_floating_banner_group_key(anchor: Vector2) -> String:
	var best_group_key := ""
	var best_score := INF
	for raw_group_key in floating_banner_groups.keys():
		var group_key := str(raw_group_key)
		var group_ids := _cleanup_floating_banner_group(group_key)
		if group_ids.is_empty():
			continue
		var reference_entry: Dictionary = floating_banner_entries.get(group_ids[0], {})
		if reference_entry.is_empty():
			continue
		var group_anchor: Vector2 = reference_entry.get("anchor", anchor)
		var dx := absf(group_anchor.x - anchor.x)
		var dy := absf(group_anchor.y - anchor.y)
		if dx > FLOATING_BANNER_GROUP_DISTANCE_X or dy > FLOATING_BANNER_GROUP_DISTANCE_Y:
			continue
		var score := dx + dy * 0.75
		if score < best_score:
			best_score = score
			best_group_key = group_key
	if best_group_key.is_empty():
		floating_banner_group_serial += 1
		best_group_key = "floating_banner_group_%d" % floating_banner_group_serial
	return best_group_key


func _cleanup_floating_banner_group(group_key: String) -> Array[int]:
	var valid_ids: Array[int] = []
	var group_ids: Array = floating_banner_groups.get(group_key, [])
	for raw_id in group_ids:
		var banner_id := int(raw_id)
		var entry: Dictionary = floating_banner_entries.get(banner_id, {})
		if entry.is_empty() or bool(entry.get("exiting", false)):
			continue
		var banner := instance_from_id(banner_id) as Control
		if banner == null or not is_instance_valid(banner):
			continue
		valid_ids.append(banner_id)
	if valid_ids.is_empty():
		floating_banner_groups.erase(group_key)
	else:
		floating_banner_groups[group_key] = valid_ids
	return valid_ids


func _kill_floating_banner_position_tween(banner: Control) -> void:
	if banner == null or not is_instance_valid(banner):
		return
	if not banner.has_meta("floating_banner_position_tween"):
		return
	var existing: Variant = banner.get_meta("floating_banner_position_tween")
	if existing is Tween:
		var tween := existing as Tween
		if tween.is_valid():
			tween.kill()
	banner.remove_meta("floating_banner_position_tween")


func _set_floating_banner_position_tween(banner: Control, tween: Tween) -> void:
	_kill_floating_banner_position_tween(banner)
	if banner == null or not is_instance_valid(banner) or tween == null:
		return
	banner.set_meta("floating_banner_position_tween", tween)


func _tween_floating_banner_to(banner: Control, target_position: Vector2, duration: float = 0.18) -> void:
	if banner == null or not is_instance_valid(banner):
		return
	if banner.position.distance_to(target_position) <= 0.5:
		banner.position = target_position
		return
	var motion := create_tween()
	motion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(banner, "position", target_position, duration)
	_set_floating_banner_position_tween(banner, motion)


func _reflow_floating_banner_group(group_key: String, skip_banner_id: int = -1, animate: bool = true) -> void:
	if floating_effect_layer == null:
		return
	var group_ids := _cleanup_floating_banner_group(group_key)
	if group_ids.is_empty():
		return
	var layer_size := _get_floating_banner_layer_size()
	var lead_entry: Dictionary = floating_banner_entries.get(group_ids[0], {})
	var group_anchor: Vector2 = lead_entry.get("anchor", layer_size * Vector2(0.5, 0.42))
	if group_anchor == Vector2.ZERO:
		group_anchor = layer_size * Vector2(0.5, 0.42)
	var base_offset_y := float(lead_entry.get("base_offset_y", 176.0))
	var side_margin := float(lead_entry.get("side_margin", 24.0))
	var top_margin := float(lead_entry.get("top_margin", 24.0))
	var bottom_margin := float(lead_entry.get("bottom_margin", 24.0))
	var raw_targets: Dictionary = {}
	var min_y := INF
	var max_bottom := -INF
	var stacked_offset := 0.0
	for raw_id in group_ids:
		var banner_id := int(raw_id)
		var banner := instance_from_id(banner_id) as PanelContainer
		if banner == null or not is_instance_valid(banner):
			continue
		var entry: Dictionary = floating_banner_entries.get(banner_id, {})
		var banner_size := _get_floating_banner_size(banner)
		var target_y := group_anchor.y - base_offset_y - stacked_offset
		var target_x := group_anchor.x - banner_size.x * 0.5
		raw_targets[banner_id] = Vector2(target_x, target_y)
		min_y = minf(min_y, target_y)
		max_bottom = maxf(max_bottom, target_y + banner_size.y)
		stacked_offset += banner_size.y + float(entry.get("stack_gap", 12.0))
	if raw_targets.is_empty():
		return
	var shift_y := 0.0
	var bottom_limit := layer_size.y - bottom_margin
	if min_y < top_margin:
		shift_y += top_margin - min_y
	if max_bottom + shift_y > bottom_limit:
		shift_y -= (max_bottom + shift_y - bottom_limit)
	for raw_id in group_ids:
		var banner_id := int(raw_id)
		var banner := instance_from_id(banner_id) as PanelContainer
		if banner == null or not is_instance_valid(banner):
			continue
		var entry: Dictionary = floating_banner_entries.get(banner_id, {})
		var banner_size := _get_floating_banner_size(banner)
		var raw_target: Vector2 = raw_targets.get(banner_id, banner.position)
		var max_x := maxf(side_margin, layer_size.x - banner_size.x - side_margin)
		var max_y := maxf(top_margin, layer_size.y - banner_size.y - bottom_margin)
		var target_position := Vector2(
			clampf(raw_target.x, side_margin, max_x),
			clampf(raw_target.y + shift_y, top_margin, max_y)
		)
		entry["target_position"] = target_position
		floating_banner_entries[banner_id] = entry
		if banner_id == skip_banner_id:
			continue
		if animate:
			_tween_floating_banner_to(banner, target_position, float(entry.get("layout_duration", 0.18)))
		else:
			_kill_floating_banner_position_tween(banner)
			banner.position = target_position


func _refresh_floating_banner_layouts() -> void:
	for raw_group_key in floating_banner_groups.keys():
		_reflow_floating_banner_group(str(raw_group_key))


func _remove_floating_banner_from_layout(banner_id: int) -> void:
	var entry: Dictionary = floating_banner_entries.get(banner_id, {})
	if entry.is_empty():
		return
	if bool(entry.get("exiting", false)):
		return
	entry["exiting"] = true
	floating_banner_entries[banner_id] = entry
	var group_key := str(entry.get("group_key", ""))
	if group_key.is_empty():
		return
	var kept_ids: Array[int] = []
	var group_ids: Array = floating_banner_groups.get(group_key, [])
	for raw_id in group_ids:
		var active_id := int(raw_id)
		if active_id != banner_id:
			kept_ids.append(active_id)
	if kept_ids.is_empty():
		floating_banner_groups.erase(group_key)
	else:
		floating_banner_groups[group_key] = kept_ids
	_reflow_floating_banner_group(group_key)


func _on_floating_banner_tree_exited(banner_id: int) -> void:
	var entry: Dictionary = floating_banner_entries.get(banner_id, {})
	if entry.is_empty():
		return
	var group_key := str(entry.get("group_key", ""))
	floating_banner_entries.erase(banner_id)
	if group_key.is_empty():
		return
	var group_ids: Array = floating_banner_groups.get(group_key, [])
	var kept_ids: Array[int] = []
	var removed := false
	for raw_id in group_ids:
		var active_id := int(raw_id)
		if active_id == banner_id:
			removed = true
			continue
		kept_ids.append(active_id)
	if kept_ids.is_empty():
		floating_banner_groups.erase(group_key)
	else:
		floating_banner_groups[group_key] = kept_ids
	if removed:
		_reflow_floating_banner_group(group_key)


func _register_floating_banner(banner: PanelContainer, anchor: Vector2, layout: Dictionary = {}) -> Dictionary:
	if banner == null or not is_instance_valid(banner):
		return {}
	var layer_size := _get_floating_banner_layer_size()
	var resolved_anchor := anchor
	if resolved_anchor == Vector2.ZERO:
		resolved_anchor = layer_size * Vector2(0.5, 0.42)
	var banner_id := banner.get_instance_id()
	var group_key := _resolve_floating_banner_group_key(resolved_anchor)
	var group_ids := _cleanup_floating_banner_group(group_key)
	var prior_count := group_ids.size()
	group_ids.insert(0, banner_id)
	floating_banner_groups[group_key] = group_ids
	floating_banner_entries[banner_id] = {
		"group_key": group_key,
		"anchor": resolved_anchor,
		"base_offset_y": float(layout.get("base_offset_y", 176.0)),
		"stack_gap": float(layout.get("stack_gap", 12.0)),
		"side_margin": float(layout.get("side_margin", 24.0)),
		"top_margin": float(layout.get("top_margin", 24.0)),
		"bottom_margin": float(layout.get("bottom_margin", 24.0)),
		"layout_duration": float(layout.get("layout_duration", 0.18)),
		"enter_offset_y": float(layout.get("enter_offset_y", 18.0)),
		"exiting": false,
	}
	banner.tree_exited.connect(_on_floating_banner_tree_exited.bind(banner_id), CONNECT_ONE_SHOT)
	_reflow_floating_banner_group(group_key, banner_id)
	var entry: Dictionary = floating_banner_entries.get(banner_id, {})
	return {
		"target_position": entry.get("target_position", resolved_anchor),
		"enter_delay": minf(float(prior_count) * 0.05, 0.12),
	}


func _play_floating_banner_enter(
	banner: PanelContainer,
	banner_style: StyleBoxFlat,
	target_position: Vector2,
	config: Dictionary = {},
	finished_callback: Callable = Callable()
) -> void:
	if banner == null or not is_instance_valid(banner):
		return
	var enter_delay := float(config.get("enter_delay", 0.0))
	var enter_offset_y := float(config.get("enter_offset_y", 18.0))
	var position_duration := float(config.get("position_duration", 0.22))
	var scale_duration := float(config.get("scale_duration", 0.20))
	var fade_duration := float(config.get("fade_duration", 0.16))
	var bg_alpha := float(config.get("bg_alpha", 0.94))
	var start_scale: Vector2 = config.get("start_scale", Vector2(0.84, 0.84))
	var end_scale: Vector2 = config.get("end_scale", Vector2.ONE)
	banner.position = target_position + Vector2(0.0, enter_offset_y)
	banner.scale = start_scale
	banner.modulate = Color(1, 1, 1, 0.0)
	if banner_style != null:
		banner_style.bg_color = Color(banner_style.bg_color.r, banner_style.bg_color.g, banner_style.bg_color.b, 0.0)
	var motion := create_tween()
	motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if enter_delay > 0.0:
		motion.tween_interval(enter_delay)
	motion.tween_property(banner, "position", target_position, position_duration)
	_set_floating_banner_position_tween(banner, motion)
	var appear := create_tween()
	appear.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if enter_delay > 0.0:
		appear.tween_interval(enter_delay)
	appear.set_parallel(true)
	appear.tween_property(banner, "scale", end_scale, scale_duration)
	appear.tween_property(banner, "modulate", Color(1, 1, 1, 1.0), fade_duration)
	if banner_style != null:
		appear.tween_property(banner_style, "bg_color:a", bg_alpha, fade_duration)
	if not finished_callback.is_null():
		appear.finished.connect(finished_callback)


func _start_floating_banner_exit(banner_id: int, lift_distance: float, position_duration: float, fade_duration: float) -> void:
	var banner := instance_from_id(banner_id) as PanelContainer
	if banner == null or not is_instance_valid(banner):
		return
	_remove_floating_banner_from_layout(banner_id)
	_kill_floating_banner_position_tween(banner)
	var banner_style := banner.get_theme_stylebox("panel") as StyleBoxFlat
	var exit := create_tween()
	exit.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit.set_parallel(true)
	exit.tween_property(banner, "position:y", banner.position.y - lift_distance, position_duration)
	exit.tween_property(banner, "modulate", Color(1, 1, 1, 0.0), fade_duration)
	if banner_style != null:
		exit.tween_property(banner_style, "bg_color:a", 0.0, fade_duration)
	exit.finished.connect(_queue_free_instance.bind(banner_id))


func _restore_reveal_frame_after_glow(frame_id: int, fate: String, original_style: StyleBox) -> void:
	var reveal_frame := instance_from_id(frame_id) as Control
	if reveal_frame == null or not is_instance_valid(reveal_frame):
		return
	if reveal_result_locked and reveal_locked_fate == fate:
		_apply_reveal_locked_indicator(fate)
	elif original_style != null:
		reveal_frame.add_theme_stylebox_override("panel", original_style)


func _set_transition_card_flight_progress(progress: float, card_id: int, start_pos: Vector2, control_point: Vector2, end_pos: Vector2) -> void:
	var transition_card := instance_from_id(card_id) as Control
	if transition_card == null or not is_instance_valid(transition_card):
		return
	transition_card.global_position = _quadratic_bezier(start_pos, control_point, end_pos, progress)


func _set_active_reveal_card_flight_progress(progress: float, start_pos: Vector2, control_point: Vector2, end_pos: Vector2) -> void:
	if active_reveal_card == null or not is_instance_valid(active_reveal_card):
		return
	active_reveal_card.global_position = _quadratic_bezier(start_pos, control_point, end_pos, progress)


func _on_skill_feedback_banner_linger_timeout(banner_id: int) -> void:
	_start_floating_banner_exit(banner_id, 28.0, 0.30, 0.28)


func _on_skill_feedback_banner_enter_finished(banner_id: int) -> void:
	var banner := instance_from_id(banner_id) as PanelContainer
	if banner == null or not is_instance_valid(banner):
		return
	var linger := get_tree().create_timer(1.35)
	linger.timeout.connect(_on_skill_feedback_banner_linger_timeout.bind(banner_id))


func _on_undying_banner_hold_timeout(banner_id: int) -> void:
	_start_floating_banner_exit(banner_id, 34.0, 0.28, 0.24)


func _on_undying_banner_enter_finished(banner_id: int) -> void:
	var banner := instance_from_id(banner_id) as PanelContainer
	if banner == null or not is_instance_valid(banner):
		return
	var hold := get_tree().create_timer(0.60)
	hold.timeout.connect(_on_undying_banner_hold_timeout.bind(banner_id))


func _run_undying_trigger_effect() -> void:
	if not is_inside_tree():
		return
	var world_center := _get_player_stage_hit_world_center()
	_trigger_hitstop(0.050, 0.22, 0.18)
	_play_screen_shake(18.0, 0.18, 5, 0.56)
	_play_spotlight_focus(Color(1.0, 0.88, 0.54), 0.66, 0.12, 0.08, 0.52)
	_spawn_undying_burst(world_center)
	_animate_player_undying_rebound()
	_show_undying_trigger_banner(world_center)
	if damage_overlay != null:
		damage_overlay.color = Color(1.0, 0.76, 0.34, 0.0)
		var overlay_tween := create_tween()
		overlay_tween.tween_property(damage_overlay, "color:a", 0.22, 0.06)
		overlay_tween.tween_property(damage_overlay, "color:a", 0.0, 0.34)


func _set_replace_modal_selected_ally(ally: Dictionary) -> void:
	modal_replace_selected_ally = ally
	if modal_replace_candidates_grid != null:
		var selected_uid := int(ally.get("uid", -1))
		for child in modal_replace_candidates_grid.get_children():
			if child is Button:
				var button := child as Button
				button.set_meta("selected", int(button.get_meta("ally_uid", -2)) == selected_uid)
				_refresh_replace_candidate_button_visual(button)
	_refresh_replace_modal_content()


func _refresh_replace_modal_content() -> void:
	if modal_replace_new_ally.is_empty() or modal_replace_selected_ally.is_empty():
		return
	if modal_replace_new_text != null:
		modal_replace_new_text.text = ""
		modal_replace_new_text.append_text(BattleScreenText.build_replace_modal_card_text(modal_replace_new_ally, "新入队伙伴", "#f0c977", "入队状态"))
		modal_replace_new_text.scroll_to_line(0)
	if modal_replace_current_text != null:
		modal_replace_current_text.text = ""
		modal_replace_current_text.append_text(BattleScreenText.build_replace_modal_card_text(modal_replace_selected_ally, "当前队友", "#ffb58f", "当前状态"))
		modal_replace_current_text.scroll_to_line(0)
	if modal_replace_confirm_button != null:
		TheaterModal.set_option_button_text(modal_replace_confirm_button, "替换 %s" % str(modal_replace_selected_ally.get("character", {}).get("code", "")))


func _set_replace_modal_active(active: bool) -> void:
	modal_active_layout = "replace" if active else ""
	if modal_replace_root != null:
		modal_replace_root.visible = active
	if modal_body_center != null:
		modal_body_center.visible = not active
	if modal_detail_panel != null:
		modal_detail_panel.visible = false if active else modal_detail_panel.visible
	if modal_flex_spacer != null:
		modal_flex_spacer.visible = not active
	if modal_buttons_center != null:
		modal_buttons_center.visible = not active
	if not active:
		modal_replace_new_ally = {}
		modal_replace_selected_ally = {}
		modal_replace_choices.clear()
		if modal_replace_candidates_grid != null:
			_clear_children(modal_replace_candidates_grid)


func _refresh_replace_modal_layout() -> void:
	if modal_panel == null or modal_replace_root == null or not modal_replace_root.visible:
		return

	var viewport_size := get_viewport_rect().size
	var max_width := clampf(viewport_size.x - 72.0, 980.0, 1340.0)
	var max_height := clampf(viewport_size.y - 84.0, 430.0, 620.0)
	var target_width := minf(1280.0, max_width)
	var panel_height := roundf(target_width / TheaterModal.CHOICE_PANEL_ASPECT)
	if panel_height > max_height:
		panel_height = max_height
		target_width = floorf(panel_height * TheaterModal.CHOICE_PANEL_ASPECT)

	modal_panel.custom_minimum_size = Vector2(target_width, panel_height)

	var content_width := maxf(760.0, target_width * (TheaterModal.CHOICE_CONTENT_RIGHT_RATIO - TheaterModal.CHOICE_CONTENT_LEFT_RATIO) - float(TheaterModal.CHOICE_CONTENT_MARGIN_X * 2))
	var compare_gap := 14.0
	var card_width := floorf((content_width - compare_gap) * 0.5)
	var card_height := clampf(panel_height * 0.39, 210.0, 270.0)
	if modal_replace_new_panel != null:
		modal_replace_new_panel.custom_minimum_size = Vector2(card_width, card_height)
	if modal_replace_current_panel != null:
		modal_replace_current_panel.custom_minimum_size = Vector2(card_width, card_height)

	if modal_replace_candidates_grid != null:
		var candidate_count := modal_replace_candidates_grid.get_child_count()
		var columns := 1
		if candidate_count >= 4:
			columns = 2
		elif candidate_count == 3:
			columns = 3 if content_width >= 930.0 else 2
		elif candidate_count > 0:
			columns = candidate_count
		modal_replace_candidates_grid.columns = maxi(columns, 1)
		var button_height := 76.0 if columns >= 3 else 84.0
		for child in modal_replace_candidates_grid.get_children():
			if child is Button:
				var button := child as Button
				button.custom_minimum_size = Vector2(0, button_height)

	if modal_replace_confirm_button != null:
		modal_replace_confirm_button.custom_minimum_size.x = clampf(target_width * 0.30, 280.0, 360.0)
	if modal_replace_cancel_button != null:
		modal_replace_cancel_button.custom_minimum_size.x = clampf(target_width * 0.22, 220.0, 300.0)

	modal_panel.reset_size()


func _present_replace_modal(new_ally: Dictionary, replaceable: Array):
	if replaceable.is_empty():
		return null

	_hide_modal_option_tooltip()
	_hide_modal_recruit_detail()
	_set_modal_detail_text("")
	modal_title.text = "槽位已满"
	if modal_replace_subtitle_label != null:
		modal_replace_subtitle_label.text = "选中一位当前队友，再决定是否替换。"

	modal_replace_new_ally = new_ally
	modal_replace_choices = replaceable.duplicate(false)
	if modal_replace_candidates_grid != null:
		_clear_children(modal_replace_candidates_grid)
		for ally in replaceable:
			modal_replace_candidates_grid.add_child(_make_replace_candidate_button(ally))

	_set_replace_modal_active(true)
	_set_replace_modal_selected_ally(replaceable[0])

	modal_backdrop.modulate = Color(1, 1, 1, 0)
	modal_backdrop.visible = true
	_refresh_replace_modal_layout()
	await get_tree().process_frame
	_refresh_replace_modal_layout()
	modal_backdrop.modulate = Color.WHITE

	var result = await modal_choice_resolved
	_set_replace_modal_active(false)
	modal_backdrop.modulate = Color.WHITE
	if result is Array and result.size() > 0:
		return result[0]
	return result


func _set_modal_recruit_detail(ally: Dictionary) -> void:
	if modal_detail_panel == null or modal_recruit_detail_root == null:
		return
	if ally.is_empty():
		_hide_modal_recruit_detail()
		return

	var character: Dictionary = ally["character"]
	var ally_skill: Dictionary = character.get("skills", {}).get("ally", {})
	var status_parts: Array[String] = BattleScreenText.get_ally_status_parts(ally)

	modal_detail_panel.visible = true
	modal_recruit_detail_root.visible = true
	if modal_detail_text != null:
		modal_detail_text.visible = false

	if modal_recruit_name_label != null:
		modal_recruit_name_label.text = "%s · %s" % [character.get("code", ""), character.get("name", "")]
	if modal_recruit_status_label != null:
		modal_recruit_status_label.text = "入队状态  %s" % " / ".join(status_parts) if not status_parts.is_empty() else ""
	if modal_recruit_skill_name_label != null:
		modal_recruit_skill_name_label.text = "队友技能 · %s" % str(ally_skill.get("name", ""))
	if modal_recruit_skill_desc_label != null:
		modal_recruit_skill_desc_label.text = str(ally_skill.get("description", ""))
	if modal_recruit_warning_label != null:
		modal_recruit_warning_label.text = "警告：潜伏结束后会反噬。" if ally["is_spy"] else ""
		modal_recruit_warning_label.visible = ally["is_spy"]


func _hide_modal_recruit_detail() -> void:
	if modal_recruit_detail_root != null:
		modal_recruit_detail_root.visible = false
	if modal_detail_text != null:
		modal_detail_text.visible = true


func _set_modal_detail_content(detail_text: String, detail_ally: Dictionary = {}) -> void:
	if detail_ally.is_empty():
		_hide_modal_recruit_detail()
		_set_modal_detail_text(detail_text)
		return
	_set_modal_detail_text("")
	_set_modal_recruit_detail(detail_ally)


func _set_modal_detail_text(detail_text: String) -> void:
	if modal_detail_panel == null or modal_detail_text == null:
		return
	modal_detail_text.text = ""
	if detail_text.is_empty():
		modal_detail_panel.visible = false
		modal_detail_panel.custom_minimum_size.y = 0
		return
	modal_detail_panel.visible = true
	modal_detail_text.append_text(detail_text)
	modal_detail_text.scroll_to_line(0)


func _set_modal_detail_text_and_refresh(detail_text: String, option_count: int, detail_layout: String = "") -> void:
	_set_modal_detail_text(detail_text)
	call_deferred("_refresh_modal_layout", not detail_text.is_empty(), option_count, detail_layout)


func _set_modal_body_text(body_text: String) -> void:
	if modal_body == null:
		return
	var escaped := body_text.replace("[", "【")
	escaped = escaped.replace("]", "】")
	modal_body.text = "[center]%s[/center]" % escaped
	modal_body.scroll_to_line(0)


func _show_modal_option_tooltip(text: String, source_control: Control) -> void:
	if modal_tooltip_panel == null or modal_tooltip_text == null or text.is_empty():
		return
	modal_tooltip_text.text = ""
	modal_tooltip_text.append_text(text)
	modal_tooltip_text.scroll_to_line(0)
	modal_tooltip_panel.reset_size()

	var source_rect := source_control.get_global_rect()
	var viewport_size := get_viewport_rect().size
	var tooltip_size := modal_tooltip_panel.size
	if tooltip_size.x <= 0.0 or tooltip_size.y <= 0.0:
		tooltip_size = modal_tooltip_panel.custom_minimum_size

	var target_x := source_rect.position.x + source_rect.size.x + 12.0
	if target_x + tooltip_size.x > viewport_size.x - 16.0:
		target_x = source_rect.position.x - tooltip_size.x - 12.0
	var target_y := source_rect.position.y + (source_rect.size.y - tooltip_size.y) * 0.5
	target_x = clampf(target_x, 16.0, viewport_size.x - tooltip_size.x - 16.0)
	target_y = clampf(target_y, 16.0, viewport_size.y - tooltip_size.y - 16.0)

	modal_tooltip_panel.position = Vector2(target_x, target_y)
	modal_tooltip_panel.visible = true


func _hide_modal_option_tooltip() -> void:
	if modal_tooltip_panel != null:
		modal_tooltip_panel.visible = false


func _refresh_log_modal_layout() -> void:
	if log_panel == null or log_box == null:
		return
	var viewport_size := get_viewport_rect().size
	var max_width := clampf(viewport_size.x - 72.0, 920.0, 1320.0)
	var max_height := clampf(viewport_size.y - 96.0, 380.0, 620.0)
	var panel_width := minf(1180.0, max_width)
	var panel_height := roundf(panel_width / TheaterModal.CHOICE_PANEL_ASPECT)
	if panel_height > max_height:
		panel_height = max_height
		panel_width = floorf(panel_height * TheaterModal.CHOICE_PANEL_ASPECT)

	var log_width := maxf(420.0, panel_width * 0.78)
	var log_height := maxf(180.0, panel_height * 0.64)

	log_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	log_box.custom_minimum_size = Vector2(log_width, log_height)
	log_panel.reset_size()


func _refresh_modal_layout(detail_visible: bool, option_count: int, detail_layout: String = "") -> void:
	if modal_panel == null or modal_title == null or modal_body == null or modal_buttons == null:
		return

	var comparison_layout := detail_layout == "comparison"
	var viewport_size := get_viewport_rect().size
	var max_width := clampf(viewport_size.x - 84.0, 860.0, 1320.0 if comparison_layout else 1260.0)
	var max_height := clampf(viewport_size.y - 96.0, 340.0, 620.0)
	var target_width := 980.0
	if detail_visible:
		target_width = 1280.0 if comparison_layout else 1240.0
	elif option_count >= 3:
		target_width = 1160.0
	elif option_count == 1:
		target_width = 920.0
	target_width = minf(target_width, max_width)

	var panel_height := roundf(target_width / TheaterModal.CHOICE_PANEL_ASPECT)
	if panel_height > max_height:
		panel_height = max_height
		target_width = floorf(panel_height * TheaterModal.CHOICE_PANEL_ASPECT)

	var inner_width := maxf(320.0, target_width * (0.76 if comparison_layout else (0.74 if detail_visible else 0.58)))
	modal_panel.custom_minimum_size = Vector2(target_width, panel_height)
	modal_body.custom_minimum_size.x = inner_width
	modal_detail_text.custom_minimum_size.x = inner_width
	modal_body.reset_size()
	if modal_detail_text != null:
		modal_detail_text.reset_size()

	var body_content_height := ceilf(maxf(modal_body.get_content_height(), 28.0))
	var buttons_height := modal_buttons.get_combined_minimum_size().y
	var title_height := maxf(48.0, modal_title.get_combined_minimum_size().y)
	var inner_height := panel_height * (TheaterModal.CHOICE_CONTENT_BOTTOM_RATIO - TheaterModal.CHOICE_CONTENT_TOP_RATIO)
	inner_height -= float(TheaterModal.CHOICE_CONTENT_MARGIN_TOP + TheaterModal.CHOICE_CONTENT_MARGIN_BOTTOM)
	var section_gap := 10.0
	var visible_sections := 4 if detail_visible else 3
	var content_budget := maxf(72.0, inner_height - title_height - buttons_height - section_gap * float(visible_sections - 1))
	var body_limit := content_budget
	if detail_visible:
		body_limit = minf(maxf(32.0, content_budget * (0.14 if comparison_layout else 0.18)), 46.0 if comparison_layout else 56.0)
	var body_height := minf(body_content_height, body_limit)
	modal_body.custom_minimum_size.y = body_height
	modal_body.scroll_active = body_content_height > body_height + 2.0
	modal_body.scroll_to_line(0)

	if detail_visible and modal_detail_panel != null and modal_detail_text != null:
		var using_recruit_detail := modal_recruit_detail_root != null and modal_recruit_detail_root.visible
		var detail_content_height := 72.0
		if using_recruit_detail:
			modal_recruit_detail_root.reset_size()
			modal_recruit_detail_root.update_minimum_size()
			detail_content_height = ceilf(maxf(modal_recruit_detail_root.get_combined_minimum_size().y + 4.0, 72.0))
			modal_detail_text.custom_minimum_size.y = 0
			modal_detail_text.scroll_active = false
		else:
			detail_content_height = ceilf(maxf(modal_detail_text.get_content_height() + 8.0, 72.0))
		var detail_limit := minf(maxf(118.0 if comparison_layout else 78.0, content_budget - body_height - 10.0), 188.0 if comparison_layout else 118.0)
		var detail_height := minf(detail_content_height, detail_limit)
		modal_detail_panel.custom_minimum_size.y = detail_height + 24.0
		if using_recruit_detail:
			modal_recruit_detail_root.custom_minimum_size = Vector2(0, detail_height)
		else:
			modal_detail_text.custom_minimum_size.y = detail_height
			modal_detail_text.scroll_active = detail_content_height > detail_height + 2.0
			modal_detail_text.scroll_to_line(0)
	else:
		if modal_detail_panel != null:
			modal_detail_panel.custom_minimum_size.y = 0

	var button_width := clampf(target_width * 0.34, 260.0, 430.0)
	for child in modal_buttons.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size.x = button_width
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	modal_panel.reset_size()


func _refresh_reveal_texture_layout() -> void:
	if reveal_card_panel == null or reveal_texture_host == null:
		return
	var available_height: float = clampf(reveal_card_panel.size.y - 76.0, 220.0, 340.0)
	var available_width: float = clampf(reveal_card_panel.size.x - 18.0, 180.0, 250.0)
	var card_ratio: float = 0.75
	var width: float = minf(available_width, available_height * card_ratio)
	var height: float = width / card_ratio
	if height > available_height:
		height = available_height
		width = height * card_ratio
	var target_size := Vector2(round(width), round(height))
	if reveal_texture != null:
		reveal_texture.custom_minimum_size = target_size
		reveal_texture.pivot_offset = reveal_texture.size / 2.0
	if reveal_preview_card != null:
		card_helper.apply_card_visual_size(reveal_preview_card, target_size)

func _sync_reveal_preview_card(character: Dictionary, fate_variant: String = "ally") -> void:
	if reveal_texture_host == null:
		return
	if reveal_preview_card != null:
		reveal_preview_card.queue_free()
		reveal_preview_card = null
	if character.is_empty():
		return
	var card_size := Vector2.ZERO
	if reveal_texture != null:
		card_size = reveal_texture.custom_minimum_size
	if card_size == Vector2.ZERO:
		card_size = Vector2(180, 240)
	reveal_preview_card = card_helper.create_card_visual(character, card_size, true, fate_variant, false)
	reveal_texture_host.add_child(reveal_preview_card)
	reveal_texture_host.move_child(reveal_preview_card, 0)
	_refresh_reveal_preview_visibility()


func _refresh_reveal_preview_visibility() -> void:
	if reveal_preview_card == null:
		return
	var has_active_reveal := active_reveal_card != null and active_reveal_card.is_inside_tree()
	reveal_preview_card.visible = not has_active_reveal and not reveal_result_locked


func _get_reveal_motion_target() -> Control:
	if active_reveal_card != null and active_reveal_card.is_inside_tree():
		return active_reveal_card
	if reveal_preview_card != null and reveal_preview_card.is_inside_tree():
		return reveal_preview_card
	if reveal_card_panel != null:
		return reveal_card_panel
	return reveal_texture


func _get_reveal_visual_frame() -> PanelContainer:
	if active_reveal_card != null and active_reveal_card.has_meta("frame"):
		return active_reveal_card.get_meta("frame") as PanelContainer
	if reveal_preview_card != null and reveal_preview_card.has_meta("frame"):
		return reveal_preview_card.get_meta("frame") as PanelContainer
	return null


func _get_card_effect_texture_target(card_visual: Control) -> TextureRect:
	if card_visual == null or not card_visual.has_meta("portrait"):
		return null
	return card_visual.get_meta("portrait") as TextureRect


func _get_active_reveal_visual_frame() -> PanelContainer:
	if active_reveal_card != null and active_reveal_card.has_meta("frame"):
		return active_reveal_card.get_meta("frame") as PanelContainer
	return null


func _get_reveal_effect_host() -> Control:
	var active_portrait := _get_card_effect_texture_target(active_reveal_card)
	if active_portrait != null:
		return active_portrait
	var preview_portrait := _get_card_effect_texture_target(reveal_preview_card)
	if preview_portrait != null:
		return preview_portrait
	var reveal_frame := _get_reveal_visual_frame()
	if reveal_frame != null:
		return reveal_frame
	return _get_reveal_motion_target()


func _get_active_reveal_effect_host() -> Control:
	var active_portrait := _get_card_effect_texture_target(active_reveal_card)
	if active_portrait != null:
		return active_portrait
	var reveal_frame := _get_active_reveal_visual_frame()
	if reveal_frame != null:
		return reveal_frame
	if active_reveal_card != null and active_reveal_card.is_inside_tree():
		return active_reveal_card
	return null


func _dock_active_reveal_card_to_host() -> void:
	if active_reveal_card == null:
		return
	_promote_active_reveal_card_to_floating_layer()
	active_reveal_card.scale = Vector2.ONE
	active_reveal_card.rotation_degrees = 0.0
	active_reveal_card.modulate = Color.WHITE
	active_reveal_card.z_index = 120
	active_reveal_card.global_position = _get_reveal_card_target_center() - active_reveal_card.size * 0.5


func _promote_active_reveal_card_to_floating_layer() -> void:
	if active_reveal_card == null or floating_effect_layer == null:
		return
	if active_reveal_card.get_parent() != floating_effect_layer:
		active_reveal_card.reparent(floating_effect_layer, true)
	active_reveal_card.z_index = 120


func _create_reveal_shader_overlay() -> Control:
	var effect_host := _get_active_reveal_effect_host()
	if effect_host == null:
		return null
	var existing_overlay: Control = _get_object_meta_value(effect_host, "fate_reveal_overlay", null) as Control
	if existing_overlay != null and is_instance_valid(existing_overlay):
		existing_overlay.queue_free()
	var overlay: Control
	var texture_host := effect_host as TextureRect
	if texture_host != null and texture_host.texture != null:
		var textured_overlay := TextureRect.new()
		textured_overlay.texture = texture_host.texture
		textured_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textured_overlay.stretch_mode = TextureRect.STRETCH_SCALE
		overlay = textured_overlay
	else:
		var flat_overlay := ColorRect.new()
		flat_overlay.color = Color(0, 0, 0, 0)
		overlay = flat_overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 4
	overlay.material = ShaderEffects.create_fate_reveal_material(true)
	effect_host.add_child(overlay)
	effect_host.set_meta("fate_reveal_overlay", overlay)
	return overlay


func _hide_reveal_shader_overlay_on_host(effect_host: Control) -> void:
	if effect_host == null:
		return
	var overlay: Control = _get_object_meta_value(effect_host, "fate_reveal_overlay", null) as Control
	if overlay == null or not is_instance_valid(overlay):
		return
	overlay.visible = false
	var overlay_material := overlay.material as ShaderMaterial
	if overlay_material != null:
		overlay_material.set_shader_parameter("glow_intensity", 0.0)
	effect_host.remove_meta("fate_reveal_overlay")


func _hide_active_reveal_shader_overlay() -> void:
	var active_host := _get_active_reveal_effect_host()
	if active_host != null:
		_hide_reveal_shader_overlay_on_host(active_host)
	var preview_host := _get_reveal_effect_host()
	if preview_host != null and preview_host != active_host:
		_hide_reveal_shader_overlay_on_host(preview_host)


func _get_frame_base_style(frame: PanelContainer) -> StyleBoxFlat:
	if frame == null:
		return null
	var stored_style: Variant = _get_object_meta_value(frame, "base_panel_style", null)
	if stored_style is StyleBoxFlat:
		return (stored_style as StyleBoxFlat).duplicate()
	var current_style := frame.get_theme_stylebox("panel")
	if current_style is StyleBoxFlat:
		return (current_style as StyleBoxFlat).duplicate()
	return null


func _get_viewport_world_center() -> Vector2:
	var viewport_rect := get_viewport_rect()
	return viewport_rect.position + viewport_rect.size * 0.5


func _align_reveal_card_panel_to_viewport_center() -> void:
	if reveal_card_panel == null or seat_layer == null:
		return
	var viewport_center := _get_viewport_world_center()
	var target_pos := _to_layer_local_point(seat_layer, viewport_center) - reveal_card_panel.size * 0.5
	if reveal_texture_host != null and reveal_texture_host.is_inside_tree():
		var host_rect := reveal_texture_host.get_global_rect()
		var panel_rect := reveal_card_panel.get_global_rect()
		if host_rect.size.x > 0.0 and host_rect.size.y > 0.0 and panel_rect.size.x > 0.0 and panel_rect.size.y > 0.0:
			target_pos -= host_rect.get_center() - panel_rect.get_center()
	reveal_card_panel.position = target_pos


func _get_reveal_card_target_center() -> Vector2:
	return _get_viewport_world_center()


func _update_reveal_preview(character: Dictionary, fate_text: String, fate_variant: String = "", reset_flip: bool = true) -> void:
	if character.is_empty():
		reveal_card_panel.visible = false
		reveal_name_label.text = ""
		reveal_name_label.visible = false
		_sync_reveal_preview_card({})
		fate_label.text = ""
		fate_label.modulate = Color("d8c9ae")
		_apply_reveal_rarity_style({})
		return

	var display_variant := _normalize_card_fate_variant(fate_variant)
	reveal_card_panel.visible = true
	reveal_name_label.text = ""
	reveal_name_label.visible = false
	_sync_reveal_preview_card(character, display_variant)
	fate_label.text = BattleScreenText.format_reveal_state_text(fate_text)
	fate_label.modulate = BattleScreenText.get_reveal_state_color(fate_text)
	if not reveal_result_locked:
		_apply_reveal_rarity_style(character)
	call_deferred("_align_reveal_card_panel_to_viewport_center")


func _lock_reveal_preview(character: Dictionary, fate_text: String, fate: String = "") -> void:
	reveal_result_locked = true
	reveal_locked_character = character.duplicate(true)
	reveal_locked_text = fate_text
	reveal_locked_fate = fate
	_update_reveal_preview(character, fate_text, fate)
	_refresh_reveal_preview_visibility()
	_apply_reveal_locked_indicator(fate)


func _unlock_reveal_preview() -> void:
	reveal_result_locked = false
	reveal_locked_character = {}
	reveal_locked_text = ""
	reveal_locked_fate = ""
	_clear_reveal_locked_indicator()
	_update_reveal_preview({}, "")
	_refresh_reveal_preview_visibility()
	if fate_reveal_overlay != null:
		fate_reveal_overlay.visible = false
	# 隐藏详情面板
	var detail_panel: PanelContainer = _get_valid_meta_value("card_detail_panel") as PanelContainer
	if detail_panel != null:
		detail_panel.visible = false


func _apply_reveal_locked_indicator(fate: String) -> void:
	if reveal_card_panel == null:
		return
	_clear_reveal_locked_indicator()
	if fate.is_empty():
		return

	var glow_color := Color("4a9eff") if fate == "ally" else Color("ff3a3a")
	var reveal_frame := _get_reveal_visual_frame()
	if reveal_frame != null:
		var locked_style := _get_frame_base_style(reveal_frame)
		if locked_style != null:
			locked_style.border_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.92)
			locked_style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.40)
			locked_style.shadow_size = 28
			locked_style.shadow_offset = Vector2.ZERO
			locked_style.border_width_left = 3
			locked_style.border_width_top = 3
			locked_style.border_width_right = 3
			locked_style.border_width_bottom = 3
			reveal_frame.add_theme_stylebox_override("panel", locked_style)


func _clear_reveal_locked_indicator() -> void:
	if reveal_locked_glow != null:
		reveal_locked_glow.queue_free()
		reveal_locked_glow = null
	var character: Dictionary = {}
	if reveal_result_locked and not reveal_locked_character.is_empty():
		character = reveal_locked_character
	_apply_reveal_rarity_style(character)


func _get_rarity_border_color(character: Dictionary) -> Color:
	return card_helper.get_rarity_border_color(character)


func _apply_reveal_rarity_style(character: Dictionary) -> void:
	var reveal_frame := _get_reveal_visual_frame()
	if reveal_frame == null:
		return

	var style := _get_frame_base_style(reveal_frame)
	if style == null:
		return
	if not character.is_empty():
		var rarity_color := card_helper.get_rarity_border_color(character)
		style.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.56)
		style.shadow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.22)
		style.shadow_size = 16
		style.shadow_offset = Vector2.ZERO
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	reveal_frame.add_theme_stylebox_override("panel", style)


func _append_log(message: String) -> void:
	if log_box == null:
		return
	log_box.append_text(BattleScreenText.format_log_message(message))
	log_box.scroll_to_line(maxi(0, log_box.get_line_count() - 1))


func _spawn_toast(message: String) -> void:
	return


func _get_skill_feedback_world_position(
	source_kind: String,
	source_ally: Dictionary = {},
	world_position_override = null
) -> Vector2:
	if world_position_override is Vector2:
		return world_position_override
	match source_kind:
		"hero":
			return _get_player_stage_hit_world_center()
		"ally":
			if not source_ally.is_empty():
				return _get_seat_world_center(_get_seat_id_for_ally(source_ally), int(source_ally.get("uid", -1)))
			return _get_seat_world_center("player")
		_:
			if active_reveal_card != null and active_reveal_card.is_inside_tree():
				return _get_control_world_center(active_reveal_card)
			return _get_seat_world_center("enemy")


func _show_skill_feedback(
	source_kind: String,
	character: Dictionary,
	skill_slot: String,
	source_ally: Dictionary = {},
	world_position_override = null,
	extra_detail: String = ""
) -> void:
	if floating_effect_layer == null or character.is_empty():
		return
	var skill: Dictionary = character.get("skills", {}).get(skill_slot, {})
	var actor_code := str(character.get("code", ""))
	var skill_name := str(skill.get("name", ""))
	var skill_desc := str(skill.get("description", "")).strip_edges()
	var detail_text := skill_desc
	var appended_detail := extra_detail.strip_edges()
	if not appended_detail.is_empty():
		if detail_text.is_empty():
			detail_text = appended_detail
		else:
			detail_text += "\n\n" + appended_detail
	if actor_code.is_empty() and skill_name.is_empty() and detail_text.is_empty():
		return

	var banner := PanelContainer.new()
	banner.z_index = 210
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var palette: Dictionary = BattleScreenText.get_skill_feedback_palette(source_kind)
	var bg_color: Color = palette["bg"]
	var border_color: Color = palette["border"]
	var accent_color: Color = palette["accent"]
	var shadow_color: Color = palette["shadow"]

	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = bg_color
	banner_style.border_color = border_color
	banner_style.border_width_left = 2
	banner_style.border_width_top = 2
	banner_style.border_width_right = 2
	banner_style.border_width_bottom = 4
	banner_style.corner_radius_top_left = 16
	banner_style.corner_radius_top_right = 16
	banner_style.corner_radius_bottom_left = 16
	banner_style.corner_radius_bottom_right = 16
	banner_style.shadow_color = shadow_color
	banner_style.shadow_size = 22
	banner.add_theme_stylebox_override("panel", banner_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	banner.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	var title := UIFactory.make_label(BattleScreenText.get_skill_feedback_title(source_kind), 15, accent_color, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0.16, 0.06, 0.04, 0.42))
	content.add_child(title)

	var headline := "%s触发" % skill_name if not skill_name.is_empty() else actor_code
	var headline_label := UIFactory.make_label(headline.strip_edges(), 28, Color("fff8ef"), true)
	headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline_label.add_theme_constant_override("outline_size", 4)
	headline_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.04, 0.52))
	content.add_child(headline_label)

	var meta_parts: Array[String] = []
	if not actor_code.is_empty():
		meta_parts.append(actor_code)
	if not skill_name.is_empty() and headline != "%s触发" % skill_name:
		meta_parts.append(skill_name)
	if not meta_parts.is_empty():
		var meta_label := UIFactory.make_label(" · ".join(meta_parts), 14, Color("ffe7c4"), true)
		meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		meta_label.add_theme_constant_override("outline_size", 3)
		meta_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.04, 0.44))
		content.add_child(meta_label)

	if not skill_desc.is_empty():
		var desc_label := UIFactory.make_label(skill_desc, 15, Color("fff1dc"))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size = Vector2(332.0, 0.0)
		desc_label.add_theme_constant_override("outline_size", 2)
		desc_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.04, 0.32))
		content.add_child(desc_label)

	if not appended_detail.is_empty():
		var result_prefix := "本次查看结果："
		if appended_detail.begins_with(result_prefix):
			var result_row := HBoxContainer.new()
			result_row.alignment = BoxContainer.ALIGNMENT_CENTER
			result_row.add_theme_constant_override("separation", 4)
			content.add_child(result_row)

			var prefix_label := UIFactory.make_label(result_prefix, 16, Color("fff1dc"), true)
			prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prefix_label.add_theme_constant_override("outline_size", 2)
			prefix_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.04, 0.32))
			result_row.add_child(prefix_label)

			var result_value := appended_detail.substr(result_prefix.length()).strip_edges()
			var result_color := Color("ff8a7a") if result_value.contains("敌") else Color("8fc6ff")
			var result_label := UIFactory.make_label(result_value, 18, result_color, true)
			result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			result_label.add_theme_constant_override("outline_size", 3)
			result_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.04, 0.40))
			result_row.add_child(result_label)
		else:
			var extra_label := UIFactory.make_label(appended_detail, 15, Color("fff1dc"))
			extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			extra_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			extra_label.custom_minimum_size = Vector2(332.0, 0.0)
			extra_label.add_theme_constant_override("outline_size", 2)
			extra_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.04, 0.32))
			content.add_child(extra_label)

	floating_effect_layer.add_child(banner)
	var banner_height := 104.0
	if not detail_text.is_empty():
		banner_height = 168.0 if not appended_detail.is_empty() else 136.0
	banner.custom_minimum_size = Vector2(392.0, banner_height)
	banner.size = banner.custom_minimum_size
	banner.pivot_offset = banner.size * 0.5

	var anchor := _to_layer_local_point(
		floating_effect_layer,
		_get_skill_feedback_world_position(source_kind, source_ally, world_position_override)
	)
	var banner_layout: Dictionary = _register_floating_banner(
		banner,
		anchor,
		{
			"base_offset_y": 176.0,
			"stack_gap": 14.0,
			"enter_offset_y": 18.0,
			"layout_duration": 0.18,
		}
	)
	_play_floating_banner_enter(
		banner,
		banner_style,
		banner_layout.get("target_position", banner.position),
		{
			"enter_delay": float(banner_layout.get("enter_delay", 0.0)),
			"enter_offset_y": 18.0,
			"position_duration": 0.22,
			"scale_duration": 0.20,
			"fade_duration": 0.16,
			"bg_alpha": 0.94,
			"start_scale": Vector2(0.84, 0.84),
		},
		_on_skill_feedback_banner_enter_finished.bind(banner.get_instance_id())
	)


func _show_hero_skill_feedback(world_position_override = null, extra_detail: String = "") -> void:
	_show_skill_feedback("hero", state.player_character, "hero", {}, world_position_override, extra_detail)


func _build_ally_feedback_character(source_ally: Dictionary, skill_code: String = "") -> Dictionary:
	var character: Dictionary = source_ally.get("character", {})
	if source_ally.is_empty() or skill_code.is_empty():
		return character
	if str(character.get("code", "")) != "FAKE":
		return character
	var mimicked_code := str(source_ally.get("extra", {}).get("mimic_code", ""))
	if mimicked_code != skill_code:
		return character
	var mimicked_character := CharactersData.get_by_code(skill_code)
	if mimicked_character.is_empty():
		return character
	var mimicked_skill: Dictionary = mimicked_character.get("skills", {}).get("ally", {})
	if mimicked_skill.is_empty():
		return character
	var feedback_character: Dictionary = character.duplicate(true)
	if not feedback_character.has("skills"):
		feedback_character["skills"] = {}
	feedback_character["skills"]["ally"] = mimicked_skill.duplicate(true)
	return feedback_character


func _show_ally_skill_feedback(source_ally: Dictionary, world_position_override = null, skill_code: String = "") -> void:
	if source_ally.is_empty():
		return
	var character := _build_ally_feedback_character(source_ally, skill_code)
	_show_skill_feedback("ally", character, "ally", source_ally, world_position_override)


func _show_enemy_skill_feedback(character: Dictionary, world_position_override = null) -> void:
	_show_skill_feedback("enemy", character, "enemy", {}, world_position_override)


func _show_enemy_skill_feedback_by_code(code: String, world_position_override = null) -> void:
	var character := CharactersData.get_by_code(code)
	if character.is_empty():
		character = {
			"code": code,
			"skills": {
				"enemy": {
					"name": code,
				}
			}
		}
	_show_enemy_skill_feedback(character, world_position_override)


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()


func _make_line_style(color: Color, thickness: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_top = thickness / 2.0
	style.content_margin_bottom = thickness / 2.0
	return style


func _make_icon_button(symbol: String, bg_color: Color, font_color: Color, border_color: Color) -> Button:
	var button := Button.new()
	button.text = symbol
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_color = border_color
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 999
	normal.corner_radius_top_right = 999
	normal.corner_radius_bottom_right = 999
	normal.corner_radius_bottom_left = 999
	normal.shadow_color = Color(0.24, 0.31, 0.44, 0.12)
	normal.shadow_size = 12
	normal.shadow_offset = Vector2(0, 6)

	var hover := normal.duplicate()
	hover.bg_color = bg_color.lerp(Color.WHITE, 0.18)
	hover.shadow_size = 16

	var pressed := normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.06)
	pressed.shadow_size = 6
	pressed.shadow_offset = Vector2(0, 3)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


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


func _sync_icon_row(container: HBoxContainer, texture: Texture2D, count: int, icon_size: int = 38, modulate: Color = Color.WHITE) -> void:
	if container == null:
		return
	while container.get_child_count() > count:
		var last := container.get_child(container.get_child_count() - 1)
		container.remove_child(last)
		last.queue_free()
	while container.get_child_count() < count:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.modulate = modulate
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(icon)
	for child in container.get_children():
		var icon := child as TextureRect
		if icon == null:
			continue
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.modulate = modulate
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _sync_hp_icon_row(container: HBoxContainer, texture: Texture2D, hp: int, max_hp: int, icon_size: int = 38) -> void:
	if container == null:
		return
	var safe_max_hp := maxi(max_hp, 1)
	var total_hearts := maxi(1, int(ceil(float(safe_max_hp) / float(HP_PER_HEART))))
	var safe_hp := clampi(hp, 0, safe_max_hp)
	var empty_modulate := Color(0.42, 0.20, 0.24, 0.26)
	_sync_icon_row(container, texture, total_hearts, icon_size, empty_modulate)
	for i in range(total_hearts):
		var heart := container.get_child(i) as TextureRect
		if heart == null:
			continue
		var segment_start := i * HP_PER_HEART
		var segment_capacity := mini(HP_PER_HEART, safe_max_hp - segment_start)
		var segment_filled := clampi(safe_hp - segment_start, 0, segment_capacity)
		var fill_ratio := 0.0 if segment_capacity <= 0 else float(segment_filled) / float(segment_capacity)
		var tint := empty_modulate.lerp(Color.WHITE, fill_ratio)
		tint.a = lerpf(empty_modulate.a, 1.0, fill_ratio)
		heart.modulate = tint


func _make_fab_button(symbol: String, _bg_color: Color, _font_color: Color, _border_color: Color, font_size: int = 22) -> Button:
	var tarot_bg := Color(0.18, 0.05, 0.07, 0.95)
	var tarot_gold := Color("e2b970")
	var tarot_border := Color("8a5d2d")
	var button := _make_icon_button(symbol, tarot_bg, tarot_gold, tarot_border)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", tarot_gold)
	button.add_theme_color_override("font_hover_color", Color("ffe2a0"))
	button.add_theme_color_override("font_pressed_color", Color("c89968"))
	var states := ["normal", "hover", "pressed"]
	for state_name in states:
		var source_style := button.get_theme_stylebox(state_name)
		if source_style is StyleBoxFlat:
			var style := (source_style as StyleBoxFlat).duplicate()
			style.bg_color = tarot_bg if state_name != "hover" else Color(0.26, 0.10, 0.10, 0.97)
			if state_name == "pressed":
				style.bg_color = Color(0.12, 0.04, 0.05, 0.95)
			style.border_color = tarot_border
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.corner_radius_top_left = 999
			style.corner_radius_top_right = 999
			style.corner_radius_bottom_left = 999
			style.corner_radius_bottom_right = 999
			style.shadow_color = Color(0, 0, 0, 0.55)
			style.shadow_size = 14 if state_name != "pressed" else 6
			style.shadow_offset = Vector2(0, 6) if state_name != "pressed" else Vector2(0, 2)
			button.add_theme_stylebox_override(state_name, style)
	return button


func _resolve_modal_option_variant(option: Dictionary, option_index: int, option_count: int) -> String:
	var explicit_variant := str(option.get("variant", ""))
	if not explicit_variant.is_empty():
		return explicit_variant

	var text := str(option.get("text", ""))
	var value = option.get("value")
	if value == false:
		return "secondary"

	var secondary_keywords := [
		"继续",
		"取消",
		"结束",
		"放弃",
		"返回",
		"正常",
		"维持原样",
		"暂时不要",
	]
	for keyword in secondary_keywords:
		if text.contains(keyword):
			return "secondary"

	if option_count > 1 and option_index == option_count - 1 and text.contains("不要"):
		return "secondary"
	return "primary"


func _build_deck_card(card: Dictionary, deck_index: int) -> Button:
	var selected := deck_index == selected_deck_index
	var peek_data: Dictionary = _get_peek_data(deck_index)
	var use_small_card := _get_small_hand_card_texture(card["character"]) != null
	var button := Button.new()
	button.flat = use_small_card
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = deck_card_size
	button.size = deck_card_size
	button.pivot_offset = deck_card_size / 2.0
	button.rotation_degrees = 0.0
	button.clip_contents = false
	button.set_meta("deck_index", deck_index)
	button.set_meta("use_small_card", use_small_card)
	button.tooltip_text = "%s · %s" % [card["character"]["code"], card["character"]["name"]]
	card_helper.apply_deck_card_button_styles(button, card["character"], selected, peek_data)

	var button_id := button.get_instance_id()
	button.mouse_entered.connect(_on_deck_card_hover_changed.bind(button_id, deck_index, true))
	button.mouse_exited.connect(_on_deck_card_hover_changed.bind(button_id, deck_index, false))

	# 小卡直接展示完整卡图，不再额外叠按钮边框或玻璃阴影

	var art_holder := Control.new()
	art_holder.name = "ArtHolder"
	art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var result_label_height := 24.0 if not peek_data.is_empty() else 0.0
	art_holder.clip_contents = false
	button.add_child(art_holder)
	button.set_meta("art_holder", art_holder)

	var image := TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.modulate = Color(1, 1, 1, 0.98)
	art_holder.add_child(image)
	button.set_meta("portrait", image)

	var blink_layer := Control.new()
	blink_layer.name = "BlinkLayer"
	blink_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blink_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blink_layer.clip_contents = false
	art_holder.add_child(blink_layer)

	var blink_texture: Texture2D = soft_glow_texture if soft_glow_texture != null else _generate_soft_glow_texture()

	var blink_halo := TextureRect.new()
	blink_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blink_halo.texture = blink_texture
	blink_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blink_halo.stretch_mode = TextureRect.STRETCH_SCALE
	blink_halo.material = _make_additive_canvas_material()
	blink_halo.modulate = Color(1, 1, 1, 0)
	blink_layer.add_child(blink_halo)
	button.set_meta("blink_halo", blink_halo)

	var blink_major := TextureRect.new()
	blink_major.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blink_major.texture = blink_texture
	blink_major.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blink_major.stretch_mode = TextureRect.STRETCH_SCALE
	blink_major.material = _make_additive_canvas_material()
	blink_major.modulate = Color(1, 1, 1, 0)
	blink_layer.add_child(blink_major)
	button.set_meta("blink_major", blink_major)

	var blink_minor := TextureRect.new()
	blink_minor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blink_minor.texture = blink_texture
	blink_minor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blink_minor.stretch_mode = TextureRect.STRETCH_SCALE
	blink_minor.material = _make_additive_canvas_material()
	blink_minor.modulate = Color(1, 1, 1, 0)
	blink_layer.add_child(blink_minor)
	button.set_meta("blink_minor", blink_minor)

	var name_tag: Label
	if use_small_card:
		art_holder.position = Vector2(4, 2)
		var art_width := deck_card_size.x - 8.0
		var art_height := minf(deck_card_size.y - 4.0, art_width / 0.75)
		art_holder.size = Vector2(art_width, art_height)
		image.texture = _get_small_hand_card_texture(card["character"])
		image.offset_left = 0.0
		image.offset_top = 0.0
		image.offset_right = 0.0
		image.offset_bottom = 0.0

		name_tag = UIFactory.make_label(card["character"].get("code", ""), 12, Color("4c280f"), true)
		name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_tag.anchor_left = 0.12
		name_tag.anchor_right = 0.88
		name_tag.anchor_top = 1.0
		name_tag.anchor_bottom = 1.0
		name_tag.offset_top = -42.0
		name_tag.offset_bottom = -20.0
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_tag.modulate = Color(1, 1, 1, 0.96)
		name_tag.z_index = 3
		art_holder.add_child(name_tag)
	else:
		art_holder.position = Vector2(4, 22)
		art_holder.size = Vector2(deck_card_size.x - 8.0, deck_card_size.y - 28.0 - result_label_height)
		image.texture = _get_hand_card_art_texture(card["character"])
		image.offset_left = -6.0
		image.offset_top = -6.0
		image.offset_right = 6.0
		image.offset_bottom = 0.0

		name_tag = UIFactory.make_label(card["character"].get("code", ""), 13, Color("2c3441"), true)
		name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_tag.anchor_left = 0.0
		name_tag.anchor_right = 1.0
		name_tag.anchor_top = 0.0
		name_tag.anchor_bottom = 0.0
		name_tag.offset_top = 6.0
		name_tag.offset_bottom = 28.0
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_tag.modulate = Color("27303d")
		name_tag.z_index = 3
		button.add_child(name_tag)
	button.set_meta("name_tag", name_tag)
	_configure_deck_card_blink_layout(button)

	if not peek_data.is_empty():
		var is_ally: bool = str(peek_data.get("fate", "")) == "ally"
		var result_label := UIFactory.make_label("队友" if is_ally else "敌人", 11 if use_small_card else 13, Color("4a86e8") if is_ally else Color("de5757"), true)
		result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.z_index = 3
		if use_small_card:
			result_label.anchor_left = 0.18
			result_label.anchor_right = 0.82
			result_label.anchor_top = 0.0
			result_label.anchor_bottom = 0.0
			result_label.offset_top = 12.0
			result_label.offset_bottom = 28.0
			result_label.add_theme_constant_override("outline_size", 2)
			result_label.add_theme_color_override("font_outline_color", Color(0.24, 0.12, 0.05, 0.58))
			art_holder.add_child(result_label)
		else:
			result_label.anchor_left = 0.0
			result_label.anchor_right = 1.0
			result_label.anchor_top = 1.0
			result_label.anchor_bottom = 1.0
			result_label.offset_top = -30.0
			result_label.offset_bottom = -8.0
			button.add_child(result_label)

	# 呼吸动画元数据
	var breath_phase := randf() * TAU
	var breath_speed := randf_range(0.4, 0.55)
	var blink_phase := randf() * TAU
	var blink_speed := randf_range(DECK_CARD_BLINK_SPEED_MIN, DECK_CARD_BLINK_SPEED_MAX)
	button.set_meta("breath_phase", breath_phase)
	button.set_meta("breath_speed", breath_speed)
	button.set_meta("blink_phase", blink_phase)
	button.set_meta("blink_speed", blink_speed)
	_apply_small_card_visual_state(button, selected, false, false)
	_update_deck_card_blink(button, deck_index, 0.0)

	button.pressed.connect(Callable(self, "_on_deck_card_pressed").bind(deck_index))
	return button


func _configure_deck_card_blink_layout(button: Button) -> void:
	if button == null:
		return
	var art_holder: Control = _get_object_meta_value(button, "art_holder") as Control
	var blink_halo: TextureRect = _get_object_meta_value(button, "blink_halo") as TextureRect
	var blink_major: TextureRect = _get_object_meta_value(button, "blink_major") as TextureRect
	var blink_minor: TextureRect = _get_object_meta_value(button, "blink_minor") as TextureRect
	if art_holder == null:
		return

	var art_size := art_holder.size
	var use_small_card: bool = bool(_get_object_meta_value(button, "use_small_card", false))

	if blink_halo != null:
		blink_halo.size = Vector2(art_size.x * 1.18, art_size.y * 1.24)
		blink_halo.position = Vector2(-art_size.x * 0.09, -art_size.y * 0.14)
		blink_halo.pivot_offset = blink_halo.size * 0.5

	var major_size := minf(art_size.x, art_size.y) * (0.28 if use_small_card else 0.22)
	var minor_size := major_size * 0.72

	if blink_major != null:
		blink_major.size = Vector2.ONE * major_size
		blink_major.position = Vector2(art_size.x - major_size * 0.74, -major_size * 0.04)
		blink_major.pivot_offset = blink_major.size * 0.5
		button.set_meta("blink_major_base_pos", blink_major.position)

	if blink_minor != null:
		blink_minor.size = Vector2.ONE * minor_size
		blink_minor.position = Vector2(-minor_size * 0.08, art_size.y * 0.26)
		blink_minor.pivot_offset = blink_minor.size * 0.5
		button.set_meta("blink_minor_base_pos", blink_minor.position)


func _apply_small_card_visual_state(button: Button, selected: bool, hovered: bool, animate: bool = true) -> void:
	if not bool(_get_object_meta_value(button, "use_small_card", false)):
		return
	var portrait: TextureRect = button.get_meta("portrait") as TextureRect
	var name_tag: Label = button.get_meta("name_tag") as Label
	if portrait == null:
		return

	var target_portrait_modulate := Color(1, 1, 1, 0.98)
	var target_name_modulate := Color(1, 1, 1, 0.96)
	if hovered:
		target_portrait_modulate = Color(1.04, 1.03, 1.00, 1.0)
		target_name_modulate = Color(1.0, 0.98, 0.92, 1.0)
	if selected:
		target_portrait_modulate = Color(1.08, 1.05, 1.00, 1.0)
		target_name_modulate = Color(1.0, 0.97, 0.88, 1.0)
	if selected and hovered:
		target_portrait_modulate = Color(1.12, 1.08, 1.02, 1.0)
		target_name_modulate = Color(1.0, 0.98, 0.90, 1.0)

	var existing_tween: Variant = _get_object_meta_value(button, "small_card_visual_tween", null)
	if existing_tween is Tween and is_instance_valid(existing_tween):
		(existing_tween as Tween).kill()

	if not animate:
		portrait.modulate = target_portrait_modulate
		if name_tag != null:
			name_tag.modulate = target_name_modulate
		button.remove_meta("small_card_visual_tween")
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(portrait, "modulate", target_portrait_modulate, 0.16)
	if name_tag != null:
		tween.parallel().tween_property(name_tag, "modulate", target_name_modulate, 0.16)
	button.set_meta("small_card_visual_tween", tween)


func _play_deck_card_focus_burst(button: Button, confirm: bool) -> void:
	if button == null:
		return
	var art_holder: Control = button.get_meta("art_holder") as Control
	if art_holder == null:
		return
	art_holder.pivot_offset = art_holder.size * 0.5
	var existing_tween: Variant = _get_object_meta_value(button, "focus_burst_tween", null)
	if existing_tween is Tween and is_instance_valid(existing_tween):
		(existing_tween as Tween).kill()
	art_holder.scale = Vector2.ONE
	var direction := -1.0 if button.position.x < (deck_grid.size.x * 0.5) else 1.0
	var burst := create_tween()
	burst.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst.set_parallel(true)
	burst.tween_property(art_holder, "scale", Vector2.ONE * (1.15 if confirm else 1.08), 0.11)
	burst.tween_property(art_holder, "rotation_degrees", direction * (5.0 if confirm else 2.6), 0.11)
	burst.chain().tween_property(art_holder, "scale", Vector2.ONE, 0.18)
	burst.parallel().tween_property(art_holder, "rotation_degrees", 0.0, 0.18)
	button.set_meta("focus_burst_tween", burst)


func _has_active_deck_card_motion(button: Button) -> bool:
	if button == null:
		return false
	var motion_tween: Variant = _get_object_meta_value(button, "motion_tween", null)
	return motion_tween is Tween and is_instance_valid(motion_tween)


func _stop_deck_card_motion(button: Button) -> void:
	if button == null:
		return
	var motion_tween: Variant = _get_object_meta_value(button, "motion_tween", null)
	if motion_tween is Tween and is_instance_valid(motion_tween):
		(motion_tween as Tween).kill()
	button.remove_meta("motion_tween")


func _get_deck_card_breath_offset(button: Button, deck_index: int) -> float:
	if button == null or bool(_get_object_meta_value(button, "hovering", false)):
		return 0.0
	var phase: float = _get_object_meta_value(button, "breath_phase", 0.0)
	var amplitude := 2.0
	var phase_scale := 1.0
	if deck_index == selected_deck_index:
		amplitude = 4.0
		phase_scale = 1.5
	return sin(phase * phase_scale) * amplitude


func _get_deck_card_target_z_index(button: Button, deck_index: int) -> int:
	if button == null:
		return 0
	if deck_index == selected_deck_index and bool(_get_object_meta_value(button, "hovering", false)):
		return 110
	if deck_index == selected_deck_index:
		return 90
	if bool(_get_object_meta_value(button, "hovering", false)):
		return 100
	return int(_get_object_meta_value(button, "base_z_index", 40))


func _build_deck_card_motion_target(button: Button, deck_index: int) -> Dictionary:
	var layout_pos: Vector2 = _get_object_meta_value(button, "layout_pos", button.position)
	var layout_scale: Vector2 = _get_object_meta_value(button, "layout_scale", Vector2.ONE)
	var layout_rotation: float = _get_object_meta_value(button, "layout_rotation", button.rotation_degrees)
	var layout_alpha: float = _get_object_meta_value(button, "layout_alpha", button.modulate.a)
	var target_pos := layout_pos + Vector2(0.0, _get_deck_card_breath_offset(button, deck_index))
	var target_scale := layout_scale
	var target_rotation := layout_rotation
	if bool(_get_object_meta_value(button, "hovering", false)):
		var hover_direction: Vector2 = _get_object_meta_value(button, "hover_direction", Vector2.UP)
		if hover_direction.length_squared() <= 0.0001:
			hover_direction = Vector2.UP
		target_pos += hover_direction * DECK_CARD_HOVER_DISTANCE
		target_scale *= DECK_CARD_HOVER_SELECTED_SCALE if deck_index == selected_deck_index else DECK_CARD_HOVER_SCALE
		target_rotation = lerpf(layout_rotation, 0.0, 0.68)
	return {
		"position": target_pos,
		"scale": target_scale,
		"rotation": target_rotation,
		"modulate": Color(1, 1, 1, layout_alpha),
	}


func _refresh_deck_card_motion(button: Button, deck_index: int, animate: bool = true) -> void:
	if button == null:
		return
	var motion_target := _build_deck_card_motion_target(button, deck_index)
	button.z_index = _get_deck_card_target_z_index(button, deck_index)
	_stop_deck_card_motion(button)
	if not animate:
		button.position = motion_target["position"]
		button.scale = motion_target["scale"]
		button.rotation_degrees = motion_target["rotation"]
		button.modulate = motion_target["modulate"]
		return
	var tween := create_tween()
	var use_punch_ease := bool(_get_object_meta_value(button, "hovering", false)) or deck_index == selected_deck_index
	tween.set_trans(Tween.TRANS_BACK if use_punch_ease else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "position", motion_target["position"], DECK_CARD_MOTION_DURATION)
	tween.tween_property(button, "scale", motion_target["scale"], DECK_CARD_MOTION_DURATION)
	tween.tween_property(button, "rotation_degrees", motion_target["rotation"], DECK_CARD_MOTION_DURATION)
	tween.tween_property(button, "modulate", motion_target["modulate"], DECK_CARD_MODULATE_DURATION)
	button.set_meta("motion_tween", tween)
	tween.finished.connect(_on_deck_card_motion_finished.bind(button.get_instance_id(), tween.get_instance_id(), deck_index))


func _refresh_deck_card_state(button: Button, deck_index: int, animate: bool = true) -> void:
	if button == null or deck_index < 0 or deck_index >= state.deck.size():
		return
	var is_selected: bool = deck_index == selected_deck_index
	var is_hovered: bool = bool(_get_object_meta_value(button, "hovering", false))
	var peek_data: Dictionary = _get_peek_data(deck_index)
	var card: Dictionary = state.deck[deck_index]
	card_helper.apply_deck_card_button_styles(button, card["character"], is_selected, peek_data)
	_apply_small_card_visual_state(button, is_selected, is_hovered, animate)
	_refresh_deck_card_motion(button, deck_index, animate)


func _refresh_action_buttons() -> void:
	if secondary_button == null:
		return
	secondary_button.visible = false
	secondary_button.text = "↩"
	if selected_deck_index < 0 or selected_deck_index >= state.deck.size():
		return

	var card: Dictionary = state.deck[selected_deck_index]
	var peek_data: Dictionary = _get_peek_data(selected_deck_index)
	if not peek_data.is_empty():
		if peek_data.get("mode", "") == "think":
			secondary_button.visible = true
			secondary_button.disabled = busy or state.phase != "battle_idle"
			secondary_button.tooltip_text = "放回 %s 并结束回合" % card["character"]["code"]
		return


func _get_peek_data(deck_index: int) -> Dictionary:
	if not peeked_cards.has(deck_index):
		return {}
	var peek_data: Dictionary = peeked_cards[deck_index]
	if not _is_peek_entry_valid(peek_data):
		peeked_cards.erase(deck_index)
		return {}
	return peek_data


func _is_peek_entry_valid(peek_data: Dictionary) -> bool:
	if peek_data.is_empty():
		return false
	if not bool(peek_data.get("ephemeral_forced", false)):
		return true
	return state.forced_next_fate != null and int(peek_data.get("forced_serial", -1)) == forced_next_fate_serial


func _queue_forced_next_fate(fate: String) -> void:
	forced_next_fate_serial += 1
	state.forced_next_fate = fate
	_clear_peek_cache()


func _clear_forced_next_fate() -> void:
	state.forced_next_fate = null
	_clear_peek_cache()


func _should_lock_peek_to_card() -> bool:
	return state.forced_next_fate == null


func _remember_peek(deck_index: int, fate: String, mode: String, lock_to_card: bool = true) -> void:
	if lock_to_card and deck_index >= 0 and deck_index < state.deck.size():
		state.deck[deck_index]["locked_fate"] = fate
	var peek_data := {
		"fate": fate,
		"mode": mode,
	}
	if not lock_to_card:
		peek_data["ephemeral_forced"] = true
		peek_data["forced_serial"] = forced_next_fate_serial
	peeked_cards[deck_index] = peek_data


func _clear_peek_cache() -> void:
	var next_peeks := {}
	for deck_index_variant in peeked_cards.keys():
		var deck_index: int = int(deck_index_variant)
		if deck_index < 0 or deck_index >= state.deck.size():
			continue
		var card: Dictionary = state.deck[deck_index]
		if card["revealed"]:
			card.erase("locked_fate")
			continue
		var peek_data: Dictionary = peeked_cards[deck_index]
		if not _is_peek_entry_valid(peek_data):
			continue
		next_peeks[deck_index] = peek_data
		if bool(peek_data.get("ephemeral_forced", false)):
			continue
		if not card.has("locked_fate"):
			card["locked_fate"] = next_peeks[deck_index].get("fate", "")
	peeked_cards = next_peeks


func _get_selected_card_status_text(card: Dictionary) -> String:
	var peek_data: Dictionary = _get_peek_data(selected_deck_index)
	if not peek_data.is_empty():
		var label := "窥视结果" if peek_data.get("mode", "") == "peek" else "三思结果"
		var fate_text := "伙伴" if peek_data.get("fate", "") == "ally" else "敌人"
		return "%s：%s" % [label, fate_text]
	return "◌"


func _update_deck_card_selection(animate: bool = true) -> void:
	_layout_deck_fan(animate)


func _deferred_layout_deck_fan() -> void:
	if visible_deck_indices.is_empty():
		return
	_layout_deck_fan(false)


func _on_deck_area_resized() -> void:
	if visible_deck_indices.is_empty():
		return
	call_deferred("_update_deck_view")


func _layout_deck_fan(animate: bool = true) -> void:
	var count := visible_deck_indices.size()
	if count == 0:
		return
	var card_size: Vector2 = deck_card_size
	var container_width: float = deck_grid.size.x
	var container_height: float = deck_grid.size.y
	if container_width <= 0.0 or container_height <= 0.0:
		return

	var layout_width: float = minf(maxf(container_width - 24.0, card_size.x + 20.0), deck_fan_max_span)
	var center_x: float = container_width * 0.5 + deck_row_center_bias
	var stride_ratio: float = _get_deck_card_stride_ratio(count)
	var desired_span: float = minf(layout_width, card_size.x * (1.0 + stride_ratio * float(maxi(0, count - 1))))
	var fan_angle: float = clampf(20.0 + float(maxi(0, count - 1)) * 2.2, 24.0, 46.0)
	var half_angle_rad: float = deg_to_rad(fan_angle * 0.5)
	var fan_radius: float = maxf(
		(desired_span - card_size.x) / maxf(2.0 * sin(half_angle_rad), 0.18),
		card_size.x * 3.6
	)
	var base_y: float = clampf(container_height - card_size.y - maxf(16.0, card_size.y * 0.06), 16.0, 52.0)
	var max_arc_drop: float = maxf((1.0 - cos(half_angle_rad)) * fan_radius, 1.0)
	var desired_arc_drop: float = clampf(
		card_size.y * (0.14 + float(maxi(0, count - 1)) * 0.008),
		card_size.y * 0.14,
		card_size.y * 0.26
	)
	var vertical_scale: float = desired_arc_drop / max_arc_drop
	var fan_center := Vector2(center_x, container_height * 1.24)

	for vis_idx in range(count):
		var deck_index: int = visible_deck_indices[vis_idx]
		var button: Button = deck_card_nodes.get(deck_index) as Button
		if button == null:
			continue

		var is_selected: bool = deck_index == selected_deck_index
		var t: float = 0.5 if count == 1 else float(vis_idx) / float(count - 1)
		var angle_deg: float = lerpf(-fan_angle * 0.5, fan_angle * 0.5, t)
		var angle_rad: float = deg_to_rad(angle_deg)
		var target_x: float = center_x + sin(angle_rad) * fan_radius - card_size.x / 2.0
		var stable_y: float = base_y + (1.0 - cos(angle_rad)) * fan_radius * vertical_scale
		var target_y: float = stable_y
		var target_rotation: float = angle_deg * 0.66
		var target_scale_factor: float = 1.0
		var target_scale: Vector2 = Vector2.ONE * target_scale_factor
		var target_alpha: float = 0.86

		if is_selected:
			target_y -= card_size.y * 0.30
			target_rotation = 0.0
			target_scale = Vector2.ONE * 1.14
			target_alpha = 1.0

		var target_pos: Vector2 = Vector2(target_x, target_y)
		button.size = card_size
		button.custom_minimum_size = card_size
		button.pivot_offset = card_size / 2.0

		var card_center := Vector2(target_x + card_size.x * 0.5, target_y + card_size.y * 0.56)
		var hover_direction := (card_center - fan_center).normalized()
		if hover_direction.length_squared() <= 0.0001:
			hover_direction = Vector2.UP

		# 存储 base / layout 数据，后续统一由单卡 motion tween 落到目标值。
		button.set_meta("base_x", target_pos.x)
		button.set_meta("base_y", target_pos.y)
		button.set_meta("drawer_limit_y", stable_y)
		button.set_meta("base_scale", target_scale)
		button.set_meta("base_z_index", 40 + vis_idx)
		button.set_meta("layout_pos", target_pos)
		button.set_meta("layout_scale", target_scale)
		button.set_meta("layout_rotation", target_rotation)
		button.set_meta("layout_alpha", target_alpha)
		button.set_meta("hover_direction", hover_direction)
		_refresh_deck_card_state(button, deck_index, animate)

	call_deferred("_refresh_info_drawer_bounds")


func _get_deck_cards_top_global_y() -> float:
	var top_y := INF
	var deck_origin_y := 0.0
	if deck_grid != null:
		deck_origin_y = deck_grid.get_global_rect().position.y
	for deck_index_variant in visible_deck_indices:
		var deck_index: int = int(deck_index_variant)
		var button: Button = deck_card_nodes.get(deck_index) as Button
		if button == null or not button.visible:
			continue
		var stable_y := float(button.get_meta("drawer_limit_y", button.position.y))
		top_y = minf(top_y, deck_origin_y + stable_y)
	if top_y == INF and deck_grid != null:
		var deck_rect := deck_grid.get_global_rect()
		if deck_rect.size.y > 0.0:
			top_y = deck_rect.position.y
	return top_y


func _play_deck_card_commit(deck_index: int) -> void:
	var button: Button = deck_card_nodes.get(deck_index) as Button
	if button == null:
		return
	_stop_deck_card_motion(button)

	var portrait: TextureRect = button.get_meta("portrait") as TextureRect
	var base_pos: Vector2 = button.position
	var base_scale: Vector2 = button.scale
	var base_rotation: float = button.rotation_degrees
	var base_modulate: Color = button.modulate
	var portrait_modulate := portrait.modulate if portrait != null else Color.WHITE
	button.disabled = true

	var launch := create_tween()
	launch.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	launch.set_parallel(true)
	launch.tween_property(button, "position:y", base_pos.y - 18.0, 0.10)
	launch.tween_property(button, "scale", base_scale * 1.08, 0.10)
	launch.tween_property(button, "rotation_degrees", 0.0, 0.08)
	await launch.finished

	var flip_in := create_tween()
	flip_in.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	flip_in.set_parallel(true)
	flip_in.tween_property(button, "scale:x", 0.10, 0.12)
	flip_in.tween_property(button, "modulate", Color(1.10, 1.06, 0.98, 1.0), 0.12)
	if portrait != null:
		flip_in.tween_property(portrait, "modulate", Color(1.18, 1.12, 1.04, 0.92), 0.10)
	await flip_in.finished

	await get_tree().create_timer(0.05).timeout

	var flip_out := create_tween()
	flip_out.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flip_out.set_parallel(true)
	# 修复：使用等比缩放，避免拉伸
	flip_out.tween_property(button, "scale", base_scale * 1.10, 0.16)
	flip_out.tween_property(button, "modulate", Color(1.14, 1.10, 1.0, 1.0), 0.16)
	if portrait != null:
		flip_out.tween_property(portrait, "modulate", Color(1.26, 1.20, 1.08, 1.0), 0.14)
	await flip_out.finished

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.set_parallel(true)
	settle.tween_property(button, "scale", base_scale, 0.10)
	settle.tween_property(button, "position:y", base_pos.y - 12.0, 0.10)
	settle.tween_property(button, "modulate", Color(1.08, 1.04, 0.98, 1.0), 0.10)
	await settle.finished

	var depart := create_tween()
	depart.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	depart.set_parallel(true)
	depart.tween_property(button, "position", base_pos + Vector2(0, -34), 0.16)
	depart.tween_property(button, "scale", base_scale * 0.92, 0.16)
	depart.tween_property(button, "modulate", Color(1.08, 1.04, 0.98, 0.0), 0.16)
	await depart.finished

	button.visible = false
	button.position = base_pos
	button.scale = base_scale
	button.rotation_degrees = base_rotation
	button.modulate = base_modulate
	button.disabled = false
	if portrait != null:
		portrait.modulate = portrait_modulate


func _spotlight_target_position() -> Vector2:
	if spotlight_burst == null:
		return Vector2.ZERO
	if active_reveal_card != null and active_reveal_card.is_inside_tree():
		var card_center := active_reveal_card.get_global_rect().get_center()
		var parent_item := spotlight_burst.get_parent() as CanvasItem
		return _canvas_item_global_to_local(parent_item, card_center) - spotlight_burst.size * 0.5
	if seat_layer != null:
		return seat_layer.size * 0.5 - spotlight_burst.size * 0.5
	return Vector2.ZERO


func _pulse_stage_lights(peak: float = 0.34, in_time: float = 0.18, out_time: float = 0.62) -> void:
	if stage_light_material == null:
		return
	if stage_light_tween != null and stage_light_tween.is_valid():
		stage_light_tween.kill()
	var current_boost := float(stage_light_material.get_shader_parameter("pulse_boost"))
	stage_light_tween = create_tween()
	stage_light_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	stage_light_tween.tween_method(_set_stage_light_pulse_boost, current_boost, peak, in_time)
	stage_light_tween.tween_method(_set_stage_light_pulse_boost, peak, 0.0, out_time)


func _play_spotlight_focus(color: Color, peak_alpha: float, in_time: float, hold_time: float = 0.0, out_time: float = 0.0) -> void:
	if spotlight_burst == null:
		return
	_pulse_stage_lights(clampf(peak_alpha * 0.92, 0.18, 0.72), maxf(in_time * 0.65, 0.12), maxf(out_time, 0.48))
	spotlight_burst.position = _spotlight_target_position()
	if spotlight_tween != null and spotlight_tween.is_valid():
		spotlight_tween.kill()
	spotlight_tween = create_tween()
	spotlight_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var start_color := spotlight_burst.modulate
	spotlight_tween.tween_method(_set_spotlight_focus_progress.bind(start_color, color, peak_alpha), 0.0, 1.0, in_time)
	if hold_time > 0.0:
		spotlight_tween.tween_interval(hold_time)
	if out_time > 0.0:
		spotlight_tween.tween_property(spotlight_burst, "modulate:a", 0.0, out_time)


func _fade_spotlight(out_time: float = 0.40) -> void:
	if spotlight_burst == null:
		return
	if spotlight_tween != null and spotlight_tween.is_valid():
		spotlight_tween.kill()
	spotlight_tween = create_tween()
	spotlight_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	spotlight_tween.tween_property(spotlight_burst, "modulate:a", 0.0, out_time)


func _animate_reveal_preview(character: Dictionary, fate_text: String) -> void:
	var motion_target: Control = _get_reveal_motion_target()
	if motion_target == null:
		_update_reveal_preview(character, fate_text)
		return

	_update_reveal_preview(character, fate_text, "", false)
	motion_target.scale = Vector2.ONE
	motion_target.rotation_degrees = 0.0
	motion_target.modulate = Color.WHITE

	# 预备：整张卡先压低重心，准备翻面
	var anticipation := create_tween()
	anticipation.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	anticipation.set_parallel(true)
	anticipation.tween_property(motion_target, "scale", Vector2(0.96, 1.03), 0.07)
	anticipation.tween_property(motion_target, "rotation_degrees", -2.0, 0.07)
	anticipation.tween_property(motion_target, "modulate", Color(0.98, 0.95, 0.90, 1.0), 0.07)
	await anticipation.finished

	# 第一段：像绕 Y 轴转到侧面，整张卡压成一条窄边
	var edge_flip := create_tween()
	edge_flip.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	edge_flip.set_parallel(true)
	edge_flip.tween_property(motion_target, "scale", Vector2(0.08, 1.02), 0.11)
	edge_flip.tween_property(motion_target, "rotation_degrees", 0.0, 0.11)
	edge_flip.tween_property(motion_target, "modulate", Color(0.90, 0.86, 0.80, 1.0), 0.11)
	await edge_flip.finished

	# 第二段：从另一侧弹开，模拟整张卡翻回正面
	var flip_return := create_tween()
	flip_return.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flip_return.set_parallel(true)
	flip_return.tween_property(motion_target, "scale", Vector2(1.10, 1.04), 0.16)
	flip_return.tween_property(motion_target, "rotation_degrees", 1.8, 0.16)
	flip_return.tween_property(motion_target, "modulate", Color(1.05, 1.01, 0.96, 1.0), 0.13)
	await flip_return.finished

	# 弹性展开
	var impact := create_tween()
	impact.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact.set_parallel(true)
	impact.tween_property(motion_target, "scale", Vector2(1.04, 1.02), 0.10)
	impact.tween_property(motion_target, "rotation_degrees", 0.8, 0.10)
	impact.tween_property(motion_target, "modulate", Color(1.02, 1.0, 0.97, 1.0), 0.10)
	await impact.finished

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.set_parallel(true)
	settle.tween_property(motion_target, "scale", Vector2.ONE, 0.10)
	settle.tween_property(motion_target, "rotation_degrees", 0.0, 0.10)
	settle.tween_property(motion_target, "modulate", Color.WHITE, 0.10)
	await settle.finished


func _play_fate_reveal_glow(fate: String) -> void:
	var motion_target: Control = _get_reveal_motion_target()
	if motion_target == null:
		return

	# ── 着色器命运揭晓光效 ──
	if fate_reveal_overlay != null:
		fate_reveal_overlay.visible = false
	var card_overlay := _create_reveal_shader_overlay()
	var reveal_overlay: Control = card_overlay if card_overlay != null else fate_reveal_overlay
	var reveal_tween := ShaderEffects.animate_fate_reveal(self, reveal_overlay, fate)
	if card_overlay != null and reveal_tween != null:
		reveal_tween.tween_callback(_queue_free_instance.bind(card_overlay.get_instance_id()))

	# ── 暗角氛围响应 ──
	if fate == "ally":
		ShaderEffects.animate_warmth_pulse(self, vignette_material)
	else:
		ShaderEffects.animate_cold_pulse(self, vignette_material)

	# 保留边框样式变化和震屏效果
	var glow_color := Color("4a9eff") if fate == "ally" else Color("ff3a3a")

	var reveal_frame := _get_reveal_visual_frame()
	var original_style := _get_frame_base_style(reveal_frame)
	if reveal_frame != null and original_style != null:
		var glow_style := original_style.duplicate()
		glow_style.border_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.88)
		glow_style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.34)
		glow_style.shadow_size = 24
		glow_style.shadow_offset = Vector2.ZERO
		glow_style.border_width_left = 3
		glow_style.border_width_top = 3
		glow_style.border_width_right = 3
		glow_style.border_width_bottom = 3
		reveal_frame.add_theme_stylebox_override("panel", glow_style)
		var reset := create_tween()
		reset.tween_interval(0.8)
		reset.tween_callback(_restore_reveal_frame_after_glow.bind(reveal_frame.get_instance_id(), fate, original_style))

	var punch := create_tween()
	punch.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch.set_parallel(true)
	punch.tween_property(motion_target, "scale", Vector2(1.18, 1.10), 0.10)
	punch.tween_property(motion_target, "rotation_degrees", -3.2 if fate == "enemy" else 2.4, 0.10)
	await punch.finished
	_trigger_hitstop(0.032, 0.12 if fate == "enemy" else 0.18, 0.10)

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.set_parallel(true)
	settle.tween_property(motion_target, "scale", Vector2.ONE, 0.12)
	settle.tween_property(motion_target, "rotation_degrees", 0.0, 0.12)
	_play_screen_shake(18.0 if fate == "enemy" else 8.0, 0.10, 4 if fate == "enemy" else 3, 0.60)


func _play_selected_card_transition(deck_index: int, dc: Dictionary) -> Control:
	var button: Button = deck_card_nodes.get(deck_index) as Button
	if button == null:
		return null
	_stop_deck_card_motion(button)
	_play_deck_card_focus_burst(button, true)
	_play_sfx("spotlight_reveal")

	var lift := create_tween()
	lift.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lift.set_parallel(true)
	lift.tween_property(button, "position:y", button.position.y - 42.0, 0.14)
	lift.tween_property(button, "scale", button.scale * 1.16, 0.14)
	lift.tween_property(button, "rotation_degrees", 0.0, 0.12)
	await lift.finished

	var transition_card := _create_transition_card(dc["character"])
	if transition_card == null:
		return null
	active_reveal_card = transition_card
	floating_effect_layer.add_child(transition_card)
	_refresh_reveal_preview_visibility()
	var button_rect := button.get_global_rect()
	transition_card.global_position = button_rect.position + button_rect.size * 0.5 - transition_card.size * 0.5
	transition_card.scale = Vector2.ONE * 0.78
	transition_card.modulate = Color(1, 1, 1, 0.0)
	button.visible = false

	var start_pos := transition_card.global_position
	var target_center := _get_reveal_card_target_center()
	var end_pos := target_center - transition_card.size * 0.5
	var control_point := Vector2((start_pos.x + end_pos.x) * 0.5, minf(start_pos.y, end_pos.y) - 220.0)
	var move := create_tween()
	move.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	move.tween_method(_set_transition_card_flight_progress.bind(transition_card.get_instance_id(), start_pos, control_point, end_pos), 0.0, 1.0, 0.42)
	move.parallel().tween_property(transition_card, "scale", Vector2.ONE * 1.04, 0.42)
	move.parallel().tween_property(transition_card, "modulate", Color.WHITE, 0.10)

	var body: Control = transition_card.get_meta("body") as Control
	if body != null:
		body.scale = Vector2.ONE * 0.82
		body.rotation_degrees = -4.0
		var land := create_tween()
		land.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		land.set_parallel(true)
		land.tween_property(body, "scale", Vector2.ONE * 1.08, 0.22)
		land.tween_property(body, "rotation_degrees", 2.0, 0.22)
		land.chain().tween_property(body, "scale", Vector2.ONE, 0.14)
		land.parallel().tween_property(body, "rotation_degrees", 0.0, 0.14)

	await move.finished
	transition_card.global_position = _get_reveal_card_target_center() - transition_card.size * 0.5
	transition_card.scale = Vector2.ONE
	_trigger_hitstop(0.034, 0.10, 0.12)
	_play_screen_shake(14.0, 0.10, 4, 0.58)
	_dock_active_reveal_card_to_host()
	return transition_card


func _create_transition_card(character: Dictionary) -> Control:
	var card := Control.new()
	var target_size := Vector2(180, 240)
	if reveal_texture != null and reveal_texture.custom_minimum_size != Vector2.ZERO:
		target_size = reveal_texture.custom_minimum_size
	card.custom_minimum_size = target_size
	card.size = card.custom_minimum_size
	card.pivot_offset = card.size * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = 120

	var body := Control.new()
	body.size = card.size
	body.pivot_offset = card.size * 0.5
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(body)

	var ally_visual := card_helper.create_reveal_card_visual(character, card.size, "ally")
	if ally_visual == null:
		ally_visual = card_helper.create_card_visual(character, card.size, true, "ally", false)
	if ally_visual == null:
		card.queue_free()
		return null
	body.add_child(ally_visual)
	var enemy_visual := card_helper.create_reveal_card_visual(character, card.size, "enemy")
	if enemy_visual == null:
		enemy_visual = card_helper.create_card_visual(character, card.size, true, "enemy", false)
	if enemy_visual == null:
		card.queue_free()
		return null
	enemy_visual.visible = false
	body.add_child(enemy_visual)

	var ally_frame: PanelContainer = ally_visual.get_meta("frame") as PanelContainer
	var enemy_frame: PanelContainer = enemy_visual.get_meta("frame") as PanelContainer

	card.set_meta("body", body)
	card.set_meta("ally_visual", ally_visual)
	card.set_meta("enemy_visual", enemy_visual)
	card.set_meta("ally_frame", ally_frame)
	card.set_meta("enemy_frame", enemy_frame)
	_set_transition_card_face(card, "ally")
	return card


func _set_transition_card_face(card: Control, fate_variant: String) -> void:
	if card == null:
		return
	var display_variant := _normalize_card_fate_variant(fate_variant)
	var ally_visual: Control = card.get_meta("ally_visual") as Control
	var enemy_visual: Control = card.get_meta("enemy_visual") as Control
	var target_visual := ally_visual if display_variant == "ally" else enemy_visual
	if ally_visual != null:
		ally_visual.visible = display_variant == "ally"
	if enemy_visual != null:
		enemy_visual.visible = display_variant == "enemy"
	var target_frame: PanelContainer = _get_object_meta_value(card, "%s_frame" % display_variant) as PanelContainer
	if target_frame != null:
		card.set_meta("frame", target_frame)
	elif card.has_meta("frame"):
		card.remove_meta("frame")
	var target_portrait: TextureRect = _get_object_meta_value(target_visual, "portrait") as TextureRect
	if target_portrait != null:
		card.set_meta("portrait", target_portrait)
	elif card.has_meta("portrait"):
		card.remove_meta("portrait")
	var target_glow: Variant = _get_object_meta_value(target_visual, "glow")
	if target_glow != null:
		card.set_meta("glow", target_glow)
	elif card.has_meta("glow"):
		card.remove_meta("glow")
	card.set_meta("current_fate_variant", display_variant)


func _play_reveal_suspense_spin(final_fate: String, duration: float = -1.0) -> void:
	if active_reveal_card == null:
		return
	var body: Control = active_reveal_card.get_meta("body") as Control
	if body == null:
		body = active_reveal_card
	body.rotation_degrees = 0.0
	body.scale = Vector2.ONE
	active_reveal_card.scale = Vector2.ONE
	_set_transition_card_face(active_reveal_card, "ally")

	var total_duration := 0.0
	for segment_duration in REVEAL_SUSPENSE_BASE_DURATIONS:
		total_duration += float(segment_duration)
	var duration_scale := 1.0
	if duration > 0.0 and total_duration > 0.0:
		duration_scale = duration / total_duration

	var flip_targets := ["enemy", "ally", "enemy", "ally", "enemy", _normalize_card_fate_variant(final_fate)]
	for index in range(flip_targets.size()):
		var target_variant := str(flip_targets[index])
		var flip_duration: float = float(REVEAL_SUSPENSE_BASE_DURATIONS[index]) * duration_scale
		var close := create_tween()
		close.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		close.set_parallel(true)
		close.tween_property(body, "scale", Vector2(0.04, 1.08), flip_duration * 0.42)
		close.tween_property(body, "rotation_degrees", -4.0 if target_variant == "enemy" else 3.2, flip_duration * 0.42)
		await close.finished
		_set_transition_card_face(active_reveal_card, target_variant)
		var open := create_tween()
		open.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		open.set_parallel(true)
		open.tween_property(body, "scale", Vector2(1.10, 1.02), flip_duration * 0.58)
		open.tween_property(body, "rotation_degrees", 2.2 if target_variant == "enemy" else -1.8, flip_duration * 0.58)
		await open.finished
		if index == flip_targets.size() - 1:
			_trigger_hitstop(0.028, 0.10, 0.10)
			_play_screen_shake(10.0 if target_variant == "ally" else 16.0, 0.10, 4, 0.62)

	body.rotation_degrees = 0.0
	body.scale = Vector2.ONE
	active_reveal_card.scale = Vector2.ONE
	_set_transition_card_face(active_reveal_card, final_fate)


func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return fx_helper._quadratic_bezier(p0, p1, p2, t)


func _play_active_reveal_pulse(fate: String) -> void:
	if active_reveal_card == null:
		return
	_set_transition_card_face(active_reveal_card, fate)
	var glow_color := Color("4a9eff") if fate == "ally" else Color("ff6458")

	# ── 聚光灯切换为命运色,迸发后维持 ──
	_play_spotlight_focus(glow_color, 0.72, 0.10, 0.50, 0.0)

	# ── 卡牌边框同步变色 ──
	var frame: PanelContainer = active_reveal_card.get_meta("frame") as PanelContainer
	if frame != null:
		var frame_style := frame.get_theme_stylebox("panel") as StyleBoxFlat
		if frame_style != null:
			var new_style := frame_style.duplicate() as StyleBoxFlat
			new_style.border_color = glow_color.lightened(0.2)
			new_style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.35)
			new_style.shadow_size = 22
			frame.add_theme_stylebox_override("panel", new_style)

	# ── 卡牌弹跳脉冲 ──
	var pulse := create_tween()
	pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.set_parallel(true)
	pulse.tween_property(active_reveal_card, "scale", Vector2.ONE * 1.16, 0.16)
	pulse.tween_property(active_reveal_card, "rotation_degrees", 3.2 if fate == "ally" else -4.0, 0.16)
	await pulse.finished
	_trigger_hitstop(0.062, 0.02 if fate == "enemy" else 0.06, 0.16)

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.set_parallel(true)
	settle.tween_property(active_reveal_card, "scale", Vector2.ONE, 0.16)
	settle.tween_property(active_reveal_card, "rotation_degrees", 0.0, 0.16)
	_play_screen_shake(24.0 if fate == "enemy" else 12.0, 0.14, 5 if fate == "enemy" else 4, 0.66)


# ── 命运裁决条 ── 翻牌后卡牌上方弹出伙伴/敌人横幅
func _show_fate_verdict_banner(fate: String, character_code: String) -> void:
	var is_ally := fate == "ally"
	var banner := PanelContainer.new()
	banner.z_index = 200  # 确保在卡牌之上
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color("4a9eff") if is_ally else Color("ff3a3a")
	banner_style.bg_color.a = 0.0  # 初始透明
	banner_style.border_width_bottom = 3
	banner_style.border_color = Color("7fcdf2").lightened(0.3) if is_ally else Color("ff9b84").lightened(0.2)
	banner_style.corner_radius_top_left = 8
	banner_style.corner_radius_top_right = 8
	banner_style.corner_radius_bottom_left = 8
	banner_style.corner_radius_bottom_right = 8
	banner_style.shadow_color = Color(banner_style.bg_color.r, banner_style.bg_color.g, banner_style.bg_color.b, 0.30)
	banner_style.shadow_size = 18
	banner.add_theme_stylebox_override("panel", banner_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	banner.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var icon := UIFactory.make_label("◉" if is_ally else "◆", 28, Color.WHITE, true)
	hbox.add_child(icon)

	var verdict_text := "伙伴" if is_ally else "敌人"
	var label := UIFactory.make_label("%s  %s" % [verdict_text, character_code], 26, Color.WHITE, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(label)

	# 放到 floating_effect_layer，定位在翻出卡牌正上方
	floating_effect_layer.add_child(banner)
	banner.size = Vector2(240, 52)
	banner.pivot_offset = banner.size * 0.5

	# 以 active_reveal_card 的真实中心和顶部为锚点，保证横幅与翻牌卡严格对齐
	var card_rect := active_reveal_card.get_global_rect() if active_reveal_card != null else Rect2(size * 0.5 - Vector2(120, 140), Vector2(240, 280))
	var card_center := card_rect.get_center()
	banner.global_position = Vector2(card_center.x - banner.size.x * 0.5, card_rect.position.y - banner.size.y - 14.0)

	# 入场动画
	banner.position.y -= 30.0
	banner.scale = Vector2(0.7, 0.7)
	banner.modulate = Color(1, 1, 1, 0.0)

	var enter := create_tween()
	enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.set_parallel(true)
	enter.tween_property(banner, "position:y", banner.position.y + 30.0, 0.30)
	enter.tween_property(banner, "scale", Vector2.ONE, 0.28)
	enter.tween_property(banner, "modulate", Color(1, 1, 1, 1.0), 0.18)

	var bg_enter := create_tween()
	bg_enter.tween_property(banner_style, "bg_color:a", 0.88, 0.18)

	await enter.finished

	# 停留展示
	await get_tree().create_timer(0.55).timeout

	# 退场动画
	var exit := create_tween()
	exit.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit.set_parallel(true)
	exit.tween_property(banner, "position:y", banner.position.y - 36.0, 0.30)
	exit.tween_property(banner, "modulate", Color(1, 1, 1, 0.0), 0.26)
	exit.tween_property(banner_style, "bg_color:a", 0.0, 0.26)

	await exit.finished
	banner.queue_free()


func _fly_active_card_to_seat(seat_id: String) -> void:
	if active_reveal_card == null:
		return
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return

	_hide_active_reveal_shader_overlay()
	_promote_active_reveal_card_to_floating_layer()
	_fade_spotlight(0.42)

	var start_pos := active_reveal_card.global_position
	var seat_center := _get_seat_world_center(seat_id)
	if seat_center == Vector2.ZERO:
		return
	var target_scale_factor := 0.38
	if active_reveal_card.size.x > 0.0 and active_reveal_card.size.y > 0.0:
		var seat_scale_x := seat.size.x / active_reveal_card.size.x
		var seat_scale_y := seat.size.y / active_reveal_card.size.y
		target_scale_factor = clampf(minf(seat_scale_x, seat_scale_y) * 0.98, 0.34, 0.90)
	var end_pos := seat_center - active_reveal_card.size * 0.5
	var control_point := Vector2((start_pos.x + end_pos.x) * 0.5, minf(start_pos.y, end_pos.y) - 72.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if active_reveal_card != null:
		active_reveal_card.modulate = Color.WHITE
	tween.tween_method(_set_active_reveal_card_flight_progress.bind(start_pos, control_point, end_pos), 0.0, 1.0, 0.34)
	tween.parallel().tween_property(active_reveal_card, "scale", Vector2.ONE * target_scale_factor, 0.34)
	await tween.finished
	if active_reveal_card != null:
		active_reveal_card.global_position = end_pos
		active_reveal_card.modulate = Color.WHITE

	# ── 入席前淡出收束，避免根节点 dissolve 产生矩形色块 ──
	if active_reveal_card != null:
		var settle_out := create_tween()
		settle_out.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		settle_out.set_parallel(true)
		settle_out.tween_property(active_reveal_card, "scale", Vector2.ONE * maxf(target_scale_factor * 0.82, 0.20), 0.18)
		settle_out.tween_property(active_reveal_card, "modulate", Color(1.08, 1.04, 0.98, 0.0), 0.18)
		await settle_out.finished

	# 席位头像渐入弹跳（在 _animate_seat_entry 中已有，增强弹性）
	_clear_active_reveal_card()


func _prepare_seat_entry_hidden(seat_id: String, ally_uid: int = -1) -> void:
	var avatar_container := _get_seat_actor_node(seat_id, ally_uid)
	if avatar_container == null:
		return
	var seat: Control = seat_nodes.get(seat_id) as Control
	var background: TextureRect = seat.get_meta("background") as TextureRect
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	var target_pos: Vector2 = avatar_container.get_meta("target_pos", avatar_container.position)
	var avatar_color := avatar_container.modulate
	var background_color := background.modulate if background != null else Color.WHITE
	var ring_color := border_ring.modulate if border_ring != null else Color.WHITE
	avatar_container.position = target_pos
	avatar_container.scale = Vector2.ZERO
	avatar_container.modulate = Color(avatar_color.r, avatar_color.g, avatar_color.b, 0.0)
	if background != null:
		background.modulate = Color(background_color.r, background_color.g, background_color.b, 0.0)
	if border_ring != null:
		border_ring.visible = true
		border_ring.modulate = Color(ring_color.r, ring_color.g, ring_color.b, 0.0)


func _discard_active_card(offset: Vector2 = Vector2(0, -120)) -> void:
	if active_reveal_card == null:
		return
	_hide_active_reveal_shader_overlay()
	_fade_spotlight(0.30)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(active_reveal_card, "global_position", active_reveal_card.global_position + offset, 0.24)
	tween.tween_property(active_reveal_card, "scale", Vector2.ONE * 0.56, 0.24)
	tween.tween_property(active_reveal_card, "modulate", Color(1.0, 0.96, 0.92, 0.0), 0.20)
	await tween.finished
	_clear_active_reveal_card()


func _clear_active_reveal_card() -> void:
	if active_reveal_card != null:
		active_reveal_card.queue_free()
		active_reveal_card = null
	if fate_reveal_overlay != null:
		fate_reveal_overlay.visible = false
	_refresh_reveal_preview_visibility()


func _animate_seat_entry(seat_id: String, ally_uid: int = -1) -> void:
	await fx_helper.animate_seat_entry(seat_id, ally_uid)


func _animate_seat_departure(seat_id: String, ally_uid: int = -1, departure_offset: Vector2 = Vector2(0.0, -18.0)) -> void:
	await fx_helper.animate_seat_departure(seat_id, ally_uid, departure_offset)


func _get_control_world_center(control: Control) -> Vector2:
	return fx_helper.get_control_world_center(control)


func _to_layer_local_point(layer: Control, world_point: Vector2) -> Vector2:
	return fx_helper.to_layer_local_point(layer, world_point)


func _get_player_stage_hit_world_center() -> Vector2:
	return fx_helper.get_player_stage_hit_world_center()


func _get_attack_flight_duration(attacker_seat: String, target_seat: String, ally_uid: int = -1) -> float:
	return fx_helper.get_attack_flight_duration(attacker_seat, target_seat, ally_uid)


func _play_attack_effect(attacker_seat: String, target_seat: String, damage: int = 0, ally_uid: int = -1) -> void:
	fx_helper.play_attack_effect(attacker_seat, target_seat, damage, ally_uid)


func _spawn_impact_burst(world_position: Vector2, base_color: Color, is_block: bool = false) -> void:
	fx_helper.spawn_impact_burst(world_position, base_color, is_block)


func _spawn_undying_burst(world_position: Vector2) -> void:
	fx_helper.spawn_undying_burst(world_position)


func _animate_player_undying_rebound() -> void:
	fx_helper.animate_player_undying_rebound()


func _show_undying_trigger_banner(world_position: Vector2) -> void:
	fx_helper.show_undying_trigger_banner(world_position)


func _get_seat_world_center(seat_id: String, ally_uid: int = -1) -> Vector2:
	return fx_helper.get_seat_world_center(seat_id, ally_uid)


func _present_choice(title: String, body: String, options: Array, context: Dictionary = {}):
	_set_replace_modal_active(false)
	_clear_children(modal_buttons)
	_hide_modal_option_tooltip()
	modal_title.text = title
	_set_modal_body_text(body)
	var option_count := options.size()
	var detail_text := str(context.get("detail_text", ""))
	var detail_ally: Dictionary = context.get("detail_ally", {})
	var inline_hover_detail := bool(context.get("inline_hover_detail", false))
	var detail_layout := str(context.get("detail_layout", ""))
	_set_modal_detail_content(detail_text, detail_ally)

	for option_index in option_count:
		var option: Dictionary = options[option_index]
		var value = option.get("value")
		var variant := _resolve_modal_option_variant(option, option_index, option_count)
		var btn := TheaterModal.make_option_button(option.get("text", ""), variant)
		var hover_text := str(option.get("hover_text", ""))
		if not hover_text.is_empty():
			if inline_hover_detail:
				btn.mouse_entered.connect(_on_modal_option_inline_hover.bind(hover_text, option_count, detail_layout))
			else:
				btn.mouse_entered.connect(_on_modal_option_button_mouse_enter.bind(btn.get_instance_id(), hover_text))
				btn.mouse_exited.connect(_hide_modal_option_tooltip)
		btn.pressed.connect(_on_modal_option_pressed.bind(value))
		modal_buttons.add_child(btn)

	var detail_visible := not detail_text.is_empty() or not detail_ally.is_empty()
	modal_backdrop.modulate = Color(1, 1, 1, 0)
	modal_backdrop.visible = true
	_refresh_modal_layout(detail_visible, option_count, detail_layout)
	await get_tree().process_frame
	_refresh_modal_layout(detail_visible, option_count, detail_layout)
	modal_backdrop.modulate = Color.WHITE

	var result = await modal_choice_resolved
	_hide_modal_option_tooltip()
	_hide_modal_recruit_detail()
	_set_modal_detail_text("")
	modal_backdrop.modulate = Color.WHITE
	if result is Array and result.size() > 0:
		return result[0]
	return result


func _confirm_choice(title: String, body: String, confirm_text: String, cancel_text: String) -> bool:
	var result = await _present_choice(title, body, [
		{"text": confirm_text, "value": true, "variant": "primary"},
		{"text": cancel_text, "value": false, "variant": "secondary"},
	])
	return bool(result)


func _resolve_selected_card() -> void:
	if busy or selected_deck_index < 0 or state.phase != "battle_idle":
		return

	var dc: Dictionary = state.deck[selected_deck_index]
	if dc["revealed"]:
		return

	busy = true
	var is_chain_flip := state.pending_chain_flips > 0

	if not is_chain_flip and state.skip_turns > 0:
		_begin_turn(false)
		state.skip_turns -= 1
		_append_log("你被迫跳过了本回合！")
		await _finish_turn(false)
		return

	var pre_action = await _handle_hero_pre_reveal(dc)
	if pre_action == "cancel":
		state.phase = "battle_idle"
		busy = false
		_update_ui()
		return

	_begin_turn(is_chain_flip)
	if state.game_over:
		await _finish_turn(false)
		return

	if pre_action == "skip_turn":
		_append_log("三思后决定放回牌池，跳过本回合。")
		await _finish_turn(false)
		return

	if pre_action == "skip_card":
		dc["revealed"] = true
		state.discard_pile.append(dc.duplicate(true))
		_show_hero_skill_feedback()
		_append_log("回避技能发动！%s 被移出牌池。" % dc["character"]["code"])
		state.last_revealed_fate = null
		await _finish_turn(true)
		return

	if pre_action == "rest":
		var healed := _heal_player(GameBalance.HERO_ZZZZ_REST_HEAL)
		_show_hero_skill_feedback()
		_append_log("补觉回复了 %d HP。" % healed)
		await _finish_turn(false)
		return

	_unlock_reveal_preview()
	_play_sfx("card_flip")
	await _play_selected_card_transition(selected_deck_index, dc)
	dc["revealed"] = true

	# ── 聚光灯聚焦：暖金色光晕在中央亮起 ──
	_play_spotlight_focus(Color(1.0, 0.82, 0.50), 0.55, 0.34)

	# ── 翻牌前：紧张氛围渐变（暗角偏冷） ──
	ShaderEffects.animate_tension_build(self, vignette_material)

	var final_fate: String = _get_selected_card_fate(dc)
	if state.forced_next_fate != null:
		DeckManager.reassign_fate(dc, String(state.forced_next_fate))
		final_fate = String(state.forced_next_fate)
		_clear_forced_next_fate()

	var hero_post_action = await _handle_hero_post_reveal(dc, final_fate)

	if hero_post_action == "reroll":
		state.discard_pile.append(dc.duplicate(true))
		_show_hero_skill_feedback()
		_append_log("重来技能发动！弃掉 %s，重新翻一张。" % dc["character"]["code"])
		_advance_spy_exposure_progress_for_reveal()
		if state.remaining_cards() > 0:
			state.pending_chain_flips = maxi(state.pending_chain_flips, 1)
		state.last_revealed_fate = null
		await _discard_active_card()
		await _finish_turn(true)
		return

	final_fate = String(hero_post_action)
	DeckManager.reassign_fate(dc, final_fate)
	_record_fate_streak(final_fate)
	if final_fate == "enemy":
		state.consecutive_enemies += 1
		if state.player_character["code"] == "Dior-s" and state.consecutive_enemies >= 2:
			_queue_forced_next_fate("ally")
			_show_hero_skill_feedback()
			_append_log("触底反弹！连续遇到2个敌人，下一张牌必定成为伙伴。")
	else:
		state.consecutive_enemies = 0
	var reveal_display_fate := BattleScreenText.get_reveal_display_fate(dc["character"], final_fate)
	var reveal_display_text := "伙伴" if reveal_display_fate == "ally" else "敌人"
	await _play_reveal_suspense_spin(reveal_display_fate)
	_play_sfx("fate_reveal")
	_lock_reveal_preview(dc["character"], reveal_display_text, reveal_display_fate)
	_play_fate_reveal_glow(reveal_display_fate)
	await _play_active_reveal_pulse(reveal_display_fate)
	_append_log(BattleScreenText.get_reveal_result_log_text(dc["character"], final_fate, reveal_display_fate))

	# ── 命运揭晓展示 ── 悬停→光圈+裁决条同时出现→停留展示
	await get_tree().create_timer(0.15).timeout  # 命运悬停
	_show_fate_verdict_banner(reveal_display_fate, dc["character"].get("code", ""))  # 不await，与展示并行
	# 更新面板边条颜色
	_update_card_info(dc["character"], selected_deck_index)
	await get_tree().create_timer(0.80).timeout  # 充分展示时间

	if final_fate == "ally":
		await _process_ally(dc, true)
	else:
		await _process_enemy(dc)
	_advance_spy_exposure_progress_for_reveal()
	state.last_revealed_fate = final_fate

	_unlock_reveal_preview()

	if not is_chain_flip and state.player_character["code"] == "GOGO" and state.pending_chain_flips == 0 and state.remaining_cards() > 0 and not state.game_over:
		var wants_extra := await _confirm_choice("加速", "使用加速技能，本回合再翻一张牌？", "再翻一张", "结束回合")
		if wants_extra:
			state.pending_chain_flips = 1
			_show_hero_skill_feedback()
			_append_log("加速发动！本回合额外翻一张牌。")

	await _finish_turn(true)


func _begin_turn(is_chain_flip: bool) -> void:
	if is_chain_flip:
		state.pending_chain_flips = maxi(0, state.pending_chain_flips - 1)
	else:
		state.round += 1
		if state.isolate_turns > 0:
			state.isolate = true
			state.isolate_turns -= 1
		else:
			state.isolate = false
		_advance_round_state()
		_apply_round_start_passives()
		_apply_hero_pre_flip_passive()
		if state.force_double_next_turn:
			state.pending_chain_flips = maxi(state.pending_chain_flips, 1)
			state.force_double_next_turn = false
			_show_enemy_skill_feedback_by_code("GOGO", _get_player_stage_hit_world_center())
			_append_log("催命效果触发！本回合强制连翻两张牌。")

	state.phase = "battle_animating"
	_update_header()


func _finish_turn(card_consumed: bool) -> void:
	_hide_ally_tooltip()
	_clear_active_reveal_card()
	_clear_peek_cache()
	if card_consumed:
		DeckManager.tick_charm_effects(state)
	_sync_charm_state(true)
	_update_ui()

	if not state.game_over and state.pending_chain_flips == 0 and not state.pending_spy_exposures.is_empty():
		await _resolve_pending_spy_exposures()

	if state.game_over:
		state.phase = "result"
		await get_tree().process_frame
		battle_finished.emit()
		return

	if state.remaining_cards() == 0:
		state.game_over = true
		state.victory = true
		state.phase = "result"
		await get_tree().process_frame
		battle_finished.emit()
		return

	if state.pending_chain_flips > 0:
		_append_log("连锁翻牌中，请继续选牌！")

	state.phase = "battle_idle"
	busy = false
	_update_ui()


func _sync_charm_state(redistribute: bool) -> void:
	if redistribute:
		DeckManager.redistribute_fates(state)


func _get_ally_by_uid(uid: int) -> Dictionary:
	for ally in state.allies:
		if int(ally.get("uid", -1)) == uid:
			return ally
	return {}


func _resolve_pending_spy_exposures() -> void:
	var pending_uids: Array = state.pending_spy_exposures.duplicate()
	state.pending_spy_exposures.clear()
	for pending_uid in pending_uids:
		if state.game_over:
			return
		var spy_ally := _get_ally_by_uid(int(pending_uid))
		if spy_ally.is_empty() or not spy_ally.get("is_spy", false):
			continue
		await _play_spy_exposure_sequence(spy_ally)
		_update_ui()


func _play_spy_exposure_sequence(spy_ally: Dictionary) -> void:
	_play_sfx("spy_reveal")
	var spy_uid := int(spy_ally.get("uid", -1))
	var seat_id := _get_seat_id_for_ally(spy_ally)
	var seat: Control = seat_nodes.get(seat_id) as Control
	var avatar_container := _get_seat_actor_node(seat_id, spy_uid)
	if seat == null or avatar_container == null:
		if _remove_ally(spy_ally, true):
			var fallback_dmg := _deal_enemy_damage(15, false, false)
			_show_enemy_skill_feedback_by_code("FAKE", _get_player_stage_hit_world_center())
			_append_log("潜伏暴露！%s 是间谍，造成 %d 点伤害。" % [spy_ally["character"]["code"], fallback_dmg])
		return

	await _animate_spy_seat_reveal(seat_id, spy_ally, avatar_container)

	var removed := _remove_ally(spy_ally, true)
	if not removed:
		_sync_ally_seats()
		return

	var previous_enemy_character := active_enemy_character
	var previous_reveal_card := active_reveal_card
	active_enemy_character = spy_ally["character"]
	active_reveal_card = avatar_container
	var flight_duration := _get_attack_flight_duration("enemy", "player")
	var dmg := _deal_enemy_damage(15, false, false)
	_show_enemy_skill_feedback_by_code("FAKE", _get_seat_world_center(seat_id, spy_uid))
	_append_log("潜伏暴露！%s 是间谍，造成 %d 点伤害。" % [spy_ally["character"]["code"], dmg])
	await get_tree().create_timer(maxf(flight_duration, 0.26) + 0.16).timeout
	active_reveal_card = previous_reveal_card
	active_enemy_character = previous_enemy_character

	await _animate_seat_departure(seat_id, spy_uid, Vector2(0.0, 28.0))
	_sync_ally_seats()


func _animate_spy_seat_reveal(seat_id: String, spy_ally: Dictionary, avatar_container: Control) -> void:
	var seat: Control = seat_nodes.get(seat_id) as Control
	if seat == null:
		return
	var avatar: TextureRect = seat.get_meta("avatar") as TextureRect
	var background: TextureRect = seat.get_meta("background") as TextureRect
	var hit_flash: ColorRect = seat.get_meta("hit_flash") as ColorRect
	if avatar == null:
		return

	var character: Dictionary = spy_ally["character"]
	var ally_texture := _get_small_hand_card_texture(character, "ally")
	var enemy_texture := _get_small_hand_card_texture(character, "enemy")
	if ally_texture == null:
		ally_texture = _get_character_avatar_texture(character, "ally")
	if enemy_texture == null:
		enemy_texture = _get_character_avatar_texture(character, "enemy")
	if ally_texture != null:
		avatar.texture = ally_texture

	var base_scale := avatar_container.scale
	var base_rotation := avatar_container.rotation_degrees
	var base_modulate := avatar_container.modulate
	var base_background := background.modulate if background != null else Color.WHITE
	var enemy_background := Color(1.18, 0.72, 0.64, base_background.a) if _seat_uses_small_card_template(seat_id) else Color(1.0, 0.56, 0.44, base_background.a)

	if hit_flash != null:
		hit_flash.visible = true
		hit_flash.color = Color(1.0, 0.26, 0.18, 0.0)

	var close := create_tween()
	close.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	close.set_parallel(true)
	close.tween_property(avatar_container, "scale", Vector2(base_scale.x * 0.08, base_scale.y * 1.08), 0.12)
	close.tween_property(avatar_container, "rotation_degrees", base_rotation - 6.0, 0.12)
	close.tween_property(avatar_container, "modulate", Color(1.18, 0.92, 0.88, base_modulate.a), 0.10)
	if background != null:
		close.tween_property(background, "modulate", enemy_background, 0.10)
	if hit_flash != null:
		close.tween_property(hit_flash, "color:a", 0.58, 0.06)
	await close.finished

	if enemy_texture != null:
		avatar.texture = enemy_texture
	avatar.modulate = Color(1.08, 0.98, 0.96, 1.0)
	_spawn_impact_burst(_get_seat_world_center(seat_id, int(spy_ally.get("uid", -1))), Color(1.0, 0.44, 0.26), false)
	_trigger_hitstop(0.040, 0.04, 0.14)
	_play_screen_shake(18.0, 0.12, 4, 0.64)

	var open := create_tween()
	open.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	open.set_parallel(true)
	open.tween_property(avatar_container, "scale", Vector2(base_scale.x * 1.08, base_scale.y * 1.02), 0.16)
	open.tween_property(avatar_container, "rotation_degrees", base_rotation + 3.0, 0.16)
	open.tween_property(avatar_container, "modulate", Color(1.18, 0.84, 0.80, base_modulate.a), 0.14)
	if background != null:
		open.tween_property(background, "modulate", Color(1.0, 0.86, 0.82, base_background.a), 0.16)
	if hit_flash != null:
		open.tween_property(hit_flash, "color:a", 0.0, 0.16)
	await open.finished

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.set_parallel(true)
	settle.tween_property(avatar_container, "scale", base_scale, 0.12)
	settle.tween_property(avatar_container, "rotation_degrees", base_rotation, 0.12)
	settle.tween_property(avatar_container, "modulate", base_modulate, 0.18)
	if background != null:
		settle.tween_property(background, "modulate", base_background, 0.22)
	await settle.finished
	if hit_flash != null:
		hit_flash.visible = false
		hit_flash.color.a = 0.0


func _advance_round_state() -> void:
	if not state.slot_seal_turns.is_empty():
		var next_turns: Array = []
		for turns in state.slot_seal_turns:
			if int(turns) - 1 > 0:
				next_turns.append(int(turns) - 1)
		state.slot_seal_turns = next_turns

	for i in range(state.allies.size() - 1, -1, -1):
		var ally: Dictionary = state.allies[i]

		if int(ally["sleeping"]) > 0:
			ally["sleeping"] = int(ally["sleeping"]) - 1

		if _ally_has_skill(ally, "IMFW") and not ally["is_spy"] and int(ally["blocks"]) < 3:
			ally["blocks"] = int(ally["blocks"]) + 1
			_show_ally_skill_feedback(ally, null, "IMFW")
			_append_log("蜕变触发！%s 的挡伤次数提升到 %d。" % [ally["character"]["code"], int(ally["blocks"])])

		if ally["extra"].has("temp_turns"):
			ally["extra"]["temp_turns"] = int(ally["extra"]["temp_turns"]) - 1
			if int(ally["extra"]["temp_turns"]) <= 0:
				_remove_ally(ally, true)
				_append_log("%s 的临时编外效果到期，已离队。" % ally["character"]["code"])
				continue


func _advance_spy_exposure_progress_for_reveal() -> void:
	var revealed_count := state.revealed_cards()
	for ally in state.allies:
		if not ally.get("is_spy", false):
			continue
		var expose_after_reveals := int(ally.get("spy_expose_after_reveals", revealed_count + int(ally.get("spy_timer", 2))))
		var remaining_reveals := maxi(0, expose_after_reveals - revealed_count)
		ally["spy_timer"] = remaining_reveals
		if remaining_reveals > 0:
			continue
		var spy_uid := int(ally.get("uid", -1))
		if spy_uid >= 0 and not state.pending_spy_exposures.has(spy_uid):
			state.pending_spy_exposures.append(spy_uid)


func _apply_round_start_passives() -> void:
	if state.player_character["code"] == "MUM":
		var hero_heal := _heal_player(GameBalance.HERO_MUM_HEAL)
		if hero_heal > 0:
			_show_hero_skill_feedback()
			_append_log("关怀效果发动，回复 %d HP。" % hero_heal)

	if state.is_monk_hero():
		return

	for ally in state.allies:
		if _ally_has_skill(ally, "MUM") and not ally["is_spy"]:
			var heal := _heal_player(GameBalance.ALLY_MUM_HEAL)
			if heal > 0:
				_show_ally_skill_feedback(ally, null, "MUM")
				_append_log("伙伴 MUM 的暖汤效果，回复 %d HP。" % heal)


func _apply_hero_pre_flip_passive() -> void:
	if state.player_character["code"] != "MALO":
		return

	var roll := randi_range(0, 2)
	_show_hero_skill_feedback()
	match roll:
		0:
			var healed := _heal_player(GameBalance.HERO_MALO_HEAL)
			_append_log("猴戏：好运！回复 %d HP。" % healed)
		1:
			var dmg := _damage_player(10, false, false, false, false)
			_append_log("猴戏：坏运！扣 %d HP。" % dmg)
		_:
			_append_log("猴戏发动！本回合无事发生。")


func _process_ally(dc: Dictionary, counts_as_revealed_ally: bool = true) -> void:
	if counts_as_revealed_ally and state.player_character["code"] == "THAN-K":
		var thanks_heal := _heal_player(GameBalance.HERO_THANK_HEAL)
		_show_hero_skill_feedback()
		_append_log("感恩技能发动，回复 %d HP。" % thanks_heal)

	if counts_as_revealed_ally and state.player_character["code"] == "IMSB":
		var recover := _heal_player(GameBalance.HERO_IMSB_HEAL)
		_show_hero_skill_feedback()
		_append_log("自罚的另一面发动，回复 %d HP。" % recover)

	if counts_as_revealed_ally and state.next_ally_blocked:
		state.next_ally_blocked = false
		_show_enemy_skill_feedback_by_code("IMSB", _get_control_world_center(active_reveal_card))
		_append_log("否定效果生效！%s 无法入队。" % dc["character"]["code"])
		await _discard_active_card(Vector2(0, -84))
		return

	var new_ally := _create_ally_slot(dc["character"])
	var protected_mimic_uid := -1
	if dc["character"]["code"] == "FAKE" and not state.can_add_ally(new_ally):
		var preselected_mimic = await _choose_mimic_target()
		if preselected_mimic != null:
			new_ally["extra"]["mimic_code"] = preselected_mimic["character"]["code"]
			new_ally["extra"]["mimic_target_uid"] = int(preselected_mimic.get("uid", -1))
			protected_mimic_uid = int(preselected_mimic.get("uid", -1))
		else:
			_append_log("模仿失败！没有其他伙伴可复制。")

	var joined := await _add_ally_to_camp(new_ally, true, protected_mimic_uid)
	if joined:
		_sync_ally_seats()
		var ally_seat_id := _get_seat_id_for_ally(new_ally)
		_prepare_seat_entry_hidden(ally_seat_id, int(new_ally.get("uid", -1)))
		if active_reveal_card != null:
			await _fly_active_card_to_seat(ally_seat_id)
		_play_sfx("ally_join")
		await _animate_seat_entry(ally_seat_id, int(new_ally.get("uid", -1)))
		_append_log("%s 加入了你的阵营。" % dc["character"]["code"])
		await _apply_ally_entry_skill(new_ally)
		await _maybe_apply_true_love_lock(new_ally)
		_sync_ally_seats()
	else:
		_append_log("%s 未能加入阵营。" % dc["character"]["code"])
		await _discard_active_card(Vector2(0, -84))

	_update_ui()


func _process_enemy(dc: Dictionary) -> void:
	var code: String = dc["character"]["code"]
	state.last_enemy_damage = 0
	active_enemy_character = dc["character"]

	if state.player_character["code"] == "IMSB":
		var self_dmg := _damage_player(5, false, false, false, false)
		_show_hero_skill_feedback()
		_append_log("自罚发动，先扣 %d HP。" % self_dmg)
		if state.game_over:
			active_enemy_character = {}
			_sync_enemy_seat()
			return

	if code == "FAKE":
		var spy_ally := _create_ally_slot(dc["character"], true)
		var spy_joined := await _add_ally_to_camp(spy_ally, false)
		if spy_joined:
			_sync_ally_seats()
			var spy_seat_id := _get_seat_id_for_ally(spy_ally)
			_prepare_seat_entry_hidden(spy_seat_id, int(spy_ally.get("uid", -1)))
			if active_reveal_card != null:
				await _fly_active_card_to_seat(spy_seat_id)
			_play_sfx("ally_join")
			await _animate_seat_entry(spy_seat_id, int(spy_ally.get("uid", -1)))
			_append_log("FAKE 伪装成伙伴入队，2 回合后将暴露。")
		else:
			await _discard_active_card(Vector2(0, -84))
			_append_log("FAKE 潜伏失败，槽位不足。")
		active_enemy_character = {}
		_sync_enemy_seat()
		_update_ui()
		return

	var deflector = null
	for ally in state.allies:
		if _ally_has_skill(ally, "FUCK") and not ally["is_spy"] and ally["extra"].get("auto_deflect", false):
			deflector = ally
			break

	if deflector != null:
		deflector["extra"]["auto_deflect"] = false
		_show_ally_skill_feedback(deflector, null, "FUCK")
		_append_log("开路技能触发！自动击退 %s。" % code)
		await _discard_active_card(Vector2(0, -84))
		active_enemy_character = {}
		_sync_enemy_seat()
		_update_ui()
		return

	var has_direct_damage := _enemy_has_direct_damage(code)
	var is_unblockable := code == "FUCK"
	var available_blockers := _get_available_blockers()
	var imsb_blocker = null
	for ally in available_blockers:
		if _ally_has_skill(ally, "IMSB"):
			imsb_blocker = ally
			break

	var can_choose_block := has_direct_damage and not is_unblockable and not state.isolate and not available_blockers.is_empty()
	var result := {"converted_to_ally": false, "blocked_base_damage": 0}

	if imsb_blocker != null and can_choose_block:
		_show_ally_skill_feedback(imsb_blocker, null, "IMSB")
		_append_log("伙伴 IMSB 的替罪效果自动挡伤，你会额外损失 5 HP。")
		_play_attack_effect("enemy", _get_seat_id_for_ally(imsb_blocker), 0, int(imsb_blocker.get("uid", -1)))
		result = _execute_enemy_skill(dc, true, false)
		await _resolve_block_usage(imsb_blocker, true)
		_apply_block_splash_damage(result)
	elif not has_direct_damage or not can_choose_block:
		result = _execute_enemy_skill(dc, false, has_direct_damage)
	else:
		var choice = await _show_block_modal(dc)
		if choice == "block":
			var block_ally = await _choose_ally_to_block()
			if block_ally != null:
				_append_log("%s 替你挡住了攻击。" % block_ally["character"]["code"])
				_play_attack_effect("enemy", _get_seat_id_for_ally(block_ally), 0, int(block_ally.get("uid", -1)))
				result = _execute_enemy_skill(dc, true, false)
				await _resolve_block_usage(block_ally, false)
				_apply_block_splash_damage(result)
			else:
				result = _execute_enemy_skill(dc, false, true)
		else:
			result = _execute_enemy_skill(dc, false, true)

	if result["converted_to_ally"] and not state.game_over:
		active_enemy_character = {}
		_sync_enemy_seat()
		await _process_ally(dc, false)
		return

	await get_tree().create_timer(0.12).timeout
	await _discard_active_card(Vector2(0, -84))
	active_enemy_character = {}
	_sync_enemy_seat()
	_update_ui()


func _show_block_modal(dc: Dictionary) -> String:
	var skill: Dictionary = dc["character"]["skills"]["enemy"]
	var block_text := "派伙伴挡伤"
	if dc["character"]["code"] == "MALO":
		block_text = "派伙伴挡伤（仍会承受随机溅射伤害）"
	else:
		var base_damage := GameBalance.get_direct_enemy_damage(dc["character"]["code"])
		var splash := GameBalance.get_block_splash(base_damage)
		if splash > 0:
			block_text = "派伙伴挡伤（仍会受到 %d 点溅射伤害）" % splash
	return await _present_choice(
		"%s 来袭！" % dc["character"]["code"],
		"[%s]\n%s\n\n你要如何应对？" % [skill["name"], skill["description"]],
		[
			{"text": block_text, "value": "block", "variant": "primary"},
			{"text": "自己硬扛", "value": "tank", "variant": "secondary"},
		]
	)


func _choose_ally_to_block():
	var available := _get_available_blockers()
	if available.is_empty():
		return null
	if available.size() == 1:
		return available[0]

	var options: Array = []
	for ally in available:
		options.append({
			"text": "%s（%d次）" % [ally["character"]["code"], int(ally["blocks"])],
			"value": ally,
			"variant": "primary",
		})
	return await _present_choice("选择挡伤伙伴", "选择一个伙伴抵挡此次攻击。", options)


func _show_replace_modal(new_ally: Dictionary) -> bool:
	return await _show_replace_modal_with_protection(new_ally)


func _show_replace_modal_with_protection(new_ally: Dictionary, protected_ally_uid: int = -1) -> bool:
	var replaceable: Array = []
	for ally in state.allies:
		if not ally["locked"] and state.ally_uses_slot(ally):
			replaceable.append(ally)

	if protected_ally_uid >= 0:
		var filtered: Array = []
		for ally in replaceable:
			if int(ally.get("uid", -1)) != protected_ally_uid:
				filtered.append(ally)
		replaceable = filtered

	if replaceable.is_empty():
		if protected_ally_uid >= 0:
			_append_log("没有其他可替换的队友，无法在保护模仿目标的前提下替换入队。")
		else:
			_append_log("所有伙伴均被锁定，无法替换。")
		return false

	var picked = await _present_replace_modal(new_ally, replaceable)
	if picked == null:
		return false

	_remove_ally(picked)
	state.allies.append(new_ally)
	_play_sfx("ally_replace")
	_sync_charm_state(true)
	return true


func _get_selected_card_fate(dc: Dictionary) -> String:
	if state.forced_next_fate != null:
		return String(state.forced_next_fate)
	return String(dc["fate"])


func _record_fate_streak(fate: String) -> void:
	if state.fate_streak_type == fate:
		state.fate_streak_count += 1
	else:
		state.fate_streak_type = fate
		state.fate_streak_count = 1


func _heal_player(amount: int) -> int:
	var heal := amount
	if state.heal_boost:
		heal *= 2
		state.heal_boost = false
		_show_hero_skill_feedback()
		_append_log("碎心触发！本次治疗翻倍。")

	var next_hp := mini(state.max_hp, state.hp + heal)
	var actual := next_hp - state.hp
	state.hp = next_hp
	if actual > 0 and state.player_character["code"] == "JOKE-R":
		_sync_charm_state(true)
	if actual > 0:
		_play_sfx("heal")
		_refresh_header_if_ready()
	return actual


func _get_undying_trigger_delay(count_as_enemy_damage: bool) -> float:
	if not count_as_enemy_damage or active_enemy_character.is_empty():
		return 0.0
	return _get_attack_flight_duration("enemy", "player")


func _play_undying_trigger_effect(delay: float = 0.0) -> void:
	if not is_inside_tree():
		return
	if delay <= 0.0:
		_run_undying_trigger_effect()
		return
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_run_undying_trigger_effect)


func _apply_enemy_followup_damage(reason: String, amount: int) -> int:
	var dmg := _deal_enemy_damage(amount, false, false)
	_append_log("%s，额外造成 %d 点伤害。" % [reason, dmg])
	return dmg


func _damage_player(
	amount: int,
	tanking: bool,
	count_as_enemy_damage: bool,
	allow_immunity: bool = true,
	blocked: bool = false,
	apply_enemy_modifiers: bool = true
) -> int:
	if blocked or amount <= 0:
		return 0

	var effective := amount
	if tanking and state.player_character["code"] == "FUCK":
		_show_hero_skill_feedback()
		effective = int(floor(float(effective) / 2.0))
		_append_log("硬刚技能发动！伤害减半为 %d。" % effective)

	var dmg := _get_effective_damage(effective, count_as_enemy_damage, apply_enemy_modifiers)

	if allow_immunity and dmg > 0 and state.player_character["code"] == "OJBK" and randf() < 0.3:
		_show_hero_skill_feedback()
		_append_log("无所谓触发！本次伤害被免疫。")
		return 0

	state.hp -= dmg
	if count_as_enemy_damage:
		state.last_enemy_damage = dmg
		if dmg > 0:
			_play_sfx("enemy_hit")
		if not active_enemy_character.is_empty():
			_play_attack_effect("enemy", "player", dmg)
		if state.player_character["code"] == "SHIT" and dmg > 0:
			var stored_revenge := int(floor(float(dmg) * 0.3))
			state.revenge_stored += stored_revenge
			if stored_revenge > 0:
				_show_hero_skill_feedback()
				_append_log("以牙还牙蓄力！已储存 %d 点反击伤害。" % stored_revenge)

	if state.hp <= 0 and not state.undying and state.player_character["code"] == "DEAD":
		state.hp = 1
		state.undying = true
		_play_undying_trigger_effect(_get_undying_trigger_delay(count_as_enemy_damage))
		_append_log("不死触发！以 1 HP 奇迹存活。")

	if state.hp <= 0:
		state.hp = 0
		state.game_over = true
		state.victory = false

	if dmg > 0 and state.player_character["code"] == "IMFW":
		if not state.heal_boost:
			_show_hero_skill_feedback()
			_append_log("碎心蓄势！下次治疗翻倍。")
		state.heal_boost = true

	if dmg > 0 and state.player_character["code"] == "JOKE-R":
		_sync_charm_state(true)
	if dmg > 0:
		_refresh_header_if_ready()

	return dmg


func _get_effective_damage(base_dmg: int, count_as_enemy_damage: bool, apply_enemy_modifiers: bool = true) -> int:
	var dmg := float(base_dmg)
	if not count_as_enemy_damage or not apply_enemy_modifiers:
		return base_dmg

	if state.taunt_multiplier > 1:
		dmg *= state.taunt_multiplier
		state.taunt_multiplier = 1
		_show_enemy_skill_feedback_by_code("JOKE-R", _get_player_stage_hit_world_center())
		_append_log("嘲讽效果结算！本次敌人伤害翻倍。")

	if state.vuln_stacks > 0:
		dmg += 5
		state.vuln_stacks -= 1
		_show_enemy_skill_feedback_by_code("IMFW", _get_player_stage_hit_world_center())
		_append_log("脆弱生效！本次伤害额外 +5。")

	if state.revenge_stored > 0 and dmg > 0:
		var absorbed := mini(int(round(dmg)), state.revenge_stored)
		dmg -= absorbed
		state.revenge_stored = 0
		_show_hero_skill_feedback()
		_append_log("以牙还牙抵消了 %d 点伤害。" % absorbed)

	return maxi(0, int(round(dmg)))


func _ally_has_skill(ally: Dictionary, code: String) -> bool:
	return ally["character"]["code"] == code or ally["extra"].get("mimic_code", "") == code


func _get_available_blockers() -> Array:
	var blockers: Array = []
	for ally in state.allies:
		if ally["locked"]:
			continue
		if ally["is_spy"]:
			continue
		if int(ally["sleeping"]) > 0:
			continue
		if int(ally["blocks"]) <= 0:
			continue
		if _ally_has_skill(ally, "DEAD"):
			continue
		blockers.append(ally)
	return blockers


func _create_ally_slot(character: Dictionary, is_spy: bool = false) -> Dictionary:
	var blocks := GameBalance.get_base_ally_blocks(character, state.player_character["code"])
	if character["code"] == "SOLO":
		var real_allies := 0
		for ally in state.allies:
			if not ally["is_spy"]:
				real_allies += 1
		if real_allies == 0:
			blocks = maxi(blocks, 2)

	var ally := {
		"character": character,
		"uid": _next_ally_uid(),
		"blocks": blocks,
		"locked": character["code"] == "LOVE-R" and not is_spy,
		"is_spy": is_spy,
		"spy_timer": 2 if is_spy else 0,
		"spy_expose_after_reveals": state.revealed_cards() + 2 if is_spy else -1,
		"sleeping": 2 if character["code"] == "ZZZZ" else 0,
		"extra": {},
	}

	if character["code"] == "Dior-s" and not is_spy:
		ally["extra"]["slotless"] = true
		ally["extra"]["temp_turns"] = 2
	if character["code"] == "FUCK" and not is_spy:
		ally["extra"]["auto_deflect"] = true

	return ally


func _next_ally_uid() -> int:
	ally_uid_counter += 1
	return ally_uid_counter


func _add_ally_to_camp(new_ally: Dictionary, allow_replacement: bool = true, protected_ally_uid: int = -1) -> bool:
	if state.can_add_ally(new_ally):
		state.allies.append(new_ally)
		_sync_charm_state(true)
		return true
	if not allow_replacement:
		return false
	return await _show_replace_modal_with_protection(new_ally, protected_ally_uid)


func _remove_ally(ally: Dictionary, ignore_lock: bool = false) -> bool:
	if ally["locked"] and not ignore_lock:
		return false

	var idx := state.allies.find(ally)
	if idx < 0:
		return false
	var leave_world_position := _get_seat_world_center(_get_seat_id_for_ally(ally), int(ally.get("uid", -1)))

	state.allies.remove_at(idx)
	state.ally_loss_stacks += 1

	if state.player_character["code"] == "ATM-er":
		var hero_heal := _heal_player(GameBalance.HERO_ATM_LEAVE_HEAL)
		if hero_heal > 0:
			_show_hero_skill_feedback()
			_append_log("回馈触发！伙伴离队时回复 %d HP。" % hero_heal)

	if _ally_has_skill(ally, "DEAD"):
		var dead_heal := _heal_player(GameBalance.ALLY_DEAD_LEAVE_HEAL)
		if dead_heal > 0:
			_show_ally_skill_feedback(ally, leave_world_position, "DEAD")
			_append_log("回光触发！DEAD 离队时回复 %d HP。" % dead_heal)

	_append_log("阵营减员，后续敌伤总倍率升至 ×%.2f。" % state.ally_loss_multiplier())
	_sync_charm_state(true)
	return true


func _remove_random_ally(reason: String):
	var candidates: Array = []
	for ally in state.allies:
		if not ally["locked"]:
			candidates.append(ally)
	if candidates.is_empty():
		_append_log("%s，但没有可移除的伙伴。" % reason)
		return null

	var picked = candidates[randi_range(0, candidates.size() - 1)]
	if not active_enemy_character.is_empty():
		_play_attack_effect("enemy", _get_seat_id_for_ally(picked), 0, int(picked.get("uid", -1)))
	_remove_ally(picked)
	_append_log("%s：%s 离队了。" % [reason, picked["character"]["code"]])
	return picked


func _remove_newest_ally(reason: String):
	for i in range(state.allies.size() - 1, -1, -1):
		var ally: Dictionary = state.allies[i]
		if ally["locked"]:
			continue
		if not active_enemy_character.is_empty():
			_play_attack_effect("enemy", _get_seat_id_for_ally(ally), 0, int(ally.get("uid", -1)))
		_remove_ally(ally)
		_append_log("%s：%s 离队了。" % [reason, ally["character"]["code"]])
		return ally
	_append_log("%s，但没有可移除的伙伴。" % reason)
	return null


func _resolve_block_usage(block_ally: Dictionary, via_imsb: bool) -> void:
	_play_sfx("ally_block")
	if via_imsb:
		var self_dmg := _damage_player(5, false, false, false, false)
		_append_log("替罪自伤，扣除 %d HP。" % self_dmg)

	block_ally["blocks"] = int(block_ally["blocks"]) - 1
	if int(block_ally["blocks"]) > 0:
		return

	var protected := false
	var protector: Dictionary = {}
	if not state.is_monk_hero():
		for ally in state.allies:
			if ally == block_ally or ally["is_spy"]:
				continue
			if _ally_has_skill(ally, "BOSS") or _ally_has_skill(ally, "POOR"):
				protected = randf() < 0.5
				if protected:
					protector = ally
					break

	if protected:
		block_ally["blocks"] = 1
		var protector_skill_code := "BOSS" if _ally_has_skill(protector, "BOSS") else "POOR"
		_show_ally_skill_feedback(protector, null, protector_skill_code)
		_append_log("铁令/专注光环触发！伙伴挡伤后未离队。")
		return

	_remove_ally(block_ally)
	_append_log("%s 耗尽挡伤次数，离队了。" % block_ally["character"]["code"])


func _enemy_has_direct_damage(code: String) -> bool:
	return code == "MALO" or GameBalance.get_direct_enemy_damage(code) > 0


func _deal_enemy_damage(amount: int, blocked_damage: bool, tanking: bool) -> int:
	var scaled := GameBalance.scale_enemy_damage(amount, state.round, state.ally_loss_stacks)
	return _damage_player(scaled, tanking, true, true, blocked_damage)


func _resolve_enemy_damage(result: Dictionary, amount: int, blocked_damage: bool, tanking: bool) -> int:
	if blocked_damage and amount > 0:
		result["blocked_base_damage"] = int(result.get("blocked_base_damage", 0)) + amount
	return _deal_enemy_damage(amount, blocked_damage, tanking)


func _apply_block_splash_damage(result: Dictionary) -> void:
	var blocked_base_damage := int(result.get("blocked_base_damage", 0))
	if blocked_base_damage <= 0:
		return
	var splash := GameBalance.get_block_splash(blocked_base_damage)
	var dmg := _damage_player(splash, false, true, false, false, false)
	if dmg > 0:
		_append_log("挡伤仍承受了 %d 点溅射伤害。" % dmg)


func _execute_enemy_skill(dc: Dictionary, blocked_damage: bool, tanking: bool) -> Dictionary:
	var code: String = dc["character"]["code"]
	var result := {"converted_to_ally": false, "blocked_base_damage": 0}
	_show_enemy_skill_feedback(dc["character"])

	match code:
		"CTRL":
			if _remove_random_ally("收编") == null:
				_apply_enemy_followup_damage("收编没有抓到伙伴", GameBalance.get_empty_camp_damage(code))
		"ATM-er":
			_queue_forced_next_fate("enemy")
			var debt := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("连环债发动！造成 %d 点伤害，且下一张牌强制成为敌人。" % debt)
		"Dior-s":
			var cost := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			state.peek_charges += 1
			_append_log("代价发动！造成 %d 点伤害，并奖励一次窥视机会。" % cost)
		"BOSS":
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，封锁无效。")
			else:
				state.slot_seal_turns.append(GameBalance.DEBUFF_TURNS)
				_append_log("%s 发动！封锁 1 个伙伴槽位 %d 回合。" % [dc["character"]["skills"]["enemy"]["name"], GameBalance.DEBUFF_TURNS])
		"POOR":
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，封锁无效。")
			else:
				state.slot_seal_turns.append(GameBalance.DEBUFF_TURNS)
				_append_log("%s 发动！封锁 1 个伙伴槽位 %d 回合。" % [dc["character"]["skills"]["enemy"]["name"], GameBalance.DEBUFF_TURNS])
			var poverty := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("匮乏追击！造成 %d 点伤害。" % poverty)
		"THAN-K":
			if _remove_newest_ally("恩债") == null:
				_apply_enemy_followup_damage("恩债没有撕走伙伴", GameBalance.get_empty_camp_damage(code))
		"OH-NO":
			DeckManager.add_charm_effect(state, -0.15, GameBalance.DEBUFF_TURNS, "OH-NO")
			_append_log("恐慌发动！接下来 %d 张牌的伙伴概率各 -15%%。" % GameBalance.DEBUFF_TURNS)
		"GOGO":
			var rush := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("催命先造成 %d 点伤害。" % rush)
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，催命无效。")
			else:
				state.force_double_next_turn = true
				_append_log("催命发动！下回合强制连翻两张牌。")
		"SEXY":
			if _remove_random_ally("魅惑") == null:
				_apply_enemy_followup_damage("魅惑落空后反咬一口", GameBalance.get_empty_camp_damage(code))
		"LOVE-R":
			var heartbreak := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("情伤发动！造成 %d 点伤害。" % heartbreak)
		"MUM":
			if _remove_random_ally("内疚") == null:
				_apply_enemy_followup_damage("内疚无人承担", GameBalance.get_empty_camp_damage(code))
		"OJBK":
			var cold := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("已读不回发动！造成 %d 点伤害。" % cold)
		"MALO":
			var monkey := _resolve_enemy_damage(result, randi_range(0, 30), blocked_damage, tanking)
			_append_log("乱拳发动！造成 %d 点伤害。" % monkey)
		"JOKE-R":
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，嘲讽无效。")
			else:
				state.taunt_multiplier = GameBalance.JOKER_TAUNT_MULTIPLIER
				_append_log("嘲讽发动！下一个敌人伤害翻倍。")
		"WOC!":
			var surprise := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("反转先造成 %d 点伤害。" % surprise)
			if randf() < GameBalance.REROLL_REVERSE_CHANCE:
				result["converted_to_ally"] = true
				_append_log("反转成功！它转为伙伴。")
		"THIN-K":
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，过度思考无效。")
			else:
				state.skip_turns += 1
				_append_log("过度思考发动！你将跳过下一回合。")
		"SHIT":
			var rage := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			DeckManager.add_charm_effect(state, GameBalance.SHIT_CHARM_BOOST, 1, "SHIT")
			_append_log("暴怒发动！造成 %d 点伤害，但后续伙伴概率 +10%%。" % rage)
		"ZZZZ":
			var sleepy := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("催眠先造成 %d 点伤害。" % sleepy)
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，催眠无效。")
			else:
				state.skip_turns += 1
			_append_log("催眠效果：你将跳过下一回合。")
		"MONK":
			var removed_positive := false
			if state.forced_next_fate == "ally":
				_clear_forced_next_fate()
				removed_positive = true
			for effect in state.charm_effects:
				if effect["positive"]:
					removed_positive = true
					break
			if removed_positive:
				DeckManager.clear_charm_effects(state, true)
			if state.pending_chain_flips > 0:
				state.pending_chain_flips = 0
				removed_positive = true
			if not removed_positive:
				DeckManager.add_charm_effect(state, GameBalance.MONK_EMPTY_PENALTY, GameBalance.DEBUFF_TURNS, "MONK")
				_append_log("皆空发动！无正面效果可移除，伙伴概率 -20%% 持续 %d 张牌。" % GameBalance.DEBUFF_TURNS)
			else:
				_append_log("皆空发动！你身上的正面效果已被移除。")
			state.max_hp = maxi(1, state.max_hp - 8)
			if state.hp > state.max_hp:
				state.hp = state.max_hp
			_refresh_header_if_ready()
			_append_log("修行压顶！HP 上限永久 -8。")
			if state.player_character["code"] == "JOKE-R":
				_sync_charm_state(true)
		"IMSB":
			var deny := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("否定发动！造成 %d 点伤害。" % deny)
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，否定无效。")
			else:
				state.next_ally_blocked = true
				_append_log("下一个翻到的伙伴无法入队。")
		"SOLO":
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，孤立无效。")
			else:
				state.isolate_turns = maxi(state.isolate_turns, 1)
				_append_log("孤立发动！下一回合无法使用伙伴挡伤。")
		"FUCK":
			var brute := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("蛮横发动！造成 %d 点不可格挡伤害。" % brute)
		"DEAD":
			state.max_hp = maxi(1, state.max_hp - 15)
			if state.hp > state.max_hp:
				state.hp = state.max_hp
			_refresh_header_if_ready()
			_append_log("死气发动！HP 上限永久 -15。")
			if state.player_character["code"] == "JOKE-R":
				_sync_charm_state(true)
		"IMFW":
			var frail := _resolve_enemy_damage(result, GameBalance.get_direct_enemy_damage(code), blocked_damage, tanking)
			_append_log("脆弱发动！先造成 %d 点伤害。" % frail)
			if state.is_monk_hero():
				_append_log("修行者免疫持续性效果，脆弱无效。")
			else:
				state.vuln_stacks += 2
				_append_log("接下来受到伤害时将额外 +5。")
		_:
			var plain := _deal_enemy_damage(randi_range(10, 20), blocked_damage, tanking)
			_append_log("%s 发起普通攻击，造成 %d 点伤害。" % [code, plain])

	return result


func _apply_ally_entry_skill(ally: Dictionary) -> void:
	var code: String = ally["character"]["code"]
	_show_ally_skill_feedback(ally)
	match code:
		"CTRL":
			var chosen = await _prompt_fate_choice("操盘：指定下一张牌的命运")
			_queue_forced_next_fate(chosen)
			_append_log("操盘技能发动！下一张牌命运设为 %s。" % ("伙伴" if chosen == "ally" else "敌人"))
		"ATM-er":
			_append_log("续费效果！ATM-er 可抵挡 2 次。")
		"Dior-s":
			_append_log("编外效果！Dior-s 不占槽位，仅存在 2 回合。")
		"THAN-K":
			var gift := _heal_player(GameBalance.ALLY_THANK_HEAL)
			_append_log("谢礼效果：回复 %d HP。" % gift)
		"OH-NO":
			var remaining_enemies := 0
			for card in state.deck:
				if not card["revealed"] and card["fate"] == "enemy":
					remaining_enemies += 1
			_append_log("预警效果！牌池中剩余 %d 张敌人牌。" % remaining_enemies)
		"GOGO":
			state.pending_chain_flips = maxi(state.pending_chain_flips, 1)
			_append_log("带飞效果！立刻额外翻一张牌。")
		"SEXY":
			_append_log("光环效果生效！在阵营中时，后续牌伙伴概率 +5%。")
		"LOVE-R":
			_append_log("至死不渝！该伙伴自动锁定。")
		"MUM":
			_append_log("伙伴 MUM 入队！每回合为你回复 2 HP。")
		"FAKE":
			var mimicked_code := str(ally["extra"].get("mimic_code", ""))
			if mimicked_code.is_empty():
				var mimicked = await _choose_mimic_target(ally)
				if mimicked != null:
					mimicked_code = mimicked["character"]["code"]
					ally["extra"]["mimic_code"] = mimicked_code
			ally["extra"].erase("mimic_target_uid")
			if mimicked_code.is_empty():
				_append_log("模仿失败！没有其他伙伴可复制。")
			else:
				_append_log("FAKE 复制了 %s 的伙伴技能。" % mimicked_code)
				await _apply_mimicked_entry_effect(ally, mimicked_code)
		"OJBK":
			_append_log("摸鱼！OJBK 占着槽位但没有任何效果。")
		"MALO":
			var roll := randi_range(0, 2)
			if roll == 0:
				var lucky := _heal_player(GameBalance.ALLY_MALO_HEAL)
				_append_log("开盲盒：好运！回复 %d HP。" % lucky)
			elif roll == 1:
				var unlucky := _damage_player(5, false, false, false, false)
				_append_log("开盲盒：坏运！扣除 %d HP。" % unlucky)
			else:
				for card in state.deck:
					if not card["revealed"]:
						_append_log("开盲盒：窥视到 %s，命运是 %s。" % [card["character"]["code"], "伙伴" if card["fate"] == "ally" else "敌人"])
						break
		"JOKE-R":
			if state.hp < int(floor(float(state.max_hp) * 0.3)):
				var clown_heal := _heal_player(GameBalance.ALLY_JOKER_HEAL)
				_append_log("含泪治愈：回复 %d HP。" % clown_heal)
			else:
				_append_log("JOKE-R 加入了阵营。")
		"WOC!":
			DeckManager.redistribute_fates(state)
			_append_log("洗牌效果！重新随机分配所有剩余牌的命运。")
		"THIN-K":
			var target_name := ""
			for card in state.deck:
				if not card["revealed"] and card["fate"] == "enemy":
					target_name = card["character"]["code"]
					break
			if target_name == "":
				_append_log("推演效果！牌池中暂时没有敌人牌。")
			else:
				_append_log("推演效果！揭示一张敌人牌：%s。" % target_name)
		"SHIT":
			if state.last_revealed_fate == "enemy" and state.last_enemy_damage > 0:
				var spit := _heal_player(int(round(float(state.last_enemy_damage) * GameBalance.SHIT_HEAL_RATIO)))
				_append_log("刀子嘴效果：回复 %d HP。" % spit)
			else:
				_append_log("刀子嘴效果无效，上一张牌不是敌人。")
		"ZZZZ":
			_append_log("赖床效果！休眠 2 回合后可挡 2 次。")
		"POOR":
			_append_log("专注效果！其他伙伴挡伤后 50%% 概率不离队。")
		"MONK":
			_cleanse_negative_effects()
			_append_log("净化效果！移除身上所有持续性负面效果。")
		"IMSB":
			_append_log("伙伴 IMSB 的替罪效果已就位，将自动挡伤 2 次。")
		"SOLO":
			var count := 0
			for member in state.allies:
				if not member["is_spy"]:
					count += 1
			if count == 1:
				ally["blocks"] = maxi(int(ally["blocks"]), 2)
				_append_log("孤军效果！SOLO 是唯一伙伴，可挡 2 次。")
		"FUCK":
			ally["extra"]["auto_deflect"] = true
			_append_log("开路效果！自动击退下一个敌人。")
		"DEAD":
			_append_log("回光效果！DEAD 无法挡伤，但离队时会回复 8 HP。")
		"IMFW":
			_append_log("蜕变效果！每回合成长一次，最多可挡 3 次。")
		_:
			_append_log("%s 加入了你的阵营。" % code)

	_sync_charm_state(true)


func _apply_mimicked_entry_effect(ally: Dictionary, mimicked_code: String) -> void:
	match mimicked_code:
		"CTRL":
			var chosen = await _prompt_fate_choice("模仿操盘：指定下一张牌的命运")
			_queue_forced_next_fate(chosen)
		"THAN-K":
			_heal_player(GameBalance.ALLY_THANK_HEAL)
		"OH-NO":
			var remaining_enemies := 0
			for card in state.deck:
				if not card["revealed"] and card["fate"] == "enemy":
					remaining_enemies += 1
			_append_log("模仿预警！剩余敌人数量：%d。" % remaining_enemies)
		"GOGO":
			state.pending_chain_flips = maxi(state.pending_chain_flips, 1)
		"WOC!":
			DeckManager.redistribute_fates(state)
		"MONK":
			_cleanse_negative_effects()
		"FUCK":
			ally["extra"]["auto_deflect"] = true
		"MALO":
			var roll := randi_range(0, 2)
			if roll == 0:
				_heal_player(GameBalance.ALLY_MALO_HEAL)
			elif roll == 1:
				_damage_player(5, false, false, false, false)


func _maybe_apply_true_love_lock(ally: Dictionary) -> void:
	if state.player_character["code"] != "LOVE-R":
		return
	if state.true_love_used or ally["locked"] or ally["is_spy"]:
		return
	var should_lock := await _confirm_choice("真爱锁", "将 %s 设为真爱？锁定后无法被替换或消耗。" % ally["character"]["code"], "锁定", "暂时不要")
	if not should_lock:
		return
	ally["locked"] = true
	state.true_love_used = true
	_show_hero_skill_feedback(_get_seat_world_center(_get_seat_id_for_ally(ally), int(ally.get("uid", -1))))
	_append_log("真爱锁定！%s 不会被替换或消耗。" % ally["character"]["code"])


func _cleanse_negative_effects() -> void:
	var next_effects: Array = []
	for effect in state.charm_effects:
		if effect["positive"]:
			next_effects.append(effect)
	state.charm_effects = next_effects
	if state.forced_next_fate == "enemy":
		_clear_forced_next_fate()
	state.taunt_multiplier = 1
	state.vuln_stacks = 0
	state.isolate = false
	state.isolate_turns = 0
	state.skip_turns = 0
	state.next_ally_blocked = false
	state.force_double_next_turn = false
	state.slot_seal_turns.clear()
	_sync_charm_state(true)


func _handle_hero_pre_reveal(dc: Dictionary) -> String:
	var hero: String = state.player_character["code"]
	var deck_index := selected_deck_index
	if not _get_peek_data(deck_index).is_empty():
		return "reveal"

	if hero == "CTRL" and state.peek_charges > 0:
		var wants_peek := await _confirm_choice("读心", "还剩 %d 次窥视机会。是否先查看这张牌的命运？" % state.peek_charges, "窥视此牌", "直接翻牌")
		if wants_peek:
			state.peek_charges -= 1
			var fate := _get_selected_card_fate(dc)
			_remember_peek(deck_index, fate, "peek", _should_lock_peek_to_card())
			_show_hero_skill_feedback(null, "本次查看结果：%s" % ("队友" if fate == "ally" else "敌人"))
			_append_log("读心发动！你看穿了 %s，这次它会以 %s 身份出现。" % [dc["character"]["code"], "伙伴" if fate == "ally" else "敌人"])
			_update_card_info(dc["character"], deck_index)
			_update_deck_card_selection()
			return "cancel"

	if hero == "THIN-K" and state.think_charges > 0:
		var wants_think := await _confirm_choice("三思", "还剩 %d 次三思机会。是否先查看这张牌的命运？" % state.think_charges, "先想一想", "直接翻牌")
		if wants_think:
			state.think_charges -= 1
			var think_fate := _get_selected_card_fate(dc)
			_remember_peek(deck_index, think_fate, "think", _should_lock_peek_to_card())
			_show_hero_skill_feedback()
			_append_log("三思发动！你看清了 %s 的命运，它这次会是 %s。" % [dc["character"]["code"], "伙伴" if think_fate == "ally" else "敌人"])
			_update_card_info(dc["character"], deck_index)
			_update_deck_card_selection()
			return "cancel"

	if hero == "OH-NO" and state.skip_charges > 0:
		var should_skip := await _confirm_choice("回避", "还剩 %d 次回避机会。是否将此牌移出牌池？" % state.skip_charges, "移除此牌", "正常翻牌")
		if should_skip:
			state.skip_charges -= 1
			return "skip_card"

	if hero == "ZZZZ" and state.skip_charges > 0:
		var should_rest := await _confirm_choice("补觉", "还剩 %d 次补觉机会。是否跳过翻牌并回复%dHP？" % [state.skip_charges, GameBalance.HERO_ZZZZ_REST_HEAL], "补觉回血", "正常翻牌")
		if should_rest:
			state.skip_charges -= 1
			return "rest"

	return "reveal"


func _handle_hero_post_reveal(dc: Dictionary, current_fate: String) -> Variant:
	var hero: String = state.player_character["code"]
	if hero == "FAKE" and state.fate_reverse_charges > 0:
		var reverse := await _confirm_choice("变脸", "还剩 %d 次变脸机会。是否将此牌反转为「%s」？" % [state.fate_reverse_charges, "敌人" if current_fate == "ally" else "伙伴"], "反转命运", "维持原样")
		if reverse:
			state.fate_reverse_charges -= 1
			_show_hero_skill_feedback()
			_append_log("变脸发动！%s 的命运被反转为 %s。" % [dc["character"]["code"], "敌人" if current_fate == "ally" else "伙伴"])
			return "enemy" if current_fate == "ally" else "ally"

	if hero == "WOC!" and state.reroll_charges > 0:
		var reroll := await _confirm_choice("重来", "还剩 %d 次重来机会。是否弃掉本张牌重新翻一张？" % state.reroll_charges, "弃牌重翻", "正常结算")
		if reroll:
			state.reroll_charges -= 1
			return "reroll"

	return current_fate


func _prompt_fate_choice(title: String) -> String:
	return await _present_choice(title, "选择下一张牌的命运。", [
		{"text": "设为伙伴", "value": "ally", "variant": "primary"},
		{"text": "设为敌人", "value": "enemy", "variant": "primary"},
	])


func _choose_mimic_target(source_ally: Dictionary = {}):
	var source_uid := int(source_ally.get("uid", -1)) if not source_ally.is_empty() else -1
	var candidates: Array = []
	for ally in state.allies:
		if int(ally.get("uid", -1)) == source_uid or ally["is_spy"]:
			continue
		candidates.append(ally)

	if candidates.is_empty():
		return null

	var options: Array = []
	for ally in candidates:
		options.append({
			"text": ally["character"]["code"],
			"value": ally,
			"variant": "primary",
		})
	return await _present_choice("模仿", "选择一个伙伴让 FAKE 复制其技能。", options)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and log_backdrop != null and log_backdrop.visible:
			_hide_log_modal()
			get_viewport().set_input_as_handled()


# ══════════════════════════════════════════
# 贴图辅助
# ══════════════════════════════════════════

func _load_texture_from_disk(res_path: String) -> Texture2D:
	return asset_helper.load_texture_from_disk(res_path)


func _load_ui_theater(filename: String) -> Texture2D:
	return asset_helper.load_ui_theater(filename)


func _get_table_background_texture() -> Texture2D:
	return asset_helper.get_table_background_texture(BATTLE_BACKGROUND_PATH)


func _normalize_card_fate_variant(fate_variant: String) -> String:
	return asset_helper.normalize_fate_variant(fate_variant)


func _get_character_avatar_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	return asset_helper.get_character_avatar_texture(character, fate_variant)


func _get_small_hand_card_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	return asset_helper.get_small_hand_card_texture(character, fate_variant)


func _get_reveal_card_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	return asset_helper.get_reveal_card_texture(character, fate_variant)


func _get_hand_card_art_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	return asset_helper.get_hand_card_art_texture(character, fate_variant)


func _generate_table_surface_texture() -> Texture2D:
	table_surface_texture = asset_helper.generate_table_surface_texture()
	return table_surface_texture


func _generate_pedestal_body_texture() -> Texture2D:
	pedestal_body_texture = asset_helper.generate_pedestal_body_texture()
	return pedestal_body_texture


func _generate_seat_card_pedestal_texture() -> Texture2D:
	seat_card_pedestal_texture = asset_helper.generate_seat_card_pedestal_texture()
	return seat_card_pedestal_texture


func _generate_seat_card_border_texture() -> Texture2D:
	seat_card_border_texture = asset_helper.generate_seat_card_border_texture()
	return seat_card_border_texture


func _generate_play_zone_texture() -> Texture2D:
	play_zone_texture = asset_helper.generate_play_zone_texture()
	return play_zone_texture


func _generate_card_shadow_texture() -> Texture2D:
	card_shadow_texture = asset_helper.generate_card_shadow_texture()
	return card_shadow_texture


func _generate_avatar_ring_texture() -> Texture2D:
	avatar_ring_texture = asset_helper.generate_avatar_ring_texture()
	return avatar_ring_texture


func _generate_avatar_glow_texture() -> Texture2D:
	avatar_glow_texture = asset_helper.generate_avatar_glow_texture()
	return avatar_glow_texture


func _generate_soft_glow_texture() -> Texture2D:
	soft_glow_texture = asset_helper.generate_soft_glow_texture()
	return soft_glow_texture


# ══════════════════════════════════════════
# 着色器辅助
# ══════════════════════════════════════════

## 生成卡牌背面纹理（程序化生成，不依赖外部资源）
