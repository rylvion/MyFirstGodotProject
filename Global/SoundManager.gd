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


# 49053354-sword-slash-315218.ogg: 0.627 sec (627 ms)
# dragon-studio-epic-dragon-roar-364481.ogg: 3.448 sec (3448 ms)
# dragon-studio-frog-croaking-sound-effect-322956.ogg: 0.314 sec (314 ms)
# dragon-studio-sword-clashhit-393837.ogg: 0.262 sec (262 ms)
# driken5482-retro-explode-1-236678.ogg: 0.340 sec (340 ms)
# floraphonic-fireball-whoosh-1-179125.ogg: 0.397 sec (397 ms)
# floraphonic-slime-squish-5-218569.ogg: 0.576 sec (576 ms)
# freesound_community-super-deep-growl-86749.ogg: 0.966 sec (966 ms)
# lesiakower-8-bit-game-over-sound-effect-331435.ogg: 2.374 sec (2374 ms)
# liecio-collect-points-190037.ogg: 0.313 sec (313 ms)
# scratchonix-victory-chime-366449.ogg: 5.842 sec (5842 ms)

const DEFAULT_SFX_PATHS: Dictionary = {
	"slime_move": "res://audio/SFX/floraphonic-slime-squish-5-218569.ogg", # use this when slime chasing (576 ms)
	"frog": "res://audio/SFX/dragon-studio-frog-croaking-sound-effect-322956.ogg", # use this for chasing (314 ms)
	"enemy_explode": "res://audio/SFX/driken5482-retro-explode-1-236678.ogg", # use this for enemy explosions/death (340 ms)
	"slash": "res://audio/SFX/49053354-sword-slash-315218.ogg", # use this for player sword swings (627 ms)
	"slash_hit": "res://audio/SFX/dragon-studio-sword-clashhit-393837.ogg", # use this for player sword connect hits (262 ms)
	"roar": "res://audio/SFX/dragon-studio-epic-dragon-roar-364481.ogg", # use this when boss spawns, when boss does summoning and idk (3448 ms)
	"fireball": "res://audio/SFX/floraphonic-fireball-whoosh-1-179125.ogg", # use this for fireball cast (397 ms)
	"pickup_collectable": "res://audio/SFX/liecio-collect-points-190037.ogg", # use this for gem and cherry pickups (313 ms)
	"victory": "res://audio/SFX/scratchonix-victory-chime-366449.ogg", # use this for victory fanfare after boss is defeated or after game completion (5842 ms)
	"growl": "res://audio/SFX/freesound_community-super-deep-growl-86749.ogg", # use this for boss growl (966 ms)
	"game_over": "res://audio/SFX/lesiakower-8-bit-game-over-sound-effect-331435.ogg" # use this for game over/when player dies (2374 ms)
}

# bijaybro-anime-inspiring-music-389687.ogg: 89.913 sec (89913 ms)
# nyxaurora-final-battle-ii-epic-cinematic-battle-music-with-intense-orchestral-361155.ogg: 121.344 sec (121344 ms)
# sekuora-epic-orchestra-anime-intro-242461.ogg: 118.704 sec (118704 ms)

const DEFAULT_MUSIC_PATHS: Dictionary = {
	"main_menu": "res://audio/music/bijaybro-anime-inspiring-music-389687.ogg", # Use this for main menu (looping, 89.913 sec (89913 ms))
	"world_loop": "res://audio/music/sekuora-epic-orchestra-anime-intro-242461.ogg", # Use this for normal gameplay (looping, 118.704 sec (118704 ms)) 
	"boss_soundtrack": "res://audio/music/nyxaurora-final-battle-ii-epic-cinematic-battle-music-with-intense-orchestral-361155.ogg" # Use this for boss fights (looping, 121.344 sec (121344 ms) fade out (10 sec) after boss is defeated, fade in 5 sec when boss spawns)
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_music_player()
	_setup_sfx_pool()
	_preload_all()


# plays sfx and RETURNS the player so u can mess with it later if u want
func play_sfx(sound_key: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0, use_randomization := true) -> AudioStreamPlayer:
	if get_tree() != null and get_tree().paused:
		return null

	var stream: AudioStream = _get_stream_from_paths(sfx_paths, sound_key)
	if stream == null:
		push_warning("sfx missing: %s" % sound_key)
		return null

	var player: AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		return null

	player.stream = stream

	# random variation so it doesnt sound like copy paste every time
	if use_randomization:
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
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)


func _setup_sfx_pool() -> void:
	for player_index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % player_index
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
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
