extends RefCounted
class_name TheaterModal

const UIFactory = preload("res://scripts/ui_factory.gd")

const MODAL_FRAME_PATH := "res://assets/ui/theater/modal_parchment.png"
const MODAL_LOG_FRAME_PATH := MODAL_FRAME_PATH
const MODAL_BUTTON_PATH := "res://assets/ui/theater/modal_button_red.png"

const TITLE_COLOR := Color("f5e9c8")
const BODY_COLOR := Color("5b4530")
const BODY_ACCENT := Color("e8d8b0")
const GOLD_EDGE := Color("d1a85a")
const OUTLINE_COLOR := Color("36110d")
const WINE_DARK := Color(0.23, 0.07, 0.06, 0.96)
const WINE_LIGHT := Color(0.33, 0.11, 0.10, 0.98)
const CHOICE_PANEL_ASPECT := 2620.0 / 1014.0
const CHOICE_CONTENT_LEFT_RATIO := 0.080
const CHOICE_CONTENT_RIGHT_RATIO := 0.920
const CHOICE_CONTENT_TOP_RATIO := 0.104
const CHOICE_CONTENT_BOTTOM_RATIO := 0.935
const CHOICE_CONTENT_MARGIN_X := 22
const CHOICE_CONTENT_MARGIN_TOP := 12
const CHOICE_CONTENT_MARGIN_BOTTOM := 10
const LOG_CONTENT_LEFT_RATIO := 0.082
const LOG_CONTENT_RIGHT_RATIO := 0.918
const LOG_CONTENT_TOP_RATIO := 0.104
const LOG_CONTENT_BOTTOM_RATIO := 0.930
const LOG_CONTENT_MARGIN_X := 22
const LOG_CONTENT_MARGIN_TOP := 10
const LOG_CONTENT_MARGIN_BOTTOM := 12
const LOG_HEADER_HEIGHT := 54

static var _modal_frame_texture: Texture2D
static var _modal_log_frame_texture: Texture2D
static var _modal_button_texture: Texture2D


static func build_choice_modal(host: Control) -> Dictionary:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.76)
	backdrop.visible = false
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.z_index = 200
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(backdrop)

	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(holder)

	var panel := _make_texture_panel(_get_modal_frame_texture())
	panel.custom_minimum_size = Vector2(960, roundi(960.0 / CHOICE_PANEL_ASPECT))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.anchor_left = CHOICE_CONTENT_LEFT_RATIO
	content_margin.anchor_top = CHOICE_CONTENT_TOP_RATIO
	content_margin.anchor_right = CHOICE_CONTENT_RIGHT_RATIO
	content_margin.anchor_bottom = CHOICE_CONTENT_BOTTOM_RATIO
	content_margin.add_theme_constant_override("margin_left", CHOICE_CONTENT_MARGIN_X)
	content_margin.add_theme_constant_override("margin_top", CHOICE_CONTENT_MARGIN_TOP)
	content_margin.add_theme_constant_override("margin_right", CHOICE_CONTENT_MARGIN_X)
	content_margin.add_theme_constant_override("margin_bottom", CHOICE_CONTENT_MARGIN_BOTTOM)
	panel.add_child(content_margin)

	var modal_root := VBoxContainer.new()
	modal_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_root.add_theme_constant_override("separation", 10)
	content_margin.add_child(modal_root)

	var title := _make_choice_title_label("")
	modal_root.add_child(title)

	var body_center := CenterContainer.new()
	body_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_root.add_child(body_center)

	var body := _make_body_text()
	body.custom_minimum_size = Vector2(0, 54)
	body_center.add_child(body)

	var detail_panel := _make_inner_panel()
	detail_panel.visible = false
	detail_panel.custom_minimum_size = Vector2(0, 120)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_root.add_child(detail_panel)

	var detail_text := _make_detail_text(true)
	detail_text.custom_minimum_size = Vector2(0, 96)
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_text)

	var flex_spacer := Control.new()
	flex_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_root.add_child(flex_spacer)

	var buttons_center := CenterContainer.new()
	buttons_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_root.add_child(buttons_center)

	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_theme_constant_override("separation", 8)
	buttons_center.add_child(buttons)

	var tooltip_panel := _make_inner_panel()
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.custom_minimum_size = Vector2(296, 184)
	tooltip_panel.z_index = 210
	backdrop.add_child(tooltip_panel)

	var tooltip_text := _make_detail_text(false)
	tooltip_text.fit_content = true
	tooltip_text.scroll_active = false
	tooltip_text.custom_minimum_size = Vector2(264, 150)
	tooltip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(tooltip_text)

	return {
		"backdrop": backdrop,
		"panel": panel,
		"modal_root": modal_root,
		"body_center": body_center,
		"title": title,
		"body": body,
		"detail_panel": detail_panel,
		"detail_text": detail_text,
		"flex_spacer": flex_spacer,
		"buttons_center": buttons_center,
		"buttons": buttons,
		"tooltip_panel": tooltip_panel,
		"tooltip_text": tooltip_text,
	}


