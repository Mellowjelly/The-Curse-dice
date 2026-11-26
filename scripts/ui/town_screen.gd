extends Control
## The town of Ashfall: choose your party, build, summon, read quests, then set out.
## Rules live in scripts/core/profile.gd; this file only displays and forwards clicks.

const Profile = preload("res://scripts/core/profile.gd")
const GameData = preload("res://scripts/core/game_data.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")
const Sfx = preload("res://scripts/ui/sfx.gd")

const GAME_SCENE := "res://scenes/game.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

## Set by the game screen so the town can show what the last run earned.
static var last_result: Dictionary = {}

var profile: Profile
var heroes_db: Array
var _rng := RandomNumberGenerator.new()
var _embers: Label
var _tabs: TabContainer
var _party_box: VBoxContainer
var _buildings: VBoxContainer
var _summon_box: VBoxContainer
var _quests: VBoxContainer
var _result_box: VBoxContainer
var _go: Button
var _fire_line: Label


func _ready() -> void:
	_rng.randomize()
	profile = Profile.new()
	profile.load_profile()
	heroes_db = GameData.load_heroes()
	_build()
	_refresh()


## Building hotspots on the town art (art pixels; the art is drawn x4). Must match tools/make_backgrounds.py.
const TOWN_BUILDINGS := {
	"chapel": Rect2(6, 34, 30, 70), "smithy": Rect2(40, 62, 30, 42), "carver": Rect2(74, 70, 24, 34),
	"fortune": Rect2(102, 72, 24, 32), "kennel": Rect2(130, 84, 20, 20), "market": Rect2(112, 116, 44, 26),
}
const ART_SCALE := 4.0
const FIRE := Vector2(256, 600)
# Where heroes stand: the party around the fire, everyone else wandering the square.
const PARTY_SPOTS := [Vector2(104, 470), Vector2(318, 448), Vector2(336, 560)]
const IDLE_SPOTS := [Vector2(444, 584), Vector2(544, 584), Vector2(10, 590)]

var _scene_layer: Control
var _art: TextureRect
var _time_box: HBoxContainer
var _banner := "heroes"
var _reveal: Dictionary = {}

# Day/night look of the town: which art to use and how to tint it.
const TIME_LOOK := {
	"dawn": ["town_day", Color(1.0, 0.82, 0.78)],
	"day": ["town_day", Color(1, 1, 1)],
	"dusk": ["town_day", Color(0.85, 0.6, 0.6)],
	"night": ["town", Color(1, 1, 1)],
}
# Who walks the square at each time of day: [sprite, from x, to x, y]
const WALKERS := {
	"dawn": [["villager_farmer", 380, 600, 430], ["villager_woman", 120, 360, 410]],
	"day": [["villager_farmer", 380, 600, 430], ["villager_woman", 120, 360, 410]],
	"dusk": [["villager_woman", 140, 380, 410], ["villager_guard", 400, 600, 430]],
	"night": [["villager_guard", 380, 620, 430]],
}
var _building_marks := {}


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	add_child(UI.full_rect(bg))
	var art := TextureRect.new()
	_art = art
	art.texture = load("res://assets/backgrounds/town.png")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.full_rect(art))
	_scene_layer = Control.new()
	_scene_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.full_rect(_scene_layer))
	_build_scene_fx()

	# Header
	var title := UI.label("Ashfall", 34, UI.TEXT)
	title.position = Vector2(24, 12)
	_shadow(title)
	add_child(title)
	_embers = UI.label("", 18, Color("#e08a3c"))
	_embers.position = Vector2(170, 24)
	_shadow(_embers)
	add_child(_embers)
	_fire_line = UI.wrap_label("", 14, Color("#d8c8f0"), 480)
	_fire_line.position = Vector2(150, 60)
	_shadow(_fire_line)
	add_child(_fire_line)
	var menu := UI.button("Menu", func(): get_tree().change_scene_to_file(TITLE_SCENE))
	menu.position = Vector2(1180, 16)
	menu.custom_minimum_size = Vector2(80, 36)
	add_child(menu)

	# Right-hand panel: results, tabs and the road out of town.
	var side := UI.panel(UI.BORDER, 1)
	side.position = Vector2(664, 64)
	side.size = Vector2(596, 576)
	add_child(side)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	side.add_child(root)
	_time_box = HBoxContainer.new()
	_time_box.add_theme_constant_override("separation", 8)
	root.add_child(_time_box)
	_result_box = VBoxContainer.new()
	root.add_child(_result_box)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 16)
	root.add_child(_tabs)
	_party_box = _tab("Party")
	_buildings = _tab("Buildings")
	_summon_box = _tab("Summon Roll")
	_quests = _tab("Quests")

	_go = UI.choice_button("", _set_out, UI.GOLD)
	_go.position = Vector2(664, 648)
	_go.size = Vector2(596, 56)
	add_child(_go)


