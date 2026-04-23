extends RefCounted


const UIFactory = preload("res://scripts/ui_factory.gd")


var host


func setup(next_host) -> void:
	host = next_host


func _tween() -> Tween:
	return host.create_tween()


func _tree():
	return host.get_tree()


func _seat_node(seat_id: String) -> Control:
	return host.seat_nodes.get(seat_id) as Control


func _seat_actor_node(seat_id: String, ally_uid: int = -1) -> Control:
	return host._get_seat_actor_node(seat_id, ally_uid)


func _soft_glow_texture() -> Texture2D:
	return host.soft_glow_texture if host.soft_glow_texture != null else host._generate_soft_glow_texture()


func _queue_free_instance(instance_id: int) -> void:
	if instance_id < 0:
		return
	var target := instance_from_id(instance_id)
	if target == null or not is_instance_valid(target):
		return
	if target is Node:
		(target as Node).queue_free()


func _hide_control_if_valid(control_id: int) -> void:
	var control := instance_from_id(control_id) as Control
	if control != null and is_instance_valid(control):
		control.visible = false


func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	return q0.lerp(q1, t)


func _set_projectile_motion_progress(
	progress: float,
	trail_id: int,
	orb_glow_id: int,
	orb_core_id: int,
	trail_emitter_id: int,
	start: Vector2,
	control_point: Vector2,
	end: Vector2
) -> void:
	var point := _quadratic_bezier(start, control_point, end, progress)
	var trail := instance_from_id(trail_id) as Line2D
	if trail != null and is_instance_valid(trail):
		var tail_points: Array = trail.get_meta("tail_points", [])
		tail_points.append(point)
		while tail_points.size() > 7:
			tail_points.remove_at(0)
		trail.set_meta("tail_points", tail_points)
		trail.clear_points()
		for tail_point in tail_points:
			trail.add_point(tail_point)
	var orb_glow := instance_from_id(orb_glow_id) as TextureRect
	if orb_glow != null and is_instance_valid(orb_glow):
		orb_glow.position = point - orb_glow.size * 0.5
		orb_glow.scale = Vector2.ONE * lerpf(0.72, 1.16, sin(progress * PI))
		orb_glow.modulate.a = lerpf(0.52, 0.20, progress)
	var orb_core := instance_from_id(orb_core_id) as TextureRect
	if orb_core != null and is_instance_valid(orb_core):
		orb_core.position = point - orb_core.size * 0.5
		orb_core.scale = Vector2.ONE * lerpf(0.88, 1.06, 1.0 - absf(progress - 0.5) * 2.0)
	if trail_emitter_id >= 0:
		var trail_emitter := instance_from_id(trail_emitter_id) as GPUParticles2D
		if trail_emitter != null and is_instance_valid(trail_emitter):
			trail_emitter.position = point


func _finalize_projectile_effect(
	orb_glow_id: int,
	orb_core_id: int,
	trail_emitter_id: int,
	trail_emitter_lifetime: float,
	trail_id: int,
	end_world: Vector2,
	projectile_color: Color,
	target_seat: String,
	damage: int,
	ally_uid: int,
	is_block: bool
) -> void:
	_queue_free_instance(orb_glow_id)
	_queue_free_instance(orb_core_id)
	if trail_emitter_id >= 0:
		var trail_emitter := instance_from_id(trail_emitter_id) as GPUParticles2D
		if trail_emitter != null and is_instance_valid(trail_emitter):
			trail_emitter.emitting = false
			var trail_cleanup: SceneTreeTimer = _tree().create_timer(trail_emitter_lifetime + 0.12)
			trail_cleanup.timeout.connect(_queue_free_instance.bind(trail_emitter_id))
	var trail := instance_from_id(trail_id) as Line2D
	if trail != null and is_instance_valid(trail):
		var fade := _tween()
		fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fade.tween_property(trail, "modulate", Color(1, 1, 1, 0), 0.16)
		fade.tween_callback(_queue_free_instance.bind(trail_id))
	spawn_impact_burst(end_world, projectile_color, is_block)
	play_hit_feedback(target_seat, damage, ally_uid, is_block)


func _play_damage_number_outro(label_id: int) -> void:
	var label := instance_from_id(label_id) as Control
	if label == null or not is_instance_valid(label):
		return
	var outro := _tween()
	outro.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	outro.set_parallel(true)
	outro.tween_property(label, "position", label.position + Vector2(0.0, -40.0), 0.32)
	outro.tween_property(label, "modulate", Color(1.0, 0.86, 0.80, 0.0), 0.32)
	outro.tween_property(label, "rotation_degrees", randf_range(-1.0, 1.0), 0.32)
	outro.tween_callback(_queue_free_instance.bind(label_id))


func pulse_seat_glow(seat_id: String) -> void:
	var seat := _seat_node(seat_id)
	if seat == null:
		return
	var background: TextureRect = seat.get_meta("background") as TextureRect
	if background == null:
		return
	var base_color := background.modulate
	var tween := _tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(background, "modulate", Color(base_color.r, base_color.g, base_color.b, 0.48), 0.10)
	tween.tween_property(background, "modulate", base_color, 0.34)


func pulse_seat_glow_breath(seat_id: String) -> void:
	var seat := _seat_node(seat_id)
	if seat == null:
		return
	var background: TextureRect = seat.get_meta("background") as TextureRect
	if background == null:
		return
	var base_color := background.modulate
	var tween := _tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background, "modulate", Color(base_color.r, base_color.g, base_color.b, 0.80), 0.30)
	tween.tween_property(background, "modulate", Color(base_color.r, base_color.g, base_color.b, 0.40), 0.30)


