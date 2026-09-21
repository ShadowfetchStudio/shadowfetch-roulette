class_name GameController
extends Node3D

var engine := RouletteEngine.new()
var wheel: WheelView
var table: TableView
var camera_rig: CinematicCamera
var ui: GameUI
var _spinning := false
var _stats: Dictionary = {}
var _pending_pocket := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats = StatsStore.load_stats()
	_configure()
	_build_world()
	ui = GameUI.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.setup(engine)
	add_child(ui)
	ui.pause_requested.connect(_toggle_pause)
	ui.spin_requested.connect(request_spin)
	ui.restart_requested.connect(_restart)
	ui.settings_requested.connect(_settings)
	ui.menu_requested.connect(_menu)
	ui.quit_requested.connect(func(): get_tree().quit())
	_handle_cli()


func _configure() -> void:
	var lim := GameSession.limits()
	engine.configure(GameSession.starting_bankroll(), lim.x, lim.y, lim.z)


func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.05, 0.048)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.34, 0.30)
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = SettingsStore.quality_effects()
	env.glow_intensity = 0.32
	env.ssao_enabled = SettingsStore.graphics_quality == "high"
	env.ssr_enabled = SettingsStore.quality_effects()
	env_node.environment = env
	add_child(env_node)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.93, 0.82)
	key.light_energy = 1.35
	key.shadow_enabled = SettingsStore.quality_shadows()
	key.rotation_degrees = Vector3(-48, -18, 0)
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.45, 0.55, 0.75)
	fill.light_energy = 0.28
	fill.rotation_degrees = Vector3(-18, 150, 0)
	add_child(fill)
	table = TableView.new()
	add_child(table)
	wheel = WheelView.new()
	wheel.position = Vector3(-0.15, 0.02, 0.05)
	add_child(wheel)
	camera_rig = CinematicCamera.new()
	add_child(camera_rig)
	if SettingsStore.quality_effects():
		var dust := GPUParticles3D.new()
		dust.amount = 24
		dust.lifetime = 6.0
		dust.position = Vector3(0, 1.4, 1.0)
		var mat := ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(3, 0.4, 2)
		mat.gravity = Vector3(0, -0.02, 0)
		mat.scale_min = 0.01
		mat.scale_max = 0.03
		dust.process_material = mat
		add_child(dust)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("spin") and not get_tree().paused:
		request_spin()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if _spinning:
		return
	ui.set_paused(not get_tree().paused)


func request_spin() -> void:
	if _spinning or get_tree().paused:
		return
	if engine.phase == RouletteEngine.Phase.SETTLED:
		engine.reset_round()
	var err := engine.begin_spin()
	if err != "":
		ui.layout.set_status(err)
		return
	_spinning = true
	AudioManager.play("spin")
	camera_rig.look_wheel()
	_pending_pocket = GameSession.force_pocket if RouletteTypes.is_valid_pocket(GameSession.force_pocket) else engine.draw_pocket()
	var dur := 0.4 if GameSession.self_test else GameSession.spin_duration() / SettingsStore.animation_speed
	wheel.start_spin(_pending_pocket, dur)


func _process(_delta: float) -> void:
	if _spinning and wheel._finished:
		_finish_spin()


func _finish_spin() -> void:
	_spinning = false
	var res := engine.resolve(_pending_pocket)
	if res.has("error"):
		ui.layout.set_status(str(res.get("error")))
		return
	_stats = StatsStore.record_spin(_stats, res)
	StatsStore.save_stats(_stats)
	camera_rig.look_table()
	if GameSession.self_test:
		_verify_self_test(res)


func _verify_self_test(res: Dictionary) -> void:
	var ok := int(res.get("pocket", -1)) == _pending_pocket and engine.bets.is_empty()
	print("SELFTEST pocket=%s bankroll=%s net=%s ok=%s" % [res.get("pocket"), engine.bankroll, res.get("net"), ok])
	get_tree().quit(0 if ok else 1)


func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--self-test" in args:
		GameSession.self_test = true
		await get_tree().process_frame
		engine.place(RouletteTypes.BetKind.STRAIGHT, [17], 10)
		GameSession.force_pocket = 17
		request_spin()
	if "--screenshot" in args:
		await get_tree().create_timer(0.8).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := "user://screenshots"
			if not OS.has_feature("standalone"):
				dir = ProjectSettings.globalize_path("res://docs/screenshots")
			DirAccess.make_dir_recursive_absolute(dir)
			var path := dir.path_join("table.png")
			img.save_png(path)
			print("SCREENSHOT ", path)


func _restart() -> void:
	get_tree().paused = false
	GameSession.force_pocket = -1
	get_tree().reload_current_scene()


func _settings() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")


func _menu() -> void:
	get_tree().paused = false
	GameSession.reset_defaults()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
