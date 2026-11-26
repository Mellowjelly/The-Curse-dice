extends Control
## Combat screen component. Shows a Combat object and forwards clicks to it.
## All rules live in scripts/core/combat.gd. Emits `finished` when the player
## presses Continue after a battle ends.

signal finished(victory: bool)

const Combat = preload("res://scripts/core/combat.gd")
const Settings = preload("res://scripts/ui/settings.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")
const Sfx = preload("res://scripts/ui/sfx.gd")
const UnitSprite = preload("res://scripts/ui/unit_sprite.gd")

const FX_STEP := 0.2        # seconds between animated actions in a turn
const HERO_SPRITE := 64
const MONSTER_SPRITE := 96

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
var _flee_btn: Button
var _tut_panel: PanelContainer
var _tut_label: Label
var _tut_target: Control
var _tut_tween: Tween
var _overlay: Control
var _overlay_text: Label
var _overlay_btn: Button
var _banner: Label
var _pet_label: Label
var _bg_art: TextureRect
var _pet_slot: Control
var _particles: CPUParticles2D
var _pulse: Tween
var _victory := false

# Animation state
var _cards := {}          # unit (by instance id) -> card Control, for floating numbers
var _die_buttons := {}    # hero index -> Button
var _rolling := 0.0
var _last_round := -1
var _last_rerolls := -1
var _pending_numbers: Array = []  # queued visual events: ["act", unit] or ["hit", unit, amount, blocked]
var _sprites := {}                 # "h0"/"m1" -> UnitSprite (kept alive across card rebuilds)
var _anim_rng := RandomNumberGenerator.new()
var _death_delay := 0.0


func _ready() -> void:
	_build_ui()


## Attach a combat. Call before (or right after) start_battle.
func bind(c: Combat, fight_title: String, background: String = "battle_early", tint: Color = Color.WHITE) -> void:
	_set_background(background)
	_bg_art.modulate = tint
	Sfx.music(self, "boss" if c.monsters.any(func(m): return m.get("boss", false)) else "battle")
	if combat != null:
		for pair in [[combat.log_added, _on_log], [combat.state_changed, _refresh],
				[combat.battle_ended, _on_battle_ended], [combat.damaged, _on_damaged],
				[combat.phase_changed, _on_phase_changed], [combat.acted, _on_acted]]:
			if pair[0].is_connected(pair[1]):
				pair[0].disconnect(pair[1])
	combat = c
	title = fight_title
	combat.log_added.connect(_on_log)
	combat.state_changed.connect(_refresh)
	combat.battle_ended.connect(_on_battle_ended)
	combat.damaged.connect(_on_damaged)
	combat.phase_changed.connect(_on_phase_changed)
	combat.acted.connect(_on_acted)
	for sp in _sprites.values():
		sp.queue_free()
	_sprites.clear()
	_pending_numbers.clear()
	_overlay.hide()
	_banner.modulate.a = 0.0
	_last_round = -1
	for ch in _pet_slot.get_children():
		ch.queue_free()
	if not combat.pet.is_empty():
		var ps := UnitSprite.create(combat.pet["id"], 40, false)
		ps.position = Vector2(0, -8)
		_pet_slot.add_child(ps)
	_log.append_text("\n[color=#c9a227][b]== %s ==[/b][/color]\n" % fight_title)
	_on_log(tr("--- Round %d ---") % combat.round_number)
	if not combat.pet.is_empty() and combat.pet["passive"] in ["first_strike", "fate_start"]:
		_on_log(tr("%s is ready.") % tr(combat.pet["name"]))
	_refresh()


