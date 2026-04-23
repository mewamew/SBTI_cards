extends RefCounted
class_name UIFactory


static func make_panel(bg_color: Color, border_color: Color, radius: int = 10, border_width: int = 2) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.20, 0.27, 0.42, 0.10)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func make_label(text: String, size: int = 18, color: Color = Color("f5f5f5"), bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.18))
	return label


static func make_button(text: String, bg_color: Color = Color("c9a84c"), font_color: Color = Color("1a1a2e")) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.corner_radius_top_left = 999
	normal.corner_radius_top_right = 999
	normal.corner_radius_bottom_right = 999
	normal.corner_radius_bottom_left = 999
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = bg_color.lerp(Color.WHITE, 0.35)
	normal.shadow_color = Color(0.24, 0.28, 0.42, 0.12)
	normal.shadow_size = 14
	normal.shadow_offset = Vector2(0, 7)
	var hover := normal.duplicate()
	hover.bg_color = bg_color.lerp(Color.WHITE, 0.18)
	hover.shadow_size = 18
	var pressed := normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.08)
	pressed.shadow_size = 7
	pressed.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


static func make_glass_style(accent_color: Color = Color("8eb8ff"), radius: int = 26, fill_alpha: float = 0.62, border_alpha: float = 0.34) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, fill_alpha)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, border_alpha)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.10)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 10)
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	return style


static func make_glass_panel(accent_color: Color = Color("8eb8ff"), radius: int = 26, fill_alpha: float = 0.62, border_alpha: float = 0.34) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", make_glass_style(accent_color, radius, fill_alpha, border_alpha))
	return panel


static func make_background_texture(texture_path: String, modulate: Color = Color.WHITE) -> TextureRect:
	var rect := TextureRect.new()
	var texture: Texture2D = null
	var image := Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if image != null and not image.is_empty():
		texture = ImageTexture.create_from_image(image)
	elif ResourceLoader.exists(texture_path):
		texture = load(texture_path) as Texture2D
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.modulate = modulate
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


static func make_rich_text() -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = true
	text.scroll_following = false
	text.selection_enabled = true
	return text
