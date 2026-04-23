extends RefCounted


const UIFactory = preload("res://scripts/ui_factory.gd")
const CircularAvatarShader = preload("res://shaders/circular_avatar.gdshader")


var asset_helper = null
var hero_spotlight_manifest_loaded := false
var hero_spotlight_manifest_entries := {}


func set_asset_helper(next_asset_helper) -> void:
	asset_helper = next_asset_helper


func build_avatar_node(size: int, show_label: bool, avatar_glow_texture: Texture2D, avatar_ring_texture: Texture2D) -> Control:
	var label_height := 20 if show_label else 0
	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size + label_height + (4 if show_label else 0))
	root.size = root.custom_minimum_size

	var glow := TextureRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = avatar_glow_texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.position = Vector2(-size * 0.05, -size * 0.05)
	glow.size = Vector2.ONE * size * 1.10
	glow.modulate = Color(1, 1, 1, 0.12)
	root.add_child(glow)

	var mask := PanelContainer.new()
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.position = Vector2.ZERO
	mask.size = Vector2.ONE * size
	mask.clip_contents = false
	var mask_style := StyleBoxFlat.new()
	mask_style.bg_color = Color(1, 1, 1, 0.74)
	mask_style.corner_radius_top_left = size
	mask_style.corner_radius_top_right = size
	mask_style.corner_radius_bottom_left = size
	mask_style.corner_radius_bottom_right = size
	mask_style.border_color = Color("d9e5ff")
	mask_style.border_width_left = 1
	mask_style.border_width_top = 1
	mask_style.border_width_right = 1
	mask_style.border_width_bottom = 1
	mask.add_theme_stylebox_override("panel", mask_style)
	root.add_child(mask)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.material = _create_circular_avatar_material(Color("d9e5ff"), 0.024)
	portrait.visible = false
	mask.add_child(portrait)

	var symbol := UIFactory.make_label("?", maxi(20, int(size * 0.34)), Color("637089"), true)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mask.add_child(symbol)

	var ring := TextureRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.texture = avatar_ring_texture
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_SCALE
	ring.position = Vector2.ZERO
	ring.size = Vector2.ONE * size
	ring.modulate = Color("d9e5ff")
	root.add_child(ring)

	var code_label := UIFactory.make_label("", maxi(10, int(size * 0.14)), Color("f7efcf"), true)
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.position = Vector2(0, size + 4)
	code_label.custom_minimum_size = Vector2(size, label_height)
	code_label.visible = show_label
	root.add_child(code_label)

	root.set_meta("glow", glow)
	root.set_meta("mask", mask)
	root.set_meta("ring", ring)
	root.set_meta("portrait", portrait)
	root.set_meta("symbol", symbol)
	root.set_meta("code_label", code_label)
	root.set_meta("show_label", show_label)
	return root


func set_avatar_node(
	avatar: Control,
	character: Dictionary,
	tone: Color,
	avatar_texture: Texture2D = null,
	code_text: String = "",
	symbol_text: String = "?"
) -> void:
	if avatar == null:
		return
	var glow := avatar.get_meta("glow") as TextureRect
	var mask := avatar.get_meta("mask") as PanelContainer
	var ring := avatar.get_meta("ring") as TextureRect
	var portrait := avatar.get_meta("portrait") as TextureRect
	var symbol := avatar.get_meta("symbol") as Label
	var code_label := avatar.get_meta("code_label") as Label
	var show_label := bool(avatar.get_meta("show_label"))

	if glow != null:
		glow.modulate = Color(tone.r, tone.g, tone.b, 0.24 if not character.is_empty() else 0.10)
	if mask != null:
		var mask_style := mask.get_theme_stylebox("panel")
		if mask_style is StyleBoxFlat:
			var flat := mask_style as StyleBoxFlat
			flat.bg_color = Color(1, 1, 1, 0.76) if not character.is_empty() else Color(1, 1, 1, 0.56)
			flat.border_color = tone.lightened(0.18)
	if ring != null:
		ring.modulate = tone.lightened(0.18)
	if portrait != null and portrait.material is ShaderMaterial:
		(portrait.material as ShaderMaterial).set_shader_parameter("border_color", tone.lightened(0.18))

	if character.is_empty():
		if portrait != null:
			portrait.texture = null
			portrait.visible = false
		if symbol != null:
			symbol.visible = true
			symbol.text = symbol_text
			symbol.modulate = Color(tone.r, tone.g, tone.b, 0.92)
		if code_label != null:
			code_label.text = code_text
			code_label.visible = show_label and not code_text.is_empty()
		return

	if portrait != null:
		portrait.texture = avatar_texture
		portrait.visible = true
	if symbol != null:
		symbol.visible = false
	if code_label != null:
		var next_text: String = code_text if not code_text.is_empty() else str(character.get("code", ""))
		code_label.text = next_text
		code_label.visible = show_label and not next_text.is_empty()


