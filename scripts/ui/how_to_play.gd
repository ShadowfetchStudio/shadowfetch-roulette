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
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.text = "How to Play"
	title.add_theme_font_size_override("font_size", 30)
	v.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = """Shadowfetch Roulette is European single-zero roulette with a fictional bankroll. There is no real-money gambling.

THE WHEEL
37 pockets: 0 (green) and 1–36 (red or black). The ball is animated onto a predetermined pocket after bets lock. Payouts use the published European odds.

BETTING
Choose a chip, then click a spot on the felt. Stack the same spot to add chips. Previous undoes the last chip. Repeat restores the last settled round. Clear refunds every live chip.

INSIDE BETS
• Straight — one number — 35 to 1
• Split — two adjoining numbers — 17 to 1
• Street — three numbers in a row, plus the 0-1-2 and 0-2-3 trios — 11 to 1
• Corner — four numbers, plus first-four 0-1-2-3 — 8 to 1
• Six Line — two adjacent streets — 5 to 1

OUTSIDE BETS
• Red / Black, Odd / Even, Low (1–18) / High (19–36) — 1 to 1
• Dozens and Columns — 2 to 1
Zero loses every outside bet.

LIMITS
Classic and Speed: min 1, max 500 per spot, table 5000.
High Limit: min 25, max 2500, table 20000.
Practice uses a larger fictional bankroll.

CONTROLS
LMB place  ·  Space spin  ·  Esc pause  ·  RMB orbit  ·  Wheel zoom  ·  H reset camera

MODES
Classic is the standard table. Practice is the same rules with more credits. High Limit raises stakes. Speed shortens the spin camera without changing odds.
"""
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		AudioManager.play("ui")
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	v.add_child(back)
