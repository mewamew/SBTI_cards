class_name RibbonBanner extends Control

var fill_color: Color = Color("6b1218")
var border_color: Color = Color("c9a04c")
var border_width: float = 2.0
var cut_depth: float = 16.0
var title_text: String = ""
var title_color: Color = Color("f0d28a")
var title_outline: Color = Color(0.05, 0.02, 0.0, 0.92)
var title_outline_size: int = 5
var title_font_size: int = 30


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
	var cd := minf(cut_depth, w * 0.25)
	var pts := PackedVector2Array([
		Vector2(0, 0),
		Vector2(w, 0),
		Vector2(w - cd, h * 0.5),
		Vector2(w, h),
		Vector2(0, h),
		Vector2(cd, h * 0.5),
	])
	var shadow_offset := Vector2(0, 4)
	var shadow_pts := PackedVector2Array()
	for p in pts:
		shadow_pts.append(p + shadow_offset)
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.45))
	draw_colored_polygon(pts, fill_color)
	var bottom_pts := PackedVector2Array([
		Vector2(0, h * 0.55),
		Vector2(cd * 0.5, h * 0.5),
		Vector2(w - cd * 0.5, h * 0.5),
		Vector2(w, h * 0.55),
		Vector2(w, h),
		Vector2(0, h),
	])
	draw_colored_polygon(bottom_pts, Color(0, 0, 0, 0.18))
	var pts_closed := pts.duplicate()
	pts_closed.append(pts[0])
	draw_polyline(pts_closed, border_color, border_width, true)
	if not title_text.is_empty():
		var font := get_theme_default_font()
		if font == null:
			return
		var text_size_px := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)
		var ascent := font.get_ascent(title_font_size)
		var descent := font.get_descent(title_font_size)
		var total_h := ascent + descent
		var baseline_y := (h - total_h) * 0.5 + ascent
		var text_x := (w - text_size_px.x) * 0.5
		var pos := Vector2(text_x, baseline_y)
		if title_outline_size > 0:
			draw_string_outline(font, pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, title_outline_size, title_outline)
		draw_string(font, pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, title_color)
