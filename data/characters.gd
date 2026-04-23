extends RefCounted
class_name Characters

const DATA_PATH := "res://data/characters.json"
const GameBalance = preload("res://scripts/game_balance.gd")

static var _cache: Array = []


static func all_characters() -> Array:
	_ensure_loaded()
	return _cache.duplicate(true)


static func get_by_code(code: String) -> Dictionary:
	_ensure_loaded()
	for character in _cache:
		if character["code"] == code:
			return character.duplicate(true)
	return {}


static func _ensure_loaded() -> void:
	if not _cache.is_empty():
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open character data: %s" % DATA_PATH)
		_cache = []
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		_cache = []
		for character in parsed:
			if character is Dictionary:
				_cache.append(GameBalance.decorate_character(character))
	else:
		push_error("Invalid character data in %s" % DATA_PATH)
		_cache = []
