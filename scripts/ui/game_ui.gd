class_name GameUI
extends CanvasLayer

signal pause_requested
signal spin_requested
signal restart_requested
signal settings_requested
signal menu_requested
signal quit_requested

var engine: RouletteEngine
var layout: BettingLayout
var _bank: Label
var _mode: Label
var _history: Label
var _result: Label
var _pause: PanelContainer
var _paused := false


func setup(p_engine: RouletteEngine) -> void:
	engine = p_engine
	layer = 10
	_build()
	engine.bankroll_changed.connect(_on_bank)
	engine.bets_changed.connect(_refresh)
	engine.spin_resolved.connect(_on_result)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ThemeFactory.make()
	add_child(root)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	top.offset_bottom = 64
	root.add_child(top)
	_mode = Label.new()
	_mode.text = GameSession.mode_name()
	_mode.add_theme_color_override("font_color", ThemeFactory.gold())
	top.add_child(_mode)
	_bank = Label.new()
	_bank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bank.add_theme_font_size_override("font_size", 22)
	top.add_child(_bank)
	var pause_btn := Button.new()
	pause_btn.text = "PAUSE"
	pause_btn.pressed.connect(func(): pause_requested.emit())
	top.add_child(pause_btn)
	_history = Label.new()
	_history.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_history.offset_left = 24
	_history.offset_right = -24
	_history.offset_top = 64
	_history.offset_bottom = 96
	_history.add_theme_font_size_override("font_size", 14)
	root.add_child(_history)
	_result = Label.new()
	_result.set_anchors_preset(Control.PRESET_CENTER)
	_result.offset_left = -280
	_result.offset_right = 280
	_result.offset_top = -80
	_result.offset_bottom = -20
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.add_theme_font_size_override("font_size", 26)
	root.add_child(_result)
	layout = BettingLayout.new()
	layout.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	layout.offset_left = 20
	layout.offset_right = -20
	layout.offset_top = -340
	layout.offset_bottom = -16
	layout.setup(engine)
	layout.bet_requested.connect(_on_bet)
	root.add_child(layout)
	_pause = PanelContainer.new()
	_pause.visible = false
	_pause.set_anchors_preset(Control.PRESET_CENTER)
	_pause.custom_minimum_size = Vector2(360, 360)
	_pause.offset_left = -180
	_pause.offset_right = 180
	_pause.offset_top = -180
	_pause.offset_bottom = 180
	root.add_child(_pause)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	_pause.add_child(pv)
	var pt := Label.new()
	pt.text = "Paused"
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pt.add_theme_font_size_override("font_size", 26)
	pv.add_child(pt)
	pv.add_child(_pbtn("RESUME", func(): set_paused(false)))
	pv.add_child(_pbtn("RESTART", func(): restart_requested.emit()))
	pv.add_child(_pbtn("SETTINGS", func(): settings_requested.emit()))
	pv.add_child(_pbtn("MAIN MENU", func(): menu_requested.emit()))
	pv.add_child(_pbtn("QUIT", func(): quit_requested.emit()))


func _pbtn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 42
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func set_paused(v: bool) -> void:
	_paused = v
	_pause.visible = v
	get_tree().paused = v
	if v:
		_pause.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _on_bet(kind: int, numbers: Array) -> void:
	if kind < 0:
		spin_requested.emit()
		return
	var err := engine.place(kind as RouletteTypes.BetKind, numbers, layout.chip_value)
	if err != "":
		layout.set_status(err)
		return
	AudioManager.play("chip")
	layout.set_status("On table: %d" % engine.table_total())


func _on_bank(_v: int) -> void:
	_refresh()


func _on_result(res: Dictionary) -> void:
	var pocket := int(res.get("pocket", 0))
	var net := int(res.get("net", 0))
	var sign := "+" if net >= 0 else ""
	_result.text = "%s  %s    %s%d" % [pocket, str(res.get("color", "")).to_upper(), sign, net]
	if pocket == 0:
		AudioManager.play("zero")
	elif net >= 0:
		AudioManager.play("win")
	else:
		AudioManager.play("lose")
	_refresh()


func _refresh() -> void:
	if _bank:
		_bank.text = "Credits  %s" % _comma(engine.bankroll)
	if _history:
		var parts: PackedStringArray = PackedStringArray()
		var hist := engine.history.duplicate()
		hist.reverse()
		for n in hist:
			parts.append("%d" % int(n))
			if parts.size() >= 16:
				break
		_history.text = "Previous  " + "   ".join(parts)
	if layout and engine.phase == RouletteEngine.Phase.BETTING and engine.bets.is_empty():
		layout.set_status("Select a chip, then click the felt.")


func _comma(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
