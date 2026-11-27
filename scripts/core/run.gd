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
##   "pet"     - choose a companion at the start of the run
##   "loot"    - choose a weapon and which hero equips it (or skip)
##   "victory" / "defeat" - the run is over

signal changed
signal log_added(text: String)

const Combat = preload("res://scripts/core/combat.gd")
const GameData = preload("res://scripts/core/game_data.gd")

const CARVE_OFFERS := 3
const BLANK_CARVE_CHANCE := 0.45  # chance an offer targets a blank face (if the hero has one)
const WEAPON_SLOTS := [4, 5]       # die faces 5 and 6 belong to the equipped weapon
const CHEST_WEAPON_CHANCE := 0.4
const RARITY_WEIGHTS := {"common": 6, "rare": 3, "cursed": 2}

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
var stats := {"fights": 0, "elites": 0, "events": 0, "carves": 0, "gold_earned": 0, "tiles": {}, "kills": {}}
var _return_phase := "map"    # where to go after a carving reward
var weapons_db: Array = []
var pets_db: Array = []
var pet_offers: Array = []
var weapon_offers: Array = []
var _loot_then := "map"       # "carve" | "map" | "shop"
var _seen_events: Array = []
var tile_snapshot: Dictionary = {}  # saved while a tile (fight/event/shop...) is in progress
var upgrades := {}            # town building levels (see data/town.json)
var _start_queue: Array = []  # steps after choosing a pet: "loot", "carve"
var boss_id := ""             # which boss guards the end of this road (see region1.json "bosses")


func _init(seed_value: int = -1, town_levels: Dictionary = {}, party: Array = []) -> void:
	upgrades = town_levels
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	# 3.5: an Isle dungeon is a short board with its own data file (upgrades["region"]); the road is region1.json.
	region = GameData.load_json(String(upgrades.get("region", "res://data/region1.json")))
	monster_defs = GameData.load_monsters()
	events = GameData.load_json("res://data/events.json")
	var defs: Array = GameData.load_heroes()
	if party.is_empty():
		defs = defs.filter(func(d): return d.get("starter", false))
	else:
		var by_id := {}
		for d in defs:
			by_id[d["id"]] = d
		defs = party.map(func(id): return by_id[id])
	for def in defs:
		var u := Combat.make_unit(def)
		u["carve_pool"] = def.get("carve_pool", [])
		u["weapon"] = {}
		var bonus_hp := int(upgrades.get("chapel", 0))
		u["max_hp"] += bonus_hp
		u["hp"] += bonus_hp
		apply_hero_stars(u, star_of("hero", u["id"]))
		apply_gear(u, upgrades.get("gear", {}).get(u["id"], {}))
		heroes.append(u)
	var unlocked: Array = upgrades.get("unlocked_weapons", [])
	weapons_db = GameData.load_weapons().filter(func(w): return not w.get("locked", false) or w["id"] in unlocked)
	pets_db = GameData.load_pets()
	# The combat object lives for the whole run, so Fate carries between fights.
	combat = Combat.new(rng.randi())
	combat.battle_ended.connect(_on_battle_ended)
	combat.log_added.connect(func(t): log_added.emit(t))
	combat.bonus_fate_start = int(upgrades.get("fortune", 0)) + (1 if time_of_day() == "dusk" else 0)
	_generate_board()
	boss_id = String(pick_road_boss(region, time_of_day(), int(upgrades.get("road_wins", 0)), rng).get("id", ""))
	# A stray follows you onto the road: pick 1 of 2 companions.
	var owned: Array = upgrades.get("owned_pets", [])
	var pool := pets_db.filter(func(p): return p.get("starter", false) or p["id"] in owned)
	_shuffle(pool)
	pet_offers = pool.slice(0, 3 if int(upgrades.get("kennel", 0)) > 0 else 2)
	phase = "pet"
	if int(upgrades.get("smithy", 0)) > 0:
		_start_queue.append("loot")
	if int(upgrades.get("carver", 0)) >= 2:
		_start_queue.append("carve")


# ---------------------------------------------------------------- board

