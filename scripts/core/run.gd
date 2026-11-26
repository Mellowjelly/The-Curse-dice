extends RefCounted
## One journey through a region: the dice-movement board, events, shops, rests,
## die carving, and the fights in between. NO UI code here.
##
## The run is a small state machine. `phase` tells the UI what to show:
##   "map"     - roll movement dice, choose how far to move
##   "combat"  - a fight is running in `combat`
##   "reward"  - choose 1 of 3 die carvings (or skip)
##   "event"   - read `event`, pick an option
##   "shop"    - buy items, then leave
##   "rest"    - heal OR carve
##   "victory" / "defeat" - the run is over

signal changed
signal log_added(text: String)

const Combat = preload("res://scripts/core/combat.gd")
const GameData = preload("res://scripts/core/game_data.gd")

const CARVE_OFFERS := 3
const BLANK_CARVE_CHANCE := 0.45  # chance an offer targets a blank face (if the hero has one)

var rng := RandomNumberGenerator.new()
var region: Dictionary
var monster_defs: Dictionary
var events: Array
var heroes: Array = []
var combat: Combat
var board: Array = []        # [{ "type": String, "visited": bool }]
var pos := 0
var gold := 0
var phase := "map"
var move_options: Array = []  # two movement dice after roll_move()
var event: Dictionary = {}
var event_result := ""        # text shown after an event choice
var carve_offers: Array = []  # [{ "hero": int, "face": int, "new": Dictionary, "text": String }]
var shop_bought: Array = []
var combat_kind := ""         # "fight" | "elite" | "boss"
var last_reward_text := ""
var stats := {"fights": 0, "elites": 0, "events": 0, "carves": 0, "gold_earned": 0, "tiles": {}}
var _return_phase := "map"    # where to go after a carving reward


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	region = GameData.load_json("res://data/region1.json")
	monster_defs = GameData.load_monsters()
	events = GameData.load_json("res://data/events.json")
	for def in GameData.load_heroes():
		var u := Combat.make_unit(def)
		u["carve_pool"] = def.get("carve_pool", [])
		heroes.append(u)
	# The combat object lives for the whole run, so Fate carries between fights.
	combat = Combat.new(rng.randi())
	combat.battle_ended.connect(_on_battle_ended)
	combat.log_added.connect(func(t): log_added.emit(t))
	_generate_board()


# ---------------------------------------------------------------- board

func _generate_board() -> void:
	var length: int = region["board_length"]
	board = [{"type": "start", "visited": true}]
	for i in range(1, length):
		var tier := "early" if i < length / 3 else ("mid" if i < 2 * length / 3 else "late")
		board.append({"type": _weighted_pick(region["tile_weights"][tier]), "visited": false})
	# Fixed landmarks: a gate campfire right before the boss (movement always stops there).
	board[length - 1] = {"type": "rest", "visited": false, "gate": true}
	board.append({"type": "boss", "visited": false, "gate": true})


