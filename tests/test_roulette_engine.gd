class_name TestRouletteEngine
extends RefCounted

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	_failures.clear()
	_checks = 0
	_test_wheel_integrity()
	_test_colors()
	_test_catalog_counts_and_uniqueness()
	_test_every_template_coverage()
	_test_every_bet_type_payout_matrix()
	_test_zero_loses_outside()
	_test_bankroll_accounting()
	_test_min_max_boundaries()
	_test_no_duplicate_settlement()
	_test_repeat_clear_undo()
	_test_invalid_bets_rejected()
	_test_randomized_resolutions(120000)
	var ok := _failures.is_empty()
	print("Roulette engine checks: %d  failures: %d" % [_checks, _failures.size()])
	for f in _failures:
		print("FAIL: ", f)
	return ok


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _test_wheel_integrity() -> void:
	_ok(RouletteTypes.WHEEL_ORDER.size() == 37, "Wheel must have 37 pockets")
	var seen: Dictionary = {}
	for n in RouletteTypes.WHEEL_ORDER:
		seen[n] = true
		_ok(RouletteTypes.is_valid_pocket(n), "Wheel pocket %s invalid" % n)
	_ok(seen.size() == 37, "Wheel must contain each pocket once")
	for n in range(37):
		_ok(seen.has(n), "Missing pocket %d on wheel" % n)
	_ok(RouletteTypes.RED_NUMBERS.size() == 18, "18 red")
	_ok(RouletteTypes.BLACK_NUMBERS.size() == 18, "18 black")


func _test_colors() -> void:
	_ok(RouletteTypes.pocket_color(0) == RouletteTypes.COLOR_GREEN, "0 is green")
	for n in RouletteTypes.RED_NUMBERS:
		_ok(RouletteTypes.is_red(n) and not RouletteTypes.is_black(n), "red %d" % n)
	for n in RouletteTypes.BLACK_NUMBERS:
		_ok(RouletteTypes.is_black(n) and not RouletteTypes.is_red(n), "black %d" % n)
	_ok(not RouletteTypes.is_red(0) and not RouletteTypes.is_black(0), "0 is neither red nor black")


func _test_catalog_counts_and_uniqueness() -> void:
	var ids: Dictionary = {}
	var templates := BetCatalog.all_templates()
	_ok(BetCatalog.all_straights().size() == 37, "37 straights")
	_ok(BetCatalog.all_splits().size() == 60, "60 splits (57 layout + 3 zero)")
	_ok(BetCatalog.all_streets().size() == 14, "12 streets + 2 zero trios")
	_ok(BetCatalog.all_corners().size() == 23, "22 corners + first four")
	_ok(BetCatalog.all_six_lines().size() == 11, "11 six-lines")
	_ok(BetCatalog.all_outside().size() == 12, "6 even-money + 3 dozens + 3 columns")
	for t in templates:
		_ok(not ids.has(t.id), "Duplicate template id %s" % t.id)
		ids[t.id] = true
		_ok(t.numbers.size() == RouletteTypes.expected_cover_count(t.kind), "Coverage %s" % t.id)
		_ok(RouletteEngine.validate_numbers(t.kind, t.numbers) == "", "Template invalid %s" % t.id)


func _test_every_template_coverage() -> void:
	for t in BetCatalog.all_templates():
		for n in t.numbers:
			_ok(t.covers(n), "%s should cover %d" % [t.id, n])
		for p in range(37):
			if p not in t.numbers:
				_ok(not t.covers(p), "%s should not cover %d" % [t.id, p])


