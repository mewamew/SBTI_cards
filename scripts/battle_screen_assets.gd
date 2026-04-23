extends RefCounted


var texture_cache := {}
var card_portrait_texture_cache := {}
var hand_card_art_texture_cache := {}
var hand_small_card_texture_cache := {}
var reveal_card_texture_cache := {}
var generated_texture_cache := {}


func normalize_fate_variant(fate_variant: String) -> String:
	return "enemy" if fate_variant == "enemy" else "ally"


func load_image_from_disk(res_path: String) -> Image:
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


func load_texture_from_disk(res_path: String) -> Texture2D:
	var image := load_image_from_disk(res_path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func load_ui_theater(filename: String) -> Texture2D:
	var path := "res://assets/ui/theater/%s" % filename
	var texture := load_texture_from_disk(path)
	if texture == null and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	return texture


func get_table_background_texture(background_path: String) -> Texture2D:
	var cache_key := "battle_background::%s" % background_path
	if generated_texture_cache.has(cache_key):
		return generated_texture_cache[cache_key]

	var disk_texture := load_texture_from_disk(background_path)
	if disk_texture != null:
		generated_texture_cache[cache_key] = disk_texture
		return disk_texture
	if ResourceLoader.exists(background_path):
		var resource_texture := load(background_path) as Texture2D
		generated_texture_cache[cache_key] = resource_texture
		return resource_texture
	push_error("Missing battle background: %s" % background_path)
	return null


func get_texture(character: Dictionary) -> Texture2D:
	var code: String = str(character.get("code", ""))
	if code.is_empty():
		return null
	if not texture_cache.has(code):
		var image_path := str(character.get("image_path", ""))
		var texture := load_texture_from_disk(image_path)
		if texture == null and not image_path.is_empty() and ResourceLoader.exists(image_path):
			texture = load(image_path) as Texture2D
		texture_cache[code] = texture
	return texture_cache[code]


func get_character_avatar_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	return _get_card_portrait_texture(character, fate_variant)


func get_small_hand_card_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	var code: String = character.get("code", "")
	if code.is_empty():
		return null
	var display_variant := normalize_fate_variant(fate_variant)
	var cache_key := "%s::%s" % [display_variant, code]
	if hand_small_card_texture_cache.has(cache_key):
		return hand_small_card_texture_cache[cache_key]

	var path := "res://assets/cards/thumb/enemy/%s.png" % code if display_variant == "enemy" else "res://assets/cards/thumb/ally/%s.png" % code
	var texture := load_texture_from_disk(path)
	if texture == null and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	hand_small_card_texture_cache[cache_key] = texture
	return texture


func get_reveal_card_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	var code: String = character.get("code", "")
	if code.is_empty():
		return null
	var display_variant := normalize_fate_variant(fate_variant)
	var cache_key := "%s::%s" % [display_variant, code]
	if reveal_card_texture_cache.has(cache_key):
		return reveal_card_texture_cache[cache_key]

	var path := "res://assets/cards/reveal/enemy/%s.png" % code if display_variant == "enemy" else "res://assets/cards/reveal/ally/%s.png" % code
	var texture := load_texture_from_disk(path)
	if texture == null and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		texture = get_small_hand_card_texture(character, display_variant)
	reveal_card_texture_cache[cache_key] = texture
	return texture


func get_hand_card_art_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	var code: String = character.get("code", "")
	if code.is_empty():
		return null
	var display_variant := normalize_fate_variant(fate_variant)
	var cache_key := "%s::%s" % [display_variant, code]
	if hand_card_art_texture_cache.has(cache_key):
		return hand_card_art_texture_cache[cache_key]

	var art_image := _extract_hand_card_art_image(character, display_variant)
	if art_image == null:
		return get_texture(character)

	var art_texture := ImageTexture.create_from_image(art_image)
	hand_card_art_texture_cache[cache_key] = art_texture
	return art_texture


func generate_table_surface_texture() -> Texture2D:
	return _get_or_build_generated_texture("table_surface", Callable(self, "_build_table_surface_texture"))


func generate_pedestal_body_texture() -> Texture2D:
	return _get_or_build_generated_texture("pedestal_body", Callable(self, "_build_pedestal_body_texture"))


func generate_seat_card_pedestal_texture() -> Texture2D:
	return _get_or_build_generated_texture("seat_card_pedestal", Callable(self, "_build_seat_card_pedestal_texture"))


func generate_seat_card_border_texture() -> Texture2D:
	return _get_or_build_generated_texture("seat_card_border", Callable(self, "_build_seat_card_border_texture"))


func generate_play_zone_texture() -> Texture2D:
	return _get_or_build_generated_texture("play_zone", Callable(self, "_build_play_zone_texture"))


func generate_card_shadow_texture() -> Texture2D:
	return _get_or_build_generated_texture("card_shadow", Callable(self, "_build_card_shadow_texture"))


func generate_avatar_ring_texture() -> Texture2D:
	return _get_or_build_generated_texture("avatar_ring", Callable(self, "_build_avatar_ring_texture"))


func generate_avatar_glow_texture() -> Texture2D:
	return _get_or_build_generated_texture("avatar_glow", Callable(self, "_build_avatar_glow_texture"))


func generate_soft_glow_texture() -> Texture2D:
	return _get_or_build_generated_texture("soft_glow", Callable(self, "_build_soft_glow_texture"))


func _get_or_build_generated_texture(cache_key: String, builder: Callable) -> Texture2D:
	if generated_texture_cache.has(cache_key):
		return generated_texture_cache[cache_key]
	var texture: Texture2D = builder.call()
	generated_texture_cache[cache_key] = texture
	return texture


func _get_portrait_candidate_paths(character: Dictionary, fate_variant: String = "ally", prefer_cutout: bool = true) -> Array[String]:
	var code := str(character.get("code", ""))
	if code.is_empty():
		return []

	var portrait_candidates: Array[String] = []
	var display_variant := normalize_fate_variant(fate_variant)
	if display_variant == "enemy":
		if prefer_cutout:
			portrait_candidates.append("res://assets/portraits/cutout/enemy/%s.png" % code)
		portrait_candidates.append("res://assets/portraits/subject/enemy/%s.png" % code)
	if prefer_cutout:
		portrait_candidates.append("res://assets/portraits/cutout/ally/%s.png" % code)
	portrait_candidates.append("res://assets/portraits/subject/ally/%s.png" % code)
	return portrait_candidates


func _extract_character_crop_image(character: Dictionary, fate_variant: String = "ally") -> Image:
	var portrait_candidates := _get_portrait_candidate_paths(character, fate_variant, true)
	for portrait_path in portrait_candidates:
		var custom_image: Image = null
		if ResourceLoader.exists(portrait_path):
			var custom_texture := load(portrait_path) as Texture2D
			if custom_texture != null:
				custom_image = custom_texture.get_image()
		if custom_image == null:
			custom_image = load_image_from_disk(portrait_path)
		if custom_image == null:
			continue
		if custom_image.get_format() != Image.FORMAT_RGBA8:
			custom_image.convert(Image.FORMAT_RGBA8)
		custom_image.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		return custom_image

	var source_texture := get_texture(character)
	if source_texture == null:
		return null
	var source_image := source_texture.get_image()
	if source_image == null:
		return null
	if source_image.get_format() != Image.FORMAT_RGBA8:
		source_image.convert(Image.FORMAT_RGBA8)

	var crop_size := int(source_image.get_width() * 0.58)
	crop_size = mini(crop_size, int(source_image.get_height() * 0.44))
	var crop_x := maxi(0, int((source_image.get_width() - crop_size) * 0.5))
	var crop_y := maxi(0, mini(int(source_image.get_height() * 0.09), source_image.get_height() - crop_size))
	var crop_image := Image.create(crop_size, crop_size, false, Image.FORMAT_RGBA8)
	crop_image.blit_rect(source_image, Rect2i(crop_x, crop_y, crop_size, crop_size), Vector2i.ZERO)
	crop_image.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	return crop_image


func _get_card_portrait_texture(character: Dictionary, fate_variant: String = "ally") -> Texture2D:
	var code: String = character.get("code", "")
	if code.is_empty():
		return null
	var display_variant := normalize_fate_variant(fate_variant)
	var cache_key := "%s::%s" % [display_variant, code]
	if card_portrait_texture_cache.has(cache_key):
		return card_portrait_texture_cache[cache_key]

	var crop_image := _extract_character_crop_image(character, display_variant)
	if crop_image == null:
		return get_texture(character)

	var portrait_texture := ImageTexture.create_from_image(crop_image)
	card_portrait_texture_cache[cache_key] = portrait_texture
	return portrait_texture


func _extract_hand_card_art_image(character: Dictionary, fate_variant: String = "ally") -> Image:
	var portrait_candidates := _get_portrait_candidate_paths(character, fate_variant, true)
	for portrait_path in portrait_candidates:
		var portrait_image: Image = null
		if ResourceLoader.exists(portrait_path):
			var portrait_texture := load(portrait_path) as Texture2D
			if portrait_texture != null:
				portrait_image = portrait_texture.get_image()
		if portrait_image == null:
			portrait_image = load_image_from_disk(portrait_path)
		if portrait_image == null:
			continue
		if portrait_image.get_format() != Image.FORMAT_RGBA8:
			portrait_image.convert(Image.FORMAT_RGBA8)
		portrait_image.resize(420, 420, Image.INTERPOLATE_LANCZOS)
		return portrait_image

	var source_texture := get_texture(character)
	if source_texture == null:
		return _extract_character_crop_image(character, fate_variant)
	var source_image := source_texture.get_image()
	if source_image == null:
		return _extract_character_crop_image(character, fate_variant)
	if source_image.get_format() != Image.FORMAT_RGBA8:
		source_image.convert(Image.FORMAT_RGBA8)

	var width := source_image.get_width()
	var height := source_image.get_height()
	var crop_rect := Rect2i(
		int(width * 0.12),
		int(height * 0.07),
		int(width * 0.76),
		int(height * 0.57)
	)
	crop_rect.position.x = clampi(crop_rect.position.x, 0, width - 1)
	crop_rect.position.y = clampi(crop_rect.position.y, 0, height - 1)
	crop_rect.size.x = clampi(crop_rect.size.x, 1, width - crop_rect.position.x)
	crop_rect.size.y = clampi(crop_rect.size.y, 1, height - crop_rect.position.y)

	var crop_image := Image.create(crop_rect.size.x, crop_rect.size.y, false, Image.FORMAT_RGBA8)
	crop_image.blit_rect(source_image, crop_rect, Vector2i.ZERO)
	crop_image.resize(420, 420, Image.INTERPOLATE_LANCZOS)
	return crop_image


func _build_table_surface_texture() -> Texture2D:
	var width := 768
	var height := 768
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2(width * 0.5, height * 0.48)

	for y in range(height):
		for x in range(width):
			var pos := Vector2(float(x), float(y))
			var dist := pos.distance_to(center) / (float(width) * 0.5)
			var blend := clampf(float(x) / float(width), 0.0, 1.0)
			var color := Color("d8f1ff").lerp(Color("f4f3ff"), blend)
			color = color.lerp(Color("ffe8ef"), clampf(float(y) / float(height), 0.0, 1.0) * 0.32)
			var vignette := 1.0 - dist * 0.28
			color = color.lightened(vignette * 0.08)

			image.set_pixel(x, y, color)

	var glow_radius := 220
	for y in range(int(center.y) - glow_radius, int(center.y) + glow_radius):
		for x in range(int(center.x) - glow_radius * 2, int(center.x) + glow_radius * 2):
			if x < 0 or x >= width or y < 0 or y >= height:
				continue

			var dx := (float(x) - center.x) / (glow_radius * 2.0)
			var dy := (float(y) - center.y) / float(glow_radius)
			var distance := sqrt(dx * dx + dy * dy)

			if distance < 1.0:
				var glow := (1.0 - distance) * 0.12
				var color := image.get_pixel(x, y)
				image.set_pixel(x, y, color.lightened(glow))

	return ImageTexture.create_from_image(image)


func _build_pedestal_body_texture() -> Texture2D:
	var width := 760
	var height := 340
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2(width * 0.5, height * 0.42)
	var rx := width * 0.42
	var ry := height * 0.22
	for y in range(height):
		for x in range(width):
			var dx := (float(x) - center.x) / rx
			var dy := (float(y) - center.y) / ry
			var dist := sqrt(dx * dx + dy * dy)
			if dist >= 1.0:
				continue
			var edge := clampf(1.0 - dist, 0.0, 1.0)
			var vertical := clampf((float(y) - (center.y - ry)) / (ry * 2.0), 0.0, 1.0)
			var top_light := clampf(1.0 - vertical * 1.55, 0.0, 1.0)
			var lower_depth := clampf((vertical - 0.42) / 0.58, 0.0, 1.0)
			var outer_rim := clampf(1.0 - abs(dist - 0.94) / 0.05, 0.0, 1.0)
			var alpha := pow(edge, 0.72) * 0.96
			alpha += outer_rim * 0.06
			var color := Color(
				0.92 + top_light * 0.04 - lower_depth * 0.24,
				0.95 + top_light * 0.03 - lower_depth * 0.18,
				1.00 - lower_depth * 0.08,
				minf(alpha, 0.98)
			)
			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)