func build_particle_color_ramp(colors: PackedColorArray, offsets: PackedFloat32Array) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.colors = colors
	gradient.offsets = offsets
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	ramp.width = 96
	return ramp


func build_seat_entry_burst_material(is_enemy: bool) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = 150.0
	material.initial_velocity_max = 280.0
	material.gravity = Vector3(0.0, 420.0, 0.0)
	material.linear_accel_min = -18.0
	material.linear_accel_max = 24.0
	material.radial_accel_min = -32.0
	material.radial_accel_max = 40.0
	material.tangential_accel_min = -14.0
	material.tangential_accel_max = 14.0
	material.damping_min = 110.0
	material.damping_max = 180.0
	material.scale_min = 0.08
	material.scale_max = 0.18
	material.angular_velocity_min = -360.0
	material.angular_velocity_max = 360.0
	material.hue_variation_min = -0.03
	material.hue_variation_max = 0.03
	if is_enemy:
		material.color_ramp = build_particle_color_ramp(
			PackedColorArray([
				Color(1.0, 0.92, 0.74, 0.0),
				Color(1.0, 0.56, 0.22, 0.95),
				Color(0.86, 0.15, 0.12, 0.72),
				Color(0.32, 0.04, 0.05, 0.0),
			]),
			PackedFloat32Array([0.0, 0.10, 0.48, 1.0])
		)
	else:
		material.color_ramp = build_particle_color_ramp(
			PackedColorArray([
				Color(1.0, 0.98, 0.86, 0.0),
				Color(1.0, 0.85, 0.42, 0.96),
				Color(0.44, 0.76, 1.0, 0.70),
				Color(0.08, 0.18, 0.36, 0.0),
			]),
			PackedFloat32Array([0.0, 0.12, 0.50, 1.0])
		)
	return material


func get_seat_entry_burst_material(seat_id: String) -> ParticleProcessMaterial:
	var is_enemy := seat_id == "enemy"
	if is_enemy:
		if host.seat_entry_enemy_burst_material == null:
			host.seat_entry_enemy_burst_material = build_seat_entry_burst_material(true)
		return host.seat_entry_enemy_burst_material
	if host.seat_entry_ally_burst_material == null:
		host.seat_entry_ally_burst_material = build_seat_entry_burst_material(false)
	return host.seat_entry_ally_burst_material


func spawn_seat_entry_burst(seat_id: String, ally_uid: int = -1) -> void:
	if host.floating_effect_layer == null:
		return
	var world_center := get_seat_world_center(seat_id, ally_uid)
	if world_center == Vector2.ZERO:
		return
	var burst := GPUParticles2D.new()
	burst.amount = 40
	burst.lifetime = 0.68
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.randomness = 0.24
	burst.fixed_fps = 30
	burst.local_coords = false
	burst.texture = _soft_glow_texture()
	burst.process_material = get_seat_entry_burst_material(seat_id)
	burst.position = to_layer_local_point(host.floating_effect_layer, world_center)
	burst.visibility_rect = Rect2(Vector2(-220.0, -220.0), Vector2(440.0, 440.0))
	burst.z_index = 10
	host.floating_effect_layer.add_child(burst)
	burst.restart()
	burst.emitting = true
	var burst_id := burst.get_instance_id()
	var cleanup_timer: SceneTreeTimer = _tree().create_timer(1.0)
	cleanup_timer.timeout.connect(_queue_free_instance.bind(burst_id))


func animate_seat_entry(seat_id: String, ally_uid: int = -1) -> void:
	var avatar_container := _seat_actor_node(seat_id, ally_uid)
	if avatar_container == null:
		return
	var seat := _seat_node(seat_id)
	var background: TextureRect = seat.get_meta("background") as TextureRect
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	var target_pos: Vector2 = avatar_container.get_meta("target_pos", avatar_container.position)
	var target_modulate := avatar_container.modulate
	var background_target := background.modulate if background != null else Color.WHITE
	var ring_target := border_ring.modulate if border_ring != null else Color.WHITE
	avatar_container.position = target_pos
	avatar_container.scale = Vector2.ZERO
	avatar_container.modulate = Color(target_modulate.r, target_modulate.g, target_modulate.b, 0.0)
	if background != null:
		background.modulate = Color(background_target.r, background_target.g, background_target.b, 0.0)
	if border_ring != null:
		border_ring.visible = true
		border_ring.modulate = Color(ring_target.r, ring_target.g, ring_target.b, 0.0)
	pulse_seat_glow(seat_id)

	var tween := _tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(avatar_container, "scale", Vector2.ONE, 0.30)
	tween.tween_property(avatar_container, "modulate", target_modulate, 0.25)
	if background != null:
		tween.tween_property(background, "modulate", background_target, 0.35)
	if border_ring != null:
		tween.tween_property(border_ring, "modulate", ring_target, 0.28)
	await _tree().create_timer(0.18).timeout
	spawn_seat_entry_burst(seat_id, ally_uid)
	host._trigger_hitstop(0.022, 0.18, 0.08)
	await tween.finished

	pulse_seat_glow_breath(seat_id)


func animate_seat_departure(
	seat_id: String,
	ally_uid: int = -1,
	departure_offset: Vector2 = Vector2(0.0, -18.0)
) -> void:
	var avatar_container := _seat_actor_node(seat_id, ally_uid)
	if avatar_container == null:
		return
	var seat := _seat_node(seat_id)
	var background: TextureRect = seat.get_meta("background") as TextureRect
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	var target_pos: Vector2 = avatar_container.get_meta("target_pos", avatar_container.position)
	var base_modulate := avatar_container.modulate
	var background_color := background.modulate if background != null else Color.WHITE
	var ring_color := border_ring.modulate if border_ring != null else Color.WHITE
	var tween := _tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(avatar_container, "position", target_pos + departure_offset, 0.18)
	tween.tween_property(avatar_container, "scale", Vector2.ONE * 0.24, 0.18)
	tween.tween_property(avatar_container, "modulate", Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0), 0.16)
	if background != null:
		tween.tween_property(background, "modulate", Color(background_color.r, background_color.g, background_color.b, 0.0), 0.18)
	if border_ring != null:
		tween.tween_property(border_ring, "modulate", Color(ring_color.r, ring_color.g, ring_color.b, 0.0), 0.16)
	await tween.finished
	if border_ring != null:
		border_ring.visible = false