func _generate_board() -> void:
	var length: int = region["board_length"]
	board = [{"type": "start", "visited": true}]
	for i in range(1, length):
		var tier := "early" if i < length / 3 else ("mid" if i < 2 * length / 3 else "late")
		board.append({"type": _weighted_pick(region["tile_weights"][tier]), "visited": false})
	var gates: Array = region.get("gate_tiles", []).map(func(g): return int(g))  # JSON numbers are floats!
	for k in region.get("fixed_tiles", {}):
		var idx := int(k)
		if idx > 0 and idx < length - 1:
			board[idx] = {"type": region["fixed_tiles"][k], "visited": false, "gate": idx in gates}
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


## 3.5: true for an Isle dungeon run (rewards go to the Isle bag, not the road's embers and quests).
func is_dungeon() -> bool:
	return String(region.get("kind", "")) == "dungeon"


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
	move_options = _roll_distinct_moves()
	changed.emit()


## Two movement dice that lead to different kinds of tiles whenever possible
## (v0.3 critique: half of all choices were fake, e.g. Fight vs Fight).
func _roll_distinct_moves() -> Array:
	var a := rng.randi_range(1, 6)
	var b := rng.randi_range(1, 6)
	for attempt in 6:
		if board[destination(a)]["type"] != board[destination(b)]["type"]:
			break
		b = rng.randi_range(1, 6)
	return [a, b]


const MOVE_REROLL_FATE := 1

## Spend Fate to reroll both movement dice.
func reroll_move() -> bool:
	if phase != "map" or move_options.is_empty() or combat.fate < MOVE_REROLL_FATE:
		return false
	combat.fate -= MOVE_REROLL_FATE
	move_options = _roll_distinct_moves()
	_log(tr("Fate bends the road (-%d Fate)") % MOVE_REROLL_FATE)
	changed.emit()
	return true


func choose_move(option_index: int) -> void:
	if phase != "map" or option_index < 0 or option_index >= move_options.size():
		return
	pos = destination(move_options[option_index])
	move_options = []
	# Snapshot BEFORE entering the tile: reloading re-enters the same tile with the same dice.
	tile_snapshot = to_dict()
	tile_snapshot["pending_enter"] = true
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
			last_reward_text = tr("You pry open a rotten chest: +%d gold.") % g
			_log(last_reward_text)
			if rng.randf() < CHEST_WEAPON_CHANCE:
				last_reward_text += tr(" A weapon lies among the bones.")
				_offer_loot(1, "map")
			elif rng.randf() < 0.35:
				last_reward_text += tr(" Inside, a bone chisel.")
				_offer_carving("map")
			else:
				phase = "map"
				changed.emit()
		"event":
			var fresh := events.filter(func(e): return not (e["id"] in _seen_events))
			if fresh.is_empty():
				fresh = events
			event = fresh[rng.randi_range(0, fresh.size() - 1)]
			_seen_events.append(event["id"])
			event_result = ""
			stats["events"] += 1
			phase = "event"
			changed.emit()
		"shop":
			shop_bought = []
			phase = "shop"
			changed.emit()
		"rest":
			if tile.get("gate", false) and pos == board.size() - 2:
				# The Last Campfire always heals before you choose (v0.5 critique: it was a trap).
				var pct := rest_percent()
				for h in heroes:
					h["hp"] = min(h["max_hp"], max(h["hp"], 0) + max(1, h["max_hp"] * pct / 100))
				_log(tr("The last campfire warms you (+%d%% HP).") % pct)
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
	var ids: Array = [boss_id] if kind == "boss" and monster_defs.has(boss_id) else pool[rng.randi_range(0, pool.size() - 1)]
	phase = "combat"
	_log("== %s ==" % (tr("BOSS") if kind == "boss" else (tr("Elite fight") if kind == "elite" else tr("Fight"))))
	combat.start_battle(heroes, ids.map(func(id): return scaled_monster(monster_defs[id], kind, tier)))
	changed.emit()


## Which boss waits at the end of the road (3.4). The first journey always meets the Rotting Bishop
## (bosses with "after_wins" above the player's road wins are hidden); after that the time of day decides.
## With no time of day (bot playtests, tests) every boss is equally likely, so balance checks see them all.
static func pick_road_boss(reg: Dictionary, time: String, road_wins: int, r: RandomNumberGenerator = null) -> Dictionary:
	var bosses: Array = reg.get("bosses", [])
	if bosses.is_empty():
		return {"id": String(reg["encounters"]["boss"][0][0])}
	if time == "":
		return bosses[r.randi_range(0, bosses.size() - 1)] if r != null else bosses[0]
	var avail := bosses.filter(func(b): return int(b.get("after_wins", 0)) <= road_wins)
	for b in avail:
		if time in b.get("times", []):
			return b
	return avail[0] if not avail.is_empty() else bosses[0]


