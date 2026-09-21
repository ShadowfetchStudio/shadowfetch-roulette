class_name StatsStore
extends RefCounted

const Paths = preload("res://scripts/save/app_paths.gd")


static func empty() -> Dictionary:
	return {
		"spins": 0,
		"bets_placed": 0,
		"bets_won": 0,
		"bets_lost": 0,
		"total_wagered": 0,
		"total_returned": 0,
		"net": 0,
		"biggest_win": 0,
		"biggest_loss": 0,
		"red_hits": 0,
		"black_hits": 0,
		"zero_hits": 0,
		"pocket_hits": _zero_pockets(),
		"kind_wagers": {},
		"kind_wins": {},
		"sessions": 0,
	}


static func _zero_pockets() -> Dictionary:
	var d: Dictionary = {}
	for n in range(37):
		d[str(n)] = 0
	return d


static func load_stats() -> Dictionary:
	var path := Paths.stats_path()
	if not FileAccess.file_exists(path):
		return empty()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return empty()
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
		return merge_defaults(json.data)
	return empty()


static func merge_defaults(d: Dictionary) -> Dictionary:
	var base := empty()
	for k in base.keys():
		if d.has(k):
			base[k] = d[k]
	if not (base["pocket_hits"] is Dictionary):
		base["pocket_hits"] = _zero_pockets()
	return base


static func save_stats(stats: Dictionary) -> void:
	Paths.ensure_dirs()
	var f := FileAccess.open(Paths.stats_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(stats, "\t"))


static func record_spin(stats: Dictionary, result: Dictionary) -> Dictionary:
	var s := merge_defaults(stats)
	s["spins"] = int(s["spins"]) + 1
	s["bets_placed"] = int(s["bets_placed"]) + int(result.get("won_bets", 0)) + int(result.get("lost_bets", 0))
	s["bets_won"] = int(s["bets_won"]) + int(result.get("won_bets", 0))
	s["bets_lost"] = int(s["bets_lost"]) + int(result.get("lost_bets", 0))
	s["total_wagered"] = int(s["total_wagered"]) + int(result.get("stakes", 0))
	s["total_returned"] = int(s["total_returned"]) + int(result.get("paid", 0))
	s["net"] = int(s["total_returned"]) - int(s["total_wagered"])
	var net := int(result.get("net", 0))
	if net > int(s["biggest_win"]):
		s["biggest_win"] = net
	if net < int(s["biggest_loss"]):
		s["biggest_loss"] = net
	var pocket := int(result.get("pocket", 0))
	var hits: Dictionary = s["pocket_hits"]
	hits[str(pocket)] = int(hits.get(str(pocket), 0)) + 1
	s["pocket_hits"] = hits
	match RouletteTypes.pocket_color(pocket):
		RouletteTypes.COLOR_GREEN:
			s["zero_hits"] = int(s["zero_hits"]) + 1
		RouletteTypes.COLOR_RED:
			s["red_hits"] = int(s["red_hits"]) + 1
		_:
			s["black_hits"] = int(s["black_hits"]) + 1
	var kinds: Dictionary = s.get("kind_wagers", {})
	var kwins: Dictionary = s.get("kind_wins", {})
	for d in result.get("details", []):
		var kn := str(d.get("kind", ""))
		kinds[kn] = int(kinds.get(kn, 0)) + 1
		if bool(d.get("hit", false)):
			kwins[kn] = int(kwins.get(kn, 0)) + 1
	s["kind_wagers"] = kinds
	s["kind_wins"] = kwins
	return s
