extends Node

# put your sound file paths here.
# keep them as res:// paths to .wav, .ogg, or .mp3 files.
#
# sfx ideas:
# - slime_move: slime sludge effect
# - slime_hit: slime squish hit
# - frog_idle: frog ribbit sound
# - frog_jump: frog jump croak / hop
# - boss_roar: boss roar when spawning or phase shift
# - boss_fireball: long-range fireball cast
# - boss_firebreath: summon / breath hitbox sound
# - boss_tail_sweep: tail sweep / whoosh
# - boss_summon: enemy summon magic sound
# - saber_swing: saber swing
# - saber_hit: saber hit / slice connect
# - player_hurt: player damage sound
# - gem_pickup: diamond / gem pickup
# - cherry_pickup: cherry pickup
#
# music ideas:
# - main_menu: menu soundtrack
# - world_loop: normal gameplay soundtrack
# - boss_wave: boss soundtrack
# - victory: win / ending soundtrack

const DEFAULT_SFX_PATHS: Dictionary = {
	# example:
	# "slime_move": "res://audio/sfx/slime/sludge_move.ogg",
}

const DEFAULT_MUSIC_PATHS: Dictionary = {
	# example:
	# "main_menu": "res://music/main_menu.ogg",
}

const SFX_POOL_SIZE: int = 12

var sfx_paths: Dictionary = DEFAULT_SFX_PATHS.duplicate(true)
var music_paths: Dictionary = DEFAULT_MUSIC_PATHS.duplicate(true)

# cache so we dont keep loading same file like an idiot mid game
var _stream_cache: Dictionary = {}

# pool of players so sounds dont cut each other off instantly
var _sfx_players: Array[AudioStreamPlayer] = []

# keep track of what player is playing what (so we can stop specific stuff)
var _active_sfx: Dictionary = {}

var _music_player: AudioStreamPlayer = null
var _current_music_key: StringName = &""


func _ready() -> void:
	_setup_music_player()
	_setup_sfx_pool()
	_preload_all()


# plays sfx and RETURNS the player so u can mess with it later if u want
func play_sfx(sound_key: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0, randomize := true) -> AudioStreamPlayer:
	var stream: AudioStream = _get_stream_from_paths(sfx_paths, sound_key)
	if stream == null:
		push_warning("sfx missing: %s" % sound_key)
		return null

	var player: AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		return null

	player.stream = stream

	# random variation so it doesnt sound like copy paste every time
	if randomize:
		player.pitch_scale = randf_range(0.95, 1.05)
		player.volume_db = volume_db + randf_range(-1.0, 1.0)
	else:
		player.pitch_scale = pitch_scale
		player.volume_db = volume_db

	player.play()

	# track it so we can stop later
	_active_sfx[player] = sound_key

	return player


func stop_sfx(player: AudioStreamPlayer) -> void:
	# stop specific sound instance
	if player == null:
		return
	player.stop()
	_active_sfx.erase(player)


func stop_all_sfx() -> void:
	# brute force kill everything
	for player in _sfx_players:
		player.stop()
	_active_sfx.clear()


func play_music(track_key: StringName, volume_db: float = -4.0, restart_if_same: bool = false) -> void:
	if _music_player == null:
		return

	if _current_music_key == track_key and _music_player.playing and not restart_if_same:
		return

	var stream: AudioStream = _get_stream_from_paths(music_paths, track_key)
	if stream == null:
		push_warning("music missing: %s" % track_key)
		return

	_current_music_key = track_key
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.pitch_scale = 1.0
	_music_player.play()


func stop_music() -> void:
	if _music_player == null:
		return
	_music_player.stop()
	_current_music_key = &""


func pause_music() -> void:
	if _music_player:
		_music_player.stream_paused = true


func resume_music() -> void:
	if _music_player:
		_music_player.stream_paused = false


# small fade cuz instant cuts sound kinda meh
func fade_out_music(duration := 1.0):
	if _music_player == null:
		return
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -80, duration)
	tween.tween_callback(_music_player.stop)


func has_sfx(sound_key: StringName) -> bool:
	return _has_path(sfx_paths, sound_key)


func has_music(track_key: StringName) -> bool:
	return _has_path(music_paths, track_key)


func set_sfx_path(sound_key: StringName, resource_path: String) -> void:
	sfx_paths[String(sound_key)] = resource_path
	_stream_cache.erase(resource_path)


func set_music_path(track_key: StringName, resource_path: String) -> void:
	music_paths[String(track_key)] = resource_path
	_stream_cache.erase(resource_path)


func get_sfx_keys() -> PackedStringArray:
	return PackedStringArray(sfx_paths.keys())


func get_music_keys() -> PackedStringArray:
	return PackedStringArray(music_paths.keys())


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = &"Music"
	add_child(_music_player)


func _setup_sfx_pool() -> void:
	for player_index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % player_index
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)


# pick free one, otherwise steal the oldest sounding one
func _get_available_sfx_player() -> AudioStreamPlayer:
	var oldest := _sfx_players[0]
	for player in _sfx_players:
		if not player.playing:
			return player
		if player.get_playback_position() > oldest.get_playback_position():
			oldest = player
	return oldest


# preload everything at start so no lag spikes later
func _preload_all() -> void:
	for path in sfx_paths.values():
		if not _stream_cache.has(path):
			_stream_cache[path] = load(path)

	for path in music_paths.values():
		if not _stream_cache.has(path):
			_stream_cache[path] = load(path)


func _get_stream_from_paths(path_map: Dictionary, sound_key: StringName) -> AudioStream:
	var key_string: String = String(sound_key)
	if not path_map.has(key_string):
		return null

	var resource_path: String = str(path_map[key_string]).strip_edges()
	if resource_path == "":
		return null

	if _stream_cache.has(resource_path):
		return _stream_cache[resource_path]

	var stream := load(resource_path) as AudioStream
	if stream == null:
		push_warning("failed to load audio: %s" % resource_path)
		return null

	_stream_cache[resource_path] = stream
	return stream


func _has_path(path_map: Dictionary, sound_key: StringName) -> bool:
	return path_map.has(String(sound_key)) and str(path_map[String(sound_key)]).strip_edges() != ""
