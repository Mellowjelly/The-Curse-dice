extends Control
## Combat screen for the prototype. Builds its UI in code (no art yet).
## All game rules live in scripts/core/combat.gd - this file only displays and forwards clicks.

const Combat = preload("res://scripts/core/combat.gd")
const GameData = preload("res://scripts/core/game_data.gd")

const TITLE_SCENE := "res://scenes/title.tscn"
const HEAL_BETWEEN_FIGHTS := 5
const REVIVE_HP := 5

# Dark fantasy palette (placeholder until pixel art arrives).
const COL_BG := Color("#0e0b12")
const COL_PANEL := Color("#1c1622")
const COL_BORDER := Color("#3a2f45")
const COL_TARGET := Color("#b3261e")
const COL_TEXT := Color("#d8cfc4")
const COL_DIM := Color("#7a6f80")
const COL_HP := Color("#8e1c1c")
const COL_GOLD := Color("#c9a227")

const FACE_COLORS := {
	"attack": Color("#9b2c2c"),
	"fire": Color("#c2571a"),
	"blood": Color("#5e0b1a"),
	"shield": Color("#3b5876"),
	"guard": Color("#2f6b6b"),
	"heal": Color("#3f6e3a"),
	"sweep": Color("#6b2d6b"),
	"blank": Color("#2a2530"),
}
const FACE_NAMES := {
	"attack": "ATK", "fire": "FIRE", "blood": "BLOOD", "shield": "SHIELD",
	"guard": "GUARD", "heal": "HEAL", "sweep": "SWEEP", "blank": "-",
}

var combat: Combat
var hero_units: Array = []
var encounters: Array = []
var monster_defs: Dictionary = {}
var encounter_index := 0

var _title: Label
var _fate: Label
var _combo: Label
var _monster_row: HBoxContainer
var _hero_row: HBoxContainer
var _log: RichTextLabel
var _reroll_btn: Button
var _fate_btn: Button
var _end_btn: Button
var _overlay: Control
var _overlay_text: Label
var _overlay_btn: Button
var _overlay_action: Callable


func _ready() -> void:
	encounters = GameData.load_encounters()
	monster_defs = GameData.load_monsters()
	_build_ui()
	_new_run()


# ---------------------------------------------------------------- game flow

func _new_run() -> void:
	hero_units = []
	for def in GameData.load_heroes():
		hero_units.append(Combat.make_unit(def))
	combat = Combat.new()
	combat.log_added.connect(_on_log)
	combat.state_changed.connect(_refresh)
	combat.battle_ended.connect(_on_battle_ended)
	encounter_index = 0
	_log.clear()
	_start_encounter()


func _start_encounter() -> void:
	_overlay.hide()
	var enc: Dictionary = encounters[encounter_index]
	var defs: Array = []
	for id in enc["monsters"]:
		defs.append(monster_defs[id])
	_on_log("[b]== %s ==[/b]" % enc["name"])
	combat.start_battle(hero_units, defs)


func _on_battle_ended(victory: bool) -> void:
	if not victory:
		_show_overlay("Your party has fallen.\nThe dice show no mercy.", "Try again", _new_run)
	elif encounter_index + 1 < encounters.size():
		_show_overlay("Victory!\nHeroes rest (+%d HP). Fallen heroes rise again." % HEAL_BETWEEN_FIGHTS,
			"Continue", _next_encounter)
	else:
		_show_overlay("The Rotting Bishop is no more.\nDemo complete - thanks for playing!",
			"Play again", _new_run)


func _go_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func _next_encounter() -> void:
	for h in hero_units:
		if Combat.is_alive(h):
			h["hp"] = min(h["max_hp"], h["hp"] + HEAL_BETWEEN_FIGHTS)
		else:
			h["hp"] = REVIVE_HP
	encounter_index += 1
	_start_encounter()