func animate_enemy_departure() -> void:
	if _seat_actor_node("enemy") == null:
		host.active_enemy_character = {}
		host._sync_enemy_seat()
		return
	await animate_seat_departure("enemy")
	host.active_enemy_character = {}
	host._sync_enemy_seat()


func get_control_world_anchor(control: Control, anchor: Vector2 = Vector2(0.5, 0.5)) -> Vector2:
	if control == null or not is_instance_valid(control):
		return Vector2.ZERO
	var rect := control.get_global_rect()
	return rect.position + Vector2(rect.size.x * anchor.x, rect.size.y * anchor.y)


func get_control_world_center(control: Control) -> Vector2:
	return get_control_world_anchor(control, Vector2(0.5, 0.5))


func to_layer_local_point(layer: Control, world_point: Vector2) -> Vector2:
	if layer == null:
		return world_point
	return layer.get_global_transform().affine_inverse() * world_point


func get_player_stage_hit_node() -> Control:
	if host.hero_spotlight_root != null and host.hero_spotlight_root.visible and host.hero_spotlight_root.is_inside_tree():
		return host.hero_spotlight_root
	return _seat_actor_node("player")


func get_player_stage_hit_world_center() -> Vector2:
	var actor := get_player_stage_hit_node()
	if actor == null:
		return get_seat_world_center("player")
	if actor == host.hero_spotlight_root:
		return get_control_world_anchor(actor, Vector2(0.5, 0.42))
	return get_control_world_center(actor)


func get_combat_target_world_center(seat_id: String, ally_uid: int = -1) -> Vector2:
	if seat_id == "player":
		return get_player_stage_hit_world_center()
	return get_seat_world_center(seat_id, ally_uid)


func get_attack_flight_duration(attacker_seat: String, target_seat: String, ally_uid: int = -1) -> float:
	if host.projectile_layer == null:
		return 0.0
	var start_world := get_attack_origin_world_center(attacker_seat)
	var end_world := get_combat_target_world_center(target_seat, ally_uid)
	if start_world == Vector2.ZERO or end_world == Vector2.ZERO:
		return 0.0
	var start := to_layer_local_point(host.projectile_layer, start_world)
	var end := to_layer_local_point(host.projectile_layer, end_world)
	return clampf(0.22 + start.distance_to(end) / 1600.0, 0.26, 0.40)


func build_attack_trail_material(is_block: bool) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(-1.0, 0.0, 0.0)
	material.spread = 26.0
	material.initial_velocity_min = 16.0
	material.initial_velocity_max = 44.0
	material.gravity = Vector3.ZERO
	material.linear_accel_min = -20.0
	material.linear_accel_max = -6.0
	material.radial_accel_min = -10.0
	material.radial_accel_max = 14.0
	material.tangential_accel_min = -8.0
	material.tangential_accel_max = 8.0
	material.damping_min = 28.0
	material.damping_max = 64.0
	material.scale_min = 0.04
	material.scale_max = 0.12
	material.angular_velocity_min = -240.0
	material.angular_velocity_max = 240.0
	if is_block:
		material.color_ramp = build_particle_color_ramp(
			PackedColorArray([
				Color(0.92, 0.98, 1.0, 0.0),
				Color(0.56, 0.83, 1.0, 0.94),
				Color(0.18, 0.48, 0.96, 0.52),
				Color(0.06, 0.14, 0.30, 0.0),
			]),
			PackedFloat32Array([0.0, 0.18, 0.58, 1.0])
		)
	else:
		material.color_ramp = build_particle_color_ramp(
			PackedColorArray([
				Color(1.0, 0.94, 0.76, 0.0),
				Color(1.0, 0.72, 0.38, 0.98),
				Color(0.94, 0.20, 0.10, 0.58),
				Color(0.30, 0.05, 0.03, 0.0),
			]),
			PackedFloat32Array([0.0, 0.16, 0.54, 1.0])
		)
	return material


func get_attack_trail_material(is_block: bool) -> ParticleProcessMaterial:
	if is_block:
		if host.attack_trail_block_material == null:
			host.attack_trail_block_material = build_attack_trail_material(true)
		return host.attack_trail_block_material
	if host.attack_trail_enemy_material == null:
		host.attack_trail_enemy_material = build_attack_trail_material(false)
	return host.attack_trail_enemy_material


func build_attack_impact_material(is_block: bool) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = 140.0
	material.initial_velocity_max = 260.0
	material.gravity = Vector3(0.0, 360.0, 0.0)
	material.linear_accel_min = -18.0
	material.linear_accel_max = 26.0
	material.radial_accel_min = -28.0
	material.radial_accel_max = 36.0
	material.tangential_accel_min = -24.0
	material.tangential_accel_max = 24.0
	material.damping_min = 110.0
	material.damping_max = 180.0
	material.scale_min = 0.06
	material.scale_max = 0.16
	material.angular_velocity_min = -420.0
	material.angular_velocity_max = 420.0
	if is_block:
		material.color_ramp = build_particle_color_ramp(
			PackedColorArray([
				Color(0.92, 0.98, 1.0, 0.0),
				Color(0.60, 0.88, 1.0, 0.96),
				Color(0.24, 0.54, 1.0, 0.68),
				Color(0.05, 0.12, 0.24, 0.0),
			]),
			PackedFloat32Array([0.0, 0.10, 0.44, 1.0])
		)
	else:
		material.color_ramp = build_particle_color_ramp(
			PackedColorArray([
				Color(1.0, 0.98, 0.86, 0.0),
				Color(1.0, 0.76, 0.40, 0.98),
				Color(0.98, 0.24, 0.12, 0.76),
				Color(0.22, 0.04, 0.03, 0.0),
			]),
			PackedFloat32Array([0.0, 0.10, 0.46, 1.0])
		)
	return material