static func build_log_modal(host: Control, log_box: RichTextLabel) -> Dictionary:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.76)
	backdrop.visible = false
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.z_index = 180
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(backdrop)

	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(holder)

	var panel := _make_texture_panel(_get_modal_log_frame_texture())
	panel.custom_minimum_size = Vector2(1120, roundi(1120.0 / CHOICE_PANEL_ASPECT))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.anchor_left = LOG_CONTENT_LEFT_RATIO
	content_margin.anchor_top = LOG_CONTENT_TOP_RATIO
	content_margin.anchor_right = LOG_CONTENT_RIGHT_RATIO
	content_margin.anchor_bottom = LOG_CONTENT_BOTTOM_RATIO
	content_margin.add_theme_constant_override("margin_left", LOG_CONTENT_MARGIN_X)
	content_margin.add_theme_constant_override("margin_top", LOG_CONTENT_MARGIN_TOP)
	content_margin.add_theme_constant_override("margin_right", LOG_CONTENT_MARGIN_X)
	content_margin.add_theme_constant_override("margin_bottom", LOG_CONTENT_MARGIN_BOTTOM)
	panel.add_child(content_margin)

	var content_root := VBoxContainer.new()
	content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_theme_constant_override("separation", 10)
	content_margin.add_child(content_root)

	var header := Control.new()
	header.custom_minimum_size = Vector2(0, LOG_HEADER_HEIGHT)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_root.add_child(header)

	var title := _make_choice_title_label("完整战报")
	var title_host := CenterContainer.new()
	title_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_host.offset_left = 56.0
	title_host.offset_right = -56.0
	header.add_child(title_host)
	title_host.add_child(title)

	var close_button := make_close_button()
	close_button.anchor_left = 1.0
	close_button.anchor_top = 0.0
	close_button.anchor_right = 1.0
	close_button.anchor_bottom = 0.0
	close_button.offset_left = -48.0
	close_button.offset_top = 2.0
	close_button.offset_right = -4.0
	close_button.offset_bottom = 46.0
	header.add_child(close_button)

	log_box.fit_content = false
	log_box.scroll_active = true
	log_box.selection_enabled = true
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_theme_color_override("default_color", BODY_COLOR)
	log_box.add_theme_font_size_override("normal_font_size", 18)
	content_root.add_child(log_box)

	return {
		"backdrop": backdrop,
		"panel": panel,
		"close_button": close_button,
	}


static func make_option_button(text: String, variant: String = "primary") -> Button:
	if variant == "secondary":
		return _make_secondary_button(text)
	return _make_primary_button(text)


static func set_option_button_text(button: Button, text: String) -> void:
	if button == null:
		return
	var display_label := button.get_meta("display_label", null) as Label
	if display_label != null:
		display_label.text = text
	else:
		button.text = text


