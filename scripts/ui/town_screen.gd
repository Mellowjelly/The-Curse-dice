extends Control
## The town of Ashfall: spend Soul Embers on buildings, read the quest board,
## and set out on the Hollow Road (or continue a saved run).

const Profile = preload("res://scripts/core/profile.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")

const GAME_SCENE := "res://scenes/game.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

## Set by the game screen so the town can show what the last run earned.
static var last_result: Dictionary = {}

var profile: Profile
var _embers: Label
var _buildings: VBoxContainer
var _quests: VBoxContainer
var _result_box: VBoxContainer


func _ready() -> void:
	profile = Profile.new()
	profile.load_profile()
	_build()
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	add_child(UI.full_rect(bg))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(UI.full_rect(margin))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := UI.label("Ashfall - the last town before the Hollow Road", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_embers = UI.label("", 22, Color("#e08a3c"))
	top.add_child(_embers)
	var menu := UI.button("Menu", func(): get_tree().change_scene_to_file(TITLE_SCENE))
	menu.custom_minimum_size = Vector2(80, 0)
	top.add_child(menu)

	_result_box = VBoxContainer.new()
	root.add_child(_result_box)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left := UI.panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 6)
	left.add_child(lbox)
	lbox.add_child(UI.label("Buildings  (spend Soul Embers; upgrades last forever)", 15, UI.DIM))
	_buildings = VBoxContainer.new()
	_buildings.add_theme_constant_override("separation", 6)
	lbox.add_child(_buildings)

	var right := UI.panel()
	right.custom_minimum_size = Vector2(470, 0)
	cols.add_child(right)
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 4)
	right.add_child(rbox)
	rbox.add_child(UI.label("Quest Board", 15, UI.DIM))
	_quests = VBoxContainer.new()
	_quests.add_theme_constant_override("separation", 2)
	rbox.add_child(_quests)

	var go_text := "Continue your journey" if Profile.has_saved_run() else "Set out on the Hollow Road"
	var go := UI.choice_button(go_text, _set_out, UI.GOLD)
	go.custom_minimum_size = Vector2(0, 60)
	root.add_child(go)


func _set_out() -> void:
	last_result = {}
	get_tree().change_scene_to_file(GAME_SCENE)


func _refresh() -> void:
	_embers.text = "Soul Embers: %d   " % profile.embers
	for c in _result_box.get_children():
		c.queue_free()
	if not last_result.is_empty():
		var t := "Your last journey earned %d Soul Embers." % int(last_result["embers"])
		for q in last_result["quests"]:
			t += "   Quest complete: %s (+%d)" % [q["name"], int(q["reward"])]
		_result_box.add_child(UI.wrap_label(t, 16, UI.GOLD, 1200))

	for c in _buildings.get_children():
		c.queue_free()
	for b in profile.town["buildings"]:
		var id: String = b["id"]
		var lv := profile.level(id)
		var max_lv: int = b["costs"].size()
		var cost := profile.next_cost(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UI.label("%s   Lv %d/%d" % [b["name"], lv, max_lv], 17, UI.GOLD if lv > 0 else UI.TEXT))
		info.add_child(UI.wrap_label(b["desc"], 13, UI.DIM, 300))
		row.add_child(info)
		var btn := UI.button("MAX" if cost < 0 else "Build (%d)" % cost, func(): profile.upgrade(id); _refresh())
		btn.disabled = not profile.can_upgrade(id)
		btn.custom_minimum_size = Vector2(130, 44)
		row.add_child(btn)
		_buildings.add_child(row)

	for c in _quests.get_children():
		c.queue_free()
	for q in profile.quests:
		var done: bool = q["id"] in profile.quests_done
		var prog := profile.quest_progress(q)
		var line := "%s %s  (%d/%d)  +%d" % ["[done]" if done else "-", q["name"], prog, int(q["goal"]), int(q["reward"])]
		_quests.add_child(UI.label(line, 15, UI.GREEN if done else UI.TEXT))
		_quests.add_child(UI.label("     " + q["desc"], 12, UI.DIM))
