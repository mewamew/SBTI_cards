extends RefCounted


const GameBalance = preload("res://scripts/game_balance.gd")
const UIFactory = preload("res://scripts/ui_factory.gd")


var asset_helper = null


func set_asset_helper(next_asset_helper) -> void:
	asset_helper = next_asset_helper


func normalize_fate_variant(fate_variant: String) -> String:
	if asset_helper != null and asset_helper.has_method("normalize_fate_variant"):
		return asset_helper.normalize_fate_variant(fate_variant)
	return "enemy" if fate_variant == "enemy" else "ally"


func get_rarity_border_color(character: Dictionary) -> Color:
	return GameBalance.get_rarity_color(character)


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


func apply_card_visual_size(card_visual: Control, card_size: Vector2) -> void:
	if card_visual == null:
		return
	card_visual.custom_minimum_size = card_size
	card_visual.size = card_size
	card_visual.pivot_offset = card_size * 0.5
	if not card_visual.has_meta("frame"):
		return
	var frame := _get_object_meta_value(card_visual, "frame") as PanelContainer
	if frame == null:
		return
	if bool(_get_object_meta_value(card_visual, "uses_small_card_texture", false)):
		var art_holder_small := _get_object_meta_value(card_visual, "art_holder") as Control
		if art_holder_small != null:
			art_holder_small.offset_left = 0.0
			art_holder_small.offset_top = 0.0
			art_holder_small.offset_right = 0.0
			art_holder_small.offset_bottom = 0.0
		var portrait_small := _get_object_meta_value(card_visual, "portrait") as TextureRect
		if portrait_small != null:
			portrait_small.offset_left = 0.0
			portrait_small.offset_top = 0.0
			portrait_small.offset_right = 0.0
			portrait_small.offset_bottom = 0.0
		var name_tag_small := _get_object_meta_value(card_visual, "name_tag") as Label
		if name_tag_small != null:
			name_tag_small.visible = false
		return

	var name_height := clampf(card_size.y * 0.11, 22.0, 34.0)
	var side_padding := clampf(card_size.x * 0.03, 4.0, 8.0)
	var top_padding := clampf(card_size.y * 0.03, 4.0, 10.0)
	var art_holder := _get_object_meta_value(card_visual, "art_holder") as Control
	if art_holder != null:
		art_holder.position = Vector2(side_padding, name_height)
		art_holder.size = Vector2(card_size.x - side_padding * 2.0, card_size.y - name_height - top_padding)
	var portrait := _get_object_meta_value(card_visual, "portrait") as TextureRect
	if portrait != null:
		portrait.offset_left = -card_size.x * 0.04
		portrait.offset_top = -card_size.y * 0.03
		portrait.offset_right = card_size.x * 0.04
		portrait.offset_bottom = 0.0
	var name_tag := _get_object_meta_value(card_visual, "name_tag") as Label
	if name_tag != null:
		name_tag.offset_top = top_padding
		name_tag.offset_bottom = top_padding + name_height
		name_tag.add_theme_font_size_override("font_size", maxi(13, int(card_size.y * 0.065)))


func create_textured_card_visual(texture: Texture2D, card_size: Vector2, fate_variant: String = "ally") -> Control:
	if texture == null:
		return null

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = card_size
	root.size = card_size
	root.pivot_offset = card_size * 0.5
	root.set_meta("uses_small_card_texture", true)
	root.set_meta("fate_variant", normalize_fate_variant(fate_variant))

	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(1, 1, 1, 0.0)
	frame_style.corner_radius_top_left = 28
	frame_style.corner_radius_top_right = 28
	frame_style.corner_radius_bottom_right = 28
	frame_style.corner_radius_bottom_left = 28
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(1, 1, 1, 0.08)
	frame_style.shadow_color = Color(0, 0, 0, 0.22)
	frame_style.shadow_size = 18
	frame_style.shadow_offset = Vector2(0, 10)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.set_meta("base_panel_style", frame_style.duplicate())
	root.add_child(frame)

	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.clip_contents = false
	frame.add_child(content)

	var art_holder := Control.new()
	art_holder.name = "ArtHolder"
	art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_holder.clip_contents = false
	content.add_child(art_holder)

	var image := TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.modulate = Color.WHITE
	art_holder.add_child(image)

	root.set_meta("frame", frame)
	root.set_meta("portrait", image)
	root.set_meta("art_holder", art_holder)
	apply_card_visual_size(root, card_size)
	return root