## The data entry of this road's boss (lair name, scenery, gate and victory text).
func boss_info() -> Dictionary:
	for b in region.get("bosses", []):
		if b["id"] == boss_id:
			return b
	return {"id": boss_id}


## Enemies get tougher further down the road (region1.json "scaling").
func scaled_monster(def: Dictionary, kind: String, tier: String) -> Dictionary:
	var sc: Dictionary = region.get("scaling", {}).get(kind if kind in ["elite", "boss"] else tier, {})
	var curse := curse_level()
	var night := time_of_day() == "night"
	var gear_k := gear_scaling()
	if sc.is_empty() and curse == 0 and not night and gear_k == 1.0:
		return def
	var d := def.duplicate(true)
	# Curse rules (see CURSE_RULES): I hungry dead, II sharpened bones, IV the Bishop wakes early.
	d["hp"] = int(round(float(d["hp"]) * float(sc.get("hp", 1.0)) * (1.15 if curse >= 1 else 1.0) * (1.2 if night else 1.0) * gear_k))
	var bonus := int(sc.get("damage", 0)) + (1 if curse >= 2 else 0) + (1 if curse >= 4 and kind == "elite" else 0) 
	if curse >= 4 and d.has("phase2"):
		d["phase2"]["at"] = 0.7
	for faces in [d["faces"], d.get("phase2", {}).get("faces", [])]:
		for f in faces:
			if f["type"] in ["attack", "sweep"]:
				f["value"] = int(f["value"]) + bonus
	return d


# ---------------------------------------------------------------- crafted gear from the Forge

## Crafted weapon = the hero's starting weapon (faces 5-6). Armour = +max HP and shield in round 1 of every fight.
static func apply_gear(u: Dictionary, g: Dictionary) -> void:
	if g.has("weapon"):
		var w: Dictionary = g["weapon"]
		equip_weapon(u, {"id": w["id"], "name": w["name"], "rarity": "crafted", "faces": w["faces"].duplicate(true)})
	if g.has("armor"):
		var a: Dictionary = g["armor"]
		u["max_hp"] += int(a["hp"])
		u["hp"] += int(a["hp"])
		u["armor_shield"] = int(a["shield"])
		u["armor"] = a["name"]


# ---------------------------------------------------------------- stars from the town's Collection

func star_of(kind: String, id: String) -> int:
	return int(upgrades.get("stars", {}).get("%s:%s" % [kind, id], 1))


## Hero stars: 2 = +2 max HP, 3 = +1 to the weakest face (1-4), 4 = +2 max HP, 5 = +1 skill charge each fight.
static func apply_hero_stars(u: Dictionary, star: int) -> void:
	var hp := (2 if star >= 2 else 0) + (2 if star >= 4 else 0)
	u["max_hp"] += hp
	u["hp"] += hp
	if star >= 3:
		var best := -1
		for i in 4:
			var f: Dictionary = u["faces"][i]
			if f["type"] != "blank" and (best < 0 or int(f["value"]) < int(u["faces"][best]["value"])):
				best = i
		if best >= 0:
			var nf: Dictionary = u["faces"][best].duplicate()
			nf["value"] = int(nf["value"]) + 1
			u["faces"][best] = nf
	if star >= 5:
		u["charge_bonus"] = 1
	u["star"] = star


## Pet stars: each star after the first adds +1 to a non-blank d4 face; star 5 turns the blank into ATK 2.
static func apply_pet_stars(p: Dictionary, star: int) -> void:
	var faces: Array = p["faces"]
	var non_blank: Array = []
	for i in faces.size():
		if faces[i]["type"] != "blank":
			non_blank.append(i)
	for k in range(min(star - 1, 3)):
		if non_blank.is_empty():
			break
		var i: int = non_blank[k % non_blank.size()]
		faces[i] = {"type": faces[i]["type"], "value": int(faces[i]["value"]) + 1}
	if star >= 5:
		for i in faces.size():
			if faces[i]["type"] == "blank":
				faces[i] = {"type": "attack", "value": 2}
				break
	p["star"] = star