# ---------------------------------------------------------------- UI building

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	# Left: the battlefield.
	var field := VBoxContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 12)
	root.add_child(field)

	var top := HBoxContainer.new()
	field.add_child(top)
	_title = _label("", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	_fate = _label("", 18, COL_GOLD)
	top.add_child(_fate)
	var menu := _button("Menu", _go_to_title)
	menu.custom_minimum_size = Vector2(80, 0)
	top.add_child(menu)

	field.add_child(_label("ENEMIES  (click one to target)", 13, COL_DIM))
	_monster_row = HBoxContainer.new()
	_monster_row.add_theme_constant_override("separation", 12)
	_monster_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_child(_monster_row)

	_combo = _label("", 16, Color("#e0b04a"))
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_child(_combo)

	field.add_child(_label("YOUR PARTY  (click a die to lock / unlock it)", 13, COL_DIM))
	_hero_row = HBoxContainer.new()
	_hero_row.add_theme_constant_override("separation", 12)
	_hero_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_child(_hero_row)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	field.add_child(buttons)
	_reroll_btn = _button("", func(): combat.reroll())
	_fate_btn = _button("", func(): combat.fate_reroll())
	_end_btn = _button("END TURN", func(): combat.end_turn())
	for b in [_reroll_btn, _fate_btn, _end_btn]:
		b.custom_minimum_size = Vector2(200, 48)
		buttons.add_child(b)

	# Right: battle log.
	var log_panel := _panel(COL_BORDER)
	log_panel.custom_minimum_size = Vector2(330, 0)
	root.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log.add_theme_color_override("default_color", COL_TEXT)
	log_panel.add_child(_log)

	# Overlay for victory / defeat.
	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0, 0, 0, 0.8)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	_overlay_text = _label("", 28)
	_overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_overlay_text)
	_overlay_btn = _button("", func(): _overlay_action.call())
	_overlay_btn.custom_minimum_size = Vector2(220, 52)
	box.add_child(_overlay_btn)
	var to_menu := _button("Main Menu", _go_to_title)
	to_menu.custom_minimum_size = Vector2(220, 40)
	box.add_child(to_menu)
	_overlay.hide()


func _show_overlay(text: String, button_text: String, action: Callable) -> void:
	_overlay_text.text = text
	_overlay_btn.text = button_text
	_overlay_action = action
	_overlay.show()


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	var enc: Dictionary = encounters[encounter_index]
	_title.text = "Fight %d/%d: %s   -   Round %d" % [
		encounter_index + 1, encounters.size(), enc["name"], combat.round_number]
	_fate.text = "Fate %d/%d" % [combat.fate, Combat.MAX_FATE]

	_reroll_btn.text = "REROLL (%d left)" % combat.rerolls_left
	_reroll_btn.disabled = combat.finished or combat.rerolls_left <= 0
	_fate_btn.text = "FATE REROLL (-%d Fate)" % Combat.FATE_REROLL_COST
	_fate_btn.disabled = combat.finished or combat.fate < Combat.FATE_REROLL_COST
	_end_btn.disabled = combat.finished

	var combos := combat.compute_combos()
	var parts: Array[String] = []
	for t in combos:
		if combos[t] >= 3:
			parts.append("TRIPLE %s = x2" % FACE_NAMES[t])
		elif combos[t] >= 2:
			parts.append("PAIR %s = +1 each" % FACE_NAMES[t])
	_combo.text = ("Combo: " + ", ".join(parts)) if not parts.is_empty() else " "

	for c in _monster_row.get_children():
		c.queue_free()
	for i in combat.monsters.size():
		_monster_row.add_child(_monster_card(combat.monsters[i], i))

	for c in _hero_row.get_children():
		c.queue_free()
	for i in combat.heroes.size():
		_hero_row.add_child(_hero_card(combat.heroes[i], i, combos))


