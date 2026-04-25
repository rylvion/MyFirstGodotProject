extends Node

const GAME_VERSION: String = "v.0.10-alpha"
const SAVE_SCHEMA_VERSION: int = 2
const MAX_LEVEL: int = 100
const MAX_GOLD: float = 10000.0
const HEAL_PER_WAVE: int = 10
const HEAL_PER_BOSS_WAVE: int = 25
const LIFESTEAL_PER_KILL: int = 1

signal level_changed(new_level: int)
signal hp_changed(new_hp: int)
signal max_hp_changed(new_max_hp: int)
signal gold_changed(new_gold: float)
signal wins_changed(total_wins: int)
signal tutorial_progress_changed
signal input_blocked_changed(is_blocked: bool)

var _max_hp: int = 10
var _player_hp: int = 10
var _gold: float = 0.0
var _level: int = 1
var _wins: int = 0
var _last_victory_wave: int = 0
var _startup_begin_msec: int = -1
var _input_blocked: bool = false

const TUTORIAL_STEP_ORDER: Array[StringName] = [
	&"move",
	&"jump",
	&"slash",
	&"attack",
	&"pickup_gold",
	&"stomp",
	&"level_up",
	&"elite_wave",
	&"boss_wave",
]

const TUTORIAL_STEP_HINTS: Dictionary = {
	&"move": "Tutorial: Move with A/D or Left/Right.",
	&"jump": "Tutorial: Press W, Up, or Space to jump.",
	&"slash": "Tutorial: Left click to swing the saber.",
	&"attack": "Tutorial: Press X, F, or Enter to throw a fireball.",
	&"pickup_gold": "Tutorial: Pick up cherries or gems to earn gold.",
	&"stomp": "Tutorial: Jump on an enemy to bounce-kill it for gold.",
	&"level_up": "Tutorial: Press R or use +1 Level when you can afford it.",
	&"elite_wave": "Tutorial: Every 5th non-boss wave is elite. Clear one to keep going.",
	&"boss_wave": "Tutorial: Boss waves happen every 10 waves. Beat the boss to advance.",
}

var tutorial_progress: Dictionary = {}


func get_hp_upgrade_cost(current_level: int) -> int:
	var level_index: int = max(current_level - 1, 0)
	var scaled_cost: float = 10.0 + (4.0 * level_index) + (0.25 * pow(level_index, 2.0))
	return max(10, int(round(scaled_cost)))


func get_max_hp(current_level: int) -> int:
	var level_index: int = max(current_level - 1, 0)
	var scaled_hp: float = 10.0 + (2.0 * level_index) + (0.05 * pow(level_index, 2.0))
	return max(10, int(round(scaled_hp)))


var maxHP: int:
	get:
		return _max_hp
	set(value):
		var safe_value: int = max(value, 1)
		if safe_value == _max_hp:
			return

		_max_hp = safe_value
		if _player_hp > _max_hp:
			_player_hp = _max_hp
			hp_changed.emit(_player_hp)
		max_hp_changed.emit(_max_hp)


var playerHP: int:
	get:
		return _player_hp
	set(value):
		var safe_value := clampi(value, 0, maxHP)
		if safe_value == _player_hp:
			return

		_player_hp = safe_value
		hp_changed.emit(_player_hp)


var gold: float:
	get:
		return _gold
	set(value):
		var safe_value := clampf(value, 0.0, MAX_GOLD)
		if is_equal_approx(safe_value, _gold):
			return

		_gold = safe_value
		gold_changed.emit(_gold)


var level: int:
	get:
		return _level
	set(value):
		var safe_value: int = clampi(value, 1, MAX_LEVEL)
		if safe_value == _level:
			return

		var old_max := maxHP
		_level = safe_value
		maxHP = get_max_hp(_level)
		if maxHP > old_max:
			playerHP = min(maxHP, playerHP + (maxHP - old_max))
		else:
			playerHP = min(maxHP, playerHP)
		level_changed.emit(_level)


var wins: int:
	get:
		return _wins
	set(value):
		var safe_value: int = max(value, 0)
		if safe_value == _wins:
			return

		_wins = safe_value
		wins_changed.emit(_wins)


var last_victory_wave: int:
	get:
		return _last_victory_wave
	set(value):
		_last_victory_wave = max(value, 0)