func get_attack_impact_material(is_block: bool) -> ParticleProcessMaterial:
	if is_block:
		if host.attack_impact_block_material == null:
			host.attack_impact_block_material = build_attack_impact_material(true)
		return host.attack_impact_block_material
	if host.attack_impact_enemy_material == null:
		host.attack_impact_enemy_material = build_attack_impact_material(false)
	return host.attack_impact_enemy_material


func spawn_attack_trail_emitter(local_position: Vector2, is_block: bool) -> GPUParticles2D:
	if host.projectile_layer == null:
		return null
	var emitter := GPUParticles2D.new()
	emitter.amount = 28
	emitter.lifetime = 0.30
	emitter.one_shot = false
	emitter.explosiveness = 0.0
	emitter.randomness = 0.55
	emitter.fixed_fps = 30
	emitter.local_coords = false
	emitter.texture = _soft_glow_texture()
	emitter.process_material = get_attack_trail_material(is_block)
	emitter.position = local_position
	emitter.visibility_rect = Rect2(Vector2(-180.0, -180.0), Vector2(360.0, 360.0))
	emitter.z_index = 8
	host.projectile_layer.add_child(emitter)
	emitter.emitting = true
	return emitter


func spawn_attack_launch_flash(world_position: Vector2, base_color: Color) -> void:
	if host.floating_effect_layer == null:
		return
	var local_position := to_layer_local_point(host.floating_effect_layer, world_position)
	var flare := TextureRect.new()
	flare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flare.texture = _soft_glow_texture()
	flare.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flare.stretch_mode = TextureRect.STRETCH_SCALE
	flare.size = Vector2(88.0, 88.0)
	flare.pivot_offset = flare.size * 0.5
	flare.position = local_position - flare.size * 0.5
	flare.scale = Vector2.ONE * 0.35
	flare.modulate = Color(base_color.r, base_color.g, base_color.b, 0.42)
	flare.z_index = 7
	host.floating_effect_layer.add_child(flare)
	var flash := _tween()
	flash.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash.set_parallel(true)
	flash.tween_property(flare, "scale", Vector2.ONE * 1.12, 0.22)
	flash.tween_property(flare, "modulate:a", 0.0, 0.22)
	flash.tween_callback(flare.queue_free)


func spawn_attack_impact_particles(world_position: Vector2, is_block: bool) -> void:
	if host.floating_effect_layer == null:
		return
	var burst := GPUParticles2D.new()
	burst.amount = 34
	burst.lifetime = 0.56
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.randomness = 0.28
	burst.fixed_fps = 30
	burst.local_coords = false
	burst.texture = _soft_glow_texture()
	burst.process_material = get_attack_impact_material(is_block)
	burst.position = to_layer_local_point(host.floating_effect_layer, world_position)
	burst.visibility_rect = Rect2(Vector2(-240.0, -240.0), Vector2(480.0, 480.0))
	burst.z_index = 12
	host.floating_effect_layer.add_child(burst)
	burst.restart()
	burst.emitting = true
	var burst_id := burst.get_instance_id()
	var cleanup_timer: SceneTreeTimer = _tree().create_timer(1.0)
	cleanup_timer.timeout.connect(_queue_free_instance.bind(burst_id))


func get_attack_origin_world_center(attacker_seat: String) -> Vector2:
	if attacker_seat == "enemy" and host.active_reveal_card != null:
		return get_control_world_center(host.active_reveal_card)
	return get_seat_world_center(attacker_seat)


func get_attack_origin_actor(attacker_seat: String) -> Control:
	if attacker_seat == "enemy" and host.active_reveal_card != null and host.active_reveal_card.is_inside_tree():
		return host.active_reveal_card
	if attacker_seat == "player":
		return get_player_stage_hit_node()
	return _seat_actor_node(attacker_seat)


func play_attack_origin_kick(attacker_seat: String) -> void:
	var actor := get_attack_origin_actor(attacker_seat)
	if actor == null:
		return
	var base_scale := actor.scale
	var base_rotation := actor.rotation_degrees
	var kick_tween := _tween()
	kick_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	kick_tween.set_parallel(true)
	kick_tween.tween_property(actor, "scale", Vector2(base_scale.x * 1.05, base_scale.y * 0.95), 0.05)
	kick_tween.tween_property(actor, "rotation_degrees", base_rotation + (-2.4 if attacker_seat == "enemy" else 2.4), 0.05)
	kick_tween.chain().tween_property(actor, "scale", base_scale, 0.14)
	kick_tween.parallel().tween_property(actor, "rotation_degrees", base_rotation, 0.14)


