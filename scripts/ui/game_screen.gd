extends Control
## The main game screen for a run: the board map, plus pop-up panels for
## events / shop / rest / carving rewards, plus the combat view for fights.
## All rules live in scripts/core/run.gd; this file only displays and forwards clicks.

const Run = preload("res://scripts/core/run.gd")
const Combat = preload("res://scripts/core/combat.gd")
const CombatView = preload("res://scripts/ui/combat_view.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")
const Profile = preload("res://scripts/core/profile.gd")
const TownScreen = preload("res://scripts/ui/town_screen.gd")
const Sfx = preload("res://scripts/ui/sfx.gd")
const UnitSprite = preload("res://scripts/ui/unit_sprite.gd")

const TOWN_SCENE := "res://scenes/town.tscn"

const TITLE_SCENE := "res://scenes/title.tscn"
const COLS := 10
const NODE := 52                     # diameter of a tile node on the world map
const COL_STEP := 112.0
const ROW_STEP := 80.0
const BOARD_ORIGIN := Vector2(76, 120)  # centre of tile 0

var run: Run
var profile: Profile
var _recorded := false
var _combat_view: CombatView
var _in_combat := false

var _map_root: Control
var _board_layer: Control
var _header: Label
var _stats: Label
var _party_box: HBoxContainer
var _action_box: HBoxContainer
var _modal: Control
var _modal_box: VBoxContainer
var _token: Control


func _ready() -> void:
	_build_map()
	_combat_view = CombatView.new()
	add_child(UI.full_rect(_combat_view))
	_combat_view.hide()
	_combat_view.finished.connect(_on_combat_finished)
	Sfx.music(self)
	profile = Profile.new()
	profile.load_profile()
	var saved := Profile.load_run_data()
	if not saved.is_empty():
		_attach(Run.from_dict(saved))
	else:
		new_run()


func new_run() -> void:
	Profile.delete_saved_run()
	_attach(Run.new(-1, profile.run_options(), profile.party))


func _attach(r: Run) -> void:
	run = r
	_recorded = false
	run.changed.connect(_on_run_changed)
	_in_combat = false
	_draw_board()
	_on_run_changed()


# ---------------------------------------------------------------- map layout

func _build_map() -> void:
	_map_root = Control.new()
	add_child(UI.full_rect(_map_root))
	var bg := ColorRect.new()
	bg.color = UI.BG
	_map_root.add_child(UI.full_rect(bg))
	var map_art := TextureRect.new()
	map_art.texture = load("res://assets/backgrounds/map.png")
	map_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_art.stretch_mode = TextureRect.STRETCH_SCALE
	map_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_root.add_child(map_art)

	_header = UI.label("", 26, UI.TEXT)
	_header.add_theme_color_override("font_shadow_color", Color.BLACK)
	_header.add_theme_constant_override("shadow_offset_x", 2)
	_header.add_theme_constant_override("shadow_offset_y", 2)
	_header.position = Vector2(40, 22)
	_map_root.add_child(_header)
	_stats = UI.label("", 20, UI.GOLD)
	_stats.position = Vector2(640, 28)
	_map_root.add_child(_stats)
	var menu := UI.button("Town", func(): get_tree().change_scene_to_file(TOWN_SCENE))
	menu.position = Vector2(1170, 22)
	menu.custom_minimum_size = Vector2(80, 36)
	_map_root.add_child(menu)

	_board_layer = Control.new()
	_map_root.add_child(_board_layer)

	# Bottom panel: party on the left, actions on the right.
	var bottom := UI.panel()
	bottom.position = Vector2(20, 520)
	bottom.size = Vector2(1240, 184)
	_map_root.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bottom.add_child(row)
	_party_box = HBoxContainer.new()
	_party_box.add_theme_constant_override("separation", 10)
	_party_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_party_box)
	_action_box = HBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 10)
	_action_box.custom_minimum_size = Vector2(420, 0)
	_action_box.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_action_box)

	# Modal for events / shop / rest / rewards / end screens.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	_modal = UI.full_rect(dim)
	_map_root.add_child(_modal)
	var center := CenterContainer.new()
	_modal.add_child(UI.full_rect(center))
	var panel := UI.panel(UI.BORDER, 2)
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	_modal_box = VBoxContainer.new()
	_modal_box.add_theme_constant_override("separation", 12)
	panel.add_child(_modal_box)
	_modal.hide()


