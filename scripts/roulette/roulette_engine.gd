class_name RouletteEngine
extends RefCounted

## Presentation-independent European roulette: bankroll, bets, one settlement per spin.

signal bankroll_changed(value: int)
signal bets_changed
signal spin_resolved(result: Dictionary)

enum Phase { BETTING, SPINNING, SETTLED }

var bankroll: int = RouletteTypes.DEFAULT_BANKROLL
var min_bet: int = RouletteTypes.DEFAULT_MIN_BET
var max_bet: int = RouletteTypes.DEFAULT_MAX_BET
var table_max: int = RouletteTypes.DEFAULT_TABLE_MAX
var phase: Phase = Phase.BETTING
var bets: Array[RouletteBet] = []
var last_bets: Array[RouletteBet] = []
var history: Array[int] = []
var last_result: Dictionary = {}
var spin_index: int = 0
var rng := RandomNumberGenerator.new()
var _settled_spin: int = -1
var _undo: Array[Dictionary] = []


func _init() -> void:
	rng.randomize()


func configure(p_bankroll: int, p_min: int, p_max: int, p_table: int) -> void:
	bankroll = p_bankroll
	min_bet = p_min
	max_bet = p_max
	table_max = p_table
	clear_bets(false)
	phase = Phase.BETTING
	last_result = {}
	_settled_spin = -1
	bankroll_changed.emit(bankroll)


func reset_round() -> void:
	if phase == Phase.SPINNING:
		return
	bets.clear()
	_undo.clear()
	phase = Phase.BETTING
	last_result = {}
	bets_changed.emit()


func table_total() -> int:
	var s := 0
	for b in bets:
		s += b.amount
	return s


func find_bet(id: String) -> RouletteBet:
	for b in bets:
		if b.id == id:
			return b
	return null


func can_place(amount: int) -> String:
	if phase != Phase.BETTING:
		return "Bets are locked"
	if amount < min_bet:
		return "Below minimum bet"
	if amount > max_bet:
		return "Above maximum bet"
	if amount > bankroll:
		return "Insufficient bankroll"
	if table_total() + amount > table_max:
		return "Table maximum reached"
	return ""


func place(kind: RouletteTypes.BetKind, numbers: Array, amount: int) -> String:
	var err := validate_numbers(kind, numbers)
	if err != "":
		return err
	err = can_place(amount)
	if err != "":
		return err
	var bet := RouletteBet.new(kind, numbers, amount)
	var existing := find_bet(bet.id)
	if existing != null:
		if existing.amount + amount > max_bet:
			return "Above maximum bet"
		existing.amount += amount
		_undo.append({"op": "add", "id": existing.id, "amount": amount})
	else:
		bets.append(bet)
		_undo.append({"op": "new", "id": bet.id, "amount": amount})
	bankroll -= amount
	bankroll_changed.emit(bankroll)
	bets_changed.emit()
	return ""


func place_template(template: RouletteBet, amount: int) -> String:
	return place(template.kind, template.numbers, amount)


func undo_last() -> bool:
	if phase != Phase.BETTING or _undo.is_empty():
		return false
	var op: Dictionary = _undo.pop_back()
	var id := str(op.get("id", ""))
	var amt := int(op.get("amount", 0))
	var b := find_bet(id)
	if b == null:
		return false
	b.amount -= amt
	if b.amount <= 0:
		bets.erase(b)
	bankroll += amt
	bankroll_changed.emit(bankroll)
	bets_changed.emit()
	return true


func clear_bets(refund: bool = true) -> void:
	if phase == Phase.SPINNING:
		return
	if refund:
		bankroll += table_total()
		bankroll_changed.emit(bankroll)
	bets.clear()
	_undo.clear()
	bets_changed.emit()


func repeat_last() -> String:
	if phase != Phase.BETTING:
		return "Bets are locked"
	if last_bets.is_empty():
		return "No previous bets"
	clear_bets(true)
	for src in last_bets:
		var err := place(src.kind, src.numbers, src.amount)
		if err != "":
			return err
	return ""


func snapshot_bets() -> Array[RouletteBet]:
	var copy: Array[RouletteBet] = []
	for b in bets:
		copy.append(b.duplicate_with_amount(b.amount))
	return copy


func begin_spin() -> String:
	if phase != Phase.BETTING:
		return "Not accepting bets"
	if bets.is_empty():
		return "Place a bet first"
	phase = Phase.SPINNING
	spin_index += 1
	return ""


func draw_pocket() -> int:
	return rng.randi_range(0, 36)