func play_attack_effect(attacker_seat: String, target_seat: String, damage: int = 0, ally_uid: int = -1) -> void:
	if host.projectile_layer == null:
		return
	var start_world := get_attack_origin_world_center(attacker_seat)
	var end_world := get_combat_target_world_center(target_seat, ally_uid)
	if start_world == Vector2.ZERO or end_world == Vector2.ZERO:
		return
	var start := to_layer_local_point(host.projectile_layer, start_world)
	var end := to_layer_local_point(host.projectile_layer, end_world)
	var is_block := ally_uid >= 0
	var projectile_color := Color("4a9eff") if is_block else Color(1.0, 0.60, 0.28, 0.94)
	var distance := start.distance_to(end)
	var arc_height := clampf(distance * 0.18, 40.0, 96.0)
	var control_point := Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - arc_height)
	var flight_duration := get_attack_flight_duration(attacker_seat, target_seat, ally_uid)
	if flight_duration <= 0.0:
		flight_duration = 0.30
	play_attack_origin_kick(attacker_seat)
	spawn_attack_launch_flash(start_world, projectile_color)

	var trail := Line2D.new()
	trail.width = 5.0
	trail.default_color = Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.46)
	var trail_gradient := Gradient.new()
	trail_gradient.colors = PackedColorArray([
		Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.0),
		Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.72),
		Color(projectile_color.r * 0.55, projectile_color.g * 0.55, projectile_color.b * 0.55, 0.0),
	])
	trail_gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	trail.gradient = trail_gradient
	host.projectile_layer.add_child(trail)
	var tail_points: Array[Vector2] = []
	for _i in range(6):
		tail_points.append(start)
	trail.set_meta("tail_points", tail_points)

	var orb_glow := TextureRect.new()
	orb_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb_glow.texture = _soft_glow_texture()
	orb_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orb_glow.stretch_mode = TextureRect.STRETCH_SCALE
	orb_glow.size = Vector2(78.0, 78.0)
	orb_glow.pivot_offset = orb_glow.size * 0.5
	orb_glow.position = start - orb_glow.size * 0.5
	orb_glow.modulate = Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.40)
	host.projectile_layer.add_child(orb_glow)

	var orb_core := TextureRect.new()
	orb_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb_core.texture = _soft_glow_texture()
	orb_core.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orb_core.stretch_mode = TextureRect.STRETCH_SCALE
	orb_core.size = Vector2(30.0, 30.0)
	orb_core.pivot_offset = orb_core.size * 0.5
	orb_core.position = start - orb_core.size * 0.5
	orb_core.modulate = Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.94)
	host.projectile_layer.add_child(orb_core)

	var trail_emitter := spawn_attack_trail_emitter(start, is_block)
	var trail_emitter_id := trail_emitter.get_instance_id() if trail_emitter != null else -1

	var tween := _tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_set_projectile_motion_progress.bind(
			trail.get_instance_id(),
			orb_glow.get_instance_id(),
			orb_core.get_instance_id(),
			trail_emitter_id,
			start,
			control_point,
			end
		),
		0.0,
		1.0,
		flight_duration
	)
	tween.tween_callback(
		_finalize_projectile_effect.bind(
			orb_glow.get_instance_id(),
			orb_core.get_instance_id(),
			trail_emitter_id,
			trail_emitter.lifetime if trail_emitter != null else 0.0,
			trail.get_instance_id(),
			end_world,
			projectile_color,
			target_seat,
			damage,
			ally_uid,
			is_block
		)
	)


func play_hit_feedback(seat_id: String, damage: int = 0, ally_uid: int = -1, is_block: bool = false) -> void:
	animate_seat_hit(seat_id, ally_uid, is_block)
	host._trigger_hitstop(0.036 if is_block else 0.056, 0.14 if is_block else 0.04, 0.12)
	host._play_screen_shake(12.0 if is_block else 20.0, 0.12, 4 if is_block else 5, 0.70)
	if damage > 0:
		spawn_damage_number(get_combat_target_world_center(seat_id, ally_uid), damage)
		if host.damage_overlay != null:
			var dmg_tween := _tween()
			dmg_tween.tween_property(host.damage_overlay, "color:a", 0.28, 0.06)
			dmg_tween.tween_property(host.damage_overlay, "color:a", 0.0, 0.28)


func animate_player_stage_hit() -> void:
	var actor := get_player_stage_hit_node()
	if actor == null:
		return
	var base_position := actor.position
	var base_scale := actor.scale
	var base_modulate := actor.modulate
	var shake_tween := _tween()
	for _i in range(5):
		var offset := Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 8.0))
		shake_tween.tween_property(actor, "position", base_position + offset, 0.026)
	shake_tween.tween_property(actor, "position", base_position, 0.06)

	var hit_tween := _tween()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(actor, "scale", Vector2(base_scale.x * 0.97, base_scale.y * 0.94), 0.06)
	hit_tween.tween_property(actor, "modulate", Color(1.14, 0.88, 0.84, base_modulate.a), 0.06)
	hit_tween.chain().tween_property(actor, "scale", base_scale, 0.18)
	hit_tween.parallel().tween_property(actor, "modulate", base_modulate, 0.22)

	if host.hero_spotlight_pose != null and host.hero_spotlight_pose.is_inside_tree():
		var pose_base: Color = host.hero_spotlight_pose.modulate
		var pose_tween := _tween()
		pose_tween.tween_property(host.hero_spotlight_pose, "modulate", Color(1.18, 0.90, 0.84, pose_base.a), 0.05)
		pose_tween.tween_property(host.hero_spotlight_pose, "modulate", pose_base, 0.22)

	if host.hero_spotlight_halo != null and host.hero_spotlight_halo.is_inside_tree():
		var halo_base_scale: Vector2 = host.hero_spotlight_halo.scale
		var halo_base_modulate: Color = host.hero_spotlight_halo.modulate
		var halo_tween := _tween()
		halo_tween.set_parallel(true)
		halo_tween.tween_property(host.hero_spotlight_halo, "scale", halo_base_scale * 1.10, 0.10)
		halo_tween.tween_property(
			host.hero_spotlight_halo,
			"modulate",
			Color(1.0, 0.48, 0.28, minf(1.0, halo_base_modulate.a + 0.22)),
			0.08
		)
		halo_tween.chain().tween_property(host.hero_spotlight_halo, "scale", halo_base_scale, 0.24)
		halo_tween.parallel().tween_property(host.hero_spotlight_halo, "modulate", halo_base_modulate, 0.24)


