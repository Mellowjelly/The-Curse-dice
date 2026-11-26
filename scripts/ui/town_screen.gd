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
var _summon_text := ""
var _fire_line: Label


func _ready() -> void:
	_rng.randomize()
	profile = Profile.new()
	profile.load_profile()
	heroes_db = GameData.load_heroes()
	_build()
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	add_child(UI.full_rect(bg))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(UI.full_rect(margin))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := UI.label("Ashfall", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_embers = UI.label("", 20, Color("#e08a3c"))
	top.add_child(_embers)
	var menu := UI.button("Menu", func(): get_tree().change_scene_to_file(TITLE_SCENE))
	menu.custom_minimum_size = Vector2(80, 0)
	top.add_child(menu)

	_fire_line = UI.wrap_label("", 15, Color("#b39ddb"), 1200)
	root.add_child(_fire_line)
	_result_box = VBoxContainer.new()
	root.add_child(_result_box)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 17)
	root.add_child(_tabs)
	_party_box = _tab("Party")
	_buildings = _tab("Buildings")
	_summon_box = _tab("Summon Roll")
	_quests = _tab("Quests")

	_go = UI.choice_button("", _set_out, UI.GOLD)
	_go.custom_minimum_size = Vector2(0, 58)
	root.add_child(_go)


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
	_embers.text = "Soul Embers %d    Grave Dice %d   " % [profile.embers, profile.grave_dice]
	var speaker := _hero_def(profile.party[0] if not profile.party.is_empty() else "varek")
	_fire_line.text = "At the fire, %s stares into the embers: \"%s\"" % [speaker.get("name", "?"), speaker.get("lore", "")]
	_clear(_result_box)
	if not last_result.is_empty():
		var t := "Your last journey earned %d Soul Embers and %d Grave Dice." % [int(last_result["embers"]), int(last_result.get("dice", 0))]
		for q in last_result["quests"]:
			t += "   Quest complete: %s (+%d)" % [q["name"], int(q["reward"])]
		_result_box.add_child(UI.wrap_label(t, 15, UI.GOLD, 1200))
	var saved := Profile.has_saved_run()
	_go.text = "Continue your journey" if saved else ("Set out on the Hollow Road" if profile.party.size() == 3 else "Choose 3 heroes to set out")
	_go.disabled = not saved and profile.party.size() != 3
	_refresh_party()
	_refresh_buildings()
	_refresh_summon()
	_refresh_quests()


func _refresh_party() -> void:
	_clear(_party_box)
	_party_box.add_child(UI.label("Choose 3 heroes (%d/3). Click to add or remove." % profile.party.size(), 15, UI.DIM))
	var grid := GridContainer.new()
	grid.columns = 3
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
		b.custom_minimum_size = Vector2(390, 92)
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
	row.add_child(UI.label("  Each level: enemies +12% HP (+1 damage at 2 and 4), +25% Soul Embers. Beat a level to unlock the next.", 13, UI.DIM))


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
		info.add_child(UI.wrap_label(b["desc"], 13, UI.DIM, 300))
		row.add_child(info)
		var btn := UI.button("MAX" if cost < 0 else "Build (%d Embers)" % cost, func(): profile.upgrade(id); Sfx.play(self, "fate"); _refresh())
		btn.disabled = not profile.can_upgrade(id)
		btn.custom_minimum_size = Vector2(180, 44)
		row.add_child(btn)
		_buildings.add_child(row)


func _refresh_summon() -> void:
	_clear(_summon_box)
	var s: Dictionary = profile.summon
	_summon_box.add_child(UI.wrap_label("Roll the Bone Dice of the Crossroads. Paid only with Grave Dice, earned on the road: 1 per journey, +1 per elite, +2 per victory, +1 per quest. No other currency, ever.", 15, UI.TEXT, 1150))
	var rates: Array[String] = []
	for r in s["rates"]:
		rates.append("%s %d%%" % [r["kind"].capitalize(), int(r["weight"])])
	_summon_box.add_child(UI.label("Rates: %s.   Pity: a new hero is guaranteed within %d rolls (now %d/%d)." % [
		", ".join(rates), int(s["pity"]), profile.summons_since_hero, int(s["pity"])], 15, UI.GOLD))
	_summon_box.add_child(UI.label("Duplicates turn into Soul Embers. Summoned heroes are sidegrades: the starting three can win the game.", 13, UI.DIM))
	_summon_box.add_child(UI.label("Still sealed: %d heroes, %d relic weapons." % [profile.locked_heroes().size(), profile.locked_relics().size()], 14, UI.DIM))
	var b := UI.choice_button("Summon Roll  (%d Grave Dice)" % int(s["cost"]), _do_summon, UI.GOLD, profile.can_summon())
	b.custom_minimum_size = Vector2(0, 56)
	_summon_box.add_child(b)
	if _summon_text != "":
		_summon_box.add_child(UI.wrap_label(_summon_text, 18, Color("#b39ddb"), 1150))


func _do_summon() -> void:
	var r := profile.summon_roll(_rng)
	if r.is_empty():
		return
	_summon_text = r["text"]
	Sfx.play(self, "triple" if r.get("new", false) else "dice")
	_refresh()


func _refresh_quests() -> void:
	_clear(_quests)
	for q in profile.quests:
		var done: bool = q["id"] in profile.quests_done
		var line := "%s %s  (%d/%d)  +%d Embers" % ["[done]" if done else "-", q["name"], profile.quest_progress(q), int(q["goal"]), int(q["reward"])]
		_quests.add_child(UI.label(line, 15, UI.GREEN if done else UI.TEXT))
		_quests.add_child(UI.label("     " + q["desc"], 12, UI.DIM))
