extends Control

const TitleScreen := preload("res://scripts/title_screen.gd")
const SelectScreen := preload("res://scripts/select_screen.gd")
const BattleScreen := preload("res://scripts/battle_screen.gd")
const ResultScreen := preload("res://scripts/result_screen.gd")
const GameAudio := preload("res://scripts/game_audio.gd")
const MIN_WINDOW_SIZE := Vector2i(320, 180)
const TITLE_BGM_KEY := "title_screen_theme"
const SELECT_BGM_KEY := "select_screen_theme"
const BATTLE_BGM_KEY := "battle_screen_theme"
const BATTLE_BGM_DELAY_SEC := 1.0

enum TransitionType {
	INSTANT,
	FADE,
	SCALE_FADE,
	SLIDE_UP,
	SLIDE_DOWN,
	CURTAIN,
}

var state := GameState.new()
var current_screen: Control
var transition_overlay: ColorRect
var game_audio: GameAudio
var is_transitioning := false
var _bgm_request_serial := 0


func _ready() -> void:
	randomize()
	_configure_window()
	_setup_audio()
	_setup_transition_overlay()
	_show_title()


func _configure_window() -> void:
	var window := get_window()
	window.min_size = MIN_WINDOW_SIZE


func _setup_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.color = Color(0.04, 0.025, 0.015, 0)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000
	add_child(transition_overlay)


func _setup_audio() -> void:
	game_audio = GameAudio.new()
	game_audio.name = "GameAudio"
	add_child(game_audio)


func _queue_bgm(key: String, delay_sec: float = 0.0) -> void:
	_bgm_request_serial += 1
	var request_serial := _bgm_request_serial
	if game_audio == null:
		return
	if delay_sec <= 0.0:
		game_audio.play_bgm(key)
		return
	_play_bgm_after_delay(request_serial, key, delay_sec)


func _cancel_pending_bgm() -> void:
	_bgm_request_serial += 1


func _play_bgm_after_delay(request_serial: int, key: String, delay_sec: float) -> void:
	await get_tree().create_timer(delay_sec).timeout
	if request_serial != _bgm_request_serial:
		return
	if game_audio == null:
		return
	game_audio.play_bgm(key)


