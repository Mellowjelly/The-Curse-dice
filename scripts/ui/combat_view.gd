extends Control
## Combat screen component. Shows a Combat object and forwards clicks to it.
## All rules live in scripts/core/combat.gd. Emits `finished` when the player
## presses Continue after a battle ends.

signal finished(victory: bool)

const Combat = preload("res://scripts/core/combat.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")

const ROLL_ANIM_TIME := 0.35

var combat: Combat
var title := ""

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
var _banner: Label
var _pet_label: Label
var _victory := false

# Animation state
var _cards := {}          # unit (by instance id) -> card Control, for floating numbers
var _die_buttons := {}    # hero index -> Button
var _rolling := 0.0
var _last_round := -1
var _last_rerolls := -1
var _pending_numbers: Array = []
var _anim_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_build_ui()


## Attach a combat. Call before (or right after) start_battle.
func bind(c: Combat, fight_title: String) -> void:
	if combat != null:
		for pair in [[combat.log_added, _on_log], [combat.state_changed, _refresh],
				[combat.battle_ended, _on_battle_ended], [combat.damaged, _on_damaged],
				[combat.phase_changed, _on_phase_changed]]:
			if pair[0].is_connected(pair[1]):
				pair[0].disconnect(pair[1])
	combat = c
	title = fight_title
	combat.log_added.connect(_on_log)
	combat.state_changed.connect(_refresh)
	combat.battle_ended.connect(_on_battle_ended)
	combat.damaged.connect(_on_damaged)
	combat.phase_changed.connect(_on_phase_changed)
	_overlay.hide()
	_banner.modulate.a = 0.0
	_log.clear()
	_last_round = -1
	_refresh()


# ---------------------------------------------------------------- layout

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	add_child(UI.full_rect(bg))

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(UI.full_rect(margin))

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var field := VBoxContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 10)
	root.add_child(field)

	var top := HBoxContainer.new()
	field.add_child(top)
	_title = UI.label("", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	_fate = UI.label("", 18, UI.GOLD)
	top.add_child(_fate)

	field.add_child(UI.label("ENEMIES  (click Target to choose who your attacks hit)", 13, UI.DIM))
	_monster_row = HBoxContainer.new()
	_monster_row.add_theme_constant_override("separation", 12)
	_monster_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_child(_monster_row)

	_combo = UI.label(" ", 22, Color("#e0b04a"))
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_child(_combo)

	var party_head := HBoxContainer.new()
	field.add_child(party_head)
	var party_lbl := UI.label("YOUR PARTY  (click a die to lock / unlock it)", 13, UI.DIM)
	party_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_head.add_child(party_lbl)
	_pet_label = UI.label("", 15, Color("#b39ddb"))
	party_head.add_child(_pet_label)
	_hero_row = HBoxContainer.new()
	_hero_row.add_theme_constant_override("separation", 12)
	_hero_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_child(_hero_row)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	field.add_child(buttons)
	_reroll_btn = UI.button("", func(): _start_roll_anim(); combat.reroll())
	_fate_btn = UI.button("", func(): combat.fate_reroll())
	_end_btn = UI.button("END TURN", func(): combat.end_turn())
	for b in [_reroll_btn, _fate_btn, _end_btn]:
		b.custom_minimum_size = Vector2(200, 48)
		buttons.add_child(b)

	var log_panel := UI.panel()
	log_panel.custom_minimum_size = Vector2(300, 0)
	root.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log.add_theme_font_size_override("bold_font_size", 13)
	_log.add_theme_color_override("default_color", UI.TEXT)
	log_panel.add_child(_log)

	_banner = UI.label("", 30, UI.BLOOD)
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_shadow_color", Color.BLACK)
	_banner.add_theme_constant_override("shadow_offset_x", 3)
	_banner.add_theme_constant_override("shadow_offset_y", 3)
	_banner.position = Vector2(140, 300)
	_banner.size = Vector2(1000, 120)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	_overlay = UI.full_rect(dim)
	add_child(_overlay)
	var center := CenterContainer.new()
	_overlay.add_child(UI.full_rect(center))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	_overlay_text = UI.label("", 30)
	_overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_overlay_text)
	_overlay_btn = UI.button("Continue", func(): finished.emit(_victory), 20)
	_overlay_btn.custom_minimum_size = Vector2(240, 52)
	_overlay_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_overlay_btn)
	_overlay.hide()


# ---------------------------------------------------------------- events

func _on_log(text: String) -> void:
	if text.begins_with("!!"):
		text = "[color=#e0573f][b]%s[/b][/color]" % text
	elif text.begins_with("*"):
		text = "[color=#c9a227]%s[/color]" % text
	elif text.begins_with("--- Round"):
		text = "[color=#7a6f80]%s[/color]" % text
	_log.append_text(text + "\n")