## Centre of tile i on the world map: a snaking road with a gentle wobble so it feels hand-drawn.
func _tile_pos(i: int) -> Vector2:
	var row := i / COLS
	var col := i % COLS
	if row % 2 == 1:
		col = COLS - 1 - col
	var wobble := Vector2(sin(i * 1.7) * 6.0, sin(i * 2.3 + 1.0) * 7.0)
	return BOARD_ORIGIN + Vector2(col * COL_STEP, row * ROW_STEP) + wobble


func _draw_board() -> void:
	for c in _board_layer.get_children():
		c.queue_free()
	# The road: a dark edge with a dusty centre line through every tile.
	var pts := PackedVector2Array()
	for i in run.board.size():
		pts.append(_tile_pos(i))
	for layer in [[18.0, Color("#140e0c")], [11.0, Color("#5c4630")], [3.0, Color("#7a6044")]]:
		var road := Line2D.new()
		road.points = pts
		road.width = layer[0]
		road.default_color = layer[1]
		road.joint_mode = Line2D.LINE_JOINT_ROUND
		road.begin_cap_mode = Line2D.LINE_CAP_ROUND
		road.end_cap_mode = Line2D.LINE_CAP_ROUND
		_board_layer.add_child(road)
	for i in run.board.size():
		var t: Dictionary = run.board[i]
		var node := Panel.new()
		node.name = "Tile%d" % i
		node.size = Vector2(NODE, NODE)
		node.position = _tile_pos(i) - node.size / 2
		node.tooltip_text = UI.TILE_LABELS.get(t["type"], t["type"])
		var icon := TextureRect.new()
		icon.texture = load("res://assets/icons/tile_%s.png" % t["type"]) if ResourceLoader.exists("res://assets/icons/tile_%s.png" % t["type"]) else null
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.size = Vector2(32, 32)
		icon.position = Vector2((NODE - 32) / 2.0, (NODE - 32) / 2.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(icon)
		_board_layer.add_child(node)
		if t["type"] in ["shop", "rest", "boss", "elite"] or t.get("gate", false):
			var lbl := UI.label(UI.TILE_LABELS.get(t["type"], t["type"]), 11, UI.TEXT)
			lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
			lbl.add_theme_constant_override("shadow_offset_y", 1)
			lbl.position = _tile_pos(i) + Vector2(-NODE / 2.0, NODE / 2.0 - 4)
			lbl.size = Vector2(NODE, 14)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_board_layer.add_child(lbl)
	# The party leader walks the road.
	var leader: String = run.heroes[0]["id"]
	_token = UnitSprite.create(leader, 64, false)
	_board_layer.add_child(_token)
	_token.position = _token_pos(0)


func _token_pos(i: int) -> Vector2:
	return _tile_pos(i) + Vector2(-32, -62)


func _style_tiles() -> void:
	var targets := {}
	for i in run.move_options.size():
		targets[run.destination(run.move_options[i])] = true
	for i in run.board.size():
		var tile: Panel = _board_layer.get_node_or_null("Tile%d" % i)
		if tile == null:
			continue
		var t: Dictionary = run.board[i]
		var color: Color = UI.TILE_COLORS.get(t["type"], UI.PANEL)
		var border := Color("#0e0b12")
		var width := 2
		if t.get("gate", false):
			border = Color("#a3541c")
		if i < run.pos:
			color = color.darkened(0.65)
			tile.modulate = Color(0.7, 0.7, 0.7)
		else:
			tile.modulate = Color.WHITE
		if i == run.pos:
			border = Color.WHITE
			width = 3
		if targets.has(i):
			border = UI.GOLD
			width = 4
		tile.add_theme_stylebox_override("panel", UI.box(color, border, width, NODE / 2, 0))
		# Destination tiles pulse so the choice is obvious.
		if targets.has(i) and not tile.has_meta("pulsing"):
			tile.set_meta("pulsing", true)
			tile.pivot_offset = tile.size / 2
			var tw := tile.create_tween().set_loops()
			tw.tween_property(tile, "scale", Vector2(1.15, 1.15), 0.4)
			tw.tween_property(tile, "scale", Vector2.ONE, 0.4)
			tile.set_meta("tween", tw)
		elif not targets.has(i) and tile.has_meta("pulsing"):
			tile.remove_meta("pulsing")
			var old_tw: Tween = tile.get_meta("tween")
			if old_tw != null and old_tw.is_valid():
				old_tw.kill()
			tile.scale = Vector2.ONE


func _move_token() -> void:
	var dest := _token_pos(run.pos)
	if _token.position.distance_to(dest) < 1.0:
		return
	# Hop from tile to tile along the road.
	var start_i := 0
	for i in run.board.size():
		if _token_pos(i).distance_to(_token.position) < 2.0:
			start_i = i
	var tw := create_tween()
	for i in range(start_i + 1, run.pos + 1):
		var p := _token_pos(i)
		tw.tween_property(_token, "position", p + Vector2(0, -10), 0.09).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_token, "position", p, 0.07)


