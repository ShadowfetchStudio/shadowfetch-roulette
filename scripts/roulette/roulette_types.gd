class_name RouletteTypes
extends RefCounted

## European single-zero wheel order, clockwise from 0 as seen from above.
const WHEEL_ORDER: Array[int] = [
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10,
	5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
]

const RED_NUMBERS: Array[int] = [
	1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36
]

const BLACK_NUMBERS: Array[int] = [
	2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35
]

enum BetKind {
	STRAIGHT,
	SPLIT,
	STREET,
	CORNER,
	SIX_LINE,
	RED,
	BLACK,
	ODD,
	EVEN,
	LOW,
	HIGH,
	DOZEN,
	COLUMN,
}

const PAYOUT_STRAIGHT := 35
const PAYOUT_SPLIT := 17
const PAYOUT_STREET := 11
const PAYOUT_CORNER := 8
const PAYOUT_SIX_LINE := 5
const PAYOUT_EVEN_MONEY := 1
const PAYOUT_DOZEN := 2
const PAYOUT_COLUMN := 2

const COLOR_GREEN := 0
const COLOR_RED := 1
const COLOR_BLACK := 2

const DEFAULT_BANKROLL := 10000
const DEFAULT_MIN_BET := 1
const DEFAULT_MAX_BET := 500
const DEFAULT_TABLE_MAX := 5000
const HIGH_LIMIT_MIN := 25
const HIGH_LIMIT_MAX := 2500
const HIGH_LIMIT_TABLE := 20000
const PRACTICE_BANKROLL := 25000


static func pocket_color(n: int) -> int:
	if n == 0:
		return COLOR_GREEN
	if n in RED_NUMBERS:
		return COLOR_RED
	return COLOR_BLACK


static func is_red(n: int) -> bool:
	return n != 0 and n in RED_NUMBERS


static func is_black(n: int) -> bool:
	return n != 0 and n in BLACK_NUMBERS


static func is_valid_pocket(n: int) -> bool:
	return n >= 0 and n <= 36


static func payout_for(kind: BetKind) -> int:
	match kind:
		BetKind.STRAIGHT:
			return PAYOUT_STRAIGHT
		BetKind.SPLIT:
			return PAYOUT_SPLIT
		BetKind.STREET:
			return PAYOUT_STREET
		BetKind.CORNER:
			return PAYOUT_CORNER
		BetKind.SIX_LINE:
			return PAYOUT_SIX_LINE
		BetKind.RED, BetKind.BLACK, BetKind.ODD, BetKind.EVEN, BetKind.LOW, BetKind.HIGH:
			return PAYOUT_EVEN_MONEY
		BetKind.DOZEN, BetKind.COLUMN:
			return PAYOUT_DOZEN
	return 0


static func kind_name(kind: BetKind) -> String:
	match kind:
		BetKind.STRAIGHT:
			return "Straight"
		BetKind.SPLIT:
			return "Split"
		BetKind.STREET:
			return "Street"
		BetKind.CORNER:
			return "Corner"
		BetKind.SIX_LINE:
			return "Six Line"
		BetKind.RED:
			return "Red"
		BetKind.BLACK:
			return "Black"
		BetKind.ODD:
			return "Odd"
		BetKind.EVEN:
			return "Even"
		BetKind.LOW:
			return "Low"
		BetKind.HIGH:
			return "High"
		BetKind.DOZEN:
			return "Dozen"
		BetKind.COLUMN:
			return "Column"
	return "Unknown"


static func expected_cover_count(kind: BetKind) -> int:
	match kind:
		BetKind.STRAIGHT:
			return 1
		BetKind.SPLIT:
			return 2
		BetKind.STREET:
			return 3
		BetKind.CORNER:
			return 4
		BetKind.SIX_LINE:
			return 6
		BetKind.RED, BetKind.BLACK, BetKind.ODD, BetKind.EVEN, BetKind.LOW, BetKind.HIGH:
			return 18
		BetKind.DOZEN, BetKind.COLUMN:
			return 12
	return 0


static func pocket_label(n: int) -> String:
	return str(n)


static func color_label(n: int) -> String:
	match pocket_color(n):
		COLOR_GREEN:
			return "green"
		COLOR_RED:
			return "red"
		_:
			return "black"
