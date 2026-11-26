extends Control
## Title screen: New Game, How to Play, Quit. Built in code (no art yet).

const GAME_SCENE := "res://scenes/town.tscn"

const COL_BG := Color("#0e0b12")
const COL_TEXT := Color("#d8cfc4")
const COL_DIM := Color("#7a6f80")
const COL_BLOOD := Color("#b3261e")
const COL_GOLD := Color("#c9a227")
const COL_PANEL := Color("#1c1622")
const COL_BORDER := Color("#3a2f45")

const HOW_TO_PLAY := """[b]Each round[/b]
- Your 3 heroes roll their dice automatically.
- Click a die to [color=#c9a227]LOCK[/color] it, then REROLL the rest (2 rerolls per round).
- Pick a target. Read each enemy's [b]Intent[/b]: it shows what they will do and who they will hit.
- Press END TURN: your dice resolve, then the enemies act.

[b]Dice faces[/b]
ATK hit the target   FIRE hit + burn   BLOOD huge hit, costs 2 HP
SHIELD block for self   GUARD block for the whole party   HEAL heal the weakest ally
-  (blank) nothing... but gives +1 [color=#c9a227]Fate[/color]

[b]Combos[/b]   2 of the same face = +1 each.   3 of the same face = DOUBLE.

[b]Fate[/b]   Blank faces, combos and victories give Fate (max 5). Bad luck becomes power.
Spend 2 Fate for an extra reroll, or 4 Fate to TWIST a die to any face you want.

[b]The road[/b]   Roll two dice, move with one. Carve your dice after every win; elites drop weapons
(a weapon replaces die faces 5 and 6). Your pet rolls a small d4 every round.

[b]Skills[/b]   Heroes charge every round (faster with combos).
When charged, press the skill button. Every power has a price."""

var _help: Control


func _ready() -> void:
	_build()
	load("res://scripts/ui/sfx.gd").music(self)


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# A faint red glow behind the title, like a dying fire.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.55, 0.07, 0.05, 0.35))
	gradient.set_color(1, Color(0.55, 0.07, 0.05, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var glow := TextureRect.new()
	glow.texture = tex
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.size = Vector2(1100, 520)
	glow.position = Vector2(640 - 550, -10)
	add_child(glow)

	add_child(_embers())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := _label("CURSED DICE", 84, COL_BLOOD)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(title)
	box.add_child(_label("The gods' dice are broken. Every roll has a price.", 20, COL_TEXT))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	box.add_child(spacer)

	box.add_child(_menu_button("Play", _on_new_game))
	box.add_child(_menu_button("How to Play", func(): _help.show()))
	var Sfx = load("res://scripts/ui/sfx.gd")
	var sound_btn := _menu_button("Sound: " + ("OFF" if Sfx.muted else "ON"), func(): pass)
	sound_btn.pressed.connect(func():
		Sfx.set_muted(not Sfx.muted)
		sound_btn.text = "Sound: " + ("OFF" if Sfx.muted else "ON"))
	box.add_child(sound_btn)
	if OS.get_name() != "Web":
		box.add_child(_menu_button("Quit", func(): get_tree().quit()))

	var version := _label("Version 1.4", 14, COL_DIM)
	version.position = Vector2(1150, 690)
	add_child(version)

	# The heroes face the Bishop across the bottom of the screen.
	var US = load("res://scripts/ui/unit_sprite.gd")
	var x := 60
	for id in ["varek", "lys", "aldric"]:
		var sp: Control = US.create(id, 96, false)
		sp.position = Vector2(x, 600)
		add_child(sp)
		x += 90
	var boss: Control = US.create("rotting_bishop", 144, true)
	boss.position = Vector2(1080, 548)
	add_child(boss)

	_help = _build_help()
	add_child(_help)
	_help.hide()


func _on_new_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _build_help() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COL_PANEL
	style.border_color = COL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(_label("How to Play", 30, COL_GOLD))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(760, 0)
	text.add_theme_font_size_override("normal_font_size", 17)
	text.add_theme_font_size_override("bold_font_size", 17)
	text.add_theme_color_override("default_color", COL_TEXT)
	text.text = HOW_TO_PLAY
	box.add_child(text)
	var close := _menu_button("Close", func(): dim.hide())
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(close)
	return dim


## Slow rising embers for atmosphere (no textures needed).
func _embers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(640, 740)
	p.amount = 60
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 10)
	p.direction = Vector2(0, -1)
	p.spread = 15.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.45, 0.1, 0.9))
	fade.set_color(1, Color(0.6, 0.1, 0.05, 0.0))
	p.color_ramp = fade
	return p


func _menu_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = COL_PANEL
	normal.border_color = COL_BORDER
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate()
	hover.border_color = COL_BLOOD
	hover.bg_color = Color("#2a1a22")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_GOLD)
	b.pressed.connect(on_press)
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
