class_name ButtonFeedback


static func add_press_feedback(button: Button, target_scale := 0.92) -> void:
	var button_id := button.get_instance_id()
	button.button_down.connect(func() -> void:
		var btn := instance_from_id(button_id) as Button
		if btn == null or not is_instance_valid(btn):
			return
		btn.pivot_offset = btn.size * 0.5
		var tween := btn.create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(target_scale, target_scale), 0.08)
	)
	button.button_up.connect(func() -> void:
		var btn := instance_from_id(button_id) as Button
		if btn == null or not is_instance_valid(btn):
			return
		var tween := btn.create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.35)
	)


static func spawn_ripple(parent: Control, center: Vector2, color: Color = Color(1.0, 0.88, 0.55, 0.25)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var ripple := ColorRect.new()
	ripple.color = color
	ripple.custom_minimum_size = Vector2(6, 6)
	ripple.size = ripple.custom_minimum_size
	ripple.position = center - Vector2(3, 3)
	ripple.pivot_offset = Vector2(3, 3)
	ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(ripple)

	var tween := parent.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ripple, "scale", Vector2(24.0, 24.0), 0.45)
	tween.parallel().tween_property(ripple, "modulate:a", 0.0, 0.45)
	tween.tween_callback(ripple.queue_free)