func _shadow(l: Label) -> void:
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)


## Fire sparks, chimney smoke and a flickering glow.
func _build_scene_fx() -> void:
	var sparks := CPUParticles2D.new()
	sparks.position = FIRE + Vector2(0, -20)
	sparks.amount = 24
	sparks.lifetime = 2.2
	sparks.direction = Vector2(0, -1)
	sparks.spread = 25.0
	sparks.gravity = Vector2(0, -20)
	sparks.initial_velocity_min = 20.0
	sparks.initial_velocity_max = 55.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 4.0
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.75, 0.3, 1.0))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	sparks.color_ramp = g
	_scene_layer.add_child(sparks)
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(262, 210)
	smoke.amount = 14
	smoke.lifetime = 5.0
	smoke.direction = Vector2(0.4, -1)
	smoke.spread = 10.0
	smoke.gravity = Vector2(6, -4)
	smoke.initial_velocity_min = 8.0
	smoke.initial_velocity_max = 16.0
	smoke.scale_amount_min = 8.0
	smoke.scale_amount_max = 18.0
	var sg := Gradient.new()
	sg.set_color(0, Color(0.5, 0.45, 0.5, 0.35))
	sg.set_color(1, Color(0.5, 0.45, 0.5, 0.0))
	smoke.color_ramp = sg
	_scene_layer.add_child(smoke)
	# Firelight that breathes.
	var glow_tex := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.set_color(0, Color(1.0, 0.55, 0.2, 0.28))
	gg.set_color(1, Color(1.0, 0.55, 0.2, 0.0))
	glow_tex.gradient = gg
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(0.5, 0.0)
	var glow := TextureRect.new()
	glow.texture = glow_tex
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.size = Vector2(420, 260)
	glow.position = FIRE - glow.size / 2
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_layer.add_child(glow)
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.6, 0.35)
	tw.tween_property(glow, "modulate:a", 1.0, 0.25)
	tw.tween_property(glow, "modulate:a", 0.8, 0.3)


