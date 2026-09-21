extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_ui()
	SettingsStore.apply_display()
	SettingsStore.apply_audio()
	_handle_cli()


func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--screenshot" in args:
		await get_tree().create_timer(0.7).timeout
		_save_shot("menu.png")
	if "--self-test" in args:
		GameSession.self_test = true
		GameSession.mode = GameSession.Mode.CLASSIC
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/game.tscn")


func _save_shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	var dir := "user://screenshots"
	if not OS.has_feature("standalone"):
		dir = ProjectSettings.globalize_path("res://docs/screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(name)
	img.save_png(path)
	print("SCREENSHOT ", path)


func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.03, 0.035)
	add_child(bg)
	var vp_wrap := SubViewportContainer.new()
	vp_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_wrap.stretch = true
	vp_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp_wrap.add_child(vp)
	add_child(vp_wrap)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.045, 0.04)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42, 0.36, 0.30)
	e.ambient_light_energy = 0.58
	e.glow_enabled = true
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -20, 0)
	light.light_energy = 1.4
	light.light_color = Color(1.0, 0.92, 0.78)
	light.shadow_enabled = true
	world.add_child(light)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.9, 0.7, 0.35)
	fill.light_energy = 2.2
	fill.omni_range = 10.0
	fill.position = Vector3(1.2, 2.4, 1.6)
	world.add_child(fill)
	var wheel := WheelView.new()
	world.add_child(wheel)
	var cam := Camera3D.new()
	cam.fov = 34
	world.add_child(cam)
	var tw := create_tween().set_loops()
	tw.tween_method(func(a: float):
		if not is_instance_valid(cam):
			return
		cam.position = Vector3(sin(a) * 4.6, 2.8, cos(a) * 4.6)
		cam.look_at(Vector3(0, 0.15, 0))
	, 0.4, 0.4 + TAU, 22.0)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 540
	shade.color = Color(0.025, 0.02, 0.02, 0.84)
	add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	box.offset_left = 56
	box.offset_right = 500
	box.offset_top = 72
	box.offset_bottom = -72
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var kicker := Label.new()
	kicker.text = "EUROPEAN SINGLE-ZERO"
	kicker.add_theme_color_override("font_color", ThemeFactory.gold())
	kicker.add_theme_font_size_override("font_size", 12)
	box.add_child(kicker)
	var title := Label.new()
	title.text = "Shadowfetch"
	var df: FontFile = load("res://assets/fonts/InterDisplay-SemiBold.ttf")
	if df:
		title.add_theme_font_override("font", df)
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Roulette"
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color(0.88, 0.78, 0.48))
	box.add_child(sub)
	var blurb := Label.new()
	blurb.text = "A cinematic wheel. Honest odds. Fictional chips only."
	blurb.add_theme_color_override("font_color", ThemeFactory.muted())
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(blurb)
	box.add_child(Control.new())
	box.add_child(_menu_btn("PLAY", func(): _start(GameSession.Mode.CLASSIC)))
	box.add_child(_menu_btn("GAME MODES", func(): get_tree().change_scene_to_file("res://scenes/menus/game_modes.tscn")))
	box.add_child(_menu_btn("HOW TO PLAY", func(): get_tree().change_scene_to_file("res://scenes/menus/how_to_play.tscn")))
	box.add_child(_menu_btn("STATISTICS", func(): get_tree().change_scene_to_file("res://scenes/menus/statistics.tscn")))
	box.add_child(_menu_btn("SETTINGS", func(): get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")))
	box.add_child(_menu_btn("QUIT", func(): get_tree().quit()))
	var note := Label.new()
	note.text = "No real-money gambling. Integer credits. Linux native."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.48, 0.46, 0.40))
	note.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	box.add_child(note)


func _menu_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func _start(mode: GameSession.Mode) -> void:
	GameSession.reset_defaults()
	GameSession.mode = mode
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")