func create_small_card_visual(character: Dictionary, card_size: Vector2, fate_variant: String = "ally") -> Control:
	if asset_helper == null:
		return null
	return create_textured_card_visual(asset_helper.get_small_hand_card_texture(character, fate_variant), card_size, fate_variant)


func create_reveal_card_visual(character: Dictionary, card_size: Vector2, fate_variant: String = "ally") -> Control:
	if asset_helper == null:
		return null
	return create_textured_card_visual(asset_helper.get_reveal_card_texture(character, fate_variant), card_size, fate_variant)


func create_card_visual(
	character: Dictionary,
	card_size: Vector2,
	selected: bool = true,
	fate_variant: String = "ally",
	show_name_tag: bool = true
) -> Control:
	var display_variant := normalize_fate_variant(fate_variant)
	var small_card_visual := create_small_card_visual(character, card_size, display_variant)
	if small_card_visual != null:
		return small_card_visual

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = card_size
	root.size = card_size
	root.pivot_offset = card_size * 0.5

	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame_style := make_card_style(character, selected, false, {}, display_variant)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.set_meta("base_panel_style", frame_style.duplicate())
	root.add_child(frame)

	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.clip_contents = false
	frame.add_child(content)

	var art_holder := Control.new()
	art_holder.name = "ArtHolder"
	art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_holder.clip_contents = false
	content.add_child(art_holder)

	var image := TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if asset_helper != null:
		image.texture = asset_helper.get_hand_card_art_texture(character, display_variant)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.modulate = Color(0.98, 0.95, 0.96, 0.99) if display_variant == "enemy" else Color(1, 1, 1, 0.98)
	art_holder.add_child(image)

	var name_tag_color := Color("f2ded1") if display_variant == "enemy" else Color("2c3441")
	var name_tag := UIFactory.make_label(str(character.get("code", "")), 13, name_tag_color, true)
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_tag.anchor_left = 0.0
	name_tag.anchor_right = 1.0
	name_tag.anchor_top = 0.0
	name_tag.anchor_bottom = 0.0
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_tag.modulate = Color("f7e3da") if display_variant == "enemy" else Color("27303d")
	name_tag.z_index = 3
	name_tag.visible = show_name_tag
	content.add_child(name_tag)

	root.set_meta("frame", frame)
	root.set_meta("portrait", image)
	root.set_meta("art_holder", art_holder)
	root.set_meta("name_tag", name_tag)
	root.set_meta("fate_variant", display_variant)
	apply_card_visual_size(root, card_size)
	return root


func create_card_back_visual(card_size: Vector2) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = card_size
	root.size = card_size
	root.pivot_offset = card_size * 0.5

	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("eef4ff").darkened(0.03)
	panel_style.border_color = Color("c9d6f1")
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 28
	panel_style.corner_radius_top_right = 28
	panel_style.corner_radius_bottom_left = 28
	panel_style.corner_radius_bottom_right = 28
	frame.add_theme_stylebox_override("panel", panel_style)
	root.add_child(frame)

	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(content)

	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 0.18
	badge.anchor_right = 0.82
	badge.anchor_top = 0.28
	badge.anchor_bottom = 0.72
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1, 1, 1, 0.34)
	var badge_border := Color("dbe5f8")
	badge_border.a = 0.88
	badge_style.border_color = badge_border
	badge_style.border_width_left = 2
	badge_style.border_width_top = 2
	badge_style.border_width_right = 2
	badge_style.border_width_bottom = 2
	badge_style.corner_radius_top_left = 24
	badge_style.corner_radius_top_right = 24
	badge_style.corner_radius_bottom_left = 24
	badge_style.corner_radius_bottom_right = 24
	badge.add_theme_stylebox_override("panel", badge_style)
	content.add_child(badge)

	var core := Panel.new()
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.anchor_left = 0.32
	core.anchor_right = 0.68
	core.anchor_top = 0.37
	core.anchor_bottom = 0.63
	var core_style := StyleBoxFlat.new()
	core_style.bg_color = Color(0.79, 0.85, 0.98, 0.72)
	core_style.corner_radius_top_left = 18
	core_style.corner_radius_top_right = 18
	core_style.corner_radius_bottom_left = 18
	core_style.corner_radius_bottom_right = 18
	core.add_theme_stylebox_override("panel", core_style)
	content.add_child(core)

	return root