func _build_seat_card_pedestal_texture() -> Texture2D:
	var width := 300
	var height := 400
	var radius := 18.0
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var cx := minf(minf(float(x), float(width - 1 - x)), radius)
			var cy := minf(minf(float(y), float(height - 1 - y)), radius)
			var corner_dist := sqrt(pow(radius - cx, 2) + pow(radius - cy, 2))
			var rounded_alpha := 1.0
			if cx < radius and cy < radius:
				rounded_alpha = clampf(1.0 - (corner_dist - radius + 1.0), 0.0, 1.0)
			if rounded_alpha <= 0.0:
				continue
			var ny := float(y) / float(height)
			var top_warm := pow(1.0 - ny, 1.6) * 0.10
			var red := 0.93 + top_warm * 0.08
			var green := 0.86 + top_warm * 0.05
			var blue := 0.72 + top_warm * 0.02
			var inner_dx := minf(float(x), float(width - 1 - x)) / float(width)
			var inner_dy := minf(float(y), float(height - 1 - y)) / float(height)
			var edge_dark := clampf(1.0 - minf(inner_dx, inner_dy) * 6.0, 0.0, 1.0)
			red -= edge_dark * 0.22
			green -= edge_dark * 0.22
			blue -= edge_dark * 0.20
			image.set_pixel(x, y, Color(red, green, blue, rounded_alpha * 0.94))

	return ImageTexture.create_from_image(image)