static func make_close_button() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = "✕"
	button.custom_minimum_size = Vector2(42, 42)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TITLE_COLOR)
	button.add_theme_color_override("font_hover_color", Color("fff3d8"))
	button.add_theme_color_override("font_pressed_color", BODY_ACCENT)
	button.add_theme_color_override("font_focus_color", TITLE_COLOR)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_outline_color", OUTLINE_COLOR)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.20, 0.06, 0.05, 0.76)
	normal.border_color = GOLD_EDGE
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.shadow_color = Color(0, 0, 0, 0.20)
	normal.shadow_size = 12
	normal.shadow_offset = Vector2(0, 5)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.28, 0.10, 0.09, 0.86)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.16, 0.05, 0.05, 0.92)
	pressed.shadow_size = 6
	pressed.shadow_offset = Vector2(0, 2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	return button


static func _make_texture_panel(texture: Texture2D) -> TextureRect:
	var panel := TextureRect.new()
	panel.texture = texture
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return panel


static func _make_frame_panel(texture: Texture2D, left: int, right: int, top: int, bottom: int) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = texture
	panel.patch_margin_left = left
	panel.patch_margin_right = right
	panel.patch_margin_top = top
	panel.patch_margin_bottom = bottom
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return panel


static func _make_title_label(text: String, font_size: int) -> Label:
	var title := UIFactory.make_label(text, font_size, TITLE_COLOR, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	return title


static func _make_choice_title_label(text: String) -> Label:
	var title := UIFactory.make_label(text, 29, Color("5f3417"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.custom_minimum_size = Vector2(0, 48)
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color("f5e7c3"))
	return title


static func _make_body_text() -> RichTextLabel:
	var text := UIFactory.make_rich_text()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.selection_enabled = false
	text.add_theme_color_override("default_color", BODY_COLOR)
	text.add_theme_font_size_override("normal_font_size", 22)
	return text


static func _make_detail_text(scroll_active: bool) -> RichTextLabel:
	var text := UIFactory.make_rich_text()
	text.bbcode_enabled = true
	text.fit_content = not scroll_active
	text.scroll_active = scroll_active
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.selection_enabled = false
	text.add_theme_color_override("default_color", BODY_ACCENT)
	text.add_theme_font_size_override("normal_font_size", 16)
	return text


static func _make_inner_panel() -> PanelContainer:
	var panel := UIFactory.make_panel(WINE_DARK, GOLD_EDGE, 18, 2)
	var style := panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		flat.bg_color = WINE_DARK
		flat.border_color = GOLD_EDGE
		flat.shadow_color = Color(0, 0, 0, 0.20)
		flat.shadow_size = 14
		flat.shadow_offset = Vector2(0, 6)
		flat.content_margin_left = 18
		flat.content_margin_top = 16
		flat.content_margin_right = 18
		flat.content_margin_bottom = 16
	return panel


static func _make_primary_button(text: String) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	button.custom_minimum_size = Vector2(320, 56)

	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)

	var background := TextureRect.new()
	background.texture = _get_modal_button_texture()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(background)
	button.set_meta("background", background)

	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("fff0cf"))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(label)
	button.set_meta("display_label", label)

	button.set_meta("hovered", false)
	button.set_meta("pressed_state", false)
	var button_id := button.get_instance_id()
	button.mouse_entered.connect(func() -> void:
		_update_primary_button_state(button_id, true, null)
	)
	button.mouse_exited.connect(func() -> void:
		_update_primary_button_state(button_id, false, false)
	)
	button.button_down.connect(func() -> void:
		_update_primary_button_state(button_id, null, true)
	)
	button.button_up.connect(func() -> void:
		_update_primary_button_state(button_id, null, false)
	)
	_refresh_primary_button_visual(button, background, label)
	return button


static func _make_secondary_button(text: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = text
	button.custom_minimum_size = Vector2(320, 50)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", BODY_ACCENT)
	button.add_theme_color_override("font_focus_color", BODY_ACCENT)
	button.add_theme_color_override("font_hover_color", Color("f8e8be"))
	button.add_theme_color_override("font_pressed_color", BODY_ACCENT)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_outline_color", OUTLINE_COLOR)

	var normal := StyleBoxFlat.new()
	normal.bg_color = WINE_LIGHT
	normal.border_color = GOLD_EDGE
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
	hover.bg_color = Color(0.40, 0.14, 0.12, 0.98)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.20, 0.06, 0.05, 1.0)
	pressed.shadow_size = 6
	pressed.shadow_offset = Vector2(0, 2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	return button


static func _refresh_primary_button_visual(button: Button, background: TextureRect, label: Label) -> void:
	var hovered := bool(button.get_meta("hovered", false))
	var pressed := bool(button.get_meta("pressed_state", false))
	var bg_modulate := Color.WHITE
	var label_color := Color("fff0cf")
	if hovered:
		bg_modulate = Color(1.06, 1.04, 1.00, 1.0)
		label_color = Color("fff7df")
	if pressed:
		bg_modulate = Color(0.90, 0.88, 0.84, 1.0)
		label_color = Color("f6e1b1")
	background.modulate = bg_modulate
	label.add_theme_color_override("font_color", label_color)


static func _update_primary_button_state(button_id: int, hovered: Variant, pressed: Variant) -> void:
	var button := instance_from_id(button_id) as Button
	if button == null or not is_instance_valid(button):
		return
	if hovered != null:
		button.set_meta("hovered", bool(hovered))
	if pressed != null:
		button.set_meta("pressed_state", bool(pressed))
	var background := button.get_meta("background", null) as TextureRect
	var label := button.get_meta("display_label", null) as Label
	if background == null or label == null or not is_instance_valid(background) or not is_instance_valid(label):
		return
	_refresh_primary_button_visual(button, background, label)


static func _get_modal_frame_texture() -> Texture2D:
	if _modal_frame_texture == null:
		_modal_frame_texture = _load_texture(MODAL_FRAME_PATH)
	return _modal_frame_texture


static func _get_modal_log_frame_texture() -> Texture2D:
	if _modal_log_frame_texture == null:
		_modal_log_frame_texture = _load_texture(MODAL_LOG_FRAME_PATH)
	return _modal_log_frame_texture


static func _get_modal_button_texture() -> Texture2D:
	if _modal_button_texture == null:
		_modal_button_texture = _load_texture(MODAL_BUTTON_PATH)
	return _modal_button_texture


static func _load_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image != null and not image.is_empty():
		return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