func _test_every_bet_type_payout_matrix() -> void:
	var stake := 10
	for t in BetCatalog.all_templates():
		for pocket in range(37):
			var expected := RouletteEngine.independent_return(t.kind, t.numbers, stake, pocket)
			var e := RouletteEngine.new()
			e.configure(100000, 1, 10000, 100000)
			var err := e.place(t.kind, t.numbers, stake)
			_ok(err == "", "place %s: %s" % [t.id, err])
			var res := e.spin_and_resolve(pocket)
			_ok(not res.has("error"), "resolve %s @ %d: %s" % [t.id, pocket, res.get("error", "")])
			_ok(int(res.get("paid", -1)) == expected, "paid %s @ %d got %s want %s" % [t.id, pocket, res.get("paid"), expected])
			var want_bank := 100000 - stake + expected
			_ok(e.bankroll == want_bank, "bank %s @ %d got %d want %d" % [t.id, pocket, e.bankroll, want_bank])
			_ok(int(res.get("net", 0)) == expected - stake, "net %s @ %d" % [t.id, pocket])
			_ok(e.phase == RouletteEngine.Phase.BETTING, "betting after settlement %s" % t.id)
			_ok(e.bets.is_empty(), "bets cleared after settlement %s" % t.id)
			_ok(not e.last_result.is_empty(), "result stored %s" % t.id)


func _test_zero_loses_outside() -> void:
	var outs := BetCatalog.all_outside()
	for t in outs:
		var e := RouletteEngine.new()
		e.configure(1000, 1, 500, 5000)
		e.place(t.kind, t.numbers, 50)
		var res := e.spin_and_resolve(0)
		_ok(int(res.get("paid", 1)) == 0, "0 must lose %s" % t.id)
		_ok(e.bankroll == 950, "0 lose bankroll %s" % t.id)


func _test_bankroll_accounting() -> void:
	var e := RouletteEngine.new()
	e.configure(1000, 1, 200, 800)
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [17], 25) == "", "place 17")
	_ok(e.bankroll == 975, "deducted")
	_ok(e.table_total() == 25, "table")
	e.clear_bets(true)
	_ok(e.bankroll == 1000 and e.bets.is_empty(), "clear refunds")
	e.place(RouletteTypes.BetKind.RED, RouletteTypes.RED_NUMBERS, 40)
	e.place(RouletteTypes.BetKind.STRAIGHT, [7], 10)
	var before := e.bankroll
	var stakes := e.table_total()
	var res := e.spin_and_resolve(7)
	_ok(before == 1000 - stakes, "stakes left bankroll")
	_ok(e.bankroll == before + int(res.get("paid", 0)), "paid returned to bankroll")
	_ok(e.bankroll == 1000 + int(res.get("net", 0)), "net identity")


func _test_min_max_boundaries() -> void:
	var e := RouletteEngine.new()
	e.configure(100, 5, 20, 40)
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [1], 4) != "", "below min rejected")
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [1], 21) != "", "above max rejected")
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [1], 20) == "", "max ok")
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [2], 20) == "", "second at table max")
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [3], 5) != "", "table max rejected")
	e.clear_bets(true)
	e.configure(10, 1, 50, 100)
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [1], 11) != "", "over bankroll rejected")
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [1], 10) == "", "all-in ok")
	_ok(e.bankroll == 0, "all-in empties bankroll")
	_ok(e.begin_spin() == "", "can spin all-in")
	var res := e.resolve(1)
	_ok(int(res.get("paid", 0)) == 10 + 10 * 35, "all-in straight win")
	_ok(e.spin_and_resolve(2).has("error"), "empty table cannot spin")


func _test_no_duplicate_settlement() -> void:
	var e := RouletteEngine.new()
	e.configure(500, 1, 100, 500)
	e.place(RouletteTypes.BetKind.STRAIGHT, [0], 10)
	e.begin_spin()
	var first := e.resolve(0)
	var second := e.resolve(0)
	_ok(not first.has("error"), "first settle ok")
	_ok(second.has("error"), "second settle blocked")
	_ok(e.bankroll == 500 - 10 + 10 * 36, "bankroll settled once")