func _build_seat_card_border_texture() -> Texture2D:
	var width := 300
	var height := 400
	var radius := 18.0
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var dx := minf(float(x), float(width - 1 - x))
			var dy := minf(float(y), float(height - 1 - y))
			var edge_distance := minf(dx, dy)
			var ring_alpha := 0.0
			if edge_distance < 6.0:
				ring_alpha = clampf(1.0 - edge_distance / 6.0, 0.0, 1.0) * 0.92
			elif edge_distance < 28.0:
				ring_alpha = clampf(1.0 - (edge_distance - 6.0) / 22.0, 0.0, 1.0) * 0.34
			if ring_alpha <= 0.0:
				continue
			var cx := minf(dx, radius)
			var cy := minf(dy, radius)
			var corner_dist := sqrt(pow(radius - cx, 2) + pow(radius - cy, 2))
			if dx < radius and dy < radius:
				var corner_alpha := clampf(1.0 - (corner_dist - radius + 1.0), 0.0, 1.0)
				ring_alpha *= corner_alpha
			image.set_pixel(x, y, Color(1, 1, 1, ring_alpha))

	return ImageTexture.create_from_image(image)


func _build_play_zone_texture() -> Texture2D:
	var width := 640
	var height := 320
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2(width * 0.5, height * 0.5)
	var rx := width * 0.44
	var ry := height * 0.26
	for y in range(height):
		for x in range(width):
			var dx := (float(x) - center.x) / rx
			var dy := (float(y) - center.y) / ry
			var ellipse := sqrt(dx * dx + dy * dy)
			var alpha := 0.0
			if ellipse < 1.0:
				alpha += pow(1.0 - ellipse, 2.0) * 0.32
				var ring := clampf(1.0 - abs(ellipse - 0.88) / 0.16, 0.0, 1.0)
				alpha += ring * 0.12
				image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)