# ---------------------------------------------------------------- refresh

func _on_run_changed() -> void:
	if run.phase == "combat" and not _in_combat:
		_enter_combat()
		return
	if _in_combat:
		return  # stay on the combat screen until the player presses Continue
	_map_root.show()
	_combat_view.hide()
	if run.phase == "map":
		Profile.save_run_data(run.to_dict())  # auto-save at every map step
	elif run.is_over() and not _recorded:
		_recorded = true
		Profile.delete_saved_run()
		TownScreen.last_result = profile.record_run(run)
	_header.text = "%s  -  tile %d / %d" % [run.region["name"], run.pos, run.board.size() - 1]
	_stats.text = "Gold %d    Fate %d/%d" % [run.gold, run.combat.fate, Combat.MAX_FATE]
	if not run.combat.pet.is_empty():
		_stats.text += "    Pet: " + run.combat.pet["name"]
	_style_tiles()
	_move_token()
	_refresh_party()
	_refresh_actions()
	if run.phase in ["event", "shop", "rest", "loot", "reward"] and not run.tile_snapshot.is_empty() and run.event_result == "":
		Profile.save_run_data(run.tile_snapshot)
	_refresh_modal()


func _enter_combat() -> void:
	_in_combat = true
	if not run.tile_snapshot.is_empty():
		Profile.save_run_data(run.tile_snapshot)  # closing the app mid-fight restarts this fight
	_modal.hide()
	_map_root.hide()
	_combat_view.show()
	var names := {"fight": "Fight", "elite": "ELITE", "boss": "BOSS: The Chapel of Rot"}
	var scene := "battle_boss" if run.combat_kind == "boss" else "battle_" + run.tier_at(run.pos)
	_combat_view.bind(run.combat, names.get(run.combat_kind, "Fight"), scene)


func _on_combat_finished(_victory: bool) -> void:
	_in_combat = false
	_on_run_changed()


func _refresh_party() -> void:
	for c in _party_box.get_children():
		c.queue_free()
	for h in run.heroes:
		var holder := HBoxContainer.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sp := UnitSprite.create(h["id"], 64, false)
		if not Combat.is_alive(h):
			sp.set_dead(true)
		holder.add_child(sp)
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.add_child(card)
		card.add_theme_constant_override("separation", 4)
		var alive := Combat.is_alive(h)
		card.add_child(UI.label(h["name"] + ("" if alive else "  (fallen)"), 15, UI.TEXT if alive else UI.DIM))
		card.add_child(UI.hp_bar(h["hp"], h["max_hp"], 18))
		card.add_child(UI.wrap_label(" ".join(h["faces"].map(UI.face_short)), 13, UI.DIM, 150))
		card.add_child(UI.label("Skill: " + h["skill"].get("name", "-"), 12, UI.DIM))
		var w: Dictionary = h.get("weapon", {})
		card.add_child(UI.label("Weapon: " + (w["name"] if not w.is_empty() else "bare hands"), 12,
			UI.BLOOD if w.get("rarity", "") == "cursed" else UI.DIM))
		_party_box.add_child(holder)


