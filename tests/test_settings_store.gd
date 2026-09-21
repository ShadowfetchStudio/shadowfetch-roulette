class_name TestSettingsStore
extends RefCounted

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	_failures.clear()
	var tmp := OS.get_environment("SHADOWFETCH_ROULETTE_CONFIG")
	_ok(not tmp.is_empty(), "test config override is set")
	var created := false
	var store: Node = Engine.get_main_loop().root.get_node_or_null("SettingsStore")
	if store == null:
		store = load("res://scripts/save/settings_store.gd").new()
		Engine.get_main_loop().root.add_child(store)
		created = true
	store.reset_to_defaults()
	store.master_volume = 0.42
	store.fullscreen = true
	store.antialiasing = 4
	store.save_settings()
	store.reset_to_defaults()
	_ok(is_equal_approx(store.master_volume, 0.85), "defaults after reset")
	store.load_settings()
	_ok(is_equal_approx(store.master_volume, 0.42), "persisted master volume")
	_ok(store.fullscreen, "persisted fullscreen")
	_ok(store.antialiasing == 4, "persisted AA")

	var f := FileAccess.open(store.settings_path(), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	store.load_settings()
	_ok(is_equal_approx(store.master_volume, 0.85), "corrupt JSON recovers defaults")
	_ok(store.fullscreen == false, "corrupt fullscreen default")

	f = FileAccess.open(store.settings_path(), FileAccess.WRITE)
	f.store_string("{\"graphics_quality\":\"nuclear\",\"antialiasing\":99,\"master_volume\":4.0}")
	f.close()
	store.load_settings()
	_ok(store.graphics_quality == "high", "invalid quality clamped")
	_ok(store.antialiasing == 2, "invalid AA clamped")
	_ok(store.master_volume <= 1.0, "volume clamped")

	var stats := StatsStore.empty()
	var fake := {
		"pocket": 7,
		"paid": 360,
		"stakes": 10,
		"net": 350,
		"won_bets": 1,
		"lost_bets": 0,
		"details": [{"kind": "Straight", "hit": true}],
	}
	stats = StatsStore.record_spin(stats, fake)
	_ok(int(stats["spins"]) == 1, "stats spin")
	_ok(int(stats["net"]) == 350, "stats net")
	_ok(int(stats["pocket_hits"]["7"]) == 1, "pocket histogram")
	StatsStore.save_stats(stats)
	var loaded := StatsStore.load_stats()
	_ok(int(loaded["spins"]) == 1, "stats persist")

	var garbage := FileAccess.open(store.stats_path(), FileAccess.WRITE)
	garbage.store_string("[]")
	garbage.close()
	var recovered := StatsStore.load_stats()
	_ok(int(recovered["spins"]) == 0, "corrupt stats recover")

	if created and is_instance_valid(store):
		store.queue_free()
	print("Settings/stats checks: %d  failures: %d" % [_checks, _failures.size()])
	for msg in _failures:
		print("FAIL: ", msg)
	return _failures.is_empty()


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