func get_card_glass_accent(character: Dictionary, peek_data: Dictionary = {}) -> Color:
	var accent := get_rarity_border_color(character).lightened(0.22)
	if not peek_data.is_empty():
		var hint_color := Color("4a9eff") if peek_data.get("fate", "") == "ally" else Color("ff8470")
		accent = accent.lerp(hint_color, 0.55)
	return accent


func apply_deck_card_button_styles(button: Button, character: Dictionary, selected: bool, peek_data: Dictionary = {}) -> void:
	var use_small_card := button != null and button.has_meta("use_small_card") and bool(button.get_meta("use_small_card"))
	var normal_style := make_small_card_style(character, selected, false, peek_data) if use_small_card else make_card_style(character, selected, false, peek_data)
	var hover_style := make_small_card_style(character, selected, true, peek_data) if use_small_card else make_card_style(character, selected, true, peek_data)
	var pressed_style := make_small_card_style(character, true, true, peek_data) if use_small_card else make_card_style(character, true, true, peek_data)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)


func make_small_card_style(character: Dictionary, selected: bool, hovered: bool, peek_data: Dictionary = {}) -> StyleBox:
	return StyleBoxEmpty.new()


func make_card_style(character: Dictionary, selected: bool, hovered: bool, peek_data: Dictionary = {}, fate_variant: String = "ally") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var display_variant := normalize_fate_variant(fate_variant)
	var accent := get_card_glass_accent(character, peek_data)
	if display_variant == "enemy":
		accent = accent.lerp(Color("ff7466"), 0.68)
	var fill := Color(0.95, 0.97, 1.0, 0.92)
	if display_variant == "enemy":
		fill = Color(0.18, 0.07, 0.10, 0.94)
		fill = fill.lerp(Color(accent.r, accent.g * 0.48, accent.b * 0.52, 0.94), 0.24)
	else:
		fill = fill.lerp(Color(accent.r, accent.g, accent.b, 0.92), 0.10)
	fill.a = 0.94 if display_variant == "enemy" else 0.92
	style.bg_color = fill
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_detail = 12
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.76).lerp(accent.lightened(0.82), 0.30)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.20)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 12)
	if display_variant == "enemy":
		style.border_color = Color(1.0, 0.90, 0.84, 0.80).lerp(accent.lightened(0.22), 0.46)
		style.shadow_color = Color(accent.r, accent.g * 0.38, accent.b * 0.40, 0.34)
		style.shadow_size = 28

	if hovered:
		if display_variant == "enemy":
			fill = fill.lerp(Color(0.30, 0.10, 0.14, 0.96), 0.18)
			fill.a = 0.96
			style.shadow_size = 34
			style.shadow_color = Color(accent.r, accent.g * 0.42, accent.b * 0.45, 0.40)
			style.border_color = Color(1.0, 0.92, 0.86, 0.90).lerp(accent.lightened(0.16), 0.52)
		else:
			fill = fill.lerp(Color(0.985, 0.992, 1.0, 0.92), 0.10)
			fill.a = 0.92
			style.shadow_size = 30
			style.shadow_color = Color(accent.r, accent.g, accent.b, 0.24)
			style.border_color = Color(1, 1, 1, 0.84).lerp(accent.lightened(0.72), 0.34)
		style.bg_color = fill

	if selected:
		if display_variant == "enemy":
			fill = fill.lerp(Color(0.38, 0.12, 0.17, 0.98), 0.28)
			fill.a = 0.98
			style.border_color = Color(1.0, 0.94, 0.88, 0.98).lerp(accent.lightened(0.12), 0.60)
			style.shadow_color = Color(accent.r, accent.g * 0.42, accent.b * 0.46, 0.50)
			style.shadow_size = 48
		else:
			fill = fill.lerp(Color(1.0, 0.998, 0.998, 0.98), 0.18)
			fill.a = 0.98
			style.border_color = Color(1, 1, 1, 0.98).lerp(accent.lightened(0.50), 0.52)
			style.shadow_color = Color(accent.r, accent.g, accent.b, 0.44)
			style.shadow_size = 46
		style.bg_color = fill
		style.shadow_offset = Vector2(0, 18)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3

	return style
