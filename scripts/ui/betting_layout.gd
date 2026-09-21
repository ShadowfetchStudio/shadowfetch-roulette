class_name BettingLayout
extends Control

signal bet_requested(kind: int, numbers: Array)

var chip_value := 5
var _engine: RouletteEngine
var _status: Label
var _chips: Array[Button] = []


func setup(engine: RouletteEngine) -> void:
	_engine = engine
	theme = ThemeFactory.make()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func set_status(text: String) -> void:
	if _status:
		_status.text = text


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	_status = Label.new()
	_status.text = "Select a chip, then click the felt."
	_status.add_theme_font_size_override("font_size", 13)
	root.add_child(_status)
	var felt := PanelContainer.new()
	felt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var felt_style := StyleBoxFlat.new()
	felt_style.bg_color = Color(0.05, 0.18, 0.13, 0.92)
	felt_style.set_corner_radius_all(10)
	felt_style.set_border_width_all(1)
	felt_style.border_color = Color(0.72, 0.58, 0.28, 0.45)
	felt.add_theme_stylebox_override("panel", felt_style)
	root.add_child(felt)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	felt.add_child(inner)
	inner.add_child(_zero_row())
	inner.add_child(_number_grid())
	inner.add_child(_dozens_row())
	inner.add_child(_even_money_row())
	inner.add_child(_chip_row())
	inner.add_child(_action_row())


func _zero_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.add_child(_spot("0", RouletteTypes.BetKind.STRAIGHT, [0], Color(0.08, 0.42, 0.24), Vector2(64, 40)))
	h.add_child(_spot("0-1", RouletteTypes.BetKind.SPLIT, [0, 1], Color(0.12, 0.16, 0.14), Vector2(56, 40)))
	h.add_child(_spot("0-2", RouletteTypes.BetKind.SPLIT, [0, 2], Color(0.12, 0.16, 0.14), Vector2(56, 40)))
	h.add_child(_spot("0-3", RouletteTypes.BetKind.SPLIT, [0, 3], Color(0.12, 0.16, 0.14), Vector2(56, 40)))
	h.add_child(_spot("0-1-2", RouletteTypes.BetKind.STREET, [0, 1, 2], Color(0.14, 0.18, 0.16), Vector2(70, 40)))
	h.add_child(_spot("0-2-3", RouletteTypes.BetKind.STREET, [0, 2, 3], Color(0.14, 0.18, 0.16), Vector2(70, 40)))
	h.add_child(_spot("0-1-2-3", RouletteTypes.BetKind.CORNER, [0, 1, 2, 3], Color(0.16, 0.14, 0.10), Vector2(86, 40)))
	return h


func _number_grid() -> HBoxContainer:
	var wrap := HBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	var grid := GridContainer.new()
	grid.columns = 12
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	# Top row 3,6,... then 2,5,... then 1,4,...
	for row in [2, 1, 0]:
		for col in range(12):
			var n := BetCatalog.layout_number(col, row)
			var colr := Color(0.62, 0.12, 0.14) if RouletteTypes.is_red(n) else Color(0.08, 0.08, 0.10)
			grid.add_child(_spot(str(n), RouletteTypes.BetKind.STRAIGHT, [n], colr, Vector2(48, 36)))
	wrap.add_child(grid)
	var cols := VBoxContainer.new()
	cols.add_theme_constant_override("separation", 2)
	for c in range(2, -1, -1):
		var nums: Array[int] = []
		for i in range(12):
			nums.append(BetCatalog.layout_number(i, c))
		cols.add_child(_spot("2:1", RouletteTypes.BetKind.COLUMN, nums, Color(0.12, 0.16, 0.14), Vector2(48, 36)))
	wrap.add_child(cols)
	return wrap


func _dozens_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	for d in range(3):
		var nums: Array[int] = []
		for n in range(d * 12 + 1, d * 12 + 13):
			nums.append(n)
		var labels := ["1st 12", "2nd 12", "3rd 12"]
		h.add_child(_spot(labels[d], RouletteTypes.BetKind.DOZEN, nums, Color(0.10, 0.16, 0.14), Vector2(188, 34)))
	return h