func _refresh_actions() -> void:
	for c in _action_box.get_children():
		c.queue_free()
	if run.phase != "map":
		return
	if run.move_options.is_empty():
		var roll := UI.choice_button("Roll the bone dice", func(): Sfx.play(self, "dice"); run.roll_move(), UI.GOLD)
		roll.autowrap_mode = TextServer.AUTOWRAP_OFF
		roll.custom_minimum_size = Vector2(300, 80)
		_action_box.add_child(roll)
		return
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_action_box.add_child(col)
	col.add_child(UI.label("Choose one die to move:", 14, UI.DIM))
	for i in run.move_options.size():
		var steps: int = run.move_options[i]
		var dest := run.destination(steps)
		var t: String = run.board[dest]["type"]
		var text := "Move %d  ->  %s" % [steps, UI.TILE_LABELS.get(t, t)]
		if dest - run.pos < steps:
			text += "  (stops here)"
		var b := UI.choice_button(text, func(): run.choose_move(i), UI.TILE_COLORS.get(t, UI.BORDER))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.custom_minimum_size = Vector2(400, 44)
		col.add_child(b)
	var rr := UI.button("Reroll movement (-%d Fate)" % Run.MOVE_REROLL_FATE, func(): run.reroll_move(), 13)
	rr.custom_minimum_size = Vector2(400, 28)
	rr.disabled = run.combat.fate < Run.MOVE_REROLL_FATE
	col.add_child(rr)


# ---------------------------------------------------------------- modal panels

func _clear_modal() -> void:
	for c in _modal_box.get_children():
		c.queue_free()