func load_hero_spotlight_manifest(manifest_path: String) -> void:
	if hero_spotlight_manifest_loaded:
		return
	hero_spotlight_manifest_loaded = true
	hero_spotlight_manifest_entries.clear()

	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var entries: Variant = (parsed as Dictionary).get("entries", [])
	if not (entries is Array):
		return
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var code := str(entry.get("code", ""))
		if code.is_empty():
			continue
		hero_spotlight_manifest_entries[code] = entry.duplicate(true)


func resolve_hero_spotlight_entry(character: Dictionary, manifest_path: String) -> Dictionary:
	var code := str(character.get("code", ""))
	if code.is_empty():
		return {}

	load_hero_spotlight_manifest(manifest_path)
	if hero_spotlight_manifest_entries.has(code):
		return (hero_spotlight_manifest_entries[code] as Dictionary).duplicate(true)

	var fallback_pose := ""
	var pose_candidates: Array[String] = [
		"res://assets/portraits/cutout/ally/%s.png" % code,
		"res://assets/entrance_rituals/stage_poses/%s.png" % code,
		"res://assets/portraits/subject/ally/%s.png" % code,
	]
	for pose_path in pose_candidates:
		if _has_optional_texture(pose_path):
			fallback_pose = pose_path
			break

	return {
		"code": code,
		"quote": str(character.get("quote", "")),
		"stage_pose": fallback_pose,
		"halo_texture": "",
		"halo_color": "#f0c977",
		"subtitle_fill": "#fff0c1",
		"subtitle_stroke": "#483e2c",
	}


func color_from_manifest(value: Variant, fallback: Color) -> Color:
	var text := str(value)
	if text.is_empty():
		return fallback
	return Color.from_string(text, fallback)


