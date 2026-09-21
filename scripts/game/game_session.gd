extends Node

enum Mode { CLASSIC, PRACTICE, HIGH_LIMIT, SPEED }

var mode: Mode = Mode.CLASSIC
var bankroll_override: int = -1
var force_pocket: int = -1
var self_test: bool = false
var screenshot: bool = false


func reset_defaults() -> void:
	mode = Mode.CLASSIC
	bankroll_override = -1
	force_pocket = -1
	self_test = false
	screenshot = false


func mode_name() -> String:
	match mode:
		Mode.PRACTICE:
			return "Practice"
		Mode.HIGH_LIMIT:
			return "High Limit"
		Mode.SPEED:
			return "Speed"
		_:
			return "Classic"


func starting_bankroll() -> int:
	if bankroll_override > 0:
		return bankroll_override
	match mode:
		Mode.PRACTICE:
			return RouletteTypes.PRACTICE_BANKROLL
		Mode.HIGH_LIMIT:
			return 25000
		_:
			return SettingsStore.starting_bankroll


func limits() -> Vector3i:
	match mode:
		Mode.HIGH_LIMIT:
			return Vector3i(RouletteTypes.HIGH_LIMIT_MIN, RouletteTypes.HIGH_LIMIT_MAX, RouletteTypes.HIGH_LIMIT_TABLE)
		_:
			return Vector3i(RouletteTypes.DEFAULT_MIN_BET, RouletteTypes.DEFAULT_MAX_BET, RouletteTypes.DEFAULT_TABLE_MAX)


func spin_duration() -> float:
	if mode == Mode.SPEED:
		return 2.4
	return 4.2
