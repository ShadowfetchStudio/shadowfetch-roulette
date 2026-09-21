extends SceneTree

const EngineTests = preload("res://tests/test_roulette_engine.gd")
const SettingsTests = preload("res://tests/test_settings_store.gd")


func _initialize() -> void:
	print("Running Shadowfetch Roulette tests...")
	var tmp := OS.get_user_data_dir().path_join("roulette-test-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(tmp)
	OS.set_environment("SHADOWFETCH_ROULETTE_CONFIG", tmp.path_join("config"))
	OS.set_environment("SHADOWFETCH_ROULETTE_DATA", tmp.path_join("data"))
	var engine_ok: bool = EngineTests.new().run_all()
	var settings_ok: bool = SettingsTests.new().run_all()
	var ok := engine_ok and settings_ok
	_cleanup(tmp)
	if ok:
		print("ALL TESTS PASSED")
	else:
		print("TESTS FAILED")
	quit(0 if ok else 1)


func _cleanup(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	_rm(path)


func _rm(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := path.path_join(name)
		if dir.current_is_dir() and name != "." and name != "..":
			_rm(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	DirAccess.remove_absolute(path)