func _weighted_pick(weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := rng.randi_range(1, total)
	for k in weights:
		roll -= int(weights[k])
		if roll <= 0:
			return k
	return weights.keys()[0]


func tier_at(index: int) -> String:
	var length: int = region["board_length"]
	return "early" if index < length / 3 else ("mid" if index < 2 * length / 3 else "late")


## Where a move of `steps` would land (stops early at a gate tile).
func destination(steps: int) -> int:
	var p := pos
	for s in steps:
		p += 1
		if p >= board.size() - 1 or board[p].get("gate", false):
			return min(p, board.size() - 1)
	return p


# ---------------------------------------------------------------- map phase

func roll_move() -> void:
	if phase != "map" or not move_options.is_empty():
		return
	move_options = [rng.randi_range(1, 6), rng.randi_range(1, 6)]
	changed.emit()


const MOVE_REROLL_FATE := 1

## Spend Fate to reroll both movement dice.
func reroll_move() -> bool:
	if phase != "map" or move_options.is_empty() or combat.fate < MOVE_REROLL_FATE:
		return false
	combat.fate -= MOVE_REROLL_FATE
	move_options = [rng.randi_range(1, 6), rng.randi_range(1, 6)]
	_log("Fate bends the road (-%d Fate)" % MOVE_REROLL_FATE)
	changed.emit()
	return true


func choose_move(option_index: int) -> void:
	if phase != "map" or option_index < 0 or option_index >= move_options.size():
		return
	pos = destination(move_options[option_index])
	move_options = []
	var tile: Dictionary = board[pos]
	tile["visited"] = true
	stats["tiles"][tile["type"]] = stats["tiles"].get(tile["type"], 0) + 1
	_enter_tile(tile)


func _enter_tile(tile: Dictionary) -> void:
	match tile["type"]:
		"fight", "elite", "boss":
			_start_fight(tile["type"], tier_at(pos))
		"chest":
			var g := _gold_roll("chest")
			last_reward_text = "You pry open a rotten chest: +%d gold." % g
			_log(last_reward_text)
			if rng.randf() < 0.35:
				last_reward_text += " Inside, a bone chisel."
				_offer_carving("map")
			else:
				phase = "map"
				changed.emit()
		"event":
			event = events[rng.randi_range(0, events.size() - 1)]
			event_result = ""
			stats["events"] += 1
			phase = "event"
			changed.emit()
		"shop":
			shop_bought = []
			phase = "shop"
			changed.emit()
		"rest":
			phase = "rest"
			changed.emit()
		_:
			phase = "map"
			changed.emit()


# ---------------------------------------------------------------- combat

func _start_fight(kind: String, tier: String) -> void:
	combat_kind = kind
	var pool_name := kind if kind in ["elite", "boss"] else tier
	var pool: Array = region["encounters"][pool_name]
	var ids: Array = pool[rng.randi_range(0, pool.size() - 1)]
	phase = "combat"
	_log("== %s ==" % ("BOSS" if kind == "boss" else ("Elite fight" if kind == "elite" else "Fight")))
	combat.start_battle(heroes, ids.map(func(id): return monster_defs[id]))
	changed.emit()


func _on_battle_ended(victory: bool) -> void:
	if not victory:
		phase = "defeat"
		changed.emit()
		return
	if combat_kind == "boss":
		phase = "victory"
		changed.emit()
		return
	stats["elites" if combat_kind == "elite" else "fights"] += 1
	# The fallen crawl back with a little HP.
	var pct: int = region["revive_after_fight_percent"]
	for h in heroes:
		if not Combat.is_alive(h):
			h["hp"] = max(1, h["max_hp"] * pct / 100)
	var g := _gold_roll("elite" if combat_kind == "elite" else "fight")
	last_reward_text = "Victory! +%d gold." % g
	_offer_carving("map")


func _gold_roll(kind: String) -> int:
	var r: Array = region["gold"][kind]
	var g := rng.randi_range(int(r[0]), int(r[1]))
	add_gold(g)
	return g


func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	if amount > 0:
		stats["gold_earned"] += amount


# ---------------------------------------------------------------- carving (dice building)

func _offer_carving(return_to: String) -> void:
	_return_phase = return_to
	carve_offers = []
	var hero_order := range(heroes.size())
	_shuffle(hero_order)
	for k in CARVE_OFFERS:
		var hi: int = hero_order[k % hero_order.size()]
		carve_offers.append(_make_offer(hi))
	phase = "reward"
	changed.emit()


func _make_offer(hi: int) -> Dictionary:
	var h: Dictionary = heroes[hi]
	var faces: Array = h["faces"]
	var blanks: Array = []
	var others: Array = []
	for i in faces.size():
		(blanks if faces[i]["type"] == "blank" else others).append(i)
	var fi: int
	var new_face: Dictionary
	if not blanks.is_empty() and (others.is_empty() or rng.randf() < BLANK_CARVE_CHANCE) and not h["carve_pool"].is_empty():
		fi = blanks[rng.randi_range(0, blanks.size() - 1)]
		var pool: Array = h["carve_pool"]
		new_face = pool[rng.randi_range(0, pool.size() - 1)].duplicate()
	else:
		fi = others[rng.randi_range(0, others.size() - 1)]
		new_face = faces[fi].duplicate()
		new_face["value"] = int(new_face["value"]) + 1
	return {
		"hero": hi, "face": fi, "new": new_face,
		"text": "%s: %s -> %s" % [Combat.short_name(h), face_text(faces[fi]), face_text(new_face)],
	}


static func face_text(f: Dictionary) -> String:
	return "blank" if f["type"] == "blank" else "%s %d" % [String(f["type"]).to_upper(), int(f["value"])]


func choose_carving(index: int) -> void:
	if phase != "reward" or index < 0 or index >= carve_offers.size():
		return
	var o: Dictionary = carve_offers[index]
	heroes[o["hero"]]["faces"][o["face"]] = o["new"]
	stats["carves"] += 1
	_log("Carved: " + o["text"])
	skip_carving()


func skip_carving() -> void:
	if phase != "reward":
		return
	carve_offers = []
	phase = _return_phase
	changed.emit()


# ---------------------------------------------------------------- events

func can_choose_event_option(index: int) -> bool:
	if phase != "event" or event_result != "" or index < 0 or index >= event["options"].size():
		return false
	return gold >= int(event["options"][index].get("require_gold", 0))


func choose_event_option(index: int) -> void:
	if not can_choose_event_option(index):
		return
	var lines: Array[String] = []
	var next := _apply_effects(event["options"][index]["effects"], lines)
	event_result = " ".join(lines) if not lines.is_empty() else "You move on."
	_log(event_result)
	if next == "fight":
		return  # combat already started
	if next == "carve":
		_offer_carving("map")
		return
	changed.emit()


## Called by the UI after the player has read the event outcome.
func close_event() -> void:
	if phase == "event" and event_result != "":
		phase = "map"
		changed.emit()


## Applies a list of effects. Returns "fight", "carve" or "" (what should happen next).
func _apply_effects(effects: Array, lines: Array[String]) -> String:
	var next := ""
	for e in effects:
		match e["op"]:
			"hp":
				for h in _pick_heroes(e["who"]):
					var before: int = h["hp"]
					h["hp"] = clamp(h["hp"] + int(e["value"]), 1, h["max_hp"])
					var diff: int = h["hp"] - before
					if diff != 0:
						lines.append("%s %s %d HP." % [Combat.short_name(h), "heals" if diff > 0 else "loses", abs(diff)])
			"max_hp":
				for h in _pick_heroes(e["who"]):
					h["max_hp"] = max(5, h["max_hp"] + int(e["value"]))
					h["hp"] = min(h["hp"], h["max_hp"])
					lines.append("%s's max HP is now %d." % [Combat.short_name(h), h["max_hp"]])
			"gold":
				add_gold(int(e["value"]))
				lines.append("%+d gold." % int(e["value"]))
			"fate":
				combat.fate = min(Combat.MAX_FATE, combat.fate + int(e["value"]))
				lines.append("+%d Fate." % int(e["value"]))
			"revive":
				for h in heroes:
					if not Combat.is_alive(h):
						h["hp"] = max(1, h["max_hp"] * int(e["percent"]) / 100)
						lines.append("%s rises." % Combat.short_name(h))
			"carve":
				next = "carve"
			"fight":
				lines.append(e.get("text", "You are attacked!"))
				event_result = " ".join(lines)
				_start_fight("fight", e.get("pool", tier_at(pos)))
				return "fight"
			"chance":
				var branch: Array = e["win"] if rng.randf() < float(e["p"]) else e["lose"]
				var sub := _apply_effects(branch, lines)
				if sub != "":
					next = sub
					if sub == "fight":
						return sub
	return next


func _pick_heroes(who: String) -> Array:
	var alive := heroes.filter(func(h): return Combat.is_alive(h))
	if alive.is_empty():
		return []
	match who:
		"all":
			return alive
		"random":
			return [alive[rng.randi_range(0, alive.size() - 1)]]
		"healthiest":
			var best = alive[0]
			for h in alive:
				if h["hp"] > best["hp"]:
					best = h
			return [best]
		"lowest":
			var worst = alive[0]
			for h in alive:
				if h["hp"] < worst["hp"]:
					worst = h
			return [worst]
	return []


# ---------------------------------------------------------------- shop

func shop_items() -> Array:
	return region["shop"]


func can_buy(item_id: String) -> bool:
	if phase != "shop" or item_id in shop_bought:
		return false
	for it in region["shop"]:
		if it["id"] == item_id:
			if item_id == "resurrect" and heroes.all(func(h): return Combat.is_alive(h)):
				return false
			return gold >= int(it["cost"])
	return false


func buy(item_id: String) -> void:
	if not can_buy(item_id):
		return
	var item: Dictionary = region["shop"].filter(func(it): return it["id"] == item_id)[0]
	gold -= int(item["cost"])
	shop_bought.append(item_id)
	_log("Bought " + item["name"])
	match item_id:
		"tonic":
			for h in heroes:
				if Combat.is_alive(h):
					h["hp"] = min(h["max_hp"], h["hp"] + 8)
		"fate_shard":
			combat.fate = min(Combat.MAX_FATE, combat.fate + 3)
		"resurrect":
			for h in heroes:
				if not Combat.is_alive(h):
					h["hp"] = h["max_hp"] / 2
		"carving":
			_offer_carving("shop")
			return
	changed.emit()


func leave_shop() -> void:
	if phase == "shop":
		phase = "map"
		changed.emit()


# ---------------------------------------------------------------- rest

func rest_heal() -> void:
	if phase != "rest":
		return
	var pct: int = region["rest_heal_percent"]
	for h in heroes:
		var amount: int = max(1, h["max_hp"] * pct / 100)
		h["hp"] = min(h["max_hp"], max(h["hp"], 0) + amount)
	_log("The party rests by the fire.")
	phase = "map"
	changed.emit()


func rest_carve() -> void:
	if phase == "rest":
		_offer_carving("map")


# ---------------------------------------------------------------- helpers

func is_over() -> bool:
	return phase in ["victory", "defeat"]


func progress() -> float:
	return float(pos) / float(board.size() - 1)


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


func _log(text: String) -> void:
	log_added.emit(text)
