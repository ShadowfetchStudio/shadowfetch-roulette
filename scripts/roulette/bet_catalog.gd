class_name BetCatalog
extends RefCounted

## Every legal European inside/outside bet, generated once from the layout.


static func layout_number(col: int, row: int) -> int:
	## col 0..11 left-to-right, row 0..2 bottom-to-top: 1,2,3 then 4,5,6...
	return col * 3 + row + 1


static func all_straights() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	for n in range(0, 37):
		out.append(RouletteBet.new(RouletteTypes.BetKind.STRAIGHT, [n], 0))
	return out


static func all_splits() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	var seen: Dictionary = {}
	# Vertical neighbors on a street (1-2, 2-3, 4-5, ...)
	for col in range(12):
		for row in range(2):
			_add_unique(out, seen, RouletteTypes.BetKind.SPLIT, [layout_number(col, row), layout_number(col, row + 1)])
	# Horizontal neighbors
	for row in range(3):
		for col in range(11):
			_add_unique(out, seen, RouletteTypes.BetKind.SPLIT, [layout_number(col, row), layout_number(col + 1, row)])
	# Zero splits
	for n in [1, 2, 3]:
		_add_unique(out, seen, RouletteTypes.BetKind.SPLIT, [0, n])
	return out


static func all_streets() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	for col in range(12):
		out.append(RouletteBet.new(RouletteTypes.BetKind.STREET, [
			layout_number(col, 0), layout_number(col, 1), layout_number(col, 2)
		], 0))
	# Zero trio streets used on European tables
	out.append(RouletteBet.new(RouletteTypes.BetKind.STREET, [0, 1, 2], 0))
	out.append(RouletteBet.new(RouletteTypes.BetKind.STREET, [0, 2, 3], 0))
	return out


static func all_corners() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	for col in range(11):
		for row in range(2):
			out.append(RouletteBet.new(RouletteTypes.BetKind.CORNER, [
				layout_number(col, row), layout_number(col, row + 1),
				layout_number(col + 1, row), layout_number(col + 1, row + 1)
			], 0))
	# First-four (0,1,2,3) — pays as a corner
	out.append(RouletteBet.new(RouletteTypes.BetKind.CORNER, [0, 1, 2, 3], 0))
	return out


static func all_six_lines() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	for col in range(11):
		var nums: Array[int] = []
		for row in range(3):
			nums.append(layout_number(col, row))
			nums.append(layout_number(col + 1, row))
		out.append(RouletteBet.new(RouletteTypes.BetKind.SIX_LINE, nums, 0))
	return out


static func all_outside() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	out.append(RouletteBet.new(RouletteTypes.BetKind.RED, RouletteTypes.RED_NUMBERS.duplicate(), 0))
	out.append(RouletteBet.new(RouletteTypes.BetKind.BLACK, RouletteTypes.BLACK_NUMBERS.duplicate(), 0))
	var odds: Array[int] = []
	var evens: Array[int] = []
	var low: Array[int] = []
	var high: Array[int] = []
	for n in range(1, 37):
		if n % 2 == 1:
			odds.append(n)
		else:
			evens.append(n)
		if n <= 18:
			low.append(n)
		else:
			high.append(n)
	out.append(RouletteBet.new(RouletteTypes.BetKind.ODD, odds, 0))
	out.append(RouletteBet.new(RouletteTypes.BetKind.EVEN, evens, 0))
	out.append(RouletteBet.new(RouletteTypes.BetKind.LOW, low, 0))
	out.append(RouletteBet.new(RouletteTypes.BetKind.HIGH, high, 0))
	for d in range(3):
		var dozen: Array[int] = []
		for n in range(d * 12 + 1, d * 12 + 13):
			dozen.append(n)
		out.append(RouletteBet.new(RouletteTypes.BetKind.DOZEN, dozen, 0))
	for c in range(3):
		var col: Array[int] = []
		for i in range(12):
			col.append(layout_number(i, c))
		out.append(RouletteBet.new(RouletteTypes.BetKind.COLUMN, col, 0))
	return out


static func all_templates() -> Array[RouletteBet]:
	var out: Array[RouletteBet] = []
	out.append_array(all_straights())
	out.append_array(all_splits())
	out.append_array(all_streets())
	out.append_array(all_corners())
	out.append_array(all_six_lines())
	out.append_array(all_outside())
	return out


static var _id_cache: Dictionary = {}
static var _legal_ids: Dictionary = {}


static func by_id() -> Dictionary:
	if not _id_cache.is_empty():
		return _id_cache
	var d: Dictionary = {}
	for b in all_templates():
		d[b.id] = b
		_legal_ids[b.id] = true
	_id_cache = d
	return d


static func is_legal_id(id: String) -> bool:
	if _legal_ids.is_empty():
		by_id()
	return _legal_ids.has(id)


static func _add_unique(out: Array[RouletteBet], seen: Dictionary, kind: RouletteTypes.BetKind, nums: Array) -> void:
	var b := RouletteBet.new(kind, nums, 0)
	if seen.has(b.id):
		return
	seen[b.id] = true
	out.append(b)