func resolve(pocket: int) -> Dictionary:
	if not RouletteTypes.is_valid_pocket(pocket):
		return {"error": "Invalid pocket"}
	if phase != Phase.SPINNING:
		return {"error": "Spin is not in progress"}
	if _settled_spin == spin_index:
		return {"error": "Already settled"}
	var paid := 0
	var lost := 0
	var won_count := 0
	var lost_count := 0
	var details: Array[Dictionary] = []
	for b in bets:
		var hit := b.covers(pocket)
		var ret := b.win_return() if hit else 0
		if hit:
			paid += ret
			won_count += 1
		else:
			lost += b.amount
			lost_count += 1
		details.append({
			"id": b.id,
			"kind": RouletteTypes.kind_name(b.kind),
			"amount": b.amount,
			"hit": hit,
			"returned": ret,
			"profit": (ret - b.amount) if hit else -b.amount,
		})
	bankroll += paid
	_settled_spin = spin_index
	last_bets = snapshot_bets()
	history.append(pocket)
	if history.size() > 64:
		history = history.slice(history.size() - 64)
	var stakes := 0
	for b in bets:
		stakes += b.amount
	var net := paid - stakes
	last_result = {
		"pocket": pocket,
		"color": RouletteTypes.color_label(pocket),
		"paid": paid,
		"lost": lost,
		"stakes": stakes,
		"net": net,
		"won_bets": won_count,
		"lost_bets": lost_count,
		"bankroll": bankroll,
		"spin": spin_index,
		"details": details,
	}
	bets.clear()
	_undo.clear()
	phase = Phase.BETTING
	bankroll_changed.emit(bankroll)
	bets_changed.emit()
	spin_resolved.emit(last_result)
	return last_result


func spin_and_resolve(forced_pocket: int = -1) -> Dictionary:
	var err := begin_spin()
	if err != "":
		return {"error": err}
	var pocket := forced_pocket if RouletteTypes.is_valid_pocket(forced_pocket) else draw_pocket()
	return resolve(pocket)


static func validate_numbers(kind: RouletteTypes.BetKind, numbers: Array) -> String:
	if numbers.is_empty():
		return "Bet covers no numbers"
	var uniq: Dictionary = {}
	for n in numbers:
		var v := int(n)
		if not RouletteTypes.is_valid_pocket(v):
			return "Invalid pocket"
		uniq[v] = true
	if uniq.size() != numbers.size():
		return "Duplicate pockets in bet"
	var expected := RouletteTypes.expected_cover_count(kind)
	if uniq.size() != expected:
		return "Wrong coverage for %s" % RouletteTypes.kind_name(kind)
	match kind:
		RouletteTypes.BetKind.RED:
			for n in uniq.keys():
				if not RouletteTypes.is_red(int(n)):
					return "Red bet must cover only red"
		RouletteTypes.BetKind.BLACK:
			for n in uniq.keys():
				if not RouletteTypes.is_black(int(n)):
					return "Black bet must cover only black"
		RouletteTypes.BetKind.ODD:
			for n in uniq.keys():
				if int(n) == 0 or int(n) % 2 == 0:
					return "Odd bet invalid"
		RouletteTypes.BetKind.EVEN:
			for n in uniq.keys():
				if int(n) == 0 or int(n) % 2 == 1:
					return "Even bet invalid"
		RouletteTypes.BetKind.LOW:
			for n in uniq.keys():
				if int(n) < 1 or int(n) > 18:
					return "Low bet invalid"
		RouletteTypes.BetKind.HIGH:
			for n in uniq.keys():
				if int(n) < 19 or int(n) > 36:
					return "High bet invalid"
		RouletteTypes.BetKind.DOZEN:
			var vals: Array = uniq.keys()
			vals.sort()
			if int(vals[0]) not in [1, 13, 25] or int(vals[vals.size() - 1]) != int(vals[0]) + 11:
				return "Dozen bet invalid"
		RouletteTypes.BetKind.COLUMN:
			var base := -1
			for n in uniq.keys():
				var v := int(n)
				if v < 1:
					return "Column cannot include 0"
				var row := (v - 1) % 3
				if base < 0:
					base = row
				elif row != base:
					return "Column bet invalid"
		RouletteTypes.BetKind.STRAIGHT:
			pass
		RouletteTypes.BetKind.SPLIT, RouletteTypes.BetKind.STREET, RouletteTypes.BetKind.CORNER, RouletteTypes.BetKind.SIX_LINE:
			var probe := RouletteBet.new(kind, uniq.keys(), 0)
			if not BetCatalog.is_legal_id(probe.id):
				return "Inside bet is not a legal layout combination"
	return ""


static func independent_return(kind: RouletteTypes.BetKind, numbers: Array, amount: int, pocket: int) -> int:
	if pocket in numbers:
		return amount + amount * RouletteTypes.payout_for(kind)
	return 0
