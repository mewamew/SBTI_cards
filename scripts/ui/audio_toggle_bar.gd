extends Control
class_name AudioToggleBar

const GameAudio := preload("res://scripts/game_audio.gd")
const ButtonFeedback := preload("res://scripts/ui/button_feedback.gd")

const BGM_ON_ICON_PATH := "res://assets/ui/audio_controls/bgm_on.png"
const BGM_OFF_ICON_PATH := "res://assets/ui/audio_controls/bgm_off.png"
const SFX_ON_ICON_PATH := "res://assets/ui/audio_controls/sfx_on.png"
const SFX_OFF_ICON_PATH := "res://assets/ui/audio_controls/sfx_off.png"
const PANEL_MARGIN := Vector2(18.0, 18.0)
const BUTTON_SIZE := Vector2(56.0, 56.0)
const ICON_INSET := 2.0

@export var show_sfx_toggle := false

var _audio: GameAudio
var _panel: PanelContainer
var _row: HBoxContainer
var _bgm_button: Button
var _sfx_button: Button
var _bgm_icon: TextureRect
var _sfx_icon: TextureRect
var _bgm_on_texture: Texture2D
var _bgm_off_texture: Texture2D
var _sfx_on_texture: Texture2D
var _sfx_off_texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 240
	_load_textures()
	_build_ui()
	_bind_audio()
	_refresh_buttons()


func _load_textures() -> void:
	_bgm_on_texture = _load_texture(BGM_ON_ICON_PATH)
	_bgm_off_texture = _load_texture(BGM_OFF_ICON_PATH)
	_sfx_on_texture = _load_texture(SFX_ON_ICON_PATH)
	_sfx_off_texture = _load_texture(SFX_OFF_ICON_PATH)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "AudioTogglePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.position = PANEL_MARGIN
	_panel.z_index = 240
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_panel)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_row.add_theme_constant_override("separation", 8)
	_panel.add_child(_row)

	_bgm_button = _make_toggle_button()
	_bgm_button.tooltip_text = "关闭背景音乐"
	_bgm_button.pressed.connect(_on_bgm_button_pressed)
	_row.add_child(_bgm_button)
	_bgm_icon = _get_button_icon(_bgm_button)

	if show_sfx_toggle:
		_sfx_button = _make_toggle_button()
		_sfx_button.tooltip_text = "关闭音效"
		_sfx_button.pressed.connect(_on_sfx_button_pressed)
		_row.add_child(_sfx_button)
		_sfx_icon = _get_button_icon(_sfx_button)


func _make_toggle_button() -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.custom_minimum_size = BUTTON_SIZE
	button.size = BUTTON_SIZE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_button_style(true, false))
	button.add_theme_stylebox_override("hover", _make_button_style(true, true))
	button.add_theme_stylebox_override("pressed", _make_button_style(true, true, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ButtonFeedback.add_press_feedback(button, 0.94)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = ICON_INSET
	icon.offset_top = ICON_INSET
	icon.offset_right = -ICON_INSET
	icon.offset_bottom = -ICON_INSET
	button.add_child(icon)

	return button


func _get_button_icon(button: Button) -> TextureRect:
	return button.get_node("Icon") as TextureRect


func _bind_audio() -> void:
	_audio = GameAudio.get_shared(self)
	if _audio == null:
		visible = false
		call_deferred("_bind_audio_deferred")
		return
	visible = true
	_audio.bgm_enabled_changed.connect(_on_bgm_enabled_changed)
	_audio.sfx_enabled_changed.connect(_on_sfx_enabled_changed)


func _bind_audio_deferred() -> void:
	if _audio != null:
		return
	_audio = GameAudio.get_shared(self)
	if _audio == null:
		return
	visible = true
	_audio.bgm_enabled_changed.connect(_on_bgm_enabled_changed)
	_audio.sfx_enabled_changed.connect(_on_sfx_enabled_changed)
	_refresh_buttons()


func _on_bgm_button_pressed() -> void:
	if _audio == null:
		return
	_audio.toggle_bgm_enabled()


func _on_sfx_button_pressed() -> void:
	if _audio == null:
		return
	_audio.toggle_sfx_enabled()


func _on_bgm_enabled_changed(_enabled: bool) -> void:
	_refresh_buttons()


func _on_sfx_enabled_changed(_enabled: bool) -> void:
	_refresh_buttons()


func _refresh_buttons() -> void:
	if _audio == null:
		return

	var bgm_on := _audio.bgm_enabled
	if _bgm_icon != null:
		_bgm_icon.texture = _bgm_on_texture if bgm_on else _bgm_off_texture
	if _bgm_button != null:
		_apply_button_state(_bgm_button, bgm_on)
		_bgm_button.tooltip_text = "关闭背景音乐" if bgm_on else "开启背景音乐"

	if show_sfx_toggle and _sfx_button != null and _sfx_icon != null:
		var sfx_on := _audio.sfx_enabled
		_sfx_icon.texture = _sfx_on_texture if sfx_on else _sfx_off_texture
		_apply_button_state(_sfx_button, sfx_on)
		_sfx_button.tooltip_text = "关闭音效" if sfx_on else "开启音效"


func _apply_button_state(button: Button, is_enabled: bool) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(is_enabled, false))
	button.add_theme_stylebox_override("hover", _make_button_style(is_enabled, true))
	button.add_theme_stylebox_override("pressed", _make_button_style(is_enabled, true, true))


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.03, 0.02, 0.44)
	style.border_color = Color(0.86, 0.68, 0.36, 0.28)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _make_button_style(is_enabled: bool, is_hovered: bool, is_pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.08, 0.06, 0.12 if is_enabled else 0.04)
	style.border_color = Color(0.94, 0.78, 0.42, 0.42 if is_enabled else 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0.86, 0.62, 0.26, 0.18 if is_enabled else 0.08)
	style.shadow_size = 12 if is_hovered else 8
	style.shadow_offset = Vector2(0, 5 if is_pressed else 7)
	if is_pressed:
		style.bg_color = style.bg_color.darkened(0.08)
	return style
