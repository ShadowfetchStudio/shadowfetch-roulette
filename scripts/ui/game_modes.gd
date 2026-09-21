extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.032, 0.03)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(520, 520)
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -260
	box.offset_bottom = 260
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var t := Label.new()
	t.text = "Game Modes"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	box.add_child(t)
	box.add_child(_mode("CLASSIC", "European table. Fictional 10,000 credits.", GameSession.Mode.CLASSIC))
	box.add_child(_mode("PRACTICE", "Same rules, 25,000 credits to learn the felt.", GameSession.Mode.PRACTICE))
	box.add_child(_mode("HIGH LIMIT", "Raised minimums and a deeper bankroll.", GameSession.Mode.HIGH_LIMIT))
	box.add_child(_mode("SPEED", "Shorter spin. Identical odds and settlement.", GameSession.Mode.SPEED))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func():
		AudioManager.play("ui")
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	box.add_child(back)


func _mode(title: String, blurb: String, mode: GameSession.Mode) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" % [title, blurb]
	b.custom_minimum_size = Vector2(0, 72)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		GameSession.reset_defaults()
		GameSession.mode = mode
		get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	)
	return b