## Buildings you can tap (dark and ruined until built), plus every owned hero in the square.
func _refresh_scene() -> void:
	for c in _scene_layer.get_children():
		if c.has_meta("dynamic"):
			c.queue_free()
	for b in profile.town["buildings"]:
		var id: String = b["id"]
		if not TOWN_BUILDINGS.has(id):
			continue
		var r: Rect2 = TOWN_BUILDINGS[id]
		var rect := Rect2(r.position * ART_SCALE, r.size * ART_SCALE)
		var lv := profile.level(id)
		var spot := Button.new()
		spot.set_meta("dynamic", true)
		spot.flat = true
		spot.position = rect.position
		spot.size = rect.size
		spot.tooltip_text = "%s (Lv %d/%d)\n%s" % [b["name"], lv, b["costs"].size(), b["desc"]]
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(1, 0.8, 0.4, 0.12)
		hover.border_color = UI.GOLD
		hover.set_border_width_all(2)
		spot.add_theme_stylebox_override("hover", hover)
		spot.add_theme_stylebox_override("pressed", hover)
		spot.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		spot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		spot.pressed.connect(func(): _tabs.current_tab = 1; Sfx.play(self, "click"))
		if lv == 0:
			# Not built yet: the building stands dark and ruined.
			var dark := ColorRect.new()
			dark.color = Color(0.02, 0.01, 0.04, 0.62)
			dark.size = rect.size
			dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			spot.add_child(dark)
		_scene_layer.add_child(spot)
		var sign := UI.label(("%s\nLv %d" % [b["name"].split(" ")[-1], lv]) if lv > 0 else "%s\n(ruined)" % b["name"].split(" ")[-1], 11,
			UI.GOLD if lv > 0 else UI.DIM)
		sign.set_meta("dynamic", true)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.position = Vector2(rect.position.x - 10, rect.end.y + 2)
		sign.size = Vector2(rect.size.x + 20, 28)
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_shadow(sign)
		_scene_layer.add_child(sign)
	var US = load("res://scripts/ui/unit_sprite.gd")
	# Villagers going about their day (only the watch is out at night).
	for w in WALKERS[profile.time_name()]:
		var v: Control = US.create(w[0], 96, false)
		v.set_meta("dynamic", true)
		v.position = Vector2(w[1], w[3])
		_scene_layer.add_child(v)
		var speed := 38.0
		var dur: float = abs(float(w[2]) - float(w[1])) / speed
		var tw := v.create_tween().set_loops()
		tw.tween_callback(func(): v.set_facing(1))
		tw.tween_property(v, "position:x", float(w[2]), dur)
		tw.tween_interval(randf_range(0.5, 2.0))
		tw.tween_callback(func(): v.set_facing(-1))
		tw.tween_property(v, "position:x", float(w[1]), dur)
		tw.tween_interval(randf_range(0.5, 2.0))
	# Companions rest near the fire.
	var pet_spots := [Vector2(24, 646), Vector2(170, 652), Vector2(520, 404)]
	var shown := 0
	for pid in profile.owned_pets:
		if shown >= pet_spots.size():
			break
		var pet: Control = US.create(pid, 64, shown % 2 == 1)
		pet.set_meta("dynamic", true)
		pet.position = pet_spots[shown]
		_scene_layer.add_child(pet)
		shown += 1
	# Heroes: the chosen party warms itself at the fire; the rest wander the square.
	var idle_i := 0
	for id in profile.owned_heroes:
		var spot_pos: Vector2
		var face_left := false
		var pi := profile.party.find(id)
		if pi >= 0 and pi < PARTY_SPOTS.size():
			spot_pos = PARTY_SPOTS[pi]
			face_left = spot_pos.x > FIRE.x
		elif idle_i < IDLE_SPOTS.size():
			spot_pos = IDLE_SPOTS[idle_i]
			idle_i += 1
			face_left = true
		else:
			continue
		var sp: Control = US.create(id, 96, face_left)
		sp.set_meta("dynamic", true)
		sp.position = spot_pos
		_scene_layer.add_child(sp)
		var nm := UI.label(String(id).capitalize(), 12, UI.TEXT if pi >= 0 else UI.DIM)
		nm.set_meta("dynamic", true)
		nm.position = spot_pos + Vector2(0, 92)
		nm.size = Vector2(96, 16)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_shadow(nm)
		_scene_layer.add_child(nm)


func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	return box


func _set_out() -> void:
	if profile.party.size() != 3 and not Profile.has_saved_run():
		return
	last_result = {}
	get_tree().change_scene_to_file(GAME_SCENE)


func _clear(box: Control) -> void:
	for c in box.get_children():
		c.queue_free()


func _hero_def(id: String) -> Dictionary:
	for h in heroes_db:
		if h["id"] == id:
			return h
	return {}


func _refresh() -> void:
	_embers.text = "Soul Embers %d    Grave Dice %d" % [profile.embers, profile.grave_dice]
	var tod := profile.time_name()
	_art.texture = load("res://assets/backgrounds/%s.png" % TIME_LOOK[tod][0])
	_art.modulate = TIME_LOOK[tod][1]
	_refresh_time_box()
	_refresh_scene()
	var speaker := _hero_def(profile.party[0] if not profile.party.is_empty() else "varek")
	_fire_line.text = "At the fire, %s stares into the embers: \"%s\"" % [speaker.get("name", "?"), speaker.get("lore", "")]
	_clear(_result_box)
	if not last_result.is_empty():
		var t := "Your last journey earned %d Soul Embers and %d Grave Dice." % [int(last_result["embers"]), int(last_result.get("dice", 0))]
		for q in last_result["quests"]:
			t += "   Quest complete: %s (+%d)" % [q["name"], int(q["reward"])]
		_result_box.add_child(UI.wrap_label(t, 14, UI.GOLD, 560))
	var saved := Profile.has_saved_run()
	_go.text = "Continue your journey" if saved else ("Set out on the Hollow Road" if profile.party.size() == 3 else "Choose 3 heroes to set out")
	_go.disabled = not saved and profile.party.size() != 3
	_refresh_party()
	_refresh_buildings()
	_refresh_summon()
	_refresh_quests()