func _modal_title(text: String, color: Color = UI.GOLD) -> void:
	var l := UI.label(text, 28, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_box.add_child(l)


func _modal_text(text: String, color: Color = UI.TEXT) -> void:
	_modal_box.add_child(UI.wrap_label(text, 17, color, 680))


func _refresh_modal() -> void:
	_clear_modal()
	match run.phase:
		"pet":
			_modal_title("A stray follows you", Color("#b39ddb"))
			_modal_text("Something small and loyal watches you from the ditch. Its die is a d4: it rolls every round and acts after your heroes.")
			for i in run.pet_offers.size():
				var p: Dictionary = run.pet_offers[i]
				var text := "%s  [%s]\n%s" % [p["name"], " ".join(p["faces"].map(UI.face_short)), p["desc"]]
				_modal_box.add_child(UI.choice_button(text, func(): run.choose_pet(i), UI.GOLD))
		"loot":
			_modal_title("Weapons")
			if run.last_reward_text != "":
				_modal_text(run.last_reward_text, UI.GOLD)
			_modal_text("A weapon replaces die faces 5 and 6 of the hero who carries it. The old weapon is left behind.", UI.DIM)
			for wi in run.weapon_offers.size():
				var w: Dictionary = run.weapon_offers[wi]
				var color := UI.BLOOD if w["rarity"] == "cursed" else (UI.GOLD if w["rarity"] == "rare" else UI.TEXT)
				_modal_box.add_child(UI.label("%s  (%s)   faces: %s" % [w["name"], w["rarity"], "  ".join(w["faces"].map(UI.face_short))], 18, color))
				_modal_box.add_child(UI.wrap_label(w["desc"], 14, UI.DIM, 680))
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				for hi in run.heroes.size():
					var h: Dictionary = run.heroes[hi]
					var cur := "%s %s" % [UI.face_short(h["faces"][4]), UI.face_short(h["faces"][5])]
					var b := UI.choice_button("Give to %s\n(replaces %s)" % [Combat.short_name(h), cur], func(): run.equip(wi, hi), color)
					b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					row.add_child(b)
				_modal_box.add_child(row)
			_modal_box.add_child(UI.button("Leave them", func(): run.skip_loot()))
		"reward":
			_modal_title("Carve your dice")
			if run.last_reward_text != "":
				_modal_text(run.last_reward_text, UI.GOLD)
			_modal_text("Choose one carving. It changes that hero's die for the rest of the run.", UI.DIM)
			for i in run.carve_offers.size():
				var o: Dictionary = run.carve_offers[i]
				_modal_box.add_child(UI.choice_button(o["text"], func(): run.choose_carving(i), UI.FACE_COLORS[o["new"]["type"]]))
			_modal_box.add_child(UI.button("Skip", func(): run.skip_carving()))
		"event":
			_modal_title(run.event["title"], Color("#b39ddb"))
			_modal_text(run.event["text"])
			if run.event_result == "":
				for i in run.event["options"].size():
					var opt: Dictionary = run.event["options"][i]
					_modal_box.add_child(UI.choice_button(opt["label"], func(): run.choose_event_option(i),
						UI.BORDER, run.can_choose_event_option(i)))
			else:
				_modal_text(run.event_result, UI.GOLD)
				_modal_box.add_child(UI.choice_button("Continue", func(): run.close_event(), UI.GOLD))
		"shop":
			_modal_title("The Bone Market")
			_modal_text("A hooded figure spreads its wares on a burial cloth. Gold: %d" % run.gold, UI.DIM)
			for it in run.shop_items():
				var id: String = it["id"]
				var bought: bool = id in run.shop_bought
				var text := "%s  (%d gold)\n%s" % [it["name"], run.price(it), "Sold" if bought else it["desc"]]
				_modal_box.add_child(UI.choice_button(text, func(): run.buy(id), UI.GOLD, run.can_buy(id)))
			_modal_box.add_child(UI.button("Leave", func(): run.leave_shop()))
		"rest":
			var gate: bool = run.board[run.pos].get("gate", false)
			_modal_title("The Last Campfire" if gate else "Campfire", Color("#e08a3c"))
			_modal_text("The chapel bells toll ahead. This is the last rest before the Bishop." if gate
				else "Embers crackle. For one night, nothing hunts you.")
			_modal_box.add_child(UI.choice_button("Rest: heal %d%% HP (the fallen rise)" % int(run.region["rest_heal_percent"]),
				func(): run.rest_heal(), UI.GREEN))
			_modal_box.add_child(UI.choice_button("Whittle: carve a die instead", func(): run.rest_carve(), UI.GOLD))
		"victory":
			_modal_title("The Rotting Bishop is no more", UI.GOLD)
			_modal_text("The chapel bells fall silent. One shard of the Dice of Fate glows in the ashes.")
			_modal_text(_run_summary(), UI.DIM)
			_end_buttons()
		"defeat":
			_modal_title("Your party has fallen", UI.BLOOD)
			_modal_text("The Hollow Road claims three more souls. The dice keep rolling without you.")
			_modal_text(_run_summary(), UI.DIM)
			_end_buttons()
		_:
			_modal.hide()
			return
	_modal.show()


func _end_buttons() -> void:
	var res: Dictionary = TownScreen.last_result
	if not res.is_empty():
		var t := "+%d Soul Embers, +%d Grave Dice" % [int(res["embers"]), int(res.get("dice", 0))]
		for q in res["quests"]:
			t += "\nQuest complete: %s" % q["name"]
		_modal_text(t, Color("#e08a3c"))
	_modal_box.add_child(UI.choice_button("Return to Ashfall", func(): get_tree().change_scene_to_file(TOWN_SCENE), UI.GOLD))


func _run_summary() -> String:
	var s := run.stats
	return "Reached tile %d/%d  -  %d fights and %d elites won, %d events, %d carvings, %d gold earned." % [
		run.pos, run.board.size() - 1, s["fights"], s["elites"], s["events"], s["carves"], s["gold_earned"]]