## Companion treat (v3.1, crafted at the Forge): fills the pet's blank d4 face with the treat's face.
## A pet with no blank left (5 stars) gets +1 on its weakest face instead, so a treat is never wasted.
static func apply_pet_treat(p: Dictionary, treat: Dictionary) -> void:
	if treat.is_empty() or not treat.has("face"):
		return
	var faces: Array = p["faces"]
	for i in faces.size():
		if faces[i]["type"] == "blank":
			faces[i] = (treat["face"] as Dictionary).duplicate()
			p["treat"] = treat["name"]
			return
	var low := 0
	for i in faces.size():
		if int(faces[i]["value"]) < int(faces[low]["value"]):
			low = i
	faces[low] = {"type": faces[low]["type"], "value": int(faces[low]["value"]) + 1}
	p["treat"] = treat["name"]


## Relic stars: alternate +1 between the two weapon faces.
static func apply_relic_stars(w: Dictionary, star: int) -> Dictionary:
	for k in range(star - 1):
		var i := k % 2
		var f: Dictionary = w["faces"][i]
		if f["type"] != "blank":
			w["faces"][i] = {"type": f["type"], "value": int(f["value"]) + 1}
	if star > 1:
		w["name"] = "%s +%d" % [w["name"], star - 1]
	return w


## Opt-in difficulty rules. Each level adds one rule on top of the previous ones.
const CURSE_RULES := [
	"I. The Hungry Dead: enemies have +15% HP.",
	"II. Sharpened Bones: enemy attacks deal +1 damage.",
	"III. Cold Fires: camps heal 10% less, the fallen rise with 25% HP.",
	"IV. The Road Wakes: elites hit +1 harder, the road's boss enrages at 70% HP.",
]


## Time of day the journey began ("dawn", "day", "dusk", "night" or "" when not set).
func time_of_day() -> String:
	return String(upgrades.get("time", ""))


## Crafted gear makes the road answer in kind: +6% enemy HP per SR item, +12% per SSR (max +30%).
func gear_scaling() -> float:
	var bonus := 0.0
	for hero in upgrades.get("gear", {}):
		for slot in upgrades["gear"][hero]:
			if slot == "treat":
				continue  # companion treats are small; the road does not answer them
			bonus += 0.12 if upgrades["gear"][hero][slot].get("grade", "SR") == "SSR" else 0.06
	return 1.0 + min(bonus, 0.3)


func curse_level() -> int:
	return int(upgrades.get("curse", 0))


func rest_percent() -> int:
	return int(region["rest_heal_percent"]) - (10 if curse_level() >= 3 else 0) + (10 if time_of_day() == "dawn" else 0)


func _on_battle_ended(victory: bool) -> void:
	for m in combat.monsters:
		if not Combat.is_alive(m):
			stats["kills"][m["id"]] = stats["kills"].get(m["id"], 0) + 1
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
	var pct: int = 25 if curse_level() >= 3 else int(region["revive_after_fight_percent"])
	for h in heroes:
		if not Combat.is_alive(h):
			h["hp"] = max(1, h["max_hp"] * pct / 100)
	var g := _gold_roll("elite" if combat_kind == "elite" else "fight")
	last_reward_text = tr("Victory! +%d gold.") % g
	if combat.pet.get("passive", "") == "mend":
		for h in heroes:
			if Combat.is_alive(h):
				h["hp"] = min(h["max_hp"], h["hp"] + Combat.PET_MEND)
		last_reward_text += tr(" The Candle Moth mends your wounds (+%d HP).") % Combat.PET_MEND
	if combat_kind == "elite":
		var heal_pct := int(region.get("elite_heal_percent", 0))
		for h in heroes:
			h["hp"] = min(h["max_hp"], h["hp"] + h["max_hp"] * heal_pct / 100)
		last_reward_text += tr(" The party catches its breath (+%d%% HP). The elite drops its arms.") % heal_pct
		_offer_loot(2, "carve")
	else:
		_offer_carving("map")