func _test_repeat_clear_undo() -> void:
	var e := RouletteEngine.new()
	e.configure(1000, 1, 100, 500)
	e.place(RouletteTypes.BetKind.STRAIGHT, [5], 10)
	e.place(RouletteTypes.BetKind.STRAIGHT, [5], 5)
	_ok(e.find_bet("straight:5").amount == 15, "stack same straight")
	e.undo_last()
	_ok(e.find_bet("straight:5").amount == 10, "undo last chip")
	_ok(e.bankroll == 990, "undo refund")
	e.spin_and_resolve(12)
	_ok(e.repeat_last() == "", "repeat last")
	_ok(e.table_total() == 10, "repeat amount")
	e.clear_bets(true)
	_ok(e.bets.is_empty() and e.bankroll == 990, "clear after loss")


func _test_invalid_bets_rejected() -> void:
	var e := RouletteEngine.new()
	e.configure(1000, 1, 100, 500)
	_ok(e.place(RouletteTypes.BetKind.SPLIT, [1, 36], 5) != "", "illegal split")
	_ok(e.place(RouletteTypes.BetKind.STREET, [1, 2, 4], 5) != "", "illegal street")
	_ok(e.place(RouletteTypes.BetKind.CORNER, [1, 2, 3, 4], 5) != "", "illegal corner 1-4")
	_ok(e.place(RouletteTypes.BetKind.RED, [1, 2], 5) != "", "red wrong count")
	_ok(e.place(RouletteTypes.BetKind.STRAIGHT, [99], 5) != "", "invalid pocket")
	_ok(e.bets.is_empty(), "no invalid bets stored")


func _test_randomized_resolutions(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260920
	var templates := BetCatalog.all_templates()
	var kinds_seen: Dictionary = {}
	var pockets_seen: Dictionary = {}
	var e := RouletteEngine.new()
	for i in count:
		e.configure(1_000_000, 1, 5000, 20000)
		var n_bets := rng.randi_range(1, 6)
		var expected_paid := 0
		var stakes := 0
		var placed: Array[Dictionary] = []
		for _j in n_bets:
			var t: RouletteBet = templates[rng.randi_range(0, templates.size() - 1)]
			var amt := rng.randi_range(1, 40)
			if e.place(t.kind, t.numbers, amt) != "":
				continue
			stakes += amt
			placed.append({"kind": t.kind, "numbers": t.numbers.duplicate(), "amount": amt})
			kinds_seen[t.kind] = true
		if placed.is_empty():
			continue
		var pocket := rng.randi_range(0, 36)
		pockets_seen[pocket] = true
		for p in placed:
			expected_paid += RouletteEngine.independent_return(p["kind"], p["numbers"], p["amount"], pocket)
		var res := e.spin_and_resolve(pocket)
		_ok(not res.has("error"), "rand resolve error %s" % res.get("error", ""))
		_ok(int(res.get("paid", -1)) == expected_paid, "rand paid spin %d got %s want %d" % [i, res.get("paid"), expected_paid])
		_ok(e.bankroll == 1_000_000 - stakes + expected_paid, "rand bankroll spin %d" % i)
		_ok(int(res.get("stakes", -1)) == stakes, "rand stakes spin %d" % i)
		var unique := {}
		for p in placed:
			unique[RouletteBet.canonical_id(p["kind"], p["numbers"])] = true
		_ok(int(res.get("won_bets", 0)) + int(res.get("lost_bets", 0)) == unique.size(), "rand settle count %d" % i)
		_ok(e.bets.is_empty(), "rand bets remain %d" % i)
		# Second resolve must fail
		e.phase = RouletteEngine.Phase.SPINNING
		var again := e.resolve(pocket)
		_ok(again.has("error"), "rand double settle %d" % i)
	_ok(kinds_seen.size() == 13, "random suite hit every bet kind (%d)" % kinds_seen.size())
	_ok(pockets_seen.size() == 37, "random suite hit every pocket (%d)" % pockets_seen.size())
	print("Randomized resolutions executed: %d" % count)
