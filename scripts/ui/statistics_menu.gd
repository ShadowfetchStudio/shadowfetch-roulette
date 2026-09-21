extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.032, 0.03)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 80
	panel.offset_right = -80
	panel.offset_top = 48
	panel.offset_bottom = -48
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var title := Label.new()
	title.text = "Statistics"
	title.add_theme_font_size_override("font_size", 30)
	v.add_child(title)
	var s := StatsStore.load_stats()
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var pockets := ""
	var hits: Dictionary = s.get("pocket_hits", {})
	for n in range(37):
		pockets += "%s:%s  " % [n, hits.get(str(n), 0)]
		if (n + 1) % 10 == 0:
			pockets += "\n"
	body.text = """Spins: %s
Bets won / lost: %s / %s
Wagered: %s    Returned: %s    Net: %s
Biggest win: %s    Biggest loss: %s
Red / Black / Zero hits: %s / %s / %s

Pocket frequency
%s
""" % [
		s.get("spins", 0), s.get("bets_won", 0), s.get("bets_lost", 0),
		s.get("total_wagered", 0), s.get("total_returned", 0), s.get("net", 0),
		s.get("biggest_win", 0), s.get("biggest_loss", 0),
		s.get("red_hits", 0), s.get("black_hits", 0), s.get("zero_hits", 0),
		pockets
	]
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	var row := HBoxContainer.new()
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		AudioManager.play("ui")
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	row.add_child(back)
	v.add_child(row)