func _refresh_time_box() -> void:
	_clear(_time_box)
	var t := profile.time_name()
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var colors := {"dawn": Color("#f0a890"), "day": Color("#f4e08a"), "dusk": Color("#d08aa0"), "night": Color("#9fb4ff")}
	info.add_child(UI.label("Time: %s" % Profile.TIME_NAMES[t], 17, colors[t]))
	info.add_child(UI.wrap_label(Profile.TIME_EFFECTS[t], 12, UI.DIM, 380))
	_time_box.add_child(info)
	var next: String = Profile.TIMES[(Profile.TIMES.find(t) + 1) % Profile.TIMES.size()]
	var wait := UI.button("Wait until %s" % Profile.TIME_NAMES[next], func(): profile.advance_time(); Sfx.play(self, "fate"); _refresh(), 14)
	wait.custom_minimum_size = Vector2(170, 40)
	wait.disabled = Profile.has_saved_run()
	wait.tooltip_text = "Time passes for free. Your journey begins at this time of day."
	_time_box.add_child(wait)


func _refresh_party() -> void:
	_clear(_party_box)
	_party_box.add_child(UI.label("Choose 3 heroes (%d/3). Tap to add or remove." % profile.party.size(), 15, UI.DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_party_box.add_child(grid)
	for h in heroes_db:
		var id: String = h["id"]
		var owned: bool = id in profile.owned_heroes
		var chosen: bool = id in profile.party
		var text := "%s  (%s)\nHP %d   Skill: %s\n%s" % [h["name"], h["role"], int(h["hp"]), h["skill"]["name"],
			" ".join(h["faces"].map(UI.face_short))] if owned else "???\nNot yet summoned\n(Summon Roll tab)"
		var b := UI.choice_button(text, func(): _toggle_party(id), UI.GOLD if chosen else UI.BORDER, owned)
		b.custom_minimum_size = Vector2(276, 112)
		if owned:
			b.icon = load("res://scripts/ui/unit_sprite.gd").portrait(id)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 64)
		b.add_theme_font_size_override("font_size", 14)
		grid.add_child(b)
	# Curse level (opt-in difficulty).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_party_box.add_child(row)
	row.add_child(UI.label("Curse level: %d / %d unlocked  " % [profile.curse, profile.max_curse()], 16,
		UI.BLOOD if profile.curse > 0 else UI.TEXT))
	var minus := UI.button(" - ", func(): profile.set_curse(profile.curse - 1); _refresh())
	minus.disabled = profile.curse <= 0
	row.add_child(minus)
	var plus := UI.button(" + ", func(): profile.set_curse(profile.curse + 1); _refresh())
	plus.disabled = profile.curse >= profile.max_curse()
	row.add_child(plus)
	_party_box.add_child(UI.wrap_label("+25% Soul Embers per Curse level. Beat a level to unlock the next.", 13, UI.DIM, 540))
	var Run = load("res://scripts/core/run.gd")
	for i in Run.CURSE_RULES.size():
		var active: bool = i < profile.curse
		_party_box.add_child(UI.wrap_label(("[active] " if active else "") + Run.CURSE_RULES[i], 13, UI.BLOOD if active else UI.DIM, 540))


func _toggle_party(id: String) -> void:
	if id in profile.party:
		profile.party.erase(id)
	elif profile.party.size() < 3:
		profile.party.append(id)
	profile.save()
	Sfx.play(self, "click")
	_refresh()


func _refresh_buildings() -> void:
	_clear(_buildings)
	for b in profile.town["buildings"]:
		var id: String = b["id"]
		var lv := profile.level(id)
		var cost := profile.next_cost(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UI.label("%s   Lv %d/%d" % [b["name"], lv, b["costs"].size()], 17, UI.GOLD if lv > 0 else UI.TEXT))
		info.add_child(UI.wrap_label(b["desc"], 13, UI.DIM, 340))
		row.add_child(info)
		var btn := UI.button("MAX" if cost < 0 else "Build (%d Embers)" % cost, func(): profile.upgrade(id); Sfx.play(self, "fate"); _refresh())
		btn.disabled = not profile.can_upgrade(id)
		btn.custom_minimum_size = Vector2(170, 44)
		row.add_child(btn)
		_buildings.add_child(row)


func _refresh_summon() -> void:
	_clear(_summon_box)
	var s: Dictionary = profile.summon
	_summon_box.add_child(UI.wrap_label("Roll the Bone Dice of the Crossroads. Paid only with Grave Dice earned on the road (1 per journey, +1 per elite, +2 per victory, +1 per quest, +1 at night). No other currency, ever.", 13, UI.TEXT, 540))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_summon_box.add_child(row)
	var labels := {"heroes": "Heroes", "relics": "Relics", "pets": "Companions"}
	for banner in Profile.BANNERS:
		var left := profile.locked_in(banner).size()
		var bb := UI.choice_button("%s\n%s" % [labels[banner], ("%d sealed" % left) if left > 0 else "complete"],
			func(): _banner = banner; _reveal = {}; _refresh_summon(), UI.GOLD if banner == _banner else UI.BORDER)
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bb.custom_minimum_size = Vector2(0, 56)
		row.add_child(bb)
	var info: Dictionary = s["banners"][_banner]
	_summon_box.add_child(UI.label(info["name"], 18, UI.GOLD))
	_summon_box.add_child(UI.wrap_label("%s  Each roll: %d%% something new, otherwise %d Soul Embers. Guaranteed new within %d rolls (now %d/%d)." % [
		info["desc"], int(s["new_chance"]), int(s["embers_amount"]), int(s["pity"]), profile.pity_count(_banner), int(s["pity"])], 13, UI.DIM, 540))
	var sealed := profile.locked_in(_banner)
	if sealed.is_empty():
		_summon_box.add_child(UI.label("Everything in this banner is yours.", 14, UI.GREEN))
	else:
		_summon_box.add_child(UI.wrap_label("Still sealed: " + ", ".join(sealed.map(func(x): return "???")), 13, UI.DIM, 540))
	var b := UI.choice_button("Roll  (%d Grave Dice)" % int(s["cost"]), _do_summon, UI.GOLD, profile.can_summon(_banner))
	b.custom_minimum_size = Vector2(0, 52)
	_summon_box.add_child(b)
	if not _reveal.is_empty():
		_summon_box.add_child(_reveal_card(_reveal))


## The prize, shown with its picture.
func _reveal_card(r: Dictionary) -> Control:
	var panel := UI.panel(UI.GOLD if r["new"] else UI.BORDER, 2)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)
	var pic: Control
	var US = load("res://scripts/ui/unit_sprite.gd")
	match r["kind"]:
		"hero", "pet":
			pic = US.create(r["id"], 96, false)
		"relic":
			var tr := TextureRect.new()
			var w: Array = GameData.load_weapons().filter(func(x): return x["id"] == r["id"])
			tr.texture = UI.face_icon(w[0]["faces"][0]["type"]) if not w.is_empty() else null
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.custom_minimum_size = Vector2(96, 96)
			pic = tr
		_:
			var l := UI.label("+%d" % int(profile.summon["embers_amount"]), 30, Color("#e08a3c"))
			l.custom_minimum_size = Vector2(96, 96)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pic = l
	hb.add_child(pic)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.add_child(UI.label(("NEW!  " if r["new"] else "") + r["name"], 20, UI.GOLD if r["new"] else UI.TEXT))
	txt.add_child(UI.wrap_label(r["text"], 13, Color("#d8c8f0"), 400))
	hb.add_child(txt)
	# Pop-in reveal.
	panel.pivot_offset = Vector2(280, 60)
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate = Color(3, 3, 3, 0)
	var tw := panel.create_tween()
	tw.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.18).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.1)
	return panel


func _do_summon() -> void:
	var r := profile.summon_roll(_rng, _banner)
	if r.is_empty():
		return
	_reveal = r
	Sfx.play(self, "triple" if r.get("new", false) else "dice")
	_refresh()


func _refresh_quests() -> void:
	_clear(_quests)
	for q in profile.quests:
		var done: bool = q["id"] in profile.quests_done
		var line := "%s %s  (%d/%d)  +%d Embers" % ["[done]" if done else "-", q["name"], profile.quest_progress(q), int(q["goal"]), int(q["reward"])]
		_quests.add_child(UI.label(line, 15, UI.GREEN if done else UI.TEXT))
		_quests.add_child(UI.wrap_label("     " + q["desc"], 12, UI.DIM, 540))