func animate_seat_hit(seat_id: String, ally_uid: int = -1, is_block: bool = false) -> void:
	if seat_id == "player":
		animate_player_stage_hit()
		return
	var seat := _seat_node(seat_id)
	if seat == null:
		return
	var hit_flash: ColorRect = seat.get_meta("hit_flash") as ColorRect
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	var background: TextureRect = seat.get_meta("background") as TextureRect
	var avatar_container := _seat_actor_node(seat_id, ally_uid)
	var flash_color := Color("4a9eff") if is_block else Color(1.0, 0.28, 0.18)
	if hit_flash != null:
		hit_flash.visible = true
		hit_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
		hit_flash.color.a = 0.0
	if avatar_container == null:
		return
	var target_pos: Vector2 = avatar_container.get_meta("target_pos", avatar_container.position)
	var base_scale := avatar_container.scale
	var shake_tween := _tween()
	for _i in range(6):
		var offset := Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		shake_tween.tween_property(avatar_container, "position", target_pos + offset, 0.03)
	shake_tween.tween_property(avatar_container, "position", target_pos, 0.05)
	if hit_flash != null:
		var flash_tween := _tween()
		flash_tween.tween_property(hit_flash, "color:a", 0.56 if is_block else 0.76, 0.04)
		flash_tween.tween_property(hit_flash, "color:a", 0.0, 0.22)
		flash_tween.finished.connect(_hide_control_if_valid.bind(hit_flash.get_instance_id()))
	var base_modulate := avatar_container.modulate
	var hit_tween := _tween()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(
		avatar_container,
		"scale",
		Vector2(base_scale.x * (0.92 if is_block else 0.84), base_scale.y * (1.08 if is_block else 0.82)),
		0.06
	)
	hit_tween.tween_property(
		avatar_container,
		"modulate",
		Color(
			1.14 if is_block else 1.24,
			1.00 if is_block else 0.78,
			1.22 if is_block else 0.76,
			base_modulate.a
		),
		0.06
	)
	if border_ring != null:
		var base_ring := border_ring.modulate
		hit_tween.tween_property(
			border_ring,
			"modulate",
			Color(
				flash_color.r,
				flash_color.g,
				flash_color.b,
				maxf(base_ring.a, 0.82 if is_block else 0.88)
			),
			0.05
		)
		hit_tween.chain().tween_property(border_ring, "modulate", base_ring, 0.24)
	if background != null:
		var base_background := background.modulate
		hit_tween.tween_property(
			background,
			"modulate",
			Color(
				minf(base_background.r + (0.10 if is_block else 0.18), 1.2),
				minf(base_background.g + (0.14 if is_block else 0.04), 1.2),
				minf(base_background.b + (0.22 if is_block else 0.02), 1.2),
				base_background.a
			),
			0.05
		)
		hit_tween.chain().tween_property(background, "modulate", base_background, 0.20)
	hit_tween.chain().tween_property(avatar_container, "scale", base_scale, 0.20)
	hit_tween.parallel().tween_property(avatar_container, "modulate", base_modulate, 0.26)


func spawn_impact_burst(world_position: Vector2, base_color: Color, is_block: bool = false) -> void:
	if host.floating_effect_layer == null:
		return
	var local_position := to_layer_local_point(host.floating_effect_layer, world_position)
	spawn_attack_impact_particles(world_position, is_block)

	var ring := TextureRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.texture = _soft_glow_texture()
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_SCALE
	ring.modulate = Color(base_color.r, base_color.g, base_color.b, 0.56)
	ring.size = Vector2(18, 18)
	ring.position = local_position - ring.size * 0.5
	ring.pivot_offset = ring.size * 0.5
	host.floating_effect_layer.add_child(ring)

	var ring_tween := _tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2.ONE * 1.85, 0.30)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.30)
	ring_tween.tween_callback(ring.queue_free)

	for _i in range(9):
		var frag := TextureRect.new()
		frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frag.texture = _soft_glow_texture()
		frag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frag.stretch_mode = TextureRect.STRETCH_SCALE
		frag.modulate = Color(base_color.r, base_color.g, base_color.b, 0.84)
		frag.size = Vector2(14.0, 14.0)
		frag.pivot_offset = frag.size * 0.5
		frag.position = local_position - frag.size * 0.5
		host.floating_effect_layer.add_child(frag)
		var angle := randf() * TAU
		var distance := randf_range(28.0, 78.0)
		var target_pos := local_position + Vector2(cos(angle), sin(angle)) * distance - frag.size * 0.5
		var frag_tween := _tween()
		frag_tween.set_parallel(true)
		frag_tween.tween_property(frag, "position", target_pos, 0.40)
		frag_tween.tween_property(frag, "scale", Vector2.ONE * randf_range(0.34, 0.58), 0.40)
		frag_tween.tween_property(frag, "modulate", Color(base_color.r, base_color.g, base_color.b, 0.0), 0.40)
		frag_tween.tween_callback(frag.queue_free)