func _monster_card(m: Dictionary, index: int) -> Control:
	var alive := Combat.is_alive(m)
	var targeted := alive and index == combat.target_index
	var panel := _panel(COL_TARGET if targeted else COL_BORDER, 3 if targeted else 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 1.0 if alive else 0.35
	var box := VBoxContainer.new()
	panel.add_child(box)

	var name_text: String = ("[BOSS] " if m["boss"] else "") + m["name"]
	box.add_child(_label(name_text, 18))
	box.add_child(_hp_bar(m))
	box.add_child(_label(_status_text(m), 14, COL_DIM))
	if alive:
		var face := Combat.current_face(m)
		var intent := _label("Intent: " + combat.intent_text(m), 16, FACE_COLORS[face["type"]].lightened(0.35))
		box.add_child(intent)
		var btn := _button("TARGETED" if targeted else "Target", func(): combat.set_target(index))
		btn.disabled = targeted
		box.add_child(btn)
	else:
		box.add_child(_label("Dead", 16, COL_DIM))
	return panel


func _hero_card(h: Dictionary, index: int, combos: Dictionary) -> Control:
	var alive := Combat.is_alive(h)
	var panel := _panel(COL_GOLD if h["locked"] else COL_BORDER, 3 if h["locked"] else 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 1.0 if alive else 0.35
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label(h["name"], 17))
	box.add_child(_hp_bar(h))
	box.add_child(_label(_status_text(h), 14, COL_DIM))

	if not alive:
		box.add_child(_label("Fallen", 18, COL_DIM))
		return panel

	var face := Combat.current_face(h)
	var value := Combat.effective_value(face, combos)
	var die := Button.new()
	die.custom_minimum_size = Vector2(0, 78)
	die.add_theme_font_size_override("font_size", 22)
	var face_text: String = FACE_NAMES[face["type"]]
	if face["type"] != "blank":
		face_text += "  %d" % value
		if value != int(face["value"]):
			face_text += "  (base %d)" % int(face["value"])
	die.text = face_text + ("\nLOCKED" if h["locked"] else "")
	var style := StyleBoxFlat.new()
	style.bg_color = FACE_COLORS[face["type"]]
	style.set_corner_radius_all(6)
	style.set_border_width_all(3 if h["locked"] else 0)
	style.border_color = COL_GOLD
	for state in ["normal", "hover", "pressed", "focus"]:
		die.add_theme_stylebox_override(state, style)
	die.tooltip_text = "All faces: " + ", ".join(h["faces"].map(_face_short))
	die.pressed.connect(func(): combat.toggle_lock(index))
	box.add_child(die)
	if not h["skill"].is_empty():
		box.add_child(_skill_button(h, index))
	var faces := _label("Faces: " + " | ".join(h["faces"].map(_face_short)), 12, COL_DIM)
	faces.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	faces.custom_minimum_size = Vector2(120, 0)
	box.add_child(faces)
	return panel


func _skill_button(h: Dictionary, index: int) -> Button:
	var cost := Combat.skill_cost(h)
	var is_ready := combat.can_use_skill(index)
	var b := _button("", func(): combat.use_skill(index))
	b.text = ("%s  - READY!" if is_ready else "%s  (%d/%d)") % (
		[h["skill"]["name"]] if is_ready else [h["skill"]["name"], h["charge"], cost])
	b.disabled = not is_ready
	b.tooltip_text = h["skill"]["desc"]
	b.custom_minimum_size = Vector2(0, 34)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.bg_color = Color("#4a3a12") if is_ready else Color("#221c28")
	style.border_color = COL_GOLD if is_ready else COL_BORDER
	style.set_border_width_all(2 if is_ready else 1)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, style)
	b.add_theme_color_override("font_color", COL_GOLD if is_ready else COL_DIM)
	b.add_theme_color_override("font_disabled_color", COL_DIM)
	return b


# ---------------------------------------------------------------- helpers

func _on_log(text: String) -> void:
	_log.append_text(text + "\n")


func _status_text(u: Dictionary) -> String:
	var parts: Array[String] = []
	if u["shield"] > 0:
		parts.append("Shield %d" % u["shield"])
	if u["burn"] > 0:
		parts.append("Burn %d" % u["burn"])
	return " ".join(parts) if not parts.is_empty() else " "


func _face_short(f: Dictionary) -> String:
	return FACE_NAMES[f["type"]] + ("" if f["type"] == "blank" else str(int(f["value"])))


func _hp_bar(u: Dictionary) -> Control:
	var bar := ProgressBar.new()
	bar.max_value = u["max_hp"]
	bar.value = u["hp"]
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COL_HP
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#2a1418")
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	var text := _label("%d / %d" % [u["hp"], u["max_hp"]], 13)
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(text)
	return bar


func _label(text: String, size: int, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(on_press)
	return b


func _panel(border: Color, border_width: int = 1) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = COL_PANEL
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	return p
