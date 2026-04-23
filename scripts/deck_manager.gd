extends RefCounted
class_name DeckManager

const GameState = preload("res://scripts/game_state.gd")
const Characters = preload("res://data/characters.gd")
const GameBalance = preload("res://scripts/game_balance.gd")


static func build_deck(player_char: Dictionary) -> Array:
	var pool: Array = []
	for character in Characters.all_characters():
		if character["code"] != player_char["code"]:
			pool.append(character)

	var picked := _pick_weighted_characters(pool, GameState.DECK_SIZE)
	var base_ally_chance := clampf(
		float(player_char["charm"]) - GameBalance.GLOBAL_ALLY_CHANCE_PENALTY,
		0.0,
		1.0
	)
	var deck: Array = []

	for i in range(picked.size()):
		var character: Dictionary = picked[i]
		deck.append({
			"character": character,
			"fate": _roll_fate(_get_character_ally_chance(base_ally_chance, 0.0, character)),
			"revealed": false,
			"idx": i,
		})

	return deck


static func _pick_weighted_characters(pool: Array, count: int) -> Array:
	var remaining := pool.duplicate()
	var picked: Array = []
	var target_count := mini(count, remaining.size())

	for _i in range(target_count):
		var total_weight := 0.0
		for character in remaining:
			total_weight += GameBalance.get_rarity_pick_weight(character)

		if total_weight <= 0.0:
			remaining.shuffle()
			picked.append_array(remaining.slice(0, target_count - picked.size()))
			break

		var roll := randf() * total_weight
		var cumulative := 0.0
		var picked_index := remaining.size() - 1
		for j in range(remaining.size()):
			cumulative += GameBalance.get_rarity_pick_weight(remaining[j])
			if roll <= cumulative:
				picked_index = j
				break

		picked.append(remaining[picked_index])
		remaining.remove_at(picked_index)

	return picked


static func get_effective_charm(state: GameState) -> float:
	if state.player_character.is_empty():
		return 0.5

	var charm := float(state.player_character["charm"]) - GameBalance.GLOBAL_ALLY_CHANCE_PENALTY

	if not state.is_monk_hero():
		for effect in state.charm_effects:
			charm += float(effect["amount"])

		for ally in state.allies:
			if ally["character"]["code"] == "SEXY" and not ally["is_spy"]:
				charm += 0.05

	if state.player_character["code"] == "SOLO":
		charm += float(state.empty_slots()) * 0.05

	if state.player_character["code"] == "JOKE-R" and state.max_hp > 0:
		var missing_pct := 1.0 - float(state.hp) / float(state.max_hp)
		charm += floor(missing_pct * 10.0) * 0.02

	if state.max_hp > 0 and float(state.hp) / float(state.max_hp) <= GameBalance.LOW_HP_FEAR_THRESHOLD:
		charm -= GameBalance.LOW_HP_FEAR_PENALTY

	return clampf(charm, 0.0, 1.0)


static func get_adjusted_ally_chance(state: GameState, character: Dictionary) -> float:
	var base_ally_chance := get_effective_charm(state)
	var streak_shift := _get_streak_shift(state)
	return _get_character_ally_chance(base_ally_chance, streak_shift, character)


static func _get_character_ally_chance(base_ally_chance: float, streak_shift: float, character: Dictionary) -> float:
	var rarity_mod := GameBalance.get_rarity_ally_modifier(character)
	var chance := base_ally_chance * rarity_mod + streak_shift
	return clampf(chance, GameBalance.MIN_ALLY_CHANCE, GameBalance.MAX_ALLY_CHANCE)


static func _get_streak_shift(state: GameState) -> float:
	var decay := _get_nonlinear_streak_decay(state.fate_streak_count)
	if state.fate_streak_type == "ally":
		return -decay
	if state.fate_streak_type == "enemy":
		return decay
	return 0.0


static func reassign_fate(card: Dictionary, new_fate: String) -> void:
	card["fate"] = new_fate


static func redistribute_fates(state: GameState) -> void:
	for card in state.deck:
		if not card["revealed"]:
			if card.has("locked_fate") and not String(card["locked_fate"]).is_empty():
				card["fate"] = String(card["locked_fate"])
			else:
				card["fate"] = _roll_fate(get_adjusted_ally_chance(state, card["character"]))


static func add_charm_effect(state: GameState, amount: float, remaining: int, source: String) -> void:
	if remaining <= 0 or state.is_monk_hero():
		return

	state.charm_effects.append({
		"amount": amount,
		"remaining": remaining,
		"positive": amount > 0.0,
		"source": source,
	})
	redistribute_fates(state)


static func tick_charm_effects(state: GameState) -> void:
	if state.charm_effects.is_empty():
		return

	var next_effects: Array = []
	for effect in state.charm_effects:
		var updated: Dictionary = effect.duplicate(true)
		updated["remaining"] = int(updated["remaining"]) - 1
		if updated["remaining"] > 0:
			next_effects.append(updated)

	state.charm_effects = next_effects
	redistribute_fates(state)


static func clear_charm_effects(state: GameState, positive: Variant = null) -> void:
	if positive == null:
		state.charm_effects.clear()
	else:
		var next_effects: Array = []
		for effect in state.charm_effects:
			if effect["positive"] != positive:
				next_effects.append(effect)
		state.charm_effects = next_effects

	redistribute_fates(state)


static func _roll_fate(ally_chance: float) -> String:
	if randf() < ally_chance:
		return "ally"
	return "enemy"


static func _get_nonlinear_streak_decay(streak_count: int) -> float:
	if streak_count <= 0:
		return 0.0
	var scaled := 1.0 - exp(-0.40 * pow(float(streak_count), 1.7))
	return minf(GameBalance.MAX_STREAK_DECAY, GameBalance.MAX_STREAK_DECAY * scaled)
