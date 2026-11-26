extends Control
## The main game screen for a run: the board map, plus pop-up panels for
## events / shop / rest / carving rewards, plus the combat view for fights.
## All rules live in scripts/core/run.gd; this file only displays and forwards clicks.

const Run = preload("res://scripts/core/run.gd")
const Combat = preload("res://scripts/core/combat.gd")
const CombatView = preload("res://scripts/ui/combat_view.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")

const TITLE_SCENE := "res://scenes/title.tscn"
const COLS := 10
const TILE_SIZE := Vector2(96, 62)
const TILE_GAP := Vector2(14, 18)
const BOARD_ORIGIN := Vector2(40, 96)

var run: Run
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
var _token: Panel


func _ready() -> void:
	_build_map()
	_combat_view = CombatView.new()
	add_child(UI.full_rect(_combat_view))
	_combat_view.hide()
	_combat_view.finished.connect(_on_combat_finished)
	new_run()


func new_run() -> void:
	run = Run.new()
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

	_header = UI.label("", 26, UI.TEXT)
	_header.position = Vector2(40, 22)
	_map_root.add_child(_header)
	_stats = UI.label("", 20, UI.GOLD)
	_stats.position = Vector2(640, 28)
	_map_root.add_child(_stats)
	var menu := UI.button("Menu", func(): get_tree().change_scene_to_file(TITLE_SCENE))
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


func _tile_pos(i: int) -> Vector2:
	# Snake layout: left->right, then right->left on the next row.
	var row := i / COLS
	var col := i % COLS
	if row % 2 == 1:
		col = COLS - 1 - col
	return BOARD_ORIGIN + Vector2(col * (TILE_SIZE.x + TILE_GAP.x), row * (TILE_SIZE.y + TILE_GAP.y))


func _draw_board() -> void:
	for c in _board_layer.get_children():
		c.queue_free()
	for i in run.board.size():
		var t: Dictionary = run.board[i]
		var tile := Panel.new()
		tile.position = _tile_pos(i)
		tile.size = TILE_SIZE
		tile.name = "Tile%d" % i
		var lbl := UI.label(UI.TILE_LABELS.get(t["type"], t["type"]), 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.add_child(UI.full_rect(lbl))
		var num := UI.label(str(i), 11, UI.DIM)
		num.position = Vector2(5, 2)
		tile.add_child(num)
		_board_layer.add_child(tile)
	_token = Panel.new()
	_token.size = Vector2(22, 22)
	_token.add_theme_stylebox_override("panel", UI.box(UI.GOLD, Color.BLACK, 2, 11, 0))
	_board_layer.add_child(_token)
	_token.position = _tile_pos(0) + Vector2(TILE_SIZE.x - 28, TILE_SIZE.y - 28)


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
		if i < run.pos:
			color = color.darkened(0.6)
		var border := UI.GOLD if targets.has(i) else (Color.WHITE if i == run.pos else Color("#000000"))
		tile.add_theme_stylebox_override("panel", UI.box(color, border, 3 if targets.has(i) or i == run.pos else 1, 6, 0))


func _move_token() -> void:
	var dest := _tile_pos(run.pos) + Vector2(TILE_SIZE.x - 28, TILE_SIZE.y - 28)
	var tw := create_tween()
	tw.tween_property(_token, "position", dest, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- refresh

func _on_run_changed() -> void:
	if run.phase == "combat" and not _in_combat:
		_enter_combat()
		return
	if _in_combat:
		return  # stay on the combat screen until the player presses Continue
	_map_root.show()
	_combat_view.hide()
	_header.text = "%s  -  tile %d / %d" % [run.region["name"], run.pos, run.board.size() - 1]
	_stats.text = "Gold %d    Fate %d/%d" % [run.gold, run.combat.fate, Combat.MAX_FATE]
	if not run.combat.pet.is_empty():
		_stats.text += "    Pet: " + run.combat.pet["name"]
	_style_tiles()
	_move_token()
	_refresh_party()
	_refresh_actions()
	_refresh_modal()


func _enter_combat() -> void:
	_in_combat = true
	_modal.hide()
	_map_root.hide()
	_combat_view.show()
	var names := {"fight": "Fight", "elite": "ELITE", "boss": "BOSS: The Chapel of Rot"}
	_combat_view.bind(run.combat, names.get(run.combat_kind, "Fight"))


func _on_combat_finished(_victory: bool) -> void:
	_in_combat = false
	_on_run_changed()


func _refresh_party() -> void:
	for c in _party_box.get_children():
		c.queue_free()
	for h in run.heroes:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 4)
		var alive := Combat.is_alive(h)
		card.add_child(UI.label(h["name"] + ("" if alive else "  (fallen)"), 15, UI.TEXT if alive else UI.DIM))
		card.add_child(UI.hp_bar(h["hp"], h["max_hp"], 18))
		card.add_child(UI.wrap_label(" ".join(h["faces"].map(UI.face_short)), 13, UI.DIM, 150))
		card.add_child(UI.label("Skill: " + h["skill"].get("name", "-"), 12, UI.DIM))
		var w: Dictionary = h.get("weapon", {})
		card.add_child(UI.label("Weapon: " + (w["name"] if not w.is_empty() else "bare hands"), 12,
			UI.BLOOD if w.get("rarity", "") == "cursed" else UI.DIM))
		_party_box.add_child(card)


func _refresh_actions() -> void:
	for c in _action_box.get_children():
		c.queue_free()
	if run.phase != "map":
		return
	if run.move_options.is_empty():
		var roll := UI.choice_button("Roll the bone dice", func(): run.roll_move(), UI.GOLD)
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
				var text := "%s  (%d gold)\n%s" % [it["name"], int(it["cost"]), "Sold" if bought else it["desc"]]
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
	_modal_box.add_child(UI.choice_button("New Run", new_run, UI.GOLD))
	_modal_box.add_child(UI.button("Main Menu", func(): get_tree().change_scene_to_file(TITLE_SCENE)))


func _run_summary() -> String:
	var s := run.stats
	return "Reached tile %d/%d  -  %d fights and %d elites won, %d events, %d carvings, %d gold earned." % [
		run.pos, run.board.size() - 1, s["fights"], s["elites"], s["events"], s["carves"], s["gold_earned"]]