func _on_battle_ended(victory: bool) -> void:
	_victory = victory
	_overlay_text.text = "Victory!" if victory else "Your party has fallen.\nThe dice show no mercy."
	_overlay_text.add_theme_color_override("font_color", UI.GOLD if victory else UI.BLOOD)
	# Let the last floating numbers play before covering the screen.
	get_tree().create_timer(0.6).timeout.connect(func(): _overlay.show())


func _on_damaged(unit: Dictionary, amount: int, blocked: int) -> void:
	_pending_numbers.append([unit, amount, blocked])


func _on_phase_changed(_unit: Dictionary, text: String) -> void:
	_show_banner(text)


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.8)


# ---------------------------------------------------------------- animation

func _start_roll_anim() -> void:
	_rolling = ROLL_ANIM_TIME


func _process(delta: float) -> void:
	if _rolling > 0.0:
		_rolling -= delta
		for i in _die_buttons:
			var h: Dictionary = combat.heroes[i]
			if h["locked"] or not Combat.is_alive(h):
				continue
			var f: Dictionary = h["faces"][_anim_rng.randi_range(0, h["faces"].size() - 1)]
			var b: Button = _die_buttons[i]
			if is_instance_valid(b):
				b.text = UI.face_short(f)
				(b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = UI.FACE_COLORS[f["type"]]
		if _rolling <= 0.0:
			_refresh()
	if not _pending_numbers.is_empty():
		_spawn_numbers()


func _spawn_numbers() -> void:
	var delay := 0.0
	for item in _pending_numbers:
		var key := _uid(item[0])
		if key == "":
			continue
		# Place by slot in the row (cards may have just been rebuilt and not laid out yet).
		var is_hero := key.begins_with("h")
		var row: Control = _hero_row if is_hero else _monster_row
		var count: int = combat.heroes.size() if is_hero else combat.monsters.size()
		var slot := int(key.substr(1))
		var slot_w: float = row.size.x / float(max(count, 1))
		var text := "-%d" % item[1] if item[1] > 0 else "blocked"
		var l := UI.label(text, 30, UI.BLOOD if item[1] > 0 else Color("#7fa7d1"))
		l.add_theme_color_override("font_shadow_color", Color.BLACK)
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		var start := row.global_position + Vector2(slot_w * (slot + 0.5) - 20 + _anim_rng.randf_range(-30, 30), 40)
		l.global_position = start
		l.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(l, "modulate:a", 1.0, 0.05)
		tw.parallel().tween_property(l, "global_position", start + Vector2(0, -50), 0.9)
		tw.tween_property(l, "modulate:a", 0.0, 0.3)
		tw.tween_callback(l.queue_free)
		delay += 0.12
	_pending_numbers.clear()


func _uid(unit: Dictionary) -> String:
	# Dictionaries are shared references; use the name + index position as a stable key.
	for i in combat.heroes.size():
		if is_same(combat.heroes[i], unit):
			return "h%d" % i
	for i in combat.monsters.size():
		if is_same(combat.monsters[i], unit):
			return "m%d" % i
	return ""


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	if combat == null or _title == null:
		return
	if combat.round_number != _last_round:
		if _last_round != -1 or combat.round_number == 1:
			_start_roll_anim()
		_last_round = combat.round_number
	_title.text = "%s   -   Round %d" % [title, combat.round_number]
	_fate.text = "Fate %d/%d" % [combat.fate, Combat.MAX_FATE]
	_reroll_btn.text = "REROLL (%d left)" % combat.rerolls_left
	_reroll_btn.disabled = combat.finished or combat.rerolls_left <= 0
	_fate_btn.text = "FATE REROLL (-%d Fate)" % Combat.FATE_REROLL_COST
	_fate_btn.disabled = combat.finished or combat.fate < Combat.FATE_REROLL_COST
	_end_btn.disabled = combat.finished
	if combat.pet.is_empty():
		_pet_label.text = ""
	else:
		var pf: Dictionary = combat.pet["faces"][combat.pet["face"]]
		_pet_label.text = "Pet %s rolled: %s" % [combat.pet["name"], UI.face_short(pf)]

	var combos := combat.compute_combos()
	var parts: Array[String] = []
	for t in combos:
		if combos[t] >= 3:
			parts.append("TRIPLE %s  x2!" % UI.FACE_NAMES[t])
		elif combos[t] >= 2:
			parts.append("PAIR %s  +1 each" % UI.FACE_NAMES[t])
	_combo.text = ("COMBO: " + "   ".join(parts)) if not parts.is_empty() else " "

	_cards.clear()
	_die_buttons.clear()
	for c in _monster_row.get_children():
		c.queue_free()
	for i in combat.monsters.size():
		var card := _monster_card(combat.monsters[i], i)
		_cards["m%d" % i] = card
		_monster_row.add_child(card)
	for c in _hero_row.get_children():
		c.queue_free()
	for i in combat.heroes.size():
		var card := _hero_card(combat.heroes[i], i, combos)
		_cards["h%d" % i] = card
		_hero_row.add_child(card)


func _status_text(u: Dictionary) -> String:
	var parts: Array[String] = []
	if u["shield"] > 0:
		parts.append("Shield %d" % u["shield"])
	if u["burn"] > 0:
		parts.append("Burn %d" % u["burn"])
	return "  ".join(parts) if not parts.is_empty() else " "


func _monster_card(m: Dictionary, index: int) -> Control:
	var alive := Combat.is_alive(m)
	var targeted := alive and index == combat.target_index
	var border := UI.BLOOD if targeted else (Color("#8a1f4a") if m.get("boss", false) else UI.BORDER)
	var panel := UI.panel(border, 3 if targeted else 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 1.0 if alive else 0.35
	var box := VBoxContainer.new()
	panel.add_child(box)
	var name_text: String = ("[BOSS] " if m["boss"] else "") + m["name"]
	if m.get("phased", false):
		name_text += "  (enraged)"
	box.add_child(UI.label(name_text, 18))
	box.add_child(UI.hp_bar(m["hp"], m["max_hp"]))
	box.add_child(UI.label(_status_text(m), 14, UI.DIM))
	if alive:
		var face := Combat.current_face(m)
		box.add_child(UI.label("Intent: " + combat.intent_text(m), 17, UI.FACE_COLORS[face["type"]].lightened(0.4)))
		var btn := UI.button("TARGETED" if targeted else "Target", func(): combat.set_target(index))
		btn.disabled = targeted or combat.finished
		box.add_child(btn)
	else:
		box.add_child(UI.label("Dead", 16, UI.DIM))
	return panel


func _hero_card(h: Dictionary, index: int, combos: Dictionary) -> Control:
	var alive := Combat.is_alive(h)
	var panel := UI.panel(UI.GOLD if h["locked"] else UI.BORDER, 3 if h["locked"] else 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 1.0 if alive else 0.35
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UI.label(h["name"], 17))
	box.add_child(UI.hp_bar(h["hp"], h["max_hp"]))
	box.add_child(UI.label(_status_text(h), 14, UI.DIM))
	if not alive:
		box.add_child(UI.label("Fallen", 18, UI.DIM))
		return panel

	var face := Combat.current_face(h)
	var value := Combat.effective_value(face, combos)
	var die := Button.new()
	die.custom_minimum_size = Vector2(0, 70)
	die.add_theme_font_size_override("font_size", 22)
	var face_text: String = UI.FACE_NAMES[face["type"]]
	if face["type"] != "blank":
		face_text += "  %d" % value
		if value != int(face["value"]):
			face_text += "  (base %d)" % int(face["value"])
	die.text = face_text + ("\nLOCKED" if h["locked"] else "")
	var style := StyleBoxFlat.new()
	style.bg_color = UI.FACE_COLORS[face["type"]]
	style.set_corner_radius_all(6)
	style.set_border_width_all(3 if h["locked"] else 0)
	style.border_color = UI.GOLD
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		die.add_theme_stylebox_override(state, style)
	die.disabled = combat.finished
	die.pressed.connect(func(): combat.toggle_lock(index))
	_die_buttons[index] = die
	box.add_child(die)
	if combat.fate >= Combat.FATE_TWIST_COST and not combat.finished:
		# Fate Twist: click any face to set the die to it.
		box.add_child(UI.label("Fate Twist (-%d): pick a face" % Combat.FATE_TWIST_COST, 12, UI.GOLD))
		var grid := GridContainer.new()
		grid.columns = 3
		for fi in h["faces"].size():
			var f: Dictionary = h["faces"][fi]
			var fb := UI.button(UI.face_short(f), func(): combat.fate_twist(index, fi), 11)
			fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fb.add_theme_stylebox_override("normal", UI.box(UI.FACE_COLORS[f["type"]].darkened(0.2), UI.GOLD, 1, 3, 2))
			grid.add_child(fb)
		box.add_child(grid)
	else:
		var faces := UI.wrap_label("Faces: " + " | ".join(h["faces"].map(UI.face_short)), 12, UI.DIM, 120)
		box.add_child(faces)
	if not h["skill"].is_empty():
		box.add_child(_skill_button(h, index))
	return panel


func _skill_button(h: Dictionary, index: int) -> Control:
	var cost := Combat.skill_cost(h)
	var is_ready := combat.can_use_skill(index)
	var b := Button.new()
	b.text = "%s  %s\n%s" % [h["skill"]["name"], "READY!" if is_ready else "(%d/%d)" % [h["charge"], cost], h["skill"]["desc"]]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 12)
	b.disabled = not is_ready
	b.custom_minimum_size = Vector2(120, 0)
	b.pressed.connect(func(): combat.use_skill(index))
	var style := UI.box(Color("#4a3a12") if is_ready else Color("#221c28"), UI.GOLD if is_ready else UI.BORDER, 2 if is_ready else 1, 4, 6)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, style)
	b.add_theme_color_override("font_color", UI.GOLD if is_ready else UI.DIM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", UI.DIM)
	return b