func load_optional_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if asset_helper != null and asset_helper.has_method("load_texture_from_disk"):
		var disk_texture: Texture2D = asset_helper.load_texture_from_disk(path)
		if disk_texture != null:
			return disk_texture
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func refresh_hero_spotlight_layout(
	hero_spotlight_root: Control,
	seat_layer: Control,
	hero_spotlight_shadow: TextureRect,
	hero_spotlight_halo: TextureRect,
	hero_spotlight_pose: TextureRect,
	hero_spotlight_quote_backdrop: PanelContainer,
	hero_spotlight_quote_label: RichTextLabel,
	center: Vector2
) -> void:
	if hero_spotlight_root == null or seat_layer == null:
		return

	var stage_size := seat_layer.size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return

	var actor_size := Vector2(
		clampf(stage_size.x * 0.15, 176.0, 230.0),
		clampf(stage_size.y * 0.36, 208.0, 290.0)
	)
	var actor_pos := center - Vector2(actor_size.x * 0.5, actor_size.y * 0.26)
	hero_spotlight_root.position = actor_pos
	hero_spotlight_root.size = actor_size
	hero_spotlight_root.pivot_offset = Vector2(actor_size.x * 0.5, actor_size.y * 0.82)

	if hero_spotlight_shadow != null:
		hero_spotlight_shadow.size = Vector2(actor_size.x * 1.10, actor_size.x * 0.34)
		hero_spotlight_shadow.position = Vector2(
			(actor_size.x - hero_spotlight_shadow.size.x) * 0.5,
			actor_size.y - hero_spotlight_shadow.size.y * 0.86
		)

	if hero_spotlight_halo != null:
		hero_spotlight_halo.size = Vector2(actor_size.x * 1.58, actor_size.y * 1.08)
		hero_spotlight_halo.position = Vector2(
			(actor_size.x - hero_spotlight_halo.size.x) * 0.5,
			actor_size.y * -0.08
		)

	if hero_spotlight_pose != null:
		hero_spotlight_pose.size = actor_size
		hero_spotlight_pose.position = Vector2.ZERO

	if hero_spotlight_quote_backdrop != null:
		var max_left_space := maxf(220.0, actor_pos.x - 28.0)
		var quote_width := minf(clampf(stage_size.x * 0.31, 300.0, 420.0), max_left_space)
		var quote_height := 112.0
		hero_spotlight_quote_backdrop.custom_minimum_size = Vector2(quote_width, quote_height)
		hero_spotlight_quote_backdrop.size = hero_spotlight_quote_backdrop.custom_minimum_size
		hero_spotlight_quote_backdrop.position = Vector2(
			maxf(20.0, actor_pos.x - quote_width - 14.0),
			actor_pos.y + actor_size.y * 0.04
		)
		if hero_spotlight_quote_label != null:
			hero_spotlight_quote_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func apply_hero_spotlight_character(
	character: Dictionary,
	manifest_path: String,
	hero_spotlight_pose: TextureRect,
	hero_spotlight_halo: TextureRect,
	hero_spotlight_shadow: TextureRect,
	hero_spotlight_quote_backdrop: PanelContainer,
	hero_spotlight_quote_label: RichTextLabel,
	soft_glow_texture: Texture2D,
	target_body_alpha: float,
	target_halo_alpha: float
) -> Dictionary:
	var entry := resolve_hero_spotlight_entry(character, manifest_path)
	var halo_color := color_from_manifest(entry.get("halo_color", ""), Color("f0c977"))
	var subtitle_fill := color_from_manifest(entry.get("subtitle_fill", ""), halo_color.lightened(0.30))
	var subtitle_stroke := color_from_manifest(entry.get("subtitle_stroke", ""), Color("483e2c"))
	var code := str(character.get("code", ""))
	var pose_texture: Texture2D = null
	var pose_candidates: Array[String] = ["res://assets/portraits/cutout/ally/%s.png" % code]
	var manifest_stage_pose := str(entry.get("stage_pose", ""))
	if not manifest_stage_pose.is_empty():
		pose_candidates.append(manifest_stage_pose)
	pose_candidates.append("res://assets/entrance_rituals/stage_poses/%s.png" % code)
	pose_candidates.append("res://assets/portraits/subject/ally/%s.png" % code)
	for pose_path in pose_candidates:
		pose_texture = load_optional_texture(pose_path)
		if pose_texture != null:
			break
	if hero_spotlight_pose != null:
		hero_spotlight_pose.texture = pose_texture

	var halo_texture := load_optional_texture(str(entry.get("halo_texture", "")))
	if hero_spotlight_halo != null:
		hero_spotlight_halo.texture = halo_texture if halo_texture != null else soft_glow_texture
		hero_spotlight_halo.modulate = Color(halo_color.r, halo_color.g, halo_color.b, target_halo_alpha)

	if hero_spotlight_shadow != null:
		var shadow_color := subtitle_stroke.darkened(0.18)
		hero_spotlight_shadow.modulate = Color(shadow_color.r, shadow_color.g, shadow_color.b, target_body_alpha * 0.46)

	if hero_spotlight_quote_backdrop != null:
		var quote_style := hero_spotlight_quote_backdrop.get_theme_stylebox("panel")
		if quote_style is StyleBoxFlat:
			var flat := quote_style as StyleBoxFlat
			flat.bg_color = Color(subtitle_stroke.r, subtitle_stroke.g, subtitle_stroke.b, 0.38)
			flat.border_color = Color(subtitle_fill.r, subtitle_fill.g, subtitle_fill.b, 0.32)

	if hero_spotlight_quote_label != null:
		hero_spotlight_quote_label.text = "[right][font_size=22][i]「%s」[/i][/font_size][/right]" % str(entry.get("quote", character.get("quote", "")))
		hero_spotlight_quote_label.add_theme_color_override("default_color", subtitle_fill)
		hero_spotlight_quote_label.add_theme_color_override("font_outline_color", subtitle_stroke)
		hero_spotlight_quote_label.add_theme_constant_override("outline_size", 6)

	return entry


func _create_circular_avatar_material(border_color: Color, border_width: float = 0.03) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = CircularAvatarShader
	material.set_shader_parameter("border_color", border_color)
	material.set_shader_parameter("border_width", border_width)
	material.set_shader_parameter("smoothing", 0.018)
	return material


func _has_optional_texture(path: String) -> bool:
	return load_optional_texture(path) != null or ResourceLoader.exists(path)
