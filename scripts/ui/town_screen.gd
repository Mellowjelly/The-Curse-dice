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
var _explore: Button
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
	var menu := UI.button(tr("Menu"), func(): get_tree().change_scene_to_file(TITLE_SCENE))
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
	_party_box = _tab(tr("Party"))
	_collection = _tab(tr("Collection"))
	_forge = _tab(tr("Forge"))
	_buildings = _tab(tr("Buildings"))
	_summon_box = _tab(tr("Summon"))
	_quests = _tab(tr("Quests"))
	_storage = _tab(tr("Storage"))

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
	var explore := UI.choice_button(tr("Explore the Cursed Isle"), func(): last_result = {}; get_tree().change_scene_to_file("res://scenes/world.tscn"), Color("#7fd0c0"))
	_explore = explore
	explore.position = Vector2(968, 648)
	explore.size = Vector2(292, 56)
	explore.tooltip_text = tr("The open world: 7 countries, minerals to gather, monsters roaming.")
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
		spot.tooltip_text = tr("%s (Lv %d/%d)\n%s") % [tr(b["name"]), lv, b["costs"].size(), tr(b["desc"])]
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
		var sign := UI.label((tr("%s\nLv %d") % [tr(b["name"].split(" ")[-1]), lv]) if lv > 0 else tr("%s\n(ruined)") % tr(b["name"].split(" ")[-1]), 11,
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
		talk.tooltip_text = "%s %s" % [tr(vdef["name"]), tr(vdef["title"])]
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
	_embers.text = tr("Soul Embers %d    Grave Dice %d    Star Dust %d") % [profile.embers, profile.grave_dice, profile.star_dust]
	var tod := profile.time_name()
	_art.texture = load("res://assets/backgrounds/%s.png" % TIME_LOOK[tod][0])
	_art.modulate = TIME_LOOK[tod][1]
	_refresh_time_box()
	_refresh_scene()
	var speaker := _hero_def(profile.party[0] if not profile.party.is_empty() else "varek")
	_fire_line.text = tr("At the fire, %s stares into the embers: \"%s\"") % [tr(speaker.get("name", "?")), tr(speaker.get("lore", ""))]
	_clear(_result_box)
	if not last_result.is_empty():
		var t := tr("Your last journey earned %d Soul Embers and %d Grave Dice.") % [int(last_result["embers"]), int(last_result.get("dice", 0))]
		if last_result.has("banked"):
			t = tr("Back from the Cursed Isle. Stored: ") + last_result["banked"]
		for q in last_result["quests"]:
			t += tr("   Quest complete: %s (+%d)") % [tr(q["name"]), int(q["reward"])]
		_result_box.add_child(UI.wrap_label(t, 14, UI.GOLD, 560))
		var bonus: Dictionary = last_result.get("boss_bonus", {})
		if not bonus.is_empty():
			_result_box.add_child(UI.wrap_label(tr("The road remembers today's first fallen boss: +%d Soul Embers, +%d Grave Die (included above).") % [
				int(bonus["embers"]), int(bonus["dice"])], 13, Color("#d08a6a"), 560))
	if profile.max_curse() > 0 and profile.curse == 0:
		_result_box.add_child(UI.wrap_label(tr("The Bishop has fallen. The road can be walked under a Curse now: harder, but +25% Soul Embers per level (Party tab)."), 13, UI.BLOOD, 560))
	var saved := Profile.has_saved_run()
	_go.text = tr("Continue your journey") if saved else (tr("Set out on the Hollow Road") if profile.party.size() == 3 else tr("Choose 3 heroes to set out"))
	_go.disabled = not saved and profile.party.size() != 3
	_refresh_unlocks()
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
	info.add_child(UI.label(tr("Time: %s") % tr(Profile.TIME_NAMES[t]), 17, colors[t]))
	info.add_child(UI.wrap_label(tr(Profile.TIME_EFFECTS[t]), 12, UI.DIM, 380))
	var omen := String(profile.road_boss().get("omen", ""))
	if omen != "":
		info.add_child(UI.wrap_label(tr(omen), 12, Color("#d08a6a"), 380))  # 3.4: which boss waits on the road now
	if profile.stat("wins") > 0:
		var daily: Dictionary = profile.town.get("road_boss_daily", {})
		var ready := profile.road_bonus_ready()
		info.add_child(UI.wrap_label((tr("Today's first road boss pays +%d Soul Embers, +%d Grave Die.") % [int(daily.get("embers", 0)), int(daily.get("dice", 0))])
			if ready else tr("Today's road-boss bonus is taken. It returns at Dawn."), 12, Color("#d08a6a") if ready else UI.DIM, 380))
	_time_box.add_child(info)
	var next: String = Profile.TIMES[(Profile.TIMES.find(t) + 1) % Profile.TIMES.size()]
	var wait := UI.button(tr("Wait until %s") % tr(Profile.TIME_NAMES[next]), func(): profile.advance_time(); Sfx.play(self, "fate"); _refresh(), 14)
	wait.custom_minimum_size = Vector2(170, 40)
	wait.disabled = Profile.has_saved_run()
	wait.tooltip_text = tr("Time passes for free. Your journey begins at this time of day.")
	_time_box.add_child(wait)


func _refresh_party() -> void:
	_clear(_party_box)
	_party_box.add_child(UI.label(tr("Choose 3 heroes (%d/3). Tap to add or remove.") % profile.party.size(), 15, UI.DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_party_box.add_child(grid)
	for h in heroes_db:
		var id: String = h["id"]
		var owned: bool = id in profile.owned_heroes
		var chosen: bool = id in profile.party
		var text := tr("%s  (%s)\nHP %d   Skill: %s\n%s") % [tr(h["name"]), tr(h["role"]), int(h["hp"]), tr(h["skill"]["name"]),
			" ".join(h["faces"].map(UI.face_short))] if owned else (tr("???\nNot yet summoned\n(Summon Roll tab)") if profile.feature_unlocked("summon") else tr("???\nA hero still lost\nin the dice"))
		if owned:
			text = "[%s] %s  %s\n%s" % [h.get("grade", "SR"), UI.stars_text(profile.star("hero", id)), String(h.get("element", "")).capitalize(), text]
		var b := UI.choice_button(text, func(): _toggle_party(id), UI.GOLD if chosen else UI.grade_color(h.get("grade", "SR")) if owned else UI.BORDER, owned)
		# 3.5: grow with long (Thai) text; Godot 4.3 buttons do not do it themselves.
		b.custom_minimum_size = Vector2(276, max(140.0, UI.wrapped_height(text, 14, 176 if owned else 240) + 28))
		if owned:
			b.icon = load("res://scripts/ui/unit_sprite.gd").portrait(id)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 64)
		b.add_theme_font_size_override("font_size", 14)
		grid.add_child(b)
	# Which companion walks the Cursed Isle with the party.
	if profile.feature_unlocked("isle") and profile.owned_pets.size() > 1:
		_party_box.add_child(UI.label(tr("Companion on the Cursed Isle:"), 15, UI.TEXT))
		var pets_row := HFlowContainer.new()
		pets_row.add_theme_constant_override("h_separation", 6)
		pets_row.add_theme_constant_override("v_separation", 6)
		for pid in profile.owned_pets:
			var chosen: bool = profile.isle_pet_id() == pid
			var pb := UI.choice_button(tr(profile.item_def("pet", pid).get("name", pid)), func(): profile.set_isle_pet(pid); Sfx.play(self, "click"); _refresh(), UI.GOLD if chosen else UI.BORDER)
			pb.autowrap_mode = TextServer.AUTOWRAP_OFF
			pb.custom_minimum_size = Vector2(0, 36)
			pets_row.add_child(pb)
		_party_box.add_child(pets_row)
	# Curse level (opt-in difficulty).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_party_box.add_child(row)
	row.add_child(UI.label(tr("Curse level: %d / %d unlocked  ") % [profile.curse, profile.max_curse()], 16,
		UI.BLOOD if profile.curse > 0 else UI.TEXT))
	var minus := UI.button(" - ", func(): profile.set_curse(profile.curse - 1); _refresh())
	minus.disabled = profile.curse <= 0
	row.add_child(minus)
	var plus := UI.button(" + ", func(): profile.set_curse(profile.curse + 1); _refresh())
	plus.disabled = profile.curse >= profile.max_curse()
	row.add_child(plus)
	_party_box.add_child(UI.wrap_label(tr("+25% Soul Embers per Curse level. Beat a level to unlock the next."), 13, UI.DIM, 540))
	var Run = load("res://scripts/core/run.gd")
	for i in Run.CURSE_RULES.size():
		var active: bool = i < profile.curse
		_party_box.add_child(UI.wrap_label((tr("[active] ") if active else "") + tr(Run.CURSE_RULES[i]), 13, UI.BLOOD if active else UI.DIM, 540))


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
		info.add_child(UI.label(tr("%s   Lv %d/%d") % [tr(b["name"]), lv, b["costs"].size()], 17, UI.GOLD if lv > 0 else UI.TEXT))
		info.add_child(UI.wrap_label(tr(b["desc"]), 13, UI.DIM, 340))
		row.add_child(info)
		var btn := _confirm_button(tr("MAX") if cost < 0 else tr("Build (%d Embers)") % cost, func(): if profile.upgrade(id): Sfx.play(self, "fate"); _toast(tr("%s is now level %d.") % [tr(b["name"]), profile.level(id)]); _refresh(), 16)
		btn.disabled = not profile.can_upgrade(id)
		btn.custom_minimum_size = Vector2(170, 44)
		row.add_child(btn)
		_buildings.add_child(row)


func _refresh_summon() -> void:
	_clear(_summon_box)
	var s: Dictionary = profile.summon
	_summon_box.add_child(UI.wrap_label(tr("Roll the Bone Dice of the Crossroads. Paid only with Grave Dice earned on the road (1 per journey, +1 per elite, +2 per victory, +1 per quest, +1 at night). No other currency, ever."), 13, UI.TEXT, 540))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_summon_box.add_child(row)
	var labels := {"heroes": tr("Heroes"), "relics": tr("Relics"), "pets": tr("Companions")}
	for banner in Profile.BANNERS:
		var left := profile.locked_in(banner).size()
		var bb := UI.choice_button("%s\n%s" % [labels[banner], (tr("%d sealed") % left) if left > 0 else "complete"],
			func(): _banner = banner; _reveal = {}; _refresh_summon(), UI.GOLD if banner == _banner else UI.BORDER)
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bb.custom_minimum_size = Vector2(0, 56)
		row.add_child(bb)
	var info: Dictionary = s["banners"][_banner]
	_summon_box.add_child(UI.label(tr(info["name"]), 18, UI.GOLD))
	_summon_box.add_child(UI.wrap_label(tr("%s  Each roll: %d%% something new, otherwise %d Soul Embers. Guaranteed new within %d rolls (now %d/%d).") % [
		tr(info["desc"]), int(s["new_chance"]), int(s["embers_amount"]), int(s["pity"]), profile.pity_count(_banner), int(s["pity"])], 13, UI.DIM, 540))
	var sealed := profile.locked_in(_banner)
	if sealed.is_empty():
		_summon_box.add_child(UI.label(tr("Everything in this banner is yours."), 14, UI.GREEN))
	else:
		_summon_box.add_child(UI.wrap_label(tr("Still sealed: ") + ", ".join(sealed.map(func(x): return "???")), 13, UI.DIM, 540))
	var b := UI.choice_button(tr("Roll  (%d Grave Dice)") % int(s["cost"]), _do_summon, UI.GOLD, profile.can_summon(_banner))
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
	txt.add_child(UI.label((tr("NEW!  ") if r["new"] else "") + (("[%s] " % grade) if grade != "" else "") + tr(r["name"]), 20,
		UI.grade_color(grade) if grade != "" else UI.TEXT))
	txt.add_child(UI.wrap_label(tr(r["text"]), 13, Color("#d8c8f0"), 260))
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
		var line := tr("%s %s  (%d/%d)  +%d Embers") % [tr("[done]") if done else "-", tr(q["name"]), profile.quest_progress(q), int(q["goal"]), int(q["reward"])]
		_quests.add_child(UI.label(line, 15, UI.GREEN if done else UI.TEXT))
		_quests.add_child(UI.wrap_label("     " + tr(q["desc"]), 12, UI.DIM, 540))
	_refresh_bestiary()


# ---------------------------------------------------------------- the Bestiary (v3.1): a page per monster killed

func _refresh_bestiary() -> void:
	var entries: Array = profile.bestiary_entries()
	var known := entries.filter(func(e): return e["known"]).size()
	var ready := entries.filter(func(e): return e["claimable"]).size()
	_tabs.set_tab_title(_quests.get_parent().get_index(), tr("Quests (%d!)") % ready if ready > 0 else tr("Quests"))
	_quests.add_child(UI.label(tr("Bestiary  (%d / %d pages)") % [known, entries.size()], 18, UI.GOLD))
	_quests.add_child(UI.wrap_label(tr("Every monster you defeat, on the road or the Isle, fills a page. Kill milestones pay Star Dust and Grave Dice."), 12, UI.DIM, 540))
	var US = load("res://scripts/ui/unit_sprite.gd")
	for e in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var pic := TextureRect.new()
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.custom_minimum_size = Vector2(40, 40)
		pic.texture = US.portrait(e["id"])
		pic.modulate = Color.WHITE if e["known"] else Color(0, 0, 0, 0.8)
		row.add_child(pic)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if e["known"]:
			var rank: String = "" if e["rank"] == "common" else "  [%s]" % String(e["rank"]).to_upper()
			info.add_child(UI.label("%s%s   x%d" % [tr(e["name"]), rank, int(e["kills"])], 15, UI.TEXT))
			info.add_child(UI.wrap_label(tr(e["lore"]), 12, UI.DIM, 330))
		else:
			info.add_child(UI.label("???", 15, UI.DIM))
			info.add_child(UI.label(tr("Not yet met."), 12, UI.DIM))
		if int(e["next_kills"]) > 0:
			var r: Dictionary = e["next_reward"]
			var names := {"dust": tr("Star Dust"), "dice": tr("Grave Dice"), "embers": tr("Soul Embers")}
			info.add_child(UI.label(tr("Next: %d kills (%d/%d) -> %d %s") % [int(e["next_kills"]), min(int(e["kills"]), int(e["next_kills"])), int(e["next_kills"]), int(r.get("amount", 0)), names.get(r["kind"], r["kind"])], 12, UI.GREEN if e["claimable"] else UI.DIM))
		row.add_child(info)
		if e["claimable"]:
			var id: String = e["id"]
			var btn := UI.button(tr("Claim"), func():
				var res := profile.claim_bestiary(id)
				if not res.is_empty():
					Sfx.play(self, "fate")
					_toast(tr("Bestiary: ") + tr(res["text"]))
				_refresh(), 13)
			btn.custom_minimum_size = Vector2(90, 40)
			row.add_child(btn)
		_quests.add_child(row)


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
	box.add_child(UI.label("%s, %s" % [tr(v["name"]), tr(v["title"])], 18, UI.GOLD))
	var req := profile.npc_request(_dialog_npc)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	if not _dialog_reveal.is_empty():
		box.add_child(UI.wrap_label("\"%s\"" % tr(profile.last_done_request(_dialog_npc).get("done", "")), 14, UI.TEXT, 460))
		box.add_child(_reveal_card(_dialog_reveal))
	elif req.is_empty():
		box.add_child(UI.wrap_label(tr("\"You have done so much for us. Ashfall will not forget you.\""), 14, UI.TEXT, 460))
	elif profile.is_request_done(_dialog_npc):
		box.add_child(UI.wrap_label(tr("\"You did it? Truly?\""), 14, UI.TEXT, 460))
		box.add_child(UI.label(tr("%s  -  done!") % tr(req["title"]), 15, UI.GREEN))
		buttons.add_child(_dialog_button(tr("Claim reward"), _claim_dialog))
	elif profile.is_request_active(_dialog_npc):
		box.add_child(UI.wrap_label("\"%s\"" % tr(v["greeting"][randi() % v["greeting"].size()]), 14, UI.TEXT, 460))
		box.add_child(UI.label("%s:  %d / %d" % [tr(req["title"]), profile.request_progress(_dialog_npc), int(req["goal"]["amount"])], 15, UI.GOLD))
		box.add_child(UI.wrap_label(tr(req["ask"]), 12, UI.DIM, 460))
		box.add_child(_reward_line(profile.request_reward(_dialog_npc)))
		if req["goal"]["scope"] == "deliver":
			box.add_child(UI.label(tr("Counts what is in your Storage. Handed over when you claim."), 12, UI.DIM))
	else:
		box.add_child(UI.wrap_label("\"%s\"" % tr(req["ask"]), 14, UI.TEXT, 460))
		box.add_child(UI.label(tr("Request: ") + tr(req["title"]), 15, UI.GOLD))
		box.add_child(_reward_line(profile.request_reward(_dialog_npc)))
		buttons.add_child(_dialog_button(tr("I will help"), func(): profile.accept_request(_dialog_npc); Sfx.play(self, "fate"); _refresh()))
	var bye := UI.button(tr("Goodbye"), func(): _dialog.hide(); _refresh(), 14)
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
		if profile.owns(kind, r["id"]):
			return UI.label(tr("Reward: %d Star Dust (you already have %s)") % [profile.duplicate_dust(kind, r["id"]), tr(d.get("name", r["id"]))], 15, Color("#d8c8f0"))
		var line := tr("Reward: [%s] %s (%s)") % [grade, tr(d.get("name", r["id"])), {"hero": tr("hero"), "pet": tr("companion"), "relic": tr("relic weapon")}[kind]]
		if r.has("instead_of"):  # 3.5: the promised item is already yours, so the villager offers another
			line += "\n" + tr("(you already have %s, so this is offered instead)") % tr(profile.item_def(kind, r["instead_of"]).get("name", r["instead_of"]))
		return UI.wrap_label(line, 15, UI.grade_color(grade), 460)
	var names := {"dust": tr("Star Dust"), "dice": tr("Grave Dice"), "embers": tr("Soul Embers")}
	return UI.label(tr("Reward: %d %s") % [int(r["amount"]), names[kind]], 15, Color("#d8c8f0"))


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
	_collection.add_child(UI.wrap_label(tr("Upgrade your heroes, companions and relics with Soul Embers and Star Dust (from villagers' requests, journeys and duplicates). SR = purple, SSR = gold."), 13, UI.DIM, 540))
	_collection.add_child(UI.label(tr("Star Dust: %d     Soul Embers: %d") % [profile.star_dust, profile.embers], 15, Color("#d8c8f0")))
	var sections := [["hero", tr("Heroes"), GameData.load_heroes(), profile.owned_heroes],
		["pet", tr("Companions"), GameData.load_pets(), profile.owned_pets],
		["relic", tr("Relics"), GameData.load_weapons().filter(func(w): return w.get("locked", false)), profile.unlocked_weapons]]
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
				info.add_child(UI.label("[%s] %s   %s" % [grade, tr(d["name"]), UI.stars_text(st)], 15, UI.grade_color(grade)))
				if kind == "pet":
					info.add_child(UI.wrap_label(UI.pet_lines(d), 12, UI.TEXT, 330))
				var nxt := st + 1
				var desc: Array = profile.star_rules["desc"][kind]
				info.add_child(UI.wrap_label((tr("Next star: ") + tr(desc[st])) if nxt <= 5 else tr("Fully upgraded."), 12, UI.DIM, 330))
			else:
				info.add_child(UI.label("[%s] ???" % grade, 15, UI.DIM))
				info.add_child(UI.label(tr("Not yet found (summon or villagers' rewards)"), 12, UI.DIM))
			row.add_child(info)
			if owned:
				var cost := profile.star_cost(kind, id)
				var btn := _confirm_button(tr("MAX") if cost.is_empty() else tr("Upgrade\n%d Embers + %d Dust") % [int(cost[0]), int(cost[1])],
					func(): if profile.upgrade_star(kind, id): Sfx.play(self, "triple"); _toast(tr("%s rose to %d stars.") % [String(id).capitalize(), profile.star(kind, id)]); _refresh(), 12)
				btn.disabled = not profile.can_upgrade_star(kind, id)
				btn.custom_minimum_size = Vector2(150, 44)
				row.add_child(btn)
			_collection.add_child(row)


# ---------------------------------------------------------------- storage: materials from the open world

func _refresh_storage() -> void:
	_clear(_storage)
	_storage.add_child(UI.wrap_label(tr("Minerals you brought back from the Cursed Isle. Sell them at the Night Market for Soul Embers, or grind them into Star Dust."), 13, UI.DIM, 540))
	if profile.materials.is_empty():
		_storage.add_child(UI.label(tr("Empty. Explore the Cursed Isle and gather minerals."), 15, UI.DIM))
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
		lab.add_child(UI.label("%s x%d%s" % [meta[0], amount, tr("   (rare)") if meta[3] else ""], 15, Color("#b07cf0") if meta[3] else UI.TEXT))
		lab.add_child(UI.label(tr("from %s   -   worth %d each") % [meta[2], meta[1]], 12, UI.DIM))
		row.add_child(lab)
		var sell_n: int = min(amount, 5)
		var sell := UI.button(tr("Sell %d\n+%d Embers") % [sell_n, sell_n * meta[1]], func(): profile.trade_material(id, sell_n, "embers", meta[1]); Sfx.play(self, "click"); _refresh(), 12)
		sell.custom_minimum_size = Vector2(110, 40)
		row.add_child(sell)
		var dust_amount := int(floor(sell_n * meta[1] * float(wdata["trade"]["dust_per_value"])))
		var grind := UI.button(tr("Grind %d\n+%d Dust") % [sell_n, dust_amount], func(): profile.trade_material(id, sell_n, "dust", meta[1]); Sfx.play(self, "fate"); _refresh(), 12)
		grind.custom_minimum_size = Vector2(100, 40)
		grind.disabled = dust_amount <= 0
		row.add_child(grind)
		_storage.add_child(row)


## id -> [name, value, where it comes from, rare?] for every material on the Cursed Isle.
func _material_info() -> Dictionary:
	var wdata: Dictionary = GameData.load_json("res://data/world.json")
	var info := {}
	for c in wdata["countries"]:
		info[c["mineral"]["id"]] = [tr(c["mineral"]["name"]), int(c["mineral"]["value"]), tr(c["name"]), false]
		info[c["rare"]["id"]] = [tr(c["rare"]["name"]), int(c["rare"]["value"]), tr(c["name"]), true]
		info[c["wood"]["id"]] = [tr(c["wood"]["name"]), int(c["wood"]["value"]), tr(c["name"]), false]
	for h in wdata["hides"]:
		info[h] = [wdata["hides"][h][0], int(wdata["hides"][h][1]), tr("beasts and bosses"), int(wdata["hides"][h][1]) >= 25]
	return info


# ---------------------------------------------------------------- the Forge: craft and equip gear

## Tabs and the Isle open step by step (rules in Profile.feature_unlocked).
func _refresh_unlocks() -> void:
	var tab_feature := {1: "collection", 2: "forge", 4: "summon", 6: "storage"}
	for i in tab_feature:
		var open := profile.feature_unlocked(tab_feature[i])
		_tabs.set_tab_hidden(i, not open)
	var isle := profile.feature_unlocked("isle")
	_explore.disabled = not isle
	_explore.text = tr("Explore the Cursed Isle") if isle else tr("Cursed Isle (locked)")
	_explore.tooltip_text = tr("The open world: 7 countries, minerals to gather, monsters roaming.") if isle else profile.unlock_hint("isle")


## Small message that floats above the town for a moment (results of building, crafting, upgrading).
func _toast(text: String) -> void:
	var l := UI.label(text, 18, UI.GOLD)
	l.position = Vector2(20, 360)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	add_child(l)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


## Two-press confirm for anything that spends: first press asks, second press does it.
func _confirm_button(text: String, action: Callable, size: int = 13) -> Button:
	var b := UI.button(text, func(): pass, size)
	b.pressed.connect(func():
		if b.get_meta("armed", false):
			action.call()
		else:
			b.set_meta("armed", true)
			b.text = tr("Sure? Press again")
			get_tree().create_timer(2.5).timeout.connect(func():
				if is_instance_valid(b):
					b.set_meta("armed", false)
					b.text = text))
	return b


func _refresh_forge() -> void:
	_clear(_forge)
	var info := _material_info()
	_forge.add_child(UI.wrap_label(tr("The Gravesmith turns ore, wood and hides into gear. A crafted weapon becomes the hero's dice faces 5-6; armour adds max HP and a shield at the start of every fight. Gear works on the road and on the Cursed Isle."), 13, UI.DIM, 540))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for slot in ["weapon", "armor", "treat", "armory"]:
		var label: String = {"weapon": tr("Weapons"), "armor": tr("Armour"), "treat": tr("Treats"), "armory": tr("Armory (%d)") % profile.gear.size()}[slot]
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
		var title := UI.label("[%s] %s" % [grade, tr(r["name"])], 15, UI.grade_color(grade))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(title)
		var effect := ""
		if r["slot"] == "weapon":
			effect = tr("faces: ") + "  ".join(r["faces"].map(UI.face_short))
		elif r["slot"] == "treat":
			effect = tr("companion's blank face -> ") + UI.face_short(r["face"])
		else:
			effect = tr("+%d max HP, +%d shield each fight") % [int(r["hp"]), int(r["shield"])]
		head.add_child(UI.label(effect, 13, UI.TEXT))
		box.add_child(head)
		if r["slot"] == "treat":
			box.add_child(UI.wrap_label(tr(r.get("desc", "")) + tr(" (Fills the companion's blank d4 face for good; a 5-star companion gets +1 on its weakest face.)"), 12, UI.DIM, 540))
		if r["slot"] == "weapon":
			var now: Array[String] = []
			for hid in profile.party:
				var hf: Array = _hero_def(hid).get("faces", [])
				if hf.size() >= 6:
					now.append("%s %s %s" % [String(hid).capitalize(), UI.face_short(hf[4]), UI.face_short(hf[5])])
			if not now.is_empty():
				box.add_child(UI.wrap_label(tr("Replaces faces 5-6. Now: ") + ",  ".join(now), 12, UI.DIM, 540))
		var need: Array[String] = []
		for m in r["materials"]:
			var have := int(profile.materials.get(m, 0))
			var want := int(r["materials"][m])
			need.append("%s %d/%d" % [info.get(m, [m])[0], have, want])
		need.append(tr("Embers %d/%d") % [profile.embers, int(r["embers"])])
		var row := HBoxContainer.new()
		row.add_child(UI.wrap_label("   ".join(need), 12, UI.GREEN if profile.can_craft(r["id"]) else UI.DIM, 400))
		var craft := _confirm_button(tr("Craft"), func(): if profile.craft(r["id"]) >= 0: Sfx.play(self, "triple"); _toast(tr("Crafted %s. Equip it in the Armory.") % tr(r["name"])); _refresh())
		craft.disabled = not profile.can_craft(r["id"])
		craft.custom_minimum_size = Vector2(80, 34)
		row.add_child(craft)
		box.add_child(row)
		_forge.add_child(box)
		_forge.add_child(HSeparator.new())


func _refresh_armory() -> void:
	if profile.gear.is_empty():
		_forge.add_child(UI.label(tr("Nothing crafted yet."), 14, UI.DIM))
		return
	var heroes: Array = profile.party
	for g in profile.gear:
		var uid := int(g["uid"])
		var r := profile.recipe(g["recipe"])
		var owner := profile.gear_owner(uid)
		var row := VBoxContainer.new()
		var where: String = tr("in the chest")
		if owner.begins_with("pet:"):
			where = tr("fed to ") + tr(String(profile.item_def("pet", owner.substr(4)).get("name", owner)))
		elif owner != "":
			where = tr("worn by ") + owner.capitalize()
		row.add_child(UI.label("[%s] %s  -  %s" % [r["grade"], tr(r["name"]), where], 14,
			UI.grade_color(r["grade"])))
		var btns := HFlowContainer.new()
		btns.add_theme_constant_override("h_separation", 6)
		if r["slot"] == "treat":
			for pid in profile.owned_pets:
				var pet_name: String = tr(profile.item_def("pet", pid).get("name", pid))
				var fb := UI.button((tr("Fed: ") if owner == "pet:" + pid else tr("Feed ")) + pet_name, func(): if profile.feed_treat(pid, uid): Sfx.play(self, "fate"); _toast(tr("%s will remember the taste.") % pet_name); _refresh(), 12)
				fb.disabled = owner == "pet:" + pid
				fb.custom_minimum_size = Vector2(130, 30)
				btns.add_child(fb)
			row.add_child(btns)
			_forge.add_child(row)
			continue
		for hid in heroes:
			var b := UI.button((tr("On ") if owner == hid else tr("Give ")) + String(hid).capitalize(), func(): profile.equip_gear(hid, r["slot"], uid); Sfx.play(self, "click"); _refresh(), 12)
			b.disabled = owner == hid
			b.custom_minimum_size = Vector2(110, 30)
			btns.add_child(b)
		if owner != "":
			var off := UI.button(tr("Take off"), func(): profile.equip_gear(owner, r["slot"], -1); _refresh(), 12)
			off.custom_minimum_size = Vector2(90, 30)
			btns.add_child(off)
		row.add_child(btns)
		_forge.add_child(row)


# ---------------------------------------------------------------- phone Back button / app pause (see app_events.gd)

func on_back() -> bool:
	if _dialog.visible:
		_dialog.hide()
		_refresh()
		return true
	return false


func save_state() -> void:
	profile.save()