func _gold_roll(kind: String) -> int:
	var r: Array = region["gold"][kind]
	var g := rng.randi_range(int(r[0]), int(r[1]))
	if combat.pet.get("passive", "") == "greedy":
		g = int(g * 1.5)
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
	var count := CARVE_OFFERS + (1 if int(upgrades.get("carver", 0)) >= 1 else 0)
	for k in count:
		var hi: int = hero_order[k % hero_order.size()]
		var offer := _make_offer(hi, k == 0)
		for attempt in 6:  # 3.5 player bug: two identical carvings in one offer
			if not carve_offers.any(func(o): return o["text"] == offer["text"]):
				break
			offer = _make_offer(hero_order[(k + attempt + 1) % hero_order.size()], false)
		carve_offers.append(offer)
	phase = "reward"
	changed.emit()


const MAX_FACE_VALUE := 7

func _make_offer(hi: int, force_new_face: bool = false) -> Dictionary:
	var h: Dictionary = heroes[hi]
	var faces: Array = h["faces"]
	var blanks: Array = []
	var others: Array = []
	for i in faces.size():
		if i in WEAPON_SLOTS:
			continue  # weapon faces belong to the weapon; carving shapes the hero's own faces 1-4
		(blanks if faces[i]["type"] == "blank" else others).append(i)
	var fi: int
	var new_face: Dictionary
	var maxed := others.filter(func(i): return int(faces[i]["value"]) >= MAX_FACE_VALUE)
	var upgradable := others.filter(func(i): return int(faces[i]["value"]) < MAX_FACE_VALUE)
	var pool: Array = h["carve_pool"]
	var new_face_offer := force_new_face or upgradable.is_empty() or (not blanks.is_empty() and rng.randf() < BLANK_CARVE_CHANCE)
	if new_face_offer and not pool.is_empty():
		# Replace a blank, or the weakest face, with a new face from the hero's carve pool.
		if not blanks.is_empty():
			fi = blanks[rng.randi_range(0, blanks.size() - 1)]
		else:
			fi = others[0]
			for i in others:
				if int(faces[i]["value"]) < int(faces[fi]["value"]):
					fi = i
		new_face = pool[rng.randi_range(0, pool.size() - 1)].duplicate()
		if new_face["type"] == faces[fi]["type"] and int(new_face["value"]) <= int(faces[fi]["value"]):
			new_face = faces[fi].duplicate()
			new_face["value"] = min(MAX_FACE_VALUE, int(new_face["value"]) + 1)
	else:
		fi = upgradable[rng.randi_range(0, upgradable.size() - 1)] if not upgradable.is_empty() else others[0]
		new_face = faces[fi].duplicate()
		new_face["value"] = min(MAX_FACE_VALUE, int(new_face["value"]) + 1)
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
	var hero: Dictionary = heroes[o["hero"]]
	hero["faces"][o["face"]] = o["new"]
	if o["face"] in WEAPON_SLOTS and not hero["weapon"].is_empty():
		hero["weapon"]["faces"][WEAPON_SLOTS.find(o["face"])] = o["new"]
	stats["carves"] += 1
	_log(tr("Carved: ") + o["text"])
	skip_carving()


func skip_carving() -> void:
	if phase != "reward":
		return
	carve_offers = []
	if _return_phase == "start":
		_next_start_step()
		return
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
	event_result = " ".join(lines) if not lines.is_empty() else tr("You move on.")
	_log(event_result)
	if next == "fight":
		return  # combat already started
	if next == "carve":
		last_reward_text = event_result  # the event's own words, not a stale shop/chest message
		_offer_carving("map")
		return
	if next == "loot":
		last_reward_text = event_result
		_offer_loot(_event_loot, "map")
		return
	changed.emit()


## Called by the UI after the player has read the event outcome.
func close_event() -> void:
	if phase == "event" and event_result != "":
		phase = "map"
		changed.emit()


var _event_loot := 2  # how many weapons an event's "weapon" effect offers