# ---------------------------------------------------------------- layout

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	add_child(UI.full_rect(bg))
	_bg_art = TextureRect.new()
	_bg_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_art.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.full_rect(_bg_art))
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.05, 0.35)  # keeps text readable over the scenery
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.full_rect(shade))
	_particles = CPUParticles2D.new()
	add_child(_particles)

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
	var legend := UI.label(tr("Elements: Fire > Wind > Earth > Water > Fire   |   Light <> Dark   (+20% / -20%)"), 12, UI.DIM)
	legend.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(legend)  # in the header so it never pushes the buttons off-screen
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(16, 0)
	top.add_child(gap)
	_fate = UI.label("", 18, UI.GOLD)
	top.add_child(_fate)

	field.add_child(UI.label(tr("ENEMIES  (tap Target to choose who your attacks hit)"), 13, UI.DIM))
	_monster_row = HBoxContainer.new()
	_monster_row.add_theme_constant_override("separation", 12)
	_monster_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_child(_monster_row)

	_combo = UI.label(" ", 22, Color("#e0b04a"))
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_child(_combo)

	var party_head := HBoxContainer.new()
	field.add_child(party_head)
	var party_lbl := UI.label(tr("YOUR PARTY  (tap a die to lock / unlock it)"), 13, UI.DIM)
	party_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_head.add_child(party_lbl)
	_pet_label = UI.label("", 15, Color("#b39ddb"))
	party_head.add_child(_pet_label)
	_pet_slot = Control.new()
	_pet_slot.custom_minimum_size = Vector2(40, 32)
	party_head.add_child(_pet_slot)
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
	_end_btn = UI.button(tr("END TURN"), func(): combat.end_turn())
	_flee_btn = UI.button(tr("FLEE"), func(): combat.flee(), 14)
	for b in [_reroll_btn, _fate_btn, _end_btn]:
		b.custom_minimum_size = Vector2(200, 48)
		buttons.add_child(b)
	_flee_btn.custom_minimum_size = Vector2(90, 48)
	_flee_btn.tooltip_text = tr("Run back two steps. The enemy stays. Possible from round 2.")
	buttons.add_child(_flee_btn)

	var log_panel := UI.panel()
	log_panel.custom_minimum_size = Vector2(230, 0)
	root.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log.add_theme_font_size_override("bold_font_size", 13)
	_log.add_theme_color_override("default_color", UI.TEXT)
	log_panel.add_child(_log)

	_build_tutorial()

	_banner = UI.label("", 30, UI.BLOOD)
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_shadow_color", Color.BLACK)
	_banner.add_theme_constant_override("shadow_offset_x", 3)
	_banner.add_theme_constant_override("shadow_offset_y", 3)
	_banner.position = Vector2(140, 300)
	_banner.size = Vector2(1000, 120)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_stylebox_override("normal", UI.box(Color(0.03, 0.02, 0.05, 0.92), UI.BLOOD, 2, 8, 16))
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
	_overlay_btn = UI.button(tr("Continue"), func(): finished.emit(_victory), 20)
	_overlay_btn.custom_minimum_size = Vector2(240, 52)
	_overlay_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_overlay_btn)
	_overlay.hide()


## Battle scenery: battle_early (dead forest), battle_mid (graveyard), battle_late (burning ruins), battle_boss (chapel).
func _set_background(id: String) -> void:
	var path := "res://assets/backgrounds/%s.png" % id
	_bg_art.texture = load(path) if ResourceLoader.exists(path) else null
	var p := _particles
	p.emitting = false
	p.position = Vector2(640, 740)
	p.amount = 40
	p.lifetime = 10.0
	p.preprocess = 10.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 10)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2.ZERO
	var fade := Gradient.new()
	match id:
		"battle_late", "battle_boss":
			# rising embers
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 80.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 4.0
			fade.set_color(0, Color(1.0, 0.5, 0.1, 0.9))
			fade.set_color(1, Color(0.6, 0.1, 0.05, 0.0))
		_:
			# slow drifting fog motes
			p.position = Vector2(-40, 430)
			p.emission_rect_extents = Vector2(10, 180)
			p.direction = Vector2(1, 0)
			p.initial_velocity_min = 12.0
			p.initial_velocity_max = 30.0
			p.scale_amount_min = 6.0
			p.scale_amount_max = 14.0
			p.lifetime = 40.0
			p.preprocess = 40.0
			fade.set_color(0, Color(0.7, 0.7, 0.8, 0.10))
			fade.set_color(1, Color(0.7, 0.7, 0.8, 0.0))
	p.color_ramp = fade
	p.emitting = true


# ---------------------------------------------------------------- events