func spawn_damage_number(world_position: Vector2, damage: int) -> void:
	if host.floating_effect_layer == null or damage <= 0:
		return
	var label := UIFactory.make_label("-%d" % damage, 28, Color("ffd8cf"), true)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label_size := label.get_combined_minimum_size()
	var local_position := to_layer_local_point(host.floating_effect_layer, world_position)
	label.position = local_position - label_size * 0.5
	label.pivot_offset = label_size * 0.5
	label.scale = Vector2.ONE * 0.58
	label.rotation_degrees = randf_range(-6.0, 6.0)
	label.modulate = Color(1.12, 0.94, 0.88, 0.0)
	host.floating_effect_layer.add_child(label)

	var pop := _tween()
	pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(label, "scale", Vector2.ONE * 1.42, 0.10)
	pop.tween_property(label, "scale", Vector2.ONE, 0.14)

	var intro := _tween()
	intro.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro.set_parallel(true)
	intro.tween_property(label, "position", label.position + Vector2(randf_range(-8.0, 8.0), -18.0), 0.12)
	intro.tween_property(label, "modulate", Color(1.0, 0.90, 0.84, 1.0), 0.08)
	intro.tween_property(label, "rotation_degrees", randf_range(-2.0, 2.0), 0.12)
	intro.finished.connect(_play_damage_number_outro.bind(label.get_instance_id()))


func spawn_undying_burst(world_position: Vector2) -> void:
	if host.floating_effect_layer == null:
		return
	var local_position := to_layer_local_point(host.floating_effect_layer, world_position)

	var core := TextureRect.new()
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.texture = _soft_glow_texture()
	core.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	core.stretch_mode = TextureRect.STRETCH_SCALE
	core.material = host._make_additive_canvas_material()
	core.size = Vector2(180.0, 180.0)
	core.pivot_offset = core.size * 0.5
	core.position = local_position - core.size * 0.5
	core.scale = Vector2.ONE * 0.24
	core.modulate = Color(1.0, 0.94, 0.82, 0.92)
	core.z_index = 18
	host.floating_effect_layer.add_child(core)
	var core_tween := _tween()
	core_tween.set_parallel(true)
	core_tween.tween_property(core, "scale", Vector2.ONE * 1.20, 0.24)
	core_tween.tween_property(core, "modulate:a", 0.0, 0.24)
	core_tween.tween_callback(core.queue_free)

	for ring_data in [
		{"size": 88.0, "scale": 2.30, "duration": 0.34, "color": Color(1.0, 0.80, 0.34, 0.76)},
		{"size": 142.0, "scale": 1.82, "duration": 0.42, "color": Color(1.0, 0.42, 0.28, 0.46)},
	]:
		var ring := TextureRect.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.texture = _soft_glow_texture()
		ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ring.stretch_mode = TextureRect.STRETCH_SCALE
		ring.material = host._make_additive_canvas_material()
		ring.size = Vector2.ONE * float(ring_data["size"])
		ring.pivot_offset = ring.size * 0.5
		ring.position = local_position - ring.size * 0.5
		ring.scale = Vector2.ONE * 0.18
		ring.modulate = ring_data["color"]
		ring.z_index = 17
		host.floating_effect_layer.add_child(ring)
		var ring_tween := _tween()
		ring_tween.set_parallel(true)
		ring_tween.tween_property(ring, "scale", Vector2.ONE * float(ring_data["scale"]), float(ring_data["duration"]))
		ring_tween.tween_property(ring, "modulate:a", 0.0, float(ring_data["duration"]))
		ring_tween.tween_callback(ring.queue_free)

	for _i in range(18):
		var frag := TextureRect.new()
		frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frag.texture = _soft_glow_texture()
		frag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frag.stretch_mode = TextureRect.STRETCH_SCALE
		frag.material = host._make_additive_canvas_material()
		var frag_size := randf_range(12.0, 22.0)
		frag.size = Vector2.ONE * frag_size
		frag.pivot_offset = frag.size * 0.5
		frag.position = local_position - frag.size * 0.5
		frag.scale = Vector2.ONE * randf_range(0.28, 0.54)
		frag.rotation_degrees = randf_range(-180.0, 180.0)
		frag.modulate = Color(
			randf_range(0.96, 1.0),
			randf_range(0.56, 0.90),
			randf_range(0.20, 0.48),
			randf_range(0.68, 0.96)
		)
		frag.z_index = 19
		host.floating_effect_layer.add_child(frag)
		var angle := randf() * TAU
		var distance := randf_range(68.0, 146.0)
		var target_pos := local_position + Vector2(cos(angle), sin(angle)) * distance + Vector2(0.0, randf_range(-42.0, 16.0)) - frag.size * 0.5
		var frag_tween := _tween()
		frag_tween.set_parallel(true)
		frag_tween.tween_property(frag, "position", target_pos, 0.44)
		frag_tween.tween_property(frag, "scale", Vector2.ONE * randf_range(0.08, 0.20), 0.44)
		frag_tween.tween_property(frag, "rotation_degrees", frag.rotation_degrees + randf_range(-90.0, 90.0), 0.44)
		frag_tween.tween_property(frag, "modulate:a", 0.0, 0.44)
		frag_tween.tween_callback(frag.queue_free)

	for _i in range(4):
		var streak := ColorRect.new()
		streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
		streak.color = Color(1.0, 0.82, 0.42, 0.82)
		streak.size = Vector2(randf_range(4.0, 7.0), randf_range(54.0, 88.0))
		streak.pivot_offset = Vector2(streak.size.x * 0.5, streak.size.y)
		streak.position = local_position + Vector2(randf_range(-24.0, 24.0), randf_range(12.0, 28.0))
		streak.rotation_degrees = randf_range(-26.0, 26.0)
		streak.z_index = 16
		host.floating_effect_layer.add_child(streak)
		var streak_tween := _tween()
		streak_tween.set_parallel(true)
		streak_tween.tween_property(
			streak,
			"position",
			streak.position + Vector2(randf_range(-12.0, 12.0), -randf_range(90.0, 132.0)),
			0.30
		)
		streak_tween.tween_property(streak, "scale", Vector2(1.0, 0.22), 0.30)
		streak_tween.tween_property(streak, "color:a", 0.0, 0.30)
		streak_tween.tween_callback(streak.queue_free)


