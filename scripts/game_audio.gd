extends Node
class_name GameAudio

signal bgm_enabled_changed(enabled: bool)
signal sfx_enabled_changed(enabled: bool)

const SFX_CONFIG := {
	"card_hover": {
		"path": "res://assets/audio/sfx/final/card_hover.wav",
		"volume_db": -16.0,
		"cooldown": 0.05,
	},
	"card_select": {
		"path": "res://assets/audio/sfx/final/card_select.ogg",
		"volume_db": -10.0,
		"cooldown": 0.05,
	},
	"card_flip": {
		"path": "res://assets/audio/sfx/final/card_flip.wav",
		"volume_db": -8.0,
	},
	"ally_join": {
		"path": "res://assets/audio/sfx/final/ally_join.ogg",
		"volume_db": -9.0,
	},
	"ally_replace": {
		"path": "res://assets/audio/sfx/final/ally_replace.ogg",
		"volume_db": -8.0,
	},
	"enemy_hit": {
		"path": "res://assets/audio/sfx/final/enemy_hit.ogg",
		"volume_db": -4.0,
		"cooldown": 0.03,
	},
	"ally_block": {
		"path": "res://assets/audio/sfx/final/ally_block.ogg",
		"volume_db": -5.5,
	},
	"heal": {
		"path": "res://assets/audio/sfx/final/heal.ogg",
		"volume_db": -10.0,
		"cooldown": 0.04,
	},
	"spy_reveal": {
		"path": "res://assets/audio/sfx/final/spy_reveal.wav",
		"volume_db": -7.0,
	},
	"spotlight_reveal": {
		"path": "res://assets/audio/sfx/final/spotlight_reveal.ogg",
		"volume_db": -9.0,
		"cooldown": 0.08,
	},
	"fate_reveal": {
		"path": "res://assets/audio/sfx/final/fate_reveal.ogg",
		"volume_db": -1.5,
	},
	"victory": {
		"path": "res://assets/audio/sfx/final/victory.wav",
		"volume_db": -11.0,
	},
	"defeat": {
		"path": "res://assets/audio/sfx/final/defeat.ogg",
		"volume_db": -11.0,
	},
}

const BGM_CONFIG := {
	"title_screen_theme": {
		"path": "res://assets/audio/bgm/final/title_screen_theme.mp3",
		"volume_db": -24.0,
		"loop": true,
		"start_position_sec": 13.5,
		"loop_offset_sec": 13.5,
	},
	"select_screen_theme": {
		"path": "res://assets/audio/bgm/final/select_screen_theme.mp3",
		"volume_db": -25.0,
		"loop": true,
	},
	"battle_screen_theme": {
		"path": "res://assets/audio/bgm/final/battle_screen_theme.mp3",
		"volume_db": -26.0,
		"loop": true,
	},
}

var _stream_cache: Dictionary = {}
var _bgm_stream_cache: Dictionary = {}
var _last_play_ms: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _persistent_player: AudioStreamPlayer
var _current_bgm_key := ""
var bgm_enabled := true
var sfx_enabled := true


static func get_shared(context: Node) -> GameAudio:
	if context == null:
		return null
	var tree := context.get_tree()
	if tree == null:
		return null
	var nodes := tree.get_nodes_in_group("game_audio")
	if nodes.is_empty():
		return null
	return nodes[0] as GameAudio


func _ready() -> void:
	add_to_group("game_audio")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_players()