## Applies a list of effects. Returns "fight", "carve", "loot" or "" (what should happen next).
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
						lines.append((tr("%s heals %d HP.") if diff > 0 else tr("%s loses %d HP.")) % [Combat.short_name(h), abs(diff)])
			"max_hp":
				for h in _pick_heroes(e["who"]):
					h["max_hp"] = max(5, h["max_hp"] + int(e["value"]))
					h["hp"] = min(h["hp"], h["max_hp"])
					lines.append(tr("%s's max HP is now %d.") % [Combat.short_name(h), h["max_hp"]])
			"gold":
				add_gold(int(e["value"]))
				lines.append(tr("%+d gold.") % int(e["value"]))
			"fate":
				combat.gain_fate(int(e["value"]), tr("Fate"))  # overflow -> free rerolls, never wasted
				lines.append(tr("+%d Fate.") % int(e["value"]))
			"revive":
				for h in heroes:
					if not Combat.is_alive(h):
						h["hp"] = max(1, h["max_hp"] * int(e["percent"]) / 100)
						lines.append(tr("%s rises.") % Combat.short_name(h))
			"carve":
				next = "carve"
			"weapon":
				_event_loot = int(e.get("count", 2))
				next = "loot"
			"fight":
				lines.append(tr(e.get("text", "You are attacked!")))
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


func price(item: Dictionary) -> int:
	var discount := 0.15 * int(upgrades.get("market", 0)) + (0.15 if time_of_day() == "day" else 0.0)
	return int(round(int(item["cost"]) * (1.0 - discount)))


func can_buy(item_id: String) -> bool:
	if phase != "shop" or item_id in shop_bought:
		return false
	for it in region["shop"]:
		if it["id"] == item_id:
			if item_id == "resurrect" and heroes.all(func(h): return Combat.is_alive(h)):
				return false
			return gold >= price(it)
	return false


func buy(item_id: String) -> void:
	if not can_buy(item_id):
		return
	var item: Dictionary = region["shop"].filter(func(it): return it["id"] == item_id)[0]
	gold -= price(item)
	shop_bought.append(item_id)
	_log(tr("Bought ") + tr(item["name"]))
	match item_id:
		"tonic":
			for h in heroes:
				if Combat.is_alive(h):
					h["hp"] = min(h["max_hp"], h["hp"] + 8)
		"fate_shard":
			combat.gain_fate(3, tr("Fate Shard") + ":")  # Fate beyond 5 becomes free rerolls in the next fight
		"resurrect":
			for h in heroes:
				if not Combat.is_alive(h):
					h["hp"] = h["max_hp"] / 2
		"carving":
			last_reward_text = tr("The Bone Carver sets to work on your dice.")
			_offer_carving("shop")
			return
		"weapon":
			last_reward_text = tr("The merchant lays two weapons on the cloth.")
			_offer_loot(2, "shop")
			return
	changed.emit()


func leave_shop() -> void:
	if phase == "shop":
		phase = "map"
		changed.emit()


# ---------------------------------------------------------------- pets & weapons

func choose_pet(index: int) -> void:
	if phase != "pet" or index < 0 or index >= pet_offers.size():
		return
	var p: Dictionary = pet_offers[index].duplicate(true)
	apply_pet_stars(p, star_of("pet", p["id"]))
	apply_pet_treat(p, upgrades.get("gear", {}).get("pet:" + String(p["id"]), {}).get("treat", {}))
	p["face"] = 0
	combat.pet = p
	_log(tr("%s follows you.") % tr(p["name"]))
	pet_offers = []
	_next_start_step()


## Town upgrades that happen at the start of a run (Gravesmith weapon, Bone Carver carving).
func _next_start_step() -> void:
	if _start_queue.is_empty():
		phase = "map"
		changed.emit()
		return
	var step: String = _start_queue.pop_front()
	last_reward_text = tr("A gift from the town.")
	if step == "loot":
		_offer_loot(int(upgrades.get("smithy", 0)), "start", "common")
	else:
		_offer_carving("start")


func _offer_loot(count: int, then: String, only_rarity: String = "") -> void:
	_loot_then = then
	weapon_offers = []
	var guard := 0
	while weapon_offers.size() < count and guard < 80:
		guard += 1
		var w := _weighted_weapon()
		if only_rarity != "" and w["rarity"] != only_rarity:
			continue
		if not weapon_offers.any(func(x): return x["id"] == w["id"]):
			weapon_offers.append(apply_relic_stars(w.duplicate(true), star_of("relic", w["id"])))
	phase = "loot"
	changed.emit()


func _weighted_weapon() -> Dictionary:
	var total := 0
	for w in weapons_db:
		total += RARITY_WEIGHTS.get(w["rarity"], 1)
	var roll := rng.randi_range(1, total)
	for w in weapons_db:
		roll -= RARITY_WEIGHTS.get(w["rarity"], 1)
		if roll <= 0:
			return w
	return weapons_db[0]