var input_blocked: bool:
	get:
		return _input_blocked
	set(value):
		if value == _input_blocked:
			return
		_input_blocked = value
		input_blocked_changed.emit(_input_blocked)


func try_level_up() -> bool:
	if level >= MAX_LEVEL:
		return false

	var cost: int = get_hp_upgrade_cost(level)
	if gold < cost:
		return false

	gold -= cost
	level += 1
	mark_tutorial_step(&"level_up")
	return true


func begin_startup_timer() -> void:
	_startup_begin_msec = Time.get_ticks_msec()


func consume_startup_timer_msec() -> int:
	if _startup_begin_msec < 0:
		return -1
	var elapsed: int = Time.get_ticks_msec() - _startup_begin_msec
	_startup_begin_msec = -1
	return elapsed


func apply_wave_completion_heal(completed_wave: int) -> int:
	if completed_wave <= 0:
		return 0

	var heal_amount: int = HEAL_PER_BOSS_WAVE if completed_wave % 10 == 0 else HEAL_PER_WAVE
	if heal_amount <= 0:
		return 0

	var before_hp: int = playerHP
	playerHP = min(maxHP, before_hp + heal_amount)
	return max(playerHP - before_hp, 0)


func apply_kill_lifesteal() -> int:
	if LIFESTEAL_PER_KILL <= 0:
		return 0

	var before_hp: int = playerHP
	playerHP = min(maxHP, before_hp + LIFESTEAL_PER_KILL)
	return max(playerHP - before_hp, 0)


func record_victory(completed_wave: int) -> void:
	wins += 1
	last_victory_wave = max(completed_wave, 0)


func mark_tutorial_step(step: StringName) -> void:
	if tutorial_progress.get(step, false):
		return
	if TUTORIAL_STEP_HINTS.has(step) == false:
		return

	tutorial_progress[step] = true
	tutorial_progress_changed.emit()


func is_tutorial_step_done(step: StringName) -> bool:
	return bool(tutorial_progress.get(step, false))


func get_tutorial_progress_data() -> Dictionary:
	var data: Dictionary = {}
	for step in TUTORIAL_STEP_ORDER:
		data[String(step)] = bool(tutorial_progress.get(step, false))
	return data


func load_tutorial_progress(progress_data: Dictionary = {}) -> void:
	tutorial_progress.clear()
	for step in TUTORIAL_STEP_ORDER:
		tutorial_progress[step] = bool(progress_data.get(String(step), false))
	tutorial_progress_changed.emit()


func load_legacy_tutorial_progress(attack_done: bool, stomp_done: bool, level_done: bool) -> void:
	load_tutorial_progress({
		"attack": attack_done,
		"stomp": stomp_done,
		"level_up": level_done,
	})


func reset_tutorial_progress() -> void:
	var empty_progress: Dictionary = {}
	for step in TUTORIAL_STEP_ORDER:
		empty_progress[String(step)] = false
	load_tutorial_progress(empty_progress)


func is_tutorial_complete() -> bool:
	for step in TUTORIAL_STEP_ORDER:
		if not bool(tutorial_progress.get(step, false)):
			return false
	return true


func get_next_tutorial_hint() -> String:
	for step in TUTORIAL_STEP_ORDER:
		if not bool(tutorial_progress.get(step, false)):
			return str(TUTORIAL_STEP_HINTS.get(step, ""))
	return ""


var tutorial_move_done: bool:
	get:
		return is_tutorial_step_done(&"move")


var tutorial_jump_done: bool:
	get:
		return is_tutorial_step_done(&"jump")


var tutorial_slash_done: bool:
	get:
		return is_tutorial_step_done(&"slash")


var tutorial_attack_done: bool:
	get:
		return is_tutorial_step_done(&"attack")


var tutorial_pickup_gold_done: bool:
	get:
		return is_tutorial_step_done(&"pickup_gold")


var tutorial_stomp_done: bool:
	get:
		return is_tutorial_step_done(&"stomp")


var tutorial_level_done: bool:
	get:
		return is_tutorial_step_done(&"level_up")


var tutorial_elite_wave_done: bool:
	get:
		return is_tutorial_step_done(&"elite_wave")


var tutorial_boss_wave_done: bool:
	get:
		return is_tutorial_step_done(&"boss_wave")