func _swap_screen(screen: Control, type: TransitionType = TransitionType.FADE) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if type == TransitionType.INSTANT or current_screen == null:
		if current_screen != null:
			current_screen.queue_free()
		current_screen = screen
		add_child(screen)
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		is_transitioning = false
		return

	var out_duration := 0.22
	var hold_duration := 0.06
	var in_duration := 0.32

	var viewport_size := get_viewport_rect().size

	# Phase 1: animate out current screen
	var out_tween := create_tween()
	out_tween.set_trans(Tween.TRANS_CUBIC)
	out_tween.set_ease(Tween.EASE_IN)

	match type:
		TransitionType.FADE:
			out_tween.tween_property(current_screen, "modulate:a", 0.0, out_duration)
		TransitionType.SCALE_FADE:
			current_screen.pivot_offset = viewport_size / 2
			out_tween.parallel().tween_property(current_screen, "modulate:a", 0.0, out_duration)
			out_tween.parallel().tween_property(current_screen, "scale", Vector2(1.04, 1.04), out_duration)
		TransitionType.SLIDE_UP:
			out_tween.parallel().tween_property(current_screen, "modulate:a", 0.0, out_duration)
			out_tween.parallel().tween_property(current_screen, "position:y", -40, out_duration)
		TransitionType.SLIDE_DOWN:
			out_tween.parallel().tween_property(current_screen, "modulate:a", 0.0, out_duration)
			out_tween.parallel().tween_property(current_screen, "position:y", 40, out_duration)
		TransitionType.CURTAIN:
			out_tween.tween_property(transition_overlay, "color:a", 1.0, out_duration)
		_:
			out_tween.tween_property(current_screen, "modulate:a", 0.0, out_duration)

	await out_tween.finished

	# Swap screens
	if current_screen != null:
		current_screen.queue_free()
	current_screen = screen
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Phase 2: brief hold with overlay (for curtain type)
	if type == TransitionType.CURTAIN:
		await get_tree().create_timer(hold_duration).timeout

	# Set initial state for incoming screen
	match type:
		TransitionType.FADE:
			screen.modulate.a = 0.0
		TransitionType.SCALE_FADE:
			screen.modulate.a = 0.0
			screen.scale = Vector2(0.96, 0.96)
			screen.pivot_offset = viewport_size / 2
		TransitionType.SLIDE_UP:
			screen.modulate.a = 0.0
			screen.position.y = 40
		TransitionType.SLIDE_DOWN:
			screen.modulate.a = 0.0
			screen.position.y = -40
		TransitionType.CURTAIN:
			screen.modulate.a = 1.0
		_:
			screen.modulate.a = 0.0

	# Phase 3: animate in new screen
	var in_tween := create_tween()
	in_tween.set_trans(Tween.TRANS_CUBIC)
	in_tween.set_ease(Tween.EASE_OUT)

	match type:
		TransitionType.FADE:
			in_tween.tween_property(screen, "modulate:a", 1.0, in_duration)
		TransitionType.SCALE_FADE:
			in_tween.parallel().tween_property(screen, "modulate:a", 1.0, in_duration)
			in_tween.parallel().tween_property(screen, "scale", Vector2(1.0, 1.0), in_duration)
		TransitionType.SLIDE_UP:
			in_tween.parallel().tween_property(screen, "modulate:a", 1.0, in_duration)
			in_tween.parallel().tween_property(screen, "position:y", 0, in_duration)
		TransitionType.SLIDE_DOWN:
			in_tween.parallel().tween_property(screen, "modulate:a", 1.0, in_duration)
			in_tween.parallel().tween_property(screen, "position:y", 0, in_duration)
		TransitionType.CURTAIN:
			in_tween.tween_property(transition_overlay, "color:a", 0.0, in_duration)
		_:
			in_tween.tween_property(screen, "modulate:a", 1.0, in_duration)

	await in_tween.finished

	# Reset any transform residuals
	match type:
		TransitionType.SCALE_FADE:
			screen.scale = Vector2(1, 1)
		TransitionType.SLIDE_UP, TransitionType.SLIDE_DOWN:
			screen.position.y = 0

	is_transitioning = false


func _show_title() -> void:
	if game_audio != null:
		game_audio.stop_persistent()
	_queue_bgm(TITLE_BGM_KEY)
	var screen: Control = TitleScreen.new()
	screen.start_requested.connect(_show_select)
	_swap_screen(screen, TransitionType.INSTANT)


func _show_select() -> void:
	if game_audio != null:
		game_audio.stop_persistent()
	_queue_bgm(SELECT_BGM_KEY)
	var screen: Control = SelectScreen.new()
	screen.setup(Characters.all_characters())
	screen.hero_confirmed.connect(_start_battle)
	_swap_screen(screen, TransitionType.SCALE_FADE)


func _start_battle(character: Dictionary) -> void:
	if game_audio != null:
		game_audio.stop_persistent()
		game_audio.stop_bgm()
	_queue_bgm(BATTLE_BGM_KEY, BATTLE_BGM_DELAY_SEC)
	state.start_run(character)
	var screen: Control = BattleScreen.new()
	screen.setup(state)
	screen.battle_finished.connect(_show_result)
	screen.exit_to_select_requested.connect(_show_select)
	_swap_screen(screen, TransitionType.CURTAIN)


func _show_result() -> void:
	_cancel_pending_bgm()
	if game_audio != null:
		game_audio.stop_bgm()
	var screen: Control = ResultScreen.new()
	screen.setup(state)
	screen.theater_requested.connect(_show_title)
	screen.replay_requested.connect(_show_select)
	_swap_screen(screen, TransitionType.SLIDE_UP)