func animate_player_undying_rebound() -> void:
	var actor := get_player_stage_hit_node()
	if actor != null:
		var base_position := actor.position
		var base_scale := actor.scale
		var base_modulate := actor.modulate
		var actor_tween := _tween()
		actor_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		actor_tween.set_parallel(true)
		actor_tween.tween_property(actor, "position", base_position + Vector2(0.0, -18.0), 0.15)
		actor_tween.tween_property(actor, "scale", Vector2(base_scale.x * 1.10, base_scale.y * 1.14), 0.15)
		actor_tween.tween_property(actor, "modulate", Color(1.18, 1.08, 0.92, base_modulate.a), 0.11)
		actor_tween.chain().tween_property(actor, "position", base_position, 0.26)
		actor_tween.parallel().tween_property(actor, "scale", base_scale, 0.30)
		actor_tween.parallel().tween_property(actor, "modulate", base_modulate, 0.30)

	var seat := _seat_node("player")
	if seat == null:
		return
	var border_ring: TextureRect = seat.get_meta("border_ring") as TextureRect
	var background: TextureRect = seat.get_meta("background") as TextureRect
	if background != null:
		var background_base := background.modulate
		var background_tween := _tween()
		background_tween.tween_property(
			background,
			"modulate",
			Color(
				minf(background_base.r + 0.22, 1.15),
				minf(background_base.g + 0.10, 1.08),
				minf(background_base.b + 0.06, 1.02),
				minf(background_base.a + 0.30, 0.92)
			),
			0.10
		)
		background_tween.tween_property(background, "modulate", background_base, 0.34)
	if border_ring != null:
		var ring_base := border_ring.modulate
		var ring_tween := _tween()
		ring_tween.tween_property(border_ring, "modulate", Color(1.0, 0.84, 0.48, maxf(ring_base.a, 0.96)), 0.08)
		ring_tween.tween_property(border_ring, "modulate", ring_base, 0.34)

	if host.hero_spotlight_halo != null and host.hero_spotlight_halo.is_inside_tree():
		var halo_base_scale: Vector2 = host.hero_spotlight_halo.scale
		var halo_base_modulate: Color = host.hero_spotlight_halo.modulate
		var halo_tween := _tween()
		halo_tween.set_parallel(true)
		halo_tween.tween_property(host.hero_spotlight_halo, "scale", halo_base_scale * 1.18, 0.18)
		halo_tween.tween_property(
			host.hero_spotlight_halo,
			"modulate",
			Color(1.0, 0.88, 0.54, minf(1.0, halo_base_modulate.a + 0.32)),
			0.12
		)
		halo_tween.chain().tween_property(host.hero_spotlight_halo, "scale", halo_base_scale, 0.30)
		halo_tween.parallel().tween_property(host.hero_spotlight_halo, "modulate", halo_base_modulate, 0.32)


func show_undying_trigger_banner(world_position: Vector2) -> void:
	if host.floating_effect_layer == null:
		return
	var banner := PanelContainer.new()
	banner.z_index = 220
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.34, 0.06, 0.06, 0.0)
	banner_style.border_color = Color("ffc56c")
	banner_style.border_width_left = 2
	banner_style.border_width_top = 2
	banner_style.border_width_right = 2
	banner_style.border_width_bottom = 4
	banner_style.corner_radius_top_left = 14
	banner_style.corner_radius_top_right = 14
	banner_style.corner_radius_bottom_left = 14
	banner_style.corner_radius_bottom_right = 14
	banner_style.shadow_color = Color(1.0, 0.44, 0.18, 0.28)
	banner_style.shadow_size = 26
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

	var title := UIFactory.make_label("不死触发", 30, Color("fff1cf"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color("4d1111"))
	content.add_child(title)

	var subtitle := UIFactory.make_label("1 HP 续命", 18, Color("ffd481"), true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color("351010"))
	content.add_child(subtitle)

	host.floating_effect_layer.add_child(banner)
	banner.custom_minimum_size = Vector2(296.0, 96.0)
	banner.size = banner.custom_minimum_size
	banner.pivot_offset = banner.size * 0.5

	var anchor := to_layer_local_point(host.floating_effect_layer, world_position)
	var banner_layout: Dictionary = host._register_floating_banner(
		banner,
		anchor,
		{
			"base_offset_y": 160.0,
			"stack_gap": 12.0,
			"enter_offset_y": 26.0,
			"layout_duration": 0.18,
		}
	)
	host._play_floating_banner_enter(
		banner,
		banner_style,
		banner_layout.get("target_position", banner.position),
		{
			"enter_delay": float(banner_layout.get("enter_delay", 0.0)),
			"enter_offset_y": 26.0,
			"position_duration": 0.26,
			"scale_duration": 0.24,
			"fade_duration": 0.18,
			"bg_alpha": 0.94,
			"start_scale": Vector2(0.76, 0.76),
		},
		host._on_undying_banner_enter_finished.bind(banner.get_instance_id())
	)


func get_seat_world_center(seat_id: String, ally_uid: int = -1) -> Vector2:
	var actor := _seat_actor_node(seat_id, ally_uid)
	if actor != null:
		var actor_rect := actor.get_global_rect()
		return actor_rect.position + actor_rect.size * 0.5
	var seat := _seat_node(seat_id)
	if seat == null:
		return Vector2.ZERO
	return seat.global_position + seat.size * 0.5
