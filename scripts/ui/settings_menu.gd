extends Control

var _res: OptionButton
var _full: CheckButton
var _vsync: CheckButton
var _quality: OptionButton
var _aa: OptionButton
var _shadows: CheckButton
var _effects: CheckButton
var _sens: HSlider
var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _ambient: HSlider
var _back_scene := "res://scenes/menus/main_menu.tscn"


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--back="):
			_back_scene = a.substr(7)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.032, 0.03)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(620, 720)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -360
	panel.offset_bottom = 360
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	_quality = _opt(["Low", "Medium", "High"], ["low", "medium", "high"], SettingsStore.graphics_quality)
	v.add_child(_row("Graphics quality", _quality))
	_res = OptionButton.new()
	for r in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		_res.add_item("%d × %d" % [r.x, r.y])
		_res.set_item_metadata(_res.item_count - 1, r)
		if r == SettingsStore.resolution:
			_res.select(_res.item_count - 1)
	v.add_child(_row("Resolution", _res))
	_full = CheckButton.new()
	_full.button_pressed = SettingsStore.fullscreen
	v.add_child(_row("Fullscreen", _full))
	_vsync = CheckButton.new()
	_vsync.button_pressed = SettingsStore.vsync
	v.add_child(_row("VSync", _vsync))
	_aa = _opt(["Off", "2×", "4×", "8×"], [0, 2, 4, 8], SettingsStore.antialiasing)
	v.add_child(_row("Anti-aliasing", _aa))
	_shadows = CheckButton.new()
	_shadows.button_pressed = SettingsStore.shadows_enabled
	v.add_child(_row("Shadows", _shadows))
	_effects = CheckButton.new()
	_effects.button_pressed = SettingsStore.effects_enabled
	v.add_child(_row("Effects", _effects))
	_sens = _slider(0.3, 2.5, SettingsStore.camera_sensitivity)
	v.add_child(_row("Camera sensitivity", _sens))
	_master = _slider(0.0, 1.0, SettingsStore.master_volume)
	v.add_child(_row("Master volume", _master))
	_music = _slider(0.0, 1.0, SettingsStore.music_volume)
	v.add_child(_row("Music volume", _music))
	_sfx = _slider(0.0, 1.0, SettingsStore.sfx_volume)
	v.add_child(_row("SFX volume", _sfx))
	_ambient = _slider(0.0, 1.0, SettingsStore.ambient_volume)
	v.add_child(_row("Ambient volume", _ambient))
	var row := HBoxContainer.new()
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_apply)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		_apply()
		get_tree().change_scene_to_file(_back_scene)
	)
	row.add_child(apply_btn)
	row.add_child(back)
	v.add_child(row)


func _row(text: String, w: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 220
	h.add_child(l)
	w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(w)
	return h


func _opt(labels: Array, values: Array, current: Variant) -> OptionButton:
	var o := OptionButton.new()
	for i in labels.size():
		o.add_item(str(labels[i]))
		o.set_item_metadata(i, values[i])
		if values[i] == current:
			o.select(i)
	return o


func _slider(a: float, b: float, val: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = a
	s.max_value = b
	s.step = 0.05
	s.value = val
	return s


func _apply() -> void:
	SettingsStore.graphics_quality = str(_quality.get_selected_metadata())
	if _res.selected >= 0:
		SettingsStore.resolution = _res.get_selected_metadata()
	SettingsStore.fullscreen = _full.button_pressed
	SettingsStore.vsync = _vsync.button_pressed
	SettingsStore.antialiasing = int(_aa.get_selected_metadata())
	SettingsStore.shadows_enabled = _shadows.button_pressed
	SettingsStore.effects_enabled = _effects.button_pressed
	SettingsStore.camera_sensitivity = _sens.value
	SettingsStore.master_volume = _master.value
	SettingsStore.music_volume = _music.value
	SettingsStore.sfx_volume = _sfx.value
	SettingsStore.ambient_volume = _ambient.value
	SettingsStore.save_settings()
	SettingsStore.apply_display()
	SettingsStore.apply_audio()
	AudioManager.play("ui")