func play_sfx(key: String, volume_offset_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	_ensure_players()
	if not sfx_enabled:
		return
	var config: Dictionary = SFX_CONFIG.get(key, {})
	if config.is_empty():
		return
	if _is_on_cooldown(key, float(config.get("cooldown", 0.0))):
		return
	var stream := _get_stream(key)
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = stream
	player.volume_db = float(config.get("volume_db", 0.0)) + volume_offset_db
	player.pitch_scale = pitch_scale
	player.finished.connect(_on_one_shot_finished.bind(player))
	add_child(player)
	player.play()
	_last_play_ms[key] = Time.get_ticks_msec()


func play_persistent(key: String) -> void:
	_ensure_players()
	if not sfx_enabled:
		return
	var config: Dictionary = SFX_CONFIG.get(key, {})
	if config.is_empty():
		return
	var stream := _get_stream(key)
	if stream == null:
		return
	if _persistent_player == null:
		return
	if _persistent_player.playing:
		_persistent_player.stop()
	_persistent_player.stream = stream
	_persistent_player.volume_db = float(config.get("volume_db", 0.0))
	_persistent_player.pitch_scale = 1.0
	_persistent_player.play()
	_last_play_ms[key] = Time.get_ticks_msec()


func play_bgm(key: String) -> void:
	_ensure_players()
	_current_bgm_key = key
	if not bgm_enabled:
		return
	var config: Dictionary = BGM_CONFIG.get(key, {})
	if config.is_empty():
		return
	if _bgm_player == null:
		return
	var stream := _get_bgm_stream(key)
	if stream == null:
		return
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stop()
	_bgm_player.stream = stream
	_bgm_player.volume_db = float(config.get("volume_db", 0.0))
	_bgm_player.pitch_scale = 1.0
	_bgm_player.play(float(config.get("start_position_sec", 0.0)))


func set_bgm_enabled(enabled: bool) -> void:
	_ensure_players()
	if bgm_enabled == enabled:
		return
	bgm_enabled = enabled
	if bgm_enabled:
		if not _current_bgm_key.is_empty():
			play_bgm(_current_bgm_key)
	else:
		stop_bgm()
	bgm_enabled_changed.emit(bgm_enabled)


func toggle_bgm_enabled() -> void:
	set_bgm_enabled(not bgm_enabled)


func set_sfx_enabled(enabled: bool) -> void:
	_ensure_players()
	if sfx_enabled == enabled:
		return
	sfx_enabled = enabled
	if not sfx_enabled:
		_stop_active_sfx_players()
	sfx_enabled_changed.emit(sfx_enabled)


func toggle_sfx_enabled() -> void:
	set_sfx_enabled(not sfx_enabled)


func stop_bgm() -> void:
	_ensure_players()
	if _bgm_player != null and _bgm_player.playing:
		_bgm_player.stop()


func stop_persistent() -> void:
	_ensure_players()
	if _persistent_player != null and _persistent_player.playing:
		_persistent_player.stop()


func stop_all() -> void:
	stop_bgm()
	_stop_active_sfx_players()


func _get_stream(key: String) -> AudioStream:
	if _stream_cache.has(key):
		return _stream_cache[key] as AudioStream
	var config: Dictionary = SFX_CONFIG.get(key, {})
	if config.is_empty():
		return null
	var path := str(config.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	_stream_cache[key] = stream
	return stream


func _ensure_players() -> void:
	if _bgm_player == null or not is_instance_valid(_bgm_player):
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.name = "BgmPlayer"
		_bgm_player.bus = "Master"
		add_child(_bgm_player)
	if _persistent_player == null or not is_instance_valid(_persistent_player):
		_persistent_player = AudioStreamPlayer.new()
		_persistent_player.name = "PersistentPlayer"
		_persistent_player.bus = "Master"
		add_child(_persistent_player)


func _stop_active_sfx_players() -> void:
	stop_persistent()
	for child in get_children():
		if child == _bgm_player or child == _persistent_player:
			continue
		if child is AudioStreamPlayer:
			var player := child as AudioStreamPlayer
			if player.playing:
				player.stop()
			player.queue_free()


func _get_bgm_stream(key: String) -> AudioStream:
	if _bgm_stream_cache.has(key):
		return _bgm_stream_cache[key] as AudioStream
	var config: Dictionary = BGM_CONFIG.get(key, {})
	if config.is_empty():
		return null
	var path := str(config.get("path", ""))
	if path.is_empty():
		return null
	var stream := _load_audio_stream(path)
	if stream == null:
		return null
	_apply_loop_settings(
		stream,
		bool(config.get("loop", false)),
		float(config.get("loop_offset_sec", config.get("start_position_sec", 0.0)))
	)
	_bgm_stream_cache[key] = stream
	return stream


func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream

	var extension := path.get_extension().to_lower()
	if extension != "mp3":
		return null

	var data := FileAccess.get_file_as_bytes(path)
	if data.is_empty():
		return null

	var stream := AudioStreamMP3.new()
	stream.data = data
	return stream


func _apply_loop_settings(stream: AudioStream, should_loop: bool, loop_offset_sec: float = 0.0) -> void:
	if stream is AudioStreamMP3:
		var mp3 := stream as AudioStreamMP3
		mp3.loop = should_loop
		mp3.loop_offset = maxf(loop_offset_sec, 0.0)
	elif stream is AudioStreamOggVorbis:
		var ogg := stream as AudioStreamOggVorbis
		ogg.loop = should_loop
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if should_loop else AudioStreamWAV.LOOP_DISABLED


func _is_on_cooldown(key: String, cooldown_sec: float) -> bool:
	if cooldown_sec <= 0.0:
		return false
	if not _last_play_ms.has(key):
		return false
	var elapsed_ms := Time.get_ticks_msec() - int(_last_play_ms[key])
	return elapsed_ms < int(round(cooldown_sec * 1000.0))


func _on_one_shot_finished(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.queue_free()