func _build_card_shadow_texture() -> Texture2D:
	var width := 180
	var height := 236
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2(width * 0.5, height * 0.5)
	var rx := width * 0.42
	var ry := height * 0.38

	for y in range(height):
		for x in range(width):
			var dx := (float(x) - center.x) / rx
			var dy := (float(y) - center.y) / ry
			var dist := sqrt(dx * dx + dy * dy)

			if dist >= 1.0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var alpha := pow(clampf(1.0 - dist, 0.0, 1.0), 3.2) * 0.28
				image.set_pixel(x, y, Color(0, 0, 0, alpha))

	return ImageTexture.create_from_image(image)


func _build_avatar_ring_texture() -> Texture2D:
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var outer := size * 0.48
	var inner := size * 0.40
	for y in range(size):
		for x in range(size):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := 0.0
			if dist <= outer and dist >= inner:
				alpha = clampf(1.0 - abs(dist - (outer + inner) * 0.5) / 7.5, 0.0, 1.0) * 0.72
			elif dist < inner:
				alpha = clampf((inner - dist) / inner, 0.0, 1.0) * 0.08
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)


func _build_avatar_glow_texture() -> Texture2D:
	var size := 144
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.44
	for y in range(size):
		for x in range(size):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := pow(clampf(1.0 - dist / radius, 0.0, 1.0), 2.8) * 0.48
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)


func _build_soft_glow_texture() -> Texture2D:
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.46
	for y in range(size):
		for x in range(size):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			var alpha := pow(clampf(1.0 - dist / radius, 0.0, 1.0), 3.6) * 0.48
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)