func _on_log(text: String) -> void:
	# Sound hooks on the big moments.
	if text.begins_with(tr("COMBO!")):
		Sfx.play(self, "triple")
	elif text.begins_with(tr("Combo:")) or text.contains(tr("Fate twists")) or text.contains(tr("Fate overflows")):
		Sfx.play(self, "fate")
	elif text.begins_with("* "):
		Sfx.play(self, "skill")
	elif text.contains("rises"):
		Sfx.play(self, "fate", -2.0)
	if text.begins_with("!!"):
		text = "[color=#e0573f][b]%s[/b][/color]" % text
	elif text.begins_with("*"):
		text = "[color=#c9a227]%s[/color]" % text
	elif text.begins_with("--- Round"):
		text = "[color=#7a6f80]%s[/color]" % text
	_log.append_text(text + "\n")


func _on_battle_ended(victory: bool) -> void:
	_victory = victory
	Sfx.play(self, "victory" if victory else "defeat")
	_overlay_text.text = tr("Victory!") if victory else tr("Your party has fallen.\nThe dice show no mercy.")
	_overlay_text.add_theme_color_override("font_color", UI.GOLD if victory else UI.BLOOD)
	# Let the last floating numbers play before covering the screen.
	get_tree().create_timer(0.6).timeout.connect(func(): _overlay.show())


func _on_damaged(unit: Dictionary, amount: int, blocked: int) -> void:
	if not _pending_numbers.any(func(e): return e[0] == "hit"):
		Sfx.play(self, "hit", -10.0)
	_pending_numbers.append(["hit", unit, amount, blocked, float(unit.get("last_eff", 1.0))])


func _on_acted(unit: Dictionary) -> void:
	_pending_numbers.append(["act", unit])


