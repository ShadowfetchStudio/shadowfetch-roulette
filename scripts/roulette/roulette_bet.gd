class_name RouletteBet
extends RefCounted

var kind: RouletteTypes.BetKind
var numbers: Array[int] = []
var amount: int = 0
var id: String = ""


func _init(p_kind: RouletteTypes.BetKind = RouletteTypes.BetKind.STRAIGHT, p_numbers: Array = [], p_amount: int = 0, p_id: String = "") -> void:
	kind = p_kind
	numbers = []
	for n in p_numbers:
		numbers.append(int(n))
	numbers.sort()
	amount = p_amount
	id = p_id if p_id != "" else canonical_id(kind, numbers)


static func canonical_id(p_kind: RouletteTypes.BetKind, p_numbers: Array) -> String:
	var copy: Array[int] = []
	for n in p_numbers:
		copy.append(int(n))
	copy.sort()
	var parts: PackedStringArray = PackedStringArray()
	for n in copy:
		parts.append(str(n))
	return "%s:%s" % [RouletteTypes.kind_name(p_kind).to_lower().replace(" ", "_"), ",".join(parts)]


func covers(pocket: int) -> bool:
	return pocket in numbers


func payout_odds() -> int:
	return RouletteTypes.payout_for(kind)


func win_return() -> int:
	## Stake plus profit when this bet wins.
	return amount + amount * payout_odds()


func profit() -> int:
	return amount * payout_odds()


func duplicate_with_amount(new_amount: int) -> RouletteBet:
	return RouletteBet.new(kind, numbers.duplicate(), new_amount, id)


func to_dict() -> Dictionary:
	return {
		"kind": int(kind),
		"kind_name": RouletteTypes.kind_name(kind),
		"numbers": numbers.duplicate(),
		"amount": amount,
		"id": id,
	}


static func from_dict(d: Dictionary) -> RouletteBet:
	var nums: Array = d.get("numbers", [])
	return RouletteBet.new(int(d.get("kind", 0)) as RouletteTypes.BetKind, nums, int(d.get("amount", 0)), str(d.get("id", "")))