## Equip weapon_offers[weapon_index] on heroes[hero_index]. The old weapon is lost.
func equip(weapon_index: int, hero_index: int) -> void:
	if phase != "loot" or weapon_index < 0 or weapon_index >= weapon_offers.size():
		return
	if hero_index < 0 or hero_index >= heroes.size():
		return
	equip_weapon(heroes[hero_index], weapon_offers[weapon_index])
	_log(tr("%s takes up %s.") % [Combat.short_name(heroes[hero_index]), tr(weapon_offers[weapon_index]["name"])])
	skip_loot()


static func equip_weapon(h: Dictionary, weapon: Dictionary) -> void:
	var old: Dictionary = h["weapon"]
	h["max_hp"] -= int(old.get("max_hp", 0))
	var w := weapon.duplicate(true)
	h["weapon"] = w
	h["max_hp"] = max(5, h["max_hp"] + int(w.get("max_hp", 0)))
	h["hp"] = min(h["hp"], h["max_hp"])
	for k in WEAPON_SLOTS.size():
		h["faces"][WEAPON_SLOTS[k]] = w["faces"][k]


func skip_loot() -> void:
	if phase != "loot":
		return
	weapon_offers = []
	match _loot_then:
		"carve":
			_offer_carving("map")
		"shop":
			phase = "shop"
			changed.emit()
		"start":
			_next_start_step()
		_:
			phase = "map"
			changed.emit()


# ---------------------------------------------------------------- rest

## False when resting would heal nobody (e.g. the Last Campfire already healed you): carve instead.
func rest_heal_useful() -> bool:
	return heroes.any(func(h): return h["hp"] < h["max_hp"])


## Shop discount explained for the UI ("" when there is none).
func price_note() -> String:
	var parts: Array[String] = []
	if int(upgrades.get("market", 0)) > 0:
		parts.append(tr("Night Market -%d%%") % (15 * int(upgrades.get("market", 0))))
	if time_of_day() == "day":
		parts.append(tr("Day -15%"))
	return ", ".join(parts)


func rest_heal() -> void:
	if phase != "rest":
		return
	var pct := rest_percent()
	for h in heroes:
		var amount: int = max(1, h["max_hp"] * pct / 100)
		h["hp"] = min(h["max_hp"], max(h["hp"], 0) + amount)
	_log(tr("The party rests by the fire."))
	phase = "map"
	changed.emit()


func rest_carve() -> void:
	if phase == "rest":
		last_reward_text = tr("By the fire, you whittle at your dice.")
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


# ---------------------------------------------------------------- save / load (only on the map)

const SAVE_VERSION := 2  # v1 saves (0.5-0.6) load fine: they simply have no pending tile.

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION, "rng_seed": rng.seed, "rng_state": rng.state, "combat_rng_state": combat.rng.state,
		"board": board, "pos": pos, "gold": gold, "heroes": heroes, "fate": combat.fate, "pet": combat.pet,
		"twists": combat.twists, "stats": stats, "seen_events": _seen_events, "upgrades": upgrades,
		"move_options": move_options, "boss_id": boss_id,
	}


static func from_dict(d: Dictionary) -> RefCounted:
	var script: GDScript = load("res://scripts/core/run.gd")
	var r = script.new(0, d.get("upgrades", {}))
	r.rng.seed = d["rng_seed"]
	r.rng.state = d["rng_state"]
	r.combat.rng.state = d["combat_rng_state"]
	r.board = d["board"]
	r.pos = d["pos"]
	r.gold = d["gold"]
	r.heroes = d["heroes"]
	r.combat.fate = d["fate"]
	r.combat.pet = d["pet"]
	r.combat.twists = d.get("twists", 0)
	r.stats = d["stats"]
	r._seen_events = d["seen_events"]
	r.move_options = d.get("move_options", [])
	r.boss_id = String(d.get("boss_id", "rotting_bishop"))  # saves from before 3.4 always met the Bishop
	r._start_queue = []
	r.pet_offers = []
	r.phase = "map"
	if d.get("pending_enter", false):
		# The save was made when stepping onto this tile: enter it again (same RNG, same outcome).
		var tile: Dictionary = r.board[r.pos]
		r._enter_tile(tile)
	return r