func _on_phase_changed(unit: Dictionary, text: String) -> void:
	Sfx.play(self, "phase", 0.0)
	var sp = _sprites.get(_uid(unit))
	if sp != null and ResourceLoader.exists("res://assets/sprites/%s_enraged.png" % unit["id"]):
		sp.enrage("%s_enraged" % unit["id"])
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
	Sfx.play(self, "dice", -8.0)


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
				b.icon = UI.face_icon(f["type"])
				(b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = UI.FACE_COLORS[f["type"]]
		if _rolling <= 0.0:
			_refresh()
	if not _pending_numbers.is_empty():
		_spawn_numbers()


func _spawn_numbers() -> void:
	var delay := 0.0
	var per_unit := {}
	for item in _pending_numbers:
		var key := _uid(item[1])
		if key == "":
			continue
		var sp = _sprites.get(key)
		if item[0] == "act":
			if sp != null:
				sp.attack(delay)
			delay += FX_STEP
			continue
		if sp != null:
			sp.hurt(delay + 0.08)
		# Place by slot in the row (cards may have just been rebuilt and not laid out yet).
		var is_hero := key.begins_with("h")
		var row: Control = _hero_row if is_hero else _monster_row
		var count: int = combat.heroes.size() if is_hero else combat.monsters.size()
		var slot := int(key.substr(1))
		var slot_w: float = row.size.x / float(max(count, 1))
		var eff: float = item[4] if item.size() > 4 else 1.0
		var text := "-%d" % item[2] if item[2] > 0 else "blocked"
		var color := UI.BLOOD if item[2] > 0 else Color("#7fa7d1")
		var size := 30
		if item[2] > 0 and eff > 1.0:
			text += "!"
			color = Color("#ff9a3c")  # super effective
			size = 36
		elif item[2] > 0 and eff < 1.0:
			color = Color("#9a9aa8")  # resisted
			size = 24
		var l := UI.label(text, size, color)
		l.add_theme_color_override("font_shadow_color", Color.BLACK)
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		var nth: int = per_unit.get(key, 0)
		per_unit[key] = nth + 1
		# Several hits on one unit fan out side by side instead of overlapping.
		var start := row.global_position + Vector2(slot_w * (slot + 0.5) - 30 + nth * 46, 40 - nth * 6)
		if sp != null and sp.is_inside_tree() and sp.size.x > 0:
			start = sp.global_position + Vector2(sp.size.x * 0.5 - 16 + nth * 40, -6 - nth * 6)
		l.global_position = start
		l.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(l, "modulate:a", 1.0, 0.05)
		tw.parallel().tween_property(l, "global_position", start + Vector2(0, -50), 0.9)
		tw.tween_property(l, "modulate:a", 0.0, 0.3)
		tw.tween_callback(l.queue_free)
		delay += FX_STEP * 0.6
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
	_update_tutorial()
	if combat.round_number != _last_round:
		if _last_round != -1 or combat.round_number == 1:
			_start_roll_anim()
		_last_round = combat.round_number
	_title.text = tr("%s   -   Round %d") % [title, combat.round_number]
	_fate.text = tr("Fate %d/%d") % [combat.fate, Combat.MAX_FATE]
	_reroll_btn.text = tr("REROLL (%d left)") % combat.rerolls_left
	_reroll_btn.disabled = combat.finished or combat.rerolls_left <= 0
	_fate_btn.text = tr("FATE REROLL (-%d Fate)") % Combat.FATE_REROLL_COST
	_fate_btn.disabled = combat.finished or combat.fate < Combat.FATE_REROLL_COST
	_end_btn.disabled = combat.finished
	_flee_btn.visible = combat.can_flee
	_flee_btn.disabled = combat.finished or combat.round_number < 2
	if combat.pet.is_empty():
		_pet_label.text = ""
	else:
		var pf: Dictionary = combat.pet["faces"][combat.pet["face"]]
		_pet_label.text = tr("Pet %s rolled: %s") % [tr(combat.pet["name"]), UI.face_short(pf)]

	var combos := combat.compute_combos()
	var parts: Array[String] = []
	for t in combos:
		if combos[t] >= 3:
			parts.append(tr("TRIPLE %s  x2!") % UI.face_name(t))
		elif combos[t] >= 2:
			parts.append(tr("PAIR %s  +1 each") % UI.face_name(t))
	_combo.text = (tr("COMBO: ") + "   ".join(parts)) if not parts.is_empty() else " "
	if combat.fate >= Combat.MAX_FATE and not combat.finished and parts.is_empty():
		_combo.text = tr("FATE IS FULL - tap a face under a die to TWIST it!")
		if _pulse == null or not _pulse.is_valid():
			_pulse = _combo.create_tween().set_loops()
			_pulse.tween_property(_combo, "modulate:a", 0.4, 0.5)
			_pulse.tween_property(_combo, "modulate:a", 1.0, 0.5)
	elif _pulse != null and _pulse.is_valid():
		_pulse.kill()
		_combo.modulate.a = 1.0

	_cards.clear()
	_die_buttons.clear()
	for sp in _sprites.values():
		if sp.get_parent() != null:
			sp.get_parent().remove_child(sp)
	# Deaths play after this turn's queued attacks and hits.
	_death_delay = _pending_numbers.size() * FX_STEP * 0.8 + 0.2
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


func _sprite_row(key: String, u: Dictionary, info: Control, is_hero: bool) -> Control:
	var sp = _sprites.get(key)
	if sp == null:
		var id: String = u["id"] + ("_enraged" if u.get("phased", false) and ResourceLoader.exists("res://assets/sprites/%s_enraged.png" % u["id"]) else "")
		var px := HERO_SPRITE if is_hero else MONSTER_SPRITE
		sp = UnitSprite.create(id, px, not is_hero)
		_sprites[key] = sp
		if not Combat.is_alive(u):
			sp.set_dead(true)
	sp.set_dead(not Combat.is_alive(u), _death_delay)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(sp)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	return row


func _status_text(u: Dictionary) -> String:
	var parts: Array[String] = []
	if u["shield"] > 0:
		parts.append(tr("Shield %d") % u["shield"])
	if u["burn"] > 0:
		parts.append(tr("Burn %d") % u["burn"])
	return "  ".join(parts) if not parts.is_empty() else " "


func _monster_card(m: Dictionary, index: int) -> Control:
	var alive := Combat.is_alive(m)
	var targeted := alive and index == combat.target_index
	var border := UI.BLOOD if targeted else (Color("#8a1f4a") if m.get("boss", false) else UI.BORDER)
	var panel := UI.panel(border, 3 if targeted else 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 1.0 if alive else 0.6
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	var box := VBoxContainer.new()
	outer.add_child(_sprite_row("m%d" % index, m, box, false))
	var name_text: String = (tr("[BOSS] ") if m["boss"] else "") + tr(m["name"])
	if m.get("phased", false):
		name_text += tr("  (enraged)")
	var nl := UI.label(name_text, 17)
	nl.clip_text = true
	box.add_child(nl)
	box.add_child(UI.hp_bar(m["hp"], m["max_hp"]))
	var weak := UI.element_weakness(m.get("element", ""))
	box.add_child(UI.element_badge(m.get("element", ""), (tr("  -  weak to %s") % weak) if weak != "" else ""))
	box.add_child(UI.label(_status_text(m), 14, UI.DIM))
	box = outer
	if alive:
		var face := Combat.current_face(m)
		box.add_child(UI.label(tr("Intent: ") + combat.intent_text(m), 17, UI.FACE_COLORS[face["type"]].lightened(0.4)))
		var btn := UI.button(tr("TARGETED") if targeted else tr("Target"), func(): combat.set_target(index))
		btn.disabled = targeted or combat.finished
		box.add_child(btn)
	else:
		box.add_child(UI.label(tr("Dead"), 16, UI.DIM))
	return panel


func _hero_card(h: Dictionary, index: int, combos: Dictionary) -> Control:
	var alive := Combat.is_alive(h)
	var panel := UI.panel(UI.GOLD if h["locked"] else UI.BORDER, 3 if h["locked"] else 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 1.0 if alive else 0.6
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var info := VBoxContainer.new()
	var nl := UI.label(tr(h["name"]), 16)
	nl.clip_text = true
	info.add_child(nl)
	info.add_child(UI.hp_bar(h["hp"], h["max_hp"]))
	var status_row := HBoxContainer.new()
	status_row.add_child(UI.element_badge(h.get("element", "")))
	status_row.add_child(UI.label("  " + _status_text(h), 13, UI.DIM))
	info.add_child(status_row)
	box.add_child(_sprite_row("h%d" % index, h, info, true))
	if not alive:
		box.add_child(UI.label(tr("Fallen"), 18, UI.DIM))
		return panel

	var face := Combat.current_face(h)
	var value := Combat.effective_value(face, combos)
	var die := Button.new()
	var twisting := combat.fate >= Combat.FATE_TWIST_COST and not combat.finished
	die.custom_minimum_size = Vector2(0, 46 if twisting else 60)
	die.add_theme_font_size_override("font_size", 20 if twisting else 22)
	var face_text: String = UI.face_name(face["type"])
	if face["type"] != "blank":
		face_text += "  %d" % value
		if value != int(face["value"]):
			face_text += tr("  (base %d)") % int(face["value"])
	die.text = face_text + (tr("\nLOCKED") if h["locked"] else "")
	die.icon = UI.face_icon(face["type"])
	die.expand_icon = true
	die.add_theme_constant_override("icon_max_width", 40 if not twisting else 32)
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
		box.add_child(UI.label(tr("Twist (-%d Fate): tap a face") % Combat.FATE_TWIST_COST, 12, UI.GOLD))
		var grid := GridContainer.new()
		grid.columns = 3
		for fi in h["faces"].size():
			var f: Dictionary = h["faces"][fi]
			var fb := UI.button(UI.face_short(f).replace(tr("BLANK"), "-"), func(): combat.fate_twist(index, fi), 12)
			fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fb.custom_minimum_size = Vector2(0, 32)
			fb.icon = UI.face_icon(f["type"])
			fb.add_theme_stylebox_override("normal", UI.box(UI.FACE_COLORS[f["type"]].darkened(0.2), UI.GOLD, 1, 3, 2))
			grid.add_child(fb)
		box.add_child(grid)
	else:
		var faces := UI.wrap_label(tr("Faces: ") + " | ".join(h["faces"].map(UI.face_short)), 12, UI.DIM, 250)
		box.add_child(faces)
	if not h["skill"].is_empty():
		box.add_child(_skill_button(h, index))
	return panel


func _skill_button(h: Dictionary, index: int) -> Control:
	var cost := Combat.skill_cost(h)
	var is_ready := combat.can_use_skill(index)
	var b := Button.new()
	var hint := ""
	if is_ready and h["skill"]["id"] == "broken_oath" and not combat.monsters.any(
			func(m): return Combat.is_alive(m) and Combat.current_face(m)["type"] == "attack"):
		hint = tr("  (no single attacks incoming)")
	b.text = "%s  %s%s\n%s" % [tr(h["skill"]["name"]), tr("READY!") if is_ready else "(%d/%d)" % [h["charge"], cost], hint, tr(h["skill"]["desc"])]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 12)
	b.disabled = not is_ready
	b.custom_minimum_size = Vector2(250, 0)
	b.pressed.connect(func(): combat.use_skill(index))
	var style := UI.box(Color("#4a3a12") if is_ready else Color("#221c28"), UI.GOLD if is_ready else UI.BORDER, 2 if is_ready else 1, 4, 6)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, style)
	b.add_theme_color_override("font_color", UI.GOLD if is_ready else UI.DIM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", UI.DIM)
	return b


# ---------------------------------------------------------------- first-fight tutorial
# Steps: 0 lock a die -> 1 reroll -> 2 read intent and end turn -> 3 (waits for 4 Fate) twist -> done.
# Progress lives in Settings (settings.cfg), so it shows once per device and can be skipped.

func _build_tutorial() -> void:
	_tut_panel = UI.panel(UI.GOLD, 2)
	_tut_panel.position = Vector2(150, 296)
	_tut_panel.custom_minimum_size = Vector2(720, 0)
	_tut_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_tut_panel.add_child(row)
	_tut_label = UI.label("", 15, UI.TEXT)
	_tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_label.custom_minimum_size = Vector2(560, 0)
	_tut_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_tut_label)
	var skip := UI.button(tr("Skip tutorial"), func(): Settings.set_tutorial_step(Settings.TUTORIAL_DONE); _update_tutorial(), 12)
	skip.custom_minimum_size = Vector2(120, 36)
	row.add_child(skip)
	add_child(_tut_panel)
	_tut_panel.hide()


func _update_tutorial() -> void:
	if _tut_panel == null:
		return
	var step := Settings.tutorial_step
	if step >= Settings.TUTORIAL_DONE or combat == null or combat.finished:
		_show_tutorial("", null)
		return
	# Advance when the player has done what the current step asks.
	if step == 0 and combat.heroes.any(func(h): return h["locked"]):
		step = 1
	elif step == 1 and combat.rerolls_left < Combat.REROLLS_PER_TURN:
		step = 2
	elif step == 2 and combat.round_number >= 2:
		step = 3
	elif step == 4 and combat.twists > 0:
		step = Settings.TUTORIAL_DONE
	if step == 3 and combat.fate >= Combat.FATE_TWIST_COST:
		step = 4
	if step != Settings.tutorial_step:
		Settings.set_tutorial_step(step)
	match step:
		0:
			_show_tutorial(tr("Tutorial 1/4: Tap a die to LOCK it. Locked dice keep their face when you reroll."), _hero_row)
		1:
			_show_tutorial(tr("Tutorial 2/4: Press REROLL. Every unlocked die rolls again. You have 2 rerolls each round."), _reroll_btn)
		2:
			_show_tutorial(tr("Tutorial 3/4: Two dice with the same face make a COMBO. Read each enemy's Intent, tap Target on who to hit, then press END TURN."), _end_btn)
		4:
			_show_tutorial(tr("Tutorial 4/4: Fate is full enough to TWIST: tap a face under a die to turn that die to it. Blank faces and combos refill Fate."), _hero_row)
		_:
			_show_tutorial("", null)


func _show_tutorial(text: String, target: Control) -> void:
	if text == "":
		_tut_panel.hide()
		_set_tut_target(null)
		return
	_tut_label.text = text
	_tut_panel.show()
	_set_tut_target(target)


## The control the current step is about gently pulses, so the eye finds it.
func _set_tut_target(target: Control) -> void:
	if target == _tut_target:
		return
	if _tut_tween != null and _tut_tween.is_valid():
		_tut_tween.kill()
	if _tut_target != null and is_instance_valid(_tut_target):
		_tut_target.modulate = Color.WHITE
	_tut_target = target
	if target != null:
		_tut_tween = target.create_tween().set_loops()
		_tut_tween.tween_property(target, "modulate", Color(1.35, 1.25, 0.8), 0.6)
		_tut_tween.tween_property(target, "modulate", Color.WHITE, 0.6)