func _even_money_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var low: Array[int] = []
	var high: Array[int] = []
	var odd: Array[int] = []
	var even: Array[int] = []
	for n in range(1, 37):
		if n <= 18:
			low.append(n)
		else:
			high.append(n)
		if n % 2 == 1:
			odd.append(n)
		else:
			even.append(n)
	h.add_child(_spot("1–18", RouletteTypes.BetKind.LOW, low, Color(0.10, 0.14, 0.12), Vector2(92, 34)))
	h.add_child(_spot("EVEN", RouletteTypes.BetKind.EVEN, even, Color(0.10, 0.14, 0.12), Vector2(92, 34)))
	h.add_child(_spot("RED", RouletteTypes.BetKind.RED, RouletteTypes.RED_NUMBERS.duplicate(), Color(0.55, 0.12, 0.14), Vector2(92, 34)))
	h.add_child(_spot("BLACK", RouletteTypes.BetKind.BLACK, RouletteTypes.BLACK_NUMBERS.duplicate(), Color(0.08, 0.08, 0.10), Vector2(92, 34)))
	h.add_child(_spot("ODD", RouletteTypes.BetKind.ODD, odd, Color(0.10, 0.14, 0.12), Vector2(92, 34)))
	h.add_child(_spot("19–36", RouletteTypes.BetKind.HIGH, high, Color(0.10, 0.14, 0.12), Vector2(92, 34)))
	return h


func _chip_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var lab := Label.new()
	lab.text = "Chip"
	h.add_child(lab)
	for v in [1, 5, 25, 100, 500]:
		var b := Button.new()
		b.text = str(v)
		b.custom_minimum_size = Vector2(56, 32)
		b.toggle_mode = true
		b.button_pressed = v == chip_value
		var val: int = v
		b.pressed.connect(func():
			chip_value = val
			for other in _chips:
				other.button_pressed = other == b
			AudioManager.play("chip")
		)
		_chips.append(b)
		h.add_child(b)
	var more := Label.new()
	more.text = "  Inside extras"
	h.add_child(more)
	h.add_child(_spot_menu())
	return h


func _spot_menu() -> MenuButton:
	var mb := MenuButton.new()
	mb.text = "Splits / Streets / Corners / Six"
	mb.custom_minimum_size = Vector2(260, 32)
	var pop := mb.get_popup()
	var items: Array[RouletteBet] = []
	items.append_array(BetCatalog.all_splits())
	items.append_array(BetCatalog.all_streets())
	items.append_array(BetCatalog.all_corners())
	items.append_array(BetCatalog.all_six_lines())
	var i := 0
	for t in items:
		pop.add_item("%s  %s" % [RouletteTypes.kind_name(t.kind), t.id], i)
		pop.set_item_metadata(i, t)
		i += 1
	pop.id_pressed.connect(func(id: int):
		var t: RouletteBet = pop.get_item_metadata(id)
		bet_requested.emit(t.kind, t.numbers)
	)
	return mb


func _action_row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(_act("PREVIOUS", "previous"))
	h.add_child(_act("REPEAT", "repeat"))
	h.add_child(_act("CLEAR", "clear"))
	h.add_child(_act("SPIN", "spin"))
	return h


func _act(text: String, id: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 40)
	b.pressed.connect(func():
		AudioManager.play("ui")
		_engine_action(id)
	)
	return b


func _engine_action(id: String) -> void:
	if _engine == null:
		return
	match id:
		"previous":
			if not _engine.undo_last():
				set_status("Nothing to undo")
			else:
				set_status("Undid last chip")
		"repeat":
			var err := _engine.repeat_last()
			set_status(err if err != "" else "Repeated last round")
		"clear":
			_engine.clear_bets(true)
			set_status("Bets cleared")
			AudioManager.play("clear")
		"spin":
			bet_requested.emit(-1, [])


func _spot(text: String, kind: RouletteTypes.BetKind, numbers: Array, color: Color, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.85, 0.72, 0.38, 0.35)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate()
	hov.border_color = Color(0.95, 0.86, 0.45, 0.95)
	b.add_theme_stylebox_override("hover", hov)
	b.pressed.connect(func():
		bet_requested.emit(kind, numbers)
	)
	return b
