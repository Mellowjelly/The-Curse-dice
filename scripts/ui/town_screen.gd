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
	Sfx.music(self, "town")


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
var _collection: VBoxContainer
var _storage: VBoxContainer
var _forge: VBoxContainer
var _forge_slot := "weapon"
var _dialog: PanelContainer
var _dialog_npc := ""
var _dialog_reveal: Dictionary = {}
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
# Where each villager walks: [from x, to x, y]. Who is out depends on the time of day (villagers.json "times").
const LANES := {
	"tobin": [380, 600, 430], "marla": [120, 360, 410], "pip": [150, 290, 606], "hesk": [400, 620, 424],
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
	_collection = _tab("Collection")
	_forge = _tab("Forge")
	_buildings = _tab("Buildings")
	_summon_box = _tab("Summon")
	_quests = _tab("Quests")
	_storage = _tab("Storage")

	# Dialogue box for talking to villagers (over the town scene).
	_dialog = UI.panel(UI.GOLD, 2)
	_dialog.position = Vector2(20, 400)
	_dialog.size = Vector2(624, 300)
	add_child(_dialog)
	_dialog.hide()

	_go = UI.choice_button("", _set_out, UI.GOLD)
	_go.position = Vector2(664, 648)
	_go.size = Vector2(292, 56)
	add_child(_go)
	var explore := UI.choice_button("Explore the Cursed Isle", func(): last_result = {}; get_tree().change_scene_to_file("res://scenes/world.tscn"), Color("#7fd0c0"))
	explore.position = Vector2(968, 648)
	explore.size = Vector2(292, 56)
	explore.tooltip_text = "The open world: 7 countries, minerals to gather, monsters roaming."
	add_child(explore)


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
		spot.pressed.connect(func(): _tabs.current_tab = 3 if id != "smithy" else 2; Sfx.play(self, "click"))
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
	# Villagers going about their day. Tap one to talk.
	for vdef in profile.villagers:
		var vid: String = vdef["id"]
		if not profile.npc_is_out(vid) or not LANES.has(vid):
			continue
		var w: Array = [vdef["sprite"]] + LANES[vid]
		var v: Control = US.create(w[0], 96, false)
		v.set_meta("dynamic", true)
		v.position = Vector2(w[1], w[3])
		_scene_layer.add_child(v)
		var talk := Button.new()
		talk.flat = true
		talk.size = Vector2(70, 96)
		talk.position = Vector2(13, 0)
		talk.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		talk.tooltip_text = "%s %s" % [vdef["name"], vdef["title"]]
		for st in ["normal", "hover", "pressed", "focus"]:
			talk.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		talk.pressed.connect(func(): _open_dialog(vid))
		v.add_child(talk)
		var mark := _npc_marker(vid)
		if mark != null:
			mark.position = Vector2(36, -18)
			v.add_child(mark)
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
	var pet_spots := [Vector2(24, 646), Vector2(520, 404), Vector2(588, 412)]
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
	_embers.text = "Soul Embers %d    Grave Dice %d    Star Dust %d" % [profile.embers, profile.grave_dice, profile.star_dust]
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
		if last_result.has("banked"):
			t = "Back from the Cursed Isle. Stored: " + last_result["banked"]
		for q in last_result["quests"]:
			t += "   Quest complete: %s (+%d)" % [q["name"], int(q["reward"])]
		_result_box.add_child(UI.wrap_label(t, 14, UI.GOLD, 560))
	var saved := Profile.has_saved_run()
	_go.text = "Continue your journey" if saved else ("Set out on the Hollow Road" if profile.party.size() == 3 else "Choose 3 heroes to set out")
	_go.disabled = not saved and profile.party.size() != 3
	_refresh_party()
	_refresh_collection()
	_refresh_storage()
	_refresh_forge()
	_refresh_buildings()
	if _dialog.visible:
		_render_dialog()
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
		if owned:
			text = "[%s] %s  %s\n%s" % [h.get("grade", "SR"), UI.stars_text(profile.star("hero", id)), String(h.get("element", "")).capitalize(), text]
		var b := UI.choice_button(text, func(): _toggle_party(id), UI.GOLD if chosen else UI.grade_color(h.get("grade", "SR")) if owned else UI.BORDER, owned)
		b.custom_minimum_size = Vector2(276, 140)
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
	var grade: String = r.get("grade", "")
	if grade == "" and r["kind"] in ["hero", "pet", "relic"]:
		grade = profile.item_def(r["kind"], r["id"]).get("grade", "SR")
	var panel := UI.panel(UI.grade_color(grade) if grade != "" else UI.BORDER, 3)
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
	txt.add_child(UI.label(("NEW!  " if r["new"] else "") + (("[%s] " % grade) if grade != "" else "") + r["name"], 20,
		UI.grade_color(grade) if grade != "" else UI.TEXT))
	txt.add_child(UI.wrap_label(r["text"], 13, Color("#d8c8f0"), 260))
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


# ---------------------------------------------------------------- villagers: talking

## "!" = has a request for you, "?" = your request is done (come claim), "..." = in progress.
func _npc_marker(vid: String) -> Label:
	var req := profile.npc_request(vid)
	if req.is_empty():
		return null
	var text := "!"
	var color := UI.GOLD
	if profile.is_request_done(vid):
		text = "?"
		color = UI.GREEN
	elif profile.is_request_active(vid):
		text = "..."
		color = UI.DIM
	var l := UI.label(text, 26, color)
	_shadow(l)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := l.create_tween().set_loops()
	tw.tween_property(l, "position:y", -24.0, 0.5)
	tw.tween_property(l, "position:y", -18.0, 0.5)
	return l


func _open_dialog(vid: String) -> void:
	_dialog_npc = vid
	_dialog_reveal = {}
	Sfx.play(self, "click")
	_dialog.show()
	_render_dialog()


func _render_dialog() -> void:
	for c in _dialog.get_children():
		c.queue_free()
	var v := profile.npc(_dialog_npc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	_dialog.add_child(hb)
	var US = load("res://scripts/ui/unit_sprite.gd")
	hb.add_child(US.create(v["sprite"], 96, false))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	hb.add_child(box)
	box.add_child(UI.label("%s, %s" % [v["name"], v["title"]], 18, UI.GOLD))
	var req := profile.npc_request(_dialog_npc)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	if not _dialog_reveal.is_empty():
		box.add_child(UI.wrap_label("\"%s\"" % profile.npc(_dialog_npc)["requests"][int(profile.npc_step.get(_dialog_npc, 1)) - 1]["done"], 14, UI.TEXT, 460))
		box.add_child(_reveal_card(_dialog_reveal))
	elif req.is_empty():
		box.add_child(UI.wrap_label("\"You have done so much for us. Ashfall will not forget you.\"", 14, UI.TEXT, 460))
	elif profile.is_request_done(_dialog_npc):
		box.add_child(UI.wrap_label("\"You did it? Truly?\"", 14, UI.TEXT, 460))
		box.add_child(UI.label("%s  -  done!" % req["title"], 15, UI.GREEN))
		buttons.add_child(_dialog_button("Claim reward", _claim_dialog))
	elif profile.is_request_active(_dialog_npc):
		box.add_child(UI.wrap_label("\"%s\"" % v["greeting"][randi() % v["greeting"].size()], 14, UI.TEXT, 460))
		box.add_child(UI.label("%s:  %d / %d" % [req["title"], profile.request_progress(_dialog_npc), int(req["goal"]["amount"])], 15, UI.GOLD))
		box.add_child(UI.wrap_label(req["ask"], 12, UI.DIM, 460))
	else:
		box.add_child(UI.wrap_label("\"%s\"" % req["ask"], 14, UI.TEXT, 460))
		box.add_child(UI.label("Request: " + req["title"], 15, UI.GOLD))
		box.add_child(_reward_line(req["reward"]))
		buttons.add_child(_dialog_button("I will help", func(): profile.accept_request(_dialog_npc); Sfx.play(self, "fate"); _refresh()))
	var bye := UI.button("Goodbye", func(): _dialog.hide(); _refresh(), 14)
	bye.custom_minimum_size = Vector2(110, 40)
	buttons.add_child(bye)
	box.add_child(buttons)


func _dialog_button(text: String, action: Callable) -> Button:
	var b := UI.choice_button(text, action, UI.GOLD)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.custom_minimum_size = Vector2(180, 44)
	return b


func _reward_line(r: Dictionary) -> Control:
	var kind: String = r["kind"]
	if kind in ["hero", "pet", "relic"]:
		var d := profile.item_def(kind, r["id"])
		var grade: String = d.get("grade", "SR")
		return UI.label("Reward: [%s] %s (%s)" % [grade, d.get("name", r["id"]), {"hero": "hero", "pet": "companion", "relic": "relic weapon"}[kind]], 15, UI.grade_color(grade))
	var names := {"dust": "Star Dust", "dice": "Grave Dice", "embers": "Soul Embers"}
	return UI.label("Reward: %d %s" % [int(r["amount"]), names[kind]], 15, Color("#d8c8f0"))


func _claim_dialog() -> void:
	var r := profile.claim_request(_dialog_npc)
	if r.is_empty():
		return
	_dialog_reveal = r
	Sfx.play(self, "triple" if r.get("new", false) else "fate")
	_refresh()


# ---------------------------------------------------------------- collection: grades and stars

func _refresh_collection() -> void:
	_clear(_collection)
	_collection.add_child(UI.wrap_label("Upgrade your heroes, companions and relics with Soul Embers and Star Dust (from villagers' requests, journeys and duplicates). SR = purple, SSR = gold.", 13, UI.DIM, 540))
	_collection.add_child(UI.label("Star Dust: %d     Soul Embers: %d" % [profile.star_dust, profile.embers], 15, Color("#d8c8f0")))
	var sections := [["hero", "Heroes", GameData.load_heroes(), profile.owned_heroes],
		["pet", "Companions", GameData.load_pets(), profile.owned_pets],
		["relic", "Relics", GameData.load_weapons().filter(func(w): return w.get("locked", false)), profile.unlocked_weapons]]
	var US = load("res://scripts/ui/unit_sprite.gd")
	for sec in sections:
		var kind: String = sec[0]
		_collection.add_child(UI.label(sec[1], 18, UI.GOLD))
		for d in sec[2]:
			var id: String = d["id"]
			var owned: bool = id in sec[3]
			var grade: String = d.get("grade", "SR")
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var pic := TextureRect.new()
			pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			pic.stretch_mode = TextureRect.STRETCH_SCALE
			pic.custom_minimum_size = Vector2(48, 48)
			pic.texture = US.portrait(id) if kind != "relic" else UI.face_icon(d["faces"][0]["type"])
			pic.modulate = Color.WHITE if owned else Color(0, 0, 0, 0.8)
			row.add_child(pic)
			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if owned:
				var st := profile.star(kind, id)
				info.add_child(UI.label("[%s] %s   %s" % [grade, d["name"], UI.stars_text(st)], 15, UI.grade_color(grade)))
				var nxt := st + 1
				var desc: Array = profile.star_rules["desc"][kind]
				info.add_child(UI.wrap_label(("Next star: " + desc[st]) if nxt <= 5 else "Fully upgraded.", 12, UI.DIM, 330))
			else:
				info.add_child(UI.label("[%s] ???" % grade, 15, UI.DIM))
				info.add_child(UI.label("Not yet found (summon or villagers' rewards)", 12, UI.DIM))
			row.add_child(info)
			if owned:
				var cost := profile.star_cost(kind, id)
				var btn := UI.button("MAX" if cost.is_empty() else "Upgrade\n%d Embers + %d Dust" % [int(cost[0]), int(cost[1])],
					func(): if profile.upgrade_star(kind, id): Sfx.play(self, "triple"); _refresh(), 12)
				btn.disabled = not profile.can_upgrade_star(kind, id)
				btn.custom_minimum_size = Vector2(150, 44)
				row.add_child(btn)
			_collection.add_child(row)


# ---------------------------------------------------------------- storage: materials from the open world

func _refresh_storage() -> void:
	_clear(_storage)
	_storage.add_child(UI.wrap_label("Minerals you brought back from the Cursed Isle. Sell them at the Night Market for Soul Embers, or grind them into Star Dust.", 13, UI.DIM, 540))
	if profile.materials.is_empty():
		_storage.add_child(UI.label("Empty. Explore the Cursed Isle and gather minerals.", 15, UI.DIM))
		return
	var wdata: Dictionary = GameData.load_json("res://data/world.json")
	var info := _material_info()
	for id in profile.materials:
		var meta: Array = info.get(id, [id, 1, "?", false])
		var amount: int = int(profile.materials[id])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var pic := TextureRect.new()
		var ore_path := "res://assets/world/ore_%s.png" % id
		pic.texture = load(ore_path) if ResourceLoader.exists(ore_path) else load("res://assets/world/ore_depleted.png")
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.custom_minimum_size = Vector2(40, 40)
		if meta[3]:
			pic.modulate = Color(1.3, 0.9, 1.4)
		row.add_child(pic)
		var lab := VBoxContainer.new()
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_child(UI.label("%s x%d%s" % [meta[0], amount, "   (rare)" if meta[3] else ""], 15, Color("#b07cf0") if meta[3] else UI.TEXT))
		lab.add_child(UI.label("from %s   -   worth %d each" % [meta[2], meta[1]], 12, UI.DIM))
		row.add_child(lab)
		var sell_n: int = min(amount, 5)
		var sell := UI.button("Sell %d\n+%d Embers" % [sell_n, sell_n * meta[1]], func(): profile.trade_material(id, sell_n, "embers", meta[1]); Sfx.play(self, "click"); _refresh(), 12)
		sell.custom_minimum_size = Vector2(110, 40)
		row.add_child(sell)
		var dust_amount := int(floor(sell_n * meta[1] * float(wdata["trade"]["dust_per_value"])))
		var grind := UI.button("Grind %d\n+%d Dust" % [sell_n, dust_amount], func(): profile.trade_material(id, sell_n, "dust", meta[1]); Sfx.play(self, "fate"); _refresh(), 12)
		grind.custom_minimum_size = Vector2(100, 40)
		grind.disabled = dust_amount <= 0
		row.add_child(grind)
		_storage.add_child(row)


## id -> [name, value, where it comes from, rare?] for every material on the Cursed Isle.
func _material_info() -> Dictionary:
	var wdata: Dictionary = GameData.load_json("res://data/world.json")
	var info := {}
	for c in wdata["countries"]:
		info[c["mineral"]["id"]] = [c["mineral"]["name"], int(c["mineral"]["value"]), c["name"], false]
		info[c["rare"]["id"]] = [c["rare"]["name"], int(c["rare"]["value"]), c["name"], true]
		info[c["wood"]["id"]] = [c["wood"]["name"], int(c["wood"]["value"]), c["name"], false]
	for h in wdata["hides"]:
		info[h] = [wdata["hides"][h][0], int(wdata["hides"][h][1]), "beasts and bosses", int(wdata["hides"][h][1]) >= 25]
	return info


# ---------------------------------------------------------------- the Forge: craft and equip gear

func _refresh_forge() -> void:
	_clear(_forge)
	var info := _material_info()
	_forge.add_child(UI.wrap_label("The Gravesmith turns ore, wood and hides into gear. A crafted weapon becomes the hero's dice faces 5-6; armour adds max HP and a shield at the start of every fight. Gear works on the road and on the Cursed Isle.", 13, UI.DIM, 540))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for slot in ["weapon", "armor", "armory"]:
		var label: String = {"weapon": "Weapons", "armor": "Armour", "armory": "Armory (%d)" % profile.gear.size()}[slot]
		var b := UI.choice_button(label, func(): _forge_slot = slot; _refresh_forge(), UI.GOLD if slot == _forge_slot else UI.BORDER)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		tabs.add_child(b)
	_forge.add_child(tabs)
	if _forge_slot == "armory":
		_refresh_armory()
		return
	for r in profile.recipes():
		if r["slot"] != _forge_slot:
			continue
		var grade: String = r["grade"]
		var box := VBoxContainer.new()
		var head := HBoxContainer.new()
		var title := UI.label("[%s] %s" % [grade, r["name"]], 15, UI.grade_color(grade))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(title)
		var effect := ""
		if r["slot"] == "weapon":
			effect = "faces: " + "  ".join(r["faces"].map(UI.face_short))
		else:
			effect = "+%d max HP, +%d shield each fight" % [int(r["hp"]), int(r["shield"])]
		head.add_child(UI.label(effect, 13, UI.TEXT))
		box.add_child(head)
		var need: Array[String] = []
		for m in r["materials"]:
			var have := int(profile.materials.get(m, 0))
			var want := int(r["materials"][m])
			need.append("%s %d/%d" % [info.get(m, [m])[0], have, want])
		need.append("Embers %d/%d" % [profile.embers, int(r["embers"])])
		var row := HBoxContainer.new()
		row.add_child(UI.wrap_label("   ".join(need), 12, UI.GREEN if profile.can_craft(r["id"]) else UI.DIM, 400))
		var craft := UI.button("Craft", func(): if profile.craft(r["id"]) >= 0: Sfx.play(self, "triple"); _refresh(), 13)
		craft.disabled = not profile.can_craft(r["id"])
		craft.custom_minimum_size = Vector2(80, 34)
		row.add_child(craft)
		box.add_child(row)
		_forge.add_child(box)
		_forge.add_child(HSeparator.new())


func _refresh_armory() -> void:
	if profile.gear.is_empty():
		_forge.add_child(UI.label("Nothing crafted yet.", 14, UI.DIM))
		return
	var heroes: Array = profile.party
	for g in profile.gear:
		var uid := int(g["uid"])
		var r := profile.recipe(g["recipe"])
		var owner := profile.gear_owner(uid)
		var row := VBoxContainer.new()
		row.add_child(UI.label("[%s] %s  -  %s" % [r["grade"], r["name"], ("worn by " + owner.capitalize()) if owner != "" else "in the chest"], 14,
			UI.grade_color(r["grade"])))
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 6)
		for hid in heroes:
			var b := UI.button(("On " if owner == hid else "Give ") + String(hid).capitalize(), func(): profile.equip_gear(hid, r["slot"], uid); Sfx.play(self, "click"); _refresh(), 12)
			b.disabled = owner == hid
			b.custom_minimum_size = Vector2(110, 30)
			btns.add_child(b)
		if owner != "":
			var off := UI.button("Take off", func(): profile.equip_gear(owner, r["slot"], -1); _refresh(), 12)
			off.custom_minimum_size = Vector2(90, 30)
			btns.add_child(off)
		row.add_child(btns)
		_forge.add_child(row)
