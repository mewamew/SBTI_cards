extends RefCounted
class_name GameState

const GameBalance = preload("res://scripts/game_balance.gd")

const MAX_ALLIES := 4
const DECK_SIZE := 15

var phase := "title"
var player_character: Dictionary = {}
var hp := 0
var max_hp := 0
var round := 0
var max_ally_slots := MAX_ALLIES

var allies: Array = []
var deck: Array = []
var discard_pile: Array = []

var undying := false
var peek_charges := 0
var fate_reverse_charges := 0
var skip_charges := 0
var reroll_charges := 0
var think_charges := 0
var forced_next_fate: Variant = null

var taunt_multiplier := 1
var charm_effects: Array = []
var isolate := false
var isolate_turns := 0
var vuln_stacks := 0
var heal_boost := false
var skip_turns := 0
var pending_chain_flips := 0
var pending_spy_exposures: Array = []
var force_double_next_turn := false
var next_ally_blocked := false
var slot_seal_turns: Array = []

var consecutive_enemies := 0
var last_enemy_damage := 0
var revenge_stored := 0
var last_revealed_fate: Variant = null
var fate_streak_type: Variant = null
var fate_streak_count := 0
var true_love_used := false
var ally_loss_stacks := 0

var game_over := false
var victory := false


func reset() -> void:
	phase = "title"
	player_character = {}
	hp = 0
	max_hp = 0
	round = 0
	max_ally_slots = MAX_ALLIES
	allies.clear()
	deck.clear()
	discard_pile.clear()
	undying = false
	peek_charges = 0
	fate_reverse_charges = 0
	skip_charges = 0
	reroll_charges = 0
	think_charges = 0
	forced_next_fate = null
	taunt_multiplier = 1
	charm_effects.clear()
	isolate = false
	isolate_turns = 0
	vuln_stacks = 0
	heal_boost = false
	skip_turns = 0
	pending_chain_flips = 0
	pending_spy_exposures.clear()
	force_double_next_turn = false
	next_ally_blocked = false
	slot_seal_turns.clear()
	consecutive_enemies = 0
	last_enemy_damage = 0
	revenge_stored = 0
	last_revealed_fate = null
	fate_streak_type = null
	fate_streak_count = 0
	true_love_used = false
	ally_loss_stacks = 0
	game_over = false
	victory = false


func start_run(character: Dictionary) -> void:
	reset()
	player_character = character.duplicate(true)
	hp = int(character["hp"])
	max_hp = int(character["hp"])
	phase = "battle_idle"

	var code: String = character["code"]
	if code == "BOSS":
		max_ally_slots = MAX_ALLIES + 1
	if code == "POOR":
		max_ally_slots = 2
	if code == "CTRL":
		peek_charges = 3
	if code == "FAKE":
		fate_reverse_charges = 2
	if code == "OH-NO":
		skip_charges = 3
	if code == "WOC!":
		reroll_charges = 2
	if code == "THIN-K":
		think_charges = 3
	if code == "ZZZZ":
		skip_charges = 3


func remaining_cards() -> int:
	var count := 0
	for card in deck:
		if not card["revealed"]:
			count += 1
	return count


func total_cards() -> int:
	return deck.size()


func revealed_cards() -> int:
	return maxi(0, total_cards() - remaining_cards())


func starting_hp() -> int:
	if not player_character.is_empty() and player_character.has("hp"):
		return int(player_character["hp"])
	return max_hp


func displayed_hp_capacity() -> int:
	return maxi(starting_hp(), max_hp)


func is_monk_hero() -> bool:
	return player_character.get("code", "") == "MONK"


func sealed_slot_count() -> int:
	return slot_seal_turns.size()


func usable_ally_slots() -> int:
	return maxi(0, max_ally_slots - sealed_slot_count())


func ally_uses_slot(ally: Dictionary) -> bool:
	var extra: Dictionary = ally.get("extra", {})
	return not extra.get("slotless", false)


func occupied_slots() -> int:
	var count := 0
	for ally in allies:
		if ally_uses_slot(ally):
			count += 1
	return count


func slotless_ally_count() -> int:
	var count := 0
	for ally in allies:
		if not ally_uses_slot(ally):
			count += 1
	return count


func empty_slots() -> int:
	return maxi(0, usable_ally_slots() - occupied_slots())


func can_add_ally(ally: Dictionary = {}) -> bool:
	return not ally_uses_slot(ally) or empty_slots() > 0


func ally_slot_summary(occupied_override: int = -1) -> String:
	var occupied := occupied_slots() if occupied_override < 0 else occupied_override
	var summary := "%d/%d" % [occupied, max_ally_slots]
	var slotless := slotless_ally_count()
	if slotless > 0:
		summary += " +%d编外" % slotless
	return summary


func pressure_multiplier() -> float:
	return GameBalance.get_pressure_multiplier(round)


func ally_loss_multiplier() -> float:
	return GameBalance.get_ally_loss_multiplier(ally_loss_stacks)
